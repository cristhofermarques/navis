package utility

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