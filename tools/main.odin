package tools

import "core:fmt"

FLAG_DEBUG :: "debug"
FLAG_VERBOSE :: "debug"
FLAG_COPY_BGFX_RESOURCES :: "copy-bgfx-resources"
FLAG_BUILD_NAVIS_MODULE :: "module:navis"
FLAG_NAVIS_COLLECTION :: "collection:navis"
FLAG_NAVIS_BUILD_MODE_EMBEDDED :: "navis-build-mode:embedded"
FLAG_BUILD_MODULE :: "module"
FLAG_BUILD_LAUNCHER :: "launcher"
FLAG_BUILD_SHADER :: "shader"
FLAG_CLEAR_SHADER_MODULES :: "clear-shader-modules"

main :: proc()
{
    if cli_help() do return

    debug := cli_has_flag(FLAG_DEBUG) > -1
    verbose := cli_has_flag(FLAG_VERBOSE) > -1
    navis_collection := cli_has_flag(FLAG_NAVIS_COLLECTION) > -1
    navis_build_mode_embedded := cli_has_flag(FLAG_NAVIS_BUILD_MODE_EMBEDDED) > -1
    clear_shader_modules := cli_has_flag(FLAG_CLEAR_SHADER_MODULES) > -1
    module_build_config := get_module_build_config()
    shader_compile_options := bgfx_get_shader_compile_options()

    //Copy bgfx resources
    {
        if cli_has_flag(FLAG_COPY_BGFX_RESOURCES) > -1
        {
            bgfx_copy_binaries_for_windows()
        }
    }

    //Build navis module
    {
        if cli_has_flag(FLAG_BUILD_NAVIS_MODULE) > -1
        {
            build_navis_module(debug, verbose)
        }
    }

    //Build modules
    {
        indices := cli_get_pair_flag_index_list(FLAG_BUILD_MODULE, allocator = context.temp_allocator)
        for i in indices
        {
            f, k, v := cli_unpack_pair_flag_argument(i)
            build_module(k, v, module_build_config)
        }
    }

    //Build launchers
    {
        indices := cli_get_pair_flag_index_list(FLAG_BUILD_LAUNCHER, allocator = context.temp_allocator)
        for i in indices
        {
            f, k, v := cli_unpack_pair_flag_argument(i)
            build_launcher(k, v, module_build_config)
        }
    }

    //Shader compilation
    {
        indices := cli_get_pair_flag_index_list(FLAG_BUILD_SHADER, allocator = context.temp_allocator)
        for i in indices
        {
            f, k, v := cli_unpack_pair_flag_argument(i)
            bgfx_build_shader(k, v, shader_compile_options, clear_shader_modules)
        }
    }
}