package input

Physical_Keyboard_Key :: enum
{
    //Others
    Escape,
    
    //Functions
    F1, F2,  F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,

    //Alphanumerics
    Alpha_0, Alpha_1, Alpha_2, Alpha_3, Alpha_4, Alpha_5, Alpha_6, Alpha_7, Alpha_8, Alpha_9,

    //Letters
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    
    //Specials
    Spacebar, Backspace, Return, Caps_Lock, Tab,

    //Left Typewriters
    Left_Alt, Left_System, Left_Control, Left_Shift,

    //Right Typewriters
    Right_Alt, Right_System, Right_Control, Right_Shift,

    //Cursors
    Arrow_Up, Arrow_Down, Arrow_Left, Arrow_Right,
}

keyboard_get_key :: proc{
    keyboard_get_key_physical,
}