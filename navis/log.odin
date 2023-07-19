package navis

import "core:log"

@(disabled=!ODIN_DEBUG)
log_debug :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.debug(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
log_info :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.info(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
log_warn :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.warn(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
log_error :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.error(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
log_fatal :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.fatal(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
log_verbose_debug :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log_debug(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
log_verbose_info :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log_info(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
log_verbose_warn :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log_warn(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
log_verbose_error :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log_error(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
log_verbose_fatal :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log_fatal(args = args, sep = sep, location = location)
}