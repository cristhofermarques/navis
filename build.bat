@echo off

set binaries_directory=.binaries\windows

set library_name=navis
set library_extension=.dll

set build_kind_directory=shared
set build_mode_directory=release
set build_arch_directory=amd64

set odin_build_target=-target:windows_amd64
set odin_build_mode=-build-mode:shared
set odin_build_debug=

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
)

set build_path=%binaries_directory%
set build_path=%build_path%\%build_kind_directory%
set build_path=%build_path%\%build_arch_directory%
set build_path=%build_path%\%build_mode_directory%

set library_path=%build_path%\%library_name%%library_extension%

set build_command=build %library_name%
set build_command=%build_command% %odin_build_debug%
set build_command=%build_command% %odin_build_target%
set build_command=%build_command% %odin_build_mode%
set build_command=%build_command% -define:NAVIS_API_SHARED=true
set build_command=%build_command% -define:NAVIS_API_EXPORT=true
set build_command=%build_command% -collection:%library_name%=%library_name%
set build_command=%build_command% -collection:binaries=%build_path%
set build_command=%build_command% -out:%library_path%

if not exist "%build_path%" (
    mkdir %build_path%
)

@odin %build_command%