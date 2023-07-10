package navis

import "api"
import "graphics/commons"
import "graphics/ui"

when api.BINDINGS
{
    import "core:runtime"

    when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

    @(default_calling_convention="odin")
    foreign navis
    {
        /* Navis */
        @(link_prefix=PREFIX)
        run_from_paths :: proc(paths: ..string, allocator := context.allocator) ---

        @(link_prefix=PREFIX)
        exit_uncached :: proc(application: ^Application) ---
    }
}