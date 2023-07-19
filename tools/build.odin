package tools

import "core:os"
import "core:c/libc"
import "core:strings"
import "core:path/filepath"

Navis_Build_Descriptor :: struct
{
    collection, implementation, export, bindings, module, verbose: bool,
}

Module_Build_Descriptor :: struct
{
    navis_build_mode: Build_Mode,
    navis_collection, debug, verbose: bool,
}

command_write_navis_build_descritor :: proc(builder: ^strings.Builder, descriptor: Navis_Build_Descriptor)
{
    navis_directory := io_get_navis_directory(context.temp_allocator)
    defer delete(navis_directory, context.temp_allocator)

    //Collection
    if descriptor.collection
    {
        strings.write_string(builder, "-collection:")
        strings.write_string(builder, "navis")
        strings.write_string(builder, "=")
        strings.write_string(builder, navis_directory)
        strings.write_string(builder, " ")
    }

    //Implementation
    strings.write_string(builder, "-define:")
    strings.write_string(builder, "NAVIS_IMPLEMENTATION")
    strings.write_string(builder, "=")
    strings.write_string(builder, descriptor.implementation ? "true" : "false")
    strings.write_string(builder, " ")
    
    //Export
    strings.write_string(builder, "-define:")
    strings.write_string(builder, "NAVIS_EXPORT")
    strings.write_string(builder, "=")
    strings.write_string(builder, descriptor.export ? "true" : "false")
    strings.write_string(builder, " ")
    
    //Bindings
    strings.write_string(builder, "-define:")
    strings.write_string(builder, "NAVIS_BINDINGS")
    strings.write_string(builder, "=")
    strings.write_string(builder, descriptor.bindings ? "true" : "false")
    strings.write_string(builder, " ")
    
    //Module
    strings.write_string(builder, "-define:")
    strings.write_string(builder, "NAVIS_MODULE")
    strings.write_string(builder, "=")
    strings.write_string(builder, descriptor.module ? "true" : "false")
    strings.write_string(builder, " ")

    //Verbose
    strings.write_string(builder, "-define:")
    strings.write_string(builder, "NAVIS_VERBOSE")
    strings.write_string(builder, "=")
    strings.write_string(builder, descriptor.verbose ? "true" : "false")
    strings.write_string(builder, " ")
}

command_submit :: proc(builder: ^strings.Builder)
{
    command := strings.to_string(builder^)
    cstr_command, cstr_command_allocation_error := strings.clone_to_cstring(command, context.temp_allocator)
    if cstr_command_allocation_error != .None do return
    defer delete(cstr_command, context.temp_allocator)
    libc.system(cstr_command)
}

Build_Mode :: enum
{
    Shared,
    Embedded,
}

build_navis_module :: proc(debug, verbose: bool)
{
    command := strings.builder_make(context.temp_allocator)
    defer strings.builder_destroy(&command)

    root_directory := io_get_root_directory(context.temp_allocator)
    defer delete(root_directory, context.temp_allocator)

    navis_directory := io_get_navis_directory(context.temp_allocator)
    defer delete(navis_directory, context.temp_allocator)

    when ODIN_OS == .Windows do out_path := filepath.join({root_directory, "navis.dll"}, context.temp_allocator)
    when ODIN_OS == .Linux do out_path := filepath.join({root_directory, "navis.so"}, context.temp_allocator)
    defer delete(out_path, context.temp_allocator)

    //Build navis
    strings.write_string(&command, "odin build")
    strings.write_string(&command, " ")
    strings.write_string(&command, navis_directory)
    strings.write_string(&command, " ")
    
    //Build mode
    strings.write_string(&command, "-build-mode:shared")
    strings.write_string(&command, " ")
    
    //Debug
    if debug
    {
        strings.write_string(&command, "-debug")
        strings.write_string(&command, " ")
    }
    
    //Defines
    descriptor: Navis_Build_Descriptor
    descriptor.implementation = true
    descriptor.export = true
    descriptor.verbose = verbose
    command_write_navis_build_descritor(&command, descriptor)

    command_submit(&command)

    when ODIN_OS == .Windows do from_lib_path := filepath.join({root_directory, "navis.lib"}, context.temp_allocator)
    when ODIN_OS == .Linux do from_lib_path := filepath.join({root_directory, "navis.a"}, context.temp_allocator)
    defer delete(from_lib_path, context.temp_allocator)

    when ODIN_OS == .Windows do to_lib_path := filepath.join({navis_directory, "navis.lib"}, context.temp_allocator)
    when ODIN_OS == .Linux do to_lib_path := filepath.join({navis_directory, "navis.a"}, context.temp_allocator)
    defer delete(to_lib_path, context.temp_allocator)

    copy_command, copy_command_allocation_error := strings.concatenate({"copy ", from_lib_path, " ", to_lib_path}, context.temp_allocator)
    if copy_command_allocation_error != .None do return
    defer delete(copy_command, context.temp_allocator)

    treated_copy_command, treated_copy_command_was_allocation := strings.replace_all(copy_command, "/", "\\", context.temp_allocator)
    defer if treated_copy_command_was_allocation do delete(treated_copy_command, context.temp_allocator)

    cstr_treated_copy_command, cstr_treated_copy_command_allocation_error := strings.clone_to_cstring(treated_copy_command, context.temp_allocator)
    if cstr_treated_copy_command_allocation_error != .None do return
    defer delete(cstr_treated_copy_command, context.temp_allocator)

    libc.system(cstr_treated_copy_command)
}

build_module :: proc(name, directory: string, descriptor: Module_Build_Descriptor)
{
    command := strings.builder_make(context.temp_allocator)
    defer strings.builder_destroy(&command)

    root_directory := io_get_root_directory(context.temp_allocator)
    defer delete(root_directory, context.temp_allocator)

    navis_directory := io_get_navis_directory(context.temp_allocator)
    defer delete(navis_directory, context.temp_allocator)

    out_directory := cli_get_out_directory(context.temp_allocator)
    defer delete(out_directory, context.temp_allocator)

    when ODIN_OS == .Windows do out_file_name := strings.concatenate({name, ".dll"}, context.temp_allocator)
    when ODIN_OS == .Linux do out_file_name := strings.concatenate({name, ".so"}, context.temp_allocator)
    defer delete(out_file_name, context.temp_allocator)

    out_path := filepath.join({out_directory, out_file_name}, context.temp_allocator)
    defer delete(out_path, context.temp_allocator)

    //Build navis
    strings.write_string(&command, "odin build")
    strings.write_string(&command, " ")
    strings.write_string(&command, directory)
    strings.write_string(&command, " ")
    
    //Build mode
    strings.write_string(&command, "-build-mode:shared")
    strings.write_string(&command, " ")

    //Out
    strings.write_string(&command, "-out:")
    strings.write_string(&command, out_path)
    strings.write_string(&command, " ")
    
    //Navis Collection
    if descriptor.navis_collection
    {
        strings.write_string(&command, "-collection:")
        strings.write_string(&command, "navis")
        strings.write_string(&command, "=")
        strings.write_string(&command, navis_directory)
        strings.write_string(&command, " ")
    }

    //Debug
    if descriptor.debug
    {
        strings.write_string(&command, "-debug")
        strings.write_string(&command, " ")
    }
    
    //Defines
    navis_descriptor: Navis_Build_Descriptor
    navis_descriptor.bindings = descriptor.navis_build_mode == .Shared
    navis_descriptor.implementation = descriptor.navis_build_mode == .Embedded
    navis_descriptor.module = true
    navis_descriptor.verbose = descriptor.verbose
    command_write_navis_build_descritor(&command, navis_descriptor)
    command_submit(&command)
}

build_launcher :: proc(name, directory: string, descriptor: Module_Build_Descriptor)
{
    command := strings.builder_make(context.temp_allocator)
    defer strings.builder_destroy(&command)

    root_directory := io_get_root_directory(context.temp_allocator)
    defer delete(root_directory, context.temp_allocator)

    navis_directory := io_get_navis_directory(context.temp_allocator)
    defer delete(navis_directory, context.temp_allocator)

    out_directory := cli_get_out_directory(context.temp_allocator)
    defer delete(out_directory, context.temp_allocator)

    when ODIN_OS == .Windows do out_file_name := strings.concatenate({name, ".exe"}, context.temp_allocator)
    when ODIN_OS == .Linux do out_file_name := strings.concatenate({name, ".out"}, context.temp_allocator)
    defer delete(out_file_name, context.temp_allocator)

    out_path := filepath.join({out_directory, out_file_name}, context.temp_allocator)
    defer delete(out_path, context.temp_allocator)

    //Build navis
    strings.write_string(&command, "odin build")
    strings.write_string(&command, " ")
    strings.write_string(&command, directory)
    strings.write_string(&command, " ")
    
    //Build mode
    strings.write_string(&command, "-build-mode:exe")
    strings.write_string(&command, " ")

    //Out
    strings.write_string(&command, "-out:")
    strings.write_string(&command, out_path)
    strings.write_string(&command, " ")
    
    //Navis Collection
    if descriptor.navis_collection
    {
        strings.write_string(&command, "-collection:")
        strings.write_string(&command, "navis")
        strings.write_string(&command, "=")
        strings.write_string(&command, navis_directory)
        strings.write_string(&command, " ")
    }

    //Debug
    if descriptor.debug
    {
        strings.write_string(&command, "-debug")
        strings.write_string(&command, " ")
    }
    
    //Defines
    navis_descriptor: Navis_Build_Descriptor
    navis_descriptor.bindings = descriptor.navis_build_mode == .Shared
    navis_descriptor.implementation = descriptor.navis_build_mode == .Embedded
    navis_descriptor.module = true
    navis_descriptor.verbose = descriptor.verbose
    command_write_navis_build_descritor(&command, navis_descriptor)
    command_submit(&command)
}