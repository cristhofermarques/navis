package navis

import "bgfx"

Renderer_Descriptor :: struct
{
    renderer_type: bgfx.Renderer_Type,
    vsync: bool,
}

Renderer :: struct
{
    view: Renderer_View,
    scene: ^Scene,
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

        return renderer, true
    }

    renderer_create :: proc{
        renderer_create_from_descriptor,
    }

    renderer_destroy :: proc(renderer: ^Renderer)
    {
        if renderer == nil
        {
            return
        }

        bgfx.shutdown()
    }

    renderer_update :: proc(renderer: ^Renderer)
    {
        if renderer == nil do return
        bgfx.touch(renderer.view.id)
        bgfx.frame(false)
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