package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"
    import "core:runtime"

    @(export=api.SHARED, link_prefix=PREFIX)
    device_create_from_desc :: proc(physical_device: ^Physical_Device, desc: ^Device_Descriptor, allocator := context.allocator, location := #caller_location) -> (Device, bool) #optional_ok
    {
        graphics_do_transfer := desc.graphics_queue.index == desc.transfer_queue.index
        graphics_do_present := desc.graphics_queue.index == desc.present_queue.index
        transfer_do_present := desc.transfer_queue.index == desc.present_queue.index

        queue_infos_count := 1
        if !graphics_do_transfer do queue_infos_count += 1
        if !graphics_do_present do queue_infos_count += 1

        queue_infos, queue_infos_alloc_err := make([]vk.DeviceQueueCreateInfo, queue_infos_count, context.temp_allocator)
        if queue_infos_alloc_err != .None do return {}, false

        queue_infos_seek := 0
        
        //Graphics queues
        graphics_info: vk.DeviceQueueCreateInfo
        graphics_info.sType = .DEVICE_QUEUE_CREATE_INFO
        graphics_info.pQueuePriorities = commons.array_try_as_pointer(desc.graphics_queue.priorities)
        graphics_info.queueCount = cast(u32)commons.array_try_len(desc.graphics_queue.priorities)
        graphics_info.queueFamilyIndex = cast(u32)desc.graphics_queue.index
        queue_infos[queue_infos_seek] = graphics_info
        queue_infos_seek += 1
        
        //Transfer queues
        if !graphics_do_transfer
        {
            transfer_info: vk.DeviceQueueCreateInfo
            transfer_info.sType = .DEVICE_QUEUE_CREATE_INFO
            transfer_info.pQueuePriorities = commons.array_try_as_pointer(desc.transfer_queue.priorities)
            transfer_info.queueCount = cast(u32)commons.array_try_len(desc.transfer_queue.priorities)
            transfer_info.queueFamilyIndex = cast(u32)desc.transfer_queue.index
            queue_infos[queue_infos_seek] = transfer_info
            queue_infos_seek += 1
        }

        //Present queues
        if !graphics_do_present && !transfer_do_present
        {
            present_info: vk.DeviceQueueCreateInfo
            present_info.sType = .DEVICE_QUEUE_CREATE_INFO
            present_info.pQueuePriorities = commons.array_try_as_pointer(desc.present_queue.priorities)
            present_info.queueCount = cast(u32)commons.array_try_len(desc.present_queue.priorities)
            present_info.queueFamilyIndex = cast(u32)desc.present_queue.index
            queue_infos[queue_infos_seek] = present_info
            queue_infos_seek += 1
        }

        //Enabled extensions
        enabled_extensions, enabled_extensions_succ := commons.dynamic_from_slice(desc.extensions, context.temp_allocator) if desc.extensions != nil else make([dynamic]cstring, 0, 0, context.temp_allocator), true
        if log.verbose_fail_error(!enabled_extensions_succ, "create dynamic slice from enabled extensions slice", location) do return {}, false
        defer delete(enabled_extensions)

        //Add swapchain extension
        //append(&enabled_extensions, vk.KHR_SWAPCHAIN_EXTENSION_NAME)
        
        //Making create info
        info: vk.DeviceCreateInfo
        info.sType = .DEVICE_CREATE_INFO
        info.pQueueCreateInfos = commons.array_try_as_pointer(queue_infos)
        info.queueCreateInfoCount = cast(u32)commons.array_try_len(queue_infos)
        info.ppEnabledExtensionNames = commons.array_try_as_pointer(enabled_extensions)
        info.enabledExtensionCount = cast(u32)commons.array_try_len(enabled_extensions)
        info.pEnabledFeatures = desc.features

        //Creating device
        handle: vk.Device
        result := vk._create_device(physical_device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan device", location) do return {}, false

        //Getting graphics queues
        graphics_queues: []Queue
        {
            success: bool
            graphics_queues, success = queue_enumerate_from_handle(handle, &desc.graphics_queue, allocator)
            if log.verbose_fail_error(!success, "enumerate vulkan device graphics queues", location)
            {
                vk.DestroyDevice(handle, nil)
                return {}, false
            }
        }

        //Getting transfer queues
        transfer_queues: []Queue
        if !graphics_do_transfer
        {
            success: bool
            transfer_queues, success = queue_enumerate_from_handle(handle, &desc.transfer_queue, allocator)
            if log.verbose_fail_error(!success, "enumerate vulkan device transfer queues", location)
            {
                vk.DestroyDevice(handle, nil)
                return {}, false
            }
        }

        //Getting present queues
        present_queues: []Queue
        if !graphics_do_present && !transfer_do_present
        {
            success: bool
            present_queues, success = queue_enumerate_from_handle(handle, &desc.present_queue, allocator)
            if log.verbose_fail_error(!success, "enumerate vulkan device present queues", location)
            {
                vk.DestroyDevice(handle, nil)
                return {}, false
            }
        }

        //Cloning infos
        device_features := desc.features != nil ? desc.features^ : {}
        device_extensions := commons.cstring_clone_dynamic(&enabled_extensions, allocator, location)

        //Making device
        device: Device
        device.allocator = allocator
        device.features = device_features
        device.extensions = device_extensions
        device.graphics_queues = graphics_queues
        device.transfer_queues = transfer_queues
        device.present_queues = present_queues
        device.handle = handle
        return device, true
    }

/*
Destroy a single device.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    device_destroy :: proc(device: ^Device, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false

        allocator := device.allocator

        if device.handle != nil
        {
            vk.DestroyDevice(device.handle, nil)
            device.handle = nil
        }

        if device.extensions != nil
        {
            for extension in device.extensions do delete(extension, allocator)
            delete(device.extensions, allocator)
            device.extensions = nil
        }

        if device.graphics_queues != nil
        {
            delete(device.graphics_queues, allocator)
            device.graphics_queues = nil
        }

        if device.transfer_queues != nil
        {
            delete(device.transfer_queues, allocator)
            device.transfer_queues = nil
        }

        if device.present_queues != nil
        {
            delete(device.present_queues, allocator)
            device.present_queues = nil
        }

        return true
    }
}