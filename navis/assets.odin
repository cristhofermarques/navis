package navis

import "bff"

Shader_Asset_Entry :: struct
{
    vertex, fragment: []byte,
}

Shader_Asset :: struct
{
    glsl_120,
    glsl_130,
    glsl_140,
    glsl_150,
    glsl_330,
    glsl_400,
    glsl_410,
    glsl_420,
    glsl_430,
    glsl_440,
    glsl_100_es,
    glsl_300_es,
    glsl_310_es,
    glsl_320_es,
    hlsl_s_3_0,
    hlsl_s_4_0,
    hlsl_s_5_0,
    metal,
    pssl,
    spirv,
    spirv_10_10,
    spirv_13_11,
    spirv_14_11,
    spirv_15_12,
    spirv_16_13: Shader_Asset_Entry,
}

/*
*/
shader_asset_create :: proc{
    shader_asset_create_from_bff,
}

/*
NOTE(cris): there is no allocation.
*/
shader_asset_create_from_bff :: proc(data: []byte) -> Shader_Asset
{
    asset: Shader_Asset
    bff.unmarshal(data, &asset)
    return asset
}