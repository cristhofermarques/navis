package utility

cstring_clone_single :: proc(str: cstring, allocator := context.allocator, location := #caller_location) -> cstring
{
    assert(str != nil, "nil cstring parameter", location)

    str_len := len(str)
    clone_len := str_len + 1
    clone, alloc_err := make([]u8, clone_len, allocator, location)
    assert(alloc_err == .None, "allocation error", location)

    str_u8 := transmute([^]u8)str
    clone_u8 := transmute([^]u8)&clone[0]
    for i := 0; i < clone_len; i += 1 do clone_u8[i] = str_u8[i]
    return transmute(cstring)clone_u8
}

cstring_clone_multiple :: proc(strs: []cstring, allocator := context.allocator, location := #caller_location) -> []cstring
{
    assert(strs != nil, "nil cstring slice parameter")

    strs_len := len(strs)
    clones, alloc_err := make([]cstring, strs_len, allocator)
    assert(alloc_err == .None, "allocation error")

    for i := 0; i < strs_len; i += 1 do clones[i] = cstring_clone_single(strs[i], allocator)
    return clones
}

cstring_clone_from_dynamic :: proc(strs: ^[dynamic]cstring, allocator := context.allocator, location := #caller_location) -> []cstring
{
    assert(strs != nil, "nil cstring slice parameter")

    strs_len := len(strs)
    clones, alloc_err := make([]cstring, strs_len, allocator)
    assert(alloc_err == .None, "allocation error")

    for i := 0; i < strs_len; i += 1 do clones[i] = cstring_clone_single(strs[i], allocator)
    return clones
}

cstring_clone :: proc{
    cstring_clone_single,
    cstring_clone_multiple,
    cstring_clone_from_dynamic,
}