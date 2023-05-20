package vulkan

import "vk"
import "navis:commons"

/*
Vulkan pipeline.
*/
Pipeline :: struct
{
    handle: vk.Pipeline,
}

/*
Descriptor to compose a shader state create info.
*/
Shader_State_Descriptor :: struct
{
    flags: vk.PipelineShaderStageCreateFlags,
    stage: vk.ShaderStageFlags,
    module: vk.ShaderModule,
    name: cstring,
    specialization: ^vk.SpecializationInfo,
}

/*
Compose a shader state create info.
*/
pipeline_compose_shader_state :: #force_inline proc(desc: ^Shader_State_Descriptor) -> vk.PipelineShaderStageCreateInfo
{
    stage: vk.PipelineShaderStageCreateInfo
    stage.sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
    stage.flags = desc.flags
    stage.stage = desc.stage
    stage.module = desc.module
    stage.pName = desc.name
    stage.pSpecializationInfo = desc.specialization
    return stage
}

/*
Compose a dynamic state create info.
*/
pipeline_compose_dynamic_state :: #force_inline proc(states: []vk.DynamicState) -> vk.PipelineDynamicStateCreateInfo
{
    state: vk.PipelineDynamicStateCreateInfo
    state.sType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO
    state.pDynamicStates = commons.array_try_as_pointer(states)
    state.dynamicStateCount = cast(u32)commons.array_try_len(states)
    return state
}

/*
Descriptor to compose a vertex input state create info.
*/
Vertex_Input_State_Descriptor :: struct
{
    bindings: []vk.VertexInputBindingDescription,
    attributes: []vk.VertexInputAttributeDescription,
}

/*
Compose a vertex input state create info.
*/
pipeline_compose_vertex_input_state :: #force_inline proc(desc: ^Vertex_Input_State_Descriptor) -> vk.PipelineVertexInputStateCreateInfo
{
    state: vk.PipelineVertexInputStateCreateInfo
    state.sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO
    state.pVertexBindingDescriptions = commons.array_try_as_pointer(desc.bindings)
    state.vertexBindingDescriptionCount = cast(u32)commons.array_try_len(desc.bindings)
    state.pVertexAttributeDescriptions = commons.array_try_as_pointer(desc.attributes)
    state.vertexAttributeDescriptionCount = cast(u32)commons.array_try_len(desc.attributes)
    return state
}

/*
Descriptor to compose a input assembly state create info.
*/
Input_Assembly_State_Descriptor :: struct
{
    topology: vk.PrimitiveTopology,
    restart_enabled: bool,
}

/*
Compose a input assembly state create info.
*/
pipeline_compose_input_assembly_state :: #force_inline proc(desc: ^Input_Assembly_State_Descriptor) -> vk.PipelineInputAssemblyStateCreateInfo
{
    state: vk.PipelineInputAssemblyStateCreateInfo
    state.sType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO
    state.topology = desc.topology
    state.primitiveRestartEnable = cast(b32)desc.restart_enabled
    return state
}

/*
Descriptor to compose a viewport state create info.
*/
Viewport_State_Descriptor :: struct
{
    viewports: []vk.Viewport,
    scissors: []vk.Rect2D,
}

/*
Compose a viewport state create info.
*/
pipeline_compose_viewport_state :: #force_inline proc(desc: ^Viewport_State_Descriptor) -> vk.PipelineViewportStateCreateInfo
{
    state: vk.PipelineViewportStateCreateInfo
    state.sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO
    state.pViewports = commons.array_try_as_pointer(desc.viewports)
    state.viewportCount = cast(u32)commons.array_try_len(desc.viewports)
    state.pScissors = commons.array_try_as_pointer(desc.scissors)
    state.scissorCount = cast(u32)commons.array_try_len(desc.scissors)
    return state
}

/*
Descriptor to compose a rasterization state create info.
*/
Raterization_State_Descriptor :: struct
{
    depth_clamp, rasterizer_discard: bool,
    polygon_mode: vk.PolygonMode,
    line_width: f32,
    cull_mode: vk.CullModeFlags,
    front_face: vk.FrontFace,
    depth_bias: bool,
    depth_bias_const_factor, depth_bias_clamp, depth_bias_slope_factor: f32,
}

/*
Compose a rasterization state create info.
*/
pipeline_compose_rasterization_state :: #force_inline proc(desc: ^Raterization_State_Descriptor) -> vk.PipelineRasterizationStateCreateInfo
{
    state: vk.PipelineRasterizationStateCreateInfo
    state.sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO
    state.depthClampEnable = cast(b32)desc.depth_clamp
    state.rasterizerDiscardEnable = cast(b32)desc.rasterizer_discard
    state.polygonMode = desc.polygon_mode
    state.lineWidth = desc.line_width
    state.cullMode = desc.cull_mode
    state.frontFace = desc.front_face
    state.depthBiasEnable = cast(b32)desc.depth_bias
    state.depthBiasConstantFactor = desc.depth_bias_const_factor
    state.depthBiasClamp = desc.depth_bias_clamp
    state.depthBiasSlopeFactor = desc.depth_bias_slope_factor
    return state
}

/*
Descriptor to compose a multisample state create info.
*/
Multisample_State_Descriptor :: struct
{
    sample_shading: bool,
    rasterization_samples: vk.SampleCountFlags,
    min_sample_shading: f32,
    mask: ^vk.SampleMask,
    alpha_to_coverage, alpha_to_one: bool,
}

/*
Compose a multisample state create info.
*/
pipeline_compose_multisample_state :: #force_inline proc(desc: ^Multisample_State_Descriptor) -> vk.PipelineMultisampleStateCreateInfo
{
    state: vk.PipelineMultisampleStateCreateInfo
    state.sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO
    state.sampleShadingEnable = cast(b32)desc.sample_shading
    state.rasterizationSamples = desc.rasterization_samples
    state.minSampleShading = desc.min_sample_shading
    state.pSampleMask = desc.mask
    state.alphaToCoverageEnable = cast(b32)desc.alpha_to_coverage
    state.alphaToOneEnable = cast(b32)desc.alpha_to_one
    return state
}

/*
Descriptor to compose a depth stencil state create info.
*/
Depth_Stencil_State_Descriptor :: struct
{
    flags: vk.PipelineDepthStencilStateCreateFlags,
    depth_test, depth_write: bool,
    depth_compare_op: vk.CompareOp,
    depth_bounds_test, stencil_test: bool,
    front, back: vk.StencilOpState,
    min_depth_bounds, max_depth_bounds: f32,
}

/*
Compose a depth stencil state create info.
*/
pipeline_compose_depth_stencil_state :: #force_inline proc(desc: ^Depth_Stencil_State_Descriptor) -> vk.PipelineDepthStencilStateCreateInfo
{
    state: vk.PipelineDepthStencilStateCreateInfo
    state.sType = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO
    state.flags = desc.flags
    state.depthTestEnable = cast(b32)desc.depth_test
    state.depthWriteEnable = cast(b32)desc.depth_write
    state.depthCompareOp = desc.depth_compare_op
    state.depthBoundsTestEnable = cast(b32)desc.depth_bounds_test
    state.front = desc.front
    state.back = desc.back
    state.minDepthBounds = desc.min_depth_bounds
    state.maxDepthBounds = desc.max_depth_bounds
    return state
}

/*
Descriptor to compose a color blend state create info.
*/
Color_Blend_State_Descriptor :: struct
{
    flags: vk.PipelineColorBlendStateCreateFlags,
    logic_op_enabled: bool,
    logic_op: vk.LogicOp,
    attachments: []vk.PipelineColorBlendAttachmentState,
    blend_constants: [4]f32,
}

/*
Compose a color blend state create info.
*/
pipeline_compose_color_blend_state :: #force_inline proc(desc: ^Color_Blend_State_Descriptor) -> vk.PipelineColorBlendStateCreateInfo
{
    state: vk.PipelineColorBlendStateCreateInfo
    state.sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO
    state.flags = desc.flags
    state.logicOpEnable = cast(b32)desc.logic_op_enabled
    state.logicOp = desc.logic_op
    state.pAttachments = commons.array_try_as_pointer(desc.attachments)
    state.attachmentCount = cast(u32)commons.array_try_len(desc.attachments)
    state.blendConstants = desc.blend_constants
    return state
}

/*
Descriptor to compose a layout state create info.
*/
Layout_State_Descriptor :: struct
{
    layouts: []vk.DescriptorSetLayout,
    push_constant_ranges: []vk.PushConstantRange,
}

/*
Compose a layout state create info.
*/
pipeline_compose_layout_state :: #force_inline proc(desc: ^Layout_State_Descriptor) -> vk.PipelineLayoutCreateInfo
{
    state: vk.PipelineLayoutCreateInfo
    state.sType = .PIPELINE_LAYOUT_CREATE_INFO
    state.pSetLayouts = commons.array_try_as_pointer(desc.layouts)
    state.setLayoutCount = cast(u32)commons.array_try_len(desc.layouts)
    state.pPushConstantRanges = commons.array_try_as_pointer(desc.push_constant_ranges)
    state.pushConstantRangeCount = cast(u32)commons.array_try_len(desc.push_constant_ranges)
    return state
}