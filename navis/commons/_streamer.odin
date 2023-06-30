package commons

Asset :: struct
{
    data: rawptr,
    size: uint,
}

Streamer :: struct
{
    table: map[string]^Asset,
}