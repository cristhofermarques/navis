package vulkan

import "vk"
import "core:runtime"

/*
Vulkan buffer descriptor.
*/
Buffer_Descriptor :: struct
{
    flags: vk.BufferCreateFlags,
    usage: vk.BufferUsageFlags,
    queue_indices: []i32,
    size: uint,
}

/*
Vulkan buffer.
*/
Buffer :: struct
{
    allocator: runtime.Allocator,
    usage: vk.BufferUsageFlags,
    queue_indices: []i32,
    size: uint,
    requirements: vk.MemoryRequirements,
    handle: vk.Buffer,
}

/*
Checks if buffer handle is valid.
*/
buffer_is_valid :: #force_inline proc(buffer: ^Buffer) -> bool
{
    return buffer != nil && handle_is_valid(buffer.handle)
}

buffer_create :: proc{
    buffer_create_from_descriptor,
}