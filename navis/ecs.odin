package navis

// ECS :: struct
// {
//     components_table: map[string]Component_ID,
//     components_infos: map[Component_ID]Component_Info,
//     //components_arenas: map[Component_ID]
// }

// INVALID_ID :: 0

// Component_ID :: uint
// Entity_ID :: uint

// Component_Info :: struct
// {
//     size: int,
// }

// Component :: struct
// {
//     id: Component_ID,
//     data: rawptr,
// }

// ENTITY_MAX_COMPONENTS :: 64
// ENTITY_MAX_SYSTEMS :: 64

// Entity :: struct
// {
//     components: [ENTITY_MAX_COMPONENTS]Component,
// }

// ecs_init :: proc(ecs: ^ECS, components_reserve := 64, allocator := context.allocator)
// {
//     components_table, components_table_allocation_error := make(map[string]string, components_reserve, allocator)
//     if components_table_allocation_error != .None
//     {
//         //TODO(cris): log error
//         return
//     }

//     components_infos, components_infos_allocation_error := make(map[Component_ID]Component_Info, components_reserve, allocator)
//     if components_infos_allocation_error != .None
//     {
//         //TODO(cris): log error
//         delete(components_table)
//         return
//     }

//     ecs.components_table = components_table
//     ecs.components_infos = components_infos
// }

// ecs_delete :: proc(ecs: ^ECS)
// {
//     if ecs == nil do return

//     if ecs.components_table != nil
//     {
//         delete(ecs.components_table)
//         ecs.components_table = nil
//     }

//     if ecs.components_infos != nil
//     {
//         delete(ecs.components_infos)
//         ecs.components_infos = nil
//     }
// }

// ecs_register_component_from_module :: proc(ecs: ^ECS, module: ^Module, $T: typeid)
// {
//     if ecs == nil do return
//     name := module.name_of(T, context.temp_allocator)
//     id := Component_ID(len(ecs.components_table) + 1)
//     info: Component_Info
//     info.size = size_of(T)

//     ecs.components_table[name] = id
//     ecs.components[id] = info
// }

// ecs_has_component_by_name :: proc "contextless" (ecs: ^ECS, name: string) -> bool
// {
//     if ecs == nil do return false
//     return ecs.components_table[name] != INVALID_ID
// }

// ecs_get_component_id_by_name :: proc "contextless" (ecs: ^ECS, name: string) -> Component_ID
// {
//     if ecs == nil do return INVALID_ID
//     return ecs.components_table[name]
// }

// when IMPLEMENTATION
// {
//     @(export=EXPORT, link_name=PREFIX)
//     name_of :: proc(id: typeid, allocator := context.allocator) -> string
//     {
//         return get_name_of(id, allocator)
//     }

//     ecs_register_component_from_navis :: proc(ecs: ^ECS, $T: typeid)
//     {
//         if ecs == nil do return
//         name := name_of(T, context.temp_allocator)
//         id := Component_ID(len(ecs.components_table) + 1)
//         info: Component_Info
//         info.size = size_of(T)
        
//         ecs.components_table[name] = id
//         ecs.components[id] = info
//     }
    
//     @(export=EXPORT, link_name=PREFIX)
//     ecs_register_component_from_module :: proc(ecs: ^ECS, module: ^Module, id: typeid)
//     {
//         if ecs == nil || module == nil do return
//         name := module.name_of(id, context.temp_allocator)
//         id := Component_ID(len(ecs.components_table) + 1)
//         info: Component_Info
//         info.size = size_of(T)
//         ecs.components_table[name] = id
//         ecs.components[id] = info
//     }
// }

// when MODULE
// {
//     ecs_register_component :: proc{
//         ecs_register_component_from_module,
//     }

//     //ecs_register_component_cached :: proc($T: typeid)
// }

import "core:fmt"
get_name_of :: proc(id: typeid, allocator := context.allocator) -> string
{
    context.allocator = allocator
    return fmt.aprint(id)
}