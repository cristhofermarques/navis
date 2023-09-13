package navis_mem

import "core:mem"
import "core:runtime"
import "core:sync"

Collection :: struct($T: typeid)
{
    mutex: sync.Atomic_Mutex,
    allocator: runtime.Allocator,
    chunk_capacity: int,
    sub_allocations: int,
    seek: ^Chunk(T),
    chunks: [dynamic]Chunk(T),
}

collection_create :: proc($T: typeid, chunk_capacity, reserve_count: int, allocator := context.allocator) -> (Collection(T), bool)
{
    if chunk_capacity < 1
    {
        //TODO: log error
        return {}, false
    }

    chunks, chunks_allocation_error := make_dynamic_array_len_cap([dynamic]Chunk(T), 1, max(1, reserve_count), allocator)
    if chunks_allocation_error != .None
    {
        //TODO: log error
        return {}, false
    }

    initial_chunk, created_initial_chunk := chunk_create(T, chunk_capacity, allocator)
    if !created_initial_chunk
    {
        //TODO: log error
        delete(chunks)
        return {}, false
    }

    chunks[0] = initial_chunk
    collection: Collection(T)
    collection.allocator = allocator
    collection.chunk_capacity = chunk_capacity
    collection.chunks = chunks
    collection.seek = raw_data(chunks)
    return collection, true
}

collection_destroy :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do chunk_destroy(&chunk)
    delete(collection.chunks)
    collection^ = {}
    return true
}

collection_create_chunk :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    chunk, created := chunk_create(T, collection.chunk_capacity, collection.allocator)
    if !created do return false
    append(&collection.chunks, chunk)
    return true
}

collection_destroy_chunk :: proc(collection: ^Collection($T), index: int) -> bool
{
    if collection == nil || index < 1 do return false
    chunk := &collection.chunks[index]
    if collection.seek == chunk do collection.seek = raw_data(collection.chunks)
    chunk_destroy(chunk, collection.allocator)
    unordered_remove(&collection.chunks, index)
    return true
}

collection_sub_allocate :: proc(collection: ^Collection($T)) -> ^T
{
    if collection == nil do return nil

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    if data := chunk_sub_allocate(collection.seek); data != nil //Cache
    {
        collection.sub_allocations += 1
        if chunk_is_full(collection.seek) do collection_seek_to_next(collection)
        return data
    }

    if collection_is_full(collection) //Create
    {
        if !collection_create_chunk(collection) do return nil
        last := &collection.chunks[max(0, len(collection.chunks) - 1)]

        data := chunk_sub_allocate(last)
        if data == nil do return nil
        
        collection.sub_allocations += 1
        collection.seek = last
        return data
    }
    else //Search
    {       
        for i := 0; i < len(collection.chunks); i += 1
        {
            chunk := &collection.chunks[i]
            if chunk_is_full(chunk) do continue
            
            data := chunk_sub_allocate(chunk)
            if data == nil do continue
            
            collection.sub_allocations += 1
            collection.seek = chunk
            if chunk_is_full(collection.seek) do collection_seek_to_next(collection)
            return data
        }
    }
    
    return nil
}

collection_free :: proc(collection: ^Collection($T), data: ^T)
{
    if collection == nil || data == nil do return

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    for &chunk, i in collection.chunks
    {
        if !chunk_has(&chunk, data) do continue
        
        chunk_free(&chunk, data)
        collection.sub_allocations -= 1
        if chunk_is_empty(&chunk) && collection_get_empty_chunk_count(collection) > 1
        {    
            collection_destroy_chunk(collection, i)
            return
        }

        if cast(uintptr)&chunk < cast(uintptr)chunk.seek do collection.seek = &chunk
        return
    }
}

@(private)
collection_seek_to_next :: proc "contextless" (collection: ^Collection($T))
{
    last := collection_get_last(collection)
    next := mem.ptr_offset(collection.seek, 1)
    uptr_last := uintptr(last)
    uptr_next := uintptr(next)
    collection.seek = transmute(^Chunk(T))min(uptr_next, uptr_last)
}

collection_is_full :: proc "contextless" (collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for i := 0; i < len(collection.chunks); i += 1
    {
        chunk := &collection.chunks[i]
        if !chunk_is_full(chunk) do return false
    }
    return true
}

collection_get_last :: proc "contextless" (collection: ^Collection($T)) -> ^Chunk(T)
{
    return &collection.chunks[max(0, len(collection.chunks) - 1)]
}

collection_get_empty_chunk_count :: proc "contextless" (collection: ^Collection($T)) -> int
{
    count := 0
    for &chunk in collection.chunks do if chunk_is_empty(&chunk) do count += 1
    return count
}

Untyped_Collection :: struct
{
    mutex: sync.Atomic_Mutex,
    allocator: runtime.Allocator,
    slot_size, chunk_capacity, sub_allocations: int,
    slot_data_offset: uintptr,
    seek: ^Untyped_Chunk,
    chunks: [dynamic]Untyped_Chunk,
}

untyped_collection_create :: proc(slot_size:int, slot_data_offset: uintptr, chunk_capacity, reserve_count: int, allocator := context.allocator) -> (Untyped_Collection, bool)
{
    if slot_size < 1 || slot_data_offset < 1 || chunk_capacity < 1 do return {}, false

    chunks, chunks_allocation_error := make_dynamic_array_len_cap([dynamic]Untyped_Chunk, 1, max(1, reserve_count), allocator)
    if chunks_allocation_error != .None do return {}, false

    intial_chunk, did_create_intial_chunk := untyped_chunk_create(slot_size, slot_data_offset, chunk_capacity, allocator)
    if !did_create_intial_chunk
    {
        delete(chunks)
        return {}, false
    }

    chunks[0] = intial_chunk
    collection: Untyped_Collection
    collection.allocator = allocator
    collection.slot_size = slot_size
    collection.slot_data_offset = slot_data_offset
    collection.chunk_capacity = chunk_capacity
    collection.seek = raw_data(chunks)
    collection.chunks = chunks
    return collection, true
}

untyped_collection_destroy :: proc(collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do untyped_chunk_destroy(&chunk, collection.allocator)
    delete(collection.chunks)
    collection^ = {}
    return true
}

untyped_collection_sub_allocate :: proc(collection: ^Untyped_Collection) -> rawptr
{
    if collection == nil do return nil

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)
    
    if data := untyped_chunk_sub_allocate(collection.seek); data != nil
    {
        collection.sub_allocations += 1
        if untyped_chunk_is_full(collection.seek) do untyped_collection_seek_to_next(collection)
        return data
    }

    if untyped_collection_is_full(collection)
    {
        if !untyped_collection_create_chunk(collection) do return nil
        last := untyped_collection_get_last(collection)
        data := untyped_chunk_sub_allocate(last)
        if data == nil do return nil

        collection.sub_allocations += 1
        collection.seek = last
        return data
    }
    else
    {
        for &chunk, i in collection.chunks
        {
            if untyped_chunk_is_full(&chunk) do continue
            data := untyped_chunk_sub_allocate(&chunk)
            if data == nil do continue

            collection.sub_allocations += 1
            collection.seek = &chunk
            if untyped_chunk_is_full(&chunk) do untyped_collection_seek_to_next(collection)
            return data
        }
    }
    
    return nil
}

untyped_collection_free :: proc(collection: ^Untyped_Collection, data: rawptr)
{
    if collection == nil || data == nil do return

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    for &chunk, i in collection.chunks
    {
        if !untyped_chunk_has(&chunk, data) do continue
        if !untyped_chunk_free(&chunk, data) do return
        collection.sub_allocations -= 1
        if untyped_chunk_is_empty(&chunk) && untyped_collection_get_empty_chunk_count(collection) > 1
        {    
            untyped_collection_destroy_chunk(collection, i)
            return
        }

        if cast(uintptr)&chunk < cast(uintptr)chunk.seek do collection.seek = &chunk
        return
    }
}

@(private)
untyped_collection_seek_to_next :: proc(collection: ^Untyped_Collection)
{
    last := untyped_collection_get_last(collection)
    next := mem.ptr_offset(collection.seek, 1)
    uptr_last := uintptr(last)
    uptr_next := uintptr(next)
    collection.seek = transmute(^Untyped_Chunk)min(uptr_next, uptr_last)
}

untyped_collection_get_last :: proc "contextless" (collection: ^Untyped_Collection) -> ^Untyped_Chunk
{
    return &collection.chunks[max(0, len(collection.chunks) - 1)]
}

untyped_collection_is_full :: proc "contextless" (collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do if !untyped_chunk_is_full(&chunk) do return false
    return true
}

untyped_collection_create_chunk :: proc(collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    chunk, created := untyped_chunk_create(collection.slot_size, collection.slot_data_offset, collection.chunk_capacity, collection.allocator)
    if !created do return false
    append(&collection.chunks, chunk)
    return true
}

untyped_collection_destroy_chunk :: proc(collection: ^Untyped_Collection, index: int) -> bool
{
    if collection == nil || index < 1 do return false
    chunk := &collection.chunks[index]
    if collection.seek == chunk do collection.seek = raw_data(collection.chunks)
    untyped_chunk_destroy(chunk, collection.allocator)
    unordered_remove(&collection.chunks, index)
    return true
}

untyped_collection_get_empty_chunk_count :: proc "contextless" (collection: ^Untyped_Collection) -> int
{
    count := 0
    for &chunk in collection.chunks do if untyped_chunk_is_empty(&chunk) do count += 1
    return count
}