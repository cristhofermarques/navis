package vulkan

import "vk"
import graphics_commons "navis:graphics/commons"

/*
Vulkan renderer
*/
Renderer_Info :: struct
{
    application_name: cstring,
    application_version: u32,
}

/*
Vulkan renderer
*/
Renderer :: struct
{
    context_: Context,
    target: Target,
}

renderer_create :: proc{
    renderer_create_from_descriptor,
}

physical_device_type_from_gpu_type :: proc "contextless" (gpu_type: graphics_commons.GPU_Type) -> vk.PhysicalDeviceType
{
    switch gpu_type
    {
        case .Integrated: return .INTEGRATED_GPU
        case .Dedicated: return .DISCRETE_GPU
    }

    //Default
    return .DISCRETE_GPU
}
