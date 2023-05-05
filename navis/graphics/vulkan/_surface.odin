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
Check if surface support image count.
*/
surface_support_image_count :: #force_inline proc(surface: ^Surface, image_count: i32) -> bool
{
    if log.verbose_fail_error(!surface_is_valid(surface), "invalid vulkan surface parameter") do return false
    u_image_count := u32(image_count)
    return u_image_count >= surface.capabilities.minImageCount && u_image_count <= surface.capabilities.maxImageCount
}

/*
Check if surface support format.
*/
surface_support_image_format :: #force_inline proc(surface: ^Surface, format: vk.SurfaceFormatKHR, check_format := true, check_colorspace := false) -> bool
{
    if log.verbose_fail_error(!surface_is_valid(surface), "invalid vulkan surface parameter") do return false
    for format in surface.formats
    {
        pass_format := check_format ? format.format == format.format: true
        pass_colorspace := check_colorspace ? format.colorSpace == format.colorSpace: true
        match := pass_format && pass_colorspace
        if match do return true
    }

    return false
}

/*
Check if surface support present mode.
*/
surface_support_present_mode :: #force_inline proc(surface: ^Surface, present_mode: vk.PresentModeKHR) -> bool
{
    if log.verbose_fail_error(!surface_is_valid(surface), "invalid vulkan surface parameter") do return false
    return commons.array_contains(surface.present_modes, present_mode)
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