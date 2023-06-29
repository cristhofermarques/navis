package navis

import "navis:api"

when api.IMPORT
{
    import "graphics"

    application: ^Application

    @(export=ODIN_BUILD_MODE==.Dynamic, link_name=MODULE_ON_SET_APPLICATION_CACHE)
    navis_module_on_set_application_cache :: proc(p_application: ^Application)
    {
        application = p_application
    }

    exit_cached :: proc()
    {
        exit_uncached(application)
    }

    exit :: proc{
        exit_uncached,
        exit_cached,
    }

    renderer_refresh_cached :: proc "contextless" ()
    {
        graphics.renderer_refresh_uncached(&application.graphics.renderer)
    }

    renderer_refresh :: proc{
        graphics.renderer_refresh_uncached,
        renderer_refresh_cached,
    }
}