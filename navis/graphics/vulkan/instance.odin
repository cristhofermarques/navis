package vulkan

import "navis:api"

when api.EXPORT
{
    import "vk"
    import "navis:commons/log"
    import "navis:commons/utility"

    ENGINE_NAME :: "Navis"

    @(export=api.SHARED, link_prefix=PREFIX)
    instance_create_from_descriptor :: proc(desc: ^Instance_Descriptor, allocator := context.allocator) -> (Instance, bool) #optional_ok
    {
        if desc == nil do return {}, false

        app_info: vk.ApplicationInfo
        app_info.sType = .APPLICATION_INFO
        app_info.pApplicationName = desc.app_name
        app_info.applicationVersion = desc.app_version
        app_info.pEngineName = ENGINE_NAME
        app_info.engineVersion = vk.MAKE_VERSION(api.VERSION_MAJOR, api.VERSION_MINOR, api.VERSION_PATCH)
        app_info.apiVersion = desc.api_version

        info: vk.InstanceCreateInfo
        info.sType = .INSTANCE_CREATE_INFO
        info.pApplicationInfo = &app_info
        info.ppEnabledExtensionNames = utility.slice_as_mult_ptr(desc.extensions)
        info.enabledExtensionCount = u32(utility.slice_may_len(desc.extensions))
        info.ppEnabledLayerNames = utility.slice_as_mult_ptr(desc.layers)
        info.enabledLayerCount = u32(utility.slice_may_len(desc.layers))

        handle: vk.Instance
        result := vk._create_instance(&info, nil, &handle)
        if log.verbose_fail_error(result != .SUCCESS, "Create Instance") do return {}, false

        instance: Instance
        instance.__allocator = allocator
        instance.app_name = utility.cstring_clone(desc.app_name, allocator)
        instance.app_version = desc.app_version
        instance.engine_name = utility.cstring_clone(ENGINE_NAME, allocator)
        instance.engine_version = app_info.engineVersion
        if desc.extensions != nil do instance.enabled_extensions = utility.cstring_clone(desc.extensions, allocator)
        if desc.layers != nil do instance.enabled_layers = utility.cstring_clone(desc.layers, allocator)
        instance.handle = handle
        return instance, true
    }

    @(export=api.SHARED, link_prefix=PREFIX)
    instance_create_from_parameters :: proc(app_name: cstring, app_version, api_version: u32, extensions, layers: []cstring, allocator := context.allocator) -> (Instance, bool) #optional_ok
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
    instance_destroy :: proc(instance: ^Instance)
    {
        if log.verbose_fail_error(instance == nil, "Nil Instance paramater") do return

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

        if instance.handle != nil
        {
            vk.DestroyInstance(instance.handle, nil)
            instance.handle = nil
        }
    }
}