package vulkan

import "vk"
import "core:runtime"


/*
TODO
*/
Device_Descriptor :: struct
{
    extensions: []cstring,
    features: ^vk.PhysicalDeviceFeatures,
    graphics_queue, transfer_queue, present_queue: Queue_Descriptor,
}

/*
TODO
*/
Device :: struct
{
    allocator: runtime.Allocator,
    features: vk.PhysicalDeviceFeatures,
    extensions: []cstring,
    graphics_queues, transfer_queues, present_queues: []Queue,
    handle: vk.Device,
}

/*
Checks if device handle is valid.
*/
device_is_valid :: #force_inline proc(device: ^Device) -> bool
{
    return device != nil && device.handle != nil
}