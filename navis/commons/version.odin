package commons

import "navis:api"

when api.IMPLEMENTATION
{
    @(export=api.SHARED, link_prefix=PREFIX)
    version_major :: proc "contextless" () -> u32
    {
        return api.VERSION_MAJOR
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    version_minor :: proc "contextless" () -> u32
    {
        return api.VERSION_MINOR
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    version_patch :: proc "contextless" () -> u32
    {
        return api.VERSION_PATCH
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    version_pack :: proc "contextless" (major, minor, patch: u32) -> Version
    {
        return Version{major, minor, patch}
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    version_unpack :: proc "contextless" (version: Version) -> (major, minor, patch: u32)
    {
        major = version.major
        minor = version.minor
        patch = version.patch
        return
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    version :: proc "contextless" () -> Version
    {
        return Version{api.VERSION_MAJOR, api.VERSION_MINOR, api.VERSION_PATCH}
    }
}