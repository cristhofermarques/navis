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
            physical_device.allocator = allocator
            physical_device.features = physical_device_get_features(handle)
            physical_device.properties = physical_device_get_properties(handle)
            physical_device.memory_properties = physical_device_get_memory_properties(handle)
            physical_device.queue_infos = queue_enumerate_infos_from_handle(handle, allocator)
            physical_device.handle = handle
            physical_devices[index] = physical_device
        }

        return physical_devices, true
    }

/*
Filter physical devices, first one that matches will be choosed.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    physical_device_filter :: proc(instance: ^Instance, filter: ^Physical_Device_Filter, allocator := context.allocator, location := #caller_location) -> ([]Physical_Device, []Queues_Info, bool)
    {
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance parameter", location) do return nil, nil, false
        
        //Enumerating physical devices
        physical_devices, physical_devices_succ := physical_device_enumerate(instance, context.temp_allocator)
        if log.verbose_fail_error(!physical_devices_succ, "enumerate physical devices", location) do return nil, nil, false
        defer for pd, i in physical_devices do physical_device_delete(&physical_devices[i])
        defer delete(physical_devices, context.temp_allocator)

        physical_devices_len := len(physical_devices)

        pd_matches, pd_matches_alloc_err := make([dynamic]Physical_Device, 0, physical_devices_len, context.temp_allocator)
        if log.verbose_fail_error(pd_matches_alloc_err != .None, "make physical device matches dynamic slice", location) do return nil, nil, false
        defer delete(pd_matches)

        qi_matches, qi_matches_alloc_err := make([dynamic]Queues_Info, 0, physical_devices_len, context.temp_allocator)
        if log.verbose_fail_error(qi_matches_alloc_err != .None, "make queues info matches dynamic slice", location) do return nil, nil, false
        defer delete(qi_matches)

        //Forcing queues
        incl_elem(&filter.graphics_queue_filter.require_flags, vk.QueueFlag.GRAPHICS)
        incl_elem(&filter.transfer_queue_filter.require_flags, vk.QueueFlag.TRANSFER)
        filter.present_queue_filter.require_presentation = true

        for physical_device, index in physical_devices
        {
            p_physical_device := &physical_devices[index]

            //Pre sutability
            correct_type := physical_device.properties.deviceType == filter.type_
            support_api_version := physical_device.properties.apiVersion >= filter.api_version
            pre_sutable := correct_type && support_api_version
            if !pre_sutable do continue

            //Queues selection
            graphics_queue_infos, graphics_queue_infos_succ := queue_filter(p_physical_device, &filter.graphics_queue_filter, allocator)
            if !graphics_queue_infos_succ do continue

            transfer_queue_infos, transfer_queue_infos_succ := queue_filter(p_physical_device, &filter.transfer_queue_filter, allocator)
            if !transfer_queue_infos_succ
            {
                delete(graphics_queue_infos, allocator)
                continue
            }

            present_queue_infos, present_queue_infos_succ := queue_filter(p_physical_device, &filter.present_queue_filter, allocator)
            if !present_queue_infos_succ
            {
                delete(transfer_queue_infos, allocator)
                delete(graphics_queue_infos, allocator)
                continue
            }

            queue_infos: Queues_Info
            queue_infos.allocator = allocator
            queue_infos.graphics = graphics_queue_infos
            queue_infos.transfer = transfer_queue_infos
            queue_infos.present = present_queue_infos

            //Match
            pd, pd_succ := physical_device_clone(p_physical_device, allocator)
            if log.verbose_fail_error(!pd_succ, "clone vulkan physical device", location) do continue
            append(&pd_matches, pd)
            append(&qi_matches, queue_infos)
        }

        pd_matches_len := len(pd_matches)
        qi_matches_len := len(qi_matches)
        if log.verbose_fail_error(pd_matches_len != qi_matches_len || pd_matches_len < 1 || qi_matches_len < 1, "invalid matche dynamic slices length", location) do return nil, nil, false
        
        pds, pds_succ := commons.slice_from_dynamic(pd_matches, allocator)
        if log.verbose_fail_error(!pds_succ, "making physical devices slice from dynamic slice matches", location) do return nil, nil, false

        qis, qis_succ := commons.slice_from_dynamic(qi_matches, allocator)
        if log.verbose_fail_error(!qis_succ, "making queue infos slice from dynamic slice matches", location)
        {
            for pd, i in pds do physical_device_delete(&pds[i])
            delete(pds, allocator)
            return nil, nil, false
        }

        //Success
        return pds, qis, true
    }

/*
Filter physical devices, first one that matches will be choosed.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    physical_device_filter_first :: proc(instance: ^Instance, filter: ^Physical_Device_Filter, allocator := context.allocator, location := #caller_location) -> (Physical_Device, Queues_Info, bool)
    {
        physical_devices, queues_infos, success :=  physical_device_filter(instance, filter, allocator, location)
        if !success do return {}, {}, false
        defer delete(physical_devices, allocator)
        defer physical_device_delete(physical_devices)
        defer delete(queues_infos, allocator)
        defer queues_info_delete(queues_infos)

        physical_device, physical_device_succ := physical_device_clone(&physical_devices[0], allocator)
        if !physical_device_succ do return {}, {}, false
        
        queues_info, queues_info_succ := queues_info_clone(&queues_infos[0], allocator, location)
        if !queues_info_succ
        {
            physical_device_delete(&physical_device)
            return {}, {}, false
        }

        return physical_device, queues_info, true
    }
}