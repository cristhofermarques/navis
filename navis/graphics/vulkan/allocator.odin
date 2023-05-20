package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"

/*
Creates a vulkan allocator.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    allocator_create_from_descriptor :: proc(context_: ^Context, descriptor: ^Allocator_Descriptor, allocator := context.allocator) -> (Allocator, bool) #optional_ok
    {
        if !context_is_valid(context_)
        {
            return {}, true
        }

        if !allocator_descriptor_is_valid(descriptor)
        {
            return {}, true
        }

        buffer_packs, buff_pack_alloc_err := make([dynamic]Buffer_Pack, 0, descriptor.buffer_packs_reserved_count, allocator)
        if buff_pack_alloc_err != .None
        {
            return {}, false
        }

        allocator_: Allocator
        allocator_.allocator = allocator
        allocator_.allocations = 0
        allocator_.max_allocations = context_.physical_device.properties.limits.maxMemoryAllocationCount
        allocator_.buffer_packs = buffer_packs
        return allocator_, true
    }

/*
Destroy a vulkan allocator.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    allocator_destroy :: proc(context_: ^Context, allocator_: ^Allocator) -> bool
    {
        if !context_is_valid(context_)
        {
            return true
        }

        if !allocator_is_valid(allocator_)
        {
            return true
        }

        //Destroying buffer packs
        for i := 0; i < len(allocator_.buffer_packs); i += 1 do buffer_pack_destroy(context_, &allocator_.buffer_packs[i])
        delete(allocator_.buffer_packs)
        allocator_.buffer_packs = nil

        return true
    }


/*
Creates a buffer pack from descriptor for allocator.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    allocator_create_buffer_pack_from_descriptor_single :: proc(context_: ^Context, allocator_: ^Allocator, descriptor: ^Buffer_Pack_Descriptor) -> (^Buffer_Pack, bool) #optional_ok
    {
        if !context_is_valid(context_)
        {
            return nil, true
        }

        if !allocator_is_valid(allocator_)
        {
            return nil, true
        }

        if !buffer_pack_descriptor_is_valid(descriptor)
        {
            return nil, true
        }

        buffer_pack, buff_pack_succ := buffer_pack_create_from_descriptor_single(context_, descriptor, allocator_.allocator)
        if !buff_pack_succ
        {
            return nil, true
        }

        allocator_.allocations += 1
        append(&allocator_.buffer_packs, buffer_pack)
        p_buffer_pack := allocator_address_of_buffer_pack(allocator_, &buffer_pack)
        return p_buffer_pack, p_buffer_pack != nil
    }
}