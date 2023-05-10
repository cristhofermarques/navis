package vulkan

import "vk"

Command_Buffer :: vk.CommandBuffer

Command_Buffer_Descriptor :: struct
{
    command_pool: ^Command_Pool,
    count: i32,
    level: vk.CommandBufferLevel,
}

command_buffer_create_from_descriptor_single :: proc(device: ^Device, desc: ^Command_Buffer_Descriptor) -> (Command_Buffer, bool) #optional_ok
{
    info: vk.CommandBufferAllocateInfo
    info.sType = .COMMAND_BUFFER_ALLOCATE_INFO
    info.commandPool = desc.command_pool.handle
    info.commandBufferCount = 1
    info.level = desc.level

    handle: vk.CommandBuffer
    result := vk.AllocateCommandBuffers(device.handle, &info, &handle)
    if result != .SUCCESS do return nil, false
    else do return handle, true
}

command_buffer_create :: proc{
    command_buffer_create_from_descriptor_single,
}