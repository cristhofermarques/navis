package navis

when BINDINGS
{
    import "core:runtime"

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
        run_from_paths :: proc(paths: ..string, allocator := context.allocator) ---
        
        @(link_prefix=PREFIX)
        exit_uncached :: proc(application: ^Application) ---
        
        // @(link_prefix=PREFIX)
        // ecs_register_component_from_module :: proc(ecs: ^ECS, module: ^Module, id: typeid) ---

        /* Renderer */
        @(link_prefix=PREFIX)
        renderer_refresh_uncached :: proc "contextless" (renderer: ^Renderer) ---
        
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
        package_create_from_path :: proc(path: string, allocator := context.allocator) -> (Package, bool) ---

        @(link_prefix=PREFIX)
        package_read_asset :: proc(pkg: ^Package, path: string, allocator := context.allocator) -> []byte ---

        @(link_prefix=PREFIX)
        package_delete :: proc(pkg: ^Package, allocator := context.allocator) ---
        
        @(link_prefix=PREFIX)
        streamer_create :: proc(paths: []string, references: []Package_Reference = nil, allocator := context.allocator) -> (Streamer, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        streamer_destroy :: proc(streamer: ^Streamer, allocator := context.allocator) ---
    }
}