package sandbox

import "navis:."
import "navis:ecs"
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

    COUNT :: 1_000_000
    ids := make([]ecs.Entity_ID, COUNT, context.temp_allocator)
    
    t0 := time.now()
    for &id in ids
    {
        id = navis.create_entity()
    }
    fmt.println("Created", navis.application.ecs.entities.sub_allocations, "Empty Entities in", time.duration_milliseconds((time.diff(t0, time.now()))), "ms")
    fmt.println("Total Chunks", len(navis.application.ecs.entities.chunks.content), "with Capacity of", navis.application.ecs.entities.chunk_capacity)

    t1 := time.now()
    for id in ids
    {
        navis.destroy_entity(id)
    }
    fmt.println("Destroyed", navis.application.ecs.entities.sub_allocations, "Empty Entities in", time.duration_milliseconds((time.diff(t1, time.now()))), "ms")
    fmt.println("Total Chunks", len(navis.application.ecs.entities.chunks.content), "with Capacity of", navis.application.ecs.entities.chunk_capacity)
}

@(export, link_name=navis.MODULE_ON_END)
on_end :: proc()
{
    fmt.println("End")
}

Colorize :: struct
{
    _element: ecs.Chunk_Element,
    _entity_id: ecs.Entity_ID,
    color: [4]byte,
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