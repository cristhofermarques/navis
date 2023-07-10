package tools

import "core:fmt"
import "core:os"
import "core:c/libc"
import "core:strings"
import "core:path/filepath"

build_navis :: proc()
{
    binaries_builder := strings.builder_make(context.temp_allocator)
    defer strings.builder_destroy(&binaries_builder)
    
    strings.write_string(&binaries_builder, "./.binaries/")
    when ODIN_OS == .Windows do strings.write_string(&binaries_builder, "windows/")
    when ODIN_OS == .Linux do strings.write_string(&binaries_builder, "linux/")
    strings.write_string(&binaries_builder, "shared/")
    when ODIN_ARCH == .amd64 do strings.write_string(&binaries_builder, "amd64/")
    when ODIN_DEBUG do strings.write_string(&binaries_builder, "debug/")
    else do strings.write_string(&binaries_builder, "release/")
    binaries := strings.to_string(binaries_builder)

    //Unsure binaries directory
    if !os.is_dir(binaries)
    {
        mkdir_cmd, mkdir_cmd_err := strings.concatenate({"mkdir ", binaries}, context.temp_allocator)
        if mkdir_cmd_err != .None do return
        defer delete(mkdir_cmd, context.temp_allocator)

        s: bool
        mkdir_cmd, s = strings.replace_all(mkdir_cmd, "/", "\\", context.temp_allocator)
        
        cstr_mkdir_cmd, cstr_mkdir_cmd_err := strings.clone_to_cstring(mkdir_cmd, context.temp_allocator)
        if cstr_mkdir_cmd_err != .None do return
        defer delete(cstr_mkdir_cmd, context.temp_allocator)

        libc.system(cstr_mkdir_cmd)
    }

    command_builder := strings.builder_make(context.temp_allocator)
    defer strings.builder_destroy(&command_builder)

    strings.write_string(&command_builder, "odin build navis -build-mode:shared ")

    //Navis collection
    strings.write_string(&command_builder, "-collection:navis=navis ")

    //Binaries collection
    strings.write_string(&command_builder, "-collection:binaries=")
    strings.write_string(&command_builder, strings.to_string(binaries_builder))
    strings.write_string(&command_builder, " ")
    
    strings.write_string(&command_builder, "-define:NAVIS_API_SHARED=true ")
    strings.write_string(&command_builder, "-define:NAVIS_API_EXPORT=true ")
    strings.write_string(&command_builder, "-define:NAVIS_API_VERBOSE=")
    strings.write_string(&command_builder, cli_has_flag("verbose") ? "true " : "false ")
    
    //Output
    strings.write_string(&command_builder, "-out:")
    strings.write_string(&command_builder, strings.to_string(binaries_builder))
    strings.write_string(&command_builder, "navis")
    when ODIN_OS == .Windows do strings.write_string(&command_builder, ".dll")
    when ODIN_OS == .Linux do strings.write_string(&command_builder, ".so")

    cstr_command, cstr_command_allocation_error := strings.clone_to_cstring(strings.to_string(command_builder), context.temp_allocator)
    if cstr_command_allocation_error != .None do return
    defer delete(cstr_command, context.temp_allocator)

    fmt.println(cstr_command)

    libc.system(cstr_command)
}

build_module :: proc(directory, name: string, navis_implementation: bool)
{
    binaries_builder := strings.builder_make(context.temp_allocator)
    defer strings.builder_destroy(&binaries_builder)
    
    strings.write_string(&binaries_builder, "./.binaries/")
    when ODIN_OS == .Windows do strings.write_string(&binaries_builder, "windows/")
    when ODIN_OS == .Linux do strings.write_string(&binaries_builder, "linux/")
    strings.write_string(&binaries_builder, "shared/")
    when ODIN_ARCH == .amd64 do strings.write_string(&binaries_builder, "amd64/")
    when ODIN_DEBUG do strings.write_string(&binaries_builder, "debug/")
    else do strings.write_string(&binaries_builder, "release/")
    binaries := strings.to_string(binaries_builder)

    //Unsure binaries directory
    if !os.is_dir(binaries)
    {
        mkdir_cmd, mkdir_cmd_err := strings.concatenate({"mkdir ", binaries}, context.temp_allocator)
        if mkdir_cmd_err != .None do return
        defer delete(mkdir_cmd, context.temp_allocator)

        s: bool
        mkdir_cmd, s = strings.replace_all(mkdir_cmd, "/", "\\", context.temp_allocator)
        
        cstr_mkdir_cmd, cstr_mkdir_cmd_err := strings.clone_to_cstring(mkdir_cmd, context.temp_allocator)
        if cstr_mkdir_cmd_err != .None do return
        defer delete(cstr_mkdir_cmd, context.temp_allocator)

        libc.system(cstr_mkdir_cmd)
    }

    command_builder := strings.builder_make(context.temp_allocator)
    defer strings.builder_destroy(&command_builder)

    strings.write_string(&command_builder, "odin build ")
    strings.write_string(&command_builder, directory)
    strings.write_string(&command_builder, " -build-mode:shared ")

    //Navis collection
    strings.write_string(&command_builder, "-collection:navis=navis ")

    //Binaries collection
    strings.write_string(&command_builder, "-collection:binaries=")
    strings.write_string(&command_builder, strings.to_string(binaries_builder))
    strings.write_string(&command_builder, " ")
    
    strings.write_string(&command_builder, "-define:NAVIS_API_SHARED=")
    strings.write_string(&command_builder, navis_implementation ? "false " : "true ")

    strings.write_string(&command_builder, "-define:NAVIS_API_EXPORT=")
    strings.write_string(&command_builder, navis_implementation ? "true " : "false ")

    strings.write_string(&command_builder, "-define:NAVIS_API_VERBOSE=")
    strings.write_string(&command_builder, cli_has_flag("verbose") ? "true " : "false ")
    
    //Output
    strings.write_string(&command_builder, "-out:")
    strings.write_string(&command_builder, strings.to_string(binaries_builder))
    strings.write_string(&command_builder, name)
    when ODIN_OS == .Windows do strings.write_string(&command_builder, ".dll")
    when ODIN_OS == .Linux do strings.write_string(&command_builder, ".so")

    cstr_command, cstr_command_allocation_error := strings.clone_to_cstring(strings.to_string(command_builder), context.temp_allocator)
    if cstr_command_allocation_error != .None do return
    defer delete(cstr_command, context.temp_allocator)

    fmt.println(cstr_command)

    libc.system(cstr_command)
}