package commons

import "core:intrinsics"

/*
Return array length if it is not nil, else return 0.
* Works for any array type (array, slice, dynamic).
*/
array_try_len :: #force_inline proc(array: $T) -> (int, bool) where intrinsics.type_is_array(T) || intrinsics.type_is_slice(T) || intrinsics.type_is_dynamic_array(T) #optional_ok
{
    if array == nil do return 0, false
    else do return len(array), true
}

/*
Return slice as pointer if its not nil, else return nil.
*/
slice_try_as_pointer :: #force_inline proc(array: $Array/[]$Type) -> (^Type, bool) #optional_ok
{
    if array_try_len(array) < 1 do return nil, false
    else do return &array[0], true
}

/*
Return dynamic slice as pointer if its not nil, else return nil.
*/
dynamic_try_as_pointer :: #force_inline proc(array: $Array/[dynamic]$Type) -> (^Type, bool) #optional_ok
{
    if array_try_len(array) < 1 do return nil, false
    else do return &array[0], true
}

array_try_as_pointer :: proc{
    slice_try_as_pointer,
    dynamic_try_as_pointer,
}