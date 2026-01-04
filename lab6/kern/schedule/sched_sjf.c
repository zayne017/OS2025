#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <sched_sjf.h>

static void
SJF_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}

static void
SJF_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    
    list_entry_t *le = list_next(&(rq->run_list));
    while (le != &(rq->run_list)) {
        struct proc_struct *next_proc = le2proc(le, run_link);
        if (proc->lab6_priority < next_proc->lab6_priority) {
            break;
        }
        le = list_next(le);
    }
    list_add_before(le, &(proc->run_link));
    
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}

static void
SJF_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num--;
}

static struct proc_struct *
SJF_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}

static void
SJF_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // SJF is non-preemptive
}

struct sched_class sjf_sched_class = {
    .name = "SJF_scheduler",
    .init = SJF_init,
    .enqueue = SJF_enqueue,
    .dequeue = SJF_dequeue,
    .pick_next = SJF_pick_next,
    .proc_tick = SJF_proc_tick,
};
