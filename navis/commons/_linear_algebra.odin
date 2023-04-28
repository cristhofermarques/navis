package commons

API_PRECISION : Api_Precision : cast(Api_Precision) #config(NAVIS_API_PRECISION, Api_Precision.F32)

API_PRECISION_F32 :: API_PRECISION == .F32
API_PRECISION_F64 :: API_PRECISION == .F64

Api_Precision :: enum
{
    F32,
    F64,
}

import linear_algebra "core:math/linalg"

/*
Nickname for core:linalg.Quaternionf32.
Not Distinct.
*/
Quaternion :: linear_algebra.Quaternionf32

/*
Nickname for core:linalg.Matrix2x2f32
Not Distinct.
*/
Matrix2x2 :: linear_algebra.Matrix2x2f32

/*
Nickname for core:linalg.Matrix3x3f32
Not Distinct.
*/
Matrix3x3 :: linear_algebra.Matrix3x3f32

/*
Nickname for core:linalg.Matrix4x4f32
Not Distinct.
*/
Matrix4x4 :: linear_algebra.Matrix4x4f32

/*
Nickname for core:linalg.Vector2f32
Not Distinct.
*/
Vector2f32 :: linear_algebra.Vector2f32

/*
Nickname for core:linalg.Vector2f64
Not Distinct.
*/
Vector2f64 :: linear_algebra.Vector2f64

/*
Nickname for core:linalg.Vector3f32
Not Distinct.
*/
Vector3f32 :: linear_algebra.Vector3f32

/*
Nickname for core:linalg.Vector3f64
Not Distinct.
*/
Vector3f64 :: linear_algebra.Vector3f64

/*
Nickname for core:linalg.Vector4f32
Not Distinct.
*/
Vector4f32 :: linear_algebra.Vector4f32

/*
Nickname for core:linalg.Vector4f64
Not Distinct.
*/
Vector4f64 :: linear_algebra.Vector4f64

when API_PRECISION_F32
{
    Vector2 :: Vector2f32
    Vector3 :: Vector3f32
    Vector4 :: Vector4f32
}

when API_PRECISION_F64
{
    Vector2 :: Vector2f64
    Vector3 :: Vector3f64
    Vector4 :: Vector4f64
}