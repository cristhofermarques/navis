package bgfx

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && ODIN_DEBUG do foreign import shaderc{
    "binaries/texturec_windows_amd64_debug.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && !ODIN_DEBUG do foreign import shaderc{
    "binaries/texturec_windows_amd64_release.lib",
}

foreign shaderc
{
    @(link_name="bgfx_compile_texture")
	compile_texture_argc_argv :: proc "c" (argc: i32, argv: [^]cstring) -> i32 ---
}