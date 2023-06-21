package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    swapchain_enumerate_images_from_handle :: proc(device: ^Device, swapchain: vk.SwapchainKHR, allocator := context.allocator, location := #caller_location) -> ([]vk.Image, bool) #optional_ok
    {
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter", device)
            return nil, false
        }
        
        result: vk.Result
        count: u32
        result = vk.GetSwapchainImagesKHR(device.handle, swapchain, &count, nil)
        if result != .SUCCESS
        {
            log.verbose_error("Failed to enumerate swapchain images, count querry", result)
            return nil, false
        }
        
        images, alloc_err := make([]vk.Image, count, allocator, location)
        if alloc_err != .Nones
        {
            log.verbose_error("Failed to allocate swapchain images slices", alloc_err)
            return nil, false
        }

        result = vk.GetSwapchainImagesKHR(device.handle, swapchain, &count, commons.array_try_as_pointer(images))
        if result != .SUCCESS
        {
            log.verbose_error("Failed to enumerate swapchain images, fill querry", result)
            delete(images, allocator)
            return nil, false
        }

        return images, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    swapchain_create_from_descriptor :: proc(device: ^Device, surface: ^Surface, descriptor: ^Swapchain_Descriptor, allocator := context.allocator) -> (Swapchain, bool) #optional_ok
    {
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid vulkan device parameter", device)
            return {}, false
        }

        if !surface_is_valid(surface)
        {
            log.verbose_error("Invalid vulkan surface parameter", surface)
            return {}, false
        }

        if !swapchain_descriptor_is_valid(descriptor)
        {
            log.verbose_error("Invalid vulkan swapchain descriptor parameter", descriptor)
            return {}, false
        }

        if !surface_support_image_count(surface, descriptor.image_count)
        {
            log.verbose_error("Unsupported swapchain image count", descriptor.image_count)
            return {}, false
        }

        if !surface_support_image_format(surface, descriptor.image_format)
        {
            log.verbose_error("Unsupported swapchain image format", descriptor.image_format)
            return {}, false
        }

        if !surface_support_image_present_mode(surface, descriptor.present_mode)
        {
            log.verbose_error("Unsupported swapchain present mode", descriptor.present_mode)
            return {}, false
        }

        //Making create info
        info: vk.SwapchainCreateInfoKHR
        info.sType = .SWAPCHAIN_CREATE_INFO_KHR
        info.imageUsage = {.COLOR_ATTACHMENT}
        info.compositeAlpha = {.OPAQUE}
        info.surface = surface.handle
        info.imageExtent = surface.capabilities.currentExtent
        info.preTransform = surface.capabilities.currentTransform
        info.minImageCount = cast(u32)descriptor.image_count
        info.imageFormat = descriptor.image_format.format
        info.imageColorSpace = descriptor.image_format.colorSpace
        info.presentMode = descriptor.present_mode
        info.imageSharingMode = device.graphics_do_present ? .EXCLUSIVE : .CONCURRENT
        info.clipped = cast(b32)descriptor.clipped
        info.imageArrayLayers = 1

        //HERE: fix logging format
        handle: vk.SwapchainKHR
        result := vk.CreateSwapchainKHR(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create swapchain", location) do return {}, false

        //Getting swapchain images
        images, images_succ := swapchain_enumerate_images_from_handle(device, handle, allocator, location)
        if log.verbose_fail_error(!images_succ, "enumerate vulkan swapchain images", location)
        {
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }

        //Making image views slice
        image_views, iv_alloc_err := make([]Image_View, descriptor.image_count, allocator)
        if log.verbose_fail_error(iv_alloc_err != .None, "make image views slice", location)
        {
            delete(images, allocator)
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }
        
        //Making image view descriptor
        image_view_desc: Image_View_Descriptor
        image_view_descriptor.flags = descriptor.image_view_flags
        image_view_descriptor.view_type = descriptor.image_view_type
        image_view_descriptor.format = descriptor.image_format.format
        image_view_descriptor.components = descriptor.image_view_components
        image_view_descriptor.subresource_range = descriptor.image_view_subresource_range
        
        //Creating image views
        iv_created_count := 0
        for image, index in images
        {   
            image_view_descriptor.image = image
            image_view, success := image_view_create(device, &image_view_desc, location)
            if !success do break

            image_views[index] = image_view
            iv_created_count += 1
        }

        //Cheking creation fail
        if log.verbose_fail_error(iv_created_count != len(image_views), "create image views", location)
        {
            for i := 0; i < iv_created_count; i += 1 do image_view_destroy(device, &image_views[i], location)
            delete(image_views, allocator)
            delete(images, allocator)
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }

        //Making swapchain
        swapchain: Swapchain
        swapchain.allocator = allocator
        swapchain.image_count = descriptor.image_count
        swapchain.image_extent = surface.capabilities.currentExtent
        swapchain.image_format = descriptor.image_format
        swapchain.present_mode = descriptor.present_mode
        swapchain.images = images
        swapchain.image_views = image_views
        swapchain.handle = handle
        return swapchain, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    swapchain_destroy :: proc(device: ^Device, swapchain: ^Swapchain, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!swapchain_is_valid(swapchain), "invalid vulkan swapchain parameter", location) do return false

        allocator := swapchain.allocator

        if swapchain.handle != 0
        {
            vk.DestroySwapchainKHR(device.handle, swapchain.handle, nil)
            swapchain.handle = 0
        }

        if swapchain.image_views != nil
        {
            for i := 0; i < len(swapchain.image_views); i += 1 do image_view_destroy(device, &swapchain.image_views[i], location)
            delete(swapchain.image_views, allocator)
            swapchain.image_views = nil
        }

        if swapchain.images != nil
        {
            delete(swapchain.images, allocator)
            swapchain.images = nil
        }
        
        return true
    }
}