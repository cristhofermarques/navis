package navis

import "bgfx"
import "mem"
import "pkg"
import "log"
import "core:thread"
import "core:runtime"
import "core:intrinsics"

Renderer_Descriptor :: struct
{
    shaders_chunk_capacity,
    shaders_map_initial_capacity: int,
    renderer_type: bgfx.Renderer_Type,
    vsync: bool,
}

Renderer :: struct
{
    allocator: runtime.Allocator,
    status: Renderer_Status,
    view: Renderer_View,
    scene: ^Scene,
    shaders: mem.Collection(Shader),
    shaders_map: map[string]^Shader,
}

Renderer_Status :: struct
{
    frame_count: uint,
}

Renderer_View_Clear :: struct
{
    flags: bgfx.Clear_Flags,
    color: bgfx.Color_ABGR,
    depth: f32,
    stencil: u8,
}

Renderer_View_Rect_Size_By :: enum
{
    Ratio,
    Custom,
}

Renderer_View_Rect :: struct
{
    size_by: Renderer_View_Rect_Size_By,
    ratio: bgfx.Backbuffer_Ratio,
    rect: Rect(u16),
}

Renderer_View :: struct
{
    id: bgfx.View_ID,
    clear: Renderer_View_Clear,
    rect: Renderer_View_Rect,
}

when IMPLEMENTATION
{
    import "vendor:glfw"

    renderer_init :: proc(renderer: ^Renderer, window: ^Window, descriptor: ^Renderer_Descriptor, allocator := context.allocator) -> bool
    {
        if renderer == nil
        {
            log.verbose_error("'renderer' parameter is 'nil'")
            return false
        }

        if !window_is_valid(window)
        {
            log.verbose_error("invalid 'window'")
            return false
        }
        
        if descriptor == nil
        {
            log.verbose_error("'descriptor' parameter is 'nil'")
            return false
        }

        
        init: bgfx.Init
        bgfx.init_ctor(&init)
        
        window_size := window_get_size(window)
        init.type = descriptor.renderer_type
        init.resolution.width = cast(u32)window_size.x
        init.resolution.height = cast(u32)window_size.y
        init.resolution.reset = descriptor.vsync ?  .VSync : .None

        when ODIN_OS == .Windows
        {
            init.platform_data.nwh = glfw.GetWin32Window(window.handle)
        }

        if !bgfx.init(&init)
        {
            log.error("failed to init bgfx")
            return false
        }

        shaders, created_shaders := mem.collection_create(Shader, descriptor.shaders_chunk_capacity, 2, allocator)
        if !created_shaders
        {
            log.error("failed to init shaders collection")
            bgfx.shutdown()
            return false
        }

        shaders_map, shaders_map_allocation_error := make_map(map[string]^Shader, descriptor.shaders_map_initial_capacity, allocator)
        if shaders_map_allocation_error != .None
        {
            log.error("failed to make shaders map", shaders_map_allocation_error)
            mem.collection_destroy(&shaders)
            bgfx.shutdown()
            return false
        }

        renderer.allocator = allocator
        renderer.shaders = shaders
        renderer.shaders_map = shaders_map
        log.verbose_debug("renderer initialized")
        return true
    }

    renderer_destroy :: proc(renderer: ^Renderer) -> bool
    {
        if renderer == nil
        {
            log.verbose_error("'renderer' parameter is 'nil'")
            return false
        }

        for shader_name, shader in renderer.shaders_map
        {
            shader_destroy(shader, renderer.allocator)
            log.debug("shader", shader_name, "destroyed")
        }
        delete(renderer.shaders_map)
        mem.collection_destroy(&renderer.shaders)
        bgfx.shutdown()
        log.verbose_debug("renderer destroyed")
        return true
    }

    renderer_update :: proc(renderer: ^Renderer)
    {
        if renderer == nil do return

        bgfx.touch(renderer.view.id)
   
        bgfx.frame(false)

        renderer.status.frame_count += 1
    }

    renderer_frame :: proc(renderer: ^Renderer)
    {
        bgfx.touch(renderer.view.id)
        bgfx.frame(false)
        renderer.status.frame_count += 1

        for shader_name, shader in renderer.shaders_map
        {
            if shader.references == 0
            {
                if shader.idle_frames > 0 do intrinsics.atomic_sub(&shader.idle_frames, 1)
                else
                {
                    shader_destroy(shader, renderer.allocator)
                    mem.collection_free(&renderer.shaders, shader)
                    delete_key(&renderer.shaders_map, shader_name)
                    log.verbose_debug("destroyed shader", shader_name, "by idle frames")
                }
            }
        }
    }

    @(export=EXPORT, link_prefix=PREFIX)
    renderer_refresh_uncached :: proc "contextless" (renderer: ^Renderer)
    {
        if renderer == nil do return

        //Refresh view clear
        bgfx.set_view_clear(renderer.view.id, renderer.view.clear.flags, renderer.view.clear.color,renderer.view.clear.depth, renderer.view.clear.stencil)

        //Refresh view rect
        switch renderer.view.rect.size_by
        {
            case .Ratio:
                bgfx.set_view_rect_ratio(renderer.view.id, renderer.view.rect.rect.x, renderer.view.rect.rect.y, renderer.view.rect.ratio)
                
            case .Custom:
                bgfx.set_view_rect(renderer.view.id, renderer.view.rect.rect.x, renderer.view.rect.rect.y, renderer.view.rect.rect.width, renderer.view.rect.rect.height)
        }
    }

    // @(export=EXPORT, link_prefix=PREFIX)
    // renderer_require_shader :: proc(renderer: ^Renderer, streamer: ^pkg.Streamer, pool: ^thread.Pool, package_name, asset_name: string, idle_frames := 0) -> bool
    // {
    //     if renderer == nil
    //     {
    //         log.verbose_error("'renderer' parameter is 'nil'")
    //         return false
    //     }
        
    //     if asset := renderer.shaders_map[asset_name]; asset != nil
    //     {
    //         log.verbose_error("already exists shader, added a reference", asset_name)
    //         intrinsics.atomic_add(&asset.references, 1)
    //         if idle_frames != 0 do intrinsics.atomic_store(&asset.idle_frames, idle_frames)
    //         return false
    //     }

    //     shader := mem.collection_sub_allocate(&renderer.shaders)
    //     if shader == nil
    //     {
    //         log.verbose_error("failed to suballocate from shaders collection")
    //         return false
    //     }

    //     data, data_allocation_error := new(On_Shader_Asset_Loaded_Data, renderer.allocator)
    //     if data_allocation_error != .None
    //     {
    //         log.verbose_error("failed to allocate shader asset load data", data_allocation_error)
    //         mem.collection_free(&renderer.shaders, shader)
    //         return false
    //     }
        
    //     shader.references = 1
    //     shader.idle_frames = idle_frames
    //     renderer.shaders_map[asset_name] = shader
    //     data.assset_name = asset_name
    //     data.renderer = renderer
    //     data.shader = shader
    //     if !pkg.require(streamer, pool, package_name, asset_name, auto_cast on_shader_asset_loaded, data, 2, renderer.allocator)
    //     {
    //         log.verbose_error("failed to require shader asset", asset_name, "on package", package_name)
    //         mem.collection_free(&renderer.shaders, shader)
    //         free(data, renderer.allocator)
    //         return false
    //     }

    //     log.verbose_debug("requested to load shader assset", asset_name, "on package", package_name)
    //     return true
    // }

    // On_Shader_Asset_Loaded_Data :: struct
    // {
    //     assset_name: string,
    //     renderer: ^Renderer,
    //     shader: ^Shader,
    // }

    // on_shader_asset_loaded :: proc(asset: ^pkg.Asset, data: ^On_Shader_Asset_Loaded_Data)
    // {
    //     shader_asset := shader_asset_create_from_bff(asset.data)
    //     shader, created_shader := shader_create_from_asset(&shader_asset, data.renderer.allocator)
    //     if !created_shader
    //     {
    //         log.verbose_error("failed to create shader", data.assset_name, "from asset")
    //         return
    //     }

    //     data.shader.uniforms = shader.uniforms
    //     data.shader.program = shader.program
    //     free(data, data.renderer.allocator)
    //     log.verbose_debug("created shader", data.assset_name, "from asset", data.shader)
    // }
}