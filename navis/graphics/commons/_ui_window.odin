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

//@(deprecated="Use Window_Descriptor")
Window_Desc :: Window_Descriptor

/*Window Descriptor*/
Window_Descriptor :: struct
{
    title: string,
    width, height: u32,
    mode : Window_Mode,
    event_callback : Window_Event_Callback,
}

ui_window_create :: proc{
    ui_window_create_separated,
    ui_window_create_desc,
}