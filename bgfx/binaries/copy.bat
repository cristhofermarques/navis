@echo off

if "%1" == "" goto end
if not exist "%1" goto end

set out_path=.
if not "%2" == "" (
    set out_path=%2
)

set windows_amd64_path="%1\win64_vs2022\bin"
if exist "%windows_amd64_path%" (
    for %%l in (bx bgfx bimg bimg_encode bimg_decode shaderc texturec fcpp glslang glsl-optimizer spirv-cross spirv-opt) do (
        for %%m in (debug release) do (
            for %%e in (.lib .pdb) do (
                if exist "%windows_amd64_path%\%%l%%m%%e" (
                    echo        %%l_windows_amd64_%%m%%e
                    @copy %windows_amd64_path%\%%l%%m%%e %out_path%\%%l_windows_amd64_%%m%%e
                )
            )
        )
    )
)

:end