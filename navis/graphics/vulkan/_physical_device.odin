package vulkan

import "vk"
import "navis:commons"
import "core:runtime"

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
    allocator: runtime.Allocator,
    features: vk.PhysicalDeviceFeatures,
    properties: vk.PhysicalDeviceProperties,
    memory_properties: vk.PhysicalDeviceMemoryProperties,
    queue_infos: []Queue_Info,
    handle: vk.PhysicalDevice,
}

/*
Clone physical device.
*/
physical_device_clone :: proc(physical_device: ^Physical_Device, allocator := context.allocator) -> (Physical_Device, bool) #optional_ok
{
    if physical_device == nil do return {}, false
    
    queue_infos_len := len(physical_device.queue_infos)
    if queue_infos_len < 1 do return {}, false

    queue_infos, queue_infos_alloc_err := make([]Queue_Info, queue_infos_len, allocator)
    if queue_infos_alloc_err != .None do return {}, false
    for queue_info, index in physical_device.queue_infos do queue_infos[index] = queue_info

    clone := physical_device^
    clone.allocator = allocator
    clone.queue_infos = queue_infos
    return clone, true
}

/*
Delete a single physical device.
*/
physical_device_delete_single :: proc(physical_device: ^Physical_Device) -> bool
{
    if physical_device == nil do return false

    allocator := physical_device.allocator
    if physical_device.queue_infos != nil
    {
        delete(physical_device.queue_infos, allocator)
        physical_device.queue_infos = nil
    }

    return true
}

/*
Delete a physical device slice.
*/
physical_device_delete_slice :: proc(physical_devices: []Physical_Device) -> bool
{
    if physical_devices == nil do return false
    for pd, i in physical_devices do physical_device_delete_single(&physical_devices[i])
    return true
}

physical_device_delete :: proc{
    physical_device_delete_single,
    physical_device_delete_slice,
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
Return physical device memory properties
*/
physical_device_get_memory_properties :: #force_inline proc(physical_device: vk.PhysicalDevice) -> vk.PhysicalDeviceProperties
{
    properties: vk.PhysicalDeviceMemoryProperties
    vk.GetPhysicalDeviceMemoryProperties(physical_device, &properties)
    return properties
}

/*
Return physical device queue family properties
*/
physical_device_get_queue_family_properties :: proc(physical_device: vk.PhysicalDevice, allocator := context.allocator) -> ([]vk.QueueFamilyProperties, bool)
{
    queue_family_count: u32
    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, nil)
    if queue_family_count < 1 do return nil, false
    
    queue_families_properties, alloc_err := make([]vk.QueueFamilyProperties, queue_family_count, allocator)
    if alloc_err != .None do return nil, false

    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, commons.array_try_as_pointer(queue_families_properties))
    return queue_families_properties, true
}