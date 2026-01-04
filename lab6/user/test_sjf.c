#include <stdio.h>
#include <ulib.h>
#include <unistd.h>

/* 
 * SJF Test Case
 * 
 * Purpose: Verify Shortest Job First behavior using priorities as burst time.
 * Logic:
 * 1. Create 3 children with different priorities (simulated burst times).
 *    - Child 0: Prio 100 (Long)
 *    - Child 1: Prio 10  (Short)
 *    - Child 2: Prio 50  (Medium)
 * 2. Each child yields to ensure all are enqueued.
 * 3. Each child performs the SAME amount of work.
 * 4. Expected: Completion order follows priority (Smallest Prio First).
 *    Order: Child 1 (10) -> Child 2 (50) -> Child 0 (100).
 */

void spin(int n) {
    volatile int i;
    for (i = 0; i < n; i++);
}

int main(void) {
    int i, pid;
    // Priorities: 100 (Long), 10 (Short), 50 (Medium)
    int priorities[] = {100, 10, 50}; 
    
    cprintf("SJF Test: Parent %d starting children...\n", getpid());

    for (i = 0; i < 3; i++) {
        pid = fork();
        if (pid == 0) {
            // Child
            int prio = priorities[i];
            lab6_setpriority(prio);
            int start_time = gettime_msec();
            cprintf("Child %d (PID %d) created at %d with priority %d\n", i, getpid(), start_time, prio);
            
            // Yield to allow others to start and enqueue
            // If SJF is working, the scheduler should pick the one with smallest priority next
            yield();
            
            int run_time = gettime_msec();
            cprintf("Child %d (PID %d) running at %d (Response Time: %d)\n", 
                    i, getpid(), run_time, run_time - start_time);
            
            spin(40000000); // Same work for everyone
            
            int end_time = gettime_msec();
            cprintf("Child %d (PID %d) finished at %d (Turnaround Time: %d)\n", 
                    i, getpid(), end_time, end_time - start_time);
            exit(0);
        }
    }

    cprintf("Parent waiting...\n");
    for (i = 0; i < 3; i++) {
        waitpid(-1, NULL);
    }
    cprintf("SJF Test: Finished.\n");
    return 0;
}
