package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import graphics_commons "navis:graphics/commons"

    @(export=api.SHARED, link_prefix=PREFIX)
    renderer_create_from_descriptor :: proc(descriptor: ^graphics_commons.Renderer_Descriptor) -> (Renderer, bool) #optional_ok
    {
        context_descriptor: Context_Descriptor
        //Making instance descriptor
        context_descriptor.instance.api_version = vk.API_VERSION_1_3
        context_descriptor.instance.app_name = "Navis_Application"
        context_descriptor.instance.app_version = vk.MAKE_VERSION(1, 0, 0)

        //Making debugger descriptor
        when ODIN_DEBUG
        {
            context_descriptor.debugger.message_type = {.PERFORMANCE, .GENERAL, .VALIDATION}
            context_descriptor.debugger.message_severity = {.VERBOSE, .WARNING, .ERROR}
        }

        //Making physical device descriptor
        context_descriptor.physical_device.api_version = vk.API_VERSION_1_3
        context_descriptor.physical_device.type_ = physical_device_type_from_gpu_type(descriptor.gpu_type)
        context_descriptor.physical_device.graphics_queue_filter.require_flags = {.GRAPHICS}
        context_descriptor.physical_device.graphics_queue_filter.require_count = 1
        context_descriptor.physical_device.transfer_queue_filter.require_flags = {.GRAPHICS, .TRANSFER}
        context_descriptor.physical_device.transfer_queue_filter.require_count = 1
        context_descriptor.physical_device.present_queue_filter.require_flags = {.GRAPHICS}
        context_descriptor.physical_device.present_queue_filter.require_presentation = true

        //Making device descriptor
        context_descriptor.device.graphics_queue.priorities = {1.0}
        context_descriptor.device.transfer_queue.priorities = {1.0}
        context_descriptor.device.present_queue.priorities = {1.0}

        context_, context_success := context_create(&context_descriptor, context.allocator)
        if !context_success do return {}, false

        renderer: Renderer
        renderer.context_ = context_

        return renderer, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    renderer_destroy :: proc(renderer: ^Renderer) -> bool
    {
        if renderer == nil do return false

        defer context_destroy(&renderer.context_)

        return true
    }
}