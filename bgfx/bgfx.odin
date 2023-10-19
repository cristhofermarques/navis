package bgfx

Handle :: u16
INVALID_HANDLE :: max(Handle)

Color_ABGR :: struct {a, b, g, r: u8}
Color_Code :: u8

Color_Codes :: enum u8
{
	Transparent,
	Dark_Blue,
	Dark_Green,
	_3,
	_4,
	_5,
	_6,
	_7,
	_8,
	_9,
	A,
	B,
	C,
	D,
	E,
	White,
}

color_code :: proc "contextless" (background, foreground: Color_Codes) -> Color_Code
{
	return (u8(background) << 4) | u8(foreground)
}

StateFlags :: enum u64
{
	WriteR                 = 0x0000000000000001,
	WriteG                 = 0x0000000000000002,
	WriteB                 = 0x0000000000000004,
	WriteA                 = 0x0000000000000008,
	WriteZ                 = 0x0000004000000000,
	WriteRgb               = 0x0000000000000007,
	WriteMask              = 0x000000400000000f,
	DepthTestLess          = 0x0000000000000010,
	DepthTestLequal        = 0x0000000000000020,
	DepthTestEqual         = 0x0000000000000030,
	DepthTestGequal        = 0x0000000000000040,
	DepthTestGreater       = 0x0000000000000050,
	DepthTestNotequal      = 0x0000000000000060,
	DepthTestNever         = 0x0000000000000070,
	DepthTestAlways        = 0x0000000000000080,
	DepthTestShift         = 4,
	DepthTestMask          = 0x00000000000000f0,
	BlendZero              = 0x0000000000001000,
	BlendOne               = 0x0000000000002000,
	BlendSrcColor          = 0x0000000000003000,
	BlendInvSrcColor       = 0x0000000000004000,
	BlendSrcAlpha          = 0x0000000000005000,
	BlendInvSrcAlpha       = 0x0000000000006000,
	BlendDstAlpha          = 0x0000000000007000,
	BlendInvDstAlpha       = 0x0000000000008000,
	BlendDstColor          = 0x0000000000009000,
	BlendInvDstColor       = 0x000000000000a000,
	BlendSrcAlphaSat       = 0x000000000000b000,
	BlendFactor            = 0x000000000000c000,
	BlendInvFactor         = 0x000000000000d000,
	BlendShift             = 12,
	BlendMask              = 0x000000000ffff000,
	BlendEquationAdd       = 0x0000000000000000,
	BlendEquationSub       = 0x0000000010000000,
	BlendEquationRevsub    = 0x0000000020000000,
	BlendEquationMin       = 0x0000000030000000,
	BlendEquationMax       = 0x0000000040000000,
	BlendEquationShift     = 28,
	BlendEquationMask      = 0x00000003f0000000,
	CullCw                 = 0x0000001000000000,
	CullCcw                = 0x0000002000000000,
	CullShift              = 36,
	CullMask               = 0x0000003000000000,
	AlphaRefShift          = 40,
	AlphaRefMask           = 0x0000ff0000000000,
	PtTristrip             = 0x0001000000000000,
	PtLines                = 0x0002000000000000,
	PtLinestrip            = 0x0003000000000000,
	PtPoints               = 0x0004000000000000,
	PtShift                = 48,
	PtMask                 = 0x0007000000000000,
	PointSizeShift         = 52,
	PointSizeMask          = 0x00f0000000000000,
	Msaa                   = 0x0100000000000000,
	Lineaa                 = 0x0200000000000000,
	ConservativeRaster     = 0x0400000000000000,
	None                   = 0x0000000000000000,
	FrontCcw               = 0x0000008000000000,
	BlendIndependent       = 0x0000000400000000,
	BlendAlphaToCoverage   = 0x0000000800000000,
	Default                = 0x010000500000001f,
	Mask                   = 0xffffffffffffffff,
	ReservedShift          = 61,
	ReservedMask           = 0xe000000000000000,
}

StencilFlags :: enum u32
{
	FuncRefShift           = 0,
	FuncRefMask            = 0x0,
	FuncRmaskShift         = 8,
	FuncRmaskMask          = 0x0000ff00,
	None                   = 0x00000000,
	Mask                   = 0xffffffff,
	Default                = 0x00000000,
	TestLess               = 0x00010000,
	TestLequal             = 0x00020000,
	TestEqual              = 0x00030000,
	TestGequal             = 0x00040000,
	TestGreater            = 0x00050000,
	TestNotequal           = 0x00060000,
	TestNever              = 0x00070000,
	TestAlways             = 0x00080000,
	TestShift              = 16,
	TestMask               = 0x000f0000,
	OpFailSZero            = 0x00000000,
	OpFailSKeep            = 0x00100000,
	OpFailSReplace         = 0x00200000,
	OpFailSIncr            = 0x00300000,
	OpFailSIncrsat         = 0x00400000,
	OpFailSDecr            = 0x00500000,
	OpFailSDecrsat         = 0x00600000,
	OpFailSInvert          = 0x00700000,
	OpFailSShift           = 20,
	OpFailSMask            = 0x00f00000,
	OpFailZZero            = 0x00000000,
	OpFailZKeep            = 0x01000000,
	OpFailZReplace         = 0x02000000,
	OpFailZIncr            = 0x03000000,
	OpFailZIncrsat         = 0x04000000,
	OpFailZDecr            = 0x05000000,
	OpFailZDecrsat         = 0x06000000,
	OpFailZInvert          = 0x07000000,
	OpFailZShift           = 24,
	OpFailZMask            = 0x0f000000,
	OpPassZZero            = 0x00000000,
	OpPassZKeep            = 0x10000000,
	OpPassZReplace         = 0x20000000,
	OpPassZIncr            = 0x30000000,
	OpPassZIncrsat         = 0x40000000,
	OpPassZDecr            = 0x50000000,
	OpPassZDecrsat         = 0x60000000,
	OpPassZInvert          = 0x70000000,
	OpPassZShift           = 28,
	OpPassZMask            = 0xf0000000,
}

Clear_Flag :: enum u16
{
	Color,
	Depth,
	Stencil,
	Discard_Color_0,
	Discard_Color_1,
	Discard_Color_2,
	Discard_Color_3,
	Discard_Color_4,
	Discard_Color_5,
	Discard_Color_6,
	Discard_Color_7,
	Discard_Depth,
	Discard_Stencil,
}

Clear_Flags :: bit_set[Clear_Flag; u16]

DiscardFlags :: enum u32
{
	None                   = 0x00000000,
	Bindings               = 0x00000001,
	IndexBuffer            = 0x00000002,
	InstanceData           = 0x00000004,
	State                  = 0x00000008,
	Transform              = 0x00000010,
	VertexStreams          = 0x00000020,
	All                    = 0x000000ff,
}

Debug_Flag :: enum u32
{
	Wireframe,
	IFH,
	Stats,
	Text,
	Profiler,
}

Debug_Flags :: bit_set[Debug_Flag]

Create_Buffer_Flag :: enum u16
{
	Compute_Read,
	Compute_Write,
	Draw_Indirect,
	Allow_Resize,
	Index_32,
}

Create_Buffer_Flags :: bit_set[Create_Buffer_Flag; u16]

Buffer_Flags :: enum u16
{
	Compute_Format_8x1       = 0x0001,
	Compute_Format_8x2       = 0x0002,
	Compute_Format_8x4       = 0x0003,
	Compute_Format_16x1      = 0x0004,
	Compute_Format_16x2      = 0x0005,
	Compute_Format_16x4      = 0x0006,
	Compute_Format_32x1      = 0x0007,
	Compute_Format_32x2      = 0x0008,
	Compute_Format_32x4      = 0x0009,
	Compute_Format_Shift     = 0,
	Compute_Format_Mask      = 0x000f,
	Compute_Type_Int         = 0x0010,
	Compute_Type_UInt        = 0x0020,
	Compute_Type_Float       = 0x0030,
	Compute_Type_Shift       = 4,
	Compute_Type_Mask        = 0x0030,
	None                   = 0x0000,
	Compute_Read            = 0x0100,
	Compute_Write           = 0x0200,
	Draw_Indirect           = 0x0400,
	Allow_Resize            = 0x0800,
	Index_32                = 0x1000,
	Compute_Read_Write       = 0x0300,
}

TEXTURE_FLAGS_NONE          :: 0x0000000000000000
TEXTURE_FLAGS_MSAA_SAMPLE   :: 0x0000000800000000
TEXTURE_FLAGS_RT            :: 0x0000001000000000
TEXTURE_FLAGS_COMPUTE_WRITE :: 0x0000100000000000
TEXTURE_FLAGS_SRGB          :: 0x0000200000000000
TEXTURE_FLAGS_BLIT_DST      :: 0x0000400000000000
TEXTURE_FLAGS_READ_BACK     :: 0x0000800000000000
TEXTURE_FLAGS_RT_MSAA_2     :: 0x0000002000000000
TEXTURE_FLAGS_RT_MSAA_4     :: 0x0000003000000000
TEXTURE_FLAGS_RT_MSAA_8     :: 0x0000004000000000
TEXTURE_FLAGS_RT_MSAA_16    :: 0x0000005000000000
TEXTURE_FLAGS_RT_MSAA_SHIFT :: 36
TEXTURE_FLAGS_RT_MSAA_MASK  :: 0x0000007000000000
TEXTURE_FLAGS_RT_WRITE_ONLY :: 0x0000008000000000
TEXTURE_FLAGS_RT_SHIFT      :: 36
TEXTURE_FLAGS_RT_MASK       :: 0x000000f000000000

SAMPLER_FLAGS_U_MIRROR           :: 0x00000001
SAMPLER_FLAGS_U_CLAMP            :: 0x00000002
SAMPLER_FLAGS_U_BORDER           :: 0x00000003
SAMPLER_FLAGS_U_SHIFT            :: 0
SAMPLER_FLAGS_U_MASK             :: 0x00000003
SAMPLER_FLAGS_V_MIRROR           :: 0x00000004
SAMPLER_FLAGS_V_CLAMP            :: 0x00000008
SAMPLER_FLAGS_V_BORDER           :: 0x0000000c
SAMPLER_FLAGS_V_SHIFT            :: 2
SAMPLER_FLAGS_V_MASK             :: 0x0000000c
SAMPLER_FLAGS_W_MIRROR           :: 0x00000010
SAMPLER_FLAGS_W_CLAMP            :: 0x00000020
SAMPLER_FLAGS_W_BORDER           :: 0x00000030
SAMPLER_FLAGS_W_SHIFT            :: 4
SAMPLER_FLAGS_W_MASK             :: 0x00000030
SAMPLER_FLAGS_MIN_POINT          :: 0x00000040
SAMPLER_FLAGS_MIN_ANISOTROPIC    :: 0x00000080
SAMPLER_FLAGS_MIN_SHIFT          :: 6
SAMPLER_FLAGS_MIN_MASK           :: 0x000000c0
SAMPLER_FLAGS_MAG_POINT          :: 0x00000100
SAMPLER_FLAGS_MAG_ANISOTROPIC    :: 0x00000200
SAMPLER_FLAGS_MAG_SHIFT          :: 8
SAMPLER_FLAGS_MAG_MASK           :: 0x00000300
SAMPLER_FLAGS_MIP_POINT          :: 0x00000400
SAMPLER_FLAGS_MIP_SHIFT          :: 10
SAMPLER_FLAGS_MIP_MASK           :: 0x00000400
SAMPLER_FLAGS_COMPARE_LESS       :: 0x00010000
SAMPLER_FLAGS_COMPARE_LEQUAL     :: 0x00020000
SAMPLER_FLAGS_COMPARE_EQUAL      :: 0x00030000
SAMPLER_FLAGS_COMPARE_GEQUAL     :: 0x00040000
SAMPLER_FLAGS_COMPARE_GREATER    :: 0x00050000
SAMPLER_FLAGS_COMPARE_NOT_EQUAL  :: 0x00060000
SAMPLER_FLAGS_COMPARE_NEVER      :: 0x00070000
SAMPLER_FLAGS_COMPARE_ALWAYS     :: 0x00080000
SAMPLER_FLAGS_COMPARE_SHIFT      :: 16
SAMPLER_FLAGS_COMPARE_MASK       :: 0x000f0000
SAMPLER_FLAGS_BORDER_COLOR_SHIFT :: 24
SAMPLER_FLAGS_BORDER_COLOR_MASK  :: 0x0f000000
SAMPLER_FLAGS_RESERVED_SHIFT     :: 28
SAMPLER_FLAGS_RESERVED_MASK      :: 0xf0000000
SAMPLER_FLAGS_NONE               :: 0x00000000
SAMPLER_FLAGS_SAMPLE_STENCIL     :: 0x00100000
SAMPLER_FLAGS_POINT              :: 0x00000540
SAMPLER_FLAGS_UVW_MIRROR         :: 0x00000015
SAMPLER_FLAGS_UVW_CLAMP          :: 0x0000002a
SAMPLER_FLAGS_UVW_BORDER         :: 0x0000003f
SAMPLER_FLAGS_BITS_MASK          :: 0x000f07ff

Sampler_Flag :: enum
{
	U_Mirror,
	U_Clamp,
	V_Mirror,
	V_Clamp,
	W_Mirror,
	W_Clamp,
	Min_Point,
	Min_Anisotropic,
	Mag_Point,
	Mag_Anisotropic,
	Mip_Point,
	Compare_Less,
	Compare_Lequal,
	Compare_Gequal,
	Compare_Always,
	Sample_Stencil,
}

Sampler_Flags :: bit_set[Sampler_Flag]

Reset :: enum u32
{
	MSAA_2                 = 0x00000010,
	MSAA_4                 = 0x00000020,
	MSAA_8                 = 0x00000030,
	MSAA_16                = 0x00000040,
	MSAA_Shift              = 4,
	MSAA_Mask               = 0x00000070,
	None                   = 0x00000000,
	Fullscreen             = 0x00000001,
	VSync                  = 0x00000080,
	Maxanisotropy          = 0x00000100,
	Capture                = 0x00000200,
	Flush_After_Render       = 0x00002000,
	Flip_After_Render        = 0x00004000,
	SRGB_Backbuffer         = 0x00008000,
	HDR10                  = 0x00010000,
	HI_DPI                  = 0x00020000,
	Depth_Clamp             = 0x00040000,
	Suspend                = 0x00080000,
	Transparent_Backbuffer  = 0x00100000,
	Fullscreen_Shift        = 0,
	Fullscreen_Mask         = 0x00000001,
	Reserved_Shift          = 31,
	Reserved_Mask           = 0x80000000,
}

Caps_Flag :: enum u64
{
	Alpha_To_Coverage,
	Blend_Independent,
	Compute,
	Conservative_Raster,
	Draw_Indirect,
	Fragment_Depth,
	Fragment_Ordering,
	Graphics_Debugger,
	HDR10,
	HIDPI,
	Image_Rw,
	Index_32,
	Instancing,
	Occlusion_Query,
	Renderer_Multithreaded,
	Swap_Chain,
	Texture_2D_Array,
	Texture_3D,
	Texture_Blit,
	Transparent_Backbuffer,
	Texture_Compare_Reserved,
	Texture_Compare_Lequal,
	Texture_Cube_Array,
	Texture_Direct_Access,
	Texture_Read_Back,
	Vertex_Attrib_Half,
	Vertex_Attrib_UInt10,
	Vertex_ID,
	Viewport_Layer_Array,
	Draw_Indirect_Count,
	Texture_Compare_All,
}

Caps_Flags :: bit_set[Caps_Flag; u64]

Caps_Format_Texture_Flag :: enum u16
{
	_2D,
	_2D_SRGB,
	_2D_Emulated,
	_3D,
	_3D_SRGB,
	_3D_Emulated,
	Cube,
	Cube_SRGB,
	Cube_Emulated,
	Vertex,
	Image_Read,
	Image_Write,
	Framebuffer,
	Framebuffer_MSAA,
	MSAA,
	Mip_Autogen,
}

Caps_Format_Texture_Flags :: bit_set[Caps_Format_Texture_Flag; u16]

ResolveFlags :: enum u32
{
	None                   = 0x00000000,
	AutoGenMips            = 0x00000001,
}

PCI_ID :: enum u16
{
	None                   = 0x0000,
	Software_Rasterizer    = 0x0001,
	AMD                    = 0x1002,
	Apple                  = 0x106b,
	Intel                  = 0x8086,
	Nvidia                 = 0x10de,
	Microsoft              = 0x1414,
	ARM                    = 0x13b5,
}

CubeMapFlags :: enum u32
{
	PositiveX              = 0x00000000,
	NegativeX              = 0x00000001,
	PositiveY              = 0x00000002,
	NegativeY              = 0x00000003,
	PositiveZ              = 0x00000004,
	NegativeZ              = 0x00000005,
}

Fatal :: enum u32
{
	DebugCheck,
	InvalidShader,
	UnableToInitialize,
	UnableToCreateTexture,
	DeviceLost,
	Count,
}

Renderer_Type :: enum u32
{
	No_Op,
	AGC,
	Direct3D_9,
	Direct3D_11,
	Direct3D_12,
	GNM,
	Metal,
	NVM,
	OpenGL_ES,
	OpenGL,
	Vulkan,
	WebGPU,
	Count,
}

Access :: enum u32
{
	Read,
	Write,
	Read_Write,
	Count,
}

Attrib :: enum u32
{
	Position,
	Normal,
	Tangent,
	Bitangent,
	Color_0,
	Color_1,
	Color_2,
	Color_3,
	Indices,
	Weight,
	Texcoord_0,
	Texcoord_1,
	Texcoord_2,
	Texcoord_3,
	Texcoord_4,
	Texcoord_5,
	Texcoord_6,
	Texcoord_7,

	Count,
}

Attrib_Type :: enum u32
{
	U8,
	U10,
	I16,
	Half,
	F32,
	Count,
}

Texture_Format :: enum u32
{
	BC1,
	BC2,
	BC3,
	BC4,
	BC5,
	BC6H,
	BC7,
	ETC1,
	ETC2,
	ETC2A,
	ETC2A1,
	PTC12,
	PTC14,
	PTC12A,
	PTC14A,
	PTC22,
	PTC24,
	ATC,
	ATCE,
	ATCI,
	ASTC4x4,
	ASTC5x4,
	ASTC5x5,
	ASTC6x5,
	ASTC6x6,
	ASTC8x5,
	ASTC8x6,
	ASTC8x8,
	ASTC10x5,
	ASTC10x6,
	ASTC10x8,
	ASTC10x10,
	ASTC12x10,
	ASTC12x12,
	Unknown,
	R1,
	A8,
	R8,
	R8I,
	R8U,
	R8S,
	R16,
	R16I,
	R16U,
	R16F,
	R16S,
	R32I,
	R32U,
	R32F,
	RG8,
	RG8I,
	RG8U,
	RG8S,
	RG16,
	RG16I,
	RG16U,
	RG16F,
	RG16S,
	RG32I,
	RG32U,
	RG32F,
	RGB8,
	RGB8I,
	RGB8U,
	RGB8S,
	RGB9E5F,
	BGRA8,
	RGBA8,
	RGBA8I,
	RGBA8U,
	RGBA8S,
	RGBA16,
	RGBA16I,
	RGBA16U,
	RGBA16F,
	RGBA16S,
	RGBA32I,
	RGBA32U,
	RGBA32F,
	B5G6R5,
	R5G6B5,
	BGRA4,
	RGBA4,
	BGR5A1,
	RGB5A1,
	RGB10A2,
	RG11B10F,
	Unknown_Depth,
	D16,
	D24,
	D24S8,
	D32,
	D16F,
	D24F,
	D32F,
	D0S8,

	Count,
}

Uniform_Type :: enum u32
{
	Sampler,
	End,
	Vec4,
	Mat3,
	Mat4,
}

Backbuffer_Ratio :: enum u32
{
	Equal,
	Half,
	Quarter,
	Eighth,
	Sixteenth,
	Double,

	Count,
}

OcclusionQueryResult :: enum u32
{
	Invisible,
	Visible,
	NoResult,
	Count,
}

Topology :: enum u32
{
	TriList,
	TriStrip,
	LineList,
	LineStrip,
	PointList,
	Count,
}

TopologyConvert :: enum u32
{
	TriListFlipWinding,
	TriStripFlipWinding,
	TriListToLineList,
	TriStripToTriList,
	LineStripToLineList,
	Count,
}

TopologySort :: enum u32
{
	DirectionFrontToBackMin,
	DirectionFrontToBackAvg,
	DirectionFrontToBackMax,
	DirectionBackToFrontMin,
	DirectionBackToFrontAvg,
	DirectionBackToFrontMax,
	DistanceFrontToBackMin,
	DistanceFrontToBackAvg,
	DistanceFrontToBackMax,
	DistanceBackToFrontMin,
	DistanceBackToFrontAvg,
	DistanceBackToFrontMax,
	Count,
}

View_Mode :: enum u32
{
	Default,
	Sequential,
	Depth_Ascending,
	Depth_Descending,
	Count,
}

RenderFrame :: enum u32
{
	NoContext,
	Render,
	Timeout,
	Exiting,
	Count,
}

View_ID :: u16

GPU :: struct {
    vendor_id: PCI_ID,
    device_id: u16,
}

Caps_Limits :: struct
{
    max_draw_calls,
    max_blits,
    max_texture_size,
    max_texture_layers,
    max_views,
    max_frame_Buffers,
    max_fb_attachments,
    max_programs,
    max_shaders,
    max_textures,
    max_texture_samplers,
    max_compute_bindings,
    max_vertex_layouts,
    max_vertex_streams,
    max_index_buffers,
    max_vertex_buffers,
    max_dynamic_index_buffers,
    max_dynamic_vertex_buffers,
    max_uniforms,
    max_occlusion_queries,
    max_encoders,
    min_resource_cb_size,
    transient_vb_size,
    transient_ib_size: u32,
}

Caps :: struct
{
    rendererType: Renderer_Type,
    supported: Caps_Flags,
    vendor_id: PCI_ID,
    device_id: u16,
    homogeneous_depth,
    origin_bottom_left: bool,
    num_gpus: u8,
    gpu : [4]GPU,
    limits: Caps_Limits,
    formats : [max(Texture_Format)]Caps_Format_Texture_Flags,
}

InternalData :: struct {
    caps: ^Caps,
    context_: rawptr,
}

Platform_Data :: struct
{
    ndt,
    nwh,
    context_,
    back_buffer,
    back_buffer_ds: rawptr,
	window_type: i32,
}

Resolution :: struct
{
    format: Texture_Format,
    width,
    height: u32,
    reset: Reset,
    num_back_buffers,
    max_frame_latency,
    debug_text_scale: u8,
}

Init_Limits :: struct {
    max_encoders: u16,
    min_resource_cb_size,
    transient_vb_size,
    transient_ib_size: u32,
}

Init :: struct {
    type: Renderer_Type,
    vendor_id: PCI_ID,
    device_id: u16,
    capabilities: Caps_Flags,
    debug,
    profile: bool,
    platform_data: Platform_Data,
    resolution: Resolution,
    limits: Init_Limits,
    callback,
    allocator: rawptr,
}

Memory :: struct {
    data : ^u8,
    size : u32,
}

TransientIndexBuffer :: struct {
    data : ^u8,
    size : u32,
    startIndex : u32,
    handle : Index_Buffer_Handle,
    isIndex16 : u8,
}

TransientVertexBuffer :: struct {
    data : ^u8,
    size : u32,
    startVertex : u32,
    stride : u16,
    handle : Vertex_Buffer_Handle,
    layoutHandle : Vertex_Layout_Handle,
}

InstanceDataBuffer :: struct {
	data : ^u8,
	size : u32,
	offset : u32,
	num : u32,
	stride : u16,
	handle : Vertex_Buffer_Handle,
}

Texture_Info :: struct {
	format: Texture_Format,
	storage_size: u32,
	width,
	height,
	depth,
	num_layers: u16,
	num_mips,
	bits_per_pixel: u8,
	cube_map: bool,
}

Uniform_Info :: struct {
	name: [256]u8,
	type: Uniform_Type,
	num: u16,
}

Attachment :: struct {
	access 	: Access,
	handle 	: Texture_Handle,
	mip 	:	u16,
	layer 	:	u16,
	numLayers 	:	u16,
	resolve 	:	u8,
}

Transform :: struct {
	data: ^f32,
	num: u16,
}

View_Stats :: struct {
    name: [256]u8,
    view: View_ID,
    cpu_time_begin: i64,
    cpu_time_end: i64,
    gpu_time_begin: i64,
    gpu_time_end: i64,
    gpu_frame_num: u32,
}

Encoder_Stats :: struct {
    cpu_time_begin: i64,
    cpu_time_end: i64,
}

Stats :: struct {
    cpu_time_frame: i64,
    cpu_time_begin: i64,
    cpu_time_end: i64,
    cpu_timer_freq: i64,
    gpu_time_begin: i64,
    gpu_time_end: i64,
    gpu_timer_freq: i64,
    wait_render: i64,
    wait_submit: i64,
    num_draw: u32,
    num_compute: u32,
    num_blit: u32,
    max_gpu_latency: u32,
    gpu_frame_num: u32,
    num_dynamic_index_buffers: u16,
    num_dynamic_vertex_buffers: u16,
    num_frame_buffers: u16,
    num_index_buffers: u16,
    num_occlusion_queries: u16,
    num_programs: u16,
    num_shaders: u16,
    num_textures: u16,
    num_uniforms: u16,
    num_vertex_buffers: u16,
    num_vertex_layouts: u16,
    texture_memory_used : i64,
	rt_memory_used : i64,
	transient_vb_used : i32,
	transient_ib_used : i32,
	num_prims : [5]u32,
	gpu_memory_max : i64,
	gpu_memory_used : i64,
	width : u16,
	height : u16,
	text_width : u16,
	text_height : u16,
	num_views : u16,
	view_stats : ^View_Stats,
	num_encoders : u8,
	encoder_stats : ^Encoder_Stats,
}

Vertex_Layout :: struct
{
    hash: u32,
    stride: u16,
    offset: [18]u16,
    attributes: [18]u16,
}

Encoder :: struct {}

DynamicIndex_Buffer_Handle :: struct {
    idx: u16,
}

DynamicVertex_Buffer_Handle :: struct {
    idx: u16,
}

Frame_Buffer_Handle :: Handle
Index_Buffer_Handle :: Handle

IndirectBufferHandle :: struct {
    idx: u16,
}

OcclusionQueryHandle :: struct {
    idx: u16,
}

Program_Handle :: Handle
Shader_Handle :: Handle

Texture_Handle :: Handle
Uniform_Handle :: Handle
Vertex_Buffer_Handle :: Handle
Vertex_Layout_Handle :: Handle

when ODIN_OS == .Windows && ODIN_ARCH == .i386 && ODIN_DEBUG do foreign import bgfx{
	"binaries/bgfx_windows_i386_debug.lib",
	"binaries/bx_windows_i386_debug.lib",
	"binaries/bimg_windows_i386_debug.lib",
	"binaries/bimg_encode_windows_i386_debug.lib",
	"binaries/bimg_decode_windows_i386_debug.lib",
	"system:gdi32.lib",
	"system:user32.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .i386 && !ODIN_DEBUG do foreign import bgfx{
	"binaries/bgfx_windows_i386_release.lib",
	"binaries/bx_windows_i386_release.lib",
	"binaries/bimg_windows_i386_release.lib",
	"binaries/bimg_encode_windows_i386_release.lib",
	"binaries/bimg_decode_windows_i386_release.lib",
	"system:gdi32.lib",
	"system:user32.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && ODIN_DEBUG do foreign import bgfx{
	"binaries/bx_windows_amd64_debug.lib",
	"binaries/bimg_windows_amd64_debug.lib",
	"binaries/bgfx_windows_amd64_debug.lib",
	"system:libcmtd.lib",
	"system:gdi32.lib",
	"system:user32.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && !ODIN_DEBUG do foreign import bgfx{
	"binaries/bx_windows_amd64_release.lib",
	"binaries/bimg_windows_amd64_release.lib",
	"binaries/bgfx_windows_amd64_release.lib",
	//"binaries/bimg_encode_windows_amd64_release.lib",
	//"binaries/bimg_decode_windows_amd64_release.lib",
	"system:gdi32.lib",
	"system:user32.lib",
}

foreign bgfx
{
    @(link_name="bgfx_attachment_init")
    attachment_init :: proc "c" (_this: ^Attachment, _handle: Texture_Handle, _access: Access, _layer: u16, _numLayers: u16, _mip: u16, _resolve: u8) ---

    @(link_name="bgfx_vertex_layout_begin")
    vertex_layout_begin :: proc "c" (_layout: ^Vertex_Layout, _rendererType: Renderer_Type) -> ^Vertex_Layout ---

    @(link_name="bgfx_vertex_layout_add")
    vertex_layout_add :: proc "c" (_layout: ^Vertex_Layout, _attrib: Attrib, _num: u8, _type: Attrib_Type, _normalized: b8, _asInt: b8) -> ^Vertex_Layout ---

    @(link_name="bgfx_vertex_layout_decode")
    vertex_layout_decode :: proc "c" (_layout: ^Vertex_Layout, _attrib: Attrib, _num: ^u8, _type: ^Attrib_Type, _normalized: ^b8, _asInt: ^b8) ---

    @(link_name="bgfx_vertex_layout_has")
    vertex_layout_has :: proc "c" (_layout: ^Vertex_Layout, _attrib: Attrib) -> b8 ---

    @(link_name="bgfx_vertex_layout_skip")
    vertex_layout_skip :: proc "c" (_layout: ^Vertex_Layout, _num: u8) -> ^Vertex_Layout ---

    @(link_name="bgfx_vertex_layout_end")
    vertex_layout_end :: proc "c" (_layout: ^Vertex_Layout) ---

    @(link_name="bgfx_vertex_pack")
    vertex_pack :: proc "c" (_input: f32, _inputNormalized: b8, _attr: Attrib, _layout: ^Vertex_Layout, _data: rawptr, _index: u32) ---

    @(link_name="bgfx_vertex_unpack")
    vertex_unpack :: proc "c" (_output: f32, _attr: Attrib, _layout: ^Vertex_Layout, _data: rawptr, _index: u32) ---

    @(link_name="bgfx_vertex_convert")
    vertex_convert :: proc "c" (_dstLayout: ^Vertex_Layout, _dstData: rawptr, _srcLayout: ^Vertex_Layout, _srcData: rawptr, _num: u32) ---

    @(link_name="bgfx_weld_vertices")
    weld_vertices :: proc "c" (_output: rawptr, _layout: ^Vertex_Layout, _data: rawptr, _num: u32, _index32: b8, _epsilon: f32) -> u32 ---

    @(link_name="bgfx_topology_convert")
    topology_convert :: proc "c" (_conversion: TopologyConvert, _dst: rawptr, _dstSize: u32, _indices: rawptr, _numIndices: u32, _index32: b8) -> u32 ---

    @(link_name="bgfx_topology_sort_tri_list")
    topology_sort_tri_list :: proc "c" (_sort: TopologySort, _dst: rawptr, _dstSize: u32, _dir: f32, _pos: f32, _vertices: rawptr, _stride: u32, _indices: rawptr, _numIndices: u32, _index32: b8) ---

    @(link_name="bgfx_get_supported_renderers")
    get_supported_renderers :: proc "c" (_max: u8, _enum: ^Renderer_Type) -> u8 ---

    @(link_name="bgfx_get_renderer_name")
    get_renderer_name :: proc "c" (_type: Renderer_Type) -> cstring ---

    @(link_name="bgfx_init_ctor")
    init_ctor :: proc "c" (_init: ^Init) ---

    @(link_name="bgfx_init")
    init :: proc "c" (_init: ^Init) -> b8 ---

    @(link_name="bgfx_shutdown")
    shutdown :: proc "c" () ---

    @(link_name="bgfx_reset")
    reset :: proc "c" (_width: u32, _height: u32, _flags: u32, _format: Texture_Format) ---

    @(link_name="bgfx_frame")
    frame :: proc "c" (_capture: b8) -> u32 ---

    @(link_name="bgfx_get_renderer_type")
    get_renderer_type :: proc "c" () -> Renderer_Type ---

    @(link_name="bgfx_get_caps")
    get_caps :: proc "c" () -> ^Caps ---

    @(link_name="bgfx_get_stats")
    get_stats :: proc "c" () -> ^Stats ---

    @(link_name="bgfx_alloc")
    alloc :: proc "c" (_size: u32) -> ^Memory ---

    @(link_name="bgfx_copy")
    copy :: proc "c" (_data: rawptr, _size: u32) -> ^Memory ---

    @(link_name="bgfx_make_ref")
    make_ref :: proc "c" (_data: rawptr, _size: u32) -> ^Memory ---

    @(link_name="bgfx_make_ref_release")
    make_ref_release :: proc "c" (_data: rawptr, _size: u32, _releaseFn: rawptr, _userData: rawptr) -> ^Memory ---

    @(link_name="bgfx_set_debug")
    set_debug :: proc "c" (_debug: Debug_Flags) ---

    @(link_name="bgfx_dbg_text_clear")
    dbg_text_clear :: proc "c" (_color_code: Color_Code, _small: b8) ---

    @(link_name="bgfx_dbg_text_printf")
    dbg_text_printf :: proc "c" (_x: u16, _y: u16, _color_code: Color_Code, _format: cstring, #c_vararg _args: ..any) ---

    @(link_name="bgfx_dbg_text_vprintf")
    dbg_text_vprintf :: proc "c" (_x: u16, _y: u16, _color_code: Color_Code, _format: cstring, _argList: rawptr) ---

    @(link_name="bgfx_dbg_text_image")
    dbg_text_image :: proc "c" (_x: u16, _y: u16, _width: u16, _height: u16, _data: rawptr, _pitch: u16) ---

    @(link_name="bgfx_create_index_buffer")
    create_index_buffer :: proc "c" (_mem: ^Memory, _flags: Create_Buffer_Flags) -> Index_Buffer_Handle ---

    @(link_name="bgfx_set_index_buffer_name")
    set_index_buffer_name :: proc "c" (_handle: Index_Buffer_Handle, _name: cstring, _len: i32) ---

    @(link_name="bgfx_destroy_index_buffer")
    destroy_index_buffer :: proc "c" (_handle: Index_Buffer_Handle) ---

    @(link_name="bgfx_create_vertex_layout")
    create_vertex_layout :: proc "c" (_layout: ^Vertex_Layout) -> Vertex_Layout_Handle ---

    @(link_name="bgfx_destroy_vertex_layout")
    destroy_vertex_layout :: proc "c" (_layoutHandle: Vertex_Layout_Handle) ---

    @(link_name="bgfx_create_vertex_buffer")
    create_vertex_buffer :: proc "c" (_mem: ^Memory, _layout: ^Vertex_Layout, _flags: Create_Buffer_Flags) -> Vertex_Buffer_Handle ---

    @(link_name="bgfx_set_vertex_buffer_name")
    set_vertex_buffer_name :: proc "c" (_handle: Vertex_Buffer_Handle, _name: cstring, _len: i32) ---

    @(link_name="bgfx_destroy_vertex_buffer")
    destroy_vertex_buffer :: proc "c" (_handle: Vertex_Buffer_Handle) ---

    @(link_name="bgfx_create_dynamic_index_buffer")
    create_dynamic_index_buffer :: proc "c" (_num: u32, _flags: u16) -> DynamicIndex_Buffer_Handle ---

    @(link_name="bgfx_create_dynamic_index_buffer_mem")
    create_dynamic_index_buffer_mem :: proc "c" (_mem: ^Memory, _flags: u16) -> DynamicIndex_Buffer_Handle ---

    @(link_name="bgfx_update_dynamic_index_buffer")
    update_dynamic_index_buffer :: proc "c" (_handle: DynamicIndex_Buffer_Handle, _startIndex: u32, _mem: ^Memory) ---

    @(link_name="bgfx_destroy_dynamic_index_buffer")
    destroy_dynamic_index_buffer :: proc "c" (_handle: DynamicIndex_Buffer_Handle) ---

    @(link_name="bgfx_create_dynamic_vertex_buffer")
    create_dynamic_vertex_buffer :: proc "c" (_num: u32, _layout: ^Vertex_Layout, _flags: u16) -> DynamicVertex_Buffer_Handle ---

    @(link_name="bgfx_create_dynamic_vertex_buffer_mem")
    create_dynamic_vertex_buffer_mem :: proc "c" (_mem: ^Memory, _layout: ^Vertex_Layout, _flags: u16) -> DynamicVertex_Buffer_Handle ---

    @(link_name="bgfx_update_dynamic_vertex_buffer")
    update_dynamic_vertex_buffer :: proc "c" (_handle: DynamicVertex_Buffer_Handle, _startVertex: u32, _mem: ^Memory) ---

    @(link_name="bgfx_destroy_dynamic_vertex_buffer")
    destroy_dynamic_vertex_buffer :: proc "c" (_handle: DynamicVertex_Buffer_Handle) ---

    @(link_name="bgfx_get_avail_transient_index_buffer")
    get_avail_transient_index_buffer :: proc "c" (_num: u32, _index32: b8) -> u32 ---

    @(link_name="bgfx_get_avail_transient_vertex_buffer")
    get_avail_transient_vertex_buffer :: proc "c" (_num: u32, _layout: ^Vertex_Layout) -> u32 ---

    @(link_name="bgfx_get_avail_instance_data_buffer")
    get_avail_instance_data_buffer :: proc "c" (_num: u32, _stride: u16) -> u32 ---

    @(link_name="bgfx_alloc_transient_index_buffer")
    alloc_transient_index_buffer :: proc "c" (_tib: ^TransientIndexBuffer, _num: u32, _index32: b8) ---

    @(link_name="bgfx_alloc_transient_vertex_buffer")
    alloc_transient_vertex_buffer :: proc "c" (_tvb: ^TransientVertexBuffer, _num: u32, _layout: ^Vertex_Layout) ---

    @(link_name="bgfx_alloc_transient_buffers")
    alloc_transient_buffers :: proc "c" (_tvb: ^TransientVertexBuffer, _layout: ^Vertex_Layout, _numVertices: u32, _tib: ^TransientIndexBuffer, _numIndices: u32, _index32: b8) -> b8 ---

    @(link_name="bgfx_alloc_instance_data_buffer")
    alloc_instance_data_buffer :: proc "c" (_idb: ^InstanceDataBuffer, _num: u32, _stride: u16) ---

    @(link_name="bgfx_create_indirect_buffer")
    create_indirect_buffer :: proc "c" (_num: u32) -> IndirectBufferHandle ---

    @(link_name="bgfx_destroy_indirect_buffer")
    destroy_indirect_buffer :: proc "c" (_handle: IndirectBufferHandle) ---

    @(link_name="bgfx_create_shader")
    create_shader :: proc "c" (_mem: ^Memory) -> Shader_Handle ---

    @(link_name="bgfx_get_shader_uniforms")
    get_shader_uniforms :: proc "c" (_handle: Shader_Handle, _uniforms: [^]Uniform_Handle, _max: u16) -> u16 ---

    @(link_name="bgfx_set_shader_name")
    set_shader_name :: proc "c" (_handle: Shader_Handle, _name: cstring, _len: i32) ---

    @(link_name="bgfx_destroy_shader")
    destroy_shader :: proc "c" (_handle: Shader_Handle) ---

    @(link_name="bgfx_create_program")
    create_program :: proc "c" (_vsh: Shader_Handle, _fsh: Shader_Handle, _destroyShaders: b8) -> Program_Handle ---

    @(link_name="bgfx_create_compute_program")
    create_compute_program :: proc "c" (_csh: Shader_Handle, _destroyShaders: b8) -> Program_Handle ---

    @(link_name="bgfx_destroy_program")
    destroy_program :: proc "c" (_handle: Program_Handle) ---

    @(link_name="bgfx_is_texture_valid")
    is_texture_valid :: proc "c" (_depth: u16, _cubeMap: b8, _numLayers: u16, _format: Texture_Format, _flags: u64) -> b8 ---

    @(link_name="bgfx_is_frame_buffer_valid")
    is_frame_buffer_valid :: proc "c" (_num: u8, _attachment: ^Attachment) -> b8 ---

    @(link_name="bgfx_calc_texture_size")
    calc_texture_size :: proc "c" (_info: ^Texture_Info, _width: u16, _height: u16, _depth: u16, _cubeMap: b8, _hasMips: b8, _numLayers: u16, _format: Texture_Format) ---

    @(link_name="bgfx_create_texture")
    create_texture :: proc "c" (_mem: ^Memory, _flags: u64, _skip: u8, _info: ^Texture_Info) -> Texture_Handle ---

    @(link_name="bgfx_create_texture_2d")
    create_texture_2d :: proc "c" (_width: u16, _height: u16, _hasMips: b8, _numLayers: u16, _format: Texture_Format, _flags: u64, _mem: ^Memory) -> Texture_Handle ---

    @(link_name="bgfx_create_texture_2d_scaled")
    create_texture_2d_scaled :: proc "c" (_ratio: Backbuffer_Ratio, _hasMips: b8, _numLayers: u16, _format: Texture_Format, _flags: u64) -> Texture_Handle ---

    @(link_name="bgfx_create_texture_3d")
    create_texture_3d :: proc "c" (_width: u16, _height: u16, _depth: u16, _hasMips: b8, _format: Texture_Format, _flags: u64, _mem: ^Memory) -> Texture_Handle ---

    @(link_name="bgfx_create_texture_cube")
    create_texture_cube :: proc "c" (_size: u16, _hasMips: b8, _numLayers: u16, _format: Texture_Format, _flags: u64, _mem: ^Memory) -> Texture_Handle ---

    @(link_name="bgfx_update_texture_2d")
    update_texture_2d :: proc "c" (_handle: Texture_Handle, _layer: u16, _mip: u8, _x: u16, _y: u16, _width: u16, _height: u16, _mem: ^Memory, _pitch: u16) ---

    @(link_name="bgfx_update_texture_3d")
    update_texture_3d :: proc "c" (_handle: Texture_Handle, _mip: u8, _x: u16, _y: u16, _z: u16, _width: u16, _height: u16, _depth: u16, _mem: ^Memory) ---

    @(link_name="bgfx_update_texture_cube")
    update_texture_cube :: proc "c" (_handle: Texture_Handle, _layer: u16, _side: u8, _mip: u8, _x: u16, _y: u16, _width: u16, _height: u16, _mem: ^Memory, _pitch: u16) ---

    @(link_name="bgfx_read_texture")
    read_texture :: proc "c" (_handle: Texture_Handle, _data: rawptr, _mip: u8) -> u32 ---

    @(link_name="bgfx_set_texture_name")
    set_texture_name :: proc "c" (_handle: Texture_Handle, _name: cstring, _len: i32) ---

    @(link_name="bgfx_get_direct_access_ptr")
    get_direct_access_ptr :: proc "c" (_handle: Texture_Handle) -> rawptr ---

    @(link_name="bgfx_destroy_texture")
    destroy_texture :: proc "c" (_handle: Texture_Handle) ---

    @(link_name="bgfx_create_frame_buffer")
    create_frame_buffer :: proc "c" (_width: u16, _height: u16,_format :Texture_Format,_textureFlags :u64) -> Frame_Buffer_Handle ---

    @(link_name="bgfx_create_frame_buffer_scaled")
    create_frame_buffer_scaled :: proc "c" (_ratio: Backbuffer_Ratio, _format: Texture_Format, _textureFlags: u64) -> Frame_Buffer_Handle ---

    @(link_name="bgfx_create_frame_buffer_from_handles")
    create_frame_buffer_from_handles :: proc "c" (_num: u8, _handles: ^Texture_Handle, _destroyTexture: b8) -> Frame_Buffer_Handle ---

    @(link_name="bgfx_create_frame_buffer_from_attachment")
    create_frame_buffer_from_attachment :: proc "c" (_num: u8, _attachment: ^Attachment, _destroyTexture: b8) -> Frame_Buffer_Handle ---

    @(link_name="bgfx_create_frame_buffer_from_nwh")
    create_frame_buffer_from_nwh :: proc "c" (_nwh: rawptr, _width: u16, _height: u16, _format: Texture_Format, _depthFormat: Texture_Format) -> Frame_Buffer_Handle ---

    @(link_name="bgfx_set_frame_buffer_name")
    set_frame_buffer_name :: proc "c" (_handle: Frame_Buffer_Handle, _name: cstring, _len: i32) ---

    @(link_name="bgfx_get_texture")
    get_texture :: proc "c" (_handle: Frame_Buffer_Handle, _attachment: u8) -> Texture_Handle ---

    @(link_name="bgfx_destroy_frame_buffer")
    destroy_frame_buffer :: proc "c" (_handle: Frame_Buffer_Handle) ---

    @(link_name="bgfx_create_uniform")
    create_uniform :: proc "c" (_name: cstring, _type: Uniform_Type, _num: u16) -> Uniform_Handle ---

    @(link_name="bgfx_get_uniform_info")
    get_uniform_info :: proc "c" (_handle: Uniform_Handle, _info: ^Uniform_Info) ---

    @(link_name="bgfx_destroy_uniform")
    destroy_uniform :: proc "c" (_handle: Uniform_Handle) ---

    @(link_name="bgfx_create_occlusion_query")
    create_occlusion_query :: proc "c" () -> OcclusionQueryHandle ---

    @(link_name="bgfx_get_result")
    get_result :: proc "c" (_handle: OcclusionQueryHandle, _result: ^i32) -> OcclusionQueryResult ---

    @(link_name="bgfx_destroy_occlusion_query")
    destroy_occlusion_query :: proc "c" (_handle: OcclusionQueryHandle) ---

    @(link_name="bgfx_set_palette_color")
    set_palette_color :: proc "c" (_index: u8, _rgba: f32) ---

    @(link_name="bgfx_set_palette_color_rgba8")
    set_palette_color_rgba8 :: proc "c" (_index: u8, _rgba: u32) ---

    @(link_name="bgfx_set_view_name")
    set_view_name :: proc "c" (_id: View_ID, _name: cstring) ---

    @(link_name="bgfx_set_view_rect")
    set_view_rect :: proc "c" (_id: View_ID, _x: u16, _y: u16, _width: u16, _height: u16) ---

    @(link_name="bgfx_set_view_rect_ratio")
    set_view_rect_ratio :: proc "c" (_id: View_ID, _x: u16, _y: u16, _ratio: Backbuffer_Ratio) ---

    @(link_name="bgfx_set_view_scissor")
    set_view_scissor :: proc "c" (_id: View_ID, _x: u16, _y: u16, _width: u16, _height: u16) ---

    @(link_name="bgfx_set_view_clear")
    set_view_clear :: proc "c" (_id: View_ID, _flags: Clear_Flags, _color: Color_ABGR, _depth: f32, _stencil: u8) ---

    @(link_name="bgfx_set_view_clear")
    set_view_clear_color_hex :: proc "c" (_id: View_ID, _flags: Clear_Flags, _color: Color_ABGR, _depth: f32, _stencil: u8) ---

    @(link_name="bgfx_set_view_clear_mrt")
    set_view_clear_mrt :: proc "c" (_id: View_ID, _flags: Clear_Flags, _depth: f32, _stencil: u8, _c0: u8, _c1: u8, _c2: u8, _c3: u8, _c4: u8, _c5: u8, _c6: u8, _c7: u8) ---

    @(link_name="bgfx_set_view_mode")
    set_view_mode :: proc "c" (_id: View_ID, _mode: View_Mode) ---

    @(link_name="bgfx_set_view_frame_buffer")
    set_view_frame_buffer :: proc "c" (_id: View_ID, _handle: Frame_Buffer_Handle) ---

    @(link_name="bgfx_set_view_transform")
    set_view_transform :: proc "c" (_id: View_ID, _view: rawptr, _proj: rawptr) ---

    @(link_name="bgfx_set_view_order")
    set_view_order :: proc "c" (_id: View_ID, _num: u16, _order: ^View_ID) ---

    @(link_name="bgfx_reset_view")
    reset_view :: proc "c" (_id: View_ID) ---

    @(link_name="bgfx_encoder_begin")
    encoder_begin :: proc "c" (_forThread: b8) -> ^Encoder ---

    @(link_name="bgfx_encoder_end")
    encoder_end :: proc "c" (_encoder: ^Encoder) ---

    @(link_name="bgfx_encoder_set_marker")
    encoder_set_marker :: proc "c" (_this: ^Encoder, _marker: cstring) ---

    @(link_name="bgfx_encoder_set_state")
    encoder_set_state :: proc "c" (_this: ^Encoder, _state: u64, _rgba: u32) ---

    @(link_name="bgfx_encoder_set_condition")
    encoder_set_condition :: proc "c" (_this: ^Encoder, _handle: OcclusionQueryHandle, _visible: b8) ---

    @(link_name="bgfx_encoder_set_stencil")
    encoder_set_stencil :: proc "c" (_this: ^Encoder, _fstencil: u32, _bstencil: u32) ---

    @(link_name="bgfx_encoder_set_scissor")
    encoder_set_scissor :: proc "c" (_this: ^Encoder, _x: u16, _y: u16, _width: u16, _height: u16) -> u16 ---

    @(link_name="bgfx_encoder_set_scissor_cached")
    encoder_set_scissor_cached :: proc "c" (_this: ^Encoder, _cache: u16) ---

    @(link_name="bgfx_encoder_set_transform")
    encoder_set_transform :: proc "c" (_this: ^Encoder, _mtx: rawptr, _num: u16) -> u32 ---

    @(link_name="bgfx_encoder_set_transform_cached")
    encoder_set_transform_cached :: proc "c" (_this: ^Encoder, _cache: u32, _num: u16) ---

    @(link_name="bgfx_encoder_alloc_transform")
    encoder_alloc_transform :: proc "c" (_this: ^Encoder, _transform: ^Transform, _num: u16) -> u32 ---

    @(link_name="bgfx_encoder_set_uniform")
    encoder_set_uniform :: proc "c" (_this: ^Encoder, _handle: Uniform_Handle, _value: rawptr, _num: u16) ---

    @(link_name="bgfx_encoder_set_index_buffer")
    encoder_set_index_buffer :: proc "c" (_this: ^Encoder, _handle: Index_Buffer_Handle, _firstIndex: u32, _numIndices: u32) ---

    @(link_name="bgfx_encoder_set_dynamic_index_buffer")
    encoder_set_dynamic_index_buffer :: proc "c" (_this: ^Encoder, _handle: DynamicIndex_Buffer_Handle, _firstIndex: u32, _numIndices: u32) ---

    @(link_name="bgfx_encoder_set_transient_index_buffer")
    encoder_set_transient_index_buffer :: proc "c" (_this: ^Encoder, _tib: ^TransientIndexBuffer, _firstIndex: u32, _numIndices: u32) ---

    @(link_name="bgfx_encoder_set_vertex_buffer")
    encoder_set_vertex_buffer :: proc "c" (_this: ^Encoder, _stream: u8, _handle: Vertex_Buffer_Handle, _startVertex: u32, _numVertices: u32) ---

    @(link_name="bgfx_encoder_set_vertex_buffer_with_layout")
    encoder_set_vertex_buffer_with_layout :: proc "c" (_this: ^Encoder, _stream: u8, _handle: Vertex_Buffer_Handle, _startVertex: u32, _numVertices: u32, _layoutHandle: Vertex_Layout_Handle) ---

    @(link_name="bgfx_encoder_set_dynamic_vertex_buffer")
    encoder_set_dynamic_vertex_buffer :: proc "c" (_this: ^Encoder, _stream: u8, _handle: DynamicVertex_Buffer_Handle, _startVertex: u32, _numVertices: u32) ---

    @(link_name="bgfx_encoder_set_dynamic_vertex_buffer_with_layout")
    encoder_set_dynamic_vertex_buffer_with_layout :: proc "c" (_this: ^Encoder, _stream: u8, _handle: DynamicVertex_Buffer_Handle, _startVertex: u32, _numVertices: u32, _layoutHandle: Vertex_Layout_Handle) ---

    @(link_name="bgfx_encoder_set_transient_vertex_buffer")
    encoder_set_transient_vertex_buffer :: proc "c" (_this: ^Encoder, _stream: u8, _tvb: ^TransientVertexBuffer, _startVertex: u32, _numVertices: u32) ---

    @(link_name="bgfx_encoder_set_transient_vertex_buffer_with_layout")
    encoder_set_transient_vertex_buffer_with_layout :: proc "c" (_this: ^Encoder, _stream: u8, _tvb: ^TransientVertexBuffer, _startVertex: u32, _numVertices: u32, _layoutHandle: Vertex_Layout_Handle) ---

    @(link_name="bgfx_encoder_set_vertex_count")
    encoder_set_vertex_count :: proc "c" (_this: ^Encoder, _numVertices: u32) ---

    @(link_name="bgfx_encoder_set_instance_data_buffer")
    encoder_set_instance_data_buffer :: proc "c" (_this: ^Encoder, _idb: ^InstanceDataBuffer, _start: u32, _num: u32) ---

    @(link_name="bgfx_encoder_set_instance_data_from_vertex_buffer")
    encoder_set_instance_data_from_vertex_buffer :: proc "c" (_this: ^Encoder, _handle: Vertex_Buffer_Handle, _startVertex: u32, _num: u32) ---

    @(link_name="bgfx_encoder_set_instance_data_from_dynamic_vertex_buffer")
    encoder_set_instance_data_from_dynamic_vertex_buffer :: proc "c" (_this: ^Encoder, _handle: DynamicVertex_Buffer_Handle, _startVertex: u32, _num: u32) ---

    @(link_name="bgfx_encoder_set_instance_count")
    encoder_set_instance_count :: proc "c" (_this: ^Encoder, _numInstances: u32) ---

    @(link_name="bgfx_encoder_set_texture")
    encoder_set_texture :: proc "c" (_this: ^Encoder, _stage: u8, _sampler: Uniform_Handle, _handle: Texture_Handle, _flags: u32) ---

    @(link_name="bgfx_encoder_touch")
    encoder_touch :: proc "c" (_this: ^Encoder, _id: View_ID) ---

    @(link_name="bgfx_encoder_submit")
    encoder_submit :: proc "c" (_this: ^Encoder, _id: View_ID, _program: Program_Handle, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_encoder_submit_occlusion_query")
    encoder_submit_occlusion_query :: proc "c" (_this: ^Encoder, _id: View_ID, _program: Program_Handle, _occlusionQuery: OcclusionQueryHandle, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_encoder_submit_indirect")
    encoder_submit_indirect :: proc "c" (_this: ^Encoder, _id: View_ID, _program: Program_Handle, _indirectHandle: IndirectBufferHandle, _start: u16, _num: u16, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_encoder_submit_indirect_count")
    encoder_submit_indirect_count :: proc "c" (_this: ^Encoder, _id: View_ID, _program: Program_Handle, _indirectHandle: IndirectBufferHandle, _start: u16, _numHandle: Index_Buffer_Handle, _numIndex: u32, _numMax: u16, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_encoder_set_compute_index_buffer")
    encoder_set_compute_index_buffer :: proc "c" (_this: ^Encoder, _stage: u8, _handle: Index_Buffer_Handle, _access: Access) ---

    @(link_name="bgfx_encoder_set_compute_vertex_buffer")
    encoder_set_compute_vertex_buffer :: proc "c" (_this:^Encoder,_stage :u8,_handle :Vertex_Buffer_Handle,_access :Access) ---

    @(link_name="bgfx_encoder_set_compute_dynamic_index_buffer")
    encoder_set_compute_dynamic_index_buffer :: proc "c" (_this: ^Encoder, _stage: u8, _handle: DynamicIndex_Buffer_Handle, _access: Access) ---

    @(link_name="bgfx_encoder_set_compute_dynamic_vertex_buffer")
    encoder_set_compute_dynamic_vertex_buffer :: proc "c" (_this: ^Encoder, _stage: u8, _handle: DynamicVertex_Buffer_Handle, _access: Access) ---

    @(link_name="bgfx_encoder_set_compute_indirect_buffer")
    encoder_set_compute_indirect_buffer :: proc "c" (_this: ^Encoder, _stage: u8, _handle: IndirectBufferHandle, _access: Access) ---

    @(link_name="bgfx_encoder_set_image")
    encoder_set_image :: proc "c" (_this: ^Encoder, _stage: u8, _handle: Texture_Handle, _mip: u8, _access: Access, _format: Texture_Format) ---

    @(link_name="bgfx_encoder_dispatch")
    encoder_dispatch :: proc "c" (_this: ^Encoder, _id: View_ID, _program: Program_Handle, _numX: u32, _numY: u32, _numZ: u32, _flags: u8) ---

    @(link_name="bgfx_encoder_dispatch_indirect")
    encoder_dispatch_indirect :: proc "c" (_this: ^Encoder, _id: View_ID, _program: Program_Handle, _indirectHandle: IndirectBufferHandle, _start: u16, _num: u16, _flags: u8) ---

    @(link_name="bgfx_encoder_discard")
    encoder_discard :: proc "c" (_this:^Encoder,_flags :u8) ---

    @(link_name="bgfx_encoder_blit")
    encoder_blit :: proc "c" (_this:^Encoder,_id :View_ID,_dst :Texture_Handle,_dstMip :u8,_dstX :u16,_dstY :u16,_dstZ :u16,_src :Texture_Handle,_srcMip :u8,_srcX :u16,_srcY :u16,_srcZ :u16,_width :u16,_height :u16,_depth :u16) ---

    @(link_name="bgfx_request_screen_shot")
    request_screen_shot :: proc "c" (_handle: Frame_Buffer_Handle, _filePath: cstring) ---

    @(link_name="bgfx_render_frame")
    render_frame :: proc "c" (_msecs:i32) -> RenderFrame ---

    @(link_name="bgfx_set_platform_data")
    set_platform_data :: proc "c" (_data: ^Platform_Data) ---

    @(link_name="bgfx_get_internal_data")
    get_internal_data :: proc "c" () -> ^InternalData ---

    @(link_name="bgfx_override_internal_texture_ptr")
    override_internal_texture_ptr :: proc "c" (_handle: Texture_Handle, _ptr: rawptr) -> rawptr ---

    @(link_name="bgfx_override_internal_texture")
    override_internal_texture :: proc "c" (_handle: Texture_Handle, _width: u16, _height: u16, _numMips: u8, _format: Texture_Format, _flags: u64) -> rawptr ---

    @(link_name="bgfx_set_marker")
    set_marker :: proc "c" (_marker: cstring) ---

    @(link_name="bgfx_set_state")
    set_state :: proc "c" (_state: u64, _rgba: u32) ---

    @(link_name="bgfx_set_condition")
    set_condition :: proc "c" (_handle: OcclusionQueryHandle, _visible: b8) ---

    @(link_name="bgfx_set_stencil")
    set_stencil :: proc "c" (_fstencil: u32, _bstencil: u32) ---

    @(link_name="bgfx_set_scissor")
    set_scissor :: proc "c" (_x: u16, _y: u16, _width: u16, _height: u16) -> u16 ---

    @(link_name="bgfx_set_scissor_cached")
    set_scissor_cached :: proc "c" (_cache: u16) ---

    @(link_name="bgfx_set_transform")
    set_transform :: proc "c" (_mtx: rawptr, _num: u16) -> u32 ---

    @(link_name="bgfx_set_transform_cached")
    set_transform_cached :: proc "c" (_cache: u32, _num: u16) ---

    @(link_name="bgfx_alloc_transform")
    alloc_transform :: proc "c" (_transform: ^Transform, _num: u16) -> u32 ---

    @(link_name="bgfx_set_uniform")
    set_uniform :: proc "c" (_handle: Uniform_Handle, _value: rawptr, _num: u16) ---

    @(link_name="bgfx_set_index_buffer")
    set_index_buffer :: proc "c" (_handle: Index_Buffer_Handle, _firstIndex: u32, _numIndices: u32) ---

    @(link_name="bgfx_set_dynamic_index_buffer")
    set_dynamic_index_buffer :: proc "c" (_handle: DynamicIndex_Buffer_Handle, _firstIndex: u32, _numIndices: u32) ---

    @(link_name="bgfx_set_transient_index_buffer")
    set_transient_index_buffer :: proc "c" (_tib: ^TransientIndexBuffer, _firstIndex: u32, _numIndices: u32) ---

    @(link_name="bgfx_set_vertex_buffer")
    set_vertex_buffer :: proc "c" (_stream: u8, _handle: Vertex_Buffer_Handle, _startVertex: u32, _numVertices: u32) ---

    @(link_name="bgfx_set_vertex_buffer_with_layout")
    set_vertex_buffer_with_layout :: proc "c" (_stream: u8, _handle: Vertex_Buffer_Handle, _startVertex: u32, _numVertices: u32, _layoutHandle: Vertex_Layout_Handle) ---

    @(link_name="bgfx_set_dynamic_vertex_buffer")
    set_dynamic_vertex_buffer :: proc "c" (_stream :u8,_handle :DynamicVertex_Buffer_Handle,_startVertex :u32,_numVertices :u32) ---

    @(link_name="bgfx_set_dynamic_vertex_buffer_with_layout")
    set_dynamic_vertex_buffer_with_layout :: proc "c" (_stream: u8, _handle: DynamicVertex_Buffer_Handle, _startVertex: u32, _numVertices: u32, _layoutHandle: Vertex_Layout_Handle) ---

    @(link_name="bgfx_set_transient_vertex_buffer")
    set_transient_vertex_buffer :: proc "c" (_stream: u8, _tvb: ^TransientVertexBuffer, _startVertex: u32, _numVertices: u32) ---

    @(link_name="bgfx_set_transient_vertex_buffer_with_layout")
    set_transient_vertex_buffer_with_layout :: proc "c" (_stream: u8, _tvb: ^TransientVertexBuffer, _startVertex: u32, _numVertices: u32, _layoutHandle: Vertex_Layout_Handle) ---

    @(link_name="bgfx_set_vertex_count")
    set_vertex_count :: proc "c" (_numVertices: u32) ---

    @(link_name="bgfx_set_instance_data_buffer")
    set_instance_data_buffer :: proc "c" (_idb: ^InstanceDataBuffer, _start: u32, _num: u32) ---

    @(link_name="bgfx_set_instance_data_from_vertex_buffer")
    set_instance_data_from_vertex_buffer :: proc "c" (_handle: Vertex_Buffer_Handle, _startVertex: u32, _num: u32) ---

    @(link_name="bgfx_set_instance_data_from_dynamic_vertex_buffer")
    set_instance_data_from_dynamic_vertex_buffer :: proc "c" (_handle: DynamicVertex_Buffer_Handle, _startVertex: u32, _num: u32) ---

    @(link_name="bgfx_set_instance_count")
    set_instance_count :: proc "c" (_numInstances :u32) ---

    @(link_name="bgfx_set_texture")
    set_texture :: proc "c" (_stage :u8,_sampler :Uniform_Handle,_handle :Texture_Handle,_flags :u32) ---

    @(link_name="bgfx_touch")
    touch :: proc "c" (_id :View_ID) ---

    @(link_name="bgfx_submit")
    submit :: proc "c" (_id: View_ID, _program: Program_Handle, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_submit_occlusion_query")
    submit_occlusion_query :: proc "c" (_id: View_ID, _program: Program_Handle, _occlusionQuery: OcclusionQueryHandle, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_submit_indirect")
    submit_indirect :: proc "c" (_id: View_ID, _program: Program_Handle, _indirectHandle: IndirectBufferHandle, _start: u16, _num: u16, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_submit_indirect_count")
    submit_indirect_count :: proc "c" (_id: View_ID, _program: Program_Handle, _indirectHandle: IndirectBufferHandle, _start: u16, _numHandle: Index_Buffer_Handle, _numIndex: u32, _numMax: u16, _depth: u32, _flags: u8) ---

    @(link_name="bgfx_set_compute_index_buffer")
    set_compute_index_buffer :: proc "c" (_stage :u8,_handle :Index_Buffer_Handle,_access :Access) ---

    @(link_name="bgfx_set_compute_vertex_buffer")
    set_compute_vertex_buffer :: proc "c" (_stage :u8,_handle :Vertex_Buffer_Handle,_access :Access) ---

    @(link_name="bgfx_set_compute_dynamic_index_buffer")
    set_compute_dynamic_index_buffer :: proc "c" (_stage :u8,_handle :DynamicIndex_Buffer_Handle,_access :Access) ---

    @(link_name="bgfx_set_compute_dynamic_vertex_buffer")
    set_compute_dynamic_vertex_buffer :: proc "c" (_stage :u8,_handle :DynamicVertex_Buffer_Handle,_access :Access) ---

    @(link_name="bgfx_set_compute_indirect_buffer")
    set_compute_indirect_buffer :: proc "c" (_stage :u8,_handle :IndirectBufferHandle,_access :Access) ---

    @(link_name="bgfx_set_image")
    set_image :: proc "c" (_stage :u8,_handle :Texture_Handle,_mip :u8,_access :Access,_format :Texture_Format) ---

    @(link_name="bgfx_dispatch")
    dispatch :: proc "c" (_id: View_ID, _program: Program_Handle, _numX: u32, _numY: u32, _numZ: u32, _flags: u8) ---

    @(link_name="bgfx_dispatch_indirect")
    dispatch_indirect :: proc "c" (_id: View_ID, _program: Program_Handle, _indirectHandle: IndirectBufferHandle, _start: u16, _num: u16, _flags: u8) ---

    @(link_name="bgfx_discard")
    discard :: proc "c" (_flags :u8) ---

    @(link_name="bgfx_blit")
    blit :: proc "c" (_id :View_ID,_dst :Texture_Handle,_dstMip :u8,_dstX :u16,_dstY :u16,_dstZ :u16,_src :Texture_Handle,_srcMip :u8,_srcX :u16,_srcY :u16,_srcZ :u16,_width :u16,_height :u16,_depth :u16) ---
}

handle_is_valid :: proc "contextless" (handle: Handle) -> bool
{
	return handle != INVALID_HANDLE
}