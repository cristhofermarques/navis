package tools

main :: proc()
{
    debug := cli_has_flag("debug") > -1
    verbose := cli_has_flag("verbose") > -1
    navis_collection := cli_has_flag("collection:navis") > -1
    navis_build_mode_embedded := cli_has_flag("navis-build-mode:embedded") > -1

    if cli_has_flag("module:navis") > -1 do build_navis_module(debug, verbose)

    if i := cli_has_pair_flag("module"); i > -1
    {
        descriptor: Module_Build_Descriptor
        descriptor.navis_build_mode = navis_build_mode_embedded ? .Embedded : .Shared
        descriptor.navis_collection = navis_collection
        descriptor.debug = debug
        descriptor.verbose = verbose

        flag, key, val := cli_get_pair_flag("module")
        build_module(key, val, descriptor)
    }

    if i := cli_has_pair_flag("launcher"); i > -1
    {
        descriptor: Module_Build_Descriptor
        descriptor.navis_build_mode = navis_build_mode_embedded ? .Embedded : .Shared
        descriptor.navis_collection = navis_collection
        descriptor.debug = debug
        descriptor.verbose = verbose

        flag, key, val := cli_get_pair_flag("launcher")
        build_launcher(key, val, descriptor)
    }
}