#include <stdio.h>
#include <ulib.h>
#include <unistd.h>

/* 
 * FIFO Test Case: Convoy Effect
 * 
 * Purpose: Demonstrate the Convoy Effect in FIFO scheduling.
 * Scenario:
 * 1. Child 0 arrives (Long Job).
 * 2. Child 1 arrives (Short Job).
 * 3. Child 2 arrives (Short Job).
 * 
 * To simulate "arrival" while ensuring they are all in the queue:
 * - Each child yields once immediately upon starting. This allows the parent
 *   to continue forking the rest of the children.
 * - Since FIFO adds to the tail, the order in the queue should be preserved 
 *   as 0 -> 1 -> 2.
 * 
 * Expected Behavior:
 * - Child 0 runs for a long time.
 * - Child 1 and 2 are blocked waiting for Child 0.
 * - Turnaround time for Child 1 and 2 will be high (dominated by Child 0's run time).
 */

void spin(int n) {
    volatile int i;
    for (i = 0; i < n; i++);
}

int main(void) {
    int i, pid;
    cprintf("FIFO Convoy Test: Parent %d creating children...\n", getpid());

    for (i = 0; i < 3; i++) {
        pid = fork();
        if (pid == 0) {
            // Child
            int id = i;
            int start_time = gettime_msec();
            cprintf("Child %d (PID %d) created at %d\n", id, getpid(), start_time);
            
            // Yield to let parent create other children, ensuring we are all in the queue
            yield(); 
            
            int run_start = gettime_msec();
            cprintf("Child %d (PID %d) starting work at %d (Wait Time: %d)\n", 
                    id, getpid(), run_start, run_start - start_time);
            
            if (id == 0) {
                // Long job: ~800ms
                cprintf("Child 0: Long Job (Simulating heavy task)\n");
                spin(80000000); 
            } else {
                // Short job: ~100ms
                cprintf("Child %d: Short Job\n", id);
                spin(10000000);
            }
            
            int end_time = gettime_msec();
            cprintf("Child %d (PID %d) finished at %d (Turnaround Time: %d)\n", 
                    id, getpid(), end_time, end_time - start_time);
            exit(0);
        }
    }

    cprintf("Parent waiting...\n");
    for (i = 0; i < 3; i++) {
        waitpid(-1, NULL);
    }
    cprintf("FIFO Convoy Test: Finished.\n");
    return 0;
}
