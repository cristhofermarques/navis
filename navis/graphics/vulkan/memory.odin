package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"

/*
Create a device memory.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    memory_create_from_descriptor :: proc(device: ^Device, desc: ^Memory_Descriptor, location := #caller_location) -> (Memory, bool) #optional_ok
    {
        if !device_is_valid(device)
        {
            log.verbose_error(args = {"Invalid Vulkan Device Parameter"}, sep = " ", location = location)
            return {}, false
        }

        if desc == nil
        {
            log.verbose_error(args = {"Invalid Memory Descriptor Parameter"}, sep = " ", location = location)
            return {}, false
        }

        //Making allocate info
        info: vk.MemoryAllocateInfo
        info.sType = .MEMORY_ALLOCATE_INFO
        info.memoryTypeIndex = cast(u32)desc.type_index
        info.allocationSize = cast(vk.DeviceSize)desc.size

        //Allocating memory
        handle: vk.DeviceMemory
        result := vk.AllocateMemory(device.handle, &info, nil, &handle)
        if result != .SUCCESS
        {
            log.verbose_error(args = {"Fail to Allocate Memory", info}, sep = " ", location = location)
            return {}, false
        }

        //Making memory
        memory: Memory
        memory.handle = handle
        memory.type_index = desc.type_index
        memory.size = desc.size
        return memory, true
    }

/*
Destroy a device memory.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    memory_destroy :: proc(device: ^Device, memory: ^Memory, location := #caller_location) -> bool
    {
        if !device_is_valid(device)
        {
            log.verbose_error(args = {"Invalid Vulkan Device Parameter"}, sep = " ", location = location)
            return false
        }

        if !memory_is_valid(memory)
        {
            log.verbose_error(args = {"Invalid Vulkan Memory Parameter"}, sep = " ", location = location)
            return false
        }

        vk.FreeMemory(device.handle, memory.handle, nil)
        memory.handle = 0

        return true
    }
}