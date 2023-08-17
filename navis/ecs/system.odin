package ecs

import "core:intrinsics"

System_Scope :: enum
{
    Chunk,
    Collection,
}

System_Stage :: enum
{
    Logic,
    Physics,
}

MAX_SYSTEM_BUNDLE_PRIORITIES :: 3
NAVIS_SYSTEM_PRIORITY :: MAX_SYSTEM_BUNDLE_PRIORITIES

System_Bundle :: struct($T: typeid)
{
    systems: [MAX_SYSTEM_BUNDLE_PRIORITIES + 1][dynamic]T,
}

system_bundle_init :: proc(bundle: ^System_Bundle($T), initial_reserve := 32, allocator := context.allocator) -> bool
{
    assert(bundle != nil, "nil system bundle parameter")

    created := 0
    for &system in bundle.systems
    {
        s, s_ae := make_dynamic_array_len_cap([dynamic]T, 0, initial_reserve, allocator)
        if s_ae != .None do break
        created += 1
        system = s
    }

    if created != len(bundle.systems)
    {
        for &system in bundle.systems[0:created] do delete(system)
        return false
    }
    return true
}

system_bundle_destroy :: proc(bundle: ^System_Bundle($T)) -> bool
{
    assert(bundle != nil, "nil system bundle parameter")
    for &system in bundle.systems do delete(system)
    bundle^ = {}
    return true
}

system_bundle_contains :: proc "contextless" (bundle: ^System_Bundle($T), system: T) -> bool
{
    if bundle == nil || system == nil do return false
    for bundle_systems in bundle.systems
    {
        for bundle_system in bundle_systems do if rawptr(bundle_system) == rawptr(system) do return true
    }
    return false
}

system_bundle_append :: proc(bundle: ^System_Bundle($T), system: T, $Priority: int) -> bool
where
Priority < MAX_SYSTEM_BUNDLE_PRIORITIES
{
    assert(bundle != nil, "nil system bundle parameter")
    assert(system != nil, "nil system bundle parameter")
    append_elem(&bundle.systems[Priority], system)
    return true
}