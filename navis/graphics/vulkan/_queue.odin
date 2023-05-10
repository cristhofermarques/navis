package vulkan

import "vk"
import "navis:commons"
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
Clone a queues info.
*/
queues_info_clone :: #force_inline proc(queues_info: ^Queues_Info, allocator := context.allocator, location := #caller_location) -> (Queues_Info, bool) #optional_ok
{
    if log.verbose_fail_error(queues_info == nil, "invalid queues info parameter", location) do return {}, false

    clone: Queues_Info
    clone.allocator = allocator
    if queues_info.graphics != nil do clone.graphics = commons.array_clone(queues_info.graphics, allocator)
    if queues_info.transfer != nil do clone.transfer = commons.array_clone(queues_info.transfer, allocator)
    if queues_info.present != nil do clone.present = commons.array_clone(queues_info.present, allocator)
    return clone, true
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

/*
Submit descriptor.
*/
Submit_Descriptor :: struct
{
    command_buffers: []vk.CommandBuffer,
    wait_dst_stage_mask: []vk.PipelineStageFlags,
    wait_semaphores: []Semaphore,
    signal_semaphores: []Semaphore,
}

/*
Compose a single submit info from submit descriptor.
*/
queue_compose_single_submit_info :: proc(desc: ^Submit_Descriptor) -> vk.SubmitInfo
{
    info: vk.SubmitInfo
    info.sType = .SUBMIT_INFO
    info.pCommandBuffers = commons.array_try_as_pointer(desc.command_buffers)
    info.commandBufferCount = cast(u32)commons.array_try_len(desc.command_buffers)
    info.pWaitDstStageMask = commons.array_try_as_pointer(desc.wait_dst_stage_mask)
    info.pWaitSemaphores = commons.array_try_as_pointer(desc.wait_semaphores)
    info.waitSemaphoreCount = cast(u32)commons.array_try_len(desc.wait_semaphores)
    info.pSignalSemaphores = commons.array_try_as_pointer(desc.signal_semaphores)
    info.signalSemaphoreCount = cast(u32)commons.array_try_len(desc.signal_semaphores)
    return info
}

/*
Compose mutiple submit infos from submit descriptors slice.
*/
queue_compose_multiple_submit_info :: proc(descriptors: []Submit_Descriptor, allocator := context.allocator, location := #caller_location) -> ([]vk.SubmitInfo, bool) #optional_ok
{
    if descriptors == nil do return nil, false
    
    descriptors_len := len(descriptors)
    if descriptors_len < 1 do return nil, false
    
    infos, alloc_err := make([]vk.SubmitInfo, descriptors_len, allocator, location)
    if alloc_err != .None do return nil, false

    for i := 0; i < descriptors_len; i += 1 do infos[i] = queue_compose_single_submit_info(&descriptors[i])
    return infos, true
}

queue_compose_submit_info :: proc{
    queue_compose_single_submit_info,
    queue_compose_multiple_submit_info,
}

/*
Queue submit from a single descriptor.
*/
queue_submit_from_descritor_single :: proc(queue: ^Queue, desc: ^Submit_Descriptor, fence: vk.Fence, location := #caller_location) -> bool
{
    if queue == nil do return false
    if desc == nil do return false

    info := queue_compose_single_submit_info(desc)
    result := vk.QueueSubmit(queue.handle, 1, &info, fence)
    return result != .SUCCESS
}

/*
Queue submit from multiple descriptors.
* Make allocation internally.
*/
queue_submit_from_descritor_multiple :: proc(queue: ^Queue, descriptors: []Submit_Descriptor, fence: vk.Fence, location := #caller_location) -> bool
{
    if queue == nil do return false
    if descriptors == nil do return false

    infos, success := queue_compose_submit_info(descriptors, context.temp_allocator, location)
    if !success do return false
    defer delete(infos, context.temp_allocator)

    result := vk.QueueSubmit(queue.handle, cast(u32)commons.array_try_len(infos), commons.array_try_as_pointer(infos), fence)
    return result != .SUCCESS
}

queue_submit :: proc{
    queue_submit_from_descritor_single,
    queue_submit_from_descritor_multiple,
}