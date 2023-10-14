package navis

import "core:sync"
import "core:thread"
import "core:runtime"
import "core:intrinsics"

Task_ID :: enum int
{
    Default = 0,
    Load_Asset,
    Load_Asset_Callback,
    Wait_Asset_Callback,
    Load_BGFX_Asset,
    Load_BGFX_Asset_Callback,
}

pool_add_task :: #force_inline proc(pool: ^thread.Pool, allocator: runtime.Allocator, procedure: thread.Task_Proc, data: rawptr, task_id := Task_ID.Default)
{
    thread.pool_add_task(pool, allocator, procedure, data, int(task_id))
}

pool_list :: proc(pool: ^thread.Pool, task_id: Task_ID, allocator := context.allocator) -> []thread.Task
{
    sync.guard(&pool.mutex)
    slice_length := 0
    for &task in pool.tasks_done do if task.user_index == int(task_id) do slice_length += 1
    
    tasks, tasks_err := make_slice([]thread.Task, slice_length, allocator)
    if tasks_err != .None do return nil
    
    i := 0
    #reverse for &task, index in pool.tasks_done
    {
        if task.user_index == int(task_id)
        {
            unordered_remove(&pool.tasks_done, index)
            tasks[i] = task
            i += 1
            intrinsics.atomic_sub(&pool.num_done, 1)
        }
    }
    return tasks
}