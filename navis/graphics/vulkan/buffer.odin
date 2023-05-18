package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"
    import "core:runtime"
    import "core:mem"

/*
Get buffer memory requirements from a handle.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_get_requirements_from_handle :: proc(device: ^Device, buffer: vk.Buffer, location := #caller_location) -> (vk.MemoryRequirements, bool) #optional_ok
    {
        //Nil device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid Vulkan Device Parameter")
            return {}, false
        }

        //Nil device parameter
        if !handle_is_valid(buffer)
        {
            log.verbose_error("Invalid Vulkan Buffer Handle Parameter")
            return {}, false
        }

        //Getting requirements
        requirements: vk.MemoryRequirements
        vk.GetBufferMemoryRequirements(device.handle, buffer, &requirements)
        return requirements, true
    }

/*
Create a buffer from descriptor.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_create_from_descriptor_single :: proc(device: ^Device, desc: ^Buffer_Descriptor, allocator := context.allocator, location := #caller_location) -> (Buffer, bool) #optional_ok
    {
        //Nil device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid Vulkan Device Parameter")
            return {}, false
        }

        //Nil descriptor parameter
        if desc == nil
        {
            log.verbose_error("Invalid Buffer Descriptor Parameter")
            return {}, false
        }
    
        //Indices length error
        queue_indices_len := len(desc.queue_indices)
        if queue_indices_len < 1
        {
            log.verbose_error("Invalid Buffer Descriptor Queue Indices Length", desc.queue_indices)
            return {}, false
        }

        //Making create info
        info: vk.BufferCreateInfo
        info.sType = .BUFFER_CREATE_INFO
        info.flags = desc.flags
        info.usage = desc.usage
        info.size = cast(vk.DeviceSize)desc.size
        info.pQueueFamilyIndices = transmute([^]u32)commons.array_try_as_pointer(desc.queue_indices)
        info.queueFamilyIndexCount = cast(u32)commons.array_try_len(desc.queue_indices)
        info.sharingMode = queue_indices_len > 1 ? .CONCURRENT : .EXCLUSIVE

        //Creating buffer
        handle: vk.Buffer
        result := vk.CreateBuffer(device.handle, &info, nil, &handle)
        if result != .SUCCESS
        {
            log.verbose_error("Fail to Create Vulkan Buffer", result)
            return {}, false
        }

        //Cloning info
        buffer_requirements, r_success := buffer_get_requirements_from_handle(device, handle)
        if !r_success
        {
            log.verbose_error("Fail to Clone Buffer Indices from Descriptor")
            vk.DestroyBuffer(device.handle, handle, nil)
            return {}, false
        }

        buffer_queue_indices, qi_success := commons.array_clone(desc.queue_indices, allocator)
        if !qi_success
        {
            log.verbose_error("Fail to Clone Buffer Queue Indices from Descriptor")
            vk.DestroyBuffer(device.handle, handle, nil)
            return {}, false
        }

        //Making buffer
        buffer: Buffer
        buffer.allocator = allocator
        buffer.handle = handle
        buffer.usage = info.usage
        buffer.size = desc.size
        buffer.requirements = buffer_requirements
        buffer.queue_indices = buffer_queue_indices
        return buffer, true
    }

/*
Create buffers from descriptors.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_create_from_descriptor_multiple :: proc(device: ^Device, descriptors: []Buffer_Descriptor, allocator := context.allocator, location := #caller_location) -> ([]Buffer, bool) #optional_ok
    {
        //Checking device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return nil, false
        }

        //Checking descriptors parameter
        if descriptors == nil
        {
            log.verbose_error("Invalid buffer descriptors parameter")
            return nil, false
        }

        //Checking descriptors length
        descriptors_len := len(descriptors)
        if descriptors_len < 1
        {
            log.verbose_error("Invalid buffer descriptors count", descriptors, descriptors_len)
            return nil, false
        }

        //Allocating buffers slice
        buffers, buffer_alloc_err := make([]Buffer, descriptors_len, allocator)

        //Creating buffers
        created_buffer_count := 0
        for i := 0; i < descriptors_len; i += 1
        {
            descriptor := &descriptors[i]
            buffer, created := buffer_create(device, descriptor, allocator, location)
            if !created do break
            buffers[i] = buffer
            created_buffer_count += 1
        }

        //Checking buffers
        success := created_buffer_count == descriptors_len
        if !success
        {
            log.verbose_error("Failed to create all buffers, deleting the created ones", buffers)
            for i := 0; i < created_buffer_count; i += 1 do buffer_destroy(device, &buffers[i], location)
            delete(buffers, allocator)

            return nil, false
        }

        return buffers, true
    }

/*
Destroy single a buffer.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_destroy_single :: proc(device: ^Device, buffer: ^Buffer, location := #caller_location) -> bool
    {
        //Nil device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid Vulkan Device Parameter")
            return false
        }

        //Nil buffer parameter
        if !buffer_is_valid(buffer)
        {
            log.verbose_error("Invalid Vulkan Buffer Parameter")
            return false
        }

        //Destroying buffer
        vk.DestroyBuffer(device.handle, buffer.handle, nil)
        buffer.handle = 0

        //Deleting buffer
        allocator := buffer.allocator

        if buffer.queue_indices != nil
        {
            delete(buffer.queue_indices, allocator)
            buffer.queue_indices = nil
        }

        return true
    }

/*
Destroy multiple a buffers.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_destroy_multiple :: proc(device: ^Device, buffers: []Buffer, location := #caller_location) -> bool
    {
        //Checking device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return false
        }

        //Checking buffers parameter
        if !buffer_is_valid(buffers)
        {
            log.verbose_error("Invalid vulkan buffers parameter")
            return false
        }

        //Destroying buffers
        for i := 0; i < len(buffers); i += 1
        {
            buffer := &buffers[i]
            destroyed := buffer_destroy_single(device, buffer, location)
            if !destroyed do return false
        }

        return true
    }

/*
Filter physical device memory indices that matches to the buffer requirements.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_filter_memory_types_single :: proc(physical_device: ^Physical_Device, buffer: ^Buffer, property_flags: vk.MemoryPropertyFlags, allocator := context.allocator, location := #caller_location) -> ([]i32, bool)
    {
        //Nil physical device parameter
        if !physical_device_is_valid(physical_device)
        {
            log.verbose_error("Invalid Vulkan Physical Device Parameter")
            return nil, false
        }

        //Nil buffer parameter
        if !buffer_is_valid(buffer)
        {
            log.verbose_error("Invalid Vulkan Buffer Parameter")
            return nil, false
        }
 
        //Allocating matches
        matches, alloc_err := make([dynamic]i32, 0, physical_device.memory_properties.memoryTypeCount, context.temp_allocator, location)
        if alloc_err != .None
        {
            log.verbose_error("Allocate Buffer Filter Indices Matches Slice")
            return nil, false
        }
        defer delete(matches)

        //Filtering
        for i: u32 = 0; i < physical_device.memory_properties.memoryTypeCount; i += 1
        {
            types := physical_device.memory_properties.memoryTypes[i]

            support_type := bool((u32(1) << i) & buffer.requirements.memoryTypeBits)
            if !support_type do continue
            
            support_flags := types.propertyFlags & property_flags == property_flags
            if !support_flags do continue

            support := support_type && support_flags
            if support do append(&matches, i32(i))
        }

        //No matches check
        matches_len := len(matches)
        if matches_len < 1 do return nil, false

        return commons.slice_from_dynamic(matches, allocator)
    }

    buffer_support_memory_type_index :: proc{
        buffer_support_memory_type_index_single,
        buffer_support_memory_type_index_multiple,
    }

/*
Checks if buffer support memory type index and property flags.
*/
    buffer_support_memory_type_index_single :: proc(physical_device: ^Physical_Device, buffer: ^Buffer, type_index: u32, property_flags: vk.MemoryPropertyFlags) -> bool
    {
        if !physical_device_is_valid(physical_device) || !buffer_is_valid(buffer) || type_index > physical_device.memory_properties.memoryTypeCount do return false

        types := physical_device.memory_properties.memoryTypes[type_index]

        support_type := bool((u32(1) << type_index) & buffer.requirements.memoryTypeBits)
        if !support_type do return false
        
        support_flags := types.propertyFlags & property_flags == property_flags
        if !support_flags do return false

        return true
    }

/*
Checks if buffers support memory type index and property flags.
*/
    buffer_support_memory_type_index_multiple :: proc(physical_device: ^Physical_Device, buffers: []Buffer, type_index: u32, property_flags: vk.MemoryPropertyFlags) -> bool
    {
        if !physical_device_is_valid(physical_device) || !buffer_is_valid(buffers) || type_index > physical_device.memory_properties.memoryTypeCount do return false

        for i := 0; i < len(buffers); i += 1
        {
            support := buffer_support_memory_type_index_single(physical_device, &buffers[i], type_index, property_flags)
            if !support do return false
        }

        return true
    }

/*
Filter physical device memory indices that matches to the buffers requirements.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_filter_memory_types_multiple :: proc(physical_device: ^Physical_Device, buffers: []Buffer, property_flags: vk.MemoryPropertyFlags, allocator := context.allocator, location := #caller_location) -> ([]i32, bool)
    {
        //Nil physical device parameter
        if !physical_device_is_valid(physical_device)
        {
            log.verbose_error("Invalid Vulkan Physical Device Parameter")
            return nil, false
        }

        //Nil buffer parameter
        if !buffer_is_valid(buffers)
        {
            log.verbose_error("Invalid Vulkan Buffers Parameter")
            return nil, false
        }
 
        //Allocating matches
        matches, alloc_err := make([dynamic]i32, 0, physical_device.memory_properties.memoryTypeCount, context.temp_allocator, location)
        if alloc_err != .None
        {
            log.verbose_error("Allocate Buffer Filter Memory Type Indices Matches Slice")
            return nil, false
        }
        defer delete(matches)

        //Filtering
        for i: u32 = 0; i < physical_device.memory_properties.memoryTypeCount; i += 1
        {
            support := buffer_support_memory_type_index(physical_device, buffers, i, property_flags)
            if support do append(&matches, i32(i))
        }

        //No matches check
        matches_len := len(matches)
        if matches_len < 1
        {
            log.verbose_error("No Matches at Buffer Memory Type Indices Filtering")
            return nil, false
        }

        return commons.slice_from_dynamic(matches, allocator)
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_filter_memory_types_multiple_first :: proc(physical_device: ^Physical_Device, buffers: []Buffer, property_flags: vk.MemoryPropertyFlags) -> (i32, bool)
    {
        indices, success := buffer_filter_memory_types_multiple(physical_device, buffers, property_flags, context.temp_allocator)
        if !success do return -1, false
        defer delete(indices, context.temp_allocator)
        return indices[0], true
    }

/*
Bind a single buffer to memory.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_bind_memory_single :: proc(device: ^Device, memory: ^Memory, buffer: ^Buffer, offset: u64, location := #caller_location) -> bool
    {
        //Checking device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return false
        }

        //Checking device parameter
        if !memory_is_valid(memory)
        {
            log.verbose_error("Invalid vulkan memory parameter")
            return false
        }

        //Checking buffer parameter
        if !buffer_is_valid(buffer)
        {
            log.verbose_error("Invalid vulkan buffer parameter")
            return false
        }

        //Binding
        log.verbose_info("Binding vulkan buffer", buffer, "to memory", memory, "with offset of", offset)
        result := vk.BindBufferMemory(device.handle, buffer.handle, memory.handle, vk.DeviceSize(offset))
        if result != .SUCCESS
        {
            log.verbose_error(result, "Failed to bind vulkan buffer", buffer, "to memory", memory, "with offset of", offset)
            return false
        }

        log.verbose_debug("Binded vulkan buffer", buffer, "to memory", memory, "with offset of", offset)
        return true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_bind_memory_multiple_stacked :: proc(device: ^Device, memory: ^Memory, buffers: []Buffer, start_offset: u64, location := #caller_location) -> bool
    {
        //Checking device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return false
        }

        //Checking device parameter
        if !memory_is_valid(memory)
        {
            log.verbose_error("Invalid vulkan memory parameter")
            return false
        }

        //Checking buffer parameter
        if !buffer_is_valid(buffers)
        {
            log.verbose_error("Invalid vulkan buffers parameter")
            return false
        }
        
        //Checking if memory can store buffers size
        required_size := start_offset + buffer_get_required_size(buffers)
        if memory.size < required_size
        {
            log.verbose_error("Vulkan memory", memory, "cant store buffers", buffers, "required size to store buffers", required_size, "including start offset of", start_offset)
            return false
        }

        //Binding buffers
        required_alignment := buffer_get_required_alignment(buffers)
        offset := start_offset
        for i := 0; i < len(buffers); i += 1
        {
            buffer := &buffers[i]
            binded := buffer_bind_memory_single(device, memory, buffer, offset, location)
            if !binded do return false
            buffer_required_size := buffer_get_required_size(buffer, required_alignment)
            offset += buffer_required_size
        }

        log.verbose_debug("Vulkan buffers", buffers, "binded to memory", memory)
        return true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_copy_content_single :: proc(device: ^Device, memory: ^Memory, buffer: ^Buffer, offset: u64, content: rawptr) -> bool
    {
        //Checking device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return false
        }

        //Checking device parameter
        if !memory_is_valid(memory)
        {
            log.verbose_error("Invalid vulkan memory parameter")
            return false
        }

        //Checking buffer parameter
        if !buffer_is_valid(buffer)
        {
            log.verbose_error("Invalid vulkan buffer parameter")
            return false
        }

        //Checking content parameter
        if content == nil
        {
            log.verbose_error("Invalid content pointer parameter")
            return false
        }

        //Mapping memory
        log.verbose_debug("Mapping vulkan memory", memory, "with offset", offset)
        mapped_address: rawptr
        result := vk.MapMemory(device.handle, memory.handle, vk.DeviceSize(offset), buffer.requirements.size, {}, &mapped_address)
        if result != .SUCCESS
        {
            log.verbose_error(result, "Failed to map vulkan memory", memory, "with offset", offset)
            return false
        }
        log.verbose_debug("Vulkan memory mapped", mapped_address, memory, " with offset", offset)

        //Copying buffer to mapped memory
        log.verbose_debug("Copying source content", content, "with size of", buffer.size, "to mapped address", mapped_address)
        mem.copy(mapped_address, content, cast(int)buffer.size)
        log.verbose_debug("Source content copied", content, "with size of", buffer.size, "to mapped address", mapped_address)

        //Unmapping memory
        log.verbose_debug("Unmapping vulkan memory", memory)
        vk.UnmapMemory(device.handle, memory.handle)
        log.verbose_debug("Vulkan memory unmapped", memory)
        return true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_copy_content_multiple_stacked :: proc(device: ^Device, memory: ^Memory, buffers: []Buffer, contents: []rawptr, start_offset: u64) -> bool
    {
        //Checking device parameter
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return false
        }

        //Checking device parameter
        if !memory_is_valid(memory)
        {
            log.verbose_error("Invalid vulkan memory parameter")
            return false
        }

        //Checking buffer parameter
        if !buffer_is_valid(buffers)
        {
            log.verbose_error("Invalid vulkan buffers parameter")
            return false
        }

        //Checking contents parameter
        if contents == nil
        {
            log.verbose_error("Invalid contents slice parameter")
            return false
        }

        //Checking if memory can store buffers size
        required_size := start_offset + buffer_get_required_size(buffers)
        if memory.size < required_size
        {
            log.verbose_error("Vulkan memory", memory, "cant store buffers", buffers, "required size to store buffers", required_size, "including start offset of", start_offset)
            return false
        }

        //Copying contents
        offset := start_offset
        for i := 0; i < len(buffers); i += 1
        {
            buffer := &buffers[i]
            content := contents[i]
            copied := buffer_copy_content_single(device, memory, buffer, offset, content)
            if !copied
            {
                log.verbose_error("Failed to copy content", content, " to buffer", buffer, "index", i)
                return false
            }

            offset += cast(u64)buffer.requirements.size
        }

        log.verbose_debug("Buffers contents",  contents, "copied to buffers memory", buffers)
        return true
    }
}