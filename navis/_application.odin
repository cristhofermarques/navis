package navis

import "commons/memory"
import "graphics/commons"
import "graphics/ui"
import "core:time"

Application_Environment :: struct
{
    modules_directories, packages_directories: []string,
}

Application_UI :: struct
{
    window: ui.Window,
}

Application_Time :: struct
{
    delta_time_stopwatch: time.Stopwatch,
    delta_time: f64,
}

Application :: struct
{
    running: bool,
    time: Application_Time,
    ui: Application_UI,
    main_module: ^Module,
    modules: []Module,
}