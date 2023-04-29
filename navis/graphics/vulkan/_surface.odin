package vulkan

import "vk"

/*
Vulkan surface.
*/
Surface :: struct
{
    handle: vk.SurfaceKHR,
}

/*
Check if surface handle is valid.
*/
surface_is_valid :: #force_inline proc(surface: ^Surface) -> bool
{
    return surface != nil && surface.handle != 0
}