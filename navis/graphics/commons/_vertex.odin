package graphics_commons

import "navis:commons"
import "core:runtime"

Vertex_Attribute :: enum
{
    Vector2_F32 = size_of(commons.Vector2_F32),
    Vector3_F32 = size_of(commons.Vector3_F32),
    Vector4_F32 = size_of(commons.Vector4_F32),
}

vertex_attribute_get_size :: #force_inline proc(attribute: Vertex_Attribute) -> uint
{
    return cast(uint)attribute
}

Vertex_Binding_Rate :: enum
{
    Vertex,
    Instance,
}

Vertex_Binding :: struct
{
    rate: Vertex_Binding_Rate,
    attributes: []Vertex_Attribute,
}