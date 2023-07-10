package input

// import "navis:api"

// when api.BINDINGS
// { 
//     when ODIN_OS == .Windows do foreign import navis "binaries:navis.lib"
//     when ODIN_OS == .Linux   do foreign import navis "binaries:navis.a"

//     @(default_calling_convention = "odin")
//     foreign navis
//     {
//         /* Keyboard */
//         @(link_prefix=PREFIX)
//         keyboard_get_key_physical :: proc(key: Physical_Keyboard_Key) -> bool ---
        
//         /* Text */
//         @(link_prefix=PREFIX)
//         text_capture :: proc(key: Physical_Keyboard_Key) ---
//     }
// }