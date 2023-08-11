package ecs

MAX_ENTITY_COMPONENTS :: 64

Entity :: struct
{
    _element: Chunk_Element,
    components: Array_Arena(struct{name: string, component: Index}, MAX_ENTITY_COMPONENTS),
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