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

        @(link_prefix=PREFIX)
        instance_enumerate_version :: proc() -> (u32, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        instance_enumerate_extension_properties :: proc(layer_name: cstring, allocator := context.allocator, location := #caller_location) -> ([]vk.ExtensionProperties, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        instance_enumerate_layer_properties :: proc(allocator := context.allocator, location := #caller_location) -> ([]vk.LayerProperties, bool) #optional_ok ---
        
        /* Debugger */
        @(link_prefix=PREFIX)
        debugger_default_message_callback :: proc "std" (messageSeverity: vk.DebugUtilsMessageSeverityFlagsEXT, messageTypes: vk.DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^vk.DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> b32 ---

        @(link_prefix=PREFIX)
        debugger_create_from_descriptor :: proc(instance: ^Instance, desc: ^Debugger_Descriptor, allocator := context.allocator, location := #caller_location) -> (Debugger, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        debugger_destroy :: proc(instance: ^Instance, debugger: ^Debugger, location := #caller_location) -> bool ---
        
        /* Physical Device */
        @(link_prefix=PREFIX)
        physical_device_enumerate :: proc(instance: ^Instance, allocator := context.allocator) -> ([]vk.PhysicalDevice, bool) #optional_ok ---
    }
}