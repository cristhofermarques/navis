package memory

import "core:mem"
import "core:runtime"
import "core:sync"

Collection :: struct($T: typeid)
{
    mutex: sync.Atomic_Mutex,
    allocator: runtime.Allocator,
    arena_capacity: int,
    sub_allocations: int,
    seek: ^Arena(T),
    arenas: [dynamic]Arena(T),
}

collection_create :: proc($T: typeid, arena_capacity, reserve_count: int, allocator := context.allocator) -> (Collection(T), bool)
{
    if arena_capacity < 1
    {
        //TODO: log error
        return {}, false
    }

    arenas, arenas_allocation_error := make_dynamic_array_len_cap([dynamic]Arena(T), 1, max(1, reserve_count), allocator)
    if arenas_allocation_error != .None
    {
        //TODO: log error
        return {}, false
    }

    initial_arena, created_initial_arena := arena_create(T, arena_capacity, allocator)
    if !created_initial_arena
    {
        //TODO: log error
        delete(arenas)
        return {}, false
    }

    arenas[0] = initial_arena
    collection: Collection(T)
    collection.allocator = allocator
    collection.arena_capacity = arena_capacity
    collection.arenas = arenas
    collection.seek = raw_data(arenas)
    return collection, true
}

collection_destroy :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for &arena in collection.arenas do arena_destroy(&arena)
    delete(collection.arenas)
    collection^ = {}
    return true
}

collection_create_arena :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    arena, created := arena_create(T, collection.arena_capacity, collection.allocator)
    if !created do return false
    append(&collection.arenas, arena)
    return true
}

collection_destroy_arena :: proc(collection: ^Collection($T), index: int) -> bool
{
    if collection == nil || index < 1 do return false
    arena := &collection.arenas[index]
    if collection.seek == arena do collection.seek = raw_data(collection.arenas)
    arena_destroy(arena, collection.allocator)
    unordered_remove(&collection.arenas, index)
    return true
}

collection_sub_allocate :: proc(collection: ^Collection($T)) -> ^T
{
    if collection == nil do return nil

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    if data := arena_sub_allocate(collection.seek); data != nil //Cache
    {
        collection.sub_allocations += 1
        if arena_is_full(collection.seek) do collection_seek_to_next(collection)
        return data
    }

    if collection_is_full(collection) //Create
    {
        if !collection_create_arena(collection) do return nil
        last := &collection.arenas[max(0, len(collection.arenas) - 1)]

        data := arena_sub_allocate(last)
        if data == nil do return nil
        
        collection.sub_allocations += 1
        collection.seek = last
        return data
    }
    else //Search
    {       
        for i := 0; i < len(collection.arenas); i += 1
        {
            arena := &collection.arenas[i]
            if arena_is_full(arena) do continue
            
            data := arena_sub_allocate(arena)
            if data == nil do continue
            
            collection.sub_allocations += 1
            collection.seek = arena
            if arena_is_full(collection.seek) do collection_seek_to_next(collection)
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

    for &arena, i in collection.arenas
    {
        if !arena_has(&arena, data) do continue
        
        arena_free(&arena, data)
        collection.sub_allocations -= 1
        if arena_is_empty(&arena) && collection_get_empty_arena_count(collection) > 1
        {    
            collection_destroy_arena(collection, i)
            return
        }

        if cast(uintptr)&arena < cast(uintptr)arena.seek do collection.seek = &arena
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
    collection.seek = transmute(^Arena(T))min(uptr_next, uptr_last)
}

collection_is_full :: proc "contextless" (collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for i := 0; i < len(collection.arenas); i += 1
    {
        arena := &collection.arenas[i]
        if !arena_is_full(arena) do return false
    }
    return true
}

collection_get_last :: proc "contextless" (collection: ^Collection($T)) -> ^Arena(T)
{
    return &collection.arenas[max(0, len(collection.arenas) - 1)]
}

collection_get_empty_arena_count :: proc "contextless" (collection: ^Collection($T)) -> int
{
    count := 0
    for &arena in collection.arenas do if arena_is_empty(&arena) do count += 1
    return count
}

Untyped_Collection :: struct
{
    mutex: sync.Atomic_Mutex,
    allocator: runtime.Allocator,
    slot_size, arena_capacity, sub_allocations: int,
    slot_data_offset: uintptr,
    seek: ^Untyped_Arena,
    arenas: [dynamic]Untyped_Arena,
}

untyped_collection_create :: proc(slot_size:int, slot_data_offset: uintptr, arena_capacity, reserve_count: int, allocator := context.allocator) -> (Untyped_Collection, bool)
{
    if slot_size < 1 || slot_data_offset < 1 || arena_capacity < 1 do return {}, false

    arenas, arenas_allocation_error := make_dynamic_array_len_cap([dynamic]Untyped_Arena, 1, max(1, reserve_count), allocator)
    if arenas_allocation_error != .None do return {}, false

    intial_arena, did_create_intial_arena := untyped_arena_create(slot_size, slot_data_offset, arena_capacity, allocator)
    if !did_create_intial_arena
    {
        delete(arenas)
        return {}, false
    }

    arenas[0] = intial_arena
    collection: Untyped_Collection
    collection.allocator = allocator
    collection.slot_size = slot_size
    collection.slot_data_offset = slot_data_offset
    collection.arena_capacity = arena_capacity
    collection.seek = raw_data(arenas)
    collection.arenas = arenas
    return collection, true
}

untyped_collection_destroy :: proc(collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    for &arena in collection.arenas do untyped_arena_destroy(&arena, collection.allocator)
    delete(collection.arenas)
    collection^ = {}
    return true
}

untyped_collection_sub_allocate :: proc(collection: ^Untyped_Collection) -> rawptr
{
    if collection == nil do return nil

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)
    
    if data := untyped_arena_sub_allocate(collection.seek); data != nil
    {
        collection.sub_allocations += 1
        if untyped_arena_is_full(collection.seek) do untyped_collection_seek_to_next(collection)
        return data
    }

    if untyped_collection_is_full(collection)
    {
        if !untyped_collection_create_arena(collection) do return nil
        last := untyped_collection_get_last(collection)
        data := untyped_arena_sub_allocate(last)
        if data == nil do return nil

        collection.sub_allocations += 1
        collection.seek = last
        return data
    }
    else
    {
        for &arena, i in collection.arenas
        {
            if untyped_arena_is_full(&arena) do continue
            data := untyped_arena_sub_allocate(&arena)
            if data == nil do continue

            collection.sub_allocations += 1
            collection.seek = &arena
            if untyped_arena_is_full(&arena) do untyped_collection_seek_to_next(collection)
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

    for &arena, i in collection.arenas
    {
        if !untyped_arena_has(&arena, data) do continue
        if !untyped_arena_free(&arena, data) do return
        collection.sub_allocations -= 1
        if untyped_arena_is_empty(&arena) && untyped_collection_get_empty_arena_count(collection) > 1
        {    
            untyped_collection_destroy_arena(collection, i)
            return
        }

        if cast(uintptr)&arena < cast(uintptr)arena.seek do collection.seek = &arena
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
    collection.seek = transmute(^Untyped_Arena)min(uptr_next, uptr_last)
}

untyped_collection_get_last :: proc "contextless" (collection: ^Untyped_Collection) -> ^Untyped_Arena
{
    return &collection.arenas[max(0, len(collection.arenas) - 1)]
}

untyped_collection_is_full :: proc "contextless" (collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    for &arena in collection.arenas do if !untyped_arena_is_full(&arena) do return false
    return true
}

untyped_collection_create_arena :: proc(collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    arena, created := untyped_arena_create(collection.slot_size, collection.slot_data_offset, collection.arena_capacity, collection.allocator)
    if !created do return false
    append(&collection.arenas, arena)
    return true
}

untyped_collection_destroy_arena :: proc(collection: ^Untyped_Collection, index: int) -> bool
{
    if collection == nil || index < 1 do return false
    arena := &collection.arenas[index]
    if collection.seek == arena do collection.seek = raw_data(collection.arenas)
    untyped_arena_destroy(arena, collection.allocator)
    unordered_remove(&collection.arenas, index)
    return true
}

untyped_collection_get_empty_arena_count :: proc "contextless" (collection: ^Untyped_Collection) -> int
{
    count := 0
    for &arena in collection.arenas do if untyped_arena_is_empty(&arena) do count += 1
    return count
}