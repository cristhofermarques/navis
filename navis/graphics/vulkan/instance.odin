package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"
    import "navis:commons/utility"
    import "navis:commons"

    ENGINE_NAME :: "Navis"

    @(export=api.SHARED, link_prefix=PREFIX)
    instance_create_from_descriptor :: proc(desc: ^Instance_Descriptor, allocator := context.allocator, location := #caller_location) -> (Instance, bool) #optional_ok
    {
        if log.verbose_fail_error(desc == nil, "nil parameter, vulkan instance descriptor", location) do return {}, false

        //Application info
        app_info: vk.ApplicationInfo
        app_info.sType = .APPLICATION_INFO
        app_info.pApplicationName = desc.app_name
        app_info.applicationVersion = desc.app_version
        app_info.pEngineName = ENGINE_NAME
        app_info.engineVersion = vk.MAKE_VERSION(api.VERSION_MAJOR, api.VERSION_MINOR, api.VERSION_PATCH)
        app_info.apiVersion = desc.api_version

        //Enabled extensions
        enabled_extensions, enabled_extensions_succ := commons.dynamic_from_slice(desc.extensions, context.temp_allocator) if desc.extensions != nil else make([dynamic]cstring, 0, 0, context.temp_allocator), true
        if log.verbose_fail_error(!enabled_extensions_succ, "create dynamic slice from enabled extensions slice", location) do return {}, false
        defer delete(enabled_extensions)

        //Enabled layers
        enabled_layers, enabled_layers_succ := commons.dynamic_from_slice(desc.extensions, context.temp_allocator) if desc.layers != nil else make([dynamic]cstring, 0, 0, context.temp_allocator), true
        if log.verbose_fail_error(!enabled_layers_succ, "create dynamic slice from enabled layers slice", location) do return {}, false
        defer delete(enabled_layers)

        //Adding windows extensions
        when ODIN_OS == .Windows do append(&enabled_extensions, vk.KHR_SURFACE_EXTENSION_NAME)
        when ODIN_OS == .Windows do append(&enabled_extensions, vk.KHR_WIN32_SURFACE_EXTENSION_NAME)
        
        //Adding debug extensions
        when ODIN_DEBUG do append(&enabled_extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
        
        //Adding debug layers
        KHR_VALIDATION_NAME :: "VK_LAYER_KHRONOS_validation"
        when ODIN_DEBUG do append(&enabled_layers, KHR_VALIDATION_NAME)

        info: vk.InstanceCreateInfo
        info.sType = .INSTANCE_CREATE_INFO
        info.pApplicationInfo = &app_info
        info.ppEnabledExtensionNames = commons.array_try_as_pointer(enabled_extensions)
        info.enabledExtensionCount = cast(u32)commons.array_try_len(enabled_extensions)
        info.ppEnabledLayerNames = commons.array_try_as_pointer(enabled_layers)
        info.enabledLayerCount = cast(u32)commons.array_try_len(enabled_layers)

        //Creating instance
        handle: vk.Instance
        result := vk._create_instance(&info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "create vulkan instance", location) do return {}, false

        //Create debugger

        //Cloning info
        instance_app_name := utility.cstring_clone(desc.app_name, allocator)
        instance_app_version := desc.app_version
        instance_engine_name := utility.cstring_clone(ENGINE_NAME, allocator)
        instance_engine_version := app_info.engineVersion
        instance_enabled_extensions := utility.cstring_clone(&enabled_extensions, allocator)
        instance_enabled_layers := utility.cstring_clone(&enabled_layers, allocator)

        //Making instance
        instance: Instance
        instance.__allocator = allocator
        instance.app_name = instance_app_name
        instance.app_version = instance_app_version
        instance.engine_name = instance_engine_name
        instance.engine_version = instance_engine_version
        instance.enabled_extensions = instance_enabled_extensions
        instance.enabled_layers = instance_enabled_layers
        instance.handle = handle
        return instance, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    instance_create_from_parameters :: proc(app_name: cstring, app_version, api_version: u32, extensions, layers: []cstring, allocator := context.allocator, location := #caller_location) -> (Instance, bool) #optional_ok
    {
        desc: Instance_Descriptor
        desc.app_name = app_name
        desc.app_version = app_version
        desc.api_version = api_version
        desc.extensions = extensions
        desc.layers = layers

        return instance_create_from_descriptor(&desc, allocator)
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    instance_destroy :: proc(instance: ^Instance, location := #caller_location)
    {
        if log.verbose_fail_error(instance == nil, "nil instance paramater", location) do return

        allocator := instance.__allocator

        //Destroying vulkan instance
        if instance.handle != nil
        {
            log.verbose_debug("destroying vulkan instance", " ", location)
            vk._destroy_instance(instance.handle, nil)
            instance.handle = nil
        }

        //Deleting allocated
        if instance.app_name != "" do delete(instance.app_name, allocator)
        if instance.engine_name != "" do delete(instance.engine_name, allocator)
        
        if instance.enabled_extensions != nil
        {
            for extension in instance.enabled_extensions do delete(extension, allocator)
            delete(instance.enabled_extensions, allocator)
        }

        if instance.enabled_layers != nil
        {
            for layer in instance.enabled_layers do delete(layer, allocator)
            delete(instance.enabled_layers, allocator)
        }
    }

/*
Gets instance version.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    instance_enumerate_version :: proc() -> (u32, bool) #optional_ok
    {
        version: u32
        result := vk.EnumerateInstanceVersion(&version)
        return version, result == .SUCCESS
    }
    
/*
Gets instance extension properties.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    instance_enumerate_extension_properties :: proc(layer_name: cstring, allocator := context.allocator, location := #caller_location) -> ([]vk.ExtensionProperties, bool) #optional_ok
    {
        result: vk.Result

        extension_count: u32
        result = vk.EnumerateInstanceExtensionProperties(layer_name, &extension_count, nil)
        if log.verbose_fail_error(result != .SUCCESS, "enumerate instance extension properties, count querry", location) do return nil, false
        
        extensions, alloc_err := make([]vk.ExtensionProperties, extension_count, allocator)
        if log.verbose_fail_error(alloc_err != .None, "make instance extension properties slice", location) do return nil, false
        
        result = vk.EnumerateInstanceExtensionProperties(layer_name, &extension_count, commons.array_try_as_pointer(extensions))
        if log.verbose_fail_error(result != .SUCCESS, "enumerate instance extension properties, fill querry", location)
        {
            delete(extensions, allocator)
            return nil, false
        }
        
        return extensions, true
    }

/*
Gets instance layer properties.
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    instance_enumerate_layer_properties :: proc(allocator := context.allocator, location := #caller_location) -> ([]vk.LayerProperties, bool) #optional_ok
    {
        result: vk.Result

        layer_count: u32
        result = vk.EnumerateInstanceLayerProperties(&layer_count, nil)
        if log.verbose_fail_error(result != .SUCCESS, "enumerate instance layer properties, count querry", location) do return nil, false

        layers, alloc_err := make([]vk.LayerProperties, layer_count, allocator)
        if log.verbose_fail_error(alloc_err != .None, "make instance layer properties slice", location) do return nil, false

        result = vk.EnumerateInstanceLayerProperties(&layer_count, commons.array_try_as_pointer(layers));
        if log.verbose_fail_error(result != .SUCCESS, "enumerate instance layer properties, fill querry", location)
        {
            delete(layers, allocator)
            return nil, false
        }

        return layers, result == .SUCCESS
    }
}