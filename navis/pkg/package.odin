package pkg

import "core:io"
import "core:strings"
import "core:runtime"
import "core:fmt"

MAGIC :: "PKG"
EXTENSION :: ".pkg"
IGNORE :: "package_ignore"

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

Package_Asset_Seek :: struct
{
    offset, size: int,
}

Package_Asset_Info :: struct
{
    asset: Package_Field,
    seek: Package_Asset_Seek,
}

Package_Path :: string
Package_Pointer :: ^Package

Package_Reference :: union
{
    Package_Path,
    Package_Pointer,
}

/*
Populate a package structure from data.
* The only one allocation made is for the package.fields slice.
*/
from_data :: proc(data: []byte, allocator := context.allocator) -> (pkg: Package)
{
    if data == nil do return

    //Magic
    seek := 0
    if strings.compare(transmute(string)data[seek:3], MAGIC) != 0 do return
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

/*
Return the package name.
* Allocate using the provided allocator
*/
package_name :: proc(stream: io.Stream, allocator := context.allocator) -> string
{
    //Seek to begin
    seeker, _ := io.to_seeker(stream)
    io.seek(seeker, 0, .Start)

    //Magic
    magic: [3]byte
    io.read(stream, magic[:])
    if strings.compare(transmute(string)magic[:], MAGIC) != 0 do return ""

    //Package name length
    package_name_length := -1
    io.read_ptr(stream, &package_name_length, size_of(int))
    
    //Package name
    package_name, package_name_allocation_error := make([]byte, package_name_length, allocator)
    if package_name_allocation_error != .None do return ""
    io.read(stream, package_name)
    return transmute(string)package_name
}

/*
Maps seek informations of package assets.
* If 'stream_seek' is 'true' the seek info is relative to entire stream beginning to the asset seek.
*/
map_seeks :: proc(stream: io.Stream, seeks: ^map[string]Package_Asset_Seek_Info, stream_seek := true) -> bool
{
    //Seek to begin
    seeker, _ := io.to_seeker(stream)
    io.seek(seeker, 0, .Start)

    //Magic
    seek := 0 //NOTE: will be our offset info for data
    magic: [3]byte
    io.read(stream, magic[:])
    if strings.compare(transmute(string)magic[:], MAGIC) != 0 do return false
    seek += 3

    //Package name length
    package_name_length := -1
    io.read_ptr(stream, &package_name_length, size_of(int))
    seek += size_of(int)
    
    //Package name
    package_name, package_name_allocation_error := make([]byte, package_name_length, context.temp_allocator)
    io.read(stream, package_name)
    seek += package_name_length
    
    //Package fields length
    package_fields_length := -1
    io.read_ptr(stream, &package_fields_length, size_of(int))
    seek += size_of(int)

    infos, infos_err := make_slice([]Package_Asset_Info, package_fields_length, context.temp_allocator)
    if infos_err != .None do return false
    
    for index := 0; index < package_fields_length; index += 1
    {
        //Field name length
        field_name_length := -1
        io.read_ptr(stream, &field_name_length, size_of(int))
        seek += size_of(int)
        
        //Package name
        field_name, field_name_allocation_error := make([]byte, field_name_length, context.temp_allocator)
        io.read(stream, field_name)
        seek += field_name_length

        //Field data offset
        field_data_offset := -1
        io.read_ptr(stream, &field_data_offset, size_of(int))
        seek += size_of(int)

        //Field data size
        field_data_size := -1
        io.read_ptr(stream, &field_data_size, size_of(int))
        seek += size_of(int)

        info: Package_Asset_Info
        info.asset.name = transmute(string)field_name
        info.seek.offset = field_data_offset
        info.seek.size = field_data_size
        infos[index] = info
    }

    for &info in infos do seeks[info.asset.name] = {"", stream_seek ? seek + info.seek.offset : info.seek.offset, info.seek.size}
    return true
}