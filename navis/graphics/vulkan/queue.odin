package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    queue_support_presentation_from_index :: proc(physical_device: ^Physical_Device, index: u32, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter", location) do return false
        return cast(bool)vk.GetPhysicalDeviceWin32PresentationSupportKHR(physical_device.handle, index)
    }

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
            queue_info.presentation = queue_support_presentation_from_index(physical_device, u32(index))
            queue_infos[index] = queue_info
        }

        return queue_infos, true
    }

    // queue_filter :: proc(physical_device: ^Physical_Device, surface:^ Surface, filter: ^Queue_Filter, allocator := context.allocator) -> ([]Queue_Info, bool)
    // {
    //     queue_families: []vk.QueueFamilyProperties = get_physical_device_queue_family_properties(physical_device, context.temp_allocator)
    //     defer delete(queue_families, context.temp_allocator)

    //     queue_family_count := len(queue_families)
    //     queue_indices :[dynamic]Queue_Info = make([dynamic]Queue_Info, 0, queue_family_count, allocator)
    //     for queue_family, queue_family_index in queue_families
    //     {
    //         ignore := (queue_family.queueFlags & filter.ignore_flags) != {}
    //         if ignore do continue
            
    //         support_flags := queue_family.queueFlags & filter.flags == filter.flags
    //         support_count := queue_family.queueCount >= filter.count
    //         support_presentation := queue_support_presentation(physical_device, surface, u32(queue_family_index))
    //         presentation := filter.presentation ?  support_presentation : true

    //         queue_info: Queue_Info
    //         queue_info.flags = queue_family.queueFlags
    //         queue_info.max = queue_family.queueCount
    //         queue_info.index = u32(queue_family_index)
    //         queue_info.presentation = support_presentation

    //         support := support_flags && support_count && presentation
    //         if support do append(&queue_indices, queue_info)
    //     }

    //     success: bool = len(queue_indices) > 0
    //     if !success do delete(queue_families)
    //     return queue_indices, success
    // }
}