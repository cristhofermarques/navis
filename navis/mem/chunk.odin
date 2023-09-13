package navis_mem

import "core:mem"
import "core:runtime"
import "core:sync"

/*
Return slot size of provided type
*/
slot_size_of :: proc "contextless" ($T: typeid) -> int
{
    return size_of(Chunk_Slot(T))
}

/*
Return slot data offset of provided type
*/
slot_data_offset_of :: proc "contextless" ($T: typeid) -> uintptr
{
    return offset_of(Chunk_Slot(T), data)
}

Chunk_Slot :: struct($T: typeid)
{
    used: bool,
    data: T,
}

Chunk :: struct($T: typeid)
{
    seek: ^Chunk_Slot(T),
    sub_allocations: int,
    slots: []Chunk_Slot(T),
    mutex: sync.Atomic_Mutex,
}

chunk_create :: proc($T: typeid, capacity: int, allocator := context.allocator) -> (Chunk(T), bool) #optional_ok
{
    if capacity < 1 do return {}, false

    slots, slots_allocation_error := make([]Chunk_Slot(T), capacity, allocator)
    if slots_allocation_error != .None do return {}, false

    chunk: Chunk(T)
    chunk.seek = &slots[0]
    chunk.slots = slots
    return chunk, true
}

chunk_destroy :: proc(chunk: ^Chunk($T), allocator := context.allocator) -> bool
{
    if chunk == nil do return false
    delete(chunk.slots, allocator)
    chunk^ = {}
    return true
}

chunk_sub_allocate :: proc "contextless" (chunk: ^Chunk($T)) -> ^T
{
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    if chunk_is_full(chunk) do return nil
    
    //Cache
    if !chunk.seek.used
    {
        chunk.seek.used = true
        data := &chunk.seek.data
        chunk.sub_allocations += 1
        if !chunk_is_full(chunk) do chunk_seek_to_next(chunk)
        return data
    }

    //Search
    for i := 0; i < len(chunk.slots); i += 1
    {
        seek := &chunk.slots[i]
        if seek.used do continue
        seek.used = true
        data := &seek.data
        chunk.sub_allocations += 1
        chunk.seek = seek
        if !chunk_is_full(chunk) do chunk_seek_to_next(chunk)
        return data
    }

    return nil
}

chunk_free :: proc "contextless" (chunk: ^Chunk($T), data: ^T) -> bool
{
    if chunk == nil || data == nil do return false

    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    index := chunk_index_of(chunk, data)
    if index < 0 do return false

    slot := &chunk.slots[index]
    slot.used = false
    chunk.sub_allocations -= 1

    if slot < chunk.seek do chunk.seek = slot

    return true
}

@(private)
chunk_seek_to_next :: proc "contextless" (chunk: ^Chunk($T))
{
    last := chunk_get_last(chunk)
    uptr_last := transmute(uintptr)last
    uptr_seek := transmute(uintptr)chunk.seek
    next := uptr_seek + uintptr(size_of(Chunk_Slot(T)))
    chunk.seek = transmute(^Chunk_Slot(T))min(next, uptr_last)
}

chunk_is_empty :: proc "contextless" (chunk: ^Chunk($T)) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == 0
}

chunk_is_full :: proc "contextless" (chunk: ^Chunk($T)) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == len(chunk.slots)
}

chunk_has :: proc "contextless" (chunk: ^Chunk($T), data: ^T) -> bool
{
    if chunk == nil || data == nil do return false
    begin := &chunk.slots[0]
    end := mem.ptr_offset(begin, len(chunk.slots))

    uptr_data := uintptr(data)
    uptr_begin := uintptr(begin)
    uptr_end := uintptr(end)

    return uptr_data >= uptr_begin && uptr_data < uptr_end
}

chunk_get_last :: proc "contextless" (chunk: ^Chunk($T)) -> ^Chunk_Slot(T)
{
    uptr_begin := transmute(uintptr)raw_data(chunk.slots)
    return transmute(^Chunk_Slot(T))(uptr_begin + uintptr(max(0, len(chunk.slots) - 1) * size_of(Chunk_Slot(T))))
}

chunk_index_of :: proc "contextless" (chunk: ^Chunk($T), data: ^T) -> int
{
    if chunk == nil || data == nil do return -1
    uptr_begin := cast(uintptr)&chunk.slots[0]
    uptr_data := cast(uintptr)data - offset_of(Chunk_Slot(T), data)
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / size_of(Chunk_Slot(T))
}

Untyped_Chunk :: struct
{
    sub_allocations, slot_size: int,
    seek, slot_data_offset: uintptr,
    slots: runtime.Raw_Slice,
    mutex: sync.Atomic_Mutex,
}

untyped_chunk_create :: proc(slot_size: int, slot_data_offset: uintptr, capacity: int, allocator := context.allocator) -> (Untyped_Chunk, bool) #optional_ok
{
    if slot_size < 1 || slot_data_offset < 1 || capacity < 1 do return {}, false

    slots_data_size := slot_size * capacity
    slots_data, slots_data_allocation_error := mem.alloc(slots_data_size, allocator = allocator)
    if slots_data_allocation_error != .None do return {}, false

    chunk: Untyped_Chunk
    chunk.slots.data = slots_data
    chunk.slots.len = capacity
    chunk.slot_size = slot_size
    chunk.slot_data_offset = uintptr(slot_data_offset)
    chunk.seek = uintptr(slots_data)
    return chunk, true
}

untyped_chunk_destroy :: proc(chunk: ^Untyped_Chunk, allocator := context.allocator)
{
    if chunk == nil do return
    mem.free(chunk.slots.data, allocator)
    chunk^ = {}
}

untyped_chunk_sub_allocate :: proc "contextless" (chunk: ^Untyped_Chunk) -> rawptr
{
    if chunk == nil do return nil

    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    if untyped_chunk_is_full(chunk) do return nil
    uptr_slots_data := transmute(uintptr)chunk.slots.data
    uptr_slot_data_offset := chunk.slot_data_offset

    //Seek
    uptr_seek_slot_used := chunk.seek    
    seek_slot_used := transmute(^bool)uptr_seek_slot_used
    if !seek_slot_used^
    {
        seek_slot_used^ = true
        chunk.sub_allocations += 1
        if !untyped_chunk_is_full(chunk) do untyped_chunk_seek_to_next(chunk)
        return rawptr(uptr_seek_slot_used + uptr_slot_data_offset)
    }

    //Search
    for i := 0; i < chunk.slots.len; i += 1
    {
        uptr_curr_slot_used := uptr_slots_data + uintptr(chunk.slot_size * i)
        curr_slot_used := transmute(^bool)uptr_curr_slot_used
        if curr_slot_used^ do continue
        curr_slot_used^ = true
        chunk.sub_allocations += 1
        chunk.seek = uptr_curr_slot_used
        if !untyped_chunk_is_full(chunk) do untyped_chunk_seek_to_next(chunk)
        return rawptr(uptr_curr_slot_used + uptr_slot_data_offset)
    }

    return nil
}

untyped_chunk_free :: proc "contextless" (chunk: ^Untyped_Chunk, data: rawptr) -> bool
{
    if chunk == nil do return false
    
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    if !untyped_chunk_has(chunk, data) do return false
    index := untyped_chunk_index_of(chunk, data)
    if index < 0 do return false
    uptr_slot_used := uintptr(data) - chunk.slot_data_offset
    slot_used := transmute(^bool)uptr_slot_used
    if !slot_used^ do return false
    slot_used^ = false
    chunk.sub_allocations -= 1
    if uptr_slot_used < chunk.seek do chunk.seek = uptr_slot_used
    return true
}

@(private)
untyped_chunk_seek_to_next :: proc "contextless" (chunk: ^Untyped_Chunk)
{
    last := untyped_chunk_get_last(chunk)
    next := chunk.seek + uintptr(chunk.slot_size)
    chunk.seek = min(next, last)
}

untyped_chunk_is_empty :: proc "contextless" (chunk: ^Untyped_Chunk) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == 0
}

untyped_chunk_is_full :: proc "contextless" (chunk: ^Untyped_Chunk) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == chunk.slots.len
}

untyped_chunk_has :: proc "contextless" (chunk: ^Untyped_Chunk, data: rawptr) -> bool
{
    if chunk == nil || data == nil do return false
    uptr_data := transmute(uintptr)data
    uptr_begin := transmute(uintptr)chunk.slots.data
    uptr_end := uptr_begin + uintptr(chunk.slots.len * chunk.slot_size)
    return uptr_data >= uptr_begin && uptr_data < uptr_end
}

untyped_chunk_get_last :: proc "contextless" (chunk: ^Untyped_Chunk) -> uintptr
{
    uptr_begin := transmute(uintptr)chunk.slots.data
    return uptr_begin + uintptr(max(0, chunk.slots.len - 1)  * chunk.slot_size)
}

untyped_chunk_index_of :: proc "contextless" (chunk: ^Untyped_Chunk, data: rawptr) -> int
{
    if chunk == nil || data == nil do return -1
    uptr_begin := transmute(uintptr)chunk.slots.data
    uptr_data := transmute(uintptr)data - chunk.slot_data_offset
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / chunk.slot_size
}

untyped_chunk_as :: proc(chunk: ^Untyped_Chunk, $T: typeid) -> (Chunk(T), bool) #optional_ok
{
    if chunk == nil || chunk.slot_size != size_of(Chunk_Slot(T)) || chunk.slot_data_offset != offset_of(Chunk_Slot(T), data) do return {}, false
    typed: Chunk(T)
    typed.seek = transmute(^Chunk_Slot(T))chunk.seek
    typed.slots = transmute([]Chunk_Slot(T))chunk.slots
    typed.sub_allocations = chunk.sub_allocations
    return typed, true
}