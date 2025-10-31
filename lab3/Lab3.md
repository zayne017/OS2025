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





