package commons

import "navis:api"

when api.BINDINGS
{ 
    when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

    @(default_calling_convention = "odin")
    foreign navis
    {
        /* Version */
        @(link_prefix=PREFIX)
        version_major :: proc "contextless" () -> u32 ---

        @(link_prefix=PREFIX)
        version_minor :: proc "contextless" () -> u32 ---

        @(link_prefix=PREFIX)
        version_patch :: proc "contextless" () -> u32 ---

        @(link_prefix=PREFIX)
        version_pack :: proc "contextless" (major, minor, patch: u32) -> Version ---

        @(link_prefix=PREFIX)
        version_unpack :: proc "contextless" (version: Version) -> (major, minor, patch: u32) ---

        @(link_prefix=PREFIX)
        version :: proc "contextless" () -> Version ---
    }
}