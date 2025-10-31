
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	76b010ef          	jal	ra,ffffffffc0201fd6 <memset>
    dtb_init();
ffffffffc0200070:	414000ef          	jal	ra,ffffffffc0200484 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	402000ef          	jal	ra,ffffffffc0200476 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f7050513          	addi	a0,a0,-144 # ffffffffc0201fe8 <etext>
ffffffffc0200080:	096000ef          	jal	ra,ffffffffc0200116 <cputs>

    print_kerninfo();
ffffffffc0200084:	0e2000ef          	jal	ra,ffffffffc0200166 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b8000ef          	jal	ra,ffffffffc0200840 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	7ce010ef          	jal	ra,ffffffffc020185a <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7b0000ef          	jal	ra,ffffffffc0200840 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	3a0000ef          	jal	ra,ffffffffc0200434 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	79c000ef          	jal	ra,ffffffffc0200834 <intr_enable>
asm("mret");
ffffffffc020009c:	30200073          	mret
asm("ebreak");
ffffffffc02000a0:	9002                	ebreak
    while (1)
ffffffffc02000a2:	a001                	j	ffffffffc02000a2 <kern_init+0x4e>

ffffffffc02000a4 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000a4:	1141                	addi	sp,sp,-16
ffffffffc02000a6:	e022                	sd	s0,0(sp)
ffffffffc02000a8:	e406                	sd	ra,8(sp)
ffffffffc02000aa:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ac:	3cc000ef          	jal	ra,ffffffffc0200478 <cons_putc>
    (*cnt) ++;
ffffffffc02000b0:	401c                	lw	a5,0(s0)
}
ffffffffc02000b2:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000b4:	2785                	addiw	a5,a5,1
ffffffffc02000b6:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b8:	6402                	ld	s0,0(sp)
ffffffffc02000ba:	0141                	addi	sp,sp,16
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000be:	1101                	addi	sp,sp,-32
ffffffffc02000c0:	862a                	mv	a2,a0
ffffffffc02000c2:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c4:	00000517          	auipc	a0,0x0
ffffffffc02000c8:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a4 <cputch>
ffffffffc02000cc:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d2:	1d5010ef          	jal	ra,ffffffffc0201aa6 <vprintfmt>
    return cnt;
}
ffffffffc02000d6:	60e2                	ld	ra,24(sp)
ffffffffc02000d8:	4532                	lw	a0,12(sp)
ffffffffc02000da:	6105                	addi	sp,sp,32
ffffffffc02000dc:	8082                	ret

ffffffffc02000de <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000de:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e0:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000e4:	8e2a                	mv	t3,a0
ffffffffc02000e6:	f42e                	sd	a1,40(sp)
ffffffffc02000e8:	f832                	sd	a2,48(sp)
ffffffffc02000ea:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ec:	00000517          	auipc	a0,0x0
ffffffffc02000f0:	fb850513          	addi	a0,a0,-72 # ffffffffc02000a4 <cputch>
ffffffffc02000f4:	004c                	addi	a1,sp,4
ffffffffc02000f6:	869a                	mv	a3,t1
ffffffffc02000f8:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000fa:	ec06                	sd	ra,24(sp)
ffffffffc02000fc:	e0ba                	sd	a4,64(sp)
ffffffffc02000fe:	e4be                	sd	a5,72(sp)
ffffffffc0200100:	e8c2                	sd	a6,80(sp)
ffffffffc0200102:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200104:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200106:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200108:	19f010ef          	jal	ra,ffffffffc0201aa6 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010c:	60e2                	ld	ra,24(sp)
ffffffffc020010e:	4512                	lw	a0,4(sp)
ffffffffc0200110:	6125                	addi	sp,sp,96
ffffffffc0200112:	8082                	ret

ffffffffc0200114 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200114:	a695                	j	ffffffffc0200478 <cons_putc>

ffffffffc0200116 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200116:	1101                	addi	sp,sp,-32
ffffffffc0200118:	e822                	sd	s0,16(sp)
ffffffffc020011a:	ec06                	sd	ra,24(sp)
ffffffffc020011c:	e426                	sd	s1,8(sp)
ffffffffc020011e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200120:	00054503          	lbu	a0,0(a0)
ffffffffc0200124:	c51d                	beqz	a0,ffffffffc0200152 <cputs+0x3c>
ffffffffc0200126:	0405                	addi	s0,s0,1
ffffffffc0200128:	4485                	li	s1,1
ffffffffc020012a:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020012c:	34c000ef          	jal	ra,ffffffffc0200478 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200130:	00044503          	lbu	a0,0(s0)
ffffffffc0200134:	008487bb          	addw	a5,s1,s0
ffffffffc0200138:	0405                	addi	s0,s0,1
ffffffffc020013a:	f96d                	bnez	a0,ffffffffc020012c <cputs+0x16>
    (*cnt) ++;
ffffffffc020013c:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200140:	4529                	li	a0,10
ffffffffc0200142:	336000ef          	jal	ra,ffffffffc0200478 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200146:	60e2                	ld	ra,24(sp)
ffffffffc0200148:	8522                	mv	a0,s0
ffffffffc020014a:	6442                	ld	s0,16(sp)
ffffffffc020014c:	64a2                	ld	s1,8(sp)
ffffffffc020014e:	6105                	addi	sp,sp,32
ffffffffc0200150:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200152:	4405                	li	s0,1
ffffffffc0200154:	b7f5                	j	ffffffffc0200140 <cputs+0x2a>

ffffffffc0200156 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200156:	1141                	addi	sp,sp,-16
ffffffffc0200158:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020015a:	326000ef          	jal	ra,ffffffffc0200480 <cons_getc>
ffffffffc020015e:	dd75                	beqz	a0,ffffffffc020015a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200160:	60a2                	ld	ra,8(sp)
ffffffffc0200162:	0141                	addi	sp,sp,16
ffffffffc0200164:	8082                	ret

ffffffffc0200166 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200166:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200168:	00002517          	auipc	a0,0x2
ffffffffc020016c:	ea050513          	addi	a0,a0,-352 # ffffffffc0202008 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200170:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200172:	f6dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200176:	00000597          	auipc	a1,0x0
ffffffffc020017a:	ede58593          	addi	a1,a1,-290 # ffffffffc0200054 <kern_init>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	eaa50513          	addi	a0,a0,-342 # ffffffffc0202028 <etext+0x40>
ffffffffc0200186:	f59ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020018a:	00002597          	auipc	a1,0x2
ffffffffc020018e:	e5e58593          	addi	a1,a1,-418 # ffffffffc0201fe8 <etext>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	eb650513          	addi	a0,a0,-330 # ffffffffc0202048 <etext+0x60>
ffffffffc020019a:	f45ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020019e:	00007597          	auipc	a1,0x7
ffffffffc02001a2:	e8a58593          	addi	a1,a1,-374 # ffffffffc0207028 <free_area>
ffffffffc02001a6:	00002517          	auipc	a0,0x2
ffffffffc02001aa:	ec250513          	addi	a0,a0,-318 # ffffffffc0202068 <etext+0x80>
ffffffffc02001ae:	f31ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b2:	00007597          	auipc	a1,0x7
ffffffffc02001b6:	2ee58593          	addi	a1,a1,750 # ffffffffc02074a0 <end>
ffffffffc02001ba:	00002517          	auipc	a0,0x2
ffffffffc02001be:	ece50513          	addi	a0,a0,-306 # ffffffffc0202088 <etext+0xa0>
ffffffffc02001c2:	f1dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c6:	00007597          	auipc	a1,0x7
ffffffffc02001ca:	6d958593          	addi	a1,a1,1753 # ffffffffc020789f <end+0x3ff>
ffffffffc02001ce:	00000797          	auipc	a5,0x0
ffffffffc02001d2:	e8678793          	addi	a5,a5,-378 # ffffffffc0200054 <kern_init>
ffffffffc02001d6:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001de:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e0:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e4:	95be                	add	a1,a1,a5
ffffffffc02001e6:	85a9                	srai	a1,a1,0xa
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	ec050513          	addi	a0,a0,-320 # ffffffffc02020a8 <etext+0xc0>
}
ffffffffc02001f0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f2:	b5f5                	j	ffffffffc02000de <cprintf>

ffffffffc02001f4 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f4:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f6:	00002617          	auipc	a2,0x2
ffffffffc02001fa:	ee260613          	addi	a2,a2,-286 # ffffffffc02020d8 <etext+0xf0>
ffffffffc02001fe:	04d00593          	li	a1,77
ffffffffc0200202:	00002517          	auipc	a0,0x2
ffffffffc0200206:	eee50513          	addi	a0,a0,-274 # ffffffffc02020f0 <etext+0x108>
void print_stackframe(void) {
ffffffffc020020a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020c:	1cc000ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc0200210 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200210:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200212:	00002617          	auipc	a2,0x2
ffffffffc0200216:	ef660613          	addi	a2,a2,-266 # ffffffffc0202108 <etext+0x120>
ffffffffc020021a:	00002597          	auipc	a1,0x2
ffffffffc020021e:	f0e58593          	addi	a1,a1,-242 # ffffffffc0202128 <etext+0x140>
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	f0e50513          	addi	a0,a0,-242 # ffffffffc0202130 <etext+0x148>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020022c:	eb3ff0ef          	jal	ra,ffffffffc02000de <cprintf>
ffffffffc0200230:	00002617          	auipc	a2,0x2
ffffffffc0200234:	f1060613          	addi	a2,a2,-240 # ffffffffc0202140 <etext+0x158>
ffffffffc0200238:	00002597          	auipc	a1,0x2
ffffffffc020023c:	f3058593          	addi	a1,a1,-208 # ffffffffc0202168 <etext+0x180>
ffffffffc0200240:	00002517          	auipc	a0,0x2
ffffffffc0200244:	ef050513          	addi	a0,a0,-272 # ffffffffc0202130 <etext+0x148>
ffffffffc0200248:	e97ff0ef          	jal	ra,ffffffffc02000de <cprintf>
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	f2c60613          	addi	a2,a2,-212 # ffffffffc0202178 <etext+0x190>
ffffffffc0200254:	00002597          	auipc	a1,0x2
ffffffffc0200258:	f4458593          	addi	a1,a1,-188 # ffffffffc0202198 <etext+0x1b0>
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	ed450513          	addi	a0,a0,-300 # ffffffffc0202130 <etext+0x148>
ffffffffc0200264:	e7bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    }
    return 0;
}
ffffffffc0200268:	60a2                	ld	ra,8(sp)
ffffffffc020026a:	4501                	li	a0,0
ffffffffc020026c:	0141                	addi	sp,sp,16
ffffffffc020026e:	8082                	ret

ffffffffc0200270 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200270:	1141                	addi	sp,sp,-16
ffffffffc0200272:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200274:	ef3ff0ef          	jal	ra,ffffffffc0200166 <print_kerninfo>
    return 0;
}
ffffffffc0200278:	60a2                	ld	ra,8(sp)
ffffffffc020027a:	4501                	li	a0,0
ffffffffc020027c:	0141                	addi	sp,sp,16
ffffffffc020027e:	8082                	ret

ffffffffc0200280 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200280:	1141                	addi	sp,sp,-16
ffffffffc0200282:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200284:	f71ff0ef          	jal	ra,ffffffffc02001f4 <print_stackframe>
    return 0;
}
ffffffffc0200288:	60a2                	ld	ra,8(sp)
ffffffffc020028a:	4501                	li	a0,0
ffffffffc020028c:	0141                	addi	sp,sp,16
ffffffffc020028e:	8082                	ret

ffffffffc0200290 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200290:	7115                	addi	sp,sp,-224
ffffffffc0200292:	ed5e                	sd	s7,152(sp)
ffffffffc0200294:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	f1250513          	addi	a0,a0,-238 # ffffffffc02021a8 <etext+0x1c0>
kmonitor(struct trapframe *tf) {
ffffffffc020029e:	ed86                	sd	ra,216(sp)
ffffffffc02002a0:	e9a2                	sd	s0,208(sp)
ffffffffc02002a2:	e5a6                	sd	s1,200(sp)
ffffffffc02002a4:	e1ca                	sd	s2,192(sp)
ffffffffc02002a6:	fd4e                	sd	s3,184(sp)
ffffffffc02002a8:	f952                	sd	s4,176(sp)
ffffffffc02002aa:	f556                	sd	s5,168(sp)
ffffffffc02002ac:	f15a                	sd	s6,160(sp)
ffffffffc02002ae:	e962                	sd	s8,144(sp)
ffffffffc02002b0:	e566                	sd	s9,136(sp)
ffffffffc02002b2:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b4:	e2bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b8:	00002517          	auipc	a0,0x2
ffffffffc02002bc:	f1850513          	addi	a0,a0,-232 # ffffffffc02021d0 <etext+0x1e8>
ffffffffc02002c0:	e1fff0ef          	jal	ra,ffffffffc02000de <cprintf>
    if (tf != NULL) {
ffffffffc02002c4:	000b8563          	beqz	s7,ffffffffc02002ce <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c8:	855e                	mv	a0,s7
ffffffffc02002ca:	756000ef          	jal	ra,ffffffffc0200a20 <print_trapframe>
ffffffffc02002ce:	00002c17          	auipc	s8,0x2
ffffffffc02002d2:	f72c0c13          	addi	s8,s8,-142 # ffffffffc0202240 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d6:	00002917          	auipc	s2,0x2
ffffffffc02002da:	f2290913          	addi	s2,s2,-222 # ffffffffc02021f8 <etext+0x210>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	00002497          	auipc	s1,0x2
ffffffffc02002e2:	f2248493          	addi	s1,s1,-222 # ffffffffc0202200 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc02002e6:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e8:	00002b17          	auipc	s6,0x2
ffffffffc02002ec:	f20b0b13          	addi	s6,s6,-224 # ffffffffc0202208 <etext+0x220>
        argv[argc ++] = buf;
ffffffffc02002f0:	00002a17          	auipc	s4,0x2
ffffffffc02002f4:	e38a0a13          	addi	s4,s4,-456 # ffffffffc0202128 <etext+0x140>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f8:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fa:	854a                	mv	a0,s2
ffffffffc02002fc:	32d010ef          	jal	ra,ffffffffc0201e28 <readline>
ffffffffc0200300:	842a                	mv	s0,a0
ffffffffc0200302:	dd65                	beqz	a0,ffffffffc02002fa <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200304:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200308:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030a:	e1bd                	bnez	a1,ffffffffc0200370 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020030c:	fe0c87e3          	beqz	s9,ffffffffc02002fa <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200310:	6582                	ld	a1,0(sp)
ffffffffc0200312:	00002d17          	auipc	s10,0x2
ffffffffc0200316:	f2ed0d13          	addi	s10,s10,-210 # ffffffffc0202240 <commands>
        argv[argc ++] = buf;
ffffffffc020031a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031c:	4401                	li	s0,0
ffffffffc020031e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200320:	45d010ef          	jal	ra,ffffffffc0201f7c <strcmp>
ffffffffc0200324:	c919                	beqz	a0,ffffffffc020033a <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200326:	2405                	addiw	s0,s0,1
ffffffffc0200328:	0b540063          	beq	s0,s5,ffffffffc02003c8 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032c:	000d3503          	ld	a0,0(s10)
ffffffffc0200330:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200332:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200334:	449010ef          	jal	ra,ffffffffc0201f7c <strcmp>
ffffffffc0200338:	f57d                	bnez	a0,ffffffffc0200326 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020033a:	00141793          	slli	a5,s0,0x1
ffffffffc020033e:	97a2                	add	a5,a5,s0
ffffffffc0200340:	078e                	slli	a5,a5,0x3
ffffffffc0200342:	97e2                	add	a5,a5,s8
ffffffffc0200344:	6b9c                	ld	a5,16(a5)
ffffffffc0200346:	865e                	mv	a2,s7
ffffffffc0200348:	002c                	addi	a1,sp,8
ffffffffc020034a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020034e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200350:	fa0555e3          	bgez	a0,ffffffffc02002fa <kmonitor+0x6a>
}
ffffffffc0200354:	60ee                	ld	ra,216(sp)
ffffffffc0200356:	644e                	ld	s0,208(sp)
ffffffffc0200358:	64ae                	ld	s1,200(sp)
ffffffffc020035a:	690e                	ld	s2,192(sp)
ffffffffc020035c:	79ea                	ld	s3,184(sp)
ffffffffc020035e:	7a4a                	ld	s4,176(sp)
ffffffffc0200360:	7aaa                	ld	s5,168(sp)
ffffffffc0200362:	7b0a                	ld	s6,160(sp)
ffffffffc0200364:	6bea                	ld	s7,152(sp)
ffffffffc0200366:	6c4a                	ld	s8,144(sp)
ffffffffc0200368:	6caa                	ld	s9,136(sp)
ffffffffc020036a:	6d0a                	ld	s10,128(sp)
ffffffffc020036c:	612d                	addi	sp,sp,224
ffffffffc020036e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200370:	8526                	mv	a0,s1
ffffffffc0200372:	44f010ef          	jal	ra,ffffffffc0201fc0 <strchr>
ffffffffc0200376:	c901                	beqz	a0,ffffffffc0200386 <kmonitor+0xf6>
ffffffffc0200378:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020037c:	00040023          	sb	zero,0(s0)
ffffffffc0200380:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200382:	d5c9                	beqz	a1,ffffffffc020030c <kmonitor+0x7c>
ffffffffc0200384:	b7f5                	j	ffffffffc0200370 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200386:	00044783          	lbu	a5,0(s0)
ffffffffc020038a:	d3c9                	beqz	a5,ffffffffc020030c <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc020038c:	033c8963          	beq	s9,s3,ffffffffc02003be <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200390:	003c9793          	slli	a5,s9,0x3
ffffffffc0200394:	0118                	addi	a4,sp,128
ffffffffc0200396:	97ba                	add	a5,a5,a4
ffffffffc0200398:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a0:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a2:	e591                	bnez	a1,ffffffffc02003ae <kmonitor+0x11e>
ffffffffc02003a4:	b7b5                	j	ffffffffc0200310 <kmonitor+0x80>
ffffffffc02003a6:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003aa:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ac:	d1a5                	beqz	a1,ffffffffc020030c <kmonitor+0x7c>
ffffffffc02003ae:	8526                	mv	a0,s1
ffffffffc02003b0:	411010ef          	jal	ra,ffffffffc0201fc0 <strchr>
ffffffffc02003b4:	d96d                	beqz	a0,ffffffffc02003a6 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	00044583          	lbu	a1,0(s0)
ffffffffc02003ba:	d9a9                	beqz	a1,ffffffffc020030c <kmonitor+0x7c>
ffffffffc02003bc:	bf55                	j	ffffffffc0200370 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003be:	45c1                	li	a1,16
ffffffffc02003c0:	855a                	mv	a0,s6
ffffffffc02003c2:	d1dff0ef          	jal	ra,ffffffffc02000de <cprintf>
ffffffffc02003c6:	b7e9                	j	ffffffffc0200390 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c8:	6582                	ld	a1,0(sp)
ffffffffc02003ca:	00002517          	auipc	a0,0x2
ffffffffc02003ce:	e5e50513          	addi	a0,a0,-418 # ffffffffc0202228 <etext+0x240>
ffffffffc02003d2:	d0dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    return 0;
ffffffffc02003d6:	b715                	j	ffffffffc02002fa <kmonitor+0x6a>

ffffffffc02003d8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d8:	00007317          	auipc	t1,0x7
ffffffffc02003dc:	06830313          	addi	t1,t1,104 # ffffffffc0207440 <is_panic>
ffffffffc02003e0:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003e4:	715d                	addi	sp,sp,-80
ffffffffc02003e6:	ec06                	sd	ra,24(sp)
ffffffffc02003e8:	e822                	sd	s0,16(sp)
ffffffffc02003ea:	f436                	sd	a3,40(sp)
ffffffffc02003ec:	f83a                	sd	a4,48(sp)
ffffffffc02003ee:	fc3e                	sd	a5,56(sp)
ffffffffc02003f0:	e0c2                	sd	a6,64(sp)
ffffffffc02003f2:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003f4:	020e1a63          	bnez	t3,ffffffffc0200428 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f8:	4785                	li	a5,1
ffffffffc02003fa:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003fe:	8432                	mv	s0,a2
ffffffffc0200400:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200402:	862e                	mv	a2,a1
ffffffffc0200404:	85aa                	mv	a1,a0
ffffffffc0200406:	00002517          	auipc	a0,0x2
ffffffffc020040a:	e8250513          	addi	a0,a0,-382 # ffffffffc0202288 <commands+0x48>
    va_start(ap, fmt);
ffffffffc020040e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200410:	ccfff0ef          	jal	ra,ffffffffc02000de <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200414:	65a2                	ld	a1,8(sp)
ffffffffc0200416:	8522                	mv	a0,s0
ffffffffc0200418:	ca7ff0ef          	jal	ra,ffffffffc02000be <vcprintf>
    cprintf("\n");
ffffffffc020041c:	00002517          	auipc	a0,0x2
ffffffffc0200420:	cb450513          	addi	a0,a0,-844 # ffffffffc02020d0 <etext+0xe8>
ffffffffc0200424:	cbbff0ef          	jal	ra,ffffffffc02000de <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200428:	412000ef          	jal	ra,ffffffffc020083a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020042c:	4501                	li	a0,0
ffffffffc020042e:	e63ff0ef          	jal	ra,ffffffffc0200290 <kmonitor>
    while (1) {
ffffffffc0200432:	bfed                	j	ffffffffc020042c <__panic+0x54>

ffffffffc0200434 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200434:	1141                	addi	sp,sp,-16
ffffffffc0200436:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200438:	02000793          	li	a5,32
ffffffffc020043c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	2ab010ef          	jal	ra,ffffffffc0201ef6 <sbi_set_timer>
}
ffffffffc0200450:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200452:	00007797          	auipc	a5,0x7
ffffffffc0200456:	fe07bb23          	sd	zero,-10(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020045a:	00002517          	auipc	a0,0x2
ffffffffc020045e:	e4e50513          	addi	a0,a0,-434 # ffffffffc02022a8 <commands+0x68>
}
ffffffffc0200462:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200464:	b9ad                	j	ffffffffc02000de <cprintf>

ffffffffc0200466 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200466:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020046a:	67e1                	lui	a5,0x18
ffffffffc020046c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200470:	953e                	add	a0,a0,a5
ffffffffc0200472:	2850106f          	j	ffffffffc0201ef6 <sbi_set_timer>

ffffffffc0200476 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200476:	8082                	ret

ffffffffc0200478 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200478:	0ff57513          	zext.b	a0,a0
ffffffffc020047c:	2610106f          	j	ffffffffc0201edc <sbi_console_putchar>

ffffffffc0200480 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200480:	2910106f          	j	ffffffffc0201f10 <sbi_console_getchar>

ffffffffc0200484 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200484:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200486:	00002517          	auipc	a0,0x2
ffffffffc020048a:	e4250513          	addi	a0,a0,-446 # ffffffffc02022c8 <commands+0x88>
void dtb_init(void) {
ffffffffc020048e:	fc86                	sd	ra,120(sp)
ffffffffc0200490:	f8a2                	sd	s0,112(sp)
ffffffffc0200492:	e8d2                	sd	s4,80(sp)
ffffffffc0200494:	f4a6                	sd	s1,104(sp)
ffffffffc0200496:	f0ca                	sd	s2,96(sp)
ffffffffc0200498:	ecce                	sd	s3,88(sp)
ffffffffc020049a:	e4d6                	sd	s5,72(sp)
ffffffffc020049c:	e0da                	sd	s6,64(sp)
ffffffffc020049e:	fc5e                	sd	s7,56(sp)
ffffffffc02004a0:	f862                	sd	s8,48(sp)
ffffffffc02004a2:	f466                	sd	s9,40(sp)
ffffffffc02004a4:	f06a                	sd	s10,32(sp)
ffffffffc02004a6:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004a8:	c37ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004ac:	00007597          	auipc	a1,0x7
ffffffffc02004b0:	b545b583          	ld	a1,-1196(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004b4:	00002517          	auipc	a0,0x2
ffffffffc02004b8:	e2450513          	addi	a0,a0,-476 # ffffffffc02022d8 <commands+0x98>
ffffffffc02004bc:	c23ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004c0:	00007417          	auipc	s0,0x7
ffffffffc02004c4:	b4840413          	addi	s0,s0,-1208 # ffffffffc0207008 <boot_dtb>
ffffffffc02004c8:	600c                	ld	a1,0(s0)
ffffffffc02004ca:	00002517          	auipc	a0,0x2
ffffffffc02004ce:	e1e50513          	addi	a0,a0,-482 # ffffffffc02022e8 <commands+0xa8>
ffffffffc02004d2:	c0dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004d6:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	e2650513          	addi	a0,a0,-474 # ffffffffc0202300 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004e2:	120a0463          	beqz	s4,ffffffffc020060a <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004e6:	57f5                	li	a5,-3
ffffffffc02004e8:	07fa                	slli	a5,a5,0x1e
ffffffffc02004ea:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004ee:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f6:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004fa:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fe:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200502:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200506:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050c:	8ec9                	or	a3,a3,a0
ffffffffc020050e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200512:	1b7d                	addi	s6,s6,-1
ffffffffc0200514:	0167f7b3          	and	a5,a5,s6
ffffffffc0200518:	8dd5                	or	a1,a1,a3
ffffffffc020051a:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020051c:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200520:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200522:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200526:	10f59163          	bne	a1,a5,ffffffffc0200628 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020052a:	471c                	lw	a5,8(a4)
ffffffffc020052c:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020052e:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200530:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200534:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200538:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200540:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200544:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200548:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200550:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200558:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020055a:	01146433          	or	s0,s0,a7
ffffffffc020055e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200562:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200566:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200568:	0087979b          	slliw	a5,a5,0x8
ffffffffc020056c:	8c49                	or	s0,s0,a0
ffffffffc020056e:	0166f6b3          	and	a3,a3,s6
ffffffffc0200572:	00ca6a33          	or	s4,s4,a2
ffffffffc0200576:	0167f7b3          	and	a5,a5,s6
ffffffffc020057a:	8c55                	or	s0,s0,a3
ffffffffc020057c:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200580:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200582:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200584:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200586:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020058a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020058c:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058e:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200592:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200594:	00002917          	auipc	s2,0x2
ffffffffc0200598:	dbc90913          	addi	s2,s2,-580 # ffffffffc0202350 <commands+0x110>
ffffffffc020059c:	49bd                	li	s3,15
        switch (token) {
ffffffffc020059e:	4d91                	li	s11,4
ffffffffc02005a0:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005a2:	00002497          	auipc	s1,0x2
ffffffffc02005a6:	da648493          	addi	s1,s1,-602 # ffffffffc0202348 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005aa:	000a2703          	lw	a4,0(s4)
ffffffffc02005ae:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005b6:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ba:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005be:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c2:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005c6:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c8:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005cc:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005d0:	8fd5                	or	a5,a5,a3
ffffffffc02005d2:	00eb7733          	and	a4,s6,a4
ffffffffc02005d6:	8fd9                	or	a5,a5,a4
ffffffffc02005d8:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005da:	09778c63          	beq	a5,s7,ffffffffc0200672 <dtb_init+0x1ee>
ffffffffc02005de:	00fbea63          	bltu	s7,a5,ffffffffc02005f2 <dtb_init+0x16e>
ffffffffc02005e2:	07a78663          	beq	a5,s10,ffffffffc020064e <dtb_init+0x1ca>
ffffffffc02005e6:	4709                	li	a4,2
ffffffffc02005e8:	00e79763          	bne	a5,a4,ffffffffc02005f6 <dtb_init+0x172>
ffffffffc02005ec:	4c81                	li	s9,0
ffffffffc02005ee:	8a56                	mv	s4,s5
ffffffffc02005f0:	bf6d                	j	ffffffffc02005aa <dtb_init+0x126>
ffffffffc02005f2:	ffb78ee3          	beq	a5,s11,ffffffffc02005ee <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005f6:	00002517          	auipc	a0,0x2
ffffffffc02005fa:	dd250513          	addi	a0,a0,-558 # ffffffffc02023c8 <commands+0x188>
ffffffffc02005fe:	ae1ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200602:	00002517          	auipc	a0,0x2
ffffffffc0200606:	dfe50513          	addi	a0,a0,-514 # ffffffffc0202400 <commands+0x1c0>
}
ffffffffc020060a:	7446                	ld	s0,112(sp)
ffffffffc020060c:	70e6                	ld	ra,120(sp)
ffffffffc020060e:	74a6                	ld	s1,104(sp)
ffffffffc0200610:	7906                	ld	s2,96(sp)
ffffffffc0200612:	69e6                	ld	s3,88(sp)
ffffffffc0200614:	6a46                	ld	s4,80(sp)
ffffffffc0200616:	6aa6                	ld	s5,72(sp)
ffffffffc0200618:	6b06                	ld	s6,64(sp)
ffffffffc020061a:	7be2                	ld	s7,56(sp)
ffffffffc020061c:	7c42                	ld	s8,48(sp)
ffffffffc020061e:	7ca2                	ld	s9,40(sp)
ffffffffc0200620:	7d02                	ld	s10,32(sp)
ffffffffc0200622:	6de2                	ld	s11,24(sp)
ffffffffc0200624:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200626:	bc65                	j	ffffffffc02000de <cprintf>
}
ffffffffc0200628:	7446                	ld	s0,112(sp)
ffffffffc020062a:	70e6                	ld	ra,120(sp)
ffffffffc020062c:	74a6                	ld	s1,104(sp)
ffffffffc020062e:	7906                	ld	s2,96(sp)
ffffffffc0200630:	69e6                	ld	s3,88(sp)
ffffffffc0200632:	6a46                	ld	s4,80(sp)
ffffffffc0200634:	6aa6                	ld	s5,72(sp)
ffffffffc0200636:	6b06                	ld	s6,64(sp)
ffffffffc0200638:	7be2                	ld	s7,56(sp)
ffffffffc020063a:	7c42                	ld	s8,48(sp)
ffffffffc020063c:	7ca2                	ld	s9,40(sp)
ffffffffc020063e:	7d02                	ld	s10,32(sp)
ffffffffc0200640:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200642:	00002517          	auipc	a0,0x2
ffffffffc0200646:	cde50513          	addi	a0,a0,-802 # ffffffffc0202320 <commands+0xe0>
}
ffffffffc020064a:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020064c:	bc49                	j	ffffffffc02000de <cprintf>
                int name_len = strlen(name);
ffffffffc020064e:	8556                	mv	a0,s5
ffffffffc0200650:	0f7010ef          	jal	ra,ffffffffc0201f46 <strlen>
ffffffffc0200654:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200656:	4619                	li	a2,6
ffffffffc0200658:	85a6                	mv	a1,s1
ffffffffc020065a:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020065c:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020065e:	13d010ef          	jal	ra,ffffffffc0201f9a <strncmp>
ffffffffc0200662:	e111                	bnez	a0,ffffffffc0200666 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200664:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200666:	0a91                	addi	s5,s5,4
ffffffffc0200668:	9ad2                	add	s5,s5,s4
ffffffffc020066a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020066e:	8a56                	mv	s4,s5
ffffffffc0200670:	bf2d                	j	ffffffffc02005aa <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200672:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200676:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020067e:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200682:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200686:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020068a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020068e:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200692:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200696:	0087979b          	slliw	a5,a5,0x8
ffffffffc020069a:	00eaeab3          	or	s5,s5,a4
ffffffffc020069e:	00fb77b3          	and	a5,s6,a5
ffffffffc02006a2:	00faeab3          	or	s5,s5,a5
ffffffffc02006a6:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006a8:	000c9c63          	bnez	s9,ffffffffc02006c0 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006ac:	1a82                	slli	s5,s5,0x20
ffffffffc02006ae:	00368793          	addi	a5,a3,3
ffffffffc02006b2:	020ada93          	srli	s5,s5,0x20
ffffffffc02006b6:	9abe                	add	s5,s5,a5
ffffffffc02006b8:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006bc:	8a56                	mv	s4,s5
ffffffffc02006be:	b5f5                	j	ffffffffc02005aa <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c0:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006c4:	85ca                	mv	a1,s2
ffffffffc02006c6:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c8:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006cc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d0:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006d4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d8:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006dc:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006de:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8d59                	or	a0,a0,a4
ffffffffc02006e8:	00fb77b3          	and	a5,s6,a5
ffffffffc02006ec:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006ee:	1502                	slli	a0,a0,0x20
ffffffffc02006f0:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f2:	9522                	add	a0,a0,s0
ffffffffc02006f4:	089010ef          	jal	ra,ffffffffc0201f7c <strcmp>
ffffffffc02006f8:	66a2                	ld	a3,8(sp)
ffffffffc02006fa:	f94d                	bnez	a0,ffffffffc02006ac <dtb_init+0x228>
ffffffffc02006fc:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006ac <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200700:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200704:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200708:	00002517          	auipc	a0,0x2
ffffffffc020070c:	c5050513          	addi	a0,a0,-944 # ffffffffc0202358 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200710:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200714:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200718:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200720:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200724:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200728:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0187d693          	srli	a3,a5,0x18
ffffffffc0200730:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200734:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200738:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200740:	010f6f33          	or	t5,t5,a6
ffffffffc0200744:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200748:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074c:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200750:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200754:	0186f6b3          	and	a3,a3,s8
ffffffffc0200758:	01859e1b          	slliw	t3,a1,0x18
ffffffffc020075c:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200760:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200764:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200768:	8361                	srli	a4,a4,0x18
ffffffffc020076a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020076e:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200772:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200776:	00cb7633          	and	a2,s6,a2
ffffffffc020077a:	0088181b          	slliw	a6,a6,0x8
ffffffffc020077e:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200782:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200786:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078a:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078e:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200792:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200796:	011b78b3          	and	a7,s6,a7
ffffffffc020079a:	005eeeb3          	or	t4,t4,t0
ffffffffc020079e:	00c6e733          	or	a4,a3,a2
ffffffffc02007a2:	006c6c33          	or	s8,s8,t1
ffffffffc02007a6:	010b76b3          	and	a3,s6,a6
ffffffffc02007aa:	00bb7b33          	and	s6,s6,a1
ffffffffc02007ae:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007b2:	016c6b33          	or	s6,s8,s6
ffffffffc02007b6:	01146433          	or	s0,s0,a7
ffffffffc02007ba:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007bc:	1702                	slli	a4,a4,0x20
ffffffffc02007be:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c0:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c2:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c4:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c6:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ca:	0167eb33          	or	s6,a5,s6
ffffffffc02007ce:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007d0:	90fff0ef          	jal	ra,ffffffffc02000de <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007d4:	85a2                	mv	a1,s0
ffffffffc02007d6:	00002517          	auipc	a0,0x2
ffffffffc02007da:	ba250513          	addi	a0,a0,-1118 # ffffffffc0202378 <commands+0x138>
ffffffffc02007de:	901ff0ef          	jal	ra,ffffffffc02000de <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007e2:	014b5613          	srli	a2,s6,0x14
ffffffffc02007e6:	85da                	mv	a1,s6
ffffffffc02007e8:	00002517          	auipc	a0,0x2
ffffffffc02007ec:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202390 <commands+0x150>
ffffffffc02007f0:	8efff0ef          	jal	ra,ffffffffc02000de <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007f4:	008b05b3          	add	a1,s6,s0
ffffffffc02007f8:	15fd                	addi	a1,a1,-1
ffffffffc02007fa:	00002517          	auipc	a0,0x2
ffffffffc02007fe:	bb650513          	addi	a0,a0,-1098 # ffffffffc02023b0 <commands+0x170>
ffffffffc0200802:	8ddff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200806:	00002517          	auipc	a0,0x2
ffffffffc020080a:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202400 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc020080e:	00007797          	auipc	a5,0x7
ffffffffc0200812:	c487b123          	sd	s0,-958(a5) # ffffffffc0207450 <memory_base>
        memory_size = mem_size;
ffffffffc0200816:	00007797          	auipc	a5,0x7
ffffffffc020081a:	c567b123          	sd	s6,-958(a5) # ffffffffc0207458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc020081e:	b3f5                	j	ffffffffc020060a <dtb_init+0x186>

ffffffffc0200820 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200820:	00007517          	auipc	a0,0x7
ffffffffc0200824:	c3053503          	ld	a0,-976(a0) # ffffffffc0207450 <memory_base>
ffffffffc0200828:	8082                	ret

ffffffffc020082a <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020082a:	00007517          	auipc	a0,0x7
ffffffffc020082e:	c2e53503          	ld	a0,-978(a0) # ffffffffc0207458 <memory_size>
ffffffffc0200832:	8082                	ret

ffffffffc0200834 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200834:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200838:	8082                	ret

ffffffffc020083a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020083a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020083e:	8082                	ret

ffffffffc0200840 <idt_init>:

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector

       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200840:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200844:	00000797          	auipc	a5,0x0
ffffffffc0200848:	3d078793          	addi	a5,a5,976 # ffffffffc0200c14 <__alltraps>
ffffffffc020084c:	10579073          	csrw	stvec,a5
}
ffffffffc0200850:	8082                	ret

ffffffffc0200852 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200852:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200854:	1141                	addi	sp,sp,-16
ffffffffc0200856:	e022                	sd	s0,0(sp)
ffffffffc0200858:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020085a:	00002517          	auipc	a0,0x2
ffffffffc020085e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202418 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200862:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200864:	87bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200868:	640c                	ld	a1,8(s0)
ffffffffc020086a:	00002517          	auipc	a0,0x2
ffffffffc020086e:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202430 <commands+0x1f0>
ffffffffc0200872:	86dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200876:	680c                	ld	a1,16(s0)
ffffffffc0200878:	00002517          	auipc	a0,0x2
ffffffffc020087c:	bd050513          	addi	a0,a0,-1072 # ffffffffc0202448 <commands+0x208>
ffffffffc0200880:	85fff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200884:	6c0c                	ld	a1,24(s0)
ffffffffc0200886:	00002517          	auipc	a0,0x2
ffffffffc020088a:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202460 <commands+0x220>
ffffffffc020088e:	851ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200892:	700c                	ld	a1,32(s0)
ffffffffc0200894:	00002517          	auipc	a0,0x2
ffffffffc0200898:	be450513          	addi	a0,a0,-1052 # ffffffffc0202478 <commands+0x238>
ffffffffc020089c:	843ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008a0:	740c                	ld	a1,40(s0)
ffffffffc02008a2:	00002517          	auipc	a0,0x2
ffffffffc02008a6:	bee50513          	addi	a0,a0,-1042 # ffffffffc0202490 <commands+0x250>
ffffffffc02008aa:	835ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008ae:	780c                	ld	a1,48(s0)
ffffffffc02008b0:	00002517          	auipc	a0,0x2
ffffffffc02008b4:	bf850513          	addi	a0,a0,-1032 # ffffffffc02024a8 <commands+0x268>
ffffffffc02008b8:	827ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008bc:	7c0c                	ld	a1,56(s0)
ffffffffc02008be:	00002517          	auipc	a0,0x2
ffffffffc02008c2:	c0250513          	addi	a0,a0,-1022 # ffffffffc02024c0 <commands+0x280>
ffffffffc02008c6:	819ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008ca:	602c                	ld	a1,64(s0)
ffffffffc02008cc:	00002517          	auipc	a0,0x2
ffffffffc02008d0:	c0c50513          	addi	a0,a0,-1012 # ffffffffc02024d8 <commands+0x298>
ffffffffc02008d4:	80bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d8:	642c                	ld	a1,72(s0)
ffffffffc02008da:	00002517          	auipc	a0,0x2
ffffffffc02008de:	c1650513          	addi	a0,a0,-1002 # ffffffffc02024f0 <commands+0x2b0>
ffffffffc02008e2:	ffcff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e6:	682c                	ld	a1,80(s0)
ffffffffc02008e8:	00002517          	auipc	a0,0x2
ffffffffc02008ec:	c2050513          	addi	a0,a0,-992 # ffffffffc0202508 <commands+0x2c8>
ffffffffc02008f0:	feeff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008f4:	6c2c                	ld	a1,88(s0)
ffffffffc02008f6:	00002517          	auipc	a0,0x2
ffffffffc02008fa:	c2a50513          	addi	a0,a0,-982 # ffffffffc0202520 <commands+0x2e0>
ffffffffc02008fe:	fe0ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200902:	702c                	ld	a1,96(s0)
ffffffffc0200904:	00002517          	auipc	a0,0x2
ffffffffc0200908:	c3450513          	addi	a0,a0,-972 # ffffffffc0202538 <commands+0x2f8>
ffffffffc020090c:	fd2ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200910:	742c                	ld	a1,104(s0)
ffffffffc0200912:	00002517          	auipc	a0,0x2
ffffffffc0200916:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202550 <commands+0x310>
ffffffffc020091a:	fc4ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020091e:	782c                	ld	a1,112(s0)
ffffffffc0200920:	00002517          	auipc	a0,0x2
ffffffffc0200924:	c4850513          	addi	a0,a0,-952 # ffffffffc0202568 <commands+0x328>
ffffffffc0200928:	fb6ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020092c:	7c2c                	ld	a1,120(s0)
ffffffffc020092e:	00002517          	auipc	a0,0x2
ffffffffc0200932:	c5250513          	addi	a0,a0,-942 # ffffffffc0202580 <commands+0x340>
ffffffffc0200936:	fa8ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020093a:	604c                	ld	a1,128(s0)
ffffffffc020093c:	00002517          	auipc	a0,0x2
ffffffffc0200940:	c5c50513          	addi	a0,a0,-932 # ffffffffc0202598 <commands+0x358>
ffffffffc0200944:	f9aff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200948:	644c                	ld	a1,136(s0)
ffffffffc020094a:	00002517          	auipc	a0,0x2
ffffffffc020094e:	c6650513          	addi	a0,a0,-922 # ffffffffc02025b0 <commands+0x370>
ffffffffc0200952:	f8cff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200956:	684c                	ld	a1,144(s0)
ffffffffc0200958:	00002517          	auipc	a0,0x2
ffffffffc020095c:	c7050513          	addi	a0,a0,-912 # ffffffffc02025c8 <commands+0x388>
ffffffffc0200960:	f7eff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200964:	6c4c                	ld	a1,152(s0)
ffffffffc0200966:	00002517          	auipc	a0,0x2
ffffffffc020096a:	c7a50513          	addi	a0,a0,-902 # ffffffffc02025e0 <commands+0x3a0>
ffffffffc020096e:	f70ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200972:	704c                	ld	a1,160(s0)
ffffffffc0200974:	00002517          	auipc	a0,0x2
ffffffffc0200978:	c8450513          	addi	a0,a0,-892 # ffffffffc02025f8 <commands+0x3b8>
ffffffffc020097c:	f62ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200980:	744c                	ld	a1,168(s0)
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	c8e50513          	addi	a0,a0,-882 # ffffffffc0202610 <commands+0x3d0>
ffffffffc020098a:	f54ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020098e:	784c                	ld	a1,176(s0)
ffffffffc0200990:	00002517          	auipc	a0,0x2
ffffffffc0200994:	c9850513          	addi	a0,a0,-872 # ffffffffc0202628 <commands+0x3e8>
ffffffffc0200998:	f46ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020099c:	7c4c                	ld	a1,184(s0)
ffffffffc020099e:	00002517          	auipc	a0,0x2
ffffffffc02009a2:	ca250513          	addi	a0,a0,-862 # ffffffffc0202640 <commands+0x400>
ffffffffc02009a6:	f38ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009aa:	606c                	ld	a1,192(s0)
ffffffffc02009ac:	00002517          	auipc	a0,0x2
ffffffffc02009b0:	cac50513          	addi	a0,a0,-852 # ffffffffc0202658 <commands+0x418>
ffffffffc02009b4:	f2aff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b8:	646c                	ld	a1,200(s0)
ffffffffc02009ba:	00002517          	auipc	a0,0x2
ffffffffc02009be:	cb650513          	addi	a0,a0,-842 # ffffffffc0202670 <commands+0x430>
ffffffffc02009c2:	f1cff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c6:	686c                	ld	a1,208(s0)
ffffffffc02009c8:	00002517          	auipc	a0,0x2
ffffffffc02009cc:	cc050513          	addi	a0,a0,-832 # ffffffffc0202688 <commands+0x448>
ffffffffc02009d0:	f0eff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009d4:	6c6c                	ld	a1,216(s0)
ffffffffc02009d6:	00002517          	auipc	a0,0x2
ffffffffc02009da:	cca50513          	addi	a0,a0,-822 # ffffffffc02026a0 <commands+0x460>
ffffffffc02009de:	f00ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009e2:	706c                	ld	a1,224(s0)
ffffffffc02009e4:	00002517          	auipc	a0,0x2
ffffffffc02009e8:	cd450513          	addi	a0,a0,-812 # ffffffffc02026b8 <commands+0x478>
ffffffffc02009ec:	ef2ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009f0:	746c                	ld	a1,232(s0)
ffffffffc02009f2:	00002517          	auipc	a0,0x2
ffffffffc02009f6:	cde50513          	addi	a0,a0,-802 # ffffffffc02026d0 <commands+0x490>
ffffffffc02009fa:	ee4ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009fe:	786c                	ld	a1,240(s0)
ffffffffc0200a00:	00002517          	auipc	a0,0x2
ffffffffc0200a04:	ce850513          	addi	a0,a0,-792 # ffffffffc02026e8 <commands+0x4a8>
ffffffffc0200a08:	ed6ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a0e:	6402                	ld	s0,0(sp)
ffffffffc0200a10:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a12:	00002517          	auipc	a0,0x2
ffffffffc0200a16:	cee50513          	addi	a0,a0,-786 # ffffffffc0202700 <commands+0x4c0>
}
ffffffffc0200a1a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a1c:	ec2ff06f          	j	ffffffffc02000de <cprintf>

ffffffffc0200a20 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a20:	1141                	addi	sp,sp,-16
ffffffffc0200a22:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a24:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a26:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a28:	00002517          	auipc	a0,0x2
ffffffffc0200a2c:	cf050513          	addi	a0,a0,-784 # ffffffffc0202718 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a30:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a32:	eacff0ef          	jal	ra,ffffffffc02000de <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a36:	8522                	mv	a0,s0
ffffffffc0200a38:	e1bff0ef          	jal	ra,ffffffffc0200852 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a3c:	10043583          	ld	a1,256(s0)
ffffffffc0200a40:	00002517          	auipc	a0,0x2
ffffffffc0200a44:	cf050513          	addi	a0,a0,-784 # ffffffffc0202730 <commands+0x4f0>
ffffffffc0200a48:	e96ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a4c:	10843583          	ld	a1,264(s0)
ffffffffc0200a50:	00002517          	auipc	a0,0x2
ffffffffc0200a54:	cf850513          	addi	a0,a0,-776 # ffffffffc0202748 <commands+0x508>
ffffffffc0200a58:	e86ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a5c:	11043583          	ld	a1,272(s0)
ffffffffc0200a60:	00002517          	auipc	a0,0x2
ffffffffc0200a64:	d0050513          	addi	a0,a0,-768 # ffffffffc0202760 <commands+0x520>
ffffffffc0200a68:	e76ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a70:	6402                	ld	s0,0(sp)
ffffffffc0200a72:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a74:	00002517          	auipc	a0,0x2
ffffffffc0200a78:	d0450513          	addi	a0,a0,-764 # ffffffffc0202778 <commands+0x538>
}
ffffffffc0200a7c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a7e:	e60ff06f          	j	ffffffffc02000de <cprintf>

ffffffffc0200a82 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a82:	11853783          	ld	a5,280(a0)
ffffffffc0200a86:	472d                	li	a4,11
ffffffffc0200a88:	0786                	slli	a5,a5,0x1
ffffffffc0200a8a:	8385                	srli	a5,a5,0x1
ffffffffc0200a8c:	08f76963          	bltu	a4,a5,ffffffffc0200b1e <interrupt_handler+0x9c>
ffffffffc0200a90:	00002717          	auipc	a4,0x2
ffffffffc0200a94:	dc870713          	addi	a4,a4,-568 # ffffffffc0202858 <commands+0x618>
ffffffffc0200a98:	078a                	slli	a5,a5,0x2
ffffffffc0200a9a:	97ba                	add	a5,a5,a4
ffffffffc0200a9c:	439c                	lw	a5,0(a5)
ffffffffc0200a9e:	97ba                	add	a5,a5,a4
ffffffffc0200aa0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200aa2:	00002517          	auipc	a0,0x2
ffffffffc0200aa6:	d4e50513          	addi	a0,a0,-690 # ffffffffc02027f0 <commands+0x5b0>
ffffffffc0200aaa:	e34ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aae:	00002517          	auipc	a0,0x2
ffffffffc0200ab2:	d2250513          	addi	a0,a0,-734 # ffffffffc02027d0 <commands+0x590>
ffffffffc0200ab6:	e28ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200aba:	00002517          	auipc	a0,0x2
ffffffffc0200abe:	cd650513          	addi	a0,a0,-810 # ffffffffc0202790 <commands+0x550>
ffffffffc0200ac2:	e1cff06f          	j	ffffffffc02000de <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac6:	00002517          	auipc	a0,0x2
ffffffffc0200aca:	d4a50513          	addi	a0,a0,-694 # ffffffffc0202810 <commands+0x5d0>
ffffffffc0200ace:	e10ff06f          	j	ffffffffc02000de <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200ad2:	1141                	addi	sp,sp,-16
ffffffffc0200ad4:	e406                	sd	ra,8(sp)
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机

            */
            clock_set_next_event();
ffffffffc0200ad6:	991ff0ef          	jal	ra,ffffffffc0200466 <clock_set_next_event>
            ticks++;
ffffffffc0200ada:	00007797          	auipc	a5,0x7
ffffffffc0200ade:	96e78793          	addi	a5,a5,-1682 # ffffffffc0207448 <ticks>
ffffffffc0200ae2:	6398                	ld	a4,0(a5)

            static int count = 0;
                if (ticks == 100) {
ffffffffc0200ae4:	06400693          	li	a3,100
            ticks++;
ffffffffc0200ae8:	0705                	addi	a4,a4,1
ffffffffc0200aea:	e398                	sd	a4,0(a5)
                if (ticks == 100) {
ffffffffc0200aec:	639c                	ld	a5,0(a5)
ffffffffc0200aee:	02d78963          	beq	a5,a3,ffffffffc0200b20 <interrupt_handler+0x9e>
                 
        print_ticks();
        ticks = 0;  // 重置计数器
        count++;}
                if (count == 10) {
ffffffffc0200af2:	00007717          	auipc	a4,0x7
ffffffffc0200af6:	96e72703          	lw	a4,-1682(a4) # ffffffffc0207460 <count.0>
ffffffffc0200afa:	47a9                	li	a5,10
ffffffffc0200afc:	04f70763          	beq	a4,a5,ffffffffc0200b4a <interrupt_handler+0xc8>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b00:	60a2                	ld	ra,8(sp)
ffffffffc0200b02:	0141                	addi	sp,sp,16
ffffffffc0200b04:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b06:	00002517          	auipc	a0,0x2
ffffffffc0200b0a:	d3250513          	addi	a0,a0,-718 # ffffffffc0202838 <commands+0x5f8>
ffffffffc0200b0e:	dd0ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b12:	00002517          	auipc	a0,0x2
ffffffffc0200b16:	c9e50513          	addi	a0,a0,-866 # ffffffffc02027b0 <commands+0x570>
ffffffffc0200b1a:	dc4ff06f          	j	ffffffffc02000de <cprintf>
            print_trapframe(tf);
ffffffffc0200b1e:	b709                	j	ffffffffc0200a20 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b20:	06400593          	li	a1,100
ffffffffc0200b24:	00002517          	auipc	a0,0x2
ffffffffc0200b28:	d0450513          	addi	a0,a0,-764 # ffffffffc0202828 <commands+0x5e8>
ffffffffc0200b2c:	db2ff0ef          	jal	ra,ffffffffc02000de <cprintf>
        count++;}
ffffffffc0200b30:	00007697          	auipc	a3,0x7
ffffffffc0200b34:	93068693          	addi	a3,a3,-1744 # ffffffffc0207460 <count.0>
ffffffffc0200b38:	429c                	lw	a5,0(a3)
        ticks = 0;  // 重置计数器
ffffffffc0200b3a:	00007717          	auipc	a4,0x7
ffffffffc0200b3e:	90073723          	sd	zero,-1778(a4) # ffffffffc0207448 <ticks>
        count++;}
ffffffffc0200b42:	0017871b          	addiw	a4,a5,1
ffffffffc0200b46:	c298                	sw	a4,0(a3)
ffffffffc0200b48:	bf4d                	j	ffffffffc0200afa <interrupt_handler+0x78>
}
ffffffffc0200b4a:	60a2                	ld	ra,8(sp)
ffffffffc0200b4c:	0141                	addi	sp,sp,16
            sbi_shutdown();
ffffffffc0200b4e:	3de0106f          	j	ffffffffc0201f2c <sbi_shutdown>

ffffffffc0200b52 <exception_handler>:
{
    uint16_t inst = *(uint16_t *)pc;
    return ((inst & 0x3) == 0x3) ? 4 : 2;
}

void exception_handler(struct trapframe *tf) {
ffffffffc0200b52:	1101                	addi	sp,sp,-32
ffffffffc0200b54:	e822                	sd	s0,16(sp)
    switch (tf->cause) {
ffffffffc0200b56:	11853403          	ld	s0,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b5a:	e426                	sd	s1,8(sp)
ffffffffc0200b5c:	e04a                	sd	s2,0(sp)
ffffffffc0200b5e:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200b60:	490d                	li	s2,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b62:	84aa                	mv	s1,a0
    switch (tf->cause) {
ffffffffc0200b64:	05240f63          	beq	s0,s2,ffffffffc0200bc2 <exception_handler+0x70>
ffffffffc0200b68:	04896363          	bltu	s2,s0,ffffffffc0200bae <exception_handler+0x5c>
ffffffffc0200b6c:	4789                	li	a5,2
ffffffffc0200b6e:	02f41a63          	bne	s0,a5,ffffffffc0200ba2 <exception_handler+0x50>
            /*(1)输出指令异常类型（ Illegal instruction）

             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
ffffffffc0200b72:	00002517          	auipc	a0,0x2
ffffffffc0200b76:	d1650513          	addi	a0,a0,-746 # ffffffffc0202888 <commands+0x648>
ffffffffc0200b7a:	d64ff0ef          	jal	ra,ffffffffc02000de <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b7e:	1084b583          	ld	a1,264(s1)
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	d2e50513          	addi	a0,a0,-722 # ffffffffc02028b0 <commands+0x670>
ffffffffc0200b8a:	d54ff0ef          	jal	ra,ffffffffc02000de <cprintf>
            tf->epc += get_inst_len(tf->epc);
ffffffffc0200b8e:	1084b783          	ld	a5,264(s1)
    return ((inst & 0x3) == 0x3) ? 4 : 2;
ffffffffc0200b92:	0007d703          	lhu	a4,0(a5)
ffffffffc0200b96:	8b0d                	andi	a4,a4,3
ffffffffc0200b98:	07270563          	beq	a4,s2,ffffffffc0200c02 <exception_handler+0xb0>
            tf->epc += get_inst_len(tf->epc);
ffffffffc0200b9c:	97a2                	add	a5,a5,s0
ffffffffc0200b9e:	10f4b423          	sd	a5,264(s1)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ba2:	60e2                	ld	ra,24(sp)
ffffffffc0200ba4:	6442                	ld	s0,16(sp)
ffffffffc0200ba6:	64a2                	ld	s1,8(sp)
ffffffffc0200ba8:	6902                	ld	s2,0(sp)
ffffffffc0200baa:	6105                	addi	sp,sp,32
ffffffffc0200bac:	8082                	ret
    switch (tf->cause) {
ffffffffc0200bae:	1471                	addi	s0,s0,-4
ffffffffc0200bb0:	479d                	li	a5,7
ffffffffc0200bb2:	fe87f8e3          	bgeu	a5,s0,ffffffffc0200ba2 <exception_handler+0x50>
}
ffffffffc0200bb6:	6442                	ld	s0,16(sp)
ffffffffc0200bb8:	60e2                	ld	ra,24(sp)
ffffffffc0200bba:	64a2                	ld	s1,8(sp)
ffffffffc0200bbc:	6902                	ld	s2,0(sp)
ffffffffc0200bbe:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200bc0:	b585                	j	ffffffffc0200a20 <print_trapframe>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200bc2:	00002517          	auipc	a0,0x2
ffffffffc0200bc6:	d1650513          	addi	a0,a0,-746 # ffffffffc02028d8 <commands+0x698>
ffffffffc0200bca:	d14ff0ef          	jal	ra,ffffffffc02000de <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200bce:	1084b583          	ld	a1,264(s1)
ffffffffc0200bd2:	00002517          	auipc	a0,0x2
ffffffffc0200bd6:	d2650513          	addi	a0,a0,-730 # ffffffffc02028f8 <commands+0x6b8>
ffffffffc0200bda:	d04ff0ef          	jal	ra,ffffffffc02000de <cprintf>
            tf->epc += get_inst_len(tf->epc);
ffffffffc0200bde:	1084b783          	ld	a5,264(s1)
    return ((inst & 0x3) == 0x3) ? 4 : 2;
ffffffffc0200be2:	4691                	li	a3,4
ffffffffc0200be4:	0007d703          	lhu	a4,0(a5)
ffffffffc0200be8:	8b0d                	andi	a4,a4,3
ffffffffc0200bea:	00870363          	beq	a4,s0,ffffffffc0200bf0 <exception_handler+0x9e>
ffffffffc0200bee:	4689                	li	a3,2
}
ffffffffc0200bf0:	60e2                	ld	ra,24(sp)
ffffffffc0200bf2:	6442                	ld	s0,16(sp)
            tf->epc += get_inst_len(tf->epc);
ffffffffc0200bf4:	97b6                	add	a5,a5,a3
ffffffffc0200bf6:	10f4b423          	sd	a5,264(s1)
}
ffffffffc0200bfa:	6902                	ld	s2,0(sp)
ffffffffc0200bfc:	64a2                	ld	s1,8(sp)
ffffffffc0200bfe:	6105                	addi	sp,sp,32
ffffffffc0200c00:	8082                	ret
ffffffffc0200c02:	4411                	li	s0,4
ffffffffc0200c04:	bf61                	j	ffffffffc0200b9c <exception_handler+0x4a>

ffffffffc0200c06 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	0007c363          	bltz	a5,ffffffffc0200c10 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200c0e:	b791                	j	ffffffffc0200b52 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c10:	bd8d                	j	ffffffffc0200a82 <interrupt_handler>
	...

ffffffffc0200c14 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200c14:	14011073          	csrw	sscratch,sp
ffffffffc0200c18:	712d                	addi	sp,sp,-288
ffffffffc0200c1a:	e002                	sd	zero,0(sp)
ffffffffc0200c1c:	e406                	sd	ra,8(sp)
ffffffffc0200c1e:	ec0e                	sd	gp,24(sp)
ffffffffc0200c20:	f012                	sd	tp,32(sp)
ffffffffc0200c22:	f416                	sd	t0,40(sp)
ffffffffc0200c24:	f81a                	sd	t1,48(sp)
ffffffffc0200c26:	fc1e                	sd	t2,56(sp)
ffffffffc0200c28:	e0a2                	sd	s0,64(sp)
ffffffffc0200c2a:	e4a6                	sd	s1,72(sp)
ffffffffc0200c2c:	e8aa                	sd	a0,80(sp)
ffffffffc0200c2e:	ecae                	sd	a1,88(sp)
ffffffffc0200c30:	f0b2                	sd	a2,96(sp)
ffffffffc0200c32:	f4b6                	sd	a3,104(sp)
ffffffffc0200c34:	f8ba                	sd	a4,112(sp)
ffffffffc0200c36:	fcbe                	sd	a5,120(sp)
ffffffffc0200c38:	e142                	sd	a6,128(sp)
ffffffffc0200c3a:	e546                	sd	a7,136(sp)
ffffffffc0200c3c:	e94a                	sd	s2,144(sp)
ffffffffc0200c3e:	ed4e                	sd	s3,152(sp)
ffffffffc0200c40:	f152                	sd	s4,160(sp)
ffffffffc0200c42:	f556                	sd	s5,168(sp)
ffffffffc0200c44:	f95a                	sd	s6,176(sp)
ffffffffc0200c46:	fd5e                	sd	s7,184(sp)
ffffffffc0200c48:	e1e2                	sd	s8,192(sp)
ffffffffc0200c4a:	e5e6                	sd	s9,200(sp)
ffffffffc0200c4c:	e9ea                	sd	s10,208(sp)
ffffffffc0200c4e:	edee                	sd	s11,216(sp)
ffffffffc0200c50:	f1f2                	sd	t3,224(sp)
ffffffffc0200c52:	f5f6                	sd	t4,232(sp)
ffffffffc0200c54:	f9fa                	sd	t5,240(sp)
ffffffffc0200c56:	fdfe                	sd	t6,248(sp)
ffffffffc0200c58:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c5c:	100024f3          	csrr	s1,sstatus
ffffffffc0200c60:	14102973          	csrr	s2,sepc
ffffffffc0200c64:	143029f3          	csrr	s3,stval
ffffffffc0200c68:	14202a73          	csrr	s4,scause
ffffffffc0200c6c:	e822                	sd	s0,16(sp)
ffffffffc0200c6e:	e226                	sd	s1,256(sp)
ffffffffc0200c70:	e64a                	sd	s2,264(sp)
ffffffffc0200c72:	ea4e                	sd	s3,272(sp)
ffffffffc0200c74:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c76:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c78:	f8fff0ef          	jal	ra,ffffffffc0200c06 <trap>

ffffffffc0200c7c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c7c:	6492                	ld	s1,256(sp)
ffffffffc0200c7e:	6932                	ld	s2,264(sp)
ffffffffc0200c80:	10049073          	csrw	sstatus,s1
ffffffffc0200c84:	14191073          	csrw	sepc,s2
ffffffffc0200c88:	60a2                	ld	ra,8(sp)
ffffffffc0200c8a:	61e2                	ld	gp,24(sp)
ffffffffc0200c8c:	7202                	ld	tp,32(sp)
ffffffffc0200c8e:	72a2                	ld	t0,40(sp)
ffffffffc0200c90:	7342                	ld	t1,48(sp)
ffffffffc0200c92:	73e2                	ld	t2,56(sp)
ffffffffc0200c94:	6406                	ld	s0,64(sp)
ffffffffc0200c96:	64a6                	ld	s1,72(sp)
ffffffffc0200c98:	6546                	ld	a0,80(sp)
ffffffffc0200c9a:	65e6                	ld	a1,88(sp)
ffffffffc0200c9c:	7606                	ld	a2,96(sp)
ffffffffc0200c9e:	76a6                	ld	a3,104(sp)
ffffffffc0200ca0:	7746                	ld	a4,112(sp)
ffffffffc0200ca2:	77e6                	ld	a5,120(sp)
ffffffffc0200ca4:	680a                	ld	a6,128(sp)
ffffffffc0200ca6:	68aa                	ld	a7,136(sp)
ffffffffc0200ca8:	694a                	ld	s2,144(sp)
ffffffffc0200caa:	69ea                	ld	s3,152(sp)
ffffffffc0200cac:	7a0a                	ld	s4,160(sp)
ffffffffc0200cae:	7aaa                	ld	s5,168(sp)
ffffffffc0200cb0:	7b4a                	ld	s6,176(sp)
ffffffffc0200cb2:	7bea                	ld	s7,184(sp)
ffffffffc0200cb4:	6c0e                	ld	s8,192(sp)
ffffffffc0200cb6:	6cae                	ld	s9,200(sp)
ffffffffc0200cb8:	6d4e                	ld	s10,208(sp)
ffffffffc0200cba:	6dee                	ld	s11,216(sp)
ffffffffc0200cbc:	7e0e                	ld	t3,224(sp)
ffffffffc0200cbe:	7eae                	ld	t4,232(sp)
ffffffffc0200cc0:	7f4e                	ld	t5,240(sp)
ffffffffc0200cc2:	7fee                	ld	t6,248(sp)
ffffffffc0200cc4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200cc6:	10200073          	sret

ffffffffc0200cca <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200cca:	00006797          	auipc	a5,0x6
ffffffffc0200cce:	35e78793          	addi	a5,a5,862 # ffffffffc0207028 <free_area>
ffffffffc0200cd2:	e79c                	sd	a5,8(a5)
ffffffffc0200cd4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200cd6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200cda:	8082                	ret

ffffffffc0200cdc <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200cdc:	00006517          	auipc	a0,0x6
ffffffffc0200ce0:	35c56503          	lwu	a0,860(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200ce4:	8082                	ret

ffffffffc0200ce6 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200ce6:	715d                	addi	sp,sp,-80
ffffffffc0200ce8:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200cea:	00006417          	auipc	s0,0x6
ffffffffc0200cee:	33e40413          	addi	s0,s0,830 # ffffffffc0207028 <free_area>
ffffffffc0200cf2:	641c                	ld	a5,8(s0)
ffffffffc0200cf4:	e486                	sd	ra,72(sp)
ffffffffc0200cf6:	fc26                	sd	s1,56(sp)
ffffffffc0200cf8:	f84a                	sd	s2,48(sp)
ffffffffc0200cfa:	f44e                	sd	s3,40(sp)
ffffffffc0200cfc:	f052                	sd	s4,32(sp)
ffffffffc0200cfe:	ec56                	sd	s5,24(sp)
ffffffffc0200d00:	e85a                	sd	s6,16(sp)
ffffffffc0200d02:	e45e                	sd	s7,8(sp)
ffffffffc0200d04:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d06:	2c878763          	beq	a5,s0,ffffffffc0200fd4 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200d0a:	4481                	li	s1,0
ffffffffc0200d0c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d0e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d12:	8b09                	andi	a4,a4,2
ffffffffc0200d14:	2c070463          	beqz	a4,ffffffffc0200fdc <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200d18:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d1c:	679c                	ld	a5,8(a5)
ffffffffc0200d1e:	2905                	addiw	s2,s2,1
ffffffffc0200d20:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d22:	fe8796e3          	bne	a5,s0,ffffffffc0200d0e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200d26:	89a6                	mv	s3,s1
ffffffffc0200d28:	2f9000ef          	jal	ra,ffffffffc0201820 <nr_free_pages>
ffffffffc0200d2c:	71351863          	bne	a0,s3,ffffffffc020143c <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d30:	4505                	li	a0,1
ffffffffc0200d32:	271000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200d36:	8a2a                	mv	s4,a0
ffffffffc0200d38:	44050263          	beqz	a0,ffffffffc020117c <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d3c:	4505                	li	a0,1
ffffffffc0200d3e:	265000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200d42:	89aa                	mv	s3,a0
ffffffffc0200d44:	70050c63          	beqz	a0,ffffffffc020145c <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d48:	4505                	li	a0,1
ffffffffc0200d4a:	259000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200d4e:	8aaa                	mv	s5,a0
ffffffffc0200d50:	4a050663          	beqz	a0,ffffffffc02011fc <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d54:	2b3a0463          	beq	s4,s3,ffffffffc0200ffc <default_check+0x316>
ffffffffc0200d58:	2aaa0263          	beq	s4,a0,ffffffffc0200ffc <default_check+0x316>
ffffffffc0200d5c:	2aa98063          	beq	s3,a0,ffffffffc0200ffc <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d60:	000a2783          	lw	a5,0(s4)
ffffffffc0200d64:	2a079c63          	bnez	a5,ffffffffc020101c <default_check+0x336>
ffffffffc0200d68:	0009a783          	lw	a5,0(s3)
ffffffffc0200d6c:	2a079863          	bnez	a5,ffffffffc020101c <default_check+0x336>
ffffffffc0200d70:	411c                	lw	a5,0(a0)
ffffffffc0200d72:	2a079563          	bnez	a5,ffffffffc020101c <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d76:	00006797          	auipc	a5,0x6
ffffffffc0200d7a:	6fa7b783          	ld	a5,1786(a5) # ffffffffc0207470 <pages>
ffffffffc0200d7e:	40fa0733          	sub	a4,s4,a5
ffffffffc0200d82:	870d                	srai	a4,a4,0x3
ffffffffc0200d84:	00002597          	auipc	a1,0x2
ffffffffc0200d88:	31c5b583          	ld	a1,796(a1) # ffffffffc02030a0 <error_string+0x38>
ffffffffc0200d8c:	02b70733          	mul	a4,a4,a1
ffffffffc0200d90:	00002617          	auipc	a2,0x2
ffffffffc0200d94:	31863603          	ld	a2,792(a2) # ffffffffc02030a8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d98:	00006697          	auipc	a3,0x6
ffffffffc0200d9c:	6d06b683          	ld	a3,1744(a3) # ffffffffc0207468 <npage>
ffffffffc0200da0:	06b2                	slli	a3,a3,0xc
ffffffffc0200da2:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200da4:	0732                	slli	a4,a4,0xc
ffffffffc0200da6:	28d77b63          	bgeu	a4,a3,ffffffffc020103c <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200daa:	40f98733          	sub	a4,s3,a5
ffffffffc0200dae:	870d                	srai	a4,a4,0x3
ffffffffc0200db0:	02b70733          	mul	a4,a4,a1
ffffffffc0200db4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200db6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200db8:	4cd77263          	bgeu	a4,a3,ffffffffc020127c <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dbc:	40f507b3          	sub	a5,a0,a5
ffffffffc0200dc0:	878d                	srai	a5,a5,0x3
ffffffffc0200dc2:	02b787b3          	mul	a5,a5,a1
ffffffffc0200dc6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dc8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200dca:	30d7f963          	bgeu	a5,a3,ffffffffc02010dc <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200dce:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200dd0:	00043c03          	ld	s8,0(s0)
ffffffffc0200dd4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200dd8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200ddc:	e400                	sd	s0,8(s0)
ffffffffc0200dde:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200de0:	00006797          	auipc	a5,0x6
ffffffffc0200de4:	2407ac23          	sw	zero,600(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200de8:	1bb000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200dec:	2c051863          	bnez	a0,ffffffffc02010bc <default_check+0x3d6>
    free_page(p0);
ffffffffc0200df0:	4585                	li	a1,1
ffffffffc0200df2:	8552                	mv	a0,s4
ffffffffc0200df4:	1ed000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    free_page(p1);
ffffffffc0200df8:	4585                	li	a1,1
ffffffffc0200dfa:	854e                	mv	a0,s3
ffffffffc0200dfc:	1e5000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    free_page(p2);
ffffffffc0200e00:	4585                	li	a1,1
ffffffffc0200e02:	8556                	mv	a0,s5
ffffffffc0200e04:	1dd000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e08:	4818                	lw	a4,16(s0)
ffffffffc0200e0a:	478d                	li	a5,3
ffffffffc0200e0c:	28f71863          	bne	a4,a5,ffffffffc020109c <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e10:	4505                	li	a0,1
ffffffffc0200e12:	191000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200e16:	89aa                	mv	s3,a0
ffffffffc0200e18:	26050263          	beqz	a0,ffffffffc020107c <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e1c:	4505                	li	a0,1
ffffffffc0200e1e:	185000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200e22:	8aaa                	mv	s5,a0
ffffffffc0200e24:	3a050c63          	beqz	a0,ffffffffc02011dc <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e28:	4505                	li	a0,1
ffffffffc0200e2a:	179000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200e2e:	8a2a                	mv	s4,a0
ffffffffc0200e30:	38050663          	beqz	a0,ffffffffc02011bc <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200e34:	4505                	li	a0,1
ffffffffc0200e36:	16d000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200e3a:	36051163          	bnez	a0,ffffffffc020119c <default_check+0x4b6>
    free_page(p0);
ffffffffc0200e3e:	4585                	li	a1,1
ffffffffc0200e40:	854e                	mv	a0,s3
ffffffffc0200e42:	19f000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e46:	641c                	ld	a5,8(s0)
ffffffffc0200e48:	20878a63          	beq	a5,s0,ffffffffc020105c <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200e4c:	4505                	li	a0,1
ffffffffc0200e4e:	155000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200e52:	30a99563          	bne	s3,a0,ffffffffc020115c <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200e56:	4505                	li	a0,1
ffffffffc0200e58:	14b000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200e5c:	2e051063          	bnez	a0,ffffffffc020113c <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200e60:	481c                	lw	a5,16(s0)
ffffffffc0200e62:	2a079d63          	bnez	a5,ffffffffc020111c <default_check+0x436>
    free_page(p);
ffffffffc0200e66:	854e                	mv	a0,s3
ffffffffc0200e68:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e6a:	01843023          	sd	s8,0(s0)
ffffffffc0200e6e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200e72:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e76:	16b000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    free_page(p1);
ffffffffc0200e7a:	4585                	li	a1,1
ffffffffc0200e7c:	8556                	mv	a0,s5
ffffffffc0200e7e:	163000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    free_page(p2);
ffffffffc0200e82:	4585                	li	a1,1
ffffffffc0200e84:	8552                	mv	a0,s4
ffffffffc0200e86:	15b000ef          	jal	ra,ffffffffc02017e0 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e8a:	4515                	li	a0,5
ffffffffc0200e8c:	117000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200e90:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e92:	26050563          	beqz	a0,ffffffffc02010fc <default_check+0x416>
ffffffffc0200e96:	651c                	ld	a5,8(a0)
ffffffffc0200e98:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e9a:	8b85                	andi	a5,a5,1
ffffffffc0200e9c:	54079063          	bnez	a5,ffffffffc02013dc <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200ea0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ea2:	00043b03          	ld	s6,0(s0)
ffffffffc0200ea6:	00843a83          	ld	s5,8(s0)
ffffffffc0200eaa:	e000                	sd	s0,0(s0)
ffffffffc0200eac:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200eae:	0f5000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200eb2:	50051563          	bnez	a0,ffffffffc02013bc <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200eb6:	05098a13          	addi	s4,s3,80
ffffffffc0200eba:	8552                	mv	a0,s4
ffffffffc0200ebc:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ebe:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200ec2:	00006797          	auipc	a5,0x6
ffffffffc0200ec6:	1607ab23          	sw	zero,374(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200eca:	117000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ece:	4511                	li	a0,4
ffffffffc0200ed0:	0d3000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200ed4:	4c051463          	bnez	a0,ffffffffc020139c <default_check+0x6b6>
ffffffffc0200ed8:	0589b783          	ld	a5,88(s3)
ffffffffc0200edc:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200ede:	8b85                	andi	a5,a5,1
ffffffffc0200ee0:	48078e63          	beqz	a5,ffffffffc020137c <default_check+0x696>
ffffffffc0200ee4:	0609a703          	lw	a4,96(s3)
ffffffffc0200ee8:	478d                	li	a5,3
ffffffffc0200eea:	48f71963          	bne	a4,a5,ffffffffc020137c <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200eee:	450d                	li	a0,3
ffffffffc0200ef0:	0b3000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200ef4:	8c2a                	mv	s8,a0
ffffffffc0200ef6:	46050363          	beqz	a0,ffffffffc020135c <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200efa:	4505                	li	a0,1
ffffffffc0200efc:	0a7000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200f00:	42051e63          	bnez	a0,ffffffffc020133c <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200f04:	418a1c63          	bne	s4,s8,ffffffffc020131c <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f08:	4585                	li	a1,1
ffffffffc0200f0a:	854e                	mv	a0,s3
ffffffffc0200f0c:	0d5000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f10:	458d                	li	a1,3
ffffffffc0200f12:	8552                	mv	a0,s4
ffffffffc0200f14:	0cd000ef          	jal	ra,ffffffffc02017e0 <free_pages>
ffffffffc0200f18:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200f1c:	02898c13          	addi	s8,s3,40
ffffffffc0200f20:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f22:	8b85                	andi	a5,a5,1
ffffffffc0200f24:	3c078c63          	beqz	a5,ffffffffc02012fc <default_check+0x616>
ffffffffc0200f28:	0109a703          	lw	a4,16(s3)
ffffffffc0200f2c:	4785                	li	a5,1
ffffffffc0200f2e:	3cf71763          	bne	a4,a5,ffffffffc02012fc <default_check+0x616>
ffffffffc0200f32:	008a3783          	ld	a5,8(s4)
ffffffffc0200f36:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f38:	8b85                	andi	a5,a5,1
ffffffffc0200f3a:	3a078163          	beqz	a5,ffffffffc02012dc <default_check+0x5f6>
ffffffffc0200f3e:	010a2703          	lw	a4,16(s4)
ffffffffc0200f42:	478d                	li	a5,3
ffffffffc0200f44:	38f71c63          	bne	a4,a5,ffffffffc02012dc <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f48:	4505                	li	a0,1
ffffffffc0200f4a:	059000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200f4e:	36a99763          	bne	s3,a0,ffffffffc02012bc <default_check+0x5d6>
    free_page(p0);
ffffffffc0200f52:	4585                	li	a1,1
ffffffffc0200f54:	08d000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f58:	4509                	li	a0,2
ffffffffc0200f5a:	049000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200f5e:	32aa1f63          	bne	s4,a0,ffffffffc020129c <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200f62:	4589                	li	a1,2
ffffffffc0200f64:	07d000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    free_page(p2);
ffffffffc0200f68:	4585                	li	a1,1
ffffffffc0200f6a:	8562                	mv	a0,s8
ffffffffc0200f6c:	075000ef          	jal	ra,ffffffffc02017e0 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f70:	4515                	li	a0,5
ffffffffc0200f72:	031000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200f76:	89aa                	mv	s3,a0
ffffffffc0200f78:	48050263          	beqz	a0,ffffffffc02013fc <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200f7c:	4505                	li	a0,1
ffffffffc0200f7e:	025000ef          	jal	ra,ffffffffc02017a2 <alloc_pages>
ffffffffc0200f82:	2c051d63          	bnez	a0,ffffffffc020125c <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200f86:	481c                	lw	a5,16(s0)
ffffffffc0200f88:	2a079a63          	bnez	a5,ffffffffc020123c <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f8c:	4595                	li	a1,5
ffffffffc0200f8e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f90:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200f94:	01643023          	sd	s6,0(s0)
ffffffffc0200f98:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200f9c:	045000ef          	jal	ra,ffffffffc02017e0 <free_pages>
    return listelm->next;
ffffffffc0200fa0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fa2:	00878963          	beq	a5,s0,ffffffffc0200fb4 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fa6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200faa:	679c                	ld	a5,8(a5)
ffffffffc0200fac:	397d                	addiw	s2,s2,-1
ffffffffc0200fae:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fb0:	fe879be3          	bne	a5,s0,ffffffffc0200fa6 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200fb4:	26091463          	bnez	s2,ffffffffc020121c <default_check+0x536>
    assert(total == 0);
ffffffffc0200fb8:	46049263          	bnez	s1,ffffffffc020141c <default_check+0x736>
}
ffffffffc0200fbc:	60a6                	ld	ra,72(sp)
ffffffffc0200fbe:	6406                	ld	s0,64(sp)
ffffffffc0200fc0:	74e2                	ld	s1,56(sp)
ffffffffc0200fc2:	7942                	ld	s2,48(sp)
ffffffffc0200fc4:	79a2                	ld	s3,40(sp)
ffffffffc0200fc6:	7a02                	ld	s4,32(sp)
ffffffffc0200fc8:	6ae2                	ld	s5,24(sp)
ffffffffc0200fca:	6b42                	ld	s6,16(sp)
ffffffffc0200fcc:	6ba2                	ld	s7,8(sp)
ffffffffc0200fce:	6c02                	ld	s8,0(sp)
ffffffffc0200fd0:	6161                	addi	sp,sp,80
ffffffffc0200fd2:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fd4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200fd6:	4481                	li	s1,0
ffffffffc0200fd8:	4901                	li	s2,0
ffffffffc0200fda:	b3b9                	j	ffffffffc0200d28 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200fdc:	00002697          	auipc	a3,0x2
ffffffffc0200fe0:	93c68693          	addi	a3,a3,-1732 # ffffffffc0202918 <commands+0x6d8>
ffffffffc0200fe4:	00002617          	auipc	a2,0x2
ffffffffc0200fe8:	94460613          	addi	a2,a2,-1724 # ffffffffc0202928 <commands+0x6e8>
ffffffffc0200fec:	0f000593          	li	a1,240
ffffffffc0200ff0:	00002517          	auipc	a0,0x2
ffffffffc0200ff4:	95050513          	addi	a0,a0,-1712 # ffffffffc0202940 <commands+0x700>
ffffffffc0200ff8:	be0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ffc:	00002697          	auipc	a3,0x2
ffffffffc0201000:	9dc68693          	addi	a3,a3,-1572 # ffffffffc02029d8 <commands+0x798>
ffffffffc0201004:	00002617          	auipc	a2,0x2
ffffffffc0201008:	92460613          	addi	a2,a2,-1756 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020100c:	0bd00593          	li	a1,189
ffffffffc0201010:	00002517          	auipc	a0,0x2
ffffffffc0201014:	93050513          	addi	a0,a0,-1744 # ffffffffc0202940 <commands+0x700>
ffffffffc0201018:	bc0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020101c:	00002697          	auipc	a3,0x2
ffffffffc0201020:	9e468693          	addi	a3,a3,-1564 # ffffffffc0202a00 <commands+0x7c0>
ffffffffc0201024:	00002617          	auipc	a2,0x2
ffffffffc0201028:	90460613          	addi	a2,a2,-1788 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020102c:	0be00593          	li	a1,190
ffffffffc0201030:	00002517          	auipc	a0,0x2
ffffffffc0201034:	91050513          	addi	a0,a0,-1776 # ffffffffc0202940 <commands+0x700>
ffffffffc0201038:	ba0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020103c:	00002697          	auipc	a3,0x2
ffffffffc0201040:	a0468693          	addi	a3,a3,-1532 # ffffffffc0202a40 <commands+0x800>
ffffffffc0201044:	00002617          	auipc	a2,0x2
ffffffffc0201048:	8e460613          	addi	a2,a2,-1820 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020104c:	0c000593          	li	a1,192
ffffffffc0201050:	00002517          	auipc	a0,0x2
ffffffffc0201054:	8f050513          	addi	a0,a0,-1808 # ffffffffc0202940 <commands+0x700>
ffffffffc0201058:	b80ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020105c:	00002697          	auipc	a3,0x2
ffffffffc0201060:	a6c68693          	addi	a3,a3,-1428 # ffffffffc0202ac8 <commands+0x888>
ffffffffc0201064:	00002617          	auipc	a2,0x2
ffffffffc0201068:	8c460613          	addi	a2,a2,-1852 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020106c:	0d900593          	li	a1,217
ffffffffc0201070:	00002517          	auipc	a0,0x2
ffffffffc0201074:	8d050513          	addi	a0,a0,-1840 # ffffffffc0202940 <commands+0x700>
ffffffffc0201078:	b60ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020107c:	00002697          	auipc	a3,0x2
ffffffffc0201080:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0202978 <commands+0x738>
ffffffffc0201084:	00002617          	auipc	a2,0x2
ffffffffc0201088:	8a460613          	addi	a2,a2,-1884 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020108c:	0d200593          	li	a1,210
ffffffffc0201090:	00002517          	auipc	a0,0x2
ffffffffc0201094:	8b050513          	addi	a0,a0,-1872 # ffffffffc0202940 <commands+0x700>
ffffffffc0201098:	b40ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(nr_free == 3);
ffffffffc020109c:	00002697          	auipc	a3,0x2
ffffffffc02010a0:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0202ab8 <commands+0x878>
ffffffffc02010a4:	00002617          	auipc	a2,0x2
ffffffffc02010a8:	88460613          	addi	a2,a2,-1916 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02010ac:	0d000593          	li	a1,208
ffffffffc02010b0:	00002517          	auipc	a0,0x2
ffffffffc02010b4:	89050513          	addi	a0,a0,-1904 # ffffffffc0202940 <commands+0x700>
ffffffffc02010b8:	b20ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010bc:	00002697          	auipc	a3,0x2
ffffffffc02010c0:	9e468693          	addi	a3,a3,-1564 # ffffffffc0202aa0 <commands+0x860>
ffffffffc02010c4:	00002617          	auipc	a2,0x2
ffffffffc02010c8:	86460613          	addi	a2,a2,-1948 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02010cc:	0cb00593          	li	a1,203
ffffffffc02010d0:	00002517          	auipc	a0,0x2
ffffffffc02010d4:	87050513          	addi	a0,a0,-1936 # ffffffffc0202940 <commands+0x700>
ffffffffc02010d8:	b00ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010dc:	00002697          	auipc	a3,0x2
ffffffffc02010e0:	9a468693          	addi	a3,a3,-1628 # ffffffffc0202a80 <commands+0x840>
ffffffffc02010e4:	00002617          	auipc	a2,0x2
ffffffffc02010e8:	84460613          	addi	a2,a2,-1980 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02010ec:	0c200593          	li	a1,194
ffffffffc02010f0:	00002517          	auipc	a0,0x2
ffffffffc02010f4:	85050513          	addi	a0,a0,-1968 # ffffffffc0202940 <commands+0x700>
ffffffffc02010f8:	ae0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(p0 != NULL);
ffffffffc02010fc:	00002697          	auipc	a3,0x2
ffffffffc0201100:	a1468693          	addi	a3,a3,-1516 # ffffffffc0202b10 <commands+0x8d0>
ffffffffc0201104:	00002617          	auipc	a2,0x2
ffffffffc0201108:	82460613          	addi	a2,a2,-2012 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020110c:	0f800593          	li	a1,248
ffffffffc0201110:	00002517          	auipc	a0,0x2
ffffffffc0201114:	83050513          	addi	a0,a0,-2000 # ffffffffc0202940 <commands+0x700>
ffffffffc0201118:	ac0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(nr_free == 0);
ffffffffc020111c:	00002697          	auipc	a3,0x2
ffffffffc0201120:	9e468693          	addi	a3,a3,-1564 # ffffffffc0202b00 <commands+0x8c0>
ffffffffc0201124:	00002617          	auipc	a2,0x2
ffffffffc0201128:	80460613          	addi	a2,a2,-2044 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020112c:	0df00593          	li	a1,223
ffffffffc0201130:	00002517          	auipc	a0,0x2
ffffffffc0201134:	81050513          	addi	a0,a0,-2032 # ffffffffc0202940 <commands+0x700>
ffffffffc0201138:	aa0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020113c:	00002697          	auipc	a3,0x2
ffffffffc0201140:	96468693          	addi	a3,a3,-1692 # ffffffffc0202aa0 <commands+0x860>
ffffffffc0201144:	00001617          	auipc	a2,0x1
ffffffffc0201148:	7e460613          	addi	a2,a2,2020 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020114c:	0dd00593          	li	a1,221
ffffffffc0201150:	00001517          	auipc	a0,0x1
ffffffffc0201154:	7f050513          	addi	a0,a0,2032 # ffffffffc0202940 <commands+0x700>
ffffffffc0201158:	a80ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020115c:	00002697          	auipc	a3,0x2
ffffffffc0201160:	98468693          	addi	a3,a3,-1660 # ffffffffc0202ae0 <commands+0x8a0>
ffffffffc0201164:	00001617          	auipc	a2,0x1
ffffffffc0201168:	7c460613          	addi	a2,a2,1988 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020116c:	0dc00593          	li	a1,220
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	7d050513          	addi	a0,a0,2000 # ffffffffc0202940 <commands+0x700>
ffffffffc0201178:	a60ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020117c:	00001697          	auipc	a3,0x1
ffffffffc0201180:	7fc68693          	addi	a3,a3,2044 # ffffffffc0202978 <commands+0x738>
ffffffffc0201184:	00001617          	auipc	a2,0x1
ffffffffc0201188:	7a460613          	addi	a2,a2,1956 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020118c:	0b900593          	li	a1,185
ffffffffc0201190:	00001517          	auipc	a0,0x1
ffffffffc0201194:	7b050513          	addi	a0,a0,1968 # ffffffffc0202940 <commands+0x700>
ffffffffc0201198:	a40ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020119c:	00002697          	auipc	a3,0x2
ffffffffc02011a0:	90468693          	addi	a3,a3,-1788 # ffffffffc0202aa0 <commands+0x860>
ffffffffc02011a4:	00001617          	auipc	a2,0x1
ffffffffc02011a8:	78460613          	addi	a2,a2,1924 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02011ac:	0d600593          	li	a1,214
ffffffffc02011b0:	00001517          	auipc	a0,0x1
ffffffffc02011b4:	79050513          	addi	a0,a0,1936 # ffffffffc0202940 <commands+0x700>
ffffffffc02011b8:	a20ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011bc:	00001697          	auipc	a3,0x1
ffffffffc02011c0:	7fc68693          	addi	a3,a3,2044 # ffffffffc02029b8 <commands+0x778>
ffffffffc02011c4:	00001617          	auipc	a2,0x1
ffffffffc02011c8:	76460613          	addi	a2,a2,1892 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02011cc:	0d400593          	li	a1,212
ffffffffc02011d0:	00001517          	auipc	a0,0x1
ffffffffc02011d4:	77050513          	addi	a0,a0,1904 # ffffffffc0202940 <commands+0x700>
ffffffffc02011d8:	a00ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011dc:	00001697          	auipc	a3,0x1
ffffffffc02011e0:	7bc68693          	addi	a3,a3,1980 # ffffffffc0202998 <commands+0x758>
ffffffffc02011e4:	00001617          	auipc	a2,0x1
ffffffffc02011e8:	74460613          	addi	a2,a2,1860 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02011ec:	0d300593          	li	a1,211
ffffffffc02011f0:	00001517          	auipc	a0,0x1
ffffffffc02011f4:	75050513          	addi	a0,a0,1872 # ffffffffc0202940 <commands+0x700>
ffffffffc02011f8:	9e0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011fc:	00001697          	auipc	a3,0x1
ffffffffc0201200:	7bc68693          	addi	a3,a3,1980 # ffffffffc02029b8 <commands+0x778>
ffffffffc0201204:	00001617          	auipc	a2,0x1
ffffffffc0201208:	72460613          	addi	a2,a2,1828 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020120c:	0bb00593          	li	a1,187
ffffffffc0201210:	00001517          	auipc	a0,0x1
ffffffffc0201214:	73050513          	addi	a0,a0,1840 # ffffffffc0202940 <commands+0x700>
ffffffffc0201218:	9c0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(count == 0);
ffffffffc020121c:	00002697          	auipc	a3,0x2
ffffffffc0201220:	a4468693          	addi	a3,a3,-1468 # ffffffffc0202c60 <commands+0xa20>
ffffffffc0201224:	00001617          	auipc	a2,0x1
ffffffffc0201228:	70460613          	addi	a2,a2,1796 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020122c:	12500593          	li	a1,293
ffffffffc0201230:	00001517          	auipc	a0,0x1
ffffffffc0201234:	71050513          	addi	a0,a0,1808 # ffffffffc0202940 <commands+0x700>
ffffffffc0201238:	9a0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(nr_free == 0);
ffffffffc020123c:	00002697          	auipc	a3,0x2
ffffffffc0201240:	8c468693          	addi	a3,a3,-1852 # ffffffffc0202b00 <commands+0x8c0>
ffffffffc0201244:	00001617          	auipc	a2,0x1
ffffffffc0201248:	6e460613          	addi	a2,a2,1764 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020124c:	11a00593          	li	a1,282
ffffffffc0201250:	00001517          	auipc	a0,0x1
ffffffffc0201254:	6f050513          	addi	a0,a0,1776 # ffffffffc0202940 <commands+0x700>
ffffffffc0201258:	980ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020125c:	00002697          	auipc	a3,0x2
ffffffffc0201260:	84468693          	addi	a3,a3,-1980 # ffffffffc0202aa0 <commands+0x860>
ffffffffc0201264:	00001617          	auipc	a2,0x1
ffffffffc0201268:	6c460613          	addi	a2,a2,1732 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020126c:	11800593          	li	a1,280
ffffffffc0201270:	00001517          	auipc	a0,0x1
ffffffffc0201274:	6d050513          	addi	a0,a0,1744 # ffffffffc0202940 <commands+0x700>
ffffffffc0201278:	960ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020127c:	00001697          	auipc	a3,0x1
ffffffffc0201280:	7e468693          	addi	a3,a3,2020 # ffffffffc0202a60 <commands+0x820>
ffffffffc0201284:	00001617          	auipc	a2,0x1
ffffffffc0201288:	6a460613          	addi	a2,a2,1700 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020128c:	0c100593          	li	a1,193
ffffffffc0201290:	00001517          	auipc	a0,0x1
ffffffffc0201294:	6b050513          	addi	a0,a0,1712 # ffffffffc0202940 <commands+0x700>
ffffffffc0201298:	940ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020129c:	00002697          	auipc	a3,0x2
ffffffffc02012a0:	98468693          	addi	a3,a3,-1660 # ffffffffc0202c20 <commands+0x9e0>
ffffffffc02012a4:	00001617          	auipc	a2,0x1
ffffffffc02012a8:	68460613          	addi	a2,a2,1668 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02012ac:	11200593          	li	a1,274
ffffffffc02012b0:	00001517          	auipc	a0,0x1
ffffffffc02012b4:	69050513          	addi	a0,a0,1680 # ffffffffc0202940 <commands+0x700>
ffffffffc02012b8:	920ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012bc:	00002697          	auipc	a3,0x2
ffffffffc02012c0:	94468693          	addi	a3,a3,-1724 # ffffffffc0202c00 <commands+0x9c0>
ffffffffc02012c4:	00001617          	auipc	a2,0x1
ffffffffc02012c8:	66460613          	addi	a2,a2,1636 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02012cc:	11000593          	li	a1,272
ffffffffc02012d0:	00001517          	auipc	a0,0x1
ffffffffc02012d4:	67050513          	addi	a0,a0,1648 # ffffffffc0202940 <commands+0x700>
ffffffffc02012d8:	900ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012dc:	00002697          	auipc	a3,0x2
ffffffffc02012e0:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0202bd8 <commands+0x998>
ffffffffc02012e4:	00001617          	auipc	a2,0x1
ffffffffc02012e8:	64460613          	addi	a2,a2,1604 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02012ec:	10e00593          	li	a1,270
ffffffffc02012f0:	00001517          	auipc	a0,0x1
ffffffffc02012f4:	65050513          	addi	a0,a0,1616 # ffffffffc0202940 <commands+0x700>
ffffffffc02012f8:	8e0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012fc:	00002697          	auipc	a3,0x2
ffffffffc0201300:	8b468693          	addi	a3,a3,-1868 # ffffffffc0202bb0 <commands+0x970>
ffffffffc0201304:	00001617          	auipc	a2,0x1
ffffffffc0201308:	62460613          	addi	a2,a2,1572 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020130c:	10d00593          	li	a1,269
ffffffffc0201310:	00001517          	auipc	a0,0x1
ffffffffc0201314:	63050513          	addi	a0,a0,1584 # ffffffffc0202940 <commands+0x700>
ffffffffc0201318:	8c0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020131c:	00002697          	auipc	a3,0x2
ffffffffc0201320:	88468693          	addi	a3,a3,-1916 # ffffffffc0202ba0 <commands+0x960>
ffffffffc0201324:	00001617          	auipc	a2,0x1
ffffffffc0201328:	60460613          	addi	a2,a2,1540 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020132c:	10800593          	li	a1,264
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	61050513          	addi	a0,a0,1552 # ffffffffc0202940 <commands+0x700>
ffffffffc0201338:	8a0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020133c:	00001697          	auipc	a3,0x1
ffffffffc0201340:	76468693          	addi	a3,a3,1892 # ffffffffc0202aa0 <commands+0x860>
ffffffffc0201344:	00001617          	auipc	a2,0x1
ffffffffc0201348:	5e460613          	addi	a2,a2,1508 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020134c:	10700593          	li	a1,263
ffffffffc0201350:	00001517          	auipc	a0,0x1
ffffffffc0201354:	5f050513          	addi	a0,a0,1520 # ffffffffc0202940 <commands+0x700>
ffffffffc0201358:	880ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020135c:	00002697          	auipc	a3,0x2
ffffffffc0201360:	82468693          	addi	a3,a3,-2012 # ffffffffc0202b80 <commands+0x940>
ffffffffc0201364:	00001617          	auipc	a2,0x1
ffffffffc0201368:	5c460613          	addi	a2,a2,1476 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020136c:	10600593          	li	a1,262
ffffffffc0201370:	00001517          	auipc	a0,0x1
ffffffffc0201374:	5d050513          	addi	a0,a0,1488 # ffffffffc0202940 <commands+0x700>
ffffffffc0201378:	860ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020137c:	00001697          	auipc	a3,0x1
ffffffffc0201380:	7d468693          	addi	a3,a3,2004 # ffffffffc0202b50 <commands+0x910>
ffffffffc0201384:	00001617          	auipc	a2,0x1
ffffffffc0201388:	5a460613          	addi	a2,a2,1444 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020138c:	10500593          	li	a1,261
ffffffffc0201390:	00001517          	auipc	a0,0x1
ffffffffc0201394:	5b050513          	addi	a0,a0,1456 # ffffffffc0202940 <commands+0x700>
ffffffffc0201398:	840ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020139c:	00001697          	auipc	a3,0x1
ffffffffc02013a0:	79c68693          	addi	a3,a3,1948 # ffffffffc0202b38 <commands+0x8f8>
ffffffffc02013a4:	00001617          	auipc	a2,0x1
ffffffffc02013a8:	58460613          	addi	a2,a2,1412 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02013ac:	10400593          	li	a1,260
ffffffffc02013b0:	00001517          	auipc	a0,0x1
ffffffffc02013b4:	59050513          	addi	a0,a0,1424 # ffffffffc0202940 <commands+0x700>
ffffffffc02013b8:	820ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013bc:	00001697          	auipc	a3,0x1
ffffffffc02013c0:	6e468693          	addi	a3,a3,1764 # ffffffffc0202aa0 <commands+0x860>
ffffffffc02013c4:	00001617          	auipc	a2,0x1
ffffffffc02013c8:	56460613          	addi	a2,a2,1380 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02013cc:	0fe00593          	li	a1,254
ffffffffc02013d0:	00001517          	auipc	a0,0x1
ffffffffc02013d4:	57050513          	addi	a0,a0,1392 # ffffffffc0202940 <commands+0x700>
ffffffffc02013d8:	800ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(!PageProperty(p0));
ffffffffc02013dc:	00001697          	auipc	a3,0x1
ffffffffc02013e0:	74468693          	addi	a3,a3,1860 # ffffffffc0202b20 <commands+0x8e0>
ffffffffc02013e4:	00001617          	auipc	a2,0x1
ffffffffc02013e8:	54460613          	addi	a2,a2,1348 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02013ec:	0f900593          	li	a1,249
ffffffffc02013f0:	00001517          	auipc	a0,0x1
ffffffffc02013f4:	55050513          	addi	a0,a0,1360 # ffffffffc0202940 <commands+0x700>
ffffffffc02013f8:	fe1fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02013fc:	00002697          	auipc	a3,0x2
ffffffffc0201400:	84468693          	addi	a3,a3,-1980 # ffffffffc0202c40 <commands+0xa00>
ffffffffc0201404:	00001617          	auipc	a2,0x1
ffffffffc0201408:	52460613          	addi	a2,a2,1316 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020140c:	11700593          	li	a1,279
ffffffffc0201410:	00001517          	auipc	a0,0x1
ffffffffc0201414:	53050513          	addi	a0,a0,1328 # ffffffffc0202940 <commands+0x700>
ffffffffc0201418:	fc1fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(total == 0);
ffffffffc020141c:	00002697          	auipc	a3,0x2
ffffffffc0201420:	85468693          	addi	a3,a3,-1964 # ffffffffc0202c70 <commands+0xa30>
ffffffffc0201424:	00001617          	auipc	a2,0x1
ffffffffc0201428:	50460613          	addi	a2,a2,1284 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020142c:	12600593          	li	a1,294
ffffffffc0201430:	00001517          	auipc	a0,0x1
ffffffffc0201434:	51050513          	addi	a0,a0,1296 # ffffffffc0202940 <commands+0x700>
ffffffffc0201438:	fa1fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(total == nr_free_pages());
ffffffffc020143c:	00001697          	auipc	a3,0x1
ffffffffc0201440:	51c68693          	addi	a3,a3,1308 # ffffffffc0202958 <commands+0x718>
ffffffffc0201444:	00001617          	auipc	a2,0x1
ffffffffc0201448:	4e460613          	addi	a2,a2,1252 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020144c:	0f300593          	li	a1,243
ffffffffc0201450:	00001517          	auipc	a0,0x1
ffffffffc0201454:	4f050513          	addi	a0,a0,1264 # ffffffffc0202940 <commands+0x700>
ffffffffc0201458:	f81fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020145c:	00001697          	auipc	a3,0x1
ffffffffc0201460:	53c68693          	addi	a3,a3,1340 # ffffffffc0202998 <commands+0x758>
ffffffffc0201464:	00001617          	auipc	a2,0x1
ffffffffc0201468:	4c460613          	addi	a2,a2,1220 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020146c:	0ba00593          	li	a1,186
ffffffffc0201470:	00001517          	auipc	a0,0x1
ffffffffc0201474:	4d050513          	addi	a0,a0,1232 # ffffffffc0202940 <commands+0x700>
ffffffffc0201478:	f61fe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc020147c <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020147c:	1141                	addi	sp,sp,-16
ffffffffc020147e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201480:	14058a63          	beqz	a1,ffffffffc02015d4 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201484:	00259693          	slli	a3,a1,0x2
ffffffffc0201488:	96ae                	add	a3,a3,a1
ffffffffc020148a:	068e                	slli	a3,a3,0x3
ffffffffc020148c:	96aa                	add	a3,a3,a0
ffffffffc020148e:	87aa                	mv	a5,a0
ffffffffc0201490:	02d50263          	beq	a0,a3,ffffffffc02014b4 <default_free_pages+0x38>
ffffffffc0201494:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201496:	8b05                	andi	a4,a4,1
ffffffffc0201498:	10071e63          	bnez	a4,ffffffffc02015b4 <default_free_pages+0x138>
ffffffffc020149c:	6798                	ld	a4,8(a5)
ffffffffc020149e:	8b09                	andi	a4,a4,2
ffffffffc02014a0:	10071a63          	bnez	a4,ffffffffc02015b4 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc02014a4:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02014a8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014ac:	02878793          	addi	a5,a5,40
ffffffffc02014b0:	fed792e3          	bne	a5,a3,ffffffffc0201494 <default_free_pages+0x18>
    base->property = n;
ffffffffc02014b4:	2581                	sext.w	a1,a1
ffffffffc02014b6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02014b8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014bc:	4789                	li	a5,2
ffffffffc02014be:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02014c2:	00006697          	auipc	a3,0x6
ffffffffc02014c6:	b6668693          	addi	a3,a3,-1178 # ffffffffc0207028 <free_area>
ffffffffc02014ca:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014cc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02014ce:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014d2:	9db9                	addw	a1,a1,a4
ffffffffc02014d4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014d6:	0ad78863          	beq	a5,a3,ffffffffc0201586 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014da:	fe878713          	addi	a4,a5,-24
ffffffffc02014de:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014e2:	4581                	li	a1,0
            if (base < page) {
ffffffffc02014e4:	00e56a63          	bltu	a0,a4,ffffffffc02014f8 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc02014e8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014ea:	06d70263          	beq	a4,a3,ffffffffc020154e <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02014ee:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014f0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014f4:	fee57ae3          	bgeu	a0,a4,ffffffffc02014e8 <default_free_pages+0x6c>
ffffffffc02014f8:	c199                	beqz	a1,ffffffffc02014fe <default_free_pages+0x82>
ffffffffc02014fa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014fe:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201500:	e390                	sd	a2,0(a5)
ffffffffc0201502:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201504:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201506:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201508:	02d70063          	beq	a4,a3,ffffffffc0201528 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc020150c:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201510:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201514:	02081613          	slli	a2,a6,0x20
ffffffffc0201518:	9201                	srli	a2,a2,0x20
ffffffffc020151a:	00261793          	slli	a5,a2,0x2
ffffffffc020151e:	97b2                	add	a5,a5,a2
ffffffffc0201520:	078e                	slli	a5,a5,0x3
ffffffffc0201522:	97ae                	add	a5,a5,a1
ffffffffc0201524:	02f50f63          	beq	a0,a5,ffffffffc0201562 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc0201528:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020152a:	00d70f63          	beq	a4,a3,ffffffffc0201548 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc020152e:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201530:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201534:	02059613          	slli	a2,a1,0x20
ffffffffc0201538:	9201                	srli	a2,a2,0x20
ffffffffc020153a:	00261793          	slli	a5,a2,0x2
ffffffffc020153e:	97b2                	add	a5,a5,a2
ffffffffc0201540:	078e                	slli	a5,a5,0x3
ffffffffc0201542:	97aa                	add	a5,a5,a0
ffffffffc0201544:	04f68863          	beq	a3,a5,ffffffffc0201594 <default_free_pages+0x118>
}
ffffffffc0201548:	60a2                	ld	ra,8(sp)
ffffffffc020154a:	0141                	addi	sp,sp,16
ffffffffc020154c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020154e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201550:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201552:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201554:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201556:	02d70563          	beq	a4,a3,ffffffffc0201580 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc020155a:	8832                	mv	a6,a2
ffffffffc020155c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020155e:	87ba                	mv	a5,a4
ffffffffc0201560:	bf41                	j	ffffffffc02014f0 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc0201562:	491c                	lw	a5,16(a0)
ffffffffc0201564:	0107883b          	addw	a6,a5,a6
ffffffffc0201568:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020156c:	57f5                	li	a5,-3
ffffffffc020156e:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201572:	6d10                	ld	a2,24(a0)
ffffffffc0201574:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201576:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201578:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020157a:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc020157c:	e390                	sd	a2,0(a5)
ffffffffc020157e:	b775                	j	ffffffffc020152a <default_free_pages+0xae>
ffffffffc0201580:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201582:	873e                	mv	a4,a5
ffffffffc0201584:	b761                	j	ffffffffc020150c <default_free_pages+0x90>
}
ffffffffc0201586:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201588:	e390                	sd	a2,0(a5)
ffffffffc020158a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020158c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020158e:	ed1c                	sd	a5,24(a0)
ffffffffc0201590:	0141                	addi	sp,sp,16
ffffffffc0201592:	8082                	ret
            base->property += p->property;
ffffffffc0201594:	ff872783          	lw	a5,-8(a4)
ffffffffc0201598:	ff070693          	addi	a3,a4,-16
ffffffffc020159c:	9dbd                	addw	a1,a1,a5
ffffffffc020159e:	c90c                	sw	a1,16(a0)
ffffffffc02015a0:	57f5                	li	a5,-3
ffffffffc02015a2:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015a6:	6314                	ld	a3,0(a4)
ffffffffc02015a8:	671c                	ld	a5,8(a4)
}
ffffffffc02015aa:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02015ac:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02015ae:	e394                	sd	a3,0(a5)
ffffffffc02015b0:	0141                	addi	sp,sp,16
ffffffffc02015b2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015b4:	00001697          	auipc	a3,0x1
ffffffffc02015b8:	6d468693          	addi	a3,a3,1748 # ffffffffc0202c88 <commands+0xa48>
ffffffffc02015bc:	00001617          	auipc	a2,0x1
ffffffffc02015c0:	36c60613          	addi	a2,a2,876 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02015c4:	08300593          	li	a1,131
ffffffffc02015c8:	00001517          	auipc	a0,0x1
ffffffffc02015cc:	37850513          	addi	a0,a0,888 # ffffffffc0202940 <commands+0x700>
ffffffffc02015d0:	e09fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(n > 0);
ffffffffc02015d4:	00001697          	auipc	a3,0x1
ffffffffc02015d8:	6ac68693          	addi	a3,a3,1708 # ffffffffc0202c80 <commands+0xa40>
ffffffffc02015dc:	00001617          	auipc	a2,0x1
ffffffffc02015e0:	34c60613          	addi	a2,a2,844 # ffffffffc0202928 <commands+0x6e8>
ffffffffc02015e4:	08000593          	li	a1,128
ffffffffc02015e8:	00001517          	auipc	a0,0x1
ffffffffc02015ec:	35850513          	addi	a0,a0,856 # ffffffffc0202940 <commands+0x700>
ffffffffc02015f0:	de9fe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc02015f4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02015f4:	c959                	beqz	a0,ffffffffc020168a <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02015f6:	00006597          	auipc	a1,0x6
ffffffffc02015fa:	a3258593          	addi	a1,a1,-1486 # ffffffffc0207028 <free_area>
ffffffffc02015fe:	0105a803          	lw	a6,16(a1)
ffffffffc0201602:	862a                	mv	a2,a0
ffffffffc0201604:	02081793          	slli	a5,a6,0x20
ffffffffc0201608:	9381                	srli	a5,a5,0x20
ffffffffc020160a:	00a7ee63          	bltu	a5,a0,ffffffffc0201626 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020160e:	87ae                	mv	a5,a1
ffffffffc0201610:	a801                	j	ffffffffc0201620 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201612:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201616:	02071693          	slli	a3,a4,0x20
ffffffffc020161a:	9281                	srli	a3,a3,0x20
ffffffffc020161c:	00c6f763          	bgeu	a3,a2,ffffffffc020162a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201620:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201622:	feb798e3          	bne	a5,a1,ffffffffc0201612 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201626:	4501                	li	a0,0
}
ffffffffc0201628:	8082                	ret
    return listelm->prev;
ffffffffc020162a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020162e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201632:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201636:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc020163a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020163e:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201642:	02d67b63          	bgeu	a2,a3,ffffffffc0201678 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0201646:	00261693          	slli	a3,a2,0x2
ffffffffc020164a:	96b2                	add	a3,a3,a2
ffffffffc020164c:	068e                	slli	a3,a3,0x3
ffffffffc020164e:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201650:	41c7073b          	subw	a4,a4,t3
ffffffffc0201654:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201656:	00868613          	addi	a2,a3,8
ffffffffc020165a:	4709                	li	a4,2
ffffffffc020165c:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201660:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201664:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc0201668:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020166c:	e310                	sd	a2,0(a4)
ffffffffc020166e:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201672:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0201674:	0116bc23          	sd	a7,24(a3)
ffffffffc0201678:	41c8083b          	subw	a6,a6,t3
ffffffffc020167c:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201680:	5775                	li	a4,-3
ffffffffc0201682:	17c1                	addi	a5,a5,-16
ffffffffc0201684:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201688:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020168a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020168c:	00001697          	auipc	a3,0x1
ffffffffc0201690:	5f468693          	addi	a3,a3,1524 # ffffffffc0202c80 <commands+0xa40>
ffffffffc0201694:	00001617          	auipc	a2,0x1
ffffffffc0201698:	29460613          	addi	a2,a2,660 # ffffffffc0202928 <commands+0x6e8>
ffffffffc020169c:	06200593          	li	a1,98
ffffffffc02016a0:	00001517          	auipc	a0,0x1
ffffffffc02016a4:	2a050513          	addi	a0,a0,672 # ffffffffc0202940 <commands+0x700>
default_alloc_pages(size_t n) {
ffffffffc02016a8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016aa:	d2ffe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc02016ae <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02016ae:	1141                	addi	sp,sp,-16
ffffffffc02016b0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016b2:	c9e1                	beqz	a1,ffffffffc0201782 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02016b4:	00259693          	slli	a3,a1,0x2
ffffffffc02016b8:	96ae                	add	a3,a3,a1
ffffffffc02016ba:	068e                	slli	a3,a3,0x3
ffffffffc02016bc:	96aa                	add	a3,a3,a0
ffffffffc02016be:	87aa                	mv	a5,a0
ffffffffc02016c0:	00d50f63          	beq	a0,a3,ffffffffc02016de <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02016c4:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02016c6:	8b05                	andi	a4,a4,1
ffffffffc02016c8:	cf49                	beqz	a4,ffffffffc0201762 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02016ca:	0007a823          	sw	zero,16(a5)
ffffffffc02016ce:	0007b423          	sd	zero,8(a5)
ffffffffc02016d2:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016d6:	02878793          	addi	a5,a5,40
ffffffffc02016da:	fed795e3          	bne	a5,a3,ffffffffc02016c4 <default_init_memmap+0x16>
    base->property = n;
ffffffffc02016de:	2581                	sext.w	a1,a1
ffffffffc02016e0:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016e2:	4789                	li	a5,2
ffffffffc02016e4:	00850713          	addi	a4,a0,8
ffffffffc02016e8:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02016ec:	00006697          	auipc	a3,0x6
ffffffffc02016f0:	93c68693          	addi	a3,a3,-1732 # ffffffffc0207028 <free_area>
ffffffffc02016f4:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016f6:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016f8:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016fc:	9db9                	addw	a1,a1,a4
ffffffffc02016fe:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201700:	04d78a63          	beq	a5,a3,ffffffffc0201754 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201704:	fe878713          	addi	a4,a5,-24
ffffffffc0201708:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020170c:	4581                	li	a1,0
            if (base < page) {
ffffffffc020170e:	00e56a63          	bltu	a0,a4,ffffffffc0201722 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc0201712:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201714:	02d70263          	beq	a4,a3,ffffffffc0201738 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201718:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020171a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020171e:	fee57ae3          	bgeu	a0,a4,ffffffffc0201712 <default_init_memmap+0x64>
ffffffffc0201722:	c199                	beqz	a1,ffffffffc0201728 <default_init_memmap+0x7a>
ffffffffc0201724:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201728:	6398                	ld	a4,0(a5)
}
ffffffffc020172a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020172c:	e390                	sd	a2,0(a5)
ffffffffc020172e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201730:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201732:	ed18                	sd	a4,24(a0)
ffffffffc0201734:	0141                	addi	sp,sp,16
ffffffffc0201736:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201738:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020173a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020173c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020173e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201740:	00d70663          	beq	a4,a3,ffffffffc020174c <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201744:	8832                	mv	a6,a2
ffffffffc0201746:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201748:	87ba                	mv	a5,a4
ffffffffc020174a:	bfc1                	j	ffffffffc020171a <default_init_memmap+0x6c>
}
ffffffffc020174c:	60a2                	ld	ra,8(sp)
ffffffffc020174e:	e290                	sd	a2,0(a3)
ffffffffc0201750:	0141                	addi	sp,sp,16
ffffffffc0201752:	8082                	ret
ffffffffc0201754:	60a2                	ld	ra,8(sp)
ffffffffc0201756:	e390                	sd	a2,0(a5)
ffffffffc0201758:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020175a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020175c:	ed1c                	sd	a5,24(a0)
ffffffffc020175e:	0141                	addi	sp,sp,16
ffffffffc0201760:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201762:	00001697          	auipc	a3,0x1
ffffffffc0201766:	54e68693          	addi	a3,a3,1358 # ffffffffc0202cb0 <commands+0xa70>
ffffffffc020176a:	00001617          	auipc	a2,0x1
ffffffffc020176e:	1be60613          	addi	a2,a2,446 # ffffffffc0202928 <commands+0x6e8>
ffffffffc0201772:	04900593          	li	a1,73
ffffffffc0201776:	00001517          	auipc	a0,0x1
ffffffffc020177a:	1ca50513          	addi	a0,a0,458 # ffffffffc0202940 <commands+0x700>
ffffffffc020177e:	c5bfe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(n > 0);
ffffffffc0201782:	00001697          	auipc	a3,0x1
ffffffffc0201786:	4fe68693          	addi	a3,a3,1278 # ffffffffc0202c80 <commands+0xa40>
ffffffffc020178a:	00001617          	auipc	a2,0x1
ffffffffc020178e:	19e60613          	addi	a2,a2,414 # ffffffffc0202928 <commands+0x6e8>
ffffffffc0201792:	04600593          	li	a1,70
ffffffffc0201796:	00001517          	auipc	a0,0x1
ffffffffc020179a:	1aa50513          	addi	a0,a0,426 # ffffffffc0202940 <commands+0x700>
ffffffffc020179e:	c3bfe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc02017a2 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017a2:	100027f3          	csrr	a5,sstatus
ffffffffc02017a6:	8b89                	andi	a5,a5,2
ffffffffc02017a8:	e799                	bnez	a5,ffffffffc02017b6 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02017aa:	00006797          	auipc	a5,0x6
ffffffffc02017ae:	cce7b783          	ld	a5,-818(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017b2:	6f9c                	ld	a5,24(a5)
ffffffffc02017b4:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02017b6:	1141                	addi	sp,sp,-16
ffffffffc02017b8:	e406                	sd	ra,8(sp)
ffffffffc02017ba:	e022                	sd	s0,0(sp)
ffffffffc02017bc:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02017be:	87cff0ef          	jal	ra,ffffffffc020083a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02017c2:	00006797          	auipc	a5,0x6
ffffffffc02017c6:	cb67b783          	ld	a5,-842(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017ca:	6f9c                	ld	a5,24(a5)
ffffffffc02017cc:	8522                	mv	a0,s0
ffffffffc02017ce:	9782                	jalr	a5
ffffffffc02017d0:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02017d2:	862ff0ef          	jal	ra,ffffffffc0200834 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02017d6:	60a2                	ld	ra,8(sp)
ffffffffc02017d8:	8522                	mv	a0,s0
ffffffffc02017da:	6402                	ld	s0,0(sp)
ffffffffc02017dc:	0141                	addi	sp,sp,16
ffffffffc02017de:	8082                	ret

ffffffffc02017e0 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017e0:	100027f3          	csrr	a5,sstatus
ffffffffc02017e4:	8b89                	andi	a5,a5,2
ffffffffc02017e6:	e799                	bnez	a5,ffffffffc02017f4 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02017e8:	00006797          	auipc	a5,0x6
ffffffffc02017ec:	c907b783          	ld	a5,-880(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017f0:	739c                	ld	a5,32(a5)
ffffffffc02017f2:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02017f4:	1101                	addi	sp,sp,-32
ffffffffc02017f6:	ec06                	sd	ra,24(sp)
ffffffffc02017f8:	e822                	sd	s0,16(sp)
ffffffffc02017fa:	e426                	sd	s1,8(sp)
ffffffffc02017fc:	842a                	mv	s0,a0
ffffffffc02017fe:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201800:	83aff0ef          	jal	ra,ffffffffc020083a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201804:	00006797          	auipc	a5,0x6
ffffffffc0201808:	c747b783          	ld	a5,-908(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020180c:	739c                	ld	a5,32(a5)
ffffffffc020180e:	85a6                	mv	a1,s1
ffffffffc0201810:	8522                	mv	a0,s0
ffffffffc0201812:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201814:	6442                	ld	s0,16(sp)
ffffffffc0201816:	60e2                	ld	ra,24(sp)
ffffffffc0201818:	64a2                	ld	s1,8(sp)
ffffffffc020181a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020181c:	818ff06f          	j	ffffffffc0200834 <intr_enable>

ffffffffc0201820 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201820:	100027f3          	csrr	a5,sstatus
ffffffffc0201824:	8b89                	andi	a5,a5,2
ffffffffc0201826:	e799                	bnez	a5,ffffffffc0201834 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201828:	00006797          	auipc	a5,0x6
ffffffffc020182c:	c507b783          	ld	a5,-944(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201830:	779c                	ld	a5,40(a5)
ffffffffc0201832:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201834:	1141                	addi	sp,sp,-16
ffffffffc0201836:	e406                	sd	ra,8(sp)
ffffffffc0201838:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020183a:	800ff0ef          	jal	ra,ffffffffc020083a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020183e:	00006797          	auipc	a5,0x6
ffffffffc0201842:	c3a7b783          	ld	a5,-966(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201846:	779c                	ld	a5,40(a5)
ffffffffc0201848:	9782                	jalr	a5
ffffffffc020184a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020184c:	fe9fe0ef          	jal	ra,ffffffffc0200834 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201850:	60a2                	ld	ra,8(sp)
ffffffffc0201852:	8522                	mv	a0,s0
ffffffffc0201854:	6402                	ld	s0,0(sp)
ffffffffc0201856:	0141                	addi	sp,sp,16
ffffffffc0201858:	8082                	ret

ffffffffc020185a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020185a:	00001797          	auipc	a5,0x1
ffffffffc020185e:	47e78793          	addi	a5,a5,1150 # ffffffffc0202cd8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201862:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201864:	7179                	addi	sp,sp,-48
ffffffffc0201866:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201868:	00001517          	auipc	a0,0x1
ffffffffc020186c:	4a850513          	addi	a0,a0,1192 # ffffffffc0202d10 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc0201870:	00006417          	auipc	s0,0x6
ffffffffc0201874:	c0840413          	addi	s0,s0,-1016 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201878:	f406                	sd	ra,40(sp)
ffffffffc020187a:	ec26                	sd	s1,24(sp)
ffffffffc020187c:	e44e                	sd	s3,8(sp)
ffffffffc020187e:	e84a                	sd	s2,16(sp)
ffffffffc0201880:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201882:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201884:	85bfe0ef          	jal	ra,ffffffffc02000de <cprintf>
    pmm_manager->init();
ffffffffc0201888:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020188a:	00006497          	auipc	s1,0x6
ffffffffc020188e:	c0648493          	addi	s1,s1,-1018 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201892:	679c                	ld	a5,8(a5)
ffffffffc0201894:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201896:	57f5                	li	a5,-3
ffffffffc0201898:	07fa                	slli	a5,a5,0x1e
ffffffffc020189a:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc020189c:	f85fe0ef          	jal	ra,ffffffffc0200820 <get_memory_base>
ffffffffc02018a0:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02018a2:	f89fe0ef          	jal	ra,ffffffffc020082a <get_memory_size>
    if (mem_size == 0) {
ffffffffc02018a6:	16050163          	beqz	a0,ffffffffc0201a08 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018aa:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02018ac:	00001517          	auipc	a0,0x1
ffffffffc02018b0:	4ac50513          	addi	a0,a0,1196 # ffffffffc0202d58 <default_pmm_manager+0x80>
ffffffffc02018b4:	82bfe0ef          	jal	ra,ffffffffc02000de <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018b8:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02018bc:	864e                	mv	a2,s3
ffffffffc02018be:	fffa0693          	addi	a3,s4,-1
ffffffffc02018c2:	85ca                	mv	a1,s2
ffffffffc02018c4:	00001517          	auipc	a0,0x1
ffffffffc02018c8:	4ac50513          	addi	a0,a0,1196 # ffffffffc0202d70 <default_pmm_manager+0x98>
ffffffffc02018cc:	813fe0ef          	jal	ra,ffffffffc02000de <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018d0:	c80007b7          	lui	a5,0xc8000
ffffffffc02018d4:	8652                	mv	a2,s4
ffffffffc02018d6:	0d47e863          	bltu	a5,s4,ffffffffc02019a6 <pmm_init+0x14c>
ffffffffc02018da:	00007797          	auipc	a5,0x7
ffffffffc02018de:	bc578793          	addi	a5,a5,-1083 # ffffffffc020849f <end+0xfff>
ffffffffc02018e2:	757d                	lui	a0,0xfffff
ffffffffc02018e4:	8d7d                	and	a0,a0,a5
ffffffffc02018e6:	8231                	srli	a2,a2,0xc
ffffffffc02018e8:	00006597          	auipc	a1,0x6
ffffffffc02018ec:	b8058593          	addi	a1,a1,-1152 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018f0:	00006817          	auipc	a6,0x6
ffffffffc02018f4:	b8080813          	addi	a6,a6,-1152 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02018f8:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018fa:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018fe:	000807b7          	lui	a5,0x80
ffffffffc0201902:	02f60663          	beq	a2,a5,ffffffffc020192e <pmm_init+0xd4>
ffffffffc0201906:	4701                	li	a4,0
ffffffffc0201908:	4781                	li	a5,0
ffffffffc020190a:	4305                	li	t1,1
ffffffffc020190c:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201910:	953a                	add	a0,a0,a4
ffffffffc0201912:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc0201916:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020191a:	6190                	ld	a2,0(a1)
ffffffffc020191c:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020191e:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201922:	011606b3          	add	a3,a2,a7
ffffffffc0201926:	02870713          	addi	a4,a4,40
ffffffffc020192a:	fed7e3e3          	bltu	a5,a3,ffffffffc0201910 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020192e:	00261693          	slli	a3,a2,0x2
ffffffffc0201932:	96b2                	add	a3,a3,a2
ffffffffc0201934:	fec007b7          	lui	a5,0xfec00
ffffffffc0201938:	97aa                	add	a5,a5,a0
ffffffffc020193a:	068e                	slli	a3,a3,0x3
ffffffffc020193c:	96be                	add	a3,a3,a5
ffffffffc020193e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201942:	0af6e763          	bltu	a3,a5,ffffffffc02019f0 <pmm_init+0x196>
ffffffffc0201946:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201948:	77fd                	lui	a5,0xfffff
ffffffffc020194a:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020194e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201950:	04b6ee63          	bltu	a3,a1,ffffffffc02019ac <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201954:	601c                	ld	a5,0(s0)
ffffffffc0201956:	7b9c                	ld	a5,48(a5)
ffffffffc0201958:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020195a:	00001517          	auipc	a0,0x1
ffffffffc020195e:	49e50513          	addi	a0,a0,1182 # ffffffffc0202df8 <default_pmm_manager+0x120>
ffffffffc0201962:	f7cfe0ef          	jal	ra,ffffffffc02000de <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201966:	00004597          	auipc	a1,0x4
ffffffffc020196a:	69a58593          	addi	a1,a1,1690 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc020196e:	00006797          	auipc	a5,0x6
ffffffffc0201972:	b0b7bd23          	sd	a1,-1254(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201976:	c02007b7          	lui	a5,0xc0200
ffffffffc020197a:	0af5e363          	bltu	a1,a5,ffffffffc0201a20 <pmm_init+0x1c6>
ffffffffc020197e:	6090                	ld	a2,0(s1)
}
ffffffffc0201980:	7402                	ld	s0,32(sp)
ffffffffc0201982:	70a2                	ld	ra,40(sp)
ffffffffc0201984:	64e2                	ld	s1,24(sp)
ffffffffc0201986:	6942                	ld	s2,16(sp)
ffffffffc0201988:	69a2                	ld	s3,8(sp)
ffffffffc020198a:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020198c:	40c58633          	sub	a2,a1,a2
ffffffffc0201990:	00006797          	auipc	a5,0x6
ffffffffc0201994:	aec7b823          	sd	a2,-1296(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201998:	00001517          	auipc	a0,0x1
ffffffffc020199c:	48050513          	addi	a0,a0,1152 # ffffffffc0202e18 <default_pmm_manager+0x140>
}
ffffffffc02019a0:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02019a2:	f3cfe06f          	j	ffffffffc02000de <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02019a6:	c8000637          	lui	a2,0xc8000
ffffffffc02019aa:	bf05                	j	ffffffffc02018da <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02019ac:	6705                	lui	a4,0x1
ffffffffc02019ae:	177d                	addi	a4,a4,-1
ffffffffc02019b0:	96ba                	add	a3,a3,a4
ffffffffc02019b2:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02019b4:	00c6d793          	srli	a5,a3,0xc
ffffffffc02019b8:	02c7f063          	bgeu	a5,a2,ffffffffc02019d8 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc02019bc:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02019be:	fff80737          	lui	a4,0xfff80
ffffffffc02019c2:	973e                	add	a4,a4,a5
ffffffffc02019c4:	00271793          	slli	a5,a4,0x2
ffffffffc02019c8:	97ba                	add	a5,a5,a4
ffffffffc02019ca:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02019cc:	8d95                	sub	a1,a1,a3
ffffffffc02019ce:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02019d0:	81b1                	srli	a1,a1,0xc
ffffffffc02019d2:	953e                	add	a0,a0,a5
ffffffffc02019d4:	9702                	jalr	a4
}
ffffffffc02019d6:	bfbd                	j	ffffffffc0201954 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02019d8:	00001617          	auipc	a2,0x1
ffffffffc02019dc:	3f060613          	addi	a2,a2,1008 # ffffffffc0202dc8 <default_pmm_manager+0xf0>
ffffffffc02019e0:	06b00593          	li	a1,107
ffffffffc02019e4:	00001517          	auipc	a0,0x1
ffffffffc02019e8:	40450513          	addi	a0,a0,1028 # ffffffffc0202de8 <default_pmm_manager+0x110>
ffffffffc02019ec:	9edfe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02019f0:	00001617          	auipc	a2,0x1
ffffffffc02019f4:	3b060613          	addi	a2,a2,944 # ffffffffc0202da0 <default_pmm_manager+0xc8>
ffffffffc02019f8:	07100593          	li	a1,113
ffffffffc02019fc:	00001517          	auipc	a0,0x1
ffffffffc0201a00:	34c50513          	addi	a0,a0,844 # ffffffffc0202d48 <default_pmm_manager+0x70>
ffffffffc0201a04:	9d5fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
        panic("DTB memory info not available");
ffffffffc0201a08:	00001617          	auipc	a2,0x1
ffffffffc0201a0c:	32060613          	addi	a2,a2,800 # ffffffffc0202d28 <default_pmm_manager+0x50>
ffffffffc0201a10:	05a00593          	li	a1,90
ffffffffc0201a14:	00001517          	auipc	a0,0x1
ffffffffc0201a18:	33450513          	addi	a0,a0,820 # ffffffffc0202d48 <default_pmm_manager+0x70>
ffffffffc0201a1c:	9bdfe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201a20:	86ae                	mv	a3,a1
ffffffffc0201a22:	00001617          	auipc	a2,0x1
ffffffffc0201a26:	37e60613          	addi	a2,a2,894 # ffffffffc0202da0 <default_pmm_manager+0xc8>
ffffffffc0201a2a:	08c00593          	li	a1,140
ffffffffc0201a2e:	00001517          	auipc	a0,0x1
ffffffffc0201a32:	31a50513          	addi	a0,a0,794 # ffffffffc0202d48 <default_pmm_manager+0x70>
ffffffffc0201a36:	9a3fe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc0201a3a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a3a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a3e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a40:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a44:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a46:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a4a:	f022                	sd	s0,32(sp)
ffffffffc0201a4c:	ec26                	sd	s1,24(sp)
ffffffffc0201a4e:	e84a                	sd	s2,16(sp)
ffffffffc0201a50:	f406                	sd	ra,40(sp)
ffffffffc0201a52:	e44e                	sd	s3,8(sp)
ffffffffc0201a54:	84aa                	mv	s1,a0
ffffffffc0201a56:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a58:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a5c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a5e:	03067e63          	bgeu	a2,a6,ffffffffc0201a9a <printnum+0x60>
ffffffffc0201a62:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a64:	00805763          	blez	s0,ffffffffc0201a72 <printnum+0x38>
ffffffffc0201a68:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a6a:	85ca                	mv	a1,s2
ffffffffc0201a6c:	854e                	mv	a0,s3
ffffffffc0201a6e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a70:	fc65                	bnez	s0,ffffffffc0201a68 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a72:	1a02                	slli	s4,s4,0x20
ffffffffc0201a74:	00001797          	auipc	a5,0x1
ffffffffc0201a78:	3e478793          	addi	a5,a5,996 # ffffffffc0202e58 <default_pmm_manager+0x180>
ffffffffc0201a7c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a80:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a82:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a84:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a88:	70a2                	ld	ra,40(sp)
ffffffffc0201a8a:	69a2                	ld	s3,8(sp)
ffffffffc0201a8c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a8e:	85ca                	mv	a1,s2
ffffffffc0201a90:	87a6                	mv	a5,s1
}
ffffffffc0201a92:	6942                	ld	s2,16(sp)
ffffffffc0201a94:	64e2                	ld	s1,24(sp)
ffffffffc0201a96:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a98:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a9a:	03065633          	divu	a2,a2,a6
ffffffffc0201a9e:	8722                	mv	a4,s0
ffffffffc0201aa0:	f9bff0ef          	jal	ra,ffffffffc0201a3a <printnum>
ffffffffc0201aa4:	b7f9                	j	ffffffffc0201a72 <printnum+0x38>

ffffffffc0201aa6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201aa6:	7119                	addi	sp,sp,-128
ffffffffc0201aa8:	f4a6                	sd	s1,104(sp)
ffffffffc0201aaa:	f0ca                	sd	s2,96(sp)
ffffffffc0201aac:	ecce                	sd	s3,88(sp)
ffffffffc0201aae:	e8d2                	sd	s4,80(sp)
ffffffffc0201ab0:	e4d6                	sd	s5,72(sp)
ffffffffc0201ab2:	e0da                	sd	s6,64(sp)
ffffffffc0201ab4:	fc5e                	sd	s7,56(sp)
ffffffffc0201ab6:	f06a                	sd	s10,32(sp)
ffffffffc0201ab8:	fc86                	sd	ra,120(sp)
ffffffffc0201aba:	f8a2                	sd	s0,112(sp)
ffffffffc0201abc:	f862                	sd	s8,48(sp)
ffffffffc0201abe:	f466                	sd	s9,40(sp)
ffffffffc0201ac0:	ec6e                	sd	s11,24(sp)
ffffffffc0201ac2:	892a                	mv	s2,a0
ffffffffc0201ac4:	84ae                	mv	s1,a1
ffffffffc0201ac6:	8d32                	mv	s10,a2
ffffffffc0201ac8:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201aca:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201ace:	5b7d                	li	s6,-1
ffffffffc0201ad0:	00001a97          	auipc	s5,0x1
ffffffffc0201ad4:	3bca8a93          	addi	s5,s5,956 # ffffffffc0202e8c <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ad8:	00001b97          	auipc	s7,0x1
ffffffffc0201adc:	590b8b93          	addi	s7,s7,1424 # ffffffffc0203068 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ae0:	000d4503          	lbu	a0,0(s10)
ffffffffc0201ae4:	001d0413          	addi	s0,s10,1
ffffffffc0201ae8:	01350a63          	beq	a0,s3,ffffffffc0201afc <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201aec:	c121                	beqz	a0,ffffffffc0201b2c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201aee:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201af0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201af2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201af4:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201af8:	ff351ae3          	bne	a0,s3,ffffffffc0201aec <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201afc:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201b00:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201b04:	4c81                	li	s9,0
ffffffffc0201b06:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201b08:	5c7d                	li	s8,-1
ffffffffc0201b0a:	5dfd                	li	s11,-1
ffffffffc0201b0c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201b10:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b12:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b16:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b1a:	00140d13          	addi	s10,s0,1
ffffffffc0201b1e:	04b56263          	bltu	a0,a1,ffffffffc0201b62 <vprintfmt+0xbc>
ffffffffc0201b22:	058a                	slli	a1,a1,0x2
ffffffffc0201b24:	95d6                	add	a1,a1,s5
ffffffffc0201b26:	4194                	lw	a3,0(a1)
ffffffffc0201b28:	96d6                	add	a3,a3,s5
ffffffffc0201b2a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b2c:	70e6                	ld	ra,120(sp)
ffffffffc0201b2e:	7446                	ld	s0,112(sp)
ffffffffc0201b30:	74a6                	ld	s1,104(sp)
ffffffffc0201b32:	7906                	ld	s2,96(sp)
ffffffffc0201b34:	69e6                	ld	s3,88(sp)
ffffffffc0201b36:	6a46                	ld	s4,80(sp)
ffffffffc0201b38:	6aa6                	ld	s5,72(sp)
ffffffffc0201b3a:	6b06                	ld	s6,64(sp)
ffffffffc0201b3c:	7be2                	ld	s7,56(sp)
ffffffffc0201b3e:	7c42                	ld	s8,48(sp)
ffffffffc0201b40:	7ca2                	ld	s9,40(sp)
ffffffffc0201b42:	7d02                	ld	s10,32(sp)
ffffffffc0201b44:	6de2                	ld	s11,24(sp)
ffffffffc0201b46:	6109                	addi	sp,sp,128
ffffffffc0201b48:	8082                	ret
            padc = '0';
ffffffffc0201b4a:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b4c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b50:	846a                	mv	s0,s10
ffffffffc0201b52:	00140d13          	addi	s10,s0,1
ffffffffc0201b56:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b5a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b5e:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b22 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b62:	85a6                	mv	a1,s1
ffffffffc0201b64:	02500513          	li	a0,37
ffffffffc0201b68:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b6a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b6e:	8d22                	mv	s10,s0
ffffffffc0201b70:	f73788e3          	beq	a5,s3,ffffffffc0201ae0 <vprintfmt+0x3a>
ffffffffc0201b74:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b78:	1d7d                	addi	s10,s10,-1
ffffffffc0201b7a:	ff379de3          	bne	a5,s3,ffffffffc0201b74 <vprintfmt+0xce>
ffffffffc0201b7e:	b78d                	j	ffffffffc0201ae0 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b80:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b84:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b88:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b8a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b8e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b92:	02d86463          	bltu	a6,a3,ffffffffc0201bba <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b96:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b9a:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b9e:	0186873b          	addw	a4,a3,s8
ffffffffc0201ba2:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201ba6:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201ba8:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201bac:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201bae:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201bb2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bb6:	fed870e3          	bgeu	a6,a3,ffffffffc0201b96 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201bba:	f40ddce3          	bgez	s11,ffffffffc0201b12 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201bbe:	8de2                	mv	s11,s8
ffffffffc0201bc0:	5c7d                	li	s8,-1
ffffffffc0201bc2:	bf81                	j	ffffffffc0201b12 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201bc4:	fffdc693          	not	a3,s11
ffffffffc0201bc8:	96fd                	srai	a3,a3,0x3f
ffffffffc0201bca:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bce:	00144603          	lbu	a2,1(s0)
ffffffffc0201bd2:	2d81                	sext.w	s11,s11
ffffffffc0201bd4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bd6:	bf35                	j	ffffffffc0201b12 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201bd8:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bdc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201be0:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201be2:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201be4:	bfd9                	j	ffffffffc0201bba <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201be6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201be8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bec:	01174463          	blt	a4,a7,ffffffffc0201bf4 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201bf0:	1a088e63          	beqz	a7,ffffffffc0201dac <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201bf4:	000a3603          	ld	a2,0(s4)
ffffffffc0201bf8:	46c1                	li	a3,16
ffffffffc0201bfa:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201bfc:	2781                	sext.w	a5,a5
ffffffffc0201bfe:	876e                	mv	a4,s11
ffffffffc0201c00:	85a6                	mv	a1,s1
ffffffffc0201c02:	854a                	mv	a0,s2
ffffffffc0201c04:	e37ff0ef          	jal	ra,ffffffffc0201a3a <printnum>
            break;
ffffffffc0201c08:	bde1                	j	ffffffffc0201ae0 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c0a:	000a2503          	lw	a0,0(s4)
ffffffffc0201c0e:	85a6                	mv	a1,s1
ffffffffc0201c10:	0a21                	addi	s4,s4,8
ffffffffc0201c12:	9902                	jalr	s2
            break;
ffffffffc0201c14:	b5f1                	j	ffffffffc0201ae0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c16:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c18:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c1c:	01174463          	blt	a4,a7,ffffffffc0201c24 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201c20:	18088163          	beqz	a7,ffffffffc0201da2 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201c24:	000a3603          	ld	a2,0(s4)
ffffffffc0201c28:	46a9                	li	a3,10
ffffffffc0201c2a:	8a2e                	mv	s4,a1
ffffffffc0201c2c:	bfc1                	j	ffffffffc0201bfc <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c2e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c32:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c34:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c36:	bdf1                	j	ffffffffc0201b12 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c38:	85a6                	mv	a1,s1
ffffffffc0201c3a:	02500513          	li	a0,37
ffffffffc0201c3e:	9902                	jalr	s2
            break;
ffffffffc0201c40:	b545                	j	ffffffffc0201ae0 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c42:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c46:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c48:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c4a:	b5e1                	j	ffffffffc0201b12 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c4c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c4e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c52:	01174463          	blt	a4,a7,ffffffffc0201c5a <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c56:	14088163          	beqz	a7,ffffffffc0201d98 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c5a:	000a3603          	ld	a2,0(s4)
ffffffffc0201c5e:	46a1                	li	a3,8
ffffffffc0201c60:	8a2e                	mv	s4,a1
ffffffffc0201c62:	bf69                	j	ffffffffc0201bfc <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c64:	03000513          	li	a0,48
ffffffffc0201c68:	85a6                	mv	a1,s1
ffffffffc0201c6a:	e03e                	sd	a5,0(sp)
ffffffffc0201c6c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c6e:	85a6                	mv	a1,s1
ffffffffc0201c70:	07800513          	li	a0,120
ffffffffc0201c74:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c76:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c78:	6782                	ld	a5,0(sp)
ffffffffc0201c7a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c7c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c80:	bfb5                	j	ffffffffc0201bfc <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c82:	000a3403          	ld	s0,0(s4)
ffffffffc0201c86:	008a0713          	addi	a4,s4,8
ffffffffc0201c8a:	e03a                	sd	a4,0(sp)
ffffffffc0201c8c:	14040263          	beqz	s0,ffffffffc0201dd0 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c90:	0fb05763          	blez	s11,ffffffffc0201d7e <vprintfmt+0x2d8>
ffffffffc0201c94:	02d00693          	li	a3,45
ffffffffc0201c98:	0cd79163          	bne	a5,a3,ffffffffc0201d5a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c9c:	00044783          	lbu	a5,0(s0)
ffffffffc0201ca0:	0007851b          	sext.w	a0,a5
ffffffffc0201ca4:	cf85                	beqz	a5,ffffffffc0201cdc <vprintfmt+0x236>
ffffffffc0201ca6:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201caa:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cae:	000c4563          	bltz	s8,ffffffffc0201cb8 <vprintfmt+0x212>
ffffffffc0201cb2:	3c7d                	addiw	s8,s8,-1
ffffffffc0201cb4:	036c0263          	beq	s8,s6,ffffffffc0201cd8 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201cb8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cba:	0e0c8e63          	beqz	s9,ffffffffc0201db6 <vprintfmt+0x310>
ffffffffc0201cbe:	3781                	addiw	a5,a5,-32
ffffffffc0201cc0:	0ef47b63          	bgeu	s0,a5,ffffffffc0201db6 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201cc4:	03f00513          	li	a0,63
ffffffffc0201cc8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cca:	000a4783          	lbu	a5,0(s4)
ffffffffc0201cce:	3dfd                	addiw	s11,s11,-1
ffffffffc0201cd0:	0a05                	addi	s4,s4,1
ffffffffc0201cd2:	0007851b          	sext.w	a0,a5
ffffffffc0201cd6:	ffe1                	bnez	a5,ffffffffc0201cae <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201cd8:	01b05963          	blez	s11,ffffffffc0201cea <vprintfmt+0x244>
ffffffffc0201cdc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201cde:	85a6                	mv	a1,s1
ffffffffc0201ce0:	02000513          	li	a0,32
ffffffffc0201ce4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201ce6:	fe0d9be3          	bnez	s11,ffffffffc0201cdc <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cea:	6a02                	ld	s4,0(sp)
ffffffffc0201cec:	bbd5                	j	ffffffffc0201ae0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201cee:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cf0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201cf4:	01174463          	blt	a4,a7,ffffffffc0201cfc <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201cf8:	08088d63          	beqz	a7,ffffffffc0201d92 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201cfc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201d00:	0a044d63          	bltz	s0,ffffffffc0201dba <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201d04:	8622                	mv	a2,s0
ffffffffc0201d06:	8a66                	mv	s4,s9
ffffffffc0201d08:	46a9                	li	a3,10
ffffffffc0201d0a:	bdcd                	j	ffffffffc0201bfc <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201d0c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d10:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201d12:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201d14:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d18:	8fb5                	xor	a5,a5,a3
ffffffffc0201d1a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d1e:	02d74163          	blt	a4,a3,ffffffffc0201d40 <vprintfmt+0x29a>
ffffffffc0201d22:	00369793          	slli	a5,a3,0x3
ffffffffc0201d26:	97de                	add	a5,a5,s7
ffffffffc0201d28:	639c                	ld	a5,0(a5)
ffffffffc0201d2a:	cb99                	beqz	a5,ffffffffc0201d40 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d2c:	86be                	mv	a3,a5
ffffffffc0201d2e:	00001617          	auipc	a2,0x1
ffffffffc0201d32:	15a60613          	addi	a2,a2,346 # ffffffffc0202e88 <default_pmm_manager+0x1b0>
ffffffffc0201d36:	85a6                	mv	a1,s1
ffffffffc0201d38:	854a                	mv	a0,s2
ffffffffc0201d3a:	0ce000ef          	jal	ra,ffffffffc0201e08 <printfmt>
ffffffffc0201d3e:	b34d                	j	ffffffffc0201ae0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d40:	00001617          	auipc	a2,0x1
ffffffffc0201d44:	13860613          	addi	a2,a2,312 # ffffffffc0202e78 <default_pmm_manager+0x1a0>
ffffffffc0201d48:	85a6                	mv	a1,s1
ffffffffc0201d4a:	854a                	mv	a0,s2
ffffffffc0201d4c:	0bc000ef          	jal	ra,ffffffffc0201e08 <printfmt>
ffffffffc0201d50:	bb41                	j	ffffffffc0201ae0 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d52:	00001417          	auipc	s0,0x1
ffffffffc0201d56:	11e40413          	addi	s0,s0,286 # ffffffffc0202e70 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d5a:	85e2                	mv	a1,s8
ffffffffc0201d5c:	8522                	mv	a0,s0
ffffffffc0201d5e:	e43e                	sd	a5,8(sp)
ffffffffc0201d60:	200000ef          	jal	ra,ffffffffc0201f60 <strnlen>
ffffffffc0201d64:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d68:	01b05b63          	blez	s11,ffffffffc0201d7e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d6c:	67a2                	ld	a5,8(sp)
ffffffffc0201d6e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d72:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d74:	85a6                	mv	a1,s1
ffffffffc0201d76:	8552                	mv	a0,s4
ffffffffc0201d78:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d7a:	fe0d9ce3          	bnez	s11,ffffffffc0201d72 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d7e:	00044783          	lbu	a5,0(s0)
ffffffffc0201d82:	00140a13          	addi	s4,s0,1
ffffffffc0201d86:	0007851b          	sext.w	a0,a5
ffffffffc0201d8a:	d3a5                	beqz	a5,ffffffffc0201cea <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d8c:	05e00413          	li	s0,94
ffffffffc0201d90:	bf39                	j	ffffffffc0201cae <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d92:	000a2403          	lw	s0,0(s4)
ffffffffc0201d96:	b7ad                	j	ffffffffc0201d00 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d98:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d9c:	46a1                	li	a3,8
ffffffffc0201d9e:	8a2e                	mv	s4,a1
ffffffffc0201da0:	bdb1                	j	ffffffffc0201bfc <vprintfmt+0x156>
ffffffffc0201da2:	000a6603          	lwu	a2,0(s4)
ffffffffc0201da6:	46a9                	li	a3,10
ffffffffc0201da8:	8a2e                	mv	s4,a1
ffffffffc0201daa:	bd89                	j	ffffffffc0201bfc <vprintfmt+0x156>
ffffffffc0201dac:	000a6603          	lwu	a2,0(s4)
ffffffffc0201db0:	46c1                	li	a3,16
ffffffffc0201db2:	8a2e                	mv	s4,a1
ffffffffc0201db4:	b5a1                	j	ffffffffc0201bfc <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201db6:	9902                	jalr	s2
ffffffffc0201db8:	bf09                	j	ffffffffc0201cca <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201dba:	85a6                	mv	a1,s1
ffffffffc0201dbc:	02d00513          	li	a0,45
ffffffffc0201dc0:	e03e                	sd	a5,0(sp)
ffffffffc0201dc2:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201dc4:	6782                	ld	a5,0(sp)
ffffffffc0201dc6:	8a66                	mv	s4,s9
ffffffffc0201dc8:	40800633          	neg	a2,s0
ffffffffc0201dcc:	46a9                	li	a3,10
ffffffffc0201dce:	b53d                	j	ffffffffc0201bfc <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201dd0:	03b05163          	blez	s11,ffffffffc0201df2 <vprintfmt+0x34c>
ffffffffc0201dd4:	02d00693          	li	a3,45
ffffffffc0201dd8:	f6d79de3          	bne	a5,a3,ffffffffc0201d52 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201ddc:	00001417          	auipc	s0,0x1
ffffffffc0201de0:	09440413          	addi	s0,s0,148 # ffffffffc0202e70 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201de4:	02800793          	li	a5,40
ffffffffc0201de8:	02800513          	li	a0,40
ffffffffc0201dec:	00140a13          	addi	s4,s0,1
ffffffffc0201df0:	bd6d                	j	ffffffffc0201caa <vprintfmt+0x204>
ffffffffc0201df2:	00001a17          	auipc	s4,0x1
ffffffffc0201df6:	07fa0a13          	addi	s4,s4,127 # ffffffffc0202e71 <default_pmm_manager+0x199>
ffffffffc0201dfa:	02800513          	li	a0,40
ffffffffc0201dfe:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e02:	05e00413          	li	s0,94
ffffffffc0201e06:	b565                	j	ffffffffc0201cae <vprintfmt+0x208>

ffffffffc0201e08 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e08:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e0a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e0e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e10:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e12:	ec06                	sd	ra,24(sp)
ffffffffc0201e14:	f83a                	sd	a4,48(sp)
ffffffffc0201e16:	fc3e                	sd	a5,56(sp)
ffffffffc0201e18:	e0c2                	sd	a6,64(sp)
ffffffffc0201e1a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e1c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e1e:	c89ff0ef          	jal	ra,ffffffffc0201aa6 <vprintfmt>
}
ffffffffc0201e22:	60e2                	ld	ra,24(sp)
ffffffffc0201e24:	6161                	addi	sp,sp,80
ffffffffc0201e26:	8082                	ret

ffffffffc0201e28 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e28:	715d                	addi	sp,sp,-80
ffffffffc0201e2a:	e486                	sd	ra,72(sp)
ffffffffc0201e2c:	e0a6                	sd	s1,64(sp)
ffffffffc0201e2e:	fc4a                	sd	s2,56(sp)
ffffffffc0201e30:	f84e                	sd	s3,48(sp)
ffffffffc0201e32:	f452                	sd	s4,40(sp)
ffffffffc0201e34:	f056                	sd	s5,32(sp)
ffffffffc0201e36:	ec5a                	sd	s6,24(sp)
ffffffffc0201e38:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e3a:	c901                	beqz	a0,ffffffffc0201e4a <readline+0x22>
ffffffffc0201e3c:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e3e:	00001517          	auipc	a0,0x1
ffffffffc0201e42:	04a50513          	addi	a0,a0,74 # ffffffffc0202e88 <default_pmm_manager+0x1b0>
ffffffffc0201e46:	a98fe0ef          	jal	ra,ffffffffc02000de <cprintf>
readline(const char *prompt) {
ffffffffc0201e4a:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e4c:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e4e:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e50:	4aa9                	li	s5,10
ffffffffc0201e52:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e54:	00005b97          	auipc	s7,0x5
ffffffffc0201e58:	1ecb8b93          	addi	s7,s7,492 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e5c:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e60:	af6fe0ef          	jal	ra,ffffffffc0200156 <getchar>
        if (c < 0) {
ffffffffc0201e64:	00054a63          	bltz	a0,ffffffffc0201e78 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e68:	00a95a63          	bge	s2,a0,ffffffffc0201e7c <readline+0x54>
ffffffffc0201e6c:	029a5263          	bge	s4,s1,ffffffffc0201e90 <readline+0x68>
        c = getchar();
ffffffffc0201e70:	ae6fe0ef          	jal	ra,ffffffffc0200156 <getchar>
        if (c < 0) {
ffffffffc0201e74:	fe055ae3          	bgez	a0,ffffffffc0201e68 <readline+0x40>
            return NULL;
ffffffffc0201e78:	4501                	li	a0,0
ffffffffc0201e7a:	a091                	j	ffffffffc0201ebe <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e7c:	03351463          	bne	a0,s3,ffffffffc0201ea4 <readline+0x7c>
ffffffffc0201e80:	e8a9                	bnez	s1,ffffffffc0201ed2 <readline+0xaa>
        c = getchar();
ffffffffc0201e82:	ad4fe0ef          	jal	ra,ffffffffc0200156 <getchar>
        if (c < 0) {
ffffffffc0201e86:	fe0549e3          	bltz	a0,ffffffffc0201e78 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e8a:	fea959e3          	bge	s2,a0,ffffffffc0201e7c <readline+0x54>
ffffffffc0201e8e:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e90:	e42a                	sd	a0,8(sp)
ffffffffc0201e92:	a82fe0ef          	jal	ra,ffffffffc0200114 <cputchar>
            buf[i ++] = c;
ffffffffc0201e96:	6522                	ld	a0,8(sp)
ffffffffc0201e98:	009b87b3          	add	a5,s7,s1
ffffffffc0201e9c:	2485                	addiw	s1,s1,1
ffffffffc0201e9e:	00a78023          	sb	a0,0(a5)
ffffffffc0201ea2:	bf7d                	j	ffffffffc0201e60 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201ea4:	01550463          	beq	a0,s5,ffffffffc0201eac <readline+0x84>
ffffffffc0201ea8:	fb651ce3          	bne	a0,s6,ffffffffc0201e60 <readline+0x38>
            cputchar(c);
ffffffffc0201eac:	a68fe0ef          	jal	ra,ffffffffc0200114 <cputchar>
            buf[i] = '\0';
ffffffffc0201eb0:	00005517          	auipc	a0,0x5
ffffffffc0201eb4:	19050513          	addi	a0,a0,400 # ffffffffc0207040 <buf>
ffffffffc0201eb8:	94aa                	add	s1,s1,a0
ffffffffc0201eba:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ebe:	60a6                	ld	ra,72(sp)
ffffffffc0201ec0:	6486                	ld	s1,64(sp)
ffffffffc0201ec2:	7962                	ld	s2,56(sp)
ffffffffc0201ec4:	79c2                	ld	s3,48(sp)
ffffffffc0201ec6:	7a22                	ld	s4,40(sp)
ffffffffc0201ec8:	7a82                	ld	s5,32(sp)
ffffffffc0201eca:	6b62                	ld	s6,24(sp)
ffffffffc0201ecc:	6bc2                	ld	s7,16(sp)
ffffffffc0201ece:	6161                	addi	sp,sp,80
ffffffffc0201ed0:	8082                	ret
            cputchar(c);
ffffffffc0201ed2:	4521                	li	a0,8
ffffffffc0201ed4:	a40fe0ef          	jal	ra,ffffffffc0200114 <cputchar>
            i --;
ffffffffc0201ed8:	34fd                	addiw	s1,s1,-1
ffffffffc0201eda:	b759                	j	ffffffffc0201e60 <readline+0x38>

ffffffffc0201edc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201edc:	4781                	li	a5,0
ffffffffc0201ede:	00005717          	auipc	a4,0x5
ffffffffc0201ee2:	13a73703          	ld	a4,314(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201ee6:	88ba                	mv	a7,a4
ffffffffc0201ee8:	852a                	mv	a0,a0
ffffffffc0201eea:	85be                	mv	a1,a5
ffffffffc0201eec:	863e                	mv	a2,a5
ffffffffc0201eee:	00000073          	ecall
ffffffffc0201ef2:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201ef4:	8082                	ret

ffffffffc0201ef6 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201ef6:	4781                	li	a5,0
ffffffffc0201ef8:	00005717          	auipc	a4,0x5
ffffffffc0201efc:	5a073703          	ld	a4,1440(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201f00:	88ba                	mv	a7,a4
ffffffffc0201f02:	852a                	mv	a0,a0
ffffffffc0201f04:	85be                	mv	a1,a5
ffffffffc0201f06:	863e                	mv	a2,a5
ffffffffc0201f08:	00000073          	ecall
ffffffffc0201f0c:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201f0e:	8082                	ret

ffffffffc0201f10 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201f10:	4501                	li	a0,0
ffffffffc0201f12:	00005797          	auipc	a5,0x5
ffffffffc0201f16:	0fe7b783          	ld	a5,254(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f1a:	88be                	mv	a7,a5
ffffffffc0201f1c:	852a                	mv	a0,a0
ffffffffc0201f1e:	85aa                	mv	a1,a0
ffffffffc0201f20:	862a                	mv	a2,a0
ffffffffc0201f22:	00000073          	ecall
ffffffffc0201f26:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201f28:	2501                	sext.w	a0,a0
ffffffffc0201f2a:	8082                	ret

ffffffffc0201f2c <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201f2c:	4781                	li	a5,0
ffffffffc0201f2e:	00005717          	auipc	a4,0x5
ffffffffc0201f32:	0f273703          	ld	a4,242(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201f36:	88ba                	mv	a7,a4
ffffffffc0201f38:	853e                	mv	a0,a5
ffffffffc0201f3a:	85be                	mv	a1,a5
ffffffffc0201f3c:	863e                	mv	a2,a5
ffffffffc0201f3e:	00000073          	ecall
ffffffffc0201f42:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201f44:	8082                	ret

ffffffffc0201f46 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f46:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f4a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f4c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f4e:	cb81                	beqz	a5,ffffffffc0201f5e <strlen+0x18>
        cnt ++;
ffffffffc0201f50:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f52:	00a707b3          	add	a5,a4,a0
ffffffffc0201f56:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f5a:	fbfd                	bnez	a5,ffffffffc0201f50 <strlen+0xa>
ffffffffc0201f5c:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f5e:	8082                	ret

ffffffffc0201f60 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f60:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f62:	e589                	bnez	a1,ffffffffc0201f6c <strnlen+0xc>
ffffffffc0201f64:	a811                	j	ffffffffc0201f78 <strnlen+0x18>
        cnt ++;
ffffffffc0201f66:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f68:	00f58863          	beq	a1,a5,ffffffffc0201f78 <strnlen+0x18>
ffffffffc0201f6c:	00f50733          	add	a4,a0,a5
ffffffffc0201f70:	00074703          	lbu	a4,0(a4)
ffffffffc0201f74:	fb6d                	bnez	a4,ffffffffc0201f66 <strnlen+0x6>
ffffffffc0201f76:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f78:	852e                	mv	a0,a1
ffffffffc0201f7a:	8082                	ret

ffffffffc0201f7c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f7c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f80:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f84:	cb89                	beqz	a5,ffffffffc0201f96 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201f86:	0505                	addi	a0,a0,1
ffffffffc0201f88:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f8a:	fee789e3          	beq	a5,a4,ffffffffc0201f7c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f8e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f92:	9d19                	subw	a0,a0,a4
ffffffffc0201f94:	8082                	ret
ffffffffc0201f96:	4501                	li	a0,0
ffffffffc0201f98:	bfed                	j	ffffffffc0201f92 <strcmp+0x16>

ffffffffc0201f9a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f9a:	c20d                	beqz	a2,ffffffffc0201fbc <strncmp+0x22>
ffffffffc0201f9c:	962e                	add	a2,a2,a1
ffffffffc0201f9e:	a031                	j	ffffffffc0201faa <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201fa0:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fa2:	00e79a63          	bne	a5,a4,ffffffffc0201fb6 <strncmp+0x1c>
ffffffffc0201fa6:	00b60b63          	beq	a2,a1,ffffffffc0201fbc <strncmp+0x22>
ffffffffc0201faa:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201fae:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fb0:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201fb4:	f7f5                	bnez	a5,ffffffffc0201fa0 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fb6:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201fba:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fbc:	4501                	li	a0,0
ffffffffc0201fbe:	8082                	ret

ffffffffc0201fc0 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201fc0:	00054783          	lbu	a5,0(a0)
ffffffffc0201fc4:	c799                	beqz	a5,ffffffffc0201fd2 <strchr+0x12>
        if (*s == c) {
ffffffffc0201fc6:	00f58763          	beq	a1,a5,ffffffffc0201fd4 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201fca:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201fce:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201fd0:	fbfd                	bnez	a5,ffffffffc0201fc6 <strchr+0x6>
    }
    return NULL;
ffffffffc0201fd2:	4501                	li	a0,0
}
ffffffffc0201fd4:	8082                	ret

ffffffffc0201fd6 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201fd6:	ca01                	beqz	a2,ffffffffc0201fe6 <memset+0x10>
ffffffffc0201fd8:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201fda:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fdc:	0785                	addi	a5,a5,1
ffffffffc0201fde:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fe2:	fec79de3          	bne	a5,a2,ffffffffc0201fdc <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201fe6:	8082                	ret
