package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    surface_destroy :: proc(instance: ^Instance, surface: ^Surface) -> bool
    {
        if log.verbose_fail_error(!instance_is_valid(instance), "invalid vulkan instance parameter") do return false
        if log.verbose_fail_error(!surface_is_valid(surface), "invalid vulkan surface parameter") do return false

        allocator := surface.allocator

        vk.DestroySurfaceKHR(instance.handle, surface.handle, nil)
        surface.handle = 0

        if surface.formats != nil
        {
            delete(surface.formats, allocator)
            surface.formats = nil
        }

        if surface.present_modes != nil
        {
            delete(surface.present_modes, allocator)
            surface.present_modes = nil
        }

        return true
    }
}