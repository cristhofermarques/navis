package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    pipeline_layout_create_from_descriptor :: proc(device: ^Device, desc: ^Layout_State_Descriptor, location := #caller_location) -> (Pipeline_Layout, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid layout descriptor parameter", location) do return {}, false
        
        info := pipeline_compose_layout_state(desc)
        
        handle: vk.PipelineLayout
        result := vk.CreatePipelineLayout(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create pipeline layout", location) do return {}, false

        pipeline_layout: Pipeline_Layout
        pipeline_layout.handle = handle
        return pipeline_layout, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    pipeline_layout_destroy :: proc(device: ^Device, pipeline_layout: ^Pipeline_Layout, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!pipeline_layout_is_valid(pipeline_layout), "invalid vulkan pipeline layout parameter", location) do return false

        vk.DestroyPipelineLayout(device.handle, pipeline_layout.handle, nil)
        pipeline_layout.handle = 0
        
        return true
    }
}