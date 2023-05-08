package vulkan

import "vk"

/*
Vulkan pipeline layout.
*/
Pipeline_Layout :: struct
{
    handle: vk.PipelineLayout,
}

pipeline_layout_create :: proc{
    pipeline_layout_create_from_descriptor,
}

/*
Check if pipeline layout handle is invalid.
*/
pipeline_layout_is_valid :: #force_inline proc(pipeline_layout: ^Pipeline_Layout) -> bool
{
    return pipeline_layout != nil && pipeline_layout.handle != 0
}