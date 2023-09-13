package navis_log

import "core:log"

@(private)
VERBOSE :: #config(NAVIS_VERBOSE, true)

@(disabled=!ODIN_DEBUG)
debug :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.debug(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
info :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.info(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
warn :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.warn(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
error :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.error(args = args, sep = sep, location = location)
}

@(disabled=!ODIN_DEBUG)
fatal :: proc(args: ..any, sep := " ", location := #caller_location)
{
    log.fatal(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
verbose_debug :: proc(args: ..any, sep := " ", location := #caller_location)
{
    debug(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
verbose_info :: proc(args: ..any, sep := " ", location := #caller_location)
{
    info(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
verbose_warn :: proc(args: ..any, sep := " ", location := #caller_location)
{
    warn(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
verbose_error :: proc(args: ..any, sep := " ", location := #caller_location)
{
    error(args = args, sep = sep, location = location)
}

@(disabled=!VERBOSE)
verbose_fatal :: proc(args: ..any, sep := " ", location := #caller_location)
{
    fatal(args = args, sep = sep, location = location)
}