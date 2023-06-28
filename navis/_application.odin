package navis

import "commons/memory"
import "graphics/commons"
import "graphics/ui"
import "core:time"

Application_UI :: struct
{
    window: ui.Window,
}

Application :: struct
{
    running: bool,
    ui: Application_UI,
    main_module: ^Module,
    modules: []Module,
}