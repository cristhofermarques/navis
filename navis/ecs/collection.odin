package ecs

import "core:intrinsics"
import "core:runtime"
import "core:sync"

NAME :: "_element"

INVALID_INDEX :: [2]int{-1, -1}
Index :: [2]int

Collection_Descriptor :: struct($T: typeid)
where
intrinsics.type_is_named(T) && 
intrinsics.type_has_field(T, CHUNK_ELEMENT_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_FIELD_NAME) == Chunk_Element &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    chunk_capacity: int,
    chunk_init: proc(^Chunk(T), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Chunk(T), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Chunk(T)) -> int,
    chunk_free: proc "contextless" (^Chunk(T), int) -> bool,
}

Collection :: struct($T: typeid)
where
intrinsics.type_is_named(T) && 
intrinsics.type_has_field(T, CHUNK_ELEMENT_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_FIELD_NAME) == Chunk_Element &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    alocator: runtime.Allocator,
    mutex: sync.Atomic_Mutex,
    seek, sub_allocations, chunk_capacity: int,
    chunk_init: proc(^Chunk(T), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Chunk(T), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Chunk(T)) -> int,
    chunk_free: proc "contextless" (^Chunk(T), int) -> bool,
    chunks: [dynamic]Chunk(T),
}

Raw_Collection :: struct
{
    alocator: runtime.Allocator,
    mutex: sync.Atomic_Mutex,
    seek, sub_allocations, chunk_capacity: int,
    chunk_init: proc(^Raw_Chunk, int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Raw_Chunk, runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Raw_Chunk) -> int,
    chunk_free: proc "contextless" (^Raw_Chunk, int) -> bool,
    chunks: [dynamic]Raw_Chunk,
}

raw_collection_make :: proc "contextless" (descriptor: Collection_Descriptor($T)) -> Raw_Collection
{
    if descriptor.chunk_capacity < 1 || descriptor.chunk_init == nil || descriptor.chunk_destroy == nil || descriptor.chunk_sub_allocate == nil || descriptor.chunk_free == nil do return {}

    collection: Raw_Collection
    collection.chunk_capacity = descriptor.chunk_capacity
    collection.chunk_init = auto_cast descriptor.chunk_init
    collection.chunk_destroy = auto_cast descriptor.chunk_destroy
    collection.chunk_sub_allocate = auto_cast descriptor.chunk_sub_allocate
    collection.chunk_free = auto_cast descriptor.chunk_free
    return collection
}

raw_collection_init :: proc(collection: ^Raw_Collection, initial_capacity := 2, allocator := context.allocator) -> bool
{
    if collection == nil || collection.chunk_capacity < 1 || collection.chunk_init == nil ||  collection.chunk_destroy == nil || collection.chunk_sub_allocate == nil ||  collection.chunk_free == nil do return false

    chunks, chunks_allocation_error := make_dynamic_array_len_cap([dynamic]Raw_Chunk, 1, max(1, initial_capacity))
    if chunks_allocation_error != .None do return false

    if !collection.chunk_init(&chunks[0], collection.chunk_capacity, allocator) do return false

    collection.alocator = allocator
    collection.chunks = chunks
    return true
}

raw_collection_destroy :: proc(collection: ^Raw_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do collection.chunk_destroy(&chunk, collection.alocator)
    delete(collection.chunks)
    collection^ = {}
    return true
}

raw_collection_sub_allocate :: proc(collection: ^Raw_Collection) -> Index
{
    if collection == nil do return INVALID_INDEX

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    if raw_collection_is_full(collection)
    {
        new_chunk := raw_collection_new_chunk(collection)
        if new_chunk == nil do return INVALID_INDEX

        chunk_index := collection.chunk_sub_allocate(new_chunk)
        if chunk_index > -1
        {
            collection.sub_allocations += 1
            collection.seek = max(0, len(collection.chunks) - 1)
            return Index{collection.seek, chunk_index}
        }
    }
    else
    {   
        {
            seek := &collection.chunks[collection.seek]
            chunk_index := collection.chunk_sub_allocate(seek)
            if chunk_index > -1
            {
                raw_collection_index := collection.seek
                collection.sub_allocations += 1
                if raw_chunk_is_full(seek) do collection.seek = clamp(collection.seek + 1, 0, len(collection.chunks) - 1)
                return Index{raw_collection_index, chunk_index}
            }
        }
        
        for &chunk, index in collection.chunks
        {
            if raw_chunk_is_full(&chunk) do continue
            
            chunk_index := collection.chunk_sub_allocate(&chunk)
            if chunk_index > -1
            {
                collection.sub_allocations += 1
                if raw_chunk_is_full(&chunk) do collection.seek = clamp(index + 1, 0, len(collection.chunks) - 1)
                return Index{index, chunk_index}
            }
        }   
    }
    return INVALID_INDEX
}

raw_collection_is_full :: proc "contextless" (collection: ^Raw_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do if !raw_chunk_is_full(&chunk) do return false
    return true
}

@(private)
raw_collection_new_chunk :: proc(collection: ^Raw_Collection) -> ^Raw_Chunk
{
    if collection == nil do return nil

    chunk: Raw_Chunk
    if !collection.chunk_init(&chunk, collection.chunk_capacity, collection.alocator) do return nil

    append(&collection.chunks, chunk)
    return &collection.chunks[max(0, len(collection.chunks) - 1)]
}

raw_collection_as :: proc "contextless" (collection: ^Raw_Collection, $T: typeid) -> ^Collection(T)
{
    if collection == nil || collection.chunks[0].element_fields != intrinsics.type_struct_field_count(T) do return nil
    return transmute(^Collection(T))collection
}

collection_make :: proc "contextless" (descriptor: Collection_Descriptor($T)) -> Collection(T)
{
    if descriptor.chunk_capacity < 1 || descriptor.chunk_init == nil || descriptor.chunk_destroy == nil || descriptor.chunk_sub_allocate == nil || descriptor.chunk_free == nil do return {}

    collection: Collection(T)
    collection.chunk_capacity = descriptor.chunk_capacity
    collection.chunk_init = descriptor.chunk_init
    collection.chunk_destroy = descriptor.chunk_destroy
    collection.chunk_sub_allocate = descriptor.chunk_sub_allocate
    collection.chunk_free = descriptor.chunk_free
    return collection
}

collection_as_raw :: proc "contextless" (collection: ^Collection($T)) -> ^Raw_Collection
{
    return transmute(^Raw_Collection)collection
}