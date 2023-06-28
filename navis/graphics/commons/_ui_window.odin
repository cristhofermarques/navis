package graphics_commons

import "navis:commons"
import "vendor:glfw"

/* Window Type */
Window_Type :: enum
{
    Windowed,
    Borderless,
}

/* Window Descriptor */
Window_Descriptor :: struct
{
    title: string,
    width, height: u32,
    type_ : Window_Type,
}

/* Window */
Window :: struct
{
    type_: Window_Type,
    handle: glfw.WindowHandle,
}

ui_window_create :: proc{
    ui_window_create_from_descriptor,
}

ui_window_update :: proc(window: ^ Window) -> bool
{
    if !ui_window_is_valid(window) do return false
    return !glfw.WindowShouldClose(window.handle)
}