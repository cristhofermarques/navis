package vulkan

import "vk"
import "navis:commons"

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

/*
Vulkan render pass begin descriptor.
*/
Render_Pass_Begin_Descriptor :: struct
{
    render_area: vk.Rect2D,
    clear_values: []vk.ClearValue,
    contents: vk.SubpassContents,
}

/*
Begin a renderpass.
*/
render_pass_begin_from_descriptor :: #force_inline proc(render_pass: ^Render_Pass, command_buffer: Command_Buffer, framebuffer: ^Framebuffer, desc: ^Render_Pass_Begin_Descriptor)
{
    //TODO: parameters checking

    info: vk.RenderPassBeginInfo
    info.sType = .RENDER_PASS_BEGIN_INFO
    info.renderPass = render_pass.handle
    info.framebuffer = framebuffer.handle
    info.renderArea = desc.render_area
    info.pClearValues = commons.array_try_as_pointer(desc.clear_values)
    info.clearValueCount = cast(u32)commons.array_try_len(desc.clear_values)

    vk.CmdBeginRenderPass(command_buffer, &info, desc.contents)
}