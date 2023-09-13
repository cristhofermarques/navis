package navis

import "core:mem"
import "core:sync"
import "core:runtime"
import "core:intrinsics"

/* Sized Chunk */

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

/* Index Table */

INDEX_TABLE_ID_FIELD_NAME :: "__id"

Index_Table_ID :: int
INVALID_INDEX_TABLE_ID : Index_Table_ID : -1

Index_Table :: struct($T: typeid)
where
intrinsics.type_has_field(T, INDEX_TABLE_ID_FIELD_NAME) &&
intrinsics.type_field_type(T, INDEX_TABLE_ID_FIELD_NAME) == Index_Table_ID
{
    indices: [dynamic]int,
    content: [dynamic]T,
}

index_table_init :: proc(table: ^Index_Table($T), initial_capacity: int, allocator := context.allocator) -> bool
{
    indices, indices_allocation_error := make_dynamic_array_len_cap([dynamic]int, 0, initial_capacity, allocator)
    if indices_allocation_error != .None do return false

    content, content_allocation_error := make_dynamic_array_len_cap([dynamic]T, 0, initial_capacity, allocator)
    if content_allocation_error != .None
    {
        delete(indices)
        return false
    }

    table.indices = indices
    table.content = content
    return true
}

index_table_destroy :: proc(table: ^Index_Table($T)) -> bool
{
    delete(table.indices)
    delete(table.content)
    table^ = {}
    return true
}

index_table_index_of :: proc "contextless" (table: ^Index_Table($T), id: Index_Table_ID) -> int
{
    if id < 0 || id >= len(table.indices) do return -1
    return table.indices[id]
}

index_table_contains_id :: proc "contextless" (table: ^Index_Table($T), id: Index_Table_ID) -> bool
{
    if id < 0 || id >= len(table.indices) do return false
    return table.indices[id] != -1
}

index_table_get :: proc "contextless" (table: ^Index_Table($T), id: Index_Table_ID) -> ^T
{
    if id < 0 || id >= len(table.indices) do return nil
    index := table.indices[id]
    if index == -1 do return nil
    return &table.content[index]
}

index_table_content_length :: proc "contextless" (table: ^Index_Table($T)) -> int
{
    return len(table.content)
}

/*
Only for internal use.
*/
@(private)
index_table_acquire_id :: proc(table: ^Index_Table($T)) -> Index_Table_ID
{
    for index, index_index in table.indices do if index == -1 do return index_index
    append_nothing(&table.indices)
    return len(table.indices) - 1
}

index_table_append :: proc(table: ^Index_Table($T), value: ^T) -> Index_Table_ID
{
    id := index_table_acquire_id(table)
    value.__id = id
    append_elem(&table.content, value^)
    index := len(table.content) - 1
    table.indices[id] = index
    return id
}

index_table_remove :: proc(table: ^Index_Table($T), id: Index_Table_ID) -> bool
{
    index := index_table_index_of(table, id)
    unordered_remove(&table.content, index)
    table.indices[id] = -1
    for &element, index in table.content do table.indices[element.__id] = index
    return true
}

/* Chunk */

/*
Return slot size of provided type
*/
slot_size_of :: proc "contextless" ($T: typeid) -> int
{
    return size_of(Chunk_Slot(T))
}

/*
Return slot data offset of provided type
*/
slot_data_offset_of :: proc "contextless" ($T: typeid) -> uintptr
{
    return offset_of(Chunk_Slot(T), data)
}

Chunk_Slot :: struct($T: typeid)
{
    used: bool,
    data: T,
}

Chunk :: struct($T: typeid)
{
    seek: ^Chunk_Slot(T),
    sub_allocations: int,
    slots: []Chunk_Slot(T),
    mutex: sync.Atomic_Mutex,
}

chunk_create :: proc($T: typeid, capacity: int, allocator := context.allocator) -> (Chunk(T), bool) #optional_ok
{
    if capacity < 1 do return {}, false

    slots, slots_allocation_error := make([]Chunk_Slot(T), capacity, allocator)
    if slots_allocation_error != .None do return {}, false

    chunk: Chunk(T)
    chunk.seek = &slots[0]
    chunk.slots = slots
    return chunk, true
}

chunk_destroy :: proc(chunk: ^Chunk($T), allocator := context.allocator) -> bool
{
    if chunk == nil do return false
    delete(chunk.slots, allocator)
    chunk^ = {}
    return true
}

chunk_sub_allocate :: proc "contextless" (chunk: ^Chunk($T)) -> ^T
{
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    if chunk_is_full(chunk) do return nil
    
    //Cache
    if !chunk.seek.used
    {
        chunk.seek.used = true
        data := &chunk.seek.data
        chunk.sub_allocations += 1
        if !chunk_is_full(chunk) do chunk_seek_to_next(chunk)
        return data
    }

    //Search
    for i := 0; i < len(chunk.slots); i += 1
    {
        seek := &chunk.slots[i]
        if seek.used do continue
        seek.used = true
        data := &seek.data
        chunk.sub_allocations += 1
        chunk.seek = seek
        if !chunk_is_full(chunk) do chunk_seek_to_next(chunk)
        return data
    }

    return nil
}

chunk_free :: proc "contextless" (chunk: ^Chunk($T), data: ^T) -> bool
{
    if chunk == nil || data == nil do return false

    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    index := chunk_index_of(chunk, data)
    if index < 0 do return false

    slot := &chunk.slots[index]
    slot.used = false
    chunk.sub_allocations -= 1

    if slot < chunk.seek do chunk.seek = slot

    return true
}

@(private)
chunk_seek_to_next :: proc "contextless" (chunk: ^Chunk($T))
{
    last := chunk_get_last(chunk)
    uptr_last := transmute(uintptr)last
    uptr_seek := transmute(uintptr)chunk.seek
    next := uptr_seek + uintptr(size_of(Chunk_Slot(T)))
    chunk.seek = transmute(^Chunk_Slot(T))min(next, uptr_last)
}

chunk_is_empty :: proc "contextless" (chunk: ^Chunk($T)) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == 0
}

chunk_is_full :: proc "contextless" (chunk: ^Chunk($T)) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == len(chunk.slots)
}

chunk_has :: proc "contextless" (chunk: ^Chunk($T), data: ^T) -> bool
{
    if chunk == nil || data == nil do return false
    begin := &chunk.slots[0]
    end := mem.ptr_offset(begin, len(chunk.slots))

    uptr_data := uintptr(data)
    uptr_begin := uintptr(begin)
    uptr_end := uintptr(end)

    return uptr_data >= uptr_begin && uptr_data < uptr_end
}

chunk_get_last :: proc "contextless" (chunk: ^Chunk($T)) -> ^Chunk_Slot(T)
{
    uptr_begin := transmute(uintptr)raw_data(chunk.slots)
    return transmute(^Chunk_Slot(T))(uptr_begin + uintptr(max(0, len(chunk.slots) - 1) * size_of(Chunk_Slot(T))))
}

chunk_index_of :: proc "contextless" (chunk: ^Chunk($T), data: ^T) -> int
{
    if chunk == nil || data == nil do return -1
    uptr_begin := cast(uintptr)&chunk.slots[0]
    uptr_data := cast(uintptr)data - offset_of(Chunk_Slot(T), data)
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / size_of(Chunk_Slot(T))
}

Untyped_Chunk :: struct
{
    sub_allocations, slot_size: int,
    seek, slot_data_offset: uintptr,
    slots: runtime.Raw_Slice,
    mutex: sync.Atomic_Mutex,
}

untyped_chunk_create :: proc(slot_size: int, slot_data_offset: uintptr, capacity: int, allocator := context.allocator) -> (Untyped_Chunk, bool) #optional_ok
{
    if slot_size < 1 || slot_data_offset < 1 || capacity < 1 do return {}, false

    slots_data_size := slot_size * capacity
    slots_data, slots_data_allocation_error := mem.alloc(slots_data_size, allocator = allocator)
    if slots_data_allocation_error != .None do return {}, false

    chunk: Untyped_Chunk
    chunk.slots.data = slots_data
    chunk.slots.len = capacity
    chunk.slot_size = slot_size
    chunk.slot_data_offset = uintptr(slot_data_offset)
    chunk.seek = uintptr(slots_data)
    return chunk, true
}

untyped_chunk_destroy :: proc(chunk: ^Untyped_Chunk, allocator := context.allocator)
{
    if chunk == nil do return
    mem.free(chunk.slots.data, allocator)
    chunk^ = {}
}

untyped_chunk_sub_allocate :: proc "contextless" (chunk: ^Untyped_Chunk) -> rawptr
{
    if chunk == nil do return nil

    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    if untyped_chunk_is_full(chunk) do return nil
    uptr_slots_data := transmute(uintptr)chunk.slots.data
    uptr_slot_data_offset := chunk.slot_data_offset

    //Seek
    uptr_seek_slot_used := chunk.seek    
    seek_slot_used := transmute(^bool)uptr_seek_slot_used
    if !seek_slot_used^
    {
        seek_slot_used^ = true
        chunk.sub_allocations += 1
        if !untyped_chunk_is_full(chunk) do untyped_chunk_seek_to_next(chunk)
        return rawptr(uptr_seek_slot_used + uptr_slot_data_offset)
    }

    //Search
    for i := 0; i < chunk.slots.len; i += 1
    {
        uptr_curr_slot_used := uptr_slots_data + uintptr(chunk.slot_size * i)
        curr_slot_used := transmute(^bool)uptr_curr_slot_used
        if curr_slot_used^ do continue
        curr_slot_used^ = true
        chunk.sub_allocations += 1
        chunk.seek = uptr_curr_slot_used
        if !untyped_chunk_is_full(chunk) do untyped_chunk_seek_to_next(chunk)
        return rawptr(uptr_curr_slot_used + uptr_slot_data_offset)
    }

    return nil
}

untyped_chunk_free :: proc "contextless" (chunk: ^Untyped_Chunk, data: rawptr) -> bool
{
    if chunk == nil do return false
    
    sync.atomic_mutex_lock(&chunk.mutex)
    defer sync.atomic_mutex_unlock(&chunk.mutex)

    if !untyped_chunk_has(chunk, data) do return false
    index := untyped_chunk_index_of(chunk, data)
    if index < 0 do return false
    uptr_slot_used := uintptr(data) - chunk.slot_data_offset
    slot_used := transmute(^bool)uptr_slot_used
    if !slot_used^ do return false
    slot_used^ = false
    chunk.sub_allocations -= 1
    if uptr_slot_used < chunk.seek do chunk.seek = uptr_slot_used
    return true
}

@(private)
untyped_chunk_seek_to_next :: proc "contextless" (chunk: ^Untyped_Chunk)
{
    last := untyped_chunk_get_last(chunk)
    next := chunk.seek + uintptr(chunk.slot_size)
    chunk.seek = min(next, last)
}

untyped_chunk_is_empty :: proc "contextless" (chunk: ^Untyped_Chunk) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == 0
}

untyped_chunk_is_full :: proc "contextless" (chunk: ^Untyped_Chunk) -> bool
{
    if chunk == nil do return false
    return chunk.sub_allocations == chunk.slots.len
}

untyped_chunk_has :: proc "contextless" (chunk: ^Untyped_Chunk, data: rawptr) -> bool
{
    if chunk == nil || data == nil do return false
    uptr_data := transmute(uintptr)data
    uptr_begin := transmute(uintptr)chunk.slots.data
    uptr_end := uptr_begin + uintptr(chunk.slots.len * chunk.slot_size)
    return uptr_data >= uptr_begin && uptr_data < uptr_end
}

untyped_chunk_get_last :: proc "contextless" (chunk: ^Untyped_Chunk) -> uintptr
{
    uptr_begin := transmute(uintptr)chunk.slots.data
    return uptr_begin + uintptr(max(0, chunk.slots.len - 1)  * chunk.slot_size)
}

untyped_chunk_index_of :: proc "contextless" (chunk: ^Untyped_Chunk, data: rawptr) -> int
{
    if chunk == nil || data == nil do return -1
    uptr_begin := transmute(uintptr)chunk.slots.data
    uptr_data := transmute(uintptr)data - chunk.slot_data_offset
    begin_to_data_size := max(uptr_begin, uptr_data) - min(uptr_begin, uptr_data)
    return int(begin_to_data_size) / chunk.slot_size
}

untyped_chunk_as :: proc(chunk: ^Untyped_Chunk, $T: typeid) -> (Chunk(T), bool) #optional_ok
{
    if chunk == nil || chunk.slot_size != size_of(Chunk_Slot(T)) || chunk.slot_data_offset != offset_of(Chunk_Slot(T), data) do return {}, false
    typed: Chunk(T)
    typed.seek = transmute(^Chunk_Slot(T))chunk.seek
    typed.slots = transmute([]Chunk_Slot(T))chunk.slots
    typed.sub_allocations = chunk.sub_allocations
    return typed, true
}

/* SOA Chunk */

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

/* Collection */

Collection :: struct($T: typeid)
{
    mutex: sync.Atomic_Mutex,
    allocator: runtime.Allocator,
    chunk_capacity: int,
    sub_allocations: int,
    seek: ^Chunk(T),
    chunks: [dynamic]Chunk(T),
}

collection_create :: proc($T: typeid, chunk_capacity, reserve_count: int, allocator := context.allocator) -> (Collection(T), bool)
{
    if chunk_capacity < 1
    {
        //TODO: log error
        return {}, false
    }

    chunks, chunks_allocation_error := make_dynamic_array_len_cap([dynamic]Chunk(T), 1, max(1, reserve_count), allocator)
    if chunks_allocation_error != .None
    {
        //TODO: log error
        return {}, false
    }

    initial_chunk, created_initial_chunk := chunk_create(T, chunk_capacity, allocator)
    if !created_initial_chunk
    {
        //TODO: log error
        delete(chunks)
        return {}, false
    }

    chunks[0] = initial_chunk
    collection: Collection(T)
    collection.allocator = allocator
    collection.chunk_capacity = chunk_capacity
    collection.chunks = chunks
    collection.seek = raw_data(chunks)
    return collection, true
}

collection_destroy :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do chunk_destroy(&chunk)
    delete(collection.chunks)
    collection^ = {}
    return true
}

collection_create_chunk :: proc(collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    chunk, created := chunk_create(T, collection.chunk_capacity, collection.allocator)
    if !created do return false
    append(&collection.chunks, chunk)
    return true
}

collection_destroy_chunk :: proc(collection: ^Collection($T), index: int) -> bool
{
    if collection == nil || index < 1 do return false
    chunk := &collection.chunks[index]
    if collection.seek == chunk do collection.seek = raw_data(collection.chunks)
    chunk_destroy(chunk, collection.allocator)
    unordered_remove(&collection.chunks, index)
    return true
}

collection_sub_allocate :: proc(collection: ^Collection($T)) -> ^T
{
    if collection == nil do return nil

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    if data := chunk_sub_allocate(collection.seek); data != nil //Cache
    {
        collection.sub_allocations += 1
        if chunk_is_full(collection.seek) do collection_seek_to_next(collection)
        return data
    }

    if collection_is_full(collection) //Create
    {
        if !collection_create_chunk(collection) do return nil
        last := &collection.chunks[max(0, len(collection.chunks) - 1)]

        data := chunk_sub_allocate(last)
        if data == nil do return nil
        
        collection.sub_allocations += 1
        collection.seek = last
        return data
    }
    else //Search
    {       
        for i := 0; i < len(collection.chunks); i += 1
        {
            chunk := &collection.chunks[i]
            if chunk_is_full(chunk) do continue
            
            data := chunk_sub_allocate(chunk)
            if data == nil do continue
            
            collection.sub_allocations += 1
            collection.seek = chunk
            if chunk_is_full(collection.seek) do collection_seek_to_next(collection)
            return data
        }
    }
    
    return nil
}

collection_free :: proc(collection: ^Collection($T), data: ^T)
{
    if collection == nil || data == nil do return

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    for &chunk, i in collection.chunks
    {
        if !chunk_has(&chunk, data) do continue
        
        chunk_free(&chunk, data)
        collection.sub_allocations -= 1
        if chunk_is_empty(&chunk) && collection_get_empty_chunk_count(collection) > 1
        {    
            collection_destroy_chunk(collection, i)
            return
        }

        if cast(uintptr)&chunk < cast(uintptr)chunk.seek do collection.seek = &chunk
        return
    }
}

@(private)
collection_seek_to_next :: proc "contextless" (collection: ^Collection($T))
{
    last := collection_get_last(collection)
    next := mem.ptr_offset(collection.seek, 1)
    uptr_last := uintptr(last)
    uptr_next := uintptr(next)
    collection.seek = transmute(^Chunk(T))min(uptr_next, uptr_last)
}

collection_is_full :: proc "contextless" (collection: ^Collection($T)) -> bool
{
    if collection == nil do return false
    for i := 0; i < len(collection.chunks); i += 1
    {
        chunk := &collection.chunks[i]
        if !chunk_is_full(chunk) do return false
    }
    return true
}

collection_get_last :: proc "contextless" (collection: ^Collection($T)) -> ^Chunk(T)
{
    return &collection.chunks[max(0, len(collection.chunks) - 1)]
}

collection_get_empty_chunk_count :: proc "contextless" (collection: ^Collection($T)) -> int
{
    count := 0
    for &chunk in collection.chunks do if chunk_is_empty(&chunk) do count += 1
    return count
}

Untyped_Collection :: struct
{
    mutex: sync.Atomic_Mutex,
    allocator: runtime.Allocator,
    slot_size, chunk_capacity, sub_allocations: int,
    slot_data_offset: uintptr,
    seek: ^Untyped_Chunk,
    chunks: [dynamic]Untyped_Chunk,
}

untyped_collection_create :: proc(slot_size:int, slot_data_offset: uintptr, chunk_capacity, reserve_count: int, allocator := context.allocator) -> (Untyped_Collection, bool)
{
    if slot_size < 1 || slot_data_offset < 1 || chunk_capacity < 1 do return {}, false

    chunks, chunks_allocation_error := make_dynamic_array_len_cap([dynamic]Untyped_Chunk, 1, max(1, reserve_count), allocator)
    if chunks_allocation_error != .None do return {}, false

    intial_chunk, did_create_intial_chunk := untyped_chunk_create(slot_size, slot_data_offset, chunk_capacity, allocator)
    if !did_create_intial_chunk
    {
        delete(chunks)
        return {}, false
    }

    chunks[0] = intial_chunk
    collection: Untyped_Collection
    collection.allocator = allocator
    collection.slot_size = slot_size
    collection.slot_data_offset = slot_data_offset
    collection.chunk_capacity = chunk_capacity
    collection.seek = raw_data(chunks)
    collection.chunks = chunks
    return collection, true
}

untyped_collection_destroy :: proc(collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do untyped_chunk_destroy(&chunk, collection.allocator)
    delete(collection.chunks)
    collection^ = {}
    return true
}

untyped_collection_sub_allocate :: proc(collection: ^Untyped_Collection) -> rawptr
{
    if collection == nil do return nil

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)
    
    if data := untyped_chunk_sub_allocate(collection.seek); data != nil
    {
        collection.sub_allocations += 1
        if untyped_chunk_is_full(collection.seek) do untyped_collection_seek_to_next(collection)
        return data
    }

    if untyped_collection_is_full(collection)
    {
        if !untyped_collection_create_chunk(collection) do return nil
        last := untyped_collection_get_last(collection)
        data := untyped_chunk_sub_allocate(last)
        if data == nil do return nil

        collection.sub_allocations += 1
        collection.seek = last
        return data
    }
    else
    {
        for &chunk, i in collection.chunks
        {
            if untyped_chunk_is_full(&chunk) do continue
            data := untyped_chunk_sub_allocate(&chunk)
            if data == nil do continue

            collection.sub_allocations += 1
            collection.seek = &chunk
            if untyped_chunk_is_full(&chunk) do untyped_collection_seek_to_next(collection)
            return data
        }
    }
    
    return nil
}

untyped_collection_free :: proc(collection: ^Untyped_Collection, data: rawptr)
{
    if collection == nil || data == nil do return

    sync.atomic_mutex_lock(&collection.mutex)
    defer sync.atomic_mutex_unlock(&collection.mutex)

    for &chunk, i in collection.chunks
    {
        if !untyped_chunk_has(&chunk, data) do continue
        if !untyped_chunk_free(&chunk, data) do return
        collection.sub_allocations -= 1
        if untyped_chunk_is_empty(&chunk) && untyped_collection_get_empty_chunk_count(collection) > 1
        {    
            untyped_collection_destroy_chunk(collection, i)
            return
        }

        if cast(uintptr)&chunk < cast(uintptr)chunk.seek do collection.seek = &chunk
        return
    }
}

@(private)
untyped_collection_seek_to_next :: proc(collection: ^Untyped_Collection)
{
    last := untyped_collection_get_last(collection)
    next := mem.ptr_offset(collection.seek, 1)
    uptr_last := uintptr(last)
    uptr_next := uintptr(next)
    collection.seek = transmute(^Untyped_Chunk)min(uptr_next, uptr_last)
}

untyped_collection_get_last :: proc "contextless" (collection: ^Untyped_Collection) -> ^Untyped_Chunk
{
    return &collection.chunks[max(0, len(collection.chunks) - 1)]
}

untyped_collection_is_full :: proc "contextless" (collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks do if !untyped_chunk_is_full(&chunk) do return false
    return true
}

untyped_collection_create_chunk :: proc(collection: ^Untyped_Collection) -> bool
{
    if collection == nil do return false
    chunk, created := untyped_chunk_create(collection.slot_size, collection.slot_data_offset, collection.chunk_capacity, collection.allocator)
    if !created do return false
    append(&collection.chunks, chunk)
    return true
}

untyped_collection_destroy_chunk :: proc(collection: ^Untyped_Collection, index: int) -> bool
{
    if collection == nil || index < 1 do return false
    chunk := &collection.chunks[index]
    if collection.seek == chunk do collection.seek = raw_data(collection.chunks)
    untyped_chunk_destroy(chunk, collection.allocator)
    unordered_remove(&collection.chunks, index)
    return true
}

untyped_collection_get_empty_chunk_count :: proc "contextless" (collection: ^Untyped_Collection) -> int
{
    count := 0
    for &chunk in collection.chunks do if untyped_chunk_is_empty(&chunk) do count += 1
    return count
}

/* SOA Collection */

INVALID_RAW_SOA_COLLECTION_ID :: Raw_SOA_Collection_ID{-1, -1}

Raw_SOA_Collection_ID :: struct
{
    chunk_id: Index_Table_ID,
    element_index: int,
}

SOA_Collection_ID :: struct($Type: typeid, $Fields: int)
where
intrinsics.type_is_named(Type) && 
intrinsics.type_has_field(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) == SOA_Chunk_Element_Used &&
intrinsics.type_struct_field_count(Type) <= Fields
{
    chunk_id: Index_Table_ID,
    element_index: int,
}

SOA_Collection_Descriptor :: struct($Type: typeid, $Fields: int)
where
intrinsics.type_is_named(Type) &&
intrinsics.type_has_field(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) == SOA_Chunk_Element_Used &&
intrinsics.type_struct_field_count(Type) <= Fields
{
    chunk_capacity: int,
    chunk_init: proc(^SOA_Chunk(Type, Fields), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^SOA_Chunk(Type, Fields), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^SOA_Chunk(Type, Fields)) -> int,
    chunk_free: proc "contextless" (^SOA_Chunk(Type, Fields), int) -> bool,
}

SOA_Collection :: struct($Type: typeid, $Fields: int)
where
intrinsics.type_is_named(Type) &&
intrinsics.type_has_field(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) &&
intrinsics.type_field_type(Type, SOA_CHUNK_ELEMENT_USED_FIELD_NAME) == SOA_Chunk_Element_Used &&
intrinsics.type_struct_field_count(Type) <= Fields
{
    using __raw: Raw_SOA_Collection(Fields),
    // alocator: runtime.Allocator,
    // mutex: sync.Atomic_Mutex,
    // seek_id: Index_Table_ID,
    // seek_pointer: ^Raw_SOA_Chunk(Fields),
    // sub_allocations, chunk_capacity: int,
    // chunk_init: proc(^SOA_Chunk(Type, Fields), int, runtime.Allocator) -> bool,
    // chunk_destroy: proc(^SOA_Chunk(Type, Fields), runtime.Allocator) -> bool,
    // chunk_sub_allocate: proc "contextless" (^SOA_Chunk(Type, Fields)) -> int,
    // chunk_free: proc "contextless" (^SOA_Chunk(Type, Fields), int) -> bool,
    // chunks: Index_Table(Raw_SOA_Chunk(Fields)),
}

Raw_SOA_Collection :: struct($Fields: int)
{
    alocator: runtime.Allocator,
    mutex: sync.Atomic_Mutex,
    seek_id: Index_Table_ID,
    seek_pointer: ^Raw_SOA_Chunk(Fields),
    sub_allocations, chunk_capacity: int,
    chunk_init: proc(^Raw_SOA_Chunk(Fields), int, runtime.Allocator) -> bool,
    chunk_destroy: proc(^Raw_SOA_Chunk(Fields), runtime.Allocator) -> bool,
    chunk_sub_allocate: proc "contextless" (^Raw_SOA_Chunk(Fields)) -> int,
    chunk_free: proc "contextless" (^Raw_SOA_Chunk(Fields), int) -> bool,
    chunks: Index_Table(Raw_SOA_Chunk(Fields)),
}

raw_soa_collection_make :: proc "contextless" (descriptor: SOA_Collection_Descriptor($Type, $Fields)) -> Raw_SOA_Collection(Fields)
{
    if descriptor.chunk_capacity < 1 || descriptor.chunk_init == nil || descriptor.chunk_destroy == nil || descriptor.chunk_sub_allocate == nil || descriptor.chunk_free == nil do return {}

    collection: Raw_SOA_Collection(Fields)
    collection.chunk_capacity = descriptor.chunk_capacity
    collection.chunk_init = auto_cast descriptor.chunk_init
    collection.chunk_destroy = auto_cast descriptor.chunk_destroy
    collection.chunk_sub_allocate = auto_cast descriptor.chunk_sub_allocate
    collection.chunk_free = auto_cast descriptor.chunk_free
    return collection
}

raw_soa_collection_init :: proc(collection: ^Raw_SOA_Collection($Fields), initial_capacity := 2, allocator := context.allocator) -> bool
{
    if collection == nil || collection.chunk_capacity < 1 || collection.chunk_init == nil ||  collection.chunk_destroy == nil || collection.chunk_sub_allocate == nil ||  collection.chunk_free == nil do return false

    if !index_table_init(&collection.chunks, initial_capacity, allocator) do return false
    initial_chunk: Raw_SOA_Chunk(Fields)
    
    if !collection.chunk_init(&initial_chunk, collection.chunk_capacity, allocator)
    {
        index_table_destroy(&collection.chunks)
        return false
    }
    id := index_table_append(&collection.chunks, &initial_chunk)
    
    collection.alocator = allocator
    collection.seek_pointer = index_table_get(&collection.chunks, id)
    return true
}

raw_soa_collection_destroy :: proc(collection: ^Raw_SOA_Collection($Fields)) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks.content do collection.chunk_destroy(&chunk, collection.alocator)
    index_table_destroy(&collection.chunks)
    collection^ = {}
    return true
}

raw_soa_collection_sub_allocate :: proc(collection: ^Raw_SOA_Collection($Fields)) -> Raw_SOA_Collection_ID
{
    if collection.sub_allocations == (collection.chunk_capacity * len(collection.chunks.content))
    {
        new_chunk := raw_soa_collection_new_chunk(collection)
        if new_chunk == nil do return INVALID_RAW_SOA_COLLECTION_ID

        element_index := collection.chunk_sub_allocate(new_chunk)
        if element_index > -1
        {
            collection.sub_allocations += 1
            return {new_chunk.__id, element_index}
        }
    }
    else
    {
        {
            seek_pointer := collection.seek_pointer
            element_index := collection.chunk_sub_allocate(seek_pointer)
            if element_index > -1
            {
                //NOTE: dont require to be atomic if we lock the entire proc.
                collection.sub_allocations += 1
                
                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(seek_pointer) do raw_soa_collection_seek_to_next(collection)
                return {seek_pointer.__id, element_index}
            }
        }
        
        for &chunk, index in collection.chunks.content
        {
            if raw_soa_chunk_is_full(&chunk) do continue
            
            element_index := collection.chunk_sub_allocate(&chunk)
            if element_index > -1
            {
                collection.sub_allocations += 1
                collection.seek_id = chunk.__id
                collection.seek_pointer = &chunk

                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(&chunk) do raw_soa_collection_seek_to_next(collection)
                return {chunk.__id, element_index}
            }
        }   
    }

    return INVALID_RAW_SOA_COLLECTION_ID
}

raw_soa_collection_free :: proc(collection: ^Raw_SOA_Collection($Fields), id: Raw_SOA_Collection_ID) -> bool
{
    if !raw_soa_collection_contains_id(collection, id) do return false
    chunk := &collection.chunks.content[index_table_index_of(&collection.chunks, id.chunk_id)]
    freed := collection.chunk_free(chunk, id.element_index)
    if !freed do return false

    collection.sub_allocations -= 1
    if !raw_soa_chunk_is_empty(chunk) do return true
    
    if id.chunk_id == 0 do return true
    empty_chunks := raw_soa_collection_empty_chunks(collection)
    if empty_chunks > 1 do raw_soa_collection_destroy_chunk(collection, id.chunk_id)
    return true
}

raw_soa_collection_empty_chunks :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields)) -> int
{
    count := 0
    for &chunk in collection.chunks.content do if chunk.sub_allocations == 0 do count += 1
    return count
}

raw_soa_collection_is_full :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields)) -> bool
{
    if collection == nil do return false
    for &chunk in collection.chunks.content do if !raw_soa_chunk_is_full(&chunk) do return false
    return true
}

/*
Only for internal use.
*/
@(private)
raw_soa_collection_seek_to_next :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields))
{
    seek_pointer := collection.seek_pointer
    chunks_length := index_table_content_length(&collection.chunks)
    uptr_raw_chunk_size: uintptr = size_of(Raw_SOA_Chunk(Fields))
    uptr_seek_pointer := transmute(uintptr)seek_pointer
    uptr_chunks_begin := transmute(uintptr)raw_data(collection.chunks.content)
    uptr_chunks_end := uintptr(chunks_length * chunks_length) + uptr_chunks_begin
    uptr_last := uptr_chunks_end - uptr_raw_chunk_size
    uptr_next := uptr_seek_pointer + uptr_raw_chunk_size
    if uptr_next > uptr_last do uptr_next = uptr_last
    next := transmute(^Raw_SOA_Chunk(Fields))uptr_next
    collection.seek_id = next.__id
}

@(private)
raw_soa_collection_new_chunk :: proc(collection: ^Raw_SOA_Collection($Fields)) -> ^Raw_SOA_Chunk(Fields)
{
    chunk: Raw_SOA_Chunk(Fields)
    if !collection.chunk_init(&chunk, collection.chunk_capacity, collection.alocator) do return nil

    id := index_table_append(&collection.chunks, &chunk)
    pointer := index_table_get(&collection.chunks, id)
    collection.seek_id = id
    collection.seek_pointer = pointer
    return pointer
}

@(private)
raw_soa_collection_destroy_chunk :: proc(collection: ^Raw_SOA_Collection($Fields), id: Index_Table_ID) -> bool
{
    chunk := index_table_get(&collection.chunks, id)
    if !collection.chunk_destroy(chunk, collection.alocator) do return false
    index_table_remove(&collection.chunks, id)
    if collection.seek_id == id
    {
        collection.seek_id = 0
        collection.seek_pointer = index_table_get(&collection.chunks, 0)
    }
    return true
}

raw_collection_as :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields), $Type: typeid) -> ^SOA_Collection(Type, Fields)
{
    if collection == nil || collection.chunks[0].element_fields != intrinsics.type_struct_field_count(Type) do return nil
    return transmute(^SOA_Collection(Type))collection
}

soa_collection_make :: proc "contextless" (descriptor: SOA_Collection_Descriptor($Type, $Fields)) -> SOA_Collection(Type, Fields)
{
    if descriptor.chunk_capacity < 1 || descriptor.chunk_init == nil || descriptor.chunk_destroy == nil || descriptor.chunk_sub_allocate == nil || descriptor.chunk_free == nil do return {}

    collection: SOA_Collection(Type, Fields)
    collection.chunk_capacity = descriptor.chunk_capacity
    collection.chunk_init = descriptor.chunk_init
    collection.chunk_destroy = descriptor.chunk_destroy
    collection.chunk_sub_allocate = descriptor.chunk_sub_allocate
    collection.chunk_free = descriptor.chunk_free
    return collection
}

raw_soa_collection_contains_id :: proc "contextless" (collection: ^Raw_SOA_Collection($Fields), id: Raw_SOA_Collection_ID) -> bool
{
    if collection == nil || !index_table_contains_id(&collection.chunks, id.chunk_id) || id.element_index < 0 || id.element_index >= collection.chunk_capacity do return false
    return true
}

soa_collection_as_raw :: proc "contextless" (collection: ^SOA_Collection($Type, $Fields)) -> ^Raw_SOA_Collection(Fields)
{
    return transmute(^Raw_SOA_Collection(Fields))collection
}

soa_collection_contains_id :: proc "contextless" (collection: ^SOA_Collection($Type, $Fields), id: SOA_Collection_ID(Type,Fields)) -> bool
{
    if collection == nil || !index_table_contains_id(&collection.chunks, id.chunk_id) || id.element_index < 0 || id.element_index >= collection.chunk_capacity do return false
    return true
}

soa_collection_get :: proc "contextless" (collection: ^SOA_Collection($Type, $Fields), id: SOA_Collection_ID(Type, Fields), element: ^Type) -> bool
{
    if collection == nil || element == nil || !soa_collection_contains_id(collection, id) do return false
    chunk := index_table_get(&collection.chunks, id.chunk_id)
    content := soa_chunk_content(chunk)
    element^ = content[id.element_index]
    return true
}

/*
Does the same as 'raw_soa_collection_sub_allocate'. But here, we "know" the type.
    That means we can make a chunk sub allocation directly.
*/
soa_collection_sub_allocate :: proc(collection: ^SOA_Collection($Type, $Fields)) -> SOA_Collection_ID(Type, Fields)
{
    if collection.sub_allocations == (collection.chunk_capacity * len(collection.chunks.content))
    {
        new_chunk := soa_collection_new_chunk(collection)
        if new_chunk == nil do return {-1, -1}

        element_index := soa_chunk_sub_allocate(transmute(^SOA_Chunk(Type, Fields))new_chunk)
        if element_index > -1
        {
            collection.sub_allocations += 1
            return {new_chunk.__id, element_index}
        }
    }
    else
    {
        {
            seek_pointer := collection.seek_pointer
            element_index := soa_chunk_sub_allocate(transmute(^SOA_Chunk(Type, Fields))seek_pointer)
            if element_index > -1
            {
                //NOTE: dont require to be atomic if we lock the entire proc.
                collection.sub_allocations += 1
                
                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(seek_pointer) do raw_soa_collection_seek_to_next(transmute(^Raw_SOA_Collection(Fields))collection)
                return {seek_pointer.__id, element_index}
            }
        }
        
        for &chunk, index in collection.chunks.content
        {
            if raw_soa_chunk_is_full(&chunk) do continue

            element_index := soa_chunk_sub_allocate(transmute(^SOA_Chunk(Type, Fields))&chunk)
            if element_index > -1
            {
                collection.sub_allocations += 1
                collection.seek_id = chunk.__id
                collection.seek_pointer = &chunk

                //NOTE: only seek to next if the current seek chunk is full.
                if raw_soa_chunk_is_full(&chunk) do raw_soa_collection_seek_to_next(transmute(^Raw_SOA_Collection(Fields))collection)
                return {chunk.__id, element_index}
            }
        }   
    }

    return {-1, -1}
}

soa_collection_free :: proc(collection: ^SOA_Collection($Type, $Fields), id: SOA_Collection_ID(Type, Fields)) -> bool
{
    raw := transmute(^Raw_SOA_Collection(Fields))collection
    if !soa_collection_contains_id(collection, id) do return false
    chunk := &collection.chunks.content[index_table_index_of(&collection.chunks, id.chunk_id)]
    freed := soa_chunk_free(transmute(^SOA_Chunk(Type, Fields))chunk, id.element_index)
    if !freed do return false

    collection.sub_allocations -= 1
    if !raw_soa_chunk_is_empty(chunk) do return true
    
    if id.chunk_id == 0 do return true
    empty_chunks := raw_soa_collection_empty_chunks(raw)
    if empty_chunks > 1 do soa_collection_destroy_chunk(collection, id.chunk_id)
    return true
}

@(private)
soa_collection_new_chunk :: proc(collection: ^SOA_Collection($Type, $Fields)) -> ^Raw_SOA_Chunk(Fields)
{
    chunk: Raw_SOA_Chunk(Fields)
    if !soa_chunk_init(soa_chunk_from_raw(Type, &chunk), collection.chunk_capacity, collection.alocator) do return nil

    id := index_table_append(&collection.chunks, &chunk)
    pointer := index_table_get(&collection.chunks, id)
    collection.seek_id = id
    collection.seek_pointer = pointer
    return pointer
}

@(private)
soa_collection_destroy_chunk :: proc(collection: ^SOA_Collection($Type, $Fields), id: Index_Table_ID) -> bool
{
    chunk := index_table_get(&collection.chunks, id)
    if !soa_chunk_destroy(soa_chunk_from_raw(Type, &chunk), collection.alocator) do return false
    index_table_remove(&collection.chunks, id)
    if collection.seek_id == id
    {
        collection.seek_id = 0
        collection.seek_pointer = index_table_get(&collection.chunks, 0)
    }
    return true
}