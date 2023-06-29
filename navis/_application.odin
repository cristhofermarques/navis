package navis

import "graphics"
import "graphics/ui"
import "core:time"

Application_UI :: struct
{
    window: ui.Window,
}

Application_Graphics :: struct
{
    renderer: graphics.Renderer,
}

Application :: struct
{
    running: bool,
    main_module: ^Module,
    modules: []Module,
    ui: Application_UI,
    graphics: Application_Graphics,
}