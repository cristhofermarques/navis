package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    swapchain_enumerate_images_from_handle :: proc(device: ^Device, swapchain: vk.SwapchainKHR, allocator := context.allocator) -> ([]vk.Image, bool) #optional_ok
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
        
        images, alloc_err := make([]vk.Image, count, allocator)
        if alloc_err != .None
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

        if !surface_support_present_mode(surface, descriptor.present_mode)
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

        //Creating swapchain
        handle: vk.SwapchainKHR
        result := vk.CreateSwapchainKHR(device.handle, &info, nil, &handle)
        if result != .SUCCESS
        {
            log.verbose_error("Failed to create swapchain", result, info)
            return {}, false
        }

        //Getting swapchain images
        images, enumerate_images_success := swapchain_enumerate_images_from_handle(device, handle, allocator)
        if !enumerate_images_success
        {
            log.verbose_error("Failed to enumerate swapchain images", handle)
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }

        //Allocating image views slice
        image_views, image_views_slice_allocation_error := make([]Image_View, descriptor.image_count, allocator)
        if image_views_slice_allocation_error != .None
        {
            log.verbose_error("Failed to allocate image views slice", image_views_slice_allocation_error)
            delete(images, allocator)
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }
        
        //Making image view descriptor
        image_view_descriptor: Image_View_Descriptor
        image_view_descriptor.flags = descriptor.image_view_flags
        image_view_descriptor.view_type = descriptor.image_view_type
        image_view_descriptor.format = descriptor.image_format.format
        image_view_descriptor.components = descriptor.image_view_components
        image_view_descriptor.subresource_range = descriptor.image_view_subresource_range
        
        //Creating image views
        image_views_created_count := 0
        for image, index in images
        {   
            //Setting current image to descriptor
            image_view_descriptor.image = image
            
            //Create image view
            image_view, image_view_create_success := image_view_create(device, &image_view_descriptor)
            if !image_view_create_success do break

            //Setting after creation
            image_views[index] = image_view
            image_views_created_count += 1
        }

        //Cheking creation fail
        image_views_created_success := image_views_created_count == len(image_views)
        if !image_views_created_success
        {
            log.verbose_error("Failed to create image views, Created", image_views_created_count, "of", len(image_views), image_view_descriptor)

            //Deleting created image views
            for i := 0; i < image_views_created_count; i += 1 do image_view_destroy(device, &image_views[i])
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
        if !device_is_valid(device)
        {
            log.verbose_error("Invalid device parameter", device)
            return false
        }

        if !swapchain_is_valid(swapchain)
        {
            log.verbose_error("Invalid swapchain parameter", swapchain)
            return false
        }

        allocator := swapchain.allocator

        //Destroying swapchain
        if handle_is_valid(swapchain.handle)
        {
            vk.DestroySwapchainKHR(device.handle, swapchain.handle, nil)
            swapchain.handle = 0
        }
        
        //Destroying image views
        if swapchain.image_views != nil
        {
            for i := 0; i < len(swapchain.image_views); i += 1 do image_view_destroy(device, &swapchain.image_views[i], location)
            delete(swapchain.image_views, allocator)
            swapchain.image_views = nil
        }

        //Destroying images slice
        if swapchain.images != nil
        {
            delete(swapchain.images, allocator)
            swapchain.images = nil
        }
        
        return true
    }
}