package navis

import "core:intrinsics"
import "core:runtime"

/*
Checks if slice is nil or empty.
* Return false if slice is nil or empty
*/
slice_is_nil_or_empty :: proc "contextless" (slice: []$T) -> bool
{
    //Nil check
    if slice == nil do return true

    //Empty check
    if len(slice) == 0 do return true

    //Not nil or empty
    return false
}

/*
Return array length if it is not nil, else return 0.
* Works for any array type (array, slice, dynamic).
*/
array_try_len :: #force_inline proc "contextless" (array: $T) -> (int, bool) where intrinsics.type_is_array(T) || intrinsics.type_is_slice(T) || intrinsics.type_is_dynamic_array(T) #optional_ok
{
    if array == nil do return 0, false
    else do return len(array), true
}

/*
Return slice as pointer if its not nil, else return nil.
*/
slice_try_as_pointer :: proc "contextless" (array: $Array/[]$Type) -> (^Type, bool) #optional_ok
{
    //Nil array parameter
    if array == nil do return nil, false
    
    //Nil raw slice data
    raw := transmute(runtime.Raw_Slice)array
    if raw.data == nil do return nil, false
    
    //Return data
    return cast(^Type)raw.data, true
}

/*
Return dynamic slice as pointer if its not nil, else return nil.
*/
dynamic_try_as_pointer :: proc "contextless" (array: $Array/[dynamic]$Type) -> (^Type, bool) #optional_ok
{
    //Nil array parameter
    if array == nil do return nil, false
    
    //Nil raw slice data
    raw := transmute(runtime.Raw_Dynamic_Array)array
    if raw.data == nil do return nil, false
    
    //Return data
    return cast(^Type)raw.data, true
}

/*
Try to return address of slice or dynamic slice
*/
array_try_as_pointer :: proc{
    slice_try_as_pointer,
    dynamic_try_as_pointer,
}

/*
Return true if slice contains provided element.
* Use '==' operator.
*/
slice_contains :: #force_inline proc(slice: []$T, element: T) -> bool
{
    if slice == nil do return false
    for element_ in slice do if element_ == element do return true
    return false
}

/*
Return dynamic slice as array.
*/
dynamic_iterator :: #force_inline proc "contextless" (s: ^[dynamic]$T) -> []T
{
    if s == nil do return nil
    return s[0:]
}

/*
Return true if dynamic slice contains provided element.
* Use '==' operator.
*/
dynamic_contains :: #force_inline proc(slice: [dynamic]$T, element: T) -> bool
{
    if slice == nil do return false
    for element_ in slice do if element_ == element do return true
    return false
}

/*
Check if an array contains provided element.
*/
array_contains :: proc{
    slice_contains,
    dynamic_contains,
}

/*
Create slice from dynamic slice, no content cloning.
*/
slice_from_dynamic :: proc(dynamic_slice: [dynamic]$T, allocator := context.allocator) -> ([]T, bool) #optional_ok
{
    if dynamic_slice == nil do return nil, false

    slice_len := len(dynamic_slice)
    if slice_len < 1 do return nil, false

    slice, alloc_err := make([]T, slice_len, allocator)
    if alloc_err != .None do return nil, false
    
    for element, index in dynamic_slice do slice[index] = element
    return slice, true
}

/*
Creates an dynamic slice from an slice.
*/
dynamic_from_slice :: proc(slice: []$T, allocator := context.allocator) -> ([dynamic]T, bool) #optional_ok
{
    if slice == nil do return nil, false

    slice_len := len(slice)
    dyn_slice, alloc_err := make_dynamic_array_len_cap([dynamic]T, 0, slice_len, allocator)
    if alloc_err != .None do return nil, false

    dynamic_append_slice(&dyn_slice, slice)
    return dyn_slice, true
}

/*
Append slice elements to dynamic slice.
*/
dynamic_append_slice :: #force_inline proc(dyn_slice: ^[dynamic]$T, slice: []T)
{
    if dyn_slice == nil || slice == nil do return
    for element in slice do append(dyn_slice, element)
}

/*
Append slice elements to dynamic slice.
*/
slice_clone :: proc(slice: []$T, allocator := context.allocator) -> ([]T, bool) #optional_ok
{
    if slice == nil do return nil, false

    slice_len := len(slice)
    if slice_len < 1 do return nil, false

    clone, alloc_err := make([]T, slice_len, allocator)
    if alloc_err != .None do return nil, false

    for e, i in slice do clone[i] = e
    return clone, true
}

array_clone :: proc{
    slice_clone,
}

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
    if log_dynamic_contains(event.callbacks, callback) do return
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

/*
Checks if a cstring is nil or empty.
* Returns false if its not nil and empty.
*/
cstring_is_nil_or_empty_single :: proc "contextless" (cstr: cstring) -> bool
{
    //Nil check
    raw_cstr := transmute(runtime.Raw_Cstring)cstr
    if raw_cstr.data == nil do return true
    
    //Empty check
    EMPTY :: ""
    if cstr == EMPTY do return true

    //Not nil or empty
    return false
}

/*
Checks if a slice of cstring is nil or empty.
* Returns false if any cstring is not nil and empty.
*/
cstring_is_nil_or_empty_multiple :: proc "contextless" (cstrs: []cstring) -> bool
{
    //Slice Nil check
    if slice_is_nil_or_empty(cstrs) do return true
    
    //Cstring not nil or empty check
    for cstr in cstrs do if !cstring_is_nil_or_empty_single(cstr) do return false

    //All nil or empty
    return true
}

/*
Checks if cstring is nil or empty.
* Single/multiple
*/
cstring_is_nil_or_empty :: proc{
    cstring_is_nil_or_empty_single,
    cstring_is_nil_or_empty_multiple,
}

/*
Clone a cstring.
* Return cstring require to be deleted.
*/
cstring_clone_single :: proc(cstr: cstring, allocator := context.allocator) -> (cstring, bool) #optional_ok
{
    if !cstring_is_nil_or_empty(cstr) do return nil, false

    cstr_len := len(cstr)
    clone_len := cstr_len + 1
    clone, alloc_err := make([]u8, clone_len, allocator)
    if alloc_err != .None do return nil, false

    cstr_u8 := transmute([^]u8)cstr
    clone_u8 := transmute([^]u8)&clone[0]
    for i := 0; i < clone_len; i += 1 do clone_u8[i] = cstr_u8[i]
    return transmute(cstring)clone_u8, true
}

/*
Clone a cstring slice.
* Return slice and cstrings require to be deleted.
*/
cstring_clone_multiple :: proc(cstrs: []cstring, allocator := context.allocator) -> ([]cstring, bool) #optional_ok
{
    if !cstring_is_nil_or_empty(cstrs) do return nil, false

    cstrs_len := len(cstrs)
    clones, alloc_err := make([]cstring, cstrs_len, allocator)
    if alloc_err == .None do return nil, false

    for i := 0; i < cstrs_len; i += 1 do clones[i] = cstring_clone_single(cstrs[i], allocator)
    return clones, true
}

/*
Clone a cstring dynamic slice.
* Return slice and cstrings require to be deleted.
*/
cstring_clone_multiple_from_dynamic :: proc(dyn_cstrs: ^[dynamic]cstring, allocator := context.allocator) -> ([]cstring, bool) #optional_ok
{
    cstrs := dynamic_iterator(dyn_cstrs)
    return cstring_clone_multiple(cstrs, allocator)
}

/*
Clone a cstring dynamic slice.
* Use context.allocator for allocation.
* Return slice and cstrings require to be deleted.
* Single/multiple
*/
cstring_clone :: proc{
    cstring_clone_single,
    cstring_clone_multiple,
    cstring_clone_multiple_from_dynamic,
}