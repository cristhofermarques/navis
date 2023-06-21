package commons

import "core:runtime"

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