package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"
    import "navis:graphics/vulkan/shaderc"

/*
Create a new shader module compiler.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compiler_create :: proc() -> (Shader_Module_Compiler, bool) #optional_ok
    {
        compiler := shaderc.compiler_initialize()
        return cast(Shader_Module_Compiler)compiler, true
    }

/*
Destroy a shader module compiler.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compiler_destroy :: proc(compiler: Shader_Module_Compiler) -> bool
    {
        if compiler == nil do return false
        shaderc_compiler := cast(shaderc.Compiler)compiler
        shaderc.compiler_release(shaderc_compiler)
        return true
    }

/*
Compile a source code to spirv.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compile_to_spirv_from_data :: proc(compiler: Shader_Module_Compiler, options: Shader_Module_Compile_Options, descriptor: Shader_Module_Compile_Descriptor) -> shaderc.Compilation_Result
    {
        source_text := cast(cstring)descriptor.source_code
        source_text_size := descriptor.source_code_size
        shader_kind := descriptor.shader_kind
        input_file_name := cast(cstring)descriptor.input_file_name
        entry_point_name := cast(cstring)descriptor.entry_point_name
        return shaderc.compile_into_spv(compiler, source_text, source_text_size, shader_kind, input_file_name, entry_point_name, options)
    }

/*
Create a new shader module compile options.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compile_options_create :: proc() -> (Shader_Module_Compile_Options, bool) #optional_ok
    {
        options := shaderc.compile_options_initialize()
        if options == nil do return nil, false
        return cast(Shader_Module_Compile_Options)options, true
    }

/*
Destroy a shader module compile options.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compile_options_destroy :: proc(options: Shader_Module_Compile_Options) -> bool
    {
        if options == nil do return false
        shaderc_options := cast(shaderc.Compile_Options)options
        shaderc.compile_options_release(shaderc_options)
        return true
    }

/*
Set source language of a shader module compile options.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compile_options_set_source_language :: proc(options: Shader_Module_Compile_Options, language: shaderc.Source_Language)
    {
        if options == nil do return
        shaderc_options := cast(shaderc.Compile_Options)options
        shaderc.compile_options_set_source_language(shaderc_options, language)
    }

/*
Get compilation result size.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_compilation_result_get_size :: proc(result: shaderc.Compilation_Result) -> u64
    {
        if result == nil do return 0
        return shaderc.result_get_length(result)
    }

/*
Get compilation result data.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_compilation_result_get_data :: proc(result: shaderc.Compilation_Result) -> rawptr
    {
        if result == nil do return nil
        return cast(rawptr)shaderc.result_get_bytes(result)
    }

/*
Destroy a compilation result.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    shader_compilation_result_destroy :: proc(result: shaderc.Compilation_Result)
    {
        if result == nil do return
        shaderc.result_release(result)
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_create_from_data :: proc(context_: ^Context, data: []byte, location := #caller_location) -> (vk.ShaderModule, bool) #optional_ok
    {
        if log.verbose_fail_error(!context_is_valid(context_), "invalid vulkan context parameter", location) do return 0, false

        info: vk.ShaderModuleCreateInfo
        info.sType = .SHADER_MODULE_CREATE_INFO
        info.pCode = transmute(^u32)commons.array_try_as_pointer(data)
        info.codeSize = commons.array_try_len(data)

        handle: vk.ShaderModule
        result := vk.CreateShaderModule(context_.device.handle, &info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan shader module", location) do return 0, false

        return handle, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_destroy :: proc(context_: ^Context, module: vk.ShaderModule, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(!context_is_valid(context_), "invalid vulkan context parameter", location) do return false

        vk.DestroyShaderModule(context_.device.handle, module, nil)
        return true
    }
}