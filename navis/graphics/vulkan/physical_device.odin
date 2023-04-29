package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"
    import "navis:graphics/ui"

/*
Enumerate physical devices.

Return physical devices slice.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    physical_device_enumerate_handles :: proc(instance: ^Instance, allocator := context.allocator) -> ([]vk.PhysicalDevice, bool) #optional_ok
    {
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance parameter") do return nil, false
        
        result: vk.Result
        physical_device_count: u32 = 0
        result = vk.EnumeratePhysicalDevices(instance.handle, &physical_device_count, nil)
        if log.verbose_fail_error(result != .SUCCESS, "enumerate physical devices, count querry") do return nil, false
        
        physical_devices, alloc_err := make([]vk.PhysicalDevice, physical_device_count, allocator)
        if log.verbose_fail_error(alloc_err != .None, "make physical devices slice") do return nil, false
        
        result = vk.EnumeratePhysicalDevices(instance.handle, &physical_device_count, commons.array_try_as_pointer(physical_devices))
        if log.verbose_fail_error(result != .SUCCESS, "enumerate physical devices, fill querry")
        {
            delete(physical_devices, allocator)
            return nil, false
        }

        return physical_devices, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    physical_device_enumerate :: proc(instance: ^Instance, allocator := context.allocator) -> ([]Physical_Device, bool) #optional_ok
    {
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance parameter") do return nil, false
        
        handles, handles_succ := physical_device_enumerate_handles(instance, context.temp_allocator)
        if log.verbose_fail_error(!handles_succ, "enumerate vulkan physical device handles") do return nil, false
        defer delete(handles, context.temp_allocator)
        
        handles_len := len(handles)
        physical_devices, physical_devices_alloc_err := make([]Physical_Device, handles_len, allocator)
        if log.verbose_fail_error(physical_devices_alloc_err != .None, "make vulkan physical device slice") do return nil, false

        for handle, index in handles
        {
            physical_device: Physical_Device
            physical_device.features = physical_device_get_features(handle)
            physical_device.properties = physical_device_get_properties(handle)
            physical_device.handle = handle
            physical_devices[index] = physical_device
        }

        return physical_devices, true
    }

/*
Filter physical devices, first one that matches will be choosed.
*/
    // @(export=api.SHARED, link_prefix=PREFIX)
    // physical_device_filter :: proc(instance: ^Instance, filter: ^Physical_Device_Filter) -> (Physical_Device, bool) #optional_ok
    // {
    //     if log.verbose_fail_error(instance == nil, "nil vulkan instance parameter") do return nil, false
    //     if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance") do return nil, false
    //     if log.verbose_fail_error(filter == nil, "nil physical device filter parameter") do return nil, false
        
    //     //Enumerating physical devices
    //     physical_devices, physical_devices_succ := physical_device_enumerate(instance, context.temp_allocator)
    //     if log.verbose_fail_error(!physical_devices_succ, "enumerate physical devices") do return nil, false
    //     defer delete(physical_devices, context.temp_allocator)
        
    //     //Creating window
    //     window, window_succ := ui.window_create_from_parameters("", 0, 0, .Borderless, context.temp_allocator)
    //     if log.verbose_fail_error(!window_succ, "create dummy window") do return nil, false
    //     defer ui.window_destroy(&window)
        
    //     surface, surface_succ := surface_create(instance, &window)
    //     if log.verbose_fail_error(!surface_succ, "create dummy surface") do return nil, false
    //     defer ui.window_destroy(&window)

    //     for physical_device, index in physical_devices
    //     {
    //         //Pre sutability
    //         properties := physical_device_get_properties(physical_device)
    //         correct_type := properties.deviceType == filter.type_
    //         support_api_version := properties.apiVersion >= filter.api_version
    //         pre_sutable := correct_type && support_api_version
    //         if !pre_sutable do continue

    //         physical_device: Physical_Device
    //         physical_device.handle = vk_physical_device
    //         physical_device.api_version = filter.api_version
    //         physical_device._type = filter.physical_device_type
            
    //         physical_device.queues.graphics.index = INVALID_QUEUE_FAMILY_INDEX
    //         physical_device.queues.transfer.index = INVALID_QUEUE_FAMILY_INDEX
    //         physical_device.queues.present.index = INVALID_QUEUE_FAMILY_INDEX
            
    //         //Queues selection
    //         physical_device.queues.graphics, success = get_filter_queue_family_indices_first(vk_physical_device, surface, &filter.queues.graphics)
    //         if !success do continue

    //         physical_device.queues.transfer, success = get_filter_queue_family_indices_first(vk_physical_device, surface, &filter.queues.transfer)
    //         if !success do continue

    //         physical_device.queues.present, success = get_filter_queue_family_indices_first(vk_physical_device, surface, &filter.queues.present)
    //         if !success do continue

    //         //Queues relation
    //         physical_device.queues.graphics_transfer = queues_graphics_transfer(&physical_device.queues)
    //         physical_device.queues.graphics_present = queues_graphics_present(&physical_device.queues)

    //         return physical_device, true
    //     }

    //     return {}, false
    // }
}