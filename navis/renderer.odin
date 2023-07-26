package navis

import "bgfx"

Renderer_Descriptor :: struct
{
    renderer_type: bgfx.Renderer_Type,
    vsync: bool,
}

Renderer :: struct
{
    status: Renderer_Status,
    view: Renderer_View,
    scene: ^Scene,

    //Test
    shader: Shader,
    mesh: Mesh,
    vlh: bgfx.Vertex_Layout_Handle,
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

verts := []f32{
    -0.5, -0.5, 0,
    0.5, -0.5, 0,
    -0.5, 0.5, 0,
    0.5, 0.5, 0,
}


idxs := []u16{
    0, 2, 3,
    0, 3, 1,
}

when IMPLEMENTATION
{
    import "vendor:glfw"

    renderer_create_from_descriptor :: proc(descriptor: ^Renderer_Descriptor, window: ^Window) -> (Renderer, bool) #optional_ok
    {
        if descriptor == nil
        {
            return {}, false
        }
        
        if !window_is_valid(window)
        {
            return {}, false
        }

        window_size := window_get_size(window)

        init: bgfx.Init
        bgfx.init_ctor(&init)

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
            return {}, false
        }

        //Making renderer
        renderer: Renderer

        shader_data, sd_s := os.read_entire_file("editor/package/.shaders/cubes.json", context.temp_allocator)
        asset := new(Shader_Asset, context.temp_allocator)
        json.unmarshal(shader_data, asset, allocator = context.temp_allocator)
    
        shader, suc := shader_create_from_asset(asset)
        renderer.shader = shader

        vl: bgfx.Vertex_Layout
        bgfx.vertex_layout_begin(&vl, bgfx.get_renderer_type())
        bgfx.vertex_layout_add(&vl, .Position, 3, .F32, false, false)
        bgfx.vertex_layout_end(&vl)

        vh := bgfx.make_ref(raw_data(verts), u32(size_of(f32) * len(verts)))
        ih := bgfx.make_ref(raw_data(idxs), u32(size_of(u16) * len(idxs)))

        md: Mesh_Descriptor
        md.layout = &vl
        md.vertex.memory = vh
        md.index.memory = ih
        mesh, mesh_suc := mesh_create_from_descriptor(&md)
        renderer.mesh = mesh

        return renderer, true
    }

    import "core:os"
    import "core:encoding/json"

    renderer_create :: proc{
        renderer_create_from_descriptor,
    }

    renderer_destroy :: proc(renderer: ^Renderer)
    {
        if renderer == nil
        {
            return
        }

        shader_destroy(&renderer.shader)
        mesh_destroy(&renderer.mesh)
        bgfx.destroy_vertex_layout(renderer.vlh)

        bgfx.shutdown()
    }

    renderer_update :: proc(renderer: ^Renderer)
    {
        if renderer == nil do return

        
        bgfx.touch(renderer.view.id)
        
        bgfx.set_state(u64(bgfx.StateFlags.WriteRgb | bgfx.StateFlags.WriteA), 0)
        bgfx.set_vertex_buffer(0, renderer.mesh.vertex_buffer, 0, cast(u32)len(verts))
        bgfx.set_index_buffer(renderer.mesh.index_buffer, 0, 6)
        bgfx.submit(renderer.view.id, renderer.shader.program, 0.0, 0)

        
        bgfx.frame(false)

        renderer.status.frame_count += 1
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
}