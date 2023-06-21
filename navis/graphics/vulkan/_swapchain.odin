package vulkan

import "vk"
import "navis:commons"
import "core:runtime"

/*
Vulkan swapchain descriptor.
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
}

/*
Checks if swapchain descriptor is valid.
*/
swapchain_descriptor_is_valid :: proc "contextless" (descriptor: ^Swapchain_Descriptor) -> bool
{
    if descriptor == nil do return false
    if descriptor.image_count < 1 do return false
    return true
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
    handle: vk.SwapchainKHR, 
}

swapchain_create :: proc{
    swapchain_create_from_descriptor,
}

/*
Checks if swapchain handle is valid.
*/
swapchain_is_valid :: proc "contextless" (swapchain: ^Swapchain) -> bool
{
    return swapchain != nil && handle_is_valid(swapchain.handle)
}

/*
Acquire next swapchain image index.
* No parameter cheking.
*/
swapchain_acquire_next_image :: proc "contextless" (context_: ^Context, swapchain: ^Swapchain, semaphore: Semaphore, fence: vk.Fence, timeout: u64) -> (u32, bool) #optional_ok
{
    index: u32
    result := vk.AcquireNextImageKHR(context_.device.handle, swapchain.handle, timeout, semaphore, fence, &index)
    if result != .SUCCESS do return 0, false
    else do return index, true
}

swapchain_present :: proc{
    swapchain_present_from_descriptor,
}

/*
Present swapchain image descriptor.
*/
Present_Descriptor :: struct
{
    image_index: u32,
    wait_semaphores: []vk.Semaphore,
}

/*
Present swapchain image.
* No parameter cheking.
*/
swapchain_present_from_descriptor :: proc "contextless" (swapchain: ^Swapchain, queue: ^Queue, desc: ^Present_Descriptor) -> bool
{
    info: vk.PresentInfoKHR
    info.sType = .PRESENT_INFO_KHR
    info.pImageIndices = &desc.image_index
    info.pSwapchains = &swapchain.handle
    info.swapchainCount = 1
    info.pWaitSemaphores = commons.array_try_as_pointer(desc.wait_semaphores)
    info.waitSemaphoreCount = cast(u32)commons.array_try_len(desc.wait_semaphores)
    result := vk.QueuePresentKHR(queue.handle, &info)
    return result == .SUCCESS
}