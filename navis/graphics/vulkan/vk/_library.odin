package vk

import "core:dynlib"

Library :: dynlib.Library

/*
Checks if vulkan library is valid.
*/
library_is_valid :: #force_inline proc(library: Library) -> bool
{
    return library != nil
}