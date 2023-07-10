package navis

import "navis:api"
import "navis:graphics"
import "navis:graphics/ui"
import "core:dynlib"
import "core:runtime"

MODULE_ON_LOAD :: "navis_module_on_load"
Module_On_Load :: #type proc(^Module)

MODULE_ON_UNLOAD :: "navis_module_on_unload"
Module_On_Unload :: #type proc()

MODULE_ON_BEGIN :: "navis_module_on_begin"
Module_On_Begin :: #type proc()

MODULE_ON_END   :: "navis_module_on_end"
Module_On_End :: #type proc()

MODULE_ON_SET_APPLICATION_CACHE :: "navis_module_on_set_application_cache"
Module_On_Set_Application_Cache :: #type proc(^Application)

MODULE_ON_CREATE_WINDOW :: "navis_module_on_create_window"
Module_On_Create_Window :: #type proc(^ui.Window_Descriptor, runtime.Allocator)

MODULE_ON_CREATE_RENDERER :: "navis_module_on_create_renderer"
Module_On_Create_Renderer :: #type proc(^graphics.Renderer_Descriptor)

Module_VTable :: struct
{
    on_load: Module_On_Load,
    on_unload: Module_On_Unload,
    on_begin: Module_On_Begin,
    on_end: Module_On_End,
    on_set_application_cache: Module_On_Set_Application_Cache,
    on_create_window: Module_On_Create_Window,
    on_create_renderer: Module_On_Create_Renderer,
}

Module :: struct
{
    __allocator: runtime.Allocator,
    path: string,
    library: dynlib.Library,
    vtable: Module_VTable,
}

when api.IMPLEMENTATION
{
    import "commons"

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
        if module == nil || module.vtable.on_load == nil do return
        module.vtable.on_load(module)
    }

    module_on_load_multiple :: proc(modules: []Module)
    {
        if commons.slice_is_nil_or_empty(modules) do return
        for i := 0; i < len(modules); i += 1 do module_on_load_single(&modules[0])
    }

    module_on_load :: proc{
        module_on_load_single,
        module_on_load_multiple,
    }
    
    /* On Unload */

    module_on_unload_single :: proc(module: ^Module)
    {
        if module == nil || module.vtable.on_unload == nil do return
        module.vtable.on_unload()
    }

    module_on_unload_multiple :: proc(modules: []Module)
    {
        if commons.slice_is_nil_or_empty(modules) do return
        for i := 0; i < len(modules); i += 1 do module_on_unload_single(&modules[0])
    }

    module_on_unload :: proc{
        module_on_unload_single,
        module_on_unload_multiple,
    }

    /* On Begin */

    module_on_begin_single :: proc(module: ^Module)
    {
        if module == nil || module.vtable.on_begin == nil do return
        module.vtable.on_begin()
    }

    module_on_begin_multiple :: proc(modules: []Module)
    {
        if commons.slice_is_nil_or_empty(modules) do return
        for i := 0; i < len(modules); i += 1 do module_on_begin_single(&modules[0])
    }

    module_on_begin :: proc{
        module_on_begin_single,
        module_on_begin_multiple,
    }

    /* On End */

    module_on_end_single :: proc(module: ^Module)
    {
        if module == nil || module.vtable.on_end == nil do return
        module.vtable.on_end()
    }

    module_on_end_multiple :: proc(modules: []Module)
    {
        if commons.slice_is_nil_or_empty(modules) do return
        for i := 0; i < len(modules); i += 1 do module_on_end_single(&modules[0])
    }

    module_on_end :: proc{
        module_on_end_single,
        module_on_end_multiple,
    }

    /* On Set Application Cache */

    module_on_set_application_cache_single :: proc(module: ^Module, application: ^Application)
    {
        if module == nil || module.vtable.on_set_application_cache == nil || application == nil do return
        module.vtable.on_set_application_cache(application)
    }

    module_on_set_application_cache_multiple :: proc(modules: []Module, application: ^Application)
    {
        if commons.slice_is_nil_or_empty(modules) || application == nil do return
        for i := 0; i < len(modules); i += 1 do module_on_set_application_cache_single(&modules[i], application)
    }

    module_on_set_application_cache :: proc{
        module_on_set_application_cache_single,
        module_on_set_application_cache_multiple,
    }

    /* On Create Window */
    
    module_on_create_window_single :: proc(module: ^Module, descriptor: ^ui.Window_Descriptor, allocator := context.allocator)
    {
        if module == nil || module.vtable.on_create_window == nil || descriptor == nil do return
        module.vtable.on_create_window(descriptor, allocator)
    }

    module_on_create_window :: proc{
        module_on_create_window_single,
    }

    /* On Create Renderer */

    module_on_create_renderer_single :: proc(module: ^Module, descriptor: ^graphics.Renderer_Descriptor)
    {
        if module == nil || module.vtable.on_create_renderer == nil || descriptor == nil do return
        module.vtable.on_create_renderer(descriptor)
    }

    module_on_create_renderer :: proc{
        module_on_create_renderer_single,
    }
}