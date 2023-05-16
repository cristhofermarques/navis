package vulkan

import "vk"
import "navis:graphics/commons"

Vertex_Binding_Descriptor :: struct
{
    location_offset: u32,
    binding: commons.Vertex_Binding,
}

Vertex_Descriptor :: struct
{
    bindings: []Vertex_Binding_Descriptor,
}

vertex_attribute_get_location_offset :: #force_inline proc(attribute: commons.Vertex_Attribute) -> u32
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