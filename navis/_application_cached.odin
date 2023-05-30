package navis

import "navis:api"

when api.IMPORT
{
    application: ^Application

    @(export=ODIN_BUILD_MODE==.Dynamic)
    navis_module_on_application_set_cache :: proc(p_application: ^Application)
    {
        application = p_application
    }
}