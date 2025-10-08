# Lab1

# 练习1：理解内核启动中的程序入口操作
阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？

la sp, bootstacktop：la指令用于把地址加载到寄存器，将bootstacktop的地址加载到sp寄存器中，为内核设置初始栈指针，为内核设置栈空间，支持后面函数的正常调用。
tail kern_init：tail指令表示无返回地跳转到另一个函数，跳转到内核初始化函数kern_init开始初始化工作，并不会返回，函数kern_init用于进行初始化内核环境和向用户提供可视化反馈。

# 练习2: 使用GDB验证启动流程

