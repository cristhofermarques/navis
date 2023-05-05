package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    swapchain_create_from_descriptor :: proc(device: ^Device, surface: ^Surface, desc: ^Swapchain_Descriptor, location := #caller_location) -> (Swapchain, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(!surface_is_valid(surface), "invalid vulkan surface parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid swapchain descriptor parameter", location) do return {}, false
        if log.verbose_fail_error(!surface_support_image_count(surface, desc.image_count), "invalid swapchain image count", location) do return {}, false
        if log.verbose_fail_error(!surface_support_image_format(surface, desc.image_format), "unsupported swapchain image format", location) do return {}, false
        if log.verbose_fail_error(!surface_support_present_mode(surface, desc.present_mode), "unsupported swapchain present mode", location) do return {}, false

        info: vk.SwapchainCreateInfoKHR
        info.sType = .SWAPCHAIN_CREATE_INFO_KHR
        info.imageUsage = {.COLOR_ATTACHMENT}
        info.compositeAlpha = {.OPAQUE}
        info.surface = surface.handle
        info.imageExtent = surface.capabilities.currentExtent
        info.preTransform = surface.capabilities.currentTransform
        info.minImageCount = cast(u32)desc.image_count
        info.imageFormat = desc.image_format.format
        info.imageColorSpace = desc.image_format.colorSpace
        info.presentMode = desc.present_mode
        info.imageSharingMode = device.graphics_do_present ? .EXCLUSIVE : .CONCURRENT
        info.clipped = cast(b32)desc.clipped
        info.imageArrayLayers = 1

        handle: vk.SwapchainKHR
        result := vk.CreateSwapchainKHR(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create swapchain", location) do return {}, false

        swapchain: Swapchain
        swapchain.image_count = desc.image_count
        swapchain.image_extent = surface.capabilities.currentExtent
        swapchain.image_format = desc.image_format
        swapchain.present_mode = desc.present_mode
        swapchain.handle = handle
        return swapchain, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    swapchain_destroy :: proc(device: ^Device, swapchain: ^Swapchain, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!swapchain_is_valid(swapchain), "invalid vulkan swapchain parameter", location) do return false

        if swapchain.handle != 0
        {
            vk.DestroySwapchainKHR(device.handle, swapchain.handle, nil)
            swapchain.handle = 0
        }

        return true
    }
}