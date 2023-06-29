package navis

import "navis:api"

when api.EXPORT
{
    import "navis:commons"
    import "navis:commons/log"
    import "navis:graphics"
    import "navis:graphics/ui"
    import "navis:graphics/bgfx"
    import "vendor:glfw"

/*
Begins an Application with provided paths.
* First path (index 0) is treated as the main module.
*/
    application_begin_from_paths :: proc(application: ^Application, paths: []string, allocator := context.allocator) -> bool
    {
        if application == nil
        {
            log.verbose_error("Invalid application parameter", application)
            return false
        }

        if commons.slice_is_nil_or_empty(paths)
        {
            log.verbose_error("Invalid paths parameter", paths)
            return false
        }

        //Loading modules
        modules, modules_load_success := module_load_paths(paths = paths, allocator = allocator)
        if !modules_load_success
        {
            log.verbose_error("Failed to load modules")
            return false
        }

        //Setup application
        application.running = true
        application.main_module = &modules[0]
        application.modules = modules
        module_on_set_application_cache(modules, application)

        //Initialize glfw
        if glfw.Init() != 1
        {
            log.verbose_error("Failed to initialize glfw")
            return false
        }
        
        //Create window
        created_window := application_create_window(application)
        if !created_window
        {
            log.verbose_error("Failed to create window")
            return false
        }

        //Create renderer
        created_renderer := application_create_renderer(application)
        if !created_renderer
        {
            log.verbose_error("Failed to create renderer")
            return false
        }
        
        //On init
        module_on_begin(application.modules)

        //Success
        return true
    }

/*
Performs Application loop.
*/
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
    application_end :: proc(application: ^Application, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(application == nil, "'nil' Application pointer", location) do return false
        if log.verbose_fail_error(application.running, "Application is Running", location) do return false

        //On end
        module_on_end(application.modules)

        //Destroy window
        application_destroy_window(application)
        
        //Finalize renderer
        application_destroy_renderer(application)

        //Unload modules
        if application.modules != nil do module_unload(application.modules)
        application.modules = nil
        application.main_module = nil

        //Finalize glfw
        glfw.Terminate()

        return true
    }

    application_update :: proc(application: ^Application)
    {
        //Update window
        if !ui.window_update(&application.ui.window) do exit_uncached(application)

        //Update glfw
        glfw.PollEvents()
        
        //Update renderer
        graphics.renderer_update(&application.graphics.renderer)
    }

    /* Application Window */

    application_create_window :: proc(application: ^Application) -> bool
    {
        if application.main_module.vtable.on_create_window == nil
        {
            log.verbose_error("Invalid on create window on vtable", application.main_module.vtable.on_create_window)
            return false
        }

        desc: ui.Window_Descriptor
        module_on_create_window(application.main_module, &desc, context.allocator)
        defer if desc.title != "" do delete(desc.title, context.allocator)

        window, window_succ := ui.window_create(&desc)
        if !window_succ do return false

        application.ui.window = window

        return true
    }

    application_destroy_window :: proc(application: ^Application)
    {
        if application == nil || !ui.window_is_valid(&application.ui.window) do return
        ui.window_destroy(&application.ui.window)
    }

    /* Application Renderer */

    application_create_renderer :: proc(application: ^Application) -> bool
    {
        if application == nil
        {
            log.verbose_error("Invalid application parameter", application)
            return false
        }

        if !ui.window_is_valid(&application.ui.window)
        {
            log.verbose_error("Invalid application window", application.ui.window)
            return false
        }
        
        //On create renderer
        descriptor: graphics.Renderer_Descriptor
        module_on_create_renderer(application.main_module, &descriptor)
        
        //Creating renderer
        renderer, created := graphics.renderer_create(&descriptor, &application.ui.window)
        if !created
        {
            log.verbose_error("Failed to create renderer", descriptor)
            return false
        }
        
        //Success
        application.graphics.renderer = renderer
        return true
    }

    application_destroy_renderer :: proc(application: ^Application)
    {
        if application == nil
        {
            return
        }

        graphics.renderer_destroy(&application.graphics.renderer)
    }
}