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

        /* Renderer */
        @(link_prefix=PREFIX)
        renderer_refresh_uncached :: proc "contextless" (renderer: ^Renderer) ---
        
        /* Shader */
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
        window_get_position :: proc(window: ^Window) -> (Vector2_I32, bool) #optional_ok ---
        
        @(link_prefix=PREFIX)
        window_get_size :: proc(window: ^Window) -> (Vector2_I32, bool) #optional_ok ---
    }
}