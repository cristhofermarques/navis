package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

    @(export=api.SHARED, link_prefix=PREFIX)
    render_pass_create_from_descriptor :: proc(device: ^Device, desc: ^Render_Pass_Descriptor, location := #caller_location) -> (Render_Pass, bool) #optional_ok
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return {}, false
        if log.verbose_fail_error(desc == nil, "invalid render pass descriptor parameter", location) do return {}, false
        
        info: vk.RenderPassCreateInfo
        info.sType = .RENDER_PASS_CREATE_INFO
        info.flags = desc.flags
        info.pAttachments = commons.array_try_as_pointer(desc.attachments)
        info.attachmentCount = cast(u32)commons.array_try_len(desc.attachments)
        info.pSubpasses = commons.array_try_as_pointer(desc.subpasses)
        info.subpassCount = cast(u32)commons.array_try_len(desc.subpasses)
        info.pDependencies = commons.array_try_as_pointer(desc.dependencies)
        info.dependencyCount = cast(u32)commons.array_try_len(desc.dependencies)

        handle: vk.RenderPass
        result := vk.CreateRenderPass(device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan render pass", location) do return {}, false
        
        render_pass: Render_Pass
        render_pass.handle = handle
        return render_pass, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    render_pass_destroy :: proc(device: ^Device, render_pass: ^Render_Pass, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!device_is_valid(device), "invalid vulkan device parameter", location) do return false
        if log.verbose_fail_error(!render_pass_is_valid(render_pass), "invalid render pass parameter", location) do return false

        vk.DestroyRenderPass(device.handle, render_pass.handle, nil)
        render_pass.handle = 0

        return true
    }
}