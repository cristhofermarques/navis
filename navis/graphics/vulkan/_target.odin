package vulkan

import "navis:graphics/ui"

Target_Descriptor :: struct
{
    window: ^ui.Window,
    swapchain: Swapchain_Descriptor	,
}

Target :: struct
{
    surface: Surface,
    swapchain: Swapchain,
}

target_create :: proc{
    target_create_from_descriptor,
}