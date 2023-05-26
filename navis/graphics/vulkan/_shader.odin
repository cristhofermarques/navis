package vulkan

import "shaderc"

Shader_Module_Compiler :: shaderc.Compiler
Shader_Module_Compile_Options :: shaderc.Compile_Options

Shader_Module_Compile_Descriptor :: struct
{
    source_code: rawptr,
    source_code_size: u64,
    shader_kind: shaderc.Shader_Kind,
    input_file_name, entry_point_name: cstring,
}