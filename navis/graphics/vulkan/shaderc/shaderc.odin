package shaderc

Source_Language :: enum
{
    GLSL,
    HLSL,
}

Shader_Kind :: enum
{
    GLSL_Vertex,
    GLSL_Fragment,
    GLSL_Compute,
    GLSL_Geometry,
    GLSL_Tess_Control,
    GLSL_Tess_Evaluation,
    GLSL_Infer,
    GLSL_Default_Vertex,
    GLSL_Default_Fragment,
    GLSL_Default_Compute,
    GLSL_Default_Geometry,
    GLSL_Default_Tess_Control,
    GLSL_Default_Tess_Evaluation,
    Spirv_Assembly,
    GLSL_Ray_Gen,
    GLSL_Any_Hit,
    GLSL_Closest_Hit,
    GLSL_Miss_Shader,
    GLSL_Intersection,
    GLSL_Callable,
    GLSL_Default_Ray_Gen,
    GLSL_Default_Any_Hit,
    GLSL_Default_Closest_Hit,
    GLSL_Default_Miss_Shader,
    GLSL_Default_Intersection,
    GLSL_Default_Callable,
    GLSL_Task,
    GLSL_Mesh,
    GLSL_Default_Task,
    GLSL_Default_Mesh,
}

Profile :: enum
{
    None,
    Core,
    Compatibility,
    ES,
}

// Optimization level.
Optimization_Level :: enum
{
    Zero,
    Size,
    Performance,
}

// Resource limits.
Limit :: enum
{
    Max_Lights,
    Max_Clip_Planes,
    Max_Texture_Units,
    Max_Texture_Coords,
    Max_Vertex_Attribs,
    Max_Vertex_Uniform_Components,
    Max_Varying_Floats,
    Max_Vertex_Texture_Image_Units,
    Max_Combined_Texture_Image_Units,
    Max_Texture_Image_Units,
    Max_Fragment_Uniform_Components,
    Max_Draw_Buffers,
    Max_Vertex_Uniform_Vectors,
    Max_Varying_Vectors,
    Max_Fragment_Uniform_Vectors,
    Max_Vertex_Output_Vectors,
    Max_Fragment_Input_Vectors,
    Min_Program_Texel_Offset,
    Max_Program_Texel_Offset,
    Max_Clip_Distances,
    Max_Compute_Work_Group_Count_X,
    Max_Compute_Work_Group_Count_Y,
    Max_Compute_Work_Group_Count_Z,
    Max_Compute_Work_Group_Size_X,
    Max_Compute_Work_Group_Size_Y,
    Max_Compute_Work_Group_Size_Z,
    Max_Compute_Uniform_Components,
    Max_Compute_Texture_Image_Units,
    Max_Compute_Image_Uniforms,
    Max_Compute_Atomic_Counters,
    Max_Compute_Atomic_Counter_Buffers,
    Max_Varying_Components,
    Max_Vertex_Output_Components,
    Max_Geometry_Input_Components,
    Max_Geometry_Output_Components,
    Max_Fragment_Input_Components,
    Max_Image_Units,
    Max_Combined_Image_Units_And_Fragment_Outputs,
    Max_Combined_Shader_Output_Resources,
    Max_Image_Samples,
    Max_Vertex_Image_Uniforms,
    Max_Tess_Control_Image_Uniforms,
    Max_Tess_Evaluation_Image_Uniforms,
    Max_Geometry_Image_Uniforms,
    Max_Fragment_Image_Uniforms,
    Max_Gombined_Image_Uniforms,
    Max_Geometry_Texture_Image_Units,
    Max_Geometry_Output_Vertices,
    Max_Geometry_Total_Output_Components,
    Max_Geometry_Uniform_Components,
    Max_Geometry_Varying_Components,
    Max_Tess_Control_Input_Components,
    Max_Tess_Control_Output_Components,
    Max_Tess_Control_Texture_Image_Units,
    Max_Tess_Control_Uniform_Components,
    Max_Tess_Control_Total_Output_Components,
    Max_Tess_Evaluation_Input_Components,
    Max_Tess_Evaluation_Output_Components,
    Max_Tess_Evaluation_Texture_Image_Units,
    Max_Tess_Evaluation_Uniform_Components,
    Max_Tess_Patch_Components,
    Max_Patch_Vertices,
    Max_Tess_Gen_Level,
    Max_Viewports,
    Max_Vertex_Atomic_Counters,
    Max_Tess_Control_Atomic_Counters,
    Max_Tess_Evaluation_Atomic_Counters,
    Max_Geometry_Atomic_Counters,
    Max_Fragment_Atomic_Counters,
    Max_Combined_Atomic_Counters,
    Max_Atomic_Counter_Bindings,
    Max_Vertex_Atomic_Counter_Buffers,
    Max_Tess_Control_Atomic_Counter_Buffers,
    Max_Tess_Evaluation_Atomic_Counter_Buffers,
    Max_Geometry_Atomic_Counter_Buffers,
    Max_Fragment_Atomic_Counter_Buffers,
    Max_Combined_Atomic_Counter_Buffers,
    Max_Atomic_Counter_Buffer_Size,
    Max_Transform_Feedback_Buffers,
    Max_Transform_Feedback_Interleaved_Components,
    Max_Cull_Distances,
    Max_Combined_Clip_And_Cull_Distances,
    Max_Samples,
}

Uniform_Kind :: enum
{
    Image,
    Sampler,
    Texture,
    Buffer,
    Storage_Buffer,
    Unordered_Access_View,
}

Compiler :: distinct rawptr

foreign import shaderc "binaries:shaderc_combined.lib"

foreign shaderc
{
    @(link_name="shaderc_compiler_initialize")
    compiler_initialize :: proc "c" () -> Compiler ---

    @(link_name="shaderc_compiler_release")
    compiler_release :: proc "c" (compiler: Compiler) ---
}

Compile_Options :: distinct rawptr

foreign shaderc
{
    @(link_name="shaderc_compile_options_initialize")
    compile_options_initialize :: proc "c" () -> Compile_Options ---

    @(link_name="shaderc_compile_options_clone")
    compile_options_clone:: proc "c" (options: Compile_Options) -> Compile_Options ---
    
    @(link_name="shaderc_compile_options_release")
    compile_options_release :: proc "c" (options: Compile_Options) ---
    
    @(link_name="shaderc_compile_options_add_macro_definition")
    compile_options_add_macro_definition :: proc "c" (options: Compile_Options, name: cstring, name_length: u64, value: rawptr, value_length: u64) ---
    
    @(link_name="shaderc_compile_options_set_source_language")
    compile_options_set_source_language :: proc "c" (options: Compile_Options, lang: Source_Language) ---
    
    @(link_name="shaderc_compile_options_set_generate_debug_info")
    compile_options_set_generate_debug_info :: proc "c" (options: Compile_Options) ---
    
    @(link_name="shaderc_compile_options_set_optimization_level")
    compile_options_set_optimization_level :: proc "c" (options: Compile_Options, level: Optimization_Level) ---
    
    @(link_name="shaderc_compile_options_set_forced_version_profile")
    compile_options_set_forced_version_profile :: proc "c" (options: Compile_Options, version: i32, profile: Profile) ---
}

Include_Result :: struct
{
    source_name: cstring,
    source_name_length: u64,
    content: cstring,
    content_length: u64,
    user_data: rawptr,
}

Include_Type :: enum
{
    Relative,
    Standard,
}

Proc_Include_Resolve :: #type proc "c" (user_data: rawptr, requested_source: cstring, type_: i32, requesting_source: cstring, include_depth: u64) -> ^Include_Result
Proc_Include_Result_Release :: #type proc "c" (user_data: rawptr, include_result: ^Include_Result)

foreign shaderc
{
    @(link_name="shaderc_compile_options_set_include_callbacks")
    compile_options_set_include_callbacks :: proc "c" (options: Compile_Options, resolver: Proc_Include_Resolve, result_releaser: Proc_Include_Result_Release, user_data: rawptr) ---
    
    @(link_name="shaderc_compile_options_set_suppress_warnings")
    compile_options_set_suppress_warnings :: proc "c" (options: Compile_Options) ---
    
    @(link_name="shaderc_compile_options_set_target_env")
    compile_options_set_target_env :: proc "c" (options: Compile_Options, target: Target_Env, version: u32) ---
    
    @(link_name="shaderc_compile_options_set_target_spirv")
    compile_options_set_target_spirv :: proc "c" (options: Compile_Options, version: SPIRV_Version) ---
    
    @(link_name="shaderc_compile_options_set_warnings_as_errors")
    compile_options_set_warnings_as_errors :: proc "c" (options: Compile_Options) ---
    
    @(link_name="shaderc_compile_options_set_limit")
    compile_options_set_limit :: proc "c" (options: Compile_Options, limit: Limit, value: i32) ---
    
    @(link_name="shaderc_compile_options_set_auto_bind_uniforms")
    compile_options_set_auto_bind_uniforms :: proc "c" (options: Compile_Options, auto_bind: bool) ---
    
    @(link_name="shaderc_compile_options_set_auto_combined_image_sampler")
    compile_options_set_auto_combined_image_sampler :: proc "c" (options: Compile_Options, upgrade: bool) ---
    
    @(link_name="shaderc_compile_options_set_hlsl_io_mapping")
    compile_options_set_hlsl_io_mapping :: proc "c" (options: Compile_Options, hlsl_iomap: bool) ---
    
    @(link_name="shaderc_compile_options_set_hlsl_offsets")
    compile_options_set_hlsl_offsets :: proc "c" (options: Compile_Options, hlsl_offsets: bool) ---
    
    @(link_name="shaderc_compile_options_set_binding_base")
    compile_options_set_binding_base :: proc "c" (options: Compile_Options, kind: Uniform_Kind, base: u32) ---
    
    @(link_name="shaderc_compile_options_set_binding_base_for_stage")
    compile_options_set_binding_base_for_stage :: proc "c" (options: Compile_Options, shader_kind: Shader_Kind, kind: Uniform_Kind, base: u32) ---
    
    @(link_name="shaderc_compile_options_set_auto_map_locations")
    compile_options_set_auto_map_locations :: proc "c" (options: Compile_Options, auto_map: bool) ---
    
    @(link_name="shaderc_compile_options_set_hlsl_register_set_and_binding_for_stage")
    compile_options_set_hlsl_register_set_and_binding_for_stage :: proc "c" (options: Compile_Options, shader_kind: Shader_Kind, reg, set_, binding: cstring) ---
    
    @(link_name="shaderc_compile_options_set_hlsl_register_set_and_binding")
    compile_options_set_hlsl_register_set_and_binding :: proc "c" (options: Compile_Options, reg, set_, binding: cstring) ---
    
    @(link_name="shaderc_compile_options_set_hlsl_functionality1")
    compile_options_set_hlsl_functionality1 :: proc "c" (options: Compile_Options, enable: bool) ---
    
    @(link_name="shaderc_compile_options_set_hlsl_16bit_types")
    compile_options_set_hlsl_16bit_types :: proc "c" (options: Compile_Options, enable: bool) ---
    
    @(link_name="shaderc_compile_options_set_invert_y")
    compile_options_set_invert_y :: proc "c" (options: Compile_Options, enable: bool) ---
    
    @(link_name="shaderc_compile_options_set_nan_clamp")
    compile_options_set_nan_clamp :: proc "c" (options: Compile_Options, enable: bool) ---
}

Compilation_Result :: distinct rawptr

foreign shaderc
{
    @(link_name="shaderc_compile_into_spv")
    compile_into_spv :: proc "c" (compiler: Compiler, source_text: cstring, source_text_size: u64, shader_kind: Shader_Kind, input_file_name, entry_point_name: cstring, addtional_options: Compile_Options) -> Compilation_Result ---
    
    @(link_name="shaderc_compile_into_spv_assembly")
    compile_into_spv_assembly :: proc "c" (compiler: Compiler, source_text: cstring, source_text_size: u64, shader_kind: Shader_Kind, input_file_name, entry_point_name: cstring, addtional_options: Compile_Options) -> Compilation_Result ---
    
    @(link_name="shaderc_compile_into_preprocessed_text")
    compile_into_preprocessed_text :: proc "c" (compiler: Compiler, source_text: cstring, source_text_size: u64, shader_kind: Shader_Kind, input_file_name, entry_point_name: cstring, addtional_options: Compile_Options) -> Compilation_Result ---
    
    @(link_name="shaderc_assemble_into_spv")
    assemble_into_spv :: proc "c" (compiler: Compiler, source_assembly: cstring, source_assembly_size: u64, addtional_options: Compile_Options) -> Compilation_Result ---
    
    @(link_name="shaderc_result_release")
    result_release :: proc "c" (result: Compilation_Result) ---
    
    @(link_name="shaderc_result_get_length")
    result_get_length :: proc "c" (result: Compilation_Result) -> u64 ---
    
    @(link_name="shaderc_result_get_num_warnings")
    result_get_num_warnings :: proc "c" (result: Compilation_Result) -> u64 ---
    
    @(link_name="shaderc_result_get_num_errors")
    result_get_num_errors :: proc "c" (result: Compilation_Result) -> u64 ---
    
    @(link_name="shaderc_result_get_compilation_status")
    result_get_compilation_status :: proc "c" (result: Compilation_Result) -> Compilation_Status  ---
    
    @(link_name="shaderc_result_get_bytes")
    result_get_bytes :: proc "c" (result: Compilation_Result) -> cstring ---
    
    @(link_name="shaderc_result_get_error_message")
    result_get_error_message :: proc "c" (result: Compilation_Result) -> cstring ---
    
    @(link_name="shaderc_get_spv_version")
    get_spv_version :: proc "c" (version, revision: ^u32) ---
    
    @(link_name="shaderc_parse_version_profile")
    parse_version_profile :: proc "c" (str: cstring, version: ^i32, profile: ^Profile) -> bool ---
}