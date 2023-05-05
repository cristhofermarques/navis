package vulkan

import "vk"
import "navis:commons"
import "navis:commons/log"
import "core:runtime"

/*
Vulkan surface.
*/
Surface :: struct
{
    allocator: runtime.Allocator,
    capabilities: vk.SurfaceCapabilitiesKHR,
    formats: []vk.SurfaceFormatKHR,
    present_modes: []vk.PresentModeKHR,
    handle: vk.SurfaceKHR,
}

/*
Check if surface handle is valid.
*/
surface_is_valid :: #force_inline proc(surface: ^Surface) -> bool
{
    return surface != nil && surface.handle != 0
}

/*
TODO
*/
surface_get_capabilities_from_handle :: proc(physical_device: ^Physical_Device, surface: vk.SurfaceKHR) -> (vk.SurfaceCapabilitiesKHR, bool) #optional_ok
{
    if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter") do return {}, false
    
    result: vk.Result
    capabilities: vk.SurfaceCapabilitiesKHR
    vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device.handle, surface, &capabilities)
    return capabilities, true
}

/*
TODO
*/
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