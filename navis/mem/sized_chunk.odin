package navis_mem

import "core:mem"
import "core:sync"
import "core:runtime"
import "core:intrinsics"

/*
Sized chunk element
*/
Sized_Chunk_Element :: struct($Type: typeid)
where
intrinsics.type_is_struct(Type)
{
    used: bool,
    data: Type,
}

/*
Sized chunk
*/
Sized_Chunk :: struct($Type: typeid, $Capacity: int)
{
    mutex: sync.Atomic_Mutex,
    seek, sub_allocations: int,
    elements: [Capacity]Sized_Chunk_Element(Type),
}

/*
Sub allocate a chunk element.
* Multithread Safe
*/
sized_chunk_sub_allocate_safe :: #force_inline proc "contextless" (chunk: ^Sized_Chunk($Type, $Capacity)) -> ^Type
{
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)
    return sized_chunk_sub_allocate(chunk)
}

/*
Free a chunk element.
* Multithread Safe
*/
sized_chunk_free_safe :: proc "contextless" (chunk: ^Sized_Chunk($Type, $Capacity), data: ^Type) -> bool
{
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)
    return sized_chunk_free(chunk, data)
}

/*
Sub allocate a chunk element
*/
@(optimization_mode="speed")
sized_chunk_sub_allocate :: proc "contextless" (chunk: ^Sized_Chunk($Type, $Capacity)) -> ^Type
{
    if sized_chunk_is_full(chunk) do return nil
    
    //Cache
    if seek := &chunk.elements[chunk.seek]; !seek.used
    {
        seek.used = true
        data := &seek.data
        chunk.sub_allocations += 1
        if !sized_chunk_is_full(chunk) do chunk.seek += 1
        return data
    }

    //Search
    for i := 0; i < len(chunk.elements); i += 1
    {
        seek := &chunk.elements[i]
        if seek.used do continue
        seek.used = true
        data := &seek.data
        chunk.sub_allocations += 1
        chunk.seek = i
        if !sized_chunk_is_full(chunk) do chunk.seek += 1
        return data
    }

    //Failed
    return nil
}

/*
Free a chunk element
*/
@(optimization_mode="speed")
sized_chunk_free :: proc "contextless" (chunk: ^Sized_Chunk($Type, $Capacity), data: ^Type) -> bool
{
    if chunk == nil || data == nil do return false

    index := sized_chunk_index_of(chunk, data)
    if index < 0 do return false

    element := &chunk.elements[index]
    element.used = false
    chunk.sub_allocations -= 1
    if index < chunk.seek do chunk.seek = index
    return true
}

/*
Return 'true' if sized chunk is full
*/
sized_chunk_is_full :: #force_inline proc "contextless" (chunk: ^Sized_Chunk($Type, $Capacity)) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == len(chunk.elements)
}

/*
Return 'true' if sized chunk contains provided element
*/
sized_chunk_contains :: proc "contextless" (chunk: ^Sized_Chunk($Type, $Capacity), data: ^Type) -> bool
{
    if chunk == nil || data == nil do return false
    begin := &chunk.elements[0]
    end := mem.ptr_offset(begin, len(chunk.slots))

    uptr_data := uintptr(data)
    uptr_begin := uintptr(begin)
    uptr_end := uintptr(end)

    return uptr_data >= uptr_begin || uptr_data < uptr_end
}

/*
Return index of provided element.
* Return '-1' if its not a valid index
*/
sized_chunk_index_of :: proc "contextless" (chunk: ^Sized_Chunk($Type, $Capacity), data: ^Type) -> int
{
    if chunk == nil || data == nil do return -1
    uptr_begin := cast(uintptr)&chunk.elements[0]
    uptr_data := cast(uintptr)data
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / size_of(Sized_Chunk_Element(Type))
}