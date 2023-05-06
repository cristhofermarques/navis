package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"
/*
Create a command pool from descriptor.
*/
    @(export=api.EXPORT, link_prefix=PREFIX)
    command_pool_create_from_descriptor :: proc(device: ^Device, desc: ^Command_Pool_Descriptor, location := #caller_location) -> (Command_Pool, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        
        //Making create info
        info: vk.CommandPoolCreateInfo
        info.sType = .COMMAND_POOL_CREATE_INFO
        info.flags = desc.flags
        info.queueFamilyIndex = cast(u32)desc.index
        
        //Creating command pool
        handle: vk.CommandPool
        result := vk.CreateCommandPool(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan command pool", location) do return {}, false

        //Making command pool
        command_pool: Command_Pool
        command_pool.index = desc.index
        command_pool.handle = handle
        return command_pool, true
    }

/*
Create a command pool from parameters.
*/
    @(export=api.EXPORT, link_prefix=PREFIX)
    command_pool_create_from_parameters :: proc(device: ^Device, flags: vk.CommandPoolCreateFlags, index: i32, location := #caller_location) -> (Command_Pool, bool) #optional_ok
    {
        desc: Command_Pool_Descriptor
        desc.flags = flags
        desc.index = index
        return command_pool_create_from_descriptor(device, &desc, location)
    }

    @(export=api.EXPORT, link_prefix=PREFIX)
    command_pool_destroy :: proc(device: ^Device, command_pool: ^Command_Pool, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!command_pool_is_valid(command_pool), "invalid vulkan command pool parameter", location) do return false

        vk.DestroyCommandPool(device.handle, command_pool.handle, nil)
        command_pool.handle = 0
        
        return true
    }
}