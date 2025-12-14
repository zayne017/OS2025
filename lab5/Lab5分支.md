## 分支任务：gdb调试系统调用以及返回

## ecall

终端 1 (QEMU): `make debug` (启动并挂起)

终端 2 (硬件调试):

```
pgrep -a qemu       # 找 PID
sudo gdb            # 进 GDB
attach <PID>        # 连 QEMU
handle SIGPIPE nostop noprint
continue            # 让它先跑起来等待
```

终端 3 (内核调试):

```
make gdb
set remotetimeout unlimited
```

```
add-symbol-file obj/__user_exit.out
```

由于 `syscall` 代码属于用户态程序，默认的 `kernel` 符号表不包含此信息。手动加载用户符号表后，GDB 成功识别了 `user/libs/syscall.c`，允许我们在此处设置断点。

```
 break user/libs/syscall.c:18
 c
```

- 在 `syscall` 函数入口断点停下。

- 利用 `x/8i $pc` 查看汇编指令流，发现程序正在通过 `ld` (Load) 指令将参数加载到 `a0`-`a5` 寄存器中。

- 通过连续6次使用 `si` (Step Instruction) 单步执行，精准控制 CPU 执行流。

```
(gdb) x/8i $pc
=> 0x8000f8 <syscall+32>:	ld	a0,8(sp)
   0x8000fa <syscall+34>:	ld	a1,40(sp)
   0x8000fc <syscall+36>:	ld	a2,48(sp)
   0x8000fe <syscall+38>:	ld	a3,56(sp)
   0x800100 <syscall+40>:	ld	a4,64(sp)
   0x800102 <syscall+42>:	ld	a5,72(sp)
   0x800104 <syscall+44>:	ecall
   0x800108 <syscall+48>:	sd	a0,28(sp)
```

最终停在了地址 `0x800104` 处，此时下一条待执行指令正是 `ecall`，用户态参数已就位，只待跳转。

```
(gdb) x/8i $pc
=> 0x800104 <syscall+44>:	ecall
   0x800108 <syscall+48>:	sd	a0,28(sp)
   0x80010c <syscall+52>:	lw	a0,28(sp)
   0x80010e <syscall+54>:	addi	sp,sp,144
   0x800110 <syscall+56>:	ret
   0x800112 <sys_exit>:	mv	a1,a0
   0x800114 <sys_exit+2>:	li	a0,1
   0x800116 <sys_exit+4>:	j	0x8000d8 <syscall>
```

在终端2：

先ctrlc，之后设置了条件断点：

```
break riscv_raise_exception if exception == 8
```

设置断点：

```
break riscv_cpu_do_interrupt
```

按c继续。

拦截 User Mode Ecall (异常号 8)，之后在终端3按下 `si` 执行 `ecall` 后，硬件端断点立即触发，停在 `riscv_raise_exception` 函数入口。

```
(gdb) c
Continuing.
[Switching to Thread 0x7cc51ffff6c0 (LWP 4769)]

Thread 2 "qemu-system-ris" hit Breakpoint 1, riscv_raise_exception (
    env=0x5ffe0994abb0, exception=8, pc=0)
    at /home/a/qemu-4.1.1/target/riscv/op_helper.c:31
31	    CPUState *cs = env_cpu(env);
```

验证异常号

```
(gdb) p exception
$1 = 8
```

8 代表 `RISCV_EXCP_U_ECALL` ，抓住了用户态程序向内核发起的那个“请求”瞬间。

之后按c，并按了两次n，直到 `env` 被赋值。

```
(gdb) p env->priv
$2 = 0
```

`env` (Environment)： 这是 QEMU 模拟器里最重要的一个指针。 在 QEMU 的源码里，每一个虚拟 CPU 都有一个结构体叫 `CPURISCVState`（RISC-V CPU 状态），而在代码里通常用指针变量 `env` 来指向它。

`priv` (Privilege Level)： 这是结构体里的一个成员变量，代表 “当前特权级”。 QEMU 就是靠读取这个变量的值，来决定 CPU 现在能干什么、不能干什么。3代表M态，2是S态，1是U态。

结论：`priv=0` 证明 CPU 当前确实处于 用户态 (U-Mode)。

在终端2继续执行 `finish` 指令，让 QEMU 跑完整个 `riscv_cpu_do_interrupt` 函数（模拟硬件电路的动作）。

```
(gdb) finish
Run till exit from #0  riscv_cpu_do_interrupt (cs=0x5ffe099421a0)
    at /home/a/qemu-4.1.1/target/riscv/cpu_helper.c:513
cpu_handle_exception (cpu=0x5ffe099421a0, ret=0x7cc51fffe97c)
    at /home/a/qemu-4.1.1/accel/tcg/cpu-exec.c:507
507	            qemu_mutex_unlock_iothread();
```

函数返回后退出了 `env` 变量的作用域。我们使用了强制类型转换 `((RISCVCPU *)cpu)->env` 重新获取了 CPU 上下文。

证据 1 (特权级切换)：

```
(gdb) p ((RISCVCPU *)cpu)->env.priv
$3 = 1
```

结论：`priv` 从 0 变为 1，证明 CPU 已成功切换至 内核态 (S-Mode)。

证据 2 (现场保存 SEPC)：

```
(gdb) p /x ((RISCVCPU *)cpu)->env.sepc
$4 = 0x800104
```

结论：`sepc` 寄存器精准记录了触发异常的 `ecall` 指令地址 (`0x800104`)，确保未来 `sret` 能正确返回。

证据 3 (中断跳转 PC)：

```
(gdb) p /x ((RISCVCPU *)cpu)->env.pc
$5 = 0xffffffffc0200e44
```

结论：PC 指针已指向内核高地址空间（中断向量表入口），控制权已正式移交给 uCore 内核。

qemu源码：

核心函数一：`riscv_raise_exception` (抛出异常)

- 文件位置：`target/riscv/op_helper.c`
- 触发时机：`ecall` 指令执行时被调用。
- 功能：这是一个“二传手”。它接收翻译阶段传来的异常号（本实验中为 `RISCV_EXCP_U_ECALL = 8`），并将异常状态标记在 CPU 的环境结构体 (`env`) 中，随后通知 CPU 主循环“出事了，需要处理中断”。

```
void helper_raise_exception(CPURISCVState *env, uint32_t exception)
{
    riscv_raise_exception(env, exception, 0);
}
```

核心函数二：`riscv_cpu_do_interrupt` (处理中断)

- 文件位置：`target/riscv/cpu_helper.c`
- 触发时机：CPU 主循环检测到有异常挂起时调用。这是模拟硬件电路行为的核心函数。
- 功能：它负责执行 RISC-V 硬件手册规定的所有“Trap 发生时硬件自动完成的动作”。

在最后面的位置：

```
void riscv_cpu_do_interrupt(CPUState *cs)
```

核心部分：

```
/* 检查是否应该交给 S 模式处理 (uCore 内核就在 S 模式) */
if (env->priv <= PRV_S &&
    cause < TARGET_LONG_BITS && ((deleg >> cause) & 1)) {
    
    /* handle the trap in S-mode */
    
    // 1. 保存当前状态到 mstatus (SPIE, SPP)
    target_ulong s = env->mstatus;
    s = set_field(s, MSTATUS_SPIE, ...);
    s = set_field(s, MSTATUS_SPP, env->priv); // 【重点】记录之前的特权级 (0=User)
    env->mstatus = s;

    // 2. 更新 scause (异常原因)
    // 【对应 GDB】p env->scause -> 8
    env->scause = cause | ((target_ulong)async << (TARGET_LONG_BITS - 1));
    
    // 3. 保存现场 SEPC
    // 【对应 GDB】p env->sepc -> 0x800104 (ecall 的地址)
    env->sepc = env->pc;
    
    // 4. 更新 PC 跳转到中断入口 (stvec)
    // 【对应 GDB】p env->pc -> 0xffffffffc020xxxx (内核入口)
    env->pc = (env->stvec >> 2 << 2) + ...;
    
    // 5. 切换特权级 (变身！)
    // 【对应 GDB】p env->priv -> 1 (Supervisor)
    riscv_cpu_set_mode(env, PRV_S);

} else {
    /* 否则交给 M 模式处理 (OpenSBI 等固件) */
    ...
}
```

在 `riscv_cpu_do_interrupt` 函数中，QEMU 首先检查 `medeleg` (委托寄存器)。由于 uCore 运行在 S 模式，且 `ecall` 异常被委托给了 S 模式，代码进入了第一个 `if` 分支。

在这个分支内，我们观测到了与 GDB 调试完全一致的行为：

1. `env->sepc = env->pc;` 保存了触发异常的 `ecall` 地址。
2. `riscv_cpu_set_mode(env, PRV_S);` 将 CPU 特权级从 User (0) 提升到了 Supervisor (1)。

## sret

终端 1 (QEMU): `make debug` (启动并挂起)

终端 2 (硬件调试):

```
pgrep -a qemu       # 找 PID
sudo gdb            # 进 GDB
attach <PID>        # 连 QEMU
handle SIGPIPE nostop noprint
continue            # 让它先跑起来等待
```

终端 3 (内核调试):

```
make gdb
set remotetimeout unlimited
```

```
add-symbol-file obj/__user_exit.out
```

在内核 GDB 中设置断点拦截系统调用

```
b user/libs/syscall.c:syscall
c
p num #系统调用号
```

结果如下：

```
(gdb) b user/libs/syscall.c:syscall
Breakpoint 1 at 0x8000d8: file user/libs/syscall.c, line 15.
(gdb) c
Continuing.

Breakpoint 1, syscall (num=2) at user/libs/syscall.c:15
15	        a[i] = va_arg(ap, uint64_t);
(gdb) p num
$1 = 2
(gdb) 
```

定位中断返回代码段 `__trapret`，并查找 `sret` 指令的确切地址：

```
b __trapret
c
x/40i $pc  # 查看汇编，一直往下翻找到最后一行 sret 的地址 是0xffffffffc0200f0a
```

在 `sret` 指令处设置硬件断点：

```
b *0xffffffffc0200f0a
c
```

此时 CPU 停在执行 `sret` 指令的前一刻。

```
(gdb) b *0xffffffffc0200f0a
Breakpoint 2 at 0xffffffffc0200f0a: file kern/trap/trapentry.S, line 133.
(gdb) c
Continuing.

Breakpoint 2, __trapret () at kern/trap/trapentry.S:133
133	    sret
(gdb) 
```

在终端 2（硬件 GDB）中拦截 QEMU 模拟 `sret` 指令的辅助函数 `helper_sret`：

```
(gdb) Ctrl+C
(gdb) break helper_sret
(gdb) c
```

在终端 3 输入 `si`（单步执行指令），触发终端 2 的断点。

在终端 2 中观测 CPU 特权级结构体 `env->priv` 的变化：

执行前，$1 = 1  此时 CPU 处于 Supervisor Mode

```
(gdb) c
Continuing.
[Switching to Thread 0x7a78b9bff6c0 (LWP 6191)]

Thread 2 "qemu-system-ris" hit Breakpoint 1, helper_sret (env=0x63d8b5813bb0, 
    cpu_pc_deb=18446744072637910794)
    at /home/a/qemu-4.1.1/target/riscv/op_helper.c:76
76	    if (!(env->priv >= PRV_S)) {
(gdb) p env->priv
$1 = 1
(gdb) 
```

输入 `n` 单步执行 C 代码，直到执行完 `riscv_cpu_set_mode(env, prev_priv);`。

执行完观测

```
97	    mstatus = set_field(mstatus, MSTATUS_SPP, PRV_U);
(gdb) 
98	    riscv_cpu_set_mode(env, prev_priv);
(gdb) 
99	    env->mstatus = mstatus;
(gdb) p env->priv
$2 = 0  # 此时 CPU 成功切换回 User Mode
```

证实 `sret` 指令正确读取了 `mstatus` 中的 `SPP` 位（此时为 User），并将 CPU 当前特权级从 1 降为 0，完成了从内核到用户的切换。

qemu源码：

```
target_ulong helper_sret(CPURISCVState *env, target_ulong cpu_pc_deb)
{
    // 【1. 权限与合法性检查】
    // 检查当前特权级：sret 指令只能在 Supervisor (内核态) 或更高权限下执行
    // 如果用户态程序(U-Mode)尝试执行此指令，将抛出非法指令异常
    if (!(env->priv >= PRV_S)) {
        riscv_raise_exception(env, RISCV_EXCP_ILLEGAL_INST, GETPC());
    }

    // 【2. 获取返回地址】
    // 从 sepc (Supervisor Exception Program Counter) 寄存器中读取要跳回的地址
    // 通常这里存放的是系统调用指令 ecall 的下一条指令地址
    target_ulong retpc = env->sepc;
    if (!riscv_has_ext(env, RVC) && (retpc & 0x3)) {
        riscv_raise_exception(env, RISCV_EXCP_INST_ADDR_MIS, GETPC());
    }

    // (检查 mstatus 的 TSR 位，若置位则禁止 S 模式执行 sret，此处略过)
    if (env->priv_ver >= PRIV_VERSION_1_10_0 &&
        get_field(env->mstatus, MSTATUS_TSR)) {
        riscv_raise_exception(env, RISCV_EXCP_ILLEGAL_INST, GETPC());
    }

    // 【3. 准备恢复上下文】
    target_ulong mstatus = env->mstatus;
    // 读取 SPP (Supervisor Previous Privilege) 位
    // 这一位记录了进入内核前 CPU 是什么模式（本实验中应为 0，即 User Mode）
    target_ulong prev_priv = get_field(mstatus, MSTATUS_SPP);

    // 【4. 恢复中断使能状态】
    // 将 SPIE (进入内核前的中断状态) 的值 恢复给 SIE (当前中断使能位)
    // 这意味着如果用户态之前允许中断，返回后也会允许中断
    mstatus = set_field(mstatus,
        env->priv_ver >= PRIV_VERSION_1_10_0 ?
        MSTATUS_SIE : MSTATUS_UIE << prev_priv,
        get_field(mstatus, MSTATUS_SPIE));

    // 【5. 重置 mstatus 状态位】
    // 清空 SPIE 位，并将 SPP 位重置为 User Mode，为下一次 Trap 做准备
    mstatus = set_field(mstatus, MSTATUS_SPIE, 0);
    mstatus = set_field(mstatus, MSTATUS_SPP, PRV_U);

    // 【6. 执行特权级切换 (关键)】
    // 调用函数将 CPU 的当前特权级 (env->priv) 修改为 prev_priv
    // 在本实验中，此处观察到 env->priv 从 1 (S-Mode) 变为 0 (U-Mode)
    riscv_cpu_set_mode(env, prev_priv);
    
    // 将更新后的 mstatus 值写回寄存器
    env->mstatus = mstatus;

    // 【7. 跳转返回】
    // 函数返回 retpc，QEMU 将 PC 指针指向此地址，程序控制流回到用户态
    return retpc;
}
```

代码分析总结： `helper_sret` 函数完整模拟了 RISC-V 硬件执行 `sret` 指令的逻辑。

1. 安全性：首先确保指令是在内核态执行，否则抛出异常。
2. 原子性恢复：它从 `sepc` 获取返回地址，并根据 `mstatus` 中的 `SPP` 位恢复之前的特权级（在我们的调试中，`prev_priv` 为 0）。
3. 核心切换：`riscv_cpu_set_mode` 函数是实现特权级切换的关键，执行该行代码后，CPU 正式从 Supervisor Mode 降级回 User Mode，同时恢复了用户程序的中断响应能力。