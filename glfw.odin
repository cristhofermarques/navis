package navis

import "core:strings"
import "vendor:glfw"

Window_Type :: enum
{
    Windowed,
    Borderless,
}

Window_Descriptor :: struct
{
    title: string,
    size: [2]u32,
    type : Window_Type,
}

glfw_create_window :: proc(title: string, size: [2]u32, type : Window_Type) -> glfw.WindowHandle
{
    //Setuping glfw
    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
    glfw.WindowHint(glfw.DECORATED, type == .Borderless ? 0 : 1)

    //Cloning title
    cstr_title, clone_err := strings.clone_to_cstring(title, context.temp_allocator)
    if clone_err != .None
    {
        log_verbose_error("Failed to clone window title to cstring")
        return nil
    }

    //Creating window
    handle := glfw.CreateWindow(cast(i32)size.x, cast(i32)size.y, cstr_title, nil, nil)
    if handle == nil
    {
        log_verbose_error("Failed to create glfw window")
        return nil
    }

    log_verbose_debug("Created glfw window", handle)
    return handle
}