package vulkan

import "vk"

/*
Vulkan image view descriptor.
*/
Image_View_Descriptor :: struct
{
    flags: vk.ImageViewCreateFlags,
    image: vk.Image,
    view_type: vk.ImageViewType,
    format: vk.Format,
    components: vk.ComponentMapping,
    subresource_range: vk.ImageSubresourceRange,
}

/*
Vulkan image view.
*/
Image_View :: struct
{
    view_type: vk.ImageViewType,
    format: vk.Format,
    handle: vk.ImageView,
}

image_view_create :: proc{
    image_view_create_from_descriptor,
    image_view_create_multiple_from_descriptor,
}

/*
Checks if image view handle is valid.
*/
image_view_is_valid :: #force_inline proc(image_view: ^Image_View) -> bool
{
    return image_view != nil && image_view.handle != 0
}

/*
Converts a slice of vulkan image views to a slice of images view handle.
*/
image_view_slice_to_handles :: #force_inline proc(image_views: []Image_View, allocator := context.allocator, location := #caller_location) -> ([]vk.ImageView, bool) #optional_ok
{
    if image_views == nil do return nil, false
    
    image_views_len := len(image_views)
    if image_views_len < 1 do return nil, false
    
    handles, alloc_err := make([]vk.ImageView, image_views_len, allocator, location)
    if alloc_err != .None do return nil, false

    for image_view, index in image_views do handles[index] = image_view.handle
    return handles, true
}