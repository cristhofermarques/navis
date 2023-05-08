package vulkan

import "vk"
import "core:runtime"

/*
Vulkan framebuffer descriptor.
*/
Framebuffer_Descriptor :: struct
{
    flags: vk.FramebufferCreateFlags,
    width, height, layers: i32,
}

/*
Vulkan framebuffer.
*/
Framebuffer :: struct
{
    allocator: runtime.Allocator,
    width, height, layers: i32,
    image_views: []Image_View,
    handle: vk.Framebuffer,
}

framebuffer_create :: proc{
    framebuffer_create_from_descriptor,
}

/*
Checks if framebuffer handle is valid.
*/
framebuffer_is_valid :: #force_inline proc(framebuffer: ^Framebuffer) -> bool
{
    return framebuffer != nil && framebuffer.handle != 0
}