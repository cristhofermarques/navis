package sandbox

import "navis:."
import "navis:ecs"
import "navis:mem"
import "core:strings"
import "core:os"
import "core:fmt"
import "core:time"

@(export, link_name=navis.MODULE_ON_CREATE_WINDOW)
on_create_window :: proc(desc: ^navis.Window_Descriptor, allocator := context.allocator)
{
    desc.title = strings.clone("Navis Editor", allocator)
    desc.size = {600, 400}
    desc.type = .Windowed
}

@(export, link_name=navis.MODULE_ON_CREATE_RENDERER)
on_create_renderer :: proc(desc: ^navis.Renderer_Descriptor)
{
    desc.renderer_type = .Vulkan
    desc.vsync = true
}

@(export, link_name=navis.MODULE_ON_BEGIN)
on_begin :: proc()
{
    fmt.println("Begin")
    
    navis.application.graphics.renderer.view.id = 0
    navis.application.graphics.renderer.view.clear.flags = {.Color, .Depth}
    navis.application.graphics.renderer.view.clear.color = {255, 255, 55, 55}
    navis.application.graphics.renderer.view.clear.depth = 1
    navis.application.graphics.renderer.view.rect.ratio = .Equal
    navis.renderer_refresh()

    p_ecs := &navis.application.ecs

    fmt.println("Registered", ecs.name_of(Colorize), "Archetype :", ecs.register_archetype(&navis.application.ecs, ecs.Archetype_Descriptor(Colorize){100_000, colorize_chunk_init, colorize_chunk_destroy, colorize_chunk_sub_allocate, colorize_chunk_free}))
    fmt.println("Registered", ecs.name_of(Colorize), "System :", ecs.register_collection_system(&navis.application.ecs, colorize_collection_system, 0))
    fmt.println("Registered", ecs.name_of(Colorize), "System :", ecs.register_chunk_system(&navis.application.ecs, colorize_chunk_system, 0))

    t1 := time.now()
    for i in 1..=1_000_000
    {
        ecs.create_entity(p_ecs)
        //ecs.add_archetype(p_ecs, Colorize, entt)
    }
    fmt.println(time.duration_milliseconds(time.diff(t1, time.now())), "ms")

    for i in 1..=10
    {
        t0 := time.now()
        for k, &a in p_ecs.archetypes do ecs.archetype_logic_update(&a)
        fmt.println(time.duration_milliseconds(time.diff(t0, time.now())), "ms")
    }

    fmt.println(p_ecs.entities.sub_allocations)

    //Testing mem package
    cc := mem.raw_soa_collection_make(mem.SOA_Collection_Descriptor(My_Type, 2){10, my_type_chunk_init, my_type_chunk_destroy, my_type_chunk_sub_allocate, my_type_chunk_free})
    if mem.raw_soa_collection_init(&cc)
    {
        defer mem.raw_soa_collection_destroy(&cc)
        id := mem.raw_soa_collection_sub_allocate(&cc)
        mem.raw_soa_collection_free(&cc, id)
        fmt.println(cc)
    }
}

@(export, link_name=navis.MODULE_ON_END)
on_end :: proc()
{
    fmt.println("End")
}

Colorize :: struct
{
    __used: ecs.Chunk_Element_Used,
    __entity_id: ecs.Entity_ID,
    color: #simd[4]f32,
}

colorize_chunk_init :: proc(chunk: ^ecs.Chunk(Colorize), capacity: int, allocator := context.allocator) -> bool
{
    return ecs.chunk_init(chunk, capacity, allocator)
}

colorize_chunk_destroy :: proc(chunk: ^ecs.Chunk(Colorize), allocator := context.allocator) -> bool
{
    return ecs.chunk_destroy(chunk, allocator)
}

colorize_chunk_sub_allocate :: proc "contextless" (chunk: ^ecs.Chunk(Colorize)) -> int
{
    return ecs.chunk_sub_allocate(chunk)
}

colorize_chunk_free :: proc "contextless" (chunk: ^ecs.Chunk(Colorize), index: int) -> bool
{
    return ecs.chunk_free(chunk, index)
}

colorize_collection_system :: proc(collection: ^ecs.Collection(Colorize))
{
}

colorize_chunk_system :: proc(chunk: ^ecs.Chunk(Colorize))
{
    a := #simd[4]f32{1, 2, 3, 4}
    b := #simd[4]f32{1.666, 1.666, 1.666, 1.666}

    updated, to_updated := 0, 0
    content := ecs.chunk_content(chunk)
    for &colorize in content
    {
        if ecs.can_continue(colorize.__used) do continue
        colorize.color = colorize.color * a * b
        if ecs.can_break(updated, to_updated) do break
    }
}

My_Type :: struct
{
    __used: mem.SOA_Chunk_Element_Used,
    color: #simd[4]f32,
}

my_type_chunk_init :: proc(chunk: ^mem.SOA_Chunk(My_Type, 2), capacity: int, allocator := context.allocator) -> bool
{
    return mem.soa_chunk_init(chunk, capacity, allocator)
}

my_type_chunk_destroy :: proc(chunk: ^mem.SOA_Chunk(My_Type, 2), allocator := context.allocator) -> bool
{
    return mem.soa_chunk_destroy(chunk, allocator)
}

my_type_chunk_sub_allocate :: proc "contextless" (chunk: ^mem.SOA_Chunk(My_Type, 2)) -> int
{
    return mem.soa_chunk_sub_allocate(chunk)
}

my_type_chunk_free :: proc "contextless" (chunk: ^mem.SOA_Chunk(My_Type, 2), index: int) -> bool
{
    return mem.soa_chunk_free(chunk, index)
}