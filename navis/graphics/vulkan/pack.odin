package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

/*
Create a single buffer pack from descriptor.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_pack_create_from_descriptor_single :: proc(context_: ^Context, descriptor: ^Buffer_Pack_Descriptor, allocator := context.allocator) -> (Buffer_Pack, bool) #optional_ok
    {
        //Checking device parameter
        if !context_is_valid(context_)
        {
            log.verbose_error("Invalid vulkan context parameter")
            return {}, false
        }

        //Checking descriptor parameter
        if !buffer_pack_descriptor_is_valid(descriptor)
        {
            log.verbose_error("Invalid vulkan buffer pack descriptor parameter")
            return {}, false
        }

        //Allocating buffers descriptors
        elements_count := len(descriptor.elements)
        buffers_descriptors, buff_desc_alloc_err := make([]Buffer_Descriptor, elements_count, context.temp_allocator)
        if buff_desc_alloc_err != .None
        {
            log.verbose_error("Failed to allocate vulkan buffer descriptors slice")
            return {}, false
        }
        defer delete(buffers_descriptors, context.temp_allocator)

        //Making buffers descriptors
        for i := 0; i < elements_count; i += 1
        {
            buffer_descriptor := &buffers_descriptors[i]
            element_descriptor := &descriptor.elements[i]

            buffer_descriptor.flags = element_descriptor.flags
            buffer_descriptor.usage = element_descriptor.usage
            buffer_descriptor.size = element_descriptor.size
            buffer_descriptor.queue_indices = descriptor.queue_indices
        }

        //Creating buffers
        log.verbose_debug("Creating vulkan buffers", buffers_descriptors)
        buffers, buff_succ := buffer_create(&context_.device, buffers_descriptors, allocator)
        if !buff_succ
        {
            log.verbose_error("Failed to create vulkan buffers", buffers_descriptors)
            return {}, false
        }
        log.verbose_debug("Vulkan buffers created", buffers)
        
        //Filtering memory type
        log.verbose_debug("Filtering memory types", descriptor.property_flags, context_.physical_device.memory_properties)
        memory_type_index, mem_type_idx_succ := buffer_filter_memory_types_multiple_first(&context_.physical_device, buffers, descriptor.property_flags)
        if !mem_type_idx_succ
        {
            log.verbose_error("Failed to filter memory types", descriptor.property_flags, context_.physical_device.memory_properties)
            buffer_destroy(&context_.device, buffers)
            delete(buffers, allocator)
            return {}, false
        }

        //Making memory descriptor
        memory_descriptor: Memory_Descriptor
        memory_descriptor.type_index = memory_type_index
        memory_descriptor.size = buffer_get_required_size(buffers)

        //Creating memory
        log.verbose_debug("Creating vulkan memory", memory_descriptor)
        memory, mem_succ := memory_create(&context_.device, &memory_descriptor)
        if !mem_succ
        {
            log.verbose_error("Failed to create vulkan memory", memory_descriptor)
            buffer_destroy(&context_.device, buffers)
            delete(buffers, allocator)
            return {}, false
        }
        log.verbose_debug("Vulkan memory created", memory)
        
        //Binding buffers to memory
        log.verbose_debug("Binding buffers", buffers, "to memory", memory)
        buff_bind_mem_succ := buffer_bind_memory_multiple_stacked(&context_.device, &memory, buffers, 0)
        if !buff_bind_mem_succ
        {
            log.verbose_error("Failed to bind buffers", buffers, "to memory", memory)
            memory_destroy(&context_.device, &memory)
            buffer_destroy(&context_.device, buffers)
            delete(buffers, allocator)
            return {}, false
        }

        //Making buffer pack
        buffer_pack: Buffer_Pack
        buffer_pack.allocator = allocator
        buffer_pack.memory_type_index = memory_type_index
        buffer_pack.memory_property_flags = descriptor.property_flags
        buffer_pack.memory = memory
        buffer_pack.buffers = buffers
        return buffer_pack, true
    }

/*
Destroy a single buffer pack.
*/
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
        buffer_pack.buffers = nil

        memory_destroy(&context_.device, &buffer_pack.memory)

        return true
    }

/*
Upload content to buffer pack buffers.
* Uses memory mapping.
* Stack content upload.
*/
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

        if contents == nil
        {
            log.verbose_error("Invalid contents slice parameter")
            return false
        }

        if len(contents) != len(buffer_pack.buffers)
        {
            log.verbose_error("Contents slice dont have same count of buffer pack buffers", len(contents), "vs", len(buffer_pack.buffers))
            return false
        }

        return buffer_upload_content_multiple_stacked(&context_.device, &buffer_pack.memory, buffer_pack.buffers, contents, start_offset)
    }
}