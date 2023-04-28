package navis

import "navis:api"

when api.EXPORT
{
    import "commons/utility"
    import "core:dynlib"
    import "core:strings"
    import "core:path/filepath"
    import "core:runtime"
    import "core:fmt"

/*
Treats a module path, extension isn't required.

* Ignores any extension if included.
* Adds expected extension (.dll, .so) for each OS. 
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    module_treat_path :: proc(path: string, allocator := context.allocator) -> string
    {
        extension := filepath.ext(path)

        path_without_extension: string
        if extension == "" do path_without_extension = strings.clone(path, context.temp_allocator)
        else
        {
            removed, was_alloc := strings.remove(path, extension, 1, context.temp_allocator)
            if was_alloc do path_without_extension = removed
            else do path_without_extension = strings.clone(path_without_extension, context.temp_allocator)
        }
        defer delete(path_without_extension, context.temp_allocator)

        when ODIN_OS == .Windows do module_path := strings.concatenate({path_without_extension, ".dll"}, allocator)
        when ODIN_OS == .Linux   do module_path := strings.concatenate({path_without_extension, ".so" }, allocator)
        return module_path
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    module_populate_vtable :: proc(module: ^Module)
    {
        assert(module != nil, "Invalid vtable pointer")
        if module == nil do return

        module.vtable.on_load = auto_cast dynlib.symbol_address(module.library, MODULE_ON_LOAD)
        module.vtable.on_unload = auto_cast dynlib.symbol_address(module.library, MODULE_ON_UNLOAD)

        module.vtable.on_application_begin = auto_cast dynlib.symbol_address(module.library, MODULE_ON_APPLICATION_BEGIN)
        module.vtable.on_application_end = auto_cast dynlib.symbol_address(module.library, MODULE_ON_APPLICATION_END)

        module.vtable.on_application_create_window = auto_cast dynlib.symbol_address(module.library, MODULE_ON_APPLICATION_CREATE_WINDOW)
    }

/*
Loads a module from path.

Obs: Library extension (.dll/.so) not required.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    module_load_path :: proc(path: string, allocator := context.allocator) -> (Module, bool) #optional_ok
    {
        module_path := module_treat_path(path, context.temp_allocator)
        defer delete(module_path, context.temp_allocator)

        library, loaded := dynlib.load_library(module_path)
        if !loaded do return {}, false

        module: Module
        module.__allocator = allocator
        module.library = library
        module.path = strings.clone(module_path, allocator)

        module_populate_vtable(&module)

        //On Load
        if module.vtable.on_load != nil do module.vtable.on_load(&module)

        return module, true
    }

/*
Unloads a module.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    module_unload_single :: proc(module: ^Module) -> bool
    {
        if module == nil do return false

        //On Unload
        if module.vtable.on_unload != nil do module.vtable.on_unload(module)

        allocator := module.__allocator
        delete(module.path, allocator)
        return dynlib.unload_library(module.library)
        //return bool(windows.FreeLibrary(module.handle))
    }

/*
Load multiple modules.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    module_load_paths :: proc(paths: ..string, allocator := context.allocator) -> ([]Module, bool) #optional_ok
    {
        if paths == nil do return nil, false

        paths_len := len(paths)
        modules := make([dynamic]Module, 0, paths_len, context.temp_allocator)
        defer delete(modules)

        for path in paths
        {
            module, loaded := module_load_path(path, allocator)
            if !loaded do continue

            append(&modules, module)
        }
        
        return utility.slice_from_dynamic(modules)
    }

/*
Unload multiple modules.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    module_unload_multiple :: proc(modules: []Module)
    {
        if modules == nil do return
        for module, index in modules do module_unload_single(&modules[index])
    }
}