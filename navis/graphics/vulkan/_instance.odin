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
Checks if vulkan instance descriptor is valid.
*/
instance_descriptor_is_valid :: proc "contextless" (descriptor: ^Instance_Descriptor) -> bool
{
    if descriptor == nil do return false
    if descriptor.api_version <= vk.API_VERSION_1_0 do return false
    return true
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
Creates a new vulkan instance.
*/
instance_create :: proc{
    instance_create_from_descriptor,
}

/*
Check if instance is valid.
*/
instance_is_valid :: #force_inline proc "contextless" (instance: ^Instance) -> bool
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