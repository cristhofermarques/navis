package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"
    import "core:runtime"

    Buffer_Descriptor :: struct
    {
        flags: vk.BufferCreateFlags,
        usage: vk.BufferUsageFlags,
        indices: []i32,
        size: uint,
    }

    Buffer :: struct
    {
        allocator: runtime.Allocator,
        usage: vk.BufferUsageFlags,
        indices: []i32,
        size: uint,
        requirements: vk.MemoryRequirements,
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    buffer_create_from_descriptor :: proc(device: ^Device, desc: ^Buffer_Descriptor, allocator := context.allocator, location := #caller_location) -> (Buffer, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid buffer descriptor parameter", location) do return {}, false
        
        indices_len := len(desc.indices)
        if log.verbose_fail_error(indices_len < 1, "invalid descriptor indices length", location) do return {}, false


        info: vk.BufferCreateInfo
        info.sType = .BUFFER_CREATE_INFO
        info.flags = desc.flags
        info.usage = desc.usage
        return {}, false
    }
}