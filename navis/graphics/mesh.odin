package graphics

import "navis:api"

when api.IMPLEMENTATION
{
    import "bgfx"

    mesh_create_from_descriptor :: proc(descriptor: ^Mesh_Descriptor) -> (Mesh, bool) #optional_ok
    {
        if descriptor == nil do return {}, false
        
        vertex_handle := bgfx.create_vertex_buffer(descriptor.vertex.memory, descriptor.layout, descriptor.vertex.flags)
        if vertex_handle == max(u16) do return {}, false
        
        index_handle := bgfx.create_index_buffer(descriptor.index.memory, descriptor.index.flags)
        if index_handle == max(u16) do return {}, false
        
        mesh: Mesh
        mesh.vertex_buffer = vertex_handle
        mesh.index_buffer = index_handle
        return mesh, true
    }

    mesh_create :: proc{
        mesh_create_from_descriptor,
    }

    mesh_destroy :: proc(mesh: ^Mesh)
    {
        if mesh == nil do return
        
        bgfx.destroy_vertex_buffer(mesh.vertex_buffer)
        mesh.vertex_buffer = max(u16)
        
        bgfx.destroy_index_buffer(mesh.index_buffer)
        mesh.index_buffer = max(u16)
    }
}