package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    target_create_from_descriptor :: proc(context_: ^Context, desc: ^Target_Descriptor, allocator := context.allocator, location := #caller_location) -> (Target, bool) #optional_ok
    {
        if log.verbose_fail_error(!context_is_valid(context_), "invalid vulkan context parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid target descriptor parameter", location) do return {}, false
        if log.verbose_fail_error(desc.window == nil, "invalid window target descriptor parameter", location) do return {}, false
        
        success: bool
        surface: Surface
        surface, success = surface_create(&context_.instance, &context_.physical_device, desc.window, allocator, location)
        if log.verbose_fail_error(!success, "create vulkan surface for target", location) do return {}, false
        
        swapchain: Swapchain
        swapchain, success = swapchain_create(&context_.device, &surface, &desc.swapchain, allocator)
        if log.verbose_fail_error(!success, "create vulkan swapchain for target", location)
        {
            surface_destroy(&context_.instance, &surface)
            return {}, false
        }

        target: Target
        target.surface = surface
        target.swapchain = swapchain
        return target, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    target_destroy :: proc(context_: ^Context, target: ^Target, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!context_is_valid(context_), "invalid vulkan context parameter", location) do return false
        if log.verbose_fail_error(target == nil, "invalid vulkan target parameter", location) do return false

        swapchain_destroy(&context_.device, &target.swapchain, location)
        surface_destroy(&context_.instance, &target.surface)
        return true
    }
}