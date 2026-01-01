#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * RR_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 *
 *   - run_list: should be an empty list after initialization.
 *   - proc_num: set to 0
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    // 1. 初始化链表头节点 (让 prev 和 next 都指向自己)
    list_init(&(rq->run_list));
    // 2. 此时队列里没有进程，数量为 0
    rq->proc_num = 0;
}

/*
 * RR_enqueue inserts the process ``proc'' into the tail of run-queue
 * ``rq''. The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``run_link'' node into the queue.
 * The procedure should also update the meta data in ``rq'' structure.
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    // 保护性检查：确保这个进程没在别的队列里
    assert(list_empty(&(proc->run_link)));
    // 1. 把进程加到队列的尾部
    // list_add_before 在头节点的前面插入，对于循环链表来说，就是在队尾插入
    list_add_before(&(rq->run_list), &(proc->run_link));
    // 2. 如果进程的时间片用完了（等于0），或者因为某种错误超过了最大值
    // 就把它恢复成最大时间片
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    // 3. 标记这个进程现在属于这个队列
    proc->rq = rq;
    // 4. 队列里的进程数量加一
    rq->proc_num++;

}

/*
 * RR_dequeue removes the process ``proc'' from the front of run-queue
 * ``rq'', the operation would be finished by the list_del_init operation.
 * Remember to update the ``rq'' structure.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    // 保护性检查：确保这个进程确实在队列里
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    // 1. 从链表中删除这个节点，并将其重置
    list_del_init(&(proc->run_link));
    // 2. 队列里的进程数 -1
    rq->proc_num--;

}

/*
 * RR_pick_next picks the element from the front of ``run-queue'',
 * and returns the corresponding process pointer. The process pointer
 * would be calculated by macro le2proc, see kern/process/proc.h
 * for definition. Return NULL if there is no process in the queue.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    // 1. 如果队列是空的（没人排队），返回 NULL
    if (rq->proc_num == 0) {
        return NULL;
    }
    // 2. 拿出队列头的那个链表节点
    // run_list 是表头，run_list.next 就是第一个排队的节点
    list_entry_t *le = list_next(&(rq->run_list));
    // 3. 使用 le2proc 宏，通过链表节点找到对应的进程结构体指针
    return le2proc(le, run_link);

}

/*
 * RR_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    // 1. 如果时间片还大于0，就扣掉一点
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    // 2. 如果扣完之后变成0了，说明该让出CPU了
    if (proc->time_slice == 0) {
        // 设置 need_resched 标记，下次内核检查时就会把它换下去
        proc->need_resched = 1;
    }
}

struct sched_class default_sched_class = {
    .name = "RR_scheduler",
    .init = RR_init,
    .enqueue = RR_enqueue,
    .dequeue = RR_dequeue,
    .pick_next = RR_pick_next,
    .proc_tick = RR_proc_tick,
};
