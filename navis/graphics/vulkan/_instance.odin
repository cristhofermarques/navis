package vulkan

import "vk"
import "navis:commons"
import "core:runtime"

/*
Vulkan instance descriptor.
*/
Instance_Descriptor :: struct
{
    app_name: cstring,
    app_version: u32,
    api_version: u32,
    extensions: []cstring,
    layers: []cstring,
}

/*
Vulkan instance.
*/
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

/*
Creates a vulkan instance.
*/
instance_create :: proc{
    instance_create_from_descriptor,
    instance_create_from_parameters,
}

/*
Check if instance is valid.
*/
instance_is_valid :: #force_inline proc(instance: ^Instance) -> bool
{
    return instance != nil && handle_is_valid(instance.handle)
}

/*
Check if instance have provided extension enabled.
*/
instance_is_extension_enabled :: #force_inline proc(instance: ^Instance, extension: cstring) -> bool
{
    if !instance_is_valid(instance) do return false
    return commons.array_contains(instance.enabled_extensions, extension)
}

/*
Check if instance have provided layer enabled.
*/
instance_is_layer_enabled :: #force_inline proc(instance: ^Instance, layer: cstring) -> bool
{
    if !instance_is_valid(instance) do return false
    return commons.array_contains(instance.enabled_layers, layer)
}