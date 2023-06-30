package memory

import "core:runtime"

/*
Collection informations, Read-Only
*/
Collection_Info :: struct
{
    arena_data_size,
    arena_data_align,
    arena_slot_size,
    arena_slot_align,
    arena_capacity,
    allocations,
    seek: int,
}

/*
Collection
*/
Collection :: struct($T: typeid)
{
    __allocator: runtime.Allocator,
    info: Collection_Info,
    arenas: [dynamic]Arena(T),
}

/*
Create a Collection of provided type.

Parameters:
* arena_capacity - Max per arena slots.
* reserve_count - Reserve number when making arenas dynamic slice.
*/
collection_create_typed :: proc($T: typeid, arena_capacity, reserve_count: int, allocator := context.allocator) -> (Collection(T), bool) #optional_ok
{
    if arena_capacity < 1 || reserve_count < 0 do return {}, false

    //Populating info
    info: Collection_Info
    info.arena_data_size = size_of(T)
    info.arena_data_align = align_of(T)
    info.arena_slot_size = size_of(Arena_Slot(T))
    info.arena_slot_align = align_of(Arena_Slot(T))
    info.arena_capacity = arena_capacity

    //Allocating Arena dynamic slice
    arenas, alloc_err := make([dynamic]Arena(T), 1, reserve_count, allocator)
    if alloc_err != .None do return {}, false

    arena, created := arena_create_typed(T, arena_capacity, allocator)
    if !created
    {
        delete(arenas)
        return {}, false
    }

    arenas[0] = arena

    //Populating Collection
    collection: Collection(T)
    collection.__allocator = allocator
    collection.info = info
    collection.arenas = arenas
    return collection, true
}

/*
Destroys a typed Collection.
*/
collection_destroy_typed :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false

    allocator := collection.__allocator

    arenas := collection.arenas
    for arena, index in arenas do arena_destroy_typed(&arenas[index])
    delete(arenas)
    return true
}

/*
Creates a new Arena for provided Collection.
*/
collection_create_arena :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false

    allocator := collection.__allocator
    capacity := collection.info.arena_capacity
    arena, success := arena_create_typed(T, capacity, allocator)
    if !success do return false

    append(&collection.arenas, arena)
    return true
}

/*
Destroys an Arena at specified index.
*/
collection_destroy_arena :: proc(collection: ^Collection($T), index: int) -> bool
{
    if collection == nil do return false

    arenas_len := len(collection.arenas)
    if index < 0 || index > arenas_len || arenas_len <= 1 do return false
    
    arena := &collection.arenas[index]
    destroyed := arena_destroy_typed(arena)
    if !destroyed do return false

    unordered_remove(&collection.arenas, index)
    return true
}

/*
Try to sub allocate.
*/
collection_allocate_typed :: proc(collection: ^Collection($T)) -> ^T
{
    if collection == nil do return nil

    //Seek hit
    seek_hit_data := collection_allocate_typed_seek_hit(collection)
    if seek_hit_data != nil do return seek_hit_data

    return collection_allocate_typed_search(collection)
}

/*
Perform a check at seek index.

If we can allocate, its a kind of 'seek hit'.

Its faster than search for a not used slot.
*/
@(private)
collection_allocate_typed_seek_hit :: #force_inline proc (collection: ^Collection($T)) -> ^T
{
    seek := collection.info.seek
    arenas_len := len(collection.arenas)
    if arenas_len == 0 do return nil

    //Invalid seek
    if seek < 0 || seek > arenas_len do return nil
    
    //Arena pointer
    arena := &collection.arenas[seek]

    //Full Arena
    arena_full := arena.info.used_count == arena.info.capacity
    if arena_full do return nil

    //Sub Allocation
    data := arena_sub_allocate(arena)
    if data == nil do return nil

    //Success
    collection.info.allocations += 1
    return data
}

/*
Perform iteration through arenas, its slow.
*/
@(private)
collection_allocate_typed_search :: #force_inline proc(collection: ^Collection($T)) -> ^T
{
    arenas_len := len(collection.arenas)

    for i := 0; i < arenas_len; i += 1
    {
        //Arena pointer
        arena := &collection.arenas[i]

        //Full Arena
        arena_full := arena.info.used_count == arena.info.capacity
        if arena_full do continue

        //Sub Allocation
        data := arena_sub_allocate(arena)
        if data == nil do continue

        //Success
        collection.info.allocations += 1
        collection.info.seek = i
        return data
    }

    //Create new arena
    created := collection_create_arena(collection)
    if !created do return nil

    //Allocation
    last_index := max(0, len(collection.arenas) - 1)
    arena := &collection.arenas[last_index]
    data := arena_sub_allocate(arena)
    if data == nil do return nil

    //Success
    collection.info.allocations += 1
    return data
}

/*
Try to free a type pointer, its Slow.

It interates through arenas to know the type pointer owner.
*/
collection_free_typed :: proc(collection: ^Collection($T), data: ^T) -> bool
{
    if collection == nil || data == nil do return false

    arenas_len := len(collection.arenas)
    for i := 0; i < arenas_len; i += 1
    {
        //Arena pointer
        arena := &collection.arenas[i]

        //does Arena own data address
        own := arena_is_address_in(arena, data)
        if !own do continue

        //Bye, just fly, be Free.
        freed := arena_sub_free(arena, data)
        if !freed do return false

        //Success
        collection.info.allocations -= 1

        is_empty := arena.info.used_count == 0
        if is_empty do collection_destroy_arena(collection, i)

        if i < collection.info.seek do collection.info.seek = i
        return true
    }

    //Fail
    return false
}