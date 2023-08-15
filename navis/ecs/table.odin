package ecs

import "core:intrinsics"

TABLE_ID_FIELD_NAME :: "__id"

Table_ID :: int

Table :: struct($T: typeid)
where
intrinsics.type_has_field(T, TABLE_ID_FIELD_NAME) &&
intrinsics.type_field_type(T, TABLE_ID_FIELD_NAME) == Table_ID
{
    indices: [dynamic]int,
    content: [dynamic]T,
}

table_init :: proc(table: ^Table($T), initial_capacity: int, allocator := context.allocator) -> bool
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

table_destroy :: proc(table: ^Table($T)) -> bool
{
    delete(table.indices)
    delete(table.content)
    table^ = {}
    return true
}

table_index_of :: proc "contextless" (table: ^Table($T), id: Table_ID) -> int
{
    if id < 0 || id >= len(table.indices) do return -1
    return table.indices[id]
}

table_contains_id :: proc "contextless" (table: ^Table($T), id: Table_ID) -> bool
{
    if id < 0 || id >= len(table.indices) do return false
    return table.indices[id] != -1
}

table_get :: proc "contextless" (table: ^Table($T), id: Table_ID) -> ^T
{
    if id < 0 || id >= len(table.indices) do return nil
    index := table.indices[id]
    if index == -1 do return nil
    return &table.content[index]
}

table_content_length :: proc "contextless" (table: ^Table($T)) -> int
{
    return len(table.content)
}

/*
Only for internal use.
*/
@(private)
table_acquire_id :: proc(table: ^Table($T)) -> Table_ID
{
    for index, index_index in table.indices do if index == -1 do return index_index
    append_nothing(&table.indices)
    return len(table.indices) - 1
}

table_append :: proc(table: ^Table($T), value: ^T) -> Table_ID
{
    id := table_acquire_id(table)
    value.__id = id
    append_elem(&table.content, value^)
    index := len(table.content) - 1
    table.indices[id] = index
    return id
}

table_remove :: proc(table: ^Table($T), id: Table_ID) -> bool
{
    index := table_index_of(table, id)
    unordered_remove(&table.content, index)
    table.indices[id] = -1
    for &element, index in table.content do table.indices[element.__id] = index
    return true
}