package commons

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