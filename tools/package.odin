package tools

import "../navis/pkg"
import "core:io"
import "core:os"
import "core:bytes"
import "core:strings"
import "core:path/filepath"

package_pack :: proc(diretory_path, package_name: string)
{
    buffer: bytes.Buffer
    bytes.buffer_init_allocator(&buffer, 0, 400, context.temp_allocator)
    
    stream: io.Stream
    stream.data = &buffer
    stream.procedure = proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error)
    {        
        p_buffer := transmute(^bytes.Buffer)stream_data
        if mode == .Write
        {    
            bn, berr := bytes.buffer_write(p_buffer, p)
            n = i64(bn)
            err = berr
        }
        else if mode == .Size
        {
            n = i64(len(p_buffer.buf))
        }
        return
    }
    
    pkg.pack_directory(diretory_path, package_name, stream)
    
    out_directory := cli_get_out_directory(context.temp_allocator)
    package_filename, pf_err := strings.join({package_name, pkg.EXTENSION}, "", context.temp_allocator)
    package_path := filepath.join({out_directory, package_filename}, context.temp_allocator)
    os.write_entire_file(package_path, buffer.buf[:])
}