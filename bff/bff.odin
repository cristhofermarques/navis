package bff

import "core:runtime"
import "core:reflect"
import "core:strings"
import "core:mem"
import "core:io"
import "core:log"

@(private)
VERBOSE :: #config(BFF_VERBOSE, false)
MAGIC :: "BFF"
TYPE_NAME_FIELD_PATH :: "@type"

name_of :: proc($T: typeid) -> string
{
    info := type_info_of(T)
    named := info.variant.(runtime.Type_Info_Named)
    return named.name
}

write_field_string :: proc(stream: io.Stream, name, text: string)
{
    name_len := len(name) * size_of(byte)
    io.write_ptr(stream, &name_len, size_of(int))
    io.write_ptr(stream, raw_data(name), len(name) * size_of(u8))
    
    text_len := len(text) * size_of(byte)
    io.write_ptr(stream, &text_len, size_of(int))
    io.write_ptr(stream, raw_data(text), len(text) * size_of(u8))
}

write_field_data :: proc(stream: io.Stream, name: string, data: rawptr, size: int)
{
    name_len := len(name) * size_of(byte)
    io.write_ptr(stream, &name_len, size_of(int))
    io.write_ptr(stream, raw_data(name), len(name) * size_of(u8))

    size := size
    io.write_ptr(stream, &size, size_of(int))
    io.write_ptr(stream, data, size)
}

write_field_bytes :: proc(stream: io.Stream, name: string, bytes: []byte)
{
    name_len := len(name) * size_of(byte)
    io.write_ptr(stream, &name_len, size_of(int))
    io.write_ptr(stream, raw_data(name), len(name) * size_of(u8))

    data_size := len(bytes) * size_of(byte)
    io.write_ptr(stream, &data_size, size_of(int))
    io.write_ptr(stream, raw_data(bytes), data_size)
}

/*
Marshal to stream from structure.
*/
marshal :: proc(stream: io.Stream, x: ^$T)
{
    io.write_string(stream, MAGIC)
    if reflect.type_kind(typeid_of(T)) == .Named do write_field_string(stream, "@type", name_of(T))
    marshal_recursive(stream, runtime.Raw_Any{x, typeid_of(T)}, "", "")
}

@(private)
marshal_recursive :: proc(stream: io.Stream, raw_struct: runtime.Raw_Any, parent_name: string, separator := ".")
{
    fields := reflect.struct_fields_zipped(raw_struct.id)
    for &field in fields
    {
        field_path := strings.concatenate({parent_name, separator, field.name}, context.temp_allocator)
        field_value := reflect.struct_field_value_by_name(transmute(any)raw_struct, field.name)
        
        if reflect.is_struct(field.type)
        {
            raw_field_value := transmute(runtime.Raw_Any)field_value
            marshal_recursive(stream, raw_field_value, field_path)
        }
        else if reflect.is_array(field.type) || reflect.is_slice(field.type)
        {
            if reflect.is_nil(field_value)
            {
                when VERBOSE do log.info("Skipping 'nil' array field", field_path, field_value)
                continue
            }

            array_data, valid_array_data := reflect.as_raw_data(field_value)
            if !valid_array_data
            {
                when VERBOSE do log.warn("Failed to get array field data", field_path, field_value)
                continue
            }

            array_length := reflect.length(field_value)
            array_element_typeid := reflect.typeid_elem(field.type.id)
            array_element_size := reflect.size_of_typeid(array_element_typeid)
            array_size := array_length * array_element_size
            write_field_data(stream, field_path, array_data, array_size)
        }
        else if reflect.is_integer(field.type) || reflect.is_float(field.type) || reflect.is_boolean(field.type)
        {
            data := reflect.as_bytes(field_value)
            write_field_bytes(stream, field_path, data)
        }
    }
}

/*
Return type name ´@type´ from bff data.
* No allocation, the return string is referenced from bff data
*/
type_name :: proc(data: []byte) -> string
{
    magic := transmute(string)data[0:3]
    if magic != "BFF"
    {
        when VERBOSE do log.warn("File magic string dont match with bff magic")
        return ""
    }
    
    seek := 3
    type_name_field_path_length := (transmute(^int)&data[seek])^
    if type_name_field_path_length != len(TYPE_NAME_FIELD_PATH)
    {
        when VERBOSE do log.warn("Invalid type name field path lengh,", type_name_field_path_length, "vs", len(TYPE_NAME_FIELD_PATH))
        return ""
    }
    seek += size_of(int)
    
    type_name_field_path := transmute(string)runtime.Raw_String{&data[seek], type_name_field_path_length}
    if type_name_field_path != TYPE_NAME_FIELD_PATH
    {
        when VERBOSE do log.warn("Invalid type name field path,", type_name_field_path, "vs", TYPE_NAME_FIELD_PATH)
        return ""
    }
    seek += type_name_field_path_length

    type_name_field_value_length := (transmute(^int)&data[seek])^
    if type_name_field_value_length < 1
    {
        when VERBOSE do log.warn("Invalid type name field value lengh", type_name_field_value_length)
        return ""
    }
    seek += size_of(int)

    return transmute(string)runtime.Raw_String{&data[seek], type_name_field_value_length}
}

/*
Map all bff fields from bff data.
* No allocation, fields data references the bff data.
*/
map_fields :: proc(data: []byte, initial_capacity := 100, allocator := context.allocator) -> map[string][]byte
{
    fields, fields_allocation_error := make_map(map[string][]byte, initial_capacity, allocator)
    if fields_allocation_error != .None
    {
        when VERBOSE do log.error("Failed to make fields map", fields_allocation_error)
        return nil
    }

    for seek := 3; seek < len(data);
    {
        field_path_length := (transmute(^int)&data[seek])^
        seek += size_of(int)
        
        field_path := transmute(string)runtime.Raw_String{&data[seek], field_path_length}
        seek += field_path_length
        
        field_data_size := (transmute(^int)&data[seek])^
        seek += size_of(int)
        
        field_data := transmute([]byte)runtime.Raw_Slice{&data[seek], field_data_size}
        seek += field_data_size

        fields[field_path] = field_data
    }

    return fields
}

/*
Unmarshal to structure from data.
* No allocation, slices references the bff data.
*/
unmarshal :: proc(data: []byte, x: ^$T)
{
    fields := map_fields(data, 100, context.temp_allocator)
    if fields == nil do return
    unmarshal_recursive(&fields, runtime.Raw_Any{x, typeid_of(T)}, "", "")
}

@(private)
unmarshal_recursive :: proc(fields: ^map[string][]byte, raw_struct: runtime.Raw_Any, parent_name: string, separator := ".")
{
    struct_fields := reflect.struct_fields_zipped(raw_struct.id)
    for struct_field in struct_fields
    {
        struct_field_path := strings.concatenate({parent_name, separator, struct_field.name}, context.temp_allocator)
        struct_field_value := reflect.struct_field_value_by_name(transmute(any)raw_struct, struct_field.name)
        raw_any_struct_field_value := transmute(runtime.Raw_Any)struct_field_value

        if reflect.is_struct(struct_field.type) do unmarshal_recursive(fields, raw_any_struct_field_value, struct_field_path)
        else if field_data := fields[struct_field_path]; field_data != nil
        {
            if reflect.is_slice(struct_field.type)
            {
                raw_struct_field_value := transmute(^runtime.Raw_Slice)raw_any_struct_field_value.data
                length := len(field_data) / reflect.size_of_typeid(reflect.typeid_elem(struct_field.type.id))
                raw_struct_field_value.data = raw_data(field_data)
                raw_struct_field_value.len = length
                break
            }
            else if reflect.is_array(struct_field.type) || reflect.is_integer(struct_field.type) || reflect.is_float(struct_field.type) || reflect.is_boolean(struct_field.type)
            {
                mem.copy(raw_any_struct_field_value.data, raw_data(field_data), len(field_data))
                raw_any_struct_field_value.id = struct_field.type.id
                break
            }
        }
    }
}