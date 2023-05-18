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
    memory_create_from_descriptor :: proc(device: ^Device, descriptor: ^Memory_Descriptor) -> (Memory, bool) #optional_ok
    {
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return {}, false
        }

        if !memory_descriptor_is_valid(descriptor)
        {
            log.verbose_error("Invalid vulkan memory descriptor parameter")
            return {}, false
        }

        //Making allocate info
        info: vk.MemoryAllocateInfo
        info.sType = .MEMORY_ALLOCATE_INFO
        info.memoryTypeIndex = cast(u32)descriptor.type_index
        info.allocationSize = cast(vk.DeviceSize)descriptor.size

        //Allocating memory
        log.verbose_info("Allocating vulkan memory", info)
        handle: vk.DeviceMemory
        result := vk.AllocateMemory(device.handle, &info, nil, &handle)
        if result != .SUCCESS
        {
            log.verbose_error("Fail to allocate vulkan memory", info)
            return {}, false
        }

        //Making memory
        memory: Memory
        memory.handle = handle
        memory.type_index = descriptor.type_index
        memory.size = descriptor.size

        log.verbose_info("Vulkan memory allocated", memory)
        return memory, true
    }

/*
Destroy a device memory.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    memory_destroy :: proc(device: ^Device, memory: ^Memory) -> bool
    {
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter")
            return false
        }

        if !memory_is_valid(memory)
        {
            log.verbose_error("Invalid vulkan memory parameter")
            return false
        }

        //Freeding memory
        log.verbose_info("Freeding vulkan memory", memory)
        vk.FreeMemory(device.handle, memory.handle, nil)
        memory.handle = 0
        
        log.verbose_info("Vulkan memory freed")
        return true
    }
}