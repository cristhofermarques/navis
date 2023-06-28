package graphics_commons

import "navis:api"

when api.EXPORT
{
    import "navis:commons/log"
    import "core:strings"
    import "vendor:glfw"

    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_is_valid :: proc(window: ^Window) -> bool
    {
        if window == nil do return false
        if window.handle == nil do return false
        return true
    }
    
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_create_from_descriptor :: proc(descriptor: ^Window_Descriptor) -> (Window, bool) #optional_ok
    {
        log.verbose_debug("window")
        if descriptor == nil
        {
            log.verbose_error("Invalid window descriptor parameter", descriptor)
            return {}, false
        }

        //Setuping glfw
        glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
        glfw.WindowHint(glfw.DECORATED, descriptor.type_ == .Borderless ? 0 : 1)

        //Cloning title
        cstr_title, clone_err := strings.clone_to_cstring(descriptor.title, context.temp_allocator)
        if clone_err != .None
        {
            log.verbose_error("Failed to clone window descriptor title to cstring", descriptor)
            return {}, false
        }
        defer delete(cstr_title, context.temp_allocator)

        //Creating window
        handle := glfw.CreateWindow(cast(i32)descriptor.width, cast(i32)descriptor.height, cstr_title, nil, nil)
        if handle == nil
        {
            log.verbose_error("Failed to create window", descriptor)
            return {}, false
        }

        //Making window
        window: Window
        window.type_ = descriptor.type_
        window.handle = handle

        log.verbose_debug("Created window", window)
        return window, true
    }
    
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_destroy :: proc(window: ^Window) -> bool
    {
        if !ui_window_is_valid(window) do return false

        glfw.DestroyWindow(window.handle)
        window.handle = nil

        return true
    }
}