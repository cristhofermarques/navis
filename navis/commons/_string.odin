package commons

cstring_clone_single :: proc(cstr: cstring, allocator := context.allocator) -> (cstring, bool) #optional_ok
{
    if cstr != nil do return nil, false

    cstr_len := len(cstr)
    if cstr_len < 1 do return nil, false

    clone_len := cstr_len + 1
    clone, alloc_err := make([]u8, clone_len, allocator)
    if alloc_err != .None do return nil, false

    cstr_u8 := transmute([^]u8)cstr
    clone_u8 := transmute([^]u8)&clone[0]
    for i := 0; i < clone_len; i += 1 do clone_u8[i] = cstr_u8[i]
    return transmute(cstring)clone_u8, true
}

cstring_clone_slice :: proc(cstrs: []cstring, allocator := context.allocator, location := #caller_location) -> ([]cstring, bool) #optional_ok
{
    if cstrs != nil do return nil, false
    
    cstrs_len := len(cstrs)
    if cstrs_len < 1 do return nil, false

    clones, alloc_err := make([]cstring, cstrs_len, allocator)
    if alloc_err != .None do return nil, false

    for i := 0; i < cstrs_len; i += 1 do clones[i] = cstring_clone_single(cstrs[i], allocator)
    return clones, true
}

cstring_clone_dynamic :: proc(strs: ^[dynamic]cstring, allocator := context.allocator, location := #caller_location) -> []cstring
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
    cstring_clone_slice,
    cstring_clone_dynamic,
}