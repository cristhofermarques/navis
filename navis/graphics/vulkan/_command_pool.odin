package vulkan

import "vk"

/*
Vulkan command pool descriptor.
*/
Command_Pool_Descriptor :: struct
{
    flags: vk.CommandPoolCreateFlags,
    index: i32,
}

/*
Vulkan command pool.
*/
Command_Pool :: struct
{
    index: i32,
    handle: vk.CommandPool,
}

command_pool_create :: proc{
    command_pool_create_from_descriptor,
    command_pool_create_from_parameters,
}

/*
Check if command pool handle is valid.
*/
command_pool_is_valid :: #force_inline proc(command_pool: ^Command_Pool) -> bool
{
    return command_pool != nil && command_pool.handle != 0
}