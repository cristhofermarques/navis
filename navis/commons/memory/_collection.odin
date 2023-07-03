package memory

import "core:runtime"
import "core:mem"

Collection :: struct($T: typeid)
{
    allocator: runtime.Allocator,
    arena_capacity: int,
    sub_allocations: int,
    seek: ^Arena(T),
    arenas: [dynamic]Arena(T),
}

collection_create_typed :: proc($T: typeid, arena_capacity, dynamic_reserve: int, allocator := context.allocator) -> (Collection(T), bool)
{
    if arena_capacity < 1
    {
        //TODO: log error
        return {}, false
    }

    arenas, arenas_allocation_error := make_dynamic_array_len_cap([dynamic]Arena(T), 1, max(1, dynamic_reserve), allocator)
    if arenas_allocation_error != .None
    {
        //TODO: log error
        return {}, false
    }

    initial_arena, created_initial_arena := arena_create_typed(T, arena_capacity, allocator)
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
    collection.seek = &arenas[0]
    collection.arenas = arenas
    return collection, true
}

collection_destroy_typed :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for i := 0; i < len(collection.arenas); i += 1 do arena_destroy_typed(&collection.arenas[i])
    delete(collection.arenas)
    collection^ = {}
    return true
}

collection_create_arena :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil
    {
        //TODO: log error
        return false
    }
    
    arena, created := arena_create_typed(T, collection.arena_capacity, collection.allocator)
    if !created
    {
        //TODO: log error
        return false
    }
    
    append(&collection.arenas, arena)
    return true
}

collection_destroy_arena :: proc(collection: ^Collection($T), index: int) -> bool
{
    if collection == nil
    {
        //TODO: log error
        return false
    }

    if index < 1
    {
        //TODO: log error
        return false
    }

    arena := &collection.arenas[index]
    if collection.seek == arena do collection.seek = &collection.arenas[0]
    arena_destroy_typed(arena, collection.allocator)
    unordered_remove(&collection.arenas, index)
    return true
}

collection_sub_allocate :: proc(collection: ^Collection($T)) -> ^T
{
    if collection == nil
    {
        //TODO: log error
        return nil
    }

    //Cache
    if data := arena_sub_allocate(collection.seek); data != nil
    {
        collection.sub_allocations += 1
        if arena_is_full(collection.seek) do collection.seek = collection_get_next_arena(collection, collection.seek)
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
            if arena_is_full(collection.seek) do collection.seek = collection_get_next_arena(collection, collection.seek)
            return data
        }
    }
    
    return nil
}

collection_free :: proc(collection: ^Collection($T), data: ^T)
{
    if collection == nil
    {
        //TODO: log error
        return
    }

    if data == nil
    {
        //TODO: log error
        return
    }

    for i := 0; i < len(collection.arenas); i += 1
    {
        arena := &collection.arenas[i]
        if !arena_is_in(arena, data) do continue
        
        arena_free(arena, data)
        collection.sub_allocations -= 1

        if arena.sub_allocations == 0
        {    
            collection_destroy_arena(collection, i)
            return
        }

        if cast(uintptr)arena < cast(uintptr)arena.seek do collection.seek = arena
        return
    }
}

collection_get_next_arena :: proc "contextless" (collection: ^Collection($T), seek: ^Arena(T)) -> ^Arena(T)
{
    last_index := max(0, len(collection.arenas) - 1)
    last := &collection.arenas[last_index]
    next := mem.ptr_offset(seek, 1)
    uptr_last := uintptr(last)
    uptr_next := uintptr(next)
    return cast(^Arena(T))min(uptr_next, uptr_last)
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