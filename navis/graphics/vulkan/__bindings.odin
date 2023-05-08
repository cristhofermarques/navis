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

        @(link_prefix=PREFIX)
        physical_device_filter_first :: proc(instance: ^Instance, filter: ^Physical_Device_Filter, allocator := context.allocator, location := #caller_location) -> (Physical_Device, Queues_Info, bool) ---
        
        /* Surface */
        @(link_prefix=PREFIX)
        surface_create :: proc(instance: ^Instance, physical_device: ^Physical_Device, window: ^ui.Window, allocator := context.allocator, location := #caller_location) -> (Surface, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        surface_destroy :: proc(instance: ^Instance, surface: ^Surface) -> bool ---

        @(link_prefix=PREFIX)
        surface_enumerate_formats_from_handle :: proc(physical_device: ^Physical_Device, surface: vk.SurfaceKHR, allocator := context.allocator) -> ([]vk.SurfaceFormatKHR, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        surface_enumerate_present_modes_from_handle :: proc(physical_device: ^Physical_Device, surface: vk.SurfaceKHR, allocator := context.allocator) -> ([]vk.PresentModeKHR, bool) #optional_ok ---
        
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
        device_create_from_descriptor :: proc(physical_device: ^Physical_Device, desc: ^Device_Descriptor, allocator := context.allocator, location := #caller_location) -> (Device, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        device_destroy :: proc(device: ^Device, location := #caller_location) -> bool ---
        
        /* Swapchain */
        @(link_prefix=PREFIX)
        swapchain_create_from_descriptor :: proc(device: ^Device, surface: ^Surface, desc: ^Swapchain_Descriptor, location := #caller_location) -> (Swapchain, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        swapchain_destroy :: proc(device: ^Device, swapchain: ^Swapchain, location := #caller_location) -> bool ---
        
        /* Command Pool */
        @(link_prefix=PREFIX)
        command_pool_create_from_descriptor :: proc(device: ^Device, desc: ^Command_Pool_Descriptor, location := #caller_location) -> (Command_Pool, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        command_pool_create_from_parameters :: proc(device: ^Device, flags: vk.CommandPoolCreateFlags, index: i32, location := #caller_location) -> (Command_Pool, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        command_pool_destroy :: proc(device: ^Device, command_pool: ^Command_Pool, location := #caller_location) -> bool ---
        
        /* Fence */
        @(link_prefix=PREFIX)
        fence_create_from_descriptor :: proc(device: ^Device, desc: ^Fence_Descriptor, location := #caller_location) -> (Fence, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        fence_destroy :: proc(device: ^Device, fence: ^Fence, location := #caller_location) -> bool ---
        
        /* Pipeline Layout */
        @(link_prefix=PREFIX)
        pipeline_layout_create_from_descriptor :: proc(device: ^Device, desc: ^Layout_State_Descriptor, location := #caller_location) -> (Pipeline_Layout, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        pipeline_layout_destroy :: proc(device: ^Device, pipeline_layout: ^Pipeline_Layout, location := #caller_location) -> bool ---

        /* Context */
        @(link_prefix=PREFIX)
        context_create_from_descriptor :: proc(desc: ^Context_Descriptor, allocator := context.allocator, location := #caller_location) -> (Context, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        context_destroy :: proc(context_: ^Context, location := #caller_location) -> bool ---
        
        /* Target */
        @(link_prefix=PREFIX)
        target_create_from_descriptor :: proc(context_: ^Context, desc: ^Target_Descriptor, allocator := context.allocator, location := #caller_location) -> (Target, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        target_destroy :: proc(context_: ^Context, target: ^Target, location := #caller_location) -> bool ---
    }
}