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
        physical_device_enumerate_handles :: proc(instance: ^Instance, allocator := context.allocator) -> ([]vk.PhysicalDevice, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        physical_device_enumerate :: proc(instance: ^Instance, allocator := context.allocator) -> ([]Physical_Device, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        physical_device_filter :: proc(instance: ^Instance, filter: ^Physical_Device_Filter, allocator := context.allocator, location := #caller_location) -> ([]Physical_Device, []Queues_Info, bool) ---
        
        /* Surface */
        @(link_prefix=PREFIX)
        surface_create :: proc(instance: ^Instance, window: ^ui.Window) -> (Surface, bool) #optional_ok ---
        
        /* Queue */
        @(link_prefix=PREFIX)
        queue_enumerate_infos_from_handle :: proc(physical_device: vk.PhysicalDevice, allocator := context.allocator, location := #caller_location) -> ([]Queue_Info, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        queue_enumerate_infos :: proc(physical_device: ^Physical_Device, allocator := context.allocator, location := #caller_location) -> ([]Queue_Info, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        queue_filter :: proc(physical_device: ^Physical_Device, filter: ^Queue_Filter, allocator := context.allocator, location := #caller_location) -> ([]Queue_Info, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        queue_enumerate_from_handle :: proc(device: vk.Device, queue_desc: ^Queue_Descriptor, allocator := context.allocator, location := #caller_location) -> ([]Queue, bool) #optional_ok ---
        
        /* Device */
        @(link_prefix=PREFIX)
        device_create_from_desc :: proc(physical_device: ^Physical_Device, desc: ^Device_Descriptor, allocator := context.allocator, location := #caller_location) -> (Device, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        device_destroy :: proc(device: ^Device, location := #caller_location) -> bool ---
    }
}