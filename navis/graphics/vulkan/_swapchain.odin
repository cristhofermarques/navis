package vulkan

import "vk"
import "core:runtime"

/*
TODO
*/
Swapchain_Descriptor :: struct
{
    image_count: i32,
    image_format: vk.Format,
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
    image_format: vk.Format,
    present_mode: vk.PresentModeKHR,
    clipped: bool,
}

/*
TODO
*/
Swapchain :: struct
{
    handle: vk.SwapchainKHR, 
}