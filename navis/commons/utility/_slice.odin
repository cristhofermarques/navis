package utility

/*
Returns 'slice' length if it is not 'nil'
*/
slice_may_len :: #force_inline proc(slice: []$T) -> int
{
    if slice == nil do return 0
    else do return len(slice)
}

/*
Returns 'slice' as multi pointer if it is not 'nil' or length less than 1
*/
slice_as_mult_ptr :: #force_inline proc(slice: []$T) -> [^]T
{
    if slice == nil || slice_may_len(slice) < 1 do return nil
    else do return &slice[0]
}

/*
Return an element at index if it exists.
*/
slice_try_get :: #force_inline proc(slice: []$T, index: int) -> (T, bool) #optional_ok
{
    element: T
    if slice == nil do return element, false

    lenght := len(slice)
    if index < 0 || index > lenght do return element, false

    element = slice[index]
    return element, true
}

/*
Return an element at index if it exists.
*/
slice_try_get_pointer :: #force_inline proc(slice: []$T, index: int) -> (^T, bool) #optional_ok
{
    element: ^T
    if slice == nil do return element, false

    lenght := len(slice)
    if index < 0 || index > lenght do return element, false

    element = &slice[index]
    return element, true
}

/*
Returns 'slice' from dynamic slice, no content copying
*/
slice_from_dynamic :: #force_inline proc(dynamic_slice: [dynamic]$T, allocator := context.allocator) -> ([]T, bool) #optional_ok
{
    if dynamic_slice == nil do return nil, false

    slice_len := len(dynamic_slice)
    if slice_len < 1 do return nil, false

    slice := make([]T, slice_len, allocator)
    for element, index in dynamic_slice do slice[index] = element
    return slice, true
}

/*
Returns true if slice contains provided element.
* Uses '==' operator.
*/
slice_contains :: #force_inline proc(slice: []$T, element: T) -> bool
{
    if slice == nil do return false
    for element_ in slice do if element_ == element do return true
    return false
}

/*
Returns index of element if its included.
* Uses '==' operator.
*/
slice_index_of :: #force_inline proc(slice: []$T, element: T) -> (int, bool) #optional_ok
{
    if slice == nil do return -1, false
    for element_, index in slice do if element_ == element do return index, true
    return -1, false
}

may_len :: proc{
    slice_may_len,
    dynamic_may_len,
}

as_mult_ptr :: proc{
    slice_as_mult_ptr,
    dynamic_as_mult_ptr,
}