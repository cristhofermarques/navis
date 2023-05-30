package vulkan

/*
Vulkan mesh descriptor.
*/
Mesh_Descriptor :: struct
{
    vertices, indices: Buffer_Descriptor,
}

/*
Vulkan mesh.
*/
Mesh :: struct
{
    vertices, indices: Buffer,
}

/*
Vulkan mesh pack descriptor.
*/
Mesh_Pack_Descriptor :: struct
{
    meshes: []Mesh_Descriptor,
}

/*
Vulkan mesh pack.
*/
Mesh_Pack :: struct
{
    meshes: []Mesh,
}