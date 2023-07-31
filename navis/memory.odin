package navis

import "core:mem"
import "core:runtime"

Arena_Slot :: struct($T: typeid)
{
    used: bool,
    data: T,
}

Arena :: struct($T: typeid)
{
    seek: ^Arena_Slot(T),
    sub_allocations: int,
    slots: []Arena_Slot(T),
}

Untyped_Arena :: struct
{
    seek, sub_allocations, slot_size, slot_data_offset: int,
    slots: runtime.Raw_Slice,
}

arena_create_typed :: proc($T: typeid, capacity: int, allocator := context.allocator) -> (Arena(T), bool) #optional_ok
{
    if capacity < 1 do return {}, false

    slots, slots_allocation_error := make([]Arena_Slot(T), capacity, allocator)
    if slots_allocation_error != .None do return {}, false

    arena: Arena(T)
    arena.seek = &slots[0]
    arena.slots = slots
    return arena, true
}

untyped_arena_of :: proc "contextless" ($T: typeid) -> (int, int)
{
    return size_of(Arena_Slot(T)), cast(int)offset_of(Arena_Slot(T), data)
}

arena_create_untyped :: proc(slot_size, slot_data_offset, capacity: int, allocator := context.allocator) -> (Untyped_Arena, bool) #optional_ok
{
    if slot_size < 1 || slot_data_offset < 1 || capacity < 1 do return {}, false
    slots_data_size := slot_size * capacity
    slots_data, slots_data_allocation_error := mem.alloc(slots_data_size, allocator = allocator)
    if slots_data_allocation_error != .None do return {}, false
    arena: Untyped_Arena
    arena.slots.data = slots_data
    arena.slots.len = capacity
    arena.slot_size = slot_size
    arena.slot_data_offset = slot_data_offset
    arena.seek = 0
    return arena, true
}

arena_destroy_untyped :: proc(arena: ^Untyped_Arena, allocator := context.allocator)
{
    if arena == nil do return
    mem.free(arena.slots.data, allocator)
    arena^ = {}
}

arena_clone_typed :: proc(arena: ^Arena($T), allocator := context.allocator) -> (Arena(T), bool) #optional_ok
{
    if arena == nil do return {}, false
    return arena_create_typed(T, len(arena.slots), allocator)
}

arena_destroy_typed :: proc(arena: ^Arena($T), allocator := context.allocator) -> bool
{
    if arena == nil do return false
    delete(arena.slots, allocator)
    arena^ = {}
    return true
}

arena_sub_allocate :: proc "contextless" (arena: ^Arena($T)) -> ^T
{
    if arena_is_full(arena) do return nil
    
    //Cache
    if !arena.seek.used
    {
        arena.seek.used = true
        data := &arena.seek.data
        arena.sub_allocations += 1
        if !arena_is_full(arena) do arena.seek = mem.ptr_offset(arena.seek, 1)
        return data
    }

    //Search
    for i := 0; i < len(arena.slots); i += 1
    {
        seek := &arena.slots[i]
        if seek.used do continue
        seek.used = true
        data := &seek.data
        arena.sub_allocations += 1
        arena.seek = seek
        if !arena_is_full(arena) do arena.seek = mem.ptr_offset(arena.seek, 1)
        return data
    }

    return nil
}

arena_free :: proc "contextless" (arena: ^Arena($T), data: ^T) -> bool
{
    index := arena_index_of(arena, data)
    if index < 0 do return false

    slot := &arena.slots[index]
    slot.used = false
    arena.sub_allocations -= 1

    if slot < arena.seek do arena.seek = slot

    return true
}

arena_is_full :: proc "contextless" (arena: ^Arena($T)) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == len(arena.slots)
}

arena_is_in :: proc "contextless" (arena: ^Arena($T), data: ^T) -> bool
{
    if arena == nil || data == nil do return false
    begin := &arena.slots[0]
    end := mem.ptr_offset(begin, len(arena.slots))

    uptr_data := uintptr(data)
    uptr_begin := uintptr(begin)
    uptr_end := uintptr(end)

    return uptr_data >= uptr_begin || uptr_data < uptr_end
}

arena_index_of :: proc "contextless" (arena: ^Arena($T), data: ^T) -> int
{
    if arena == nil || data == nil do return -1
    uptr_begin := cast(uintptr)&arena.slots[0]
    uptr_data := cast(uintptr)data
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / size_of(Arena_Slot(T))
}

arena_create ::  proc{
    arena_create_typed,
}

arena_destroy ::  proc{
    arena_destroy_typed,
}

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

Array_Arena :: struct($Type: typeid, $Capacity: int)
{
    seek, sub_allocations: int,
    slots: [Capacity]Arena_Slot(Type),
}

array_arena_sub_allocate :: proc "contextless" (arena: ^Array_Arena($Type, $Capacity)) -> ^Type
{
    if array_arena_is_full(arena) do return nil
    
    //Cache
    if seek := &arena.slots[arena.seek]; !seek.used
    {
        seek.used = true
        data := &seek.data
        arena.sub_allocations += 1
        if !array_arena_is_full(arena) do arena.seek += 1
        return data
    }

    //Search
    for i := 0; i < len(arena.slots); i += 1
    {
        seek := &arena.slots[i]
        if seek.used do continue
        seek.used = true
        data := &seek.data
        arena.sub_allocations += 1
        arena.seek = i
        if !array_arena_is_full(arena) do arena.seek += 1
        return data
    }
    return nil
}

array_arena_free :: proc "contextless" (arena: ^Array_Arena($Type, $Capacity), data: ^Type) -> bool
{
    index := array_arena_index_of(arena, data)
    if index < 0 do return false

    slot := &arena.slots[index]
    slot.used = false
    arena.sub_allocations -= 1
    if index < arena.seek do arena.seek = index
    return true
}

array_arena_is_full :: proc "contextless" (arena: ^Array_Arena($Type, $Capacity)) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == len(arena.slots)
}

array_arena_is_in :: proc "contextless" (arena: ^Array_Arena($Type, $Capacity), data: ^Type) -> bool
{
    if arena == nil || data == nil do return false
    begin := &arena.slots[0]
    end := mem.ptr_offset(begin, len(arena.slots))

    uptr_data := uintptr(data)
    uptr_begin := uintptr(begin)
    uptr_end := uintptr(end)

    return uptr_data >= uptr_begin || uptr_data < uptr_end
}

array_arena_index_of :: proc "contextless" (arena: ^Array_Arena($Type, $Capacity), data: ^Type) -> int
{
    if arena == nil || data == nil do return -1
    uptr_begin := cast(uintptr)&arena.slots[0]
    uptr_data := cast(uintptr)data
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / size_of(Arena_Slot(T))
}