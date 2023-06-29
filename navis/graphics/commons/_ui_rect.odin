package graphics_commons

Rect_U32 :: distinct Rect(u32)
Rect_I32 :: distinct Rect(i32)
Rect_F32 :: distinct Rect(f32)
Rect_F64 :: distinct Rect(f64)

Rect :: struct($T: typeid) {x, y, width, height: T}
