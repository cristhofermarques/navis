package vulkan

import "vk"
import "navis:commons"

/*
TODO
*/
Physical_Device_Filter :: struct
{
    api_version: u32,
    type_: vk.PhysicalDeviceType,
    graphics_queue_filter: Queue_Filter,
    transfer_queue_filter: Queue_Filter,
    present_queue_filter: Queue_Filter,
}

/*
Vulkan physical device.
*/
Physical_Device :: struct
{
    features: vk.PhysicalDeviceFeatures,
    properties: vk.PhysicalDeviceProperties,
    handle: vk.PhysicalDevice,
}

/*
TODO
*/
physical_device_is_valid :: #force_inline proc(physical_device: ^Physical_Device) -> bool
{
    return physical_device != nil && physical_device.handle != nil
}

/*
Return physical device features.
*/
physical_device_get_features :: #force_inline proc(physical_device: vk.PhysicalDevice) -> vk.PhysicalDeviceFeatures
{
    physical_device_features: vk.PhysicalDeviceFeatures
    vk.GetPhysicalDeviceFeatures(physical_device, &physical_device_features)
    return physical_device_features
}

/*
Return physical device properties
*/
physical_device_get_properties :: #force_inline proc(physical_device: vk.PhysicalDevice) -> vk.PhysicalDeviceProperties
{
    physical_device_properties: vk.PhysicalDeviceProperties
    vk.GetPhysicalDeviceProperties(physical_device, &physical_device_properties)
    return physical_device_properties
}

/*
Return physical device queue family properties
*/
physical_device_get_queue_family_properties :: proc(physical_device: vk.PhysicalDevice, allocator := context.allocator) -> ([]vk.QueueFamilyProperties, bool) #optional_ok
{
    queue_family_count: u32
    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, nil)
    if queue_family_count < 1 do return nil, false
    
    queue_families_properties, alloc_err := make([]vk.QueueFamilyProperties, queue_family_count, allocator)
    if alloc_err != .None do return nil, false

    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, commons.array_try_as_pointer(queue_families_properties))
    return queue_families_properties, true
}