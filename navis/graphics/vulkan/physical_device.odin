package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

/*
Enumerate physical devices.

Return physical devices slice.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    physical_device_enumerate :: proc(instance: ^Instance, allocator := context.allocator) -> ([]vk.PhysicalDevice, bool) #optional_ok
    {
        if log.verbose_fail_error(instance == nil, "vulkan instance parameter is nil") do return nil, false
        if log.verbose_fail_error(!instance_is_valid(instance), "vulkan instance is invalid") do return nil, false
        
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
}