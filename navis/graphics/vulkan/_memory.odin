package vulkan

import "vk"

/*
Vulkan memory descriptor.
*/
Memory_Descriptor :: struct
{
    type_index: i32,
    size: u64,
}

/*
Vulkan memory.
*/
Memory :: struct
{
    type_index: i32,
    size: u64,
    handle: vk.DeviceMemory,
}

/*
Checks if device memory handle is valid.
*/
memory_is_valid :: #force_inline proc "contextless" (memory: ^Memory) -> bool
{
    return memory != nil && handle_is_valid(memory.handle)
}