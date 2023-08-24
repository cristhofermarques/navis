package navis_mem

import "core:intrinsics"

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