package navis

import "vendor:glfw"

Rect :: struct($T: typeid) {x, y, width, height: T}
Bounds :: struct($T: typeid) {left, top, right, bottom: T}

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

/* Create window */
window_create :: proc{
    window_create_from_descriptor,
}

when IMPLEMENTATION
{
    import "core:strings"
    
    @(export=EXPORT, link_prefix=PREFIX)
    window_create_from_descriptor :: proc(descriptor: ^Window_Descriptor) -> (Window, bool) #optional_ok
    {
        if descriptor == nil
        {
            log_verbose_error("Invalid window descriptor parameter", descriptor)
            return {}, false
        }

        //Setuping glfw
        glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
        glfw.WindowHint(glfw.DECORATED, descriptor.type_ == .Borderless ? 0 : 1)

        //Cloning title
        cstr_title, clone_err := strings.clone_to_cstring(descriptor.title, context.temp_allocator)
        if clone_err != .None
        {
            log_verbose_error("Failed to clone window descriptor title to cstring", descriptor)
            return {}, false
        }
        defer delete(cstr_title, context.temp_allocator)

        //Creating window
        handle := glfw.CreateWindow(cast(i32)descriptor.width, cast(i32)descriptor.height, cstr_title, nil, nil)
        if handle == nil
        {
            log_verbose_error("Failed to create window", descriptor)
            return {}, false
        }

        //Making window
        window: Window
        window.type_ = descriptor.type_
        window.handle = handle

        log_verbose_debug("Created window", window)
        return window, true
    }
    
    @(export=EXPORT, link_prefix=PREFIX)
    window_destroy :: proc(window: ^Window) -> bool
    {
        if !window_is_valid(window) do return false
        
        glfw.DestroyWindow(window.handle)
        window.handle = nil
        
        return true
    }
    
    @(export=EXPORT, link_prefix=PREFIX)
    window_update :: proc(window: ^Window) -> bool
    {
        if !window_is_valid(window) do return false
        return !glfw.WindowShouldClose(window.handle)
    }
    
    @(export=EXPORT, link_prefix=PREFIX)
    window_is_valid :: proc(window: ^Window) -> bool
    {
        if window == nil do return false
        if window.handle == nil do return false
        return true
    }

    @(export=EXPORT, link_prefix=PREFIX)
    window_get_position :: proc(window: ^Window) -> (Vector2_I32, bool) #optional_ok
    {
        if !window_is_valid(window) do return {0, 0}, false
        
        x, y := glfw.GetWindowPos(window.handle)
        return {i32(x), i32(y)}, true
    }
    
    @(export=EXPORT, link_prefix=PREFIX)
    window_get_size :: proc(window: ^Window) -> (Vector2_I32, bool) #optional_ok
    {
        if !window_is_valid(window) do return {-1, -1}, false

        width, height := glfw.GetWindowSize(window.handle)
        return {i32(width), i32(height)}, true
    }
}