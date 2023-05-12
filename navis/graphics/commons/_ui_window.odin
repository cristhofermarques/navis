package graphics_commons

import "navis:commons"

/*Window Modes*/
Window_Mode :: enum
{
    Windowed,
    Borderless,
}

/*Window Events*/
Window_Event :: enum
{
    None = 0,
    Open = 1,
    Close,
    Focus,
    Unfocus,
    Resize,
    Resize_Begin,
    Resize_End,
    Key_Down,
    Key_Up,
}

/*Procedure Type for Window Events*/
Window_Event_Callback :: #type proc(^Window, Window_Event)

/*Common Part of Window for All Platforms*/
Window_Common :: struct
{
    undestructable : bool,
    mode : Window_Mode,
    event: commons.Event(Window_Event_Callback),
}

/*Window Descriptor*/
Window_Descriptor :: struct
{
    title: string,
    width, height: u32,
    mode : Window_Mode,
    event_callback : Window_Event_Callback,
}

ui_window_create :: proc{
    ui_window_create_from_descriptor,
    ui_window_create_from_parameters,
}

/*
Create a native window from parameters.
*/
ui_window_create_from_parameters :: proc(title: string, width, height: u32, mode: Window_Mode, allocator := context.allocator, location := #caller_location) -> (Window, bool) #optional_ok
{
    desc: Window_Descriptor
    desc.title = title
    desc.width = width
    desc.height = height
    desc.mode = mode
    return ui_window_create_from_descriptor(&desc, allocator, location)
}