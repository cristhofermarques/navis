package vulkan

import "vk"
import "navis:commons"
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

/*
Check if instance is valid.
*/
instance_is_valid :: #force_inline proc(instance: ^Instance) -> bool
{
    return instance != nil && instance.handle != nil
}

/*
Check if instance have provided extension enabled.
*/
instance_is_extension_enabled :: #force_inline proc(instance: ^Instance, extension: cstring) -> bool
{
    return instance != nil && commons.array_contains(instance.enabled_extensions, extension)
}

/*
Check if instance have provided layer enabled.
*/
instance_is_layer_enabled :: #force_inline proc(instance: ^Instance, layer: cstring) -> bool
{
    return instance != nil && commons.array_contains(instance.enabled_layers, layer)
}