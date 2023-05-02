package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

/*
TODO
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    queue_enumerate_infos_from_handle :: proc(physical_device: vk.PhysicalDevice, allocator := context.allocator, location := #caller_location) -> ([]Queue_Info, bool) #optional_ok
    {
        if log.verbose_fail_error(physical_device == nil, "invalid vulkan physical device handle parameter", location) do return nil, false
        
        queue_info_count: u32
        vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_info_count, nil)
        if log.verbose_fail_error(queue_info_count < 1, "enumerate physical device queues, count querry", location) do return nil, false
        
        queue_families, alloc_err := make([]vk.QueueFamilyProperties, queue_info_count, context.temp_allocator)
        if log.verbose_fail_error(alloc_err != .None, "make physical device queues family properties slice", location) do return nil, false
        defer delete(queue_families, context.temp_allocator)
        
        vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_info_count, commons.array_try_as_pointer(queue_families))
        
        queue_infos, queue_infos_alloc_err := make([]Queue_Info, queue_info_count, allocator)
        if log.verbose_fail_error(queue_infos_alloc_err != .None, "make queues infos slice", location) do return nil, false

        for queue_family, index in queue_families
        {
            queue_info: Queue_Info
            queue_info.flags = queue_family.queueFlags
            queue_info.index = cast(i32)index
            queue_info.count = cast(i32)queue_family.queueCount
            queue_info.presentation = queue_support_presentation_from_handle(physical_device, u32(index))
            queue_infos[index] = queue_info
        }

        return queue_infos, true
    }

/*
TODO
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    queue_enumerate_infos :: proc(physical_device: ^Physical_Device, allocator := context.allocator, location := #caller_location) -> ([]Queue_Info, bool) #optional_ok
    {
        if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter", location) do return nil, false
        
        queue_info_count: u32
        vk.GetPhysicalDeviceQueueFamilyProperties(physical_device.handle, &queue_info_count, nil)
        if log.verbose_fail_error(queue_info_count < 1, "enumerate physical device queues, count querry", location) do return nil, false
        
        queue_families, alloc_err := make([]vk.QueueFamilyProperties, queue_info_count, context.temp_allocator)
        if log.verbose_fail_error(alloc_err != .None, "make physical device queues family properties slice", location) do return nil, false
        defer delete(queue_families, context.temp_allocator)
        
        vk.GetPhysicalDeviceQueueFamilyProperties(physical_device.handle, &queue_info_count, commons.array_try_as_pointer(queue_families))
        
        queue_infos, queue_infos_alloc_err := make([]Queue_Info, queue_info_count, allocator)
        if log.verbose_fail_error(queue_infos_alloc_err != .None, "make queues infos slice", location) do return nil, false

        for queue_family, index in queue_families
        {
            queue_info: Queue_Info
            queue_info.flags = queue_family.queueFlags
            queue_info.index = cast(i32)index
            queue_info.count = cast(i32)queue_family.queueCount
            queue_info.presentation = queue_support_presentation(physical_device, u32(index))
            queue_infos[index] = queue_info
        }

        return queue_infos, true
    }

/*
TODO
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    queue_filter :: proc(physical_device: ^Physical_Device, filter: ^Queue_Filter, allocator := context.allocator, location := #caller_location) -> ([]Queue_Info, bool) #optional_ok
    {
        if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter", location) do return nil, false
        
        queue_infos, queue_infos_succ := queue_enumerate_infos(physical_device, context.temp_allocator)
        if log.verbose_fail_error(!queue_infos_succ, "enumerate queue infos", location) do return nil, false
        defer delete(queue_infos, context.temp_allocator)
        
        queue_infos_len := len(queue_infos)
        matches, alloc_err := make([dynamic]Queue_Info, 0, queue_infos_len, context.temp_allocator)
        if log.verbose_fail_error(alloc_err != .None, "make queue info matches dynamic slice", location) do return nil, false
        defer delete(matches)

        for queue_info, index in queue_infos
        {
            ignore := bool(queue_info.flags & filter.ignore_flags != {})
            if ignore do continue
            
            pass_flags := queue_info.flags & filter.require_flags == filter.require_flags
            pass_count := queue_info.count >= filter.require_count
            pass_presentation := filter.require_presentation ?  queue_info.presentation : true
            match := pass_flags && pass_count && pass_presentation
            if match do append(&matches, queue_info)
        }

        matches_len := len(matches)
        if log.verbose_fail_error(matches_len < 1, "no match", location) do return nil, false

        return commons.slice_from_dynamic(matches, allocator)
    }

/*
Enumerate queues of vulkan device handle.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    queue_enumerate_from_handle :: proc(device: vk.Device, queue_desc: ^Queue_Descriptor, allocator := context.allocator, location := #caller_location) -> ([]Queue, bool) #optional_ok
    {
        if log.verbose_fail_error(device == nil, "invalid vulkan device handle parameter", location) do return nil, false
        if log.verbose_fail_error(queue_desc == nil, "invalid queue descriptor parameter", location) do return nil, false
        if log.verbose_fail_error(queue_desc.index < 0, "invalid queue descriptor index", location) do return nil, false
        if log.verbose_fail_error(queue_desc.priorities == nil, "invalid queue descriptor priorities", location) do return nil, false
        
        priorities_len := len(queue_desc.priorities)
        if log.verbose_fail_error(priorities_len < 1, "invalid priorities length", location) do return nil, false

        queues, queues_alloc_err := make([]Queue, priorities_len, allocator)
        if log.verbose_fail_error(queues_alloc_err != .None, "make queues slice", location) do return nil, false

        for i := 0; i < priorities_len; i += 1
        {
            queue: Queue
            queue.index = queue_desc.index
            queue.priority = queue_desc.priorities[i]

            queue_handle: vk.Queue
            vk.GetDeviceQueue(device, cast(u32)queue_desc.index, cast(u32)i, &queue_handle)
            queue.handle = queue_handle

            queues[i] = queue
        }

        return queues, true
    }
}