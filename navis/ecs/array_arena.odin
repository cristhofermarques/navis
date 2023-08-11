package ecs

import "core:mem"
import "core:runtime"
import "core:sync"

/*
Return slot size of provided type
*/
slot_size_of :: proc "contextless" ($T: typeid) -> int
{
    return size_of(Arena_Slot(T))
}

/*
Return slot data offset of provided type
*/
slot_data_offset_of :: proc "contextless" ($T: typeid) -> uintptr
{
    return offset_of(Arena_Slot(T), data)
}

Arena_Slot :: struct($T: typeid)
{
    used: bool,
    data: T,
}


Array_Arena :: struct($Type: typeid, $Capacity: int)
{
    mutex: sync.Atomic_Mutex,
    seek, sub_allocations: int,
    slots: [Capacity]Arena_Slot(Type),
}

array_arena_sub_allocate :: proc "contextless" (arena: ^Array_Arena($Type, $Capacity)) -> ^Type
{
    if arena == nil do return nil

    sync.atomic_mutex_lock(&arena.mutex)
    defer sync.atomic_mutex_unlock(&arena.mutex)

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
    if arena == nil || data == nil do return false

    sync.atomic_mutex_lock(&arena.mutex)
    defer sync.atomic_mutex_unlock(&arena.mutex)

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
    return int(begin_to_data_size) / size_of(Arena_Slot(Type))
}