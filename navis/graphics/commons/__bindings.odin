package graphics_commons

import "navis:api"

PREFIX :: "navis_graphics_"

when api.IMPORT
{
    when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

    @(default_calling_convention="odin")
    foreign navis
    {
        /* Window */
        @(link_prefix=PREFIX)
        ui_window_is_valid :: proc(window: ^Window) -> bool ---

        @(link_prefix=PREFIX)
        ui_window_create_separated :: proc(title: string, width, height: u32, mode: Window_Mode, location := #caller_location) -> (Window, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        ui_window_create_desc :: proc(desc: Window_Desc, allocator := context.allocator, location := #caller_location) -> (Window, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        ui_window_destroy :: proc(window: ^Window, location := #caller_location) -> bool ---

        @(link_prefix=PREFIX)
        ui_window_update :: proc(window : ^Window) -> bool ---

        @(link_prefix=PREFIX)
        ui_window_show :: proc(wnd : ^Window) ---

        @(link_prefix=PREFIX)
        ui_window_hide :: proc(wnd : ^Window) ---

        @(link_prefix=PREFIX)
        ui_window_minimize :: proc(wnd : ^Window) ---

        @(link_prefix=PREFIX)
        ui_window_maximize :: proc(wnd : ^Window) ---

        @(link_prefix=PREFIX)
        ui_window_get_title :: proc(window : ^Window, allocator := context.allocator) -> (string, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        ui_window_set_title :: proc(window : ^Window, title: string) -> bool ---

        @(link_prefix=PREFIX)
        ui_window_get_x :: proc(wnd : ^Window) -> i32 ---

        @(link_prefix=PREFIX)
        ui_window_get_y :: proc(wnd : ^Window) -> i32 ---

        @(link_prefix=PREFIX)
        ui_window_set_x :: proc(wnd : ^Window, x : i32) ---

        @(link_prefix=PREFIX)
        ui_window_set_y :: proc(wnd : ^Window, y : i32) ---

        @(link_prefix=PREFIX)
        ui_window_get_width :: proc(wnd : ^Window) -> i32 ---

        @(link_prefix=PREFIX)
        ui_window_get_height :: proc(wnd : ^Window) -> i32 ---

        @(link_prefix=PREFIX)
        ui_window_set_width :: proc(wnd : ^Window, width : i32) ---

        @(link_prefix=PREFIX)
        ui_window_set_height :: proc(wnd : ^Window, height : i32) ---

        @(link_prefix=PREFIX)
        ui_window_get_client_bounds :: proc(wnd : ^Window) -> Rect_I32 ---

        @(link_prefix=PREFIX)
        ui_window_get_bounds :: proc(wnd : ^Window) -> Rect_I32 ---

        @(link_prefix=PREFIX)
        ui_window_set_bounds :: proc(wnd : ^Window, bounds: Rect_I32) ---

    }
}