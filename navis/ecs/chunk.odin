package ecs

import "core:intrinsics"
import "core:sync"

MAX_CHUNK_ELEMENT_FIELDS :: 64
CHUNK_ELEMENT_FIELD_NAME :: "_element"

Chunk_Content :: [MAX_CHUNK_ELEMENT_FIELDS + 1]rawptr

Chunk_Element :: struct
{
    used: bool,
    mutex: sync.Atomic_Mutex,
}

Chunk :: struct($T: typeid)
where
intrinsics.type_is_named(T) && 
intrinsics.type_has_field(T, CHUNK_ELEMENT_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_FIELD_NAME) == Chunk_Element &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    seek, element_fields, sub_allocations: int,
    content: Chunk_Content,
}

Raw_Chunk :: struct
{
    seek, element_fields, sub_allocations: int,
    content: Chunk_Content,
}

chunk_init :: proc(chunk: ^Chunk($T), capacity: int, allocator := context.allocator) -> bool
{
    if capacity < 1 do return false
    content, content_allocation_error := make_soa(#soa[]T, capacity, allocator)
    if content_allocation_error != .None do return false

    chunk_content := transmute(^#soa[]T)&chunk.content
    chunk_content^ = content
    chunk.element_fields = intrinsics.type_struct_field_count(T)
    return true
}

chunk_destroy :: proc(chunk: ^Chunk($T), allocator := context.allocator) -> bool
{
    if chunk == nil do return false
    chunk_content := transmute(^#soa[]T)&chunk.content
    delete_soa(chunk_content^, allocator)
    chunk^ = {}
    return true
}

chunk_content :: proc "contextless" (chunk: ^Chunk($T)) -> ^#soa[]T
{
    if chunk == nil do return nil
    return transmute(^#soa[]T)&chunk.content
}

chunk_sub_allocate :: proc "contextless" (chunk: ^Chunk($T)) -> int
{
    if chunk == nil do return -1

    content := transmute(^#soa[]T)&chunk.content

    chunk_seek := chunk.seek
    if !content[chunk_seek]._element.used
    {
        content[chunk_seek]._element.used = true
        chunk.sub_allocations += 1
        chunk.seek = clamp(chunk_seek + 1, 0, len(content) - 1)
        return chunk_seek
    }

    for &element, index in content
    {
        if element._element.used do continue
        element._element.used = true
        chunk.sub_allocations += 1
        chunk.seek = clamp(index + 1, 0, len(content) - 1)
        return index
    }

    return -1
}

chunk_free :: proc "contextless" (chunk: ^Chunk($T), index: int) -> bool
{
    if chunk == nil || index < 0 do return false
    content := transmute(^#soa[]T)&chunk.content
    content[index]._element.used = false
    if index < chunk.seek do chunk.seek = index
    return true
}

chunk_as_raw :: proc "contextless" (chunk: ^Chunk($T)) -> ^Raw_Chunk
{
    if chunk == nil do return nil
    return transmute(^Raw_Chunk)chunk
}

chunk_from_raw :: proc "contextless" ($T: typeid, chunk: ^Raw_Chunk) ->  ^Chunk(T)
{
    if chunk == nil || chunk.element_fields != intrinsics.type_struct_field_count(T) do return nil
    return transmute(^Chunk(T))chunk
}

raw_chunk_capacity :: proc "contextless" (chunk: ^Raw_Chunk) -> int
{
    return transmute(int)chunk.content[chunk.element_fields]
}

raw_chunk_is_full :: proc "contextless" (chunk: ^Raw_Chunk) ->  bool
{
    return chunk != nil && chunk.sub_allocations == raw_chunk_capacity(chunk)
}