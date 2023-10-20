package bgfx

import "core:os"
import "core:fmt"
import "core:strings"
import "core:path/filepath"
import "core:c/libc"

Platform :: enum
{
    Android = 1,
    ASM_JS,
    IOS,
    Linux,
    Orbis,
    OSX,
    Windows,
}

platform_to_flag :: proc(platform: Platform) -> (flag: string)
{
    switch platform
    {
        case .Android: flag = "android"
        case .ASM_JS: flag = "asm.js"
        case .IOS: flag = "ios"
        case .Linux: flag = "linux"
        case .Orbis: flag = "orbis"
        case .OSX: flag = "osx"
        case .Windows: flag = "windows"
    }
    return
}

Shader_Type :: enum
{
    Vertex = 1,
    Fragment,
    Compute,
}

shader_type_to_flag :: proc(type: Shader_Type) -> (flag: string)
{
    switch type
    {
        case .Vertex: flag = "vertex"
        case .Fragment: flag = "fragment"
        case .Compute: flag = "compute"
    }
    return
}

Shader_Profile :: enum
{
    GLSL_120,
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

shader_profile_to_flag :: proc(profile: Shader_Profile) -> (flag: string)
{
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
        case .Spirv_10_10: flag = "spirv_10_10"
        case .Spirv_13_11: flag = "spirv_13_11"
        case .Spirv_14_11: flag = "spirv_14_11"
        case .Spirv_15_12: flag = "spirv_15_12"
        case .Spirv_16_13: flag = "spirv_16_13"
    }
    return
}

shader_profile_prefix :: proc(profile: Shader_Profile, text: string, allocator := context.allocator) -> string
{
    return strings.concatenate({shader_profile_to_flag(profile), "_", text})
}

shaderc :: proc(input_path, output_path, varyingdef_path: string, type: Shader_Type, profiles: bit_set[Shader_Profile], platform: Platform, include_paths: []string = nil, defines: []string = nil) -> bool
{
    input_path_base_with_ext := filepath.base(input_path)
    input_path_base := input_path_base_with_ext[0:strings.last_index(input_path_base_with_ext, ".")]
    if !os.is_dir(output_path) do os.make_directory(output_path)
    for profile in Shader_Profile
    {
        if profile not_in profiles do continue
        profile_flag := shader_profile_to_flag(profile)
        output_file_name := strings.concatenate({shader_profile_prefix(profile, input_path_base, context.temp_allocator), ".", profile_flag}, context.temp_allocator)
        output_file_path := filepath.join({output_path, output_file_name}, context.temp_allocator)

        b := strings.builder_make_len_cap(0, 4096, context.temp_allocator)
        strings.write_string(&b, filepath.dir(#file, context.temp_allocator))
        when ODIN_OS == .Windows do strings.write_string(&b, "\\binaries\\shaderc.exe")
        
        strings.write_string(&b, " -f ")
        strings.write_string(&b, input_path)
        
        strings.write_string(&b, " -o ")
        strings.write_string(&b, output_file_path)
        
        strings.write_string(&b, " --varyingdef ")
        strings.write_string(&b, varyingdef_path)
        
        strings.write_string(&b, " -i ")
        strings.write_string(&b, filepath.dir(#file, context.temp_allocator))
        
        for include_path in include_paths
        {
            strings.write_string(&b, " -i ")
            strings.write_string(&b, output_path)
        }
        
        for define in defines
        {
            strings.write_string(&b, " --define ")
            strings.write_string(&b, define)
        }
        
        strings.write_string(&b, " --platform ")
        strings.write_string(&b, platform_to_flag(platform))
        
        strings.write_string(&b, " --profile ")
        strings.write_string(&b, shader_profile_to_flag(profile))
        
        strings.write_string(&b, " --type ")
        strings.write_string(&b, shader_type_to_flag(type))
        
        strings.write_rune(&b, rune(0))
        libc.system(transmute(cstring)raw_data(b.buf))

        if !os.is_file(output_file_path) do return false
    }
    return true
}

Texture_Output_Format :: enum
{
    PNG,
    DDS,
    EXR,
    HDR,
    KTX,
}

texture_output_format_to_flag :: proc(format: Texture_Output_Format) -> (flag: string)
{
    switch format
    {
        case .PNG: flag = "png"
        case .DDS: flag = "dds"
        case .EXR: flag = "exr"
        case .HDR: flag = "hdr"
        case .KTX: flag = "ktx"
    }
    return
}

Texture_Quality :: enum
{
    Default,
    Fastest,
    Highest,
}

texture_quality_to_flag :: proc(quality: Texture_Quality) -> (flag: string)
{
    switch quality
    {
        case .Default: flag = "default"
        case .Fastest: flag = "fastest"
        case .Highest: flag = "highest"
    }
    return
}

texture_format_to_flag :: proc(format: Texture_Format) -> (flag: string)
{
    switch format
    {
        case .BC1: flag = "BC1"
        case .BC2: flag = "BC2"
        case .BC3: flag = "BC3"
        case .BC4: flag = "BC4"
        case .BC5: flag = "BC5"
        case .BC6H: flag = "BC6H"
        case .BC7: flag = "BC7"
        case .ETC1: flag = "ETC1"
        case .ETC2: flag = "ETC2"
        case .ETC2A: flag = "ETC2A"
        case .ETC2A1: flag = "ETC2A1"
        case .PTC12: flag = "PTC12"
        case .PTC14: flag = "PTC14"
        case .PTC12A: flag = "PTC12A"
        case .PTC14A: flag = "PTC14A"
        case .PTC22: flag = "PTC22"
        case .PTC24: flag = "PTC24"
        case .ATC: flag = "ATC"
        case .ATCE: flag = "ATCE"
        case .ATCI: flag = "ATCI"
        case .ASTC4x4: flag = "ASTC4x4"
        case .ASTC5x4: flag = "ASTC5x4"
        case .ASTC5x5: flag = "ASTC5x5"
        case .ASTC6x5: flag = "ASTC6x5"
        case .ASTC6x6: flag = "ASTC6x6"
        case .ASTC8x5: flag = "ASTC8x5"
        case .ASTC8x6: flag = "ASTC8x6"
        case .ASTC8x8: flag = "ASTC8x8"
        case .ASTC10x5: flag = "ASTC10x5"
        case .ASTC10x6: flag = "ASTC10x6"
        case .ASTC10x8: flag = "ASTC10x8"
        case .ASTC10x10: flag = "ASTC10x10"
        case .ASTC12x10: flag = "ASTC12x10"
        case .ASTC12x12: flag = "ASTC12x12"
        case .R1: flag = "R1"
        case .A8: flag = "A8"
        case .R8: flag = "R8"
        case .R8I: flag = "R8I"
        case .R8U: flag = "R8U"
        case .R8S: flag = "R8S"
        case .R16: flag = "R16"
        case .R16I: flag = "R16I"
        case .R16U: flag = "R16U"
        case .R16F: flag = "R16F"
        case .R16S: flag = "R16S"
        case .R32I: flag = "R32I"
        case .R32U: flag = "R32U"
        case .R32F: flag = "R32F"
        case .RG8: flag = "RG8"
        case .RG8I: flag = "RG8I"
        case .RG8U: flag = "RG8U"
        case .RG8S: flag = "RG8S"
        case .RG16: flag = "RG16"
        case .RG16I: flag = "RG16I"
        case .RG16U: flag = "RG16U"
        case .RG16F: flag = "RG16F"
        case .RG16S: flag = "RG16S"
        case .RG32I: flag = "RG32I"
        case .RG32U: flag = "RG32U"
        case .RG32F: flag = "RG32F"
        case .RGB8: flag = "RGB8"
        case .RGB8I: flag = "RGB8I"
        case .RGB8U: flag = "RGB8U"
        case .RGB8S: flag = "RGB8S"
        case .RGB9E5F: flag = "RGB9E5F"
        case .BGRA8: flag = "BGRA8"
        case .RGBA8: flag = "RGBA8"
        case .RGBA8I: flag = "RGBA8I"
        case .RGBA8U: flag = "RGBA8U"
        case .RGBA8S: flag = "RGBA8S"
        case .RGBA16: flag = "RGBA16"
        case .RGBA16I: flag = "RGBA16I"
        case .RGBA16U: flag = "RGBA16U"
        case .RGBA16F: flag = "RGBA16F"
        case .RGBA16S: flag = "RGBA16S"
        case .RGBA32I: flag = "RGBA32I"
        case .RGBA32U: flag = "RGBA32U"
        case .RGBA32F: flag = "RGBA32F"
        case .B5G6R5: flag = "B5G6R5"
        case .R5G6B5: flag = "R5G6B5"
        case .BGRA4: flag = "BGRA4"
        case .RGBA4: flag = "RGBA4"
        case .BGR5A1: flag = "BGR5A1"
        case .RGB5A1: flag = "RGB5A1"
        case .RGB10A2: flag = "RGB10A2"
        case .RG11B10F: flag = "RG11B10F"
        case .D16: flag = "D16"
        case .D24: flag = "D24"
        case .D24S8: flag = "D24S8"
        case .D32: flag = "D32"
        case .D16F: flag = "D16F"
        case .D24F: flag = "D24F"
        case .D32F: flag = "D32F"
        case .D0S8: flag = "D0S8"
        case .Count, .Unknown, .Unknown_Depth:
    }
    return
}

texturec :: proc(input_path, output_path: string, output_format: Texture_Output_Format, format: Texture_Format, quality := Texture_Quality.Default, mips := false, mip_skip := -1, normal_map := false, equirect := false, strip := false, sdf := false, ref: f32 = -1, iqa := false, pma := false, linear := false, max: [2]int = {0, 0}, radiance := false) -> bool
{
    if !os.is_dir(output_path) do os.make_directory(output_path)
    input_path_base_with_ext := filepath.base(input_path)
    input_path_base := input_path_base_with_ext[0:strings.last_index(input_path_base_with_ext, ".")]
    output_format_flag := texture_output_format_to_flag(output_format)
    output_file_name := strings.concatenate({output_format_flag, "_", input_path_base, ".", output_format_flag}, context.temp_allocator)
    output_file_path := filepath.join({output_path, output_file_name}, context.temp_allocator)

    b := strings.builder_make_len_cap(0, 4096, context.temp_allocator)
    strings.write_string(&b, filepath.dir(#file, context.temp_allocator))
    when ODIN_OS == .Windows do strings.write_string(&b, "\\binaries\\texturec.exe")

    strings.write_string(&b, " -f ")
    strings.write_string(&b, input_path)
    
    strings.write_string(&b, " -o ")
    strings.write_string(&b, output_file_path)

    strings.write_string(&b, " -t ")
    strings.write_string(&b, texture_format_to_flag(format))

    strings.write_string(&b, " -q ")
    strings.write_string(&b, texture_quality_to_flag(quality))

    if mips
    {
        strings.write_string(&b, " --mips ")
        if mip_skip != -1
        {
            strings.write_string(&b, " --mipskip ")
            strings.write_int(&b, mip_skip)
        }
    }

    if normal_map do strings.write_string(&b, " --normalmap ")
    if equirect do strings.write_string(&b, " --enquirect ")
    if strip do strings.write_string(&b, " --strip ")
    if sdf do strings.write_string(&b, " --sdf ")

    if ref >= 0
    {
        strings.write_string(&b, " --ref ")
        strings.write_f32(&b, ref, 'f')
    }

    if iqa do strings.write_string(&b, " --iqa ")
    if pma do strings.write_string(&b, " --pma ")
    if linear do strings.write_string(&b, " --linear ")

    if max.x > 0 && max.y > 0
    {
        strings.write_string(&b, " --max ")
        strings.write_int(&b, max.x)
        strings.write_string(&b, "/")
        strings.write_int(&b, max.y)
    }

    if radiance do strings.write_string(&b, " --radiance ")

    strings.write_rune(&b, rune(0))
    libc.system(transmute(cstring)raw_data(b.buf))
    return os.is_file(output_file_path)
}