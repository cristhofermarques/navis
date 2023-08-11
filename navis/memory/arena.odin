package memory

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

Arena :: struct($T: typeid)
{
    seek: ^Arena_Slot(T),
    sub_allocations: int,
    slots: []Arena_Slot(T),
    mutex: sync.Atomic_Mutex,
}

arena_create :: proc($T: typeid, capacity: int, allocator := context.allocator) -> (Arena(T), bool) #optional_ok
{
    if capacity < 1 do return {}, false

    slots, slots_allocation_error := make([]Arena_Slot(T), capacity, allocator)
    if slots_allocation_error != .None do return {}, false

    arena: Arena(T)
    arena.seek = &slots[0]
    arena.slots = slots
    return arena, true
}

arena_destroy :: proc(arena: ^Arena($T), allocator := context.allocator) -> bool
{
    if arena == nil do return false
    delete(arena.slots, allocator)
    arena^ = {}
    return true
}

arena_sub_allocate :: proc "contextless" (arena: ^Arena($T)) -> ^T
{
    sync.atomic_mutex_lock(&arena.mutex)
    defer sync.atomic_mutex_unlock(&arena.mutex)

    if arena_is_full(arena) do return nil
    
    //Cache
    if !arena.seek.used
    {
        arena.seek.used = true
        data := &arena.seek.data
        arena.sub_allocations += 1
        if !arena_is_full(arena) do arena_seek_to_next(arena)
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
        if !arena_is_full(arena) do arena_seek_to_next(arena)
        return data
    }

    return nil
}

arena_free :: proc "contextless" (arena: ^Arena($T), data: ^T) -> bool
{
    if arena == nil || data == nil do return false

    sync.atomic_mutex_lock(&arena.mutex)
    defer sync.atomic_mutex_unlock(&arena.mutex)

    index := arena_index_of(arena, data)
    if index < 0 do return false

    slot := &arena.slots[index]
    slot.used = false
    arena.sub_allocations -= 1

    if slot < arena.seek do arena.seek = slot

    return true
}

@(private)
arena_seek_to_next :: proc "contextless" (arena: ^Arena($T))
{
    last := arena_get_last(arena)
    uptr_last := transmute(uintptr)last
    uptr_seek := transmute(uintptr)arena.seek
    next := uptr_seek + uintptr(size_of(Arena_Slot(T)))
    arena.seek = transmute(^Arena_Slot(T))min(next, uptr_last)
}

arena_is_empty :: proc "contextless" (arena: ^Arena($T)) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == 0
}

arena_is_full :: proc "contextless" (arena: ^Arena($T)) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == len(arena.slots)
}

arena_has :: proc "contextless" (arena: ^Arena($T), data: ^T) -> bool
{
    if arena == nil || data == nil do return false
    begin := &arena.slots[0]
    end := mem.ptr_offset(begin, len(arena.slots))

    uptr_data := uintptr(data)
    uptr_begin := uintptr(begin)
    uptr_end := uintptr(end)

    return uptr_data >= uptr_begin && uptr_data < uptr_end
}

arena_get_last :: proc "contextless" (arena: ^Arena($T)) -> ^Arena_Slot(T)
{
    uptr_begin := transmute(uintptr)raw_data(arena.slots)
    return transmute(^Arena_Slot(T))(uptr_begin + uintptr(max(0, len(arena.slots) - 1) * size_of(Arena_Slot(T))))
}

arena_index_of :: proc "contextless" (arena: ^Arena($T), data: ^T) -> int
{
    if arena == nil || data == nil do return -1
    uptr_begin := cast(uintptr)&arena.slots[0]
    uptr_data := cast(uintptr)data - offset_of(Arena_Slot(T), data)
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / size_of(Arena_Slot(T))
}

Untyped_Arena :: struct
{
    sub_allocations, slot_size: int,
    seek, slot_data_offset: uintptr,
    slots: runtime.Raw_Slice,
    mutex: sync.Atomic_Mutex,
}

untyped_arena_create :: proc(slot_size: int, slot_data_offset: uintptr, capacity: int, allocator := context.allocator) -> (Untyped_Arena, bool) #optional_ok
{
    if slot_size < 1 || slot_data_offset < 1 || capacity < 1 do return {}, false

    slots_data_size := slot_size * capacity
    slots_data, slots_data_allocation_error := mem.alloc(slots_data_size, allocator = allocator)
    if slots_data_allocation_error != .None do return {}, false

    arena: Untyped_Arena
    arena.slots.data = slots_data
    arena.slots.len = capacity
    arena.slot_size = slot_size
    arena.slot_data_offset = uintptr(slot_data_offset)
    arena.seek = uintptr(slots_data)
    return arena, true
}

untyped_arena_destroy :: proc(arena: ^Untyped_Arena, allocator := context.allocator)
{
    if arena == nil do return
    mem.free(arena.slots.data, allocator)
    arena^ = {}
}

untyped_arena_sub_allocate :: proc "contextless" (arena: ^Untyped_Arena) -> rawptr
{
    if arena == nil do return nil

    sync.atomic_mutex_lock(&arena.mutex)
    defer sync.atomic_mutex_unlock(&arena.mutex)

    if untyped_arena_is_full(arena) do return nil
    uptr_slots_data := transmute(uintptr)arena.slots.data
    uptr_slot_data_offset := arena.slot_data_offset

    //Seek
    uptr_seek_slot_used := arena.seek    
    seek_slot_used := transmute(^bool)uptr_seek_slot_used
    if !seek_slot_used^
    {
        seek_slot_used^ = true
        arena.sub_allocations += 1
        if !untyped_arena_is_full(arena) do untyped_arena_seek_to_next(arena)
        return rawptr(uptr_seek_slot_used + uptr_slot_data_offset)
    }

    //Search
    for i := 0; i < arena.slots.len; i += 1
    {
        uptr_curr_slot_used := uptr_slots_data + uintptr(arena.slot_size * i)
        curr_slot_used := transmute(^bool)uptr_curr_slot_used
        if curr_slot_used^ do continue
        curr_slot_used^ = true
        arena.sub_allocations += 1
        arena.seek = uptr_curr_slot_used
        if !untyped_arena_is_full(arena) do untyped_arena_seek_to_next(arena)
        return rawptr(uptr_curr_slot_used + uptr_slot_data_offset)
    }

    return nil
}

untyped_arena_free :: proc "contextless" (arena: ^Untyped_Arena, data: rawptr) -> bool
{
    if arena == nil do return false
    
    sync.atomic_mutex_lock(&arena.mutex)
    defer sync.atomic_mutex_unlock(&arena.mutex)

    if !untyped_arena_has(arena, data) do return false
    index := untyped_arena_index_of(arena, data)
    if index < 0 do return false
    uptr_slot_used := uintptr(data) - arena.slot_data_offset
    slot_used := transmute(^bool)uptr_slot_used
    if !slot_used^ do return false
    slot_used^ = false
    arena.sub_allocations -= 1
    if uptr_slot_used < arena.seek do arena.seek = uptr_slot_used
    return true
}

@(private)
untyped_arena_seek_to_next :: proc "contextless" (arena: ^Untyped_Arena)
{
    last := untyped_arena_get_last(arena)
    next := arena.seek + uintptr(arena.slot_size)
    arena.seek = min(next, last)
}

untyped_arena_is_empty :: proc "contextless" (arena: ^Untyped_Arena) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == 0
}

untyped_arena_is_full :: proc "contextless" (arena: ^Untyped_Arena) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == arena.slots.len
}

untyped_arena_has :: proc "contextless" (arena: ^Untyped_Arena, data: rawptr) -> bool
{
    if arena == nil || data == nil do return false
    uptr_data := transmute(uintptr)data
    uptr_begin := transmute(uintptr)arena.slots.data
    uptr_end := uptr_begin + uintptr(arena.slots.len * arena.slot_size)
    return uptr_data >= uptr_begin && uptr_data < uptr_end
}

untyped_arena_get_last :: proc "contextless" (arena: ^Untyped_Arena) -> uintptr
{
    uptr_begin := transmute(uintptr)arena.slots.data
    return uptr_begin + uintptr(max(0, arena.slots.len - 1)  * arena.slot_size)
}

untyped_arena_index_of :: proc "contextless" (arena: ^Untyped_Arena, data: rawptr) -> int
{
    if arena == nil || data == nil do return -1
    uptr_begin := transmute(uintptr)arena.slots.data
    uptr_data := transmute(uintptr)data - arena.slot_data_offset
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / arena.slot_size
}

untyped_arena_as :: proc(arena: ^Untyped_Arena, $T: typeid) -> (Arena(T), bool) #optional_ok
{
    if arena == nil || arena.slot_size != size_of(Arena_Slot(T)) || arena.slot_data_offset != offset_of(Arena_Slot(T), data) do return {}, false
    typed: Arena(T)
    typed.seek = transmute(^Arena_Slot(T))arena.seek
    typed.slots = transmute([]Arena_Slot(T))arena.slots
    typed.sub_allocations = arena.sub_allocations
    return typed, true
}