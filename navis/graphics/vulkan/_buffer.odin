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

buffer_is_valid :: proc{
    buffer_is_valid_single,
    buffer_is_valid_multiple,
}

buffer_create :: proc{
    buffer_create_from_descriptor_single,
    buffer_create_from_descriptor_multiple,
}

buffer_destroy :: proc{
    buffer_destroy_single,
    buffer_destroy_multiple,
}

buffer_filter_memory_types :: proc{
    buffer_filter_memory_types_single,
    buffer_filter_memory_types_multiple,
}

buffer_bind_memory :: proc{
    buffer_bind_memory_single,
    buffer_bind_memory_multiple_stacked,
}

buffer_get_size :: proc{
    buffer_get_size_single,
    buffer_get_size_multiple,
}

/*
Checks if buffer handle is valid.
*/
buffer_is_valid_single :: #force_inline proc(buffer: ^Buffer) -> bool
{
    return buffer != nil && handle_is_valid(buffer.handle)
}

/*
Checks if buffers handles is valid.
*/
buffer_is_valid_multiple :: #force_inline proc(buffers: []Buffer) -> bool
{
    if buffers == nil do return false
    for i := 0; i < len(buffers); i += 1
    {
        if !buffer_is_valid_single(&buffers[i]) do return false
    }

    return true
}

/*
Return a single buffer required size.
*/
buffer_get_size_single :: #force_inline proc(buffer: ^Buffer) -> u64
{
    if !buffer_is_valid(buffer) do return 0
    return cast(u64)buffer.requirements.size
}

/*
Return size of multiple buffers required sizes.
*/
buffer_get_size_multiple :: #force_inline proc(buffers: []Buffer) -> u64
{
    if !buffer_is_valid(buffers) do return 0

    total_size: u64
    for i := 0; i < len(buffers); i += 1 do total_size += buffer_get_size_single(&buffers[i])
    return total_size
}