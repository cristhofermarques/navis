package tools

import "core:os"
import "core:strings"

cli_has_flag :: proc(name: string, begin_char := "-") -> int
{
    flag := strings.concatenate({begin_char, name}, context.temp_allocator)
    for a, i in os.args do if strings.contains(a, flag) do return i
    return -1
}

cli_has_value_flag :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> int
{
    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    for a, i in os.args do if strings.contains(a, flag) && !strings.contains(a, pair_char) do return i
    return -1
}

cli_has_pair_flag :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> int
{
    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    for a, i in os.args do if strings.contains(a, flag) && strings.contains(a, pair_char) do return i
    return -1
}

cli_has_pair_flag_list :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> bool
{
    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    pairs_count := 0
    for a, i in os.args do if strings.contains(a, flag) && strings.contains(a, pair_char) do pairs_count += 1
    return pairs_count > 1
}

cli_get_value_flag :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> (string, string)
{
    argument_index := cli_has_value_flag(name, begin_char, assign_char, pair_char)
    if argument_index < 0 do return "", ""

    argument := os.args[argument_index]
    assign_character_index := strings.index(argument, assign_char)
    if assign_character_index < 0 do return "", ""

    flag := argument[1:assign_character_index]
    value := argument[assign_character_index + 1:]
    return flag, value
}

cli_get_pair_flag :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> (string, string, string)
{
    argument_index := cli_has_pair_flag(name, begin_char, assign_char, pair_char)
    if argument_index < 0 do return "", "", ""

    argument := os.args[argument_index]
    assign_character_index := strings.index(argument, assign_char)
    if assign_character_index < 0 do return "", "", ""
    
    pair_character_index := strings.index(argument, pair_char)
    if pair_character_index < 0 do return "", "", ""

    flag := argument[1:assign_character_index]
    key := argument[assign_character_index + 1: pair_character_index]
    value := argument[pair_character_index + 1:]
    return flag, key, value
}

cli_get_out_directory :: proc(allocator := context.allocator) -> string
{
    if cli_has_value_flag("out-directory") > -1
    {
        flag, val := cli_get_value_flag("out-directory")
        return strings.clone(val, allocator)
    }
    else do return os.get_current_directory(context.allocator)
}