package navis

import "pkg"

when MODULE
{
    streamer_require_asset :: proc(asset_name: string, on_loaded: pkg.Proc_On_Asset_Loaded = nil, user_data : rawptr = nil, idle_frames := 0) -> bool
    {
        return streamer_require_asset_uncached(application, asset_name, on_loaded, user_data, idle_frames)
    }

    streamer_dispose_asset :: proc(asset_name: string, idle_frames := 0) -> bool
    {
        return streamer_dispose_asset_uncached(application, asset_name, idle_frames)
    }
}

when IMPLEMENTATION
{

    @(export=EXPORT, link_prefix=PREFIX)
    streamer_require_asset_uncached :: proc(application: ^Application, asset_name: string, on_loaded: pkg.Proc_On_Asset_Loaded = nil, user_data : rawptr = nil, idle_frames := 0) -> bool
    {
        return pkg.require(&application.streamer, &application.pool, asset_name, on_loaded, user_data, idle_frames)
    }

    @(export=EXPORT, link_prefix=PREFIX)
    streamer_dispose_asset_uncached :: proc(application: ^Application, asset_name: string, idle_frames := 0) -> bool
    {
        return pkg.dispose(&application.streamer, asset_name, idle_frames)
    }
}