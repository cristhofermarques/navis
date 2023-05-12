package vulkan

import "vk"
import "core:runtime"

/*
Vulkan debugger descriptor.
*/
Debugger_Descriptor :: struct
{
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_type: vk.DebugUtilsMessageTypeFlagsEXT,
    message_callback: vk.ProcDebugReportCallbackEXT,
}

/*
Vulkan debugger.
*/
Debugger :: struct
{
    allocator: runtime.Allocator,
    context_: ^runtime.Context,
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_type: vk.DebugUtilsMessageTypeFlagsEXT,
    message_callback: vk.ProcDebugReportCallbackEXT,
    messenger: vk.DebugUtilsMessengerEXT,
}

/*
Create a vulkan debugger.
*/
debugger_create :: proc{
    debugger_create_from_descriptor,
}