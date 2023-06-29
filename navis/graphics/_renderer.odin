package graphics

import "bgfx"
import "ui"

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
    rect: ui.Rect(u16),
}

Renderer_View :: struct
{
    id: bgfx.View_ID,
    clear: Renderer_View_Clear,
    rect: Renderer_View_Rect,
}