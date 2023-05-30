package navis

import "navis:api"

when api.EXPORT
{
    import "navis:commons"
    import "navis:commons/log"
    import "navis:commons/utility"
    import "navis:graphics/ui"
    import "navis:commons/input"
    import "core:time"
    import "core:fmt"
    
/*
Begins an Application with provided paths.
* First path (index 0) is treated as the main module.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    application_begin_paths :: proc(application: ^Application, paths: ..string, allocator := context.allocator, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(application == nil, "'nil' Application pointer", location) do return false
        if log.verbose_fail_error(paths == nil, "'nil' paths slice", location) do return false

        modules, modules_succ := module_load_paths(paths = paths, allocator = allocator)
        if log.verbose_fail_error(!modules_succ, "Load Modules", location) do return false
        
        return application_begin_modules(application = application, modules = modules, allocator = allocator, location = location)
    }

/*
Begins an Application with provided modules.
* First module (index 0) is treated as the main module.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    application_begin_modules :: proc(application: ^Application, modules: ..Module, allocator := context.allocator, location := #caller_location) -> bool
    {
        if application == nil || modules == nil do return false
        
        main_module, main_module_succ := utility.slice_try_get_pointer(modules, 0)
        if log.verbose_fail_error(!main_module_succ, "Get Main Module", location)
        {
            module_unload(modules)
            return false
        }

        application.running = true
        application.main_module = main_module
        application.modules = modules

        module_on_application_set_cache(application.modules, application)
        module_on_application_begin(application.modules, application)
        application_create_window(application)

        return true
    }

/*
Performs Application loop.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    application_loop :: proc(application: ^Application)
    {
        if application == nil do return

        for application.running
        {
            application_update(application)
        }
    }

/*
Ends Application.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    application_end :: proc(application: ^Application, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(application == nil, "'nil' Application pointer", location) do return false
        if log.verbose_fail_error(application.running, "Application is Running", location) do return false

        application_destroy_window(application)
        module_on_application_end(application.modules, application)

        if application.modules != nil do module_unload(application.modules)
        application.modules = nil
        application.main_module = nil
        return true
    }

/*
Update Application.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    application_update :: proc(application: ^Application)
    {
        application_begin_frame(application)

        application_update_window(application)

        application_end_frame(application)
    }

    application_begin_frame :: #force_inline proc(application: ^Application)
    {
        dt_sw := &application.time.delta_time_stopwatch

        time.stopwatch_reset(dt_sw)
        time.stopwatch_start(dt_sw)
    }

    application_end_frame :: #force_inline proc(application: ^Application)
    {
        dt_sw := &application.time.delta_time_stopwatch

        time.stopwatch_stop(dt_sw)
        dt_du := time.stopwatch_duration(dt_sw^)
        delta_time := time.duration_seconds(dt_du)
        application.time.delta_time = delta_time
    }

    application_create_window :: proc(application: ^Application) -> bool
    {
        desc: ui.Window_Descriptor
        application.main_module.vtable.on_application_create_window(&desc, context.allocator)
        defer if desc.title != "" do delete(desc.title, context.allocator)

        window, window_succ := ui.window_create(&desc, context.allocator)
        if !window_succ do return false

        commons.event_append(&window.common.event, desc.event_callback)
        application.ui.window = window
        return true
    }

    application_destroy_window :: proc(application: ^Application)
    {
        if application == nil || !ui.window_is_valid(&application.ui.window) do return
        ui.window_destroy(&application.ui.window)
    }

    application_update_window :: proc(application: ^Application)
    {
        if application == nil || !ui.window_is_valid(&application.ui.window) do return
        stop_running := !ui.window_update(&application.ui.window)
        if stop_running do application.running = false
    }
}