package navis_mem

import "core:intrinsics"
import "core:sync"

/*
The field name when creating a SoA chunk stucture type.
* Used to know if the SoA chunk element is being used
*/
SOA_CHUNK_ELEMENT_USED_FIELD_NAME :: "__used"

/*
The field type when creating a SoA chunk stucture type.
* Just a 'bool' alaias
*/
SOA_Chunk_Element_Used :: bool

/*
SoA Chunk
*/
SOA_Chunk :: struct($Type: typeid, $Fields: int)
where
intrinsics.type_is_named(Type) && 
intrinsics.type_has_field(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) == SOA_Chunk_Element_Used &&
intrinsics.type_struct_field_count(Type) <= Fields
{
    using __raw: Raw_SOA_Chunk(Fields)
}

Raw_SOA_Chunk :: struct($Fields: int)
{
    __id: Index_Table_ID,
    mutex: sync.Atomic_Mutex,
    seek, element_fields, sub_allocations: int,
    content: [Fields + 1]rawptr,
}

soa_chunk_init :: proc(chunk: ^SOA_Chunk($Type, $Fields), capacity: int, allocator := context.allocator) -> bool
{
    if capacity < 1 do return false
    content, content_allocation_error := make_soa(#soa[]Type, capacity, allocator)
    if content_allocation_error != .None do return false

    chunk_content := transmute(^#soa[]Type)&chunk.content
    chunk_content^ = content
    chunk.element_fields = intrinsics.type_struct_field_count(Type)
    return true
}

soa_chunk_destroy :: proc(chunk: ^SOA_Chunk($Type, $Fields), allocator := context.allocator) -> bool
{
    if chunk == nil do return false
    chunk_content := transmute(^#soa[]Type)&chunk.content
    delete_soa(chunk_content^, allocator)
    chunk^ = {}
    return true
}

soa_chunk_content :: proc "contextless" (chunk: ^SOA_Chunk($Type, $Fields)) -> ^#soa[]Type
{
    if chunk == nil do return nil
    return transmute(^#soa[]Type)&chunk.content
}

soa_chunk_sub_allocate_safe :: #force_inline proc "contextless" (chunk: ^SOA_Chunk($Type, $Fields)) -> int
{
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)
    return soa_chunk_sub_allocate(chunk)
}

soa_chunk_free_safe :: #force_inline proc "contextless" (chunk: ^SOA_Chunk($Type, $Fields), index: int) -> bool
{
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)
    return soa_chunk_free(chunk, index)
}

@(optimization_mode="speed")
soa_chunk_sub_allocate :: proc "contextless" (chunk: ^SOA_Chunk($Type, $Fields)) -> int
{
    content := transmute(^#soa[]Type)&chunk.content

    chunk_seek := chunk.seek
    if !content[chunk_seek].__used
    {
        content[chunk_seek].__used = true
        chunk.sub_allocations += 1
        chunk.seek = clamp(chunk.seek + 1, 0, len(content) - 1)
        return chunk_seek
    }

    for &element, index in content
    {
        if element.__used do continue
        element.__used = true
        chunk.sub_allocations += 1
        chunk.seek = clamp(index + 1, 0, len(content) - 1)
        return index
    }

    return -1
}

@(optimization_mode="speed")
soa_chunk_free :: proc "contextless" (chunk: ^SOA_Chunk($Type, $Fields), index: int) -> bool
{
    if chunk == nil || index < 0 do return false
    content := transmute(^#soa[]Type)&chunk.content
    if !content[index].__used do return false
    content[index].__used = false
    chunk.sub_allocations -= 1
    if index < chunk.seek do chunk.seek = index
    return true
}

soa_chunk_as_raw :: proc "contextless" (chunk: ^SOA_Chunk($Type, $Fields)) -> ^Raw_SOA_Chunk(Fields)
{
    if chunk == nil do return nil
    return transmute(^Raw_SOA_Chunk(Fields))chunk
}

soa_chunk_from_raw :: proc "contextless" ($Type: typeid, chunk: ^Raw_SOA_Chunk($Fields)) ->  ^SOA_Chunk(Type, Fields)
{
    if chunk == nil || chunk.element_fields != intrinsics.type_struct_field_count(Type) do return nil
    return transmute(^SOA_Chunk(Type, Fields))chunk
}

raw_soa_chunk_capacity :: proc "contextless" (chunk: ^Raw_SOA_Chunk($Fields)) -> int
{
    return transmute(int)chunk.content[chunk.element_fields]
}

raw_soa_chunk_is_empty :: proc "contextless" (chunk: ^Raw_SOA_Chunk($Fields)) ->  bool
{
    return chunk != nil && chunk.sub_allocations == 0
}

raw_soa_chunk_is_full :: proc "contextless" (chunk: ^Raw_SOA_Chunk($Fields)) ->  bool
{
    return chunk != nil && chunk.sub_allocations == raw_soa_chunk_capacity(chunk)
}