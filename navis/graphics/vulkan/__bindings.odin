package vulkan

import "navis:api"

PREFIX :: "navis_graphics_vulkan_"

when api.IMPORT
{
    import "vk"
    import "shaderc"
    import "navis:graphics/ui"
    import "core:dynlib"

    when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

    @(default_calling_convention="odin")
    foreign navis
    {
        /* Instance */
        @(link_prefix=PREFIX)
        instance_create_from_descriptor :: proc(descriptor: ^Instance_Descriptor) -> (Instance, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        instance_create_from_parameters :: proc(app_name: cstring, app_version, api_version: u32, extensions, layers: []cstring, allocator := context.allocator, location := #caller_location) -> (Instance, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        instance_destroy :: proc(instance: ^Instance) -> bool ---

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
        swapchain_enumerate_images_from_handle :: proc(device: ^Device, swapchain: vk.SwapchainKHR, allocator := context.allocator, location := #caller_location) -> ([]vk.Image, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        swapchain_create_from_descriptor :: proc(device: ^Device, surface: ^Surface, render_pass: ^Render_Pass, desc: ^Swapchain_Descriptor, allocator := context.allocator, location := #caller_location) -> (Swapchain, bool) #optional_ok ---
        
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
        fence_destroy :: proc(device: ^Device, fence: Fence, location := #caller_location) -> bool ---
        
        /* Pipeline Layout */
        @(link_prefix=PREFIX)
        pipeline_layout_create_from_descriptor :: proc(device: ^Device, desc: ^Layout_State_Descriptor, location := #caller_location) -> (Pipeline_Layout, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        pipeline_layout_destroy :: proc(device: ^Device, pipeline_layout: ^Pipeline_Layout, location := #caller_location) -> bool ---
        
        /* Render Pass */
        @(link_prefix=PREFIX)
        render_pass_create_from_descriptor :: proc(device: ^Device, desc: ^Render_Pass_Descriptor, location := #caller_location) -> (Render_Pass, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        render_pass_destroy :: proc(device: ^Device, render_pass: ^Render_Pass, location := #caller_location) -> bool ---
        
        /* Image View */
        @(link_prefix=PREFIX)
        image_view_create_from_descriptor :: proc(device: ^Device, desc: Image_View_Descriptor, location := #caller_location) -> (Image_View, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        image_view_create_multiple_from_descriptor :: proc(device: ^Device, desc: ^Image_View_Descriptor, images: []vk.Image, allocator := context.allocator, location := #caller_location) -> ([]Image_View, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        image_view_destroy :: proc(device: ^Device, image_view: ^Image_View, location := #caller_location) -> bool ---
        
        /* Framebuffer */
        @(link_prefix=PREFIX)
        framebuffer_create_from_descriptor :: proc(device: ^Device, render_pass: ^Render_Pass, desc: ^Framebuffer_Descriptor, image_views: []Image_View, allocator := context.allocator, location := #caller_location) -> (Framebuffer, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        framebuffer_destroy :: proc(device: ^Device, framebuffer: ^Framebuffer, location := #caller_location) -> bool ---
        
        /* Buffer */
        @(link_prefix=PREFIX)
        buffer_get_requirements_from_handle :: proc(device: ^Device, buffer: vk.Buffer, location := #caller_location) -> (vk.MemoryRequirements, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        buffer_create_from_descriptor_single :: proc(device: ^Device, desc: ^Buffer_Descriptor, allocator := context.allocator, location := #caller_location) -> (Buffer, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        buffer_create_from_descriptor_multiple :: proc(device: ^Device, descriptors: []Buffer_Descriptor, allocator := context.allocator, location := #caller_location) -> ([]Buffer, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        buffer_destroy_single :: proc(device: ^Device, buffer: ^Buffer, location := #caller_location) -> bool ---

        @(link_prefix=PREFIX)
        buffer_destroy_multiple :: proc(device: ^Device, buffers: []Buffer, location := #caller_location) -> bool ---

        @(link_prefix=PREFIX)
        buffer_filter_memory_types_single :: proc(physical_device: ^Physical_Device, buffer: ^Buffer, property_flags: vk.MemoryPropertyFlags, allocator := context.allocator, location := #caller_location) -> ([]i32, bool) ---

        @(link_prefix=PREFIX)
        buffer_filter_memory_types_multiple :: proc(physical_device: ^Physical_Device, buffers: []Buffer, property_flags: vk.MemoryPropertyFlags, allocator := context.allocator, location := #caller_location) -> ([]i32, bool) ---
        
        @(link_prefix=PREFIX)
        buffer_filter_memory_types_multiple_first :: proc(physical_device: ^Physical_Device, buffers: []Buffer, property_flags: vk.MemoryPropertyFlags) -> (i32, bool) ---

        @(link_prefix=PREFIX)
        buffer_bind_memory_single :: proc(device: ^Device, memory: ^Memory, buffer: ^Buffer, offset: u64, location := #caller_location) -> bool ---

        @(link_prefix=PREFIX)
        buffer_bind_memory_multiple_stacked :: proc(device: ^Device, memory: ^Memory, buffers: []Buffer, start_offset: u64, location := #caller_location) -> bool ---
        
        @(link_prefix=PREFIX)
        buffer_upload_content_single :: proc(device: ^Device, memory: ^Memory, buffer: ^Buffer, offset: u64, data: rawptr) -> bool ---

        @(link_prefix=PREFIX)
        buffer_upload_content_multiple_stacked :: proc(device: ^Device, memory: ^Memory, buffers: []Buffer, contents: []rawptr, start_offset: u64) -> bool ---

        /* Memory */
        @(link_prefix=PREFIX)
        memory_create_from_descriptor :: proc(device: ^Device, descriptor: ^Memory_Descriptor) -> (Memory, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        memory_destroy :: proc(device: ^Device, memory: ^Memory) -> bool ---
        
        /* Vertex Input */
        @(link_prefix=PREFIX)
        vertex_input_compose_state :: proc(desc: ^Vertex_Descriptor, allocator := context.allocator) -> (vk.PipelineVertexInputStateCreateInfo, []vk.VertexInputBindingDescription, []vk.VertexInputAttributeDescription, bool) ---

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
        
        /* Shader Module */
        @(link_prefix=PREFIX)
        shader_module_compiler_create :: proc() -> (Shader_Module_Compiler, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        shader_module_compiler_destroy :: proc(compiler: Shader_Module_Compiler) -> bool ---

        @(link_prefix=PREFIX)
        shader_module_compile_to_spirv_from_data :: proc(compiler: Shader_Module_Compiler, options: Shader_Module_Compile_Options, descriptor: Shader_Module_Compile_Descriptor) -> shaderc.Compilation_Result ---
        
        @(link_prefix=PREFIX)
        shader_module_compile_options_create :: proc() -> (Shader_Module_Compile_Options, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        shader_module_compile_options_destroy :: proc(options: Shader_Module_Compile_Options) -> bool ---
        
        @(link_prefix=PREFIX)
        shader_module_compile_options_set_source_language :: proc(options: Shader_Module_Compile_Options, language: shaderc.Source_Language) ---

        @(link_prefix=PREFIX)
        shader_compilation_result_get_size :: proc(result: shaderc.Compilation_Result) -> u64 ---

        @(link_prefix=PREFIX)
        shader_compilation_result_get_data :: proc(result: shaderc.Compilation_Result) -> rawptr ---

        @(link_prefix=PREFIX)
        shader_compilation_result_destroy :: proc(result: shaderc.Compilation_Result) ---

        @(link_prefix=PREFIX)
        shader_module_create_from_data :: proc(context_: ^Context, data: []byte, location := #caller_location) -> (vk.ShaderModule, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        shader_module_destroy :: proc(context_: ^Context, module: vk.ShaderModule, location := #caller_location) -> bool ---
        
        /* Buffer Pack */
        @(link_prefix=PREFIX)
        buffer_pack_create_from_descriptor_single :: proc(context_: ^Context, descriptor: ^Buffer_Pack_Descriptor, allocator := context.allocator) -> (Buffer_Pack, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        buffer_pack_destroy :: proc(context_: ^Context, buffer_pack: ^Buffer_Pack) -> bool ---
        
        @(link_prefix=PREFIX)
        buffer_pack_upload_content_multiple_stacked :: proc(context_: ^Context, buffer_pack: ^Buffer_Pack, contents: []rawptr, start_offset: u64 = 0) -> bool ---
        
        /* Allocator */
        @(link_prefix=PREFIX)
        allocator_create_from_descriptor :: proc(context_: ^Context, descriptor: ^Allocator_Descriptor, allocator := context.allocator) -> (Allocator, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        allocator_destroy :: proc(context_: ^Context, allocator_: ^Allocator) -> bool ---

        @(link_prefix=PREFIX)
        allocator_create_buffer_pack_from_descriptor_single :: proc(context_: ^Context, allocator_: ^Allocator, descriptor: ^Buffer_Pack_Descriptor) -> (^Buffer_Pack, bool) #optional_ok ---
    }
}