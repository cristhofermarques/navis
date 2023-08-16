package ecs

import "core:intrinsics"
import "core:runtime"

name_of :: proc($T: typeid) -> string where intrinsics.type_is_named(T)
{
    info := type_info_of(T)
    named := info.variant.(runtime.Type_Info_Named)
    return named.name
}

can_continue :: #force_inline proc "contextless" (used: Chunk_Element_Used) -> bool
{
    return !used
}

can_break :: #force_inline proc "contextless" (updated, to_update: int) -> bool
{
    updated := updated
    updated += 1
    return updated == to_update
}