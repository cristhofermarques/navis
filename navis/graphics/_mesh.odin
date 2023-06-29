package graphics

import "bgfx"

Mesh_Buffer_Descriptor :: struct
{
    memory: ^bgfx.Memory,
    flags: bgfx.Create_Buffer_Flags,
}

Mesh_Descriptor :: struct
{
    vertex, index: Mesh_Buffer_Descriptor,
    layout: ^bgfx.Vertex_Layout,
}

Mesh :: struct
{
    vertex_buffer: bgfx.Vertex_Buffer_Handle,
    index_buffer: bgfx.Index_Buffer_Handle,
}