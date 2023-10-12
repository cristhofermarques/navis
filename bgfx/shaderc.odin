package bgfx

import "core:fmt"
import "core:strings"
import "core:path/filepath"

Shader_Type :: enum
{
    Vertex = 1,
    Fragment,
    Compute,
}

Shader_Profile :: enum
{
    GLSL_120 = 1,
    GLSL_130,
    GLSL_140,
    GLSL_150,
    GLSL_330,
    GLSL_400,
    GLSL_410,
    GLSL_420,
    GLSL_430,
    GLSL_440,
    GLSL_ES_100,
    GLSL_ES_300,
    GLSL_ES_310,
    GLSL_ES_320,
    HLSL_S_3_0,
    HLSL_S_4_0,
    HLSL_S_5_0,
    Metal,
    PSSL,
    Spirv,
    Spirv_10_10,
    Spirv_13_11,
    Spirv_14_11,
    Spirv_15_12,
    Spirv_16_13,
}

shader_profile_to_flag :: proc(profile: Shader_Profile, $T: typeid) -> T where T == string || T == cstring
{
    flag: T
    switch profile
    {
        case .GLSL_120: flag = "120"
        case .GLSL_130: flag = "130"
        case .GLSL_140: flag = "140"
        case .GLSL_150: flag = "150"
        case .GLSL_330: flag = "330"
        case .GLSL_400: flag = "400"
        case .GLSL_410: flag = "410"
        case .GLSL_420: flag = "420"
        case .GLSL_430: flag = "430"
        case .GLSL_440: flag = "440"
        case .GLSL_ES_100: flag = "100_es"
        case .GLSL_ES_300: flag = "300_es"
        case .GLSL_ES_310: flag = "310_es"
        case .GLSL_ES_320: flag = "320_es"
        case .HLSL_S_3_0: flag = "s_3_0"
        case .HLSL_S_4_0: flag = "s_4_0"
        case .HLSL_S_5_0: flag = "s_5_0"
        case .Metal: flag = "metal"
        case .PSSL: flag = "pssl"
        case .Spirv: flag = "spirv"
        case .Spirv_10_10: flag = "spirv10-10"
        case .Spirv_13_11: flag = "spirv13-11"
        case .Spirv_14_11: flag = "spirv14-11"
        case .Spirv_15_12: flag = "spirv15-12"
        case .Spirv_16_13: flag = "spirv16-13"
    }
    return flag
}

shader_profile_prefixed_name :: proc(profile: Shader_Profile, name: string, alocator := context.allocator) -> string
{
    profile_flag := shader_profile_to_flag(profile, string)
    return strings.concatenate({profile_flag, "_", name})
}

Compile_Shader_Config :: struct
{
    input_path: string,
    type: Shader_Type,
}

compile_shader :: proc(input_path, output_path, varyingdef_path: string, type: Shader_Type, profile: Shader_Profile)
{
    cstr_input_path, cstr_input_path_allocation_error := strings.clone_to_cstring(input_path, context.temp_allocator)
    if cstr_input_path_allocation_error != .None do return

    cstr_output_path, cstr_output_path_allocation_error := strings.clone_to_cstring(output_path, context.temp_allocator)
    if cstr_output_path_allocation_error != .None do return

    cstr_varyingdef_path, cstr_varyingdef_path_allocation_error := strings.clone_to_cstring(varyingdef_path, context.temp_allocator)
    if cstr_varyingdef_path_allocation_error != .None do return
    
    cstr_bgfx_include, cstr_bgfx_include_allocation_error := strings.clone_to_cstring(filepath.dir(#file, context.temp_allocator), context.temp_allocator)
    if cstr_bgfx_include_allocation_error != .None do return

    cstr_type: cstring
    switch type
    {
        case .Vertex: cstr_type = "vertex"
        case .Fragment: cstr_type = "fragment"
        case .Compute: cstr_type = "compute"
    }

    cstr_profile := shader_profile_to_flag(profile, cstring)

    args: [12]cstring
    args[0] = "-f"
    args[1] = cstr_input_path
    args[2] = "-o"
    args[3] = cstr_output_path
    args[4] = "-i"
    args[5] = cstr_bgfx_include
    args[6] = "--varyingdef"
    args[7] = cstr_varyingdef_path
    args[8] = "--type"
    args[9] = cstr_type
    args[10] = "--profile"
    args[11] = cstr_profile

    compile_shader_argc_argv(cast(i32)len(args), &args[0])
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && ODIN_DEBUG do foreign import shaderc{
    "binaries/bx_windows_amd64_debug.lib",
    "binaries/fcpp_windows_amd64_debug.lib",
    "binaries/glslang_windows_amd64_debug.lib",
    "binaries/glsl-optimizer_windows_amd64_debug.lib",
    "binaries/spirv-cross_windows_amd64_debug.lib",
    "binaries/spirv-opt_windows_amd64_debug.lib",
    "binaries/shaderc_windows_amd64_debug.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && !ODIN_DEBUG do foreign import shaderc{
    "binaries/bx_windows_amd64_release.lib",
    "binaries/fcpp_windows_amd64_release.lib",
    "binaries/glslang_windows_amd64_release.lib",
    "binaries/glsl-optimizer_windows_amd64_release.lib",
    "binaries/spirv-cross_windows_amd64_release.lib",
    "binaries/spirv-opt_windows_amd64_release.lib",
    "binaries/shaderc_windows_amd64_release.lib",
}

foreign shaderc
{
    @(link_name="bgfx_compile_shader")
	compile_shader_argc_argv :: proc "c" (argc: i32, argv: [^]cstring) -> i32 ---
}