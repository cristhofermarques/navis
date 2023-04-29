package vulkan

import "navis:api"

when api.EXPORT_WINDOWS
{
    import "vk"
    import "navis:graphics/ui"
    import "navis:commons/log"
    import "core:sys/windows"

    @(export=api.SHARED, link_prefix=PREFIX)
    surface_create :: proc(instance: ^Instance, window: ^ui.Window) -> (Surface, bool) #optional_ok
    {
        if log.verbose_fail_error(instance == nil, "nil vulkan instance parameter") do return {}, false
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance") do return {}, false
        if log.verbose_fail_error(window == nil, "nil window parameter") do return {}, false
        if log.verbose_fail_error(!ui.window_is_valid(window), "invalid window") do return {}, false
        
        info: vk.Win32SurfaceCreateInfoKHR
        info.sType = .WIN32_SURFACE_CREATE_INFO_KHR
        info.hwnd = window.hwnd
        info.hinstance = cast(windows.HANDLE)windows.GetModuleHandleA(nil)
        
        //Creating surface
        handle: vk.SurfaceKHR
        result := vk.CreateWin32SurfaceKHR(instance.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create surface") do return {}, false

        //Making surface
        surface: Surface
        surface.handle = handle
        return surface, true
    }
}