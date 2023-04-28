package graphics_commons

when ODIN_OS == .Windows
{
    import "core:sys/windows"

    Window :: struct
    {
        common : Window_Common,
        hwnd : windows.HWND,
    }
}