package vulkan

import "vk"
import "navis:graphics/commons"

Vertex_Input_Binding_Descriptor :: struct
{
    binding: commons.Vertex_Binding,
    start_location: i32,
}

Vertex_Input_Descriptor :: struct
{
    bindings: []Vertex_Input_Binding_Descriptor,
}

vertex_attribute_get_location_offset :: #force_inline proc(attribute: commons.Vertex_Attribute) -> uint
{
    switch attribute
    {
        case .Vector2_F32: return 1        
        case .Vector3_F32: return 1        
        case .Vector4_F32: return 1        
    }

    return 0
}

vertex_attribute_to_format :: #force_inline proc(attribute: commons.Vertex_Attribute) -> vk.Format
{
    switch attribute
    {
        case .Vector2_F32: return .R32G32_SFLOAT
        case .Vector3_F32: return .R32G32B32_SFLOAT
        case .Vector4_F32: return .R32G32B32A32_SFLOAT
    }

    return .UNDEFINED
}