package tools

import "core:os"
import "core:strings"

cli_has_flag :: proc(flag: string) -> bool
{
    treated_flag, treated_flag_allocation_error := strings.concatenate({"-", flag}, context.temp_allocator)
    if treated_flag_allocation_error != .None do return false
    defer delete(treated_flag, context.temp_allocator)

    for arg in os.args do if strings.contains(arg, treated_flag) do return true
    return false
}

cli_has_value_flag :: proc(flag: string) -> bool
{
    treated_flag, treated_flag_allocation_error := strings.concatenate({"-", flag, ":"}, context.temp_allocator)
    if treated_flag_allocation_error != .None do return false
    defer delete(treated_flag, context.temp_allocator)

    for arg in os.args do if strings.contains(arg, treated_flag) do return true
    return false
}

cli_get_value_flag :: proc(flag: string) -> string
{
    treated_flag, treated_flag_allocation_error := strings.concatenate({"-", flag, ":"}, context.temp_allocator)
    if treated_flag_allocation_error != .None do return ""
    defer delete(treated_flag, context.temp_allocator)

    for arg in os.args do if strings.contains(arg, treated_flag) do return arg
    return ""
}

cli_get_value_flags :: proc(flag: string, allocator := context.allocator) -> []string
{
    treated_flag, treated_flag_allocation_error := strings.concatenate({"-", flag, ":"}, context.temp_allocator)
    if treated_flag_allocation_error != .None do return nil
    defer delete(treated_flag, context.temp_allocator)
    
    matches, matches_allocation_error := make([dynamic]string, 0, len(os.args), allocator)
    if matches_allocation_error != .None do return nil
    defer delete(matches)

    for arg in os.args do if strings.contains(arg, treated_flag) do append(&matches, arg)

    flags, flags_allocation_error := make([]string, len(matches), allocator)
    if flags_allocation_error != .None do return nil
    for i := 0; i < len(flags); i += 1 do flags[i] = matches[i]
    return flags
}

cli_get_value_flag_values :: proc(flag_name: string) -> (flag, key, value: string)
{
    all_flag := cli_get_value_flag(flag_name)

    double_dots_index := strings.index(all_flag, ":")
    equal_index := strings.index(all_flag, "=")

    flag = all_flag[1 : double_dots_index]
    key = all_flag[double_dots_index + 1 : equal_index]
    value = all_flag[equal_index  + 1:]
    return
}

import "core:fmt"

set_bindings_extension :: proc(path, from_ext, to_ext: string)
{
    directory, open_directory_error := os.open(path)
    if open_directory_error != os.ERROR_NONE do return
    defer os.close(directory)
    
    entries, read_entries_error := os.read_dir(directory, -1, context.temp_allocator)
    if read_entries_error != os.ERROR_NONE do return
    defer delete(entries, context.temp_allocator)
    defer for entry in entries do os.file_info_delete(entry, context.temp_allocator)
    
    for entry in entries
    {
        if entry.is_dir do set_bindings_extension(entry.fullpath, from_ext, to_ext)
        else if strings.contains(entry.name, "_bindings") && strings.contains(entry.name, from_ext)
        {
            old_entry, old_entry_clone_error := strings.clone(entry.fullpath, context.temp_allocator)
            if old_entry_clone_error != .None do continue
            defer delete(old_entry, context.temp_allocator)
            
            new_entry, replace_new_entry_was_allocation := strings.replace(old_entry, from_ext, to_ext, 1, context.temp_allocator)
            defer if replace_new_entry_was_allocation do delete(new_entry, context.temp_allocator)

            os.rename(old_entry, new_entry)
        }
    }
}

main :: proc()
{
    set_bindings_extension("navis", ".nido", ".odin")
    //set_bindings_extension("navis", ".odin", "")

    if cli_has_flag("navis-shared") do build_navis()

    if cli_has_value_flag("module")
    {
        flag, key, value := cli_get_value_flag_values("module")

        build_module(value, key, cli_has_flag("navis-implementation"))
    }
}