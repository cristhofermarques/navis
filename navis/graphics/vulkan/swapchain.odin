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
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return nil, false
        
        result: vk.Result
        count: u32
        result = vk.GetSwapchainImagesKHR(device.handle, swapchain, &count, nil)
        if log.verbose_fail_error(result != .SUCCESS, "enumerate swapchain images, count querry", location) do return nil, false
        
        images, alloc_err := make([]vk.Image, count, allocator, location)
        if log.verbose_fail_error(alloc_err != .None, "make swapchain images slice", location) do return nil, false

        result = vk.GetSwapchainImagesKHR(device.handle, swapchain, &count, commons.array_try_as_pointer(images))
        if log.verbose_fail_error(result != .SUCCESS, "enumerate swapchain images, fill querry", location)
        {
            delete(images, allocator)
            return nil, false
        }

        return images, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    swapchain_create_from_descriptor :: proc(device: ^Device, surface: ^Surface, render_pass: ^Render_Pass, desc: ^Swapchain_Descriptor, allocator := context.allocator, location := #caller_location) -> (Swapchain, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(!surface_is_valid(surface), "invalid vulkan surface parameter", location) do return {}, false
        if log.verbose_fail_error(!render_pass_is_valid(render_pass), "invalid vulkan render pass parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid swapchain descriptor parameter", location) do return {}, false
        if log.verbose_fail_error(!surface_support_image_count(surface, desc.image_count), "invalid swapchain image count", location) do return {}, false
        if log.verbose_fail_error(!surface_support_image_format(surface, desc.image_format), "unsupported swapchain image format", location) do return {}, false
        if log.verbose_fail_error(!surface_support_present_mode(surface, desc.present_mode), "unsupported swapchain present mode", location) do return {}, false

        info: vk.SwapchainCreateInfoKHR
        info.sType = .SWAPCHAIN_CREATE_INFO_KHR
        info.imageUsage = {.COLOR_ATTACHMENT}
        info.compositeAlpha = {.OPAQUE}
        info.surface = surface.handle
        info.imageExtent = surface.capabilities.currentExtent
        info.preTransform = surface.capabilities.currentTransform
        info.minImageCount = cast(u32)desc.image_count
        info.imageFormat = desc.image_format.format
        info.imageColorSpace = desc.image_format.colorSpace
        info.presentMode = desc.present_mode
        info.imageSharingMode = device.graphics_do_present ? .EXCLUSIVE : .CONCURRENT
        info.clipped = cast(b32)desc.clipped
        info.imageArrayLayers = 1

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
        image_views, iv_alloc_err := make([]Image_View, desc.image_count, allocator)
        if log.verbose_fail_error(iv_alloc_err != .None, "make image views slice", location)
        {
            delete(images, allocator)
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }
        
        //Making image view descriptor
        image_view_desc: Image_View_Descriptor
        image_view_desc.flags = desc.image_view_flags
        image_view_desc.view_type = desc.image_view_type
        image_view_desc.format = desc.image_format.format
        image_view_desc.components = desc.image_view_components
        image_view_desc.subresource_range = desc.image_view_subresource_range
        
        //Creating image views
        iv_created_count := 0
        for image, index in images
        {   
            image_view_desc.image = image
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

        //Making framebuffers slice
        framebuffers, fb_alloc_err := make([]Framebuffer, desc.image_count, allocator)
        if log.verbose_fail_error(fb_alloc_err != .None, "make framebuffers slice", location)
        {
            for i := 0; i < len(image_views); i += 1 do image_view_destroy(device, &image_views[i], location)
            delete(image_views, allocator)
            delete(images, allocator)
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }

        //Making framebuffer descriptor
        fb_desc: Framebuffer_Descriptor
        fb_desc.flags = desc.framebuffer_flags
        fb_desc.width = cast(i32)surface.capabilities.currentExtent.width
        fb_desc.height = cast(i32)surface.capabilities.currentExtent.height
        fb_desc.layers = desc.framebuffer_layers

        fb_created_count := 0
        for image_view, index in image_views
        {
            framebuffer, success := framebuffer_create_from_descriptor(device, render_pass, &fb_desc, {image_view}, allocator, location)
            if !success do break

            framebuffers[index] = framebuffer
            fb_created_count += 1
        }

        //Checking framebuffers creation fail
        if log.verbose_fail_error(fb_created_count != len(framebuffers), "create framebuffers", location)
        {
            for i := 0; i < fb_created_count; i += 1 do framebuffer_destroy(device, &framebuffers[i], location)
            delete(framebuffers, allocator)
            for i := 0; i < len(image_views); i += 1 do image_view_destroy(device, &image_views[i], location)
            delete(image_views, allocator)
            delete(images, allocator)
            vk.DestroySwapchainKHR(device.handle, handle, nil)
            return {}, false
        }

        //Making swapchain
        swapchain: Swapchain
        swapchain.allocator = allocator
        swapchain.image_count = desc.image_count
        swapchain.image_extent = surface.capabilities.currentExtent
        swapchain.image_format = desc.image_format
        swapchain.present_mode = desc.present_mode
        swapchain.images = images
        swapchain.image_views = image_views
        swapchain.framebuffers = framebuffers
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

        if swapchain.framebuffers != nil
        {
            for i := 0; i < len(swapchain.framebuffers); i += 1 do framebuffer_destroy(device, &swapchain.framebuffers[i], location)
            delete(swapchain.framebuffers, allocator)
            swapchain.framebuffers = nil
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