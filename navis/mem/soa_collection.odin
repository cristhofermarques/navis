package navis_mem

import "core:intrinsics"
import "core:runtime"
import "core:sync"
import "core:mem"

INVALID_RAW_SOA_COLLECTION_ID :: Raw_SOA_Collection_ID{-1, -1}

Raw_SOA_Collection_ID :: struct
{
    chunk_id: Index_Table_ID,
    element_index: int,
}

SOA_Collection_ID :: struct($Type: typeid, $Fields: int)
where
intrinsics.type_is_named(Type) && 
intrinsics.type_has_field(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) == SOA_Chunk_Element_Used &&
intrinsics.type_struct_field_count(Type) <= Fields
{
    chunk_id: Index_Table_ID,
    element_index: int,
}

SOA_Collection_Descriptor :: struct($Type: typeid, $Fields: int)
where
intrinsics.type_is_named(Type) &&
intrinsics.type_has_field(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) == SOA_Chunk_Element_Used &&
intrinsics.type_struct_field_count(Type) <= Fields
{
    chunk_capacity: int,
    chunk_init: proc(^SOA_Chunk(Type, Fields), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^SOA_Chunk(Type, Fields), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^SOA_Chunk(Type, Fields)) -> int,
    chunk_free: proc "contextless" (^SOA_Chunk(Type, Fields), int) -> bool,
}

SOA_Collection :: struct($Type: typeid, $Fields: int)
where
intrinsics.type_is_named(Type) &&
intrinsics.type_has_field(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) == SOA_Chunk_Element_Used &&
intrinsics.type_struct_field_count(Type) <= Fields
{
    using __raw: Raw_SOA_Collection(Fields),
    // alocator: runtime.Allocator,
    // mutex: sync.Atomic_Mutex,
    // seek_id: Index_Table_ID,
    // seek_pointer: ^Raw_SOA_Chunk(Fields),
    // sub_allocations, chunk_capacity: int,
    // chunk_init: proc(^SOA_Chunk(Type, Fields), int, runtime.Allocator) -> bool,
    // chunk_destroy: proc(^SOA_Chunk(Type, Fields), runtime.Allocator) -> bool,
    // chunk_sub_allocate: proc "contextless" (^SOA_Chunk(Type, Fields)) -> int,
    // chunk_free: proc "contextless" (^SOA_Chunk(Type, Fields), int) -> bool,
    // chunks: Index_Table(Raw_SOA_Chunk(Fields)),
}

Raw_SOA_Collection :: struct($Fields: int)
{
    alocator: runtime.Allocator,
    mutex: sync.Atomic_Mutex,
    seek_id: Index_Table_ID,
    seek_pointer: ^Raw_SOA_Chunk(Fields),
    sub_allocations, chunk_capacity: int,
    chunk_init: proc(^Raw_SOA_Chunk(Fields), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Raw_SOA_Chunk(Fields), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Raw_SOA_Chunk(Fields)) -> int,
    chunk_free: proc "contextless" (^Raw_SOA_Chunk(Fields), int) -> bool,
    chunks: Index_Table(Raw_SOA_Chunk(Fields)),
}

raw_soa_collection_make :: proc "contextless" (descriptor: SOA_Collection_Descriptor($Type, $Fields)) -> Raw_SOA_Collection(Fields)
{
    if descriptor.chunk_capacity < 1 || descriptor.chunk_init == nil || descriptor.chunk_destroy == nil || descriptor.chunk_sub_allocate == nil || descriptor.chunk_free == nil do return {}

    collection: Raw_SOA_Collection(Fields)
    collection.chunk_capacity = descriptor.chunk_capacity
    collection.chunk_init = auto_cast descriptor.chunk_init
    collection.chunk_destroy = auto_cast descriptor.chunk_destroy
    collection.chunk_sub_allocate = auto_cast descriptor.chunk_sub_allocate
    collection.chunk_free = auto_cast descriptor.chunk_free
    return collection
}

raw_soa_collection_init :: proc(collection: ^Raw_SOA_Collection($Fields), initial_capacity := 2, allocator := context.allocator) -> bool
{
    if collection == nil || collection.chunk_capacity < 1 || collection.chunk_init == nil ||  collection.chunk_destroy == nil || collection.chunk_sub_allocate == nil ||  collection.chunk_free == nil do return false

    if !index_table_init(&collection.chunks, initial_capacity, allocator) do return false
    initial_chunk: Raw_SOA_Chunk(Fields)
    
    if !collection.chunk_init(&initial_chunk, collection.chunk_capacity, allocator)
    {
        index_table_destroy(&collection.chunks)
        return false
    }
    id := index_table_append(&collection.chunks, &initial_chunk)
    
    collection.alocator = allocator
    collection.seek_pointer = index_table_get(&collection.chunks, id)
    return true
}

raw_soa_collection_destroy :: proc(collection: ^Raw_SOA_Collection($Fields)) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks.content do collection.chunk_destroy(&chunk, collection.alocator)
    index_table_destroy(&collection.chunks)
    collection^ = {}
    return true
}

raw_soa_collection_sub_allocate :: proc(collection: ^Raw_SOA_Collection($Fields)) -> Raw_SOA_Collection_ID
{
    if collection.sub_allocations == (collection.chunk_capacity * len(collection.chunks.content))
    {
        new_chunk := raw_soa_collection_new_chunk(collection)
        if new_chunk == nil do return INVALID_RAW_SOA_COLLECTION_ID

        element_index := collection.chunk_sub_allocate(new_chunk)
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
            element_index := collection.chunk_sub_allocate(seek_pointer)
            if element_index > -1
            {
                //NOTE: dont require to be atomic if we lock the entire proc.
                collection.sub_allocations += 1
                
                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(seek_pointer) do raw_soa_collection_seek_to_next(collection)
                return {seek_pointer.__id, element_index}
            }
        }
        
        for &chunk, index in collection.chunks.content
        {
            if raw_soa_chunk_is_full(&chunk) do continue
            
            element_index := collection.chunk_sub_allocate(&chunk)
            if element_index > -1
            {
                collection.sub_allocations += 1
                collection.seek_id = chunk.__id
                collection.seek_pointer = &chunk

                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(&chunk) do raw_soa_collection_seek_to_next(collection)
                return {chunk.__id, element_index}
            }
        }   
    }

    return INVALID_RAW_SOA_COLLECTION_ID
}

raw_soa_collection_free :: proc(collection: ^Raw_SOA_Collection($Fields), id: Raw_SOA_Collection_ID) -> bool
{
    if !raw_soa_collection_contains_id(collection, id) do return false
    chunk := &collection.chunks.content[index_table_index_of(&collection.chunks, id.chunk_id)]
    freed := collection.chunk_free(chunk, id.element_index)
    if !freed do return false

    collection.sub_allocations -= 1
    if !raw_soa_chunk_is_empty(chunk) do return true
    
    if id.chunk_id == 0 do return true
    empty_chunks := raw_soa_collection_empty_chunks(collection)
    if empty_chunks > 1 do raw_soa_collection_destroy_chunk(collection, id.chunk_id)
    return true
}

raw_soa_collection_empty_chunks :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields)) -> int
{
    count := 0
    for &chunk in collection.chunks.content do if chunk.sub_allocations == 0 do count += 1
    return count
}

raw_soa_collection_is_full :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields)) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks.content do if !raw_soa_chunk_is_full(&chunk) do return false
    return true
}

/*
Only for internal use.
*/
@(private)
raw_soa_collection_seek_to_next :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields))
{
    seek_pointer := collection.seek_pointer
    chunks_length := index_table_content_length(&collection.chunks)
    uptr_raw_chunk_size: uintptr = size_of(Raw_SOA_Chunk(Fields))
    uptr_seek_pointer := transmute(uintptr)seek_pointer
    uptr_chunks_begin := transmute(uintptr)raw_data(collection.chunks.content)
    uptr_chunks_end := uintptr(chunks_length * chunks_length) + uptr_chunks_begin
    uptr_last := uptr_chunks_end - uptr_raw_chunk_size
    uptr_next := uptr_seek_pointer + uptr_raw_chunk_size
    if uptr_next > uptr_last do uptr_next = uptr_last
    next := transmute(^Raw_SOA_Chunk(Fields))uptr_next
    collection.seek_id = next.__id
}

@(private)
raw_soa_collection_new_chunk :: proc(collection: ^Raw_SOA_Collection($Fields)) -> ^Raw_SOA_Chunk(Fields)
{
    chunk: Raw_SOA_Chunk(Fields)
    if !collection.chunk_init(&chunk, collection.chunk_capacity, collection.alocator) do return nil

    id := index_table_append(&collection.chunks, &chunk)
    pointer := index_table_get(&collection.chunks, id)
    collection.seek_id = id
    collection.seek_pointer = pointer
    return pointer
}

@(private)
raw_soa_collection_destroy_chunk :: proc(collection: ^Raw_SOA_Collection($Fields), id: Index_Table_ID) -> bool
{
    chunk := index_table_get(&collection.chunks, id)
    if !collection.chunk_destroy(chunk, collection.alocator) do return false
    index_table_remove(&collection.chunks, id)
    if collection.seek_id == id
    {
        collection.seek_id = 0
        collection.seek_pointer = index_table_get(&collection.chunks, 0)
    }
    return true
}

raw_collection_as :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields), $Type: typeid) -> ^SOA_Collection(Type, Fields)
{
    if collection == nil || collection.chunks[0].element_fields != intrinsics.type_struct_field_count(Type) do return nil
    return transmute(^SOA_Collection(Type))collection
}

soa_collection_make :: proc "contextless" (descriptor: SOA_Collection_Descriptor($Type, $Fields)) -> SOA_Collection(Type, Fields)
{
    if descriptor.chunk_capacity < 1 || descriptor.chunk_init == nil || descriptor.chunk_destroy == nil || descriptor.chunk_sub_allocate == nil || descriptor.chunk_free == nil do return {}

    collection: SOA_Collection(Type, Fields)
    collection.chunk_capacity = descriptor.chunk_capacity
    collection.chunk_init = descriptor.chunk_init
    collection.chunk_destroy = descriptor.chunk_destroy
    collection.chunk_sub_allocate = descriptor.chunk_sub_allocate
    collection.chunk_free = descriptor.chunk_free
    return collection
}

raw_soa_collection_contains_id :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields), id: Raw_SOA_Collection_ID) -> bool
{
    if collection == nil || !index_table_contains_id(&collection.chunks, id.chunk_id) || id.element_index < 0 || id.element_index >= collection.chunk_capacity do return false
    return true
}

soa_collection_as_raw :: proc "contextless" (collection: ^SOA_Collection($Type, $Fields)) -> ^Raw_SOA_Collection(Fields)
{
    return transmute(^Raw_SOA_Collection(Fields))collection
}

soa_collection_contains_id :: proc "contextless" (collection: ^SOA_Collection($Type, $Fields), id: SOA_Collection_ID(Type,Fields)) -> bool
{
    if collection == nil || !index_table_contains_id(&collection.chunks, id.chunk_id) || id.element_index < 0 || id.element_index >= collection.chunk_capacity do return false
    return true
}

soa_collection_get :: proc "contextless" (collection: ^SOA_Collection($Type, $Fields), id: SOA_Collection_ID(Type, Fields), element: ^Type) -> bool
{
    if collection == nil || element == nil || !soa_collection_contains_id(collection, id) do return false
    chunk := index_table_get(&collection.chunks, id.chunk_id)
    content := soa_chunk_content(chunk)
    element^ = content[id.element_index]
    return true
}

/*
Does the same as 'raw_soa_collection_sub_allocate'. But here, we "know" the type.
    That means we can make a chunk sub allocation directly.
*/
soa_collection_sub_allocate :: proc(collection: ^SOA_Collection($Type, $Fields)) -> SOA_Collection_ID(Type, Fields)
{
    if collection.sub_allocations == (collection.chunk_capacity * len(collection.chunks.content))
    {
        new_chunk := soa_collection_new_chunk(collection)
        if new_chunk == nil do return {-1, -1}

        element_index := soa_chunk_sub_allocate(transmute(^SOA_Chunk(Type, Fields))new_chunk)
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
            element_index := soa_chunk_sub_allocate(transmute(^SOA_Chunk(Type, Fields))seek_pointer)
            if element_index > -1
            {
                //NOTE: dont require to be atomic if we lock the entire proc.
                collection.sub_allocations += 1
                
                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(seek_pointer) do raw_soa_collection_seek_to_next(transmute(^Raw_SOA_Collection(Fields))collection)
                return {seek_pointer.__id, element_index}
            }
        }
        
        for &chunk, index in collection.chunks.content
        {
            if raw_soa_chunk_is_full(&chunk) do continue

            element_index := soa_chunk_sub_allocate(transmute(^SOA_Chunk(Type, Fields))&chunk)
            if element_index > -1
            {
                collection.sub_allocations += 1
                collection.seek_id = chunk.__id
                collection.seek_pointer = &chunk

                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(&chunk) do raw_soa_collection_seek_to_next(transmute(^Raw_SOA_Collection(Fields))collection)
                return {chunk.__id, element_index}
            }
        }   
    }

    return {-1, -1}
}

soa_collection_free :: proc(collection: ^SOA_Collection($Type, $Fields), id: SOA_Collection_ID(Type, Fields)) -> bool
{
    raw := transmute(^Raw_SOA_Collection(Fields))collection
    if !soa_collection_contains_id(collection, id) do return false
    chunk := &collection.chunks.content[index_table_index_of(&collection.chunks, id.chunk_id)]
    freed := soa_chunk_free(transmute(^SOA_Chunk(Type, Fields))chunk, id.element_index)
    if !freed do return false

    collection.sub_allocations -= 1
    if !raw_soa_chunk_is_empty(chunk) do return true
    
    if id.chunk_id == 0 do return true
    empty_chunks := raw_soa_collection_empty_chunks(raw)
    if empty_chunks > 1 do soa_collection_destroy_chunk(collection, id.chunk_id)
    return true
}

@(private)
soa_collection_new_chunk :: proc(collection: ^SOA_Collection($Type, $Fields)) -> ^Raw_SOA_Chunk(Fields)
{
    chunk: Raw_SOA_Chunk(Fields)
    if !soa_chunk_init(soa_chunk_from_raw(Type, &chunk), collection.chunk_capacity, collection.alocator) do return nil

    id := index_table_append(&collection.chunks, &chunk)
    pointer := index_table_get(&collection.chunks, id)
    collection.seek_id = id
    collection.seek_pointer = pointer
    return pointer
}

@(private)
soa_collection_destroy_chunk :: proc(collection: ^SOA_Collection($Type, $Fields), id: Index_Table_ID) -> bool
{
    chunk := index_table_get(&collection.chunks, id)
    if !soa_chunk_destroy(soa_chunk_from_raw(Type, &chunk), collection.alocator) do return false
    index_table_remove(&collection.chunks, id)
    if collection.seek_id == id
    {
        collection.seek_id = 0
        collection.seek_pointer = index_table_get(&collection.chunks, 0)
    }
    return true
}