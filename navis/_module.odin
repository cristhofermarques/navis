package navis

import "navis:api"
import "navis:graphics/ui"
import "navis:graphics/vulkan"
import "core:dynlib"
import "core:runtime"

MODULE_ON_LOAD :: "navis_module_on_load"
Module_On_Load :: #type proc(^Module)

MODULE_ON_UNLOAD :: "navis_module_on_unload"
Module_On_Unload :: #type proc(^Module)

MODULE_ON_APPLICATION_SET_CACHE :: "navis_module_on_application_set_cache"
Module_On_Application_Set_Cache :: #type proc(^Application)

MODULE_ON_APPLICATION_BEGIN :: "navis_module_application_on_begin"
Module_On_Application_Begin :: #type proc "odin" (^Application)

MODULE_ON_APPLICATION_END   :: "navis_module_application_on_end"
Module_On_Application_End :: #type proc "odin" (^Application)

MODULE_ON_APPLICATION_CREATE_WINDOW :: "navis_application_module_on_create_window"
Module_On_Application_Create_Window :: #type proc "odin" (^ui.Window_Descriptor, runtime.Allocator)

/* Vulkan */
MODULE_ON_APPLICATION_CREATE_VULKAN_RENDERER :: "navis_application_module_on_create_vulkan_renderer"
Module_On_Application_Create_Vulkan_Renderer :: #type proc(^vulkan.Renderer_Info, runtime.Allocator)

Module_VTable :: struct
{
    on_load: Module_On_Load,
    on_unload: Module_On_Unload,
    on_application_begin: Module_On_Application_Begin,
    on_application_end: Module_On_Application_End,
    on_application_set_cache: Module_On_Application_Set_Cache,
    on_application_create_window: Module_On_Application_Create_Window,
    on_application_create_vulkan_renderer: Module_On_Application_Create_Vulkan_Renderer,
}

Module :: struct
{
    __allocator: runtime.Allocator,
    path: string,
    library: dynlib.Library,
    vtable: Module_VTable,
}

module_on_load :: #force_inline proc(module: ^Module)
{
    if module == nil || module.vtable.on_load == nil do return
    module.vtable.on_load(module)
}

module_on_unload :: #force_inline proc(module: ^Module)
{
    if module == nil || module.vtable.on_unload == nil do return
    module.vtable.on_unload(module)
}

module_on_application_create_window_single :: #force_inline proc(module: ^Module, desc: ^ui.Window_Descriptor, allocator := context.allocator)
{
    if module == nil || module.vtable.on_application_create_window == nil || desc == nil do return
    module.vtable.on_application_create_window(desc, allocator)
}

module_on_application_begin_single :: #force_inline proc(module: ^Module, application: ^Application)
{
    if module == nil || module.vtable.on_application_begin == nil || application == nil do return
    module.vtable.on_application_begin(application)
}

module_on_application_begin_multiple :: #force_inline proc(modules: []Module, application: ^Application)
{
    if modules == nil || application == nil do return
    for module, index in modules do module_on_application_begin_single(&modules[index], application)
}

module_on_application_end_single :: #force_inline proc(module: ^Module, application: ^Application)
{
    if module == nil || module.vtable.on_application_end == nil || application == nil do return
    module.vtable.on_application_end(application)
}

module_on_application_end_multiple :: #force_inline proc(modules: []Module, application: ^Application)
{
    if modules == nil || application == nil do return
    for module, index in modules do module_on_application_end_single(&modules[index], application)
}

module_on_application_set_cache_single :: #force_inline proc(module: ^Module, application: ^Application)
{
    if module == nil || module.vtable.on_application_set_cache == nil || application == nil do return
    module.vtable.on_application_set_cache(application)
}

module_on_application_set_cache_multiple :: #force_inline proc(modules: []Module, application: ^Application)
{
    if modules == nil || application == nil do return
    for i := 0; i < len(modules); i += 1 do module_on_application_set_cache_single(&modules[i], application)
}

module_on_application_set_cache :: proc{
    module_on_application_set_cache_single,
    module_on_application_set_cache_multiple,
}

module_load :: proc{
    module_load_path,
    module_load_paths,
}

module_unload :: proc{
    module_unload_single,
    module_unload_multiple,
}

module_on_application_begin :: proc{
    module_on_application_begin_single,
    module_on_application_begin_multiple,
}

module_on_application_end :: proc{
    module_on_application_end_single,
    module_on_application_end_multiple,
}