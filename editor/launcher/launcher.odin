package sandbox

import "navis:."
import "core:log"
import "core:fmt"

My_Component :: struct
{
    pos: navis.vec3,
}

main :: proc()
{
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    // ecs: navis.ECS
    // navis.ecs_init(&ecs, 64, context.temp_allocator)
    // defer navis.ecs_delete(&ecs)

    // navis.ecs_register_component_from_navis(&ecs, My_Component)
    // fmt.println(ecs)
    // fmt.println(navis.ecs_has_component_by_name(&ecs, "My_Component"))
    // fmt.println(navis.ecs_has_component_by_name(&ecs, "Your_Component"))

    navis.run("editor")
}