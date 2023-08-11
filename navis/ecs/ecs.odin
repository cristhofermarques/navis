package ecs

import "core:runtime"
import "core:intrinsics"

Proc_Collection_System :: #type proc(^Raw_Collection)
Proc_Chunk_System :: #type proc(^Raw_Chunk)

ECS :: struct
{
    allocator: runtime.Allocator,
    entities: Collection(Entity),
    archetypes: map[string]Archetype,
}

init :: proc(ecs: ^ECS, entities_chunk_capacity: int, allocator := context.allocator) -> bool
{
    if ecs == nil || entities_chunk_capacity < 1 do return false

    descriptor: Collection_Descriptor(Entity)
    descriptor.chunk_capacity = entities_chunk_capacity
    descriptor.chunk_init = entity_chunk_init
    descriptor.chunk_destroy = entity_chunk_destroy
    descriptor.chunk_sub_allocate = entity_chunk_sub_allocate
    descriptor.chunk_free = entity_chunk_free
    entities := raw_collection_make(descriptor)
    created_entities := raw_collection_init(&entities)
    if !created_entities do return false
    ecs.entities = transmute(Collection(Entity))entities

    archetypes, archetypes_allocation_error := make_map(map[string]Archetype, 2, allocator)
    if archetypes_allocation_error != .None
    {
        raw_collection_destroy(collection_as_raw(&ecs.entities))
        return false
    }

    ecs.allocator = allocator
    ecs.archetypes = archetypes
    return true
}

destroy :: proc(ecs: ^ECS) -> bool
{
    if ecs == nil do return false
    raw_collection_destroy(collection_as_raw(&ecs.entities))
    for k, &a in ecs.archetypes do archetype_destroy(&a)
    delete_map(ecs.archetypes)
    ecs^ = {}
    return true
}

contains_archetype :: proc(ecs: ^ECS, $T: typeid) -> bool
where
intrinsics.type_is_named(T) && 
intrinsics.type_has_field(T, CHUNK_ELEMENT_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_FIELD_NAME) == Chunk_Element &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    if ecs == nil do return false
    name := name_of(T)
    archetype := ecs.archetypes[name]
    return archetype.name == name
}

Archetype :: struct
{
    name: string,
    collection: Raw_Collection,
    collection_logic_systems, collection_physics_systems: [dynamic]Proc_Collection_System,
    chunk_logic_systems, chunk_physics_systems: [dynamic]Proc_Chunk_System,
}

archetype_make :: proc(descriptor: Collection_Descriptor($T)) -> Archetype
{
    archetype: Archetype
    archetype.name = name_of(T)
    archetype.collection = raw_collection_make(descriptor)
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
    for &chunk in archetype.collection.chunks
    {
        if chunk.sub_allocations == 0 do continue

        for &system in archetype.chunk_logic_systems do system(&chunk)

        updated_count += chunk.sub_allocations
        if updated_count == to_update_count do continue
    }
}

register_archetype :: proc(ecs: ^ECS, descriptor: Collection_Descriptor($T)) -> bool
{
    if ecs == nil || contains_archetype(ecs, T) do return false
    archetype := archetype_make(descriptor)
    if !archetype_init(&archetype, ecs.allocator) do return false
    ecs.archetypes[name_of(T)] = archetype
    return true
}

logic_update :: proc(ecs: ^ECS)
{
    for name, &archetype in ecs.archetypes do archetype_logic_update(&archetype)
}

contains_collection_logic_system :: proc(ecs: ^ECS, system: proc(^Collection($T))) -> bool
{
    if ecs == nil || system == nil || !contains_archetype(ecs, T) do return false
    archetype := &ecs.archetypes[name_of(T)]
    for &collection_system in archetype.collection_logic_systems
    {
        if collection_system == transmute(Proc_Collection_System)system do return true
    }

    return false
}

register_collection_logic_system :: proc(ecs: ^ECS, system: proc(^Collection($T))) -> bool
{
    if ecs == nil || system == nil || !contains_archetype(ecs, T) || contains_collection_logic_system(ecs, system) do return false
    archetype := &ecs.archetypes[name_of(T)]
    append_count := append_elem(&archetype.collection_logic_systems, transmute(Proc_Collection_System)system)
    if append_count < 1 do return false
    return true
}