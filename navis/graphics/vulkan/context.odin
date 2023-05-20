package vulkan

import "navis:api"

when api.EXPORT
{
    import "navis:commons/log"

/*
Create a vulkan context.
* Device queue descriptor dont require to set indices.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    context_create_from_descriptor :: proc(desc: ^Context_Descriptor, allocator := context.allocator, location := #caller_location) -> (Context, bool) #optional_ok
    {
        if log.verbose_fail_error(desc == nil, "invalid context descriptor parameter", location) do return {}, false
        
        success: bool
        instance: Instance
        instance, success = instance_create(&desc.instance)
        if log.verbose_fail_error(!success, "create vulkan instance for context", location) do return {}, false
        
        debugger: Debugger
        when ODIN_DEBUG
        {
            debugger, success = debugger_create(&instance, &desc.debugger, allocator, location)
            if log.verbose_fail_error(!success, "create vulkan debugger for context", location)
            {
                instance_destroy(&instance)
                return {}, false
            }
        }

        
        physical_device: Physical_Device
        queues_info: Queues_Info
        physical_device, queues_info, success = physical_device_filter_first(&instance, &desc.physical_device, allocator, location)
        if log.verbose_fail_error(!success, "filter vulkan physical device for context", location)
        {
            when ODIN_DEBUG do debugger_destroy(&instance, &debugger, location)
            instance_destroy(&instance)
            return {}, false
        }
        
        //Setup graphics queue family index
        graphics_index := queues_info.graphics[0].index //NOTE(cris): first one is usually sutable.
        desc.device.graphics_queue.index = graphics_index

        //Setup transfer queue family index
        transfer_index := queues_info.transfer[0].index //NOTE(cris): first one is usually sutable.
        desc.device.transfer_queue.index = transfer_index

        //Setup present queue family index
        present_index := queues_info.present[0].index //NOTE(cris): first one is usually sutable.
        desc.device.present_queue.index = present_index

        device: Device
        device, success = device_create(&physical_device, &desc.device, allocator, location)
        if log.verbose_fail_error(!success, "create vulkan device for context", location)
        {
            when ODIN_DEBUG do debugger_destroy(&instance, &debugger, location)
            instance_destroy(&instance)
            return {}, false
        }

        context_: Context
        context_.allocator = allocator
        context_.instance = instance
        when ODIN_DEBUG do context_.debugger = debugger
        context_.physical_device = physical_device
        context_.queues_info = queues_info
        context_.device = device
        return context_, true
    }

/*
Destroy a vulkan context.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    context_destroy :: proc(context_: ^Context, location := #caller_location) -> bool
    {
        if context_ == nil do return false
        allocator := context_.allocator // not the odin context :)
        
        device_destroy(&context_.device, location)
        queues_info_delete(&context_.queues_info, location)
        physical_device_delete(&context_.physical_device)
        when ODIN_DEBUG do debugger_destroy(&context_.instance, &context_.debugger, location)
        instance_destroy(&context_.instance)
        return true
    }
}