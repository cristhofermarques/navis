package navis

import "core:os"
import "core:io"
import "core:strings"
import "core:runtime"
import "core:intrinsics"
import "core:bytes"
import "core:slice"
import "core:path/filepath"
import "core:thread"
import "core:sync"

/*
Magic text that begins a package.
*/
PACKAGE_MAGIC :: "PKG"

/*
Name of package ignore file.
*/
PACKAGE_IGNORE :: "package_ignore"

ASSET_STREAM_INFO_FIELD_NAME :: "info"

/*
Struct used to stream assets.

Used for:
* Load/Unload asset data.
* Create/Destroy engine resources
*/
Asset_Stream_Info :: struct
{
    is_loading, is_loaded: bool,
    requirements, idle_frames: int,
}

asset_is_loading :: #force_inline proc "contextless" (asset: ^$T) -> bool
where
intrinsics.type_is_struct(T) &&
intrinsics.type_field_type(T, ASSET_STREAM_INFO_FIELD_NAME) == Asset_Stream_Info &&
intrinsics.type_has_field(T, ASSET_STREAM_INFO_FIELD_NAME)
{
    return intrinsics.atomic_load(&asset.info.is_loading)
}

asset_is_loaded :: #force_inline proc "contextless" (asset: ^$T) -> bool
where
intrinsics.type_is_struct(T) &&
intrinsics.type_field_type(T, ASSET_STREAM_INFO_FIELD_NAME) == Asset_Stream_Info &&
intrinsics.type_has_field(T, ASSET_STREAM_INFO_FIELD_NAME)
{
    return intrinsics.atomic_load(&asset.info.is_loaded)
}

asset_requirements :: #force_inline proc "contextless" (asset: ^$T) -> int
where
intrinsics.type_is_struct(T) &&
intrinsics.type_field_type(T, ASSET_STREAM_INFO_FIELD_NAME) == Asset_Stream_Info &&
intrinsics.type_has_field(T, ASSET_STREAM_INFO_FIELD_NAME)
{
    return intrinsics.atomic_load(&asset.info.requirements)
}

asset_idle_frames :: #force_inline proc "contextless" (asset: ^$T) -> int
where
intrinsics.type_is_struct(T) &&
intrinsics.type_field_type(T, ASSET_STREAM_INFO_FIELD_NAME) == Asset_Stream_Info &&
intrinsics.type_has_field(T, ASSET_STREAM_INFO_FIELD_NAME)
{
    return intrinsics.atomic_load(&asset.info.idle_frames)
}

/*
Add one to 'asset.info.requirements'.

Return 'true' if asset need to be loaded.
*/
asset_require :: #force_inline proc "contextless" (asset: ^$T, idle_frames := 0) -> bool
where
intrinsics.type_is_struct(T) &&
intrinsics.type_field_type(T, ASSET_STREAM_INFO_FIELD_NAME) == Asset_Stream_Info &&
intrinsics.type_has_field(T, ASSET_STREAM_INFO_FIELD_NAME)
{
    if asset_requirements(asset) < 0
    {
        intrinsics.atomic_store(&asset.info.requirements, 1)
        return true
    }
    if idle_frames > asset_idle_frames(asset) do intrinsics.atomic_store(&asset.info.idle_frames, idle_frames)
    return intrinsics.atomic_add(&asset.info.requirements, 1) == 1 && !asset_is_loaded(asset)
}

/*
Sub one to 'asset.info.requirements'.
*/
asset_dispose :: #force_inline proc "contextless" (asset: ^$T, idle_frames := 0)
where
intrinsics.type_is_struct(T) &&
intrinsics.type_field_type(T, ASSET_STREAM_INFO_FIELD_NAME) == Asset_Stream_Info &&
intrinsics.type_has_field(T, ASSET_STREAM_INFO_FIELD_NAME)
{
    intrinsics.atomic_sub(&asset.info.requirements, 1)
    if idle_frames > asset_idle_frames(asset) do intrinsics.atomic_store(&asset.info.idle_frames, idle_frames)
}

/*
This is to be called every frame to update the asset.

Return 'true' if asset need to be unloaded.
*/
asset_frame :: #force_inline proc "contextless" (asset: ^$T) -> bool
where
intrinsics.type_is_struct(T) &&
intrinsics.type_field_type(T, ASSET_STREAM_INFO_FIELD_NAME) == Asset_Stream_Info &&
intrinsics.type_has_field(T, ASSET_STREAM_INFO_FIELD_NAME)
{
    if asset_requirements(asset) > 0 do return false
    intrinsics.atomic_sub(&asset.info.idle_frames, 1)
    return asset_idle_frames(asset) <= 0 && asset_is_loaded(asset)
}

/*
Package asset.
*/
Package_Asset :: struct
{
    name: string,
    data: []byte,
}

/*
Package.
*/
Package :: struct
{
    name: string,
    fields: []Package_Asset,
}

/*
Populate a package structure from data.
* The only one allocation made is for the package.fields slice.
*/
package_from_data :: proc(data: []byte, allocator := context.allocator) -> (pkg: Package)
{
    if data == nil do return

    //Magic
    seek := 0
    if strings.compare(transmute(string)data[seek:3], PACKAGE_MAGIC) != 0 do return
    seek += 3

    //Package name length
    package_name_length := (transmute(^int)&data[seek])^
    seek += size_of(int)

    package_name_data := &data[seek]
    seek += package_name_length

    raw_pakage_name: runtime.Raw_String
    raw_pakage_name.len = package_name_length
    raw_pakage_name.data = package_name_data
    
    fields_length := (transmute(^int)&data[seek])^
    seek += size_of(int)

    Package_Field_Info :: struct
    {
        using _field: Package_Asset,
        offset, size: int,
    }

    infos, infos_err := make_slice([]Package_Field_Info, fields_length, context.temp_allocator)
    if infos_err != .None do return
    
    for index := 0; index < fields_length; index += 1
    {
        field_name_length := (transmute(^int)&data[seek])^
        seek += size_of(int)
        
        field_name_data := &data[seek]
        seek += field_name_length
        
        field_data_offset := (transmute(^int)&data[seek])^
        seek += size_of(int)

        field_data_size := (transmute(^int)&data[seek])^
        seek += size_of(int)

        raw_field_name: runtime.Raw_String
        raw_field_name.len = field_name_length
        raw_field_name.data = field_name_data

        field: Package_Field_Info
        field.name = transmute(string)raw_field_name
        field.offset = field_data_offset
        field.size = field_data_size
        infos[index] = field
    }

    for &field in infos
    {
        field_data: runtime.Raw_Slice
        field_data.len = field.size
        field_data.data = &data[seek + field.offset]
        field.data = transmute([]byte)field_data
    }

    fields, fields_err := make_slice([]Package_Asset, fields_length, allocator)
    if fields_err != .None do return
    for &info, i in infos do fields[i] = info._field

    pkg.name = transmute(string)raw_pakage_name
    pkg.fields = fields
    return
}

/*
Return the package name.
* Allocate using the provided allocator
*/
package_name :: proc(stream: io.Stream, allocator := context.allocator) -> string
{
    //Seek to begin
    seeker, _ := io.to_seeker(stream)
    io.seek(seeker, 0, .Start)

    //Magic
    magic: [3]byte
    io.read(stream, magic[:])
    if strings.compare(transmute(string)magic[:], PACKAGE_MAGIC) != 0 do return ""

    //Package name length
    package_name_length := -1
    io.read_ptr(stream, &package_name_length, size_of(int))
    
    //Package name
    package_name, package_name_allocation_error := make([]byte, package_name_length, allocator)
    if package_name_allocation_error != .None do return ""
    io.read(stream, package_name)
    return transmute(string)package_name
}

Packer :: map[string][]byte

packer_init :: proc(pack: ^Packer, intial_capacity := 1, allocator := context.allocator) -> bool
{
    pack_, pack_allocation_error := make_map(Packer, intial_capacity, allocator)
    pack^ = pack_
    return pack_allocation_error == .None
}

packer_destroy :: proc(pack: ^Packer) -> bool
{
    if pack == nil do return false
    delete_map(pack^)
    pack^ = {}
    return true
}

packer_contains :: proc "contextless" (pack: ^Packer, name: string) -> bool
{
    if pack == nil || name == "" do return false
    return pack[name] != nil
}

packer_add :: proc(pack: ^Packer, name: string, content: []byte) -> bool
{
    if pack == nil || name == "" || content == nil || packer_contains(pack, name) do return false
    pack[name] = content
    return true
}

packer_remove :: proc(pack: ^Packer, name: string) -> bool
{
    if pack == nil || name == "" || !packer_contains(pack, name) do return false
    delete_key(pack, name)
    return true
}

pack_packer :: proc(packer: Packer, name: string, stream: io.Stream) -> bool
{
    if packer == nil || len(packer) < 1 do return false
    
    //Package magic
    io.write_string(stream, PACKAGE_MAGIC)

    //Package name
    name_length := len(name)
    io.write_ptr(stream, &name_length, size_of(int))
    io.write_string(stream, name)

    //Fields count
    fields_count := len(packer)
    io.write_ptr(stream, &fields_count, size_of(int))

    offset := 0
    for field_name, &field_data in packer
    {
        //Field name
        field_name_lenth := len(field_name)
        io.write_ptr(stream, &field_name_lenth, size_of(int))
        io.write_string(stream, field_name)

        //Field data info
        io.write_ptr(stream, &offset, size_of(int))

        field_data_size := len(field_data)
        io.write_ptr(stream, &field_data_size, size_of(int))
        
        offset += field_data_size
    }

    for field_name, &field_data in packer
    {
        //Field data
        io.write_ptr(stream, raw_data(field_data), len(field_data))
    }

    return true
}

package_ignore_get_text :: proc(directory_path: string, allocator := context.allocator) -> string
{
    if !os.is_dir(directory_path) do return ""
    ignore_file_path := filepath.join({directory_path, PACKAGE_IGNORE}, context.temp_allocator)
    ignore_buffer, readed := os.read_entire_file_from_filename(ignore_file_path, allocator)
    return transmute(string)ignore_buffer
}

package_ignore_split_text :: proc(ignore_text: string, allocator := context.allocator) -> []string
{
    if ignore_text == "" do return nil
    splits, error := strings.split_lines(ignore_text, allocator)
    return splits
}

package_ignore_can_ignore :: proc(ignore_list: []string, path: string) -> bool
{
    if path == PACKAGE_IGNORE do return true
    if ignore_list == nil do return false
    for ignore in ignore_list do if strings.contains(path, ignore) do return true
    return false
}

@(private)
package_ignore_get_files_recursive :: proc(paths: ^[dynamic]string, ignore_list: []string, path: string, allocator := context.allocator)
{
    if !os.is_dir(path) do return

    dh, dh_err := os.open(path)
    if dh_err != os.ERROR_NONE do return
    defer os.close(dh)

    infos, infos_err := os.read_dir(dh, 0, context.temp_allocator)
    if infos_err != os.ERROR_NONE do return

    for &info in infos
    {
        if info.is_dir
        {
            package_ignore_get_files_recursive(paths, ignore_list, info.fullpath, allocator)
        }
        else if !package_ignore_can_ignore(ignore_list, info.name)
        {
            clone, clone_err := strings.clone(info.fullpath, allocator)
            if clone_err != .None do continue
            append(paths, clone)
        }
    }
}

package_ignore_get_paths :: proc(directory_path: string, allocator := context.allocator) -> []string
{
    if !os.is_dir(directory_path) do return nil

    ignore_text := package_ignore_get_text(directory_path, context.temp_allocator)
    ignore_list := package_ignore_split_text(ignore_text, context.temp_allocator)

    dyn_paths, dyn_paths_err := make([dynamic]string, 0, 100, context.temp_allocator)
    package_ignore_get_files_recursive(&dyn_paths, ignore_list, directory_path, allocator)

    paths, paths_err := make([]string, len(dyn_paths), allocator)
    if paths_err != .None do return nil
    for &p, i in dyn_paths do paths[i] = p
    return paths
}

/*
Pack a directory from provided path.
* If not set a value to 'package_name' parameter, the package name will be the directory name.
*/
package_pack_directory :: proc(directory_path: string, package_name := "", stream: io.Stream) -> bool
{
    if !os.is_dir(directory_path) do return false
    paths := package_ignore_get_paths(directory_path, context.temp_allocator)

    //Package magic
    io.write_string(stream, PACKAGE_MAGIC)
    
    //Package name
    name := package_name != "" ? package_name : filepath.base(directory_path)
    name_length := len(name)
    io.write_ptr(stream, &name_length, size_of(int))
    io.write_string(stream, name)

    //Fields count
    fields_count := len(paths)
    io.write_ptr(stream, &fields_count, size_of(int))

    offset := 0
    for path in paths
    {
        path_base := filepath.base(path)

        //Field name
        field_name := path_base[0:strings.index(path_base, filepath.ext(path_base))]
        field_name_lenth := len(field_name)
        io.write_ptr(stream, &field_name_lenth, size_of(int))
        io.write_string(stream, field_name)

        //Field data info
        io.write_ptr(stream, &offset, size_of(int))

        field_data_size := int(os.file_size_from_path(path))
        io.write_ptr(stream, &field_data_size, size_of(int))
        
        offset += field_data_size
    }

    for path in paths
    {
        //Field data
        field_data, readed_field_data := os.read_entire_file_from_filename(path, context.temp_allocator)
        io.write_ptr(stream, raw_data(field_data), len(field_data))
    }

    return true
}

/*
ID for task that load an asset
*/
LOAD_ASSET_TASK_ID :: 1_001

Proc_On_Asset_Loaded :: proc(^Asset, rawptr)

Streamer_Task_Data :: union
{
    Streamer_Load_Asset_Task_Data,
    Streamer_Wait_Asset_Task_Data,
}

Streamer_Load_Asset_Task_Data :: struct
{
    context_: runtime.Context,
    streamer: ^Streamer,
    asset_info: Package_Asset_Info,
    on_loaded: Proc_On_Asset_Loaded,
    user_data: rawptr,
}

Streamer_Wait_Asset_Task_Data :: struct
{
    streamer: ^Streamer,
    asset: ^Asset,
    on_loaded: Proc_On_Asset_Loaded,
    user_data: rawptr,
    called_on_loaded: bool,
}

//DEP
Load_Asset_Task_Data :: struct
{
    context_: runtime.Context,
    streamer: ^Streamer,
    asset_info: Package_Asset_Info,
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
    info: Asset_Stream_Info,
    data: []byte,
}

Package_Asset_Info :: struct
{
    asset: ^Asset,
    package_name: string,
    offset, size: int,
}

/*
Used internally.
*/
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

Streamer :: struct
{
    mutex: sync.Mutex,
    assets: Collection(Asset),
    task_datas: Collection(Streamer_Task_Data),
    assets_map: map[string]Package_Asset_Info,
    package_streamers: map[string]Package_Streamer,
    stream_allocator: runtime.Allocator,
}

package_streamer_init :: proc(streamer: ^Package_Streamer, path: string, stream_allocator := context.allocator, allocator := context.allocator) -> bool
{
    if streamer == nil
    {
        log_verbose_error("'streamer' parameter is 'nil'")
        return false
    }

    if !os.is_file(path)
    {
        log_error("Invalid package path", path)
        return false
    }

    path_clone, path_clone_allocation_error := strings.clone(path, allocator)
    if path_clone_allocation_error != .None
    {
        log_verbose_error("Failed to clone 'path' parameter", path_clone_allocation_error)
        return false
    }

    streamer.handle = os.INVALID_HANDLE
    streamer.path = path_clone
    if !package_streamer_add_assets_to_load(streamer)
    {
        log_verbose_error("Failed to add dummy assets to load")
        delete(path_clone, allocator)
        return false
    }
    defer package_streamer_sub_assets_to_load(streamer)

    package_name := package_name(streamer.stream, allocator)
    if package_name == ""
    {
        log_verbose_error("Failed to get package name")
        delete(path_clone, allocator)
        return false
    }

    streamer.package_name = package_name
    streamer.stream_allocator = stream_allocator
    log_debug("Initialized streamer for package:", package_name)
    return true
}

package_streamer_destroy :: proc(streamer: ^Package_Streamer, allocator := context.allocator) -> bool
{
    if streamer == nil
    {
        log_verbose_error("'streamer' parameter is 'nil'")
        return false
    }

    if streamer.handle != os.INVALID_HANDLE
    {
        log_verbose_debug("Closed package streamer of package:", streamer.package_name, "path:", streamer.path)
        streamer.handle = os.INVALID_HANDLE
        streamer.stream = {}
    }
    log_debug("Destroyed package streamer of package:", streamer.package_name)
    delete(streamer.package_name, allocator)
    return true
}

/*
Only for internal use.
*/
package_streamer_add_assets_to_load :: proc(streamer: ^Package_Streamer) -> bool
{
    intrinsics.atomic_add(&streamer.assets_to_load, 1)
    if streamer.handle == os.INVALID_HANDLE
    {
        handle, open_error := os.open(streamer.path)
        if open_error != os.ERROR_NONE
        {
            log_verbose_error("Failed to open package streamer from path", streamer.path, "error code:", open_error)
            return false
        }

        streamer.handle =handle
        streamer.stream = os.stream_from_handle(handle)
    }

    log_verbose_debug("Opened package steamer for package:", streamer.package_name, "path:", streamer.path)
    return true
}

/*
Only for internal use.
*/
package_streamer_sub_assets_to_load :: proc(streamer: ^Package_Streamer) -> bool
{
    if streamer == nil do return false
    intrinsics.atomic_sub(&streamer.assets_to_load, 1)
    assets_to_load := intrinsics.atomic_load(&streamer.assets_to_load)
    if assets_to_load <= 0
    {
        if os.close(streamer.handle) == os.ERROR_NONE
        {
            log_verbose_debug("Closed package streamer of package:", streamer.package_name, "path:", streamer.path)
            streamer.handle = os.INVALID_HANDLE
            streamer.stream = {}
            return true
        }
        else
        {
            log_verbose_debug("Failed to close package streamer of package:", streamer.package_name, "path:", streamer.path)
            return false
        }
    }
    return true
}

package_streamer_map_infos :: proc(streamer: ^Streamer, package_streamer: ^Package_Streamer, stream_seek := true) -> bool
{
    //Seek to begin
    seeker, _ := io.to_seeker(package_streamer.stream)
    io.seek(seeker, 0, .Start)

    //Magic
    seek := 0 //NOTE: will be our offset info for data
    magic: [3]byte
    io.read(package_streamer.stream, magic[:])
    if strings.compare(transmute(string)magic[:], PACKAGE_MAGIC) != 0 do return false
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

    Named_Package_Asset_Info :: struct
    {
        name: string,
        info: Package_Asset_Info,
    }

    infos, infos_err := make_slice([]Named_Package_Asset_Info, package_fields_length, context.temp_allocator)
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

        info: Named_Package_Asset_Info
        info.name = transmute(string)field_name
        info.info.offset = field_data_offset
        info.info.size = field_data_size
        infos[index] = info
    }

    for &info in infos do streamer.assets_map[info.name] = Package_Asset_Info{nil, package_streamer.package_name, stream_seek ? seek + info.info.offset : info.info.offset, info.info.size}
    return true
}

/*
Initialize a streamer.
*/
streamer_init :: proc(streamer: ^Streamer, paths: []string, assets_chunk_capacity, assets_map_initial_capacity, wait_tasks_initial_capacity: int, stream_allocator: runtime.Allocator, allocator := context.allocator) -> bool
{
    if streamer == nil || paths == nil do return false

    if assets_chunk_capacity < 1
    {
        log_verbose_error("Invalid asset chunk capacity", assets_chunk_capacity)
        return false
    }

    assets, created_assets := collection_create(Asset, assets_chunk_capacity, 2, allocator)
    if !created_assets
    {
        log_verbose_error("Failed to create assets collection")
        return false
    }

    //TODO: add task datas chunk capacity
    task_datas, created_task_datas := collection_create(Streamer_Task_Data, assets_chunk_capacity, 2, allocator)
    if !created_task_datas
    {
        log_verbose_error("Failed to create assets collection")
        collection_destroy(&assets)
        return false
    }

    assets_map, assets_map_allocation_error := make_map(map[string]Package_Asset_Info, assets_map_initial_capacity, allocator)
    if assets_map_allocation_error != .None
    {
        log_verbose_error("Failed to allocate assets map", assets_map_allocation_error)
        collection_destroy(&task_datas)
        collection_destroy(&assets)
        return false
    }
    
    package_streamers, package_streamers_allocation_error := make_map(map[string]Package_Streamer, len(paths), allocator)
    if package_streamers_allocation_error != .None
    {
        log_verbose_error("Failed to allocate package streamers map", package_streamers_allocation_error)
        delete(assets_map)
        collection_destroy(&task_datas)
        collection_destroy(&assets)
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
        log_verbose_error("Failed to create all package streamers, created", package_streamers_create_count, "of", len(paths))
        for package_name, &package_streamer in package_streamers do package_streamer_destroy(&package_streamer, allocator)
        delete(package_streamers)
        delete(assets_map)
        collection_destroy(&task_datas)
        collection_destroy(&assets)
        return false
    }

    // wait_tasks, wait_tasks_allocation_error := make_dynamic_array_len_cap([dynamic]Wait_Asset_Task, 0, 100, allocator)
    // if wait_tasks_allocation_error != .None
    // {
    //     log_verbose_error("Failed to allocate wait task dynamic slice", wait_tasks_allocation_error)
    //     for package_name, &package_streamer in package_streamers do package_streamer_destroy(&package_streamer, allocator)
    //     delete(package_streamers)
    //     delete(assets_map)
    //     collection_destroy(&task_datas)
    //     collection_destroy(&assets)
    //     return false
    // }

    //Mapping all asset seek infos
    streamer.assets = assets
    streamer.task_datas = task_datas
    streamer.assets_map = assets_map
    streamer.package_streamers = package_streamers
    streamer.stream_allocator = stream_allocator
    for package_name, &package_streamer in package_streamers
    {
        if !package_streamer_add_assets_to_load(&package_streamer) do continue
        defer package_streamer_sub_assets_to_load(&package_streamer)
        package_streamer_map_infos(streamer, &package_streamer)
    }
    log_debug("Intialized streamer for paths", paths)
    return true
}

streamer_destroy :: proc(streamer: ^Streamer, allocator := context.allocator) -> bool
{
    if streamer == nil do return false
    collection_destroy(&streamer.task_datas)
    for asset_name, asset in streamer.assets_map
    {
        if asset.asset == nil || asset.asset.data == nil do continue
        package_streamer := &streamer.package_streamers[asset.package_name]
        delete(asset.asset.data, package_streamer.stream_allocator)
    }
    collection_destroy(&streamer.assets)
    delete(streamer.assets_map)
    streamer.assets_map = nil
    for package_name, &package_streamer in streamer.package_streamers do package_streamer_destroy(&package_streamer, allocator)
    delete(streamer.package_streamers)
    streamer.package_streamers = nil
    log_debug("Destroyed streamer")
    return true
}

streamer_require_asset :: proc(streamer: ^Streamer, pool: ^thread.Pool, asset_name: string, on_loaded: Proc_On_Asset_Loaded = nil, user_data : rawptr = nil, idle_frames := 0) -> ^Asset
{
    sync.mutex_lock(&streamer.mutex)
    defer sync.mutex_unlock(&streamer.mutex)

    asset_info := streamer.assets_map[asset_name]
    if asset_info.package_name == "" do return nil

    if asset := asset_info.asset; asset != nil
    {
        asset_require(asset, idle_frames)
        log_verbose_debug("Added requirement to asset", asset_name)
        if on_loaded == nil do return asset

        if asset_is_loaded(asset)
        {
            log_verbose_debug("Calling on loaded callback, asset", asset_name, "is already loaded")
            on_loaded(asset, user_data)
            return asset
        }
        
        if asset_is_loading(asset)
        {
            log_verbose_debug("Asset", asset_name, "is loading, adding a wait task")
            wait_asset_task_data: ^Streamer_Task_Data = collection_sub_allocate(&streamer.task_datas)
            if wait_asset_task_data == nil
            {
                return nil
            }
            wait_asset_task_data^ = Streamer_Wait_Asset_Task_Data{streamer, asset, on_loaded, user_data, false}
            return asset
        }
    }

    //Loading
    package_streamer := &streamer.package_streamers[asset_info.package_name]
    if package_streamer.package_name != asset_info.package_name do return nil

    load_task_data := collection_sub_allocate(&streamer.task_datas)
    if load_task_data == nil
    {
        log_verbose_error("Failed to sub allocate asset load task data from collection")
        return nil
    }
    
    asset := collection_sub_allocate(&streamer.assets)
    if asset == nil
    {
        log_verbose_error("Failed to sub allocate asset from collection")
        collection_free(&streamer.task_datas, load_task_data)
        return asset
    }
    asset^ = {}
    asset_info.asset = asset
    streamer.assets_map[asset_name] = asset_info
    
    asset_require(asset, idle_frames)
    load_task_data^ = Streamer_Load_Asset_Task_Data{context, streamer, asset_info, on_loaded, user_data}

    sync.lock(&package_streamer.mutex)
    defer sync.unlock(&package_streamer.mutex)

    package_streamer_add_assets_to_load(package_streamer)
    pool_add_task(pool, package_streamer.stream_allocator, _asset_load_task, load_task_data, Task_ID.Load_Asset)
    log_verbose_debug("Added task to load asset", asset_name, "of package", asset_info.package_name)
    return asset
}

streamer_dispose :: proc(streamer: ^Streamer, asset_name: string, idle_frames := 0) -> bool
{
    if streamer == nil do return false

    sync.mutex_lock(&streamer.mutex)
    defer sync.mutex_unlock(&streamer.mutex)

    info := streamer.assets_map[asset_name]
    if info.package_name == "" do return false

    package_streamer := &streamer.package_streamers[info.package_name]
    if package_streamer.package_name != info.package_name do return false

    asset := info.asset
    if asset == nil do return false

    asset_dispose(asset, idle_frames)
    return true
}

streamer_frame :: proc(streamer: ^Streamer, pool: ^thread.Pool)
{
    //Removing done asset load tasks, and adding callback tasks
    load_tasks := pool_list(pool, .Load_Asset, context.temp_allocator)
    if load_tasks != nil do for &task in load_tasks
    {
        task_data := transmute(^Streamer_Load_Asset_Task_Data)task.data
        package_streamer := &task_data.streamer.package_streamers[task_data.asset_info.package_name]
        package_streamer_sub_assets_to_load(package_streamer)
        if task_data.on_loaded != nil do pool_add_task(pool, context.allocator, _asset_load_callback_task, task_data, .Load_Asset_Callback)
        else do collection_free(&streamer.task_datas, transmute(^Streamer_Task_Data)task.data)
        fmt.println("Sending")
        //TODO: log debug
    }

    //Just removing asset load callback tasks
    load_callback_tasks := pool_list(pool, .Load_Asset_Callback, context.temp_allocator)
    if load_callback_tasks != nil do for &task in load_callback_tasks
    {
        collection_free(&streamer.task_datas, transmute(^Streamer_Task_Data)task.data)
        fmt.println("Callback")
        //TODO: log debug
    }
    
    //Wait tasks
    wait_task_iterations := 0
    for &chunk in streamer.task_datas.chunks
    {
        chunk_wait_task_iterations := 0
        for &task_data in chunk.slots
        {
            if !task_data.used do continue
            switch &_task_data in task_data.data
            {
                case Streamer_Load_Asset_Task_Data: continue
                case Streamer_Wait_Asset_Task_Data:
                    is_loading := asset_is_loading(_task_data.asset)
                    is_loaded := asset_is_loaded(_task_data.asset)
                    if !_task_data.called_on_loaded
                    {
                        _task_data.called_on_loaded = true
                        pool_add_task(pool, context.allocator, _asset_wait_callback_task, &_task_data, .Wait_Asset_Callback)
                    }
            }
            chunk_wait_task_iterations += 1
            if chunk_wait_task_iterations == chunk.sub_allocations do break
        }
        wait_task_iterations += chunk_wait_task_iterations
        if wait_task_iterations == streamer.task_datas.sub_allocations do break
    }

    //Just removing done asset wait callback tasks
    wait_callback_tasks := pool_list(pool, .Wait_Asset_Callback, context.temp_allocator)
    if wait_callback_tasks != nil do for &task in wait_callback_tasks
    {
        collection_free(&streamer.task_datas, transmute(^Streamer_Task_Data)task.data)
        fmt.println("Wait Callback")
        //TODO: log debug
    }
    
    for asset_name, &asset_info in streamer.assets_map
    {
        if asset_info.asset == nil do continue
        if !asset_is_loaded(asset_info.asset) do continue
        if !asset_frame(asset_info.asset) do continue
        package_streamer := &streamer.package_streamers[asset_info.package_name]
        delete(asset_info.asset.data, package_streamer.stream_allocator)
        asset_info.asset.data = nil
        collection_free(&streamer.assets, asset_info.asset)
        asset_info.asset = nil
        log_verbose_debug("Unloaded asset", asset_name, "of package", asset_info.package_name)
    }
}

streamer_load_asset :: proc(streamer: ^Streamer, asset_name: string, idle_frames := 0) -> ^Asset
{
    if streamer == nil do return nil
    sync.mutex_lock(&streamer.mutex)
    defer sync.mutex_unlock(&streamer.mutex)

    info := streamer.assets_map[asset_name]
    if info.package_name == "" do return nil
    if info.asset != nil && (asset_is_loading(info.asset) || asset_is_loaded(info.asset))
    {
        asset_require(info.asset, idle_frames)
        return info.asset
    }

    asset := collection_sub_allocate(&streamer.assets)
    if asset == nil
    {
        //TODO: log error
        return nil
    }
    asset^ = {}
    
    asset_require(asset, idle_frames)
    info.asset = asset
    streamer.assets_map[asset_name] = info
    
    //Loading
    package_streamer := &streamer.package_streamers[info.package_name]
    if package_streamer.package_name != info.package_name
    {
        collection_free(&streamer.assets, asset)
        return nil
    }

    sync.lock(&package_streamer.mutex)
    defer sync.unlock(&package_streamer.mutex)

    package_streamer_add_assets_to_load(package_streamer)
    defer package_streamer_sub_assets_to_load(package_streamer)

    intrinsics.atomic_store(&asset.info.is_loading, true)
    defer intrinsics.atomic_store(&asset.info.is_loading, false)

    asset_data, asset_data_allocation_error := make([]byte, info.size, package_streamer.stream_allocator)
    if asset_data_allocation_error != .None
    {
        collection_free(&streamer.assets, asset)
        return nil
    }

    _, seek_error := io.seek(io.to_seeker(package_streamer.stream), i64(info.offset), .Start)
    if seek_error != .None
    {
        collection_free(&streamer.assets, asset)
        return nil
    }
    
    _, read_error := io.read_ptr(package_streamer.stream, raw_data(asset_data), len(asset_data))
    if read_error != .None
    {
        collection_free(&streamer.assets, asset)
        return nil
    }
    
    intrinsics.atomic_store(&asset.info.is_loaded, true)
    asset.data = asset_data
    log_verbose_debug("Loaded asset", asset_name, "of package", info.package_name)
    return asset
}

/*
Procedure that do the job of loading asset using IO.
*/
_asset_load_task :: proc(task: thread.Task)
{
    data := transmute(^Streamer_Load_Asset_Task_Data)task.data
    context = data.context_
    package_streamer := &data.streamer.package_streamers[data.asset_info.package_name]
    
    sync.lock(&package_streamer.mutex)
    defer sync.unlock(&package_streamer.mutex)

    asset := data.asset_info.asset
    intrinsics.atomic_store(&asset.info.is_loading, true)
    defer intrinsics.atomic_store(&asset.info.is_loading, false)

    asset_data, asset_data_allocation_error := make([]byte, data.asset_info.size, package_streamer.stream_allocator)
    if asset_data_allocation_error != .None do return

    _, seek_error := io.seek(io.to_seeker(package_streamer.stream), i64(data.asset_info.offset), .Start)
    if seek_error != .None do return //TODO: log error
    
    _, read_error := io.read_ptr(package_streamer.stream, raw_data(asset_data), len(asset_data))
    if read_error != .None do return //TODO: log error
    
    intrinsics.atomic_store(&asset.info.is_loaded, true)
    asset.data = asset_data
}

/*
Procedure that do the job of calling the callback function when asset is loaded.
*/
_asset_load_callback_task :: proc(task: thread.Task)
{
    data := transmute(^Streamer_Load_Asset_Task_Data)task.data
    fmt.println("Asset load Callback")
    data.on_loaded(data.asset_info.asset, data.user_data)
}
import "core:fmt"
/*
Procedure that do the job of calling the callback function when asset is loaded for wait tasks.
*/
_asset_wait_callback_task :: proc(task: thread.Task)
{
    data := transmute(^Wait_Asset_Task)task.data
    data.on_loaded(data.asset, data.user_data)
}