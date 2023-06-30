package memory

import "core:runtime"
import "core:mem"

Arena :: struct($T: typeid)
{
    heads: [^]bool,
    slots: [^]T,

    slot_size: uint,
    capacity: uint,
    sub_allocations: uint,

    cache: struct
    {
        slots_begin, slots_end: rawptr,
        seek: uint,
    },

    memory: struct
    {
        data: rawptr,
        size: uint,
    },
}

arena_create :: proc($T: typeid, capacity: uint, allocator := context.allocator) -> (Arena(T), bool) #optional_ok
{
    if capacity < 1 do return {}, false

    heads_size := size_of(bool) * capacity
    slots_size := size_of(T) * capacity
    memory_size := heads_size + slots_size

    //Allocating
    memory_data := mem.alloc(cast(int)memory_size, mem.DEFAULT_ALIGNMENT, allocator)
    if memory_data == nil do return {}, false

    //Zero it
    mem.zero(memory_data, cast(int)memory_size)

    //Making arena
    arena: Arena(T)
    arena.heads = transmute([^]bool)memory_data
    arena.slots = transmute([^]T)&arena.heads[capacity]
    arena.slot_size = size_of(T)
    arena.capacity = capacity
    arena.cache.slots_begin = arena.slots
    arena.cache.slots_end = &arena.slots[capacity]
    arena.memory.data = memory_data
    arena.memory.size = memory_size
    return arena, true
}

arena_destroy :: proc(arena: ^Arena($T), allocator := context.allocator)
{
    if arena == nil do return
    mem.free(arena.memory.data, allocator)
    arena^ = {}
}

arena_clone :: proc(arena: ^Arena($T), allocator := context.allocator) -> (Arena(T), bool) #optional_ok
{
    if arena == nil do return {}, false
    return arena_create(T, arena.capacity, allocator)
}

arena_sub_allocate :: proc "contextless" (arena: ^Arena($T)) -> ^T
{
    //Full check
    if arena.sub_allocations == arena.capacity do return nil

    //Cache seek
    {
        seek := arena.cache.seek
        if !arena.heads[seek]
        {
            //Reserving slot head
            arena.heads[seek] = true
            
            //Getting slot
            slot := &arena.slots[seek]
            
            //Increamenting cache
            seek += 1
            arena.cache.seek = seek

            //Increamenting allocations
            arena.sub_allocations += 1
            
            return slot
        }
    }
    
    //Search
    {
        for seek: uint = 0; seek < arena.capacity; seek += 1
        {
            if !arena.heads[seek]
            {
                //Reserving slot head
                arena.heads[seek] = true
                
                //Getting slot
                slot := &arena.slots[seek]
                
                //Increamenting cache
                seek += 1
                arena.cache.seek = seek

                //Increamenting allocations
                arena.sub_allocations += 1
                
                return slot
            }
        }
    }

    //Failed
    return nil
}

arena_free :: proc "contextless" (arena: ^Arena($T), slot: ^T)
{
    //Getting index
    index, got_index := arena_get_slot_index(arena, slot)
    if !got_index do return

    //Not used check
    if !arena.heads[index] do return

    //Freeding slot head
    arena.heads[index] = false

    //Decrementing sub allocation count
    arena.sub_allocations -= 1

    //Cache seek check
    if index < arena.cache.seek do arena.cache.seek = index
}

arena_is_inside :: proc "contextless" (arena: ^Arena($T), slot: ^T) -> bool
{
    if arena == nil || slot == nil do return false
    return slot >= arena.cache.slots_begin && slot <= arena.cache.slots_end
}

arena_is_full :: proc "contextless" (arena: ^Arena($T)) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == arena.capacity
}

arena_is_empty :: proc "contextless" (arena: ^Arena($T)) -> bool
{
    if arena == nil do return false
    return arena.sub_allocations == 0
}

arena_get_slot_index :: proc "contextless" (arena: ^Arena($T), slot: ^T) -> (uint, bool)
{
    if arena == nil || slot == nil || !arena_is_inside(arena, slot) do return 0, false

    uptr_slot := cast(uintptr)slot
    uptr_begin := cast(uintptr)arena.slots
    begin_to_slot_size := uint(max(uptr_begin, uptr_slot) - min(uptr_begin, uptr_slot))
    index := begin_to_slot_size / arena.slot_size
    return index, true
}

arena_heads_as_slice :: proc "contextless" (arena: ^Arena($T)) -> []bool
{
    if arena == nil do return nil

    raw: runtime.Raw_Slice
    raw.data = arena.heads
    raw.len = cast(int)arena.capacity
    return transmute([]bool)raw
}

arena_as_slice :: proc "contextless" (arena: ^Arena($T)) -> []T
{
    if arena == nil do return nil

    raw: runtime.Raw_Slice
    raw.data = arena.slots
    raw.len = cast(int)arena.capacity
    return transmute([]T)raw
}