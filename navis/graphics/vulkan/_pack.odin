package vulkan

import "vk"
import "core:runtime"

Buffer_Pack_Buffer_Descriptor :: struct
{
    flags: vk.BufferCreateFlags,
    usage: vk.BufferUsageFlags,
    content: rawptr,
    size: uint,
}


Buffer_Pack_Descriptor :: struct
{
    property_flags: vk.MemoryPropertyFlags,
    queue_indices: []i32,
    buffers: []Buffer_Pack_Buffer_Descriptor,
}

buffer_pack_descriptor_is_valid :: #force_inline proc(descriptor: ^Buffer_Pack_Descriptor) -> bool
{
    if descriptor == nil do return false
    if descriptor.queue_indices == nil || len(descriptor.queue_indices) < 1 do return false
    if descriptor.buffers == nil || len(descriptor.buffers) < 1 do return false
    return true
}

Buffer_Pack :: struct
{
    allocator: runtime.Allocator,
    memory_property_flags: vk.MemoryPropertyFlags,
    memory_type_index: i32,
    queue_indices: []i32,
    memory: Memory,
    buffers: []Buffer,
}

buffer_pack_is_valid :: #force_inline proc(buffer_pack: ^Buffer_Pack) -> bool
{
    if buffer_pack == nil do return false
    if !buffer_is_valid(buffer_pack.buffers) do return false
    if !memory_is_valid(&buffer_pack.memory) do return false
    return true
}