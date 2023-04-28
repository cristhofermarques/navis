package vk

import "core:c"

// Loader Procedure Types
ProcCreateInstance                       :: #type proc "system" (pCreateInfo: ^InstanceCreateInfo, pAllocator: ^AllocationCallbacks, pInstance: ^Instance) -> Result
ProcDebugUtilsMessengerCallbackEXT       :: #type proc "system" (messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> b32
ProcDeviceMemoryReportCallbackEXT        :: #type proc "system" (pCallbackData: ^DeviceMemoryReportCallbackDataEXT, pUserData: rawptr)
ProcEnumerateInstanceExtensionProperties :: #type proc "system" (pLayerName: cstring, pPropertyCount: ^u32, pProperties: [^]ExtensionProperties) -> Result
ProcEnumerateInstanceLayerProperties     :: #type proc "system" (pPropertyCount: ^u32, pProperties: [^]LayerProperties) -> Result
ProcEnumerateInstanceVersion             :: #type proc "system" (pApiVersion: ^u32) -> Result

// Misc Procedure Types
ProcAllocationFunction             :: #type proc "system" (pUserData: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
ProcDebugReportCallbackEXT         :: #type proc "system" (flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring, pUserData: rawptr) -> b32
ProcFreeFunction                   :: #type proc "system" (pUserData: rawptr, pMemory: rawptr)
ProcInternalAllocationNotification :: #type proc "system" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
ProcInternalFreeNotification       :: #type proc "system" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
ProcReallocationFunction           :: #type proc "system" (pUserData: rawptr, pOriginal: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
ProcVoidFunction                   :: #type proc "system" ()

// Instance Procedure Types
ProcAcquireDrmDisplayEXT                                            :: #type proc "system" (physicalDevice: PhysicalDevice, drmFd: i32, display: DisplayKHR) -> Result
ProcAcquireWinrtDisplayNV                                           :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
ProcCreateDebugReportCallbackEXT                                    :: #type proc "system" (instance: Instance, pCreateInfo: ^DebugReportCallbackCreateInfoEXT, pAllocator: ^AllocationCallbacks, pCallback: ^DebugReportCallbackEXT) -> Result
ProcCreateDebugUtilsMessengerEXT                                    :: #type proc "system" (instance: Instance, pCreateInfo: ^DebugUtilsMessengerCreateInfoEXT, pAllocator: ^AllocationCallbacks, pMessenger: ^DebugUtilsMessengerEXT) -> Result
ProcCreateDevice                                                    :: #type proc "system" (physicalDevice: PhysicalDevice, pCreateInfo: ^DeviceCreateInfo, pAllocator: ^AllocationCallbacks, pDevice: ^Device) -> Result
ProcCreateDisplayModeKHR                                            :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR, pCreateInfo: ^DisplayModeCreateInfoKHR, pAllocator: ^AllocationCallbacks, pMode: ^DisplayModeKHR) -> Result
ProcCreateDisplayPlaneSurfaceKHR                                    :: #type proc "system" (instance: Instance, pCreateInfo: ^DisplaySurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateHeadlessSurfaceEXT                                        :: #type proc "system" (instance: Instance, pCreateInfo: ^HeadlessSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateIOSSurfaceMVK                                             :: #type proc "system" (instance: Instance, pCreateInfo: ^IOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateMacOSSurfaceMVK                                           :: #type proc "system" (instance: Instance, pCreateInfo: ^MacOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateMetalSurfaceEXT                                           :: #type proc "system" (instance: Instance, pCreateInfo: ^MetalSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateWin32SurfaceKHR                                           :: #type proc "system" (instance: Instance, pCreateInfo: ^Win32SurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcDebugReportMessageEXT                                           :: #type proc "system" (instance: Instance, flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring)
ProcDestroyDebugReportCallbackEXT                                   :: #type proc "system" (instance: Instance, callback: DebugReportCallbackEXT, pAllocator: ^AllocationCallbacks)
ProcDestroyDebugUtilsMessengerEXT                                   :: #type proc "system" (instance: Instance, messenger: DebugUtilsMessengerEXT, pAllocator: ^AllocationCallbacks)
ProcDestroyInstance                                                 :: #type proc "system" (instance: Instance, pAllocator: ^AllocationCallbacks)
ProcDestroySurfaceKHR                                               :: #type proc "system" (instance: Instance, surface: SurfaceKHR, pAllocator: ^AllocationCallbacks)
ProcEnumerateDeviceExtensionProperties                              :: #type proc "system" (physicalDevice: PhysicalDevice, pLayerName: cstring, pPropertyCount: ^u32, pProperties: [^]ExtensionProperties) -> Result
ProcEnumerateDeviceLayerProperties                                  :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]LayerProperties) -> Result
ProcEnumeratePhysicalDeviceGroups                                   :: #type proc "system" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: [^]PhysicalDeviceGroupProperties) -> Result
ProcEnumeratePhysicalDeviceGroupsKHR                                :: #type proc "system" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: [^]PhysicalDeviceGroupProperties) -> Result
ProcEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   :: #type proc "system" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, pCounterCount: ^u32, pCounters: [^]PerformanceCounterKHR, pCounterDescriptions: [^]PerformanceCounterDescriptionKHR) -> Result
ProcEnumeratePhysicalDevices                                        :: #type proc "system" (instance: Instance, pPhysicalDeviceCount: ^u32, pPhysicalDevices: [^]PhysicalDevice) -> Result
ProcGetDisplayModeProperties2KHR                                    :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: [^]DisplayModeProperties2KHR) -> Result
ProcGetDisplayModePropertiesKHR                                     :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: [^]DisplayModePropertiesKHR) -> Result
ProcGetDisplayPlaneCapabilities2KHR                                 :: #type proc "system" (physicalDevice: PhysicalDevice, pDisplayPlaneInfo: ^DisplayPlaneInfo2KHR, pCapabilities: [^]DisplayPlaneCapabilities2KHR) -> Result
ProcGetDisplayPlaneCapabilitiesKHR                                  :: #type proc "system" (physicalDevice: PhysicalDevice, mode: DisplayModeKHR, planeIndex: u32, pCapabilities: [^]DisplayPlaneCapabilitiesKHR) -> Result
ProcGetDisplayPlaneSupportedDisplaysKHR                             :: #type proc "system" (physicalDevice: PhysicalDevice, planeIndex: u32, pDisplayCount: ^u32, pDisplays: [^]DisplayKHR) -> Result
ProcGetDrmDisplayEXT                                                :: #type proc "system" (physicalDevice: PhysicalDevice, drmFd: i32, connectorId: u32, display: ^DisplayKHR) -> Result
ProcGetInstanceProcAddr                                             :: #type proc "system" (instance: Instance, pName: cstring) -> ProcVoidFunction
ProcGetPhysicalDeviceCalibrateableTimeDomainsEXT                    :: #type proc "system" (physicalDevice: PhysicalDevice, pTimeDomainCount: ^u32, pTimeDomains: [^]TimeDomainEXT) -> Result
ProcGetPhysicalDeviceCooperativeMatrixPropertiesNV                  :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]CooperativeMatrixPropertiesNV) -> Result
ProcGetPhysicalDeviceDisplayPlaneProperties2KHR                     :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayPlaneProperties2KHR) -> Result
ProcGetPhysicalDeviceDisplayPlanePropertiesKHR                      :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayPlanePropertiesKHR) -> Result
ProcGetPhysicalDeviceDisplayProperties2KHR                          :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayProperties2KHR) -> Result
ProcGetPhysicalDeviceDisplayPropertiesKHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayPropertiesKHR) -> Result
ProcGetPhysicalDeviceExternalBufferProperties                       :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: [^]ExternalBufferProperties)
ProcGetPhysicalDeviceExternalBufferPropertiesKHR                    :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: [^]ExternalBufferProperties)
ProcGetPhysicalDeviceExternalFenceProperties                        :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: [^]ExternalFenceProperties)
ProcGetPhysicalDeviceExternalFencePropertiesKHR                     :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: [^]ExternalFenceProperties)
ProcGetPhysicalDeviceExternalImageFormatPropertiesNV                :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, externalHandleType: ExternalMemoryHandleTypeFlagsNV, pExternalImageFormatProperties: [^]ExternalImageFormatPropertiesNV) -> Result
ProcGetPhysicalDeviceExternalSemaphoreProperties                    :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: [^]ExternalSemaphoreProperties)
ProcGetPhysicalDeviceExternalSemaphorePropertiesKHR                 :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: [^]ExternalSemaphoreProperties)
ProcGetPhysicalDeviceFeatures                                       :: #type proc "system" (physicalDevice: PhysicalDevice, pFeatures: [^]PhysicalDeviceFeatures)
ProcGetPhysicalDeviceFeatures2                                      :: #type proc "system" (physicalDevice: PhysicalDevice, pFeatures: [^]PhysicalDeviceFeatures2)
ProcGetPhysicalDeviceFeatures2KHR                                   :: #type proc "system" (physicalDevice: PhysicalDevice, pFeatures: [^]PhysicalDeviceFeatures2)
ProcGetPhysicalDeviceFormatProperties                               :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: [^]FormatProperties)
ProcGetPhysicalDeviceFormatProperties2                              :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: [^]FormatProperties2)
ProcGetPhysicalDeviceFormatProperties2KHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: [^]FormatProperties2)
ProcGetPhysicalDeviceFragmentShadingRatesKHR                        :: #type proc "system" (physicalDevice: PhysicalDevice, pFragmentShadingRateCount: ^u32, pFragmentShadingRates: [^]PhysicalDeviceFragmentShadingRateKHR) -> Result
ProcGetPhysicalDeviceImageFormatProperties                          :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, pImageFormatProperties: [^]ImageFormatProperties) -> Result
ProcGetPhysicalDeviceImageFormatProperties2                         :: #type proc "system" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: [^]ImageFormatProperties2) -> Result
ProcGetPhysicalDeviceImageFormatProperties2KHR                      :: #type proc "system" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: [^]ImageFormatProperties2) -> Result
ProcGetPhysicalDeviceMemoryProperties                               :: #type proc "system" (physicalDevice: PhysicalDevice, pMemoryProperties: [^]PhysicalDeviceMemoryProperties)
ProcGetPhysicalDeviceMemoryProperties2                              :: #type proc "system" (physicalDevice: PhysicalDevice, pMemoryProperties: [^]PhysicalDeviceMemoryProperties2)
ProcGetPhysicalDeviceMemoryProperties2KHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, pMemoryProperties: [^]PhysicalDeviceMemoryProperties2)
ProcGetPhysicalDeviceMultisamplePropertiesEXT                       :: #type proc "system" (physicalDevice: PhysicalDevice, samples: SampleCountFlags, pMultisampleProperties: [^]MultisamplePropertiesEXT)
ProcGetPhysicalDevicePresentRectanglesKHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pRectCount: ^u32, pRects: [^]Rect2D) -> Result
ProcGetPhysicalDeviceProperties                                     :: #type proc "system" (physicalDevice: PhysicalDevice, pProperties: [^]PhysicalDeviceProperties)
ProcGetPhysicalDeviceProperties2                                    :: #type proc "system" (physicalDevice: PhysicalDevice, pProperties: [^]PhysicalDeviceProperties2)
ProcGetPhysicalDeviceProperties2KHR                                 :: #type proc "system" (physicalDevice: PhysicalDevice, pProperties: [^]PhysicalDeviceProperties2)
ProcGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           :: #type proc "system" (physicalDevice: PhysicalDevice, pPerformanceQueryCreateInfo: ^QueryPoolPerformanceCreateInfoKHR, pNumPasses: [^]u32)
ProcGetPhysicalDeviceQueueFamilyProperties                          :: #type proc "system" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: [^]QueueFamilyProperties)
ProcGetPhysicalDeviceQueueFamilyProperties2                         :: #type proc "system" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: [^]QueueFamilyProperties2)
ProcGetPhysicalDeviceQueueFamilyProperties2KHR                      :: #type proc "system" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: [^]QueueFamilyProperties2)
ProcGetPhysicalDeviceSparseImageFormatProperties                    :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, samples: SampleCountFlags, usage: ImageUsageFlags, tiling: ImageTiling, pPropertyCount: ^u32, pProperties: [^]SparseImageFormatProperties)
ProcGetPhysicalDeviceSparseImageFormatProperties2                   :: #type proc "system" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: [^]SparseImageFormatProperties2)
ProcGetPhysicalDeviceSparseImageFormatProperties2KHR                :: #type proc "system" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: [^]SparseImageFormatProperties2)
ProcGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV :: #type proc "system" (physicalDevice: PhysicalDevice, pCombinationCount: ^u32, pCombinations: [^]FramebufferMixedSamplesCombinationNV) -> Result
ProcGetPhysicalDeviceSurfaceCapabilities2EXT                        :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: [^]SurfaceCapabilities2EXT) -> Result
ProcGetPhysicalDeviceSurfaceCapabilities2KHR                        :: #type proc "system" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceCapabilities: [^]SurfaceCapabilities2KHR) -> Result
ProcGetPhysicalDeviceSurfaceCapabilitiesKHR                         :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: [^]SurfaceCapabilitiesKHR) -> Result
ProcGetPhysicalDeviceSurfaceFormats2KHR                             :: #type proc "system" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: [^]SurfaceFormat2KHR) -> Result
ProcGetPhysicalDeviceSurfaceFormatsKHR                              :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: [^]SurfaceFormatKHR) -> Result
ProcGetPhysicalDeviceSurfacePresentModes2EXT                        :: #type proc "system" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pPresentModeCount: ^u32, pPresentModes: [^]PresentModeKHR) -> Result
ProcGetPhysicalDeviceSurfacePresentModesKHR                         :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pPresentModeCount: ^u32, pPresentModes: [^]PresentModeKHR) -> Result
ProcGetPhysicalDeviceSurfaceSupportKHR                              :: #type proc "system" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, surface: SurfaceKHR, pSupported: ^b32) -> Result
ProcGetPhysicalDeviceToolProperties                                 :: #type proc "system" (physicalDevice: PhysicalDevice, pToolCount: ^u32, pToolProperties: [^]PhysicalDeviceToolProperties) -> Result
ProcGetPhysicalDeviceToolPropertiesEXT                              :: #type proc "system" (physicalDevice: PhysicalDevice, pToolCount: ^u32, pToolProperties: [^]PhysicalDeviceToolProperties) -> Result
ProcGetPhysicalDeviceWin32PresentationSupportKHR                    :: #type proc "system" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32) -> b32
ProcGetWinrtDisplayNV                                               :: #type proc "system" (physicalDevice: PhysicalDevice, deviceRelativeId: u32, pDisplay: ^DisplayKHR) -> Result
ProcReleaseDisplayEXT                                               :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
ProcSubmitDebugUtilsMessageEXT                                      :: #type proc "system" (instance: Instance, messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT)

// Device Procedure Types
ProcAcquireFullScreenExclusiveModeEXT               :: #type proc "system" (device: Device, swapchain: SwapchainKHR) -> Result
ProcAcquireNextImage2KHR                            :: #type proc "system" (device: Device, pAcquireInfo: ^AcquireNextImageInfoKHR, pImageIndex: ^u32) -> Result
ProcAcquireNextImageKHR                             :: #type proc "system" (device: Device, swapchain: SwapchainKHR, timeout: u64, semaphore: Semaphore, fence: Fence, pImageIndex: ^u32) -> Result
ProcAcquirePerformanceConfigurationINTEL            :: #type proc "system" (device: Device, pAcquireInfo: ^PerformanceConfigurationAcquireInfoINTEL, pConfiguration: ^PerformanceConfigurationINTEL) -> Result
ProcAcquireProfilingLockKHR                         :: #type proc "system" (device: Device, pInfo: ^AcquireProfilingLockInfoKHR) -> Result
ProcAllocateCommandBuffers                          :: #type proc "system" (device: Device, pAllocateInfo: ^CommandBufferAllocateInfo, pCommandBuffers: [^]CommandBuffer) -> Result
ProcAllocateDescriptorSets                          :: #type proc "system" (device: Device, pAllocateInfo: ^DescriptorSetAllocateInfo, pDescriptorSets: [^]DescriptorSet) -> Result
ProcAllocateMemory                                  :: #type proc "system" (device: Device, pAllocateInfo: ^MemoryAllocateInfo, pAllocator: ^AllocationCallbacks, pMemory: ^DeviceMemory) -> Result
ProcBeginCommandBuffer                              :: #type proc "system" (commandBuffer: CommandBuffer, pBeginInfo: ^CommandBufferBeginInfo) -> Result
ProcBindAccelerationStructureMemoryNV               :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindAccelerationStructureMemoryInfoNV) -> Result
ProcBindBufferMemory                                :: #type proc "system" (device: Device, buffer: Buffer, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
ProcBindBufferMemory2                               :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindBufferMemoryInfo) -> Result
ProcBindBufferMemory2KHR                            :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindBufferMemoryInfo) -> Result
ProcBindImageMemory                                 :: #type proc "system" (device: Device, image: Image, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
ProcBindImageMemory2                                :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindImageMemoryInfo) -> Result
ProcBindImageMemory2KHR                             :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindImageMemoryInfo) -> Result
ProcBuildAccelerationStructuresKHR                  :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, infoCount: u32, pInfos: [^]AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^[^]AccelerationStructureBuildRangeInfoKHR) -> Result
ProcCmdBeginConditionalRenderingEXT                 :: #type proc "system" (commandBuffer: CommandBuffer, pConditionalRenderingBegin: ^ConditionalRenderingBeginInfoEXT)
ProcCmdBeginDebugUtilsLabelEXT                      :: #type proc "system" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
ProcCmdBeginQuery                                   :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags)
ProcCmdBeginQueryIndexedEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags, index: u32)
ProcCmdBeginRenderPass                              :: #type proc "system" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, contents: SubpassContents)
ProcCmdBeginRenderPass2                             :: #type proc "system" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
ProcCmdBeginRenderPass2KHR                          :: #type proc "system" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
ProcCmdBeginRendering                               :: #type proc "system" (commandBuffer: CommandBuffer, pRenderingInfo: ^RenderingInfo)
ProcCmdBeginRenderingKHR                            :: #type proc "system" (commandBuffer: CommandBuffer, pRenderingInfo: ^RenderingInfo)
ProcCmdBeginTransformFeedbackEXT                    :: #type proc "system" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: [^]Buffer, pCounterBufferOffsets: [^]DeviceSize)
ProcCmdBindDescriptorSets                           :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, firstSet: u32, descriptorSetCount: u32, pDescriptorSets: [^]DescriptorSet, dynamicOffsetCount: u32, pDynamicOffsets: [^]u32)
ProcCmdBindIndexBuffer                              :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, indexType: IndexType)
ProcCmdBindInvocationMaskHUAWEI                     :: #type proc "system" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
ProcCmdBindPipeline                                 :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline)
ProcCmdBindPipelineShaderGroupNV                    :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline, groupIndex: u32)
ProcCmdBindShadingRateImageNV                       :: #type proc "system" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
ProcCmdBindTransformFeedbackBuffersEXT              :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize, pSizes: [^]DeviceSize)
ProcCmdBindVertexBuffers                            :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize)
ProcCmdBindVertexBuffers2                           :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize, pSizes: [^]DeviceSize, pStrides: [^]DeviceSize)
ProcCmdBindVertexBuffers2EXT                        :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize, pSizes: [^]DeviceSize, pStrides: [^]DeviceSize)
ProcCmdBlitImage                                    :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]ImageBlit, filter: Filter)
ProcCmdBlitImage2                                   :: #type proc "system" (commandBuffer: CommandBuffer, pBlitImageInfo: ^BlitImageInfo2)
ProcCmdBlitImage2KHR                                :: #type proc "system" (commandBuffer: CommandBuffer, pBlitImageInfo: ^BlitImageInfo2)
ProcCmdBuildAccelerationStructureNV                 :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^AccelerationStructureInfoNV, instanceData: Buffer, instanceOffset: DeviceSize, update: b32, dst: AccelerationStructureNV, src: AccelerationStructureNV, scratch: Buffer, scratchOffset: DeviceSize)
ProcCmdBuildAccelerationStructuresIndirectKHR       :: #type proc "system" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: [^]AccelerationStructureBuildGeometryInfoKHR, pIndirectDeviceAddresses: [^]DeviceAddress, pIndirectStrides: [^]u32, ppMaxPrimitiveCounts: ^[^]u32)
ProcCmdBuildAccelerationStructuresKHR               :: #type proc "system" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: [^]AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^[^]AccelerationStructureBuildRangeInfoKHR)
ProcCmdClearAttachments                             :: #type proc "system" (commandBuffer: CommandBuffer, attachmentCount: u32, pAttachments: [^]ClearAttachment, rectCount: u32, pRects: [^]ClearRect)
ProcCmdClearColorImage                              :: #type proc "system" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pColor: ^ClearColorValue, rangeCount: u32, pRanges: [^]ImageSubresourceRange)
ProcCmdClearDepthStencilImage                       :: #type proc "system" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pDepthStencil: ^ClearDepthStencilValue, rangeCount: u32, pRanges: [^]ImageSubresourceRange)
ProcCmdCopyAccelerationStructureKHR                 :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureInfoKHR)
ProcCmdCopyAccelerationStructureNV                  :: #type proc "system" (commandBuffer: CommandBuffer, dst: AccelerationStructureNV, src: AccelerationStructureNV, mode: CopyAccelerationStructureModeKHR)
ProcCmdCopyAccelerationStructureToMemoryKHR         :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR)
ProcCmdCopyBuffer                                   :: #type proc "system" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstBuffer: Buffer, regionCount: u32, pRegions: [^]BufferCopy)
ProcCmdCopyBuffer2                                  :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferInfo: ^CopyBufferInfo2)
ProcCmdCopyBuffer2KHR                               :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferInfo: ^CopyBufferInfo2)
ProcCmdCopyBufferToImage                            :: #type proc "system" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]BufferImageCopy)
ProcCmdCopyBufferToImage2                           :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferToImageInfo: ^CopyBufferToImageInfo2)
ProcCmdCopyBufferToImage2KHR                        :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferToImageInfo: ^CopyBufferToImageInfo2)
ProcCmdCopyImage                                    :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]ImageCopy)
ProcCmdCopyImage2                                   :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageInfo: ^CopyImageInfo2)
ProcCmdCopyImage2KHR                                :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageInfo: ^CopyImageInfo2)
ProcCmdCopyImageToBuffer                            :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstBuffer: Buffer, regionCount: u32, pRegions: [^]BufferImageCopy)
ProcCmdCopyImageToBuffer2                           :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageToBufferInfo: ^CopyImageToBufferInfo2)
ProcCmdCopyImageToBuffer2KHR                        :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageToBufferInfo: ^CopyImageToBufferInfo2)
ProcCmdCopyMemoryToAccelerationStructureKHR         :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR)
ProcCmdCopyQueryPoolResults                         :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dstBuffer: Buffer, dstOffset: DeviceSize, stride: DeviceSize, flags: QueryResultFlags)
ProcCmdCuLaunchKernelNVX                            :: #type proc "system" (commandBuffer: CommandBuffer, pLaunchInfo: ^CuLaunchInfoNVX)
ProcCmdDebugMarkerBeginEXT                          :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
ProcCmdDebugMarkerEndEXT                            :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdDebugMarkerInsertEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
ProcCmdDispatch                                     :: #type proc "system" (commandBuffer: CommandBuffer, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDispatchBase                                 :: #type proc "system" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDispatchBaseKHR                              :: #type proc "system" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDispatchIndirect                             :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize)
ProcCmdDraw                                         :: #type proc "system" (commandBuffer: CommandBuffer, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32)
ProcCmdDrawIndexed                                  :: #type proc "system" (commandBuffer: CommandBuffer, indexCount: u32, instanceCount: u32, firstIndex: u32, vertexOffset: i32, firstInstance: u32)
ProcCmdDrawIndexedIndirect                          :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
ProcCmdDrawIndexedIndirectCount                     :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndexedIndirectCountAMD                  :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndexedIndirectCountKHR                  :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndirect                                 :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
ProcCmdDrawIndirectByteCountEXT                     :: #type proc "system" (commandBuffer: CommandBuffer, instanceCount: u32, firstInstance: u32, counterBuffer: Buffer, counterBufferOffset: DeviceSize, counterOffset: u32, vertexStride: u32)
ProcCmdDrawIndirectCount                            :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndirectCountAMD                         :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndirectCountKHR                         :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawMeshTasksIndirectCountNV                 :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawMeshTasksIndirectNV                      :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
ProcCmdDrawMeshTasksNV                              :: #type proc "system" (commandBuffer: CommandBuffer, taskCount: u32, firstTask: u32)
ProcCmdDrawMultiEXT                                 :: #type proc "system" (commandBuffer: CommandBuffer, drawCount: u32, pVertexInfo: ^MultiDrawInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32)
ProcCmdDrawMultiIndexedEXT                          :: #type proc "system" (commandBuffer: CommandBuffer, drawCount: u32, pIndexInfo: ^MultiDrawIndexedInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32, pVertexOffset: ^i32)
ProcCmdEndConditionalRenderingEXT                   :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndDebugUtilsLabelEXT                        :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndQuery                                     :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32)
ProcCmdEndQueryIndexedEXT                           :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, index: u32)
ProcCmdEndRenderPass                                :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndRenderPass2                               :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdEndRenderPass2KHR                            :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdEndRendering                                 :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndRenderingKHR                              :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndTransformFeedbackEXT                      :: #type proc "system" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: [^]Buffer, pCounterBufferOffsets: [^]DeviceSize)
ProcCmdExecuteCommands                              :: #type proc "system" (commandBuffer: CommandBuffer, commandBufferCount: u32, pCommandBuffers: [^]CommandBuffer)
ProcCmdExecuteGeneratedCommandsNV                   :: #type proc "system" (commandBuffer: CommandBuffer, isPreprocessed: b32, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
ProcCmdFillBuffer                                   :: #type proc "system" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, size: DeviceSize, data: u32)
ProcCmdInsertDebugUtilsLabelEXT                     :: #type proc "system" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
ProcCmdNextSubpass                                  :: #type proc "system" (commandBuffer: CommandBuffer, contents: SubpassContents)
ProcCmdNextSubpass2                                 :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdNextSubpass2KHR                              :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdPipelineBarrier                              :: #type proc "system" (commandBuffer: CommandBuffer, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, dependencyFlags: DependencyFlags, memoryBarrierCount: u32, pMemoryBarriers: [^]MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: [^]BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: [^]ImageMemoryBarrier)
ProcCmdPipelineBarrier2                             :: #type proc "system" (commandBuffer: CommandBuffer, pDependencyInfo: ^DependencyInfo)
ProcCmdPipelineBarrier2KHR                          :: #type proc "system" (commandBuffer: CommandBuffer, pDependencyInfo: ^DependencyInfo)
ProcCmdPreprocessGeneratedCommandsNV                :: #type proc "system" (commandBuffer: CommandBuffer, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
ProcCmdPushConstants                                :: #type proc "system" (commandBuffer: CommandBuffer, layout: PipelineLayout, stageFlags: ShaderStageFlags, offset: u32, size: u32, pValues: rawptr)
ProcCmdPushDescriptorSetKHR                         :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, set: u32, descriptorWriteCount: u32, pDescriptorWrites: [^]WriteDescriptorSet)
ProcCmdPushDescriptorSetWithTemplateKHR             :: #type proc "system" (commandBuffer: CommandBuffer, descriptorUpdateTemplate: DescriptorUpdateTemplate, layout: PipelineLayout, set: u32, pData: rawptr)
ProcCmdResetEvent                                   :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
ProcCmdResetEvent2                                  :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags2)
ProcCmdResetEvent2KHR                               :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags2)
ProcCmdResetQueryPool                               :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
ProcCmdResolveImage                                 :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]ImageResolve)
ProcCmdResolveImage2                                :: #type proc "system" (commandBuffer: CommandBuffer, pResolveImageInfo: ^ResolveImageInfo2)
ProcCmdResolveImage2KHR                             :: #type proc "system" (commandBuffer: CommandBuffer, pResolveImageInfo: ^ResolveImageInfo2)
ProcCmdSetBlendConstants                            :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdSetCheckpointNV                              :: #type proc "system" (commandBuffer: CommandBuffer, pCheckpointMarker: rawptr)
ProcCmdSetCoarseSampleOrderNV                       :: #type proc "system" (commandBuffer: CommandBuffer, sampleOrderType: CoarseSampleOrderTypeNV, customSampleOrderCount: u32, pCustomSampleOrders: [^]CoarseSampleOrderCustomNV)
ProcCmdSetCullMode                                  :: #type proc "system" (commandBuffer: CommandBuffer, cullMode: CullModeFlags)
ProcCmdSetCullModeEXT                               :: #type proc "system" (commandBuffer: CommandBuffer, cullMode: CullModeFlags)
ProcCmdSetDepthBias                                 :: #type proc "system" (commandBuffer: CommandBuffer, depthBiasConstantFactor: f32, depthBiasClamp: f32, depthBiasSlopeFactor: f32)
ProcCmdSetDepthBiasEnable                           :: #type proc "system" (commandBuffer: CommandBuffer, depthBiasEnable: b32)
ProcCmdSetDepthBiasEnableEXT                        :: #type proc "system" (commandBuffer: CommandBuffer, depthBiasEnable: b32)
ProcCmdSetDepthBounds                               :: #type proc "system" (commandBuffer: CommandBuffer, minDepthBounds: f32, maxDepthBounds: f32)
ProcCmdSetDepthBoundsTestEnable                     :: #type proc "system" (commandBuffer: CommandBuffer, depthBoundsTestEnable: b32)
ProcCmdSetDepthBoundsTestEnableEXT                  :: #type proc "system" (commandBuffer: CommandBuffer, depthBoundsTestEnable: b32)
ProcCmdSetDepthCompareOp                            :: #type proc "system" (commandBuffer: CommandBuffer, depthCompareOp: CompareOp)
ProcCmdSetDepthCompareOpEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, depthCompareOp: CompareOp)
ProcCmdSetDepthTestEnable                           :: #type proc "system" (commandBuffer: CommandBuffer, depthTestEnable: b32)
ProcCmdSetDepthTestEnableEXT                        :: #type proc "system" (commandBuffer: CommandBuffer, depthTestEnable: b32)
ProcCmdSetDepthWriteEnable                          :: #type proc "system" (commandBuffer: CommandBuffer, depthWriteEnable: b32)
ProcCmdSetDepthWriteEnableEXT                       :: #type proc "system" (commandBuffer: CommandBuffer, depthWriteEnable: b32)
ProcCmdSetDeviceMask                                :: #type proc "system" (commandBuffer: CommandBuffer, deviceMask: u32)
ProcCmdSetDeviceMaskKHR                             :: #type proc "system" (commandBuffer: CommandBuffer, deviceMask: u32)
ProcCmdSetDiscardRectangleEXT                       :: #type proc "system" (commandBuffer: CommandBuffer, firstDiscardRectangle: u32, discardRectangleCount: u32, pDiscardRectangles: [^]Rect2D)
ProcCmdSetEvent                                     :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
ProcCmdSetEvent2                                    :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, pDependencyInfo: ^DependencyInfo)
ProcCmdSetEvent2KHR                                 :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, pDependencyInfo: ^DependencyInfo)
ProcCmdSetExclusiveScissorNV                        :: #type proc "system" (commandBuffer: CommandBuffer, firstExclusiveScissor: u32, exclusiveScissorCount: u32, pExclusiveScissors: [^]Rect2D)
ProcCmdSetFragmentShadingRateEnumNV                 :: #type proc "system" (commandBuffer: CommandBuffer, shadingRate: FragmentShadingRateNV)
ProcCmdSetFragmentShadingRateKHR                    :: #type proc "system" (commandBuffer: CommandBuffer, pFragmentSize: ^Extent2D)
ProcCmdSetFrontFace                                 :: #type proc "system" (commandBuffer: CommandBuffer, frontFace: FrontFace)
ProcCmdSetFrontFaceEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, frontFace: FrontFace)
ProcCmdSetLineStippleEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, lineStippleFactor: u32, lineStipplePattern: u16)
ProcCmdSetLineWidth                                 :: #type proc "system" (commandBuffer: CommandBuffer, lineWidth: f32)
ProcCmdSetLogicOpEXT                                :: #type proc "system" (commandBuffer: CommandBuffer, logicOp: LogicOp)
ProcCmdSetPatchControlPointsEXT                     :: #type proc "system" (commandBuffer: CommandBuffer, patchControlPoints: u32)
ProcCmdSetPerformanceMarkerINTEL                    :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceMarkerInfoINTEL) -> Result
ProcCmdSetPerformanceOverrideINTEL                  :: #type proc "system" (commandBuffer: CommandBuffer, pOverrideInfo: ^PerformanceOverrideInfoINTEL) -> Result
ProcCmdSetPerformanceStreamMarkerINTEL              :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceStreamMarkerInfoINTEL) -> Result
ProcCmdSetPrimitiveRestartEnable                    :: #type proc "system" (commandBuffer: CommandBuffer, primitiveRestartEnable: b32)
ProcCmdSetPrimitiveRestartEnableEXT                 :: #type proc "system" (commandBuffer: CommandBuffer, primitiveRestartEnable: b32)
ProcCmdSetPrimitiveTopology                         :: #type proc "system" (commandBuffer: CommandBuffer, primitiveTopology: PrimitiveTopology)
ProcCmdSetPrimitiveTopologyEXT                      :: #type proc "system" (commandBuffer: CommandBuffer, primitiveTopology: PrimitiveTopology)
ProcCmdSetRasterizerDiscardEnable                   :: #type proc "system" (commandBuffer: CommandBuffer, rasterizerDiscardEnable: b32)
ProcCmdSetRasterizerDiscardEnableEXT                :: #type proc "system" (commandBuffer: CommandBuffer, rasterizerDiscardEnable: b32)
ProcCmdSetRayTracingPipelineStackSizeKHR            :: #type proc "system" (commandBuffer: CommandBuffer, pipelineStackSize: u32)
ProcCmdSetSampleLocationsEXT                        :: #type proc "system" (commandBuffer: CommandBuffer, pSampleLocationsInfo: ^SampleLocationsInfoEXT)
ProcCmdSetScissor                                   :: #type proc "system" (commandBuffer: CommandBuffer, firstScissor: u32, scissorCount: u32, pScissors: [^]Rect2D)
ProcCmdSetScissorWithCount                          :: #type proc "system" (commandBuffer: CommandBuffer, scissorCount: u32, pScissors: [^]Rect2D)
ProcCmdSetScissorWithCountEXT                       :: #type proc "system" (commandBuffer: CommandBuffer, scissorCount: u32, pScissors: [^]Rect2D)
ProcCmdSetStencilCompareMask                        :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, compareMask: u32)
ProcCmdSetStencilOp                                 :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, failOp: StencilOp, passOp: StencilOp, depthFailOp: StencilOp, compareOp: CompareOp)
ProcCmdSetStencilOpEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, failOp: StencilOp, passOp: StencilOp, depthFailOp: StencilOp, compareOp: CompareOp)
ProcCmdSetStencilReference                          :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, reference: u32)
ProcCmdSetStencilTestEnable                         :: #type proc "system" (commandBuffer: CommandBuffer, stencilTestEnable: b32)
ProcCmdSetStencilTestEnableEXT                      :: #type proc "system" (commandBuffer: CommandBuffer, stencilTestEnable: b32)
ProcCmdSetStencilWriteMask                          :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, writeMask: u32)
ProcCmdSetVertexInputEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, vertexBindingDescriptionCount: u32, pVertexBindingDescriptions: [^]VertexInputBindingDescription2EXT, vertexAttributeDescriptionCount: u32, pVertexAttributeDescriptions: [^]VertexInputAttributeDescription2EXT)
ProcCmdSetViewport                                  :: #type proc "system" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewports: [^]Viewport)
ProcCmdSetViewportShadingRatePaletteNV              :: #type proc "system" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pShadingRatePalettes: [^]ShadingRatePaletteNV)
ProcCmdSetViewportWScalingNV                        :: #type proc "system" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewportWScalings: [^]ViewportWScalingNV)
ProcCmdSetViewportWithCount                         :: #type proc "system" (commandBuffer: CommandBuffer, viewportCount: u32, pViewports: [^]Viewport)
ProcCmdSetViewportWithCountEXT                      :: #type proc "system" (commandBuffer: CommandBuffer, viewportCount: u32, pViewports: [^]Viewport)
ProcCmdSubpassShadingHUAWEI                         :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdTraceRaysIndirectKHR                         :: #type proc "system" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pMissShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pHitShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: [^]StridedDeviceAddressRegionKHR, indirectDeviceAddress: DeviceAddress)
ProcCmdTraceRaysKHR                                 :: #type proc "system" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pMissShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pHitShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: [^]StridedDeviceAddressRegionKHR, width: u32, height: u32, depth: u32)
ProcCmdTraceRaysNV                                  :: #type proc "system" (commandBuffer: CommandBuffer, raygenShaderBindingTableBuffer: Buffer, raygenShaderBindingOffset: DeviceSize, missShaderBindingTableBuffer: Buffer, missShaderBindingOffset: DeviceSize, missShaderBindingStride: DeviceSize, hitShaderBindingTableBuffer: Buffer, hitShaderBindingOffset: DeviceSize, hitShaderBindingStride: DeviceSize, callableShaderBindingTableBuffer: Buffer, callableShaderBindingOffset: DeviceSize, callableShaderBindingStride: DeviceSize, width: u32, height: u32, depth: u32)
ProcCmdUpdateBuffer                                 :: #type proc "system" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, dataSize: DeviceSize, pData: rawptr)
ProcCmdWaitEvents                                   :: #type proc "system" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: [^]Event, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, memoryBarrierCount: u32, pMemoryBarriers: [^]MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: [^]BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: [^]ImageMemoryBarrier)
ProcCmdWaitEvents2                                  :: #type proc "system" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: [^]Event, pDependencyInfos: [^]DependencyInfo)
ProcCmdWaitEvents2KHR                               :: #type proc "system" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: [^]Event, pDependencyInfos: [^]DependencyInfo)
ProcCmdWriteAccelerationStructuresPropertiesKHR     :: #type proc "system" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: [^]AccelerationStructureKHR, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
ProcCmdWriteAccelerationStructuresPropertiesNV      :: #type proc "system" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: [^]AccelerationStructureNV, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
ProcCmdWriteBufferMarker2AMD                        :: #type proc "system" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
ProcCmdWriteBufferMarkerAMD                         :: #type proc "system" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
ProcCmdWriteTimestamp                               :: #type proc "system" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, queryPool: QueryPool, query: u32)
ProcCmdWriteTimestamp2                              :: #type proc "system" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2, queryPool: QueryPool, query: u32)
ProcCmdWriteTimestamp2KHR                           :: #type proc "system" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2, queryPool: QueryPool, query: u32)
ProcCompileDeferredNV                               :: #type proc "system" (device: Device, pipeline: Pipeline, shader: u32) -> Result
ProcCopyAccelerationStructureKHR                    :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureInfoKHR) -> Result
ProcCopyAccelerationStructureToMemoryKHR            :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR) -> Result
ProcCopyMemoryToAccelerationStructureKHR            :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR) -> Result
ProcCreateAccelerationStructureKHR                  :: #type proc "system" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoKHR, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureKHR) -> Result
ProcCreateAccelerationStructureNV                   :: #type proc "system" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoNV, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureNV) -> Result
ProcCreateBuffer                                    :: #type proc "system" (device: Device, pCreateInfo: ^BufferCreateInfo, pAllocator: ^AllocationCallbacks, pBuffer: ^Buffer) -> Result
ProcCreateBufferView                                :: #type proc "system" (device: Device, pCreateInfo: ^BufferViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^BufferView) -> Result
ProcCreateCommandPool                               :: #type proc "system" (device: Device, pCreateInfo: ^CommandPoolCreateInfo, pAllocator: ^AllocationCallbacks, pCommandPool: ^CommandPool) -> Result
ProcCreateComputePipelines                          :: #type proc "system" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]ComputePipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateCuFunctionNVX                             :: #type proc "system" (device: Device, pCreateInfo: ^CuFunctionCreateInfoNVX, pAllocator: ^AllocationCallbacks, pFunction: ^CuFunctionNVX) -> Result
ProcCreateCuModuleNVX                               :: #type proc "system" (device: Device, pCreateInfo: ^CuModuleCreateInfoNVX, pAllocator: ^AllocationCallbacks, pModule: ^CuModuleNVX) -> Result
ProcCreateDeferredOperationKHR                      :: #type proc "system" (device: Device, pAllocator: ^AllocationCallbacks, pDeferredOperation: ^DeferredOperationKHR) -> Result
ProcCreateDescriptorPool                            :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorPoolCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorPool: ^DescriptorPool) -> Result
ProcCreateDescriptorSetLayout                       :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pSetLayout: ^DescriptorSetLayout) -> Result
ProcCreateDescriptorUpdateTemplate                  :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
ProcCreateDescriptorUpdateTemplateKHR               :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
ProcCreateEvent                                     :: #type proc "system" (device: Device, pCreateInfo: ^EventCreateInfo, pAllocator: ^AllocationCallbacks, pEvent: ^Event) -> Result
ProcCreateFence                                     :: #type proc "system" (device: Device, pCreateInfo: ^FenceCreateInfo, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
ProcCreateFramebuffer                               :: #type proc "system" (device: Device, pCreateInfo: ^FramebufferCreateInfo, pAllocator: ^AllocationCallbacks, pFramebuffer: ^Framebuffer) -> Result
ProcCreateGraphicsPipelines                         :: #type proc "system" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]GraphicsPipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateImage                                     :: #type proc "system" (device: Device, pCreateInfo: ^ImageCreateInfo, pAllocator: ^AllocationCallbacks, pImage: ^Image) -> Result
ProcCreateImageView                                 :: #type proc "system" (device: Device, pCreateInfo: ^ImageViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^ImageView) -> Result
ProcCreateIndirectCommandsLayoutNV                  :: #type proc "system" (device: Device, pCreateInfo: ^IndirectCommandsLayoutCreateInfoNV, pAllocator: ^AllocationCallbacks, pIndirectCommandsLayout: ^IndirectCommandsLayoutNV) -> Result
ProcCreatePipelineCache                             :: #type proc "system" (device: Device, pCreateInfo: ^PipelineCacheCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineCache: ^PipelineCache) -> Result
ProcCreatePipelineLayout                            :: #type proc "system" (device: Device, pCreateInfo: ^PipelineLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineLayout: ^PipelineLayout) -> Result
ProcCreatePrivateDataSlot                           :: #type proc "system" (device: Device, pCreateInfo: ^PrivateDataSlotCreateInfo, pAllocator: ^AllocationCallbacks, pPrivateDataSlot: ^PrivateDataSlot) -> Result
ProcCreatePrivateDataSlotEXT                        :: #type proc "system" (device: Device, pCreateInfo: ^PrivateDataSlotCreateInfo, pAllocator: ^AllocationCallbacks, pPrivateDataSlot: ^PrivateDataSlot) -> Result
ProcCreateQueryPool                                 :: #type proc "system" (device: Device, pCreateInfo: ^QueryPoolCreateInfo, pAllocator: ^AllocationCallbacks, pQueryPool: ^QueryPool) -> Result
ProcCreateRayTracingPipelinesKHR                    :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]RayTracingPipelineCreateInfoKHR, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateRayTracingPipelinesNV                     :: #type proc "system" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]RayTracingPipelineCreateInfoNV, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateRenderPass                                :: #type proc "system" (device: Device, pCreateInfo: ^RenderPassCreateInfo, pAllocator: ^AllocationCallbacks, pRenderPass: [^]RenderPass) -> Result
ProcCreateRenderPass2                               :: #type proc "system" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: [^]RenderPass) -> Result
ProcCreateRenderPass2KHR                            :: #type proc "system" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: [^]RenderPass) -> Result
ProcCreateSampler                                   :: #type proc "system" (device: Device, pCreateInfo: ^SamplerCreateInfo, pAllocator: ^AllocationCallbacks, pSampler: ^Sampler) -> Result
ProcCreateSamplerYcbcrConversion                    :: #type proc "system" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
ProcCreateSamplerYcbcrConversionKHR                 :: #type proc "system" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
ProcCreateSemaphore                                 :: #type proc "system" (device: Device, pCreateInfo: ^SemaphoreCreateInfo, pAllocator: ^AllocationCallbacks, pSemaphore: ^Semaphore) -> Result
ProcCreateShaderModule                              :: #type proc "system" (device: Device, pCreateInfo: ^ShaderModuleCreateInfo, pAllocator: ^AllocationCallbacks, pShaderModule: ^ShaderModule) -> Result
ProcCreateSharedSwapchainsKHR                       :: #type proc "system" (device: Device, swapchainCount: u32, pCreateInfos: [^]SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchains: [^]SwapchainKHR) -> Result
ProcCreateSwapchainKHR                              :: #type proc "system" (device: Device, pCreateInfo: ^SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchain: ^SwapchainKHR) -> Result
ProcCreateValidationCacheEXT                        :: #type proc "system" (device: Device, pCreateInfo: ^ValidationCacheCreateInfoEXT, pAllocator: ^AllocationCallbacks, pValidationCache: ^ValidationCacheEXT) -> Result
ProcDebugMarkerSetObjectNameEXT                     :: #type proc "system" (device: Device, pNameInfo: ^DebugMarkerObjectNameInfoEXT) -> Result
ProcDebugMarkerSetObjectTagEXT                      :: #type proc "system" (device: Device, pTagInfo: ^DebugMarkerObjectTagInfoEXT) -> Result
ProcDeferredOperationJoinKHR                        :: #type proc "system" (device: Device, operation: DeferredOperationKHR) -> Result
ProcDestroyAccelerationStructureKHR                 :: #type proc "system" (device: Device, accelerationStructure: AccelerationStructureKHR, pAllocator: ^AllocationCallbacks)
ProcDestroyAccelerationStructureNV                  :: #type proc "system" (device: Device, accelerationStructure: AccelerationStructureNV, pAllocator: ^AllocationCallbacks)
ProcDestroyBuffer                                   :: #type proc "system" (device: Device, buffer: Buffer, pAllocator: ^AllocationCallbacks)
ProcDestroyBufferView                               :: #type proc "system" (device: Device, bufferView: BufferView, pAllocator: ^AllocationCallbacks)
ProcDestroyCommandPool                              :: #type proc "system" (device: Device, commandPool: CommandPool, pAllocator: ^AllocationCallbacks)
ProcDestroyCuFunctionNVX                            :: #type proc "system" (device: Device, function: CuFunctionNVX, pAllocator: ^AllocationCallbacks)
ProcDestroyCuModuleNVX                              :: #type proc "system" (device: Device, module: CuModuleNVX, pAllocator: ^AllocationCallbacks)
ProcDestroyDeferredOperationKHR                     :: #type proc "system" (device: Device, operation: DeferredOperationKHR, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorPool                           :: #type proc "system" (device: Device, descriptorPool: DescriptorPool, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorSetLayout                      :: #type proc "system" (device: Device, descriptorSetLayout: DescriptorSetLayout, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorUpdateTemplate                 :: #type proc "system" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorUpdateTemplateKHR              :: #type proc "system" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
ProcDestroyDevice                                   :: #type proc "system" (device: Device, pAllocator: ^AllocationCallbacks)
ProcDestroyEvent                                    :: #type proc "system" (device: Device, event: Event, pAllocator: ^AllocationCallbacks)
ProcDestroyFence                                    :: #type proc "system" (device: Device, fence: Fence, pAllocator: ^AllocationCallbacks)
ProcDestroyFramebuffer                              :: #type proc "system" (device: Device, framebuffer: Framebuffer, pAllocator: ^AllocationCallbacks)
ProcDestroyImage                                    :: #type proc "system" (device: Device, image: Image, pAllocator: ^AllocationCallbacks)
ProcDestroyImageView                                :: #type proc "system" (device: Device, imageView: ImageView, pAllocator: ^AllocationCallbacks)
ProcDestroyIndirectCommandsLayoutNV                 :: #type proc "system" (device: Device, indirectCommandsLayout: IndirectCommandsLayoutNV, pAllocator: ^AllocationCallbacks)
ProcDestroyPipeline                                 :: #type proc "system" (device: Device, pipeline: Pipeline, pAllocator: ^AllocationCallbacks)
ProcDestroyPipelineCache                            :: #type proc "system" (device: Device, pipelineCache: PipelineCache, pAllocator: ^AllocationCallbacks)
ProcDestroyPipelineLayout                           :: #type proc "system" (device: Device, pipelineLayout: PipelineLayout, pAllocator: ^AllocationCallbacks)
ProcDestroyPrivateDataSlot                          :: #type proc "system" (device: Device, privateDataSlot: PrivateDataSlot, pAllocator: ^AllocationCallbacks)
ProcDestroyPrivateDataSlotEXT                       :: #type proc "system" (device: Device, privateDataSlot: PrivateDataSlot, pAllocator: ^AllocationCallbacks)
ProcDestroyQueryPool                                :: #type proc "system" (device: Device, queryPool: QueryPool, pAllocator: ^AllocationCallbacks)
ProcDestroyRenderPass                               :: #type proc "system" (device: Device, renderPass: RenderPass, pAllocator: ^AllocationCallbacks)
ProcDestroySampler                                  :: #type proc "system" (device: Device, sampler: Sampler, pAllocator: ^AllocationCallbacks)
ProcDestroySamplerYcbcrConversion                   :: #type proc "system" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
ProcDestroySamplerYcbcrConversionKHR                :: #type proc "system" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
ProcDestroySemaphore                                :: #type proc "system" (device: Device, semaphore: Semaphore, pAllocator: ^AllocationCallbacks)
ProcDestroyShaderModule                             :: #type proc "system" (device: Device, shaderModule: ShaderModule, pAllocator: ^AllocationCallbacks)
ProcDestroySwapchainKHR                             :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pAllocator: ^AllocationCallbacks)
ProcDestroyValidationCacheEXT                       :: #type proc "system" (device: Device, validationCache: ValidationCacheEXT, pAllocator: ^AllocationCallbacks)
ProcDeviceWaitIdle                                  :: #type proc "system" (device: Device) -> Result
ProcDisplayPowerControlEXT                          :: #type proc "system" (device: Device, display: DisplayKHR, pDisplayPowerInfo: ^DisplayPowerInfoEXT) -> Result
ProcEndCommandBuffer                                :: #type proc "system" (commandBuffer: CommandBuffer) -> Result
ProcFlushMappedMemoryRanges                         :: #type proc "system" (device: Device, memoryRangeCount: u32, pMemoryRanges: [^]MappedMemoryRange) -> Result
ProcFreeCommandBuffers                              :: #type proc "system" (device: Device, commandPool: CommandPool, commandBufferCount: u32, pCommandBuffers: [^]CommandBuffer)
ProcFreeDescriptorSets                              :: #type proc "system" (device: Device, descriptorPool: DescriptorPool, descriptorSetCount: u32, pDescriptorSets: [^]DescriptorSet) -> Result
ProcFreeMemory                                      :: #type proc "system" (device: Device, memory: DeviceMemory, pAllocator: ^AllocationCallbacks)
ProcGetAccelerationStructureBuildSizesKHR           :: #type proc "system" (device: Device, buildType: AccelerationStructureBuildTypeKHR, pBuildInfo: ^AccelerationStructureBuildGeometryInfoKHR, pMaxPrimitiveCounts: [^]u32, pSizeInfo: ^AccelerationStructureBuildSizesInfoKHR)
ProcGetAccelerationStructureDeviceAddressKHR        :: #type proc "system" (device: Device, pInfo: ^AccelerationStructureDeviceAddressInfoKHR) -> DeviceAddress
ProcGetAccelerationStructureHandleNV                :: #type proc "system" (device: Device, accelerationStructure: AccelerationStructureNV, dataSize: int, pData: rawptr) -> Result
ProcGetAccelerationStructureMemoryRequirementsNV    :: #type proc "system" (device: Device, pInfo: ^AccelerationStructureMemoryRequirementsInfoNV, pMemoryRequirements: [^]MemoryRequirements2KHR)
ProcGetBufferDeviceAddress                          :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
ProcGetBufferDeviceAddressEXT                       :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
ProcGetBufferDeviceAddressKHR                       :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
ProcGetBufferMemoryRequirements                     :: #type proc "system" (device: Device, buffer: Buffer, pMemoryRequirements: [^]MemoryRequirements)
ProcGetBufferMemoryRequirements2                    :: #type proc "system" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetBufferMemoryRequirements2KHR                 :: #type proc "system" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetBufferOpaqueCaptureAddress                   :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
ProcGetBufferOpaqueCaptureAddressKHR                :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
ProcGetCalibratedTimestampsEXT                      :: #type proc "system" (device: Device, timestampCount: u32, pTimestampInfos: [^]CalibratedTimestampInfoEXT, pTimestamps: [^]u64, pMaxDeviation: ^u64) -> Result
ProcGetDeferredOperationMaxConcurrencyKHR           :: #type proc "system" (device: Device, operation: DeferredOperationKHR) -> u32
ProcGetDeferredOperationResultKHR                   :: #type proc "system" (device: Device, operation: DeferredOperationKHR) -> Result
ProcGetDescriptorSetHostMappingVALVE                :: #type proc "system" (device: Device, descriptorSet: DescriptorSet, ppData: ^rawptr)
ProcGetDescriptorSetLayoutHostMappingInfoVALVE      :: #type proc "system" (device: Device, pBindingReference: ^DescriptorSetBindingReferenceVALVE, pHostMapping: ^DescriptorSetLayoutHostMappingInfoVALVE)
ProcGetDescriptorSetLayoutSupport                   :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
ProcGetDescriptorSetLayoutSupportKHR                :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
ProcGetDeviceAccelerationStructureCompatibilityKHR  :: #type proc "system" (device: Device, pVersionInfo: ^AccelerationStructureVersionInfoKHR, pCompatibility: ^AccelerationStructureCompatibilityKHR)
ProcGetDeviceBufferMemoryRequirements               :: #type proc "system" (device: Device, pInfo: ^DeviceBufferMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceBufferMemoryRequirementsKHR            :: #type proc "system" (device: Device, pInfo: ^DeviceBufferMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceGroupPeerMemoryFeatures                :: #type proc "system" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: [^]PeerMemoryFeatureFlags)
ProcGetDeviceGroupPeerMemoryFeaturesKHR             :: #type proc "system" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: [^]PeerMemoryFeatureFlags)
ProcGetDeviceGroupPresentCapabilitiesKHR            :: #type proc "system" (device: Device, pDeviceGroupPresentCapabilities: [^]DeviceGroupPresentCapabilitiesKHR) -> Result
ProcGetDeviceGroupSurfacePresentModes2EXT           :: #type proc "system" (device: Device, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pModes: [^]DeviceGroupPresentModeFlagsKHR) -> Result
ProcGetDeviceGroupSurfacePresentModesKHR            :: #type proc "system" (device: Device, surface: SurfaceKHR, pModes: [^]DeviceGroupPresentModeFlagsKHR) -> Result
ProcGetDeviceImageMemoryRequirements                :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceImageMemoryRequirementsKHR             :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceImageSparseMemoryRequirements          :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetDeviceImageSparseMemoryRequirementsKHR       :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetDeviceMemoryCommitment                       :: #type proc "system" (device: Device, memory: DeviceMemory, pCommittedMemoryInBytes: [^]DeviceSize)
ProcGetDeviceMemoryOpaqueCaptureAddress             :: #type proc "system" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
ProcGetDeviceMemoryOpaqueCaptureAddressKHR          :: #type proc "system" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
ProcGetDeviceProcAddr                               :: #type proc "system" (device: Device, pName: cstring) -> ProcVoidFunction
ProcGetDeviceQueue                                  :: #type proc "system" (device: Device, queueFamilyIndex: u32, queueIndex: u32, pQueue: ^Queue)
ProcGetDeviceQueue2                                 :: #type proc "system" (device: Device, pQueueInfo: ^DeviceQueueInfo2, pQueue: ^Queue)
ProcGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI   :: #type proc "system" (device: Device, renderpass: RenderPass, pMaxWorkgroupSize: ^Extent2D) -> Result
ProcGetEventStatus                                  :: #type proc "system" (device: Device, event: Event) -> Result
ProcGetFenceFdKHR                                   :: #type proc "system" (device: Device, pGetFdInfo: ^FenceGetFdInfoKHR, pFd: ^c.int) -> Result
ProcGetFenceStatus                                  :: #type proc "system" (device: Device, fence: Fence) -> Result
ProcGetFenceWin32HandleKHR                          :: #type proc "system" (device: Device, pGetWin32HandleInfo: ^FenceGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
ProcGetGeneratedCommandsMemoryRequirementsNV        :: #type proc "system" (device: Device, pInfo: ^GeneratedCommandsMemoryRequirementsInfoNV, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetImageDrmFormatModifierPropertiesEXT          :: #type proc "system" (device: Device, image: Image, pProperties: [^]ImageDrmFormatModifierPropertiesEXT) -> Result
ProcGetImageMemoryRequirements                      :: #type proc "system" (device: Device, image: Image, pMemoryRequirements: [^]MemoryRequirements)
ProcGetImageMemoryRequirements2                     :: #type proc "system" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetImageMemoryRequirements2KHR                  :: #type proc "system" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetImageSparseMemoryRequirements                :: #type proc "system" (device: Device, image: Image, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements)
ProcGetImageSparseMemoryRequirements2               :: #type proc "system" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetImageSparseMemoryRequirements2KHR            :: #type proc "system" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetImageSubresourceLayout                       :: #type proc "system" (device: Device, image: Image, pSubresource: ^ImageSubresource, pLayout: ^SubresourceLayout)
ProcGetImageViewAddressNVX                          :: #type proc "system" (device: Device, imageView: ImageView, pProperties: [^]ImageViewAddressPropertiesNVX) -> Result
ProcGetImageViewHandleNVX                           :: #type proc "system" (device: Device, pInfo: ^ImageViewHandleInfoNVX) -> u32
ProcGetMemoryFdKHR                                  :: #type proc "system" (device: Device, pGetFdInfo: ^MemoryGetFdInfoKHR, pFd: ^c.int) -> Result
ProcGetMemoryFdPropertiesKHR                        :: #type proc "system" (device: Device, handleType: ExternalMemoryHandleTypeFlags, fd: c.int, pMemoryFdProperties: [^]MemoryFdPropertiesKHR) -> Result
ProcGetMemoryHostPointerPropertiesEXT               :: #type proc "system" (device: Device, handleType: ExternalMemoryHandleTypeFlags, pHostPointer: rawptr, pMemoryHostPointerProperties: [^]MemoryHostPointerPropertiesEXT) -> Result
ProcGetMemoryRemoteAddressNV                        :: #type proc "system" (device: Device, pMemoryGetRemoteAddressInfo: ^MemoryGetRemoteAddressInfoNV, pAddress: [^]RemoteAddressNV) -> Result
ProcGetMemoryWin32HandleKHR                         :: #type proc "system" (device: Device, pGetWin32HandleInfo: ^MemoryGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
ProcGetMemoryWin32HandleNV                          :: #type proc "system" (device: Device, memory: DeviceMemory, handleType: ExternalMemoryHandleTypeFlagsNV, pHandle: ^HANDLE) -> Result
ProcGetMemoryWin32HandlePropertiesKHR               :: #type proc "system" (device: Device, handleType: ExternalMemoryHandleTypeFlags, handle: HANDLE, pMemoryWin32HandleProperties: [^]MemoryWin32HandlePropertiesKHR) -> Result
ProcGetPastPresentationTimingGOOGLE                 :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pPresentationTimingCount: ^u32, pPresentationTimings: [^]PastPresentationTimingGOOGLE) -> Result
ProcGetPerformanceParameterINTEL                    :: #type proc "system" (device: Device, parameter: PerformanceParameterTypeINTEL, pValue: ^PerformanceValueINTEL) -> Result
ProcGetPipelineCacheData                            :: #type proc "system" (device: Device, pipelineCache: PipelineCache, pDataSize: ^int, pData: rawptr) -> Result
ProcGetPipelineExecutableInternalRepresentationsKHR :: #type proc "system" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pInternalRepresentationCount: ^u32, pInternalRepresentations: [^]PipelineExecutableInternalRepresentationKHR) -> Result
ProcGetPipelineExecutablePropertiesKHR              :: #type proc "system" (device: Device, pPipelineInfo: ^PipelineInfoKHR, pExecutableCount: ^u32, pProperties: [^]PipelineExecutablePropertiesKHR) -> Result
ProcGetPipelineExecutableStatisticsKHR              :: #type proc "system" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pStatisticCount: ^u32, pStatistics: [^]PipelineExecutableStatisticKHR) -> Result
ProcGetPrivateData                                  :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, pData: ^u64)
ProcGetPrivateDataEXT                               :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, pData: ^u64)
ProcGetQueryPoolResults                             :: #type proc "system" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dataSize: int, pData: rawptr, stride: DeviceSize, flags: QueryResultFlags) -> Result
ProcGetQueueCheckpointData2NV                       :: #type proc "system" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointData2NV)
ProcGetQueueCheckpointDataNV                        :: #type proc "system" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointDataNV)
ProcGetRayTracingCaptureReplayShaderGroupHandlesKHR :: #type proc "system" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
ProcGetRayTracingShaderGroupHandlesKHR              :: #type proc "system" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
ProcGetRayTracingShaderGroupHandlesNV               :: #type proc "system" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
ProcGetRayTracingShaderGroupStackSizeKHR            :: #type proc "system" (device: Device, pipeline: Pipeline, group: u32, groupShader: ShaderGroupShaderKHR) -> DeviceSize
ProcGetRefreshCycleDurationGOOGLE                   :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pDisplayTimingProperties: [^]RefreshCycleDurationGOOGLE) -> Result
ProcGetRenderAreaGranularity                        :: #type proc "system" (device: Device, renderPass: RenderPass, pGranularity: ^Extent2D)
ProcGetSemaphoreCounterValue                        :: #type proc "system" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
ProcGetSemaphoreCounterValueKHR                     :: #type proc "system" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
ProcGetSemaphoreFdKHR                               :: #type proc "system" (device: Device, pGetFdInfo: ^SemaphoreGetFdInfoKHR, pFd: ^c.int) -> Result
ProcGetSemaphoreWin32HandleKHR                      :: #type proc "system" (device: Device, pGetWin32HandleInfo: ^SemaphoreGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
ProcGetShaderInfoAMD                                :: #type proc "system" (device: Device, pipeline: Pipeline, shaderStage: ShaderStageFlags, infoType: ShaderInfoTypeAMD, pInfoSize: ^int, pInfo: rawptr) -> Result
ProcGetSwapchainCounterEXT                          :: #type proc "system" (device: Device, swapchain: SwapchainKHR, counter: SurfaceCounterFlagsEXT, pCounterValue: ^u64) -> Result
ProcGetSwapchainImagesKHR                           :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pSwapchainImageCount: ^u32, pSwapchainImages: [^]Image) -> Result
ProcGetSwapchainStatusKHR                           :: #type proc "system" (device: Device, swapchain: SwapchainKHR) -> Result
ProcGetValidationCacheDataEXT                       :: #type proc "system" (device: Device, validationCache: ValidationCacheEXT, pDataSize: ^int, pData: rawptr) -> Result
ProcImportFenceFdKHR                                :: #type proc "system" (device: Device, pImportFenceFdInfo: ^ImportFenceFdInfoKHR) -> Result
ProcImportFenceWin32HandleKHR                       :: #type proc "system" (device: Device, pImportFenceWin32HandleInfo: ^ImportFenceWin32HandleInfoKHR) -> Result
ProcImportSemaphoreFdKHR                            :: #type proc "system" (device: Device, pImportSemaphoreFdInfo: ^ImportSemaphoreFdInfoKHR) -> Result
ProcImportSemaphoreWin32HandleKHR                   :: #type proc "system" (device: Device, pImportSemaphoreWin32HandleInfo: ^ImportSemaphoreWin32HandleInfoKHR) -> Result
ProcInitializePerformanceApiINTEL                   :: #type proc "system" (device: Device, pInitializeInfo: ^InitializePerformanceApiInfoINTEL) -> Result
ProcInvalidateMappedMemoryRanges                    :: #type proc "system" (device: Device, memoryRangeCount: u32, pMemoryRanges: [^]MappedMemoryRange) -> Result
ProcMapMemory                                       :: #type proc "system" (device: Device, memory: DeviceMemory, offset: DeviceSize, size: DeviceSize, flags: MemoryMapFlags, ppData: ^rawptr) -> Result
ProcMergePipelineCaches                             :: #type proc "system" (device: Device, dstCache: PipelineCache, srcCacheCount: u32, pSrcCaches: [^]PipelineCache) -> Result
ProcMergeValidationCachesEXT                        :: #type proc "system" (device: Device, dstCache: ValidationCacheEXT, srcCacheCount: u32, pSrcCaches: [^]ValidationCacheEXT) -> Result
ProcQueueBeginDebugUtilsLabelEXT                    :: #type proc "system" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
ProcQueueBindSparse                                 :: #type proc "system" (queue: Queue, bindInfoCount: u32, pBindInfo: ^BindSparseInfo, fence: Fence) -> Result
ProcQueueEndDebugUtilsLabelEXT                      :: #type proc "system" (queue: Queue)
ProcQueueInsertDebugUtilsLabelEXT                   :: #type proc "system" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
ProcQueuePresentKHR                                 :: #type proc "system" (queue: Queue, pPresentInfo: ^PresentInfoKHR) -> Result
ProcQueueSetPerformanceConfigurationINTEL           :: #type proc "system" (queue: Queue, configuration: PerformanceConfigurationINTEL) -> Result
ProcQueueSubmit                                     :: #type proc "system" (queue: Queue, submitCount: u32, pSubmits: [^]SubmitInfo, fence: Fence) -> Result
ProcQueueSubmit2                                    :: #type proc "system" (queue: Queue, submitCount: u32, pSubmits: [^]SubmitInfo2, fence: Fence) -> Result
ProcQueueSubmit2KHR                                 :: #type proc "system" (queue: Queue, submitCount: u32, pSubmits: [^]SubmitInfo2, fence: Fence) -> Result
ProcQueueWaitIdle                                   :: #type proc "system" (queue: Queue) -> Result
ProcRegisterDeviceEventEXT                          :: #type proc "system" (device: Device, pDeviceEventInfo: ^DeviceEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
ProcRegisterDisplayEventEXT                         :: #type proc "system" (device: Device, display: DisplayKHR, pDisplayEventInfo: ^DisplayEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
ProcReleaseFullScreenExclusiveModeEXT               :: #type proc "system" (device: Device, swapchain: SwapchainKHR) -> Result
ProcReleasePerformanceConfigurationINTEL            :: #type proc "system" (device: Device, configuration: PerformanceConfigurationINTEL) -> Result
ProcReleaseProfilingLockKHR                         :: #type proc "system" (device: Device)
ProcResetCommandBuffer                              :: #type proc "system" (commandBuffer: CommandBuffer, flags: CommandBufferResetFlags) -> Result
ProcResetCommandPool                                :: #type proc "system" (device: Device, commandPool: CommandPool, flags: CommandPoolResetFlags) -> Result
ProcResetDescriptorPool                             :: #type proc "system" (device: Device, descriptorPool: DescriptorPool, flags: DescriptorPoolResetFlags) -> Result
ProcResetEvent                                      :: #type proc "system" (device: Device, event: Event) -> Result
ProcResetFences                                     :: #type proc "system" (device: Device, fenceCount: u32, pFences: [^]Fence) -> Result
ProcResetQueryPool                                  :: #type proc "system" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
ProcResetQueryPoolEXT                               :: #type proc "system" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
ProcSetDebugUtilsObjectNameEXT                      :: #type proc "system" (device: Device, pNameInfo: ^DebugUtilsObjectNameInfoEXT) -> Result
ProcSetDebugUtilsObjectTagEXT                       :: #type proc "system" (device: Device, pTagInfo: ^DebugUtilsObjectTagInfoEXT) -> Result
ProcSetDeviceMemoryPriorityEXT                      :: #type proc "system" (device: Device, memory: DeviceMemory, priority: f32)
ProcSetEvent                                        :: #type proc "system" (device: Device, event: Event) -> Result
ProcSetHdrMetadataEXT                               :: #type proc "system" (device: Device, swapchainCount: u32, pSwapchains: [^]SwapchainKHR, pMetadata: ^HdrMetadataEXT)
ProcSetLocalDimmingAMD                              :: #type proc "system" (device: Device, swapChain: SwapchainKHR, localDimmingEnable: b32)
ProcSetPrivateData                                  :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, data: u64) -> Result
ProcSetPrivateDataEXT                               :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, data: u64) -> Result
ProcSignalSemaphore                                 :: #type proc "system" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
ProcSignalSemaphoreKHR                              :: #type proc "system" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
ProcTrimCommandPool                                 :: #type proc "system" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
ProcTrimCommandPoolKHR                              :: #type proc "system" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
ProcUninitializePerformanceApiINTEL                 :: #type proc "system" (device: Device)
ProcUnmapMemory                                     :: #type proc "system" (device: Device, memory: DeviceMemory)
ProcUpdateDescriptorSetWithTemplate                 :: #type proc "system" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
ProcUpdateDescriptorSetWithTemplateKHR              :: #type proc "system" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
ProcUpdateDescriptorSets                            :: #type proc "system" (device: Device, descriptorWriteCount: u32, pDescriptorWrites: [^]WriteDescriptorSet, descriptorCopyCount: u32, pDescriptorCopies: [^]CopyDescriptorSet)
ProcWaitForFences                                   :: #type proc "system" (device: Device, fenceCount: u32, pFences: [^]Fence, waitAll: b32, timeout: u64) -> Result
ProcWaitForPresentKHR                               :: #type proc "system" (device: Device, swapchain: SwapchainKHR, presentId: u64, timeout: u64) -> Result
ProcWaitSemaphores                                  :: #type proc "system" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
ProcWaitSemaphoresKHR                               :: #type proc "system" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
ProcWriteAccelerationStructuresPropertiesKHR        :: #type proc "system" (device: Device, accelerationStructureCount: u32, pAccelerationStructures: [^]AccelerationStructureKHR, queryType: QueryType, dataSize: int, pData: rawptr, stride: int) -> Result