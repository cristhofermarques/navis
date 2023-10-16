package reactphysics3d

when #config(RP3D_F64, false)
{
    Decimal :: f64
    Quaternion :: quaternion256
}
else
{
    Decimal :: f32
    Quaternion :: quaternion128
}

Vector2 :: [2]Decimal
Vector3 :: [2]Decimal

Transform :: struct
{
    position: Vector3,
    rotation: Quaternion,
}

World_Settings :: struct
{
    world_name: cstring,
    gravity: Vector3,
    persistent_contact_distance_threshold: Decimal,
    default_friction_coefficient: Decimal,
    default_bounciness: Decimal,
    restitution_velocity_threshold: Decimal,
    is_sleeping_enabled: bool,
    default_velocity_solver_nb_iterations: u16,
    default_position_solver_nb_iterations: u16,
    default_time_before_sleep: f32,
    default_sleep_linear_velocity: Decimal,
    default_sleep_angular_velocity: Decimal,
    cos_angle_similar_contact_manifold: Decimal,
}

Physics_Common :: rawptr
Physics_World :: rawptr
Sphere_Shape :: rawptr
Box_Shape :: rawptr
Capsule_Shape :: rawptr
Collision_Body :: rawptr
Rigid_Body :: rawptr

RP3D_F64 :: #config(RP3D_F64, false)

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && ODIN_DEBUG && !RP3D_F64 do foreign import rp3d {
    "binaries/rp3d_windows_amd64_debug_f32.lib",
    "binaries/crp3d_windows_amd64_debug_f32.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && !ODIN_DEBUG && !RP3D_F64 do foreign import rp3d {
    "binaries/rp3d_windows_amd64_release_f32.lib",
    "binaries/crp3d_windows_amd64_release_f32.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && ODIN_DEBUG && RP3D_F64 do foreign import rp3d {
    "binaries/rp3d_windows_amd64_debug_f64.lib",
    "binaries/crp3d_windows_amd64_debug_f64.lib",
}

when ODIN_OS == .Windows && ODIN_ARCH == .amd64 && !ODIN_DEBUG && RP3D_F64 do foreign import rp3d {
    "binaries/rp3d_windows_amd64_release_f64.lib",
    "binaries/crp3d_windows_amd64_release_f64.lib",
}

foreign rp3d
{    
    physics_common_create :: proc "c" () -> Physics_Common ---
    physics_common_destroy :: proc "c" (common: Physics_Common) ---
    physics_common_create_world :: proc "c" (common: Physics_Common, settings: ^World_Settings) -> Physics_World ---
    physics_common_destroy_world :: proc "c" (common: Physics_Common, world: Physics_World) ---
    physics_common_create_sphere_shape :: proc "c" (common: Physics_Common, radius: Decimal) -> Sphere_Shape ---
    physics_common_destroy_sphere_shape :: proc "c" (common: Physics_Common, shape: Sphere_Shape) ---
    physics_common_create_box_shape :: proc "c" (common: Physics_Common, extent: Vector3) -> Box_Shape ---
    physics_common_destroy_box_shape :: proc "c" (common: Physics_Common, shape: Box_Shape) ---
    physics_common_create_capsule_shape :: proc "c" (common: Physics_Common, radius, height: Decimal) -> Capsule_Shape ---
    physics_common_destroy_capsule_shape :: proc "c" (common: Physics_Common, shape: Capsule_Shape) ---

    physics_world_create_collision_body :: proc "c" (world: Physics_World, transform: Transform) -> Collision_Body ---
    physics_world_destroy_collision_body :: proc "c" (world: Physics_World, body: Collision_Body) ---
    physics_world_get_name :: proc "c" (world: Physics_World) -> cstring ---
    physics_world_create_rigid_body :: proc "c" (world: Physics_World, transform: Transform) -> Rigid_Body ---
    physics_world_destroy_rigid_body :: proc "c" (world: Physics_World, body: Rigid_Body) ---
}