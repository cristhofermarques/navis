package api

/*
API STRUCTURE:
    Source files that Starts With '_' character, Is Traited as Inline/Static code, used only at Shared Api Kind build.
        _example.odin - even when Shared Api Kind it will be Compiled into the Final Binary (app.exe/app.dll)
        example.odin - when Shared Api Kind it will be Compiled into the Shared Library (navis.dll/navis.so), meaning that Binding is required

API KIND:
    Static Build: Compile Navis into the Final Binary.
    Shared Build: Compile Navis into a Shared Library.
        Import: Api Bindings.
        Export: Api Implementation.
    Note: Built-In Bindings for Shared Api Kind.

BUILD DEFINES:
    NAVIS_API_SHARED - API_SHARED - default(true) : Used for Symbols Exporting and Binding Code.
    NAVIS_API_EXPORT - API_SHARED - default(false): Used for Code Implementation.

    Obs: Defines are Done for Navis Module Development in Shared Library as Default.

    Build Static : NAVIS_API_SHARED=false, NAVIS_API_EXPORT=true
    Build Shared : NAVIS_API_SHARED=true, NAVIS_API_EXPORT=false
*/

/*Runtime Kind of Navis, Shared/Static Library
    * Used for Export Symbols
*/
SHARED :: #config(NAVIS_API_SHARED, true)

/*Runtime Kind of Navis, Shared/Static Library*/
STATIC :: !SHARED

/*Include Implementation if 'true'*/
EXPORT :: #config(NAVIS_API_EXPORT, false)

/*Include Bindinds if 'true'
    * Only used at Shared Library Runtime
*/
IMPORT :: !EXPORT

/*Platform Exports*/
EXPORT_WINDOWS :: EXPORT && ODIN_OS == .Windows
EXPORT_LINUX   :: EXPORT && ODIN_OS == .Linux

VERSION_MAJOR :: #config(NAVIS_API_VERSION_MAJOR, 2023)
VERSION_MINOR :: #config(NAVIS_API_VERSION_MINOR, 4)
VERSION_PATCH :: #config(NAVIS_API_VERSION_PATCH, 16)

VERBOSE :: #config(NAVIS_API_VERBOSE, true)