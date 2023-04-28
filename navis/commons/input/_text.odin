package input

import "navis:api"

when api.EXPORT_WINDOWS
{
    import "core:sys/windows"
    import "core:fmt"

    foreign import user32 "system:User32.lib"

    foreign user32
    {
        ToUnicode :: proc "c" (
            wVirtKey: windows.UINT,
            wScanCode: windows.UINT,
            lpKeyState: rawptr,
            pwszBuff: rawptr,
            cchBuff: i32,
            wFlags: windows.UINT,
        ) -> i32 ---
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    text_capture :: proc(key: Physical_Keyboard_Key)
    {
        Keyboard_State :: [256]windows.BYTE

        win_key, win_key_succ := physical_keyboard_key_to_windows_key(key)
        if !win_key_succ do return

        keyboard_state: Keyboard_State
        windows.GetKeyboardState(&keyboard_state[0])

        win_key_state := windows.GetKeyState(win_key)

        scan_code := windows.MapVirtualKeyW(u32(win_key), windows.MAPVK_VK_TO_VSC)

        buffer: [5]windows.WCHAR
        res :=  ToUnicode(u32(win_key), scan_code, &keyboard_state[0], &buffer[0], 5, 0)
        if res < 1 do return

        fmt.println(buffer)
    }
}