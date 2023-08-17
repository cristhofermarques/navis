package ecs

import "core:runtime"
import "core:intrinsics"

ARCHETYPE_ENTITY_ID_FIELD_NAME :: "__entity_id"

Archetype_Descriptor :: struct($T: typeid)
where
intrinsics.type_is_named(T) && 
intrinsics.type_has_field(T, ARCHETYPE_ENTITY_ID_FIELD_NAME) &&
intrinsics.type_field_type(T, ARCHETYPE_ENTITY_ID_FIELD_NAME) == Entity_ID &&
intrinsics.type_has_field(T, CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_USED_FIELD_NAME) == Chunk_Element_Used &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    chunk_capacity: int,
    chunk_init: proc(^Chunk(T), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Chunk(T), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Chunk(T)) -> int,
    chunk_free: proc "contextless" (^Chunk(T), int) -> bool,
}

Archetype :: struct
{
    name: string,
    collection: Raw_Collection,
    collection_logic_systems, collection_physics_systems: System_Bundle(Proc_Collection_System),
    chunk_logic_systems, chunk_physics_systems: System_Bundle(Proc_Chunk_System),
}

archetype_make :: proc(descriptor:  Archetype_Descriptor($T)) -> Archetype
{
    archetype: Archetype
    archetype.name = name_of(T)
    archetype.collection = raw_collection_make(transmute(Collection_Descriptor(T))descriptor)
    return archetype
}

archetype_init :: proc(archetype: ^Archetype, allocator := context.allocator) -> bool
{
    if archetype == nil do return false

    INITIAL_SYSTEMS_CAPACITY :: 32

    if !system_bundle_init(&archetype.collection_logic_systems, INITIAL_SYSTEMS_CAPACITY, allocator) do return false

    if !system_bundle_init(&archetype.collection_physics_systems, INITIAL_SYSTEMS_CAPACITY, allocator)
    {
        system_bundle_destroy(&archetype.collection_logic_systems)
        return false
    }

    if !system_bundle_init(&archetype.chunk_logic_systems, INITIAL_SYSTEMS_CAPACITY, allocator)
    {
        system_bundle_destroy(&archetype.collection_logic_systems)
        system_bundle_destroy(&archetype.collection_physics_systems)
        return false
    }

    if !system_bundle_init(&archetype.chunk_physics_systems, INITIAL_SYSTEMS_CAPACITY, allocator)
    {
        system_bundle_destroy(&archetype.collection_logic_systems)
        system_bundle_destroy(&archetype.collection_physics_systems)
        system_bundle_destroy(&archetype.chunk_logic_systems)
        return false
    }

    did_init_collection := raw_collection_init(&archetype.collection, 2, allocator)
    if !did_init_collection
    {
        system_bundle_destroy(&archetype.collection_logic_systems)
        system_bundle_destroy(&archetype.collection_physics_systems)
        system_bundle_destroy(&archetype.chunk_logic_systems)
        system_bundle_destroy(&archetype.chunk_physics_systems)
    }

    return did_init_collection
}

archetype_destroy :: proc(archetype: ^Archetype) -> bool
{
    if archetype == nil do return false
    system_bundle_destroy(&archetype.collection_logic_systems)
    system_bundle_destroy(&archetype.collection_physics_systems)
    system_bundle_destroy(&archetype.chunk_logic_systems)
    system_bundle_destroy(&archetype.chunk_physics_systems)
    if !raw_collection_destroy(&archetype.collection) do return false
    archetype^ = {}
    return true
}

archetype_contains_system :: proc "contextless" (archetype: ^Archetype, system: rawptr) -> bool
{
    if archetype == nil || system == nil do return false
    if system_bundle_contains(&archetype.collection_logic_systems, auto_cast system) do return true
    if system_bundle_contains(&archetype.collection_physics_systems, auto_cast system) do return true
    if system_bundle_contains(&archetype.chunk_logic_systems, auto_cast system) do return true
    if system_bundle_contains(&archetype.chunk_physics_systems, auto_cast system) do return true
    return false
}

@(private)
archetype_register_system :: proc(archetype: ^Archetype, system: rawptr, scope := System_Scope.Chunk, stage := System_Stage.Logic, $Priority: int) -> bool
{
    if archetype_contains_system(archetype, system) do return false
    switch scope
    {
        case .Chunk:
            switch stage
            {
                case .Logic: return system_bundle_append(&archetype.chunk_logic_systems, auto_cast system, Priority)
                case .Physics: return system_bundle_append(&archetype.chunk_physics_systems, auto_cast system, Priority)
            }
            
        case .Collection:
            switch stage
            {
                case .Logic: return system_bundle_append(&archetype.collection_logic_systems, auto_cast system, Priority)
                case .Physics: return system_bundle_append(&archetype.collection_physics_systems, auto_cast system, Priority)
            }
    }
    return false
}

// @(private)
// archetype_logic_update :: proc(archetype: ^Archetype)
// {
//     if archetype.collection_logic_systems != nil
//     {
//         for &system in archetype.collection_logic_systems do system(&archetype.collection)
//     }

//     if archetype.chunk_logic_systems == nil do return
//     updated_count, to_update_count := 0, archetype.collection.sub_allocations
//     for &chunk in archetype.collection.chunks.content
//     {
//         if chunk.sub_allocations == 0 do continue

//         for &system in archetype.chunk_logic_systems do system(&chunk)

//         updated_count += chunk.sub_allocations
//         if updated_count == to_update_count do continue
//     }
// }