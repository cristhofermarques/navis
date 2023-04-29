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
        /* Instance */
        @(link_prefix=PREFIX)
        instance_create_from_descriptor :: proc(desc: ^Instance_Descriptor, allocator := context.allocator, location := #caller_location) -> (Instance, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        instance_create_from_parameters :: proc(app_name: cstring, app_version, api_version: u32, extensions, layers: []cstring, allocator := context.allocator, location := #caller_location) -> (Instance, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        instance_destroy :: proc(instance: ^Instance, location := #caller_location) ---
        
        /* Debugger */
        @(link_prefix=PREFIX)
        debugger_default_message_callback :: proc "std" (messageSeverity: vk.DebugUtilsMessageSeverityFlagsEXT, messageTypes: vk.DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^vk.DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> b32 ---

        @(link_prefix=PREFIX)
        debugger_create_from_descriptor :: proc(instance: ^Instance, desc: ^Debugger_Descriptor, allocator := context.allocator, location := #caller_location) -> (Debugger, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        debugger_destroy :: proc(instance: ^Instance, debugger: ^Debugger, location := #caller_location) -> bool ---
    }
}