package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:graphics/commons"
    import "core:fmt"

    vertex_input_rate_from_vertex_binding_rate :: proc(rate: commons.Vertex_Binding_Rate) -> vk.VertexInputRate
    {
        switch rate
        {
            case .Vertex: return .VERTEX
            case .Instance: return .INSTANCE
        }

        return .VERTEX
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    vertex_input_compose_stage :: proc(desc: ^Vertex_Input_Descriptor)
    {
        bindings_len := len(desc.bindings)

        bindings, bindings_alloc_err := make([]vk.VertexInputBindingDescription, bindings_len, context.temp_allocator)
        defer delete(bindings, context.temp_allocator)
        
        attributes, attributes_alloc_err := make([dynamic]vk.VertexInputAttributeDescription, 0, bindings_len, context.temp_allocator)
        defer delete(attributes)

        for i := 0; i < bindings_len; i += 1
        {
            p_binding := &desc.bindings[i]
            p_vk_biding := &bindings[i]

            location := cast(uint)p_binding.start_location
            offset: u32
            for attribute, attribute_index in p_binding.binding.attributes
            {
                attribute_size := commons.vertex_attribute_get_size(attribute)
                attribute_format := vertex_attribute_to_format(attribute)
                attribute_location_offset := vertex_attribute_get_location_offset(attribute)

                vk_attribute: vk.VertexInputAttributeDescription
                vk_attribute.binding = u32(i)
                vk_attribute.location = cast(u32)location
                vk_attribute.format = attribute_format
                vk_attribute.offset = offset
                append(&attributes, vk_attribute)

                location += attribute_location_offset
                offset += cast(u32)attribute_size
            }

            p_vk_biding.binding = u32(i)
            p_vk_biding.inputRate = vertex_input_rate_from_vertex_binding_rate(p_binding.binding.rate)
            p_vk_biding.stride = offset
        }

        fmt.println(bindings)
        fmt.println(attributes)
    }
}