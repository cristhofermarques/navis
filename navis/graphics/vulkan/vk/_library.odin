package vk

import "core:dynlib"

/*
Vulkan library.
*/
Library :: struct
{
    library: dynlib.Library,
    CreateInstance:                       ProcCreateInstance,
	DebugUtilsMessengerCallbackEXT:       ProcDebugUtilsMessengerCallbackEXT,
	DeviceMemoryReportCallbackEXT:        ProcDeviceMemoryReportCallbackEXT,
	EnumerateInstanceExtensionProperties: ProcEnumerateInstanceExtensionProperties,
	EnumerateInstanceLayerProperties:     ProcEnumerateInstanceLayerProperties,
	EnumerateInstanceVersion:             ProcEnumerateInstanceVersion,
	GetInstanceProcAddr:                  ProcGetInstanceProcAddr,
}

/*
Checks if library is valid.
*/
library_is_valid :: #force_inline proc(library: ^Library) -> bool
{
    return library != nil && library.library != nil
}