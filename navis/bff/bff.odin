package bff

import "core:runtime"
import "core:reflect"
import "core:strings"
import "core:bytes"
import "core:mem"

Field :: struct
{
    name: string,
    data: rawptr,
    size: int,
}

/*
*/
marshal :: proc(buffer: ^bytes.Buffer, x: $T)
{
    marshal_recursive(buffer, T, x, "")
}

@(private)
marshal_recursive :: proc(b: ^bytes.Buffer, id: typeid, parent: any, parent_name: string)
{
    fields := reflect.struct_fields_zipped(id)
    for field in fields
    {
        separator := len(parent_name) == 0 ? "" : "."
        field_path := strings.concatenate({parent_name, separator, field.name}, context.temp_allocator)
        field_path_len := len(field_path)
        field_value := reflect.struct_field_value_by_name(parent, field.name)
        
        if reflect.is_struct(field.type)
        {
            marshal_recursive(b, field.type.id, field_value, field_path)
        }
        else if reflect.is_array(field.type) || reflect.is_slice(field.type)
        {
            if reflect.is_nil(field_value) do continue
            field_data, _ := reflect.as_raw_data(field_value)
            length := reflect.length(field_value)
            typeid_el := reflect.typeid_elem(field.type.id)
            sizeof_el := reflect.size_of_typeid(typeid_el)
            data_size := length * sizeof_el

            //Field name
            bytes.buffer_write_ptr(b, &field_path_len, size_of(int))
            bytes.buffer_write_ptr(b, raw_data(field_path), field_path_len)

            //Field data
            bytes.buffer_write_ptr(b, &data_size, size_of(int))
            bytes.buffer_write_ptr(b, field_data, data_size)
        }
        else if reflect.is_integer(field.type) || reflect.is_float(field.type) || reflect.is_boolean(field.type)
        {
            data := reflect.as_bytes(field_value)

            //Field name
            bytes.buffer_write_ptr(b, &field_path_len, size_of(int))
            bytes.buffer_write_ptr(b, raw_data(field_path), field_path_len)

            //Field data
            bytes.buffer_write_ptr(b, &field.type.size, size_of(int))
            bytes.buffer_write_ptr(b, raw_data(data), field.type.size)
        }
    }
}

get_fields :: proc(data: []byte, allocator := context.allocator) -> []Field
{
    dyn_fields, dyn_fields_alloc_err := make([dynamic]Field, 0, 10, context.temp_allocator)
    if dyn_fields_alloc_err != .None do return nil

    for i := 0; i < len(data);
    {
        name_len := (transmute(^int)&data[i])^

        i += size_of(int)
        name_ptr := &data[i]
        
        i += name_len
        data_len := (transmute(^int)&data[i])^

        i += size_of(int)
        data_ptr := &data[i]

        i += data_len

        name: runtime.Raw_String
        name.data = name_ptr
        name.len = name_len

        field: Field
        field.name = transmute(string)name
        field.data = data_ptr
        field.size = data_len
        append(&dyn_fields, field)
    }

    fields_len := len(dyn_fields)
    fields, fields_alloc_err := make([]Field, fields_len, allocator)
    for i := 0; i < fields_len; i += 1 do fields[i] = dyn_fields[i]
    return fields
}

unmarshal :: proc(data: []byte, x: ^$T)
{
    fields := get_fields(data, context.temp_allocator)
    unmarshal_recursive(fields, T, x^, "")
}

@(private)
unmarshal_recursive :: proc(fields: []Field, id: typeid, parent: any, parent_name: string)
{
    sep := len(parent_name) == 0 ? "" : "."
    sfs := reflect.struct_fields_zipped(id)
    for sf in sfs
    {
        sf_path := strings.concatenate({parent_name, sep, sf.name}, context.temp_allocator)
        sf_path_len := len(sf_path)
        sf_value := reflect.struct_field_value_by_name(parent, sf.name)

        for f in fields do if reflect.is_struct(sf.type)
        {
            unmarshal_recursive(fields, sf.type.id, sf_value, sf_path)
        }
        else if f.name == sf_path
        {
            if reflect.is_slice(sf.type)
            {
                raw := transmute(runtime.Raw_Any)sf_value
                raw_slice := transmute(^runtime.Raw_Slice)raw.data
                length := f.size / reflect.size_of_typeid(reflect.typeid_elem(sf.type.id))
                raw_slice.data = f.data
                raw_slice.len = length
                break
            }
            else if reflect.is_array(sf.type) || reflect.is_integer(sf.type) || reflect.is_float(sf.type) || reflect.is_boolean(sf.type)
            {
                raw := transmute(runtime.Raw_Any)sf_value
                mem.copy(raw.data, f.data, f.size)
                raw.id = sf.type.id
                break
            }
        }
    }
}