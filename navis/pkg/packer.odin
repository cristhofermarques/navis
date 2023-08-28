package pkg

import "core:bytes"
import "core:os"
import "core:path/filepath"
import "core:io"
import "core:strings"
import "core:slice"
import "core:fmt"

Packer :: map[string][]byte

packer_init :: proc(pack: ^Packer, intial_capacity := 1, allocator := context.allocator) -> bool
{
    pack_, pack_allocation_error := make_map(Packer, intial_capacity, allocator)
    pack^ = pack_
    return pack_allocation_error == .None
}

packer_destroy :: proc(pack: ^Packer) -> bool
{
    if pack == nil do return false
    delete_map(pack^)
    pack^ = {}
    return true
}

packer_contains :: proc "contextless" (pack: ^Packer, name: string) -> bool
{
    if pack == nil || name == "" do return false
    return pack[name] != nil
}

packer_add :: proc(pack: ^Packer, name: string, content: []byte) -> bool
{
    if pack == nil || name == "" || content == nil || packer_contains(pack, name) do return false
    pack[name] = content
    return true
}

packer_remove :: proc(pack: ^Packer, name: string) -> bool
{
    if pack == nil || name == "" || !packer_contains(pack, name) do return false
    delete_key(pack, name)
    return true
}

pack_packer :: proc(packer: Packer, name: string, stream: io.Stream) -> bool
{
    if packer == nil || len(packer) < 1 do return false
    
    //Package magic
    io.write_string(stream, MAGIC)

    //Package name
    name_length := len(name)
    io.write_ptr(stream, &name_length, size_of(int))
    io.write_string(stream, name)

    //Fields count
    fields_count := len(packer)
    io.write_ptr(stream, &fields_count, size_of(int))

    offset := 0
    for field_name, &field_data in packer
    {
        //Field name
        field_name_lenth := len(field_name)
        io.write_ptr(stream, &field_name_lenth, size_of(int))
        io.write_string(stream, field_name)

        //Field data info
        io.write_ptr(stream, &offset, size_of(int))

        field_data_size := len(field_data)
        io.write_ptr(stream, &field_data_size, size_of(int))
        
        offset += field_data_size
    }

    for field_name, &field_data in packer
    {
        //Field data
        io.write_ptr(stream, raw_data(field_data), len(field_data))
    }

    return true
}

package_ignore_get_text :: proc(directory_path: string, allocator := context.allocator) -> string
{
    if !os.is_dir(directory_path) do return ""
    ignore_file_path := filepath.join({directory_path, IGNORE}, context.temp_allocator)
    ignore_buffer, readed := os.read_entire_file_from_filename(ignore_file_path, allocator)
    return transmute(string)ignore_buffer
}

package_ignore_split_text :: proc(ignore_text: string, allocator := context.allocator) -> []string
{
    if ignore_text == "" do return nil
    splits, error := strings.split_lines(ignore_text, allocator)
    return splits
}

package_ignore_can_ignore :: proc(ignore_list: []string, path: string) -> bool
{
    if path == IGNORE do return true
    if ignore_list == nil do return false
    for ignore in ignore_list do if strings.contains(path, ignore) do return true
    return false
}

@(private)
package_ignore_get_files_recursive :: proc(paths: ^[dynamic]string, ignore_list: []string, path: string, allocator := context.allocator)
{
    if !os.is_dir(path) do return

    dh, dh_err := os.open(path)
    if dh_err != os.ERROR_NONE do return
    defer os.close(dh)

    infos, infos_err := os.read_dir(dh, 0, context.temp_allocator)
    if infos_err != os.ERROR_NONE do return

    for &info in infos
    {
        if info.is_dir
        {
            package_ignore_get_files_recursive(paths, ignore_list, info.fullpath, allocator)
        }
        else if !package_ignore_can_ignore(ignore_list, info.name)
        {
            clone, clone_err := strings.clone(info.fullpath, allocator)
            if clone_err != .None do continue
            append(paths, clone)
        }
    }
}

package_ignore_get_paths :: proc(directory_path: string, allocator := context.allocator) -> []string
{
    if !os.is_dir(directory_path) do return nil

    ignore_text := package_ignore_get_text(directory_path, context.temp_allocator)
    ignore_list := package_ignore_split_text(ignore_text, context.temp_allocator)

    dyn_paths, dyn_paths_err := make([dynamic]string, 0, 100, context.temp_allocator)
    package_ignore_get_files_recursive(&dyn_paths, ignore_list, directory_path, allocator)

    paths, paths_err := make([]string, len(dyn_paths), allocator)
    if paths_err != .None do return nil
    for &p, i in dyn_paths do paths[i] = p
    return paths
}

/*
Pack a directory from provided path.
* If not set a value to 'package_name' parameter, the package name will be the directory name.
*/
pack_directory :: proc(directory_path: string, package_name := "", stream: io.Stream) -> bool
{
    if !os.is_dir(directory_path) do return false
    paths := package_ignore_get_paths(directory_path, context.temp_allocator)

    //Package magic
    io.write_string(stream, MAGIC)
    
    //Package name
    name := package_name != "" ? package_name : filepath.base(directory_path)
    name_length := len(name)
    io.write_ptr(stream, &name_length, size_of(int))
    io.write_string(stream, name)

    //Fields count
    fields_count := len(paths)
    io.write_ptr(stream, &fields_count, size_of(int))

    offset := 0
    for path in paths
    {
        path_base := filepath.base(path)

        //Field name
        field_name := path_base[0:strings.index(path_base, filepath.ext(path_base))]
        field_name_lenth := len(field_name)
        io.write_ptr(stream, &field_name_lenth, size_of(int))
        io.write_string(stream, field_name)

        //Field data info
        io.write_ptr(stream, &offset, size_of(int))

        field_data_size := int(os.file_size_from_path(path))
        io.write_ptr(stream, &field_data_size, size_of(int))
        
        offset += field_data_size
    }

    for path in paths
    {
        //Field data
        field_data, readed_field_data := os.read_entire_file_from_filename(path, context.temp_allocator)
        io.write_ptr(stream, raw_data(field_data), len(field_data))
    }

    return true
}