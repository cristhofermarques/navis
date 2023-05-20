package vulkan

import "core:runtime"

/*
Vulkan allocator descriptor.
*/
Allocator_Descriptor :: struct
{
    buffer_packs_reserved_count: u32,
}

/*
Checks if allocator descriptor is valid.
*/
allocator_descriptor_is_valid :: #force_inline proc "contextless" (descriptor: ^Allocator_Descriptor) -> bool
{
    return descriptor != nil
}

/*
Vulkan allocator.
*/
Allocator :: struct
{
    allocator: runtime.Allocator,
    allocations, max_allocations: u32,
    buffer_packs: [dynamic]Buffer_Pack,
}

/*
Checks if allocator is valid.
*/
allocator_is_valid :: #force_inline proc "contextless" (allocator: ^Allocator) -> bool
{
    return allocator != nil
}

/*
Returns the index of provided buffer pack stored in allocator.
*/
allocator_index_of_buffer_pack :: proc "contextless" (allocator: ^Allocator, buffer_pack: ^Buffer_Pack) -> int
{
    if !allocator_is_valid(allocator) do return -1
    if !buffer_pack_is_valid(buffer_pack) do return -1

    for i := 0; i < len(allocator.buffer_packs); i += 1
    {
        allocator_buffer_pack := &allocator.buffer_packs[i]
        if allocator_buffer_pack.memory.handle == buffer_pack.memory.handle do return i
    }

    return -1
}

/*
Returns the address of provided buffer pack stored in allocator.
*/
allocator_address_of_buffer_pack :: proc "contextless" (allocator: ^Allocator, buffer_pack: ^Buffer_Pack) -> ^Buffer_Pack
{
    if !allocator_is_valid(allocator) do return nil
    if !buffer_pack_is_valid(buffer_pack) do return nil

    for i := 0; i < len(allocator.buffer_packs); i += 1
    {
        allocator_buffer_pack := &allocator.buffer_packs[i]
        if allocator_buffer_pack.memory.handle == buffer_pack.memory.handle do return allocator_buffer_pack
    }

    return nil
}