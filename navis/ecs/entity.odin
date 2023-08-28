package ecs

import "../mem"

MAX_ENTITY_ARCHETYPES :: 64

INVALID_ENTITY_ID :: Entity_ID{-1, -1}
Entity_ID :: Collection_ID(Entity)

Entity_Raw_Archetype :: struct
{
    name: string,
    id: Raw_Collection_ID,
}

Entity :: struct
{
    __used: Chunk_Element_Used,
    archetypes: mem.Sized_Chunk(Entity_Raw_Archetype, MAX_ENTITY_ARCHETYPES),
}

entity_chunk_init :: proc(chunk: ^Chunk(Entity), capacity: int, allocator := context.allocator) -> bool
{
    return chunk_init(chunk, capacity, allocator)
}

entity_chunk_destroy :: proc(chunk: ^Chunk(Entity), allocator := context.allocator) -> bool
{
    return chunk_destroy(chunk, allocator)
}

entity_chunk_sub_allocate :: proc "contextless" (chunk: ^Chunk(Entity)) -> int
{
    return chunk_sub_allocate(chunk)
}

entity_chunk_free :: proc "contextless" (chunk: ^Chunk(Entity), index: int) -> bool
{
    return chunk_free(chunk, index)
}

entity_contains_archetype :: proc(ecs: ^ECS, id: Entity_ID, $T: typeid) -> (bool, Collection_ID(T), int)
{
    if !raw_collection_contains_id(transmute(^Raw_Collection)&ecs.entities, transmute(Raw_Collection_ID)id) || !contains_archetype(ecs, T) do return false, {-1, -1}, -1

    chunk := table_get(&ecs.entities.chunks, id.chunk_index)
    content := chunk_content(transmute(^Chunk(Entity))chunk)
    archetypes := &content[id.element_index].archetypes
    archetype_name := name_of(T)
    for &slot, index in archetypes.slots
    {
        if !slot.used do continue
        if slot.data.name == archetype_name do return true, transmute(Collection_ID(T))slot.data.id, index
    }

    return false, {-1, -1}, -1
}