package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    fence_create_from_descriptor :: proc(device: ^Device, desc: ^Fence_Descriptor, location := #caller_location) -> (Fence, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid fence descriptor parameter", location) do return {}, false

        //Making create info
        info: vk.FenceCreateInfo
        info.sType = .FENCE_CREATE_INFO
        info.flags = desc.flags

        //Creating fence
        handle: vk.Fence
        result := vk.CreateFence(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan fence", location) do return {}, false
        
        //Making fence
        fence: Fence
        fence.handle = handle
        return fence, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    fence_destroy :: proc(device: ^Device, fence: ^Fence, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!fence_is_valid(fence), "invalid vulkan fence parameter", location) do return false

        vk.DestroyFence(device.handle, fence.handle, nil)
        fence.handle = 0
        return true
    }
}