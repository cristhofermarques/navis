package navis

import "core:sync"
import "core:thread"

pool_list :: proc(pool: ^thread.Pool, id: int, allocator := context.allocator) -> []thread.Task
{
    sync.guard(&pool.mutex)
    slice_length := 0
    for &task in pool.tasks_done do if task.user_index == int(id) do slice_length += 1
    
    tasks, tasks_err := make_slice([]thread.Task, slice_length, allocator)
    if tasks_err != .None do return nil
    
    i := 0
    #reverse for &task, index in pool.tasks_done
    {
        if task.user_index == id
        {
            unordered_remove(&pool.tasks_done, index)
            tasks[i] = task
            i += 1
        }
    }
    return tasks
}