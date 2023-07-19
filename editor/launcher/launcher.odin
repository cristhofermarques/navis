package sandbox

import "navis:."
import "core:log"

main :: proc()
{
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)
    
    navis.run("editor")
}