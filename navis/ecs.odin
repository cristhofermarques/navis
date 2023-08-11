/*
Component events.
*/

package navis

import "memory"
import "core:runtime"
import "core:reflect"
import "core:intrinsics"
import "core:sync"
import "core:thread"

MAX_ENTITY_COMPONENTS :: 64

/*
Return the name of type.
*/
name_of :: proc($T: typeid) -> string where intrinsics.type_is_named(T)
{
    info := type_info_of(T)
    named := info.variant.(runtime.Type_Info_Named)
    return named.name
}

Any_Component :: struct
{
    name: string,
    data: rawptr,
}

Entity :: struct
{
    components: memory.Array_Arena(Any_Component, MAX_ENTITY_COMPONENTS),
}

Proc_System :: #type proc(rawptr)

Component_Node :: struct($Component_Type: typeid)
{
    component: Component_Type,
    entity: ^Entity,
    mutex: sync.Atomic_Mutex,
}

Component_Archetype :: struct
{
    component_entity_offset, component_mutex_offset: uintptr,
    on_create, on_destroy: proc(rawptr, ^Entity),
    components: memory.Untyped_Collection,
    systems: [dynamic]Proc_System,
}

component_archetype_create :: proc($T: typeid, arena_capacity: int, components_reserve := 2, systems_reserve := 32, allocator := context.allocator) -> (Component_Archetype, bool)
{
    components, created_components := memory.untyped_collection_create(memory.slot_size_of(Component_Node(T)), memory.slot_data_offset_of(Component_Node(T)), arena_capacity, components_reserve, allocator)
    if !created_components do return {}, false

    systems, systems_allocation_error := make_dynamic_array_len_cap([dynamic]Proc_System, 0, systems_reserve, allocator)
    if systems_allocation_error != .None
    {
        memory.untyped_collection_destroy(&components)
        return {}, false
    } 

    archetype: Component_Archetype
    archetype.component_entity_offset = offset_of(Component_Node(T), entity)
    archetype.component_mutex_offset = offset_of(Component_Node(T), mutex)
    archetype.components = components
    archetype.systems = systems
    return archetype, true
}

component_archetype_destroy :: proc(archetype: ^Component_Archetype) -> bool
{
    if archetype == nil do return false
    memory.untyped_collection_destroy(&archetype.components)
    archetype.components = {}
    delete(archetype.systems)
    archetype.systems = nil
    return true
}

ECS :: struct
{
    allocator: runtime.Allocator,
    entities: memory.Collection(Entity),
    components: map[string]Component_Archetype,
}

ecs_create :: proc(entities_arena_capacity, entities_reserve_count, components_reserve_count: int, allocator := context.allocator) -> (ECS, bool)
{
    entities, created_entities := memory.collection_create(Entity, entities_arena_capacity, entities_reserve_count, allocator)
    if !created_entities do return {}, false

    components, components_allocation_error := make_map(map[string]Component_Archetype, components_reserve_count, allocator)
    if components_allocation_error != .None
    {
        memory.collection_destroy(&entities)
        return {}, false
    }

    ecs: ECS
    ecs.allocator = allocator
    ecs.entities = entities
    ecs.components = components
    return ecs, true
}

ecs_destroy :: proc(ecs: ^ECS)
{
    if ecs == nil do return
    memory.collection_destroy(&ecs.entities)
    for k, v in ecs.components do component_archetype_destroy(&ecs.components[k])
    delete(ecs.components)
    ecs^ = {}
}

ecs_create_entity :: proc(ecs: ^ECS) -> ^Entity
{
    if ecs == nil do return nil
    return memory.collection_sub_allocate(&ecs.entities)
}

ecs_destroy_entity :: proc(ecs: ^ECS, entity: ^Entity) -> bool
{
    if ecs == nil || entity == nil do return false
    memory.collection_free(&ecs.entities, entity)
    return true
}

ecs_entity_has_component :: proc(entity: ^Entity, $T: typeid) -> bool
{
    if entity == nil do return false
    name := name_of(T)
    for &component in entity.components.slots do if component.used && component.data.name == name do return true
    return false
}

ecs_register_component :: proc(ecs: ^ECS, $T: typeid, arena_capacity: int, components_reserve := 2, systems_reserve := 32) -> bool
{
    if ecs == nil do return false
    archetype, created_archetype := component_archetype_create(T, arena_capacity, components_reserve, systems_reserve, ecs.allocator)
    if !created_archetype do return false
    name := name_of(T)
    ecs.components[name] = archetype
    return true
}

ecs_set_component_on_create :: proc(ecs: ^ECS, $T: typeid, on_create: proc(component: ^T, entity: ^Entity)) -> bool
{
    if ecs == nil do return false
    archetype := &ecs.components[name_of(T)]
    if archetype == nil do return false
    archetype.on_create = auto_cast on_create
    return true
}

ecs_set_component_on_destroy :: proc(ecs: ^ECS, $T: typeid, on_destroy: proc(component: ^T, entity: ^Entity)) -> bool
{
    if ecs == nil do return false
    archetype := &ecs.components[name_of(T)]
    if archetype == nil do return false
    archetype.on_destroy = auto_cast on_destroy
    return true
}

ecs_register_system :: proc(ecs: ^ECS, $T: typeid, system: proc(^T)) -> bool
{
    if ecs == nil || system == nil do return false
    archetype := &ecs.components[name_of(T)]
    if dynamic_contains(archetype.systems, Proc_System(system)) do return false
    append(&archetype.systems, Proc_System(system))
    return true
}

ecs_add_component :: proc(ecs: ^ECS, entity: ^Entity, $T: typeid) -> ^T
{
    if entity == nil do return nil

    any_component := memory.array_arena_sub_allocate(&entity.components)
    
    archetype := &ecs.components[name_of(T)]
    node := transmute(^Component_Node(T))memory.untyped_collection_sub_allocate(&archetype.components)
    if node == nil
    {
        memory.array_arena_free(&entity.components, any_component)
        return nil
    }
    
    node.entity = entity
    any_component.name = name_of(T)
    any_component.data = &node.component
    if archetype.on_create != nil do archetype.on_create(&node.component, entity)
    return &node.component
}

ecs_get_components_pointers_as_slice :: proc(ecs: ^ECS, allocator := context.allocator) -> []^Component_Archetype
{
    if ecs == nil do return nil
    count := len(ecs.components)
    if count < 1 do return nil

    slice, slice_allocation_error := make([]^Component_Archetype, count, allocator)
    if slice_allocation_error != .None do return nil
    i := 0
    for k, &v in ecs.components
    {
        slice[i] = &v
        i += 1
    }
    return slice
}

@(private)
amount_distribution :: proc(amount, splits_count: int, allocator := context.allocator) -> []int
{
    if amount < 1 || splits_count < 1 do return nil

    splits_count := amount < splits_count ? amount : splits_count
    splits, splits_allocation_error := make([]int, splits_count, allocator)
    if splits_allocation_error != .None do return nil

    split_seek := 0
    for i := 0; i < amount; i += 1
    {
        splits[split_seek] += 1
        split_seek += 1
        if split_seek >= splits_count do split_seek = 0
    }
    return splits
}

ecs_distribute :: proc(ecs: ^ECS, splits_count: int, allocator := context.allocator) -> []ESC_Update_Task_Data
{
    if ecs == nil || splits_count < 1 do return nil
    archetypes_count := len(ecs.components)
    if archetypes_count < 1 do return nil

    splits_capacities := amount_distribution(archetypes_count, splits_count, context.temp_allocator)
    splits, splits_allocation_error := make([]ESC_Update_Task_Data, len(splits_capacities), allocator)
    components := ecs_get_components_pointers_as_slice(ecs, context.temp_allocator)

    seek := 0
    for split_cap, i in splits_capacities
    {
        split := &splits[i]
        s, s_ae := make([]^Component_Archetype, split_cap, allocator)
        if s_ae != .None do break

        for &s_elem in s
        {
            s_elem = components[seek]
            seek += 1
        }

        splits[i].archetypes = s
    }

    return splits
}

ESC_Update_Task_Data :: struct
{
    archetypes: []^Component_Archetype,
    done: bool,
}

@(private)
ecs_update_task :: proc(task: thread.Task)
{
    data := transmute(^ESC_Update_Task_Data)task.data
    sync.atomic_store(&data.done, false)

    for &archetype in data.archetypes
    {
        uptr_node_entity_offset := archetype.component_entity_offset
        uptr_node_mutex_offset := archetype.component_mutex_offset

        a_updated_count := 0

        for &arena in archetype.components.arenas
        {
            if arena.sub_allocations == 0 do continue

            uptr_data := transmute(uintptr)arena.slots.data
            uptr_slot_size := transmute(uintptr)arena.slot_size
            uptr_slot_data_offset := arena.slot_data_offset

            updated_count := 0
            for i := 0; i < arena.slots.len; i += 1
            {
                uptr_slot_used := uptr_data + (uptr_slot_size * uintptr(i))
                slot_used := transmute(^bool)uptr_slot_used
                if !slot_used^ do continue

                uptr_slot_data := uptr_slot_used + uptr_slot_data_offset

                uptr_node_component := uptr_slot_data
                uptr_node_entity := uptr_node_component + uptr_node_entity_offset
                uptr_node_mutex := uptr_node_component + uptr_node_mutex_offset

                node_component := rawptr(uptr_node_component)
                node_entity := transmute(^Entity)uptr_node_entity
                node_mutex := transmute(^sync.Atomic_Mutex)uptr_node_mutex

                for &system in archetype.systems
                {
                    sync.atomic_mutex_lock(node_mutex)
                    defer sync.atomic_mutex_unlock(node_mutex)
                    
                    system(node_component)
                }

                updated_count += 1
                a_updated_count += 1
                if updated_count == arena.sub_allocations do break
            }

            if a_updated_count == archetype.components.sub_allocations do break
        }
    }

    sync.atomic_store(&data.done, true)
}

ecs_update :: proc(ecs: ^ECS, pool: ^thread.Pool)
{
    if ecs == nil || pool == nil do return

    tasks_datas := ecs_distribute(ecs, len(pool.threads), context.allocator)
    if tasks_datas == nil do return
    defer delete(tasks_datas, context.allocator)
    defer for &d in tasks_datas do delete(d.archetypes, context.allocator)

    for &task_data in tasks_datas
    {
        thread.pool_add_task(pool, context.allocator, ecs_update_task, &task_data)
    }

    for &task_data in tasks_datas
    {
        for !sync.atomic_load(&task_data.done){}
    }

    for thread.pool_num_done(pool) > 0 do thread.pool_pop_done(pool)
}