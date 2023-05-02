package vulkan

import "navis:api"

when ODIN_OS == .Windows
{
    import "vk"
    import "navis:commons/log"

/*
Check from a physical device handle if queue family index support presentation.
*/
    queue_support_presentation_from_handle :: #force_inline proc(physical_device: vk.PhysicalDevice, index: u32, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(physical_device == nil, "invalid vulkan physical device handle parameter", location) do return false
        return cast(bool)vk.GetPhysicalDeviceWin32PresentationSupportKHR(physical_device, index)
    }

/*
Check from a physical device if queue family index support presentation.
*/
    queue_support_presentation :: #force_inline proc(physical_device: ^Physical_Device, index: u32, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter", location) do return false
        return cast(bool)vk.GetPhysicalDeviceWin32PresentationSupportKHR(physical_device.handle, index)
    }
}