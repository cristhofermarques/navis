package graphics

import "bgfx"

Shader_Module :: bgfx.Shader_Handle

Shader_Descriptor :: struct
{
    vertex, fragment: struct
    {
        data: rawptr,
        size: u32,
    },
}

Shader :: struct
{
    uniforms: []bgfx.Uniform_Handle,
    program: bgfx.Program_Handle,
}

shader_create :: proc{
    shader_create_from_descriptor,
}