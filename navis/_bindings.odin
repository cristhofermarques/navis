package navis

when BINDINGS
{
    import "pkg"
    import "core:runtime"
    import "core:thread"

    when ODIN_OS == .Windows do foreign import navis "navis.lib"
    when ODIN_OS == .Linux   do foreign import navis "navis.a"

    @(default_calling_convention="odin")
    foreign navis
    {
        /* Version */
        @(link_prefix=PREFIX)
        version :: proc "contextless" () -> Version ---

        /* Navis */
        @(link_prefix=PREFIX)
        run :: proc(module_paths, package_paths: []string, allocator := context.allocator) ---

        /* Renderer */
        @(link_prefix=PREFIX)
        renderer_refresh_uncached :: proc "contextless" (renderer: ^Renderer) ---

        @(link_prefix=PREFIX)
        renderer_require_shader :: proc(renderer: ^Renderer, streamer: ^pkg.Streamer, pool: ^thread.Pool, package_name, asset_name: string, idle_frames := 0) -> bool ---
        
        /* Shader */
        @(link_prefix=PREFIX)
        shader_create_from_asset :: proc(asset: ^Shader_Asset, allocator := context.allocator) -> (Shader, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        shader_create_from_descriptor :: proc(descriptor: ^Shader_Descriptor, allocator := context.allocator) -> (Shader, bool) #optional_ok ---

        @(link_prefix=PREFIX)
        shader_destroy :: proc(shader: ^Shader, allocator := context.allocator) ---

        /* Window */
        @(link_prefix=PREFIX)
        window_create_from_descriptor :: proc(descriptor: ^Window_Descriptor) -> (Window, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        window_destroy :: proc(window: ^Window) -> bool ---
        
        @(link_prefix=PREFIX)
        window_get_position :: proc(window: ^Window) -> ([2]i32, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        window_get_size :: proc(window: ^Window) -> ([2]i32, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        window_get_key :: proc(window: ^Window, key: Keyboard_Keys) -> Keyboard_Key_State ---
        
        /* Streamer */
        @(link_prefix=PREFIX)       
        streamer_require_asset_uncached :: proc(application: ^Application, asset_name: string, on_loaded: pkg.Proc_On_Asset_Loaded = nil, user_data : rawptr = nil, idle_frames := 0) -> bool ---

        @(link_prefix=PREFIX)
        streamer_dispose_asset_uncached :: proc(application: ^Application, asset_name: string, idle_frames := 0) -> bool ---
    }
}