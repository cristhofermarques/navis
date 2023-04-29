package vulkan

import "vk"

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