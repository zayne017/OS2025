## Lab3

 ## 练习1：完善中断处理 

请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

在trap.c前面添加#include<sbi.h>，之后在对应位置填写代码：

```
case IRQ_S_TIMER:
             /* LAB3 EXERCISE1   YOUR CODE : 2213523 */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();//下次中断
            ticks++;
            static int count = 0;//计数器
                if (ticks == 100) {    
                print_ticks();
                ticks = 0;  //重置计数器
                count++;}
                if (count == 10) {
                sbi_shutdown();}//输出十行后关闭
```

首先通过调用clock_set_next_event()设置下次中断，再将计数器加一，count表示打印次数，当计数器加到100的时候，会输出一个100ticks表示触发了100次时钟中断，同时打印次数加一，当打印次数为10时调用sbi_shutdown()关闭。

定时器中断处理流程：

1.首先进行时钟初始化，当操作系统启动时，clock_init() 函数会被调用，`set_csr(sie, MIP_STIP);`用于开始使能时钟中断，`clock_set_next_event();`设置第一次时钟中断，`ticks = 0;`初始化全局中断计数器

2.中断触发，`clock_set_next_event()`设置第一次中断，触发中断， CPU 接收到信号，发现是 `IRQ_S_TIMER`，于是暂停当前工作，跳转到 `interrupt_handler` 处理

3.中断处理，CPU 进入 `interrupt_handler` 函数：

1）`switch (cause)`：CPU 通过 `cause` 寄存器判断出中断类型是 `IRQ_S_TIMER`（S模式时钟中断）。

2）`case IRQ_S_TIMER:` 分支被执行，运行刚刚的代码处理中断

3）中断返回，`case` 执行完毕，`interrupt_handler` 返回，CPU 恢复现场，返回到被中断前的地方继续执行。

4.循环，每秒100次时钟中断，触发每次时钟中断后，设置10ms后触发下一次时钟中断，之后再次重复中断触发和中断处理过程，每触发100次时钟中断（1秒钟）输出一行信息到控制台，直到输出十行100ticks，调用关机函数关机。

## 扩展练习 Challenge1：描述与理解中断流程

回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

### 问题一 处理中断流程
```
1、CPU检测到异常或中断事件，自动保存现场到CSR寄存器：
 sepc ← 当前PC（异常返回地址）
 scause ← 异常原因编码（最高位：0=异常，1=中断）
 stval ← 附加信息（如缺页地址、非法指令值）
 sstatus ← 状态信息（SPP位记录先前模式），跳转到stvec寄存器指向的异常向量表
2、
    SAVE_ALL        # 保存完整上下文到栈
    move a0, sp     # 传递trapframe指针给C函数
    jal trap        # 跳转到C语言分发器
SAVE_ALL保存内容：所有通用寄存器 x0-x31，4个关键CSR：sstatus, sepc, sbadaddr, scause，栈帧构成完整的struct trapframe
3、中断和异常区分（trap.c）
void trap(struct trapframe *tf) {
    trap_dispatch(tf);  // 核心分发函数
}
static inline void trap_dispatch(struct trapframe *tf) {
    // 根据scause最高位区分中断和异常
    if ((intptr_t)tf->cause < 0) {
        interrupt_handler(tf);    // 中断处理
    } else {
        exception_handler(tf);    // 异常处理
    }
}
4、中断处理流程（interrupt_handler）
case IRQ_S_TIMER:  //  supervisor timer interrupt
            // 1. 设置下次时钟中断
            clock_set_next_event();
            // 2. 更新系统时钟滴答
            ticks++;
            // 3. 每100个ticks打印信息
            static int count = 0;
            if (ticks % TICK_NUM == 0) {
                print_ticks();
                count++;
            }
            // 4. 打印10次后关机
            if (count == 10) {
                sbi_shutdown();
            }
            break;
5. 异常处理流程（exception_handler）
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_ILLEGAL_INSTRUCTION:
             * 处理逻辑:
             * 1. 打印异常类型和出错位置
             * 2. 通过tf->epc += 4跳过当前非法指令
            cprintf("Exception type: Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            tf->epc += 4;  // 跳过非法指令，继续执行下一条
            break;
        case CAUSE_BREAKPOINT:
             * 1. 识别并打印断点信息
             * 2. 跳过ebreak指令继续执行
             * 3. 在实际调试器中会在此暂停执行并进入调试状态
            cprintf("Exception type: breakpoint\n");
            cprintf("Breakpoint at 0x%08x\n", tf->epc);
            tf->epc += 4;  // 跳过断点指令
            break; 
        case CAUSE_MISALIGNED_FETCH:
             * 取指地址不对齐异常
             * 触发场景: 指令地址不是4字节对齐的(如0x1001)
             * 当前实现: 预留处理接口
            break;
        case CAUSE_FAULT_FETCH:
             * 取指错误异常  
            break;  
        case CAUSE_MISALIGNED_LOAD:
             * 加载地址不对齐异常
             * 示例: lw x1, 0x1001(x0) - 地址0x1001不是4字节对齐
             * 当前实现: 预留处理接口  
            break;  
        case CAUSE_FAULT_LOAD:
             * 加载错误异常
             * - 加载地址无效(如空指针访问)
             * - 页面错误(缺页异常)  
             * - 权限不足(读取只写内存)
             * 示例: int value = *((int*)0); // 访问空指针
             * 当前实现: 预留处理接口
            break;   
        case CAUSE_MISALIGNED_STORE: 
             * 存储地址不对齐异常
             * 触发场景: 存储指令(sw/sh/sb)地址不符合对齐要求  
             * 示例: sw x1, 0x1001(x0) - 地址0x1001不是4字节对齐
             * 当前实现: 预留处理接口
             */
            // 内存访问异常处理 - 待实现
            break;
        case CAUSE_FAULT_STORE:
             * 存储错误异常
             * 示例: *((int*)0) = 123; // 写入空指针
             * 当前实现: 预留处理接口
            break;
        case CAUSE_SUPERVISOR_ECALL:
             * 监督模式系统调用异常
            break;
        default:
            print_trapframe(tf);  // 未知异常，打印详细信息
            break;
    }
    /*
     * 函数返回后执行流程:
     * 1. 返回到trap_dispatch() → trap()
     * 2. 回到汇编代码__trapret标签
     * 3. RESTORE_ALL从栈中恢复所有寄存器(包括修改后的epc)
     * 4. sret指令跳转到epc指向的地址恢复执行
     * 
     * EPC管理策略总结:
     * - 可恢复异常: epc += 4 跳过当前指令
     * - 需重试异常: 保持epc不变，重试当前指令(如缺页处理)
     * - 严重异常: 可能终止进程，不返回
     */
}
6、恢复阶段（__trapret）
  __trapret:
     RESTORE_ALL   # 从栈中恢复所有寄存器
      sret          # 返回到异常前状态
  恢复sstatus ← 保存的状态，恢复sepc ← 返回地址（可能被异常处理修改），恢复所有通用寄存器，sret指令返回到sepc指向的地址
```
### 问题二
mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？
```
move a0, sp的目的
目的：将栈指针sp的值作为参数传递给trap函数。在SAVE_ALL之后，sp指向保存的trapframe结构体，trapframe包含了所有寄存器的保存值，是异常处理的上下文，通过move a0, sp将trapframe指针作为第一个参数（a0寄存器）传递给trap函数，这样在C代码中就可以通过struct trapframe *tf参数来访问和修改寄存器状态

SAVE_ALL中寄存器栈位置确定方式：
按照预定义的偏移量顺序排列

需要保存所有寄存器，理由如下：
异常处理程序不知道具体是哪种异常/中断，必须为所有可能的异常类型做好准备。某些异常处理可能需要修改寄存器值（如系统调用），异常返回时必须完全恢复执行现场，缺少任何寄存器都会导致程序状态不一致。嵌套异常处理：在处理一个异常时可能发生另一个异常，完整的上下文保存确保嵌套异常能正确处理。

```

## 扩展练习 Challenge2：理解上下文切换机制

回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

### 问题一 操作目的
```
csrw sscratch, sp
```
将当前sp保存到sscratch寄存器。
目的是在异常发生时，立即将当前栈指针(sp)保存到sscratch寄存器。因为异常处理需要使用新的栈空间，但需要记住原来的栈位置以便恢复

```
csrrw s0, sscratch, x0   
```
将sscratch的值读到s0，同时将sscratch清零,x0是零寄存器
这是一个原子操作，避免多线程环境下的竞争条件
可以用一个伪代码解释这样设计的目的
```c
original_sp = sscratch;    // 保存原始sp
sscratch = 0;              // 标记"当前在内核模式"
if (sscratch == 0) {
    // 异常发生在内核模式，使用当前内核栈
} else {
    // 异常发生在用户模式，sscratch保存了用户栈指针
    // 需要切换到内核栈
}
```

### 问题二 CSR
scause是只读寄存器​​，记录异常原因，处理完即失效，因此不需要恢复。
​sbadaddr (stval)是只读寄存器​​，记录异常相关地址（如缺页地址）、一次性信息，因此不需要恢复。
首先，当异常中断发生时，这些寄存器记录的内容对调试很重要（可以直接打印出来）。
其次，他们也参与到中断处理的决策中，在trap.c中
```
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
            .......//省略
            break;
    }
}
```
根据保存的scause来进行决策


## 扩展练习Challenge3：完善异常中断


编程完善在触发一条非法指令异常和断点异常，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。

首先要触发非法指令异常和断点异常，在init.c中加入两条内联汇编，用来触发非法指令异常和断点异常，要在intr_enable()后添加，确保系统已经准备就绪：

```
asm("mret");
asm("ebreak");
```

`mret`是M模式的特权指令，用于从M模式返回S模式，而此时我们正在S模式，在S模式执行M模式指令就会触发非法指令异常

`ebreak`指令则会触发一个断点异常

接下来在trap.c的异常处理函数中填写代码进行处理，需要先打印出异常的类型，还有异常指令地址，再更新tf->epc寄存器

这里本来直接都用tf->epc+=4来更新，但是在测试ebreak的时候出现问题，在输出断点异常后又去执行后面的print_trapframe(tf)打印了所有的寄存器，查询发现ebreak是一个压缩指令只有2字节，这样epc更新到错误的地方就会进入default，解决方法可以是在前面添加一个判断指令长度的函数，然后根据实际指令长度更新epc的值：

```
static inline int get_inst_len(uintptr_t pc) {
uint16_t inst = *(uint16_t *)pc;
//把地址强制转换为指向16位整数的指针并解引用 读取地址的前2位
return ((inst & 0x3) == 0x3) ? 4 : 2;
//0x3的二进制是11 如果最低2位是11则为4字节标准指令，反之为2字节压缩指令}

case CAUSE_ILLEGAL_INSTRUCTION:
// 非法指令异常处理
/* LAB3 CHALLENGE3   YOUR CODE : 2213523 */
/*(1)输出指令异常类型（ Illegal instruction）
*(2)输出异常指令地址
*(3)更新 tf->epc寄存器
*/
cprintf("Exception type:Illegal instruction\n");
cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
tf->epc += get_inst_len(tf->epc);
break;
case CAUSE_BREAKPOINT:
//断点异常处理
/* LAB3 CHALLLENGE3   YOUR CODE : 2213523 */
/*(1)输出指令异常类型（ breakpoint）
*(2)输出异常指令地址
*(3)更新 tf->epc寄存器
*/
cprintf("Exception type: breakpoint\n");
cprintf("ebreak caught at 0x%08x\n", tf->epc);
tf->epc += get_inst_len(tf->epc);
break;
```

修改后一切正常，执行qemu后结果如下：

![lab2](./lab3_1.png)

## 知识点总结






