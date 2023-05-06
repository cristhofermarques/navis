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

context_create :: proc{
    context_create_from_descriptor,
}

/*
Checks if vulkan context is valid.
*/
context_is_valid :: #force_inline proc(context_: ^Context) -> bool
{
    return context_ != nil &&
    instance_is_valid(&context_.instance) &&
    physical_device_is_valid(&context_.physical_device) &&
    device_is_valid(&context_.device)
}