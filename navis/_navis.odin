package navis

import "api"

import "commons/utility"
import "commons/log"
import "commons"

import graphics_commons "graphics/commons"
import "graphics/vulkan/vk"
import "graphics/vulkan"
import "graphics/ui"
import "graphics"

when api.EXPORT
{
    import "core:runtime"

    @(export=api.SHARED)
    types :: proc()
    {
        //a := type_info_of(graphics_commons.Window)
    }
}

run_paths :: #force_inline proc(paths: ..string, allocator := context.allocator, location := #caller_location)
{
    application: Application
    if !application_begin_paths(application = &application, paths = paths, allocator = allocator, location = location) do return
    defer application_end(application = &application, location = location)
    application_loop(&application)
}

run :: proc{
    run_paths,
}