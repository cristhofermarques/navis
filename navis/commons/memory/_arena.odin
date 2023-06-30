package memory

import "core:runtime"
import "core:mem"

/*Some infos about Arena*/
Arena_Info :: struct
{
    data_size,
    data_align,
    slot_size,
    slot_align,
    capacity,
    used_count,
    seek: int,
}

/*4 bytes Boolean and data of any type, struct used for an easy interpretation*/
Arena_Slot :: struct($T: typeid)
{
    used: b32,
    data: T,
}

/*Same as Arena, but without interpretation type, Its like an 'Any' for any Arena*/
Arena_Untyped :: struct
{
    __allocator: runtime.Allocator,
    info: Arena_Info,
    slots: runtime.Raw_Slice,
}

/*Arena with interpretation type*/
Arena :: struct($T: typeid)
{
    __allocator: runtime.Allocator,
    info: Arena_Info,
    slots: []Arena_Slot(T),
}

/*
Creates an untyped Arena.

Parameters Setting:

    data_size = size_of(MyType)
    data_align = align_of(MyType)
    slot_align = size_of(Arena_Slot(MyType))
    slot_align = align_of(Arena_Slot(MyType))

*/
arena_create_untyped :: proc(data_size, data_align, slot_size, slot_align, capacity: int, allocator := context.allocator, location := #caller_location) -> (Arena_Untyped, bool) #optional_ok
{
    if data_size < 1 || data_align < 1 || slot_align < 1 || capacity < 1 do return {}, false
    
    slots_size := slot_size * capacity

    slots_data := mem.alloc(slots_size, slot_align, allocator, location)
    if slots_data == nil do return {}, false
    mem.zero(slots_data, slots_size)

    arena: Arena_Untyped
    arena.__allocator = allocator
    arena.info.data_size = data_size
    arena.info.data_align = data_align
    arena.info.slot_size = slot_size
    arena.info.slot_align = slot_align
    arena.info.capacity = capacity
    arena.slots.data = slots_data
    arena.slots.len = capacity
    return arena, true
}

/*Destroys an untyped Arena*/
arena_destroy_untyped :: proc(arena: ^Arena_Untyped, location := #caller_location) -> bool
{
    if arena == nil do return false
    allocator := arena.__allocator
    success := mem.free(arena.slots.data, allocator, location) == .None
    return success
}

/*Creates an Arena*/
arena_create_typed :: proc($T: typeid, capacity: int, allocator := context.allocator) -> (Arena(T), bool) #optional_ok
{
    if capacity == 0 do return {}, false

    data_size := size_of(T)
    data_align := align_of(T)
    slot_size := size_of(Arena_Slot(T))
    slot_align := align_of(Arena_Slot(T))
    slots, alloc_err := make([]Arena_Slot(T), capacity, allocator)
    if alloc_err != .None do return {}, false

    arena: Arena(T)
    arena.__allocator = allocator
    arena.info.data_size = data_size
    arena.info.data_align = data_align
    arena.info.slot_size = slot_size
    arena.info.slot_align = slot_align
    arena.info.capacity = capacity
    arena.slots = slots
    return arena, true
}

/*Destroys an Arena*/
arena_destroy_typed :: proc(arena: ^Arena($T)) -> bool
{
    if arena == nil do return false
    allocator := arena.__allocator
    success := delete(arena.slots, allocator) == .None
    return success
}

/*Transmute Typed Arena to an Untyped Arena.*/
arena_as_untyped :: #force_inline proc "contextless" (arena: ^Arena($T)) -> ^Arena_Untyped
{
    return transmute(^Arena_Untyped)arena
}

/*
Try transmute Untyped Arena to some type.

Returns a pointer to transmuted type and success boolean.

* Type need to have same size and align of Arena.
*/
arena_untyped_as :: #force_inline proc "contextless" ($T: typeid, arena: ^Arena_Untyped) -> (^Arena(T), bool) #optional_ok
{
    if arena == nil do return nil, false

    same_size := size_of(T) == arena.info.data_size
    same_align := align_of(T) == arena.info.data_align
    support := same_size && same_align
    if !support do return nil, false

    return transmute(^Arena(T))arena, true
}

arena_sub_allocate :: proc "contextless" (arena: ^Arena($T)) -> ^T
{
    //Nil Arena check
    if arena == nil do return nil

    //Full Arena check
    if arena.info.used_count == arena.info.capacity do return nil

    //Seek hit check, fast
    seek := arena.info.seek
    capacity := arena.info.capacity
    if seek < capacity
    {
        slot := &arena.slots[seek]
        if !slot.used
        {   
            arena.info.seek = seek + 1
            
            slot.used = true
            data: ^T  = &slot.data
            arena.info.used_count += 1
            return data
        }
    }

    //Search check, slow
    for search := 0; search < capacity; search += 1
    {
        slot := &arena.slots[search]
        if slot.used do continue

        if arena.info.seek >= search do arena.info.seek = search + 1

        slot.used = true
        data: ^T  = &slot.data
        arena.info.used_count += 1
        return data
    }

    return nil
}

arena_sub_free :: proc "contextless" (arena: ^Arena($T), data: ^T) -> bool
{
    if arena == nil do return false

    index, index_succ := arena_address_index(arena, data)
    if !index_succ do return false

    slot := &arena.slots[index]
    if !slot.used || &slot.data != data do return false

    slot.used = false
    arena.info.used_count -= 1

    if index < arena.info.seek do arena.info.seek = index
    return true
}

arena_begin_address :: #force_inline proc "contextless" (arena: ^Arena($T)) -> rawptr
{
    if arena == nil do return nil

    address := &arena.slots[0]
    return address
}

arena_end_address :: #force_inline proc "contextless" (arena: ^Arena($T)) -> rawptr
{
    if arena == nil do return nil

    last_index := max(0, arena.info.capacity - 1)
    last_slot_address := uintptr(&arena.slots[last_index])

    address := last_slot_address + uintptr(arena.info.slot_size)
    return rawptr(address)
}

arena_is_address_in :: #force_inline proc "contextless" (arena: ^Arena($T), address: rawptr) -> bool
{
    if arena == nil || address == nil do return false

    begin := arena_begin_address(arena)
    end := arena_end_address(arena)
    is_in := address >= begin && address <= end
    return is_in
}

arena_size_of_slots :: #force_inline proc "contextless" (arena: ^Arena($T)) -> int
{
    if arena == nil do return 0
    begin := arena_begin_address(arena)
    end := arena_end_address(arena)
    uptr_begin := uintptr(begin)
    uptr_end := uintptr(end)
    diff := uptr_end - uptr_begin
    size := diff
    return size
}

arena_address_index :: proc "contextless" (arena: ^Arena($T), address: rawptr) -> (int, bool) #optional_ok
{
    if arena == nil || !arena_is_address_in(arena, address) do return -1, false

    begin := arena_begin_address(arena)
    uptr_begin := uintptr(begin)
    uptr_addr := uintptr(address)
    diff := uptr_addr - uptr_begin
    size := int(diff)
    index := size / int(arena.info.slot_size)
    return index, index < int(arena.info.capacity)
}

arena_create :: proc{
    arena_create_typed,
    arena_create_untyped,
}

arena_destroy :: proc{
    arena_destroy_typed,
    arena_destroy_untyped,
}