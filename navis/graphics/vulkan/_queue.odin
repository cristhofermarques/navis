package vulkan

import "vk"
import "core:runtime"

/*
TODO
*/
Queue_Filter :: struct
{
    ignore_flags: vk.QueueFlags,
    require_flags: vk.QueueFlags,
    require_count: i32,
    require_presentation: bool,
}

/*
TODO
*/
Queue_Info :: struct
{
    flags: vk.QueueFlags,
    index, count: i32,
    presentation: bool,
}

/*
TODO
*/
Queues_Info :: struct
{
    allocator: runtime.Allocator,
    graphics, transfer, present: []Queue_Info,
}

/*
TODO
*/
Queue_Descriptor :: struct
{
    index: i32,
    priorities: []f32,
}

/*
TODO
*/
Queue :: struct
{
    index: i32,
    priority: f32,
    handle: vk.Queue,
}

/*
Delete a single queues info.
*/
queues_info_delete_single :: #force_inline proc(queues_info: ^Queues_Info, location := #caller_location) -> bool
{
    if log.verbose_fail_error(queues_info == nil, "invalid queues info parameter", location) do return false

    allocator := queues_info.allocator
    if queues_info.graphics != nil
    {
        delete(queues_info.graphics, allocator)
        queues_info.graphics = nil
    }

    if queues_info.transfer != nil
    {
        delete(queues_info.transfer, allocator)
        queues_info.transfer = nil
    }

    if queues_info.present != nil
    {
        delete(queues_info.present, allocator)
        queues_info.present = nil
    }

    return true
}

/*
Delete a queues info slice.
*/
queues_info_delete_slice :: #force_inline proc(queues_infos: []Queues_Info, location := #caller_location) -> bool
{
    if queues_infos == nil do return false
    for qi, i in queues_infos do queues_info_delete_single(&queues_infos[i], location)
    return true
}

queues_info_delete :: proc{
    queues_info_delete_single,
    queues_info_delete_slice,
}

when ODIN_OS == .Windows
{
    import "navis:commons/log"

/*
TODO
*/
    queue_support_presentation_from_handle :: #force_inline proc(physical_device: vk.PhysicalDevice, index: u32, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(physical_device == nil, "invalid vulkan physical device handle parameter", location) do return false
        return cast(bool)vk.GetPhysicalDeviceWin32PresentationSupportKHR(physical_device, index)
    }

/*
TODO
*/
    queue_support_presentation :: #force_inline proc(physical_device: ^Physical_Device, index: u32, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!physical_device_is_valid(physical_device), "invalid vulkan physical device parameter", location) do return false
        return cast(bool)vk.GetPhysicalDeviceWin32PresentationSupportKHR(physical_device.handle, index)
    }
}