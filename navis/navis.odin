package navis

import "navis:api"

when api.EXPORT
{
    import "commons"
    import "commons/log"

    import "graphics"
    import graphics_commons "graphics/commons"
    import "graphics/ui"

    @(export=api.SHARED, link_prefix=PREFIX)
    run_from_paths :: proc(paths: ..string, allocator := context.allocator)
    {
        application: Application
        if !application_begin_from_paths(&application, paths, allocator) do return
        defer application_end(&application)
        application_loop(&application)
    }
    
    @(export=api.SHARED, link_prefix=PREFIX)
    exit_uncached :: proc(application: ^Application)
    {
        if application == nil do return
        
        application.running = false
    }
}