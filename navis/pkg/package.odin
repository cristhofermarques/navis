package pkg

import "core:strings"
import "core:runtime"
import "core:fmt"

MAGIC :: "PKG"
EXTENSION :: ".pkg"
IGNORE :: ".package_ignore"

Package_Field :: struct
{
    name: string,
    data: []byte,
}

Package :: struct
{
    name: string,
    //compressed, encrypted: bool,
    fields: []Package_Field,
}

Package_Path :: string
Package_Pointer :: ^Package

Package_Reference :: union
{
    Package_Path,
    Package_Pointer,
}

/*
* The only one allocation made is for the package.fields slice.
*/
from_data :: proc(data: []byte, allocator := context.allocator) -> (pkg: Package)
{
    if data == nil do return

    //Magic
    seek := 0
    if strings.compare(transmute(string)data[seek:3], MAGIC) != 0 do return {}
    seek += 3

    //Package name length
    package_name_length := (transmute(^int)&data[seek])^
    seek += size_of(int)

    package_name_data := &data[seek]
    seek += package_name_length

    raw_pakage_name: runtime.Raw_String
    raw_pakage_name.len = package_name_length
    raw_pakage_name.data = package_name_data
    
    fields_length := (transmute(^int)&data[seek])^
    seek += size_of(int)

    Package_Field_Info :: struct
    {
        using _field: Package_Field,
        offset, size: int,
    }

    infos, infos_err := make_slice([]Package_Field_Info, fields_length, context.temp_allocator)
    if infos_err != .None do return
    
    for index := 0; index < fields_length; index += 1
    {
        field_name_length := (transmute(^int)&data[seek])^
        seek += size_of(int)
        
        field_name_data := &data[seek]
        seek += field_name_length
        
        field_data_offset := (transmute(^int)&data[seek])^
        seek += size_of(int)

        field_data_size := (transmute(^int)&data[seek])^
        seek += size_of(int)

        raw_field_name: runtime.Raw_String
        raw_field_name.len = field_name_length
        raw_field_name.data = field_name_data

        field: Package_Field_Info
        field.name = transmute(string)raw_field_name
        field.offset = field_data_offset
        field.size = field_data_size
        infos[index] = field
    }

    for &field in infos
    {
        field_data: runtime.Raw_Slice
        field_data.len = field.size
        field_data.data = &data[seek + field.offset]
        field.data = transmute([]byte)field_data
    }

    fields, fields_err := make_slice([]Package_Field, fields_length, allocator)
    if fields_err != .None do return
    for &info, i in infos do fields[i] = info._field

    pkg.name = transmute(string)raw_pakage_name
    pkg.fields = fields
    return
}

// map_package :: proc(pkg: ^Package, allocator := context.al) -> map[string][]byte
// {
    
// }