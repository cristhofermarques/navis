package vk

import "navis:api"

when api.EXPORT
{
    import "navis:commons/log"
    import "core:dynlib"

    @(export=api.SHARED, link_prefix=PREFIX)
    library_load :: proc(location := #caller_location) -> (Library, bool)
    {
        name: string
        when ODIN_OS == .Windows do name = "vulkan-1.dll"
        when ODIN_OS == .Linux   do name = "vulkan.so.1"

        log.verbose_info(args = {"Loading vulkan library", name}, sep = " ", location = location)
        library, success := dynlib.load_library(name)
        if !success
        {
            log.verbose_error(args = {"Failed to load vulkan library", name}, sep = " ", location = location)
            return nil, false
        }

        log.verbose_info(args = {"Vulkan library Loaded", name, library}, sep = " ", location = location)
        return library, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    library_unload :: proc(library: Library, location := #caller_location) -> bool
    {
        if !library_is_valid(library)
        {
            log.verbose_error(args = {"Invalid vulkan library parameter"}, sep = " ", location = location)
            return false
        }

        unloaded := dynlib.unload_library(library)
        if !unloaded
        {
            log.verbose_error(args = {"Failed to unload vulkan library", library}, sep = " ", location = location)
            return false
        }
        
        log.verbose_info(args = {"Vulkan library unloaded"}, sep = " ", location = location)
        return true
    }
}