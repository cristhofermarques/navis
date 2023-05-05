package vulkan

import "navis:api"

when api.EXPORT_WINDOWS
{
    import "vk"
    import "navis:graphics/ui"
    import "navis:commons/log"
    import "core:sys/windows"

    @(export=api.SHARED, link_prefix=PREFIX)
    surface_create :: proc(instance: ^Instance, physical_device: ^Physical_Device, window: ^ui.Window, allocator := context.allocator, location := #caller_location) -> (Surface, bool) #optional_ok
    {
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance parameter", location) do return {}, false
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan physical device", location) do return {}, false
        if log.verbose_fail_error(!ui.window_is_valid(window), "invalid window parameter", location) do return {}, false
        
        info: vk.Win32SurfaceCreateInfoKHR
        info.sType = .WIN32_SURFACE_CREATE_INFO_KHR
        info.hwnd = window.hwnd
        info.hinstance = cast(windows.HANDLE)windows.GetModuleHandleA(nil)
        
        //Creating surface
        handle: vk.SurfaceKHR
        result := vk.CreateWin32SurfaceKHR(instance.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create surface", location) do return {}, false

        present_modes, present_modes_succ := surface_enumerate_present_modes_from_handle(physical_device, handle, allocator)
        if log.verbose_fail_error(!present_modes_succ, "enumerate surface present modes from handle", location) do return {}, false
        
        formats, formats_succ := surface_enumerate_formats_from_handle(physical_device, handle, allocator)
        if log.verbose_fail_error(!formats_succ, "enumerate surface formats from handle", location)
        {
            delete(present_modes, allocator)
            return {}, false
        }

        capabilities, capabilities_succ := surface_get_capabilities_from_handle(physical_device, handle)
        if log.verbose_fail_error(!formats_succ, "get surface capabilities from handle", location)
        {
            delete(formats, allocator)
            delete(present_modes, allocator)
            return {}, false
        }

        //Making surface
        surface: Surface
        surface.allocator = allocator
        surface.handle = handle
        surface.present_modes = present_modes
        surface.formats = formats
        surface.capabilities = capabilities
        return surface, true
    }
}