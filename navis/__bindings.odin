package navis

import "api"
import "graphics/commons"
import "graphics/ui"

PREFIX :: "navis_"

when api.IMPORT
{
    import "core:runtime"

    when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

    @(default_calling_convention="odin")
    foreign navis
    {
        /* Module */
        @(link_prefix=PREFIX)
        module_treat_path :: proc(path: string, allocator := context.allocator) -> string ---

        @(link_prefix=PREFIX)
        module_populate_vtable :: proc(vtable: ^Module_VTable) ---

        @(link_prefix=PREFIX)
        module_load_path :: proc(path: string, allocator := context.allocator) -> (Module, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        module_unload_single :: proc(module: ^Module) -> bool ---

        @(link_prefix=PREFIX)
        module_load_paths :: proc(paths: ..string, allocator := context.allocator) -> ([]Module, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        module_unload_multiple :: proc(modules: []Module) ---

        /* Application */
        @(link_prefix=PREFIX)
        application_begin_paths :: proc(application: ^Application, paths: ..string, allocator := context.allocator, location := #caller_location) -> bool ---

        @(link_prefix=PREFIX)
        application_loop :: proc(application: ^Application) ---

        @(link_prefix=PREFIX)
        application_end :: proc(application: ^Application, location := #caller_location) -> bool ---
    }
}