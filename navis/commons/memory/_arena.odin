package memory

import "core:mem"

//create, destroy, sub_allocate, free

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