package vulkan

import "navis:api"

PREFIX :: "navis_graphics_vulkan_"

when api.IMPORT
{
    import "vk"
    import "navis:graphics/ui"
    import "core:dynlib"

    when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

    @(default_calling_convention="odin")
    foreign navis
    {
        @(link_prefix=PREFIX)
        instance_create_from_descriptor :: proc(desc: ^Instance_Descriptor, allocator := context.allocator) -> (Instance, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        instance_create_from_parameters :: proc(app_name: cstring, app_version, api_version: u32, extensions, layers: []cstring, allocator := context.allocator) -> (Instance, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        instance_destroy :: proc(instance: ^Instance) ---
    }
}