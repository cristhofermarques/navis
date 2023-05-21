package shaderc

Target_Env :: enum 
{
    Vulkan,
    OpenGL,
    OpenGL_Compat,
    Web_GPU,
}
  
Env_Version :: enum
{
    Vulkan_1_0 = ((1 << 22)),
    Vulkan_1_1 = ((1 << 22) | (1 << 12)),
    Vulkan_1_2 = ((1 << 22) | (2 << 12)),
    Vulkan_1_3 = ((1 << 22) | (3 << 12)),
    OpenGL_4_5 = 450,
    Web_GPU,
}

SPIRV_Version :: enum
{
    _1_0 = 0x010000,
    _1_1 = 0x010100,
    _1_2 = 0x010200,
    _1_3 = 0x010300,
    _1_4 = 0x010400,
    _1_5 = 0x010500,
    _1_6 = 0x010600,
}