package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"
    import "core:c/libc"
/*
Default debugger message callback.

Log vulkan debug callbacks;
*/
    @(export=api.SHARED, link_prefix=PREFIX)    
    debugger_default_message_callback :: proc "std" (messageSeverity: vk.DebugUtilsMessageSeverityFlagsEXT, messageTypes: vk.DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^vk.DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> b32
    {
        level_text: cstring
        switch(messageSeverity)
        {
            case {.VERBOSE,}:
                level_text = "[Verb]"
            case {.INFO}:
                level_text = "[Info]"
            case {.WARNING}:
                level_text = "[Warn]"
            case {.ERROR}:
                level_text = "[Erro]"
        }

        libc.printf("%s Vulkan : %s\n", level_text, pCallbackData.pMessage)
        return true
    }

/*
Create vulkan debugger.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    debugger_create_from_descriptor :: proc(instance: ^Instance, desc: ^Debugger_Descriptor, allocator := context.allocator, location := #caller_location) -> (Debugger, bool) #optional_ok
    {
        if log.verbose_fail_error(instance == nil, "vulkan instance parameter is nil", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "debugger descriptor parameter is nil", location) do return {}, false
        if log.verbose_fail_error(vk.CreateDebugUtilsMessengerEXT == nil, "'vkCreateDebugUtilsMessengerEXT' is nil", location) do return {}, false
        if log.verbose_fail_error(vk.DestroyDebugUtilsMessengerEXT == nil, "'vkDestroyDebugUtilsMessengerEXT' is nil", location) do return {}, false

        //Creating info
        info: vk.DebugUtilsMessengerCreateInfoEXT
        info.sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
        info.messageSeverity = desc.message_severity
        info.messageType = desc.message_type
        info.pfnUserCallback = desc.message_callback == nil ? auto_cast debugger_default_message_callback : auto_cast desc.message_callback
        
        //Creating messenger
        messenger: vk.DebugUtilsMessengerEXT
        result := vk.CreateDebugUtilsMessengerEXT(instance.handle, &info, nil, &messenger)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan debug utils messenger", location) do return {}, false
        
        //Making debugger
        debugger: Debugger
        debugger.messenger = messenger
        debugger.message_type = desc.message_type
        debugger.message_severity = desc.message_severity
        debugger.message_callback = auto_cast info.pfnUserCallback        
        return debugger, true
    }

/*
Destroy vulkan debugger.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    debugger_destroy :: proc(instance: ^Instance, debugger: ^Debugger, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(instance == nil, "vulkan instance parameter is nil", location) do return false
        if log.verbose_fail_error(debugger == nil, "vulkan debugger parameter is nil", location) do return false
        if log.verbose_fail_error(vk.DestroyDebugUtilsMessengerEXT == nil, "'vkDestroyDebugUtilsMessengerEXT' is nil", location) do return false

        //Destroying messenger
        if debugger.messenger != 0
        {
            vk.DestroyDebugUtilsMessengerEXT(instance.handle, debugger.messenger, nil)
            debugger.messenger = 0
        }
        
        return true
    }
}