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
Checks if memory descriptor is valid.
*/
memory_descriptor_is_valid :: #force_inline proc "contextless" (descriptor: ^Memory_Descriptor) -> bool
{
    if descriptor == nil do return false
    if descriptor.type_index < 0 || descriptor.type_index >= vk.MAX_MEMORY_TYPES do return false
    if descriptor.size < 1 do return false
    return true
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
Create/Allocate vulkan memory.
* From descriptor.
*/
memory_create :: proc{
    memory_create_from_descriptor,
}

/*
Checks if memory handle is valid.
*/
memory_is_valid :: #force_inline proc "contextless" (memory: ^Memory) -> bool
{
    return memory != nil && handle_is_valid(memory.handle)
}