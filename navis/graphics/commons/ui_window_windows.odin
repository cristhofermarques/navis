package graphics_commons

import "navis:api"
import "navis:commons"
import "navis:commons/log"
import "navis:commons/input"

when api.EXPORT_WINDOWS
{
    import "core:sys/windows"
    import "core:strings"

    WINDOW_CLASS_NAME :: "Nav_Window_Class"

    window_count: u32

/*
Returns if window is valid.
* Windows: HWND != nil
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_is_valid :: proc(window: ^Window) -> bool
    {
        if window == nil do return false
        return window.hwnd != nil
    }

/*
Create a Native Window
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_create_separated :: proc(title: string, width, height: u32, mode: Window_Mode, allocator := context.allocator, location := #caller_location) -> (Window, bool) #optional_ok
    {
        wndclass := compose_wndclassexw()
        found_wndclass := bool(windows.GetClassInfoExW(wndclass.hInstance, windows.L(WINDOW_CLASS_NAME), &wndclass))
        if !found_wndclass
        {
            log.verbose_info("Window Class not Found, Registering Window Class", " ", location)
            registered := bool(windows.RegisterClassExW(&wndclass))
            if log.verbose_fail_error(!registered, "Register Window Class") do return {}, false
        }

        wndstyle: windows.DWORD
        switch mode
        {
            case .Windowed:
                wndstyle = windows.WS_OVERLAPPED | windows.WS_SYSMENU

            case .Borderless:
                wndstyle = windows.WS_POPUP
        }
        
        title_cstr := strings.clone_to_cstring(title, context.allocator)
        defer delete(title_cstr, context.allocator)

        log.verbose_debug("Creating Window", " ", location)
        title_u16 := transmute([^]u16)title_cstr
        hwnd: windows.HWND = windows.CreateWindowExW(0, windows.L(WINDOW_CLASS_NAME), title_u16, wndstyle | windows.WS_VISIBLE, 0, 0, i32(width), i32(height), nil, nil, windows.HINSTANCE(windows.GetModuleHandleW(nil)), nil)
        if log.verbose_fail_error(hwnd == nil, "Create Window", location) do return {}, false

        event := commons.event_make(Window_Event_Callback, 10, allocator)

        window: Window
        window.common.mode = mode
        window.common.event = event
        window.hwnd = hwnd
        window_count += 1

        return window, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_create_desc :: proc(desc: Window_Desc, allocator := context.allocator, location := #caller_location) -> (Window, bool) #optional_ok
    {
        return ui_window_create(desc.title, desc.width, desc.height, desc.mode, allocator, location)
    }

/*
Destroy a Native Window
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_destroy :: proc(window: ^Window, location := #caller_location) -> bool
    {
        if log.verbose_fail_error(window == nil, "Window Argument is 'nil'", location) do return false
        
        log.verbose_debug("Destroying Window", location)
        success := bool(windows.DestroyWindow(window.hwnd))
        if log.verbose_fail_error(!success, "Destroy Window", location) do return false

        commons.event_delete(&window.common.event)

        if window_count -= 1; window_count == 0
        {
            log.verbose_info("There is no Window, Unregistering Window Class", location)

            hinstance := windows.HINSTANCE(windows.GetModuleHandleA(nil))
            unregister_succ := bool(windows.UnregisterClassW(windows.L(WINDOW_CLASS_NAME), hinstance))
            log.verbose_fail_error(!unregister_succ, "Unregister Window Class", location)
        }

        return true
    }

/*
Update Window
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_update :: proc(window : ^Window) -> bool
    {
        if window == nil || window.hwnd == nil do return false

        msg: windows.MSG
        hwnd := window.hwnd
        for windows.PeekMessageA(&msg, hwnd, 0, 0, windows.PM_REMOVE)
        {
            event := windows_message_to_window_event(msg.message)
            if event != .None do for callback in commons.event_iterator(&window.common.event) do callback(window, event)

            if event == .Close do return false
                    
            windows.TranslateMessage(&msg)
            windows.DispatchMessageW(&msg)
        }
                
        return true
    }

/*
Show Window
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_show :: proc(wnd : ^Window)
    {
        if wnd == nil do return
        windows.ShowWindow(wnd.hwnd, windows.SW_SHOW)
    }

/*
Hide Window
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_hide :: proc(wnd : ^Window)
    {
        if wnd == nil do return
        windows.ShowWindow(wnd.hwnd, windows.SW_HIDE)
    }

/*
Minimize Window
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_minimize :: proc(wnd : ^Window)
    {
        if wnd == nil do return
        windows.ShowWindow(wnd.hwnd, windows.SW_MINIMIZE)
    }

/*
Maximize Window
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_maximize :: proc(wnd : ^Window)
    {
        if wnd == nil do return
        windows.ShowWindow(wnd.hwnd, windows.SW_MAXIMIZE)
    }

/*
Gets Window Title
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_get_title :: proc(window : ^Window, allocator := context.allocator) -> (string, bool) #optional_ok
    {
        if log.verbose_fail_error(window == nil, "Window Argument is 'nil'") do return "", false

        length := windows.GetWindowTextLengthW(window.hwnd)
        if log.verbose_fail_info(length < 1, "Invalid Window Title Length") do return "", false

        title := make([]u8, length + 1, allocator)
        title_lpcwstr := cast([^]u16)&title[0]//TODO: use commons.slice_as_mult_ptr
        copy_count := windows.GetWindowTextW(window.hwnd, title_lpcwstr, i32(len(title)))

        success := copy_count == length
        if log.verbose_fail_error(!success, "Get Window Text")
        {
            delete(title, allocator)
            return "", false
        }

        return transmute(string)title, false
    }

/*
Sets Window Title
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_set_title :: proc(window : ^Window, title: string) -> bool
    {
        if log.verbose_fail_error(window == nil, "Window Argument is 'nil'") do return false

        title_cstr := strings.clone_to_cstring(title, context.temp_allocator)
        defer delete(title_cstr, context.temp_allocator)

        title_lpcwstr := transmute([^]u16)title_cstr
        success := bool(windows.SetWindowTextW(window.hwnd, title_lpcwstr))
        log.verbose_fail_error(!success, "Set Window Text")

        return success
    }

/*
Get Window X Position.
* Left to Right order.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_get_x :: proc(wnd : ^Window) -> i32
    {
        if wnd == nil do return -1
        
        long_bounds: windows.RECT
        windows.GetWindowRect(wnd.hwnd, &long_bounds)
        return long_bounds.left
    }

/*
Get Window Y Position.
* Top to Bottom order.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_get_y :: proc(wnd : ^Window) -> i32
    {
        if wnd == nil do return -1
        
        long_bounds: windows.RECT
        windows.GetWindowRect(wnd.hwnd, &long_bounds)
        return long_bounds.top
    }

/*
Set Window X Position.
* Left to Right order.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_set_x :: proc(wnd : ^Window, x : i32)
    {
        if wnd == nil do return
        bounds := ui_window_get_bounds(wnd)
        windows.SetWindowPos(wnd.hwnd, nil, x, bounds.top, 0, 0, windows.SWP_NOSIZE)
    }

/*
Set Window Y Position.
* Top to Bottom order.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_set_y :: proc(wnd : ^Window, y : i32)
    {
        if wnd == nil do return
        bounds := ui_window_get_bounds(wnd)
        windows.SetWindowPos(wnd.hwnd, nil, bounds.left, y, 0, 0, windows.SWP_NOSIZE)
    }

/*
Get Window Width
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_get_width :: proc(wnd : ^Window) -> i32
    {
        if wnd == nil do return -1
        
        bound: windows.RECT
        windows.GetClientRect(wnd.hwnd, &bound)
        return i32(bound.right - bound.left)
    }

/*
Get Window Height
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_get_height :: proc(wnd : ^Window) -> i32
    {
        if wnd == nil do return -1
        
        bound: windows.RECT
        windows.GetClientRect(wnd.hwnd, &bound)
        return i32(bound.bottom - bound.top)
    }
    
/*
Set Window Width
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_set_width :: proc(wnd : ^Window, width : i32)
    {
        if wnd == nil do return
        bounds := ui_window_get_bounds(wnd)
        windows.SetWindowPos(wnd.hwnd, nil, 0, 0, width, bounds.bottom - bounds.top, windows.SWP_NOMOVE)
    }

/*
Set Window Height
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_set_height :: proc(wnd : ^Window, height : i32)
    {
        if wnd == nil do return
        bounds := ui_window_get_bounds(wnd)
        windows.SetWindowPos(wnd.hwnd, nil, 0, 0, bounds.right - bounds.left, height, windows.SWP_NOMOVE)
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_get_client_bounds :: proc(wnd : ^Window) -> Rect_I32
    {
        bound: Rect_I32
        if wnd == nil do return bound
        
        long_bound: windows.RECT
        windows.GetClientRect(wnd.hwnd, &long_bound)
        bound.left = i32(long_bound.left)
        bound.top = i32(long_bound.top)
        bound.right = i32(long_bound.right)
        bound.bottom = i32(long_bound.bottom)
        return bound
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_get_bounds :: proc(wnd : ^Window) -> Rect_I32
    {
        bound: Rect_I32
        if wnd == nil do return bound
        
        long_bound: windows.RECT
        windows.GetWindowRect(wnd.hwnd, &long_bound)
        bound.left = i32(long_bound.left)
        bound.top = i32(long_bound.top)
        bound.right = i32(long_bound.right)
        bound.bottom = i32(long_bound.bottom)
        return bound
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    ui_window_set_bounds :: proc(wnd : ^Window, bounds: Rect_I32)
    {
        if wnd == nil do return
        windows.SetWindowPos(wnd.hwnd, nil, bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top, windows.SWP_SHOWWINDOW)
    }

    @(private)
    compose_wndclassexw :: #force_inline proc() -> windows.WNDCLASSEXW
    {
        wndclass: windows.WNDCLASSEXW
        wndclass.cbSize = size_of(windows.WNDCLASSEXW)
        wndclass.style = windows.CS_OWNDC
        wndclass.lpfnWndProc = window_procedure
        wndclass.hInstance = windows.HINSTANCE(windows.GetModuleHandleW(nil))
        wndclass.lpszClassName = windows.L(WINDOW_CLASS_NAME)
        return wndclass
    }

    @(private)
    window_event_to_windows_message :: #force_inline proc "contextless" (event: Window_Event) -> windows.UINT
    {
        return windows.WM_USER + windows.UINT(event)
    }

    @(private)
    windows_message_to_window_event :: #force_inline proc "contextless" (msg: windows.UINT) -> Window_Event
    {
        event_u32 := msg - windows.WM_USER

        MAJOR :: u32(max(Window_Event))
        if event_u32 == 0 || event_u32 > MAJOR do return .None

        return Window_Event(event_u32)
    }

    @(private)
    window_procedure :: proc "std" (hwnd : windows.HWND, msg : windows.UINT, wparam : windows.WPARAM, lparam : windows.LPARAM) -> windows.LRESULT
    {
        switch msg
        {
            case windows.WM_CREATE:
                message := window_event_to_windows_message(.Open)
                windows.PostMessageA(hwnd, message, 0, 0)

            case windows.WM_CLOSE:
                message := window_event_to_windows_message(.Close)
                windows.PostMessageA(hwnd, message, 0, 0)
                return 0
                
            case windows.WM_SETFOCUS:
                message := window_event_to_windows_message(.Focus)
                windows.PostMessageA(hwnd, message, 0, 0)

            case windows.WM_KILLFOCUS:
                message := window_event_to_windows_message(.Unfocus)
                windows.PostMessageA(hwnd, message, 0, 0)
                
            case windows.WM_SIZE:
                message := window_event_to_windows_message(.Resize)
                windows.PostMessageA(hwnd, message, 0, 0)
                
            case windows.WM_ENTERSIZEMOVE:
                message := window_event_to_windows_message(.Resize_Begin)
                windows.PostMessageA(hwnd, message, 0, 0)
                
            case windows.WM_EXITSIZEMOVE:
                message := window_event_to_windows_message(.Resize_End)
                windows.PostMessageA(hwnd, message, 0, 0)

            case windows.WM_KEYDOWN, windows.WM_SYSKEYDOWN:
                message := window_event_to_windows_message(.Key_Down)
                windows.PostMessageA(hwnd, message, 0, 0)
                
            case windows.WM_KEYUP, windows.WM_SYSKEYUP:
                message := window_event_to_windows_message(.Key_Up)
                windows.PostMessageA(hwnd, message, 0, 0)

        }

        return windows.DefWindowProcA(hwnd, msg, wparam, lparam)
    }
}