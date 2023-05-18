package vulkan

import "vk"
import "core:runtime"

/*
Vulkan buffer pack element descriptor.
*/
Buffer_Pack_Element_Descriptor :: struct
{
    flags: vk.BufferCreateFlags,
    usage: vk.BufferUsageFlags,
    size: uint,
}

/*
Vulkan buffer pack descriptor.
*/
Buffer_Pack_Descriptor :: struct
{
    property_flags: vk.MemoryPropertyFlags,
    queue_indices: []i32,
    elements: []Buffer_Pack_Element_Descriptor,
}

/*
Checks if vulkan buffer pack descriptor is valid.
*/
buffer_pack_descriptor_is_valid :: #force_inline proc "contextless" (descriptor: ^Buffer_Pack_Descriptor) -> bool
{
    if descriptor == nil do return false
    if descriptor.queue_indices == nil || len(descriptor.queue_indices) < 1 do return false
    if descriptor.elements == nil || len(descriptor.elements) < 1 do return false
    return true
}

/*
Vulkan buffer pack.
*/
Buffer_Pack :: struct
{
    allocator: runtime.Allocator,
    memory_property_flags: vk.MemoryPropertyFlags,
    memory_type_index: i32,
    queue_indices: []i32,
    memory: Memory,
    buffers: []Buffer,
}

/*
Checks if vulkan buffer pack is valid.
*/
buffer_pack_is_valid :: #force_inline proc "contextless" (buffer_pack: ^Buffer_Pack) -> bool
{
    if buffer_pack == nil do return false
    if !buffer_is_valid(buffer_pack.buffers) do return false
    if !memory_is_valid(&buffer_pack.memory) do return false
    return true
}

buffer_pack_upload_content :: proc{
    buffer_pack_upload_content_multiple_stacked,
}