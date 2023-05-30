package vulkan

import "navis:api"

when api.EXPORT
{
    // mesh_pack_create_from_descriptor :: proc(descriptor: ^Mesh_Pack_Descriptor) -> (Mesh_Pack, bool) #optional_ok
    // {
    //     meshes_len := len(descriptor.meshes)

    //     buffer_pack_elements, buff_pack_elem_alloc_err := make([]Buffer_Pack_Element_Descriptor, meshes_len, context.temp_allocator)
    //     defer delete(buffer_pack_elements, context.temp_allocator)
    //     for bpe, bpe_i in buffer_pack_elements
    //     {
    //         mesh := &descriptor.meshes[i]

    //     } 

    //     buffer_pack_descriptor: Buffer_Pack_Descriptor
    //     buffer_pack_descriptor.elements = buffer_pack_elements
    // }
}