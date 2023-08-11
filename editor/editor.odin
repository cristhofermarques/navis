package sandbox

import "navis:."
import "navis:ecs"
import "core:strings"
import "core:os"
import "core:fmt"

@(export, link_name=navis.MODULE_ON_CREATE_WINDOW)
on_create_window :: proc(desc: ^navis.Window_Descriptor, allocator := context.allocator)
{
    desc.title = strings.clone("Navis Editor", allocator)
    desc.width = 600
    desc.height = 480
    desc.type_ = .Windowed
}

@(export, link_name=navis.MODULE_ON_CREATE_RENDERER)
on_create_renderer :: proc(desc: ^navis.Renderer_Descriptor)
{
    desc.renderer_type = .Vulkan
    desc.vsync = false
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

    ecs_: ecs.ECS
    if !ecs.init(&ecs_, 1_000) do return
    defer ecs.destroy(&ecs_)

    fmt.println("Registered", ecs.name_of(Colorize), ecs.register_archetype(&ecs_, ecs.Collection_Descriptor(Colorize){1, colorize_chunk_init, colorize_chunk_destroy, colorize_chunk_sub_allocate, colorize_chunk_free}))
}

@(export, link_name=navis.MODULE_ON_END)
on_end :: proc()
{
    fmt.println("End")
}

Colorize :: struct
{
    _element: ecs.Chunk_Element,
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