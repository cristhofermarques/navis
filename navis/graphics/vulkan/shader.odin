package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"
    import "navis:graphics/vulkan/shaderc"

    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compiler_create :: proc() -> (Shader_Module_Compiler, bool) #optional_ok
    {
        compiler := shaderc.compiler_initialize()
        return cast(Shader_Module_Compiler)compiler, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compiler_destroy :: proc(compiler: ^Shader_Module_Compiler) -> bool
    {
        shaderc_compiler := cast(shaderc.Compiler)compiler^
        shaderc.compiler_release(shaderc_compiler)
        return true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    shader_module_compile_to_spirv_from_data :: proc(compiler: ^Shader_Module_Compiler, source_code: rawptr, source_code_length: u64, kind: shaderc.Shader_Kind) -> (rawptr, bool) #optional_ok
    {
        return nil, false
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