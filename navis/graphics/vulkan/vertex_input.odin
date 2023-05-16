package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:graphics/commons"
    import navis_commons "navis:commons"

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
    vertex_input_compose_state :: proc(desc: ^Vertex_Descriptor, allocator := context.allocator) -> (vk.PipelineVertexInputStateCreateInfo, []vk.VertexInputBindingDescription, []vk.VertexInputAttributeDescription, bool)
    {
        //Allocating vulkan bindings slice.
        bindings_len := len(desc.bindings)
        if bindings_len < 1
        {
            return {}, nil, nil, false
        }
        
        //Allocating vulkan bindings slice.
        bindings, bind_alloc_err := make([]vk.VertexInputBindingDescription, bindings_len, allocator)
        if bind_alloc_err != .None
        {
            return {}, nil, nil, false
        }
        
        //Allocating vulkan dynamic attributes slice.
        dyn_attributes, dyn_attr_alloc_err := make([dynamic]vk.VertexInputAttributeDescription, 0, bindings_len, context.temp_allocator)
        if dyn_attr_alloc_err != .None
        {
            delete(bindings, allocator)
            return {}, nil, nil, false
        }
        defer delete(dyn_attributes)

        //Creating bidings and attributes
        location: u32
        for i := 0; i < bindings_len; i += 1
        {
            binding := &desc.bindings[i]
            vk_binding := &bindings[i]

            //Applying binding location offset
            location += binding.location_offset

            offset: u32
            for attribute, attribute_index in binding.binding.attributes
            {
                //Getting attribute info
                attribute_size := commons.vertex_attribute_get_size(attribute)
                attribute_format := vertex_attribute_to_format(attribute)
                attribute_location_offset := vertex_attribute_get_location_offset(attribute)

                //Making vulkan attribute
                vk_attribute: vk.VertexInputAttributeDescription
                vk_attribute.binding = u32(i)
                vk_attribute.location = u32(location)
                vk_attribute.format = attribute_format
                vk_attribute.offset = offset

                //Adding vulkan attribute
                append(&dyn_attributes, vk_attribute)

                //Applying attribute location offset 
                location += attribute_location_offset

                //Applying attribute size offset 
                offset += u32(attribute_size)
            }

            //Composing vulkan binding
            vk_binding.binding = u32(i)
            vk_binding.inputRate = vertex_input_rate_from_vertex_binding_rate(binding.binding.rate)
            vk_binding.stride = offset //Offset at the end is equivalent to binding size/stride.
        }

        //Cloning dynamic attributes to new slice
        attributes, attr_succ := navis_commons.slice_from_dynamic(dyn_attributes, allocator)
        if !attr_succ
        {
            delete(bindings, allocator)
            return {}, nil, nil, false
        }

        //Making create info
        info: vk.PipelineVertexInputStateCreateInfo
        info.sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO
        info.pVertexBindingDescriptions = navis_commons.array_try_as_pointer(bindings)
        info.vertexBindingDescriptionCount = cast(u32)navis_commons.array_try_len(bindings)
        info.pVertexAttributeDescriptions = navis_commons.array_try_as_pointer(attributes)
        info.vertexAttributeDescriptionCount = cast(u32)navis_commons.array_try_len(attributes)
        return info, bindings, attributes, true
    }
}