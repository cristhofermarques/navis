package sandbox

import "navis:."
import "navis:ecs"
import "navis:pkg"
import "navis:mem"
import "navis:bff"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:thread"
import "core:bytes"

EDITOR_PACKAGE :: "editor"

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
    desc.shaders_chunk_capacity = 10
    desc.shaders_map_initial_capacity = 10
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

    navis.streamer_require_asset("shader", on_asset_load)
}

on_asset_load :: proc(asset: ^pkg.Asset, user_data: rawptr)
{
    fmt.println("laoded asset shader")
    navis.streamer_dispose_asset("shader", 2)
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
    abc: int,
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