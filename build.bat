@echo off

set binaries_directory=.binaries
set build_mode_directory=release
set build_arch_directory=amd64
set odin_build_target=-target:windows_amd64
set odin_build_debug=
set build_verbose=false

for %%a in (%*) do (

    if %%a==-arch:i386 (
        set build_arch_directory=i386
        set odin_build_target=-target:windows_i386
    )

    if %%a==-arch:amd64 (
        set build_arch_directory=amd64
        set odin_build_target=-target:windows_amd64
    )

    if %%a==-mode:debug (
        set build_mode_directory=debug
        set odin_build_debug=-debug
    )

    if %%a==-mode:release (
        set build_mode_directory=release
        set odin_build_debug=
    )

    if %%a==-verbose (
        set build_verbose=true
    )
)

set build_path=%binaries_directory%\windows\shared
set build_path=%build_path%\%build_arch_directory%
set build_path=%build_path%\%build_mode_directory%

set library_path=%build_path%\navis.dll

set build_command=build navis -build-mode:shared
set build_command=%build_command% %odin_build_debug%
set build_command=%build_command% %odin_build_target%
set build_command=%build_command% %odin_build_mode%
set build_command=%build_command% -define:NAVIS_API_SHARED=true
set build_command=%build_command% -define:NAVIS_API_EXPORT=true
set build_command=%build_command% -define:NAVIS_API_VERBOSE=%build_verbose%
set build_command=%build_command% -define:NAVIS_API_VERSION_MAJOR=23
set build_command=%build_command% -define:NAVIS_API_VERSION_MINOR=5
set build_command=%build_command% -define:NAVIS_API_VERSION_PATCH=0
set build_command=%build_command% -collection:navis=navis
set build_command=%build_command% -collection:binaries=%build_path%
set build_command=%build_command% -out:%library_path%

if not exist "%build_path%" (
    mkdir %build_path%
)

@echo    Building os:windows kind:shared arch:%build_arch_directory% mode:%build_mode_directory% verbose:%build_verbose%
@odin %build_command%