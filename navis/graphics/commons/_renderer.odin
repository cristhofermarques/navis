package graphics_commons

GPU_Type :: enum
{
    Integrated,
    Dedicated,
}

Renderer_Descriptor :: struct
{
    gpu_type: GPU_Type,
}