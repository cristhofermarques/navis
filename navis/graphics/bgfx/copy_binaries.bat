@echo off

set BGFX_DIRECTORY=C:\_Projects\bgfx\bgfx

if not exist "%BGFX_DIRECTORY%" (
    echo %BGFX_DIRECTORY% Not Found
    goto end
)

copy %BGFX_DIRECTORY%\.build\win64_vs2022\bin\bgfxRelease.lib bgfx.lib
copy %BGFX_DIRECTORY%\.build\win64_vs2022\bin\bxRelease.lib bx.lib
copy %BGFX_DIRECTORY%\.build\win64_vs2022\bin\bimgRelease.lib bimg.lib
copy %BGFX_DIRECTORY%\.build\win64_vs2022\bin\bimg_decodeRelease.lib bimg_decode.lib

:end