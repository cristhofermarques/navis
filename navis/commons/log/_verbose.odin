package navis_log

import "navis:api"
import "core:log"

VERBOSE_FAIL_SEPARATOR :: " "

verbose_debug :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    when api.VERBOSE do log.debug(args = args, sep = sep, location = location)
}

verbose_info :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    when api.VERBOSE do log.info(args = args, sep = sep, location = location)
}

verbose_warn :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    when api.VERBOSE do log.warn(args = args, sep = sep, location = location)
}

verbose_error :: #force_inline proc(args: ..any, sep := " ", location := #caller_location)
{
    when api.VERBOSE do log.error(args = args, sep = sep, location = location)
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