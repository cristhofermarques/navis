package memory

import "core:intrinsics"

MAX_RAW_SOA_CHUNK_SLICE_FIELDS :: 32

Raw_SOA_Chunk_Slice :: [MAX_RAW_SOA_CHUNK_SLICE_FIELDS + size_of(int)]rawptr

Chunk_Element :: struct
{
    used: bool,
}

SOA_Chunk :: struct($T: typeid) where intrinsics.type_has_field(T, "_element") && intrinsics.type_field_type(T, "_element") == Chunk_Element
{
    seek, content_size: int,
    content: #soa[]T,
}

soa_chunk_init :: proc(chunk: ^SOA_Chunk($T), capacity: int, allocator := context.allocator) -> bool
{
    if capacity < 1 do return false
    content, content_allocation_error := make_soa(#soa[]T, capacity, allocator)
    if content_allocation_error != .None do return false
    
    chunk.content = content
    chunk.content_size = size_of(T)
    return true
}

soa_chunk_destroy :: proc(chunk: ^SOA_Chunk($T), allocator := context.allocator) -> bool
{
    if chunk == nil do return false
    delete_soa(chunk.content, allocator)
    chunk^ = {}
    return true
}