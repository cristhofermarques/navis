package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons"
    import "navis:commons/log"

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
}