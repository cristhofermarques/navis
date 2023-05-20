package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"
    import "navis:commons/utility"
    import "navis:commons"

    ENGINE_NAME :: "Navis"

/*
Create a new vulkan instance from descriptor.

Returns:
* Instance: new vulkan instance if success
* bool: true if success
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    instance_create_from_descriptor :: proc(descriptor: ^Instance_Descriptor) -> (Instance, bool) #optional_ok
    {
        //Checking descriptor parameter
        if !instance_descriptor_is_valid(descriptor)
        {
            log.verbose_error("Invalid vulkan instance descriptor parameter", descriptor)
            return {}, false
        }

        //Making application info
        app_info: vk.ApplicationInfo
        app_info.sType = .APPLICATION_INFO
        app_info.pApplicationName = descriptor.app_name
        app_info.applicationVersion = descriptor.app_version
        app_info.pEngineName = ENGINE_NAME
        app_info.engineVersion = vk.MAKE_VERSION(api.VERSION_MAJOR, api.VERSION_MINOR, api.VERSION_PATCH)
        app_info.apiVersion = descriptor.api_version

        //Allocatin enabled extensions
        enabled_extensions, ena_ext_succ := commons.dynamic_from_slice(descriptor.extensions, context.temp_allocator) if descriptor.extensions != nil else make([dynamic]cstring, 0, 0, context.temp_allocator), true
        if !ena_ext_succ
        {
            log.verbose_error("Failed to allocate enabled extensions dynamic slice")
            return {}, false
        }
        defer delete(enabled_extensions)

        //Allocating enabled layers
        enabled_layers, ena_lay_succ := commons.dynamic_from_slice(descriptor.layers, context.temp_allocator) if descriptor.layers != nil else make([dynamic]cstring, 0, 0, context.temp_allocator), true
        if !ena_lay_succ
        {
            log.verbose_error("Failed to allocate enabled layers dynamic slice")
            return {}, false
        }
        defer delete(enabled_layers)

        //Adding windows extensions
        when ODIN_OS == .Windows do append(&enabled_extensions, vk.KHR_SURFACE_EXTENSION_NAME)
        when ODIN_OS == .Windows do append(&enabled_extensions, vk.KHR_WIN32_SURFACE_EXTENSION_NAME)
        
        //Adding debug extensions
        when ODIN_DEBUG do append(&enabled_extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
        
        //Adding debug layers
        KHR_VALIDATION_NAME :: "VK_LAYER_KHRONOS_validation"
        when ODIN_DEBUG do append(&enabled_layers, KHR_VALIDATION_NAME)

        //Making create info
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
        if result != .SUCCESS
        {
            log.verbose_error(result, "Failed to create vulkan instance", info)
            return {}, false
        }

        //Cloning info
        instance_app_name := utility.cstring_clone(descriptor.app_name, context.allocator)
        instance_app_version := descriptor.app_version
        instance_engine_name := utility.cstring_clone(ENGINE_NAME, context.allocator)
        instance_engine_version := app_info.engineVersion
        instance_enabled_extensions := utility.cstring_clone(&enabled_extensions, context.allocator)
        instance_enabled_layers := utility.cstring_clone(&enabled_layers, context.allocator)

        //Making instance
        instance: Instance
        instance.__allocator = context.allocator
        instance.app_name = instance_app_name
        instance.app_version = instance_app_version
        instance.engine_name = instance_engine_name
        instance.engine_version = instance_engine_version
        instance.enabled_extensions = instance_enabled_extensions
        instance.enabled_layers = instance_enabled_layers
        instance.handle = handle
        return instance, true
    }

/*
Destroy a vulkan instance.

Returns:
* bool: true if success
*/
    @(export=api.SHARED, link_prefix=PREFIX)
    instance_destroy :: proc(instance: ^Instance) -> bool
    {
        //Checking instance parameter
        if !instance_is_valid(instance)
        {
            log.verbose_error("Invalid vulkan instance parameter", instance)
            return false
        }

        //Destroying instance
        log.verbose_debug("Destroying vulkan instance", instance)
        vk._destroy_instance(instance.handle, nil)

        //Deleting members
        allocator := instance.__allocator

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
        
        instance^ = {}
        return true
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