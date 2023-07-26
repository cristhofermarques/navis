package navis

//TODO: doc
Path_Package_Kind :: enum
{
    Unpacked,
    Packed,
}

//TODO: doc
Path_Package :: struct
{
    navis_resposibility: bool,
    path: string,
    kind: Path_Package_Kind,
}

//TODO: doc
Data_Package :: struct
{
    navis_resposibility: bool,
    data: []byte,
}

//TODO: doc
Package :: union
{
    Path_Package,
    Data_Package,
}

/*
TODO: just a pointer to a package union.
A way to navis read assets from it, this means that navis will not free/destroy the packages, that is your job.
*/
Package_Reference :: ^Package

//TODO: doc
Streamer :: struct
{
    packages: []Package,
    references: []Package_Reference,
}

when IMPLEMENTATION
{
    import "core:os"
    import "core:strings"
    import "core:path/filepath"

    @(export=EXPORT, link_prefix=PREFIX)
    package_create_from_path :: proc(path: string, allocator := context.allocator) -> (Package, bool)
    {
        path_clone := strings.clone(path, allocator)
        pkg: Path_Package
        pkg.path = path_clone

        if os.is_dir(path)
        {
            pkg.kind = .Unpacked
            return pkg, true
        }
        else if os.is_file(path) && filepath.ext(path) == ".pkg"
        {
            pkg.kind = .Packed
            return pkg, true
        }

        delete(path_clone, allocator)
        return {}, false
    }

    @(export=EXPORT, link_prefix=PREFIX)
    package_delete :: proc(pkg: ^Package, allocator := context.allocator)
    {
        if pkg == nil do return
        switch p in pkg
        {
            case Data_Package: delete(p.data, allocator)
            case Path_Package: delete(p.path, allocator)
        }
    }

    @(export=EXPORT, link_prefix=PREFIX)
    package_read_asset :: proc(pkg: ^Package, path: string, allocator := context.allocator) -> []byte
    {
        if pkg == nil do return nil
        switch p in pkg
        {
            case Data_Package: return nil // TODO: Read from raw data

            case Path_Package:
                switch p.kind
                {
                    case .Unpacked:
                        fullpath := filepath.join({p.path, path}, context.temp_allocator)
                        if os.is_file(fullpath)
                        {
                            d, s := os.read_entire_file(fullpath, allocator); 
                            return d
                        }
                        else do return nil

                    case .Packed: return nil // TODO: impl
                }
        }
            
        return nil
    }

    package_create :: proc{
        package_create_from_path,
    }

    @(export=EXPORT, link_prefix=PREFIX)
    streamer_create :: proc(paths: []string, references: []Package_Reference = nil, allocator := context.allocator) -> (Streamer, bool) #optional_ok
    {
        if paths == nil && references == nil 
        {
            log_verbose_error("'paths' and 'references' slice parameters are nil. paths:", paths, "references:", references)
            return {}, false
        }

        streamer: Streamer

        if paths != nil
        {
            paths_count := len(paths)
            packages, packages_allocation_error := make([]Package, paths_count, allocator)
            if packages_allocation_error != .None
            {
                log_verbose_error("failed to make packages slice. error:", packages_allocation_error)
                return {}, false
            }

            packages_create_count := 0
            for path, i in paths
            {
                pkg, created_pkg := package_create(path, allocator)
                if !created_pkg
                {
                    log_verbose_error("failed to create package index", i, "from path", path)
                    break;
                }

                packages_create_count += 1
                packages[i] = pkg
            }

            created_packages := packages_create_count == len(packages)
            if !created_packages
            {
                log_verbose_error("failed to create packages from paths")
                for &pkg in packages do package_delete(&pkg, allocator)
                delete(packages, allocator)
                return {}, false
            }
            
            streamer.packages = packages
        }

        if references != nil 
        {
            references_clone, cloned_references := slice_clone(references, allocator)
            if !cloned_references
            {
                log_verbose_error("failed to clone references parameter")
                streamer_destroy(&streamer, allocator)//NOTE(cris): call this, it makes what we want to do, freeding created packages.
                return {}, false
            }

            streamer.references = references_clone
        }

        return streamer, true
    }

    @(export=EXPORT, link_prefix=PREFIX)
    streamer_destroy :: proc(streamer: ^Streamer, allocator := context.allocator)
    {
        if streamer == nil do return // TODO: log error

        if streamer.packages != nil
        {
            for &pkg in streamer.packages do package_delete(&pkg, allocator)
            delete(streamer.packages, allocator)
            streamer.packages = nil
        }
        
        if streamer.references != nil
        {
            delete(streamer.references, allocator)
            streamer.references = nil
        }
    }
}