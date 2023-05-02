package vulkan

import "vk"
import "navis:commons/log"
import "core:runtime"

/*
Vulkan queue filter
*/
Queue_Filter :: struct
{
    ignore_flags: vk.QueueFlags,
    require_flags: vk.QueueFlags,
    require_count: i32,
    require_presentation: bool,
}

/*
Vulkan queue info.

Basic info of physical device queue family.
*/
Queue_Info :: struct
{
    flags: vk.QueueFlags,
    index, count: i32,
    presentation: bool,
}

/*
Vulkan queues info.

Additional info from physical device filtering.
*/
Queues_Info :: struct
{
    allocator: runtime.Allocator,
    graphics, transfer, present: []Queue_Info,
}

/*
Vulkan queue descriptor.
*/
Queue_Descriptor :: struct
{
    index: i32,
    priorities: []f32,
}

/*
Vulkan queue.
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