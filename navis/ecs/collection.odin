package ecs

import "core:intrinsics"
import "core:runtime"
import "core:sync"
import "core:mem"

INVALID_RAW_COLLECTION_ID :: Raw_Collection_ID{-1, -1}

Raw_Collection_ID :: struct
{
    chunk_index: Table_ID,
    element_index: int,
}

Collection_ID :: struct($T: typeid)
where
intrinsics.type_is_named(T) && 
intrinsics.type_has_field(T, CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_USED_FIELD_NAME) == Chunk_Element_Used &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    chunk_index: Table_ID,
    element_index: int,
}

Collection_Descriptor :: struct($T: typeid)
where
intrinsics.type_is_named(T) && 
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

Collection :: struct($T: typeid)
where
intrinsics.type_is_named(T) && 
intrinsics.type_has_field(T, CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(T, CHUNK_ELEMENT_USED_FIELD_NAME) == Chunk_Element_Used &&
intrinsics.type_struct_field_count(T) <= MAX_CHUNK_ELEMENT_FIELDS
{
    alocator: runtime.Allocator,
    mutex: sync.Atomic_Mutex,
    seek_id: Table_ID,
    seek_pointer: ^Raw_Chunk,
    sub_allocations, chunk_capacity: int,
    chunk_init: proc(^Chunk(T), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Chunk(T), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Chunk(T)) -> int,
    chunk_free: proc "contextless" (^Chunk(T), int) -> bool,
    chunks: Table(Raw_Chunk),
}

Raw_Collection :: struct
{
    alocator: runtime.Allocator,
    mutex: sync.Atomic_Mutex,
    seek_id: Table_ID,
    seek_pointer: ^Raw_Chunk,
    sub_allocations, chunk_capacity: int,
    chunk_init: proc(^Raw_Chunk, int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Raw_Chunk, runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Raw_Chunk) -> int,
    chunk_free: proc "contextless" (^Raw_Chunk, int) -> bool,
    chunks: Table(Raw_Chunk),
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

    if !table_init(&collection.chunks, initial_capacity, allocator) do return false

    initial_chunk: Raw_Chunk
    if !collection.chunk_init(&initial_chunk, collection.chunk_capacity, allocator)
    {
        table_destroy(&collection.chunks)
        return false
    }

    id := table_append(&collection.chunks, &initial_chunk)

    collection.alocator = allocator
    collection.seek_pointer = table_get(&collection.chunks, id)
    return true
}

raw_collection_destroy :: proc(collection: ^Raw_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks.content do collection.chunk_destroy(&chunk, collection.alocator)
    table_destroy(&collection.chunks)
    collection^ = {}
    return true
}

raw_collection_sub_allocate :: proc(collection: ^Raw_Collection) -> Raw_Collection_ID #no_bounds_check
{
    // sync.atomic_mutex_lock(&collection.mutex)
    // defer sync.atomic_mutex_unlock(&collection.mutex)

    if collection.sub_allocations == (collection.chunk_capacity * len(collection.chunks.content))
    {
        new_chunk := raw_collection_new_chunk(collection)
        if new_chunk == nil do return INVALID_RAW_COLLECTION_ID

        element_index := collection.chunk_sub_allocate(new_chunk)
        if element_index > -1
        {
            collection.sub_allocations += 1
            return Raw_Collection_ID{new_chunk.__id, element_index}
        }
    }
    else
    {
        {
            seek_pointer := collection.seek_pointer
            element_index := collection.chunk_sub_allocate(seek_pointer)
            if element_index > -1
            {
                //NOTE: dont require to be atomic if we lock the entire proc.
                collection.sub_allocations += 1
                
                //NOTE: only seek to next if the current seek chunk is full.
                if raw_chunk_is_full(seek_pointer) do raw_collection_seek_to_next(collection)
                return Raw_Collection_ID{seek_pointer.__id, element_index}
            }
        }
        
        for &chunk, index in collection.chunks.content
        {
            if raw_chunk_is_full(&chunk) do continue
            
            element_index := collection.chunk_sub_allocate(&chunk)
            if element_index > -1
            {
                collection.sub_allocations += 1
                collection.seek_id = chunk.__id
                collection.seek_pointer = &chunk

                //NOTE: only seek to next if the current seek chunk is full.
                if raw_chunk_is_full(&chunk) do raw_collection_seek_to_next(collection)
                return Raw_Collection_ID{chunk.__id, element_index}
            }
        }   
    }

    return INVALID_RAW_COLLECTION_ID
}

raw_collection_free :: proc(collection: ^Raw_Collection, id: Raw_Collection_ID) -> bool
{
    if !raw_collection_contains_id(collection, id) do return false
    chunk := &collection.chunks.content[table_index_of(&collection.chunks, id.chunk_index)]
    freed := collection.chunk_free(chunk, id.element_index)
    if !freed do return false

    collection.sub_allocations -= 1
    if !raw_chunk_is_empty(chunk) do return true
    
    if id.chunk_index == 0 do return true
    empty_chunks := raw_collection_empty_chunks(collection)
    if empty_chunks > 1 do raw_collection_destroy_chunk(collection, id.chunk_index)
    return true
}

raw_collection_empty_chunks :: proc "contextless" (collection: ^Raw_Collection) -> int
{
    count := 0
    for &chunk in collection.chunks.content do if chunk.sub_allocations == 0 do count += 1
    return count
}

raw_collection_is_full :: proc "contextless" (collection: ^Raw_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks.content do if !raw_chunk_is_full(&chunk) do return false
    return true
}

/*
Only for internal use.
*/
@(private)
raw_collection_seek_to_next :: proc "contextless" (collection: ^Raw_Collection)
{
    seek_pointer := collection.seek_pointer
    chunks_length := table_content_length(&collection.chunks)
    uptr_raw_chunk_size: uintptr = size_of(Raw_Chunk)
    uptr_seek_pointer := transmute(uintptr)seek_pointer
    uptr_chunks_begin := transmute(uintptr)raw_data(collection.chunks.content)
    uptr_chunks_end := uintptr(chunks_length * chunks_length) + uptr_chunks_begin
    uptr_last := uptr_chunks_end - uptr_raw_chunk_size
    uptr_next := uptr_seek_pointer + uptr_raw_chunk_size
    if uptr_next > uptr_last do uptr_next = uptr_last
    next := transmute(^Raw_Chunk)uptr_next
    collection.seek_id = next.__id
}

@(private)
raw_collection_new_chunk :: proc(collection: ^Raw_Collection) -> ^Raw_Chunk
{
    chunk: Raw_Chunk
    if !collection.chunk_init(&chunk, collection.chunk_capacity, collection.alocator) do return nil

    id := table_append(&collection.chunks, &chunk)
    pointer := table_get(&collection.chunks, id)
    collection.seek_id = id
    collection.seek_pointer = pointer
    return pointer
}

@(private)
raw_collection_destroy_chunk :: proc(collection: ^Raw_Collection, id: Table_ID) -> bool
{
    chunk := table_get(&collection.chunks, id)
    if !collection.chunk_destroy(chunk, collection.alocator) do return false
    table_remove(&collection.chunks, id)
    if collection.seek_id == id
    {
        collection.seek_id = 0
        collection.seek_pointer = table_get(&collection.chunks, 0)
    }
    return true
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

raw_collection_contains_id :: proc "contextless" (collection: ^Raw_Collection, id: Raw_Collection_ID) -> bool
{
    if collection == nil || !table_contains_id(&collection.chunks, id.chunk_index) || id.element_index < 0 || id.element_index >= collection.chunk_capacity do return false
    return true
}

collection_as_raw :: proc "contextless" (collection: ^Collection($T)) -> ^Raw_Collection
{
    return transmute(^Raw_Collection)collection
}

collection_contains_id :: proc "contextless" (collection: ^Collection($T), id: Collection_ID(T)) -> bool
{
    if collection == nil || !table_contains_id(&collection.chunks, id.chunk_index) || id.element_index < 0 || id.element_index >= collection.chunk_capacity do return false
    return true
}

collection_get :: proc "contextless" (collection: ^Collection($T), id: Collection_ID(T), element: ^T) -> bool
{
    if collection == nil || element == nil || !collection_contains_id(collection, id) do return false
    chunk := table_get(&collection.chunks, id.chunk_index)
    content := chunk_content(chunk)
    element^ = content[id.element_index]
    return true
}

/*
Does the same as 'raw_collection_sub_allocate'. But here, we "know" the type.
    That means we can make a chunk sub allocation directly.
*/
@(optimization_mode="speed")
collection_sub_allocate :: proc(collection: ^Collection($T)) -> Collection_ID(T)
{
    if collection.sub_allocations == (collection.chunk_capacity * len(collection.chunks.content))
    {
        new_chunk := collection_new_chunk(collection)
        if new_chunk == nil do return {-1, -1}

        element_index := chunk_sub_allocate(transmute(^Chunk(T))new_chunk)
        if element_index > -1
        {
            collection.sub_allocations += 1
            return {new_chunk.__id, element_index}
        }
    }
    else
    {
        {
            seek_pointer := collection.seek_pointer
            element_index := chunk_sub_allocate(transmute(^Chunk(T))seek_pointer)
            if element_index > -1
            {
                //NOTE: dont require to be atomic if we lock the entire proc.
                collection.sub_allocations += 1
                
                //NOTE: only seek to next if the current seek chunk is full.
                if raw_chunk_is_full(seek_pointer) do raw_collection_seek_to_next(transmute(^Raw_Collection)collection)
                return {seek_pointer.__id, element_index}
            }
        }
        
        for &chunk, index in collection.chunks.content
        {
            if raw_chunk_is_full(&chunk) do continue

            element_index := chunk_sub_allocate(transmute(^Chunk(T))&chunk)
            if element_index > -1
            {
                collection.sub_allocations += 1
                collection.seek_id = chunk.__id
                collection.seek_pointer = &chunk

                //NOTE: only seek to next if the current seek chunk is full.
                if raw_chunk_is_full(&chunk) do raw_collection_seek_to_next(transmute(^Raw_Collection)collection)
                return {chunk.__id, element_index}
            }
        }   
    }

    return {-1, -1}
}

@(optimization_mode="speed")
collection_free :: proc(collection: ^Collection($T), id: Collection_ID(T)) -> bool
{
    raw := transmute(^Raw_Collection)collection
    if !collection_contains_id(collection, id) do return false
    chunk := &collection.chunks.content[table_index_of(&collection.chunks, id.chunk_index)]
    freed := chunk_free(transmute(^Chunk(T))chunk, id.element_index)
    if !freed do return false

    collection.sub_allocations -= 1
    if !raw_chunk_is_empty(chunk) do return true
    
    if id.chunk_index == 0 do return true
    empty_chunks := raw_collection_empty_chunks(raw)
    if empty_chunks > 1 do collection_destroy_chunk(collection, id.chunk_index)
    return true
}

@(private)
collection_new_chunk :: proc(collection: ^Collection($T)) -> ^Raw_Chunk
{
    chunk: Raw_Chunk
    if !chunk_init(transmute(^Chunk(T))&chunk, collection.chunk_capacity, collection.alocator) do return nil

    id := table_append(&collection.chunks, &chunk)
    pointer := table_get(&collection.chunks, id)
    collection.seek_id = id
    collection.seek_pointer = pointer
    return pointer
}

@(private)
collection_destroy_chunk :: proc(collection: ^Collection($T), id: Table_ID) -> bool
{
    chunk := table_get(&collection.chunks, id)
    if !chunk_destroy(transmute(^Chunk(T))chunk, collection.alocator) do return false
    table_remove(&collection.chunks, id)
    if collection.seek_id == id
    {
        collection.seek_id = 0
        collection.seek_pointer = table_get(&collection.chunks, 0)
    }
    return true
}