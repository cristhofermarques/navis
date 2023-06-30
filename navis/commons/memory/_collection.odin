package memory

import "core:runtime"

Collection :: struct($T: typeid)
{
    allocator: runtime.Allocator,

    arena_capacity: uint,
    sub_allocations: uint,

    cache: struct{
        seek: uint,
    },

    arenas: [dynamic]Arena(T),
}

collection_create :: proc($T: typeid, arena_capacity, reserve_count: uint, allocator := context.allocator) -> (Collection(T), bool) #optional_ok
{
    if arena_capacity < 1
    {
        return {}, false
    }

    if reserve_count < 1
    {
        return {}, false
    }
    
    arenas, arenas_alloc_err := make_dynamic_array_len_cap([dynamic]Arena(T), 0, reserve_count, allocator)
    if arenas_alloc_err != .None
    {
        return {}, false
    }
    
    arena, created_arena := arena_create(T, arena_capacity, allocator)
    if !created_arena
    {
        return {}, false
    }

    append(&arenas, arena)

    collection: Collection(T)
    collection.allocator = allocator
    collection.arenas = arenas
    collection.arena_capacity = arena_capacity
    return collection, true
}

collection_destroy :: proc(collection: ^Collection($T))
{
    if collection == nil do return

    for i := 0; i < len(collection.arenas); i += 1 do arena_destroy(&collection.arenas[i], collection.allocator)
    delete(collection.arenas)
}

collection_sub_allocate :: proc(collection: ^Collection($T)) -> ^T
{
    if collection == nil do return nil

    //Cache
    {
        seek := collection.cache.seek
        slot := arena_sub_allocate(&collection.arenas[seek])
        if slot != nil
        {
            //Increamenting sub allocations count
            collection.sub_allocations += 1
            
            //Setting seek
            if arena_is_full(&collection.arenas[seek]) do collection.cache.seek = min(seek + 1, cast(uint)len(collection.arenas) - 1)

            //Return slot
            return slot
        }
    }

    //Search
    {
        for seek: uint = 0; seek < len(collection.arenas); seek += 1
        {
            arena := &collection.arenas[seek]

            //Arena full check
            if arena_is_full(arena) do continue

            //Sub allocating
            slot := arena_sub_allocate(arena)
            if slot == nil do continue

            //Increamenting sub allocations count
            collection.sub_allocations += 1
            
            //Setting seek
            if arena_is_full(arena) do collection.cache.seek = min(seek + 1, cast(uint)len(collection.arenas) - 1)
            else do collection.cache.seek = seek

            //Return slot
            return slot
        }
    }

    //New arena
    {
        //Full collection check
        if !collection_is_full(collection) do return nil
        
        //Creating new arena
        created_arena := collection_new_arena(collection)
        if !created_arena do return nil
        
        for seek: uint = 0; seek < len(collection.arenas); seek += 1
        {
            arena := &collection.arenas[seek]

            //Arena full check
            if arena_is_full(arena) do continue

            //Sub allocating
            slot := arena_sub_allocate(arena)
            if slot == nil do continue

            //Increamenting sub allocations count
            collection.sub_allocations += 1
            
            //Setting seek
            if arena_is_full(arena) do collection.cache.seek = min(seek + 1, cast(uint)len(collection.arenas) - 1)
            else do collection.cache.seek = seek

            //Return slot
            return slot
        }
    }

    //Failed
    return nil
}

collection_free :: proc(collection: ^Collection($T), slot: ^T)
{
    if collection == nil || slot == nil do return

    remove_index := -1
    for i := 0; i < len(collection.arenas); i += 1
    {
        arena := &collection.arenas[i]
        if !arena_is_inside(arena, slot) do continue

        //Freeding slot
        arena_free(arena, slot)

        collection.sub_allocations -= 1

        //Empty arena check
        if arena_is_empty(arena) do remove_index = i

        break
    }

    if remove_index != -1 do collection_destroy_arena(collection, remove_index)
}

collection_is_full :: proc "contextless" (collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for i := 0; i < len(collection.arenas); i += 1
    {
        if !arena_is_full(&collection.arenas[i]) do return false
    }

    return true
}

collection_new_arena :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false

    arena, created := arena_create(T, collection.arena_capacity, collection.allocator)
    if !created do return false

    append(&collection.arenas, arena)
    return true
}

collection_destroy_arena :: proc(collection: ^Collection($T), index: int) -> bool
{
    if collection == nil || index < 0 || index >= len(collection.arenas) || len(collection.arenas) == 1 do return false

    //Destroying arena
    arena_destroy(&collection.arenas[index], collection.allocator)
    
    //Removing arena
    unordered_remove(&collection.arenas, index)

    //Success
    return true
}

//Cache
//Search
//New