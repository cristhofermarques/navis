package vulkan

import "vk"
import "core:runtime"

Instance_Descriptor :: struct
{
    app_name: cstring,
    app_version: u32,
    api_version: u32,
    extensions: []cstring,
    layers: []cstring,
}

Instance :: struct
{
    __allocator: runtime.Allocator,
    app_name: cstring,
    app_version: u32,
    engine_name: cstring,
    engine_version: u32,
    enabled_extensions: []cstring,
    enabled_layers: []cstring,
    handle: vk.Instance,
}

instance_create :: proc{
    instance_create_from_descriptor,
    instance_create_from_parameters,
}