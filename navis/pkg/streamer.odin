package pkg

import "../mem"
import "../log"
import "core:io"
import "core:os"
import "core:runtime"
import "core:intrinsics"
import "core:thread"
import "core:sync"
import "core:strings"

/*
ID for task that load an asset
*/
LOAD_ASSET_TASK_ID :: 1_001

Proc_On_Asset_Loaded :: proc(^Asset, rawptr)

/*
Load asset task data
*/
Load_Asset_Task_Data :: struct
{
    streamer: ^Streamer,
    asset: ^Asset,
    seek_info: Package_Asset_Seek_Info,
    on_loaded: Proc_On_Asset_Loaded,
    user_data: rawptr,
}

/*
Wait asset task
*/
Wait_Asset_Task :: struct
{
    user_data: rawptr,
    asset: ^Asset,
    on_loaded: Proc_On_Asset_Loaded,
}

/*
Asset
*/
Asset :: struct
{
    is_loading, is_loaded: bool,
    references, idle_frames: int,
    data: []byte,
}

Package_Asset_Seek_Info :: struct
{
    package_name: string,
    offset, size: int,
}

/*
Used internally.
*/
@(private)
Package_Streamer :: struct
{
    package_name: string,
    assets_to_load: int,
    mutex: sync.Mutex,
    path: string,
    handle: os.Handle,
    stream: io.Stream,
    stream_allocator: runtime.Allocator,
}

/*
Streamer
*/
Streamer :: struct
{
    mutex: sync.Mutex,
    assets: mem.Collection(Asset),
    assets_map: map[string]^Asset,
    seek_infos: map[string]Package_Asset_Seek_Info,
    package_streamers: map[string]Package_Streamer,
    wait_tasks: [dynamic]Wait_Asset_Task,
}

asset_is_loading :: proc "contextless" (asset: ^Asset) -> bool
{
    if asset == nil do return false
    return intrinsics.atomic_load(&asset.is_loading)
}

asset_is_loaded :: proc "contextless" (asset: ^Asset) -> bool
{
    if asset == nil do return false
    return intrinsics.atomic_load(&asset.is_loaded)
}

asset_references :: #force_inline proc "contextless" (asset: ^Asset) -> int
{
    return intrinsics.atomic_load(&asset.references)
}

asset_idle_frames :: #force_inline proc "contextless" (asset: ^Asset) -> int
{
    return intrinsics.atomic_load(&asset.idle_frames)
}

package_streamer_init :: proc(streamer: ^Package_Streamer, path: string, stream_allocator := context.allocator, allocator := context.allocator) -> bool
{
    if streamer == nil
    {
        log.verbose_error("'streamer' parameter is 'nil'")
        return false
    }

    if !os.is_file(path)
    {
        log.verbose_error("Invalid package path", path)
        return false
    }

    path_clone, path_clone_allocation_error := strings.clone(path, allocator)
    if path_clone_allocation_error != .None
    {
        log.verbose_error("Failed to clone 'path' parameter", path_clone_allocation_error)
        return false
    }

    streamer.handle = os.INVALID_HANDLE
    streamer.path = path_clone
    if !package_streamer_add_assets_to_load(streamer)
    {
        log.verbose_error("Failed to add dummy assets to load")
        delete(path_clone, allocator)
        return false
    }
    defer package_streamer_sub_assets_to_load(streamer)

    package_name := package_name(streamer.stream, allocator)
    if package_name == ""
    {
        log.verbose_error("Failed to get package name")
        delete(path_clone, allocator)
        return false
    }

    streamer.package_name = package_name
    streamer.stream_allocator = stream_allocator
    log.verbose_debug("Did init streamer for package", package_name)
    return true
}

package_streamer_destroy :: proc(streamer: ^Package_Streamer, allocator := context.allocator) -> bool
{
    if streamer == nil
    {
        log.verbose_error("'streamer' parameter is 'nil'")
        return false
    }

    if streamer.handle != os.INVALID_HANDLE
    {
        log.debug("Closed package streamer of package:", streamer.package_name, "path:", streamer.path)
        streamer.handle = os.INVALID_HANDLE
        streamer.stream = {}
    }
    log.debug("Destroyed package streamer of package:", streamer.package_name)
    delete(streamer.package_name, allocator)
    return true
}

/*
Only for internal use.
*/
@(private)
package_streamer_add_assets_to_load :: proc(streamer: ^Package_Streamer) -> bool
{
    intrinsics.atomic_add(&streamer.assets_to_load, 1)
    if streamer.handle == os.INVALID_HANDLE
    {
        handle, open_error := os.open(streamer.path)
        if open_error != os.ERROR_NONE
        {
            log.error("Failed to open package streamer from path", streamer.path, "error code:", open_error)
            return false
        }

        streamer.handle =handle
        streamer.stream = os.stream_from_handle(handle)
    }

    log.debug("Opened package steamer for package:", streamer.package_name, "path:", streamer.path)
    return true
}

/*
Only for internal use.
*/
@(private)
package_streamer_sub_assets_to_load :: proc(streamer: ^Package_Streamer) -> bool
{
    intrinsics.atomic_sub(&streamer.assets_to_load, 1)
    assets_to_load := intrinsics.atomic_load(&streamer.assets_to_load)
    if assets_to_load == 0 do if os.close(streamer.handle) == os.ERROR_NONE
    {
        log.verbose_debug("Closed package streamer of package:", streamer.package_name, "path:", streamer.path)
        streamer.handle = os.INVALID_HANDLE
        streamer.stream = {}
        return true
    }
    else
    {
        log.verbose_debug("Failed to close package streamer of package:", streamer.package_name, "path:", streamer.path)
        return false
    }
    return true
}

package_streamer_map_seek_infos :: proc(streamer: ^Streamer, package_streamer: ^Package_Streamer, stream_seek := true) -> bool
{
    //Seek to begin
    seeker, _ := io.to_seeker(package_streamer.stream)
    io.seek(seeker, 0, .Start)

    //Magic
    seek := 0 //NOTE: will be our offset info for data
    magic: [3]byte
    io.read(package_streamer.stream, magic[:])
    if strings.compare(transmute(string)magic[:], MAGIC) != 0 do return false
    seek += 3

    //Package name length
    package_name_length := -1
    io.read_ptr(package_streamer.stream, &package_name_length, size_of(int))
    seek += size_of(int)
    
    //Package name
    package_name, package_name_allocation_error := make([]byte, package_name_length, context.temp_allocator)
    io.read(package_streamer.stream, package_name)
    seek += package_name_length
    
    //Package fields length
    package_fields_length := -1
    io.read_ptr(package_streamer.stream, &package_fields_length, size_of(int))
    seek += size_of(int)

    infos, infos_err := make_slice([]Package_Asset_Info, package_fields_length, context.temp_allocator)
    if infos_err != .None do return false
    
    for index := 0; index < package_fields_length; index += 1
    {
        //Field name length
        field_name_length := -1
        io.read_ptr(package_streamer.stream, &field_name_length, size_of(int))
        seek += size_of(int)
        
        //Package name
        field_name, field_name_allocation_error := make([]byte, field_name_length, context.temp_allocator)
        io.read(package_streamer.stream, field_name)
        seek += field_name_length

        //Field data offset
        field_data_offset := -1
        io.read_ptr(package_streamer.stream, &field_data_offset, size_of(int))
        seek += size_of(int)

        //Field data size
        field_data_size := -1
        io.read_ptr(package_streamer.stream, &field_data_size, size_of(int))
        seek += size_of(int)

        info: Package_Asset_Info
        info.asset.name = transmute(string)field_name
        info.seek.offset = field_data_offset
        info.seek.size = field_data_size
        infos[index] = info
    }

    for &info in infos do streamer.seek_infos[info.asset.name] = Package_Asset_Seek_Info{package_streamer.package_name, stream_seek ? seek + info.seek.offset : info.seek.offset, info.seek.size}
    return true
}

/*
Initialize a streamer.
*/
init :: proc(streamer: ^Streamer, paths: []string, assets_chunk_capacity := 100, stream_allocator := context.allocator, allocator := context.allocator) -> bool
{
    if streamer == nil || paths == nil do return false

    assets, created_assets := mem.collection_create(Asset, assets_chunk_capacity, 2, allocator)
    if !created_assets
    {
        log.verbose_error("Failed to create assets collection")
        return false
    }

    assets_map, assets_map_allocation_error := make_map(map[string]^Asset, len(paths) * 100, allocator)
    if assets_map_allocation_error != .None
    {
        log.verbose_error("Failed to allocate assets map", assets_map_allocation_error)
        mem.collection_destroy(&assets)
        return false
    }
    
    package_streamers, package_streamers_allocation_error := make_map(map[string]Package_Streamer, len(paths), allocator)
    if package_streamers_allocation_error != .None
    {
        log.verbose_error("Failed to allocate package streamers map", package_streamers_allocation_error)
        delete(assets_map)
        mem.collection_destroy(&assets)
        return false
    }

    package_streamers_create_count := 0
    for path in paths
    {
        package_streamer: Package_Streamer
        if !package_streamer_init(&package_streamer, path, stream_allocator, allocator) do break
        package_streamers[package_streamer.package_name] = package_streamer
        package_streamers_create_count += 1
    }

    if package_streamers_create_count != len(paths)
    {
        log.verbose_error("Failed to create all package streamers, created", package_streamers_create_count, "of", len(paths))
        for package_name, &package_streamer in package_streamers do package_streamer_destroy(&package_streamer, allocator)
        delete(package_streamers)
        delete(assets_map)
        mem.collection_destroy(&assets)
        return false
    }

    seek_infos, seek_infos_allocation_error := make_map(map[string]Package_Asset_Seek_Info, len(paths) * 100, allocator)
    if seek_infos_allocation_error != .None
    {
        log.verbose_error("Failed to allocate seek infos map", seek_infos_allocation_error)
        for package_name, &package_streamer in package_streamers do package_streamer_destroy(&package_streamer, allocator)
        delete(package_streamers)
        delete(assets_map)
        mem.collection_destroy(&assets)
        return false
    }

    wait_tasks, wait_tasks_allocation_error := make_dynamic_array_len_cap([dynamic]Wait_Asset_Task, 0, 100, allocator)
    if wait_tasks_allocation_error != .None
    {
        log.verbose_error("Failed to allocate wait task dynamic slice", wait_tasks_allocation_error)
        delete(seek_infos)
        for package_name, &package_streamer in package_streamers do package_streamer_destroy(&package_streamer, allocator)
        delete(package_streamers)
        delete(assets_map)
        mem.collection_destroy(&assets)
        return false
    }

    //Mapping all asset seek infos
    streamer.assets = assets
    streamer.assets_map = assets_map
    streamer.seek_infos = seek_infos
    streamer.package_streamers = package_streamers
    streamer.wait_tasks = wait_tasks
    for package_name, &package_streamer in package_streamers
    {
        if !package_streamer_add_assets_to_load(&package_streamer) do continue
        defer package_streamer_sub_assets_to_load(&package_streamer)
        package_streamer_map_seek_infos(streamer, &package_streamer)
    }
    log.verbose_debug("Intialized streamer for paths", paths)
    return true
}

destroy :: proc(streamer: ^Streamer, allocator := context.allocator) -> bool
{
    if streamer == nil do return false
    for asset_name, asset in streamer.assets_map
    {
        seek_info := streamer.seek_infos[asset_name]
        package_streamer := &streamer.package_streamers[seek_info.package_name]
        delete(asset.data, package_streamer.stream_allocator)
    }
    mem.collection_destroy(&streamer.assets)
    delete(streamer.assets_map)
    streamer.assets_map = nil
    for package_name, &package_streamer in streamer.package_streamers do package_streamer_destroy(&package_streamer, allocator)
    delete(streamer.seek_infos)
    streamer.seek_infos = nil
    delete(streamer.package_streamers)
    streamer.package_streamers = nil
    delete(streamer.wait_tasks)
    streamer.wait_tasks = nil
    return true
}

get :: proc "contextless" (streamer: ^Streamer, asset_name: string) -> ^Asset
{
    if streamer == nil do return nil
    return streamer.assets_map[asset_name]
}

require :: proc(streamer: ^Streamer, pool: ^thread.Pool, asset_name: string, on_loaded: Proc_On_Asset_Loaded = nil, user_data : rawptr = nil, idle_frames := 0) -> bool
{
    if streamer == nil || pool == nil do return false

    sync.mutex_lock(&streamer.mutex)
    defer sync.mutex_unlock(&streamer.mutex)

    seek_info := streamer.seek_infos[asset_name]
    if seek_info.package_name == "" do return false

    package_streamer := &streamer.package_streamers[seek_info.package_name]
    if package_streamer.package_name != seek_info.package_name do return false

    asset := streamer.assets_map[asset_name]
    if asset == nil
    {
        task_data, task_data_error := new(Load_Asset_Task_Data, package_streamer.stream_allocator)
        if task_data_error != .None do return false

        asset := mem.collection_sub_allocate(&streamer.assets)
        if asset == nil
        {
            free(task_data)
            return false
        }
        asset.references = 1
        asset.idle_frames = idle_frames

        streamer.assets_map[asset_name] = asset
        task_data.streamer = streamer
        task_data.asset = asset
        task_data.on_loaded = on_loaded
        task_data.seek_info = streamer.seek_infos[asset_name]
        task_data.user_data = user_data

        package_streamer_add_assets_to_load(package_streamer)
        thread.pool_add_task(pool, package_streamer.stream_allocator, asset_load_task, task_data, LOAD_ASSET_TASK_ID)
        log.verbose_debug("Added task to load asset", asset_name, "of package", seek_info.package_name)
    }
    else
    {
        intrinsics.atomic_add(&asset.references, 1)
        if idle_frames != 0 do intrinsics.atomic_store(&asset.idle_frames, idle_frames)
        if on_loaded == nil do return false //Its wait task but there is no callback
        if asset_is_loaded(asset)
        {
            on_loaded(asset, user_data)
            return true
        }
        if !asset_is_loading(asset) do return false
        append(&streamer.wait_tasks, Wait_Asset_Task{user_data, asset, on_loaded})
        log.verbose_debug("Added wait task for asset", asset_name, "of package", seek_info.package_name)
    }
    return true
}

dispose :: proc(streamer: ^Streamer, asset_name: string, idle_frames := 0) -> bool
{
    if streamer == nil do return false

    sync.mutex_lock(&streamer.mutex)
    defer sync.mutex_unlock(&streamer.mutex)

    seek_info := streamer.seek_infos[asset_name]
    if seek_info.package_name == "" do return false

    package_streamer := &streamer.package_streamers[seek_info.package_name]
    if package_streamer.package_name != seek_info.package_name do return false

    asset := streamer.assets_map[asset_name]
    if asset == nil do return false

    intrinsics.atomic_sub(&asset.references, 1)
    if idle_frames != 0 do intrinsics.atomic_store(&asset.idle_frames, idle_frames)
    return true
}

@(optimization_mode="speed")
frame :: proc(streamer: ^Streamer, pool: ^thread.Pool)
{
    tasks := pool_list(pool, LOAD_ASSET_TASK_ID, context.temp_allocator)
    if tasks != nil do for &task in tasks
    {
        task_data := transmute(^Load_Asset_Task_Data)task.data
        if task_data.on_loaded != nil do task_data.on_loaded(task_data.asset, task_data.user_data)
        free(task_data, task.allocator)
    }

    #reverse for &wt, i in streamer.wait_tasks
    {
        if asset_is_loaded(wt.asset)
        {
            wt.on_loaded(wt.asset, wt.user_data)
            ordered_remove(&streamer.wait_tasks, i)
        }
    }

    for asset_name, asset in streamer.assets_map
    {
        if asset_references(asset) == 0
        {
            if asset_idle_frames(asset) > 0 do intrinsics.atomic_sub(&asset.idle_frames, 1)
            else
            {
                seek_info := streamer.seek_infos[asset_name]
                package_streamer := &streamer.package_streamers[seek_info.package_name]            
                delete(asset.data, package_streamer.stream_allocator)
                asset.data = nil
                mem.collection_free(&streamer.assets, asset)
                delete_key(&streamer.assets_map, asset_name)
                log.verbose_debug("Unloaded asset", asset_name, "of package", seek_info.package_name)
            }
        }
    }
}

asset_load_task :: proc(task: thread.Task)
{
    data := transmute(^Load_Asset_Task_Data)task.data
    package_streamer := &data.streamer.package_streamers[data.seek_info.package_name]
    sync.lock(&package_streamer.mutex)
    defer sync.unlock(&package_streamer.mutex)

    intrinsics.atomic_store(&data.asset.is_loading, true)
    defer intrinsics.atomic_store(&data.asset.is_loading, false)

    asset_data, asset_data_allocation_error := make([]byte, data.seek_info.size, package_streamer.stream_allocator)
    if asset_data_allocation_error != .None do return

    _, seek_error := io.seek(io.to_seeker(package_streamer.stream), i64(data.seek_info.offset), .Start)
    if seek_error != .None do return
    
    _, read_error := io.read_ptr(package_streamer.stream, raw_data(asset_data), len(asset_data))
    if read_error != .None do return
    
    intrinsics.atomic_store(&data.asset.is_loaded, true)
    data.asset.data = asset_data

    package_streamer_sub_assets_to_load(package_streamer)
}