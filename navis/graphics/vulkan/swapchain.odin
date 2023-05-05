package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"

    // @(export=api.SHARED, link_prefix=PREFIX)
    // swapchain_create :: proc(device: ^Device, desc: ^Swapchain_Descriptor)
    // {
    //     info: vk.SwapchainCreateInfoKHR
    //     info.sType = .SWAPCHAIN_CREATE_INFO_KHR
    //     info.clipped = cast(b32)desc.clipped

    //     vk.CreateSwapchainKHR(device.handle, )
    // }
}