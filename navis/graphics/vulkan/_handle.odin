package vulkan

import "vk"
import "core:intrinsics"

/*
Check if a vulkan handle is valid.
*/
handle_is_valid :: #force_inline proc "contextless" (handle: $T) -> bool
{
    when intrinsics.type_is_specialization_of(T, vk.Handle) do return handle != nil
    when intrinsics.type_is_specialization_of(T, vk.NonDispatchableHandle) do return handle != 0
    return false
}