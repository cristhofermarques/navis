package vulkan

import "vk"
import "core:runtime"

/*
TODO
*/
Swapchain_Descriptor :: struct
{
    image_count: i32,
    image_format: vk.SurfaceFormatKHR,
    present_mode: vk.PresentModeKHR,
    clipped: bool,
}

/*
TODO
*/
Swapchain_Info :: struct
{
    allocator: runtime.Allocator,
    image_count: i32,
    image_format: vk.SurfaceFormatKHR,
    present_mode: vk.PresentModeKHR,
    clipped: bool,
}

/*
Vulkan swapchain.
*/
Swapchain :: struct
{
    image_count: i32,
    image_extent: vk.Extent2D,
    image_format: vk.SurfaceFormatKHR,
    present_mode: vk.PresentModeKHR,
    handle: vk.SwapchainKHR, 
}

/*
Checks if swapchain handle is valid.
*/
swapchain_is_valid :: #force_inline proc(swapchain: ^Swapchain) -> bool
{
    return swapchain != nil && swapchain.handle != 0
}