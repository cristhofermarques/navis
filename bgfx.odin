package navis

import "bff"
import "bgfx"
import "core:intrinsics"
import "core:thread"
import "core:strings"
import "core:path/filepath"
import "core:os"
import "core:encoding/json"
import "core:time"
import "core:sync"
import "core:runtime"

On_Load_BGFX_Asset :: proc(^BGFX_Asset, rawptr)

BGFX_Asset_Load_Data :: struct
{
    context_: runtime.Context,
    streamer: ^Streamer,
    bgfx_streamer: ^BGFX_Streamer,
    asset: ^BGFX_Asset,
    on_loaded: On_Load_BGFX_Asset,
    user_data: rawptr,
}

BGFX_Asset_Type :: enum
{
    Shader,
    Program,
    Vertex_Buffer,
    Index_Buffer,
}

BGFX_Asset :: struct
{
    info: Asset_Stream_Info,
    type: BGFX_Asset_Type,
    handle: bgfx.Handle,
    asset_info: struct #raw_union
    {
        vertex_count: struct{vertex_count: u32},
        index_count: struct{index_count: u32},
        program: struct{vs_asset, fs_asset: ^BGFX_Asset}
    }
}

BGFX_Streamer :: struct
{
    assets: Collection(BGFX_Asset),
    assets_map: map[string]^BGFX_Asset,
    job_data_collection: Collection(BGFX_Asset_Load_Data),
}

bgfx_streamer_init :: proc(streamer: ^BGFX_Streamer, assets_chunk_capacity: int, assets_map_initial_capacity: int, allocator := context.allocator) -> bool
{
    assets, created_assets := collection_create(BGFX_Asset, assets_chunk_capacity, 2, allocator)
    if !created_assets
    {
        log_verbose_error("Failed to init bgfx streamer assets collection")
        return false
    }
    
    assets_map, assets_map_allocation_error := make_map(map[string]^BGFX_Asset)
    if assets_map_allocation_error != .None
    {
        log_verbose_error("Failed to make bgfx streamer assets map", assets_map_allocation_error)
        collection_destroy(&assets)
        return false
    }

    job_data_collection, created_job_data_collection := collection_create(BGFX_Asset_Load_Data, assets_chunk_capacity, 2, allocator)
    if !created_job_data_collection
    {
        log_verbose_error("Failed to init bgfx streamer job data collection collection")
        delete(assets_map)
        collection_destroy(&assets)
        return false
    }
    
    streamer.assets = assets
    streamer.assets_map = assets_map
    streamer.job_data_collection = job_data_collection
    return true
}

bgfx_streamer_destroy :: proc(streamer: ^BGFX_Streamer) -> bool
{
    for asset_name, asset in streamer.assets_map
    {
        if asset.type != .Program do continue
        bgfx_asset_destroy(asset)
        delete_key(&streamer.assets_map, asset_name)
        log_verbose_debug("Destroyed bgfx asset", asset_name, "of type", asset.type)
    }

    for asset_name, asset in streamer.assets_map
    {
        bgfx_asset_destroy(asset)
        log_verbose_debug("Destroyed bgfx asset", asset_name, "of type", asset.type)
    }
    delete(streamer.assets_map)
    collection_destroy(&streamer.assets)
    collection_destroy(&streamer.job_data_collection)
    streamer^ = {}
    return true
}

bgfx_streamer_require_asset :: proc(streamer: ^Streamer, bgfx_streamer: ^BGFX_Streamer, asset_name: string, asset_type: BGFX_Asset_Type, idle_frames := 0, on_loaded: On_Load_BGFX_Asset = nil, user_data: rawptr = nil) -> ^BGFX_Asset
{
    if bgfx_asset := bgfx_streamer.assets_map[asset_name]; bgfx_asset != nil
    {
        if bgfx_asset.type != asset_type
        {
            log_verbose_warn("BGFX asset", asset_name, bgfx_asset.type, "is not of type", asset_type)
            return nil
        }

        asset_require(bgfx_asset, idle_frames)
        log_verbose_debug("Added a requirement to bgfx asset", asset_name, "of type", bgfx_asset.type, "current requirements", bgfx_asset.info.requirements)
        return bgfx_asset
    }

    //Loading
    load_data := collection_sub_allocate(&bgfx_streamer.job_data_collection)
    if load_data == nil
    {
        log_verbose_error("Failed to allocate bgfx asset load data")
        return nil
    }

    bgfx_asset := collection_sub_allocate(&bgfx_streamer.assets)
    if bgfx_asset == nil
    {
        log_verbose_error("Failed to sub allocate bgfx asset from collection")
        collection_free(&bgfx_streamer.job_data_collection, load_data)
        return nil
    }
    bgfx_asset^ = BGFX_Asset{{}, asset_type, bgfx.INVALID_HANDLE, {}}
    intrinsics.atomic_store(&bgfx_asset.info.is_loading, true)
    bgfx_streamer.assets_map[asset_name] = bgfx_asset

    asset_require(bgfx_asset, idle_frames)
    load_data.context_ = context
    load_data.asset = bgfx_asset
    load_data.streamer = streamer
    load_data.bgfx_streamer = bgfx_streamer
    load_data.on_loaded = on_loaded
    load_data.user_data = user_data

    /*
    NOTE: for less memory usage, shaders are stored in diferent assets in package.
    This means that shader assets have a profile prefix, but its not required to be passed in 'asset_name' parameter.
    Bellow line do this job, it adds the profile prefix depending on current bgfx renderer type.
    */
    required_asset_name := asset_type == .Shader ? bgfx.shader_profile_prefixed_name(bgfx_get_shader_profile(), asset_name, context.temp_allocator) : asset_name

    if streamer_require_asset(streamer, required_asset_name, auto_cast on_bgfx_asset_loaded, load_data) == nil
    {
        log_verbose_error("Failed to require bgfx asset", asset_name)
        delete_key(&bgfx_streamer.assets_map, asset_name)
        collection_free(&bgfx_streamer.assets, bgfx_asset)
        collection_free(&bgfx_streamer.job_data_collection, load_data)
        return nil
    }

    log_verbose_debug("Requested to load bgfx assset", asset_name, "of type", asset_type)
    return bgfx_asset
}

//TODO: this proc is almost deprected, it can be so useless
bgfx_streamer_dispose_asset :: proc(streamer: ^BGFX_Streamer, asset_name: string, idle_frames := 0) -> bool
{
    asset := streamer.assets_map[asset_name]
    if asset == nil do return false
    asset_dispose(asset, idle_frames)
    return true
}

/* Only for internal usage */
on_bgfx_asset_loaded :: proc(asset: ^Asset, data: ^BGFX_Asset_Load_Data)
{
    context = data.context_
    defer asset_dispose(asset, 4)
    switch data.asset.type
    {
        case .Vertex_Buffer:
        {
            defer intrinsics.atomic_store(&data.asset.info.is_loading, false)
            defer collection_free(&data.bgfx_streamer.job_data_collection, data)

            vb_asset: Vertex_Buffer_Asset
            bff.unmarshal(asset.data, &vb_asset)

            vb_memory := bgfx.make_ref(raw_data(vb_asset.vertices), cast(u32)len(vb_asset.vertices))
            if vb_memory == nil
            {
                log_verbose_error("Failed to make ref of data")
                return
            }

            handle := bgfx.create_vertex_buffer(vb_memory, &vb_asset.layout, {})
            if handle == bgfx.INVALID_HANDLE
            {
                log_verbose_error("Failed to create bgfx vertex buffer")
                return
            }

            data.asset.handle = handle
            intrinsics.atomic_store(&data.asset.info.is_loaded, true)
            log_verbose_error("Created bgfx vertex buffer", handle)
            
            if data.asset.handle != bgfx.INVALID_HANDLE && data.on_loaded != nil do data.on_loaded(data.asset, data.user_data)
            return
        }

        case .Index_Buffer:
        {
            defer intrinsics.atomic_store(&data.asset.info.is_loading, false)
            defer collection_free(&data.bgfx_streamer.job_data_collection, data)

            ib_asset: Index_Buffer_Asset
            bff.unmarshal(asset.data, &ib_asset)

            ib_memory := bgfx.make_ref(raw_data(ib_asset.data), cast(u32)len(ib_asset.data))
            if ib_memory == nil
            {
                log_verbose_error("Failed to make ref of data")
                return
            }

            handle := bgfx.create_index_buffer(ib_memory, ib_asset.is_index32 ? {.Index_32} : {})
            if handle == bgfx.INVALID_HANDLE
            {
                log_verbose_error("Failed to create bgfx index buffer")
                return
            }

            data.asset.handle = handle
            intrinsics.atomic_store(&data.asset.info.is_loaded, true)
            log_verbose_error("Created bgfx index buffer", handle)
            
            if data.asset.handle != bgfx.INVALID_HANDLE && data.on_loaded != nil do data.on_loaded(data.asset, data.user_data)
            return
        }

        case .Shader:
        {
            defer intrinsics.atomic_store(&data.asset.info.is_loading, false)
            defer collection_free(&data.bgfx_streamer.job_data_collection, data)

            shader_memory := bgfx.make_ref(raw_data(asset.data), cast(u32)len(asset.data))
            if shader_memory == nil
            {
                log_verbose_error("Failed to make bgfx memory reference of data for shader")
                return
            }

            handle := bgfx.create_shader(shader_memory)
            if handle == bgfx.INVALID_HANDLE
            {
                log_verbose_error("Failed to create bgfx shader", shader_memory)
                return
            }

            data.asset.handle = handle
            intrinsics.atomic_store(&data.asset.info.is_loaded, true)
            log_verbose_error("Created bgfx shader", handle)
            
            if data.asset.handle != bgfx.INVALID_HANDLE && data.on_loaded != nil do data.on_loaded(data.asset, data.user_data)
            return
        }

        case .Program:
            program_asset: BGFX_Program_Asset
            json.unmarshal(asset.data, &program_asset, json.DEFAULT_SPECIFICATION, context.temp_allocator)//TODO: check error

            data.asset.asset_info.program.vs_asset = bgfx_streamer_require_asset(data.streamer, data.bgfx_streamer, program_asset.vs, .Shader, 0, auto_cast _bgfx_load_program_on_shader_loaded, data)
            if data.asset.asset_info.program.vs_asset == nil
            {
                log_verbose_error("Failed to require bgfx vertex shader asset")
                return
            }

            data.asset.asset_info.program.fs_asset = bgfx_streamer_require_asset(data.streamer, data.bgfx_streamer, program_asset.fs, .Shader, 0, auto_cast _bgfx_load_program_on_shader_loaded, data)
            if data.asset.asset_info.program.fs_asset == nil
            {
                log_verbose_error("Failed to require bgfx fragment shader asset")
                asset_dispose(data.asset.asset_info.program.vs_asset)
                return
            }
            
            //TODO: treat when cant create the asset
            log_verbose_debug("Requested to load shaders VS", program_asset.vs, "and FS", program_asset.fs,  " for program creation")
            return
    }
}

/* Only for internal usage */
_bgfx_load_program_on_shader_loaded :: proc(shader_asset: ^BGFX_Asset, data: ^BGFX_Asset_Load_Data)
{
    @static mutex: sync.Mutex
    sync.lock(&mutex)
    defer sync.unlock(&mutex)

    if asset_is_loaded(data.asset) do return

    vs_asset := data.asset.asset_info.program.vs_asset
    if vs_asset == nil || !asset_is_loaded(vs_asset)
    {
        log_verbose_debug("Cant create program now, vertex shader is not loaded")
        return
    }
    
    fs_asset := data.asset.asset_info.program.fs_asset
    if fs_asset == nil || !asset_is_loaded(fs_asset)
    {
        log_verbose_error("Cant create program, fragment shader is not loaded")
        return
    }
    
    data.asset.handle = bgfx.create_program(vs_asset.handle, fs_asset.handle, false)
    intrinsics.atomic_store(&data.asset.info.is_loaded, data.asset.handle != bgfx.INVALID_HANDLE)
    intrinsics.atomic_store(&data.asset.info.is_loading, false)
    log_verbose_debug("Created bgfx program", data.asset.handle)
    collection_free(&data.bgfx_streamer.job_data_collection, data)
}

bgfx_streamer_frame :: proc(streamer: ^BGFX_Streamer)
{
    //NOTE: programs need to be destroyed before shaders.
    for asset_name, bgfx_asset in streamer.assets_map
    {
        if bgfx_asset.type != .Program do continue
        is_loaded := asset_is_loaded(bgfx_asset)
        is_loading := asset_is_loading(bgfx_asset)

        if is_loaded && asset_frame(bgfx_asset)
        {
            bgfx_asset_destroy(bgfx_asset)
            delete_key(&streamer.assets_map, asset_name)
            collection_free(&streamer.assets, bgfx_asset)
            log_verbose_debug("Destroyed bgfx asset", asset_name, "of type", bgfx_asset.type)
        }
    }

    for asset_name, bgfx_asset in streamer.assets_map
    {
        is_loaded := asset_is_loaded(bgfx_asset)
        is_loading := asset_is_loading(bgfx_asset)

        if is_loaded && asset_frame(bgfx_asset)
        {
            bgfx_asset_destroy(bgfx_asset)
            delete_key(&streamer.assets_map, asset_name)
            collection_free(&streamer.assets, bgfx_asset)
            log_verbose_debug("Destroyed bgfx asset", asset_name, "of type", bgfx_asset.type)
        }

        if !is_loading && !is_loaded
        {
            delete_key(&streamer.assets_map, asset_name)
            collection_free(&streamer.assets, bgfx_asset)
            log_verbose_error("Failed to create bgfx asset", asset_name, "of type", bgfx_asset.type)
        }
    }
}

bgfx_asset_destroy :: proc(asset: ^BGFX_Asset)
{
    switch asset.type
    {
        case .Vertex_Buffer:
            bgfx.destroy_vertex_buffer(asset.handle)
        
        case .Index_Buffer:
            bgfx.destroy_index_buffer(asset.handle)

        case .Shader:
            bgfx.destroy_shader(asset.handle)

        case .Program:
            asset_dispose(asset.asset_info.program.vs_asset)
            asset_dispose(asset.asset_info.program.fs_asset)
            bgfx.destroy_program(asset.handle)
    }
}

bgfx_compile_shader :: proc(input_path, output_directory_path, varyingdef_path: string, type: bgfx.Shader_Type, profiles: bit_set[bgfx.Shader_Profile], as_ignore := false)
{
    shader_name_with_ext := filepath.base(input_path)
    shader_name_ext := filepath.ext(shader_name_with_ext)
    shader_name_ext_index := strings.last_index(shader_name_with_ext, shader_name_ext)
    shader_name := shader_name_with_ext[:shader_name_ext_index]
    shader_asset: Shader_Asset
    if !os.is_dir(output_directory_path) do os.make_directory(output_directory_path)
    for profile in bgfx.Shader_Profile
    {
        is_in := profile in profiles
        if as_ignore ? is_in : !is_in do continue
        profile_flag := bgfx.shader_profile_to_flag(profile, string)
        shader_path, shader_path_allocation_error := strings.concatenate({output_directory_path, "/", profile_flag, "_", shader_name, ".", profile_flag}, context.temp_allocator)
        if shader_path_allocation_error != .None do break
        bgfx.compile_shader(input_path, shader_path, varyingdef_path, type, profile)
        if !os.is_file(shader_path) do break
    }
}

bgfx_get_shader_profile :: proc "contextless" () -> bgfx.Shader_Profile
{
    switch bgfx.get_renderer_type()
    {
        case .No_Op, .AGC, .GNM, .NVM, .WebGPU, .Count: return bgfx.Shader_Profile(0)
        case .Direct3D_9: return .HLSL_S_3_0
        case .Direct3D_11: return .HLSL_S_4_0
        case .Direct3D_12: return .HLSL_S_5_0
        case .Metal: return .Metal
        case .OpenGL_ES: return .GLSL_ES_300
        case .OpenGL: return .GLSL_330
        case .Vulkan: return .Spirv
    }
    return bgfx.Shader_Profile(0)
}