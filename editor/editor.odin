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

    fmt.println("Registered", ecs.name_of(Colorize), "Archetype :", ecs.register_archetype(&navis.application.ecs, ecs.Archetype_Descriptor(Colorize){1_000, colorize_chunk_init, colorize_chunk_destroy, colorize_chunk_sub_allocate, colorize_chunk_free}))
    fmt.println("Registered", ecs.name_of(Colorize), "System :", ecs.register_collection_system(&navis.application.ecs, colorize_collection_system, 0))
    fmt.println("Archetype", ecs.name_of(Colorize), ":", navis.application.ecs.archetypes[ecs.name_of(Colorize)])
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

colorize_collection_system :: proc(collection: ^ecs.Collection(Colorize))
{   
}