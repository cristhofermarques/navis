package vk

import "navis:api"

when api.EXPORT
{
    import "navis:commons/log"
    import "core:dynlib"

    @(export=api.SHARED, link_prefix=PREFIX)
    library_load :: proc() -> (Library, bool)
    {
        name: string
        when ODIN_OS == .Windows do name = "vulkan-1.dll"
        when ODIN_OS == .Linux   do name = "vulkan.so.1"

        log.verbose_info("Loading vulkan library", name)
        library, success := dynlib.load_library(name)
        if !success
        {
            log.verbose_error("Failed to load vulkan library", name)
            return nil, false
        }

        log.verbose_info("Vulkan library Loaded", name, library)
        return library, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    library_unload :: proc(library: Library) -> bool
    {
        if !library_is_valid(library)
        {
            log.verbose_error("Invalid vulkan library parameter")
            return false
        }

        unloaded := dynlib.unload_library(library)
        if !unloaded
        {
            log.verbose_error("Failed to unload vulkan library")
            return false
        }
        
        log.verbose_info("Vulkan library unloaded")
        return true
    }
}