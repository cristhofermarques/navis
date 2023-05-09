package vulkan

import "navis:graphics/ui"

Target_Descriptor :: struct
{
    window: ^ui.Window,
    render_pass: Render_Pass_Descriptor,
    swapchain: Swapchain_Descriptor,
}

Target :: struct
{
    surface: Surface,
    render_pass: Render_Pass,
    swapchain: Swapchain,
}

target_create :: proc{
    target_create_from_descriptor,
}