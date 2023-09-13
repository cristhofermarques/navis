package navis

import "ecs"
import "pkg"
import "core:intrinsics"
import "core:runtime"
import "core:thread"
import "core:os"

IMPLEMENTATION :: #config(NAVIS_IMPLEMENTATION, false)
BINDINGS :: #config(NAVIS_BINDINGS, true)
MODULE :: #config(NAVIS_MODULE, true)
EXPORT :: #config(NAVIS_EXPORT, false)

//NOTE(cris): this constants cant be exposed.

@(private)
VERBOSE :: #config(NAVIS_VERBOSE, true)

@(private)
PRECISION_64 :: #config(NAVIS_PRECISION_64, false)

@(private)
PRECISION_32 :: !PRECISION_64

@(private)
VERSION_MAJOR :: #config(NAVIS_VERSION_MAJOR, 2023)

@(private)
VERSION_MINOR :: #config(NAVIS_VERSION_MAJOR, 7)

@(private)
VERSION_PATCH :: #config(NAVIS_VERSION_MAJOR, 0)

/* Bindings prefix */
@(private)
PREFIX :: "navis_"

/* Navis */


when IMPLEMENTATION
{
    /*
    TODO(cris): documentation
    */
    @(export=EXPORT, link_prefix=PREFIX)
    run :: proc(module_paths, package_paths: []string, allocator := context.allocator)
    {
        application: Application

        if module_paths == nil
        {
            log_verbose_error("invalid 'module_paths' parameter", module_paths)
            return
        }

        if package_paths == nil
        {
            log_verbose_error("invalid 'package_paths' parameter", package_paths)
            return
        }

        //Loading modules
        modules, modules_load_success := module_load_paths(paths = module_paths, allocator = allocator)
        if !modules_load_success
        {
            log_verbose_error("Failed to load modules")
            return
        }

        module_on_set_module_cache(modules)

        //Setup application
        application.running = true
        application.main_module = &modules[0]
        application.modules = modules
        module_on_set_application_cache(modules, &application)

        //Initialize glfw
        if glfw.Init() != 1
        {
            log_verbose_error("Failed to initialize glfw")
            module_unload_multiple(application.modules)
            delete(application.modules, allocator)
            return
        }
        
        //Create window
        created_window := application_create_window(&application)
        if !created_window
        {
            log_verbose_error("Failed to create window")
            glfw.Terminate()
            module_unload_multiple(application.modules)
            delete(application.modules, allocator)
            return
        }

        //Create renderer
        created_renderer := application_create_renderer(&application)
        if !created_renderer
        {
            log_verbose_error("Failed to create renderer")
            window_destroy(&application.ui.window)
            glfw.Terminate()
            module_unload_multiple(application.modules)
            delete(application.modules, allocator)
            return
        }
        
        //Create streamer
        created_streamer := pkg.init(&application.streamer, package_paths, 100, context.allocator, allocator)
        if !created_streamer
        {
            log_verbose_error("Failed to create streamer")
            renderer_destroy(&application.graphics.renderer)
            window_destroy(&application.ui.window)
            glfw.Terminate()
            module_unload_multiple(application.modules)
            delete(application.modules, allocator)
            return
        }

        //Create ecs
        if !ecs.init(&application.ecs, 100_000, context.allocator)
        {
            log_verbose_error("Failed to create ecs")
            pkg.destroy(&application.streamer)
            renderer_destroy(&application.graphics.renderer)
            window_destroy(&application.ui.window)
            glfw.Terminate()
            module_unload_multiple(application.modules)
            delete(application.modules, allocator)
            return
        }

        //Create pool
        created_pool := application_create_pool(&application)
        if !created_pool
        {
            log_verbose_error("Failed to create pool")
            ecs.destroy(&application.ecs)
            pkg.destroy(&application.streamer)
            renderer_destroy(&application.graphics.renderer)
            window_destroy(&application.ui.window)
            glfw.Terminate()
            module_unload_multiple(application.modules)
            delete(application.modules, allocator)
            return
        }
        
        //On init
        thread.pool_start(&application.pool)
        module_on_begin(application.modules)

        for application.running
        {
            //Update window
            if !window_update(&application.ui.window) do application.running = false

            //Update glfw
            glfw.PollEvents()

            //Update ecs
            
            //Update streamer
            pkg.frame(&application.streamer, &application.pool)
            
            //Update renderer
            renderer_update(&application.graphics.renderer)
        }

        module_unload_multiple(application.modules)
        thread.pool_finish(&application.pool)// We need to finish all tasks before start destroying things
        thread.pool_destroy(&application.pool)
        ecs.destroy(&application.ecs)
        pkg.destroy(&application.streamer)
        renderer_destroy(&application.graphics.renderer)
        window_destroy(&application.ui.window)
        glfw.Terminate()
        delete(application.modules, allocator)
    }
}

/* Version */


Version :: struct
{
    major, minor, patch: u32,
}

when IMPLEMENTATION
{
/*
Return navis version
*/
    @(export=EXPORT, link_prefix=PREFIX)
    version :: proc "contextless" () -> Version
    {
        return Version{VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH}
    }
}

/* Application */


Application_UI :: struct //TODO(cris): put it inside 'Application_Graphics'
{
    window: Window,
}

Application_Graphics :: struct
{
    renderer: Renderer,
}

Application :: struct
{
    running: bool,
    main_module: ^Module,
    modules: []Module,
    ui: Application_UI,
    graphics: Application_Graphics,
    ecs: ecs.ECS,
    streamer: pkg.Streamer,
    pool: thread.Pool,
}

/* Module */

import "core:dynlib"

MODULE_NAME_OF :: "navis_module_name_of"
Module_Name_Of :: #type proc(^Module, runtime.Allocator) -> string

MODULE_ON_LOAD :: "navis_module_on_load"
Module_On_Load :: #type proc(^Module)

MODULE_ON_UNLOAD :: "navis_module_on_unload"
Module_On_Unload :: #type proc()

MODULE_ON_BEGIN :: "navis_module_on_begin"
Module_On_Begin :: #type proc()

MODULE_ON_END   :: "navis_module_on_end"
Module_On_End :: #type proc()

MODULE_ON_SET_MODULE_CACHE :: "navis_module_on_set_module_cache"
Module_On_Set_Module_Cache :: #type proc(^Module)

MODULE_ON_SET_APPLICATION_CACHE :: "navis_module_on_set_application_cache"
Module_On_Set_Application_Cache :: #type proc(^Application)

MODULE_ON_CREATE_WINDOW :: "navis_module_on_create_window"
Module_On_Create_Window :: #type proc(^Window_Descriptor, runtime.Allocator)

MODULE_ON_CREATE_RENDERER :: "navis_module_on_create_renderer"
Module_On_Create_Renderer :: #type proc(^Renderer_Descriptor)

Module :: struct
{
    library: dynlib.Library,
    name_of: Module_Name_Of,
    on_load: Module_On_Load,
    on_unload: Module_On_Unload,
    on_begin: Module_On_Begin,
    on_end: Module_On_End,
    on_set_module_cache: Module_On_Set_Module_Cache,
    on_set_application_cache: Module_On_Set_Application_Cache,
    on_create_window: Module_On_Create_Window,
    on_create_renderer: Module_On_Create_Renderer,
}

when MODULE
{
    /* TODO(cris): doc */
    application: ^Application

    /* TODO(cris): doc */
    module: ^Module

    // @(export=ODIN_BUILD_MODE==.Dynamic, link_name=MODULE_NAME_OF)
    // navis_module_name_of :: proc(id: typeid, allocator := context.allocator) -> string
    // {
    //     return get_name_of(id, allocator)
    // }

    @(export=ODIN_BUILD_MODE==.Dynamic, link_name=MODULE_ON_SET_MODULE_CACHE)
    navis_module_on_set_module_cache :: proc(module_: ^Module)
    {
        module = module_
    }

    @(export=ODIN_BUILD_MODE==.Dynamic, link_name=MODULE_ON_SET_APPLICATION_CACHE)
    navis_module_on_set_application_cache :: proc(p_application: ^Application)
    {
        application = p_application
    }

    exit :: #force_inline proc "contextless" ()
    {
        application.running = false
    }

    renderer_refresh_cached :: proc "contextless" ()
    {
       renderer_refresh_uncached(&application.graphics.renderer)
    }

    renderer_refresh :: proc{
        renderer_refresh_uncached,
        renderer_refresh_cached,
    }

    create_entity :: #force_inline proc() -> ecs.Entity_ID
    {
        return ecs.create_entity(&application.ecs)
    }

    destroy_entity :: #force_inline proc(id: ecs.Entity_ID) -> bool
    {
        return ecs.destroy_entity(&application.ecs, id)
    }

    // component_register :: proc($T: typeid, chunk_slots: int) -> bool
    // {
    //     return ecs_register_component(&application.ecs, T, chunk_slots)
    // }

    // component_on_create :: proc(on_create: proc(^$T, ^Entity)) -> bool
    // {
    //     return ecs_set_component_on_create(&application.ecs, T, on_create)
    // }

    // component_on_destroy :: proc(on_destroy: proc(^$T, ^Entity)) -> bool
    // {
    //     return ecs_set_component_on_destroy(&application.ecs, T, on_destroy)
    // }

    // component_add :: proc($T: typeid, entity: ^Entity) -> ^T
    // {
    //     return ecs_add_component(&application.ecs, entity, T)
    // }

    // system_register :: proc(system: proc(^$T)) -> bool
    // {
    //     return ecs_register_system(&application.ecs, T, system)
    // }

    require_shader :: proc(package_name, asset_name: string) -> bool
    {
        return renderer_require_shader(&application.graphics.renderer, &application.streamer, &application.pool, package_name, asset_name)
    }
}

when IMPLEMENTATION
{
    import "bgfx"
    import "vendor:glfw"

    /* Application Window */

    application_create_window :: proc(application: ^Application) -> bool
    {
        if application.main_module.on_create_window == nil
        {
            log_verbose_error("Invalid on create window on vtable", application.main_module.on_create_window)
            return false
        }

        desc: Window_Descriptor
        module_on_create_window(application.main_module, &desc, context.allocator)
        defer if desc.title != "" do delete(desc.title, context.allocator)

        window, window_succ := window_create(&desc)
        if !window_succ do return false

        application.ui.window = window

        return true
    }

    application_destroy_window :: proc(application: ^Application)
    {
        if application == nil || !window_is_valid(&application.ui.window) do return
        window_destroy(&application.ui.window)
    }

    /* Application Renderer */

    application_create_renderer :: proc(application: ^Application) -> bool
    {
        if application == nil
        {
            log_verbose_error("Invalid application parameter", application)
            return false
        }

        if !window_is_valid(&application.ui.window)
        {
            log_verbose_error("Invalid application window", application.ui.window)
            return false
        }
        
        //On create renderer
        descriptor: Renderer_Descriptor
        module_on_create_renderer(application.main_module, &descriptor)
        
        //Creating renderer
        if !renderer_init(&application.graphics.renderer, &application.ui.window, &descriptor)
        {
            log_verbose_error("Failed to create renderer", descriptor)
            return false
        }

        return true
    }

    application_destroy_renderer :: proc(application: ^Application)
    {
        if application == nil
        {
            return
        }

        renderer_destroy(&application.graphics.renderer)
    }

    application_create_pool :: proc(application: ^Application) -> bool
    {
        if application == nil do return false
        thread.pool_init(&application.pool, context.allocator, os.processor_core_count())
        return true
    }

    application_destroy_pool :: proc(application: ^Application) -> bool
    {
        if application == nil do return false
        thread.pool_finish(&application.pool)
        thread.pool_destroy(&application.pool)
        return true
    }
}

when IMPLEMENTATION
{
    import "core:strings"
    import "core:path/filepath"
    import "core:fmt"

/*
Treats a module path, extension isn't required.

* Ignores any extension if included.
* Adds expected extension (.dll, .so) for each OS. 
*/
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

/*
Loads a module from path.

Obs: Library extension (.dll/.so) not required.
*/
    module_load_path :: proc(path: string, allocator := context.allocator) -> (Module, bool) #optional_ok
    {
        module_path := module_treat_path(path, context.temp_allocator)
        defer delete(module_path, context.temp_allocator)

        library, loaded := dynlib.load_library(module_path)
        if !loaded do return {}, false

        module: Module
        module.library = library

        module.name_of = auto_cast dynlib.symbol_address(module.library, MODULE_NAME_OF)

        module.on_load = auto_cast dynlib.symbol_address(module.library, MODULE_ON_LOAD)
        module.on_unload = auto_cast dynlib.symbol_address(module.library, MODULE_ON_UNLOAD)

        module.on_begin = auto_cast dynlib.symbol_address(module.library, MODULE_ON_BEGIN)
        module.on_end = auto_cast dynlib.symbol_address(module.library, MODULE_ON_END)

        module.on_set_module_cache = auto_cast dynlib.symbol_address(module.library, MODULE_ON_SET_MODULE_CACHE)
        module.on_set_application_cache = auto_cast dynlib.symbol_address(module.library, MODULE_ON_SET_APPLICATION_CACHE)
        module.on_create_window = auto_cast dynlib.symbol_address(module.library, MODULE_ON_CREATE_WINDOW)
        module.on_create_renderer = auto_cast dynlib.symbol_address(module.library, MODULE_ON_CREATE_RENDERER)

        //On Load
        module_on_load(&module)
        return module, true
    }

/*
Unloads a module.
*/
    module_unload_single :: proc(module: ^Module) -> bool
    {
        if module == nil do return false

        //On Unload
        module_on_unload(module)

        return dynlib.unload_library(module.library)
        //return bool(windows.FreeLibrary(module.handle))
    }

/*
Load multiple modules.
*/
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
        
        return slice_from_dynamic(modules, allocator)
    }

/*
Unload multiple modules.
*/
    module_unload_multiple :: proc(modules: []Module)
    {
        if modules == nil do return
        for module, index in modules do module_unload_single(&modules[index])
    }

    module_load :: proc{
        module_load_path,
        module_load_paths,
    }

    module_unload :: proc{
        module_unload_single,
        module_unload_multiple,
    }

    /* On Load */

    module_on_load_single :: proc(module: ^Module)
    {
        if module == nil || module.on_load == nil do return
        module.on_load(module)
    }

    module_on_load_multiple :: proc(modules: []Module)
    {
        if slice_is_nil_or_empty(modules) do return
        for i := 0; i < len(modules); i += 1 do module_on_load_single(&modules[i])
    }

    module_on_load :: proc{
        module_on_load_single,
        module_on_load_multiple,
    }
    
    /* On Unload */

    module_on_unload_single :: proc(module: ^Module)
    {
        if module == nil || module.on_unload == nil do return
        module.on_unload()
    }

    module_on_unload_multiple :: proc(modules: []Module)
    {
        if slice_is_nil_or_empty(modules) do return
        #reverse for &module in modules do module_on_unload_single(&module)
    }

    module_on_unload :: proc{
        module_on_unload_single,
        module_on_unload_multiple,
    }

    /* On Begin */

    module_on_begin_single :: proc(module: ^Module)
    {
        if module == nil || module.on_begin == nil do return
        module.on_begin()
    }

    module_on_begin_multiple :: proc(modules: []Module)
    {
        if slice_is_nil_or_empty(modules) do return
        for i := 0; i < len(modules); i += 1 do module_on_begin_single(&modules[i])
    }

    module_on_begin :: proc{
        module_on_begin_single,
        module_on_begin_multiple,
    }

    /* On End */

    module_on_end_single :: proc(module: ^Module)
    {
        if module == nil || module.on_end == nil do return
        module.on_end()
    }

    module_on_end_multiple :: proc(modules: []Module)
    {
        if slice_is_nil_or_empty(modules) do return
        #reverse for &module in modules do module_on_end_single(&module)
    }

    module_on_end :: proc{
        module_on_end_single,
        module_on_end_multiple,
    }

    /* On Set Module Cache */

    module_on_set_module_cache :: proc{
        module_on_set_module_cache_single,
        module_on_set_module_cache_multiple,
    }

    module_on_set_module_cache_single :: proc(module: ^Module)
    {
        if module == nil || module.on_set_module_cache == nil do return
        module.on_set_module_cache(module)
    }

    module_on_set_module_cache_multiple :: proc(modules: []Module)
    {
        if modules == nil do return
        for &module in modules do module_on_set_module_cache_single(&module)
    }

    /* On Set Application Cache */

    module_on_set_application_cache_single :: proc(module: ^Module, application: ^Application)
    {
        if module == nil || module.on_set_application_cache == nil || application == nil do return
        module.on_set_application_cache(application)
    }

    module_on_set_application_cache_multiple :: proc(modules: []Module, application: ^Application)
    {
        if slice_is_nil_or_empty(modules) || application == nil do return
        for i := 0; i < len(modules); i += 1 do module_on_set_application_cache_single(&modules[i], application)
    }

    module_on_set_application_cache :: proc{
        module_on_set_application_cache_single,
        module_on_set_application_cache_multiple,
    }

    /* On Create Window */
    
    module_on_create_window_single :: proc(module: ^Module, descriptor: ^Window_Descriptor, allocator := context.allocator)
    {
        if module == nil || module.on_create_window == nil || descriptor == nil do return
        module.on_create_window(descriptor, allocator)
    }

    module_on_create_window :: proc{
        module_on_create_window_single,
    }

    /* On Create Renderer */

    module_on_create_renderer_single :: proc(module: ^Module, descriptor: ^Renderer_Descriptor)
    {
        if module == nil || module.on_create_renderer == nil || descriptor == nil do return
        module.on_create_renderer(descriptor)
    }

    module_on_create_renderer :: proc{
        module_on_create_renderer_single,
    }
}