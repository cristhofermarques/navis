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
intrinsics.type_has_field(T, ARCHETYPE_ENTITY_ID_FIELD_NAME) &&
intrinsics.type_field_type(T, ARCHETYPE_ENTITY_ID_FIELD_NAME) == Entity_ID &&
intrinsics.type_has_field(T, CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_USED_FIELD_NAME) == Chunk_Element_Used &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    if ecs == nil do return false
    name := name_of(T)
    archetype := ecs.archetypes[name]
    return archetype.name == name
}

register_archetype :: proc(ecs: ^ECS, descriptor: Archetype_Descriptor($T)) -> bool
{
    if ecs == nil || contains_archetype(ecs, T) do return false
    archetype := archetype_make(descriptor)
    if !archetype_init(&archetype, ecs.allocator) do return false
    ecs.archetypes[name_of(T)] = archetype
    return true
}

contains_system :: proc{
    contains_collection_system,
    contains_chunk_system,
}

contains_collection_system :: proc "contextless" (ecs: ^ECS, system: proc(^Collection($T))) -> bool
{
    if ecs == nil || system == nil || !contains_archetype(ecs, T) do return false
    archetype := &ecs.archetypes[name_of(T)]
    return archetype_contains_system(archetype, rawptr(system))
}

contains_chunk_system :: proc "contextless" (ecs: ^ECS, system: proc(^Chunk($T))) -> bool
{
    if ecs == nil || system == nil || !contains_archetype(ecs, T) do return false
    archetype := &ecs.archetypes[name_of(T)]
    return archetype_contains_system(archetype, rawptr(system))
}

register_collection_system :: proc(ecs: ^ECS, system: proc(^Collection($T)), $Priority: int, stage := System_Stage.Logic) -> bool
where
Priority < MAX_SYSTEM_BUNDLE_PRIORITIES
{
    if ecs == nil || system == nil || !contains_archetype(ecs, T) do return false
    archetype := &ecs.archetypes[name_of(T)]
    return archetype_register_system(archetype, rawptr(system), .Collection, stage, Priority)
}

register_chunk_system :: proc(ecs: ^ECS, system: proc(^Chunk($T)), $Priority: int, stage := System_Stage.Logic) -> bool
where
Priority < MAX_SYSTEM_BUNDLE_PRIORITIES
{
    if ecs == nil || system == nil || !contains_archetype(ecs, T) do return false
    archetype := &ecs.archetypes[name_of(T)]
    return archetype_register_system(archetype, rawptr(system), .Chunk, stage, Priority)
}

unregister_collection_system :: proc(ecs: ^ECS, system: proc(^Collection($T))) -> bool
{
    if ecs == nil || system == nil || !contains_archetype(ecs, T) do return false
    archetype := &ecs.archetypes[name_of(T)]
    return archetype_unregister_system(archetype, rawptr(system))
}

contains_entity_id :: proc "contextless" (ecs: ^ECS, id: Entity_ID) -> bool
{
    return ecs != nil && raw_collection_contains_id(transmute(^Raw_Collection)&ecs.entities, transmute(Raw_Collection_ID)id)
}

add_archetype :: proc(ecs: ^ECS, $T: typeid, entity_id: Entity_ID) -> Collection_ID(T)
{
    if !contains_entity_id(ecs, entity_id) do return {-1, -1}
    if contains, _, _ := entity_contains_archetype(ecs, entity_id, T); contains do return {-1, -1}

    //Creating an archetype
    archetype_name := name_of(T)
    archetype := &ecs.archetypes[archetype_name]
    archetype_id := raw_collection_sub_allocate(&archetype.collection)
    if archetype_id == INVALID_RAW_COLLECTION_ID do return {-1, -1}

    //Creating a raw archetype slot for entity
    entity_chunk := table_get(&ecs.entities.chunks, entity_id.chunk_index)
    entity_chunk_content := chunk_content(chunk_from_raw(Entity, entity_chunk))
    raw_archetype := array_arena_sub_allocate(&entity_chunk_content[entity_id.element_index].archetypes)
    if raw_archetype == nil
    {
        raw_collection_free(&archetype.collection, archetype_id)
        return {-1, -1}
    }

    //Setting archetype to entity
    raw_archetype.name = name_of(T)
    raw_archetype.id = archetype_id

    //Setting entity to archetype
    raw_archetype_chunk := table_get(&archetype.collection.chunks, archetype_id.chunk_index)
    archetype_chunk_content := chunk_content(chunk_from_raw(T, raw_archetype_chunk))
    archetype_chunk_content[archetype_id.element_index].__entity_id = entity_id

    return transmute(Collection_ID(T))archetype_id
}

@(optimization_mode="speed")
create_entity :: #force_inline proc(ecs: ^ECS) -> Entity_ID
{
    return collection_sub_allocate(&ecs.entities)
}

@(optimization_mode="speed")
destroy_entity :: #force_inline proc(ecs: ^ECS, id: Entity_ID) -> bool
{
    //TODO: destroy all components
    return collection_free(&ecs.entities, id)
}