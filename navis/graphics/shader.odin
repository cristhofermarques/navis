package graphics

import "navis:api"

when api.EXPORT
{
    import "bgfx"
    import "navis:commons"
    import "navis:commons/log"

    shader_module_create_from_memory :: proc(memory: ^bgfx.Memory) -> (Shader_Module, bool) #optional_ok
    {
        if memory == nil
        {
            //TODO: log error here
            return bgfx.INVALID_HANDLE, false
        }

        handle := bgfx.create_shader(memory)
        if !bgfx.handle_is_valid(handle)
        {
            //TODO: log error here
            return bgfx.INVALID_HANDLE, false
        }

        return handle, true
    }

    shader_module_create_from_data :: proc(data: rawptr, size: u32) -> (Shader_Module, bool) #optional_ok
    {
        memory := bgfx.make_ref(data, size)
        if memory == nil
        {
            //TODO: log error
            return bgfx.INVALID_HANDLE, false
        }

        return shader_module_create_from_memory(memory)
    }

    shader_module_get_uniforms :: proc(module: Shader_Module, allocator := context.allocator) -> ([]bgfx.Uniform_Handle, bool) #optional_ok
    {
        if !bgfx.handle_is_valid(module)
        {
            log.verbose_error("Invalid shader module handle", module)
            return nil, false
        }

        dummy_uniform: bgfx.Uniform_Handle
        uniforms_count := bgfx.get_shader_uniforms(module, &dummy_uniform, 1)
        if uniforms_count < 1
        {
            log.verbose_error("Failed to get uniforms count, shader module handle", module, "have", uniforms_count, "uniforms")
            return nil, false
        }

        uniforms, uniforms_alloc_err := make([]bgfx.Uniform_Handle, uniforms_count, allocator)
        if uniforms_alloc_err != .None
        {
            //TODO: log error here
            return nil, false
        }

        uniforms_query_count := bgfx.get_shader_uniforms(module, &uniforms[0], uniforms_count)
        if uniforms_query_count != uniforms_count
        {
            //TODO: log error here
            delete(uniforms, allocator)
            return nil, false
        }

        //Success
        return uniforms, true
    }

    shader_create_from_modules :: proc(vertex, fragment: Shader_Module, destroy_modules := false, allocator := context.allocator) -> (Shader, bool) #optional_ok
    {
        if !bgfx.handle_is_valid(vertex)
        {
            log.verbose_error("Invalid vertex shader module", vertex)
            return {}, false
        }
        
        if !bgfx.handle_is_valid(fragment)
        {
            log.verbose_error("Invalid fragment shader module", fragment)
            return {}, false
        }
        
        vertex_uniforms, got_vertex_uniforms := shader_module_get_uniforms(vertex, context.temp_allocator)
        if !got_vertex_uniforms
        {
            log.verbose_warn("Failed to get vertex shader module uniforms, handle", vertex)
        }
        defer if !got_vertex_uniforms do delete(vertex_uniforms, context.temp_allocator)
        
        fragment_uniforms, got_fragments_uniforms := shader_module_get_uniforms(fragment, context.temp_allocator)
        if !got_vertex_uniforms
        {
            log.verbose_warn("Failed to get fragment shader module uniforms, handle", fragment)
        }
        defer if !got_vertex_uniforms do delete(fragment_uniforms, context.temp_allocator)
        
        uniforms, joined_uniforms := shader_join_uniform_arrays(arrays = {vertex_uniforms, fragment_uniforms}, allocator = allocator)
        if !joined_uniforms
        {
            log.verbose_error("Failed to join shader module uniforms", fragment)
            return {}, false
        }
        
        //Creating program
        program := bgfx.create_program(vertex, fragment, cast(b8)destroy_modules)
        if !bgfx.handle_is_valid(program)
        {
            log.verbose_error("Failed to create shader", fragment)
            return {}, false
        }

        shader: Shader
        shader.program = program
        shader.uniforms = uniforms

        return shader, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    shader_create_from_descriptor :: proc(descriptor: ^Shader_Descriptor, allocator := context.allocator) -> (Shader, bool) #optional_ok
    {
        if descriptor == nil
        {
            return {}, false
        }
        
        vertex_module, created_vertex_module := shader_module_create_from_data(descriptor.vertex.data, descriptor.vertex.size)
        if !created_vertex_module
        {
            return {}, false
        }

        fragment_module, created_fragment_module := shader_module_create_from_data(descriptor.fragment.data, descriptor.fragment.size)
        if !created_fragment_module
        {
            return {}, false
        }

        return shader_create_from_modules(vertex_module, fragment_module, true, allocator)
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    shader_destroy :: proc(shader: ^Shader, allocator := context.allocator)
    {
        if shader == nil || !bgfx.handle_is_valid(shader.program)
        {
            return
        }

        bgfx.destroy_program(shader.program)
        shader.program = bgfx.INVALID_HANDLE

        if !commons.slice_is_nil_or_empty(shader.uniforms)
        {
            delete(shader.uniforms, allocator)
            shader.uniforms = nil
        }
    }

    shader_join_uniform_arrays :: proc(arrays: ..[]bgfx.Uniform_Handle, allocator := context.allocator) -> ([]bgfx.Uniform_Handle, bool)
    {
        total_uniforms: int
        for uniforms in arrays
        {
            if uniforms != nil do total_uniforms += len(uniforms)
        }

        if total_uniforms < 1
        {
            return nil, true
        }

        join, join_alloc_err := make([dynamic]bgfx.Uniform_Handle, 0, total_uniforms, context.temp_allocator)
        if join_alloc_err != .None
        {
            return nil, false
        }

        defer delete(join)

        for uniforms in arrays
        {
            if uniforms == nil do continue

            for uniform in uniforms
            {
                if commons.array_contains(join, uniform) do continue
                append(&join, uniform)
            }
        }

        return commons.slice_from_dynamic(join, allocator)
    }
}