#include <stdio.h>
#include <ulib.h>
#include <unistd.h>

/* 一个简单的纯计算耗时函数 */
void spin_delay(int n) {
    int i;
    volatile int j; // volatile 防止编译器优化掉死循环
    for (i = 0; i < n; i++) {
        j = i * i; 
    }
}

int main(void) {
    int pid, i;
    cprintf("FIFO Test Started: Parent PID %d\n", getpid());

    /* 创建 3 个子进程 */
    for (i = 0; i < 3; i++) {
        pid = fork();
        if (pid == 0) {
            // --- 子进程代码 ---
            int child_id = i + 1;
            cprintf("Child %d (PID %d) STARTED at ticks %d\n", child_id, getpid(), gettime_msec());
            
            // 模拟长作业：死循环空转
            // 根据你的 CPU 速度，可能需要调整这个数值
            // 目标是让每个进程跑大约 1-2 秒
            spin_delay(20000000); 

            cprintf("Child %d (PID %d) FINISHED at ticks %d\n", child_id, getpid(), gettime_msec());
            exit(0);
        }
    }

    /* 父进程等待所有子进程结束 */
    cprintf("Parent waiting for children...\n");
    waitpid(-1, NULL); // 等子进程1
    waitpid(-1, NULL); // 等子进程2
    waitpid(-1, NULL); // 等子进程3
    cprintf("FIFO Test Finished.\n");
    return 0;
}