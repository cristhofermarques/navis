package vk

import "navis:api"

when api.EXPORT
{
    import "navis:commons/log"
    import "core:dynlib"

/*
Loads vulkan library.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    library_load :: proc(location := #caller_location) -> (Library, bool) #optional_ok
    {
        name: string
        when ODIN_OS == .Windows do name = "vulkan-1.dll"
        when ODIN_OS == .Linux do name = "vulkan.so.1"

        //Loading library
		log.verbose_debug(args = {"loading vulkan shared library", name}, sep = " ", location = location)
        vklibrary, success := dynlib.load_library(name)
        if log.verbose_fail_error(!success, "load vulkan library", location) do return {}, false
        
        //Making library
        library: Library
        library.library = vklibrary
        library_populate(&library)

        return library, true
    }

/*
Unloads vulkan library.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    library_unload :: proc(library: ^Library, location := #caller_location) -> bool
    {
        if !library_is_valid(library) do return false

        dynlib.unload_library(library.library)
        library.library = nil

        return true
    }

/*
Populate vulkan library procedures.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    library_populate :: proc(library: ^Library)
    {
        if !library_is_valid(library) do return

        VK_GET_INSTANCE_PROC_ADDR :: "vkGetInstanceProcAddr"
        address, found := dynlib.symbol_address(library.library, VK_GET_INSTANCE_PROC_ADDR)
        if !found do return
        library.GetInstanceProcAddr = auto_cast address

        library.CreateInstance                       = auto_cast library.GetInstanceProcAddr(nil, "vkCreateInstance")
        library.DebugUtilsMessengerCallbackEXT       = auto_cast library.GetInstanceProcAddr(nil, "vkDebugUtilsMessengerCallbackEXT")
        library.DeviceMemoryReportCallbackEXT        = auto_cast library.GetInstanceProcAddr(nil, "vkDeviceMemoryReportCallbackEXT")
        library.EnumerateInstanceExtensionProperties = auto_cast library.GetInstanceProcAddr(nil, "vkEnumerateInstanceExtensionProperties")
        library.EnumerateInstanceLayerProperties     = auto_cast library.GetInstanceProcAddr(nil, "vkEnumerateInstanceLayerProperties")
        library.EnumerateInstanceVersion             = auto_cast library.GetInstanceProcAddr(nil, "vkEnumerateInstanceVersion")
        library.GetInstanceProcAddr                  = auto_cast library.GetInstanceProcAddr(nil, "vkGetInstanceProcAddr")
    }
}