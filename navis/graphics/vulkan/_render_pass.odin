package vulkan

import "vk"

/*
Vulkan render pass descriptor.
*/
Render_Pass_Descriptor :: struct
{
    flags: vk.RenderPassCreateFlags,
    attachments: []vk.AttachmentDescription,
    subpasses: []vk.SubpassDescription,
    dependencies: []vk.SubpassDependency,
}

/*
Vulkan render pass.
*/
Render_Pass :: struct
{
    handle: vk.RenderPass,
}

render_pass_create :: proc{
    render_pass_create_from_descriptor,
}

/*
Checks if renderpass handle is valid.
*/
render_pass_is_valid :: #force_inline proc(render_pass: ^Render_Pass) -> bool
{
    return render_pass != nil && render_pass.handle != 0
}