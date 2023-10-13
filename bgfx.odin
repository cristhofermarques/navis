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

On_Load_BGFX_Asset :: proc(^BGFX_Asset, rawptr)

BGFX_Asset_Load_Data :: struct
{
    streamer: ^Streamer,
    bgfx_streamer: ^BGFX_Streamer,
    pool: ^thread.Pool,
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
    asset: union
    {
        BGFX_Vertex_Buffer,
        BGFX_Index_Buffer,
        BGFX_Shader,
        BGFX_Program,
    },

    //DEPRECTED
    type: BGFX_Asset_Type,
    handle: bgfx.Handle,
}

BGFX_Vertex_Buffer :: struct
{
    handle: bgfx.Vertex_Buffer_Handle,
    vertex_count: u32,
}

BGFX_Index_Buffer :: struct
{
    handle: bgfx.Index_Buffer_Handle,
    index_count: u32,
}

BGFX_Shader :: struct
{
    handle: bgfx.Shader_Handle,
}

BGFX_Program :: struct
{
    handle: bgfx.Program_Handle,
}

BGFX_Streamer :: struct
{
    assets: Collection(BGFX_Asset),
    assets_map: map[string]^BGFX_Asset,
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

    streamer.assets = assets
    streamer.assets_map = assets_map
    return true
}

bgfx_streamer_destroy :: proc(streamer: ^BGFX_Streamer) -> bool
{
    for asset_name, asset in streamer.assets_map
    {
        if asset.type != .Program do continue
        bgfx_asset_destroy(asset)
        delete_key(&streamer.assets_map, asset_name)
        log_verbose_debug("Destroyed bgfx asset:", asset_name, "type:", asset.type, "1st")
    }

    for asset_name, asset in streamer.assets_map
    {
        bgfx_asset_destroy(asset)
        log_verbose_debug("Destroyed bgfx asset:", asset_name, "type:", asset.type)
    }
    delete(streamer.assets_map)
    collection_destroy(&streamer.assets)
    streamer^ = {}
    return true
}

bgfx_streamer_require_asset :: proc(streamer: ^Streamer, bgfx_streamer: ^BGFX_Streamer, pool: ^thread.Pool, asset_name: string, asset_type: BGFX_Asset_Type, idle_frames := 0, on_loaded: On_Load_BGFX_Asset = nil, user_data: rawptr = nil) -> bool
{
    if asset := bgfx_streamer.assets_map[asset_name]; asset != nil
    {
        bgfx_asset := asset
        if bgfx_asset.type != asset_type do return false //TODO: log verbose error
        asset_require(bgfx_asset, idle_frames)
        log_verbose_debug("Added a requirement to bgfx asset:", asset_name, "type:", bgfx_asset.type)
        return true
    }

    asset := collection_sub_allocate(&bgfx_streamer.assets)
    if asset == nil
    {
        log_verbose_error("Failed to sub allocate from bgfx assets collection")
        return false
    }
    //DEPRECTED
    asset^ = {}
    asset.type = asset_type
    asset.handle = bgfx.INVALID_HANDLE

    data, data_allocation_error := new(BGFX_Asset_Load_Data, context.allocator)
    if data_allocation_error != .None
    {
        log_verbose_error("Failed to allocate bgfx asset load data", data_allocation_error)
        collection_free(&bgfx_streamer.assets, asset)
        return false
    }
    
    asset_require(asset, idle_frames)
    bgfx_streamer.assets_map[asset_name] = asset
    data.streamer = streamer
    data.bgfx_streamer = bgfx_streamer
    data.pool = pool
    data.asset = asset
    data.on_loaded = on_loaded
    data.user_data = user_data

    intrinsics.atomic_store(&data.asset.info.is_loading, true)
    required_asset_name := asset_type == .Shader ? bgfx.shader_profile_prefixed_name(bgfx_get_shader_profile(), asset_name, context.temp_allocator) : asset_name
    if !streamer_require(streamer, pool, required_asset_name, auto_cast on_bgfx_asset_loaded, data, 2)
    {
        log_verbose_error("Failed to require bgfx asset:", asset_name)
        delete_key(&bgfx_streamer.assets_map, asset_name)
        collection_free(&bgfx_streamer.assets, asset)
        free(data, context.allocator)
        return false
    }

    log_verbose_debug("Requested to load bgfx assset:", asset_name, "type:", asset_type)
    return true
}

bgfx_streamer_dispose_asset :: proc(streamer: ^BGFX_Streamer, asset_name: string, idle_frames := 0) -> bool
{
    asset := streamer.assets_map[asset_name]
    if asset == nil do return false
    asset_dispose(asset, idle_frames)
    return true
}

on_bgfx_asset_loaded :: proc(asset: ^Asset, data: ^BGFX_Asset_Load_Data)
{
    defer asset_dispose(asset, 3)
    switch data.asset.type
    {
        case .Vertex_Buffer:
            vb_asset: Vertex_Buffer_Asset
            bff.unmarshal(asset.data, &vb_asset)
            vb_mem := bgfx.make_ref(raw_data(vb_asset.vertices), cast(u32)len(vb_asset.vertices))
            data.asset.handle = bgfx.create_vertex_buffer(vb_mem, &vb_asset.layout, {})
            intrinsics.atomic_store(&data.asset.info.is_loading, false)
            intrinsics.atomic_store(&data.asset.info.is_loaded, true)
            if data.asset.handle != bgfx.INVALID_HANDLE && data.on_loaded != nil do data.on_loaded(data.asset, data.user_data)
            return

        case .Index_Buffer:
            ib_asset: Index_Buffer_Asset
            bff.unmarshal(asset.data, &ib_asset)
            ib_mem := bgfx.make_ref(raw_data(ib_asset.data), cast(u32)len(ib_asset.data))
            data.asset.handle = bgfx.create_index_buffer(ib_mem, ib_asset.is_index32 ? {.Index_32} : {})
            intrinsics.atomic_store(&data.asset.info.is_loading, false)
            intrinsics.atomic_store(&data.asset.info.is_loaded, true)
            if data.asset.handle != bgfx.INVALID_HANDLE && data.on_loaded != nil do data.on_loaded(data.asset, data.user_data)
            return

        case .Shader:
            shader_memory := bgfx.make_ref(raw_data(asset.data), cast(u32)len(asset.data))
            if shader_memory == nil do return
            data.asset.handle = bgfx.create_shader(shader_memory)
            intrinsics.atomic_store(&data.asset.info.is_loading, false)
            intrinsics.atomic_store(&data.asset.info.is_loaded, true)
            if data.asset.handle != bgfx.INVALID_HANDLE && data.on_loaded != nil do data.on_loaded(data.asset, data.user_data)
            return

        case .Program:
            program_asset: BGFX_Program_Asset
            json.unmarshal(asset.data, &program_asset, json.DEFAULT_SPECIFICATION, context.temp_allocator)//TODO: check error
            pg_data, pg_data_err := new(BGFX_Load_Program_Data, data.streamer.stream_allocator)
            if pg_data_err != .None do return
            pg_data.streamer = data.streamer
            pg_data.program_asset = data.asset
            if !bgfx_streamer_require_asset(data.streamer, data.bgfx_streamer, data.pool, program_asset.vs, .Shader, 2, auto_cast bgfx_load_program_on_vs_shader_loaded, pg_data)
            {
                //TODO: log error
                log_verbose_error("Failed to require bgfx vertex shader asset")
                free(pg_data, data.streamer.stream_allocator)
                return
            }
            if !bgfx_streamer_require_asset(data.streamer, data.bgfx_streamer, data.pool, program_asset.fs, .Shader, 2, auto_cast bgfx_load_program_on_fs_shader_loaded, pg_data)
            {
                //TODO: log error
                log_verbose_error("Failed to require bgfx fragment shader asset")
                free(pg_data, data.streamer.stream_allocator)
                return
            }
            return
    }
}

BGFX_Load_Program_Data :: struct
{
    streamer: ^Streamer,
    program_asset,
    vs_asset, fs_asset: ^BGFX_Asset,
}

bgfx_load_program_on_vs_shader_loaded :: proc(asset: ^BGFX_Asset, data: ^BGFX_Load_Program_Data)
{
    data.vs_asset = asset
    for data.fs_asset == nil || !asset_is_loaded(data.fs_asset) do return
    data.program_asset.handle = bgfx.create_program(data.vs_asset.handle, data.fs_asset.handle, false)
    intrinsics.atomic_store(&data.program_asset.info.is_loading, false)
    intrinsics.atomic_store(&data.program_asset.info.is_loaded, data.program_asset.handle != bgfx.INVALID_HANDLE)
    allocator := data.streamer.stream_allocator
    free(data, allocator)
    log_verbose_debug("Loaded some bgfx program from vertex shader callback")
}

bgfx_load_program_on_fs_shader_loaded :: proc(asset: ^BGFX_Asset, data: ^BGFX_Load_Program_Data)
{
    data.fs_asset = asset
    for data.vs_asset == nil || !asset_is_loaded(data.vs_asset) do return
    data.program_asset.handle = bgfx.create_program(data.vs_asset.handle, data.fs_asset.handle, false)
    intrinsics.atomic_store(&data.program_asset.info.is_loading, false)
    intrinsics.atomic_store(&data.program_asset.info.is_loaded, data.program_asset.handle != bgfx.INVALID_HANDLE)
    allocator := data.streamer.stream_allocator
    free(data, allocator)
    log_verbose_debug("Loaded some bgfx program from fragment shader callback")
}

bgfx_streamer_frame :: proc(streamer: ^BGFX_Streamer)
{
    for asset_name, asset in streamer.assets_map
    {
        if !asset_frame(asset) do continue
        bgfx_asset_destroy(asset)
        delete_key(&streamer.assets_map, asset_name)
        collection_free(&streamer.assets, asset)
        log_verbose_debug("Destroyed bgfx asset:", asset_name, "type:", asset.type)
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