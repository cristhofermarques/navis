package vulkan

import "vk"

Semaphore :: vk.Semaphore

// semaphore_slice_to_handles :: #force_inline proc(semaphores: []Semaphore, allocator := context.allocator, location := #caller_location) -> ([]vk.Semaphore, bool) #optional_ok
// {
//     if semaphores != nil do return nil, false

//     semaphores_len := len(semaphores)
//     if semaphores_len < 1 do return nil, false

//     handles, alloc_err := make(,)
// }