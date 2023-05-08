package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

/*
Creates a framebuffer from a descriptor.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    framebuffer_create_from_descriptor :: proc(device: ^Device, render_pass: ^Render_Pass, desc: ^Framebuffer_Descriptor, image_views: []Image_View, allocator := context.allocator, location := #caller_location) -> (Framebuffer, bool) #optional_ok
    {
        //Checking invalid parameters
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(!render_pass_is_valid(render_pass), "invalid vulkan render pass parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid framebuffer descriptor parameter", location) do return {}, false
        if log.verbose_fail_error(image_views == nil, "invalid image views parameter", location) do return {}, false
        
        //Cloning image view handles
        iv_handles, iv_handles_succ := image_view_slice_to_handles(image_views, context.temp_allocator, location)
        if log.verbose_fail_error(!iv_handles_succ, "clone image views handles", location) do return {}, false
        defer delete(iv_handles, context.temp_allocator)

        //Making create info
        info: vk.FramebufferCreateInfo
        info.sType = .FRAMEBUFFER_CREATE_INFO
        info.flags = desc.flags
        info.renderPass = render_pass.handle
        info.pAttachments = commons.array_try_as_pointer(iv_handles)
        info.attachmentCount = cast(u32)commons.array_try_len(iv_handles)
        info.width = cast(u32)desc.width
        info.height = cast(u32)desc.height
        info.layers = cast(u32)desc.layers

        //Creating framebuffer
        handle: vk.Framebuffer
        result := vk.CreateFramebuffer(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan framebuffer", location) do return {}, false

        //Cloning infos
        framebuffer_image_views, clone_success := commons.slice_clone(image_views, allocator)
        if log.verbose_fail_error(!clone_success, "clone image views slice", location)
        {
            vk.DestroyFramebuffer(device.handle, handle, nil)
            return {}, false
        }

        //Making framebuffer
        framebuffer: Framebuffer
        framebuffer.allocator = allocator
        framebuffer.handle = handle
        framebuffer.image_views = framebuffer_image_views
        framebuffer.width = desc.width
        framebuffer.height = desc.height
        framebuffer.layers = desc.layers
        return framebuffer, true
    }

/*
Destroys a framebuffer.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    framebuffer_destroy :: proc(device: ^Device, framebuffer: ^Framebuffer, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!framebuffer_is_valid(framebuffer), "invalid vulkan framebuffer parameter", location) do return false

        allocator := framebuffer.allocator

        vk.DestroyFramebuffer(device.handle, framebuffer.handle, nil)
        framebuffer.handle = 0

        if framebuffer.image_views != nil
        {
            delete(framebuffer.image_views, allocator)
            framebuffer.image_views = nil
        }

        return true
    }
}