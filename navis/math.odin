package navis

import linear_algebra "core:math/linalg"

/*
Nickname for core:linalg.Quaternionf32.
*/
Quaternion :: linear_algebra.Quaternionf32
quat :: linear_algebra.Quaternionf32

/*
Nickname for core:linalg.Matrix2x2f32
*/
Matrix2x2 :: linear_algebra.Matrix2x2f32
mat2_f32 :: linear_algebra.Matrix2x2f32
mat2_f64 :: linear_algebra.Matrix2x2f64

/*
Nickname for core:linalg.Matrix3x3f32
*/
Matrix3x3 :: linear_algebra.Matrix3x3f32
mat3_f32 :: linear_algebra.Matrix3x3f32
mat3_f64 :: linear_algebra.Matrix3x3f64

/*
Nickname for core:linalg.Matrix4x4f32
*/
Matrix4x4 :: linear_algebra.Matrix4x4f32
mat4_f32 :: linear_algebra.Matrix4x4f32
mat4_f64 :: linear_algebra.Matrix4x4f64

/*
Nickname for core:linalg.Vector2f32
*/
Vector2_F32 :: linear_algebra.Vector2f32
vec2_f32 :: linear_algebra.Vector2f32

/*
Nickname for core:linalg.Vector2f64
*/
Vector2_F64 :: linear_algebra.Vector2f64
vec2_f64 :: linear_algebra.Vector2f64

/*
Nickname for core:linalg.Vector3f32
*/
Vector3_F32 :: linear_algebra.Vector3f32
vec3_f32 :: linear_algebra.Vector3f32

/*
Nickname for core:linalg.Vector3f64
*/
Vector3_F64 :: linear_algebra.Vector3f64
vec3_f64 :: linear_algebra.Vector3f64

/*
Nickname for core:linalg.Vector4f32
*/
Vector4_F32 :: linear_algebra.Vector4f32
vec4_f32 :: linear_algebra.Vector4f32

/*
Nickname for core:linalg.Vector4f64
*/
Vector4_F64 :: linear_algebra.Vector4f64
vec4_f64 :: linear_algebra.Vector4f64

Vector2_I32 :: [2]i32

vec2_i32 :: [2]i32
vec2_i64 :: [2]i64
vec2_u32 :: [2]u32
vec2_u64 :: [2]u64

vec3_i32 :: [3]i32
vec3_i64 :: [3]i64
vec3_u32 :: [3]u32
vec3_u64 :: [3]u64

vec4_i32 :: [4]i32
vec4_i64 :: [4]i64
vec4_u32 :: [4]u32
vec4_u64 :: [4]u64

when PRECISION_32
{
    Vector2 :: Vector2_F32
    Vector3 :: Vector3_F32
    Vector4 :: Vector4_F32

    vec2 :: vec2_f32
    vec3 :: vec3_f32
    vec4 :: vec4_f32
}

when PRECISION_64
{
    Vector2 :: Vector2_F64
    Vector3 :: Vector3_F64
    Vector4 :: Vector4_F64

    vec2 :: vec2_f64
    vec3 :: vec3_f64
    vec4 :: vec4_f64
}

/*
Nickname for core:linalg.cross
*/
math_cross :: linear_algebra.cross

/*
Nickname for core:linalg.distance
*/
math_distance :: linear_algebra.distance

/*
Nickname for core:linalg.dot
*/
math_dot :: linear_algebra.dot

math_clamp :: linear_algebra.clamp