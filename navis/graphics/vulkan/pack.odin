package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_pack_create_from_descriptor_single :: proc(context_: ^Context, descriptor: ^Buffer_Pack_Descriptor, allocator := context.allocator) -> (Buffer_Pack, bool) #optional_ok
    {
        if !context_is_valid(context_)
        {
            log.verbose_error("Invalid vulkan context parameter")
            return {}, false
        }

        if !buffer_pack_descriptor_is_valid(descriptor)
        {
            log.verbose_error("Invalid vulkan buffer pack descriptor parameter")
            return {}, false
        }

        buffers_count := len(descriptor.buffers)
        buffers_descriptors, buff_desc_alloc_err := make([]Buffer_Descriptor, buffers_count, context.temp_allocator)
        if buff_desc_alloc_err != .None
        {
            log.verbose_error("Failed to allocate vulkan buffer descriptors slice")
            return {}, false
        }
        defer delete(buffers_descriptors, context.temp_allocator)

        for i := 0; i < buffers_count; i += 1
        {
            buffer_descriptor := &buffers_descriptors[i]
            pack_buffer_descriptor := &descriptor.buffers[i]

            buffer_descriptor.flags = pack_buffer_descriptor.flags
            buffer_descriptor.usage = pack_buffer_descriptor.usage
            buffer_descriptor.size = pack_buffer_descriptor.size
            buffer_descriptor.queue_indices = descriptor.queue_indices
        }

        buffers, buff_succ := buffer_create(&context_.device, buffers_descriptors, allocator)
        if !buff_succ do return {}, false
        fmt.println("BUFFERS", buffers)

        memory_type_index, mem_type_idx_succ := buffer_filter_memory_types_multiple_first(&context_.physical_device, buffers, descriptor.property_flags)
        if !mem_type_idx_succ do return {}, false

        memory_descriptor: Memory_Descriptor
        memory_descriptor.type_index = memory_type_index
        memory_descriptor.size = buffer_get_required_size(buffers)
        memory, mem_succ := memory_create_from_descriptor(&context_.device, &memory_descriptor)
        if !mem_succ do return {}, false

        if !buffer_bind_memory_multiple_stacked(&context_.device, &memory, buffers, 0) do return {}, false

        buffer_pack: Buffer_Pack
        buffer_pack.allocator = allocator
        buffer_pack.memory_type_index = memory_type_index
        buffer_pack.buffers = buffers
        buffer_pack.memory = memory
        return buffer_pack, true
    }
    
    import "core:fmt"
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_pack_destroy :: proc(context_: ^Context, buffer_pack: ^Buffer_Pack) -> bool
    {
        if !context_is_valid(context_)
        {
            log.verbose_error("Invalid vulkan context parameter")
            return false
        }

        if !buffer_pack_is_valid(buffer_pack)
        {
            log.verbose_error("Invalid vulkan buffer pack parameter")
            return false
        }

        allocator := buffer_pack.allocator

        buffer_destroy(&context_.device, buffer_pack.buffers)
        delete(buffer_pack.buffers, allocator)

        memory_destroy(&context_.device, &buffer_pack.memory)

        return true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_pack_upload_content_multiple_stacked :: proc(context_: ^Context, buffer_pack: ^Buffer_Pack, contents: []rawptr, start_offset: u64 = 0) -> bool
    {
        if !context_is_valid(context_)
        {
            log.verbose_error("Invalid vulkan context parameter")
            return false
        }

        if !buffer_pack_is_valid(buffer_pack)
        {
            log.verbose_error("Invalid vulkan buffer pack parameter")
            return false
        }

        return buffer_copy_content_multiple_stacked(&context_.device, &buffer_pack.memory, buffer_pack.buffers, contents, start_offset)
    }
}