package input

// import "navis:api"

// when api.EXPORT_WINDOWS
// {
//     import "core:sys/windows"

//     @(private)
//     physical_keyboard_key_to_windows_key :: proc(key: Physical_Keyboard_Key) -> (windows.INT, bool) #optional_ok
//     {
//         using windows

//         switch key
//         {
//             case .A: return VK_A, true
//             case .B: return VK_B, true
//             case .C: return VK_C, true
//             case .D: return VK_D, true
//             case .E: return VK_E, true
//             case .F: return VK_F, true
//             case .G: return VK_G, true
//             case .H: return VK_H, true
//             case .I: return VK_I, true
//             case .J: return VK_J, true
//             case .K: return VK_K, true
//             case .L: return VK_L, true
//             case .M: return VK_M, true
//             case .N: return VK_N, true
//             case .O: return VK_O, true
//             case .P: return VK_P, true
//             case .Q: return VK_Q, true
//             case .R: return VK_R, true
//             case .S: return VK_S, true
//             case .T: return VK_T, true
//             case .U: return VK_U, true
//             case .V: return VK_V, true
//             case .W: return VK_W, true
//             case .X: return VK_X, true
//             case .Y: return VK_Y, true
//             case .Z: return VK_Z, true

//             case .Spacebar: return VK_SPACE, true
//             case .Backspace: return VK_BACK, true
//             case .Return: return VK_RETURN, true
//             case .Caps_Lock: return VK_CAPITAL, true
//             case .Tab: return VK_TAB, true
//             case .Escape: return VK_ESCAPE, true

//             case .Alpha_0: return VK_0, true
//             case .Alpha_1: return VK_1, true
//             case .Alpha_2: return VK_2, true
//             case .Alpha_3: return VK_3, true
//             case .Alpha_4: return VK_4, true
//             case .Alpha_5: return VK_5, true
//             case .Alpha_6: return VK_6, true
//             case .Alpha_7: return VK_7, true
//             case .Alpha_8: return VK_8, true
//             case .Alpha_9: return VK_9, true

//             case .F1: return VK_F1, true
//             case .F2: return VK_F2, true
//             case .F3: return VK_F3, true
//             case .F4: return VK_F4, true
//             case .F5: return VK_F5, true
//             case .F6: return VK_F6, true
//             case .F7: return VK_F7, true
//             case .F8: return VK_F8, true
//             case .F9: return VK_F9, true
//             case .F10: return VK_F10, true
//             case .F11: return VK_F11, true
//             case .F12: return VK_F12, true

//             case .Left_Alt: return VK_LMENU, true
//             case .Left_System: return VK_LWIN, true
//             case .Left_Control: return VK_LCONTROL, true
//             case .Left_Shift: return VK_LSHIFT, true

//             case .Right_Alt: return VK_RMENU, true
//             case .Right_System: return VK_RWIN, true
//             case .Right_Control: return VK_RCONTROL, true
//             case .Right_Shift: return VK_RSHIFT, true

//             case .Arrow_Up: return VK_UP, true
//             case .Arrow_Down: return VK_DOWN, true
//             case .Arrow_Left: return VK_LEFT, true
//             case .Arrow_Right: return VK_RIGHT, true
//         }

//         return 0, false
//     }

//     @(export=api.SHARED, link_prefix=PREFIX)
//     keyboard_get_key_physical :: proc(key: Physical_Keyboard_Key) -> bool
//     {
//         Keyboard_Key_States :: enum
//         {
//             _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14,
//             Capital_Toogle,
//             Trigger,
//         }
    
//         Keyboard_Key_State :: bit_set[Keyboard_Key_States]

//         win_vk, win_vk_succ := physical_keyboard_key_to_windows_key(key)
//         if !win_vk_succ do return false

//         win_vk_state := transmute(Keyboard_Key_State)windows.GetKeyState(win_vk)

//         triggered := Keyboard_Key_States.Trigger in win_vk_state
//         return triggered
//     }
// }