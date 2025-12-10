## Lab5

## 前置工作

在lab4中，我们创造了两个内核进程，lab5则是创造了一个用户进程，通过`ebreak`在内核态触发异常，借助异常处理机制的返回流程进行上下文切换，从而第一次进入到用户进程，并实现了系统调用。

需要补充代码：

- 在trap.c中`case IRQ_S_TIMER:`部分：

  ```
  clock_set_next_event();
  ticks++;
  if (ticks % TICK_NUM == 0)
   {
     if (current != NULL)//确保当前有进程在运行
      {
         current->need_resched = 1;//标记：该进程时间片用完了，申请调度
      }
   }
  break;
  ```

- 在proc.c中`alloc_proc`函数，增加：

  ```
  // 1. 初始化等待状态
  // 0 表示没有在等待任何事情
  proc->wait_state = 0;
  // 2. 初始化家族指针
  // 刚出生的进程没有孩子，也没有被挂到兄弟链表上，所以全是 NULL
  proc->cptr = NULL;  // 没有孩子 (Child Pointer)
  proc->optr = NULL;  // 没有哥哥 (Older Sibling Pointer)
  proc->yptr = NULL;  // 没有弟弟 (Younger Sibling Pointer)
  ```

  新创建的进程默认处于就绪或运行状态，没有在等待任何事件，因此将其初始化为 0。

  使用二叉链表的变体来管理复杂的进程族谱树：

  `parent`：指向父进程。

  `cptr`：指向该进程的最年轻的子进程即链表头，父进程通过它找到自己的孩子。

  `yptr`：指向比当前进程更年轻的兄弟进程，上一个节点。

  `optr`：指向比当前进程更年长的兄弟进程，下一个节点。

  `optr` 和 `yptr` 将同一个父进程下的所有子进程串成了一个双向链表，而父进程通过 `cptr` 抓住这个链表的头部。

  ```
  [父进程]
     | (cptr)
     V
  [子进程 A] <--(yptr/optr)--> [子进程 B] <--(yptr/optr)--> [子进程 C]
  ```

- 在do_fork函数，增加：

  ```
  proc->parent = current;  // 设置新进程的父亲为当前进程
  // 确保当前进程（父进程）的 wait_state 是 0
  assert(current->wait_state == 0);
  ```

  ```
  bool intr_flag;
  local_intr_save(intr_flag);  // 必须关中断,因为要操作全局链表，防止被打断
   {
    proc->pid = get_pid();   // 给孩子分配一个唯一的 PID
    hash_proc(proc);         // 把孩子加入 PID 哈希表，方便通过 PID 查找
    set_links(proc);       //调用
   }
  local_intr_restore(intr_flag); // 恢复中断
  ```

  `set_links(proc)`这是构建进程关系的核心函数。它完成了三件事：

  - 将 `proc` 插入到全局进程链表 `proc_list` 中，使其能被调度器识别。
  - 设置 `proc` 的 `cptr`, `yptr`, `optr`，将其挂载到父进程的子进程链表中，作为最新的子进程，将新进程接入了进程树结构。
  - 将进程总数加一。

## 练习1: 加载应用程序并执行（需要编码）

**do_execve**函数调用`load_icode`（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充`load_icode`的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好`proc_struct`结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。

请在实验报告中简要说明你的设计实现过程。

```
tf->gpr.sp = USTACKTOP;// 1. 设置用户栈指针
tf->epc = elf->e_entry;// 2. 设置程序入口地址
tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;// 3. 设置特权级和中断状态
```

设置trapframe内容：

- 设置用户栈指针 (`tf->gpr.sp = USTACKTOP`)：

  在之前的步骤中，我们已经建立了用户栈的内存映射，范围为 `[USTACKTOP - USTACKSIZE, USTACKTOP)`。

  RISC-V 中栈是向下增长的，因此我们需要将通用寄存器中的栈指针 `sp` 初始化为用户栈的最高地址 `USTACKTOP`，确保用户程序有合法的栈空间可用。

- 设置入口地址 (`tf->epc = elf->e_entry`)：

  `epc` 寄存器保存了发生异常时的指令地址，是在执行 `sret` 返回时 CPU 即将跳转到的地址。

  将 ELF 文件头中记录的程序入口地址 `e_entry` 赋值给 `epc`，这样=当从内核态返回时，PC 指针就会指向应用程序的第一条指令。

- 设置状态寄存器 (`tf->status`)：

  清除 SPP 位 (`& ~SSTATUS_SPP`)：`SPP`位记录了进入异常前的特权级别，我们希望从内核返回后进入用户模式 (User Mode)，因此须将此位清零。

  置位 SPIE 位 (`| SSTATUS_SPIE`)：`SPIE` 位记录了进入异常前中断是否开启，我们希望用户程序运行时能够响应中断，因此须将此位置 1。当执行 `sret` 时，硬件会将 `SPIE` 的值复制给 `SIE` ，从而开启中断。

请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。

1. 创建与调度

   创建：`init` 进程在 `init_main` 中调用 `kernel_thread`，通过 `do_fork` 创建一个新的内核线程 `user_main`，并将其状态设置为 `PROC_RUNNABLE` 。

   等待：`init` 进程随后调用 `do_wait` 进入休眠，并在 `schedule` 中让出 CPU 。

   调度：调度器选中这个新的内核线程，通过 `proc_run` -> `switch_to` 切换上下文，之后跳转到`forkrets`切换中断帧恢复寄存器，最终开始执行 `user_main` 函数 。

2. 加载应用程序

   发起调用：在 `user_main` 函数中，执行宏 `KERNEL_EXECVE(exit)`，通过内联汇编执行 `ebreak` 指令，触发断点异常，从而在内核态发起系统调用 。

   异常分发：CPU 跳转到 `__alltraps` -> `trap` ，在 `exception_handler` 中识别出断点异常，调用 `syscall` 。

   执行 Exec ：`syscall` 根据参数分发到 `sys_exec`，进而调用 `do_execve` 。

   加载内存：`do_execve` 销毁当前的内存空间，并调用 `load_icode` 加载 `exit` 程序的 ELF 文件。`load_icode` 会建立新的用户内存空间（代码段、数据段、BSS、用户栈），并关键地设置了 `current->tf` 中断帧，设置`epc`为应用程序第一条指令地址。

3. 切换与执行

   中断返回：`do_execve` 返回后，中断处理流程结束，执行 `kernel_execve_ret`，跳转到`__trapret`（位于 `trapentry.S`）。

   恢复现场：`__trapret` 从内核栈的 `TrapFrame` 中恢复通用寄存器。

   特权级切换：执行 `sret` 指令。CPU 根据 `sstatus` 的设置从内核态切换到用户态并将 PC 跳转到 `sepc`，即 `epc` 中保存的 ELF 入口地址 。

   执行：CPU 开始执行用户程序 `exit.c` 的第一条指令。

## 练习2: 父进程复制自己的内存空间给子进程（需要编码）

创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于kern/mm/pmm.c中）实现的，请补充`copy_range`的实现，确保能够正确执行。

请在实验报告中简要说明你的设计实现过程。

将父进程的内容拷贝到子进程中，`page`是父进程对应的物理页，`npage`是为子进程分配的新页。

```
void *src_kvaddr = page2kva(page);
void *dst_kvaddr = page2kva(npage);
memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ret = page_insert(to, npage, start, perm);
```

- 首先调用 `page2kva()` 函数，将父进程的源物理页 `page`和子进程的新物理页 `npage`转换为内核可以直接访问的虚拟地址 `src_kvaddr` 和 `dst_kvaddr`。
- 调用 `memcpy(dst_kvaddr, src_kvaddr, PGSIZE)`，将父进程该物理页内的全部 4096 字节（PGSIZE）数据，复制到子进程新分配的物理页中。
- 调用 `page_insert(to, npage, start, perm)` 更新子进程的页表，在子进程的页表 `to`中，把虚拟地址 `start` 映射到物理页 `npage`，同时赋予它权限 `perm`。

如何设计实现`Copy on Write`机制？给出概要设计，鼓励给出详细设计。

当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面，这样一个进程所做的修改不会被另外一个进程可见。

- 修改 `do_fork` 调用的 `copy_range` 函数，实现共享映射和只读权限设置，不再为子进程分配新的物理页，而是将子进程的虚拟地址映射到父进程的同一个物理页，并把权限全部设置为只读。
- 增加缺页异常处理，需要判断并处理 COW 异常，当进程修改此用户内存空间中的页面时触发一次，如果只有当前进程在使用该物理页，则无需复制，直接恢复写权限；如果引用计数大一1，则需要申请新物理页并复制数据，建立新映射，加上写权限。

## 练习3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）

请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：

- 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
- 请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）

执行：make grade。如果所显示的应用程序检测都输出ok，则基本正确。（使用的是qemu-1.0.1）

## 扩展练习 Challenge1

实现 Copy on Write （COW）机制

给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。

这是一个big challenge.

## 扩展练习 Challenge2


说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？
