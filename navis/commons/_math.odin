package commons

import "navis:api"

import linear_algebra "core:math/linalg"

/*
Nickname for core:linalg.Quaternionf32.
*/
Quaternion :: linear_algebra.Quaternionf32

/*
Nickname for core:linalg.Matrix2x2f32
*/
Matrix2x2 :: linear_algebra.Matrix2x2f32

/*
Nickname for core:linalg.Matrix3x3f32
*/
Matrix3x3 :: linear_algebra.Matrix3x3f32

/*
Nickname for core:linalg.Matrix4x4f32
*/
Matrix4x4 :: linear_algebra.Matrix4x4f32

/*
Nickname for core:linalg.Vector2f32
*/
Vector2_F32 :: linear_algebra.Vector2f32

/*
Nickname for core:linalg.Vector2f64
*/
Vector2_F64 :: linear_algebra.Vector2f64

/*
Nickname for core:linalg.Vector3f32
*/
Vector3_F32 :: linear_algebra.Vector3f32

/*
Nickname for core:linalg.Vector3f64
*/
Vector3_F64 :: linear_algebra.Vector3f64

/*
Nickname for core:linalg.Vector4f32
*/
Vector4_F32 :: linear_algebra.Vector4f32

/*
Nickname for core:linalg.Vector4f64
*/
Vector4_F64 :: linear_algebra.Vector4f64

when api.PRECISION_32
{
    Vector2 :: Vector2_F32
    Vector3 :: Vector3_F32
    Vector4 :: Vector4_F32
}

when api.PRECISION_64
{
    Vector2 :: Vector2_F64
    Vector3 :: Vector3_F64
    Vector4 :: Vector4_F64
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