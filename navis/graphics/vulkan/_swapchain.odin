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
    image_view_flags: vk.ImageViewCreateFlags,
    image_view_type: vk.ImageViewType,
    image_view_components: vk.ComponentMapping,
    image_view_subresource_range: vk.ImageSubresourceRange,
    framebuffer_flags: vk.FramebufferCreateFlags,
    framebuffer_layers: i32,
}

/*
Swapchain Information.
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
    allocator: runtime.Allocator,
    image_count: i32,
    image_extent: vk.Extent2D,
    image_format: vk.SurfaceFormatKHR,
    present_mode: vk.PresentModeKHR,
    images: []vk.Image,
    image_views: []Image_View,
    framebuffers: []Framebuffer,
    handle: vk.SwapchainKHR, 
}

swapchain_create :: proc{
    swapchain_create_from_descriptor,
}

/*
Checks if swapchain handle is valid.
*/
swapchain_is_valid :: #force_inline proc(swapchain: ^Swapchain) -> bool
{
    return swapchain != nil && swapchain.handle != 0
}