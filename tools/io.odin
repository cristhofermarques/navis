package tools

import "core:strings"
import "core:path/filepath"

io_get_root_directory :: proc(allocator := context.allocator) -> string
{
    tools_directory := io_get_tools_directory(context.temp_allocator)
    defer delete(tools_directory, context.temp_allocator)
    return filepath.join({tools_directory, ".."}, allocator)
}

io_get_tools_directory :: proc(allocator := context.allocator) -> string
{
    return filepath.dir(#file, allocator)
}

io_get_navis_directory :: proc(allocator := context.allocator) -> string
{
    tools_directory := io_get_tools_directory(context.temp_allocator)
    defer delete(tools_directory, context.temp_allocator)

    navis_directory, navis_directory_was_allocation := strings.replace(tools_directory, "tools", "navis", 1, allocator)
    if navis_directory_was_allocation do return navis_directory
    else
    {
        clone_navis_directory, clone_navis_directory_error := strings.clone(navis_directory, allocator)
        return clone_navis_directory
    }
}