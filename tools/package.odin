package tools

import "../navis/pkg"
import "core:io"
import "core:os"
import "core:strings"
import "core:path/filepath"

package_pack :: proc(diretory_path, package_name: string)
{
    if !os.is_dir(diretory_path) do return
    out_directory := cli_get_out_directory(context.temp_allocator)
    name := package_name == "" ? filepath.base(diretory_path) : package_name
    package_filename, pf_err := strings.join({name, pkg.EXTENSION}, "", context.temp_allocator)
    package_path := filepath.join({out_directory, package_filename}, context.temp_allocator)

    handle, handle_err := os.open(package_path, os.is_file(package_path) ? os.O_WRONLY : os.O_WRONLY | os.O_CREATE)
    if handle_err != os.ERROR_NONE do return
    defer os.close(handle)

    stream := os.stream_from_handle(handle)
    pkg.pack_directory(diretory_path, package_name, stream)
}