package vulkan

import "vk"

/*
Vulkan fence descriptor.
*/
Fence_Descriptor :: struct
{
    flags: vk.FenceCreateFlags,
}

/*
Vulkan fence.
*/
Fence :: struct
{
    handle: vk.Fence,
}

/*
Checks if fence handle is valid.
*/
fence_is_valid :: #force_inline proc(fence: ^Fence) -> bool
{
    return fence != nil && fence.handle != 0
}