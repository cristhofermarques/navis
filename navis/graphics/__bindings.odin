package graphics

import "navis:api"

PREFIX :: "navis_graphics_"

when api.IMPORT
{
    when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

    @(default_calling_convention="odin")
    foreign navis
    {
        /* Renderer */
        @(link_prefix=PREFIX)
        renderer_refresh_uncached :: proc "contextless" (renderer: ^Renderer) ---
        
        /* Shader */
        @(link_prefix=PREFIX)
        shader_create_from_descriptor :: proc(descriptor: ^Shader_Descriptor, allocator := context.allocator) -> (Shader, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        shader_destroy :: proc(shader: ^Shader, allocator := context.allocator) ---
    }
}