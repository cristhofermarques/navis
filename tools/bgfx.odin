package tools

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:c/libc"

bgfx_copy_binaries_for_windows :: proc()
{
    if cli_has_value_flag("bgfx-directory") < 0 do return
    flag, bgfx_directory := cli_get_value_flag("bgfx-directory")

    navis_directory := io_get_navis_directory(context.temp_allocator)
    tools_directory := io_get_tools_directory(context.temp_allocator)

    navis_bgfx_binaries_directory := filepath.join({navis_directory, "bgfx/binaries"}, context.temp_allocator)
    if !os.is_dir(navis_bgfx_binaries_directory) do os.make_directory(navis_bgfx_binaries_directory)

    tools_bgfx_directory := filepath.join({tools_directory, "bgfx"}, context.temp_allocator)
    if !os.is_dir(tools_bgfx_directory) do os.make_directory(tools_bgfx_directory)

    postfixes := []string{"vs2022", "vs2019", "vs2017"}
    prefixes := []string{"win32", "win64"}
    libraries := []string{"bgfx", "bx", "bimg", "bimg_encode", "bimg_decode"}
    executables := []string{"shaderc", "geometryc", "geometryv", "texturec", "texturev"}
    modes := []string{"Debug", "Release"}

    for postfix in postfixes do for prefix in prefixes
    {
        os_arch_vs, os_arch_vs_allocation_error := strings.concatenate({prefix, "_", postfix}, context.temp_allocator)
        if os_arch_vs_allocation_error != .None do continue
        
        binaries_directory := filepath.join({bgfx_directory, ".build", os_arch_vs, "bin"}, context.temp_allocator)
        if !os.is_dir(binaries_directory) do continue

        for library in libraries do for mode in modes
        {
            library_file, library_file_allocation_error := strings.concatenate({library, mode, ".lib"}, context.temp_allocator)
            if library_file_allocation_error != .None do continue
            
            library_path := filepath.join({binaries_directory, library_file}, context.temp_allocator)
            if !os.is_file(library_path) do continue
            
            arch_ := prefix == "win32" ? "i386_" : "amd64_"
            mode_ := mode == "Debug" ? "debug" : "release"
            new_library_file, new_library_file_allocation_error := strings.concatenate({library, "_windows_", arch_, mode_, ".lib"}, context.temp_allocator)
            if new_library_file_allocation_error != .None do continue
            new_library_path := filepath.join({navis_bgfx_binaries_directory, new_library_file}, context.temp_allocator)

            binary, read_binary_error := os.read_entire_file(library_path, context.temp_allocator)
            new_lib, new_lib_err := os.open(new_library_path, os.O_CREATE)
            if new_lib_err != 0 do continue
            defer os.close(new_lib)
            os.write(new_lib, binary)
        }
        
        for executable in executables
        {
            arch_ := prefix == "win32" ? "i386" : "amd64"

            executable_file, executable_file_allocation_error := strings.concatenate({executable, "Release", ".exe"}, context.temp_allocator)
            if executable_file_allocation_error != .None do continue
            
            executable_path := filepath.join({binaries_directory, executable_file}, context.temp_allocator)
            if !os.is_file(executable_path) do continue
            
            new_executable_file, new_executable_file_allocation_error := strings.concatenate({executable, "_windows_", arch_, ".exe"}, context.temp_allocator)
            if new_executable_file_allocation_error != .None do continue
            new_executable_path := filepath.join({tools_bgfx_directory, new_executable_file}, context.temp_allocator)

            binary, read_binary_error := os.read_entire_file(executable_path, context.temp_allocator)
            new_exe, new_exe_err := os.open(new_executable_path, os.O_CREATE)
            if new_exe_err != 0 do continue
            defer os.close(new_exe)
            os.write(new_exe, binary)
        }
    }

    shader_sh_path := filepath.join({bgfx_directory, "src/bgfx_shader.sh"}, context.temp_allocator)
    shader_sh_data, read_shader_sh_data_error := os.read_entire_file(shader_sh_path, context.temp_allocator)  
    new_shader_sh_path := filepath.join({tools_bgfx_directory, "bgfx_shader.sh"}, context.temp_allocator)
    new_shader_sh, new_shader_sh_err := os.open(new_shader_sh_path, os.O_CREATE)
    if new_shader_sh_err == 0
    {
        os.write(new_shader_sh, shader_sh_data)
        os.close(new_shader_sh)
    }

    compute_shader_sh_path := filepath.join({bgfx_directory, "src/bgfx_compute.sh"}, context.temp_allocator)
    compute_shader_sh_data, read_compute_shader_sh_data_error := os.read_entire_file(compute_shader_sh_path, context.temp_allocator)  
    new_compute_shader_sh_path := filepath.join({tools_bgfx_directory, "bgfx_compute.sh"}, context.temp_allocator)
    new_compute_shader_sh, new_compute_shader_sh_err := os.open(new_compute_shader_sh_path, os.O_CREATE)
    if new_compute_shader_sh_err == 0
    {
        os.write(new_compute_shader_sh, compute_shader_sh_data)
        os.close(new_compute_shader_sh)
    }
}

bgfx_get_directory :: proc(allocator := context.allocator) -> string
{
    tools_dir := io_get_tools_directory(context.temp_allocator)
    return filepath.join({tools_dir, "bgfx"}, allocator)
}

bgfx_get_shader_includes :: proc(allocator := context.allocator) -> []string
{
    return cli_get_value_flag_list("shader-include", allocator = allocator)
}

bgfx_get_shaderc_executable_path :: proc(allocator := context.allocator) -> string
{
    when ODIN_OS == .Windows
    {
        os := "windows"
        ext := ".exe"
    }

    when ODIN_OS == .Linux
    {
        os := "linux"
        ext := ""
    }
    
    when ODIN_ARCH == .amd64 do arch := "amd64"
    when ODIN_ARCH == .i386  do arch := "i386"
    
    bgfx_dir := bgfx_get_directory(context.temp_allocator)
    shaderc_file, shaderc_file_alloc_err := strings.concatenate({"shaderc", "_", os, "_", arch, ext}, context.temp_allocator)
    if shaderc_file_alloc_err != .None do return ""
    return filepath.join({bgfx_dir, shaderc_file}, allocator)
}

bgfx_get_varyingdef_path :: proc(allocator := context.allocator) -> string
{
    bgfx_dir := bgfx_get_directory(context.temp_allocator)
    default_path := filepath.join({bgfx_dir, "varying.def.sc"}, allocator)

    FLAG :: "varyingdef"
    if cli_has_value_flag(FLAG) > -1
    {
        flag, value := cli_get_value_flag(FLAG)
        clone, clone_err :=  strings.clone(value, allocator)
        if clone_err != .None do return default_path
        defer delete(default_path, allocator)
        return clone
    }
    else do return default_path
}

Shader_Module_Type :: enum
{
    Vertex,
    Fragment,
    Compute,
}

shader_module_type_to_flag :: proc "contextless" (type: Shader_Module_Type) -> string
{
    switch type
    {
        case .Vertex: return "vertex"
        case .Fragment: return "fragment"
        case .Compute: return "compute"
    }

    return ""
}

shader_module_type_to_extension :: proc "contextless" (type: Shader_Module_Type) -> string
{
    switch type
    {
        case .Vertex: return ".vs"
        case .Fragment: return ".fs"
        case .Compute: return ".cs"
    }

    return ""
}

Shader_Module_Profile :: enum
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

shader_module_profile_to_flag :: proc "contextless" (profile: Shader_Module_Profile) -> string
{
    switch profile
    {
        case .GLSL_120: return "120"
        case .GLSL_130: return "130"
        case .GLSL_140: return "140"
        case .GLSL_150: return "150"
        case .GLSL_330: return "330"
        case .GLSL_400: return "400"
        case .GLSL_410: return "410"
        case .GLSL_420: return "420"
        case .GLSL_430: return "430"
        case .GLSL_440: return "440"
        case .GLSL_ES_100: return "100_es"
        case .GLSL_ES_300: return "300_es"
        case .GLSL_ES_310: return "310_es"
        case .GLSL_ES_320: return "320_es"
        case .HLSL_S_3_0: return "s_3_0"
        case .HLSL_S_4_0: return "s_4_0"
        case .HLSL_S_5_0: return "s_5_0"
        case .Metal: return "metal"
        case .PSSL: return "pssl"
        case .Spirv: return "spirv"
        case .Spirv_10_10: return "spirv10-10"
        case .Spirv_13_11: return "spirv13-11"
        case .Spirv_14_11: return "spirv14-11"
        case .Spirv_15_12: return "spirv15-12"
        case .Spirv_16_13: return "spirv16-13"
    }

    return ""
}

Shader_Compile_Options :: struct
{
    no_opengl,
    no_opengl_es,
    no_direct3d,
    no_vulkan,
    no_gnm: bool,
}

bgfx_get_shader_compile_options :: proc() -> Shader_Compile_Options
{
    options: Shader_Compile_Options
    options.no_opengl = cli_has_flag("no-opengl") > -1
    options.no_opengl_es = cli_has_flag("no-opengl-es") > -1
    options.no_direct3d = cli_has_flag("no-direct3d") > -1
    options.no_vulkan = cli_has_flag("no-vulkan") > -1
    options.no_gnm = cli_has_flag("no-gnm") > -1
    return options
}

bgfx_compose_shader_module_output_path :: proc(path: string, type: Shader_Module_Type, profile: Shader_Module_Profile, allocator := context.allocator) -> string
{
    base := filepath.base(path)
    sc_bi := strings.last_index(base, ".")
    sc_base := base[0:sc_bi]
    name_bi := strings.last_index(sc_base, ".")
    name := sc_base[0:name_bi]
    profile_flag := shader_module_profile_to_flag(profile)
    type_flag := shader_module_type_to_flag(type)
    type_ext := shader_module_type_to_extension(type)

    out_dir := cli_get_out_directory(context.temp_allocator)
    out_file := strings.concatenate({name, type_ext, ".", profile_flag}, context.temp_allocator)//TODO: check for error
    return filepath.join({out_dir, out_file}, allocator)
}

bgfx_compile_shader_module :: proc(path: string, type: Shader_Module_Type, profile: Shader_Module_Profile)
{
    if !os.is_file(path)
    {
        fmt.println("Cant file", path)
        return //TODO(cris): log error  here
    }

    // base := filepath.base(path)
    // sc_bi := strings.last_index(base, ".")
    // sc_base := base[0:sc_bi]
    // name_bi := strings.last_index(sc_base, ".")
    // name := sc_base[0:name_bi]
    profile_flag := shader_module_profile_to_flag(profile)
    type_flag := shader_module_type_to_flag(type)
    // type_ext := shader_module_type_to_extension(type)

    bgfx_dir := bgfx_get_directory(context.temp_allocator)
    shaderc_path := bgfx_get_shaderc_executable_path(context.temp_allocator)
    out_dir := cli_get_out_directory(context.temp_allocator)
    varyingdef_path := bgfx_get_varyingdef_path(context.temp_allocator)
    //out_file := strings.concatenate({name, type_ext, ".", profile_flag}, context.temp_allocator)//TODO: check for error
    out_path := bgfx_compose_shader_module_output_path(path, type, profile, context.temp_allocator)

    sb, sb_ae := strings.builder_make(0, 512, context.temp_allocator)
    //TODO(cris): check for error
    defer strings.builder_destroy(&sb)

    //Executable
    strings.write_string(&sb, shaderc_path)
    strings.write_string(&sb, " ")
    
    //File
    strings.write_string(&sb, "-f")
    strings.write_string(&sb, " ")
    strings.write_string(&sb, path)
    strings.write_string(&sb, " ")
    
    //Output
    strings.write_string(&sb, "-o")
    strings.write_string(&sb, " ")
    strings.write_string(&sb, out_path)
    strings.write_string(&sb, " ")
    
    //Type
    strings.write_string(&sb, "--type")
    strings.write_string(&sb, " ")
    strings.write_string(&sb, type_flag)
    strings.write_string(&sb, " ")

    //Profile
    strings.write_string(&sb, "--profile")
    strings.write_string(&sb, " ")
    strings.write_string(&sb, profile_flag)
    strings.write_string(&sb, " ")
    
    //Varyingdef
    strings.write_string(&sb, "--varyingdef")
    strings.write_string(&sb, " ")
    strings.write_string(&sb, varyingdef_path)
    strings.write_string(&sb, " ")
    
    //Standard Include
    strings.write_string(&sb, "-i")
    strings.write_string(&sb, " ")
    strings.write_string(&sb, bgfx_dir)
    strings.write_string(&sb, " ")

    //Includes
    shader_includes := bgfx_get_shader_includes(context.temp_allocator)
    if shader_includes != nil do for si in shader_includes
    {
        strings.write_string(&sb, "-i")
        strings.write_string(&sb, " ")
        strings.write_string(&sb, si)
        strings.write_string(&sb, " ")
    }

    cmd := strings.clone_to_cstring(strings.to_string(sb), context.temp_allocator)
    libc.system(cmd)
}

bgfx_compose_shader_module_path :: proc(path: string, type: Shader_Module_Type, allocator := context.allocator) -> string
{
    switch type
    {
        case .Vertex:
            s_path, s_path_err := strings.concatenate({path, ".vs"}, allocator)
            if s_path_err == .None do return s_path

        case .Fragment:
            s_path, s_path_err := strings.concatenate({path, ".fs"}, allocator)
            if s_path_err == .None do return s_path

        case .Compute:
            s_path, s_path_err := strings.concatenate({path, ".cs"}, allocator)
            if s_path_err == .None do return s_path
    }

    return ""
}

bgfx_compile_shader_modules :: proc(path: string, options: Shader_Compile_Options = {})
{
    vs_path := bgfx_compose_shader_module_path(path, .Vertex, context.temp_allocator)
    if !os.is_file(vs_path) do return //TODO(cris): log error here

    fs_path := bgfx_compose_shader_module_path(path, .Fragment, context.temp_allocator)
    if !os.is_file(fs_path) do return //TODO(cris): log error here

    if !options.no_opengl do for p in Shader_Module_Profile.GLSL_410..=Shader_Module_Profile.GLSL_440
    {
        bgfx_compile_shader_module(vs_path, .Vertex, p)
        bgfx_compile_shader_module(fs_path, .Fragment, p)
    }

    if !options.no_opengl_es do for p in Shader_Module_Profile.GLSL_ES_100..=Shader_Module_Profile.GLSL_ES_320
    {
        bgfx_compile_shader_module(vs_path, .Vertex, p)
        bgfx_compile_shader_module(fs_path, .Fragment, p)
    }

    if !options.no_direct3d do for p in Shader_Module_Profile.HLSL_S_3_0..=Shader_Module_Profile.HLSL_S_5_0
    {
        bgfx_compile_shader_module(vs_path, .Vertex, p)
        bgfx_compile_shader_module(fs_path, .Fragment, p)
    }

    if !options.no_vulkan do for p in Shader_Module_Profile.Spirv..=Shader_Module_Profile.Spirv_16_13
    {
        bgfx_compile_shader_module(vs_path, .Vertex, p)
        bgfx_compile_shader_module(fs_path, .Fragment, p)
    }

    if !options.no_gnm do for p in Shader_Module_Profile.PSSL..=Shader_Module_Profile.PSSL
    {
        bgfx_compile_shader_module(vs_path, .Vertex, p)
        bgfx_compile_shader_module(fs_path, .Fragment, p)
    }
}

bgfx_set_shader_asset_entry :: proc(asset: ^navis.Shader_Asset, entry: navis.Shader_Asset_Entry, profile: Shader_Module_Profile)
{
    if asset == nil do return
    switch profile
    {
        case .GLSL_120: asset.glsl_120 = entry
        case .GLSL_130: asset.glsl_130 = entry
        case .GLSL_140: asset.glsl_140 = entry
        case .GLSL_150: asset.glsl_150 = entry
        case .GLSL_330: asset.glsl_330 = entry
        case .GLSL_400: asset.glsl_400 = entry
        case .GLSL_410: asset.glsl_410 = entry
        case .GLSL_420: asset.glsl_420 = entry
        case .GLSL_430: asset.glsl_430 = entry
        case .GLSL_440: asset.glsl_440 = entry
        case .GLSL_ES_100: asset.glsl_100_es = entry
        case .GLSL_ES_300: asset.glsl_300_es = entry
        case .GLSL_ES_310: asset.glsl_310_es = entry
        case .GLSL_ES_320: asset.glsl_320_es = entry
        case .HLSL_S_3_0: asset.hlsl_s_3_0 = entry
        case .HLSL_S_4_0: asset.hlsl_s_4_0 = entry
        case .HLSL_S_5_0: asset.hlsl_s_5_0 = entry
        case .Metal: asset.metal = entry
        case .PSSL: asset.pssl = entry
        case .Spirv: asset.spirv = entry
        case .Spirv_10_10: asset.spirv_10_10 = entry
        case .Spirv_13_11: asset.spirv_13_11 = entry
        case .Spirv_14_11: asset.spirv_14_11 = entry
        case .Spirv_15_12: asset.spirv_15_12 = entry
        case .Spirv_16_13: asset.spirv_16_13 = entry
    }
}

bgfx_compose_shader_path :: proc(name: string, allocator := context.allocator) -> string
{
    out_dir := cli_get_out_directory(context.temp_allocator)
    shader_file, shader_file_err := strings.concatenate({name, ".bff"}, context.temp_allocator)
    if shader_file_err != .None do return ""
    return filepath.join({out_dir, shader_file}, allocator)
}

bgfx_pack_shader_asset :: proc(name, path: string, options: Shader_Compile_Options = {})
{
    vs_path := bgfx_compose_shader_module_path(path, .Vertex, context.temp_allocator)
    if !os.is_file(vs_path) do return //TODO(cris): log error here

    fs_path := bgfx_compose_shader_module_path(path, .Fragment, context.temp_allocator)
    if !os.is_file(fs_path) do return //TODO(cris): log error here

    asset: navis.Shader_Asset
    pack_allocator := runtime.default_allocator()
    defer free_all(pack_allocator)

    copy_shader_modules_to_shader_entry :: proc(asset: ^navis.Shader_Asset, vs_path, fs_path: string, profile: Shader_Module_Profile, allocator: runtime.Allocator)
    {
        out_vs_path := bgfx_compose_shader_module_output_path(vs_path, .Vertex,   profile, context.temp_allocator)
        out_fs_path := bgfx_compose_shader_module_output_path(fs_path, .Fragment, profile, context.temp_allocator)

        vs_data := read_file(out_vs_path, allocator)
        fs_data := read_file(out_fs_path, allocator)

        entry: navis.Shader_Asset_Entry
        entry.vertex = vs_data
        entry.fragment = fs_data
        bgfx_set_shader_asset_entry(asset, entry, profile)
    }

    if !options.no_opengl do for p in Shader_Module_Profile.GLSL_410..=Shader_Module_Profile.GLSL_440
    {
        copy_shader_modules_to_shader_entry(&asset, vs_path, fs_path, p, pack_allocator)
    }

    if !options.no_opengl_es do for p in Shader_Module_Profile.GLSL_ES_100..=Shader_Module_Profile.GLSL_ES_320
    {
        copy_shader_modules_to_shader_entry(&asset, vs_path, fs_path, p, pack_allocator)
    }

    if !options.no_direct3d do for p in Shader_Module_Profile.HLSL_S_3_0..=Shader_Module_Profile.HLSL_S_5_0
    {
        copy_shader_modules_to_shader_entry(&asset, vs_path, fs_path, p, pack_allocator)
    }

    if !options.no_vulkan do for p in Shader_Module_Profile.Spirv..=Shader_Module_Profile.Spirv_16_13
    {
        copy_shader_modules_to_shader_entry(&asset, vs_path, fs_path, p, pack_allocator)
    }

    if !options.no_gnm do for p in Shader_Module_Profile.PSSL..=Shader_Module_Profile.PSSL
    {
        copy_shader_modules_to_shader_entry(&asset, vs_path, fs_path, p, pack_allocator)
    }

    shader_path := bgfx_compose_shader_path(name, context.temp_allocator)
    bgfx_serialize_shader_asset_to_file(shader_path, asset)
}

bgfx_clear_shader_asset :: proc(path: string)
{
    vs_path := bgfx_compose_shader_module_path(path, .Vertex, context.temp_allocator)
    fs_path := bgfx_compose_shader_module_path(path, .Fragment, context.temp_allocator)

    delete_shader_modules :: proc(vs_path, fs_path: string, profile: Shader_Module_Profile)
    {
        out_vs_path := bgfx_compose_shader_module_output_path(vs_path, .Vertex,   profile, context.temp_allocator)
        out_fs_path := bgfx_compose_shader_module_output_path(fs_path, .Fragment, profile, context.temp_allocator)

        if os.is_file(out_vs_path) do os.remove(out_vs_path)
        if os.is_file(out_fs_path) do os.remove(out_fs_path)
    }

    for p in Shader_Module_Profile do delete_shader_modules(vs_path, fs_path, p)
}

bgfx_build_shader :: proc(name, path: string, options: Shader_Compile_Options = {}, post_clear := true)
{
    bgfx_compile_shader_modules(path, options)
    bgfx_pack_shader_asset(name, path, options)
    if post_clear do bgfx_clear_shader_asset(path)
}

bgfx_serialize_shader_asset_to_file :: proc(path: string, asset: navis.Shader_Asset)
{
    b: bytes.Buffer
    bytes.buffer_init_allocator(&b, 0, 1024 * 256, context.temp_allocator)
    defer bytes.buffer_destroy(&b)
    bff.marshal(&b, asset)
    write_file(path, bytes.buffer_to_bytes(&b))
}

read_file :: proc(path: string, allocator := context.allocator) -> []byte
{
    if !os.is_file(path) do return nil
    data, did_read := os.read_entire_file(path, allocator)
    return did_read ? data : nil
}

write_file :: proc(path: string, data: []byte)
{
    if data == nil do return
    fh, fh_err := os.open(path, os.is_file(path) ? os.O_WRONLY : os.O_CREATE)
    if fh_err != os.ERROR_NONE do return
    defer os.close(fh)
    os.write(fh, data)
}

import "../navis"
import "core:encoding/base64"
import "core:encoding/csv"
import "core:encoding/json"
import "core:runtime"

import "core:bytes"
import "../navis/bff"