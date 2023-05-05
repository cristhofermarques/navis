package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

    
    @(export=api.SHARED, link_prefix=PREFIX)
    surface_destroy :: proc(instance: ^Instance, surface: ^Surface) -> bool
    {
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance parameter") do return false
        if log.verbose_fail_error(!surface_is_valid(surface), "invalid vulkan surface parameter") do return false

        allocator := surface.allocator

        vk.DestroySurfaceKHR(instance.handle, surface.handle, nil)
        surface.handle = 0

        if surface.formats != nil
        {
            delete(surface.formats, allocator)
            surface.formats = nil
        }

        if surface.present_modes != nil
        {
            delete(surface.present_modes, allocator)
            surface.present_modes = nil
        }

        return true
    }

    /*
    TODO
    */
    @(export=api.SHARED, link_prefix=PREFIX)
    surface_enumerate_formats_from_handle :: proc(physical_device: ^Physical_Device, surface: vk.SurfaceKHR, allocator := context.allocator) -> ([]vk.SurfaceFormatKHR, bool) #optional_ok
    {
        if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter") do return nil, false
        if log.verbose_fail_error(surface == 0, "invalid vulkan handle surface parameter") do return nil, false
        
        result: vk.Result
        formats_count: u32
        result = vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device.handle, surface, &formats_count, nil)
        if log.verbose_fail_error(result != .SUCCESS, "enumerate vulkan physical device surface formats slice, count querry") do return nil, false
        
        formats, formats_alloc_err := make([]vk.SurfaceFormatKHR, formats_count, allocator)
        if log.verbose_fail_error(formats_alloc_err != .None, "make vulkan physical device surface formats slice") do return nil, false

        result = vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device.handle, surface, &formats_count, commons.array_try_as_pointer(formats))
        if log.verbose_fail_error(result != .SUCCESS, "enumerate vulkan physical device surface formats slice, fill querry")
        {
            delete(formats, allocator)
            return nil, false
        }

        return formats, true
    }

    /*
    TODO
    */
    @(export=api.SHARED, link_prefix=PREFIX)
    surface_enumerate_present_modes_from_handle :: proc(physical_device: ^Physical_Device, surface: vk.SurfaceKHR, allocator := context.allocator) -> ([]vk.PresentModeKHR, bool) #optional_ok
    {
        if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter") do return nil, false
        if log.verbose_fail_error(surface == 0, "invalid vulkan handle surface parameter") do return nil, false
        
        result: vk.Result
        present_modes_count: u32
        result = vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device.handle, surface, &present_modes_count, nil)
        if log.verbose_fail_error(result != .SUCCESS, "enumerate vulkan physical device surface present modes slice, count querry") do return nil, false
        
        present_modes, present_modes_alloc_err := make([]vk.PresentModeKHR, present_modes_count, allocator)
        if log.verbose_fail_error(present_modes_alloc_err != .None, "make vulkan physical device surface present modes slice") do return nil, false

        result = vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device.handle, surface, &present_modes_count, commons.array_try_as_pointer(present_modes))
        if log.verbose_fail_error(result != .SUCCESS, "enumerate vulkan physical device surface present modes slice, fill querry")
        {
            delete(present_modes, allocator)
            return nil, false
        }

        return present_modes, true
    }
}