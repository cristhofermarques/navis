package commons

import "utility"
import "core:intrinsics"

Event :: struct($T: typeid) where intrinsics.type_is_proc(T)
{
    callbacks: [dynamic]T,
}

event_make :: proc($T: typeid, reserve_count: int, allocator := context.allocator) -> Event(T) where intrinsics.type_is_proc(T)
{
    callbacks := make([dynamic]T, 0, reserve_count, allocator)
    
    event: Event(T)
    event.callbacks = callbacks
    return event
}

event_delete :: proc(event: ^Event($T)) where intrinsics.type_is_proc(T)
{
    if event == nil || event.callbacks == nil do return
    delete(event.callbacks)
}

event_append :: proc(event: ^Event($T), callback: T) where intrinsics.type_is_proc(T)
{
    if event == nil || event.callbacks == nil || callback == nil do return
    if utility.dynamic_contains(event.callbacks, callback) do return
    append(&event.callbacks, callback)
}

event_remove :: proc(event: ^Event($T), callback: T) where intrinsics.type_is_proc(T)
{
    if event == nil || event.callbacks == nil || callback == nil do return

    if !utility.dynamic_contains(event.callbacks, callback) do return

    index, index_succ := utility.dynamic_index_of(event.callbacks, callback)
    if !index_succ do return

    unordered_remove(&event.callbacks, index)
}

/*
Event callbacks iterator
*/
event_iterator :: #force_inline proc(event: ^Event($T)) -> []T where intrinsics.type_is_proc(T)
{
    assert(event != nil)
    assert(event.callbacks != nil)
    return event.callbacks[0:]
}