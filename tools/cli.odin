package tools

import "core:os"
import "core:fmt"
import "core:strings"

help_text := #load("help.txt", string)

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

cli_has_value_flag_list :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> int
{
    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    values_count := 0
    for a, i in os.args do if strings.contains(a, flag) && !strings.contains(a, pair_char) do values_count += 1
    return values_count
}

cli_has_pair_flag :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> int
{
    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    for a, i in os.args do if strings.contains(a, flag) && strings.contains(a, pair_char) do return i
    return -1
}

cli_has_pair_flag_list :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=") -> int
{
    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    pairs_count := 0
    for a, i in os.args do if strings.contains(a, flag) && strings.contains(a, pair_char) do pairs_count += 1
    return pairs_count
}

cli_unpack_value_flag_argument :: proc(arg: string, assign_char := ":") -> (string, string)
{
    assign_idx := strings.index(arg, assign_char)
    flag := arg[1:assign_idx]
    value := arg[assign_idx+1:]
    return flag, value
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

cli_get_value_flag_list :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=", allocator := context.allocator) -> []string
{
    count := cli_has_value_flag_list(name, begin_char, assign_char, pair_char)
    if count == 0 do return nil

    dv := make([dynamic]string, 0, count, context.temp_allocator)
    defer delete(dv)

    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    for arg, i in os.args do if strings.contains(arg, flag) && !strings.contains(arg, pair_char)
    {
        flag, value := cli_unpack_value_flag_argument(arg, assign_char)
        append(&dv, value)
    }

    values, values_err := make([]string, len(dv), allocator)
    if values_err != .None do return nil
    for v, i in dv do values[i] = v
    return values
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

cli_unpack_pair_flag_argument :: proc(index: int, begin_char := "-", assign_char := ":", pair_char := "=") -> (string, string, string)
{
    arg := os.args[index]
    bi := strings.index(arg, begin_char)
    ai := strings.index(arg, assign_char)
    pi := strings.index(arg, pair_char)

    flag := arg[bi+1:ai]
    key := arg[ai+1:pi]
    value := arg[pi+1:]
    return flag, key, value
}

cli_get_pair_flag_index_list :: proc(name: string, begin_char := "-", assign_char := ":", pair_char := "=", allocator := context.allocator) -> []int
{
    count := cli_has_pair_flag_list(name, begin_char, assign_char, pair_char)
    if count == 0 do return nil

    dv := make([dynamic]int, 0, count, context.temp_allocator)
    defer delete(dv)

    flag := strings.concatenate({begin_char, name, assign_char}, context.temp_allocator)
    for arg, i in os.args do if strings.contains(arg, flag) && strings.contains(arg, pair_char)
    {
        append(&dv, i)
    }

    values, values_err := make([]int, len(dv), allocator)
    if values_err != .None do return nil
    for v, i in dv do values[i] = v
    return values
}

cli_help :: proc() -> bool
{
    if cli_has_flag("help") == -1 do return false
    fmt.println(help_text)
    return true
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