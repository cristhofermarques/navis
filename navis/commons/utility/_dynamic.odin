package utility

/*
Returns provided dynamic slice length if it is not 'nil'
*/
dynamic_may_len :: #force_inline proc(slice: [dynamic]$T) -> int
{
    if slice == nil do return 0
    else do return len(slice)
}

/*
Returns provided dynamic slice as multi pointer if it is not 'nil' or length less than 1
*/
dynamic_as_mult_ptr :: #force_inline proc(slice: [dynamic]$T) -> [^]T
{
    if slice == nil || dynamic_may_len(slice) < 1 do return nil
    else do return &slice[0]
}

/*
Reinterpret as slice.
*/
dynamic_iterator :: #force_inline proc(slice: ^[dynamic]$T) -> []T
{
    assert(slice != nil)
    return slice[0:]
}

/*
Creates an dynamic slice from an slice.
*/
dynamic_from_slice :: #force_inline proc(slice: []$T, allocator := context.allocator) -> ([dynamic]T, bool) #optional_ok
{
    if slice == nil do return nil, false

    slice_len := len(slice)
    dyn_slice, alloc_err := make_dynamic_array_len_cap([dynamic]T, 0, slice_len, allocator)
    if alloc_err != .None do return nil, false

    dynamic_append_slice(&dyn_slice, slice)
    return dyn_slice, true
}

/*
Returns index of element if its included.
* Uses '==' operator.
*/
dynamic_index_of :: #force_inline proc(slice: [dynamic]$T, element: T) -> (int, bool) #optional_ok
{
    if slice == nil do return -1, false
    for element_, index in slice do if element_ == element do return index, true
    return -1, false
}

/*
Return true if slice contains provided element.
* Use '==' operator.
*/
dynamic_contains :: #force_inline proc(slice: [dynamic]$T, element: T) -> bool
{
    if slice == nil do return false
    for element_ in slice do if element_ == element do return true
    return false
}

/*
Append slice elements to dynamic slice.
*/
dynamic_append_slice :: #force_inline proc(dyn_slice: ^[dynamic]$T, slice: []T)
{
    if dyn_slice == nil || slice == nil do return
    for element in slice do append(dyn_slice, element)
}