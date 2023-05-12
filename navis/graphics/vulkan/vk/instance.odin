package vk

import "navis:api"

when api.EXPORT
{
/*
Populate instance procedures.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    instance_vtable_populate :: proc(library: ^Library, instance: Instance, vtable: ^Instance_VTable)
    {
        if !library_is_valid(library) do return
        if instance == nil || vtable == nil do return

        vtable.AcquireDrmDisplayEXT                                            = auto_cast library.GetInstanceProcAddr(instance, "vkAcquireDrmDisplayEXT")
		vtable.AcquireWinrtDisplayNV                                           = auto_cast library.GetInstanceProcAddr(instance, "vkAcquireWinrtDisplayNV")
		vtable.CreateDebugReportCallbackEXT                                    = auto_cast library.GetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT")
		vtable.CreateDebugUtilsMessengerEXT                                    = auto_cast library.GetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT")
		vtable.CreateDevice                                                    = auto_cast library.GetInstanceProcAddr(instance, "vkCreateDevice")
		vtable.CreateDisplayModeKHR                                            = auto_cast library.GetInstanceProcAddr(instance, "vkCreateDisplayModeKHR")
		vtable.CreateDisplayPlaneSurfaceKHR                                    = auto_cast library.GetInstanceProcAddr(instance, "vkCreateDisplayPlaneSurfaceKHR")
		vtable.CreateHeadlessSurfaceEXT                                        = auto_cast library.GetInstanceProcAddr(instance, "vkCreateHeadlessSurfaceEXT")
		vtable.CreateIOSSurfaceMVK                                             = auto_cast library.GetInstanceProcAddr(instance, "vkCreateIOSSurfaceMVK")
		vtable.CreateMacOSSurfaceMVK                                           = auto_cast library.GetInstanceProcAddr(instance, "vkCreateMacOSSurfaceMVK")
		vtable.CreateMetalSurfaceEXT                                           = auto_cast library.GetInstanceProcAddr(instance, "vkCreateMetalSurfaceEXT")
		vtable.CreateWin32SurfaceKHR                                           = auto_cast library.GetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR")
		vtable.DebugReportMessageEXT                                           = auto_cast library.GetInstanceProcAddr(instance, "vkDebugReportMessageEXT")
		vtable.DestroyDebugReportCallbackEXT                                   = auto_cast library.GetInstanceProcAddr(instance, "vkDestroyDebugReportCallbackEXT")
		vtable.DestroyDebugUtilsMessengerEXT                                   = auto_cast library.GetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT")
		vtable.DestroyInstance                                                 = auto_cast library.GetInstanceProcAddr(instance, "vkDestroyInstance")
		vtable.DestroySurfaceKHR                                               = auto_cast library.GetInstanceProcAddr(instance, "vkDestroySurfaceKHR")
		vtable.EnumerateDeviceExtensionProperties                              = auto_cast library.GetInstanceProcAddr(instance, "vkEnumerateDeviceExtensionProperties")
		vtable.EnumerateDeviceLayerProperties                                  = auto_cast library.GetInstanceProcAddr(instance, "vkEnumerateDeviceLayerProperties")
		vtable.EnumeratePhysicalDeviceGroups                                   = auto_cast library.GetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceGroups")
		vtable.EnumeratePhysicalDeviceGroupsKHR                                = auto_cast library.GetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceGroupsKHR")
		vtable.EnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   = auto_cast library.GetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR")
		vtable.EnumeratePhysicalDevices                                        = auto_cast library.GetInstanceProcAddr(instance, "vkEnumeratePhysicalDevices")
		vtable.GetDisplayModeProperties2KHR                                    = auto_cast library.GetInstanceProcAddr(instance, "vkGetDisplayModeProperties2KHR")
		vtable.GetDisplayModePropertiesKHR                                     = auto_cast library.GetInstanceProcAddr(instance, "vkGetDisplayModePropertiesKHR")
		vtable.GetDisplayPlaneCapabilities2KHR                                 = auto_cast library.GetInstanceProcAddr(instance, "vkGetDisplayPlaneCapabilities2KHR")
		vtable.GetDisplayPlaneCapabilitiesKHR                                  = auto_cast library.GetInstanceProcAddr(instance, "vkGetDisplayPlaneCapabilitiesKHR")
		vtable.GetDisplayPlaneSupportedDisplaysKHR                             = auto_cast library.GetInstanceProcAddr(instance, "vkGetDisplayPlaneSupportedDisplaysKHR")
		vtable.GetDrmDisplayEXT                                                = auto_cast library.GetInstanceProcAddr(instance, "vkGetDrmDisplayEXT")
		vtable.GetPhysicalDeviceCalibrateableTimeDomainsEXT                    = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT")
		vtable.GetPhysicalDeviceCooperativeMatrixPropertiesNV                  = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV")
		vtable.GetPhysicalDeviceDisplayPlaneProperties2KHR                     = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPlaneProperties2KHR")
		vtable.GetPhysicalDeviceDisplayPlanePropertiesKHR                      = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR")
		vtable.GetPhysicalDeviceDisplayProperties2KHR                          = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayProperties2KHR")
		vtable.GetPhysicalDeviceDisplayPropertiesKHR                           = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPropertiesKHR")
		vtable.GetPhysicalDeviceExternalBufferProperties                       = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalBufferProperties")
		vtable.GetPhysicalDeviceExternalBufferPropertiesKHR                    = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalBufferPropertiesKHR")
		vtable.GetPhysicalDeviceExternalFenceProperties                        = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalFenceProperties")
		vtable.GetPhysicalDeviceExternalFencePropertiesKHR                     = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalFencePropertiesKHR")
		vtable.GetPhysicalDeviceExternalImageFormatPropertiesNV                = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalImageFormatPropertiesNV")
		vtable.GetPhysicalDeviceExternalSemaphoreProperties                    = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalSemaphoreProperties")
		vtable.GetPhysicalDeviceExternalSemaphorePropertiesKHR                 = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalSemaphorePropertiesKHR")
		vtable.GetPhysicalDeviceFeatures                                       = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures")
		vtable.GetPhysicalDeviceFeatures2                                      = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures2")
		vtable.GetPhysicalDeviceFeatures2KHR                                   = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures2KHR")
		vtable.GetPhysicalDeviceFormatProperties                               = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties")
		vtable.GetPhysicalDeviceFormatProperties2                              = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties2")
		vtable.GetPhysicalDeviceFormatProperties2KHR                           = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties2KHR")
		vtable.GetPhysicalDeviceFragmentShadingRatesKHR                        = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFragmentShadingRatesKHR")
		vtable.GetPhysicalDeviceImageFormatProperties                          = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties")
		vtable.GetPhysicalDeviceImageFormatProperties2                         = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties2")
		vtable.GetPhysicalDeviceImageFormatProperties2KHR                      = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties2KHR")
		vtable.GetPhysicalDeviceMemoryProperties                               = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties")
		vtable.GetPhysicalDeviceMemoryProperties2                              = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties2")
		vtable.GetPhysicalDeviceMemoryProperties2KHR                           = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties2KHR")
		vtable.GetPhysicalDeviceMultisamplePropertiesEXT                       = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMultisamplePropertiesEXT")
		vtable.GetPhysicalDevicePresentRectanglesKHR                           = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDevicePresentRectanglesKHR")
		vtable.GetPhysicalDeviceProperties                                     = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties")
		vtable.GetPhysicalDeviceProperties2                                    = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties2")
		vtable.GetPhysicalDeviceProperties2KHR                                 = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties2KHR")
		vtable.GetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR")
		vtable.GetPhysicalDeviceQueueFamilyProperties                          = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties")
		vtable.GetPhysicalDeviceQueueFamilyProperties2                         = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties2")
		vtable.GetPhysicalDeviceQueueFamilyProperties2KHR                      = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties2KHR")
		vtable.GetPhysicalDeviceSparseImageFormatProperties                    = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties")
		vtable.GetPhysicalDeviceSparseImageFormatProperties2                   = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties2")
		vtable.GetPhysicalDeviceSparseImageFormatProperties2KHR                = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties2KHR")
		vtable.GetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV")
		vtable.GetPhysicalDeviceSurfaceCapabilities2EXT                        = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilities2EXT")
		vtable.GetPhysicalDeviceSurfaceCapabilities2KHR                        = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilities2KHR")
		vtable.GetPhysicalDeviceSurfaceCapabilitiesKHR                         = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR")
		vtable.GetPhysicalDeviceSurfaceFormats2KHR                             = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormats2KHR")
		vtable.GetPhysicalDeviceSurfaceFormatsKHR                              = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormatsKHR")
		vtable.GetPhysicalDeviceSurfacePresentModes2EXT                        = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModes2EXT")
		vtable.GetPhysicalDeviceSurfacePresentModesKHR                         = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModesKHR")
		vtable.GetPhysicalDeviceSurfaceSupportKHR                              = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceSupportKHR")
		vtable.GetPhysicalDeviceToolProperties                                 = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceToolProperties")
		vtable.GetPhysicalDeviceToolPropertiesEXT                              = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceToolPropertiesEXT")
		vtable.GetPhysicalDeviceWin32PresentationSupportKHR                    = auto_cast library.GetInstanceProcAddr(instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR")
		vtable.GetWinrtDisplayNV                                               = auto_cast library.GetInstanceProcAddr(instance, "vkGetWinrtDisplayNV")
		vtable.ReleaseDisplayEXT                                               = auto_cast library.GetInstanceProcAddr(instance, "vkReleaseDisplayEXT")
		vtable.SubmitDebugUtilsMessageEXT                                      = auto_cast library.GetInstanceProcAddr(instance, "vkSubmitDebugUtilsMessageEXT")
    }
}