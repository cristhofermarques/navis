package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    image_view_create_from_descriptor :: proc(device: ^Device, desc: ^Image_View_Descriptor, location := #caller_location) -> (Image_View, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid image view descriptor parameter", location) do return {}, false
        
        info: vk.ImageViewCreateInfo
        info.sType = .IMAGE_VIEW_CREATE_INFO
        info.flags = desc.flags
        info.image = desc.image
        info.viewType = desc.view_type
        info.format = desc.format
        info.components = desc.components
        info.subresourceRange = desc.subresource_range
        
        handle: vk.ImageView
        result := vk.CreateImageView(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan image view", location) do return {}, false

        image_view: Image_View
        image_view.view_type = desc.view_type
        image_view.format = desc.format
        image_view.handle = handle
        return image_view, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    image_view_create_multiple_from_descriptor :: proc(device: ^Device, desc: ^Image_View_Descriptor, images: []vk.Image, allocator := context.allocator, location := #caller_location) -> ([]Image_View, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return nil, false
        if log.verbose_fail_error(desc == nil, "invalid image view descriptor parameter", location) do return nil, false
        if log.verbose_fail_error(images == nil, "invalid images parameter", location) do return nil, false
        
        //Validating images slice
        images_len := len(images)
        if log.verbose_fail_error(images_len < 1, "invalid images length", location) do return nil, false
        
        //Making image views slice
        image_views, images_views_alloc_err := make([]Image_View, images_len, allocator, location)
        if log.verbose_fail_error(images_views_alloc_err != .None, "make image views slice", location) do return nil, false

        //Creating image views
        image_view_created_count := 0
        for image, index in images
        {
            desc.image = image

            image_view, success := image_view_create_from_descriptor(device, desc, location)
            if !success do break

            image_views[index] = image_view
            image_view_created_count += 1
        }

        //Checking creation fail
        if log.verbose_fail_error(image_view_created_count != images_len, "create image views slice", location)
        {
            for i := 0; i < image_view_created_count; i += 1 do image_view_destroy(device, &image_views[i], location) //Destroy created image views
            delete(image_views, allocator)
            return nil, false
        }

        return image_views, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    image_view_destroy :: proc(device: ^Device, image_view: ^Image_View, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!image_view_is_valid(image_view), "invalid vulkan image view parameter", location) do return false

        vk.DestroyImageView(device.handle, image_view.handle, nil)
        image_view.handle = 0

        return true
    }
}