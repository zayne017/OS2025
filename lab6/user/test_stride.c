#include <stdio.h>
#include <ulib.h>
#include <string.h>

/* 
 * Stride Test Case
 * 
 * This test verifies the proportional share property of Stride Scheduling.
 * We create processes with priorities 2, 3, and 5.
 * They should get CPU time roughly in ratio 2:3:5.
 */

#define TOTAL 3
#define DURATION 2000 // Run for 2 seconds

int main(void) {
    int pids[TOTAL];
    int priorities[TOTAL] = {2, 3, 5};
    int i;
    unsigned int start_time;
    
    cprintf("Stride Test: Parent (pid %d) starting...\n", getpid());

    for (i = 0; i < TOTAL; i++) {
        if ((pids[i] = fork()) == 0) {
            // Child
            lab6_setpriority(priorities[i]);
            cprintf("Child %d (pid %d) started with priority %d\n", i, getpid(), priorities[i]);
            
            long long counter = 0;
            start_time = gettime_msec();
            while (gettime_msec() - start_time < DURATION) {
                counter++;
            }
            cprintf("Child %d (pid %d) finished. Count: %lld\n", i, getpid(), counter);
            exit((int)(counter / 10000)); // Return a scaled count
        }
    }

    cprintf("Parent: Waiting for children...\n");
    for (i = 0; i < TOTAL; i++) {
        int exit_code;
        waitpid(pids[i], &exit_code);
        cprintf("Child %d exited with scaled count: %d\n", i, exit_code);
    }
    cprintf("Stride Test: Finished.\n");
    return 0;
}
