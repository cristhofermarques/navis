package navis_log

import "navis:api"
import "core:log"

VERBOSE_FAIL_SEPARATOR :: " "

/*
Verborse log.
* Only execute at verbose builds
*/
@(disabled=!api.VERBOSE)
verbose_log :: #force_inline proc(level: log.Level, args: ..any, sep := " ", location := #caller_location)
{
    log.log(level = level, args = args, sep = sep, location = location)
}

/*
Verborse debug log.
* Only execute at verbose builds
*/
@(disabled=!api.VERBOSE)
verbose_debug :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    log.debug(args = args, sep = sep, location = location)
}

/*
Verborse info log.
* Only execute at verbose builds
*/
@(disabled=!api.VERBOSE)
verbose_info :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    log.info(args = args, sep = sep, location = location)
}

/*
Verborse warn info.
* Only execute at verbose builds
*/
@(disabled=!api.VERBOSE)
verbose_warn :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    log.warn(args = args, sep = sep, location = location)
}

/*
Verborse error info.
* Only execute at verbose builds
*/
@(disabled=!api.VERBOSE)
verbose_error :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    log.error(args = args, sep = sep, location = location)
}

/*
Verborse fatal info.
* Only execute at verbose builds
*/
@(disabled=!api.VERBOSE)
verbose_fatal :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    log.fatal(args = args, sep = sep, location = location)
}

verbose_fail_debug :: #force_inline proc(condition: bool, msg: string, location := #caller_location) -> bool
{
    if condition do verbose_debug(args = {msg}, sep = VERBOSE_FAIL_SEPARATOR, location = location)
    return condition
}

verbose_fail_info :: #force_inline proc(condition: bool, msg: string, location := #caller_location) -> bool
{
    if condition do verbose_info(args = {msg}, sep = VERBOSE_FAIL_SEPARATOR, location = location)
    return condition
}

verbose_fail_warn :: #force_inline proc(condition: bool, msg: string, location := #caller_location) -> bool
{
    if condition do verbose_warn(args = {msg}, sep = VERBOSE_FAIL_SEPARATOR, location = location)
    return condition
}

verbose_fail_error :: #force_inline proc(condition: bool, msg: string, location := #caller_location) -> bool
{
    if condition do verbose_error(args = {msg}, sep = VERBOSE_FAIL_SEPARATOR, location = location)
    return condition
}