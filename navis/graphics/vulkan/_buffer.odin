package vulkan

import "vk"
import "core:runtime"
import "core:mem"

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

buffer_get_required_alignment :: proc{
    buffer_get_required_alignment_single,
    buffer_get_required_alignment_multiple,
}

buffer_get_required_size :: proc{
    buffer_get_required_size_single,
    buffer_get_required_size_single_aligned,
    buffer_get_required_size_multiple_aligned,
}

buffer_copy_content :: proc{
    buffer_copy_content_single,
    buffer_copy_content_multiple_stacked,
}

/*
Checks if buffer handle is valid.
*/
buffer_is_valid_single :: proc "contextless" (buffer: ^Buffer) -> bool
{
    return buffer != nil && handle_is_valid(buffer.handle)
}

/*
Checks if buffers handles is valid.
*/
buffer_is_valid_multiple :: proc "contextless" (buffers: []Buffer) -> bool
{
    if buffers == nil do return false
    for i := 0; i < len(buffers); i += 1
    {
        if !buffer_is_valid_single(&buffers[i]) do return false
    }

    return true
}

/*
Return the required alignment of a single buffer.
*/
buffer_get_required_alignment_single :: #force_inline proc "contextless" (buffer: ^Buffer) -> u64
{
    if !buffer_is_valid(buffer) do return 0
    return cast(u64)buffer.requirements.alignment
}

/*
Return the required alignment of buffers.
* The base alignemt value will be the major alignment value between buffer required alignment.
*/
buffer_get_required_alignment_multiple :: #force_inline proc "contextless" (buffers: []Buffer) -> u64
{
    if !buffer_is_valid(buffers) do return 0

    required_alignment: u64 = 0
    for i := 0; i < len(buffers); i += 1
    {
        buffer := &buffers[i]
        buffer_alignment := cast(u64)buffer.requirements.alignment
        if buffer_alignment > required_alignment do required_alignment = buffer_alignment
    }

    return required_alignment
}

/*
Return a single buffer required size.
*/
buffer_get_required_size_single :: #force_inline proc "contextless" (buffer: ^Buffer) -> u64
{
    if !buffer_is_valid(buffer) do return 0
    return cast(u64)buffer.requirements.size
}

/*
Returns a buffer aligned required size.
*/
buffer_get_required_size_single_aligned :: #force_inline proc "contextless" (buffer: ^Buffer, alignment: u64) -> u64
{
    if !buffer_is_valid(buffer) do return 0
    i_buff_req_size := cast(int)buffer.requirements.size
    i_alignment := int(alignment)
    return cast(u64)mem.align_formula(i_buff_req_size, i_alignment)
}

/*
Return aligned required size of multiple buffers.
*/
buffer_get_required_size_multiple_aligned :: #force_inline proc "contextless" (buffers: []Buffer) -> u64
{
    if !buffer_is_valid(buffers) do return 0

    alignment := buffer_get_required_alignment(buffers)
    if alignment == 0 do return 0

    total_size: u64
    for i := 0; i < len(buffers); i += 1 do total_size += buffer_get_required_size(&buffers[i], alignment)
    return total_size
}