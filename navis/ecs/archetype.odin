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
    collection_logic_systems, collection_physics_systems: [dynamic]Proc_Collection_System,
    chunk_logic_systems, chunk_physics_systems: [dynamic]Proc_Chunk_System,
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

    collection_logic_systems, collection_logic_systems_allocation_error := make_dynamic_array_len_cap([dynamic]Proc_Collection_System, 0, INITIAL_SYSTEMS_CAPACITY, allocator)
    if collection_logic_systems_allocation_error != .None do return false

    collection_physics_systems, collection_physics_systems_allocation_error := make_dynamic_array_len_cap([dynamic]Proc_Collection_System, 0, INITIAL_SYSTEMS_CAPACITY, allocator)
    if collection_physics_systems_allocation_error != .None
    {
        delete(collection_logic_systems)
        return false
    }

    chunk_logic_systems, chunk_logic_systems_allocation_error := make_dynamic_array_len_cap([dynamic]Proc_Chunk_System, 0, INITIAL_SYSTEMS_CAPACITY, allocator)
    if chunk_logic_systems_allocation_error != .None
    {
        delete(collection_logic_systems)
        delete(collection_physics_systems)
        return false
    }

    chunk_physics_systems, chunk_physics_systems_allocation_error := make_dynamic_array_len_cap([dynamic]Proc_Chunk_System, 0, INITIAL_SYSTEMS_CAPACITY, allocator)
    if chunk_physics_systems_allocation_error != .None
    {
        delete(collection_logic_systems)
        delete(collection_physics_systems)
        delete(chunk_logic_systems)
        return false
    }

    archetype.collection_logic_systems = collection_logic_systems
    archetype.collection_physics_systems = collection_physics_systems
    archetype.chunk_logic_systems = chunk_logic_systems
    archetype.chunk_physics_systems = chunk_physics_systems

    did_init_collection := raw_collection_init(&archetype.collection, 2, allocator)
    if !did_init_collection
    {
        delete(collection_logic_systems)
        delete(chunk_logic_systems)
    }

    return did_init_collection
}

archetype_destroy :: proc(archetype: ^Archetype) -> bool
{
    if archetype == nil do return false
    delete(archetype.collection_logic_systems)
    delete(archetype.collection_physics_systems)
    delete(archetype.chunk_logic_systems)
    delete(archetype.chunk_physics_systems)
    if !raw_collection_destroy(&archetype.collection) do return false
    archetype^ = {}
    return true
}

@(private)
archetype_logic_update :: proc(archetype: ^Archetype)
{
    if archetype.collection_logic_systems != nil
    {
        for &system in archetype.collection_logic_systems do system(&archetype.collection)
    }

    if archetype.chunk_logic_systems == nil do return
    updated_count, to_update_count := 0, archetype.collection.sub_allocations
    for &chunk in archetype.collection.chunks.content
    {
        if chunk.sub_allocations == 0 do continue

        for &system in archetype.chunk_logic_systems do system(&chunk)

        updated_count += chunk.sub_allocations
        if updated_count == to_update_count do continue
    }
}