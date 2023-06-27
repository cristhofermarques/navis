package navis

import "api"

import "commons"
import "commons/log"

import "graphics"
import graphics_commons "graphics/commons"
import "graphics/vulkan/vk"
import "graphics/vulkan/shaderc"
import "graphics/vulkan"
import "graphics/ui"

run_from_paths :: #force_inline proc(modules_paths, packages_paths: []string, allocator := context.allocator)
{
    application: Application
    if !application_begin_from_paths(&application, modules_paths, packages_paths, allocator) do return
    defer application_end(&application)
    application_loop(&application)
}

run :: proc{
    run_from_paths,
}