package vulkan

import "vk"

Debugger_Descriptor :: struct
{
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_type: vk.DebugUtilsMessageTypeFlagsEXT,
    message_callback: vk.ProcDebugReportCallbackEXT,
}

Debugger :: struct
{
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_type: vk.DebugUtilsMessageTypeFlagsEXT,
    message_callback: vk.ProcDebugReportCallbackEXT,
    messenger: vk.DebugUtilsMessengerEXT,
}