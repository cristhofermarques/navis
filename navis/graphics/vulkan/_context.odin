package vulkan

import "core:runtime"

Context_Descriptor :: struct
{
    instance: Instance_Descriptor,
    debugger: Debugger_Descriptor,
    physical_device: Physical_Device_Filter,
    device: Device_Descriptor,
}

Context :: struct
{
    allocator: runtime.Allocator,
    instance: Instance,
    debugger: Debugger,
    physical_device: Physical_Device,
    queues_info: Queues_Info,
    device: Device,
}

Target :: struct
{
    allocator: runtime.Allocator,
    surface: Surface,
    swapchain: Swapchain,
}

context_create :: proc{
    context_create_from_descriptor,
}