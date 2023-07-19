package sandbox

import "navis:."
import "core:strings"
import "core:os"
import "core:fmt"

@(export, link_name=navis.MODULE_ON_CREATE_WINDOW)
on_create_window :: proc(desc: ^navis.Window_Descriptor, allocator := context.allocator)
{
    desc.title = strings.clone("Navis Editor", allocator)
    desc.width = 600
    desc.height = 480
    desc.type_ = .Windowed
}

@(export, link_name=navis.MODULE_ON_CREATE_RENDERER)
on_create_renderer :: proc(desc: ^navis.Renderer_Descriptor)
{
    desc.renderer_type = .Direct3D_11
    desc.vsync = true
}

@(export, link_name=navis.MODULE_ON_BEGIN)
on_begin :: proc()
{
    fmt.println("Begin")

    navis.application.graphics.renderer.view.id = 0
    navis.application.graphics.renderer.view.clear.flags = {.Color, .Depth}
    navis.application.graphics.renderer.view.clear.color = {255, 255, 55, 55}
    navis.application.graphics.renderer.view.clear.depth = 1
    navis.application.graphics.renderer.view.rect.ratio = .Equal
    navis.application.graphics.renderer.view.rect.rect = {0, 0, 0, 0,}
    navis.renderer_refresh()
}    

@(export, link_name=navis.MODULE_ON_END)
on_end :: proc()
{
    fmt.println("End")
}
