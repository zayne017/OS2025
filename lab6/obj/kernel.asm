
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000cd517          	auipc	a0,0xcd
ffffffffc020004e:	06e50513          	addi	a0,a0,110 # ffffffffc02cd0b8 <buf>
ffffffffc0200052:	000d1617          	auipc	a2,0xd1
ffffffffc0200056:	54660613          	addi	a2,a2,1350 # ffffffffc02d1598 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	407050ef          	jal	ra,ffffffffc0205c68 <memset>
    cons_init(); // init the console
ffffffffc0200066:	520000ef          	jal	ra,ffffffffc0200586 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	c2e58593          	addi	a1,a1,-978 # ffffffffc0205c98 <etext+0x6>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	c4650513          	addi	a0,a0,-954 # ffffffffc0205cb8 <etext+0x26>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	576000ef          	jal	ra,ffffffffc02005f8 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	5a4020ef          	jal	ra,ffffffffc020262a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	12b000ef          	jal	ra,ffffffffc02009b4 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	129000ef          	jal	ra,ffffffffc02009b6 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	071030ef          	jal	ra,ffffffffc0203902 <vmm_init>
    sched_init();
ffffffffc0200096:	468050ef          	jal	ra,ffffffffc02054fe <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	4b7040ef          	jal	ra,ffffffffc0204d50 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	107000ef          	jal	ra,ffffffffc02009a8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	643040ef          	jal	ra,ffffffffc0204ee8 <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	715d                	addi	sp,sp,-80
ffffffffc02000ac:	e486                	sd	ra,72(sp)
ffffffffc02000ae:	e0a6                	sd	s1,64(sp)
ffffffffc02000b0:	fc4a                	sd	s2,56(sp)
ffffffffc02000b2:	f84e                	sd	s3,48(sp)
ffffffffc02000b4:	f452                	sd	s4,40(sp)
ffffffffc02000b6:	f056                	sd	s5,32(sp)
ffffffffc02000b8:	ec5a                	sd	s6,24(sp)
ffffffffc02000ba:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000bc:	c901                	beqz	a0,ffffffffc02000cc <readline+0x22>
ffffffffc02000be:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000c0:	00006517          	auipc	a0,0x6
ffffffffc02000c4:	c0050513          	addi	a0,a0,-1024 # ffffffffc0205cc0 <etext+0x2e>
ffffffffc02000c8:	0d0000ef          	jal	ra,ffffffffc0200198 <cprintf>
readline(const char *prompt) {
ffffffffc02000cc:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ce:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000d2:	4aa9                	li	s5,10
ffffffffc02000d4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d6:	000cdb97          	auipc	s7,0xcd
ffffffffc02000da:	fe2b8b93          	addi	s7,s7,-30 # ffffffffc02cd0b8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000de:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000e2:	12e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000e6:	00054a63          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ea:	00a95a63          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc02000ee:	029a5263          	bge	s4,s1,ffffffffc0200112 <readline+0x68>
        c = getchar();
ffffffffc02000f2:	11e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000f6:	fe055ae3          	bgez	a0,ffffffffc02000ea <readline+0x40>
            return NULL;
ffffffffc02000fa:	4501                	li	a0,0
ffffffffc02000fc:	a091                	j	ffffffffc0200140 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fe:	03351463          	bne	a0,s3,ffffffffc0200126 <readline+0x7c>
ffffffffc0200102:	e8a9                	bnez	s1,ffffffffc0200154 <readline+0xaa>
        c = getchar();
ffffffffc0200104:	10c000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc0200108:	fe0549e3          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010c:	fea959e3          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc0200110:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200112:	e42a                	sd	a0,8(sp)
ffffffffc0200114:	0ba000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i ++] = c;
ffffffffc0200118:	6522                	ld	a0,8(sp)
ffffffffc020011a:	009b87b3          	add	a5,s7,s1
ffffffffc020011e:	2485                	addiw	s1,s1,1
ffffffffc0200120:	00a78023          	sb	a0,0(a5)
ffffffffc0200124:	bf7d                	j	ffffffffc02000e2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200126:	01550463          	beq	a0,s5,ffffffffc020012e <readline+0x84>
ffffffffc020012a:	fb651ce3          	bne	a0,s6,ffffffffc02000e2 <readline+0x38>
            cputchar(c);
ffffffffc020012e:	0a0000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i] = '\0';
ffffffffc0200132:	000cd517          	auipc	a0,0xcd
ffffffffc0200136:	f8650513          	addi	a0,a0,-122 # ffffffffc02cd0b8 <buf>
ffffffffc020013a:	94aa                	add	s1,s1,a0
ffffffffc020013c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200140:	60a6                	ld	ra,72(sp)
ffffffffc0200142:	6486                	ld	s1,64(sp)
ffffffffc0200144:	7962                	ld	s2,56(sp)
ffffffffc0200146:	79c2                	ld	s3,48(sp)
ffffffffc0200148:	7a22                	ld	s4,40(sp)
ffffffffc020014a:	7a82                	ld	s5,32(sp)
ffffffffc020014c:	6b62                	ld	s6,24(sp)
ffffffffc020014e:	6bc2                	ld	s7,16(sp)
ffffffffc0200150:	6161                	addi	sp,sp,80
ffffffffc0200152:	8082                	ret
            cputchar(c);
ffffffffc0200154:	4521                	li	a0,8
ffffffffc0200156:	078000ef          	jal	ra,ffffffffc02001ce <cputchar>
            i --;
ffffffffc020015a:	34fd                	addiw	s1,s1,-1
ffffffffc020015c:	b759                	j	ffffffffc02000e2 <readline+0x38>

ffffffffc020015e <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e022                	sd	s0,0(sp)
ffffffffc0200162:	e406                	sd	ra,8(sp)
ffffffffc0200164:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200166:	422000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	401c                	lw	a5,0(s0)
}
ffffffffc020016c:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016e:	2785                	addiw	a5,a5,1
ffffffffc0200170:	c01c                	sw	a5,0(s0)
}
ffffffffc0200172:	6402                	ld	s0,0(sp)
ffffffffc0200174:	0141                	addi	sp,sp,16
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe050513          	addi	a0,a0,-32 # ffffffffc020015e <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	6b8050ef          	jal	ra,ffffffffc0205844 <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
{
ffffffffc020019e:	8e2a                	mv	t3,a0
ffffffffc02001a0:	f42e                	sd	a1,40(sp)
ffffffffc02001a2:	f832                	sd	a2,48(sp)
ffffffffc02001a4:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a6:	00000517          	auipc	a0,0x0
ffffffffc02001aa:	fb850513          	addi	a0,a0,-72 # ffffffffc020015e <cputch>
ffffffffc02001ae:	004c                	addi	a1,sp,4
ffffffffc02001b0:	869a                	mv	a3,t1
ffffffffc02001b2:	8672                	mv	a2,t3
{
ffffffffc02001b4:	ec06                	sd	ra,24(sp)
ffffffffc02001b6:	e0ba                	sd	a4,64(sp)
ffffffffc02001b8:	e4be                	sd	a5,72(sp)
ffffffffc02001ba:	e8c2                	sd	a6,80(sp)
ffffffffc02001bc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001c0:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c2:	682050ef          	jal	ra,ffffffffc0205844 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	4512                	lw	a0,4(sp)
ffffffffc02001ca:	6125                	addi	sp,sp,96
ffffffffc02001cc:	8082                	ret

ffffffffc02001ce <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ce:	ae6d                	j	ffffffffc0200588 <cons_putc>

ffffffffc02001d0 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001d0:	1101                	addi	sp,sp,-32
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	ec06                	sd	ra,24(sp)
ffffffffc02001d6:	e426                	sd	s1,8(sp)
ffffffffc02001d8:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001da:	00054503          	lbu	a0,0(a0)
ffffffffc02001de:	c51d                	beqz	a0,ffffffffc020020c <cputs+0x3c>
ffffffffc02001e0:	0405                	addi	s0,s0,1
ffffffffc02001e2:	4485                	li	s1,1
ffffffffc02001e4:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e6:	3a2000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001ea:	00044503          	lbu	a0,0(s0)
ffffffffc02001ee:	008487bb          	addw	a5,s1,s0
ffffffffc02001f2:	0405                	addi	s0,s0,1
ffffffffc02001f4:	f96d                	bnez	a0,ffffffffc02001e6 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f6:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001fa:	4529                	li	a0,10
ffffffffc02001fc:	38c000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200200:	60e2                	ld	ra,24(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	6442                	ld	s0,16(sp)
ffffffffc0200206:	64a2                	ld	s1,8(sp)
ffffffffc0200208:	6105                	addi	sp,sp,32
ffffffffc020020a:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc020020c:	4405                	li	s0,1
ffffffffc020020e:	b7f5                	j	ffffffffc02001fa <cputs+0x2a>

ffffffffc0200210 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200210:	1141                	addi	sp,sp,-16
ffffffffc0200212:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200214:	3a8000ef          	jal	ra,ffffffffc02005bc <cons_getc>
ffffffffc0200218:	dd75                	beqz	a0,ffffffffc0200214 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	0141                	addi	sp,sp,16
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200220:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	00006517          	auipc	a0,0x6
ffffffffc0200226:	aa650513          	addi	a0,a0,-1370 # ffffffffc0205cc8 <etext+0x36>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00006517          	auipc	a0,0x6
ffffffffc020023c:	ab050513          	addi	a0,a0,-1360 # ffffffffc0205ce8 <etext+0x56>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00006597          	auipc	a1,0x6
ffffffffc0200248:	a4e58593          	addi	a1,a1,-1458 # ffffffffc0205c92 <etext>
ffffffffc020024c:	00006517          	auipc	a0,0x6
ffffffffc0200250:	abc50513          	addi	a0,a0,-1348 # ffffffffc0205d08 <etext+0x76>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000cd597          	auipc	a1,0xcd
ffffffffc020025c:	e6058593          	addi	a1,a1,-416 # ffffffffc02cd0b8 <buf>
ffffffffc0200260:	00006517          	auipc	a0,0x6
ffffffffc0200264:	ac850513          	addi	a0,a0,-1336 # ffffffffc0205d28 <etext+0x96>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000d1597          	auipc	a1,0xd1
ffffffffc0200270:	32c58593          	addi	a1,a1,812 # ffffffffc02d1598 <end>
ffffffffc0200274:	00006517          	auipc	a0,0x6
ffffffffc0200278:	ad450513          	addi	a0,a0,-1324 # ffffffffc0205d48 <etext+0xb6>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000d1597          	auipc	a1,0xd1
ffffffffc0200284:	71758593          	addi	a1,a1,1815 # ffffffffc02d1997 <end+0x3ff>
ffffffffc0200288:	00000797          	auipc	a5,0x0
ffffffffc020028c:	dc278793          	addi	a5,a5,-574 # ffffffffc020004a <kern_init>
ffffffffc0200290:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029a:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029e:	95be                	add	a1,a1,a5
ffffffffc02002a0:	85a9                	srai	a1,a1,0xa
ffffffffc02002a2:	00006517          	auipc	a0,0x6
ffffffffc02002a6:	ac650513          	addi	a0,a0,-1338 # ffffffffc0205d68 <etext+0xd6>
}
ffffffffc02002aa:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ac:	b5f5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002ae <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002ae:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b0:	00006617          	auipc	a2,0x6
ffffffffc02002b4:	ae860613          	addi	a2,a2,-1304 # ffffffffc0205d98 <etext+0x106>
ffffffffc02002b8:	04d00593          	li	a1,77
ffffffffc02002bc:	00006517          	auipc	a0,0x6
ffffffffc02002c0:	af450513          	addi	a0,a0,-1292 # ffffffffc0205db0 <etext+0x11e>
void print_stackframe(void) {
ffffffffc02002c4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c6:	1cc000ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02002ca <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ca:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002cc:	00006617          	auipc	a2,0x6
ffffffffc02002d0:	afc60613          	addi	a2,a2,-1284 # ffffffffc0205dc8 <etext+0x136>
ffffffffc02002d4:	00006597          	auipc	a1,0x6
ffffffffc02002d8:	b1458593          	addi	a1,a1,-1260 # ffffffffc0205de8 <etext+0x156>
ffffffffc02002dc:	00006517          	auipc	a0,0x6
ffffffffc02002e0:	b1450513          	addi	a0,a0,-1260 # ffffffffc0205df0 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00006617          	auipc	a2,0x6
ffffffffc02002ee:	b1660613          	addi	a2,a2,-1258 # ffffffffc0205e00 <etext+0x16e>
ffffffffc02002f2:	00006597          	auipc	a1,0x6
ffffffffc02002f6:	b3658593          	addi	a1,a1,-1226 # ffffffffc0205e28 <etext+0x196>
ffffffffc02002fa:	00006517          	auipc	a0,0x6
ffffffffc02002fe:	af650513          	addi	a0,a0,-1290 # ffffffffc0205df0 <etext+0x15e>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00006617          	auipc	a2,0x6
ffffffffc020030a:	b3260613          	addi	a2,a2,-1230 # ffffffffc0205e38 <etext+0x1a6>
ffffffffc020030e:	00006597          	auipc	a1,0x6
ffffffffc0200312:	b4a58593          	addi	a1,a1,-1206 # ffffffffc0205e58 <etext+0x1c6>
ffffffffc0200316:	00006517          	auipc	a0,0x6
ffffffffc020031a:	ada50513          	addi	a0,a0,-1318 # ffffffffc0205df0 <etext+0x15e>
ffffffffc020031e:	e7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    return 0;
}
ffffffffc0200322:	60a2                	ld	ra,8(sp)
ffffffffc0200324:	4501                	li	a0,0
ffffffffc0200326:	0141                	addi	sp,sp,16
ffffffffc0200328:	8082                	ret

ffffffffc020032a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032a:	1141                	addi	sp,sp,-16
ffffffffc020032c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032e:	ef3ff0ef          	jal	ra,ffffffffc0200220 <print_kerninfo>
    return 0;
}
ffffffffc0200332:	60a2                	ld	ra,8(sp)
ffffffffc0200334:	4501                	li	a0,0
ffffffffc0200336:	0141                	addi	sp,sp,16
ffffffffc0200338:	8082                	ret

ffffffffc020033a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033a:	1141                	addi	sp,sp,-16
ffffffffc020033c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033e:	f71ff0ef          	jal	ra,ffffffffc02002ae <print_stackframe>
    return 0;
}
ffffffffc0200342:	60a2                	ld	ra,8(sp)
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	0141                	addi	sp,sp,16
ffffffffc0200348:	8082                	ret

ffffffffc020034a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034a:	7115                	addi	sp,sp,-224
ffffffffc020034c:	ed5e                	sd	s7,152(sp)
ffffffffc020034e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200350:	00006517          	auipc	a0,0x6
ffffffffc0200354:	b1850513          	addi	a0,a0,-1256 # ffffffffc0205e68 <etext+0x1d6>
kmonitor(struct trapframe *tf) {
ffffffffc0200358:	ed86                	sd	ra,216(sp)
ffffffffc020035a:	e9a2                	sd	s0,208(sp)
ffffffffc020035c:	e5a6                	sd	s1,200(sp)
ffffffffc020035e:	e1ca                	sd	s2,192(sp)
ffffffffc0200360:	fd4e                	sd	s3,184(sp)
ffffffffc0200362:	f952                	sd	s4,176(sp)
ffffffffc0200364:	f556                	sd	s5,168(sp)
ffffffffc0200366:	f15a                	sd	s6,160(sp)
ffffffffc0200368:	e962                	sd	s8,144(sp)
ffffffffc020036a:	e566                	sd	s9,136(sp)
ffffffffc020036c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036e:	e2bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200372:	00006517          	auipc	a0,0x6
ffffffffc0200376:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0205e90 <etext+0x1fe>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	01b000ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
ffffffffc0200388:	00006c17          	auipc	s8,0x6
ffffffffc020038c:	b78c0c13          	addi	s8,s8,-1160 # ffffffffc0205f00 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	b2890913          	addi	s2,s2,-1240 # ffffffffc0205eb8 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00006497          	auipc	s1,0x6
ffffffffc020039c:	b2848493          	addi	s1,s1,-1240 # ffffffffc0205ec0 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00006b17          	auipc	s6,0x6
ffffffffc02003a6:	b26b0b13          	addi	s6,s6,-1242 # ffffffffc0205ec8 <etext+0x236>
        argv[argc ++] = buf;
ffffffffc02003aa:	00006a17          	auipc	s4,0x6
ffffffffc02003ae:	a3ea0a13          	addi	s4,s4,-1474 # ffffffffc0205de8 <etext+0x156>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b4:	854a                	mv	a0,s2
ffffffffc02003b6:	cf5ff0ef          	jal	ra,ffffffffc02000aa <readline>
ffffffffc02003ba:	842a                	mv	s0,a0
ffffffffc02003bc:	dd65                	beqz	a0,ffffffffc02003b4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003c2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c4:	e1bd                	bnez	a1,ffffffffc020042a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003c6:	fe0c87e3          	beqz	s9,ffffffffc02003b4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ca:	6582                	ld	a1,0(sp)
ffffffffc02003cc:	00006d17          	auipc	s10,0x6
ffffffffc02003d0:	b34d0d13          	addi	s10,s10,-1228 # ffffffffc0205f00 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	035050ef          	jal	ra,ffffffffc0205c0e <strcmp>
ffffffffc02003de:	c919                	beqz	a0,ffffffffc02003f4 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	2405                	addiw	s0,s0,1
ffffffffc02003e2:	0b540063          	beq	s0,s5,ffffffffc0200482 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e6:	000d3503          	ld	a0,0(s10)
ffffffffc02003ea:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ec:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ee:	021050ef          	jal	ra,ffffffffc0205c0e <strcmp>
ffffffffc02003f2:	f57d                	bnez	a0,ffffffffc02003e0 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f4:	00141793          	slli	a5,s0,0x1
ffffffffc02003f8:	97a2                	add	a5,a5,s0
ffffffffc02003fa:	078e                	slli	a5,a5,0x3
ffffffffc02003fc:	97e2                	add	a5,a5,s8
ffffffffc02003fe:	6b9c                	ld	a5,16(a5)
ffffffffc0200400:	865e                	mv	a2,s7
ffffffffc0200402:	002c                	addi	a1,sp,8
ffffffffc0200404:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200408:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020040a:	fa0555e3          	bgez	a0,ffffffffc02003b4 <kmonitor+0x6a>
}
ffffffffc020040e:	60ee                	ld	ra,216(sp)
ffffffffc0200410:	644e                	ld	s0,208(sp)
ffffffffc0200412:	64ae                	ld	s1,200(sp)
ffffffffc0200414:	690e                	ld	s2,192(sp)
ffffffffc0200416:	79ea                	ld	s3,184(sp)
ffffffffc0200418:	7a4a                	ld	s4,176(sp)
ffffffffc020041a:	7aaa                	ld	s5,168(sp)
ffffffffc020041c:	7b0a                	ld	s6,160(sp)
ffffffffc020041e:	6bea                	ld	s7,152(sp)
ffffffffc0200420:	6c4a                	ld	s8,144(sp)
ffffffffc0200422:	6caa                	ld	s9,136(sp)
ffffffffc0200424:	6d0a                	ld	s10,128(sp)
ffffffffc0200426:	612d                	addi	sp,sp,224
ffffffffc0200428:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042a:	8526                	mv	a0,s1
ffffffffc020042c:	027050ef          	jal	ra,ffffffffc0205c52 <strchr>
ffffffffc0200430:	c901                	beqz	a0,ffffffffc0200440 <kmonitor+0xf6>
ffffffffc0200432:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200436:	00040023          	sb	zero,0(s0)
ffffffffc020043a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043c:	d5c9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc020043e:	b7f5                	j	ffffffffc020042a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200440:	00044783          	lbu	a5,0(s0)
ffffffffc0200444:	d3c9                	beqz	a5,ffffffffc02003c6 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	033c8963          	beq	s9,s3,ffffffffc0200478 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020044a:	003c9793          	slli	a5,s9,0x3
ffffffffc020044e:	0118                	addi	a4,sp,128
ffffffffc0200450:	97ba                	add	a5,a5,a4
ffffffffc0200452:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020045a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020045c:	e591                	bnez	a1,ffffffffc0200468 <kmonitor+0x11e>
ffffffffc020045e:	b7b5                	j	ffffffffc02003ca <kmonitor+0x80>
ffffffffc0200460:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200464:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	d1a5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200468:	8526                	mv	a0,s1
ffffffffc020046a:	7e8050ef          	jal	ra,ffffffffc0205c52 <strchr>
ffffffffc020046e:	d96d                	beqz	a0,ffffffffc0200460 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200470:	00044583          	lbu	a1,0(s0)
ffffffffc0200474:	d9a9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200476:	bf55                	j	ffffffffc020042a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200478:	45c1                	li	a1,16
ffffffffc020047a:	855a                	mv	a0,s6
ffffffffc020047c:	d1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200480:	b7e9                	j	ffffffffc020044a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00006517          	auipc	a0,0x6
ffffffffc0200488:	a6450513          	addi	a0,a0,-1436 # ffffffffc0205ee8 <etext+0x256>
ffffffffc020048c:	d0dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
ffffffffc0200490:	b715                	j	ffffffffc02003b4 <kmonitor+0x6a>

ffffffffc0200492 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200492:	000d1317          	auipc	t1,0xd1
ffffffffc0200496:	07e30313          	addi	t1,t1,126 # ffffffffc02d1510 <is_panic>
ffffffffc020049a:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020049e:	715d                	addi	sp,sp,-80
ffffffffc02004a0:	ec06                	sd	ra,24(sp)
ffffffffc02004a2:	e822                	sd	s0,16(sp)
ffffffffc02004a4:	f436                	sd	a3,40(sp)
ffffffffc02004a6:	f83a                	sd	a4,48(sp)
ffffffffc02004a8:	fc3e                	sd	a5,56(sp)
ffffffffc02004aa:	e0c2                	sd	a6,64(sp)
ffffffffc02004ac:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004ae:	020e1a63          	bnez	t3,ffffffffc02004e2 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004b2:	4785                	li	a5,1
ffffffffc02004b4:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	8432                	mv	s0,a2
ffffffffc02004ba:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004bc:	862e                	mv	a2,a1
ffffffffc02004be:	85aa                	mv	a1,a0
ffffffffc02004c0:	00006517          	auipc	a0,0x6
ffffffffc02004c4:	a8850513          	addi	a0,a0,-1400 # ffffffffc0205f48 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c8:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ca:	ccfff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ce:	65a2                	ld	a1,8(sp)
ffffffffc02004d0:	8522                	mv	a0,s0
ffffffffc02004d2:	ca7ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004d6:	00007517          	auipc	a0,0x7
ffffffffc02004da:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0207040 <default_pmm_manager+0x578>
ffffffffc02004de:	cbbff0ef          	jal	ra,ffffffffc0200198 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004e2:	4501                	li	a0,0
ffffffffc02004e4:	4581                	li	a1,0
ffffffffc02004e6:	4601                	li	a2,0
ffffffffc02004e8:	48a1                	li	a7,8
ffffffffc02004ea:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ee:	4c0000ef          	jal	ra,ffffffffc02009ae <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	e57ff0ef          	jal	ra,ffffffffc020034a <kmonitor>
    while (1) {
ffffffffc02004f8:	bfed                	j	ffffffffc02004f2 <__panic+0x60>

ffffffffc02004fa <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	715d                	addi	sp,sp,-80
ffffffffc02004fc:	832e                	mv	t1,a1
ffffffffc02004fe:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200500:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200502:	8432                	mv	s0,a2
ffffffffc0200504:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200508:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020050a:	00006517          	auipc	a0,0x6
ffffffffc020050e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0205f68 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200512:	ec06                	sd	ra,24(sp)
ffffffffc0200514:	f436                	sd	a3,40(sp)
ffffffffc0200516:	f83a                	sd	a4,48(sp)
ffffffffc0200518:	e0c2                	sd	a6,64(sp)
ffffffffc020051a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020051c:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051e:	c7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200522:	65a2                	ld	a1,8(sp)
ffffffffc0200524:	8522                	mv	a0,s0
ffffffffc0200526:	c53ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020052a:	00007517          	auipc	a0,0x7
ffffffffc020052e:	b1650513          	addi	a0,a0,-1258 # ffffffffc0207040 <default_pmm_manager+0x578>
ffffffffc0200532:	c67ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc0200536:	60e2                	ld	ra,24(sp)
ffffffffc0200538:	6442                	ld	s0,16(sp)
ffffffffc020053a:	6161                	addi	sp,sp,80
ffffffffc020053c:	8082                	ret

ffffffffc020053e <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc020053e:	02000793          	li	a5,32
ffffffffc0200542:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200546:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054a:	67e1                	lui	a5,0x18
ffffffffc020054c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf98>
ffffffffc0200550:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200552:	4581                	li	a1,0
ffffffffc0200554:	4601                	li	a2,0
ffffffffc0200556:	4881                	li	a7,0
ffffffffc0200558:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	00006517          	auipc	a0,0x6
ffffffffc0200560:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0205f88 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000d1797          	auipc	a5,0xd1
ffffffffc0200568:	fa07ba23          	sd	zero,-76(a5) # ffffffffc02d1518 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056c:	b135                	j	ffffffffc0200198 <cprintf>

ffffffffc020056e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200572:	67e1                	lui	a5,0x18
ffffffffc0200574:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf98>
ffffffffc0200578:	953e                	add	a0,a0,a5
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	4881                	li	a7,0
ffffffffc0200580:	00000073          	ecall
ffffffffc0200584:	8082                	ret

ffffffffc0200586 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200588:	100027f3          	csrr	a5,sstatus
ffffffffc020058c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020058e:	0ff57513          	zext.b	a0,a0
ffffffffc0200592:	e799                	bnez	a5,ffffffffc02005a0 <cons_putc+0x18>
ffffffffc0200594:	4581                	li	a1,0
ffffffffc0200596:	4601                	li	a2,0
ffffffffc0200598:	4885                	li	a7,1
ffffffffc020059a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020059e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a0:	1101                	addi	sp,sp,-32
ffffffffc02005a2:	ec06                	sd	ra,24(sp)
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a6:	408000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005aa:	6522                	ld	a0,8(sp)
ffffffffc02005ac:	4581                	li	a1,0
ffffffffc02005ae:	4601                	li	a2,0
ffffffffc02005b0:	4885                	li	a7,1
ffffffffc02005b2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b6:	60e2                	ld	ra,24(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005ba:	a6fd                	j	ffffffffc02009a8 <intr_enable>

ffffffffc02005bc <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005bc:	100027f3          	csrr	a5,sstatus
ffffffffc02005c0:	8b89                	andi	a5,a5,2
ffffffffc02005c2:	eb89                	bnez	a5,ffffffffc02005d4 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c4:	4501                	li	a0,0
ffffffffc02005c6:	4581                	li	a1,0
ffffffffc02005c8:	4601                	li	a2,0
ffffffffc02005ca:	4889                	li	a7,2
ffffffffc02005cc:	00000073          	ecall
ffffffffc02005d0:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d2:	8082                	ret
int cons_getc(void) {
ffffffffc02005d4:	1101                	addi	sp,sp,-32
ffffffffc02005d6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005d8:	3d6000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005dc:	4501                	li	a0,0
ffffffffc02005de:	4581                	li	a1,0
ffffffffc02005e0:	4601                	li	a2,0
ffffffffc02005e2:	4889                	li	a7,2
ffffffffc02005e4:	00000073          	ecall
ffffffffc02005e8:	2501                	sext.w	a0,a0
ffffffffc02005ea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ec:	3bc000ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc02005f0:	60e2                	ld	ra,24(sp)
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	6105                	addi	sp,sp,32
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005f8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02005fa:	00006517          	auipc	a0,0x6
ffffffffc02005fe:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0205fa8 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200602:	fc86                	sd	ra,120(sp)
ffffffffc0200604:	f8a2                	sd	s0,112(sp)
ffffffffc0200606:	e8d2                	sd	s4,80(sp)
ffffffffc0200608:	f4a6                	sd	s1,104(sp)
ffffffffc020060a:	f0ca                	sd	s2,96(sp)
ffffffffc020060c:	ecce                	sd	s3,88(sp)
ffffffffc020060e:	e4d6                	sd	s5,72(sp)
ffffffffc0200610:	e0da                	sd	s6,64(sp)
ffffffffc0200612:	fc5e                	sd	s7,56(sp)
ffffffffc0200614:	f862                	sd	s8,48(sp)
ffffffffc0200616:	f466                	sd	s9,40(sp)
ffffffffc0200618:	f06a                	sd	s10,32(sp)
ffffffffc020061a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020061c:	b7dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200620:	0000c597          	auipc	a1,0xc
ffffffffc0200624:	9e05b583          	ld	a1,-1568(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200628:	00006517          	auipc	a0,0x6
ffffffffc020062c:	99050513          	addi	a0,a0,-1648 # ffffffffc0205fb8 <commands+0xb8>
ffffffffc0200630:	b69ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200634:	0000c417          	auipc	s0,0xc
ffffffffc0200638:	9d440413          	addi	s0,s0,-1580 # ffffffffc020c008 <boot_dtb>
ffffffffc020063c:	600c                	ld	a1,0(s0)
ffffffffc020063e:	00006517          	auipc	a0,0x6
ffffffffc0200642:	98a50513          	addi	a0,a0,-1654 # ffffffffc0205fc8 <commands+0xc8>
ffffffffc0200646:	b53ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020064a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020064e:	00006517          	auipc	a0,0x6
ffffffffc0200652:	99250513          	addi	a0,a0,-1646 # ffffffffc0205fe0 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc0200656:	120a0463          	beqz	s4,ffffffffc020077e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020065a:	57f5                	li	a5,-3
ffffffffc020065c:	07fa                	slli	a5,a5,0x1e
ffffffffc020065e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200662:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200664:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200668:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020066e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200672:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	8ec9                	or	a3,a3,a0
ffffffffc0200682:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200686:	1b7d                	addi	s6,s6,-1
ffffffffc0200688:	0167f7b3          	and	a5,a5,s6
ffffffffc020068c:	8dd5                	or	a1,a1,a3
ffffffffc020068e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200690:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe0e955>
ffffffffc020069a:	10f59163          	bne	a1,a5,ffffffffc020079c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020069e:	471c                	lw	a5,8(a4)
ffffffffc02006a0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006a8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006ac:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006bc:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006cc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	01146433          	or	s0,s0,a7
ffffffffc02006d2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006d6:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006da:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8c49                	or	s0,s0,a0
ffffffffc02006e2:	0166f6b3          	and	a3,a3,s6
ffffffffc02006e6:	00ca6a33          	or	s4,s4,a2
ffffffffc02006ea:	0167f7b3          	and	a5,a5,s6
ffffffffc02006ee:	8c55                	or	s0,s0,a3
ffffffffc02006f0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006f6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fa:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200706:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200708:	00006917          	auipc	s2,0x6
ffffffffc020070c:	92890913          	addi	s2,s2,-1752 # ffffffffc0206030 <commands+0x130>
ffffffffc0200710:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200712:	4d91                	li	s11,4
ffffffffc0200714:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200716:	00006497          	auipc	s1,0x6
ffffffffc020071a:	91248493          	addi	s1,s1,-1774 # ffffffffc0206028 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020071e:	000a2703          	lw	a4,0(s4)
ffffffffc0200722:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0087569b          	srliw	a3,a4,0x8
ffffffffc020072a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0107571b          	srliw	a4,a4,0x10
ffffffffc020073a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200744:	8fd5                	or	a5,a5,a3
ffffffffc0200746:	00eb7733          	and	a4,s6,a4
ffffffffc020074a:	8fd9                	or	a5,a5,a4
ffffffffc020074c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020074e:	09778c63          	beq	a5,s7,ffffffffc02007e6 <dtb_init+0x1ee>
ffffffffc0200752:	00fbea63          	bltu	s7,a5,ffffffffc0200766 <dtb_init+0x16e>
ffffffffc0200756:	07a78663          	beq	a5,s10,ffffffffc02007c2 <dtb_init+0x1ca>
ffffffffc020075a:	4709                	li	a4,2
ffffffffc020075c:	00e79763          	bne	a5,a4,ffffffffc020076a <dtb_init+0x172>
ffffffffc0200760:	4c81                	li	s9,0
ffffffffc0200762:	8a56                	mv	s4,s5
ffffffffc0200764:	bf6d                	j	ffffffffc020071e <dtb_init+0x126>
ffffffffc0200766:	ffb78ee3          	beq	a5,s11,ffffffffc0200762 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020076a:	00006517          	auipc	a0,0x6
ffffffffc020076e:	93e50513          	addi	a0,a0,-1730 # ffffffffc02060a8 <commands+0x1a8>
ffffffffc0200772:	a27ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200776:	00006517          	auipc	a0,0x6
ffffffffc020077a:	96a50513          	addi	a0,a0,-1686 # ffffffffc02060e0 <commands+0x1e0>
}
ffffffffc020077e:	7446                	ld	s0,112(sp)
ffffffffc0200780:	70e6                	ld	ra,120(sp)
ffffffffc0200782:	74a6                	ld	s1,104(sp)
ffffffffc0200784:	7906                	ld	s2,96(sp)
ffffffffc0200786:	69e6                	ld	s3,88(sp)
ffffffffc0200788:	6a46                	ld	s4,80(sp)
ffffffffc020078a:	6aa6                	ld	s5,72(sp)
ffffffffc020078c:	6b06                	ld	s6,64(sp)
ffffffffc020078e:	7be2                	ld	s7,56(sp)
ffffffffc0200790:	7c42                	ld	s8,48(sp)
ffffffffc0200792:	7ca2                	ld	s9,40(sp)
ffffffffc0200794:	7d02                	ld	s10,32(sp)
ffffffffc0200796:	6de2                	ld	s11,24(sp)
ffffffffc0200798:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020079a:	bafd                	j	ffffffffc0200198 <cprintf>
}
ffffffffc020079c:	7446                	ld	s0,112(sp)
ffffffffc020079e:	70e6                	ld	ra,120(sp)
ffffffffc02007a0:	74a6                	ld	s1,104(sp)
ffffffffc02007a2:	7906                	ld	s2,96(sp)
ffffffffc02007a4:	69e6                	ld	s3,88(sp)
ffffffffc02007a6:	6a46                	ld	s4,80(sp)
ffffffffc02007a8:	6aa6                	ld	s5,72(sp)
ffffffffc02007aa:	6b06                	ld	s6,64(sp)
ffffffffc02007ac:	7be2                	ld	s7,56(sp)
ffffffffc02007ae:	7c42                	ld	s8,48(sp)
ffffffffc02007b0:	7ca2                	ld	s9,40(sp)
ffffffffc02007b2:	7d02                	ld	s10,32(sp)
ffffffffc02007b4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007b6:	00006517          	auipc	a0,0x6
ffffffffc02007ba:	84a50513          	addi	a0,a0,-1974 # ffffffffc0206000 <commands+0x100>
}
ffffffffc02007be:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c0:	bae1                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c2:	8556                	mv	a0,s5
ffffffffc02007c4:	402050ef          	jal	ra,ffffffffc0205bc6 <strlen>
ffffffffc02007c8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ca:	4619                	li	a2,6
ffffffffc02007cc:	85a6                	mv	a1,s1
ffffffffc02007ce:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d0:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d2:	45a050ef          	jal	ra,ffffffffc0205c2c <strncmp>
ffffffffc02007d6:	e111                	bnez	a0,ffffffffc02007da <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007d8:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007da:	0a91                	addi	s5,s5,4
ffffffffc02007dc:	9ad2                	add	s5,s5,s4
ffffffffc02007de:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e2:	8a56                	mv	s4,s5
ffffffffc02007e4:	bf2d                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007e6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ea:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ee:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fe:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200802:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020080e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200812:	00fb77b3          	and	a5,s6,a5
ffffffffc0200816:	00faeab3          	or	s5,s5,a5
ffffffffc020081a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020081c:	000c9c63          	bnez	s9,ffffffffc0200834 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200820:	1a82                	slli	s5,s5,0x20
ffffffffc0200822:	00368793          	addi	a5,a3,3
ffffffffc0200826:	020ada93          	srli	s5,s5,0x20
ffffffffc020082a:	9abe                	add	s5,s5,a5
ffffffffc020082c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200830:	8a56                	mv	s4,s5
ffffffffc0200832:	b5f5                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200834:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200838:	85ca                	mv	a1,s2
ffffffffc020083a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020083c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200840:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200844:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200848:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200850:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0087979b          	slliw	a5,a5,0x8
ffffffffc020085a:	8d59                	or	a0,a0,a4
ffffffffc020085c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200860:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200862:	1502                	slli	a0,a0,0x20
ffffffffc0200864:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200866:	9522                	add	a0,a0,s0
ffffffffc0200868:	3a6050ef          	jal	ra,ffffffffc0205c0e <strcmp>
ffffffffc020086c:	66a2                	ld	a3,8(sp)
ffffffffc020086e:	f94d                	bnez	a0,ffffffffc0200820 <dtb_init+0x228>
ffffffffc0200870:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200820 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200874:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200878:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020087c:	00005517          	auipc	a0,0x5
ffffffffc0200880:	7bc50513          	addi	a0,a0,1980 # ffffffffc0206038 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc0200884:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200888:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020088c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200890:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200894:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200898:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020089c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a0:	0187d693          	srli	a3,a5,0x18
ffffffffc02008a4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008a8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008ac:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008b4:	010f6f33          	or	t5,t5,a6
ffffffffc02008b8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008bc:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008c4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c8:	0186f6b3          	and	a3,a3,s8
ffffffffc02008cc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d0:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008d4:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008d8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008dc:	8361                	srli	a4,a4,0x18
ffffffffc02008de:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008e6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008ea:	00cb7633          	and	a2,s6,a2
ffffffffc02008ee:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008f6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008fa:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008fe:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200902:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200906:	0088989b          	slliw	a7,a7,0x8
ffffffffc020090a:	011b78b3          	and	a7,s6,a7
ffffffffc020090e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200912:	00c6e733          	or	a4,a3,a2
ffffffffc0200916:	006c6c33          	or	s8,s8,t1
ffffffffc020091a:	010b76b3          	and	a3,s6,a6
ffffffffc020091e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200922:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200926:	016c6b33          	or	s6,s8,s6
ffffffffc020092a:	01146433          	or	s0,s0,a7
ffffffffc020092e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200930:	1702                	slli	a4,a4,0x20
ffffffffc0200932:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200934:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200938:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	0167eb33          	or	s6,a5,s6
ffffffffc0200942:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200944:	855ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200948:	85a2                	mv	a1,s0
ffffffffc020094a:	00005517          	auipc	a0,0x5
ffffffffc020094e:	70e50513          	addi	a0,a0,1806 # ffffffffc0206058 <commands+0x158>
ffffffffc0200952:	847ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200956:	014b5613          	srli	a2,s6,0x14
ffffffffc020095a:	85da                	mv	a1,s6
ffffffffc020095c:	00005517          	auipc	a0,0x5
ffffffffc0200960:	71450513          	addi	a0,a0,1812 # ffffffffc0206070 <commands+0x170>
ffffffffc0200964:	835ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200968:	008b05b3          	add	a1,s6,s0
ffffffffc020096c:	15fd                	addi	a1,a1,-1
ffffffffc020096e:	00005517          	auipc	a0,0x5
ffffffffc0200972:	72250513          	addi	a0,a0,1826 # ffffffffc0206090 <commands+0x190>
ffffffffc0200976:	823ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020097a:	00005517          	auipc	a0,0x5
ffffffffc020097e:	76650513          	addi	a0,a0,1894 # ffffffffc02060e0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200982:	000d1797          	auipc	a5,0xd1
ffffffffc0200986:	b887bf23          	sd	s0,-1122(a5) # ffffffffc02d1520 <memory_base>
        memory_size = mem_size;
ffffffffc020098a:	000d1797          	auipc	a5,0xd1
ffffffffc020098e:	b967bf23          	sd	s6,-1122(a5) # ffffffffc02d1528 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200992:	b3f5                	j	ffffffffc020077e <dtb_init+0x186>

ffffffffc0200994 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200994:	000d1517          	auipc	a0,0xd1
ffffffffc0200998:	b8c53503          	ld	a0,-1140(a0) # ffffffffc02d1520 <memory_base>
ffffffffc020099c:	8082                	ret

ffffffffc020099e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020099e:	000d1517          	auipc	a0,0xd1
ffffffffc02009a2:	b8a53503          	ld	a0,-1142(a0) # ffffffffc02d1528 <memory_size>
ffffffffc02009a6:	8082                	ret

ffffffffc02009a8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009a8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009b4:	8082                	ret

ffffffffc02009b6 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009b6:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009ba:	00000797          	auipc	a5,0x0
ffffffffc02009be:	44678793          	addi	a5,a5,1094 # ffffffffc0200e00 <__alltraps>
ffffffffc02009c2:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009c6:	000407b7          	lui	a5,0x40
ffffffffc02009ca:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009ce:	8082                	ret

ffffffffc02009d0 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d0:	610c                	ld	a1,0(a0)
{
ffffffffc02009d2:	1141                	addi	sp,sp,-16
ffffffffc02009d4:	e022                	sd	s0,0(sp)
ffffffffc02009d6:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	72050513          	addi	a0,a0,1824 # ffffffffc02060f8 <commands+0x1f8>
{
ffffffffc02009e0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e2:	fb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009e6:	640c                	ld	a1,8(s0)
ffffffffc02009e8:	00005517          	auipc	a0,0x5
ffffffffc02009ec:	72850513          	addi	a0,a0,1832 # ffffffffc0206110 <commands+0x210>
ffffffffc02009f0:	fa8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f4:	680c                	ld	a1,16(s0)
ffffffffc02009f6:	00005517          	auipc	a0,0x5
ffffffffc02009fa:	73250513          	addi	a0,a0,1842 # ffffffffc0206128 <commands+0x228>
ffffffffc02009fe:	f9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a02:	6c0c                	ld	a1,24(s0)
ffffffffc0200a04:	00005517          	auipc	a0,0x5
ffffffffc0200a08:	73c50513          	addi	a0,a0,1852 # ffffffffc0206140 <commands+0x240>
ffffffffc0200a0c:	f8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a10:	700c                	ld	a1,32(s0)
ffffffffc0200a12:	00005517          	auipc	a0,0x5
ffffffffc0200a16:	74650513          	addi	a0,a0,1862 # ffffffffc0206158 <commands+0x258>
ffffffffc0200a1a:	f7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a1e:	740c                	ld	a1,40(s0)
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	75050513          	addi	a0,a0,1872 # ffffffffc0206170 <commands+0x270>
ffffffffc0200a28:	f70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a2c:	780c                	ld	a1,48(s0)
ffffffffc0200a2e:	00005517          	auipc	a0,0x5
ffffffffc0200a32:	75a50513          	addi	a0,a0,1882 # ffffffffc0206188 <commands+0x288>
ffffffffc0200a36:	f62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3a:	7c0c                	ld	a1,56(s0)
ffffffffc0200a3c:	00005517          	auipc	a0,0x5
ffffffffc0200a40:	76450513          	addi	a0,a0,1892 # ffffffffc02061a0 <commands+0x2a0>
ffffffffc0200a44:	f54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a48:	602c                	ld	a1,64(s0)
ffffffffc0200a4a:	00005517          	auipc	a0,0x5
ffffffffc0200a4e:	76e50513          	addi	a0,a0,1902 # ffffffffc02061b8 <commands+0x2b8>
ffffffffc0200a52:	f46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a56:	642c                	ld	a1,72(s0)
ffffffffc0200a58:	00005517          	auipc	a0,0x5
ffffffffc0200a5c:	77850513          	addi	a0,a0,1912 # ffffffffc02061d0 <commands+0x2d0>
ffffffffc0200a60:	f38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a64:	682c                	ld	a1,80(s0)
ffffffffc0200a66:	00005517          	auipc	a0,0x5
ffffffffc0200a6a:	78250513          	addi	a0,a0,1922 # ffffffffc02061e8 <commands+0x2e8>
ffffffffc0200a6e:	f2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a72:	6c2c                	ld	a1,88(s0)
ffffffffc0200a74:	00005517          	auipc	a0,0x5
ffffffffc0200a78:	78c50513          	addi	a0,a0,1932 # ffffffffc0206200 <commands+0x300>
ffffffffc0200a7c:	f1cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a80:	702c                	ld	a1,96(s0)
ffffffffc0200a82:	00005517          	auipc	a0,0x5
ffffffffc0200a86:	79650513          	addi	a0,a0,1942 # ffffffffc0206218 <commands+0x318>
ffffffffc0200a8a:	f0eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a8e:	742c                	ld	a1,104(s0)
ffffffffc0200a90:	00005517          	auipc	a0,0x5
ffffffffc0200a94:	7a050513          	addi	a0,a0,1952 # ffffffffc0206230 <commands+0x330>
ffffffffc0200a98:	f00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a9c:	782c                	ld	a1,112(s0)
ffffffffc0200a9e:	00005517          	auipc	a0,0x5
ffffffffc0200aa2:	7aa50513          	addi	a0,a0,1962 # ffffffffc0206248 <commands+0x348>
ffffffffc0200aa6:	ef2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aaa:	7c2c                	ld	a1,120(s0)
ffffffffc0200aac:	00005517          	auipc	a0,0x5
ffffffffc0200ab0:	7b450513          	addi	a0,a0,1972 # ffffffffc0206260 <commands+0x360>
ffffffffc0200ab4:	ee4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200ab8:	604c                	ld	a1,128(s0)
ffffffffc0200aba:	00005517          	auipc	a0,0x5
ffffffffc0200abe:	7be50513          	addi	a0,a0,1982 # ffffffffc0206278 <commands+0x378>
ffffffffc0200ac2:	ed6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200ac6:	644c                	ld	a1,136(s0)
ffffffffc0200ac8:	00005517          	auipc	a0,0x5
ffffffffc0200acc:	7c850513          	addi	a0,a0,1992 # ffffffffc0206290 <commands+0x390>
ffffffffc0200ad0:	ec8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad4:	684c                	ld	a1,144(s0)
ffffffffc0200ad6:	00005517          	auipc	a0,0x5
ffffffffc0200ada:	7d250513          	addi	a0,a0,2002 # ffffffffc02062a8 <commands+0x3a8>
ffffffffc0200ade:	ebaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae2:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae4:	00005517          	auipc	a0,0x5
ffffffffc0200ae8:	7dc50513          	addi	a0,a0,2012 # ffffffffc02062c0 <commands+0x3c0>
ffffffffc0200aec:	eacff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af0:	704c                	ld	a1,160(s0)
ffffffffc0200af2:	00005517          	auipc	a0,0x5
ffffffffc0200af6:	7e650513          	addi	a0,a0,2022 # ffffffffc02062d8 <commands+0x3d8>
ffffffffc0200afa:	e9eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200afe:	744c                	ld	a1,168(s0)
ffffffffc0200b00:	00005517          	auipc	a0,0x5
ffffffffc0200b04:	7f050513          	addi	a0,a0,2032 # ffffffffc02062f0 <commands+0x3f0>
ffffffffc0200b08:	e90ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b0c:	784c                	ld	a1,176(s0)
ffffffffc0200b0e:	00005517          	auipc	a0,0x5
ffffffffc0200b12:	7fa50513          	addi	a0,a0,2042 # ffffffffc0206308 <commands+0x408>
ffffffffc0200b16:	e82ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1a:	7c4c                	ld	a1,184(s0)
ffffffffc0200b1c:	00006517          	auipc	a0,0x6
ffffffffc0200b20:	80450513          	addi	a0,a0,-2044 # ffffffffc0206320 <commands+0x420>
ffffffffc0200b24:	e74ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b28:	606c                	ld	a1,192(s0)
ffffffffc0200b2a:	00006517          	auipc	a0,0x6
ffffffffc0200b2e:	80e50513          	addi	a0,a0,-2034 # ffffffffc0206338 <commands+0x438>
ffffffffc0200b32:	e66ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b36:	646c                	ld	a1,200(s0)
ffffffffc0200b38:	00006517          	auipc	a0,0x6
ffffffffc0200b3c:	81850513          	addi	a0,a0,-2024 # ffffffffc0206350 <commands+0x450>
ffffffffc0200b40:	e58ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b44:	686c                	ld	a1,208(s0)
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	82250513          	addi	a0,a0,-2014 # ffffffffc0206368 <commands+0x468>
ffffffffc0200b4e:	e4aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b52:	6c6c                	ld	a1,216(s0)
ffffffffc0200b54:	00006517          	auipc	a0,0x6
ffffffffc0200b58:	82c50513          	addi	a0,a0,-2004 # ffffffffc0206380 <commands+0x480>
ffffffffc0200b5c:	e3cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b60:	706c                	ld	a1,224(s0)
ffffffffc0200b62:	00006517          	auipc	a0,0x6
ffffffffc0200b66:	83650513          	addi	a0,a0,-1994 # ffffffffc0206398 <commands+0x498>
ffffffffc0200b6a:	e2eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b6e:	746c                	ld	a1,232(s0)
ffffffffc0200b70:	00006517          	auipc	a0,0x6
ffffffffc0200b74:	84050513          	addi	a0,a0,-1984 # ffffffffc02063b0 <commands+0x4b0>
ffffffffc0200b78:	e20ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b7c:	786c                	ld	a1,240(s0)
ffffffffc0200b7e:	00006517          	auipc	a0,0x6
ffffffffc0200b82:	84a50513          	addi	a0,a0,-1974 # ffffffffc02063c8 <commands+0x4c8>
ffffffffc0200b86:	e12ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8a:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	85050513          	addi	a0,a0,-1968 # ffffffffc02063e0 <commands+0x4e0>
}
ffffffffc0200b98:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b9a:	dfeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b9e <print_trapframe>:
{
ffffffffc0200b9e:	1141                	addi	sp,sp,-16
ffffffffc0200ba0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba2:	85aa                	mv	a1,a0
{
ffffffffc0200ba4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba6:	00006517          	auipc	a0,0x6
ffffffffc0200baa:	85250513          	addi	a0,a0,-1966 # ffffffffc02063f8 <commands+0x4f8>
{
ffffffffc0200bae:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb0:	de8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bb4:	8522                	mv	a0,s0
ffffffffc0200bb6:	e1bff0ef          	jal	ra,ffffffffc02009d0 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bba:	10043583          	ld	a1,256(s0)
ffffffffc0200bbe:	00006517          	auipc	a0,0x6
ffffffffc0200bc2:	85250513          	addi	a0,a0,-1966 # ffffffffc0206410 <commands+0x510>
ffffffffc0200bc6:	dd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bca:	10843583          	ld	a1,264(s0)
ffffffffc0200bce:	00006517          	auipc	a0,0x6
ffffffffc0200bd2:	85a50513          	addi	a0,a0,-1958 # ffffffffc0206428 <commands+0x528>
ffffffffc0200bd6:	dc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bda:	11043583          	ld	a1,272(s0)
ffffffffc0200bde:	00006517          	auipc	a0,0x6
ffffffffc0200be2:	86250513          	addi	a0,a0,-1950 # ffffffffc0206440 <commands+0x540>
ffffffffc0200be6:	db2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bea:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf2:	00006517          	auipc	a0,0x6
ffffffffc0200bf6:	85e50513          	addi	a0,a0,-1954 # ffffffffc0206450 <commands+0x550>
}
ffffffffc0200bfa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bfc:	d9cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200c00 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c00:	11853783          	ld	a5,280(a0)
ffffffffc0200c04:	472d                	li	a4,11
ffffffffc0200c06:	0786                	slli	a5,a5,0x1
ffffffffc0200c08:	8385                	srli	a5,a5,0x1
ffffffffc0200c0a:	08f76263          	bltu	a4,a5,ffffffffc0200c8e <interrupt_handler+0x8e>
ffffffffc0200c0e:	00006717          	auipc	a4,0x6
ffffffffc0200c12:	8fa70713          	addi	a4,a4,-1798 # ffffffffc0206508 <commands+0x608>
ffffffffc0200c16:	078a                	slli	a5,a5,0x2
ffffffffc0200c18:	97ba                	add	a5,a5,a4
ffffffffc0200c1a:	439c                	lw	a5,0(a5)
ffffffffc0200c1c:	97ba                	add	a5,a5,a4
ffffffffc0200c1e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c20:	00006517          	auipc	a0,0x6
ffffffffc0200c24:	8a850513          	addi	a0,a0,-1880 # ffffffffc02064c8 <commands+0x5c8>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c2c:	00006517          	auipc	a0,0x6
ffffffffc0200c30:	87c50513          	addi	a0,a0,-1924 # ffffffffc02064a8 <commands+0x5a8>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c38:	00006517          	auipc	a0,0x6
ffffffffc0200c3c:	83050513          	addi	a0,a0,-2000 # ffffffffc0206468 <commands+0x568>
ffffffffc0200c40:	d58ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	84450513          	addi	a0,a0,-1980 # ffffffffc0206488 <commands+0x588>
ffffffffc0200c4c:	d4cff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200c50:	1141                	addi	sp,sp,-16
ffffffffc0200c52:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
         clock_set_next_event();
ffffffffc0200c54:	91bff0ef          	jal	ra,ffffffffc020056e <clock_set_next_event>
        ticks++;
ffffffffc0200c58:	000d1797          	auipc	a5,0xd1
ffffffffc0200c5c:	8c078793          	addi	a5,a5,-1856 # ffffffffc02d1518 <ticks>
ffffffffc0200c60:	6398                	ld	a4,0(a5)
        if (ticks % TICK_NUM == 0)
        {
            if (current != NULL)//确保当前有进程在运行
ffffffffc0200c62:	000d1517          	auipc	a0,0xd1
ffffffffc0200c66:	90653503          	ld	a0,-1786(a0) # ffffffffc02d1568 <current>
        ticks++;
ffffffffc0200c6a:	0705                	addi	a4,a4,1
ffffffffc0200c6c:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0)
ffffffffc0200c6e:	639c                	ld	a5,0(a5)
ffffffffc0200c70:	8b85                	andi	a5,a5,1
ffffffffc0200c72:	e781                	bnez	a5,ffffffffc0200c7a <interrupt_handler+0x7a>
            if (current != NULL)//确保当前有进程在运行
ffffffffc0200c74:	c119                	beqz	a0,ffffffffc0200c7a <interrupt_handler+0x7a>
            {
                current->need_resched = 1;// 标记：该进程时间片用完了，申请调度
ffffffffc0200c76:	4785                	li	a5,1
ffffffffc0200c78:	ed1c                	sd	a5,24(a0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c7a:	60a2                	ld	ra,8(sp)
ffffffffc0200c7c:	0141                	addi	sp,sp,16
        sched_class_proc_tick(current);
ffffffffc0200c7e:	0590406f          	j	ffffffffc02054d6 <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c82:	00006517          	auipc	a0,0x6
ffffffffc0200c86:	86650513          	addi	a0,a0,-1946 # ffffffffc02064e8 <commands+0x5e8>
ffffffffc0200c8a:	d0eff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c8e:	bf01                	j	ffffffffc0200b9e <print_trapframe>

ffffffffc0200c90 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c90:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c94:	1141                	addi	sp,sp,-16
ffffffffc0200c96:	e022                	sd	s0,0(sp)
ffffffffc0200c98:	e406                	sd	ra,8(sp)
ffffffffc0200c9a:	473d                	li	a4,15
ffffffffc0200c9c:	842a                	mv	s0,a0
ffffffffc0200c9e:	0af76b63          	bltu	a4,a5,ffffffffc0200d54 <exception_handler+0xc4>
ffffffffc0200ca2:	00006717          	auipc	a4,0x6
ffffffffc0200ca6:	a2670713          	addi	a4,a4,-1498 # ffffffffc02066c8 <commands+0x7c8>
ffffffffc0200caa:	078a                	slli	a5,a5,0x2
ffffffffc0200cac:	97ba                	add	a5,a5,a4
ffffffffc0200cae:	439c                	lw	a5,0(a5)
ffffffffc0200cb0:	97ba                	add	a5,a5,a4
ffffffffc0200cb2:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cb4:	00006517          	auipc	a0,0x6
ffffffffc0200cb8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0206620 <commands+0x720>
ffffffffc0200cbc:	cdcff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200cc0:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cc4:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cc6:	0791                	addi	a5,a5,4
ffffffffc0200cc8:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ccc:	6402                	ld	s0,0(sp)
ffffffffc0200cce:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cd0:	2710406f          	j	ffffffffc0205740 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cd4:	00006517          	auipc	a0,0x6
ffffffffc0200cd8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0206640 <commands+0x740>
}
ffffffffc0200cdc:	6402                	ld	s0,0(sp)
ffffffffc0200cde:	60a2                	ld	ra,8(sp)
ffffffffc0200ce0:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200ce2:	cb6ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200ce6:	00006517          	auipc	a0,0x6
ffffffffc0200cea:	97a50513          	addi	a0,a0,-1670 # ffffffffc0206660 <commands+0x760>
ffffffffc0200cee:	b7fd                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200cf0:	00006517          	auipc	a0,0x6
ffffffffc0200cf4:	99050513          	addi	a0,a0,-1648 # ffffffffc0206680 <commands+0x780>
ffffffffc0200cf8:	b7d5                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200cfa:	00006517          	auipc	a0,0x6
ffffffffc0200cfe:	99e50513          	addi	a0,a0,-1634 # ffffffffc0206698 <commands+0x798>
ffffffffc0200d02:	bfe9                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d04:	00006517          	auipc	a0,0x6
ffffffffc0200d08:	9ac50513          	addi	a0,a0,-1620 # ffffffffc02066b0 <commands+0x7b0>
ffffffffc0200d0c:	bfc1                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d0e:	00006517          	auipc	a0,0x6
ffffffffc0200d12:	82a50513          	addi	a0,a0,-2006 # ffffffffc0206538 <commands+0x638>
ffffffffc0200d16:	b7d9                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d18:	00006517          	auipc	a0,0x6
ffffffffc0200d1c:	84050513          	addi	a0,a0,-1984 # ffffffffc0206558 <commands+0x658>
ffffffffc0200d20:	bf75                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d22:	00006517          	auipc	a0,0x6
ffffffffc0200d26:	85650513          	addi	a0,a0,-1962 # ffffffffc0206578 <commands+0x678>
ffffffffc0200d2a:	bf4d                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d2c:	00006517          	auipc	a0,0x6
ffffffffc0200d30:	86450513          	addi	a0,a0,-1948 # ffffffffc0206590 <commands+0x690>
ffffffffc0200d34:	b765                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200d36:	00006517          	auipc	a0,0x6
ffffffffc0200d3a:	86a50513          	addi	a0,a0,-1942 # ffffffffc02065a0 <commands+0x6a0>
ffffffffc0200d3e:	bf79                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d40:	00006517          	auipc	a0,0x6
ffffffffc0200d44:	88050513          	addi	a0,a0,-1920 # ffffffffc02065c0 <commands+0x6c0>
ffffffffc0200d48:	bf51                	j	ffffffffc0200cdc <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d4a:	00006517          	auipc	a0,0x6
ffffffffc0200d4e:	8be50513          	addi	a0,a0,-1858 # ffffffffc0206608 <commands+0x708>
ffffffffc0200d52:	b769                	j	ffffffffc0200cdc <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d54:	8522                	mv	a0,s0
}
ffffffffc0200d56:	6402                	ld	s0,0(sp)
ffffffffc0200d58:	60a2                	ld	ra,8(sp)
ffffffffc0200d5a:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d5c:	b589                	j	ffffffffc0200b9e <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d5e:	00006617          	auipc	a2,0x6
ffffffffc0200d62:	87a60613          	addi	a2,a2,-1926 # ffffffffc02065d8 <commands+0x6d8>
ffffffffc0200d66:	0c200593          	li	a1,194
ffffffffc0200d6a:	00006517          	auipc	a0,0x6
ffffffffc0200d6e:	88650513          	addi	a0,a0,-1914 # ffffffffc02065f0 <commands+0x6f0>
ffffffffc0200d72:	f20ff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200d76 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200d76:	1101                	addi	sp,sp,-32
ffffffffc0200d78:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d7a:	000d0417          	auipc	s0,0xd0
ffffffffc0200d7e:	7ee40413          	addi	s0,s0,2030 # ffffffffc02d1568 <current>
ffffffffc0200d82:	6018                	ld	a4,0(s0)
{
ffffffffc0200d84:	ec06                	sd	ra,24(sp)
ffffffffc0200d86:	e426                	sd	s1,8(sp)
ffffffffc0200d88:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d8a:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200d8e:	cf1d                	beqz	a4,ffffffffc0200dcc <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d90:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d94:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200d98:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d9a:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d9e:	0206c463          	bltz	a3,ffffffffc0200dc6 <trap+0x50>
        exception_handler(tf);
ffffffffc0200da2:	eefff0ef          	jal	ra,ffffffffc0200c90 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200da6:	601c                	ld	a5,0(s0)
ffffffffc0200da8:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200dac:	e499                	bnez	s1,ffffffffc0200dba <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200dae:	0b07a703          	lw	a4,176(a5)
ffffffffc0200db2:	8b05                	andi	a4,a4,1
ffffffffc0200db4:	e329                	bnez	a4,ffffffffc0200df6 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200db6:	6f9c                	ld	a5,24(a5)
ffffffffc0200db8:	eb85                	bnez	a5,ffffffffc0200de8 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200dba:	60e2                	ld	ra,24(sp)
ffffffffc0200dbc:	6442                	ld	s0,16(sp)
ffffffffc0200dbe:	64a2                	ld	s1,8(sp)
ffffffffc0200dc0:	6902                	ld	s2,0(sp)
ffffffffc0200dc2:	6105                	addi	sp,sp,32
ffffffffc0200dc4:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200dc6:	e3bff0ef          	jal	ra,ffffffffc0200c00 <interrupt_handler>
ffffffffc0200dca:	bff1                	j	ffffffffc0200da6 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dcc:	0006c863          	bltz	a3,ffffffffc0200ddc <trap+0x66>
}
ffffffffc0200dd0:	6442                	ld	s0,16(sp)
ffffffffc0200dd2:	60e2                	ld	ra,24(sp)
ffffffffc0200dd4:	64a2                	ld	s1,8(sp)
ffffffffc0200dd6:	6902                	ld	s2,0(sp)
ffffffffc0200dd8:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200dda:	bd5d                	j	ffffffffc0200c90 <exception_handler>
}
ffffffffc0200ddc:	6442                	ld	s0,16(sp)
ffffffffc0200dde:	60e2                	ld	ra,24(sp)
ffffffffc0200de0:	64a2                	ld	s1,8(sp)
ffffffffc0200de2:	6902                	ld	s2,0(sp)
ffffffffc0200de4:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200de6:	bd29                	j	ffffffffc0200c00 <interrupt_handler>
}
ffffffffc0200de8:	6442                	ld	s0,16(sp)
ffffffffc0200dea:	60e2                	ld	ra,24(sp)
ffffffffc0200dec:	64a2                	ld	s1,8(sp)
ffffffffc0200dee:	6902                	ld	s2,0(sp)
ffffffffc0200df0:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200df2:	0110406f          	j	ffffffffc0205602 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200df6:	555d                	li	a0,-9
ffffffffc0200df8:	4a4030ef          	jal	ra,ffffffffc020429c <do_exit>
            if (current->need_resched)
ffffffffc0200dfc:	601c                	ld	a5,0(s0)
ffffffffc0200dfe:	bf65                	j	ffffffffc0200db6 <trap+0x40>

ffffffffc0200e00 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e00:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e04:	00011463          	bnez	sp,ffffffffc0200e0c <__alltraps+0xc>
ffffffffc0200e08:	14002173          	csrr	sp,sscratch
ffffffffc0200e0c:	712d                	addi	sp,sp,-288
ffffffffc0200e0e:	e002                	sd	zero,0(sp)
ffffffffc0200e10:	e406                	sd	ra,8(sp)
ffffffffc0200e12:	ec0e                	sd	gp,24(sp)
ffffffffc0200e14:	f012                	sd	tp,32(sp)
ffffffffc0200e16:	f416                	sd	t0,40(sp)
ffffffffc0200e18:	f81a                	sd	t1,48(sp)
ffffffffc0200e1a:	fc1e                	sd	t2,56(sp)
ffffffffc0200e1c:	e0a2                	sd	s0,64(sp)
ffffffffc0200e1e:	e4a6                	sd	s1,72(sp)
ffffffffc0200e20:	e8aa                	sd	a0,80(sp)
ffffffffc0200e22:	ecae                	sd	a1,88(sp)
ffffffffc0200e24:	f0b2                	sd	a2,96(sp)
ffffffffc0200e26:	f4b6                	sd	a3,104(sp)
ffffffffc0200e28:	f8ba                	sd	a4,112(sp)
ffffffffc0200e2a:	fcbe                	sd	a5,120(sp)
ffffffffc0200e2c:	e142                	sd	a6,128(sp)
ffffffffc0200e2e:	e546                	sd	a7,136(sp)
ffffffffc0200e30:	e94a                	sd	s2,144(sp)
ffffffffc0200e32:	ed4e                	sd	s3,152(sp)
ffffffffc0200e34:	f152                	sd	s4,160(sp)
ffffffffc0200e36:	f556                	sd	s5,168(sp)
ffffffffc0200e38:	f95a                	sd	s6,176(sp)
ffffffffc0200e3a:	fd5e                	sd	s7,184(sp)
ffffffffc0200e3c:	e1e2                	sd	s8,192(sp)
ffffffffc0200e3e:	e5e6                	sd	s9,200(sp)
ffffffffc0200e40:	e9ea                	sd	s10,208(sp)
ffffffffc0200e42:	edee                	sd	s11,216(sp)
ffffffffc0200e44:	f1f2                	sd	t3,224(sp)
ffffffffc0200e46:	f5f6                	sd	t4,232(sp)
ffffffffc0200e48:	f9fa                	sd	t5,240(sp)
ffffffffc0200e4a:	fdfe                	sd	t6,248(sp)
ffffffffc0200e4c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e50:	100024f3          	csrr	s1,sstatus
ffffffffc0200e54:	14102973          	csrr	s2,sepc
ffffffffc0200e58:	143029f3          	csrr	s3,stval
ffffffffc0200e5c:	14202a73          	csrr	s4,scause
ffffffffc0200e60:	e822                	sd	s0,16(sp)
ffffffffc0200e62:	e226                	sd	s1,256(sp)
ffffffffc0200e64:	e64a                	sd	s2,264(sp)
ffffffffc0200e66:	ea4e                	sd	s3,272(sp)
ffffffffc0200e68:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e6a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e6c:	f0bff0ef          	jal	ra,ffffffffc0200d76 <trap>

ffffffffc0200e70 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e70:	6492                	ld	s1,256(sp)
ffffffffc0200e72:	6932                	ld	s2,264(sp)
ffffffffc0200e74:	1004f413          	andi	s0,s1,256
ffffffffc0200e78:	e401                	bnez	s0,ffffffffc0200e80 <__trapret+0x10>
ffffffffc0200e7a:	1200                	addi	s0,sp,288
ffffffffc0200e7c:	14041073          	csrw	sscratch,s0
ffffffffc0200e80:	10049073          	csrw	sstatus,s1
ffffffffc0200e84:	14191073          	csrw	sepc,s2
ffffffffc0200e88:	60a2                	ld	ra,8(sp)
ffffffffc0200e8a:	61e2                	ld	gp,24(sp)
ffffffffc0200e8c:	7202                	ld	tp,32(sp)
ffffffffc0200e8e:	72a2                	ld	t0,40(sp)
ffffffffc0200e90:	7342                	ld	t1,48(sp)
ffffffffc0200e92:	73e2                	ld	t2,56(sp)
ffffffffc0200e94:	6406                	ld	s0,64(sp)
ffffffffc0200e96:	64a6                	ld	s1,72(sp)
ffffffffc0200e98:	6546                	ld	a0,80(sp)
ffffffffc0200e9a:	65e6                	ld	a1,88(sp)
ffffffffc0200e9c:	7606                	ld	a2,96(sp)
ffffffffc0200e9e:	76a6                	ld	a3,104(sp)
ffffffffc0200ea0:	7746                	ld	a4,112(sp)
ffffffffc0200ea2:	77e6                	ld	a5,120(sp)
ffffffffc0200ea4:	680a                	ld	a6,128(sp)
ffffffffc0200ea6:	68aa                	ld	a7,136(sp)
ffffffffc0200ea8:	694a                	ld	s2,144(sp)
ffffffffc0200eaa:	69ea                	ld	s3,152(sp)
ffffffffc0200eac:	7a0a                	ld	s4,160(sp)
ffffffffc0200eae:	7aaa                	ld	s5,168(sp)
ffffffffc0200eb0:	7b4a                	ld	s6,176(sp)
ffffffffc0200eb2:	7bea                	ld	s7,184(sp)
ffffffffc0200eb4:	6c0e                	ld	s8,192(sp)
ffffffffc0200eb6:	6cae                	ld	s9,200(sp)
ffffffffc0200eb8:	6d4e                	ld	s10,208(sp)
ffffffffc0200eba:	6dee                	ld	s11,216(sp)
ffffffffc0200ebc:	7e0e                	ld	t3,224(sp)
ffffffffc0200ebe:	7eae                	ld	t4,232(sp)
ffffffffc0200ec0:	7f4e                	ld	t5,240(sp)
ffffffffc0200ec2:	7fee                	ld	t6,248(sp)
ffffffffc0200ec4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200ec6:	10200073          	sret

ffffffffc0200eca <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200eca:	812a                	mv	sp,a0
ffffffffc0200ecc:	b755                	j	ffffffffc0200e70 <__trapret>

ffffffffc0200ece <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ece:	000cc797          	auipc	a5,0xcc
ffffffffc0200ed2:	5ea78793          	addi	a5,a5,1514 # ffffffffc02cd4b8 <free_area>
ffffffffc0200ed6:	e79c                	sd	a5,8(a5)
ffffffffc0200ed8:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200eda:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ede:	8082                	ret

ffffffffc0200ee0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200ee0:	000cc517          	auipc	a0,0xcc
ffffffffc0200ee4:	5e856503          	lwu	a0,1512(a0) # ffffffffc02cd4c8 <free_area+0x10>
ffffffffc0200ee8:	8082                	ret

ffffffffc0200eea <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200eea:	715d                	addi	sp,sp,-80
ffffffffc0200eec:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200eee:	000cc417          	auipc	s0,0xcc
ffffffffc0200ef2:	5ca40413          	addi	s0,s0,1482 # ffffffffc02cd4b8 <free_area>
ffffffffc0200ef6:	641c                	ld	a5,8(s0)
ffffffffc0200ef8:	e486                	sd	ra,72(sp)
ffffffffc0200efa:	fc26                	sd	s1,56(sp)
ffffffffc0200efc:	f84a                	sd	s2,48(sp)
ffffffffc0200efe:	f44e                	sd	s3,40(sp)
ffffffffc0200f00:	f052                	sd	s4,32(sp)
ffffffffc0200f02:	ec56                	sd	s5,24(sp)
ffffffffc0200f04:	e85a                	sd	s6,16(sp)
ffffffffc0200f06:	e45e                	sd	s7,8(sp)
ffffffffc0200f08:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f0a:	2a878d63          	beq	a5,s0,ffffffffc02011c4 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200f0e:	4481                	li	s1,0
ffffffffc0200f10:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f12:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f16:	8b09                	andi	a4,a4,2
ffffffffc0200f18:	2a070a63          	beqz	a4,ffffffffc02011cc <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200f1c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f20:	679c                	ld	a5,8(a5)
ffffffffc0200f22:	2905                	addiw	s2,s2,1
ffffffffc0200f24:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f26:	fe8796e3          	bne	a5,s0,ffffffffc0200f12 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200f2a:	89a6                	mv	s3,s1
ffffffffc0200f2c:	6df000ef          	jal	ra,ffffffffc0201e0a <nr_free_pages>
ffffffffc0200f30:	6f351e63          	bne	a0,s3,ffffffffc020162c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f34:	4505                	li	a0,1
ffffffffc0200f36:	657000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0200f3a:	8aaa                	mv	s5,a0
ffffffffc0200f3c:	42050863          	beqz	a0,ffffffffc020136c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f40:	4505                	li	a0,1
ffffffffc0200f42:	64b000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0200f46:	89aa                	mv	s3,a0
ffffffffc0200f48:	70050263          	beqz	a0,ffffffffc020164c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f4c:	4505                	li	a0,1
ffffffffc0200f4e:	63f000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0200f52:	8a2a                	mv	s4,a0
ffffffffc0200f54:	48050c63          	beqz	a0,ffffffffc02013ec <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f58:	293a8a63          	beq	s5,s3,ffffffffc02011ec <default_check+0x302>
ffffffffc0200f5c:	28aa8863          	beq	s5,a0,ffffffffc02011ec <default_check+0x302>
ffffffffc0200f60:	28a98663          	beq	s3,a0,ffffffffc02011ec <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f64:	000aa783          	lw	a5,0(s5)
ffffffffc0200f68:	2a079263          	bnez	a5,ffffffffc020120c <default_check+0x322>
ffffffffc0200f6c:	0009a783          	lw	a5,0(s3)
ffffffffc0200f70:	28079e63          	bnez	a5,ffffffffc020120c <default_check+0x322>
ffffffffc0200f74:	411c                	lw	a5,0(a0)
ffffffffc0200f76:	28079b63          	bnez	a5,ffffffffc020120c <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f7a:	000d0797          	auipc	a5,0xd0
ffffffffc0200f7e:	5d67b783          	ld	a5,1494(a5) # ffffffffc02d1550 <pages>
ffffffffc0200f82:	40fa8733          	sub	a4,s5,a5
ffffffffc0200f86:	00007617          	auipc	a2,0x7
ffffffffc0200f8a:	5ea63603          	ld	a2,1514(a2) # ffffffffc0208570 <nbase>
ffffffffc0200f8e:	8719                	srai	a4,a4,0x6
ffffffffc0200f90:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f92:	000d0697          	auipc	a3,0xd0
ffffffffc0200f96:	5b66b683          	ld	a3,1462(a3) # ffffffffc02d1548 <npage>
ffffffffc0200f9a:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f9c:	0732                	slli	a4,a4,0xc
ffffffffc0200f9e:	28d77763          	bgeu	a4,a3,ffffffffc020122c <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200fa2:	40f98733          	sub	a4,s3,a5
ffffffffc0200fa6:	8719                	srai	a4,a4,0x6
ffffffffc0200fa8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200faa:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200fac:	4cd77063          	bgeu	a4,a3,ffffffffc020146c <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200fb0:	40f507b3          	sub	a5,a0,a5
ffffffffc0200fb4:	8799                	srai	a5,a5,0x6
ffffffffc0200fb6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fb8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fba:	30d7f963          	bgeu	a5,a3,ffffffffc02012cc <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200fbe:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fc0:	00043c03          	ld	s8,0(s0)
ffffffffc0200fc4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200fc8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200fcc:	e400                	sd	s0,8(s0)
ffffffffc0200fce:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200fd0:	000cc797          	auipc	a5,0xcc
ffffffffc0200fd4:	4e07ac23          	sw	zero,1272(a5) # ffffffffc02cd4c8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200fd8:	5b5000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0200fdc:	2c051863          	bnez	a0,ffffffffc02012ac <default_check+0x3c2>
    free_page(p0);
ffffffffc0200fe0:	4585                	li	a1,1
ffffffffc0200fe2:	8556                	mv	a0,s5
ffffffffc0200fe4:	5e7000ef          	jal	ra,ffffffffc0201dca <free_pages>
    free_page(p1);
ffffffffc0200fe8:	4585                	li	a1,1
ffffffffc0200fea:	854e                	mv	a0,s3
ffffffffc0200fec:	5df000ef          	jal	ra,ffffffffc0201dca <free_pages>
    free_page(p2);
ffffffffc0200ff0:	4585                	li	a1,1
ffffffffc0200ff2:	8552                	mv	a0,s4
ffffffffc0200ff4:	5d7000ef          	jal	ra,ffffffffc0201dca <free_pages>
    assert(nr_free == 3);
ffffffffc0200ff8:	4818                	lw	a4,16(s0)
ffffffffc0200ffa:	478d                	li	a5,3
ffffffffc0200ffc:	28f71863          	bne	a4,a5,ffffffffc020128c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201000:	4505                	li	a0,1
ffffffffc0201002:	58b000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0201006:	89aa                	mv	s3,a0
ffffffffc0201008:	26050263          	beqz	a0,ffffffffc020126c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020100c:	4505                	li	a0,1
ffffffffc020100e:	57f000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0201012:	8aaa                	mv	s5,a0
ffffffffc0201014:	3a050c63          	beqz	a0,ffffffffc02013cc <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201018:	4505                	li	a0,1
ffffffffc020101a:	573000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc020101e:	8a2a                	mv	s4,a0
ffffffffc0201020:	38050663          	beqz	a0,ffffffffc02013ac <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201024:	4505                	li	a0,1
ffffffffc0201026:	567000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc020102a:	36051163          	bnez	a0,ffffffffc020138c <default_check+0x4a2>
    free_page(p0);
ffffffffc020102e:	4585                	li	a1,1
ffffffffc0201030:	854e                	mv	a0,s3
ffffffffc0201032:	599000ef          	jal	ra,ffffffffc0201dca <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201036:	641c                	ld	a5,8(s0)
ffffffffc0201038:	20878a63          	beq	a5,s0,ffffffffc020124c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020103c:	4505                	li	a0,1
ffffffffc020103e:	54f000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0201042:	30a99563          	bne	s3,a0,ffffffffc020134c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201046:	4505                	li	a0,1
ffffffffc0201048:	545000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc020104c:	2e051063          	bnez	a0,ffffffffc020132c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201050:	481c                	lw	a5,16(s0)
ffffffffc0201052:	2a079d63          	bnez	a5,ffffffffc020130c <default_check+0x422>
    free_page(p);
ffffffffc0201056:	854e                	mv	a0,s3
ffffffffc0201058:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020105a:	01843023          	sd	s8,0(s0)
ffffffffc020105e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201062:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201066:	565000ef          	jal	ra,ffffffffc0201dca <free_pages>
    free_page(p1);
ffffffffc020106a:	4585                	li	a1,1
ffffffffc020106c:	8556                	mv	a0,s5
ffffffffc020106e:	55d000ef          	jal	ra,ffffffffc0201dca <free_pages>
    free_page(p2);
ffffffffc0201072:	4585                	li	a1,1
ffffffffc0201074:	8552                	mv	a0,s4
ffffffffc0201076:	555000ef          	jal	ra,ffffffffc0201dca <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020107a:	4515                	li	a0,5
ffffffffc020107c:	511000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0201080:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201082:	26050563          	beqz	a0,ffffffffc02012ec <default_check+0x402>
ffffffffc0201086:	651c                	ld	a5,8(a0)
ffffffffc0201088:	8385                	srli	a5,a5,0x1
ffffffffc020108a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020108c:	54079063          	bnez	a5,ffffffffc02015cc <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201090:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201092:	00043b03          	ld	s6,0(s0)
ffffffffc0201096:	00843a83          	ld	s5,8(s0)
ffffffffc020109a:	e000                	sd	s0,0(s0)
ffffffffc020109c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020109e:	4ef000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc02010a2:	50051563          	bnez	a0,ffffffffc02015ac <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02010a6:	08098a13          	addi	s4,s3,128
ffffffffc02010aa:	8552                	mv	a0,s4
ffffffffc02010ac:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02010ae:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02010b2:	000cc797          	auipc	a5,0xcc
ffffffffc02010b6:	4007ab23          	sw	zero,1046(a5) # ffffffffc02cd4c8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010ba:	511000ef          	jal	ra,ffffffffc0201dca <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010be:	4511                	li	a0,4
ffffffffc02010c0:	4cd000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc02010c4:	4c051463          	bnez	a0,ffffffffc020158c <default_check+0x6a2>
ffffffffc02010c8:	0889b783          	ld	a5,136(s3)
ffffffffc02010cc:	8385                	srli	a5,a5,0x1
ffffffffc02010ce:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010d0:	48078e63          	beqz	a5,ffffffffc020156c <default_check+0x682>
ffffffffc02010d4:	0909a703          	lw	a4,144(s3)
ffffffffc02010d8:	478d                	li	a5,3
ffffffffc02010da:	48f71963          	bne	a4,a5,ffffffffc020156c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010de:	450d                	li	a0,3
ffffffffc02010e0:	4ad000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc02010e4:	8c2a                	mv	s8,a0
ffffffffc02010e6:	46050363          	beqz	a0,ffffffffc020154c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02010ea:	4505                	li	a0,1
ffffffffc02010ec:	4a1000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc02010f0:	42051e63          	bnez	a0,ffffffffc020152c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02010f4:	418a1c63          	bne	s4,s8,ffffffffc020150c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010f8:	4585                	li	a1,1
ffffffffc02010fa:	854e                	mv	a0,s3
ffffffffc02010fc:	4cf000ef          	jal	ra,ffffffffc0201dca <free_pages>
    free_pages(p1, 3);
ffffffffc0201100:	458d                	li	a1,3
ffffffffc0201102:	8552                	mv	a0,s4
ffffffffc0201104:	4c7000ef          	jal	ra,ffffffffc0201dca <free_pages>
ffffffffc0201108:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020110c:	04098c13          	addi	s8,s3,64
ffffffffc0201110:	8385                	srli	a5,a5,0x1
ffffffffc0201112:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201114:	3c078c63          	beqz	a5,ffffffffc02014ec <default_check+0x602>
ffffffffc0201118:	0109a703          	lw	a4,16(s3)
ffffffffc020111c:	4785                	li	a5,1
ffffffffc020111e:	3cf71763          	bne	a4,a5,ffffffffc02014ec <default_check+0x602>
ffffffffc0201122:	008a3783          	ld	a5,8(s4)
ffffffffc0201126:	8385                	srli	a5,a5,0x1
ffffffffc0201128:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020112a:	3a078163          	beqz	a5,ffffffffc02014cc <default_check+0x5e2>
ffffffffc020112e:	010a2703          	lw	a4,16(s4)
ffffffffc0201132:	478d                	li	a5,3
ffffffffc0201134:	38f71c63          	bne	a4,a5,ffffffffc02014cc <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201138:	4505                	li	a0,1
ffffffffc020113a:	453000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc020113e:	36a99763          	bne	s3,a0,ffffffffc02014ac <default_check+0x5c2>
    free_page(p0);
ffffffffc0201142:	4585                	li	a1,1
ffffffffc0201144:	487000ef          	jal	ra,ffffffffc0201dca <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201148:	4509                	li	a0,2
ffffffffc020114a:	443000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc020114e:	32aa1f63          	bne	s4,a0,ffffffffc020148c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201152:	4589                	li	a1,2
ffffffffc0201154:	477000ef          	jal	ra,ffffffffc0201dca <free_pages>
    free_page(p2);
ffffffffc0201158:	4585                	li	a1,1
ffffffffc020115a:	8562                	mv	a0,s8
ffffffffc020115c:	46f000ef          	jal	ra,ffffffffc0201dca <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201160:	4515                	li	a0,5
ffffffffc0201162:	42b000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0201166:	89aa                	mv	s3,a0
ffffffffc0201168:	48050263          	beqz	a0,ffffffffc02015ec <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020116c:	4505                	li	a0,1
ffffffffc020116e:	41f000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0201172:	2c051d63          	bnez	a0,ffffffffc020144c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201176:	481c                	lw	a5,16(s0)
ffffffffc0201178:	2a079a63          	bnez	a5,ffffffffc020142c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020117c:	4595                	li	a1,5
ffffffffc020117e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201180:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201184:	01643023          	sd	s6,0(s0)
ffffffffc0201188:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020118c:	43f000ef          	jal	ra,ffffffffc0201dca <free_pages>
    return listelm->next;
ffffffffc0201190:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201192:	00878963          	beq	a5,s0,ffffffffc02011a4 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201196:	ff87a703          	lw	a4,-8(a5)
ffffffffc020119a:	679c                	ld	a5,8(a5)
ffffffffc020119c:	397d                	addiw	s2,s2,-1
ffffffffc020119e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02011a0:	fe879be3          	bne	a5,s0,ffffffffc0201196 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02011a4:	26091463          	bnez	s2,ffffffffc020140c <default_check+0x522>
    assert(total == 0);
ffffffffc02011a8:	46049263          	bnez	s1,ffffffffc020160c <default_check+0x722>
}
ffffffffc02011ac:	60a6                	ld	ra,72(sp)
ffffffffc02011ae:	6406                	ld	s0,64(sp)
ffffffffc02011b0:	74e2                	ld	s1,56(sp)
ffffffffc02011b2:	7942                	ld	s2,48(sp)
ffffffffc02011b4:	79a2                	ld	s3,40(sp)
ffffffffc02011b6:	7a02                	ld	s4,32(sp)
ffffffffc02011b8:	6ae2                	ld	s5,24(sp)
ffffffffc02011ba:	6b42                	ld	s6,16(sp)
ffffffffc02011bc:	6ba2                	ld	s7,8(sp)
ffffffffc02011be:	6c02                	ld	s8,0(sp)
ffffffffc02011c0:	6161                	addi	sp,sp,80
ffffffffc02011c2:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02011c4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011c6:	4481                	li	s1,0
ffffffffc02011c8:	4901                	li	s2,0
ffffffffc02011ca:	b38d                	j	ffffffffc0200f2c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02011cc:	00005697          	auipc	a3,0x5
ffffffffc02011d0:	53c68693          	addi	a3,a3,1340 # ffffffffc0206708 <commands+0x808>
ffffffffc02011d4:	00005617          	auipc	a2,0x5
ffffffffc02011d8:	54460613          	addi	a2,a2,1348 # ffffffffc0206718 <commands+0x818>
ffffffffc02011dc:	11000593          	li	a1,272
ffffffffc02011e0:	00005517          	auipc	a0,0x5
ffffffffc02011e4:	55050513          	addi	a0,a0,1360 # ffffffffc0206730 <commands+0x830>
ffffffffc02011e8:	aaaff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011ec:	00005697          	auipc	a3,0x5
ffffffffc02011f0:	5dc68693          	addi	a3,a3,1500 # ffffffffc02067c8 <commands+0x8c8>
ffffffffc02011f4:	00005617          	auipc	a2,0x5
ffffffffc02011f8:	52460613          	addi	a2,a2,1316 # ffffffffc0206718 <commands+0x818>
ffffffffc02011fc:	0db00593          	li	a1,219
ffffffffc0201200:	00005517          	auipc	a0,0x5
ffffffffc0201204:	53050513          	addi	a0,a0,1328 # ffffffffc0206730 <commands+0x830>
ffffffffc0201208:	a8aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020120c:	00005697          	auipc	a3,0x5
ffffffffc0201210:	5e468693          	addi	a3,a3,1508 # ffffffffc02067f0 <commands+0x8f0>
ffffffffc0201214:	00005617          	auipc	a2,0x5
ffffffffc0201218:	50460613          	addi	a2,a2,1284 # ffffffffc0206718 <commands+0x818>
ffffffffc020121c:	0dc00593          	li	a1,220
ffffffffc0201220:	00005517          	auipc	a0,0x5
ffffffffc0201224:	51050513          	addi	a0,a0,1296 # ffffffffc0206730 <commands+0x830>
ffffffffc0201228:	a6aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020122c:	00005697          	auipc	a3,0x5
ffffffffc0201230:	60468693          	addi	a3,a3,1540 # ffffffffc0206830 <commands+0x930>
ffffffffc0201234:	00005617          	auipc	a2,0x5
ffffffffc0201238:	4e460613          	addi	a2,a2,1252 # ffffffffc0206718 <commands+0x818>
ffffffffc020123c:	0de00593          	li	a1,222
ffffffffc0201240:	00005517          	auipc	a0,0x5
ffffffffc0201244:	4f050513          	addi	a0,a0,1264 # ffffffffc0206730 <commands+0x830>
ffffffffc0201248:	a4aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020124c:	00005697          	auipc	a3,0x5
ffffffffc0201250:	66c68693          	addi	a3,a3,1644 # ffffffffc02068b8 <commands+0x9b8>
ffffffffc0201254:	00005617          	auipc	a2,0x5
ffffffffc0201258:	4c460613          	addi	a2,a2,1220 # ffffffffc0206718 <commands+0x818>
ffffffffc020125c:	0f700593          	li	a1,247
ffffffffc0201260:	00005517          	auipc	a0,0x5
ffffffffc0201264:	4d050513          	addi	a0,a0,1232 # ffffffffc0206730 <commands+0x830>
ffffffffc0201268:	a2aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020126c:	00005697          	auipc	a3,0x5
ffffffffc0201270:	4fc68693          	addi	a3,a3,1276 # ffffffffc0206768 <commands+0x868>
ffffffffc0201274:	00005617          	auipc	a2,0x5
ffffffffc0201278:	4a460613          	addi	a2,a2,1188 # ffffffffc0206718 <commands+0x818>
ffffffffc020127c:	0f000593          	li	a1,240
ffffffffc0201280:	00005517          	auipc	a0,0x5
ffffffffc0201284:	4b050513          	addi	a0,a0,1200 # ffffffffc0206730 <commands+0x830>
ffffffffc0201288:	a0aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc020128c:	00005697          	auipc	a3,0x5
ffffffffc0201290:	61c68693          	addi	a3,a3,1564 # ffffffffc02068a8 <commands+0x9a8>
ffffffffc0201294:	00005617          	auipc	a2,0x5
ffffffffc0201298:	48460613          	addi	a2,a2,1156 # ffffffffc0206718 <commands+0x818>
ffffffffc020129c:	0ee00593          	li	a1,238
ffffffffc02012a0:	00005517          	auipc	a0,0x5
ffffffffc02012a4:	49050513          	addi	a0,a0,1168 # ffffffffc0206730 <commands+0x830>
ffffffffc02012a8:	9eaff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012ac:	00005697          	auipc	a3,0x5
ffffffffc02012b0:	5e468693          	addi	a3,a3,1508 # ffffffffc0206890 <commands+0x990>
ffffffffc02012b4:	00005617          	auipc	a2,0x5
ffffffffc02012b8:	46460613          	addi	a2,a2,1124 # ffffffffc0206718 <commands+0x818>
ffffffffc02012bc:	0e900593          	li	a1,233
ffffffffc02012c0:	00005517          	auipc	a0,0x5
ffffffffc02012c4:	47050513          	addi	a0,a0,1136 # ffffffffc0206730 <commands+0x830>
ffffffffc02012c8:	9caff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012cc:	00005697          	auipc	a3,0x5
ffffffffc02012d0:	5a468693          	addi	a3,a3,1444 # ffffffffc0206870 <commands+0x970>
ffffffffc02012d4:	00005617          	auipc	a2,0x5
ffffffffc02012d8:	44460613          	addi	a2,a2,1092 # ffffffffc0206718 <commands+0x818>
ffffffffc02012dc:	0e000593          	li	a1,224
ffffffffc02012e0:	00005517          	auipc	a0,0x5
ffffffffc02012e4:	45050513          	addi	a0,a0,1104 # ffffffffc0206730 <commands+0x830>
ffffffffc02012e8:	9aaff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc02012ec:	00005697          	auipc	a3,0x5
ffffffffc02012f0:	61468693          	addi	a3,a3,1556 # ffffffffc0206900 <commands+0xa00>
ffffffffc02012f4:	00005617          	auipc	a2,0x5
ffffffffc02012f8:	42460613          	addi	a2,a2,1060 # ffffffffc0206718 <commands+0x818>
ffffffffc02012fc:	11800593          	li	a1,280
ffffffffc0201300:	00005517          	auipc	a0,0x5
ffffffffc0201304:	43050513          	addi	a0,a0,1072 # ffffffffc0206730 <commands+0x830>
ffffffffc0201308:	98aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc020130c:	00005697          	auipc	a3,0x5
ffffffffc0201310:	5e468693          	addi	a3,a3,1508 # ffffffffc02068f0 <commands+0x9f0>
ffffffffc0201314:	00005617          	auipc	a2,0x5
ffffffffc0201318:	40460613          	addi	a2,a2,1028 # ffffffffc0206718 <commands+0x818>
ffffffffc020131c:	0fd00593          	li	a1,253
ffffffffc0201320:	00005517          	auipc	a0,0x5
ffffffffc0201324:	41050513          	addi	a0,a0,1040 # ffffffffc0206730 <commands+0x830>
ffffffffc0201328:	96aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020132c:	00005697          	auipc	a3,0x5
ffffffffc0201330:	56468693          	addi	a3,a3,1380 # ffffffffc0206890 <commands+0x990>
ffffffffc0201334:	00005617          	auipc	a2,0x5
ffffffffc0201338:	3e460613          	addi	a2,a2,996 # ffffffffc0206718 <commands+0x818>
ffffffffc020133c:	0fb00593          	li	a1,251
ffffffffc0201340:	00005517          	auipc	a0,0x5
ffffffffc0201344:	3f050513          	addi	a0,a0,1008 # ffffffffc0206730 <commands+0x830>
ffffffffc0201348:	94aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020134c:	00005697          	auipc	a3,0x5
ffffffffc0201350:	58468693          	addi	a3,a3,1412 # ffffffffc02068d0 <commands+0x9d0>
ffffffffc0201354:	00005617          	auipc	a2,0x5
ffffffffc0201358:	3c460613          	addi	a2,a2,964 # ffffffffc0206718 <commands+0x818>
ffffffffc020135c:	0fa00593          	li	a1,250
ffffffffc0201360:	00005517          	auipc	a0,0x5
ffffffffc0201364:	3d050513          	addi	a0,a0,976 # ffffffffc0206730 <commands+0x830>
ffffffffc0201368:	92aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020136c:	00005697          	auipc	a3,0x5
ffffffffc0201370:	3fc68693          	addi	a3,a3,1020 # ffffffffc0206768 <commands+0x868>
ffffffffc0201374:	00005617          	auipc	a2,0x5
ffffffffc0201378:	3a460613          	addi	a2,a2,932 # ffffffffc0206718 <commands+0x818>
ffffffffc020137c:	0d700593          	li	a1,215
ffffffffc0201380:	00005517          	auipc	a0,0x5
ffffffffc0201384:	3b050513          	addi	a0,a0,944 # ffffffffc0206730 <commands+0x830>
ffffffffc0201388:	90aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020138c:	00005697          	auipc	a3,0x5
ffffffffc0201390:	50468693          	addi	a3,a3,1284 # ffffffffc0206890 <commands+0x990>
ffffffffc0201394:	00005617          	auipc	a2,0x5
ffffffffc0201398:	38460613          	addi	a2,a2,900 # ffffffffc0206718 <commands+0x818>
ffffffffc020139c:	0f400593          	li	a1,244
ffffffffc02013a0:	00005517          	auipc	a0,0x5
ffffffffc02013a4:	39050513          	addi	a0,a0,912 # ffffffffc0206730 <commands+0x830>
ffffffffc02013a8:	8eaff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013ac:	00005697          	auipc	a3,0x5
ffffffffc02013b0:	3fc68693          	addi	a3,a3,1020 # ffffffffc02067a8 <commands+0x8a8>
ffffffffc02013b4:	00005617          	auipc	a2,0x5
ffffffffc02013b8:	36460613          	addi	a2,a2,868 # ffffffffc0206718 <commands+0x818>
ffffffffc02013bc:	0f200593          	li	a1,242
ffffffffc02013c0:	00005517          	auipc	a0,0x5
ffffffffc02013c4:	37050513          	addi	a0,a0,880 # ffffffffc0206730 <commands+0x830>
ffffffffc02013c8:	8caff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013cc:	00005697          	auipc	a3,0x5
ffffffffc02013d0:	3bc68693          	addi	a3,a3,956 # ffffffffc0206788 <commands+0x888>
ffffffffc02013d4:	00005617          	auipc	a2,0x5
ffffffffc02013d8:	34460613          	addi	a2,a2,836 # ffffffffc0206718 <commands+0x818>
ffffffffc02013dc:	0f100593          	li	a1,241
ffffffffc02013e0:	00005517          	auipc	a0,0x5
ffffffffc02013e4:	35050513          	addi	a0,a0,848 # ffffffffc0206730 <commands+0x830>
ffffffffc02013e8:	8aaff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013ec:	00005697          	auipc	a3,0x5
ffffffffc02013f0:	3bc68693          	addi	a3,a3,956 # ffffffffc02067a8 <commands+0x8a8>
ffffffffc02013f4:	00005617          	auipc	a2,0x5
ffffffffc02013f8:	32460613          	addi	a2,a2,804 # ffffffffc0206718 <commands+0x818>
ffffffffc02013fc:	0d900593          	li	a1,217
ffffffffc0201400:	00005517          	auipc	a0,0x5
ffffffffc0201404:	33050513          	addi	a0,a0,816 # ffffffffc0206730 <commands+0x830>
ffffffffc0201408:	88aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc020140c:	00005697          	auipc	a3,0x5
ffffffffc0201410:	64468693          	addi	a3,a3,1604 # ffffffffc0206a50 <commands+0xb50>
ffffffffc0201414:	00005617          	auipc	a2,0x5
ffffffffc0201418:	30460613          	addi	a2,a2,772 # ffffffffc0206718 <commands+0x818>
ffffffffc020141c:	14600593          	li	a1,326
ffffffffc0201420:	00005517          	auipc	a0,0x5
ffffffffc0201424:	31050513          	addi	a0,a0,784 # ffffffffc0206730 <commands+0x830>
ffffffffc0201428:	86aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc020142c:	00005697          	auipc	a3,0x5
ffffffffc0201430:	4c468693          	addi	a3,a3,1220 # ffffffffc02068f0 <commands+0x9f0>
ffffffffc0201434:	00005617          	auipc	a2,0x5
ffffffffc0201438:	2e460613          	addi	a2,a2,740 # ffffffffc0206718 <commands+0x818>
ffffffffc020143c:	13a00593          	li	a1,314
ffffffffc0201440:	00005517          	auipc	a0,0x5
ffffffffc0201444:	2f050513          	addi	a0,a0,752 # ffffffffc0206730 <commands+0x830>
ffffffffc0201448:	84aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020144c:	00005697          	auipc	a3,0x5
ffffffffc0201450:	44468693          	addi	a3,a3,1092 # ffffffffc0206890 <commands+0x990>
ffffffffc0201454:	00005617          	auipc	a2,0x5
ffffffffc0201458:	2c460613          	addi	a2,a2,708 # ffffffffc0206718 <commands+0x818>
ffffffffc020145c:	13800593          	li	a1,312
ffffffffc0201460:	00005517          	auipc	a0,0x5
ffffffffc0201464:	2d050513          	addi	a0,a0,720 # ffffffffc0206730 <commands+0x830>
ffffffffc0201468:	82aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020146c:	00005697          	auipc	a3,0x5
ffffffffc0201470:	3e468693          	addi	a3,a3,996 # ffffffffc0206850 <commands+0x950>
ffffffffc0201474:	00005617          	auipc	a2,0x5
ffffffffc0201478:	2a460613          	addi	a2,a2,676 # ffffffffc0206718 <commands+0x818>
ffffffffc020147c:	0df00593          	li	a1,223
ffffffffc0201480:	00005517          	auipc	a0,0x5
ffffffffc0201484:	2b050513          	addi	a0,a0,688 # ffffffffc0206730 <commands+0x830>
ffffffffc0201488:	80aff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020148c:	00005697          	auipc	a3,0x5
ffffffffc0201490:	58468693          	addi	a3,a3,1412 # ffffffffc0206a10 <commands+0xb10>
ffffffffc0201494:	00005617          	auipc	a2,0x5
ffffffffc0201498:	28460613          	addi	a2,a2,644 # ffffffffc0206718 <commands+0x818>
ffffffffc020149c:	13200593          	li	a1,306
ffffffffc02014a0:	00005517          	auipc	a0,0x5
ffffffffc02014a4:	29050513          	addi	a0,a0,656 # ffffffffc0206730 <commands+0x830>
ffffffffc02014a8:	febfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02014ac:	00005697          	auipc	a3,0x5
ffffffffc02014b0:	54468693          	addi	a3,a3,1348 # ffffffffc02069f0 <commands+0xaf0>
ffffffffc02014b4:	00005617          	auipc	a2,0x5
ffffffffc02014b8:	26460613          	addi	a2,a2,612 # ffffffffc0206718 <commands+0x818>
ffffffffc02014bc:	13000593          	li	a1,304
ffffffffc02014c0:	00005517          	auipc	a0,0x5
ffffffffc02014c4:	27050513          	addi	a0,a0,624 # ffffffffc0206730 <commands+0x830>
ffffffffc02014c8:	fcbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	4fc68693          	addi	a3,a3,1276 # ffffffffc02069c8 <commands+0xac8>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	24460613          	addi	a2,a2,580 # ffffffffc0206718 <commands+0x818>
ffffffffc02014dc:	12e00593          	li	a1,302
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	25050513          	addi	a0,a0,592 # ffffffffc0206730 <commands+0x830>
ffffffffc02014e8:	fabfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	4b468693          	addi	a3,a3,1204 # ffffffffc02069a0 <commands+0xaa0>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	22460613          	addi	a2,a2,548 # ffffffffc0206718 <commands+0x818>
ffffffffc02014fc:	12d00593          	li	a1,301
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	23050513          	addi	a0,a0,560 # ffffffffc0206730 <commands+0x830>
ffffffffc0201508:	f8bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	48468693          	addi	a3,a3,1156 # ffffffffc0206990 <commands+0xa90>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	20460613          	addi	a2,a2,516 # ffffffffc0206718 <commands+0x818>
ffffffffc020151c:	12800593          	li	a1,296
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	21050513          	addi	a0,a0,528 # ffffffffc0206730 <commands+0x830>
ffffffffc0201528:	f6bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	36468693          	addi	a3,a3,868 # ffffffffc0206890 <commands+0x990>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	1e460613          	addi	a2,a2,484 # ffffffffc0206718 <commands+0x818>
ffffffffc020153c:	12700593          	li	a1,295
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	1f050513          	addi	a0,a0,496 # ffffffffc0206730 <commands+0x830>
ffffffffc0201548:	f4bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	42468693          	addi	a3,a3,1060 # ffffffffc0206970 <commands+0xa70>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	1c460613          	addi	a2,a2,452 # ffffffffc0206718 <commands+0x818>
ffffffffc020155c:	12600593          	li	a1,294
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	1d050513          	addi	a0,a0,464 # ffffffffc0206730 <commands+0x830>
ffffffffc0201568:	f2bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	3d468693          	addi	a3,a3,980 # ffffffffc0206940 <commands+0xa40>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	1a460613          	addi	a2,a2,420 # ffffffffc0206718 <commands+0x818>
ffffffffc020157c:	12500593          	li	a1,293
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	1b050513          	addi	a0,a0,432 # ffffffffc0206730 <commands+0x830>
ffffffffc0201588:	f0bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	39c68693          	addi	a3,a3,924 # ffffffffc0206928 <commands+0xa28>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	18460613          	addi	a2,a2,388 # ffffffffc0206718 <commands+0x818>
ffffffffc020159c:	12400593          	li	a1,292
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	19050513          	addi	a0,a0,400 # ffffffffc0206730 <commands+0x830>
ffffffffc02015a8:	eebfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	2e468693          	addi	a3,a3,740 # ffffffffc0206890 <commands+0x990>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	16460613          	addi	a2,a2,356 # ffffffffc0206718 <commands+0x818>
ffffffffc02015bc:	11e00593          	li	a1,286
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	17050513          	addi	a0,a0,368 # ffffffffc0206730 <commands+0x830>
ffffffffc02015c8:	ecbfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	34468693          	addi	a3,a3,836 # ffffffffc0206910 <commands+0xa10>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	14460613          	addi	a2,a2,324 # ffffffffc0206718 <commands+0x818>
ffffffffc02015dc:	11900593          	li	a1,281
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	15050513          	addi	a0,a0,336 # ffffffffc0206730 <commands+0x830>
ffffffffc02015e8:	eabfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	44468693          	addi	a3,a3,1092 # ffffffffc0206a30 <commands+0xb30>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	12460613          	addi	a2,a2,292 # ffffffffc0206718 <commands+0x818>
ffffffffc02015fc:	13700593          	li	a1,311
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	13050513          	addi	a0,a0,304 # ffffffffc0206730 <commands+0x830>
ffffffffc0201608:	e8bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	45468693          	addi	a3,a3,1108 # ffffffffc0206a60 <commands+0xb60>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	10460613          	addi	a2,a2,260 # ffffffffc0206718 <commands+0x818>
ffffffffc020161c:	14700593          	li	a1,327
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	11050513          	addi	a0,a0,272 # ffffffffc0206730 <commands+0x830>
ffffffffc0201628:	e6bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	11c68693          	addi	a3,a3,284 # ffffffffc0206748 <commands+0x848>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	0e460613          	addi	a2,a2,228 # ffffffffc0206718 <commands+0x818>
ffffffffc020163c:	11300593          	li	a1,275
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	0f050513          	addi	a0,a0,240 # ffffffffc0206730 <commands+0x830>
ffffffffc0201648:	e4bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	13c68693          	addi	a3,a3,316 # ffffffffc0206788 <commands+0x888>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	0c460613          	addi	a2,a2,196 # ffffffffc0206718 <commands+0x818>
ffffffffc020165c:	0d800593          	li	a1,216
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	0d050513          	addi	a0,a0,208 # ffffffffc0206730 <commands+0x830>
ffffffffc0201668:	e2bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020166c <default_free_pages>:
{
ffffffffc020166c:	1141                	addi	sp,sp,-16
ffffffffc020166e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201670:	14058463          	beqz	a1,ffffffffc02017b8 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201674:	00659693          	slli	a3,a1,0x6
ffffffffc0201678:	96aa                	add	a3,a3,a0
ffffffffc020167a:	87aa                	mv	a5,a0
ffffffffc020167c:	02d50263          	beq	a0,a3,ffffffffc02016a0 <default_free_pages+0x34>
ffffffffc0201680:	6798                	ld	a4,8(a5)
ffffffffc0201682:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201684:	10071a63          	bnez	a4,ffffffffc0201798 <default_free_pages+0x12c>
ffffffffc0201688:	6798                	ld	a4,8(a5)
ffffffffc020168a:	8b09                	andi	a4,a4,2
ffffffffc020168c:	10071663          	bnez	a4,ffffffffc0201798 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201690:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201694:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201698:	04078793          	addi	a5,a5,64
ffffffffc020169c:	fed792e3          	bne	a5,a3,ffffffffc0201680 <default_free_pages+0x14>
    base->property = n;
ffffffffc02016a0:	2581                	sext.w	a1,a1
ffffffffc02016a2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02016a4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016a8:	4789                	li	a5,2
ffffffffc02016aa:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02016ae:	000cc697          	auipc	a3,0xcc
ffffffffc02016b2:	e0a68693          	addi	a3,a3,-502 # ffffffffc02cd4b8 <free_area>
ffffffffc02016b6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016b8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016ba:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016be:	9db9                	addw	a1,a1,a4
ffffffffc02016c0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02016c2:	0ad78463          	beq	a5,a3,ffffffffc020176a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02016c6:	fe878713          	addi	a4,a5,-24
ffffffffc02016ca:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02016ce:	4581                	li	a1,0
            if (base < page)
ffffffffc02016d0:	00e56a63          	bltu	a0,a4,ffffffffc02016e4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02016d4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02016d6:	04d70c63          	beq	a4,a3,ffffffffc020172e <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02016da:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02016dc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02016e0:	fee57ae3          	bgeu	a0,a4,ffffffffc02016d4 <default_free_pages+0x68>
ffffffffc02016e4:	c199                	beqz	a1,ffffffffc02016ea <default_free_pages+0x7e>
ffffffffc02016e6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016ea:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016ec:	e390                	sd	a2,0(a5)
ffffffffc02016ee:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016f0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016f2:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02016f4:	00d70d63          	beq	a4,a3,ffffffffc020170e <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02016f8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016fc:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201700:	02059813          	slli	a6,a1,0x20
ffffffffc0201704:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201708:	97b2                	add	a5,a5,a2
ffffffffc020170a:	02f50c63          	beq	a0,a5,ffffffffc0201742 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020170e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201710:	00d78c63          	beq	a5,a3,ffffffffc0201728 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201714:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201716:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020171a:	02061593          	slli	a1,a2,0x20
ffffffffc020171e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201722:	972a                	add	a4,a4,a0
ffffffffc0201724:	04e68a63          	beq	a3,a4,ffffffffc0201778 <default_free_pages+0x10c>
}
ffffffffc0201728:	60a2                	ld	ra,8(sp)
ffffffffc020172a:	0141                	addi	sp,sp,16
ffffffffc020172c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020172e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201730:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201732:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201734:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201736:	02d70763          	beq	a4,a3,ffffffffc0201764 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020173a:	8832                	mv	a6,a2
ffffffffc020173c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020173e:	87ba                	mv	a5,a4
ffffffffc0201740:	bf71                	j	ffffffffc02016dc <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201742:	491c                	lw	a5,16(a0)
ffffffffc0201744:	9dbd                	addw	a1,a1,a5
ffffffffc0201746:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020174a:	57f5                	li	a5,-3
ffffffffc020174c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201750:	01853803          	ld	a6,24(a0)
ffffffffc0201754:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201756:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201758:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc020175c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020175e:	0105b023          	sd	a6,0(a1)
ffffffffc0201762:	b77d                	j	ffffffffc0201710 <default_free_pages+0xa4>
ffffffffc0201764:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201766:	873e                	mv	a4,a5
ffffffffc0201768:	bf41                	j	ffffffffc02016f8 <default_free_pages+0x8c>
}
ffffffffc020176a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020176c:	e390                	sd	a2,0(a5)
ffffffffc020176e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201770:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201772:	ed1c                	sd	a5,24(a0)
ffffffffc0201774:	0141                	addi	sp,sp,16
ffffffffc0201776:	8082                	ret
            base->property += p->property;
ffffffffc0201778:	ff87a703          	lw	a4,-8(a5)
ffffffffc020177c:	ff078693          	addi	a3,a5,-16
ffffffffc0201780:	9e39                	addw	a2,a2,a4
ffffffffc0201782:	c910                	sw	a2,16(a0)
ffffffffc0201784:	5775                	li	a4,-3
ffffffffc0201786:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020178a:	6398                	ld	a4,0(a5)
ffffffffc020178c:	679c                	ld	a5,8(a5)
}
ffffffffc020178e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201790:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201792:	e398                	sd	a4,0(a5)
ffffffffc0201794:	0141                	addi	sp,sp,16
ffffffffc0201796:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201798:	00005697          	auipc	a3,0x5
ffffffffc020179c:	2e068693          	addi	a3,a3,736 # ffffffffc0206a78 <commands+0xb78>
ffffffffc02017a0:	00005617          	auipc	a2,0x5
ffffffffc02017a4:	f7860613          	addi	a2,a2,-136 # ffffffffc0206718 <commands+0x818>
ffffffffc02017a8:	09400593          	li	a1,148
ffffffffc02017ac:	00005517          	auipc	a0,0x5
ffffffffc02017b0:	f8450513          	addi	a0,a0,-124 # ffffffffc0206730 <commands+0x830>
ffffffffc02017b4:	cdffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc02017b8:	00005697          	auipc	a3,0x5
ffffffffc02017bc:	2b868693          	addi	a3,a3,696 # ffffffffc0206a70 <commands+0xb70>
ffffffffc02017c0:	00005617          	auipc	a2,0x5
ffffffffc02017c4:	f5860613          	addi	a2,a2,-168 # ffffffffc0206718 <commands+0x818>
ffffffffc02017c8:	09000593          	li	a1,144
ffffffffc02017cc:	00005517          	auipc	a0,0x5
ffffffffc02017d0:	f6450513          	addi	a0,a0,-156 # ffffffffc0206730 <commands+0x830>
ffffffffc02017d4:	cbffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02017d8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017d8:	c941                	beqz	a0,ffffffffc0201868 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02017da:	000cc597          	auipc	a1,0xcc
ffffffffc02017de:	cde58593          	addi	a1,a1,-802 # ffffffffc02cd4b8 <free_area>
ffffffffc02017e2:	0105a803          	lw	a6,16(a1)
ffffffffc02017e6:	872a                	mv	a4,a0
ffffffffc02017e8:	02081793          	slli	a5,a6,0x20
ffffffffc02017ec:	9381                	srli	a5,a5,0x20
ffffffffc02017ee:	00a7ee63          	bltu	a5,a0,ffffffffc020180a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017f2:	87ae                	mv	a5,a1
ffffffffc02017f4:	a801                	j	ffffffffc0201804 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02017f6:	ff87a683          	lw	a3,-8(a5)
ffffffffc02017fa:	02069613          	slli	a2,a3,0x20
ffffffffc02017fe:	9201                	srli	a2,a2,0x20
ffffffffc0201800:	00e67763          	bgeu	a2,a4,ffffffffc020180e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201804:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201806:	feb798e3          	bne	a5,a1,ffffffffc02017f6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020180a:	4501                	li	a0,0
}
ffffffffc020180c:	8082                	ret
    return listelm->prev;
ffffffffc020180e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201812:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201816:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020181a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020181e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201822:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201826:	02c77863          	bgeu	a4,a2,ffffffffc0201856 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020182a:	071a                	slli	a4,a4,0x6
ffffffffc020182c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020182e:	41c686bb          	subw	a3,a3,t3
ffffffffc0201832:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201834:	00870613          	addi	a2,a4,8
ffffffffc0201838:	4689                	li	a3,2
ffffffffc020183a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020183e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201842:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201846:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020184a:	e290                	sd	a2,0(a3)
ffffffffc020184c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201850:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201852:	01173c23          	sd	a7,24(a4)
ffffffffc0201856:	41c8083b          	subw	a6,a6,t3
ffffffffc020185a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020185e:	5775                	li	a4,-3
ffffffffc0201860:	17c1                	addi	a5,a5,-16
ffffffffc0201862:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201866:	8082                	ret
{
ffffffffc0201868:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020186a:	00005697          	auipc	a3,0x5
ffffffffc020186e:	20668693          	addi	a3,a3,518 # ffffffffc0206a70 <commands+0xb70>
ffffffffc0201872:	00005617          	auipc	a2,0x5
ffffffffc0201876:	ea660613          	addi	a2,a2,-346 # ffffffffc0206718 <commands+0x818>
ffffffffc020187a:	06c00593          	li	a1,108
ffffffffc020187e:	00005517          	auipc	a0,0x5
ffffffffc0201882:	eb250513          	addi	a0,a0,-334 # ffffffffc0206730 <commands+0x830>
{
ffffffffc0201886:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201888:	c0bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020188c <default_init_memmap>:
{
ffffffffc020188c:	1141                	addi	sp,sp,-16
ffffffffc020188e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201890:	c5f1                	beqz	a1,ffffffffc020195c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201892:	00659693          	slli	a3,a1,0x6
ffffffffc0201896:	96aa                	add	a3,a3,a0
ffffffffc0201898:	87aa                	mv	a5,a0
ffffffffc020189a:	00d50f63          	beq	a0,a3,ffffffffc02018b8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020189e:	6798                	ld	a4,8(a5)
ffffffffc02018a0:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02018a2:	cf49                	beqz	a4,ffffffffc020193c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02018a4:	0007a823          	sw	zero,16(a5)
ffffffffc02018a8:	0007b423          	sd	zero,8(a5)
ffffffffc02018ac:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018b0:	04078793          	addi	a5,a5,64
ffffffffc02018b4:	fed795e3          	bne	a5,a3,ffffffffc020189e <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018b8:	2581                	sext.w	a1,a1
ffffffffc02018ba:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018bc:	4789                	li	a5,2
ffffffffc02018be:	00850713          	addi	a4,a0,8
ffffffffc02018c2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018c6:	000cc697          	auipc	a3,0xcc
ffffffffc02018ca:	bf268693          	addi	a3,a3,-1038 # ffffffffc02cd4b8 <free_area>
ffffffffc02018ce:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018d0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018d2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018d6:	9db9                	addw	a1,a1,a4
ffffffffc02018d8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02018da:	04d78a63          	beq	a5,a3,ffffffffc020192e <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02018de:	fe878713          	addi	a4,a5,-24
ffffffffc02018e2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02018e6:	4581                	li	a1,0
            if (base < page)
ffffffffc02018e8:	00e56a63          	bltu	a0,a4,ffffffffc02018fc <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02018ec:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02018ee:	02d70263          	beq	a4,a3,ffffffffc0201912 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02018f2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02018f4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02018f8:	fee57ae3          	bgeu	a0,a4,ffffffffc02018ec <default_init_memmap+0x60>
ffffffffc02018fc:	c199                	beqz	a1,ffffffffc0201902 <default_init_memmap+0x76>
ffffffffc02018fe:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201902:	6398                	ld	a4,0(a5)
}
ffffffffc0201904:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201906:	e390                	sd	a2,0(a5)
ffffffffc0201908:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020190a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020190c:	ed18                	sd	a4,24(a0)
ffffffffc020190e:	0141                	addi	sp,sp,16
ffffffffc0201910:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201912:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201914:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201916:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201918:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020191a:	00d70663          	beq	a4,a3,ffffffffc0201926 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc020191e:	8832                	mv	a6,a2
ffffffffc0201920:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201922:	87ba                	mv	a5,a4
ffffffffc0201924:	bfc1                	j	ffffffffc02018f4 <default_init_memmap+0x68>
}
ffffffffc0201926:	60a2                	ld	ra,8(sp)
ffffffffc0201928:	e290                	sd	a2,0(a3)
ffffffffc020192a:	0141                	addi	sp,sp,16
ffffffffc020192c:	8082                	ret
ffffffffc020192e:	60a2                	ld	ra,8(sp)
ffffffffc0201930:	e390                	sd	a2,0(a5)
ffffffffc0201932:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201934:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201936:	ed1c                	sd	a5,24(a0)
ffffffffc0201938:	0141                	addi	sp,sp,16
ffffffffc020193a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020193c:	00005697          	auipc	a3,0x5
ffffffffc0201940:	16468693          	addi	a3,a3,356 # ffffffffc0206aa0 <commands+0xba0>
ffffffffc0201944:	00005617          	auipc	a2,0x5
ffffffffc0201948:	dd460613          	addi	a2,a2,-556 # ffffffffc0206718 <commands+0x818>
ffffffffc020194c:	04b00593          	li	a1,75
ffffffffc0201950:	00005517          	auipc	a0,0x5
ffffffffc0201954:	de050513          	addi	a0,a0,-544 # ffffffffc0206730 <commands+0x830>
ffffffffc0201958:	b3bfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc020195c:	00005697          	auipc	a3,0x5
ffffffffc0201960:	11468693          	addi	a3,a3,276 # ffffffffc0206a70 <commands+0xb70>
ffffffffc0201964:	00005617          	auipc	a2,0x5
ffffffffc0201968:	db460613          	addi	a2,a2,-588 # ffffffffc0206718 <commands+0x818>
ffffffffc020196c:	04700593          	li	a1,71
ffffffffc0201970:	00005517          	auipc	a0,0x5
ffffffffc0201974:	dc050513          	addi	a0,a0,-576 # ffffffffc0206730 <commands+0x830>
ffffffffc0201978:	b1bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020197c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc020197c:	c94d                	beqz	a0,ffffffffc0201a2e <slob_free+0xb2>
{
ffffffffc020197e:	1141                	addi	sp,sp,-16
ffffffffc0201980:	e022                	sd	s0,0(sp)
ffffffffc0201982:	e406                	sd	ra,8(sp)
ffffffffc0201984:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201986:	e9c1                	bnez	a1,ffffffffc0201a16 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201988:	100027f3          	csrr	a5,sstatus
ffffffffc020198c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020198e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201990:	ebd9                	bnez	a5,ffffffffc0201a26 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201992:	000cb617          	auipc	a2,0xcb
ffffffffc0201996:	71660613          	addi	a2,a2,1814 # ffffffffc02cd0a8 <slobfree>
ffffffffc020199a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020199c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020199e:	679c                	ld	a5,8(a5)
ffffffffc02019a0:	02877a63          	bgeu	a4,s0,ffffffffc02019d4 <slob_free+0x58>
ffffffffc02019a4:	00f46463          	bltu	s0,a5,ffffffffc02019ac <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019a8:	fef76ae3          	bltu	a4,a5,ffffffffc020199c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02019ac:	400c                	lw	a1,0(s0)
ffffffffc02019ae:	00459693          	slli	a3,a1,0x4
ffffffffc02019b2:	96a2                	add	a3,a3,s0
ffffffffc02019b4:	02d78a63          	beq	a5,a3,ffffffffc02019e8 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019b8:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02019ba:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019bc:	00469793          	slli	a5,a3,0x4
ffffffffc02019c0:	97ba                	add	a5,a5,a4
ffffffffc02019c2:	02f40e63          	beq	s0,a5,ffffffffc02019fe <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02019c6:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02019c8:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc02019ca:	e129                	bnez	a0,ffffffffc0201a0c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02019cc:	60a2                	ld	ra,8(sp)
ffffffffc02019ce:	6402                	ld	s0,0(sp)
ffffffffc02019d0:	0141                	addi	sp,sp,16
ffffffffc02019d2:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019d4:	fcf764e3          	bltu	a4,a5,ffffffffc020199c <slob_free+0x20>
ffffffffc02019d8:	fcf472e3          	bgeu	s0,a5,ffffffffc020199c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02019dc:	400c                	lw	a1,0(s0)
ffffffffc02019de:	00459693          	slli	a3,a1,0x4
ffffffffc02019e2:	96a2                	add	a3,a3,s0
ffffffffc02019e4:	fcd79ae3          	bne	a5,a3,ffffffffc02019b8 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02019e8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02019ea:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02019ec:	9db5                	addw	a1,a1,a3
ffffffffc02019ee:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02019f0:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02019f2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019f4:	00469793          	slli	a5,a3,0x4
ffffffffc02019f8:	97ba                	add	a5,a5,a4
ffffffffc02019fa:	fcf416e3          	bne	s0,a5,ffffffffc02019c6 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc02019fe:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201a00:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201a02:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201a04:	9ebd                	addw	a3,a3,a5
ffffffffc0201a06:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201a08:	e70c                	sd	a1,8(a4)
ffffffffc0201a0a:	d169                	beqz	a0,ffffffffc02019cc <slob_free+0x50>
}
ffffffffc0201a0c:	6402                	ld	s0,0(sp)
ffffffffc0201a0e:	60a2                	ld	ra,8(sp)
ffffffffc0201a10:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201a12:	f97fe06f          	j	ffffffffc02009a8 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201a16:	25bd                	addiw	a1,a1,15
ffffffffc0201a18:	8191                	srli	a1,a1,0x4
ffffffffc0201a1a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a1c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a20:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a22:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a24:	d7bd                	beqz	a5,ffffffffc0201992 <slob_free+0x16>
        intr_disable();
ffffffffc0201a26:	f89fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201a2a:	4505                	li	a0,1
ffffffffc0201a2c:	b79d                	j	ffffffffc0201992 <slob_free+0x16>
ffffffffc0201a2e:	8082                	ret

ffffffffc0201a30 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a30:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a32:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a34:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a38:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a3a:	352000ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
	if (!page)
ffffffffc0201a3e:	c91d                	beqz	a0,ffffffffc0201a74 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a40:	000d0697          	auipc	a3,0xd0
ffffffffc0201a44:	b106b683          	ld	a3,-1264(a3) # ffffffffc02d1550 <pages>
ffffffffc0201a48:	8d15                	sub	a0,a0,a3
ffffffffc0201a4a:	8519                	srai	a0,a0,0x6
ffffffffc0201a4c:	00007697          	auipc	a3,0x7
ffffffffc0201a50:	b246b683          	ld	a3,-1244(a3) # ffffffffc0208570 <nbase>
ffffffffc0201a54:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201a56:	00c51793          	slli	a5,a0,0xc
ffffffffc0201a5a:	83b1                	srli	a5,a5,0xc
ffffffffc0201a5c:	000d0717          	auipc	a4,0xd0
ffffffffc0201a60:	aec73703          	ld	a4,-1300(a4) # ffffffffc02d1548 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201a64:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201a66:	00e7fa63          	bgeu	a5,a4,ffffffffc0201a7a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201a6a:	000d0697          	auipc	a3,0xd0
ffffffffc0201a6e:	af66b683          	ld	a3,-1290(a3) # ffffffffc02d1560 <va_pa_offset>
ffffffffc0201a72:	9536                	add	a0,a0,a3
}
ffffffffc0201a74:	60a2                	ld	ra,8(sp)
ffffffffc0201a76:	0141                	addi	sp,sp,16
ffffffffc0201a78:	8082                	ret
ffffffffc0201a7a:	86aa                	mv	a3,a0
ffffffffc0201a7c:	00005617          	auipc	a2,0x5
ffffffffc0201a80:	08460613          	addi	a2,a2,132 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0201a84:	07100593          	li	a1,113
ffffffffc0201a88:	00005517          	auipc	a0,0x5
ffffffffc0201a8c:	0a050513          	addi	a0,a0,160 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0201a90:	a03fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201a94 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201a94:	1101                	addi	sp,sp,-32
ffffffffc0201a96:	ec06                	sd	ra,24(sp)
ffffffffc0201a98:	e822                	sd	s0,16(sp)
ffffffffc0201a9a:	e426                	sd	s1,8(sp)
ffffffffc0201a9c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a9e:	01050713          	addi	a4,a0,16
ffffffffc0201aa2:	6785                	lui	a5,0x1
ffffffffc0201aa4:	0cf77363          	bgeu	a4,a5,ffffffffc0201b6a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201aa8:	00f50493          	addi	s1,a0,15
ffffffffc0201aac:	8091                	srli	s1,s1,0x4
ffffffffc0201aae:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ab0:	10002673          	csrr	a2,sstatus
ffffffffc0201ab4:	8a09                	andi	a2,a2,2
ffffffffc0201ab6:	e25d                	bnez	a2,ffffffffc0201b5c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201ab8:	000cb917          	auipc	s2,0xcb
ffffffffc0201abc:	5f090913          	addi	s2,s2,1520 # ffffffffc02cd0a8 <slobfree>
ffffffffc0201ac0:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ac4:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201ac6:	4398                	lw	a4,0(a5)
ffffffffc0201ac8:	08975e63          	bge	a4,s1,ffffffffc0201b64 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201acc:	00f68b63          	beq	a3,a5,ffffffffc0201ae2 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ad0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201ad2:	4018                	lw	a4,0(s0)
ffffffffc0201ad4:	02975a63          	bge	a4,s1,ffffffffc0201b08 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201ad8:	00093683          	ld	a3,0(s2)
ffffffffc0201adc:	87a2                	mv	a5,s0
ffffffffc0201ade:	fef699e3          	bne	a3,a5,ffffffffc0201ad0 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201ae2:	ee31                	bnez	a2,ffffffffc0201b3e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201ae4:	4501                	li	a0,0
ffffffffc0201ae6:	f4bff0ef          	jal	ra,ffffffffc0201a30 <__slob_get_free_pages.constprop.0>
ffffffffc0201aea:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201aec:	cd05                	beqz	a0,ffffffffc0201b24 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201aee:	6585                	lui	a1,0x1
ffffffffc0201af0:	e8dff0ef          	jal	ra,ffffffffc020197c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201af4:	10002673          	csrr	a2,sstatus
ffffffffc0201af8:	8a09                	andi	a2,a2,2
ffffffffc0201afa:	ee05                	bnez	a2,ffffffffc0201b32 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201afc:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b00:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201b02:	4018                	lw	a4,0(s0)
ffffffffc0201b04:	fc974ae3          	blt	a4,s1,ffffffffc0201ad8 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201b08:	04e48763          	beq	s1,a4,ffffffffc0201b56 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201b0c:	00449693          	slli	a3,s1,0x4
ffffffffc0201b10:	96a2                	add	a3,a3,s0
ffffffffc0201b12:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201b14:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201b16:	9f05                	subw	a4,a4,s1
ffffffffc0201b18:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201b1a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201b1c:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201b1e:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201b22:	e20d                	bnez	a2,ffffffffc0201b44 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201b24:	60e2                	ld	ra,24(sp)
ffffffffc0201b26:	8522                	mv	a0,s0
ffffffffc0201b28:	6442                	ld	s0,16(sp)
ffffffffc0201b2a:	64a2                	ld	s1,8(sp)
ffffffffc0201b2c:	6902                	ld	s2,0(sp)
ffffffffc0201b2e:	6105                	addi	sp,sp,32
ffffffffc0201b30:	8082                	ret
        intr_disable();
ffffffffc0201b32:	e7dfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
			cur = slobfree;
ffffffffc0201b36:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201b3a:	4605                	li	a2,1
ffffffffc0201b3c:	b7d1                	j	ffffffffc0201b00 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201b3e:	e6bfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201b42:	b74d                	j	ffffffffc0201ae4 <slob_alloc.constprop.0+0x50>
ffffffffc0201b44:	e65fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc0201b48:	60e2                	ld	ra,24(sp)
ffffffffc0201b4a:	8522                	mv	a0,s0
ffffffffc0201b4c:	6442                	ld	s0,16(sp)
ffffffffc0201b4e:	64a2                	ld	s1,8(sp)
ffffffffc0201b50:	6902                	ld	s2,0(sp)
ffffffffc0201b52:	6105                	addi	sp,sp,32
ffffffffc0201b54:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201b56:	6418                	ld	a4,8(s0)
ffffffffc0201b58:	e798                	sd	a4,8(a5)
ffffffffc0201b5a:	b7d1                	j	ffffffffc0201b1e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201b5c:	e53fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201b60:	4605                	li	a2,1
ffffffffc0201b62:	bf99                	j	ffffffffc0201ab8 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201b64:	843e                	mv	s0,a5
ffffffffc0201b66:	87b6                	mv	a5,a3
ffffffffc0201b68:	b745                	j	ffffffffc0201b08 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b6a:	00005697          	auipc	a3,0x5
ffffffffc0201b6e:	fce68693          	addi	a3,a3,-50 # ffffffffc0206b38 <default_pmm_manager+0x70>
ffffffffc0201b72:	00005617          	auipc	a2,0x5
ffffffffc0201b76:	ba660613          	addi	a2,a2,-1114 # ffffffffc0206718 <commands+0x818>
ffffffffc0201b7a:	06300593          	li	a1,99
ffffffffc0201b7e:	00005517          	auipc	a0,0x5
ffffffffc0201b82:	fda50513          	addi	a0,a0,-38 # ffffffffc0206b58 <default_pmm_manager+0x90>
ffffffffc0201b86:	90dfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201b8a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201b8a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201b8c:	00005517          	auipc	a0,0x5
ffffffffc0201b90:	fe450513          	addi	a0,a0,-28 # ffffffffc0206b70 <default_pmm_manager+0xa8>
{
ffffffffc0201b94:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201b96:	e02fe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201b9a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b9c:	00005517          	auipc	a0,0x5
ffffffffc0201ba0:	fec50513          	addi	a0,a0,-20 # ffffffffc0206b88 <default_pmm_manager+0xc0>
}
ffffffffc0201ba4:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ba6:	df2fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201baa <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201baa:	4501                	li	a0,0
ffffffffc0201bac:	8082                	ret

ffffffffc0201bae <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201bae:	1101                	addi	sp,sp,-32
ffffffffc0201bb0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bb2:	6905                	lui	s2,0x1
{
ffffffffc0201bb4:	e822                	sd	s0,16(sp)
ffffffffc0201bb6:	ec06                	sd	ra,24(sp)
ffffffffc0201bb8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bba:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f41>
{
ffffffffc0201bbe:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bc0:	04a7f963          	bgeu	a5,a0,ffffffffc0201c12 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201bc4:	4561                	li	a0,24
ffffffffc0201bc6:	ecfff0ef          	jal	ra,ffffffffc0201a94 <slob_alloc.constprop.0>
ffffffffc0201bca:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201bcc:	c929                	beqz	a0,ffffffffc0201c1e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201bce:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201bd2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201bd4:	00f95763          	bge	s2,a5,ffffffffc0201be2 <kmalloc+0x34>
ffffffffc0201bd8:	6705                	lui	a4,0x1
ffffffffc0201bda:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201bdc:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201bde:	fef74ee3          	blt	a4,a5,ffffffffc0201bda <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201be2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201be4:	e4dff0ef          	jal	ra,ffffffffc0201a30 <__slob_get_free_pages.constprop.0>
ffffffffc0201be8:	e488                	sd	a0,8(s1)
ffffffffc0201bea:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201bec:	c525                	beqz	a0,ffffffffc0201c54 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bee:	100027f3          	csrr	a5,sstatus
ffffffffc0201bf2:	8b89                	andi	a5,a5,2
ffffffffc0201bf4:	ef8d                	bnez	a5,ffffffffc0201c2e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201bf6:	000d0797          	auipc	a5,0xd0
ffffffffc0201bfa:	93a78793          	addi	a5,a5,-1734 # ffffffffc02d1530 <bigblocks>
ffffffffc0201bfe:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c00:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c02:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201c04:	60e2                	ld	ra,24(sp)
ffffffffc0201c06:	8522                	mv	a0,s0
ffffffffc0201c08:	6442                	ld	s0,16(sp)
ffffffffc0201c0a:	64a2                	ld	s1,8(sp)
ffffffffc0201c0c:	6902                	ld	s2,0(sp)
ffffffffc0201c0e:	6105                	addi	sp,sp,32
ffffffffc0201c10:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c12:	0541                	addi	a0,a0,16
ffffffffc0201c14:	e81ff0ef          	jal	ra,ffffffffc0201a94 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c18:	01050413          	addi	s0,a0,16
ffffffffc0201c1c:	f565                	bnez	a0,ffffffffc0201c04 <kmalloc+0x56>
ffffffffc0201c1e:	4401                	li	s0,0
}
ffffffffc0201c20:	60e2                	ld	ra,24(sp)
ffffffffc0201c22:	8522                	mv	a0,s0
ffffffffc0201c24:	6442                	ld	s0,16(sp)
ffffffffc0201c26:	64a2                	ld	s1,8(sp)
ffffffffc0201c28:	6902                	ld	s2,0(sp)
ffffffffc0201c2a:	6105                	addi	sp,sp,32
ffffffffc0201c2c:	8082                	ret
        intr_disable();
ffffffffc0201c2e:	d81fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c32:	000d0797          	auipc	a5,0xd0
ffffffffc0201c36:	8fe78793          	addi	a5,a5,-1794 # ffffffffc02d1530 <bigblocks>
ffffffffc0201c3a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c3c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c3e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201c40:	d69fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
		return bb->pages;
ffffffffc0201c44:	6480                	ld	s0,8(s1)
}
ffffffffc0201c46:	60e2                	ld	ra,24(sp)
ffffffffc0201c48:	64a2                	ld	s1,8(sp)
ffffffffc0201c4a:	8522                	mv	a0,s0
ffffffffc0201c4c:	6442                	ld	s0,16(sp)
ffffffffc0201c4e:	6902                	ld	s2,0(sp)
ffffffffc0201c50:	6105                	addi	sp,sp,32
ffffffffc0201c52:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c54:	45e1                	li	a1,24
ffffffffc0201c56:	8526                	mv	a0,s1
ffffffffc0201c58:	d25ff0ef          	jal	ra,ffffffffc020197c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201c5c:	b765                	j	ffffffffc0201c04 <kmalloc+0x56>

ffffffffc0201c5e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c5e:	c169                	beqz	a0,ffffffffc0201d20 <kfree+0xc2>
{
ffffffffc0201c60:	1101                	addi	sp,sp,-32
ffffffffc0201c62:	e822                	sd	s0,16(sp)
ffffffffc0201c64:	ec06                	sd	ra,24(sp)
ffffffffc0201c66:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201c68:	03451793          	slli	a5,a0,0x34
ffffffffc0201c6c:	842a                	mv	s0,a0
ffffffffc0201c6e:	e3d9                	bnez	a5,ffffffffc0201cf4 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c70:	100027f3          	csrr	a5,sstatus
ffffffffc0201c74:	8b89                	andi	a5,a5,2
ffffffffc0201c76:	e7d9                	bnez	a5,ffffffffc0201d04 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c78:	000d0797          	auipc	a5,0xd0
ffffffffc0201c7c:	8b87b783          	ld	a5,-1864(a5) # ffffffffc02d1530 <bigblocks>
    return 0;
ffffffffc0201c80:	4601                	li	a2,0
ffffffffc0201c82:	cbad                	beqz	a5,ffffffffc0201cf4 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201c84:	000d0697          	auipc	a3,0xd0
ffffffffc0201c88:	8ac68693          	addi	a3,a3,-1876 # ffffffffc02d1530 <bigblocks>
ffffffffc0201c8c:	a021                	j	ffffffffc0201c94 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c8e:	01048693          	addi	a3,s1,16
ffffffffc0201c92:	c3a5                	beqz	a5,ffffffffc0201cf2 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201c94:	6798                	ld	a4,8(a5)
ffffffffc0201c96:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201c98:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201c9a:	fe871ae3          	bne	a4,s0,ffffffffc0201c8e <kfree+0x30>
				*last = bb->next;
ffffffffc0201c9e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201ca0:	ee2d                	bnez	a2,ffffffffc0201d1a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201ca2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201ca6:	4098                	lw	a4,0(s1)
ffffffffc0201ca8:	08f46963          	bltu	s0,a5,ffffffffc0201d3a <kfree+0xdc>
ffffffffc0201cac:	000d0697          	auipc	a3,0xd0
ffffffffc0201cb0:	8b46b683          	ld	a3,-1868(a3) # ffffffffc02d1560 <va_pa_offset>
ffffffffc0201cb4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201cb6:	8031                	srli	s0,s0,0xc
ffffffffc0201cb8:	000d0797          	auipc	a5,0xd0
ffffffffc0201cbc:	8907b783          	ld	a5,-1904(a5) # ffffffffc02d1548 <npage>
ffffffffc0201cc0:	06f47163          	bgeu	s0,a5,ffffffffc0201d22 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201cc4:	00007517          	auipc	a0,0x7
ffffffffc0201cc8:	8ac53503          	ld	a0,-1876(a0) # ffffffffc0208570 <nbase>
ffffffffc0201ccc:	8c09                	sub	s0,s0,a0
ffffffffc0201cce:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201cd0:	000d0517          	auipc	a0,0xd0
ffffffffc0201cd4:	88053503          	ld	a0,-1920(a0) # ffffffffc02d1550 <pages>
ffffffffc0201cd8:	4585                	li	a1,1
ffffffffc0201cda:	9522                	add	a0,a0,s0
ffffffffc0201cdc:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201ce0:	0ea000ef          	jal	ra,ffffffffc0201dca <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201ce4:	6442                	ld	s0,16(sp)
ffffffffc0201ce6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ce8:	8526                	mv	a0,s1
}
ffffffffc0201cea:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201cec:	45e1                	li	a1,24
}
ffffffffc0201cee:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cf0:	b171                	j	ffffffffc020197c <slob_free>
ffffffffc0201cf2:	e20d                	bnez	a2,ffffffffc0201d14 <kfree+0xb6>
ffffffffc0201cf4:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201cf8:	6442                	ld	s0,16(sp)
ffffffffc0201cfa:	60e2                	ld	ra,24(sp)
ffffffffc0201cfc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cfe:	4581                	li	a1,0
}
ffffffffc0201d00:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d02:	b9ad                	j	ffffffffc020197c <slob_free>
        intr_disable();
ffffffffc0201d04:	cabfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d08:	000d0797          	auipc	a5,0xd0
ffffffffc0201d0c:	8287b783          	ld	a5,-2008(a5) # ffffffffc02d1530 <bigblocks>
        return 1;
ffffffffc0201d10:	4605                	li	a2,1
ffffffffc0201d12:	fbad                	bnez	a5,ffffffffc0201c84 <kfree+0x26>
        intr_enable();
ffffffffc0201d14:	c95fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d18:	bff1                	j	ffffffffc0201cf4 <kfree+0x96>
ffffffffc0201d1a:	c8ffe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d1e:	b751                	j	ffffffffc0201ca2 <kfree+0x44>
ffffffffc0201d20:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d22:	00005617          	auipc	a2,0x5
ffffffffc0201d26:	eae60613          	addi	a2,a2,-338 # ffffffffc0206bd0 <default_pmm_manager+0x108>
ffffffffc0201d2a:	06900593          	li	a1,105
ffffffffc0201d2e:	00005517          	auipc	a0,0x5
ffffffffc0201d32:	dfa50513          	addi	a0,a0,-518 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0201d36:	f5cfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d3a:	86a2                	mv	a3,s0
ffffffffc0201d3c:	00005617          	auipc	a2,0x5
ffffffffc0201d40:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc0201d44:	07700593          	li	a1,119
ffffffffc0201d48:	00005517          	auipc	a0,0x5
ffffffffc0201d4c:	de050513          	addi	a0,a0,-544 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0201d50:	f42fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d54 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d54:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201d56:	00005617          	auipc	a2,0x5
ffffffffc0201d5a:	e7a60613          	addi	a2,a2,-390 # ffffffffc0206bd0 <default_pmm_manager+0x108>
ffffffffc0201d5e:	06900593          	li	a1,105
ffffffffc0201d62:	00005517          	auipc	a0,0x5
ffffffffc0201d66:	dc650513          	addi	a0,a0,-570 # ffffffffc0206b28 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201d6a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201d6c:	f26fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d70 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201d70:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201d72:	00005617          	auipc	a2,0x5
ffffffffc0201d76:	e7e60613          	addi	a2,a2,-386 # ffffffffc0206bf0 <default_pmm_manager+0x128>
ffffffffc0201d7a:	07f00593          	li	a1,127
ffffffffc0201d7e:	00005517          	auipc	a0,0x5
ffffffffc0201d82:	daa50513          	addi	a0,a0,-598 # ffffffffc0206b28 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201d86:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201d88:	f0afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d8c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d8c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d90:	8b89                	andi	a5,a5,2
ffffffffc0201d92:	e799                	bnez	a5,ffffffffc0201da0 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d94:	000cf797          	auipc	a5,0xcf
ffffffffc0201d98:	7c47b783          	ld	a5,1988(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201d9c:	6f9c                	ld	a5,24(a5)
ffffffffc0201d9e:	8782                	jr	a5
{
ffffffffc0201da0:	1141                	addi	sp,sp,-16
ffffffffc0201da2:	e406                	sd	ra,8(sp)
ffffffffc0201da4:	e022                	sd	s0,0(sp)
ffffffffc0201da6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201da8:	c07fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dac:	000cf797          	auipc	a5,0xcf
ffffffffc0201db0:	7ac7b783          	ld	a5,1964(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201db4:	6f9c                	ld	a5,24(a5)
ffffffffc0201db6:	8522                	mv	a0,s0
ffffffffc0201db8:	9782                	jalr	a5
ffffffffc0201dba:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201dbc:	bedfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201dc0:	60a2                	ld	ra,8(sp)
ffffffffc0201dc2:	8522                	mv	a0,s0
ffffffffc0201dc4:	6402                	ld	s0,0(sp)
ffffffffc0201dc6:	0141                	addi	sp,sp,16
ffffffffc0201dc8:	8082                	ret

ffffffffc0201dca <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dca:	100027f3          	csrr	a5,sstatus
ffffffffc0201dce:	8b89                	andi	a5,a5,2
ffffffffc0201dd0:	e799                	bnez	a5,ffffffffc0201dde <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201dd2:	000cf797          	auipc	a5,0xcf
ffffffffc0201dd6:	7867b783          	ld	a5,1926(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201dda:	739c                	ld	a5,32(a5)
ffffffffc0201ddc:	8782                	jr	a5
{
ffffffffc0201dde:	1101                	addi	sp,sp,-32
ffffffffc0201de0:	ec06                	sd	ra,24(sp)
ffffffffc0201de2:	e822                	sd	s0,16(sp)
ffffffffc0201de4:	e426                	sd	s1,8(sp)
ffffffffc0201de6:	842a                	mv	s0,a0
ffffffffc0201de8:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201dea:	bc5fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201dee:	000cf797          	auipc	a5,0xcf
ffffffffc0201df2:	76a7b783          	ld	a5,1898(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201df6:	739c                	ld	a5,32(a5)
ffffffffc0201df8:	85a6                	mv	a1,s1
ffffffffc0201dfa:	8522                	mv	a0,s0
ffffffffc0201dfc:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201dfe:	6442                	ld	s0,16(sp)
ffffffffc0201e00:	60e2                	ld	ra,24(sp)
ffffffffc0201e02:	64a2                	ld	s1,8(sp)
ffffffffc0201e04:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e06:	ba3fe06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0201e0a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e0a:	100027f3          	csrr	a5,sstatus
ffffffffc0201e0e:	8b89                	andi	a5,a5,2
ffffffffc0201e10:	e799                	bnez	a5,ffffffffc0201e1e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e12:	000cf797          	auipc	a5,0xcf
ffffffffc0201e16:	7467b783          	ld	a5,1862(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201e1a:	779c                	ld	a5,40(a5)
ffffffffc0201e1c:	8782                	jr	a5
{
ffffffffc0201e1e:	1141                	addi	sp,sp,-16
ffffffffc0201e20:	e406                	sd	ra,8(sp)
ffffffffc0201e22:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201e24:	b8bfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e28:	000cf797          	auipc	a5,0xcf
ffffffffc0201e2c:	7307b783          	ld	a5,1840(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201e30:	779c                	ld	a5,40(a5)
ffffffffc0201e32:	9782                	jalr	a5
ffffffffc0201e34:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e36:	b73fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e3a:	60a2                	ld	ra,8(sp)
ffffffffc0201e3c:	8522                	mv	a0,s0
ffffffffc0201e3e:	6402                	ld	s0,0(sp)
ffffffffc0201e40:	0141                	addi	sp,sp,16
ffffffffc0201e42:	8082                	ret

ffffffffc0201e44 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e44:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e48:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201e4c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e4e:	078e                	slli	a5,a5,0x3
{
ffffffffc0201e50:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e52:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e56:	6094                	ld	a3,0(s1)
{
ffffffffc0201e58:	f04a                	sd	s2,32(sp)
ffffffffc0201e5a:	ec4e                	sd	s3,24(sp)
ffffffffc0201e5c:	e852                	sd	s4,16(sp)
ffffffffc0201e5e:	fc06                	sd	ra,56(sp)
ffffffffc0201e60:	f822                	sd	s0,48(sp)
ffffffffc0201e62:	e456                	sd	s5,8(sp)
ffffffffc0201e64:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e66:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e6a:	892e                	mv	s2,a1
ffffffffc0201e6c:	8a32                	mv	s4,a2
ffffffffc0201e6e:	000cf997          	auipc	s3,0xcf
ffffffffc0201e72:	6da98993          	addi	s3,s3,1754 # ffffffffc02d1548 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e76:	efbd                	bnez	a5,ffffffffc0201ef4 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e78:	14060c63          	beqz	a2,ffffffffc0201fd0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e7c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e80:	8b89                	andi	a5,a5,2
ffffffffc0201e82:	14079963          	bnez	a5,ffffffffc0201fd4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e86:	000cf797          	auipc	a5,0xcf
ffffffffc0201e8a:	6d27b783          	ld	a5,1746(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201e8e:	6f9c                	ld	a5,24(a5)
ffffffffc0201e90:	4505                	li	a0,1
ffffffffc0201e92:	9782                	jalr	a5
ffffffffc0201e94:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e96:	12040d63          	beqz	s0,ffffffffc0201fd0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e9a:	000cfb17          	auipc	s6,0xcf
ffffffffc0201e9e:	6b6b0b13          	addi	s6,s6,1718 # ffffffffc02d1550 <pages>
ffffffffc0201ea2:	000b3503          	ld	a0,0(s6)
ffffffffc0201ea6:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201eaa:	000cf997          	auipc	s3,0xcf
ffffffffc0201eae:	69e98993          	addi	s3,s3,1694 # ffffffffc02d1548 <npage>
ffffffffc0201eb2:	40a40533          	sub	a0,s0,a0
ffffffffc0201eb6:	8519                	srai	a0,a0,0x6
ffffffffc0201eb8:	9556                	add	a0,a0,s5
ffffffffc0201eba:	0009b703          	ld	a4,0(s3)
ffffffffc0201ebe:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201ec2:	4685                	li	a3,1
ffffffffc0201ec4:	c014                	sw	a3,0(s0)
ffffffffc0201ec6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ec8:	0532                	slli	a0,a0,0xc
ffffffffc0201eca:	16e7f763          	bgeu	a5,a4,ffffffffc0202038 <get_pte+0x1f4>
ffffffffc0201ece:	000cf797          	auipc	a5,0xcf
ffffffffc0201ed2:	6927b783          	ld	a5,1682(a5) # ffffffffc02d1560 <va_pa_offset>
ffffffffc0201ed6:	6605                	lui	a2,0x1
ffffffffc0201ed8:	4581                	li	a1,0
ffffffffc0201eda:	953e                	add	a0,a0,a5
ffffffffc0201edc:	58d030ef          	jal	ra,ffffffffc0205c68 <memset>
    return page - pages + nbase;
ffffffffc0201ee0:	000b3683          	ld	a3,0(s6)
ffffffffc0201ee4:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ee8:	8699                	srai	a3,a3,0x6
ffffffffc0201eea:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201eec:	06aa                	slli	a3,a3,0xa
ffffffffc0201eee:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ef2:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ef4:	77fd                	lui	a5,0xfffff
ffffffffc0201ef6:	068a                	slli	a3,a3,0x2
ffffffffc0201ef8:	0009b703          	ld	a4,0(s3)
ffffffffc0201efc:	8efd                	and	a3,a3,a5
ffffffffc0201efe:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f02:	10e7ff63          	bgeu	a5,a4,ffffffffc0202020 <get_pte+0x1dc>
ffffffffc0201f06:	000cfa97          	auipc	s5,0xcf
ffffffffc0201f0a:	65aa8a93          	addi	s5,s5,1626 # ffffffffc02d1560 <va_pa_offset>
ffffffffc0201f0e:	000ab403          	ld	s0,0(s5)
ffffffffc0201f12:	01595793          	srli	a5,s2,0x15
ffffffffc0201f16:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f1a:	96a2                	add	a3,a3,s0
ffffffffc0201f1c:	00379413          	slli	s0,a5,0x3
ffffffffc0201f20:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f22:	6014                	ld	a3,0(s0)
ffffffffc0201f24:	0016f793          	andi	a5,a3,1
ffffffffc0201f28:	ebad                	bnez	a5,ffffffffc0201f9a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f2a:	0a0a0363          	beqz	s4,ffffffffc0201fd0 <get_pte+0x18c>
ffffffffc0201f2e:	100027f3          	csrr	a5,sstatus
ffffffffc0201f32:	8b89                	andi	a5,a5,2
ffffffffc0201f34:	efcd                	bnez	a5,ffffffffc0201fee <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f36:	000cf797          	auipc	a5,0xcf
ffffffffc0201f3a:	6227b783          	ld	a5,1570(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201f3e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f40:	4505                	li	a0,1
ffffffffc0201f42:	9782                	jalr	a5
ffffffffc0201f44:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f46:	c4c9                	beqz	s1,ffffffffc0201fd0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f48:	000cfb17          	auipc	s6,0xcf
ffffffffc0201f4c:	608b0b13          	addi	s6,s6,1544 # ffffffffc02d1550 <pages>
ffffffffc0201f50:	000b3503          	ld	a0,0(s6)
ffffffffc0201f54:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f58:	0009b703          	ld	a4,0(s3)
ffffffffc0201f5c:	40a48533          	sub	a0,s1,a0
ffffffffc0201f60:	8519                	srai	a0,a0,0x6
ffffffffc0201f62:	9552                	add	a0,a0,s4
ffffffffc0201f64:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f68:	4685                	li	a3,1
ffffffffc0201f6a:	c094                	sw	a3,0(s1)
ffffffffc0201f6c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f6e:	0532                	slli	a0,a0,0xc
ffffffffc0201f70:	0ee7f163          	bgeu	a5,a4,ffffffffc0202052 <get_pte+0x20e>
ffffffffc0201f74:	000ab783          	ld	a5,0(s5)
ffffffffc0201f78:	6605                	lui	a2,0x1
ffffffffc0201f7a:	4581                	li	a1,0
ffffffffc0201f7c:	953e                	add	a0,a0,a5
ffffffffc0201f7e:	4eb030ef          	jal	ra,ffffffffc0205c68 <memset>
    return page - pages + nbase;
ffffffffc0201f82:	000b3683          	ld	a3,0(s6)
ffffffffc0201f86:	40d486b3          	sub	a3,s1,a3
ffffffffc0201f8a:	8699                	srai	a3,a3,0x6
ffffffffc0201f8c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f8e:	06aa                	slli	a3,a3,0xa
ffffffffc0201f90:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f94:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f96:	0009b703          	ld	a4,0(s3)
ffffffffc0201f9a:	068a                	slli	a3,a3,0x2
ffffffffc0201f9c:	757d                	lui	a0,0xfffff
ffffffffc0201f9e:	8ee9                	and	a3,a3,a0
ffffffffc0201fa0:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fa4:	06e7f263          	bgeu	a5,a4,ffffffffc0202008 <get_pte+0x1c4>
ffffffffc0201fa8:	000ab503          	ld	a0,0(s5)
ffffffffc0201fac:	00c95913          	srli	s2,s2,0xc
ffffffffc0201fb0:	1ff97913          	andi	s2,s2,511
ffffffffc0201fb4:	96aa                	add	a3,a3,a0
ffffffffc0201fb6:	00391513          	slli	a0,s2,0x3
ffffffffc0201fba:	9536                	add	a0,a0,a3
}
ffffffffc0201fbc:	70e2                	ld	ra,56(sp)
ffffffffc0201fbe:	7442                	ld	s0,48(sp)
ffffffffc0201fc0:	74a2                	ld	s1,40(sp)
ffffffffc0201fc2:	7902                	ld	s2,32(sp)
ffffffffc0201fc4:	69e2                	ld	s3,24(sp)
ffffffffc0201fc6:	6a42                	ld	s4,16(sp)
ffffffffc0201fc8:	6aa2                	ld	s5,8(sp)
ffffffffc0201fca:	6b02                	ld	s6,0(sp)
ffffffffc0201fcc:	6121                	addi	sp,sp,64
ffffffffc0201fce:	8082                	ret
            return NULL;
ffffffffc0201fd0:	4501                	li	a0,0
ffffffffc0201fd2:	b7ed                	j	ffffffffc0201fbc <get_pte+0x178>
        intr_disable();
ffffffffc0201fd4:	9dbfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fd8:	000cf797          	auipc	a5,0xcf
ffffffffc0201fdc:	5807b783          	ld	a5,1408(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201fe0:	6f9c                	ld	a5,24(a5)
ffffffffc0201fe2:	4505                	li	a0,1
ffffffffc0201fe4:	9782                	jalr	a5
ffffffffc0201fe6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fe8:	9c1fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201fec:	b56d                	j	ffffffffc0201e96 <get_pte+0x52>
        intr_disable();
ffffffffc0201fee:	9c1fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0201ff2:	000cf797          	auipc	a5,0xcf
ffffffffc0201ff6:	5667b783          	ld	a5,1382(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0201ffa:	6f9c                	ld	a5,24(a5)
ffffffffc0201ffc:	4505                	li	a0,1
ffffffffc0201ffe:	9782                	jalr	a5
ffffffffc0202000:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202002:	9a7fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202006:	b781                	j	ffffffffc0201f46 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202008:	00005617          	auipc	a2,0x5
ffffffffc020200c:	af860613          	addi	a2,a2,-1288 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0202010:	0fa00593          	li	a1,250
ffffffffc0202014:	00005517          	auipc	a0,0x5
ffffffffc0202018:	c0450513          	addi	a0,a0,-1020 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020201c:	c76fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202020:	00005617          	auipc	a2,0x5
ffffffffc0202024:	ae060613          	addi	a2,a2,-1312 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0202028:	0ed00593          	li	a1,237
ffffffffc020202c:	00005517          	auipc	a0,0x5
ffffffffc0202030:	bec50513          	addi	a0,a0,-1044 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202034:	c5efe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202038:	86aa                	mv	a3,a0
ffffffffc020203a:	00005617          	auipc	a2,0x5
ffffffffc020203e:	ac660613          	addi	a2,a2,-1338 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0202042:	0e900593          	li	a1,233
ffffffffc0202046:	00005517          	auipc	a0,0x5
ffffffffc020204a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020204e:	c44fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202052:	86aa                	mv	a3,a0
ffffffffc0202054:	00005617          	auipc	a2,0x5
ffffffffc0202058:	aac60613          	addi	a2,a2,-1364 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc020205c:	0f700593          	li	a1,247
ffffffffc0202060:	00005517          	auipc	a0,0x5
ffffffffc0202064:	bb850513          	addi	a0,a0,-1096 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202068:	c2afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020206c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020206c:	1141                	addi	sp,sp,-16
ffffffffc020206e:	e022                	sd	s0,0(sp)
ffffffffc0202070:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202072:	4601                	li	a2,0
{
ffffffffc0202074:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202076:	dcfff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
    if (ptep_store != NULL)
ffffffffc020207a:	c011                	beqz	s0,ffffffffc020207e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020207c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020207e:	c511                	beqz	a0,ffffffffc020208a <get_page+0x1e>
ffffffffc0202080:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202082:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202084:	0017f713          	andi	a4,a5,1
ffffffffc0202088:	e709                	bnez	a4,ffffffffc0202092 <get_page+0x26>
}
ffffffffc020208a:	60a2                	ld	ra,8(sp)
ffffffffc020208c:	6402                	ld	s0,0(sp)
ffffffffc020208e:	0141                	addi	sp,sp,16
ffffffffc0202090:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202092:	078a                	slli	a5,a5,0x2
ffffffffc0202094:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202096:	000cf717          	auipc	a4,0xcf
ffffffffc020209a:	4b273703          	ld	a4,1202(a4) # ffffffffc02d1548 <npage>
ffffffffc020209e:	00e7ff63          	bgeu	a5,a4,ffffffffc02020bc <get_page+0x50>
ffffffffc02020a2:	60a2                	ld	ra,8(sp)
ffffffffc02020a4:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02020a6:	fff80537          	lui	a0,0xfff80
ffffffffc02020aa:	97aa                	add	a5,a5,a0
ffffffffc02020ac:	079a                	slli	a5,a5,0x6
ffffffffc02020ae:	000cf517          	auipc	a0,0xcf
ffffffffc02020b2:	4a253503          	ld	a0,1186(a0) # ffffffffc02d1550 <pages>
ffffffffc02020b6:	953e                	add	a0,a0,a5
ffffffffc02020b8:	0141                	addi	sp,sp,16
ffffffffc02020ba:	8082                	ret
ffffffffc02020bc:	c99ff0ef          	jal	ra,ffffffffc0201d54 <pa2page.part.0>

ffffffffc02020c0 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02020c0:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020c2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02020c6:	f486                	sd	ra,104(sp)
ffffffffc02020c8:	f0a2                	sd	s0,96(sp)
ffffffffc02020ca:	eca6                	sd	s1,88(sp)
ffffffffc02020cc:	e8ca                	sd	s2,80(sp)
ffffffffc02020ce:	e4ce                	sd	s3,72(sp)
ffffffffc02020d0:	e0d2                	sd	s4,64(sp)
ffffffffc02020d2:	fc56                	sd	s5,56(sp)
ffffffffc02020d4:	f85a                	sd	s6,48(sp)
ffffffffc02020d6:	f45e                	sd	s7,40(sp)
ffffffffc02020d8:	f062                	sd	s8,32(sp)
ffffffffc02020da:	ec66                	sd	s9,24(sp)
ffffffffc02020dc:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020de:	17d2                	slli	a5,a5,0x34
ffffffffc02020e0:	e3ed                	bnez	a5,ffffffffc02021c2 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02020e2:	002007b7          	lui	a5,0x200
ffffffffc02020e6:	842e                	mv	s0,a1
ffffffffc02020e8:	0ef5ed63          	bltu	a1,a5,ffffffffc02021e2 <unmap_range+0x122>
ffffffffc02020ec:	8932                	mv	s2,a2
ffffffffc02020ee:	0ec5fa63          	bgeu	a1,a2,ffffffffc02021e2 <unmap_range+0x122>
ffffffffc02020f2:	4785                	li	a5,1
ffffffffc02020f4:	07fe                	slli	a5,a5,0x1f
ffffffffc02020f6:	0ec7e663          	bltu	a5,a2,ffffffffc02021e2 <unmap_range+0x122>
ffffffffc02020fa:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02020fc:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02020fe:	000cfc97          	auipc	s9,0xcf
ffffffffc0202102:	44ac8c93          	addi	s9,s9,1098 # ffffffffc02d1548 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202106:	000cfc17          	auipc	s8,0xcf
ffffffffc020210a:	44ac0c13          	addi	s8,s8,1098 # ffffffffc02d1550 <pages>
ffffffffc020210e:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202112:	000cfd17          	auipc	s10,0xcf
ffffffffc0202116:	446d0d13          	addi	s10,s10,1094 # ffffffffc02d1558 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020211a:	00200b37          	lui	s6,0x200
ffffffffc020211e:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202122:	4601                	li	a2,0
ffffffffc0202124:	85a2                	mv	a1,s0
ffffffffc0202126:	854e                	mv	a0,s3
ffffffffc0202128:	d1dff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
ffffffffc020212c:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020212e:	cd29                	beqz	a0,ffffffffc0202188 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202130:	611c                	ld	a5,0(a0)
ffffffffc0202132:	e395                	bnez	a5,ffffffffc0202156 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202134:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202136:	ff2466e3          	bltu	s0,s2,ffffffffc0202122 <unmap_range+0x62>
}
ffffffffc020213a:	70a6                	ld	ra,104(sp)
ffffffffc020213c:	7406                	ld	s0,96(sp)
ffffffffc020213e:	64e6                	ld	s1,88(sp)
ffffffffc0202140:	6946                	ld	s2,80(sp)
ffffffffc0202142:	69a6                	ld	s3,72(sp)
ffffffffc0202144:	6a06                	ld	s4,64(sp)
ffffffffc0202146:	7ae2                	ld	s5,56(sp)
ffffffffc0202148:	7b42                	ld	s6,48(sp)
ffffffffc020214a:	7ba2                	ld	s7,40(sp)
ffffffffc020214c:	7c02                	ld	s8,32(sp)
ffffffffc020214e:	6ce2                	ld	s9,24(sp)
ffffffffc0202150:	6d42                	ld	s10,16(sp)
ffffffffc0202152:	6165                	addi	sp,sp,112
ffffffffc0202154:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202156:	0017f713          	andi	a4,a5,1
ffffffffc020215a:	df69                	beqz	a4,ffffffffc0202134 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020215c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202160:	078a                	slli	a5,a5,0x2
ffffffffc0202162:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202164:	08e7ff63          	bgeu	a5,a4,ffffffffc0202202 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202168:	000c3503          	ld	a0,0(s8)
ffffffffc020216c:	97de                	add	a5,a5,s7
ffffffffc020216e:	079a                	slli	a5,a5,0x6
ffffffffc0202170:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202172:	411c                	lw	a5,0(a0)
ffffffffc0202174:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202178:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020217a:	cf11                	beqz	a4,ffffffffc0202196 <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020217c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202180:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202184:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202186:	bf45                	j	ffffffffc0202136 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202188:	945a                	add	s0,s0,s6
ffffffffc020218a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020218e:	d455                	beqz	s0,ffffffffc020213a <unmap_range+0x7a>
ffffffffc0202190:	f92469e3          	bltu	s0,s2,ffffffffc0202122 <unmap_range+0x62>
ffffffffc0202194:	b75d                	j	ffffffffc020213a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202196:	100027f3          	csrr	a5,sstatus
ffffffffc020219a:	8b89                	andi	a5,a5,2
ffffffffc020219c:	e799                	bnez	a5,ffffffffc02021aa <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020219e:	000d3783          	ld	a5,0(s10)
ffffffffc02021a2:	4585                	li	a1,1
ffffffffc02021a4:	739c                	ld	a5,32(a5)
ffffffffc02021a6:	9782                	jalr	a5
    if (flag)
ffffffffc02021a8:	bfd1                	j	ffffffffc020217c <unmap_range+0xbc>
ffffffffc02021aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021ac:	803fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02021b0:	000d3783          	ld	a5,0(s10)
ffffffffc02021b4:	6522                	ld	a0,8(sp)
ffffffffc02021b6:	4585                	li	a1,1
ffffffffc02021b8:	739c                	ld	a5,32(a5)
ffffffffc02021ba:	9782                	jalr	a5
        intr_enable();
ffffffffc02021bc:	fecfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02021c0:	bf75                	j	ffffffffc020217c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021c2:	00005697          	auipc	a3,0x5
ffffffffc02021c6:	a6668693          	addi	a3,a3,-1434 # ffffffffc0206c28 <default_pmm_manager+0x160>
ffffffffc02021ca:	00004617          	auipc	a2,0x4
ffffffffc02021ce:	54e60613          	addi	a2,a2,1358 # ffffffffc0206718 <commands+0x818>
ffffffffc02021d2:	12200593          	li	a1,290
ffffffffc02021d6:	00005517          	auipc	a0,0x5
ffffffffc02021da:	a4250513          	addi	a0,a0,-1470 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02021de:	ab4fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02021e2:	00005697          	auipc	a3,0x5
ffffffffc02021e6:	a7668693          	addi	a3,a3,-1418 # ffffffffc0206c58 <default_pmm_manager+0x190>
ffffffffc02021ea:	00004617          	auipc	a2,0x4
ffffffffc02021ee:	52e60613          	addi	a2,a2,1326 # ffffffffc0206718 <commands+0x818>
ffffffffc02021f2:	12300593          	li	a1,291
ffffffffc02021f6:	00005517          	auipc	a0,0x5
ffffffffc02021fa:	a2250513          	addi	a0,a0,-1502 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02021fe:	a94fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202202:	b53ff0ef          	jal	ra,ffffffffc0201d54 <pa2page.part.0>

ffffffffc0202206 <exit_range>:
{
ffffffffc0202206:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202208:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020220c:	fc86                	sd	ra,120(sp)
ffffffffc020220e:	f8a2                	sd	s0,112(sp)
ffffffffc0202210:	f4a6                	sd	s1,104(sp)
ffffffffc0202212:	f0ca                	sd	s2,96(sp)
ffffffffc0202214:	ecce                	sd	s3,88(sp)
ffffffffc0202216:	e8d2                	sd	s4,80(sp)
ffffffffc0202218:	e4d6                	sd	s5,72(sp)
ffffffffc020221a:	e0da                	sd	s6,64(sp)
ffffffffc020221c:	fc5e                	sd	s7,56(sp)
ffffffffc020221e:	f862                	sd	s8,48(sp)
ffffffffc0202220:	f466                	sd	s9,40(sp)
ffffffffc0202222:	f06a                	sd	s10,32(sp)
ffffffffc0202224:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202226:	17d2                	slli	a5,a5,0x34
ffffffffc0202228:	20079a63          	bnez	a5,ffffffffc020243c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020222c:	002007b7          	lui	a5,0x200
ffffffffc0202230:	24f5e463          	bltu	a1,a5,ffffffffc0202478 <exit_range+0x272>
ffffffffc0202234:	8ab2                	mv	s5,a2
ffffffffc0202236:	24c5f163          	bgeu	a1,a2,ffffffffc0202478 <exit_range+0x272>
ffffffffc020223a:	4785                	li	a5,1
ffffffffc020223c:	07fe                	slli	a5,a5,0x1f
ffffffffc020223e:	22c7ed63          	bltu	a5,a2,ffffffffc0202478 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202242:	c00009b7          	lui	s3,0xc0000
ffffffffc0202246:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020224a:	ffe00937          	lui	s2,0xffe00
ffffffffc020224e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202252:	5cfd                	li	s9,-1
ffffffffc0202254:	8c2a                	mv	s8,a0
ffffffffc0202256:	0125f933          	and	s2,a1,s2
ffffffffc020225a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020225c:	000cfd17          	auipc	s10,0xcf
ffffffffc0202260:	2ecd0d13          	addi	s10,s10,748 # ffffffffc02d1548 <npage>
    return KADDR(page2pa(page));
ffffffffc0202264:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202268:	000cf717          	auipc	a4,0xcf
ffffffffc020226c:	2e870713          	addi	a4,a4,744 # ffffffffc02d1550 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202270:	000cfd97          	auipc	s11,0xcf
ffffffffc0202274:	2e8d8d93          	addi	s11,s11,744 # ffffffffc02d1558 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202278:	c0000437          	lui	s0,0xc0000
ffffffffc020227c:	944e                	add	s0,s0,s3
ffffffffc020227e:	8079                	srli	s0,s0,0x1e
ffffffffc0202280:	1ff47413          	andi	s0,s0,511
ffffffffc0202284:	040e                	slli	s0,s0,0x3
ffffffffc0202286:	9462                	add	s0,s0,s8
ffffffffc0202288:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f8>
        if (pde1 & PTE_V)
ffffffffc020228c:	001a7793          	andi	a5,s4,1
ffffffffc0202290:	eb99                	bnez	a5,ffffffffc02022a6 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202292:	12098463          	beqz	s3,ffffffffc02023ba <exit_range+0x1b4>
ffffffffc0202296:	400007b7          	lui	a5,0x40000
ffffffffc020229a:	97ce                	add	a5,a5,s3
ffffffffc020229c:	894e                	mv	s2,s3
ffffffffc020229e:	1159fe63          	bgeu	s3,s5,ffffffffc02023ba <exit_range+0x1b4>
ffffffffc02022a2:	89be                	mv	s3,a5
ffffffffc02022a4:	bfd1                	j	ffffffffc0202278 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02022a6:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02022aa:	0a0a                	slli	s4,s4,0x2
ffffffffc02022ac:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02022b0:	1cfa7263          	bgeu	s4,a5,ffffffffc0202474 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022b4:	fff80637          	lui	a2,0xfff80
ffffffffc02022b8:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02022ba:	000806b7          	lui	a3,0x80
ffffffffc02022be:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02022c0:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02022c4:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02022c6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02022c8:	18f5fa63          	bgeu	a1,a5,ffffffffc020245c <exit_range+0x256>
ffffffffc02022cc:	000cf817          	auipc	a6,0xcf
ffffffffc02022d0:	29480813          	addi	a6,a6,660 # ffffffffc02d1560 <va_pa_offset>
ffffffffc02022d4:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02022d8:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02022da:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02022de:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02022e0:	00080337          	lui	t1,0x80
ffffffffc02022e4:	6885                	lui	a7,0x1
ffffffffc02022e6:	a819                	j	ffffffffc02022fc <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02022e8:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02022ea:	002007b7          	lui	a5,0x200
ffffffffc02022ee:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02022f0:	08090c63          	beqz	s2,ffffffffc0202388 <exit_range+0x182>
ffffffffc02022f4:	09397a63          	bgeu	s2,s3,ffffffffc0202388 <exit_range+0x182>
ffffffffc02022f8:	0f597063          	bgeu	s2,s5,ffffffffc02023d8 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02022fc:	01595493          	srli	s1,s2,0x15
ffffffffc0202300:	1ff4f493          	andi	s1,s1,511
ffffffffc0202304:	048e                	slli	s1,s1,0x3
ffffffffc0202306:	94da                	add	s1,s1,s6
ffffffffc0202308:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020230a:	0017f693          	andi	a3,a5,1
ffffffffc020230e:	dee9                	beqz	a3,ffffffffc02022e8 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202310:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202314:	078a                	slli	a5,a5,0x2
ffffffffc0202316:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202318:	14b7fe63          	bgeu	a5,a1,ffffffffc0202474 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020231c:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020231e:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202322:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202326:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020232a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020232c:	12bef863          	bgeu	t4,a1,ffffffffc020245c <exit_range+0x256>
ffffffffc0202330:	00083783          	ld	a5,0(a6)
ffffffffc0202334:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202336:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020233a:	629c                	ld	a5,0(a3)
ffffffffc020233c:	8b85                	andi	a5,a5,1
ffffffffc020233e:	f7d5                	bnez	a5,ffffffffc02022ea <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202340:	06a1                	addi	a3,a3,8
ffffffffc0202342:	fed59ce3          	bne	a1,a3,ffffffffc020233a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202346:	631c                	ld	a5,0(a4)
ffffffffc0202348:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020234a:	100027f3          	csrr	a5,sstatus
ffffffffc020234e:	8b89                	andi	a5,a5,2
ffffffffc0202350:	e7d9                	bnez	a5,ffffffffc02023de <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202352:	000db783          	ld	a5,0(s11)
ffffffffc0202356:	4585                	li	a1,1
ffffffffc0202358:	e032                	sd	a2,0(sp)
ffffffffc020235a:	739c                	ld	a5,32(a5)
ffffffffc020235c:	9782                	jalr	a5
    if (flag)
ffffffffc020235e:	6602                	ld	a2,0(sp)
ffffffffc0202360:	000cf817          	auipc	a6,0xcf
ffffffffc0202364:	20080813          	addi	a6,a6,512 # ffffffffc02d1560 <va_pa_offset>
ffffffffc0202368:	fff80e37          	lui	t3,0xfff80
ffffffffc020236c:	00080337          	lui	t1,0x80
ffffffffc0202370:	6885                	lui	a7,0x1
ffffffffc0202372:	000cf717          	auipc	a4,0xcf
ffffffffc0202376:	1de70713          	addi	a4,a4,478 # ffffffffc02d1550 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020237a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020237e:	002007b7          	lui	a5,0x200
ffffffffc0202382:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202384:	f60918e3          	bnez	s2,ffffffffc02022f4 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202388:	f00b85e3          	beqz	s7,ffffffffc0202292 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020238c:	000d3783          	ld	a5,0(s10)
ffffffffc0202390:	0efa7263          	bgeu	s4,a5,ffffffffc0202474 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202394:	6308                	ld	a0,0(a4)
ffffffffc0202396:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202398:	100027f3          	csrr	a5,sstatus
ffffffffc020239c:	8b89                	andi	a5,a5,2
ffffffffc020239e:	efad                	bnez	a5,ffffffffc0202418 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02023a0:	000db783          	ld	a5,0(s11)
ffffffffc02023a4:	4585                	li	a1,1
ffffffffc02023a6:	739c                	ld	a5,32(a5)
ffffffffc02023a8:	9782                	jalr	a5
ffffffffc02023aa:	000cf717          	auipc	a4,0xcf
ffffffffc02023ae:	1a670713          	addi	a4,a4,422 # ffffffffc02d1550 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02023b2:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02023b6:	ee0990e3          	bnez	s3,ffffffffc0202296 <exit_range+0x90>
}
ffffffffc02023ba:	70e6                	ld	ra,120(sp)
ffffffffc02023bc:	7446                	ld	s0,112(sp)
ffffffffc02023be:	74a6                	ld	s1,104(sp)
ffffffffc02023c0:	7906                	ld	s2,96(sp)
ffffffffc02023c2:	69e6                	ld	s3,88(sp)
ffffffffc02023c4:	6a46                	ld	s4,80(sp)
ffffffffc02023c6:	6aa6                	ld	s5,72(sp)
ffffffffc02023c8:	6b06                	ld	s6,64(sp)
ffffffffc02023ca:	7be2                	ld	s7,56(sp)
ffffffffc02023cc:	7c42                	ld	s8,48(sp)
ffffffffc02023ce:	7ca2                	ld	s9,40(sp)
ffffffffc02023d0:	7d02                	ld	s10,32(sp)
ffffffffc02023d2:	6de2                	ld	s11,24(sp)
ffffffffc02023d4:	6109                	addi	sp,sp,128
ffffffffc02023d6:	8082                	ret
            if (free_pd0)
ffffffffc02023d8:	ea0b8fe3          	beqz	s7,ffffffffc0202296 <exit_range+0x90>
ffffffffc02023dc:	bf45                	j	ffffffffc020238c <exit_range+0x186>
ffffffffc02023de:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02023e0:	e42a                	sd	a0,8(sp)
ffffffffc02023e2:	dccfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02023e6:	000db783          	ld	a5,0(s11)
ffffffffc02023ea:	6522                	ld	a0,8(sp)
ffffffffc02023ec:	4585                	li	a1,1
ffffffffc02023ee:	739c                	ld	a5,32(a5)
ffffffffc02023f0:	9782                	jalr	a5
        intr_enable();
ffffffffc02023f2:	db6fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02023f6:	6602                	ld	a2,0(sp)
ffffffffc02023f8:	000cf717          	auipc	a4,0xcf
ffffffffc02023fc:	15870713          	addi	a4,a4,344 # ffffffffc02d1550 <pages>
ffffffffc0202400:	6885                	lui	a7,0x1
ffffffffc0202402:	00080337          	lui	t1,0x80
ffffffffc0202406:	fff80e37          	lui	t3,0xfff80
ffffffffc020240a:	000cf817          	auipc	a6,0xcf
ffffffffc020240e:	15680813          	addi	a6,a6,342 # ffffffffc02d1560 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202412:	0004b023          	sd	zero,0(s1)
ffffffffc0202416:	b7a5                	j	ffffffffc020237e <exit_range+0x178>
ffffffffc0202418:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020241a:	d94fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020241e:	000db783          	ld	a5,0(s11)
ffffffffc0202422:	6502                	ld	a0,0(sp)
ffffffffc0202424:	4585                	li	a1,1
ffffffffc0202426:	739c                	ld	a5,32(a5)
ffffffffc0202428:	9782                	jalr	a5
        intr_enable();
ffffffffc020242a:	d7efe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020242e:	000cf717          	auipc	a4,0xcf
ffffffffc0202432:	12270713          	addi	a4,a4,290 # ffffffffc02d1550 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202436:	00043023          	sd	zero,0(s0)
ffffffffc020243a:	bfb5                	j	ffffffffc02023b6 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020243c:	00004697          	auipc	a3,0x4
ffffffffc0202440:	7ec68693          	addi	a3,a3,2028 # ffffffffc0206c28 <default_pmm_manager+0x160>
ffffffffc0202444:	00004617          	auipc	a2,0x4
ffffffffc0202448:	2d460613          	addi	a2,a2,724 # ffffffffc0206718 <commands+0x818>
ffffffffc020244c:	13700593          	li	a1,311
ffffffffc0202450:	00004517          	auipc	a0,0x4
ffffffffc0202454:	7c850513          	addi	a0,a0,1992 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202458:	83afe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc020245c:	00004617          	auipc	a2,0x4
ffffffffc0202460:	6a460613          	addi	a2,a2,1700 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0202464:	07100593          	li	a1,113
ffffffffc0202468:	00004517          	auipc	a0,0x4
ffffffffc020246c:	6c050513          	addi	a0,a0,1728 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0202470:	822fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202474:	8e1ff0ef          	jal	ra,ffffffffc0201d54 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202478:	00004697          	auipc	a3,0x4
ffffffffc020247c:	7e068693          	addi	a3,a3,2016 # ffffffffc0206c58 <default_pmm_manager+0x190>
ffffffffc0202480:	00004617          	auipc	a2,0x4
ffffffffc0202484:	29860613          	addi	a2,a2,664 # ffffffffc0206718 <commands+0x818>
ffffffffc0202488:	13800593          	li	a1,312
ffffffffc020248c:	00004517          	auipc	a0,0x4
ffffffffc0202490:	78c50513          	addi	a0,a0,1932 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202494:	ffffd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202498 <page_remove>:
{
ffffffffc0202498:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020249a:	4601                	li	a2,0
{
ffffffffc020249c:	ec26                	sd	s1,24(sp)
ffffffffc020249e:	f406                	sd	ra,40(sp)
ffffffffc02024a0:	f022                	sd	s0,32(sp)
ffffffffc02024a2:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02024a4:	9a1ff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
    if (ptep != NULL)
ffffffffc02024a8:	c511                	beqz	a0,ffffffffc02024b4 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02024aa:	611c                	ld	a5,0(a0)
ffffffffc02024ac:	842a                	mv	s0,a0
ffffffffc02024ae:	0017f713          	andi	a4,a5,1
ffffffffc02024b2:	e711                	bnez	a4,ffffffffc02024be <page_remove+0x26>
}
ffffffffc02024b4:	70a2                	ld	ra,40(sp)
ffffffffc02024b6:	7402                	ld	s0,32(sp)
ffffffffc02024b8:	64e2                	ld	s1,24(sp)
ffffffffc02024ba:	6145                	addi	sp,sp,48
ffffffffc02024bc:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024be:	078a                	slli	a5,a5,0x2
ffffffffc02024c0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024c2:	000cf717          	auipc	a4,0xcf
ffffffffc02024c6:	08673703          	ld	a4,134(a4) # ffffffffc02d1548 <npage>
ffffffffc02024ca:	06e7f363          	bgeu	a5,a4,ffffffffc0202530 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ce:	fff80537          	lui	a0,0xfff80
ffffffffc02024d2:	97aa                	add	a5,a5,a0
ffffffffc02024d4:	079a                	slli	a5,a5,0x6
ffffffffc02024d6:	000cf517          	auipc	a0,0xcf
ffffffffc02024da:	07a53503          	ld	a0,122(a0) # ffffffffc02d1550 <pages>
ffffffffc02024de:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02024e0:	411c                	lw	a5,0(a0)
ffffffffc02024e2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02024e6:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02024e8:	cb11                	beqz	a4,ffffffffc02024fc <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02024ea:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02024ee:	12048073          	sfence.vma	s1
}
ffffffffc02024f2:	70a2                	ld	ra,40(sp)
ffffffffc02024f4:	7402                	ld	s0,32(sp)
ffffffffc02024f6:	64e2                	ld	s1,24(sp)
ffffffffc02024f8:	6145                	addi	sp,sp,48
ffffffffc02024fa:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024fc:	100027f3          	csrr	a5,sstatus
ffffffffc0202500:	8b89                	andi	a5,a5,2
ffffffffc0202502:	eb89                	bnez	a5,ffffffffc0202514 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202504:	000cf797          	auipc	a5,0xcf
ffffffffc0202508:	0547b783          	ld	a5,84(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc020250c:	739c                	ld	a5,32(a5)
ffffffffc020250e:	4585                	li	a1,1
ffffffffc0202510:	9782                	jalr	a5
    if (flag)
ffffffffc0202512:	bfe1                	j	ffffffffc02024ea <page_remove+0x52>
        intr_disable();
ffffffffc0202514:	e42a                	sd	a0,8(sp)
ffffffffc0202516:	c98fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020251a:	000cf797          	auipc	a5,0xcf
ffffffffc020251e:	03e7b783          	ld	a5,62(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc0202522:	739c                	ld	a5,32(a5)
ffffffffc0202524:	6522                	ld	a0,8(sp)
ffffffffc0202526:	4585                	li	a1,1
ffffffffc0202528:	9782                	jalr	a5
        intr_enable();
ffffffffc020252a:	c7efe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020252e:	bf75                	j	ffffffffc02024ea <page_remove+0x52>
ffffffffc0202530:	825ff0ef          	jal	ra,ffffffffc0201d54 <pa2page.part.0>

ffffffffc0202534 <page_insert>:
{
ffffffffc0202534:	7139                	addi	sp,sp,-64
ffffffffc0202536:	e852                	sd	s4,16(sp)
ffffffffc0202538:	8a32                	mv	s4,a2
ffffffffc020253a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020253c:	4605                	li	a2,1
{
ffffffffc020253e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202540:	85d2                	mv	a1,s4
{
ffffffffc0202542:	f426                	sd	s1,40(sp)
ffffffffc0202544:	fc06                	sd	ra,56(sp)
ffffffffc0202546:	f04a                	sd	s2,32(sp)
ffffffffc0202548:	ec4e                	sd	s3,24(sp)
ffffffffc020254a:	e456                	sd	s5,8(sp)
ffffffffc020254c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020254e:	8f7ff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
    if (ptep == NULL)
ffffffffc0202552:	c961                	beqz	a0,ffffffffc0202622 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202554:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202556:	611c                	ld	a5,0(a0)
ffffffffc0202558:	89aa                	mv	s3,a0
ffffffffc020255a:	0016871b          	addiw	a4,a3,1
ffffffffc020255e:	c018                	sw	a4,0(s0)
ffffffffc0202560:	0017f713          	andi	a4,a5,1
ffffffffc0202564:	ef05                	bnez	a4,ffffffffc020259c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202566:	000cf717          	auipc	a4,0xcf
ffffffffc020256a:	fea73703          	ld	a4,-22(a4) # ffffffffc02d1550 <pages>
ffffffffc020256e:	8c19                	sub	s0,s0,a4
ffffffffc0202570:	000807b7          	lui	a5,0x80
ffffffffc0202574:	8419                	srai	s0,s0,0x6
ffffffffc0202576:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202578:	042a                	slli	s0,s0,0xa
ffffffffc020257a:	8cc1                	or	s1,s1,s0
ffffffffc020257c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202580:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38f8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202584:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202588:	4501                	li	a0,0
}
ffffffffc020258a:	70e2                	ld	ra,56(sp)
ffffffffc020258c:	7442                	ld	s0,48(sp)
ffffffffc020258e:	74a2                	ld	s1,40(sp)
ffffffffc0202590:	7902                	ld	s2,32(sp)
ffffffffc0202592:	69e2                	ld	s3,24(sp)
ffffffffc0202594:	6a42                	ld	s4,16(sp)
ffffffffc0202596:	6aa2                	ld	s5,8(sp)
ffffffffc0202598:	6121                	addi	sp,sp,64
ffffffffc020259a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020259c:	078a                	slli	a5,a5,0x2
ffffffffc020259e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025a0:	000cf717          	auipc	a4,0xcf
ffffffffc02025a4:	fa873703          	ld	a4,-88(a4) # ffffffffc02d1548 <npage>
ffffffffc02025a8:	06e7ff63          	bgeu	a5,a4,ffffffffc0202626 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ac:	000cfa97          	auipc	s5,0xcf
ffffffffc02025b0:	fa4a8a93          	addi	s5,s5,-92 # ffffffffc02d1550 <pages>
ffffffffc02025b4:	000ab703          	ld	a4,0(s5)
ffffffffc02025b8:	fff80937          	lui	s2,0xfff80
ffffffffc02025bc:	993e                	add	s2,s2,a5
ffffffffc02025be:	091a                	slli	s2,s2,0x6
ffffffffc02025c0:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02025c2:	01240c63          	beq	s0,s2,ffffffffc02025da <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02025c6:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcaea68>
ffffffffc02025ca:	fff7869b          	addiw	a3,a5,-1
ffffffffc02025ce:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02025d2:	c691                	beqz	a3,ffffffffc02025de <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025d4:	120a0073          	sfence.vma	s4
}
ffffffffc02025d8:	bf59                	j	ffffffffc020256e <page_insert+0x3a>
ffffffffc02025da:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02025dc:	bf49                	j	ffffffffc020256e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025de:	100027f3          	csrr	a5,sstatus
ffffffffc02025e2:	8b89                	andi	a5,a5,2
ffffffffc02025e4:	ef91                	bnez	a5,ffffffffc0202600 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02025e6:	000cf797          	auipc	a5,0xcf
ffffffffc02025ea:	f727b783          	ld	a5,-142(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc02025ee:	739c                	ld	a5,32(a5)
ffffffffc02025f0:	4585                	li	a1,1
ffffffffc02025f2:	854a                	mv	a0,s2
ffffffffc02025f4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02025f6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025fa:	120a0073          	sfence.vma	s4
ffffffffc02025fe:	bf85                	j	ffffffffc020256e <page_insert+0x3a>
        intr_disable();
ffffffffc0202600:	baefe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202604:	000cf797          	auipc	a5,0xcf
ffffffffc0202608:	f547b783          	ld	a5,-172(a5) # ffffffffc02d1558 <pmm_manager>
ffffffffc020260c:	739c                	ld	a5,32(a5)
ffffffffc020260e:	4585                	li	a1,1
ffffffffc0202610:	854a                	mv	a0,s2
ffffffffc0202612:	9782                	jalr	a5
        intr_enable();
ffffffffc0202614:	b94fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202618:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020261c:	120a0073          	sfence.vma	s4
ffffffffc0202620:	b7b9                	j	ffffffffc020256e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202622:	5571                	li	a0,-4
ffffffffc0202624:	b79d                	j	ffffffffc020258a <page_insert+0x56>
ffffffffc0202626:	f2eff0ef          	jal	ra,ffffffffc0201d54 <pa2page.part.0>

ffffffffc020262a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020262a:	00004797          	auipc	a5,0x4
ffffffffc020262e:	49e78793          	addi	a5,a5,1182 # ffffffffc0206ac8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202632:	638c                	ld	a1,0(a5)
{
ffffffffc0202634:	7159                	addi	sp,sp,-112
ffffffffc0202636:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202638:	00004517          	auipc	a0,0x4
ffffffffc020263c:	63850513          	addi	a0,a0,1592 # ffffffffc0206c70 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202640:	000cfb17          	auipc	s6,0xcf
ffffffffc0202644:	f18b0b13          	addi	s6,s6,-232 # ffffffffc02d1558 <pmm_manager>
{
ffffffffc0202648:	f486                	sd	ra,104(sp)
ffffffffc020264a:	e8ca                	sd	s2,80(sp)
ffffffffc020264c:	e4ce                	sd	s3,72(sp)
ffffffffc020264e:	f0a2                	sd	s0,96(sp)
ffffffffc0202650:	eca6                	sd	s1,88(sp)
ffffffffc0202652:	e0d2                	sd	s4,64(sp)
ffffffffc0202654:	fc56                	sd	s5,56(sp)
ffffffffc0202656:	f45e                	sd	s7,40(sp)
ffffffffc0202658:	f062                	sd	s8,32(sp)
ffffffffc020265a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020265c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202660:	b39fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc0202664:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202668:	000cf997          	auipc	s3,0xcf
ffffffffc020266c:	ef898993          	addi	s3,s3,-264 # ffffffffc02d1560 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202670:	679c                	ld	a5,8(a5)
ffffffffc0202672:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202674:	57f5                	li	a5,-3
ffffffffc0202676:	07fa                	slli	a5,a5,0x1e
ffffffffc0202678:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020267c:	b18fe0ef          	jal	ra,ffffffffc0200994 <get_memory_base>
ffffffffc0202680:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202682:	b1cfe0ef          	jal	ra,ffffffffc020099e <get_memory_size>
    if (mem_size == 0)
ffffffffc0202686:	200505e3          	beqz	a0,ffffffffc0203090 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020268a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020268c:	00004517          	auipc	a0,0x4
ffffffffc0202690:	61c50513          	addi	a0,a0,1564 # ffffffffc0206ca8 <default_pmm_manager+0x1e0>
ffffffffc0202694:	b05fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202698:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020269c:	fff40693          	addi	a3,s0,-1
ffffffffc02026a0:	864a                	mv	a2,s2
ffffffffc02026a2:	85a6                	mv	a1,s1
ffffffffc02026a4:	00004517          	auipc	a0,0x4
ffffffffc02026a8:	61c50513          	addi	a0,a0,1564 # ffffffffc0206cc0 <default_pmm_manager+0x1f8>
ffffffffc02026ac:	aedfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02026b0:	c8000737          	lui	a4,0xc8000
ffffffffc02026b4:	87a2                	mv	a5,s0
ffffffffc02026b6:	54876163          	bltu	a4,s0,ffffffffc0202bf8 <pmm_init+0x5ce>
ffffffffc02026ba:	757d                	lui	a0,0xfffff
ffffffffc02026bc:	000d0617          	auipc	a2,0xd0
ffffffffc02026c0:	edb60613          	addi	a2,a2,-293 # ffffffffc02d2597 <end+0xfff>
ffffffffc02026c4:	8e69                	and	a2,a2,a0
ffffffffc02026c6:	000cf497          	auipc	s1,0xcf
ffffffffc02026ca:	e8248493          	addi	s1,s1,-382 # ffffffffc02d1548 <npage>
ffffffffc02026ce:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026d2:	000cfb97          	auipc	s7,0xcf
ffffffffc02026d6:	e7eb8b93          	addi	s7,s7,-386 # ffffffffc02d1550 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02026da:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026dc:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026e0:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026e4:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026e6:	02f50863          	beq	a0,a5,ffffffffc0202716 <pmm_init+0xec>
ffffffffc02026ea:	4781                	li	a5,0
ffffffffc02026ec:	4585                	li	a1,1
ffffffffc02026ee:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02026f2:	00679513          	slli	a0,a5,0x6
ffffffffc02026f6:	9532                	add	a0,a0,a2
ffffffffc02026f8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd2da70>
ffffffffc02026fc:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202700:	6088                	ld	a0,0(s1)
ffffffffc0202702:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202704:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202708:	00d50733          	add	a4,a0,a3
ffffffffc020270c:	fee7e3e3          	bltu	a5,a4,ffffffffc02026f2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202710:	071a                	slli	a4,a4,0x6
ffffffffc0202712:	00e606b3          	add	a3,a2,a4
ffffffffc0202716:	c02007b7          	lui	a5,0xc0200
ffffffffc020271a:	2ef6ece3          	bltu	a3,a5,ffffffffc0203212 <pmm_init+0xbe8>
ffffffffc020271e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202722:	77fd                	lui	a5,0xfffff
ffffffffc0202724:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202726:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202728:	5086eb63          	bltu	a3,s0,ffffffffc0202c3e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020272c:	00004517          	auipc	a0,0x4
ffffffffc0202730:	5bc50513          	addi	a0,a0,1468 # ffffffffc0206ce8 <default_pmm_manager+0x220>
ffffffffc0202734:	a65fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202738:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020273c:	000cf917          	auipc	s2,0xcf
ffffffffc0202740:	e0490913          	addi	s2,s2,-508 # ffffffffc02d1540 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202744:	7b9c                	ld	a5,48(a5)
ffffffffc0202746:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202748:	00004517          	auipc	a0,0x4
ffffffffc020274c:	5b850513          	addi	a0,a0,1464 # ffffffffc0206d00 <default_pmm_manager+0x238>
ffffffffc0202750:	a49fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202754:	00009697          	auipc	a3,0x9
ffffffffc0202758:	8ac68693          	addi	a3,a3,-1876 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc020275c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202760:	c02007b7          	lui	a5,0xc0200
ffffffffc0202764:	28f6ebe3          	bltu	a3,a5,ffffffffc02031fa <pmm_init+0xbd0>
ffffffffc0202768:	0009b783          	ld	a5,0(s3)
ffffffffc020276c:	8e9d                	sub	a3,a3,a5
ffffffffc020276e:	000cf797          	auipc	a5,0xcf
ffffffffc0202772:	dcd7b523          	sd	a3,-566(a5) # ffffffffc02d1538 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202776:	100027f3          	csrr	a5,sstatus
ffffffffc020277a:	8b89                	andi	a5,a5,2
ffffffffc020277c:	4a079763          	bnez	a5,ffffffffc0202c2a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202780:	000b3783          	ld	a5,0(s6)
ffffffffc0202784:	779c                	ld	a5,40(a5)
ffffffffc0202786:	9782                	jalr	a5
ffffffffc0202788:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020278a:	6098                	ld	a4,0(s1)
ffffffffc020278c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202790:	83b1                	srli	a5,a5,0xc
ffffffffc0202792:	66e7e363          	bltu	a5,a4,ffffffffc0202df8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202796:	00093503          	ld	a0,0(s2)
ffffffffc020279a:	62050f63          	beqz	a0,ffffffffc0202dd8 <pmm_init+0x7ae>
ffffffffc020279e:	03451793          	slli	a5,a0,0x34
ffffffffc02027a2:	62079b63          	bnez	a5,ffffffffc0202dd8 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02027a6:	4601                	li	a2,0
ffffffffc02027a8:	4581                	li	a1,0
ffffffffc02027aa:	8c3ff0ef          	jal	ra,ffffffffc020206c <get_page>
ffffffffc02027ae:	60051563          	bnez	a0,ffffffffc0202db8 <pmm_init+0x78e>
ffffffffc02027b2:	100027f3          	csrr	a5,sstatus
ffffffffc02027b6:	8b89                	andi	a5,a5,2
ffffffffc02027b8:	44079e63          	bnez	a5,ffffffffc0202c14 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027bc:	000b3783          	ld	a5,0(s6)
ffffffffc02027c0:	4505                	li	a0,1
ffffffffc02027c2:	6f9c                	ld	a5,24(a5)
ffffffffc02027c4:	9782                	jalr	a5
ffffffffc02027c6:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02027c8:	00093503          	ld	a0,0(s2)
ffffffffc02027cc:	4681                	li	a3,0
ffffffffc02027ce:	4601                	li	a2,0
ffffffffc02027d0:	85d2                	mv	a1,s4
ffffffffc02027d2:	d63ff0ef          	jal	ra,ffffffffc0202534 <page_insert>
ffffffffc02027d6:	26051ae3          	bnez	a0,ffffffffc020324a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02027da:	00093503          	ld	a0,0(s2)
ffffffffc02027de:	4601                	li	a2,0
ffffffffc02027e0:	4581                	li	a1,0
ffffffffc02027e2:	e62ff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
ffffffffc02027e6:	240502e3          	beqz	a0,ffffffffc020322a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02027ea:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02027ec:	0017f713          	andi	a4,a5,1
ffffffffc02027f0:	5a070263          	beqz	a4,ffffffffc0202d94 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02027f4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02027f6:	078a                	slli	a5,a5,0x2
ffffffffc02027f8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027fa:	58e7fb63          	bgeu	a5,a4,ffffffffc0202d90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02027fe:	000bb683          	ld	a3,0(s7)
ffffffffc0202802:	fff80637          	lui	a2,0xfff80
ffffffffc0202806:	97b2                	add	a5,a5,a2
ffffffffc0202808:	079a                	slli	a5,a5,0x6
ffffffffc020280a:	97b6                	add	a5,a5,a3
ffffffffc020280c:	14fa17e3          	bne	s4,a5,ffffffffc020315a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202810:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>
ffffffffc0202814:	4785                	li	a5,1
ffffffffc0202816:	12f692e3          	bne	a3,a5,ffffffffc020313a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020281a:	00093503          	ld	a0,0(s2)
ffffffffc020281e:	77fd                	lui	a5,0xfffff
ffffffffc0202820:	6114                	ld	a3,0(a0)
ffffffffc0202822:	068a                	slli	a3,a3,0x2
ffffffffc0202824:	8efd                	and	a3,a3,a5
ffffffffc0202826:	00c6d613          	srli	a2,a3,0xc
ffffffffc020282a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203122 <pmm_init+0xaf8>
ffffffffc020282e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202832:	96e2                	add	a3,a3,s8
ffffffffc0202834:	0006ba83          	ld	s5,0(a3)
ffffffffc0202838:	0a8a                	slli	s5,s5,0x2
ffffffffc020283a:	00fafab3          	and	s5,s5,a5
ffffffffc020283e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202842:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203108 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202846:	4601                	li	a2,0
ffffffffc0202848:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020284a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020284c:	df8ff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202850:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202852:	55551363          	bne	a0,s5,ffffffffc0202d98 <pmm_init+0x76e>
ffffffffc0202856:	100027f3          	csrr	a5,sstatus
ffffffffc020285a:	8b89                	andi	a5,a5,2
ffffffffc020285c:	3a079163          	bnez	a5,ffffffffc0202bfe <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202860:	000b3783          	ld	a5,0(s6)
ffffffffc0202864:	4505                	li	a0,1
ffffffffc0202866:	6f9c                	ld	a5,24(a5)
ffffffffc0202868:	9782                	jalr	a5
ffffffffc020286a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020286c:	00093503          	ld	a0,0(s2)
ffffffffc0202870:	46d1                	li	a3,20
ffffffffc0202872:	6605                	lui	a2,0x1
ffffffffc0202874:	85e2                	mv	a1,s8
ffffffffc0202876:	cbfff0ef          	jal	ra,ffffffffc0202534 <page_insert>
ffffffffc020287a:	060517e3          	bnez	a0,ffffffffc02030e8 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020287e:	00093503          	ld	a0,0(s2)
ffffffffc0202882:	4601                	li	a2,0
ffffffffc0202884:	6585                	lui	a1,0x1
ffffffffc0202886:	dbeff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
ffffffffc020288a:	02050fe3          	beqz	a0,ffffffffc02030c8 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020288e:	611c                	ld	a5,0(a0)
ffffffffc0202890:	0107f713          	andi	a4,a5,16
ffffffffc0202894:	7c070e63          	beqz	a4,ffffffffc0203070 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202898:	8b91                	andi	a5,a5,4
ffffffffc020289a:	7a078b63          	beqz	a5,ffffffffc0203050 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020289e:	00093503          	ld	a0,0(s2)
ffffffffc02028a2:	611c                	ld	a5,0(a0)
ffffffffc02028a4:	8bc1                	andi	a5,a5,16
ffffffffc02028a6:	78078563          	beqz	a5,ffffffffc0203030 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02028aa:	000c2703          	lw	a4,0(s8)
ffffffffc02028ae:	4785                	li	a5,1
ffffffffc02028b0:	76f71063          	bne	a4,a5,ffffffffc0203010 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02028b4:	4681                	li	a3,0
ffffffffc02028b6:	6605                	lui	a2,0x1
ffffffffc02028b8:	85d2                	mv	a1,s4
ffffffffc02028ba:	c7bff0ef          	jal	ra,ffffffffc0202534 <page_insert>
ffffffffc02028be:	72051963          	bnez	a0,ffffffffc0202ff0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02028c2:	000a2703          	lw	a4,0(s4)
ffffffffc02028c6:	4789                	li	a5,2
ffffffffc02028c8:	70f71463          	bne	a4,a5,ffffffffc0202fd0 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02028cc:	000c2783          	lw	a5,0(s8)
ffffffffc02028d0:	6e079063          	bnez	a5,ffffffffc0202fb0 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02028d4:	00093503          	ld	a0,0(s2)
ffffffffc02028d8:	4601                	li	a2,0
ffffffffc02028da:	6585                	lui	a1,0x1
ffffffffc02028dc:	d68ff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
ffffffffc02028e0:	6a050863          	beqz	a0,ffffffffc0202f90 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02028e4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028e6:	00177793          	andi	a5,a4,1
ffffffffc02028ea:	4a078563          	beqz	a5,ffffffffc0202d94 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028ee:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028f0:	00271793          	slli	a5,a4,0x2
ffffffffc02028f4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028f6:	48d7fd63          	bgeu	a5,a3,ffffffffc0202d90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028fa:	000bb683          	ld	a3,0(s7)
ffffffffc02028fe:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202902:	97d6                	add	a5,a5,s5
ffffffffc0202904:	079a                	slli	a5,a5,0x6
ffffffffc0202906:	97b6                	add	a5,a5,a3
ffffffffc0202908:	66fa1463          	bne	s4,a5,ffffffffc0202f70 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc020290c:	8b41                	andi	a4,a4,16
ffffffffc020290e:	64071163          	bnez	a4,ffffffffc0202f50 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202912:	00093503          	ld	a0,0(s2)
ffffffffc0202916:	4581                	li	a1,0
ffffffffc0202918:	b81ff0ef          	jal	ra,ffffffffc0202498 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020291c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202920:	4785                	li	a5,1
ffffffffc0202922:	60fc9763          	bne	s9,a5,ffffffffc0202f30 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202926:	000c2783          	lw	a5,0(s8)
ffffffffc020292a:	5e079363          	bnez	a5,ffffffffc0202f10 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020292e:	00093503          	ld	a0,0(s2)
ffffffffc0202932:	6585                	lui	a1,0x1
ffffffffc0202934:	b65ff0ef          	jal	ra,ffffffffc0202498 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202938:	000a2783          	lw	a5,0(s4)
ffffffffc020293c:	52079a63          	bnez	a5,ffffffffc0202e70 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202940:	000c2783          	lw	a5,0(s8)
ffffffffc0202944:	50079663          	bnez	a5,ffffffffc0202e50 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202948:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020294c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020294e:	000a3683          	ld	a3,0(s4)
ffffffffc0202952:	068a                	slli	a3,a3,0x2
ffffffffc0202954:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202956:	42b6fd63          	bgeu	a3,a1,ffffffffc0202d90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020295a:	000bb503          	ld	a0,0(s7)
ffffffffc020295e:	96d6                	add	a3,a3,s5
ffffffffc0202960:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202962:	00d507b3          	add	a5,a0,a3
ffffffffc0202966:	439c                	lw	a5,0(a5)
ffffffffc0202968:	4d979463          	bne	a5,s9,ffffffffc0202e30 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc020296c:	8699                	srai	a3,a3,0x6
ffffffffc020296e:	00080637          	lui	a2,0x80
ffffffffc0202972:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202974:	00c69713          	slli	a4,a3,0xc
ffffffffc0202978:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020297a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020297c:	48b77e63          	bgeu	a4,a1,ffffffffc0202e18 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202980:	0009b703          	ld	a4,0(s3)
ffffffffc0202984:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202986:	629c                	ld	a5,0(a3)
ffffffffc0202988:	078a                	slli	a5,a5,0x2
ffffffffc020298a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020298c:	40b7f263          	bgeu	a5,a1,ffffffffc0202d90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202990:	8f91                	sub	a5,a5,a2
ffffffffc0202992:	079a                	slli	a5,a5,0x6
ffffffffc0202994:	953e                	add	a0,a0,a5
ffffffffc0202996:	100027f3          	csrr	a5,sstatus
ffffffffc020299a:	8b89                	andi	a5,a5,2
ffffffffc020299c:	30079963          	bnez	a5,ffffffffc0202cae <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02029a0:	000b3783          	ld	a5,0(s6)
ffffffffc02029a4:	4585                	li	a1,1
ffffffffc02029a6:	739c                	ld	a5,32(a5)
ffffffffc02029a8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02029aa:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02029ae:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02029b0:	078a                	slli	a5,a5,0x2
ffffffffc02029b2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029b4:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202d90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029b8:	000bb503          	ld	a0,0(s7)
ffffffffc02029bc:	fff80737          	lui	a4,0xfff80
ffffffffc02029c0:	97ba                	add	a5,a5,a4
ffffffffc02029c2:	079a                	slli	a5,a5,0x6
ffffffffc02029c4:	953e                	add	a0,a0,a5
ffffffffc02029c6:	100027f3          	csrr	a5,sstatus
ffffffffc02029ca:	8b89                	andi	a5,a5,2
ffffffffc02029cc:	2c079563          	bnez	a5,ffffffffc0202c96 <pmm_init+0x66c>
ffffffffc02029d0:	000b3783          	ld	a5,0(s6)
ffffffffc02029d4:	4585                	li	a1,1
ffffffffc02029d6:	739c                	ld	a5,32(a5)
ffffffffc02029d8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02029da:	00093783          	ld	a5,0(s2)
ffffffffc02029de:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd2da68>
    asm volatile("sfence.vma");
ffffffffc02029e2:	12000073          	sfence.vma
ffffffffc02029e6:	100027f3          	csrr	a5,sstatus
ffffffffc02029ea:	8b89                	andi	a5,a5,2
ffffffffc02029ec:	28079b63          	bnez	a5,ffffffffc0202c82 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc02029f0:	000b3783          	ld	a5,0(s6)
ffffffffc02029f4:	779c                	ld	a5,40(a5)
ffffffffc02029f6:	9782                	jalr	a5
ffffffffc02029f8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02029fa:	4b441b63          	bne	s0,s4,ffffffffc0202eb0 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02029fe:	00004517          	auipc	a0,0x4
ffffffffc0202a02:	62a50513          	addi	a0,a0,1578 # ffffffffc0207028 <default_pmm_manager+0x560>
ffffffffc0202a06:	f92fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0202a0a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a0e:	8b89                	andi	a5,a5,2
ffffffffc0202a10:	24079f63          	bnez	a5,ffffffffc0202c6e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a14:	000b3783          	ld	a5,0(s6)
ffffffffc0202a18:	779c                	ld	a5,40(a5)
ffffffffc0202a1a:	9782                	jalr	a5
ffffffffc0202a1c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a1e:	6098                	ld	a4,0(s1)
ffffffffc0202a20:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a24:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a26:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a2a:	6a05                	lui	s4,0x1
ffffffffc0202a2c:	02f47c63          	bgeu	s0,a5,ffffffffc0202a64 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202a30:	00c45793          	srli	a5,s0,0xc
ffffffffc0202a34:	00093503          	ld	a0,0(s2)
ffffffffc0202a38:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202d36 <pmm_init+0x70c>
ffffffffc0202a3c:	0009b583          	ld	a1,0(s3)
ffffffffc0202a40:	4601                	li	a2,0
ffffffffc0202a42:	95a2                	add	a1,a1,s0
ffffffffc0202a44:	c00ff0ef          	jal	ra,ffffffffc0201e44 <get_pte>
ffffffffc0202a48:	32050463          	beqz	a0,ffffffffc0202d70 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a4c:	611c                	ld	a5,0(a0)
ffffffffc0202a4e:	078a                	slli	a5,a5,0x2
ffffffffc0202a50:	0157f7b3          	and	a5,a5,s5
ffffffffc0202a54:	2e879e63          	bne	a5,s0,ffffffffc0202d50 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a58:	6098                	ld	a4,0(s1)
ffffffffc0202a5a:	9452                	add	s0,s0,s4
ffffffffc0202a5c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a60:	fcf468e3          	bltu	s0,a5,ffffffffc0202a30 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202a64:	00093783          	ld	a5,0(s2)
ffffffffc0202a68:	639c                	ld	a5,0(a5)
ffffffffc0202a6a:	42079363          	bnez	a5,ffffffffc0202e90 <pmm_init+0x866>
ffffffffc0202a6e:	100027f3          	csrr	a5,sstatus
ffffffffc0202a72:	8b89                	andi	a5,a5,2
ffffffffc0202a74:	24079963          	bnez	a5,ffffffffc0202cc6 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a78:	000b3783          	ld	a5,0(s6)
ffffffffc0202a7c:	4505                	li	a0,1
ffffffffc0202a7e:	6f9c                	ld	a5,24(a5)
ffffffffc0202a80:	9782                	jalr	a5
ffffffffc0202a82:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a84:	00093503          	ld	a0,0(s2)
ffffffffc0202a88:	4699                	li	a3,6
ffffffffc0202a8a:	10000613          	li	a2,256
ffffffffc0202a8e:	85d2                	mv	a1,s4
ffffffffc0202a90:	aa5ff0ef          	jal	ra,ffffffffc0202534 <page_insert>
ffffffffc0202a94:	44051e63          	bnez	a0,ffffffffc0202ef0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202a98:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>
ffffffffc0202a9c:	4785                	li	a5,1
ffffffffc0202a9e:	42f71963          	bne	a4,a5,ffffffffc0202ed0 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202aa2:	00093503          	ld	a0,0(s2)
ffffffffc0202aa6:	6405                	lui	s0,0x1
ffffffffc0202aa8:	4699                	li	a3,6
ffffffffc0202aaa:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e30>
ffffffffc0202aae:	85d2                	mv	a1,s4
ffffffffc0202ab0:	a85ff0ef          	jal	ra,ffffffffc0202534 <page_insert>
ffffffffc0202ab4:	72051363          	bnez	a0,ffffffffc02031da <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202ab8:	000a2703          	lw	a4,0(s4)
ffffffffc0202abc:	4789                	li	a5,2
ffffffffc0202abe:	6ef71e63          	bne	a4,a5,ffffffffc02031ba <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202ac2:	00004597          	auipc	a1,0x4
ffffffffc0202ac6:	6ae58593          	addi	a1,a1,1710 # ffffffffc0207170 <default_pmm_manager+0x6a8>
ffffffffc0202aca:	10000513          	li	a0,256
ffffffffc0202ace:	12e030ef          	jal	ra,ffffffffc0205bfc <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ad2:	10040593          	addi	a1,s0,256
ffffffffc0202ad6:	10000513          	li	a0,256
ffffffffc0202ada:	134030ef          	jal	ra,ffffffffc0205c0e <strcmp>
ffffffffc0202ade:	6a051e63          	bnez	a0,ffffffffc020319a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202ae2:	000bb683          	ld	a3,0(s7)
ffffffffc0202ae6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202aea:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202aec:	40da06b3          	sub	a3,s4,a3
ffffffffc0202af0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202af2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202af4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202af6:	8031                	srli	s0,s0,0xc
ffffffffc0202af8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202afc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202afe:	30f77d63          	bgeu	a4,a5,ffffffffc0202e18 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b02:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b06:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b0a:	96be                	add	a3,a3,a5
ffffffffc0202b0c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b10:	0b6030ef          	jal	ra,ffffffffc0205bc6 <strlen>
ffffffffc0202b14:	66051363          	bnez	a0,ffffffffc020317a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202b18:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b1c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b1e:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd2da68>
ffffffffc0202b22:	068a                	slli	a3,a3,0x2
ffffffffc0202b24:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b26:	26f6f563          	bgeu	a3,a5,ffffffffc0202d90 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202b2a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b2c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b2e:	2ef47563          	bgeu	s0,a5,ffffffffc0202e18 <pmm_init+0x7ee>
ffffffffc0202b32:	0009b403          	ld	s0,0(s3)
ffffffffc0202b36:	9436                	add	s0,s0,a3
ffffffffc0202b38:	100027f3          	csrr	a5,sstatus
ffffffffc0202b3c:	8b89                	andi	a5,a5,2
ffffffffc0202b3e:	1e079163          	bnez	a5,ffffffffc0202d20 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202b42:	000b3783          	ld	a5,0(s6)
ffffffffc0202b46:	4585                	li	a1,1
ffffffffc0202b48:	8552                	mv	a0,s4
ffffffffc0202b4a:	739c                	ld	a5,32(a5)
ffffffffc0202b4c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b4e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202b50:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b52:	078a                	slli	a5,a5,0x2
ffffffffc0202b54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b56:	22e7fd63          	bgeu	a5,a4,ffffffffc0202d90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b5a:	000bb503          	ld	a0,0(s7)
ffffffffc0202b5e:	fff80737          	lui	a4,0xfff80
ffffffffc0202b62:	97ba                	add	a5,a5,a4
ffffffffc0202b64:	079a                	slli	a5,a5,0x6
ffffffffc0202b66:	953e                	add	a0,a0,a5
ffffffffc0202b68:	100027f3          	csrr	a5,sstatus
ffffffffc0202b6c:	8b89                	andi	a5,a5,2
ffffffffc0202b6e:	18079d63          	bnez	a5,ffffffffc0202d08 <pmm_init+0x6de>
ffffffffc0202b72:	000b3783          	ld	a5,0(s6)
ffffffffc0202b76:	4585                	li	a1,1
ffffffffc0202b78:	739c                	ld	a5,32(a5)
ffffffffc0202b7a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b7c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202b80:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b82:	078a                	slli	a5,a5,0x2
ffffffffc0202b84:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b86:	20e7f563          	bgeu	a5,a4,ffffffffc0202d90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b8a:	000bb503          	ld	a0,0(s7)
ffffffffc0202b8e:	fff80737          	lui	a4,0xfff80
ffffffffc0202b92:	97ba                	add	a5,a5,a4
ffffffffc0202b94:	079a                	slli	a5,a5,0x6
ffffffffc0202b96:	953e                	add	a0,a0,a5
ffffffffc0202b98:	100027f3          	csrr	a5,sstatus
ffffffffc0202b9c:	8b89                	andi	a5,a5,2
ffffffffc0202b9e:	14079963          	bnez	a5,ffffffffc0202cf0 <pmm_init+0x6c6>
ffffffffc0202ba2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ba6:	4585                	li	a1,1
ffffffffc0202ba8:	739c                	ld	a5,32(a5)
ffffffffc0202baa:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202bac:	00093783          	ld	a5,0(s2)
ffffffffc0202bb0:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202bb4:	12000073          	sfence.vma
ffffffffc0202bb8:	100027f3          	csrr	a5,sstatus
ffffffffc0202bbc:	8b89                	andi	a5,a5,2
ffffffffc0202bbe:	10079f63          	bnez	a5,ffffffffc0202cdc <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202bc6:	779c                	ld	a5,40(a5)
ffffffffc0202bc8:	9782                	jalr	a5
ffffffffc0202bca:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202bcc:	4c8c1e63          	bne	s8,s0,ffffffffc02030a8 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202bd0:	00004517          	auipc	a0,0x4
ffffffffc0202bd4:	61850513          	addi	a0,a0,1560 # ffffffffc02071e8 <default_pmm_manager+0x720>
ffffffffc0202bd8:	dc0fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202bdc:	7406                	ld	s0,96(sp)
ffffffffc0202bde:	70a6                	ld	ra,104(sp)
ffffffffc0202be0:	64e6                	ld	s1,88(sp)
ffffffffc0202be2:	6946                	ld	s2,80(sp)
ffffffffc0202be4:	69a6                	ld	s3,72(sp)
ffffffffc0202be6:	6a06                	ld	s4,64(sp)
ffffffffc0202be8:	7ae2                	ld	s5,56(sp)
ffffffffc0202bea:	7b42                	ld	s6,48(sp)
ffffffffc0202bec:	7ba2                	ld	s7,40(sp)
ffffffffc0202bee:	7c02                	ld	s8,32(sp)
ffffffffc0202bf0:	6ce2                	ld	s9,24(sp)
ffffffffc0202bf2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202bf4:	f97fe06f          	j	ffffffffc0201b8a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202bf8:	c80007b7          	lui	a5,0xc8000
ffffffffc0202bfc:	bc7d                	j	ffffffffc02026ba <pmm_init+0x90>
        intr_disable();
ffffffffc0202bfe:	db1fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c02:	000b3783          	ld	a5,0(s6)
ffffffffc0202c06:	4505                	li	a0,1
ffffffffc0202c08:	6f9c                	ld	a5,24(a5)
ffffffffc0202c0a:	9782                	jalr	a5
ffffffffc0202c0c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c0e:	d9bfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c12:	b9a9                	j	ffffffffc020286c <pmm_init+0x242>
        intr_disable();
ffffffffc0202c14:	d9bfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c18:	000b3783          	ld	a5,0(s6)
ffffffffc0202c1c:	4505                	li	a0,1
ffffffffc0202c1e:	6f9c                	ld	a5,24(a5)
ffffffffc0202c20:	9782                	jalr	a5
ffffffffc0202c22:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c24:	d85fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c28:	b645                	j	ffffffffc02027c8 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202c2a:	d85fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c32:	779c                	ld	a5,40(a5)
ffffffffc0202c34:	9782                	jalr	a5
ffffffffc0202c36:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202c38:	d71fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c3c:	b6b9                	j	ffffffffc020278a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202c3e:	6705                	lui	a4,0x1
ffffffffc0202c40:	177d                	addi	a4,a4,-1
ffffffffc0202c42:	96ba                	add	a3,a3,a4
ffffffffc0202c44:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202c46:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202c4a:	14a77363          	bgeu	a4,a0,ffffffffc0202d90 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202c4e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202c52:	fff80537          	lui	a0,0xfff80
ffffffffc0202c56:	972a                	add	a4,a4,a0
ffffffffc0202c58:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202c5a:	8c1d                	sub	s0,s0,a5
ffffffffc0202c5c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202c60:	00c45593          	srli	a1,s0,0xc
ffffffffc0202c64:	9532                	add	a0,a0,a2
ffffffffc0202c66:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202c68:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202c6c:	b4c1                	j	ffffffffc020272c <pmm_init+0x102>
        intr_disable();
ffffffffc0202c6e:	d41fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c72:	000b3783          	ld	a5,0(s6)
ffffffffc0202c76:	779c                	ld	a5,40(a5)
ffffffffc0202c78:	9782                	jalr	a5
ffffffffc0202c7a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c7c:	d2dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c80:	bb79                	j	ffffffffc0202a1e <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202c82:	d2dfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c86:	000b3783          	ld	a5,0(s6)
ffffffffc0202c8a:	779c                	ld	a5,40(a5)
ffffffffc0202c8c:	9782                	jalr	a5
ffffffffc0202c8e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c90:	d19fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c94:	b39d                	j	ffffffffc02029fa <pmm_init+0x3d0>
ffffffffc0202c96:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202c98:	d17fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202c9c:	000b3783          	ld	a5,0(s6)
ffffffffc0202ca0:	6522                	ld	a0,8(sp)
ffffffffc0202ca2:	4585                	li	a1,1
ffffffffc0202ca4:	739c                	ld	a5,32(a5)
ffffffffc0202ca6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ca8:	d01fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cac:	b33d                	j	ffffffffc02029da <pmm_init+0x3b0>
ffffffffc0202cae:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cb0:	cfffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202cb4:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb8:	6522                	ld	a0,8(sp)
ffffffffc0202cba:	4585                	li	a1,1
ffffffffc0202cbc:	739c                	ld	a5,32(a5)
ffffffffc0202cbe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cc0:	ce9fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cc4:	b1dd                	j	ffffffffc02029aa <pmm_init+0x380>
        intr_disable();
ffffffffc0202cc6:	ce9fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cca:	000b3783          	ld	a5,0(s6)
ffffffffc0202cce:	4505                	li	a0,1
ffffffffc0202cd0:	6f9c                	ld	a5,24(a5)
ffffffffc0202cd2:	9782                	jalr	a5
ffffffffc0202cd4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cd6:	cd3fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cda:	b36d                	j	ffffffffc0202a84 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202cdc:	cd3fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ce0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce4:	779c                	ld	a5,40(a5)
ffffffffc0202ce6:	9782                	jalr	a5
ffffffffc0202ce8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202cea:	cbffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cee:	bdf9                	j	ffffffffc0202bcc <pmm_init+0x5a2>
ffffffffc0202cf0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cf2:	cbdfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202cf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfa:	6522                	ld	a0,8(sp)
ffffffffc0202cfc:	4585                	li	a1,1
ffffffffc0202cfe:	739c                	ld	a5,32(a5)
ffffffffc0202d00:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d02:	ca7fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d06:	b55d                	j	ffffffffc0202bac <pmm_init+0x582>
ffffffffc0202d08:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d0a:	ca5fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d0e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d12:	6522                	ld	a0,8(sp)
ffffffffc0202d14:	4585                	li	a1,1
ffffffffc0202d16:	739c                	ld	a5,32(a5)
ffffffffc0202d18:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d1a:	c8ffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d1e:	bdb9                	j	ffffffffc0202b7c <pmm_init+0x552>
        intr_disable();
ffffffffc0202d20:	c8ffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d24:	000b3783          	ld	a5,0(s6)
ffffffffc0202d28:	4585                	li	a1,1
ffffffffc0202d2a:	8552                	mv	a0,s4
ffffffffc0202d2c:	739c                	ld	a5,32(a5)
ffffffffc0202d2e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d30:	c79fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d34:	bd29                	j	ffffffffc0202b4e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d36:	86a2                	mv	a3,s0
ffffffffc0202d38:	00004617          	auipc	a2,0x4
ffffffffc0202d3c:	dc860613          	addi	a2,a2,-568 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0202d40:	25f00593          	li	a1,607
ffffffffc0202d44:	00004517          	auipc	a0,0x4
ffffffffc0202d48:	ed450513          	addi	a0,a0,-300 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202d4c:	f46fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d50:	00004697          	auipc	a3,0x4
ffffffffc0202d54:	33868693          	addi	a3,a3,824 # ffffffffc0207088 <default_pmm_manager+0x5c0>
ffffffffc0202d58:	00004617          	auipc	a2,0x4
ffffffffc0202d5c:	9c060613          	addi	a2,a2,-1600 # ffffffffc0206718 <commands+0x818>
ffffffffc0202d60:	26000593          	li	a1,608
ffffffffc0202d64:	00004517          	auipc	a0,0x4
ffffffffc0202d68:	eb450513          	addi	a0,a0,-332 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202d6c:	f26fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d70:	00004697          	auipc	a3,0x4
ffffffffc0202d74:	2d868693          	addi	a3,a3,728 # ffffffffc0207048 <default_pmm_manager+0x580>
ffffffffc0202d78:	00004617          	auipc	a2,0x4
ffffffffc0202d7c:	9a060613          	addi	a2,a2,-1632 # ffffffffc0206718 <commands+0x818>
ffffffffc0202d80:	25f00593          	li	a1,607
ffffffffc0202d84:	00004517          	auipc	a0,0x4
ffffffffc0202d88:	e9450513          	addi	a0,a0,-364 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202d8c:	f06fd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202d90:	fc5fe0ef          	jal	ra,ffffffffc0201d54 <pa2page.part.0>
ffffffffc0202d94:	fddfe0ef          	jal	ra,ffffffffc0201d70 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d98:	00004697          	auipc	a3,0x4
ffffffffc0202d9c:	0a868693          	addi	a3,a3,168 # ffffffffc0206e40 <default_pmm_manager+0x378>
ffffffffc0202da0:	00004617          	auipc	a2,0x4
ffffffffc0202da4:	97860613          	addi	a2,a2,-1672 # ffffffffc0206718 <commands+0x818>
ffffffffc0202da8:	22f00593          	li	a1,559
ffffffffc0202dac:	00004517          	auipc	a0,0x4
ffffffffc0202db0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202db4:	edefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202db8:	00004697          	auipc	a3,0x4
ffffffffc0202dbc:	fc868693          	addi	a3,a3,-56 # ffffffffc0206d80 <default_pmm_manager+0x2b8>
ffffffffc0202dc0:	00004617          	auipc	a2,0x4
ffffffffc0202dc4:	95860613          	addi	a2,a2,-1704 # ffffffffc0206718 <commands+0x818>
ffffffffc0202dc8:	22200593          	li	a1,546
ffffffffc0202dcc:	00004517          	auipc	a0,0x4
ffffffffc0202dd0:	e4c50513          	addi	a0,a0,-436 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202dd4:	ebefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202dd8:	00004697          	auipc	a3,0x4
ffffffffc0202ddc:	f6868693          	addi	a3,a3,-152 # ffffffffc0206d40 <default_pmm_manager+0x278>
ffffffffc0202de0:	00004617          	auipc	a2,0x4
ffffffffc0202de4:	93860613          	addi	a2,a2,-1736 # ffffffffc0206718 <commands+0x818>
ffffffffc0202de8:	22100593          	li	a1,545
ffffffffc0202dec:	00004517          	auipc	a0,0x4
ffffffffc0202df0:	e2c50513          	addi	a0,a0,-468 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202df4:	e9efd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202df8:	00004697          	auipc	a3,0x4
ffffffffc0202dfc:	f2868693          	addi	a3,a3,-216 # ffffffffc0206d20 <default_pmm_manager+0x258>
ffffffffc0202e00:	00004617          	auipc	a2,0x4
ffffffffc0202e04:	91860613          	addi	a2,a2,-1768 # ffffffffc0206718 <commands+0x818>
ffffffffc0202e08:	22000593          	li	a1,544
ffffffffc0202e0c:	00004517          	auipc	a0,0x4
ffffffffc0202e10:	e0c50513          	addi	a0,a0,-500 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202e14:	e7efd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202e18:	00004617          	auipc	a2,0x4
ffffffffc0202e1c:	ce860613          	addi	a2,a2,-792 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0202e20:	07100593          	li	a1,113
ffffffffc0202e24:	00004517          	auipc	a0,0x4
ffffffffc0202e28:	d0450513          	addi	a0,a0,-764 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0202e2c:	e66fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e30:	00004697          	auipc	a3,0x4
ffffffffc0202e34:	1a068693          	addi	a3,a3,416 # ffffffffc0206fd0 <default_pmm_manager+0x508>
ffffffffc0202e38:	00004617          	auipc	a2,0x4
ffffffffc0202e3c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0206718 <commands+0x818>
ffffffffc0202e40:	24800593          	li	a1,584
ffffffffc0202e44:	00004517          	auipc	a0,0x4
ffffffffc0202e48:	dd450513          	addi	a0,a0,-556 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202e4c:	e46fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e50:	00004697          	auipc	a3,0x4
ffffffffc0202e54:	13868693          	addi	a3,a3,312 # ffffffffc0206f88 <default_pmm_manager+0x4c0>
ffffffffc0202e58:	00004617          	auipc	a2,0x4
ffffffffc0202e5c:	8c060613          	addi	a2,a2,-1856 # ffffffffc0206718 <commands+0x818>
ffffffffc0202e60:	24600593          	li	a1,582
ffffffffc0202e64:	00004517          	auipc	a0,0x4
ffffffffc0202e68:	db450513          	addi	a0,a0,-588 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202e6c:	e26fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e70:	00004697          	auipc	a3,0x4
ffffffffc0202e74:	14868693          	addi	a3,a3,328 # ffffffffc0206fb8 <default_pmm_manager+0x4f0>
ffffffffc0202e78:	00004617          	auipc	a2,0x4
ffffffffc0202e7c:	8a060613          	addi	a2,a2,-1888 # ffffffffc0206718 <commands+0x818>
ffffffffc0202e80:	24500593          	li	a1,581
ffffffffc0202e84:	00004517          	auipc	a0,0x4
ffffffffc0202e88:	d9450513          	addi	a0,a0,-620 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202e8c:	e06fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202e90:	00004697          	auipc	a3,0x4
ffffffffc0202e94:	21068693          	addi	a3,a3,528 # ffffffffc02070a0 <default_pmm_manager+0x5d8>
ffffffffc0202e98:	00004617          	auipc	a2,0x4
ffffffffc0202e9c:	88060613          	addi	a2,a2,-1920 # ffffffffc0206718 <commands+0x818>
ffffffffc0202ea0:	26300593          	li	a1,611
ffffffffc0202ea4:	00004517          	auipc	a0,0x4
ffffffffc0202ea8:	d7450513          	addi	a0,a0,-652 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202eac:	de6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202eb0:	00004697          	auipc	a3,0x4
ffffffffc0202eb4:	15068693          	addi	a3,a3,336 # ffffffffc0207000 <default_pmm_manager+0x538>
ffffffffc0202eb8:	00004617          	auipc	a2,0x4
ffffffffc0202ebc:	86060613          	addi	a2,a2,-1952 # ffffffffc0206718 <commands+0x818>
ffffffffc0202ec0:	25000593          	li	a1,592
ffffffffc0202ec4:	00004517          	auipc	a0,0x4
ffffffffc0202ec8:	d5450513          	addi	a0,a0,-684 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202ecc:	dc6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202ed0:	00004697          	auipc	a3,0x4
ffffffffc0202ed4:	22868693          	addi	a3,a3,552 # ffffffffc02070f8 <default_pmm_manager+0x630>
ffffffffc0202ed8:	00004617          	auipc	a2,0x4
ffffffffc0202edc:	84060613          	addi	a2,a2,-1984 # ffffffffc0206718 <commands+0x818>
ffffffffc0202ee0:	26800593          	li	a1,616
ffffffffc0202ee4:	00004517          	auipc	a0,0x4
ffffffffc0202ee8:	d3450513          	addi	a0,a0,-716 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202eec:	da6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202ef0:	00004697          	auipc	a3,0x4
ffffffffc0202ef4:	1c868693          	addi	a3,a3,456 # ffffffffc02070b8 <default_pmm_manager+0x5f0>
ffffffffc0202ef8:	00004617          	auipc	a2,0x4
ffffffffc0202efc:	82060613          	addi	a2,a2,-2016 # ffffffffc0206718 <commands+0x818>
ffffffffc0202f00:	26700593          	li	a1,615
ffffffffc0202f04:	00004517          	auipc	a0,0x4
ffffffffc0202f08:	d1450513          	addi	a0,a0,-748 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202f0c:	d86fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f10:	00004697          	auipc	a3,0x4
ffffffffc0202f14:	07868693          	addi	a3,a3,120 # ffffffffc0206f88 <default_pmm_manager+0x4c0>
ffffffffc0202f18:	00004617          	auipc	a2,0x4
ffffffffc0202f1c:	80060613          	addi	a2,a2,-2048 # ffffffffc0206718 <commands+0x818>
ffffffffc0202f20:	24200593          	li	a1,578
ffffffffc0202f24:	00004517          	auipc	a0,0x4
ffffffffc0202f28:	cf450513          	addi	a0,a0,-780 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202f2c:	d66fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f30:	00004697          	auipc	a3,0x4
ffffffffc0202f34:	ef868693          	addi	a3,a3,-264 # ffffffffc0206e28 <default_pmm_manager+0x360>
ffffffffc0202f38:	00003617          	auipc	a2,0x3
ffffffffc0202f3c:	7e060613          	addi	a2,a2,2016 # ffffffffc0206718 <commands+0x818>
ffffffffc0202f40:	24100593          	li	a1,577
ffffffffc0202f44:	00004517          	auipc	a0,0x4
ffffffffc0202f48:	cd450513          	addi	a0,a0,-812 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202f4c:	d46fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202f50:	00004697          	auipc	a3,0x4
ffffffffc0202f54:	05068693          	addi	a3,a3,80 # ffffffffc0206fa0 <default_pmm_manager+0x4d8>
ffffffffc0202f58:	00003617          	auipc	a2,0x3
ffffffffc0202f5c:	7c060613          	addi	a2,a2,1984 # ffffffffc0206718 <commands+0x818>
ffffffffc0202f60:	23e00593          	li	a1,574
ffffffffc0202f64:	00004517          	auipc	a0,0x4
ffffffffc0202f68:	cb450513          	addi	a0,a0,-844 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202f6c:	d26fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f70:	00004697          	auipc	a3,0x4
ffffffffc0202f74:	ea068693          	addi	a3,a3,-352 # ffffffffc0206e10 <default_pmm_manager+0x348>
ffffffffc0202f78:	00003617          	auipc	a2,0x3
ffffffffc0202f7c:	7a060613          	addi	a2,a2,1952 # ffffffffc0206718 <commands+0x818>
ffffffffc0202f80:	23d00593          	li	a1,573
ffffffffc0202f84:	00004517          	auipc	a0,0x4
ffffffffc0202f88:	c9450513          	addi	a0,a0,-876 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202f8c:	d06fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202f90:	00004697          	auipc	a3,0x4
ffffffffc0202f94:	f2068693          	addi	a3,a3,-224 # ffffffffc0206eb0 <default_pmm_manager+0x3e8>
ffffffffc0202f98:	00003617          	auipc	a2,0x3
ffffffffc0202f9c:	78060613          	addi	a2,a2,1920 # ffffffffc0206718 <commands+0x818>
ffffffffc0202fa0:	23c00593          	li	a1,572
ffffffffc0202fa4:	00004517          	auipc	a0,0x4
ffffffffc0202fa8:	c7450513          	addi	a0,a0,-908 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202fac:	ce6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fb0:	00004697          	auipc	a3,0x4
ffffffffc0202fb4:	fd868693          	addi	a3,a3,-40 # ffffffffc0206f88 <default_pmm_manager+0x4c0>
ffffffffc0202fb8:	00003617          	auipc	a2,0x3
ffffffffc0202fbc:	76060613          	addi	a2,a2,1888 # ffffffffc0206718 <commands+0x818>
ffffffffc0202fc0:	23b00593          	li	a1,571
ffffffffc0202fc4:	00004517          	auipc	a0,0x4
ffffffffc0202fc8:	c5450513          	addi	a0,a0,-940 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202fcc:	cc6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202fd0:	00004697          	auipc	a3,0x4
ffffffffc0202fd4:	fa068693          	addi	a3,a3,-96 # ffffffffc0206f70 <default_pmm_manager+0x4a8>
ffffffffc0202fd8:	00003617          	auipc	a2,0x3
ffffffffc0202fdc:	74060613          	addi	a2,a2,1856 # ffffffffc0206718 <commands+0x818>
ffffffffc0202fe0:	23a00593          	li	a1,570
ffffffffc0202fe4:	00004517          	auipc	a0,0x4
ffffffffc0202fe8:	c3450513          	addi	a0,a0,-972 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0202fec:	ca6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202ff0:	00004697          	auipc	a3,0x4
ffffffffc0202ff4:	f5068693          	addi	a3,a3,-176 # ffffffffc0206f40 <default_pmm_manager+0x478>
ffffffffc0202ff8:	00003617          	auipc	a2,0x3
ffffffffc0202ffc:	72060613          	addi	a2,a2,1824 # ffffffffc0206718 <commands+0x818>
ffffffffc0203000:	23900593          	li	a1,569
ffffffffc0203004:	00004517          	auipc	a0,0x4
ffffffffc0203008:	c1450513          	addi	a0,a0,-1004 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020300c:	c86fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203010:	00004697          	auipc	a3,0x4
ffffffffc0203014:	f1868693          	addi	a3,a3,-232 # ffffffffc0206f28 <default_pmm_manager+0x460>
ffffffffc0203018:	00003617          	auipc	a2,0x3
ffffffffc020301c:	70060613          	addi	a2,a2,1792 # ffffffffc0206718 <commands+0x818>
ffffffffc0203020:	23700593          	li	a1,567
ffffffffc0203024:	00004517          	auipc	a0,0x4
ffffffffc0203028:	bf450513          	addi	a0,a0,-1036 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020302c:	c66fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203030:	00004697          	auipc	a3,0x4
ffffffffc0203034:	ed868693          	addi	a3,a3,-296 # ffffffffc0206f08 <default_pmm_manager+0x440>
ffffffffc0203038:	00003617          	auipc	a2,0x3
ffffffffc020303c:	6e060613          	addi	a2,a2,1760 # ffffffffc0206718 <commands+0x818>
ffffffffc0203040:	23600593          	li	a1,566
ffffffffc0203044:	00004517          	auipc	a0,0x4
ffffffffc0203048:	bd450513          	addi	a0,a0,-1068 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020304c:	c46fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203050:	00004697          	auipc	a3,0x4
ffffffffc0203054:	ea868693          	addi	a3,a3,-344 # ffffffffc0206ef8 <default_pmm_manager+0x430>
ffffffffc0203058:	00003617          	auipc	a2,0x3
ffffffffc020305c:	6c060613          	addi	a2,a2,1728 # ffffffffc0206718 <commands+0x818>
ffffffffc0203060:	23500593          	li	a1,565
ffffffffc0203064:	00004517          	auipc	a0,0x4
ffffffffc0203068:	bb450513          	addi	a0,a0,-1100 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020306c:	c26fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203070:	00004697          	auipc	a3,0x4
ffffffffc0203074:	e7868693          	addi	a3,a3,-392 # ffffffffc0206ee8 <default_pmm_manager+0x420>
ffffffffc0203078:	00003617          	auipc	a2,0x3
ffffffffc020307c:	6a060613          	addi	a2,a2,1696 # ffffffffc0206718 <commands+0x818>
ffffffffc0203080:	23400593          	li	a1,564
ffffffffc0203084:	00004517          	auipc	a0,0x4
ffffffffc0203088:	b9450513          	addi	a0,a0,-1132 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020308c:	c06fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc0203090:	00004617          	auipc	a2,0x4
ffffffffc0203094:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206c88 <default_pmm_manager+0x1c0>
ffffffffc0203098:	06500593          	li	a1,101
ffffffffc020309c:	00004517          	auipc	a0,0x4
ffffffffc02030a0:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02030a4:	beefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02030a8:	00004697          	auipc	a3,0x4
ffffffffc02030ac:	f5868693          	addi	a3,a3,-168 # ffffffffc0207000 <default_pmm_manager+0x538>
ffffffffc02030b0:	00003617          	auipc	a2,0x3
ffffffffc02030b4:	66860613          	addi	a2,a2,1640 # ffffffffc0206718 <commands+0x818>
ffffffffc02030b8:	27a00593          	li	a1,634
ffffffffc02030bc:	00004517          	auipc	a0,0x4
ffffffffc02030c0:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02030c4:	bcefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030c8:	00004697          	auipc	a3,0x4
ffffffffc02030cc:	de868693          	addi	a3,a3,-536 # ffffffffc0206eb0 <default_pmm_manager+0x3e8>
ffffffffc02030d0:	00003617          	auipc	a2,0x3
ffffffffc02030d4:	64860613          	addi	a2,a2,1608 # ffffffffc0206718 <commands+0x818>
ffffffffc02030d8:	23300593          	li	a1,563
ffffffffc02030dc:	00004517          	auipc	a0,0x4
ffffffffc02030e0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02030e4:	baefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02030e8:	00004697          	auipc	a3,0x4
ffffffffc02030ec:	d8868693          	addi	a3,a3,-632 # ffffffffc0206e70 <default_pmm_manager+0x3a8>
ffffffffc02030f0:	00003617          	auipc	a2,0x3
ffffffffc02030f4:	62860613          	addi	a2,a2,1576 # ffffffffc0206718 <commands+0x818>
ffffffffc02030f8:	23200593          	li	a1,562
ffffffffc02030fc:	00004517          	auipc	a0,0x4
ffffffffc0203100:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203104:	b8efd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203108:	86d6                	mv	a3,s5
ffffffffc020310a:	00004617          	auipc	a2,0x4
ffffffffc020310e:	9f660613          	addi	a2,a2,-1546 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0203112:	22e00593          	li	a1,558
ffffffffc0203116:	00004517          	auipc	a0,0x4
ffffffffc020311a:	b0250513          	addi	a0,a0,-1278 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020311e:	b74fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203122:	00004617          	auipc	a2,0x4
ffffffffc0203126:	9de60613          	addi	a2,a2,-1570 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc020312a:	22d00593          	li	a1,557
ffffffffc020312e:	00004517          	auipc	a0,0x4
ffffffffc0203132:	aea50513          	addi	a0,a0,-1302 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203136:	b5cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020313a:	00004697          	auipc	a3,0x4
ffffffffc020313e:	cee68693          	addi	a3,a3,-786 # ffffffffc0206e28 <default_pmm_manager+0x360>
ffffffffc0203142:	00003617          	auipc	a2,0x3
ffffffffc0203146:	5d660613          	addi	a2,a2,1494 # ffffffffc0206718 <commands+0x818>
ffffffffc020314a:	22b00593          	li	a1,555
ffffffffc020314e:	00004517          	auipc	a0,0x4
ffffffffc0203152:	aca50513          	addi	a0,a0,-1334 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203156:	b3cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020315a:	00004697          	auipc	a3,0x4
ffffffffc020315e:	cb668693          	addi	a3,a3,-842 # ffffffffc0206e10 <default_pmm_manager+0x348>
ffffffffc0203162:	00003617          	auipc	a2,0x3
ffffffffc0203166:	5b660613          	addi	a2,a2,1462 # ffffffffc0206718 <commands+0x818>
ffffffffc020316a:	22a00593          	li	a1,554
ffffffffc020316e:	00004517          	auipc	a0,0x4
ffffffffc0203172:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203176:	b1cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020317a:	00004697          	auipc	a3,0x4
ffffffffc020317e:	04668693          	addi	a3,a3,70 # ffffffffc02071c0 <default_pmm_manager+0x6f8>
ffffffffc0203182:	00003617          	auipc	a2,0x3
ffffffffc0203186:	59660613          	addi	a2,a2,1430 # ffffffffc0206718 <commands+0x818>
ffffffffc020318a:	27100593          	li	a1,625
ffffffffc020318e:	00004517          	auipc	a0,0x4
ffffffffc0203192:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203196:	afcfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020319a:	00004697          	auipc	a3,0x4
ffffffffc020319e:	fee68693          	addi	a3,a3,-18 # ffffffffc0207188 <default_pmm_manager+0x6c0>
ffffffffc02031a2:	00003617          	auipc	a2,0x3
ffffffffc02031a6:	57660613          	addi	a2,a2,1398 # ffffffffc0206718 <commands+0x818>
ffffffffc02031aa:	26e00593          	li	a1,622
ffffffffc02031ae:	00004517          	auipc	a0,0x4
ffffffffc02031b2:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02031b6:	adcfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02031ba:	00004697          	auipc	a3,0x4
ffffffffc02031be:	f9e68693          	addi	a3,a3,-98 # ffffffffc0207158 <default_pmm_manager+0x690>
ffffffffc02031c2:	00003617          	auipc	a2,0x3
ffffffffc02031c6:	55660613          	addi	a2,a2,1366 # ffffffffc0206718 <commands+0x818>
ffffffffc02031ca:	26a00593          	li	a1,618
ffffffffc02031ce:	00004517          	auipc	a0,0x4
ffffffffc02031d2:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02031d6:	abcfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02031da:	00004697          	auipc	a3,0x4
ffffffffc02031de:	f3668693          	addi	a3,a3,-202 # ffffffffc0207110 <default_pmm_manager+0x648>
ffffffffc02031e2:	00003617          	auipc	a2,0x3
ffffffffc02031e6:	53660613          	addi	a2,a2,1334 # ffffffffc0206718 <commands+0x818>
ffffffffc02031ea:	26900593          	li	a1,617
ffffffffc02031ee:	00004517          	auipc	a0,0x4
ffffffffc02031f2:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02031f6:	a9cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02031fa:	00004617          	auipc	a2,0x4
ffffffffc02031fe:	9ae60613          	addi	a2,a2,-1618 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc0203202:	0c900593          	li	a1,201
ffffffffc0203206:	00004517          	auipc	a0,0x4
ffffffffc020320a:	a1250513          	addi	a0,a0,-1518 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc020320e:	a84fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203212:	00004617          	auipc	a2,0x4
ffffffffc0203216:	99660613          	addi	a2,a2,-1642 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc020321a:	08100593          	li	a1,129
ffffffffc020321e:	00004517          	auipc	a0,0x4
ffffffffc0203222:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203226:	a6cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020322a:	00004697          	auipc	a3,0x4
ffffffffc020322e:	bb668693          	addi	a3,a3,-1098 # ffffffffc0206de0 <default_pmm_manager+0x318>
ffffffffc0203232:	00003617          	auipc	a2,0x3
ffffffffc0203236:	4e660613          	addi	a2,a2,1254 # ffffffffc0206718 <commands+0x818>
ffffffffc020323a:	22900593          	li	a1,553
ffffffffc020323e:	00004517          	auipc	a0,0x4
ffffffffc0203242:	9da50513          	addi	a0,a0,-1574 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203246:	a4cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020324a:	00004697          	auipc	a3,0x4
ffffffffc020324e:	b6668693          	addi	a3,a3,-1178 # ffffffffc0206db0 <default_pmm_manager+0x2e8>
ffffffffc0203252:	00003617          	auipc	a2,0x3
ffffffffc0203256:	4c660613          	addi	a2,a2,1222 # ffffffffc0206718 <commands+0x818>
ffffffffc020325a:	22600593          	li	a1,550
ffffffffc020325e:	00004517          	auipc	a0,0x4
ffffffffc0203262:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203266:	a2cfd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020326a <copy_range>:
{
ffffffffc020326a:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020326c:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203270:	f486                	sd	ra,104(sp)
ffffffffc0203272:	f0a2                	sd	s0,96(sp)
ffffffffc0203274:	eca6                	sd	s1,88(sp)
ffffffffc0203276:	e8ca                	sd	s2,80(sp)
ffffffffc0203278:	e4ce                	sd	s3,72(sp)
ffffffffc020327a:	e0d2                	sd	s4,64(sp)
ffffffffc020327c:	fc56                	sd	s5,56(sp)
ffffffffc020327e:	f85a                	sd	s6,48(sp)
ffffffffc0203280:	f45e                	sd	s7,40(sp)
ffffffffc0203282:	f062                	sd	s8,32(sp)
ffffffffc0203284:	ec66                	sd	s9,24(sp)
ffffffffc0203286:	e86a                	sd	s10,16(sp)
ffffffffc0203288:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020328a:	17d2                	slli	a5,a5,0x34
ffffffffc020328c:	20079f63          	bnez	a5,ffffffffc02034aa <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc0203290:	002007b7          	lui	a5,0x200
ffffffffc0203294:	8432                	mv	s0,a2
ffffffffc0203296:	1af66263          	bltu	a2,a5,ffffffffc020343a <copy_range+0x1d0>
ffffffffc020329a:	8936                	mv	s2,a3
ffffffffc020329c:	18d67f63          	bgeu	a2,a3,ffffffffc020343a <copy_range+0x1d0>
ffffffffc02032a0:	4785                	li	a5,1
ffffffffc02032a2:	07fe                	slli	a5,a5,0x1f
ffffffffc02032a4:	18d7eb63          	bltu	a5,a3,ffffffffc020343a <copy_range+0x1d0>
ffffffffc02032a8:	5b7d                	li	s6,-1
ffffffffc02032aa:	8aaa                	mv	s5,a0
ffffffffc02032ac:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02032ae:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02032b0:	000cec17          	auipc	s8,0xce
ffffffffc02032b4:	298c0c13          	addi	s8,s8,664 # ffffffffc02d1548 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02032b8:	000ceb97          	auipc	s7,0xce
ffffffffc02032bc:	298b8b93          	addi	s7,s7,664 # ffffffffc02d1550 <pages>
    return KADDR(page2pa(page));
ffffffffc02032c0:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02032c4:	000cec97          	auipc	s9,0xce
ffffffffc02032c8:	294c8c93          	addi	s9,s9,660 # ffffffffc02d1558 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02032cc:	4601                	li	a2,0
ffffffffc02032ce:	85a2                	mv	a1,s0
ffffffffc02032d0:	854e                	mv	a0,s3
ffffffffc02032d2:	b73fe0ef          	jal	ra,ffffffffc0201e44 <get_pte>
ffffffffc02032d6:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02032d8:	0e050c63          	beqz	a0,ffffffffc02033d0 <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc02032dc:	611c                	ld	a5,0(a0)
ffffffffc02032de:	8b85                	andi	a5,a5,1
ffffffffc02032e0:	e785                	bnez	a5,ffffffffc0203308 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02032e2:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02032e4:	ff2464e3          	bltu	s0,s2,ffffffffc02032cc <copy_range+0x62>
    return 0;
ffffffffc02032e8:	4501                	li	a0,0
}
ffffffffc02032ea:	70a6                	ld	ra,104(sp)
ffffffffc02032ec:	7406                	ld	s0,96(sp)
ffffffffc02032ee:	64e6                	ld	s1,88(sp)
ffffffffc02032f0:	6946                	ld	s2,80(sp)
ffffffffc02032f2:	69a6                	ld	s3,72(sp)
ffffffffc02032f4:	6a06                	ld	s4,64(sp)
ffffffffc02032f6:	7ae2                	ld	s5,56(sp)
ffffffffc02032f8:	7b42                	ld	s6,48(sp)
ffffffffc02032fa:	7ba2                	ld	s7,40(sp)
ffffffffc02032fc:	7c02                	ld	s8,32(sp)
ffffffffc02032fe:	6ce2                	ld	s9,24(sp)
ffffffffc0203300:	6d42                	ld	s10,16(sp)
ffffffffc0203302:	6da2                	ld	s11,8(sp)
ffffffffc0203304:	6165                	addi	sp,sp,112
ffffffffc0203306:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203308:	4605                	li	a2,1
ffffffffc020330a:	85a2                	mv	a1,s0
ffffffffc020330c:	8556                	mv	a0,s5
ffffffffc020330e:	b37fe0ef          	jal	ra,ffffffffc0201e44 <get_pte>
ffffffffc0203312:	c56d                	beqz	a0,ffffffffc02033fc <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203314:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203316:	0017f713          	andi	a4,a5,1
ffffffffc020331a:	01f7f493          	andi	s1,a5,31
ffffffffc020331e:	16070a63          	beqz	a4,ffffffffc0203492 <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc0203322:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203326:	078a                	slli	a5,a5,0x2
ffffffffc0203328:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020332c:	14d77763          	bgeu	a4,a3,ffffffffc020347a <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc0203330:	000bb783          	ld	a5,0(s7)
ffffffffc0203334:	fff806b7          	lui	a3,0xfff80
ffffffffc0203338:	9736                	add	a4,a4,a3
ffffffffc020333a:	071a                	slli	a4,a4,0x6
ffffffffc020333c:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203340:	10002773          	csrr	a4,sstatus
ffffffffc0203344:	8b09                	andi	a4,a4,2
ffffffffc0203346:	e345                	bnez	a4,ffffffffc02033e6 <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203348:	000cb703          	ld	a4,0(s9)
ffffffffc020334c:	4505                	li	a0,1
ffffffffc020334e:	6f18                	ld	a4,24(a4)
ffffffffc0203350:	9702                	jalr	a4
ffffffffc0203352:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203354:	0c0d8363          	beqz	s11,ffffffffc020341a <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc0203358:	100d0163          	beqz	s10,ffffffffc020345a <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc020335c:	000bb703          	ld	a4,0(s7)
ffffffffc0203360:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203364:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203368:	40ed86b3          	sub	a3,s11,a4
ffffffffc020336c:	8699                	srai	a3,a3,0x6
ffffffffc020336e:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0203370:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203374:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203376:	08c7f663          	bgeu	a5,a2,ffffffffc0203402 <copy_range+0x198>
    return page - pages + nbase;
ffffffffc020337a:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc020337e:	000ce717          	auipc	a4,0xce
ffffffffc0203382:	1e270713          	addi	a4,a4,482 # ffffffffc02d1560 <va_pa_offset>
ffffffffc0203386:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203388:	8799                	srai	a5,a5,0x6
ffffffffc020338a:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc020338c:	0167f733          	and	a4,a5,s6
ffffffffc0203390:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203394:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203396:	06c77563          	bgeu	a4,a2,ffffffffc0203400 <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020339a:	6605                	lui	a2,0x1
ffffffffc020339c:	953e                	add	a0,a0,a5
ffffffffc020339e:	0dd020ef          	jal	ra,ffffffffc0205c7a <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02033a2:	86a6                	mv	a3,s1
ffffffffc02033a4:	8622                	mv	a2,s0
ffffffffc02033a6:	85ea                	mv	a1,s10
ffffffffc02033a8:	8556                	mv	a0,s5
ffffffffc02033aa:	98aff0ef          	jal	ra,ffffffffc0202534 <page_insert>
            assert(ret == 0);// 确保映射成功
ffffffffc02033ae:	d915                	beqz	a0,ffffffffc02032e2 <copy_range+0x78>
ffffffffc02033b0:	00004697          	auipc	a3,0x4
ffffffffc02033b4:	e7868693          	addi	a3,a3,-392 # ffffffffc0207228 <default_pmm_manager+0x760>
ffffffffc02033b8:	00003617          	auipc	a2,0x3
ffffffffc02033bc:	36060613          	addi	a2,a2,864 # ffffffffc0206718 <commands+0x818>
ffffffffc02033c0:	1be00593          	li	a1,446
ffffffffc02033c4:	00004517          	auipc	a0,0x4
ffffffffc02033c8:	85450513          	addi	a0,a0,-1964 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02033cc:	8c6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02033d0:	00200637          	lui	a2,0x200
ffffffffc02033d4:	9432                	add	s0,s0,a2
ffffffffc02033d6:	ffe00637          	lui	a2,0xffe00
ffffffffc02033da:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02033dc:	f00406e3          	beqz	s0,ffffffffc02032e8 <copy_range+0x7e>
ffffffffc02033e0:	ef2466e3          	bltu	s0,s2,ffffffffc02032cc <copy_range+0x62>
ffffffffc02033e4:	b711                	j	ffffffffc02032e8 <copy_range+0x7e>
        intr_disable();
ffffffffc02033e6:	dc8fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02033ea:	000cb703          	ld	a4,0(s9)
ffffffffc02033ee:	4505                	li	a0,1
ffffffffc02033f0:	6f18                	ld	a4,24(a4)
ffffffffc02033f2:	9702                	jalr	a4
ffffffffc02033f4:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02033f6:	db2fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02033fa:	bfa9                	j	ffffffffc0203354 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc02033fc:	5571                	li	a0,-4
ffffffffc02033fe:	b5f5                	j	ffffffffc02032ea <copy_range+0x80>
ffffffffc0203400:	86be                	mv	a3,a5
ffffffffc0203402:	00003617          	auipc	a2,0x3
ffffffffc0203406:	6fe60613          	addi	a2,a2,1790 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc020340a:	07100593          	li	a1,113
ffffffffc020340e:	00003517          	auipc	a0,0x3
ffffffffc0203412:	71a50513          	addi	a0,a0,1818 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0203416:	87cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(page != NULL);
ffffffffc020341a:	00004697          	auipc	a3,0x4
ffffffffc020341e:	dee68693          	addi	a3,a3,-530 # ffffffffc0207208 <default_pmm_manager+0x740>
ffffffffc0203422:	00003617          	auipc	a2,0x3
ffffffffc0203426:	2f660613          	addi	a2,a2,758 # ffffffffc0206718 <commands+0x818>
ffffffffc020342a:	19600593          	li	a1,406
ffffffffc020342e:	00003517          	auipc	a0,0x3
ffffffffc0203432:	7ea50513          	addi	a0,a0,2026 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203436:	85cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020343a:	00004697          	auipc	a3,0x4
ffffffffc020343e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0206c58 <default_pmm_manager+0x190>
ffffffffc0203442:	00003617          	auipc	a2,0x3
ffffffffc0203446:	2d660613          	addi	a2,a2,726 # ffffffffc0206718 <commands+0x818>
ffffffffc020344a:	17e00593          	li	a1,382
ffffffffc020344e:	00003517          	auipc	a0,0x3
ffffffffc0203452:	7ca50513          	addi	a0,a0,1994 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203456:	83cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(npage != NULL);
ffffffffc020345a:	00004697          	auipc	a3,0x4
ffffffffc020345e:	dbe68693          	addi	a3,a3,-578 # ffffffffc0207218 <default_pmm_manager+0x750>
ffffffffc0203462:	00003617          	auipc	a2,0x3
ffffffffc0203466:	2b660613          	addi	a2,a2,694 # ffffffffc0206718 <commands+0x818>
ffffffffc020346a:	19700593          	li	a1,407
ffffffffc020346e:	00003517          	auipc	a0,0x3
ffffffffc0203472:	7aa50513          	addi	a0,a0,1962 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203476:	81cfd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020347a:	00003617          	auipc	a2,0x3
ffffffffc020347e:	75660613          	addi	a2,a2,1878 # ffffffffc0206bd0 <default_pmm_manager+0x108>
ffffffffc0203482:	06900593          	li	a1,105
ffffffffc0203486:	00003517          	auipc	a0,0x3
ffffffffc020348a:	6a250513          	addi	a0,a0,1698 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc020348e:	804fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203492:	00003617          	auipc	a2,0x3
ffffffffc0203496:	75e60613          	addi	a2,a2,1886 # ffffffffc0206bf0 <default_pmm_manager+0x128>
ffffffffc020349a:	07f00593          	li	a1,127
ffffffffc020349e:	00003517          	auipc	a0,0x3
ffffffffc02034a2:	68a50513          	addi	a0,a0,1674 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc02034a6:	fedfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02034aa:	00003697          	auipc	a3,0x3
ffffffffc02034ae:	77e68693          	addi	a3,a3,1918 # ffffffffc0206c28 <default_pmm_manager+0x160>
ffffffffc02034b2:	00003617          	auipc	a2,0x3
ffffffffc02034b6:	26660613          	addi	a2,a2,614 # ffffffffc0206718 <commands+0x818>
ffffffffc02034ba:	17d00593          	li	a1,381
ffffffffc02034be:	00003517          	auipc	a0,0x3
ffffffffc02034c2:	75a50513          	addi	a0,a0,1882 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc02034c6:	fcdfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02034ca <pgdir_alloc_page>:
{
ffffffffc02034ca:	7179                	addi	sp,sp,-48
ffffffffc02034cc:	ec26                	sd	s1,24(sp)
ffffffffc02034ce:	e84a                	sd	s2,16(sp)
ffffffffc02034d0:	e052                	sd	s4,0(sp)
ffffffffc02034d2:	f406                	sd	ra,40(sp)
ffffffffc02034d4:	f022                	sd	s0,32(sp)
ffffffffc02034d6:	e44e                	sd	s3,8(sp)
ffffffffc02034d8:	8a2a                	mv	s4,a0
ffffffffc02034da:	84ae                	mv	s1,a1
ffffffffc02034dc:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034de:	100027f3          	csrr	a5,sstatus
ffffffffc02034e2:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02034e4:	000ce997          	auipc	s3,0xce
ffffffffc02034e8:	07498993          	addi	s3,s3,116 # ffffffffc02d1558 <pmm_manager>
ffffffffc02034ec:	ef8d                	bnez	a5,ffffffffc0203526 <pgdir_alloc_page+0x5c>
ffffffffc02034ee:	0009b783          	ld	a5,0(s3)
ffffffffc02034f2:	4505                	li	a0,1
ffffffffc02034f4:	6f9c                	ld	a5,24(a5)
ffffffffc02034f6:	9782                	jalr	a5
ffffffffc02034f8:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02034fa:	cc09                	beqz	s0,ffffffffc0203514 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02034fc:	86ca                	mv	a3,s2
ffffffffc02034fe:	8626                	mv	a2,s1
ffffffffc0203500:	85a2                	mv	a1,s0
ffffffffc0203502:	8552                	mv	a0,s4
ffffffffc0203504:	830ff0ef          	jal	ra,ffffffffc0202534 <page_insert>
ffffffffc0203508:	e915                	bnez	a0,ffffffffc020353c <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc020350a:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc020350c:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020350e:	4785                	li	a5,1
ffffffffc0203510:	04f71e63          	bne	a4,a5,ffffffffc020356c <pgdir_alloc_page+0xa2>
}
ffffffffc0203514:	70a2                	ld	ra,40(sp)
ffffffffc0203516:	8522                	mv	a0,s0
ffffffffc0203518:	7402                	ld	s0,32(sp)
ffffffffc020351a:	64e2                	ld	s1,24(sp)
ffffffffc020351c:	6942                	ld	s2,16(sp)
ffffffffc020351e:	69a2                	ld	s3,8(sp)
ffffffffc0203520:	6a02                	ld	s4,0(sp)
ffffffffc0203522:	6145                	addi	sp,sp,48
ffffffffc0203524:	8082                	ret
        intr_disable();
ffffffffc0203526:	c88fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020352a:	0009b783          	ld	a5,0(s3)
ffffffffc020352e:	4505                	li	a0,1
ffffffffc0203530:	6f9c                	ld	a5,24(a5)
ffffffffc0203532:	9782                	jalr	a5
ffffffffc0203534:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203536:	c72fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020353a:	b7c1                	j	ffffffffc02034fa <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020353c:	100027f3          	csrr	a5,sstatus
ffffffffc0203540:	8b89                	andi	a5,a5,2
ffffffffc0203542:	eb89                	bnez	a5,ffffffffc0203554 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203544:	0009b783          	ld	a5,0(s3)
ffffffffc0203548:	8522                	mv	a0,s0
ffffffffc020354a:	4585                	li	a1,1
ffffffffc020354c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020354e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203550:	9782                	jalr	a5
    if (flag)
ffffffffc0203552:	b7c9                	j	ffffffffc0203514 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203554:	c5afd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0203558:	0009b783          	ld	a5,0(s3)
ffffffffc020355c:	8522                	mv	a0,s0
ffffffffc020355e:	4585                	li	a1,1
ffffffffc0203560:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203562:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203564:	9782                	jalr	a5
        intr_enable();
ffffffffc0203566:	c42fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020356a:	b76d                	j	ffffffffc0203514 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020356c:	00004697          	auipc	a3,0x4
ffffffffc0203570:	ccc68693          	addi	a3,a3,-820 # ffffffffc0207238 <default_pmm_manager+0x770>
ffffffffc0203574:	00003617          	auipc	a2,0x3
ffffffffc0203578:	1a460613          	addi	a2,a2,420 # ffffffffc0206718 <commands+0x818>
ffffffffc020357c:	20700593          	li	a1,519
ffffffffc0203580:	00003517          	auipc	a0,0x3
ffffffffc0203584:	69850513          	addi	a0,a0,1688 # ffffffffc0206c18 <default_pmm_manager+0x150>
ffffffffc0203588:	f0bfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020358c <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020358c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020358e:	00004697          	auipc	a3,0x4
ffffffffc0203592:	cc268693          	addi	a3,a3,-830 # ffffffffc0207250 <default_pmm_manager+0x788>
ffffffffc0203596:	00003617          	auipc	a2,0x3
ffffffffc020359a:	18260613          	addi	a2,a2,386 # ffffffffc0206718 <commands+0x818>
ffffffffc020359e:	07400593          	li	a1,116
ffffffffc02035a2:	00004517          	auipc	a0,0x4
ffffffffc02035a6:	cce50513          	addi	a0,a0,-818 # ffffffffc0207270 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02035aa:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02035ac:	ee7fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02035b0 <mm_create>:
{
ffffffffc02035b0:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035b2:	04000513          	li	a0,64
{
ffffffffc02035b6:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035b8:	df6fe0ef          	jal	ra,ffffffffc0201bae <kmalloc>
    if (mm != NULL)
ffffffffc02035bc:	cd19                	beqz	a0,ffffffffc02035da <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02035be:	e508                	sd	a0,8(a0)
ffffffffc02035c0:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02035c2:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02035c6:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02035ca:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02035ce:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02035d2:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02035d6:	02053c23          	sd	zero,56(a0)
}
ffffffffc02035da:	60a2                	ld	ra,8(sp)
ffffffffc02035dc:	0141                	addi	sp,sp,16
ffffffffc02035de:	8082                	ret

ffffffffc02035e0 <find_vma>:
{
ffffffffc02035e0:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02035e2:	c505                	beqz	a0,ffffffffc020360a <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02035e4:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035e6:	c501                	beqz	a0,ffffffffc02035ee <find_vma+0xe>
ffffffffc02035e8:	651c                	ld	a5,8(a0)
ffffffffc02035ea:	02f5f263          	bgeu	a1,a5,ffffffffc020360e <find_vma+0x2e>
    return listelm->next;
ffffffffc02035ee:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02035f0:	00f68d63          	beq	a3,a5,ffffffffc020360a <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02035f4:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f38e0>
ffffffffc02035f8:	00e5e663          	bltu	a1,a4,ffffffffc0203604 <find_vma+0x24>
ffffffffc02035fc:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203600:	00e5ec63          	bltu	a1,a4,ffffffffc0203618 <find_vma+0x38>
ffffffffc0203604:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203606:	fef697e3          	bne	a3,a5,ffffffffc02035f4 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc020360a:	4501                	li	a0,0
}
ffffffffc020360c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020360e:	691c                	ld	a5,16(a0)
ffffffffc0203610:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02035ee <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203614:	ea88                	sd	a0,16(a3)
ffffffffc0203616:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203618:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc020361c:	ea88                	sd	a0,16(a3)
ffffffffc020361e:	8082                	ret

ffffffffc0203620 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203620:	6590                	ld	a2,8(a1)
ffffffffc0203622:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_matrix_out_size+0x73908>
{
ffffffffc0203626:	1141                	addi	sp,sp,-16
ffffffffc0203628:	e406                	sd	ra,8(sp)
ffffffffc020362a:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020362c:	01066763          	bltu	a2,a6,ffffffffc020363a <insert_vma_struct+0x1a>
ffffffffc0203630:	a085                	j	ffffffffc0203690 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203632:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203636:	04e66863          	bltu	a2,a4,ffffffffc0203686 <insert_vma_struct+0x66>
ffffffffc020363a:	86be                	mv	a3,a5
ffffffffc020363c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020363e:	fef51ae3          	bne	a0,a5,ffffffffc0203632 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203642:	02a68463          	beq	a3,a0,ffffffffc020366a <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203646:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020364a:	fe86b883          	ld	a7,-24(a3)
ffffffffc020364e:	08e8f163          	bgeu	a7,a4,ffffffffc02036d0 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203652:	04e66f63          	bltu	a2,a4,ffffffffc02036b0 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203656:	00f50a63          	beq	a0,a5,ffffffffc020366a <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020365a:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020365e:	05076963          	bltu	a4,a6,ffffffffc02036b0 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203662:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203666:	02c77363          	bgeu	a4,a2,ffffffffc020368c <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020366a:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020366c:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020366e:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203672:	e390                	sd	a2,0(a5)
ffffffffc0203674:	e690                	sd	a2,8(a3)
}
ffffffffc0203676:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203678:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020367a:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020367c:	0017079b          	addiw	a5,a4,1
ffffffffc0203680:	d11c                	sw	a5,32(a0)
}
ffffffffc0203682:	0141                	addi	sp,sp,16
ffffffffc0203684:	8082                	ret
    if (le_prev != list)
ffffffffc0203686:	fca690e3          	bne	a3,a0,ffffffffc0203646 <insert_vma_struct+0x26>
ffffffffc020368a:	bfd1                	j	ffffffffc020365e <insert_vma_struct+0x3e>
ffffffffc020368c:	f01ff0ef          	jal	ra,ffffffffc020358c <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203690:	00004697          	auipc	a3,0x4
ffffffffc0203694:	bf068693          	addi	a3,a3,-1040 # ffffffffc0207280 <default_pmm_manager+0x7b8>
ffffffffc0203698:	00003617          	auipc	a2,0x3
ffffffffc020369c:	08060613          	addi	a2,a2,128 # ffffffffc0206718 <commands+0x818>
ffffffffc02036a0:	07a00593          	li	a1,122
ffffffffc02036a4:	00004517          	auipc	a0,0x4
ffffffffc02036a8:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc02036ac:	de7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036b0:	00004697          	auipc	a3,0x4
ffffffffc02036b4:	c1068693          	addi	a3,a3,-1008 # ffffffffc02072c0 <default_pmm_manager+0x7f8>
ffffffffc02036b8:	00003617          	auipc	a2,0x3
ffffffffc02036bc:	06060613          	addi	a2,a2,96 # ffffffffc0206718 <commands+0x818>
ffffffffc02036c0:	07300593          	li	a1,115
ffffffffc02036c4:	00004517          	auipc	a0,0x4
ffffffffc02036c8:	bac50513          	addi	a0,a0,-1108 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc02036cc:	dc7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036d0:	00004697          	auipc	a3,0x4
ffffffffc02036d4:	bd068693          	addi	a3,a3,-1072 # ffffffffc02072a0 <default_pmm_manager+0x7d8>
ffffffffc02036d8:	00003617          	auipc	a2,0x3
ffffffffc02036dc:	04060613          	addi	a2,a2,64 # ffffffffc0206718 <commands+0x818>
ffffffffc02036e0:	07200593          	li	a1,114
ffffffffc02036e4:	00004517          	auipc	a0,0x4
ffffffffc02036e8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc02036ec:	da7fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02036f0 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02036f0:	591c                	lw	a5,48(a0)
{
ffffffffc02036f2:	1141                	addi	sp,sp,-16
ffffffffc02036f4:	e406                	sd	ra,8(sp)
ffffffffc02036f6:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02036f8:	e78d                	bnez	a5,ffffffffc0203722 <mm_destroy+0x32>
ffffffffc02036fa:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02036fc:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02036fe:	00a40c63          	beq	s0,a0,ffffffffc0203716 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203702:	6118                	ld	a4,0(a0)
ffffffffc0203704:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203706:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203708:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020370a:	e398                	sd	a4,0(a5)
ffffffffc020370c:	d52fe0ef          	jal	ra,ffffffffc0201c5e <kfree>
    return listelm->next;
ffffffffc0203710:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203712:	fea418e3          	bne	s0,a0,ffffffffc0203702 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203716:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203718:	6402                	ld	s0,0(sp)
ffffffffc020371a:	60a2                	ld	ra,8(sp)
ffffffffc020371c:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020371e:	d40fe06f          	j	ffffffffc0201c5e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203722:	00004697          	auipc	a3,0x4
ffffffffc0203726:	bbe68693          	addi	a3,a3,-1090 # ffffffffc02072e0 <default_pmm_manager+0x818>
ffffffffc020372a:	00003617          	auipc	a2,0x3
ffffffffc020372e:	fee60613          	addi	a2,a2,-18 # ffffffffc0206718 <commands+0x818>
ffffffffc0203732:	09e00593          	li	a1,158
ffffffffc0203736:	00004517          	auipc	a0,0x4
ffffffffc020373a:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc020373e:	d55fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203742 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203742:	7139                	addi	sp,sp,-64
ffffffffc0203744:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203746:	6405                	lui	s0,0x1
ffffffffc0203748:	147d                	addi	s0,s0,-1
ffffffffc020374a:	77fd                	lui	a5,0xfffff
ffffffffc020374c:	9622                	add	a2,a2,s0
ffffffffc020374e:	962e                	add	a2,a2,a1
{
ffffffffc0203750:	f426                	sd	s1,40(sp)
ffffffffc0203752:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203754:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203758:	f04a                	sd	s2,32(sp)
ffffffffc020375a:	ec4e                	sd	s3,24(sp)
ffffffffc020375c:	e852                	sd	s4,16(sp)
ffffffffc020375e:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203760:	002005b7          	lui	a1,0x200
ffffffffc0203764:	00f67433          	and	s0,a2,a5
ffffffffc0203768:	06b4e363          	bltu	s1,a1,ffffffffc02037ce <mm_map+0x8c>
ffffffffc020376c:	0684f163          	bgeu	s1,s0,ffffffffc02037ce <mm_map+0x8c>
ffffffffc0203770:	4785                	li	a5,1
ffffffffc0203772:	07fe                	slli	a5,a5,0x1f
ffffffffc0203774:	0487ed63          	bltu	a5,s0,ffffffffc02037ce <mm_map+0x8c>
ffffffffc0203778:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020377a:	cd21                	beqz	a0,ffffffffc02037d2 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020377c:	85a6                	mv	a1,s1
ffffffffc020377e:	8ab6                	mv	s5,a3
ffffffffc0203780:	8a3a                	mv	s4,a4
ffffffffc0203782:	e5fff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
ffffffffc0203786:	c501                	beqz	a0,ffffffffc020378e <mm_map+0x4c>
ffffffffc0203788:	651c                	ld	a5,8(a0)
ffffffffc020378a:	0487e263          	bltu	a5,s0,ffffffffc02037ce <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020378e:	03000513          	li	a0,48
ffffffffc0203792:	c1cfe0ef          	jal	ra,ffffffffc0201bae <kmalloc>
ffffffffc0203796:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203798:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020379a:	02090163          	beqz	s2,ffffffffc02037bc <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020379e:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02037a0:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02037a4:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02037a8:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02037ac:	85ca                	mv	a1,s2
ffffffffc02037ae:	e73ff0ef          	jal	ra,ffffffffc0203620 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02037b2:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02037b4:	000a0463          	beqz	s4,ffffffffc02037bc <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02037b8:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>

out:
    return ret;
}
ffffffffc02037bc:	70e2                	ld	ra,56(sp)
ffffffffc02037be:	7442                	ld	s0,48(sp)
ffffffffc02037c0:	74a2                	ld	s1,40(sp)
ffffffffc02037c2:	7902                	ld	s2,32(sp)
ffffffffc02037c4:	69e2                	ld	s3,24(sp)
ffffffffc02037c6:	6a42                	ld	s4,16(sp)
ffffffffc02037c8:	6aa2                	ld	s5,8(sp)
ffffffffc02037ca:	6121                	addi	sp,sp,64
ffffffffc02037cc:	8082                	ret
        return -E_INVAL;
ffffffffc02037ce:	5575                	li	a0,-3
ffffffffc02037d0:	b7f5                	j	ffffffffc02037bc <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02037d2:	00004697          	auipc	a3,0x4
ffffffffc02037d6:	b2668693          	addi	a3,a3,-1242 # ffffffffc02072f8 <default_pmm_manager+0x830>
ffffffffc02037da:	00003617          	auipc	a2,0x3
ffffffffc02037de:	f3e60613          	addi	a2,a2,-194 # ffffffffc0206718 <commands+0x818>
ffffffffc02037e2:	0b300593          	li	a1,179
ffffffffc02037e6:	00004517          	auipc	a0,0x4
ffffffffc02037ea:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc02037ee:	ca5fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02037f2 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02037f2:	7139                	addi	sp,sp,-64
ffffffffc02037f4:	fc06                	sd	ra,56(sp)
ffffffffc02037f6:	f822                	sd	s0,48(sp)
ffffffffc02037f8:	f426                	sd	s1,40(sp)
ffffffffc02037fa:	f04a                	sd	s2,32(sp)
ffffffffc02037fc:	ec4e                	sd	s3,24(sp)
ffffffffc02037fe:	e852                	sd	s4,16(sp)
ffffffffc0203800:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203802:	c52d                	beqz	a0,ffffffffc020386c <dup_mmap+0x7a>
ffffffffc0203804:	892a                	mv	s2,a0
ffffffffc0203806:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203808:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc020380a:	e595                	bnez	a1,ffffffffc0203836 <dup_mmap+0x44>
ffffffffc020380c:	a085                	j	ffffffffc020386c <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020380e:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203810:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f3900>
        vma->vm_end = vm_end;
ffffffffc0203814:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203818:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc020381c:	e05ff0ef          	jal	ra,ffffffffc0203620 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203820:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc0203824:	fe843603          	ld	a2,-24(s0)
ffffffffc0203828:	6c8c                	ld	a1,24(s1)
ffffffffc020382a:	01893503          	ld	a0,24(s2)
ffffffffc020382e:	4701                	li	a4,0
ffffffffc0203830:	a3bff0ef          	jal	ra,ffffffffc020326a <copy_range>
ffffffffc0203834:	e105                	bnez	a0,ffffffffc0203854 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203836:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203838:	02848863          	beq	s1,s0,ffffffffc0203868 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020383c:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203840:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203844:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203848:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020384c:	b62fe0ef          	jal	ra,ffffffffc0201bae <kmalloc>
ffffffffc0203850:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203852:	fd55                	bnez	a0,ffffffffc020380e <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203854:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203856:	70e2                	ld	ra,56(sp)
ffffffffc0203858:	7442                	ld	s0,48(sp)
ffffffffc020385a:	74a2                	ld	s1,40(sp)
ffffffffc020385c:	7902                	ld	s2,32(sp)
ffffffffc020385e:	69e2                	ld	s3,24(sp)
ffffffffc0203860:	6a42                	ld	s4,16(sp)
ffffffffc0203862:	6aa2                	ld	s5,8(sp)
ffffffffc0203864:	6121                	addi	sp,sp,64
ffffffffc0203866:	8082                	ret
    return 0;
ffffffffc0203868:	4501                	li	a0,0
ffffffffc020386a:	b7f5                	j	ffffffffc0203856 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc020386c:	00004697          	auipc	a3,0x4
ffffffffc0203870:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0207308 <default_pmm_manager+0x840>
ffffffffc0203874:	00003617          	auipc	a2,0x3
ffffffffc0203878:	ea460613          	addi	a2,a2,-348 # ffffffffc0206718 <commands+0x818>
ffffffffc020387c:	0cf00593          	li	a1,207
ffffffffc0203880:	00004517          	auipc	a0,0x4
ffffffffc0203884:	9f050513          	addi	a0,a0,-1552 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203888:	c0bfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020388c <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc020388c:	1101                	addi	sp,sp,-32
ffffffffc020388e:	ec06                	sd	ra,24(sp)
ffffffffc0203890:	e822                	sd	s0,16(sp)
ffffffffc0203892:	e426                	sd	s1,8(sp)
ffffffffc0203894:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203896:	c531                	beqz	a0,ffffffffc02038e2 <exit_mmap+0x56>
ffffffffc0203898:	591c                	lw	a5,48(a0)
ffffffffc020389a:	84aa                	mv	s1,a0
ffffffffc020389c:	e3b9                	bnez	a5,ffffffffc02038e2 <exit_mmap+0x56>
    return listelm->next;
ffffffffc020389e:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02038a0:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02038a4:	02850663          	beq	a0,s0,ffffffffc02038d0 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038a8:	ff043603          	ld	a2,-16(s0)
ffffffffc02038ac:	fe843583          	ld	a1,-24(s0)
ffffffffc02038b0:	854a                	mv	a0,s2
ffffffffc02038b2:	80ffe0ef          	jal	ra,ffffffffc02020c0 <unmap_range>
ffffffffc02038b6:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038b8:	fe8498e3          	bne	s1,s0,ffffffffc02038a8 <exit_mmap+0x1c>
ffffffffc02038bc:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02038be:	00848c63          	beq	s1,s0,ffffffffc02038d6 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038c2:	ff043603          	ld	a2,-16(s0)
ffffffffc02038c6:	fe843583          	ld	a1,-24(s0)
ffffffffc02038ca:	854a                	mv	a0,s2
ffffffffc02038cc:	93bfe0ef          	jal	ra,ffffffffc0202206 <exit_range>
ffffffffc02038d0:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038d2:	fe8498e3          	bne	s1,s0,ffffffffc02038c2 <exit_mmap+0x36>
    }
}
ffffffffc02038d6:	60e2                	ld	ra,24(sp)
ffffffffc02038d8:	6442                	ld	s0,16(sp)
ffffffffc02038da:	64a2                	ld	s1,8(sp)
ffffffffc02038dc:	6902                	ld	s2,0(sp)
ffffffffc02038de:	6105                	addi	sp,sp,32
ffffffffc02038e0:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038e2:	00004697          	auipc	a3,0x4
ffffffffc02038e6:	a4668693          	addi	a3,a3,-1466 # ffffffffc0207328 <default_pmm_manager+0x860>
ffffffffc02038ea:	00003617          	auipc	a2,0x3
ffffffffc02038ee:	e2e60613          	addi	a2,a2,-466 # ffffffffc0206718 <commands+0x818>
ffffffffc02038f2:	0e800593          	li	a1,232
ffffffffc02038f6:	00004517          	auipc	a0,0x4
ffffffffc02038fa:	97a50513          	addi	a0,a0,-1670 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc02038fe:	b95fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203902 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203902:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203904:	04000513          	li	a0,64
{
ffffffffc0203908:	fc06                	sd	ra,56(sp)
ffffffffc020390a:	f822                	sd	s0,48(sp)
ffffffffc020390c:	f426                	sd	s1,40(sp)
ffffffffc020390e:	f04a                	sd	s2,32(sp)
ffffffffc0203910:	ec4e                	sd	s3,24(sp)
ffffffffc0203912:	e852                	sd	s4,16(sp)
ffffffffc0203914:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203916:	a98fe0ef          	jal	ra,ffffffffc0201bae <kmalloc>
    if (mm != NULL)
ffffffffc020391a:	2e050663          	beqz	a0,ffffffffc0203c06 <vmm_init+0x304>
ffffffffc020391e:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203920:	e508                	sd	a0,8(a0)
ffffffffc0203922:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203924:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203928:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020392c:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203930:	02053423          	sd	zero,40(a0)
ffffffffc0203934:	02052823          	sw	zero,48(a0)
ffffffffc0203938:	02053c23          	sd	zero,56(a0)
ffffffffc020393c:	03200413          	li	s0,50
ffffffffc0203940:	a811                	j	ffffffffc0203954 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203942:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203944:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203946:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc020394a:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020394c:	8526                	mv	a0,s1
ffffffffc020394e:	cd3ff0ef          	jal	ra,ffffffffc0203620 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203952:	c80d                	beqz	s0,ffffffffc0203984 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203954:	03000513          	li	a0,48
ffffffffc0203958:	a56fe0ef          	jal	ra,ffffffffc0201bae <kmalloc>
ffffffffc020395c:	85aa                	mv	a1,a0
ffffffffc020395e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203962:	f165                	bnez	a0,ffffffffc0203942 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203964:	00004697          	auipc	a3,0x4
ffffffffc0203968:	b5c68693          	addi	a3,a3,-1188 # ffffffffc02074c0 <default_pmm_manager+0x9f8>
ffffffffc020396c:	00003617          	auipc	a2,0x3
ffffffffc0203970:	dac60613          	addi	a2,a2,-596 # ffffffffc0206718 <commands+0x818>
ffffffffc0203974:	12c00593          	li	a1,300
ffffffffc0203978:	00004517          	auipc	a0,0x4
ffffffffc020397c:	8f850513          	addi	a0,a0,-1800 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203980:	b13fc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0203984:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203988:	1f900913          	li	s2,505
ffffffffc020398c:	a819                	j	ffffffffc02039a2 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc020398e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203990:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203992:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203996:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203998:	8526                	mv	a0,s1
ffffffffc020399a:	c87ff0ef          	jal	ra,ffffffffc0203620 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc020399e:	03240a63          	beq	s0,s2,ffffffffc02039d2 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039a2:	03000513          	li	a0,48
ffffffffc02039a6:	a08fe0ef          	jal	ra,ffffffffc0201bae <kmalloc>
ffffffffc02039aa:	85aa                	mv	a1,a0
ffffffffc02039ac:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02039b0:	fd79                	bnez	a0,ffffffffc020398e <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc02039b2:	00004697          	auipc	a3,0x4
ffffffffc02039b6:	b0e68693          	addi	a3,a3,-1266 # ffffffffc02074c0 <default_pmm_manager+0x9f8>
ffffffffc02039ba:	00003617          	auipc	a2,0x3
ffffffffc02039be:	d5e60613          	addi	a2,a2,-674 # ffffffffc0206718 <commands+0x818>
ffffffffc02039c2:	13300593          	li	a1,307
ffffffffc02039c6:	00004517          	auipc	a0,0x4
ffffffffc02039ca:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc02039ce:	ac5fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc02039d2:	649c                	ld	a5,8(s1)
ffffffffc02039d4:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02039d6:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02039da:	16f48663          	beq	s1,a5,ffffffffc0203b46 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02039de:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd2da50>
ffffffffc02039e2:	ffe70693          	addi	a3,a4,-2
ffffffffc02039e6:	10d61063          	bne	a2,a3,ffffffffc0203ae6 <vmm_init+0x1e4>
ffffffffc02039ea:	ff07b683          	ld	a3,-16(a5)
ffffffffc02039ee:	0ed71c63          	bne	a4,a3,ffffffffc0203ae6 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc02039f2:	0715                	addi	a4,a4,5
ffffffffc02039f4:	679c                	ld	a5,8(a5)
ffffffffc02039f6:	feb712e3          	bne	a4,a1,ffffffffc02039da <vmm_init+0xd8>
ffffffffc02039fa:	4a1d                	li	s4,7
ffffffffc02039fc:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02039fe:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203a02:	85a2                	mv	a1,s0
ffffffffc0203a04:	8526                	mv	a0,s1
ffffffffc0203a06:	bdbff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
ffffffffc0203a0a:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203a0c:	16050d63          	beqz	a0,ffffffffc0203b86 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a10:	00140593          	addi	a1,s0,1
ffffffffc0203a14:	8526                	mv	a0,s1
ffffffffc0203a16:	bcbff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
ffffffffc0203a1a:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a1c:	14050563          	beqz	a0,ffffffffc0203b66 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a20:	85d2                	mv	a1,s4
ffffffffc0203a22:	8526                	mv	a0,s1
ffffffffc0203a24:	bbdff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a28:	16051f63          	bnez	a0,ffffffffc0203ba6 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a2c:	00340593          	addi	a1,s0,3
ffffffffc0203a30:	8526                	mv	a0,s1
ffffffffc0203a32:	bafff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a36:	1a051863          	bnez	a0,ffffffffc0203be6 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a3a:	00440593          	addi	a1,s0,4
ffffffffc0203a3e:	8526                	mv	a0,s1
ffffffffc0203a40:	ba1ff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203a44:	18051163          	bnez	a0,ffffffffc0203bc6 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a48:	00893783          	ld	a5,8(s2)
ffffffffc0203a4c:	0a879d63          	bne	a5,s0,ffffffffc0203b06 <vmm_init+0x204>
ffffffffc0203a50:	01093783          	ld	a5,16(s2)
ffffffffc0203a54:	0b479963          	bne	a5,s4,ffffffffc0203b06 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a58:	0089b783          	ld	a5,8(s3)
ffffffffc0203a5c:	0c879563          	bne	a5,s0,ffffffffc0203b26 <vmm_init+0x224>
ffffffffc0203a60:	0109b783          	ld	a5,16(s3)
ffffffffc0203a64:	0d479163          	bne	a5,s4,ffffffffc0203b26 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a68:	0415                	addi	s0,s0,5
ffffffffc0203a6a:	0a15                	addi	s4,s4,5
ffffffffc0203a6c:	f9541be3          	bne	s0,s5,ffffffffc0203a02 <vmm_init+0x100>
ffffffffc0203a70:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a72:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a74:	85a2                	mv	a1,s0
ffffffffc0203a76:	8526                	mv	a0,s1
ffffffffc0203a78:	b69ff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
ffffffffc0203a7c:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203a80:	c90d                	beqz	a0,ffffffffc0203ab2 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203a82:	6914                	ld	a3,16(a0)
ffffffffc0203a84:	6510                	ld	a2,8(a0)
ffffffffc0203a86:	00004517          	auipc	a0,0x4
ffffffffc0203a8a:	9c250513          	addi	a0,a0,-1598 # ffffffffc0207448 <default_pmm_manager+0x980>
ffffffffc0203a8e:	f0afc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203a92:	00004697          	auipc	a3,0x4
ffffffffc0203a96:	9de68693          	addi	a3,a3,-1570 # ffffffffc0207470 <default_pmm_manager+0x9a8>
ffffffffc0203a9a:	00003617          	auipc	a2,0x3
ffffffffc0203a9e:	c7e60613          	addi	a2,a2,-898 # ffffffffc0206718 <commands+0x818>
ffffffffc0203aa2:	15900593          	li	a1,345
ffffffffc0203aa6:	00003517          	auipc	a0,0x3
ffffffffc0203aaa:	7ca50513          	addi	a0,a0,1994 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203aae:	9e5fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203ab2:	147d                	addi	s0,s0,-1
ffffffffc0203ab4:	fd2410e3          	bne	s0,s2,ffffffffc0203a74 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203ab8:	8526                	mv	a0,s1
ffffffffc0203aba:	c37ff0ef          	jal	ra,ffffffffc02036f0 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203abe:	00004517          	auipc	a0,0x4
ffffffffc0203ac2:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0207488 <default_pmm_manager+0x9c0>
ffffffffc0203ac6:	ed2fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0203aca:	7442                	ld	s0,48(sp)
ffffffffc0203acc:	70e2                	ld	ra,56(sp)
ffffffffc0203ace:	74a2                	ld	s1,40(sp)
ffffffffc0203ad0:	7902                	ld	s2,32(sp)
ffffffffc0203ad2:	69e2                	ld	s3,24(sp)
ffffffffc0203ad4:	6a42                	ld	s4,16(sp)
ffffffffc0203ad6:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ad8:	00004517          	auipc	a0,0x4
ffffffffc0203adc:	9d050513          	addi	a0,a0,-1584 # ffffffffc02074a8 <default_pmm_manager+0x9e0>
}
ffffffffc0203ae0:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ae2:	eb6fc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ae6:	00004697          	auipc	a3,0x4
ffffffffc0203aea:	87a68693          	addi	a3,a3,-1926 # ffffffffc0207360 <default_pmm_manager+0x898>
ffffffffc0203aee:	00003617          	auipc	a2,0x3
ffffffffc0203af2:	c2a60613          	addi	a2,a2,-982 # ffffffffc0206718 <commands+0x818>
ffffffffc0203af6:	13d00593          	li	a1,317
ffffffffc0203afa:	00003517          	auipc	a0,0x3
ffffffffc0203afe:	77650513          	addi	a0,a0,1910 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203b02:	991fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b06:	00004697          	auipc	a3,0x4
ffffffffc0203b0a:	8e268693          	addi	a3,a3,-1822 # ffffffffc02073e8 <default_pmm_manager+0x920>
ffffffffc0203b0e:	00003617          	auipc	a2,0x3
ffffffffc0203b12:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0206718 <commands+0x818>
ffffffffc0203b16:	14e00593          	li	a1,334
ffffffffc0203b1a:	00003517          	auipc	a0,0x3
ffffffffc0203b1e:	75650513          	addi	a0,a0,1878 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203b22:	971fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b26:	00004697          	auipc	a3,0x4
ffffffffc0203b2a:	8f268693          	addi	a3,a3,-1806 # ffffffffc0207418 <default_pmm_manager+0x950>
ffffffffc0203b2e:	00003617          	auipc	a2,0x3
ffffffffc0203b32:	bea60613          	addi	a2,a2,-1046 # ffffffffc0206718 <commands+0x818>
ffffffffc0203b36:	14f00593          	li	a1,335
ffffffffc0203b3a:	00003517          	auipc	a0,0x3
ffffffffc0203b3e:	73650513          	addi	a0,a0,1846 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203b42:	951fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b46:	00004697          	auipc	a3,0x4
ffffffffc0203b4a:	80268693          	addi	a3,a3,-2046 # ffffffffc0207348 <default_pmm_manager+0x880>
ffffffffc0203b4e:	00003617          	auipc	a2,0x3
ffffffffc0203b52:	bca60613          	addi	a2,a2,-1078 # ffffffffc0206718 <commands+0x818>
ffffffffc0203b56:	13b00593          	li	a1,315
ffffffffc0203b5a:	00003517          	auipc	a0,0x3
ffffffffc0203b5e:	71650513          	addi	a0,a0,1814 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203b62:	931fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203b66:	00004697          	auipc	a3,0x4
ffffffffc0203b6a:	84268693          	addi	a3,a3,-1982 # ffffffffc02073a8 <default_pmm_manager+0x8e0>
ffffffffc0203b6e:	00003617          	auipc	a2,0x3
ffffffffc0203b72:	baa60613          	addi	a2,a2,-1110 # ffffffffc0206718 <commands+0x818>
ffffffffc0203b76:	14600593          	li	a1,326
ffffffffc0203b7a:	00003517          	auipc	a0,0x3
ffffffffc0203b7e:	6f650513          	addi	a0,a0,1782 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203b82:	911fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203b86:	00004697          	auipc	a3,0x4
ffffffffc0203b8a:	81268693          	addi	a3,a3,-2030 # ffffffffc0207398 <default_pmm_manager+0x8d0>
ffffffffc0203b8e:	00003617          	auipc	a2,0x3
ffffffffc0203b92:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0206718 <commands+0x818>
ffffffffc0203b96:	14400593          	li	a1,324
ffffffffc0203b9a:	00003517          	auipc	a0,0x3
ffffffffc0203b9e:	6d650513          	addi	a0,a0,1750 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203ba2:	8f1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203ba6:	00004697          	auipc	a3,0x4
ffffffffc0203baa:	81268693          	addi	a3,a3,-2030 # ffffffffc02073b8 <default_pmm_manager+0x8f0>
ffffffffc0203bae:	00003617          	auipc	a2,0x3
ffffffffc0203bb2:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0206718 <commands+0x818>
ffffffffc0203bb6:	14800593          	li	a1,328
ffffffffc0203bba:	00003517          	auipc	a0,0x3
ffffffffc0203bbe:	6b650513          	addi	a0,a0,1718 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203bc2:	8d1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203bc6:	00004697          	auipc	a3,0x4
ffffffffc0203bca:	81268693          	addi	a3,a3,-2030 # ffffffffc02073d8 <default_pmm_manager+0x910>
ffffffffc0203bce:	00003617          	auipc	a2,0x3
ffffffffc0203bd2:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0206718 <commands+0x818>
ffffffffc0203bd6:	14c00593          	li	a1,332
ffffffffc0203bda:	00003517          	auipc	a0,0x3
ffffffffc0203bde:	69650513          	addi	a0,a0,1686 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203be2:	8b1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203be6:	00003697          	auipc	a3,0x3
ffffffffc0203bea:	7e268693          	addi	a3,a3,2018 # ffffffffc02073c8 <default_pmm_manager+0x900>
ffffffffc0203bee:	00003617          	auipc	a2,0x3
ffffffffc0203bf2:	b2a60613          	addi	a2,a2,-1238 # ffffffffc0206718 <commands+0x818>
ffffffffc0203bf6:	14a00593          	li	a1,330
ffffffffc0203bfa:	00003517          	auipc	a0,0x3
ffffffffc0203bfe:	67650513          	addi	a0,a0,1654 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203c02:	891fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203c06:	00003697          	auipc	a3,0x3
ffffffffc0203c0a:	6f268693          	addi	a3,a3,1778 # ffffffffc02072f8 <default_pmm_manager+0x830>
ffffffffc0203c0e:	00003617          	auipc	a2,0x3
ffffffffc0203c12:	b0a60613          	addi	a2,a2,-1270 # ffffffffc0206718 <commands+0x818>
ffffffffc0203c16:	12400593          	li	a1,292
ffffffffc0203c1a:	00003517          	auipc	a0,0x3
ffffffffc0203c1e:	65650513          	addi	a0,a0,1622 # ffffffffc0207270 <default_pmm_manager+0x7a8>
ffffffffc0203c22:	871fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203c26 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203c26:	7179                	addi	sp,sp,-48
ffffffffc0203c28:	f022                	sd	s0,32(sp)
ffffffffc0203c2a:	f406                	sd	ra,40(sp)
ffffffffc0203c2c:	ec26                	sd	s1,24(sp)
ffffffffc0203c2e:	e84a                	sd	s2,16(sp)
ffffffffc0203c30:	e44e                	sd	s3,8(sp)
ffffffffc0203c32:	e052                	sd	s4,0(sp)
ffffffffc0203c34:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203c36:	c135                	beqz	a0,ffffffffc0203c9a <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203c38:	002007b7          	lui	a5,0x200
ffffffffc0203c3c:	04f5e663          	bltu	a1,a5,ffffffffc0203c88 <user_mem_check+0x62>
ffffffffc0203c40:	00c584b3          	add	s1,a1,a2
ffffffffc0203c44:	0495f263          	bgeu	a1,s1,ffffffffc0203c88 <user_mem_check+0x62>
ffffffffc0203c48:	4785                	li	a5,1
ffffffffc0203c4a:	07fe                	slli	a5,a5,0x1f
ffffffffc0203c4c:	0297ee63          	bltu	a5,s1,ffffffffc0203c88 <user_mem_check+0x62>
ffffffffc0203c50:	892a                	mv	s2,a0
ffffffffc0203c52:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c54:	6a05                	lui	s4,0x1
ffffffffc0203c56:	a821                	j	ffffffffc0203c6e <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c58:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c5c:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c5e:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c60:	c685                	beqz	a3,ffffffffc0203c88 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c62:	c399                	beqz	a5,ffffffffc0203c68 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c64:	02e46263          	bltu	s0,a4,ffffffffc0203c88 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203c68:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203c6a:	04947663          	bgeu	s0,s1,ffffffffc0203cb6 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203c6e:	85a2                	mv	a1,s0
ffffffffc0203c70:	854a                	mv	a0,s2
ffffffffc0203c72:	96fff0ef          	jal	ra,ffffffffc02035e0 <find_vma>
ffffffffc0203c76:	c909                	beqz	a0,ffffffffc0203c88 <user_mem_check+0x62>
ffffffffc0203c78:	6518                	ld	a4,8(a0)
ffffffffc0203c7a:	00e46763          	bltu	s0,a4,ffffffffc0203c88 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c7e:	4d1c                	lw	a5,24(a0)
ffffffffc0203c80:	fc099ce3          	bnez	s3,ffffffffc0203c58 <user_mem_check+0x32>
ffffffffc0203c84:	8b85                	andi	a5,a5,1
ffffffffc0203c86:	f3ed                	bnez	a5,ffffffffc0203c68 <user_mem_check+0x42>
            return 0;
ffffffffc0203c88:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203c8a:	70a2                	ld	ra,40(sp)
ffffffffc0203c8c:	7402                	ld	s0,32(sp)
ffffffffc0203c8e:	64e2                	ld	s1,24(sp)
ffffffffc0203c90:	6942                	ld	s2,16(sp)
ffffffffc0203c92:	69a2                	ld	s3,8(sp)
ffffffffc0203c94:	6a02                	ld	s4,0(sp)
ffffffffc0203c96:	6145                	addi	sp,sp,48
ffffffffc0203c98:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203c9a:	c02007b7          	lui	a5,0xc0200
ffffffffc0203c9e:	4501                	li	a0,0
ffffffffc0203ca0:	fef5e5e3          	bltu	a1,a5,ffffffffc0203c8a <user_mem_check+0x64>
ffffffffc0203ca4:	962e                	add	a2,a2,a1
ffffffffc0203ca6:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203c8a <user_mem_check+0x64>
ffffffffc0203caa:	c8000537          	lui	a0,0xc8000
ffffffffc0203cae:	0505                	addi	a0,a0,1
ffffffffc0203cb0:	00a63533          	sltu	a0,a2,a0
ffffffffc0203cb4:	bfd9                	j	ffffffffc0203c8a <user_mem_check+0x64>
        return 1;
ffffffffc0203cb6:	4505                	li	a0,1
ffffffffc0203cb8:	bfc9                	j	ffffffffc0203c8a <user_mem_check+0x64>

ffffffffc0203cba <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203cba:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203cbc:	9402                	jalr	s0

	jal do_exit
ffffffffc0203cbe:	5de000ef          	jal	ra,ffffffffc020429c <do_exit>

ffffffffc0203cc2 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203cc2:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cc4:	14800513          	li	a0,328
{
ffffffffc0203cc8:	e022                	sd	s0,0(sp)
ffffffffc0203cca:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203ccc:	ee3fd0ef          	jal	ra,ffffffffc0201bae <kmalloc>
ffffffffc0203cd0:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203cd2:	cd35                	beqz	a0,ffffffffc0203d4e <alloc_proc+0x8c>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */

        proc->state = PROC_UNINIT;         // 状态：未初始化
ffffffffc0203cd4:	57fd                	li	a5,-1
ffffffffc0203cd6:	1782                	slli	a5,a5,0x20
ffffffffc0203cd8:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                    // 运行时间：0
        proc->kstack = 0;                  // 内核栈：暂无
        proc->need_resched = 0;            // 不需要调度
        proc->parent = NULL;               // 父进程：暂无
        proc->mm = NULL;                   // 内存管理：暂无
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
ffffffffc0203cda:	07000613          	li	a2,112
ffffffffc0203cde:	4581                	li	a1,0
        proc->runs = 0;                    // 运行时间：0
ffffffffc0203ce0:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d2ea70>
        proc->kstack = 0;                  // 内核栈：暂无
ffffffffc0203ce4:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;            // 不需要调度
ffffffffc0203ce8:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;               // 父进程：暂无
ffffffffc0203cec:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                   // 内存管理：暂无
ffffffffc0203cf0:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
ffffffffc0203cf4:	03050513          	addi	a0,a0,48
ffffffffc0203cf8:	771010ef          	jal	ra,ffffffffc0205c68 <memset>
        proc->tf = NULL;                   // 中断帧：暂无
        proc->pgdir = boot_pgdir_pa;       // 页表：默认使用内核页表
ffffffffc0203cfc:	000ce797          	auipc	a5,0xce
ffffffffc0203d00:	83c7b783          	ld	a5,-1988(a5) # ffffffffc02d1538 <boot_pgdir_pa>
ffffffffc0203d04:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;                   // 中断帧：暂无
ffffffffc0203d06:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                   // 标志位：0
ffffffffc0203d0a:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 名字清零
ffffffffc0203d0e:	4641                	li	a2,16
ffffffffc0203d10:	4581                	li	a1,0
ffffffffc0203d12:	0b440513          	addi	a0,s0,180
ffffffffc0203d16:	753010ef          	jal	ra,ffffffffc0205c68 <memset>
        // 1. 初始化运行队列指针
        // 刚出生的进程还没被放入任何 CPU 的队列，所以是 NULL
        proc->rq = NULL;
        // 2. 初始化运行队列链表节点
        // 防止野指针，虽然稍后 enqueue 时会被覆盖，但初始化一下更安全
        list_init(&(proc->run_link));
ffffffffc0203d1a:	11040793          	addi	a5,s0,272
        proc->wait_state = 0; 
ffffffffc0203d1e:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;  // 孩子 (Child)
ffffffffc0203d22:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;  // 哥哥 (Older Sibling)
ffffffffc0203d26:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;  // 弟弟 (Younger Sibling)
ffffffffc0203d2a:	0e043c23          	sd	zero,248(s0)
        proc->rq = NULL;
ffffffffc0203d2e:	10043423          	sd	zero,264(s0)
    elm->prev = elm->next = elm;
ffffffffc0203d32:	10f43c23          	sd	a5,280(s0)
ffffffffc0203d36:	10f43823          	sd	a5,272(s0)
        // 3. 初始化时间片
        // 初始为 0，等到它真正被放入队列（enqueue）时，调度器会给它分配具体的时间片
        proc->time_slice = 0;
ffffffffc0203d3a:	12042023          	sw	zero,288(s0)


        // 4. 初始化 Stride 算法相关参数
        // 4.1 斜堆节点：用来在优先队列中排序
        proc->lab6_run_pool.left = proc->lab6_run_pool.right = proc->lab6_run_pool.parent = NULL;
ffffffffc0203d3e:	12043423          	sd	zero,296(s0)
ffffffffc0203d42:	12043823          	sd	zero,304(s0)
ffffffffc0203d46:	12043c23          	sd	zero,312(s0)
        
        // 4.2 Stride 值：表示该进程当前的“进度”或“里程”
        proc->lab6_stride = 0;
ffffffffc0203d4a:	14043023          	sd	zero,320(s0)
        // 但 alloc_proc 只是申请内存，真正的 default priority 设置通常在 do_fork 中或者是 default_sched 的 init 逻辑中
        proc->lab6_priority = 0;

    }
    return proc;
}
ffffffffc0203d4e:	60a2                	ld	ra,8(sp)
ffffffffc0203d50:	8522                	mv	a0,s0
ffffffffc0203d52:	6402                	ld	s0,0(sp)
ffffffffc0203d54:	0141                	addi	sp,sp,16
ffffffffc0203d56:	8082                	ret

ffffffffc0203d58 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203d58:	000ce797          	auipc	a5,0xce
ffffffffc0203d5c:	8107b783          	ld	a5,-2032(a5) # ffffffffc02d1568 <current>
ffffffffc0203d60:	73c8                	ld	a0,160(a5)
ffffffffc0203d62:	968fd06f          	j	ffffffffc0200eca <forkrets>

ffffffffc0203d66 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203d66:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203d68:	1141                	addi	sp,sp,-16
ffffffffc0203d6a:	e406                	sd	ra,8(sp)
ffffffffc0203d6c:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d70:	02f6ee63          	bltu	a3,a5,ffffffffc0203dac <put_pgdir+0x46>
ffffffffc0203d74:	000cd517          	auipc	a0,0xcd
ffffffffc0203d78:	7ec53503          	ld	a0,2028(a0) # ffffffffc02d1560 <va_pa_offset>
ffffffffc0203d7c:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203d7e:	82b1                	srli	a3,a3,0xc
ffffffffc0203d80:	000cd797          	auipc	a5,0xcd
ffffffffc0203d84:	7c87b783          	ld	a5,1992(a5) # ffffffffc02d1548 <npage>
ffffffffc0203d88:	02f6fe63          	bgeu	a3,a5,ffffffffc0203dc4 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d8c:	00004517          	auipc	a0,0x4
ffffffffc0203d90:	7e453503          	ld	a0,2020(a0) # ffffffffc0208570 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203d94:	60a2                	ld	ra,8(sp)
ffffffffc0203d96:	8e89                	sub	a3,a3,a0
ffffffffc0203d98:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203d9a:	000cd517          	auipc	a0,0xcd
ffffffffc0203d9e:	7b653503          	ld	a0,1974(a0) # ffffffffc02d1550 <pages>
ffffffffc0203da2:	4585                	li	a1,1
ffffffffc0203da4:	9536                	add	a0,a0,a3
}
ffffffffc0203da6:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203da8:	822fe06f          	j	ffffffffc0201dca <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203dac:	00003617          	auipc	a2,0x3
ffffffffc0203db0:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc0203db4:	07700593          	li	a1,119
ffffffffc0203db8:	00003517          	auipc	a0,0x3
ffffffffc0203dbc:	d7050513          	addi	a0,a0,-656 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0203dc0:	ed2fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203dc4:	00003617          	auipc	a2,0x3
ffffffffc0203dc8:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206bd0 <default_pmm_manager+0x108>
ffffffffc0203dcc:	06900593          	li	a1,105
ffffffffc0203dd0:	00003517          	auipc	a0,0x3
ffffffffc0203dd4:	d5850513          	addi	a0,a0,-680 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0203dd8:	ebafc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203ddc <proc_run>:
{
ffffffffc0203ddc:	7179                	addi	sp,sp,-48
ffffffffc0203dde:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203de0:	000cd917          	auipc	s2,0xcd
ffffffffc0203de4:	78890913          	addi	s2,s2,1928 # ffffffffc02d1568 <current>
{
ffffffffc0203de8:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203dea:	00093483          	ld	s1,0(s2)
{
ffffffffc0203dee:	f406                	sd	ra,40(sp)
ffffffffc0203df0:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203df2:	02a48863          	beq	s1,a0,ffffffffc0203e22 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203df6:	100027f3          	csrr	a5,sstatus
ffffffffc0203dfa:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203dfc:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203dfe:	ef9d                	bnez	a5,ffffffffc0203e3c <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203e00:	755c                	ld	a5,168(a0)
ffffffffc0203e02:	577d                	li	a4,-1
ffffffffc0203e04:	177e                	slli	a4,a4,0x3f
ffffffffc0203e06:	83b1                	srli	a5,a5,0xc
            current = proc;                   
ffffffffc0203e08:	00a93023          	sd	a0,0(s2)
ffffffffc0203e0c:	8fd9                	or	a5,a5,a4
ffffffffc0203e0e:	18079073          	csrw	satp,a5
            switch_to(&(from->context), &(proc->context));
ffffffffc0203e12:	03050593          	addi	a1,a0,48
ffffffffc0203e16:	03048513          	addi	a0,s1,48
ffffffffc0203e1a:	122010ef          	jal	ra,ffffffffc0204f3c <switch_to>
    if (flag)
ffffffffc0203e1e:	00099863          	bnez	s3,ffffffffc0203e2e <proc_run+0x52>
}
ffffffffc0203e22:	70a2                	ld	ra,40(sp)
ffffffffc0203e24:	7482                	ld	s1,32(sp)
ffffffffc0203e26:	6962                	ld	s2,24(sp)
ffffffffc0203e28:	69c2                	ld	s3,16(sp)
ffffffffc0203e2a:	6145                	addi	sp,sp,48
ffffffffc0203e2c:	8082                	ret
ffffffffc0203e2e:	70a2                	ld	ra,40(sp)
ffffffffc0203e30:	7482                	ld	s1,32(sp)
ffffffffc0203e32:	6962                	ld	s2,24(sp)
ffffffffc0203e34:	69c2                	ld	s3,16(sp)
ffffffffc0203e36:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203e38:	b71fc06f          	j	ffffffffc02009a8 <intr_enable>
ffffffffc0203e3c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203e3e:	b71fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0203e42:	6522                	ld	a0,8(sp)
ffffffffc0203e44:	4985                	li	s3,1
ffffffffc0203e46:	bf6d                	j	ffffffffc0203e00 <proc_run+0x24>

ffffffffc0203e48 <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0203e48:	7119                	addi	sp,sp,-128
ffffffffc0203e4a:	f0ca                	sd	s2,96(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e4c:	000cd917          	auipc	s2,0xcd
ffffffffc0203e50:	73490913          	addi	s2,s2,1844 # ffffffffc02d1580 <nr_process>
ffffffffc0203e54:	00092703          	lw	a4,0(s2)
{
ffffffffc0203e58:	fc86                	sd	ra,120(sp)
ffffffffc0203e5a:	f8a2                	sd	s0,112(sp)
ffffffffc0203e5c:	f4a6                	sd	s1,104(sp)
ffffffffc0203e5e:	ecce                	sd	s3,88(sp)
ffffffffc0203e60:	e8d2                	sd	s4,80(sp)
ffffffffc0203e62:	e4d6                	sd	s5,72(sp)
ffffffffc0203e64:	e0da                	sd	s6,64(sp)
ffffffffc0203e66:	fc5e                	sd	s7,56(sp)
ffffffffc0203e68:	f862                	sd	s8,48(sp)
ffffffffc0203e6a:	f466                	sd	s9,40(sp)
ffffffffc0203e6c:	f06a                	sd	s10,32(sp)
ffffffffc0203e6e:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e70:	6785                	lui	a5,0x1
ffffffffc0203e72:	32f75b63          	bge	a4,a5,ffffffffc02041a8 <do_fork+0x360>
ffffffffc0203e76:	8a2a                	mv	s4,a0
ffffffffc0203e78:	89ae                	mv	s3,a1
ffffffffc0203e7a:	8432                	mv	s0,a2
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */
    // 1. 调用 alloc_proc 分配一个 proc_struct 结构体
    //    此时 proc 里的很多成员已经被初始化为空了
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203e7c:	e47ff0ef          	jal	ra,ffffffffc0203cc2 <alloc_proc>
ffffffffc0203e80:	84aa                	mv	s1,a0
ffffffffc0203e82:	30050463          	beqz	a0,ffffffffc020418a <do_fork+0x342>
        goto fork_out;
    }
    // ==========================================================
    // LAB5 更新点 1：设置父进程关系
    // ==========================================================
    proc->parent = current;  // 设置新进程的父亲为当前进程
ffffffffc0203e86:	000cdc17          	auipc	s8,0xcd
ffffffffc0203e8a:	6e2c0c13          	addi	s8,s8,1762 # ffffffffc02d1568 <current>
ffffffffc0203e8e:	000c3783          	ld	a5,0(s8)
    // 确保当前进程（父进程）的 wait_state 是 0
    assert(current->wait_state == 0);
ffffffffc0203e92:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8e44>
    proc->parent = current;  // 设置新进程的父亲为当前进程
ffffffffc0203e96:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0203e98:	30071d63          	bnez	a4,ffffffffc02041b2 <do_fork+0x36a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203e9c:	4509                	li	a0,2
ffffffffc0203e9e:	eeffd0ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
    if (page != NULL)
ffffffffc0203ea2:	2e050163          	beqz	a0,ffffffffc0204184 <do_fork+0x33c>
    return page - pages + nbase;
ffffffffc0203ea6:	000cda97          	auipc	s5,0xcd
ffffffffc0203eaa:	6aaa8a93          	addi	s5,s5,1706 # ffffffffc02d1550 <pages>
ffffffffc0203eae:	000ab683          	ld	a3,0(s5)
ffffffffc0203eb2:	00004b17          	auipc	s6,0x4
ffffffffc0203eb6:	6beb0b13          	addi	s6,s6,1726 # ffffffffc0208570 <nbase>
ffffffffc0203eba:	000b3783          	ld	a5,0(s6)
ffffffffc0203ebe:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203ec2:	000cdb97          	auipc	s7,0xcd
ffffffffc0203ec6:	686b8b93          	addi	s7,s7,1670 # ffffffffc02d1548 <npage>
    return page - pages + nbase;
ffffffffc0203eca:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203ecc:	5dfd                	li	s11,-1
ffffffffc0203ece:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0203ed2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203ed4:	00cddd93          	srli	s11,s11,0xc
ffffffffc0203ed8:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0203edc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203ede:	2ee67a63          	bgeu	a2,a4,ffffffffc02041d2 <do_fork+0x38a>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203ee2:	000c3603          	ld	a2,0(s8)
ffffffffc0203ee6:	000cdc17          	auipc	s8,0xcd
ffffffffc0203eea:	67ac0c13          	addi	s8,s8,1658 # ffffffffc02d1560 <va_pa_offset>
ffffffffc0203eee:	000c3703          	ld	a4,0(s8)
ffffffffc0203ef2:	02863d03          	ld	s10,40(a2)
ffffffffc0203ef6:	e43e                	sd	a5,8(sp)
ffffffffc0203ef8:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203efa:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0203efc:	020d0863          	beqz	s10,ffffffffc0203f2c <do_fork+0xe4>
    if (clone_flags & CLONE_VM)
ffffffffc0203f00:	100a7a13          	andi	s4,s4,256
ffffffffc0203f04:	1c0a0163          	beqz	s4,ffffffffc02040c6 <do_fork+0x27e>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203f08:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f0c:	018d3783          	ld	a5,24(s10)
ffffffffc0203f10:	c02006b7          	lui	a3,0xc0200
ffffffffc0203f14:	2705                	addiw	a4,a4,1
ffffffffc0203f16:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0203f1a:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f1e:	2ed7e263          	bltu	a5,a3,ffffffffc0204202 <do_fork+0x3ba>
ffffffffc0203f22:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f26:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f28:	8f99                	sub	a5,a5,a4
ffffffffc0203f2a:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f2c:	6789                	lui	a5,0x2
ffffffffc0203f2e:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8050>
ffffffffc0203f32:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0203f34:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f36:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0203f38:	87b6                	mv	a5,a3
ffffffffc0203f3a:	12040893          	addi	a7,s0,288
ffffffffc0203f3e:	00063803          	ld	a6,0(a2)
ffffffffc0203f42:	6608                	ld	a0,8(a2)
ffffffffc0203f44:	6a0c                	ld	a1,16(a2)
ffffffffc0203f46:	6e18                	ld	a4,24(a2)
ffffffffc0203f48:	0107b023          	sd	a6,0(a5)
ffffffffc0203f4c:	e788                	sd	a0,8(a5)
ffffffffc0203f4e:	eb8c                	sd	a1,16(a5)
ffffffffc0203f50:	ef98                	sd	a4,24(a5)
ffffffffc0203f52:	02060613          	addi	a2,a2,32
ffffffffc0203f56:	02078793          	addi	a5,a5,32
ffffffffc0203f5a:	ff1612e3          	bne	a2,a7,ffffffffc0203f3e <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc0203f5e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203f62:	12098f63          	beqz	s3,ffffffffc02040a0 <do_fork+0x258>
ffffffffc0203f66:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203f6a:	00000797          	auipc	a5,0x0
ffffffffc0203f6e:	dee78793          	addi	a5,a5,-530 # ffffffffc0203d58 <forkret>
ffffffffc0203f72:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203f74:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f76:	100027f3          	csrr	a5,sstatus
ffffffffc0203f7a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f7c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f7e:	14079063          	bnez	a5,ffffffffc02040be <do_fork+0x276>
    if (++last_pid >= MAX_PID)
ffffffffc0203f82:	000c9817          	auipc	a6,0xc9
ffffffffc0203f86:	12e80813          	addi	a6,a6,302 # ffffffffc02cd0b0 <last_pid.1>
ffffffffc0203f8a:	00082783          	lw	a5,0(a6)
ffffffffc0203f8e:	6709                	lui	a4,0x2
ffffffffc0203f90:	0017851b          	addiw	a0,a5,1
ffffffffc0203f94:	00a82023          	sw	a0,0(a6)
ffffffffc0203f98:	08e55d63          	bge	a0,a4,ffffffffc0204032 <do_fork+0x1ea>
    if (last_pid >= next_safe)
ffffffffc0203f9c:	000c9317          	auipc	t1,0xc9
ffffffffc0203fa0:	11830313          	addi	t1,t1,280 # ffffffffc02cd0b4 <next_safe.0>
ffffffffc0203fa4:	00032783          	lw	a5,0(t1)
ffffffffc0203fa8:	000cd417          	auipc	s0,0xcd
ffffffffc0203fac:	52840413          	addi	s0,s0,1320 # ffffffffc02d14d0 <proc_list>
ffffffffc0203fb0:	08f55963          	bge	a0,a5,ffffffffc0204042 <do_fork+0x1fa>
    // LAB5 更新点 2：插入进程链表 & 设置家族关系
    // ==========================================================
    bool intr_flag;
    local_intr_save(intr_flag);  // 必须关中断！因为要操作全局链表，防止被打断
    {
        proc->pid = get_pid();   // 给孩子分配一个唯一的 PID
ffffffffc0203fb4:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203fb6:	45a9                	li	a1,10
ffffffffc0203fb8:	2501                	sext.w	a0,a0
ffffffffc0203fba:	009010ef          	jal	ra,ffffffffc02057c2 <hash32>
ffffffffc0203fbe:	02051793          	slli	a5,a0,0x20
ffffffffc0203fc2:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203fc6:	000c9797          	auipc	a5,0xc9
ffffffffc0203fca:	50a78793          	addi	a5,a5,1290 # ffffffffc02cd4d0 <hash_list>
ffffffffc0203fce:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0203fd0:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203fd2:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203fd4:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0203fd8:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203fda:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0203fdc:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203fde:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0203fe0:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0203fe4:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0203fe6:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0203fe8:	e21c                	sd	a5,0(a2)
ffffffffc0203fea:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0203fec:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0203fee:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0203ff0:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203ff4:	10e4b023          	sd	a4,256(s1)
ffffffffc0203ff8:	c311                	beqz	a4,ffffffffc0203ffc <do_fork+0x1b4>
        proc->optr->yptr = proc;
ffffffffc0203ffa:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0203ffc:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204000:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204002:	2785                	addiw	a5,a5,1
ffffffffc0204004:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc0204008:	18099363          	bnez	s3,ffffffffc020418e <do_fork+0x346>
    }
    local_intr_restore(intr_flag); // 恢复中断

    // 6. 调用 wakeup_proc 唤醒子进程
    //    把子进程的状态设置为 PROC_RUNNABLE，让它有资格被调度器选中
    wakeup_proc(proc);
ffffffffc020400c:	8526                	mv	a0,s1
ffffffffc020400e:	542010ef          	jal	ra,ffffffffc0205550 <wakeup_proc>

    // 7. 返回子进程的 PID
    //    父进程调用 fork 得到的返回值就是孩子的 PID
    ret = proc->pid;
ffffffffc0204012:	40c8                	lw	a0,4(s1)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc0204014:	70e6                	ld	ra,120(sp)
ffffffffc0204016:	7446                	ld	s0,112(sp)
ffffffffc0204018:	74a6                	ld	s1,104(sp)
ffffffffc020401a:	7906                	ld	s2,96(sp)
ffffffffc020401c:	69e6                	ld	s3,88(sp)
ffffffffc020401e:	6a46                	ld	s4,80(sp)
ffffffffc0204020:	6aa6                	ld	s5,72(sp)
ffffffffc0204022:	6b06                	ld	s6,64(sp)
ffffffffc0204024:	7be2                	ld	s7,56(sp)
ffffffffc0204026:	7c42                	ld	s8,48(sp)
ffffffffc0204028:	7ca2                	ld	s9,40(sp)
ffffffffc020402a:	7d02                	ld	s10,32(sp)
ffffffffc020402c:	6de2                	ld	s11,24(sp)
ffffffffc020402e:	6109                	addi	sp,sp,128
ffffffffc0204030:	8082                	ret
        last_pid = 1;
ffffffffc0204032:	4785                	li	a5,1
ffffffffc0204034:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204038:	4505                	li	a0,1
ffffffffc020403a:	000c9317          	auipc	t1,0xc9
ffffffffc020403e:	07a30313          	addi	t1,t1,122 # ffffffffc02cd0b4 <next_safe.0>
    return listelm->next;
ffffffffc0204042:	000cd417          	auipc	s0,0xcd
ffffffffc0204046:	48e40413          	addi	s0,s0,1166 # ffffffffc02d14d0 <proc_list>
ffffffffc020404a:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020404e:	6789                	lui	a5,0x2
ffffffffc0204050:	00f32023          	sw	a5,0(t1)
ffffffffc0204054:	86aa                	mv	a3,a0
ffffffffc0204056:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204058:	6e89                	lui	t4,0x2
ffffffffc020405a:	148e0263          	beq	t3,s0,ffffffffc020419e <do_fork+0x356>
ffffffffc020405e:	88ae                	mv	a7,a1
ffffffffc0204060:	87f2                	mv	a5,t3
ffffffffc0204062:	6609                	lui	a2,0x2
ffffffffc0204064:	a811                	j	ffffffffc0204078 <do_fork+0x230>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204066:	00e6d663          	bge	a3,a4,ffffffffc0204072 <do_fork+0x22a>
ffffffffc020406a:	00c75463          	bge	a4,a2,ffffffffc0204072 <do_fork+0x22a>
ffffffffc020406e:	863a                	mv	a2,a4
ffffffffc0204070:	4885                	li	a7,1
ffffffffc0204072:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204074:	00878d63          	beq	a5,s0,ffffffffc020408e <do_fork+0x246>
            if (proc->pid == last_pid)
ffffffffc0204078:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7ff4>
ffffffffc020407c:	fed715e3          	bne	a4,a3,ffffffffc0204066 <do_fork+0x21e>
                if (++last_pid >= next_safe)
ffffffffc0204080:	2685                	addiw	a3,a3,1
ffffffffc0204082:	10c6d963          	bge	a3,a2,ffffffffc0204194 <do_fork+0x34c>
ffffffffc0204086:	679c                	ld	a5,8(a5)
ffffffffc0204088:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020408a:	fe8797e3          	bne	a5,s0,ffffffffc0204078 <do_fork+0x230>
ffffffffc020408e:	c581                	beqz	a1,ffffffffc0204096 <do_fork+0x24e>
ffffffffc0204090:	00d82023          	sw	a3,0(a6)
ffffffffc0204094:	8536                	mv	a0,a3
ffffffffc0204096:	f0088fe3          	beqz	a7,ffffffffc0203fb4 <do_fork+0x16c>
ffffffffc020409a:	00c32023          	sw	a2,0(t1)
ffffffffc020409e:	bf19                	j	ffffffffc0203fb4 <do_fork+0x16c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02040a0:	89b6                	mv	s3,a3
ffffffffc02040a2:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02040a6:	00000797          	auipc	a5,0x0
ffffffffc02040aa:	cb278793          	addi	a5,a5,-846 # ffffffffc0203d58 <forkret>
ffffffffc02040ae:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02040b0:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040b2:	100027f3          	csrr	a5,sstatus
ffffffffc02040b6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040b8:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040ba:	ec0784e3          	beqz	a5,ffffffffc0203f82 <do_fork+0x13a>
        intr_disable();
ffffffffc02040be:	8f1fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02040c2:	4985                	li	s3,1
ffffffffc02040c4:	bd7d                	j	ffffffffc0203f82 <do_fork+0x13a>
    if ((mm = mm_create()) == NULL)
ffffffffc02040c6:	ceaff0ef          	jal	ra,ffffffffc02035b0 <mm_create>
ffffffffc02040ca:	8caa                	mv	s9,a0
ffffffffc02040cc:	c541                	beqz	a0,ffffffffc0204154 <do_fork+0x30c>
    if ((page = alloc_page()) == NULL)
ffffffffc02040ce:	4505                	li	a0,1
ffffffffc02040d0:	cbdfd0ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc02040d4:	cd2d                	beqz	a0,ffffffffc020414e <do_fork+0x306>
    return page - pages + nbase;
ffffffffc02040d6:	000ab683          	ld	a3,0(s5)
ffffffffc02040da:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02040dc:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02040e0:	40d506b3          	sub	a3,a0,a3
ffffffffc02040e4:	8699                	srai	a3,a3,0x6
ffffffffc02040e6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02040e8:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02040ec:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040ee:	0eedf263          	bgeu	s11,a4,ffffffffc02041d2 <do_fork+0x38a>
ffffffffc02040f2:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02040f6:	6605                	lui	a2,0x1
ffffffffc02040f8:	000cd597          	auipc	a1,0xcd
ffffffffc02040fc:	4485b583          	ld	a1,1096(a1) # ffffffffc02d1540 <boot_pgdir_va>
ffffffffc0204100:	9a36                	add	s4,s4,a3
ffffffffc0204102:	8552                	mv	a0,s4
ffffffffc0204104:	377010ef          	jal	ra,ffffffffc0205c7a <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204108:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc020410c:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204110:	4785                	li	a5,1
ffffffffc0204112:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204116:	8b85                	andi	a5,a5,1
ffffffffc0204118:	4a05                	li	s4,1
ffffffffc020411a:	c799                	beqz	a5,ffffffffc0204128 <do_fork+0x2e0>
    {
        schedule();
ffffffffc020411c:	4e6010ef          	jal	ra,ffffffffc0205602 <schedule>
ffffffffc0204120:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc0204124:	8b85                	andi	a5,a5,1
ffffffffc0204126:	fbfd                	bnez	a5,ffffffffc020411c <do_fork+0x2d4>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204128:	85ea                	mv	a1,s10
ffffffffc020412a:	8566                	mv	a0,s9
ffffffffc020412c:	ec6ff0ef          	jal	ra,ffffffffc02037f2 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204130:	57f9                	li	a5,-2
ffffffffc0204132:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204136:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204138:	0e078e63          	beqz	a5,ffffffffc0204234 <do_fork+0x3ec>
good_mm:
ffffffffc020413c:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc020413e:	dc0505e3          	beqz	a0,ffffffffc0203f08 <do_fork+0xc0>
    exit_mmap(mm);
ffffffffc0204142:	8566                	mv	a0,s9
ffffffffc0204144:	f48ff0ef          	jal	ra,ffffffffc020388c <exit_mmap>
    put_pgdir(mm);
ffffffffc0204148:	8566                	mv	a0,s9
ffffffffc020414a:	c1dff0ef          	jal	ra,ffffffffc0203d66 <put_pgdir>
    mm_destroy(mm);
ffffffffc020414e:	8566                	mv	a0,s9
ffffffffc0204150:	da0ff0ef          	jal	ra,ffffffffc02036f0 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204154:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204156:	c02007b7          	lui	a5,0xc0200
ffffffffc020415a:	0cf6e163          	bltu	a3,a5,ffffffffc020421c <do_fork+0x3d4>
ffffffffc020415e:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204162:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0204166:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020416a:	83b1                	srli	a5,a5,0xc
ffffffffc020416c:	06e7ff63          	bgeu	a5,a4,ffffffffc02041ea <do_fork+0x3a2>
    return &pages[PPN(pa) - nbase];
ffffffffc0204170:	000b3703          	ld	a4,0(s6)
ffffffffc0204174:	000ab503          	ld	a0,0(s5)
ffffffffc0204178:	4589                	li	a1,2
ffffffffc020417a:	8f99                	sub	a5,a5,a4
ffffffffc020417c:	079a                	slli	a5,a5,0x6
ffffffffc020417e:	953e                	add	a0,a0,a5
ffffffffc0204180:	c4bfd0ef          	jal	ra,ffffffffc0201dca <free_pages>
    kfree(proc);
ffffffffc0204184:	8526                	mv	a0,s1
ffffffffc0204186:	ad9fd0ef          	jal	ra,ffffffffc0201c5e <kfree>
    ret = -E_NO_MEM;
ffffffffc020418a:	5571                	li	a0,-4
    return ret;
ffffffffc020418c:	b561                	j	ffffffffc0204014 <do_fork+0x1cc>
        intr_enable();
ffffffffc020418e:	81bfc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204192:	bdad                	j	ffffffffc020400c <do_fork+0x1c4>
                    if (last_pid >= MAX_PID)
ffffffffc0204194:	01d6c363          	blt	a3,t4,ffffffffc020419a <do_fork+0x352>
                        last_pid = 1;
ffffffffc0204198:	4685                	li	a3,1
                    goto repeat;
ffffffffc020419a:	4585                	li	a1,1
ffffffffc020419c:	bd7d                	j	ffffffffc020405a <do_fork+0x212>
ffffffffc020419e:	c599                	beqz	a1,ffffffffc02041ac <do_fork+0x364>
ffffffffc02041a0:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02041a4:	8536                	mv	a0,a3
ffffffffc02041a6:	b539                	j	ffffffffc0203fb4 <do_fork+0x16c>
    int ret = -E_NO_FREE_PROC;
ffffffffc02041a8:	556d                	li	a0,-5
ffffffffc02041aa:	b5ad                	j	ffffffffc0204014 <do_fork+0x1cc>
    return last_pid;
ffffffffc02041ac:	00082503          	lw	a0,0(a6)
ffffffffc02041b0:	b511                	j	ffffffffc0203fb4 <do_fork+0x16c>
    assert(current->wait_state == 0);
ffffffffc02041b2:	00003697          	auipc	a3,0x3
ffffffffc02041b6:	31e68693          	addi	a3,a3,798 # ffffffffc02074d0 <default_pmm_manager+0xa08>
ffffffffc02041ba:	00002617          	auipc	a2,0x2
ffffffffc02041be:	55e60613          	addi	a2,a2,1374 # ffffffffc0206718 <commands+0x818>
ffffffffc02041c2:	20c00593          	li	a1,524
ffffffffc02041c6:	00003517          	auipc	a0,0x3
ffffffffc02041ca:	32a50513          	addi	a0,a0,810 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc02041ce:	ac4fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc02041d2:	00003617          	auipc	a2,0x3
ffffffffc02041d6:	92e60613          	addi	a2,a2,-1746 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc02041da:	07100593          	li	a1,113
ffffffffc02041de:	00003517          	auipc	a0,0x3
ffffffffc02041e2:	94a50513          	addi	a0,a0,-1718 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc02041e6:	aacfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02041ea:	00003617          	auipc	a2,0x3
ffffffffc02041ee:	9e660613          	addi	a2,a2,-1562 # ffffffffc0206bd0 <default_pmm_manager+0x108>
ffffffffc02041f2:	06900593          	li	a1,105
ffffffffc02041f6:	00003517          	auipc	a0,0x3
ffffffffc02041fa:	93250513          	addi	a0,a0,-1742 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc02041fe:	a94fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204202:	86be                	mv	a3,a5
ffffffffc0204204:	00003617          	auipc	a2,0x3
ffffffffc0204208:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc020420c:	1b700593          	li	a1,439
ffffffffc0204210:	00003517          	auipc	a0,0x3
ffffffffc0204214:	2e050513          	addi	a0,a0,736 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204218:	a7afc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020421c:	00003617          	auipc	a2,0x3
ffffffffc0204220:	98c60613          	addi	a2,a2,-1652 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc0204224:	07700593          	li	a1,119
ffffffffc0204228:	00003517          	auipc	a0,0x3
ffffffffc020422c:	90050513          	addi	a0,a0,-1792 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0204230:	a62fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204234:	00003617          	auipc	a2,0x3
ffffffffc0204238:	2d460613          	addi	a2,a2,724 # ffffffffc0207508 <default_pmm_manager+0xa40>
ffffffffc020423c:	04000593          	li	a1,64
ffffffffc0204240:	00003517          	auipc	a0,0x3
ffffffffc0204244:	2d850513          	addi	a0,a0,728 # ffffffffc0207518 <default_pmm_manager+0xa50>
ffffffffc0204248:	a4afc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020424c <kernel_thread>:
{
ffffffffc020424c:	7129                	addi	sp,sp,-320
ffffffffc020424e:	fa22                	sd	s0,304(sp)
ffffffffc0204250:	f626                	sd	s1,296(sp)
ffffffffc0204252:	f24a                	sd	s2,288(sp)
ffffffffc0204254:	84ae                	mv	s1,a1
ffffffffc0204256:	892a                	mv	s2,a0
ffffffffc0204258:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020425a:	4581                	li	a1,0
ffffffffc020425c:	12000613          	li	a2,288
ffffffffc0204260:	850a                	mv	a0,sp
{
ffffffffc0204262:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204264:	205010ef          	jal	ra,ffffffffc0205c68 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204268:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020426a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020426c:	100027f3          	csrr	a5,sstatus
ffffffffc0204270:	edd7f793          	andi	a5,a5,-291
ffffffffc0204274:	1207e793          	ori	a5,a5,288
ffffffffc0204278:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020427a:	860a                	mv	a2,sp
ffffffffc020427c:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204280:	00000797          	auipc	a5,0x0
ffffffffc0204284:	a3a78793          	addi	a5,a5,-1478 # ffffffffc0203cba <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204288:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020428a:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020428c:	bbdff0ef          	jal	ra,ffffffffc0203e48 <do_fork>
}
ffffffffc0204290:	70f2                	ld	ra,312(sp)
ffffffffc0204292:	7452                	ld	s0,304(sp)
ffffffffc0204294:	74b2                	ld	s1,296(sp)
ffffffffc0204296:	7912                	ld	s2,288(sp)
ffffffffc0204298:	6131                	addi	sp,sp,320
ffffffffc020429a:	8082                	ret

ffffffffc020429c <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc020429c:	7179                	addi	sp,sp,-48
ffffffffc020429e:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02042a0:	000cd417          	auipc	s0,0xcd
ffffffffc02042a4:	2c840413          	addi	s0,s0,712 # ffffffffc02d1568 <current>
ffffffffc02042a8:	601c                	ld	a5,0(s0)
{
ffffffffc02042aa:	f406                	sd	ra,40(sp)
ffffffffc02042ac:	ec26                	sd	s1,24(sp)
ffffffffc02042ae:	e84a                	sd	s2,16(sp)
ffffffffc02042b0:	e44e                	sd	s3,8(sp)
ffffffffc02042b2:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02042b4:	000cd717          	auipc	a4,0xcd
ffffffffc02042b8:	2bc73703          	ld	a4,700(a4) # ffffffffc02d1570 <idleproc>
ffffffffc02042bc:	0ce78c63          	beq	a5,a4,ffffffffc0204394 <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02042c0:	000cd497          	auipc	s1,0xcd
ffffffffc02042c4:	2b848493          	addi	s1,s1,696 # ffffffffc02d1578 <initproc>
ffffffffc02042c8:	6098                	ld	a4,0(s1)
ffffffffc02042ca:	0ee78b63          	beq	a5,a4,ffffffffc02043c0 <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc02042ce:	0287b983          	ld	s3,40(a5)
ffffffffc02042d2:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02042d4:	02098663          	beqz	s3,ffffffffc0204300 <do_exit+0x64>
ffffffffc02042d8:	000cd797          	auipc	a5,0xcd
ffffffffc02042dc:	2607b783          	ld	a5,608(a5) # ffffffffc02d1538 <boot_pgdir_pa>
ffffffffc02042e0:	577d                	li	a4,-1
ffffffffc02042e2:	177e                	slli	a4,a4,0x3f
ffffffffc02042e4:	83b1                	srli	a5,a5,0xc
ffffffffc02042e6:	8fd9                	or	a5,a5,a4
ffffffffc02042e8:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02042ec:	0309a783          	lw	a5,48(s3)
ffffffffc02042f0:	fff7871b          	addiw	a4,a5,-1
ffffffffc02042f4:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc02042f8:	cb55                	beqz	a4,ffffffffc02043ac <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc02042fa:	601c                	ld	a5,0(s0)
ffffffffc02042fc:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc0204300:	601c                	ld	a5,0(s0)
ffffffffc0204302:	470d                	li	a4,3
ffffffffc0204304:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204306:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020430a:	100027f3          	csrr	a5,sstatus
ffffffffc020430e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204310:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204312:	e3f9                	bnez	a5,ffffffffc02043d8 <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc0204314:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204316:	800007b7          	lui	a5,0x80000
ffffffffc020431a:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020431c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020431e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204322:	0af70f63          	beq	a4,a5,ffffffffc02043e0 <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc0204326:	6018                	ld	a4,0(s0)
ffffffffc0204328:	7b7c                	ld	a5,240(a4)
ffffffffc020432a:	c3a1                	beqz	a5,ffffffffc020436a <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc020432c:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204330:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204332:	0985                	addi	s3,s3,1
ffffffffc0204334:	a021                	j	ffffffffc020433c <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204336:	6018                	ld	a4,0(s0)
ffffffffc0204338:	7b7c                	ld	a5,240(a4)
ffffffffc020433a:	cb85                	beqz	a5,ffffffffc020436a <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020433c:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff39f8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204340:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204342:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204344:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204346:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020434a:	10e7b023          	sd	a4,256(a5)
ffffffffc020434e:	c311                	beqz	a4,ffffffffc0204352 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204350:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204352:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204354:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204356:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204358:	fd271fe3          	bne	a4,s2,ffffffffc0204336 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020435c:	0ec52783          	lw	a5,236(a0)
ffffffffc0204360:	fd379be3          	bne	a5,s3,ffffffffc0204336 <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc0204364:	1ec010ef          	jal	ra,ffffffffc0205550 <wakeup_proc>
ffffffffc0204368:	b7f9                	j	ffffffffc0204336 <do_exit+0x9a>
    if (flag)
ffffffffc020436a:	020a1263          	bnez	s4,ffffffffc020438e <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc020436e:	294010ef          	jal	ra,ffffffffc0205602 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204372:	601c                	ld	a5,0(s0)
ffffffffc0204374:	00003617          	auipc	a2,0x3
ffffffffc0204378:	1dc60613          	addi	a2,a2,476 # ffffffffc0207550 <default_pmm_manager+0xa88>
ffffffffc020437c:	27b00593          	li	a1,635
ffffffffc0204380:	43d4                	lw	a3,4(a5)
ffffffffc0204382:	00003517          	auipc	a0,0x3
ffffffffc0204386:	16e50513          	addi	a0,a0,366 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc020438a:	908fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc020438e:	e1afc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204392:	bff1                	j	ffffffffc020436e <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204394:	00003617          	auipc	a2,0x3
ffffffffc0204398:	19c60613          	addi	a2,a2,412 # ffffffffc0207530 <default_pmm_manager+0xa68>
ffffffffc020439c:	24700593          	li	a1,583
ffffffffc02043a0:	00003517          	auipc	a0,0x3
ffffffffc02043a4:	15050513          	addi	a0,a0,336 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc02043a8:	8eafc0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc02043ac:	854e                	mv	a0,s3
ffffffffc02043ae:	cdeff0ef          	jal	ra,ffffffffc020388c <exit_mmap>
            put_pgdir(mm);
ffffffffc02043b2:	854e                	mv	a0,s3
ffffffffc02043b4:	9b3ff0ef          	jal	ra,ffffffffc0203d66 <put_pgdir>
            mm_destroy(mm);
ffffffffc02043b8:	854e                	mv	a0,s3
ffffffffc02043ba:	b36ff0ef          	jal	ra,ffffffffc02036f0 <mm_destroy>
ffffffffc02043be:	bf35                	j	ffffffffc02042fa <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02043c0:	00003617          	auipc	a2,0x3
ffffffffc02043c4:	18060613          	addi	a2,a2,384 # ffffffffc0207540 <default_pmm_manager+0xa78>
ffffffffc02043c8:	24b00593          	li	a1,587
ffffffffc02043cc:	00003517          	auipc	a0,0x3
ffffffffc02043d0:	12450513          	addi	a0,a0,292 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc02043d4:	8befc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc02043d8:	dd6fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02043dc:	4a05                	li	s4,1
ffffffffc02043de:	bf1d                	j	ffffffffc0204314 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02043e0:	170010ef          	jal	ra,ffffffffc0205550 <wakeup_proc>
ffffffffc02043e4:	b789                	j	ffffffffc0204326 <do_exit+0x8a>

ffffffffc02043e6 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc02043e6:	715d                	addi	sp,sp,-80
ffffffffc02043e8:	f84a                	sd	s2,48(sp)
ffffffffc02043ea:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc02043ec:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02043f0:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02043f2:	fc26                	sd	s1,56(sp)
ffffffffc02043f4:	f052                	sd	s4,32(sp)
ffffffffc02043f6:	ec56                	sd	s5,24(sp)
ffffffffc02043f8:	e85a                	sd	s6,16(sp)
ffffffffc02043fa:	e45e                	sd	s7,8(sp)
ffffffffc02043fc:	e486                	sd	ra,72(sp)
ffffffffc02043fe:	e0a2                	sd	s0,64(sp)
ffffffffc0204400:	84aa                	mv	s1,a0
ffffffffc0204402:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204404:	000cdb97          	auipc	s7,0xcd
ffffffffc0204408:	164b8b93          	addi	s7,s7,356 # ffffffffc02d1568 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc020440c:	00050b1b          	sext.w	s6,a0
ffffffffc0204410:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204414:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204416:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204418:	ccbd                	beqz	s1,ffffffffc0204496 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020441a:	0359e863          	bltu	s3,s5,ffffffffc020444a <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020441e:	45a9                	li	a1,10
ffffffffc0204420:	855a                	mv	a0,s6
ffffffffc0204422:	3a0010ef          	jal	ra,ffffffffc02057c2 <hash32>
ffffffffc0204426:	02051793          	slli	a5,a0,0x20
ffffffffc020442a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020442e:	000c9797          	auipc	a5,0xc9
ffffffffc0204432:	0a278793          	addi	a5,a5,162 # ffffffffc02cd4d0 <hash_list>
ffffffffc0204436:	953e                	add	a0,a0,a5
ffffffffc0204438:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020443a:	a029                	j	ffffffffc0204444 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020443c:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204440:	02978163          	beq	a5,s1,ffffffffc0204462 <do_wait.part.0+0x7c>
ffffffffc0204444:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204446:	fe851be3          	bne	a0,s0,ffffffffc020443c <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc020444a:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc020444c:	60a6                	ld	ra,72(sp)
ffffffffc020444e:	6406                	ld	s0,64(sp)
ffffffffc0204450:	74e2                	ld	s1,56(sp)
ffffffffc0204452:	7942                	ld	s2,48(sp)
ffffffffc0204454:	79a2                	ld	s3,40(sp)
ffffffffc0204456:	7a02                	ld	s4,32(sp)
ffffffffc0204458:	6ae2                	ld	s5,24(sp)
ffffffffc020445a:	6b42                	ld	s6,16(sp)
ffffffffc020445c:	6ba2                	ld	s7,8(sp)
ffffffffc020445e:	6161                	addi	sp,sp,80
ffffffffc0204460:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204462:	000bb683          	ld	a3,0(s7)
ffffffffc0204466:	f4843783          	ld	a5,-184(s0)
ffffffffc020446a:	fed790e3          	bne	a5,a3,ffffffffc020444a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020446e:	f2842703          	lw	a4,-216(s0)
ffffffffc0204472:	478d                	li	a5,3
ffffffffc0204474:	0ef70b63          	beq	a4,a5,ffffffffc020456a <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204478:	4785                	li	a5,1
ffffffffc020447a:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020447c:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204480:	182010ef          	jal	ra,ffffffffc0205602 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204484:	000bb783          	ld	a5,0(s7)
ffffffffc0204488:	0b07a783          	lw	a5,176(a5)
ffffffffc020448c:	8b85                	andi	a5,a5,1
ffffffffc020448e:	d7c9                	beqz	a5,ffffffffc0204418 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204490:	555d                	li	a0,-9
ffffffffc0204492:	e0bff0ef          	jal	ra,ffffffffc020429c <do_exit>
        proc = current->cptr;
ffffffffc0204496:	000bb683          	ld	a3,0(s7)
ffffffffc020449a:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020449c:	d45d                	beqz	s0,ffffffffc020444a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020449e:	470d                	li	a4,3
ffffffffc02044a0:	a021                	j	ffffffffc02044a8 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02044a2:	10043403          	ld	s0,256(s0)
ffffffffc02044a6:	d869                	beqz	s0,ffffffffc0204478 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044a8:	401c                	lw	a5,0(s0)
ffffffffc02044aa:	fee79ce3          	bne	a5,a4,ffffffffc02044a2 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02044ae:	000cd797          	auipc	a5,0xcd
ffffffffc02044b2:	0c27b783          	ld	a5,194(a5) # ffffffffc02d1570 <idleproc>
ffffffffc02044b6:	0c878963          	beq	a5,s0,ffffffffc0204588 <do_wait.part.0+0x1a2>
ffffffffc02044ba:	000cd797          	auipc	a5,0xcd
ffffffffc02044be:	0be7b783          	ld	a5,190(a5) # ffffffffc02d1578 <initproc>
ffffffffc02044c2:	0cf40363          	beq	s0,a5,ffffffffc0204588 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02044c6:	000a0663          	beqz	s4,ffffffffc02044d2 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02044ca:	0e842783          	lw	a5,232(s0)
ffffffffc02044ce:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044d2:	100027f3          	csrr	a5,sstatus
ffffffffc02044d6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02044d8:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044da:	e7c1                	bnez	a5,ffffffffc0204562 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02044dc:	6c70                	ld	a2,216(s0)
ffffffffc02044de:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02044e0:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02044e4:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02044e6:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02044e8:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02044ea:	6470                	ld	a2,200(s0)
ffffffffc02044ec:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02044ee:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02044f0:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02044f2:	c319                	beqz	a4,ffffffffc02044f8 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02044f4:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02044f6:	7c7c                	ld	a5,248(s0)
ffffffffc02044f8:	c3b5                	beqz	a5,ffffffffc020455c <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02044fa:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02044fe:	000cd717          	auipc	a4,0xcd
ffffffffc0204502:	08270713          	addi	a4,a4,130 # ffffffffc02d1580 <nr_process>
ffffffffc0204506:	431c                	lw	a5,0(a4)
ffffffffc0204508:	37fd                	addiw	a5,a5,-1
ffffffffc020450a:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc020450c:	e5a9                	bnez	a1,ffffffffc0204556 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020450e:	6814                	ld	a3,16(s0)
ffffffffc0204510:	c02007b7          	lui	a5,0xc0200
ffffffffc0204514:	04f6ee63          	bltu	a3,a5,ffffffffc0204570 <do_wait.part.0+0x18a>
ffffffffc0204518:	000cd797          	auipc	a5,0xcd
ffffffffc020451c:	0487b783          	ld	a5,72(a5) # ffffffffc02d1560 <va_pa_offset>
ffffffffc0204520:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204522:	82b1                	srli	a3,a3,0xc
ffffffffc0204524:	000cd797          	auipc	a5,0xcd
ffffffffc0204528:	0247b783          	ld	a5,36(a5) # ffffffffc02d1548 <npage>
ffffffffc020452c:	06f6fa63          	bgeu	a3,a5,ffffffffc02045a0 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204530:	00004517          	auipc	a0,0x4
ffffffffc0204534:	04053503          	ld	a0,64(a0) # ffffffffc0208570 <nbase>
ffffffffc0204538:	8e89                	sub	a3,a3,a0
ffffffffc020453a:	069a                	slli	a3,a3,0x6
ffffffffc020453c:	000cd517          	auipc	a0,0xcd
ffffffffc0204540:	01453503          	ld	a0,20(a0) # ffffffffc02d1550 <pages>
ffffffffc0204544:	9536                	add	a0,a0,a3
ffffffffc0204546:	4589                	li	a1,2
ffffffffc0204548:	883fd0ef          	jal	ra,ffffffffc0201dca <free_pages>
    kfree(proc);
ffffffffc020454c:	8522                	mv	a0,s0
ffffffffc020454e:	f10fd0ef          	jal	ra,ffffffffc0201c5e <kfree>
    return 0;
ffffffffc0204552:	4501                	li	a0,0
ffffffffc0204554:	bde5                	j	ffffffffc020444c <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204556:	c52fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020455a:	bf55                	j	ffffffffc020450e <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020455c:	701c                	ld	a5,32(s0)
ffffffffc020455e:	fbf8                	sd	a4,240(a5)
ffffffffc0204560:	bf79                	j	ffffffffc02044fe <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204562:	c4cfc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204566:	4585                	li	a1,1
ffffffffc0204568:	bf95                	j	ffffffffc02044dc <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020456a:	f2840413          	addi	s0,s0,-216
ffffffffc020456e:	b781                	j	ffffffffc02044ae <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204570:	00002617          	auipc	a2,0x2
ffffffffc0204574:	63860613          	addi	a2,a2,1592 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc0204578:	07700593          	li	a1,119
ffffffffc020457c:	00002517          	auipc	a0,0x2
ffffffffc0204580:	5ac50513          	addi	a0,a0,1452 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0204584:	f0ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204588:	00003617          	auipc	a2,0x3
ffffffffc020458c:	fe860613          	addi	a2,a2,-24 # ffffffffc0207570 <default_pmm_manager+0xaa8>
ffffffffc0204590:	3a900593          	li	a1,937
ffffffffc0204594:	00003517          	auipc	a0,0x3
ffffffffc0204598:	f5c50513          	addi	a0,a0,-164 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc020459c:	ef7fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02045a0:	00002617          	auipc	a2,0x2
ffffffffc02045a4:	63060613          	addi	a2,a2,1584 # ffffffffc0206bd0 <default_pmm_manager+0x108>
ffffffffc02045a8:	06900593          	li	a1,105
ffffffffc02045ac:	00002517          	auipc	a0,0x2
ffffffffc02045b0:	57c50513          	addi	a0,a0,1404 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc02045b4:	edffb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02045b8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02045b8:	1141                	addi	sp,sp,-16
ffffffffc02045ba:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045bc:	84ffd0ef          	jal	ra,ffffffffc0201e0a <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02045c0:	deafd0ef          	jal	ra,ffffffffc0201baa <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02045c4:	4601                	li	a2,0
ffffffffc02045c6:	4581                	li	a1,0
ffffffffc02045c8:	00000517          	auipc	a0,0x0
ffffffffc02045cc:	62850513          	addi	a0,a0,1576 # ffffffffc0204bf0 <user_main>
ffffffffc02045d0:	c7dff0ef          	jal	ra,ffffffffc020424c <kernel_thread>
    if (pid <= 0)
ffffffffc02045d4:	00a04563          	bgtz	a0,ffffffffc02045de <init_main+0x26>
ffffffffc02045d8:	a071                	j	ffffffffc0204664 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02045da:	028010ef          	jal	ra,ffffffffc0205602 <schedule>
    if (code_store != NULL)
ffffffffc02045de:	4581                	li	a1,0
ffffffffc02045e0:	4501                	li	a0,0
ffffffffc02045e2:	e05ff0ef          	jal	ra,ffffffffc02043e6 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02045e6:	d975                	beqz	a0,ffffffffc02045da <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02045e8:	00003517          	auipc	a0,0x3
ffffffffc02045ec:	fc850513          	addi	a0,a0,-56 # ffffffffc02075b0 <default_pmm_manager+0xae8>
ffffffffc02045f0:	ba9fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02045f4:	000cd797          	auipc	a5,0xcd
ffffffffc02045f8:	f847b783          	ld	a5,-124(a5) # ffffffffc02d1578 <initproc>
ffffffffc02045fc:	7bf8                	ld	a4,240(a5)
ffffffffc02045fe:	e339                	bnez	a4,ffffffffc0204644 <init_main+0x8c>
ffffffffc0204600:	7ff8                	ld	a4,248(a5)
ffffffffc0204602:	e329                	bnez	a4,ffffffffc0204644 <init_main+0x8c>
ffffffffc0204604:	1007b703          	ld	a4,256(a5)
ffffffffc0204608:	ef15                	bnez	a4,ffffffffc0204644 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020460a:	000cd697          	auipc	a3,0xcd
ffffffffc020460e:	f766a683          	lw	a3,-138(a3) # ffffffffc02d1580 <nr_process>
ffffffffc0204612:	4709                	li	a4,2
ffffffffc0204614:	0ae69463          	bne	a3,a4,ffffffffc02046bc <init_main+0x104>
    return listelm->next;
ffffffffc0204618:	000cd697          	auipc	a3,0xcd
ffffffffc020461c:	eb868693          	addi	a3,a3,-328 # ffffffffc02d14d0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204620:	6698                	ld	a4,8(a3)
ffffffffc0204622:	0c878793          	addi	a5,a5,200
ffffffffc0204626:	06f71b63          	bne	a4,a5,ffffffffc020469c <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020462a:	629c                	ld	a5,0(a3)
ffffffffc020462c:	04f71863          	bne	a4,a5,ffffffffc020467c <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204630:	00003517          	auipc	a0,0x3
ffffffffc0204634:	06850513          	addi	a0,a0,104 # ffffffffc0207698 <default_pmm_manager+0xbd0>
ffffffffc0204638:	b61fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc020463c:	60a2                	ld	ra,8(sp)
ffffffffc020463e:	4501                	li	a0,0
ffffffffc0204640:	0141                	addi	sp,sp,16
ffffffffc0204642:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204644:	00003697          	auipc	a3,0x3
ffffffffc0204648:	f9468693          	addi	a3,a3,-108 # ffffffffc02075d8 <default_pmm_manager+0xb10>
ffffffffc020464c:	00002617          	auipc	a2,0x2
ffffffffc0204650:	0cc60613          	addi	a2,a2,204 # ffffffffc0206718 <commands+0x818>
ffffffffc0204654:	41500593          	li	a1,1045
ffffffffc0204658:	00003517          	auipc	a0,0x3
ffffffffc020465c:	e9850513          	addi	a0,a0,-360 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204660:	e33fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204664:	00003617          	auipc	a2,0x3
ffffffffc0204668:	f2c60613          	addi	a2,a2,-212 # ffffffffc0207590 <default_pmm_manager+0xac8>
ffffffffc020466c:	40c00593          	li	a1,1036
ffffffffc0204670:	00003517          	auipc	a0,0x3
ffffffffc0204674:	e8050513          	addi	a0,a0,-384 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204678:	e1bfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020467c:	00003697          	auipc	a3,0x3
ffffffffc0204680:	fec68693          	addi	a3,a3,-20 # ffffffffc0207668 <default_pmm_manager+0xba0>
ffffffffc0204684:	00002617          	auipc	a2,0x2
ffffffffc0204688:	09460613          	addi	a2,a2,148 # ffffffffc0206718 <commands+0x818>
ffffffffc020468c:	41800593          	li	a1,1048
ffffffffc0204690:	00003517          	auipc	a0,0x3
ffffffffc0204694:	e6050513          	addi	a0,a0,-416 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204698:	dfbfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020469c:	00003697          	auipc	a3,0x3
ffffffffc02046a0:	f9c68693          	addi	a3,a3,-100 # ffffffffc0207638 <default_pmm_manager+0xb70>
ffffffffc02046a4:	00002617          	auipc	a2,0x2
ffffffffc02046a8:	07460613          	addi	a2,a2,116 # ffffffffc0206718 <commands+0x818>
ffffffffc02046ac:	41700593          	li	a1,1047
ffffffffc02046b0:	00003517          	auipc	a0,0x3
ffffffffc02046b4:	e4050513          	addi	a0,a0,-448 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc02046b8:	ddbfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc02046bc:	00003697          	auipc	a3,0x3
ffffffffc02046c0:	f6c68693          	addi	a3,a3,-148 # ffffffffc0207628 <default_pmm_manager+0xb60>
ffffffffc02046c4:	00002617          	auipc	a2,0x2
ffffffffc02046c8:	05460613          	addi	a2,a2,84 # ffffffffc0206718 <commands+0x818>
ffffffffc02046cc:	41600593          	li	a1,1046
ffffffffc02046d0:	00003517          	auipc	a0,0x3
ffffffffc02046d4:	e2050513          	addi	a0,a0,-480 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc02046d8:	dbbfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02046dc <do_execve>:
{
ffffffffc02046dc:	7171                	addi	sp,sp,-176
ffffffffc02046de:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046e0:	000cdd97          	auipc	s11,0xcd
ffffffffc02046e4:	e88d8d93          	addi	s11,s11,-376 # ffffffffc02d1568 <current>
ffffffffc02046e8:	000db783          	ld	a5,0(s11)
{
ffffffffc02046ec:	e54e                	sd	s3,136(sp)
ffffffffc02046ee:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046f0:	0287b983          	ld	s3,40(a5)
{
ffffffffc02046f4:	e94a                	sd	s2,144(sp)
ffffffffc02046f6:	f4de                	sd	s7,104(sp)
ffffffffc02046f8:	892a                	mv	s2,a0
ffffffffc02046fa:	8bb2                	mv	s7,a2
ffffffffc02046fc:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02046fe:	862e                	mv	a2,a1
ffffffffc0204700:	4681                	li	a3,0
ffffffffc0204702:	85aa                	mv	a1,a0
ffffffffc0204704:	854e                	mv	a0,s3
{
ffffffffc0204706:	f506                	sd	ra,168(sp)
ffffffffc0204708:	f122                	sd	s0,160(sp)
ffffffffc020470a:	e152                	sd	s4,128(sp)
ffffffffc020470c:	fcd6                	sd	s5,120(sp)
ffffffffc020470e:	f8da                	sd	s6,112(sp)
ffffffffc0204710:	f0e2                	sd	s8,96(sp)
ffffffffc0204712:	ece6                	sd	s9,88(sp)
ffffffffc0204714:	e8ea                	sd	s10,80(sp)
ffffffffc0204716:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204718:	d0eff0ef          	jal	ra,ffffffffc0203c26 <user_mem_check>
ffffffffc020471c:	40050a63          	beqz	a0,ffffffffc0204b30 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204720:	4641                	li	a2,16
ffffffffc0204722:	4581                	li	a1,0
ffffffffc0204724:	1808                	addi	a0,sp,48
ffffffffc0204726:	542010ef          	jal	ra,ffffffffc0205c68 <memset>
    memcpy(local_name, name, len);
ffffffffc020472a:	47bd                	li	a5,15
ffffffffc020472c:	8626                	mv	a2,s1
ffffffffc020472e:	1e97e263          	bltu	a5,s1,ffffffffc0204912 <do_execve+0x236>
ffffffffc0204732:	85ca                	mv	a1,s2
ffffffffc0204734:	1808                	addi	a0,sp,48
ffffffffc0204736:	544010ef          	jal	ra,ffffffffc0205c7a <memcpy>
    if (mm != NULL)
ffffffffc020473a:	1e098363          	beqz	s3,ffffffffc0204920 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc020473e:	00003517          	auipc	a0,0x3
ffffffffc0204742:	bba50513          	addi	a0,a0,-1094 # ffffffffc02072f8 <default_pmm_manager+0x830>
ffffffffc0204746:	a8bfb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc020474a:	000cd797          	auipc	a5,0xcd
ffffffffc020474e:	dee7b783          	ld	a5,-530(a5) # ffffffffc02d1538 <boot_pgdir_pa>
ffffffffc0204752:	577d                	li	a4,-1
ffffffffc0204754:	177e                	slli	a4,a4,0x3f
ffffffffc0204756:	83b1                	srli	a5,a5,0xc
ffffffffc0204758:	8fd9                	or	a5,a5,a4
ffffffffc020475a:	18079073          	csrw	satp,a5
ffffffffc020475e:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7f00>
ffffffffc0204762:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204766:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020476a:	2c070463          	beqz	a4,ffffffffc0204a32 <do_execve+0x356>
        current->mm = NULL;
ffffffffc020476e:	000db783          	ld	a5,0(s11)
ffffffffc0204772:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204776:	e3bfe0ef          	jal	ra,ffffffffc02035b0 <mm_create>
ffffffffc020477a:	84aa                	mv	s1,a0
ffffffffc020477c:	1c050d63          	beqz	a0,ffffffffc0204956 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204780:	4505                	li	a0,1
ffffffffc0204782:	e0afd0ef          	jal	ra,ffffffffc0201d8c <alloc_pages>
ffffffffc0204786:	3a050963          	beqz	a0,ffffffffc0204b38 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc020478a:	000cdc97          	auipc	s9,0xcd
ffffffffc020478e:	dc6c8c93          	addi	s9,s9,-570 # ffffffffc02d1550 <pages>
ffffffffc0204792:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204796:	000cdc17          	auipc	s8,0xcd
ffffffffc020479a:	db2c0c13          	addi	s8,s8,-590 # ffffffffc02d1548 <npage>
    return page - pages + nbase;
ffffffffc020479e:	00004717          	auipc	a4,0x4
ffffffffc02047a2:	dd273703          	ld	a4,-558(a4) # ffffffffc0208570 <nbase>
ffffffffc02047a6:	40d506b3          	sub	a3,a0,a3
ffffffffc02047aa:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02047ac:	5afd                	li	s5,-1
ffffffffc02047ae:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02047b2:	96ba                	add	a3,a3,a4
ffffffffc02047b4:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02047b6:	00cad713          	srli	a4,s5,0xc
ffffffffc02047ba:	ec3a                	sd	a4,24(sp)
ffffffffc02047bc:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02047be:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02047c0:	38f77063          	bgeu	a4,a5,ffffffffc0204b40 <do_execve+0x464>
ffffffffc02047c4:	000cdb17          	auipc	s6,0xcd
ffffffffc02047c8:	d9cb0b13          	addi	s6,s6,-612 # ffffffffc02d1560 <va_pa_offset>
ffffffffc02047cc:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02047d0:	6605                	lui	a2,0x1
ffffffffc02047d2:	000cd597          	auipc	a1,0xcd
ffffffffc02047d6:	d6e5b583          	ld	a1,-658(a1) # ffffffffc02d1540 <boot_pgdir_va>
ffffffffc02047da:	9936                	add	s2,s2,a3
ffffffffc02047dc:	854a                	mv	a0,s2
ffffffffc02047de:	49c010ef          	jal	ra,ffffffffc0205c7a <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047e2:	7782                	ld	a5,32(sp)
ffffffffc02047e4:	4398                	lw	a4,0(a5)
ffffffffc02047e6:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02047ea:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047ee:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e77>
ffffffffc02047f2:	14f71863          	bne	a4,a5,ffffffffc0204942 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02047f6:	7682                	ld	a3,32(sp)
ffffffffc02047f8:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02047fc:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204800:	00371793          	slli	a5,a4,0x3
ffffffffc0204804:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204806:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204808:	078e                	slli	a5,a5,0x3
ffffffffc020480a:	97ce                	add	a5,a5,s3
ffffffffc020480c:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc020480e:	00f9fc63          	bgeu	s3,a5,ffffffffc0204826 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204812:	0009a783          	lw	a5,0(s3)
ffffffffc0204816:	4705                	li	a4,1
ffffffffc0204818:	14e78163          	beq	a5,a4,ffffffffc020495a <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc020481c:	77a2                	ld	a5,40(sp)
ffffffffc020481e:	03898993          	addi	s3,s3,56
ffffffffc0204822:	fef9e8e3          	bltu	s3,a5,ffffffffc0204812 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204826:	4701                	li	a4,0
ffffffffc0204828:	46ad                	li	a3,11
ffffffffc020482a:	00100637          	lui	a2,0x100
ffffffffc020482e:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204832:	8526                	mv	a0,s1
ffffffffc0204834:	f0ffe0ef          	jal	ra,ffffffffc0203742 <mm_map>
ffffffffc0204838:	892a                	mv	s2,a0
ffffffffc020483a:	1e051263          	bnez	a0,ffffffffc0204a1e <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc020483e:	6c88                	ld	a0,24(s1)
ffffffffc0204840:	467d                	li	a2,31
ffffffffc0204842:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204846:	c85fe0ef          	jal	ra,ffffffffc02034ca <pgdir_alloc_page>
ffffffffc020484a:	38050363          	beqz	a0,ffffffffc0204bd0 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc020484e:	6c88                	ld	a0,24(s1)
ffffffffc0204850:	467d                	li	a2,31
ffffffffc0204852:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204856:	c75fe0ef          	jal	ra,ffffffffc02034ca <pgdir_alloc_page>
ffffffffc020485a:	34050b63          	beqz	a0,ffffffffc0204bb0 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020485e:	6c88                	ld	a0,24(s1)
ffffffffc0204860:	467d                	li	a2,31
ffffffffc0204862:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204866:	c65fe0ef          	jal	ra,ffffffffc02034ca <pgdir_alloc_page>
ffffffffc020486a:	32050363          	beqz	a0,ffffffffc0204b90 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020486e:	6c88                	ld	a0,24(s1)
ffffffffc0204870:	467d                	li	a2,31
ffffffffc0204872:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204876:	c55fe0ef          	jal	ra,ffffffffc02034ca <pgdir_alloc_page>
ffffffffc020487a:	2e050b63          	beqz	a0,ffffffffc0204b70 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc020487e:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204880:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204884:	6c94                	ld	a3,24(s1)
ffffffffc0204886:	2785                	addiw	a5,a5,1
ffffffffc0204888:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc020488a:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020488c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204890:	2cf6e463          	bltu	a3,a5,ffffffffc0204b58 <do_execve+0x47c>
ffffffffc0204894:	000b3783          	ld	a5,0(s6)
ffffffffc0204898:	577d                	li	a4,-1
ffffffffc020489a:	177e                	slli	a4,a4,0x3f
ffffffffc020489c:	8e9d                	sub	a3,a3,a5
ffffffffc020489e:	00c6d793          	srli	a5,a3,0xc
ffffffffc02048a2:	f654                	sd	a3,168(a2)
ffffffffc02048a4:	8fd9                	or	a5,a5,a4
ffffffffc02048a6:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02048aa:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048ac:	4581                	li	a1,0
ffffffffc02048ae:	12000613          	li	a2,288
ffffffffc02048b2:	8526                	mv	a0,s1
ffffffffc02048b4:	3b4010ef          	jal	ra,ffffffffc0205c68 <memset>
    tf->epc = elf->e_entry;
ffffffffc02048b8:	7782                	ld	a5,32(sp)
ffffffffc02048ba:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc02048bc:	4785                	li	a5,1
ffffffffc02048be:	07fe                	slli	a5,a5,0x1f
ffffffffc02048c0:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;
ffffffffc02048c2:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02048c6:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048ca:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02048ce:	edf7f793          	andi	a5,a5,-289
ffffffffc02048d2:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048d6:	0b440413          	addi	s0,s0,180
ffffffffc02048da:	4641                	li	a2,16
ffffffffc02048dc:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02048de:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048e2:	8522                	mv	a0,s0
ffffffffc02048e4:	384010ef          	jal	ra,ffffffffc0205c68 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02048e8:	463d                	li	a2,15
ffffffffc02048ea:	180c                	addi	a1,sp,48
ffffffffc02048ec:	8522                	mv	a0,s0
ffffffffc02048ee:	38c010ef          	jal	ra,ffffffffc0205c7a <memcpy>
}
ffffffffc02048f2:	70aa                	ld	ra,168(sp)
ffffffffc02048f4:	740a                	ld	s0,160(sp)
ffffffffc02048f6:	64ea                	ld	s1,152(sp)
ffffffffc02048f8:	69aa                	ld	s3,136(sp)
ffffffffc02048fa:	6a0a                	ld	s4,128(sp)
ffffffffc02048fc:	7ae6                	ld	s5,120(sp)
ffffffffc02048fe:	7b46                	ld	s6,112(sp)
ffffffffc0204900:	7ba6                	ld	s7,104(sp)
ffffffffc0204902:	7c06                	ld	s8,96(sp)
ffffffffc0204904:	6ce6                	ld	s9,88(sp)
ffffffffc0204906:	6d46                	ld	s10,80(sp)
ffffffffc0204908:	6da6                	ld	s11,72(sp)
ffffffffc020490a:	854a                	mv	a0,s2
ffffffffc020490c:	694a                	ld	s2,144(sp)
ffffffffc020490e:	614d                	addi	sp,sp,176
ffffffffc0204910:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204912:	463d                	li	a2,15
ffffffffc0204914:	85ca                	mv	a1,s2
ffffffffc0204916:	1808                	addi	a0,sp,48
ffffffffc0204918:	362010ef          	jal	ra,ffffffffc0205c7a <memcpy>
    if (mm != NULL)
ffffffffc020491c:	e20991e3          	bnez	s3,ffffffffc020473e <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204920:	000db783          	ld	a5,0(s11)
ffffffffc0204924:	779c                	ld	a5,40(a5)
ffffffffc0204926:	e40788e3          	beqz	a5,ffffffffc0204776 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc020492a:	00003617          	auipc	a2,0x3
ffffffffc020492e:	d8e60613          	addi	a2,a2,-626 # ffffffffc02076b8 <default_pmm_manager+0xbf0>
ffffffffc0204932:	28700593          	li	a1,647
ffffffffc0204936:	00003517          	auipc	a0,0x3
ffffffffc020493a:	bba50513          	addi	a0,a0,-1094 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc020493e:	b55fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc0204942:	8526                	mv	a0,s1
ffffffffc0204944:	c22ff0ef          	jal	ra,ffffffffc0203d66 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204948:	8526                	mv	a0,s1
ffffffffc020494a:	da7fe0ef          	jal	ra,ffffffffc02036f0 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc020494e:	5961                	li	s2,-8
    do_exit(ret);
ffffffffc0204950:	854a                	mv	a0,s2
ffffffffc0204952:	94bff0ef          	jal	ra,ffffffffc020429c <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204956:	5971                	li	s2,-4
ffffffffc0204958:	bfe5                	j	ffffffffc0204950 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc020495a:	0289b603          	ld	a2,40(s3)
ffffffffc020495e:	0209b783          	ld	a5,32(s3)
ffffffffc0204962:	1cf66d63          	bltu	a2,a5,ffffffffc0204b3c <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204966:	0049a783          	lw	a5,4(s3)
ffffffffc020496a:	0017f693          	andi	a3,a5,1
ffffffffc020496e:	c291                	beqz	a3,ffffffffc0204972 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204970:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204972:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204976:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204978:	e779                	bnez	a4,ffffffffc0204a46 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc020497a:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc020497c:	c781                	beqz	a5,ffffffffc0204984 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc020497e:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204982:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204984:	0026f793          	andi	a5,a3,2
ffffffffc0204988:	e3f1                	bnez	a5,ffffffffc0204a4c <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc020498a:	0046f793          	andi	a5,a3,4
ffffffffc020498e:	c399                	beqz	a5,ffffffffc0204994 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204990:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204994:	0109b583          	ld	a1,16(s3)
ffffffffc0204998:	4701                	li	a4,0
ffffffffc020499a:	8526                	mv	a0,s1
ffffffffc020499c:	da7fe0ef          	jal	ra,ffffffffc0203742 <mm_map>
ffffffffc02049a0:	892a                	mv	s2,a0
ffffffffc02049a2:	ed35                	bnez	a0,ffffffffc0204a1e <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049a4:	0109bb83          	ld	s7,16(s3)
ffffffffc02049a8:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc02049aa:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049ae:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049b2:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049b6:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc02049b8:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049ba:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc02049bc:	054be963          	bltu	s7,s4,ffffffffc0204a0e <do_execve+0x332>
ffffffffc02049c0:	aa95                	j	ffffffffc0204b34 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02049c2:	6785                	lui	a5,0x1
ffffffffc02049c4:	415b8533          	sub	a0,s7,s5
ffffffffc02049c8:	9abe                	add	s5,s5,a5
ffffffffc02049ca:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc02049ce:	015a7463          	bgeu	s4,s5,ffffffffc02049d6 <do_execve+0x2fa>
                size -= la - end;
ffffffffc02049d2:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc02049d6:	000cb683          	ld	a3,0(s9)
ffffffffc02049da:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02049dc:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02049e0:	40d406b3          	sub	a3,s0,a3
ffffffffc02049e4:	8699                	srai	a3,a3,0x6
ffffffffc02049e6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02049e8:	67e2                	ld	a5,24(sp)
ffffffffc02049ea:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02049ee:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049f0:	14b87863          	bgeu	a6,a1,ffffffffc0204b40 <do_execve+0x464>
ffffffffc02049f4:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02049f8:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc02049fa:	9bb2                	add	s7,s7,a2
ffffffffc02049fc:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc02049fe:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204a00:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a02:	278010ef          	jal	ra,ffffffffc0205c7a <memcpy>
            start += size, from += size;
ffffffffc0204a06:	6622                	ld	a2,8(sp)
ffffffffc0204a08:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204a0a:	054bf363          	bgeu	s7,s4,ffffffffc0204a50 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a0e:	6c88                	ld	a0,24(s1)
ffffffffc0204a10:	866a                	mv	a2,s10
ffffffffc0204a12:	85d6                	mv	a1,s5
ffffffffc0204a14:	ab7fe0ef          	jal	ra,ffffffffc02034ca <pgdir_alloc_page>
ffffffffc0204a18:	842a                	mv	s0,a0
ffffffffc0204a1a:	f545                	bnez	a0,ffffffffc02049c2 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204a1c:	5971                	li	s2,-4
    exit_mmap(mm);
ffffffffc0204a1e:	8526                	mv	a0,s1
ffffffffc0204a20:	e6dfe0ef          	jal	ra,ffffffffc020388c <exit_mmap>
    put_pgdir(mm);
ffffffffc0204a24:	8526                	mv	a0,s1
ffffffffc0204a26:	b40ff0ef          	jal	ra,ffffffffc0203d66 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204a2a:	8526                	mv	a0,s1
ffffffffc0204a2c:	cc5fe0ef          	jal	ra,ffffffffc02036f0 <mm_destroy>
    return ret;
ffffffffc0204a30:	b705                	j	ffffffffc0204950 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204a32:	854e                	mv	a0,s3
ffffffffc0204a34:	e59fe0ef          	jal	ra,ffffffffc020388c <exit_mmap>
            put_pgdir(mm);
ffffffffc0204a38:	854e                	mv	a0,s3
ffffffffc0204a3a:	b2cff0ef          	jal	ra,ffffffffc0203d66 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204a3e:	854e                	mv	a0,s3
ffffffffc0204a40:	cb1fe0ef          	jal	ra,ffffffffc02036f0 <mm_destroy>
ffffffffc0204a44:	b32d                	j	ffffffffc020476e <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204a46:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a4a:	fb95                	bnez	a5,ffffffffc020497e <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204a4c:	4d5d                	li	s10,23
ffffffffc0204a4e:	bf35                	j	ffffffffc020498a <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204a50:	0109b683          	ld	a3,16(s3)
ffffffffc0204a54:	0289b903          	ld	s2,40(s3)
ffffffffc0204a58:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204a5a:	075bfd63          	bgeu	s7,s5,ffffffffc0204ad4 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204a5e:	db790fe3          	beq	s2,s7,ffffffffc020481c <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204a62:	6785                	lui	a5,0x1
ffffffffc0204a64:	00fb8533          	add	a0,s7,a5
ffffffffc0204a68:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204a6c:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204a70:	0b597d63          	bgeu	s2,s5,ffffffffc0204b2a <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204a74:	000cb683          	ld	a3,0(s9)
ffffffffc0204a78:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a7a:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204a7e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a82:	8699                	srai	a3,a3,0x6
ffffffffc0204a84:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a86:	67e2                	ld	a5,24(sp)
ffffffffc0204a88:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a8c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a8e:	0ac5f963          	bgeu	a1,a2,ffffffffc0204b40 <do_execve+0x464>
ffffffffc0204a92:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204a96:	8652                	mv	a2,s4
ffffffffc0204a98:	4581                	li	a1,0
ffffffffc0204a9a:	96c2                	add	a3,a3,a6
ffffffffc0204a9c:	9536                	add	a0,a0,a3
ffffffffc0204a9e:	1ca010ef          	jal	ra,ffffffffc0205c68 <memset>
            start += size;
ffffffffc0204aa2:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204aa6:	03597463          	bgeu	s2,s5,ffffffffc0204ace <do_execve+0x3f2>
ffffffffc0204aaa:	d6e909e3          	beq	s2,a4,ffffffffc020481c <do_execve+0x140>
ffffffffc0204aae:	00003697          	auipc	a3,0x3
ffffffffc0204ab2:	c3268693          	addi	a3,a3,-974 # ffffffffc02076e0 <default_pmm_manager+0xc18>
ffffffffc0204ab6:	00002617          	auipc	a2,0x2
ffffffffc0204aba:	c6260613          	addi	a2,a2,-926 # ffffffffc0206718 <commands+0x818>
ffffffffc0204abe:	2f000593          	li	a1,752
ffffffffc0204ac2:	00003517          	auipc	a0,0x3
ffffffffc0204ac6:	a2e50513          	addi	a0,a0,-1490 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204aca:	9c9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0204ace:	ff5710e3          	bne	a4,s5,ffffffffc0204aae <do_execve+0x3d2>
ffffffffc0204ad2:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204ad4:	d52bf4e3          	bgeu	s7,s2,ffffffffc020481c <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204ad8:	6c88                	ld	a0,24(s1)
ffffffffc0204ada:	866a                	mv	a2,s10
ffffffffc0204adc:	85d6                	mv	a1,s5
ffffffffc0204ade:	9edfe0ef          	jal	ra,ffffffffc02034ca <pgdir_alloc_page>
ffffffffc0204ae2:	842a                	mv	s0,a0
ffffffffc0204ae4:	dd05                	beqz	a0,ffffffffc0204a1c <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204ae6:	6785                	lui	a5,0x1
ffffffffc0204ae8:	415b8533          	sub	a0,s7,s5
ffffffffc0204aec:	9abe                	add	s5,s5,a5
ffffffffc0204aee:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204af2:	01597463          	bgeu	s2,s5,ffffffffc0204afa <do_execve+0x41e>
                size -= la - end;
ffffffffc0204af6:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204afa:	000cb683          	ld	a3,0(s9)
ffffffffc0204afe:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b00:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204b04:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b08:	8699                	srai	a3,a3,0x6
ffffffffc0204b0a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b0c:	67e2                	ld	a5,24(sp)
ffffffffc0204b0e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b12:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b14:	02b87663          	bgeu	a6,a1,ffffffffc0204b40 <do_execve+0x464>
ffffffffc0204b18:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b1c:	4581                	li	a1,0
            start += size;
ffffffffc0204b1e:	9bb2                	add	s7,s7,a2
ffffffffc0204b20:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b22:	9536                	add	a0,a0,a3
ffffffffc0204b24:	144010ef          	jal	ra,ffffffffc0205c68 <memset>
ffffffffc0204b28:	b775                	j	ffffffffc0204ad4 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b2a:	417a8a33          	sub	s4,s5,s7
ffffffffc0204b2e:	b799                	j	ffffffffc0204a74 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204b30:	5975                	li	s2,-3
ffffffffc0204b32:	b3c1                	j	ffffffffc02048f2 <do_execve+0x216>
        while (start < end)
ffffffffc0204b34:	86de                	mv	a3,s7
ffffffffc0204b36:	bf39                	j	ffffffffc0204a54 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204b38:	5971                	li	s2,-4
ffffffffc0204b3a:	bdc5                	j	ffffffffc0204a2a <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204b3c:	5961                	li	s2,-8
ffffffffc0204b3e:	b5c5                	j	ffffffffc0204a1e <do_execve+0x342>
ffffffffc0204b40:	00002617          	auipc	a2,0x2
ffffffffc0204b44:	fc060613          	addi	a2,a2,-64 # ffffffffc0206b00 <default_pmm_manager+0x38>
ffffffffc0204b48:	07100593          	li	a1,113
ffffffffc0204b4c:	00002517          	auipc	a0,0x2
ffffffffc0204b50:	fdc50513          	addi	a0,a0,-36 # ffffffffc0206b28 <default_pmm_manager+0x60>
ffffffffc0204b54:	93ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b58:	00002617          	auipc	a2,0x2
ffffffffc0204b5c:	05060613          	addi	a2,a2,80 # ffffffffc0206ba8 <default_pmm_manager+0xe0>
ffffffffc0204b60:	30f00593          	li	a1,783
ffffffffc0204b64:	00003517          	auipc	a0,0x3
ffffffffc0204b68:	98c50513          	addi	a0,a0,-1652 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204b6c:	927fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b70:	00003697          	auipc	a3,0x3
ffffffffc0204b74:	c8868693          	addi	a3,a3,-888 # ffffffffc02077f8 <default_pmm_manager+0xd30>
ffffffffc0204b78:	00002617          	auipc	a2,0x2
ffffffffc0204b7c:	ba060613          	addi	a2,a2,-1120 # ffffffffc0206718 <commands+0x818>
ffffffffc0204b80:	30a00593          	li	a1,778
ffffffffc0204b84:	00003517          	auipc	a0,0x3
ffffffffc0204b88:	96c50513          	addi	a0,a0,-1684 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204b8c:	907fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b90:	00003697          	auipc	a3,0x3
ffffffffc0204b94:	c2068693          	addi	a3,a3,-992 # ffffffffc02077b0 <default_pmm_manager+0xce8>
ffffffffc0204b98:	00002617          	auipc	a2,0x2
ffffffffc0204b9c:	b8060613          	addi	a2,a2,-1152 # ffffffffc0206718 <commands+0x818>
ffffffffc0204ba0:	30900593          	li	a1,777
ffffffffc0204ba4:	00003517          	auipc	a0,0x3
ffffffffc0204ba8:	94c50513          	addi	a0,a0,-1716 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204bac:	8e7fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bb0:	00003697          	auipc	a3,0x3
ffffffffc0204bb4:	bb868693          	addi	a3,a3,-1096 # ffffffffc0207768 <default_pmm_manager+0xca0>
ffffffffc0204bb8:	00002617          	auipc	a2,0x2
ffffffffc0204bbc:	b6060613          	addi	a2,a2,-1184 # ffffffffc0206718 <commands+0x818>
ffffffffc0204bc0:	30800593          	li	a1,776
ffffffffc0204bc4:	00003517          	auipc	a0,0x3
ffffffffc0204bc8:	92c50513          	addi	a0,a0,-1748 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204bcc:	8c7fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204bd0:	00003697          	auipc	a3,0x3
ffffffffc0204bd4:	b5068693          	addi	a3,a3,-1200 # ffffffffc0207720 <default_pmm_manager+0xc58>
ffffffffc0204bd8:	00002617          	auipc	a2,0x2
ffffffffc0204bdc:	b4060613          	addi	a2,a2,-1216 # ffffffffc0206718 <commands+0x818>
ffffffffc0204be0:	30700593          	li	a1,775
ffffffffc0204be4:	00003517          	auipc	a0,0x3
ffffffffc0204be8:	90c50513          	addi	a0,a0,-1780 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204bec:	8a7fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204bf0 <user_main>:
{
ffffffffc0204bf0:	1101                	addi	sp,sp,-32
ffffffffc0204bf2:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204bf4:	000cd917          	auipc	s2,0xcd
ffffffffc0204bf8:	97490913          	addi	s2,s2,-1676 # ffffffffc02d1568 <current>
ffffffffc0204bfc:	00093783          	ld	a5,0(s2)
ffffffffc0204c00:	00003617          	auipc	a2,0x3
ffffffffc0204c04:	c4060613          	addi	a2,a2,-960 # ffffffffc0207840 <default_pmm_manager+0xd78>
ffffffffc0204c08:	00003517          	auipc	a0,0x3
ffffffffc0204c0c:	c4850513          	addi	a0,a0,-952 # ffffffffc0207850 <default_pmm_manager+0xd88>
ffffffffc0204c10:	43cc                	lw	a1,4(a5)
{
ffffffffc0204c12:	ec06                	sd	ra,24(sp)
ffffffffc0204c14:	e822                	sd	s0,16(sp)
ffffffffc0204c16:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c18:	d80fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204c1c:	00003517          	auipc	a0,0x3
ffffffffc0204c20:	c2450513          	addi	a0,a0,-988 # ffffffffc0207840 <default_pmm_manager+0xd78>
ffffffffc0204c24:	7a3000ef          	jal	ra,ffffffffc0205bc6 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204c28:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204c2c:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c2e:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c32:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c34:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c36:	6789                	lui	a5,0x2
ffffffffc0204c38:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8050>
ffffffffc0204c3c:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c3e:	8522                	mv	a0,s0
ffffffffc0204c40:	03a010ef          	jal	ra,ffffffffc0205c7a <memcpy>
    current->tf = new_tf;
ffffffffc0204c44:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204c48:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204c4c:	af068693          	addi	a3,a3,-1296 # b738 <_binary_obj___user_priority_out_size>
ffffffffc0204c50:	00088617          	auipc	a2,0x88
ffffffffc0204c54:	a9860613          	addi	a2,a2,-1384 # ffffffffc028c6e8 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204c58:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204c5a:	85a6                	mv	a1,s1
ffffffffc0204c5c:	00003517          	auipc	a0,0x3
ffffffffc0204c60:	be450513          	addi	a0,a0,-1052 # ffffffffc0207840 <default_pmm_manager+0xd78>
ffffffffc0204c64:	a79ff0ef          	jal	ra,ffffffffc02046dc <do_execve>
    asm volatile(
ffffffffc0204c68:	8122                	mv	sp,s0
ffffffffc0204c6a:	a06fc06f          	j	ffffffffc0200e70 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204c6e:	00003617          	auipc	a2,0x3
ffffffffc0204c72:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0207878 <default_pmm_manager+0xdb0>
ffffffffc0204c76:	3ff00593          	li	a1,1023
ffffffffc0204c7a:	00003517          	auipc	a0,0x3
ffffffffc0204c7e:	87650513          	addi	a0,a0,-1930 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204c82:	811fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204c86 <do_yield>:
    current->need_resched = 1;
ffffffffc0204c86:	000cd797          	auipc	a5,0xcd
ffffffffc0204c8a:	8e27b783          	ld	a5,-1822(a5) # ffffffffc02d1568 <current>
ffffffffc0204c8e:	4705                	li	a4,1
ffffffffc0204c90:	ef98                	sd	a4,24(a5)
}
ffffffffc0204c92:	4501                	li	a0,0
ffffffffc0204c94:	8082                	ret

ffffffffc0204c96 <do_wait>:
{
ffffffffc0204c96:	1101                	addi	sp,sp,-32
ffffffffc0204c98:	e822                	sd	s0,16(sp)
ffffffffc0204c9a:	e426                	sd	s1,8(sp)
ffffffffc0204c9c:	ec06                	sd	ra,24(sp)
ffffffffc0204c9e:	842e                	mv	s0,a1
ffffffffc0204ca0:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204ca2:	c999                	beqz	a1,ffffffffc0204cb8 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204ca4:	000cd797          	auipc	a5,0xcd
ffffffffc0204ca8:	8c47b783          	ld	a5,-1852(a5) # ffffffffc02d1568 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204cac:	7788                	ld	a0,40(a5)
ffffffffc0204cae:	4685                	li	a3,1
ffffffffc0204cb0:	4611                	li	a2,4
ffffffffc0204cb2:	f75fe0ef          	jal	ra,ffffffffc0203c26 <user_mem_check>
ffffffffc0204cb6:	c909                	beqz	a0,ffffffffc0204cc8 <do_wait+0x32>
ffffffffc0204cb8:	85a2                	mv	a1,s0
}
ffffffffc0204cba:	6442                	ld	s0,16(sp)
ffffffffc0204cbc:	60e2                	ld	ra,24(sp)
ffffffffc0204cbe:	8526                	mv	a0,s1
ffffffffc0204cc0:	64a2                	ld	s1,8(sp)
ffffffffc0204cc2:	6105                	addi	sp,sp,32
ffffffffc0204cc4:	f22ff06f          	j	ffffffffc02043e6 <do_wait.part.0>
ffffffffc0204cc8:	60e2                	ld	ra,24(sp)
ffffffffc0204cca:	6442                	ld	s0,16(sp)
ffffffffc0204ccc:	64a2                	ld	s1,8(sp)
ffffffffc0204cce:	5575                	li	a0,-3
ffffffffc0204cd0:	6105                	addi	sp,sp,32
ffffffffc0204cd2:	8082                	ret

ffffffffc0204cd4 <do_kill>:
{
ffffffffc0204cd4:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204cd6:	6789                	lui	a5,0x2
{
ffffffffc0204cd8:	e406                	sd	ra,8(sp)
ffffffffc0204cda:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204cdc:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204ce0:	17f9                	addi	a5,a5,-2
ffffffffc0204ce2:	02e7e963          	bltu	a5,a4,ffffffffc0204d14 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ce6:	842a                	mv	s0,a0
ffffffffc0204ce8:	45a9                	li	a1,10
ffffffffc0204cea:	2501                	sext.w	a0,a0
ffffffffc0204cec:	2d7000ef          	jal	ra,ffffffffc02057c2 <hash32>
ffffffffc0204cf0:	02051793          	slli	a5,a0,0x20
ffffffffc0204cf4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204cf8:	000c8797          	auipc	a5,0xc8
ffffffffc0204cfc:	7d878793          	addi	a5,a5,2008 # ffffffffc02cd4d0 <hash_list>
ffffffffc0204d00:	953e                	add	a0,a0,a5
ffffffffc0204d02:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204d04:	a029                	j	ffffffffc0204d0e <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204d06:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204d0a:	00870b63          	beq	a4,s0,ffffffffc0204d20 <do_kill+0x4c>
ffffffffc0204d0e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204d10:	fef51be3          	bne	a0,a5,ffffffffc0204d06 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204d14:	5475                	li	s0,-3
}
ffffffffc0204d16:	60a2                	ld	ra,8(sp)
ffffffffc0204d18:	8522                	mv	a0,s0
ffffffffc0204d1a:	6402                	ld	s0,0(sp)
ffffffffc0204d1c:	0141                	addi	sp,sp,16
ffffffffc0204d1e:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204d20:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204d24:	00177693          	andi	a3,a4,1
ffffffffc0204d28:	e295                	bnez	a3,ffffffffc0204d4c <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d2a:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204d2c:	00176713          	ori	a4,a4,1
ffffffffc0204d30:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204d34:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d36:	fe06d0e3          	bgez	a3,ffffffffc0204d16 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204d3a:	f2878513          	addi	a0,a5,-216
ffffffffc0204d3e:	013000ef          	jal	ra,ffffffffc0205550 <wakeup_proc>
}
ffffffffc0204d42:	60a2                	ld	ra,8(sp)
ffffffffc0204d44:	8522                	mv	a0,s0
ffffffffc0204d46:	6402                	ld	s0,0(sp)
ffffffffc0204d48:	0141                	addi	sp,sp,16
ffffffffc0204d4a:	8082                	ret
        return -E_KILLED;
ffffffffc0204d4c:	545d                	li	s0,-9
ffffffffc0204d4e:	b7e1                	j	ffffffffc0204d16 <do_kill+0x42>

ffffffffc0204d50 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204d50:	1101                	addi	sp,sp,-32
ffffffffc0204d52:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204d54:	000cc797          	auipc	a5,0xcc
ffffffffc0204d58:	77c78793          	addi	a5,a5,1916 # ffffffffc02d14d0 <proc_list>
ffffffffc0204d5c:	ec06                	sd	ra,24(sp)
ffffffffc0204d5e:	e822                	sd	s0,16(sp)
ffffffffc0204d60:	e04a                	sd	s2,0(sp)
ffffffffc0204d62:	000c8497          	auipc	s1,0xc8
ffffffffc0204d66:	76e48493          	addi	s1,s1,1902 # ffffffffc02cd4d0 <hash_list>
ffffffffc0204d6a:	e79c                	sd	a5,8(a5)
ffffffffc0204d6c:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204d6e:	000cc717          	auipc	a4,0xcc
ffffffffc0204d72:	76270713          	addi	a4,a4,1890 # ffffffffc02d14d0 <proc_list>
ffffffffc0204d76:	87a6                	mv	a5,s1
ffffffffc0204d78:	e79c                	sd	a5,8(a5)
ffffffffc0204d7a:	e39c                	sd	a5,0(a5)
ffffffffc0204d7c:	07c1                	addi	a5,a5,16
ffffffffc0204d7e:	fef71de3          	bne	a4,a5,ffffffffc0204d78 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204d82:	f41fe0ef          	jal	ra,ffffffffc0203cc2 <alloc_proc>
ffffffffc0204d86:	000cc917          	auipc	s2,0xcc
ffffffffc0204d8a:	7ea90913          	addi	s2,s2,2026 # ffffffffc02d1570 <idleproc>
ffffffffc0204d8e:	00a93023          	sd	a0,0(s2)
ffffffffc0204d92:	0e050f63          	beqz	a0,ffffffffc0204e90 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204d96:	4789                	li	a5,2
ffffffffc0204d98:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204d9a:	00004797          	auipc	a5,0x4
ffffffffc0204d9e:	26678793          	addi	a5,a5,614 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204da2:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204da6:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204da8:	4785                	li	a5,1
ffffffffc0204daa:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204dac:	4641                	li	a2,16
ffffffffc0204dae:	4581                	li	a1,0
ffffffffc0204db0:	8522                	mv	a0,s0
ffffffffc0204db2:	6b7000ef          	jal	ra,ffffffffc0205c68 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204db6:	463d                	li	a2,15
ffffffffc0204db8:	00003597          	auipc	a1,0x3
ffffffffc0204dbc:	af858593          	addi	a1,a1,-1288 # ffffffffc02078b0 <default_pmm_manager+0xde8>
ffffffffc0204dc0:	8522                	mv	a0,s0
ffffffffc0204dc2:	6b9000ef          	jal	ra,ffffffffc0205c7a <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204dc6:	000cc717          	auipc	a4,0xcc
ffffffffc0204dca:	7ba70713          	addi	a4,a4,1978 # ffffffffc02d1580 <nr_process>
ffffffffc0204dce:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204dd0:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204dd4:	4601                	li	a2,0
    nr_process++;
ffffffffc0204dd6:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204dd8:	4581                	li	a1,0
ffffffffc0204dda:	fffff517          	auipc	a0,0xfffff
ffffffffc0204dde:	7de50513          	addi	a0,a0,2014 # ffffffffc02045b8 <init_main>
    nr_process++;
ffffffffc0204de2:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204de4:	000cc797          	auipc	a5,0xcc
ffffffffc0204de8:	78d7b223          	sd	a3,1924(a5) # ffffffffc02d1568 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204dec:	c60ff0ef          	jal	ra,ffffffffc020424c <kernel_thread>
ffffffffc0204df0:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204df2:	08a05363          	blez	a0,ffffffffc0204e78 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204df6:	6789                	lui	a5,0x2
ffffffffc0204df8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204dfc:	17f9                	addi	a5,a5,-2
ffffffffc0204dfe:	2501                	sext.w	a0,a0
ffffffffc0204e00:	02e7e363          	bltu	a5,a4,ffffffffc0204e26 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e04:	45a9                	li	a1,10
ffffffffc0204e06:	1bd000ef          	jal	ra,ffffffffc02057c2 <hash32>
ffffffffc0204e0a:	02051793          	slli	a5,a0,0x20
ffffffffc0204e0e:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e12:	96a6                	add	a3,a3,s1
ffffffffc0204e14:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e16:	a029                	j	ffffffffc0204e20 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204e18:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8004>
ffffffffc0204e1c:	04870b63          	beq	a4,s0,ffffffffc0204e72 <proc_init+0x122>
    return listelm->next;
ffffffffc0204e20:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e22:	fef69be3          	bne	a3,a5,ffffffffc0204e18 <proc_init+0xc8>
    return NULL;
ffffffffc0204e26:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e28:	0b478493          	addi	s1,a5,180
ffffffffc0204e2c:	4641                	li	a2,16
ffffffffc0204e2e:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204e30:	000cc417          	auipc	s0,0xcc
ffffffffc0204e34:	74840413          	addi	s0,s0,1864 # ffffffffc02d1578 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e38:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204e3a:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e3c:	62d000ef          	jal	ra,ffffffffc0205c68 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e40:	463d                	li	a2,15
ffffffffc0204e42:	00003597          	auipc	a1,0x3
ffffffffc0204e46:	a9658593          	addi	a1,a1,-1386 # ffffffffc02078d8 <default_pmm_manager+0xe10>
ffffffffc0204e4a:	8526                	mv	a0,s1
ffffffffc0204e4c:	62f000ef          	jal	ra,ffffffffc0205c7a <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204e50:	00093783          	ld	a5,0(s2)
ffffffffc0204e54:	cbb5                	beqz	a5,ffffffffc0204ec8 <proc_init+0x178>
ffffffffc0204e56:	43dc                	lw	a5,4(a5)
ffffffffc0204e58:	eba5                	bnez	a5,ffffffffc0204ec8 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204e5a:	601c                	ld	a5,0(s0)
ffffffffc0204e5c:	c7b1                	beqz	a5,ffffffffc0204ea8 <proc_init+0x158>
ffffffffc0204e5e:	43d8                	lw	a4,4(a5)
ffffffffc0204e60:	4785                	li	a5,1
ffffffffc0204e62:	04f71363          	bne	a4,a5,ffffffffc0204ea8 <proc_init+0x158>
}
ffffffffc0204e66:	60e2                	ld	ra,24(sp)
ffffffffc0204e68:	6442                	ld	s0,16(sp)
ffffffffc0204e6a:	64a2                	ld	s1,8(sp)
ffffffffc0204e6c:	6902                	ld	s2,0(sp)
ffffffffc0204e6e:	6105                	addi	sp,sp,32
ffffffffc0204e70:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204e72:	f2878793          	addi	a5,a5,-216
ffffffffc0204e76:	bf4d                	j	ffffffffc0204e28 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204e78:	00003617          	auipc	a2,0x3
ffffffffc0204e7c:	a4060613          	addi	a2,a2,-1472 # ffffffffc02078b8 <default_pmm_manager+0xdf0>
ffffffffc0204e80:	43b00593          	li	a1,1083
ffffffffc0204e84:	00002517          	auipc	a0,0x2
ffffffffc0204e88:	66c50513          	addi	a0,a0,1644 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204e8c:	e06fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204e90:	00003617          	auipc	a2,0x3
ffffffffc0204e94:	a0860613          	addi	a2,a2,-1528 # ffffffffc0207898 <default_pmm_manager+0xdd0>
ffffffffc0204e98:	42c00593          	li	a1,1068
ffffffffc0204e9c:	00002517          	auipc	a0,0x2
ffffffffc0204ea0:	65450513          	addi	a0,a0,1620 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204ea4:	deefb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204ea8:	00003697          	auipc	a3,0x3
ffffffffc0204eac:	a6068693          	addi	a3,a3,-1440 # ffffffffc0207908 <default_pmm_manager+0xe40>
ffffffffc0204eb0:	00002617          	auipc	a2,0x2
ffffffffc0204eb4:	86860613          	addi	a2,a2,-1944 # ffffffffc0206718 <commands+0x818>
ffffffffc0204eb8:	44200593          	li	a1,1090
ffffffffc0204ebc:	00002517          	auipc	a0,0x2
ffffffffc0204ec0:	63450513          	addi	a0,a0,1588 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204ec4:	dcefb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204ec8:	00003697          	auipc	a3,0x3
ffffffffc0204ecc:	a1868693          	addi	a3,a3,-1512 # ffffffffc02078e0 <default_pmm_manager+0xe18>
ffffffffc0204ed0:	00002617          	auipc	a2,0x2
ffffffffc0204ed4:	84860613          	addi	a2,a2,-1976 # ffffffffc0206718 <commands+0x818>
ffffffffc0204ed8:	44100593          	li	a1,1089
ffffffffc0204edc:	00002517          	auipc	a0,0x2
ffffffffc0204ee0:	61450513          	addi	a0,a0,1556 # ffffffffc02074f0 <default_pmm_manager+0xa28>
ffffffffc0204ee4:	daefb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204ee8 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204ee8:	1141                	addi	sp,sp,-16
ffffffffc0204eea:	e022                	sd	s0,0(sp)
ffffffffc0204eec:	e406                	sd	ra,8(sp)
ffffffffc0204eee:	000cc417          	auipc	s0,0xcc
ffffffffc0204ef2:	67a40413          	addi	s0,s0,1658 # ffffffffc02d1568 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204ef6:	6018                	ld	a4,0(s0)
ffffffffc0204ef8:	6f1c                	ld	a5,24(a4)
ffffffffc0204efa:	dffd                	beqz	a5,ffffffffc0204ef8 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204efc:	706000ef          	jal	ra,ffffffffc0205602 <schedule>
ffffffffc0204f00:	bfdd                	j	ffffffffc0204ef6 <cpu_idle+0xe>

ffffffffc0204f02 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204f02:	1141                	addi	sp,sp,-16
ffffffffc0204f04:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f06:	85aa                	mv	a1,a0
{
ffffffffc0204f08:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204f0a:	00003517          	auipc	a0,0x3
ffffffffc0204f0e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0207930 <default_pmm_manager+0xe68>
{
ffffffffc0204f12:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f14:	a84fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc0204f18:	000cc797          	auipc	a5,0xcc
ffffffffc0204f1c:	6507b783          	ld	a5,1616(a5) # ffffffffc02d1568 <current>
    if (priority == 0)
ffffffffc0204f20:	e801                	bnez	s0,ffffffffc0204f30 <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc0204f22:	60a2                	ld	ra,8(sp)
ffffffffc0204f24:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc0204f26:	4705                	li	a4,1
ffffffffc0204f28:	14e7a223          	sw	a4,324(a5)
}
ffffffffc0204f2c:	0141                	addi	sp,sp,16
ffffffffc0204f2e:	8082                	ret
ffffffffc0204f30:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc0204f32:	1487a223          	sw	s0,324(a5)
}
ffffffffc0204f36:	6402                	ld	s0,0(sp)
ffffffffc0204f38:	0141                	addi	sp,sp,16
ffffffffc0204f3a:	8082                	ret

ffffffffc0204f3c <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204f3c:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204f40:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204f44:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204f46:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204f48:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204f4c:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204f50:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204f54:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204f58:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204f5c:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204f60:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204f64:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204f68:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204f6c:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204f70:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204f74:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204f78:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204f7a:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204f7c:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204f80:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204f84:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204f88:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204f8c:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204f90:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204f94:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204f98:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204f9c:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204fa0:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204fa4:	8082                	ret

ffffffffc0204fa6 <stride_init>:
    elm->prev = elm->next = elm;
ffffffffc0204fa6:	e508                	sd	a0,8(a0)
ffffffffc0204fa8:	e108                	sd	a0,0(a0)
      * (1) init the ready process list: rq->run_list
      * (2) init the run pool: rq->lab6_run_pool
      * (3) set number of process: rq->proc_num to 0
      */
    list_init(&(rq->run_list));
    rq->lab6_run_pool = NULL;
ffffffffc0204faa:	00053c23          	sd	zero,24(a0)
    rq->proc_num = 0;
ffffffffc0204fae:	00052823          	sw	zero,16(a0)
    
}
ffffffffc0204fb2:	8082                	ret

ffffffffc0204fb4 <stride_pick_next>:
             (1.1) If using skew_heap, we can use le2proc get the p from rq->lab6_run_pol
             (1.2) If using list, we have to search list to find the p with minimum stride value
      * (2) update p;s stride value: p->lab6_stride
      * (3) return p
      */
       if (rq->lab6_run_pool == NULL)
ffffffffc0204fb4:	6d1c                	ld	a5,24(a0)
ffffffffc0204fb6:	cf81                	beqz	a5,ffffffffc0204fce <stride_pick_next+0x1a>
    {
        return NULL;
    }
    struct proc_struct *proc = le2proc(rq->lab6_run_pool, lab6_run_pool);
    proc->lab6_stride += BIG_STRIDE / proc->lab6_priority;
ffffffffc0204fb8:	4fd0                	lw	a2,28(a5)
ffffffffc0204fba:	400006b7          	lui	a3,0x40000
ffffffffc0204fbe:	4f98                	lw	a4,24(a5)
ffffffffc0204fc0:	02c6d6bb          	divuw	a3,a3,a2
    struct proc_struct *proc = le2proc(rq->lab6_run_pool, lab6_run_pool);
ffffffffc0204fc4:	ed878513          	addi	a0,a5,-296
    proc->lab6_stride += BIG_STRIDE / proc->lab6_priority;
ffffffffc0204fc8:	9f35                	addw	a4,a4,a3
ffffffffc0204fca:	cf98                	sw	a4,24(a5)
    return proc;
ffffffffc0204fcc:	8082                	ret
        return NULL;
ffffffffc0204fce:	4501                	li	a0,0
}
ffffffffc0204fd0:	8082                	ret

ffffffffc0204fd2 <stride_proc_tick>:
 */
static void
stride_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: YOUR CODE */
      if (proc->time_slice > 0)
ffffffffc0204fd2:	1205a783          	lw	a5,288(a1)
ffffffffc0204fd6:	00f05563          	blez	a5,ffffffffc0204fe0 <stride_proc_tick+0xe>
    {
        proc->time_slice--;
ffffffffc0204fda:	37fd                	addiw	a5,a5,-1
ffffffffc0204fdc:	12f5a023          	sw	a5,288(a1)
    }
    if (proc->time_slice == 0)
ffffffffc0204fe0:	e399                	bnez	a5,ffffffffc0204fe6 <stride_proc_tick+0x14>
    {
        proc->need_resched = 1;
ffffffffc0204fe2:	4785                	li	a5,1
ffffffffc0204fe4:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0204fe6:	8082                	ret

ffffffffc0204fe8 <skew_heap_merge.constprop.0>:
{
     a->left = a->right = a->parent = NULL;
}

static inline skew_heap_entry_t *
skew_heap_merge(skew_heap_entry_t *a, skew_heap_entry_t *b,
ffffffffc0204fe8:	7139                	addi	sp,sp,-64
ffffffffc0204fea:	f822                	sd	s0,48(sp)
ffffffffc0204fec:	fc06                	sd	ra,56(sp)
ffffffffc0204fee:	f426                	sd	s1,40(sp)
ffffffffc0204ff0:	f04a                	sd	s2,32(sp)
ffffffffc0204ff2:	ec4e                	sd	s3,24(sp)
ffffffffc0204ff4:	e852                	sd	s4,16(sp)
ffffffffc0204ff6:	e456                	sd	s5,8(sp)
ffffffffc0204ff8:	e05a                	sd	s6,0(sp)
ffffffffc0204ffa:	842e                	mv	s0,a1
                compare_f comp)
{
     if (a == NULL) return b;
ffffffffc0204ffc:	c925                	beqz	a0,ffffffffc020506c <skew_heap_merge.constprop.0+0x84>
ffffffffc0204ffe:	84aa                	mv	s1,a0
     else if (b == NULL) return a;
ffffffffc0205000:	c1ed                	beqz	a1,ffffffffc02050e2 <skew_heap_merge.constprop.0+0xfa>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205002:	4d1c                	lw	a5,24(a0)
ffffffffc0205004:	4d98                	lw	a4,24(a1)
     else if (c == 0)
ffffffffc0205006:	40e786bb          	subw	a3,a5,a4
ffffffffc020500a:	0606cc63          	bltz	a3,ffffffffc0205082 <skew_heap_merge.constprop.0+0x9a>
          return a;
     }
     else
     {
          r = b->left;
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020500e:	0105b903          	ld	s2,16(a1)
          r = b->left;
ffffffffc0205012:	0085ba03          	ld	s4,8(a1)
     else if (b == NULL) return a;
ffffffffc0205016:	04090763          	beqz	s2,ffffffffc0205064 <skew_heap_merge.constprop.0+0x7c>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020501a:	01892703          	lw	a4,24(s2)
     else if (c == 0)
ffffffffc020501e:	40e786bb          	subw	a3,a5,a4
ffffffffc0205022:	0c06c263          	bltz	a3,ffffffffc02050e6 <skew_heap_merge.constprop.0+0xfe>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205026:	01093983          	ld	s3,16(s2)
          r = b->left;
ffffffffc020502a:	00893a83          	ld	s5,8(s2)
     else if (b == NULL) return a;
ffffffffc020502e:	10098c63          	beqz	s3,ffffffffc0205146 <skew_heap_merge.constprop.0+0x15e>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205032:	0189a703          	lw	a4,24(s3)
     else if (c == 0)
ffffffffc0205036:	9f99                	subw	a5,a5,a4
ffffffffc0205038:	1407c863          	bltz	a5,ffffffffc0205188 <skew_heap_merge.constprop.0+0x1a0>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020503c:	0109b583          	ld	a1,16(s3)
          r = b->left;
ffffffffc0205040:	0089b483          	ld	s1,8(s3)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205044:	fa5ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          
          b->left = l;
ffffffffc0205048:	00a9b423          	sd	a0,8(s3)
          b->right = r;
ffffffffc020504c:	0099b823          	sd	s1,16(s3)
          if (l) l->parent = b;
ffffffffc0205050:	c119                	beqz	a0,ffffffffc0205056 <skew_heap_merge.constprop.0+0x6e>
ffffffffc0205052:	01353023          	sd	s3,0(a0)
          b->left = l;
ffffffffc0205056:	01393423          	sd	s3,8(s2)
          b->right = r;
ffffffffc020505a:	01593823          	sd	s5,16(s2)
          if (l) l->parent = b;
ffffffffc020505e:	0129b023          	sd	s2,0(s3)
ffffffffc0205062:	84ca                	mv	s1,s2
          b->left = l;
ffffffffc0205064:	e404                	sd	s1,8(s0)
          b->right = r;
ffffffffc0205066:	01443823          	sd	s4,16(s0)
          if (l) l->parent = b;
ffffffffc020506a:	e080                	sd	s0,0(s1)
ffffffffc020506c:	8522                	mv	a0,s0

          return b;
     }
}
ffffffffc020506e:	70e2                	ld	ra,56(sp)
ffffffffc0205070:	7442                	ld	s0,48(sp)
ffffffffc0205072:	74a2                	ld	s1,40(sp)
ffffffffc0205074:	7902                	ld	s2,32(sp)
ffffffffc0205076:	69e2                	ld	s3,24(sp)
ffffffffc0205078:	6a42                	ld	s4,16(sp)
ffffffffc020507a:	6aa2                	ld	s5,8(sp)
ffffffffc020507c:	6b02                	ld	s6,0(sp)
ffffffffc020507e:	6121                	addi	sp,sp,64
ffffffffc0205080:	8082                	ret
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205082:	01053903          	ld	s2,16(a0)
          r = a->left;
ffffffffc0205086:	00853a03          	ld	s4,8(a0)
     if (a == NULL) return b;
ffffffffc020508a:	04090863          	beqz	s2,ffffffffc02050da <skew_heap_merge.constprop.0+0xf2>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020508e:	01892783          	lw	a5,24(s2)
     else if (c == 0)
ffffffffc0205092:	40e7873b          	subw	a4,a5,a4
ffffffffc0205096:	08074963          	bltz	a4,ffffffffc0205128 <skew_heap_merge.constprop.0+0x140>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc020509a:	0105b983          	ld	s3,16(a1)
          r = b->left;
ffffffffc020509e:	0085ba83          	ld	s5,8(a1)
     else if (b == NULL) return a;
ffffffffc02050a2:	02098663          	beqz	s3,ffffffffc02050ce <skew_heap_merge.constprop.0+0xe6>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02050a6:	0189a703          	lw	a4,24(s3)
     else if (c == 0)
ffffffffc02050aa:	9f99                	subw	a5,a5,a4
ffffffffc02050ac:	0a07cf63          	bltz	a5,ffffffffc020516a <skew_heap_merge.constprop.0+0x182>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02050b0:	0109b583          	ld	a1,16(s3)
          r = b->left;
ffffffffc02050b4:	0089bb03          	ld	s6,8(s3)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02050b8:	854a                	mv	a0,s2
ffffffffc02050ba:	f2fff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc02050be:	00a9b423          	sd	a0,8(s3)
          b->right = r;
ffffffffc02050c2:	0169b823          	sd	s6,16(s3)
          if (l) l->parent = b;
ffffffffc02050c6:	894e                	mv	s2,s3
ffffffffc02050c8:	c119                	beqz	a0,ffffffffc02050ce <skew_heap_merge.constprop.0+0xe6>
ffffffffc02050ca:	01253023          	sd	s2,0(a0)
          b->left = l;
ffffffffc02050ce:	01243423          	sd	s2,8(s0)
          b->right = r;
ffffffffc02050d2:	01543823          	sd	s5,16(s0)
          if (l) l->parent = b;
ffffffffc02050d6:	00893023          	sd	s0,0(s2)
          a->left = l;
ffffffffc02050da:	e480                	sd	s0,8(s1)
          a->right = r;
ffffffffc02050dc:	0144b823          	sd	s4,16(s1)
          if (l) l->parent = a;
ffffffffc02050e0:	e004                	sd	s1,0(s0)
ffffffffc02050e2:	8526                	mv	a0,s1
ffffffffc02050e4:	b769                	j	ffffffffc020506e <skew_heap_merge.constprop.0+0x86>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02050e6:	01053983          	ld	s3,16(a0)
          r = a->left;
ffffffffc02050ea:	00853a83          	ld	s5,8(a0)
     if (a == NULL) return b;
ffffffffc02050ee:	02098663          	beqz	s3,ffffffffc020511a <skew_heap_merge.constprop.0+0x132>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02050f2:	0189a783          	lw	a5,24(s3)
     else if (c == 0)
ffffffffc02050f6:	40e7873b          	subw	a4,a5,a4
ffffffffc02050fa:	04074863          	bltz	a4,ffffffffc020514a <skew_heap_merge.constprop.0+0x162>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02050fe:	01093583          	ld	a1,16(s2)
          r = b->left;
ffffffffc0205102:	00893b03          	ld	s6,8(s2)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205106:	854e                	mv	a0,s3
ffffffffc0205108:	ee1ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc020510c:	00a93423          	sd	a0,8(s2)
          b->right = r;
ffffffffc0205110:	01693823          	sd	s6,16(s2)
          if (l) l->parent = b;
ffffffffc0205114:	c119                	beqz	a0,ffffffffc020511a <skew_heap_merge.constprop.0+0x132>
ffffffffc0205116:	01253023          	sd	s2,0(a0)
          a->left = l;
ffffffffc020511a:	0124b423          	sd	s2,8(s1)
          a->right = r;
ffffffffc020511e:	0154b823          	sd	s5,16(s1)
          if (l) l->parent = a;
ffffffffc0205122:	00993023          	sd	s1,0(s2)
ffffffffc0205126:	bf3d                	j	ffffffffc0205064 <skew_heap_merge.constprop.0+0x7c>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205128:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc020512c:	00893983          	ld	s3,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205130:	844a                	mv	s0,s2
ffffffffc0205132:	eb7ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205136:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc020513a:	01393823          	sd	s3,16(s2)
          if (l) l->parent = a;
ffffffffc020513e:	dd51                	beqz	a0,ffffffffc02050da <skew_heap_merge.constprop.0+0xf2>
ffffffffc0205140:	01253023          	sd	s2,0(a0)
ffffffffc0205144:	bf59                	j	ffffffffc02050da <skew_heap_merge.constprop.0+0xf2>
          if (l) l->parent = b;
ffffffffc0205146:	89a6                	mv	s3,s1
ffffffffc0205148:	b739                	j	ffffffffc0205056 <skew_heap_merge.constprop.0+0x6e>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020514a:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc020514e:	0089bb03          	ld	s6,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205152:	85ca                	mv	a1,s2
ffffffffc0205154:	e95ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205158:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc020515c:	0169b823          	sd	s6,16(s3)
          if (l) l->parent = a;
ffffffffc0205160:	894e                	mv	s2,s3
ffffffffc0205162:	dd45                	beqz	a0,ffffffffc020511a <skew_heap_merge.constprop.0+0x132>
          if (l) l->parent = b;
ffffffffc0205164:	01253023          	sd	s2,0(a0)
ffffffffc0205168:	bf4d                	j	ffffffffc020511a <skew_heap_merge.constprop.0+0x132>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020516a:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc020516e:	00893b03          	ld	s6,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205172:	85ce                	mv	a1,s3
ffffffffc0205174:	e75ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205178:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc020517c:	01693823          	sd	s6,16(s2)
          if (l) l->parent = a;
ffffffffc0205180:	d539                	beqz	a0,ffffffffc02050ce <skew_heap_merge.constprop.0+0xe6>
          if (l) l->parent = b;
ffffffffc0205182:	01253023          	sd	s2,0(a0)
ffffffffc0205186:	b7a1                	j	ffffffffc02050ce <skew_heap_merge.constprop.0+0xe6>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205188:	6908                	ld	a0,16(a0)
          r = a->left;
ffffffffc020518a:	0084bb03          	ld	s6,8(s1)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020518e:	85ce                	mv	a1,s3
ffffffffc0205190:	e59ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205194:	e488                	sd	a0,8(s1)
          a->right = r;
ffffffffc0205196:	0164b823          	sd	s6,16(s1)
          if (l) l->parent = a;
ffffffffc020519a:	d555                	beqz	a0,ffffffffc0205146 <skew_heap_merge.constprop.0+0x15e>
ffffffffc020519c:	e104                	sd	s1,0(a0)
ffffffffc020519e:	89a6                	mv	s3,s1
ffffffffc02051a0:	bd5d                	j	ffffffffc0205056 <skew_heap_merge.constprop.0+0x6e>

ffffffffc02051a2 <stride_enqueue>:
{
ffffffffc02051a2:	7139                	addi	sp,sp,-64
ffffffffc02051a4:	f04a                	sd	s2,32(sp)
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02051a6:	01853903          	ld	s2,24(a0)
{
ffffffffc02051aa:	f822                	sd	s0,48(sp)
ffffffffc02051ac:	f426                	sd	s1,40(sp)
ffffffffc02051ae:	fc06                	sd	ra,56(sp)
ffffffffc02051b0:	ec4e                	sd	s3,24(sp)
ffffffffc02051b2:	e852                	sd	s4,16(sp)
ffffffffc02051b4:	e456                	sd	s5,8(sp)
     a->left = a->right = a->parent = NULL;
ffffffffc02051b6:	1205b423          	sd	zero,296(a1)
ffffffffc02051ba:	1205bc23          	sd	zero,312(a1)
ffffffffc02051be:	1205b823          	sd	zero,304(a1)
ffffffffc02051c2:	842e                	mv	s0,a1
ffffffffc02051c4:	84aa                	mv	s1,a0
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02051c6:	12858593          	addi	a1,a1,296
     if (a == NULL) return b;
ffffffffc02051ca:	00090d63          	beqz	s2,ffffffffc02051e4 <stride_enqueue+0x42>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02051ce:	14042703          	lw	a4,320(s0)
ffffffffc02051d2:	01892783          	lw	a5,24(s2)
     else if (c == 0)
ffffffffc02051d6:	9f99                	subw	a5,a5,a4
ffffffffc02051d8:	0207cd63          	bltz	a5,ffffffffc0205212 <stride_enqueue+0x70>
          b->left = l;
ffffffffc02051dc:	13243823          	sd	s2,304(s0)
          if (l) l->parent = b;
ffffffffc02051e0:	00b93023          	sd	a1,0(s2)
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice)
ffffffffc02051e4:	12042783          	lw	a5,288(s0)
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc02051e8:	ec8c                	sd	a1,24(s1)
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice)
ffffffffc02051ea:	48d8                	lw	a4,20(s1)
ffffffffc02051ec:	c399                	beqz	a5,ffffffffc02051f2 <stride_enqueue+0x50>
ffffffffc02051ee:	00f75463          	bge	a4,a5,ffffffffc02051f6 <stride_enqueue+0x54>
        proc->time_slice = rq->max_time_slice;
ffffffffc02051f2:	12e42023          	sw	a4,288(s0)
    rq->proc_num++;
ffffffffc02051f6:	489c                	lw	a5,16(s1)
}
ffffffffc02051f8:	70e2                	ld	ra,56(sp)
    proc->rq = rq;
ffffffffc02051fa:	10943423          	sd	s1,264(s0)
}
ffffffffc02051fe:	7442                	ld	s0,48(sp)
    rq->proc_num++;
ffffffffc0205200:	2785                	addiw	a5,a5,1
ffffffffc0205202:	c89c                	sw	a5,16(s1)
}
ffffffffc0205204:	7902                	ld	s2,32(sp)
ffffffffc0205206:	74a2                	ld	s1,40(sp)
ffffffffc0205208:	69e2                	ld	s3,24(sp)
ffffffffc020520a:	6a42                	ld	s4,16(sp)
ffffffffc020520c:	6aa2                	ld	s5,8(sp)
ffffffffc020520e:	6121                	addi	sp,sp,64
ffffffffc0205210:	8082                	ret
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205212:	01093983          	ld	s3,16(s2)
          r = a->left;
ffffffffc0205216:	00893a03          	ld	s4,8(s2)
     if (a == NULL) return b;
ffffffffc020521a:	00098c63          	beqz	s3,ffffffffc0205232 <stride_enqueue+0x90>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020521e:	0189a783          	lw	a5,24(s3)
     else if (c == 0)
ffffffffc0205222:	40e7873b          	subw	a4,a5,a4
ffffffffc0205226:	00074e63          	bltz	a4,ffffffffc0205242 <stride_enqueue+0xa0>
          b->left = l;
ffffffffc020522a:	13343823          	sd	s3,304(s0)
          if (l) l->parent = b;
ffffffffc020522e:	00b9b023          	sd	a1,0(s3)
          a->left = l;
ffffffffc0205232:	00b93423          	sd	a1,8(s2)
          a->right = r;
ffffffffc0205236:	01493823          	sd	s4,16(s2)
          if (l) l->parent = a;
ffffffffc020523a:	0125b023          	sd	s2,0(a1)
ffffffffc020523e:	85ca                	mv	a1,s2
ffffffffc0205240:	b755                	j	ffffffffc02051e4 <stride_enqueue+0x42>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205242:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc0205246:	0089ba83          	ld	s5,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020524a:	d9fff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc020524e:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc0205252:	0159b823          	sd	s5,16(s3)
          if (l) l->parent = a;
ffffffffc0205256:	85ce                	mv	a1,s3
ffffffffc0205258:	dd69                	beqz	a0,ffffffffc0205232 <stride_enqueue+0x90>
ffffffffc020525a:	01353023          	sd	s3,0(a0)
ffffffffc020525e:	bfd1                	j	ffffffffc0205232 <stride_enqueue+0x90>

ffffffffc0205260 <stride_dequeue>:
      assert(proc->rq == rq && rq->proc_num > 0);
ffffffffc0205260:	1085b783          	ld	a5,264(a1)
{
ffffffffc0205264:	711d                	addi	sp,sp,-96
ffffffffc0205266:	ec86                	sd	ra,88(sp)
ffffffffc0205268:	e8a2                	sd	s0,80(sp)
ffffffffc020526a:	e4a6                	sd	s1,72(sp)
ffffffffc020526c:	e0ca                	sd	s2,64(sp)
ffffffffc020526e:	fc4e                	sd	s3,56(sp)
ffffffffc0205270:	f852                	sd	s4,48(sp)
ffffffffc0205272:	f456                	sd	s5,40(sp)
ffffffffc0205274:	f05a                	sd	s6,32(sp)
ffffffffc0205276:	ec5e                	sd	s7,24(sp)
ffffffffc0205278:	e862                	sd	s8,16(sp)
ffffffffc020527a:	e466                	sd	s9,8(sp)
ffffffffc020527c:	e06a                	sd	s10,0(sp)
      assert(proc->rq == rq && rq->proc_num > 0);
ffffffffc020527e:	22a79c63          	bne	a5,a0,ffffffffc02054b6 <stride_dequeue+0x256>
ffffffffc0205282:	491c                	lw	a5,16(a0)
ffffffffc0205284:	8b2a                	mv	s6,a0
ffffffffc0205286:	22078863          	beqz	a5,ffffffffc02054b6 <stride_dequeue+0x256>
static inline skew_heap_entry_t *
skew_heap_remove(skew_heap_entry_t *a, skew_heap_entry_t *b,
                 compare_f comp)
{
     skew_heap_entry_t *p   = b->parent;
     skew_heap_entry_t *rep = skew_heap_merge(b->left, b->right, comp);
ffffffffc020528a:	1305b903          	ld	s2,304(a1)
    rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc020528e:	01853a83          	ld	s5,24(a0)
     skew_heap_entry_t *p   = b->parent;
ffffffffc0205292:	1285ba03          	ld	s4,296(a1)
     skew_heap_entry_t *rep = skew_heap_merge(b->left, b->right, comp);
ffffffffc0205296:	1385b483          	ld	s1,312(a1)
ffffffffc020529a:	842e                	mv	s0,a1
     if (a == NULL) return b;
ffffffffc020529c:	12090763          	beqz	s2,ffffffffc02053ca <stride_dequeue+0x16a>
     else if (b == NULL) return a;
ffffffffc02052a0:	12048d63          	beqz	s1,ffffffffc02053da <stride_dequeue+0x17a>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02052a4:	01892703          	lw	a4,24(s2)
ffffffffc02052a8:	4c94                	lw	a3,24(s1)
     else if (c == 0)
ffffffffc02052aa:	40d7063b          	subw	a2,a4,a3
ffffffffc02052ae:	0a064663          	bltz	a2,ffffffffc020535a <stride_dequeue+0xfa>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02052b2:	0104b983          	ld	s3,16(s1)
          r = b->left;
ffffffffc02052b6:	0084bc03          	ld	s8,8(s1)
     else if (b == NULL) return a;
ffffffffc02052ba:	04098b63          	beqz	s3,ffffffffc0205310 <stride_dequeue+0xb0>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02052be:	0189a683          	lw	a3,24(s3)
     else if (c == 0)
ffffffffc02052c2:	40d7063b          	subw	a2,a4,a3
ffffffffc02052c6:	10064e63          	bltz	a2,ffffffffc02053e2 <stride_dequeue+0x182>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02052ca:	0109bb83          	ld	s7,16(s3)
          r = b->left;
ffffffffc02052ce:	0089bc83          	ld	s9,8(s3)
     else if (b == NULL) return a;
ffffffffc02052d2:	020b8863          	beqz	s7,ffffffffc0205302 <stride_dequeue+0xa2>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02052d6:	018ba783          	lw	a5,24(s7)
     else if (c == 0)
ffffffffc02052da:	9f1d                	subw	a4,a4,a5
ffffffffc02052dc:	1a074b63          	bltz	a4,ffffffffc0205492 <stride_dequeue+0x232>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02052e0:	010bb583          	ld	a1,16(s7)
          r = b->left;
ffffffffc02052e4:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02052e8:	854a                	mv	a0,s2
ffffffffc02052ea:	cffff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc02052ee:	00abb423          	sd	a0,8(s7)
          b->right = r;
ffffffffc02052f2:	01abb823          	sd	s10,16(s7)
    rq->proc_num--;
ffffffffc02052f6:	010b2783          	lw	a5,16(s6)
          if (l) l->parent = b;
ffffffffc02052fa:	c119                	beqz	a0,ffffffffc0205300 <stride_dequeue+0xa0>
ffffffffc02052fc:	01753023          	sd	s7,0(a0)
ffffffffc0205300:	895e                	mv	s2,s7
          b->left = l;
ffffffffc0205302:	0129b423          	sd	s2,8(s3)
          b->right = r;
ffffffffc0205306:	0199b823          	sd	s9,16(s3)
          if (l) l->parent = b;
ffffffffc020530a:	01393023          	sd	s3,0(s2)
ffffffffc020530e:	894e                	mv	s2,s3
          b->left = l;
ffffffffc0205310:	0124b423          	sd	s2,8(s1)
          b->right = r;
ffffffffc0205314:	0184b823          	sd	s8,16(s1)
          if (l) l->parent = b;
ffffffffc0205318:	00993023          	sd	s1,0(s2)
     if (rep) rep->parent = p;
ffffffffc020531c:	0144b023          	sd	s4,0(s1)
     
     if (p)
ffffffffc0205320:	0a0a0863          	beqz	s4,ffffffffc02053d0 <stride_dequeue+0x170>
     {
          if (p->left == b)
ffffffffc0205324:	008a3703          	ld	a4,8(s4)
    rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc0205328:	12840413          	addi	s0,s0,296
ffffffffc020532c:	0a870463          	beq	a4,s0,ffffffffc02053d4 <stride_dequeue+0x174>
               p->left = rep;
          else p->right = rep;
ffffffffc0205330:	009a3823          	sd	s1,16(s4)
}
ffffffffc0205334:	60e6                	ld	ra,88(sp)
ffffffffc0205336:	6446                	ld	s0,80(sp)
    rq->proc_num--;
ffffffffc0205338:	37fd                	addiw	a5,a5,-1
    rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
ffffffffc020533a:	015b3c23          	sd	s5,24(s6)
    rq->proc_num--;
ffffffffc020533e:	00fb2823          	sw	a5,16(s6)
}
ffffffffc0205342:	64a6                	ld	s1,72(sp)
ffffffffc0205344:	6906                	ld	s2,64(sp)
ffffffffc0205346:	79e2                	ld	s3,56(sp)
ffffffffc0205348:	7a42                	ld	s4,48(sp)
ffffffffc020534a:	7aa2                	ld	s5,40(sp)
ffffffffc020534c:	7b02                	ld	s6,32(sp)
ffffffffc020534e:	6be2                	ld	s7,24(sp)
ffffffffc0205350:	6c42                	ld	s8,16(sp)
ffffffffc0205352:	6ca2                	ld	s9,8(sp)
ffffffffc0205354:	6d02                	ld	s10,0(sp)
ffffffffc0205356:	6125                	addi	sp,sp,96
ffffffffc0205358:	8082                	ret
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020535a:	01093983          	ld	s3,16(s2)
          r = a->left;
ffffffffc020535e:	00893c03          	ld	s8,8(s2)
     if (a == NULL) return b;
ffffffffc0205362:	04098a63          	beqz	s3,ffffffffc02053b6 <stride_dequeue+0x156>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc0205366:	0189a703          	lw	a4,24(s3)
     else if (c == 0)
ffffffffc020536a:	40d706bb          	subw	a3,a4,a3
ffffffffc020536e:	0a06cd63          	bltz	a3,ffffffffc0205428 <stride_dequeue+0x1c8>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205372:	0104bb83          	ld	s7,16(s1)
          r = b->left;
ffffffffc0205376:	0084bc83          	ld	s9,8(s1)
     else if (b == NULL) return a;
ffffffffc020537a:	020b8863          	beqz	s7,ffffffffc02053aa <stride_dequeue+0x14a>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc020537e:	018ba783          	lw	a5,24(s7)
     else if (c == 0)
ffffffffc0205382:	9f1d                	subw	a4,a4,a5
ffffffffc0205384:	0e074663          	bltz	a4,ffffffffc0205470 <stride_dequeue+0x210>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205388:	010bb583          	ld	a1,16(s7)
          r = b->left;
ffffffffc020538c:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205390:	854e                	mv	a0,s3
ffffffffc0205392:	c57ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc0205396:	00abb423          	sd	a0,8(s7)
          b->right = r;
ffffffffc020539a:	01abb823          	sd	s10,16(s7)
    rq->proc_num--;
ffffffffc020539e:	010b2783          	lw	a5,16(s6)
          if (l) l->parent = b;
ffffffffc02053a2:	c119                	beqz	a0,ffffffffc02053a8 <stride_dequeue+0x148>
ffffffffc02053a4:	01753023          	sd	s7,0(a0)
ffffffffc02053a8:	89de                	mv	s3,s7
          b->left = l;
ffffffffc02053aa:	0134b423          	sd	s3,8(s1)
          b->right = r;
ffffffffc02053ae:	0194b823          	sd	s9,16(s1)
          if (l) l->parent = b;
ffffffffc02053b2:	0099b023          	sd	s1,0(s3)
          a->left = l;
ffffffffc02053b6:	00993423          	sd	s1,8(s2)
          a->right = r;
ffffffffc02053ba:	01893823          	sd	s8,16(s2)
          if (l) l->parent = a;
ffffffffc02053be:	0124b023          	sd	s2,0(s1)
ffffffffc02053c2:	84ca                	mv	s1,s2
     if (rep) rep->parent = p;
ffffffffc02053c4:	0144b023          	sd	s4,0(s1)
ffffffffc02053c8:	bfa1                	j	ffffffffc0205320 <stride_dequeue+0xc0>
ffffffffc02053ca:	f8a9                	bnez	s1,ffffffffc020531c <stride_dequeue+0xbc>
     if (p)
ffffffffc02053cc:	f40a1ce3          	bnez	s4,ffffffffc0205324 <stride_dequeue+0xc4>
ffffffffc02053d0:	8aa6                	mv	s5,s1
ffffffffc02053d2:	b78d                	j	ffffffffc0205334 <stride_dequeue+0xd4>
               p->left = rep;
ffffffffc02053d4:	009a3423          	sd	s1,8(s4)
ffffffffc02053d8:	bfb1                	j	ffffffffc0205334 <stride_dequeue+0xd4>
ffffffffc02053da:	84ca                	mv	s1,s2
     if (rep) rep->parent = p;
ffffffffc02053dc:	0144b023          	sd	s4,0(s1)
ffffffffc02053e0:	b781                	j	ffffffffc0205320 <stride_dequeue+0xc0>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc02053e2:	01093b83          	ld	s7,16(s2)
          r = a->left;
ffffffffc02053e6:	00893c83          	ld	s9,8(s2)
     if (a == NULL) return b;
ffffffffc02053ea:	020b8863          	beqz	s7,ffffffffc020541a <stride_dequeue+0x1ba>
     int32_t c = p->lab6_stride - q->lab6_stride;
ffffffffc02053ee:	018ba783          	lw	a5,24(s7)
     else if (c == 0)
ffffffffc02053f2:	40d786bb          	subw	a3,a5,a3
ffffffffc02053f6:	0406cb63          	bltz	a3,ffffffffc020544c <stride_dequeue+0x1ec>
          l = skew_heap_merge(a, b->right, comp);
ffffffffc02053fa:	0109b583          	ld	a1,16(s3)
          r = b->left;
ffffffffc02053fe:	0089bd03          	ld	s10,8(s3)
          l = skew_heap_merge(a, b->right, comp);
ffffffffc0205402:	855e                	mv	a0,s7
ffffffffc0205404:	be5ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          b->left = l;
ffffffffc0205408:	00a9b423          	sd	a0,8(s3)
          b->right = r;
ffffffffc020540c:	01a9b823          	sd	s10,16(s3)
    rq->proc_num--;
ffffffffc0205410:	010b2783          	lw	a5,16(s6)
          if (l) l->parent = b;
ffffffffc0205414:	c119                	beqz	a0,ffffffffc020541a <stride_dequeue+0x1ba>
ffffffffc0205416:	01353023          	sd	s3,0(a0)
          a->left = l;
ffffffffc020541a:	01393423          	sd	s3,8(s2)
          a->right = r;
ffffffffc020541e:	01993823          	sd	s9,16(s2)
          if (l) l->parent = a;
ffffffffc0205422:	0129b023          	sd	s2,0(s3)
ffffffffc0205426:	b5ed                	j	ffffffffc0205310 <stride_dequeue+0xb0>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205428:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc020542c:	0089bb83          	ld	s7,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205430:	85a6                	mv	a1,s1
ffffffffc0205432:	bb7ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc0205436:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc020543a:	0179b823          	sd	s7,16(s3)
ffffffffc020543e:	010b2783          	lw	a5,16(s6)
          if (l) l->parent = a;
ffffffffc0205442:	c119                	beqz	a0,ffffffffc0205448 <stride_dequeue+0x1e8>
ffffffffc0205444:	01353023          	sd	s3,0(a0)
ffffffffc0205448:	84ce                	mv	s1,s3
ffffffffc020544a:	b7b5                	j	ffffffffc02053b6 <stride_dequeue+0x156>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020544c:	010bb503          	ld	a0,16(s7)
          r = a->left;
ffffffffc0205450:	008bbd03          	ld	s10,8(s7)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205454:	85ce                	mv	a1,s3
ffffffffc0205456:	b93ff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc020545a:	00abb423          	sd	a0,8(s7)
          a->right = r;
ffffffffc020545e:	01abb823          	sd	s10,16(s7)
ffffffffc0205462:	010b2783          	lw	a5,16(s6)
          if (l) l->parent = a;
ffffffffc0205466:	c119                	beqz	a0,ffffffffc020546c <stride_dequeue+0x20c>
ffffffffc0205468:	01753023          	sd	s7,0(a0)
ffffffffc020546c:	89de                	mv	s3,s7
ffffffffc020546e:	b775                	j	ffffffffc020541a <stride_dequeue+0x1ba>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205470:	0109b503          	ld	a0,16(s3)
          r = a->left;
ffffffffc0205474:	0089bd03          	ld	s10,8(s3)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205478:	85de                	mv	a1,s7
ffffffffc020547a:	b6fff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc020547e:	00a9b423          	sd	a0,8(s3)
          a->right = r;
ffffffffc0205482:	01a9b823          	sd	s10,16(s3)
ffffffffc0205486:	010b2783          	lw	a5,16(s6)
          if (l) l->parent = a;
ffffffffc020548a:	d105                	beqz	a0,ffffffffc02053aa <stride_dequeue+0x14a>
ffffffffc020548c:	01353023          	sd	s3,0(a0)
ffffffffc0205490:	bf29                	j	ffffffffc02053aa <stride_dequeue+0x14a>
          l = skew_heap_merge(a->right, b, comp);
ffffffffc0205492:	01093503          	ld	a0,16(s2)
          r = a->left;
ffffffffc0205496:	00893d03          	ld	s10,8(s2)
          l = skew_heap_merge(a->right, b, comp);
ffffffffc020549a:	85de                	mv	a1,s7
ffffffffc020549c:	b4dff0ef          	jal	ra,ffffffffc0204fe8 <skew_heap_merge.constprop.0>
          a->left = l;
ffffffffc02054a0:	00a93423          	sd	a0,8(s2)
          a->right = r;
ffffffffc02054a4:	01a93823          	sd	s10,16(s2)
ffffffffc02054a8:	010b2783          	lw	a5,16(s6)
          if (l) l->parent = a;
ffffffffc02054ac:	e4050be3          	beqz	a0,ffffffffc0205302 <stride_dequeue+0xa2>
ffffffffc02054b0:	01253023          	sd	s2,0(a0)
ffffffffc02054b4:	b5b9                	j	ffffffffc0205302 <stride_dequeue+0xa2>
      assert(proc->rq == rq && rq->proc_num > 0);
ffffffffc02054b6:	00002697          	auipc	a3,0x2
ffffffffc02054ba:	49268693          	addi	a3,a3,1170 # ffffffffc0207948 <default_pmm_manager+0xe80>
ffffffffc02054be:	00001617          	auipc	a2,0x1
ffffffffc02054c2:	25a60613          	addi	a2,a2,602 # ffffffffc0206718 <commands+0x818>
ffffffffc02054c6:	06b00593          	li	a1,107
ffffffffc02054ca:	00002517          	auipc	a0,0x2
ffffffffc02054ce:	4a650513          	addi	a0,a0,1190 # ffffffffc0207970 <default_pmm_manager+0xea8>
ffffffffc02054d2:	fc1fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02054d6 <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc02054d6:	000cc797          	auipc	a5,0xcc
ffffffffc02054da:	09a7b783          	ld	a5,154(a5) # ffffffffc02d1570 <idleproc>
{
ffffffffc02054de:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc02054e0:	00a78c63          	beq	a5,a0,ffffffffc02054f8 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc02054e4:	000cc797          	auipc	a5,0xcc
ffffffffc02054e8:	0ac7b783          	ld	a5,172(a5) # ffffffffc02d1590 <sched_class>
ffffffffc02054ec:	779c                	ld	a5,40(a5)
ffffffffc02054ee:	000cc517          	auipc	a0,0xcc
ffffffffc02054f2:	09a53503          	ld	a0,154(a0) # ffffffffc02d1588 <rq>
ffffffffc02054f6:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc02054f8:	4705                	li	a4,1
ffffffffc02054fa:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc02054fc:	8082                	ret

ffffffffc02054fe <sched_init>:

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc02054fe:	1141                	addi	sp,sp,-16
    list_init(&timer_list);

    extern struct sched_class stride_sched_class;
    extern struct sched_class fifo_sched_class;
    extern struct sched_class sjf_sched_class;
    sched_class = &stride_sched_class;
ffffffffc0205500:	000c8717          	auipc	a4,0xc8
ffffffffc0205504:	b7870713          	addi	a4,a4,-1160 # ffffffffc02cd078 <stride_sched_class>
{
ffffffffc0205508:	e022                	sd	s0,0(sp)
ffffffffc020550a:	e406                	sd	ra,8(sp)
ffffffffc020550c:	000cc797          	auipc	a5,0xcc
ffffffffc0205510:	ff478793          	addi	a5,a5,-12 # ffffffffc02d1500 <timer_list>
    //sched_class = &fifo_sched_class;
    //sched_class = &sjf_sched_class;

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc0205514:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc0205516:	000cc517          	auipc	a0,0xcc
ffffffffc020551a:	fca50513          	addi	a0,a0,-54 # ffffffffc02d14e0 <__rq>
ffffffffc020551e:	e79c                	sd	a5,8(a5)
ffffffffc0205520:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205522:	4795                	li	a5,5
ffffffffc0205524:	c95c                	sw	a5,20(a0)
    sched_class = &stride_sched_class;
ffffffffc0205526:	000cc417          	auipc	s0,0xcc
ffffffffc020552a:	06a40413          	addi	s0,s0,106 # ffffffffc02d1590 <sched_class>
    rq = &__rq;
ffffffffc020552e:	000cc797          	auipc	a5,0xcc
ffffffffc0205532:	04a7bd23          	sd	a0,90(a5) # ffffffffc02d1588 <rq>
    sched_class = &stride_sched_class;
ffffffffc0205536:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc0205538:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020553a:	601c                	ld	a5,0(s0)
}
ffffffffc020553c:	6402                	ld	s0,0(sp)
ffffffffc020553e:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205540:	638c                	ld	a1,0(a5)
ffffffffc0205542:	00002517          	auipc	a0,0x2
ffffffffc0205546:	46650513          	addi	a0,a0,1126 # ffffffffc02079a8 <default_pmm_manager+0xee0>
}
ffffffffc020554a:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020554c:	c4dfa06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0205550 <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205550:	4118                	lw	a4,0(a0)
{
ffffffffc0205552:	1101                	addi	sp,sp,-32
ffffffffc0205554:	ec06                	sd	ra,24(sp)
ffffffffc0205556:	e822                	sd	s0,16(sp)
ffffffffc0205558:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020555a:	478d                	li	a5,3
ffffffffc020555c:	08f70363          	beq	a4,a5,ffffffffc02055e2 <wakeup_proc+0x92>
ffffffffc0205560:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205562:	100027f3          	csrr	a5,sstatus
ffffffffc0205566:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205568:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020556a:	e7bd                	bnez	a5,ffffffffc02055d8 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020556c:	4789                	li	a5,2
ffffffffc020556e:	04f70863          	beq	a4,a5,ffffffffc02055be <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205572:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205574:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc0205578:	000cc797          	auipc	a5,0xcc
ffffffffc020557c:	ff07b783          	ld	a5,-16(a5) # ffffffffc02d1568 <current>
ffffffffc0205580:	02878363          	beq	a5,s0,ffffffffc02055a6 <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc0205584:	000cc797          	auipc	a5,0xcc
ffffffffc0205588:	fec7b783          	ld	a5,-20(a5) # ffffffffc02d1570 <idleproc>
ffffffffc020558c:	00f40d63          	beq	s0,a5,ffffffffc02055a6 <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc0205590:	000cc797          	auipc	a5,0xcc
ffffffffc0205594:	0007b783          	ld	a5,0(a5) # ffffffffc02d1590 <sched_class>
ffffffffc0205598:	6b9c                	ld	a5,16(a5)
ffffffffc020559a:	85a2                	mv	a1,s0
ffffffffc020559c:	000cc517          	auipc	a0,0xcc
ffffffffc02055a0:	fec53503          	ld	a0,-20(a0) # ffffffffc02d1588 <rq>
ffffffffc02055a4:	9782                	jalr	a5
    if (flag)
ffffffffc02055a6:	e491                	bnez	s1,ffffffffc02055b2 <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02055a8:	60e2                	ld	ra,24(sp)
ffffffffc02055aa:	6442                	ld	s0,16(sp)
ffffffffc02055ac:	64a2                	ld	s1,8(sp)
ffffffffc02055ae:	6105                	addi	sp,sp,32
ffffffffc02055b0:	8082                	ret
ffffffffc02055b2:	6442                	ld	s0,16(sp)
ffffffffc02055b4:	60e2                	ld	ra,24(sp)
ffffffffc02055b6:	64a2                	ld	s1,8(sp)
ffffffffc02055b8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02055ba:	beefb06f          	j	ffffffffc02009a8 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02055be:	00002617          	auipc	a2,0x2
ffffffffc02055c2:	43a60613          	addi	a2,a2,1082 # ffffffffc02079f8 <default_pmm_manager+0xf30>
ffffffffc02055c6:	05700593          	li	a1,87
ffffffffc02055ca:	00002517          	auipc	a0,0x2
ffffffffc02055ce:	41650513          	addi	a0,a0,1046 # ffffffffc02079e0 <default_pmm_manager+0xf18>
ffffffffc02055d2:	f29fa0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc02055d6:	bfc1                	j	ffffffffc02055a6 <wakeup_proc+0x56>
        intr_disable();
ffffffffc02055d8:	bd6fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02055dc:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc02055de:	4485                	li	s1,1
ffffffffc02055e0:	b771                	j	ffffffffc020556c <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02055e2:	00002697          	auipc	a3,0x2
ffffffffc02055e6:	3de68693          	addi	a3,a3,990 # ffffffffc02079c0 <default_pmm_manager+0xef8>
ffffffffc02055ea:	00001617          	auipc	a2,0x1
ffffffffc02055ee:	12e60613          	addi	a2,a2,302 # ffffffffc0206718 <commands+0x818>
ffffffffc02055f2:	04800593          	li	a1,72
ffffffffc02055f6:	00002517          	auipc	a0,0x2
ffffffffc02055fa:	3ea50513          	addi	a0,a0,1002 # ffffffffc02079e0 <default_pmm_manager+0xf18>
ffffffffc02055fe:	e95fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205602 <schedule>:

void schedule(void)
{
ffffffffc0205602:	7179                	addi	sp,sp,-48
ffffffffc0205604:	f406                	sd	ra,40(sp)
ffffffffc0205606:	f022                	sd	s0,32(sp)
ffffffffc0205608:	ec26                	sd	s1,24(sp)
ffffffffc020560a:	e84a                	sd	s2,16(sp)
ffffffffc020560c:	e44e                	sd	s3,8(sp)
ffffffffc020560e:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205610:	100027f3          	csrr	a5,sstatus
ffffffffc0205614:	8b89                	andi	a5,a5,2
ffffffffc0205616:	4a01                	li	s4,0
ffffffffc0205618:	e3cd                	bnez	a5,ffffffffc02056ba <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020561a:	000cc497          	auipc	s1,0xcc
ffffffffc020561e:	f4e48493          	addi	s1,s1,-178 # ffffffffc02d1568 <current>
ffffffffc0205622:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc0205624:	000cc997          	auipc	s3,0xcc
ffffffffc0205628:	f6c98993          	addi	s3,s3,-148 # ffffffffc02d1590 <sched_class>
ffffffffc020562c:	000cc917          	auipc	s2,0xcc
ffffffffc0205630:	f5c90913          	addi	s2,s2,-164 # ffffffffc02d1588 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc0205634:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc0205636:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc020563a:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc020563c:	0009b783          	ld	a5,0(s3)
ffffffffc0205640:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205644:	04e68e63          	beq	a3,a4,ffffffffc02056a0 <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc0205648:	739c                	ld	a5,32(a5)
ffffffffc020564a:	9782                	jalr	a5
ffffffffc020564c:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020564e:	c521                	beqz	a0,ffffffffc0205696 <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc0205650:	0009b783          	ld	a5,0(s3)
ffffffffc0205654:	00093503          	ld	a0,0(s2)
ffffffffc0205658:	85a2                	mv	a1,s0
ffffffffc020565a:	6f9c                	ld	a5,24(a5)
ffffffffc020565c:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020565e:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc0205660:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc0205662:	2785                	addiw	a5,a5,1
ffffffffc0205664:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc0205666:	00870563          	beq	a4,s0,ffffffffc0205670 <schedule+0x6e>
        {
            proc_run(next);
ffffffffc020566a:	8522                	mv	a0,s0
ffffffffc020566c:	f70fe0ef          	jal	ra,ffffffffc0203ddc <proc_run>
    if (flag)
ffffffffc0205670:	000a1a63          	bnez	s4,ffffffffc0205684 <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205674:	70a2                	ld	ra,40(sp)
ffffffffc0205676:	7402                	ld	s0,32(sp)
ffffffffc0205678:	64e2                	ld	s1,24(sp)
ffffffffc020567a:	6942                	ld	s2,16(sp)
ffffffffc020567c:	69a2                	ld	s3,8(sp)
ffffffffc020567e:	6a02                	ld	s4,0(sp)
ffffffffc0205680:	6145                	addi	sp,sp,48
ffffffffc0205682:	8082                	ret
ffffffffc0205684:	7402                	ld	s0,32(sp)
ffffffffc0205686:	70a2                	ld	ra,40(sp)
ffffffffc0205688:	64e2                	ld	s1,24(sp)
ffffffffc020568a:	6942                	ld	s2,16(sp)
ffffffffc020568c:	69a2                	ld	s3,8(sp)
ffffffffc020568e:	6a02                	ld	s4,0(sp)
ffffffffc0205690:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0205692:	b16fb06f          	j	ffffffffc02009a8 <intr_enable>
            next = idleproc;
ffffffffc0205696:	000cc417          	auipc	s0,0xcc
ffffffffc020569a:	eda43403          	ld	s0,-294(s0) # ffffffffc02d1570 <idleproc>
ffffffffc020569e:	b7c1                	j	ffffffffc020565e <schedule+0x5c>
    if (proc != idleproc)
ffffffffc02056a0:	000cc717          	auipc	a4,0xcc
ffffffffc02056a4:	ed073703          	ld	a4,-304(a4) # ffffffffc02d1570 <idleproc>
ffffffffc02056a8:	fae580e3          	beq	a1,a4,ffffffffc0205648 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc02056ac:	6b9c                	ld	a5,16(a5)
ffffffffc02056ae:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc02056b0:	0009b783          	ld	a5,0(s3)
ffffffffc02056b4:	00093503          	ld	a0,0(s2)
ffffffffc02056b8:	bf41                	j	ffffffffc0205648 <schedule+0x46>
        intr_disable();
ffffffffc02056ba:	af4fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02056be:	4a05                	li	s4,1
ffffffffc02056c0:	bfa9                	j	ffffffffc020561a <schedule+0x18>

ffffffffc02056c2 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02056c2:	000cc797          	auipc	a5,0xcc
ffffffffc02056c6:	ea67b783          	ld	a5,-346(a5) # ffffffffc02d1568 <current>
}
ffffffffc02056ca:	43c8                	lw	a0,4(a5)
ffffffffc02056cc:	8082                	ret

ffffffffc02056ce <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02056ce:	4501                	li	a0,0
ffffffffc02056d0:	8082                	ret

ffffffffc02056d2 <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc02056d2:	000cc797          	auipc	a5,0xcc
ffffffffc02056d6:	e467b783          	ld	a5,-442(a5) # ffffffffc02d1518 <ticks>
ffffffffc02056da:	0027951b          	slliw	a0,a5,0x2
ffffffffc02056de:	9d3d                	addw	a0,a0,a5
}
ffffffffc02056e0:	0015151b          	slliw	a0,a0,0x1
ffffffffc02056e4:	8082                	ret

ffffffffc02056e6 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc02056e6:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc02056e8:	1141                	addi	sp,sp,-16
ffffffffc02056ea:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc02056ec:	817ff0ef          	jal	ra,ffffffffc0204f02 <lab6_set_priority>
    return 0;
}
ffffffffc02056f0:	60a2                	ld	ra,8(sp)
ffffffffc02056f2:	4501                	li	a0,0
ffffffffc02056f4:	0141                	addi	sp,sp,16
ffffffffc02056f6:	8082                	ret

ffffffffc02056f8 <sys_putc>:
    cputchar(c);
ffffffffc02056f8:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02056fa:	1141                	addi	sp,sp,-16
ffffffffc02056fc:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02056fe:	ad1fa0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc0205702:	60a2                	ld	ra,8(sp)
ffffffffc0205704:	4501                	li	a0,0
ffffffffc0205706:	0141                	addi	sp,sp,16
ffffffffc0205708:	8082                	ret

ffffffffc020570a <sys_kill>:
    return do_kill(pid);
ffffffffc020570a:	4108                	lw	a0,0(a0)
ffffffffc020570c:	dc8ff06f          	j	ffffffffc0204cd4 <do_kill>

ffffffffc0205710 <sys_yield>:
    return do_yield();
ffffffffc0205710:	d76ff06f          	j	ffffffffc0204c86 <do_yield>

ffffffffc0205714 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205714:	6d14                	ld	a3,24(a0)
ffffffffc0205716:	6910                	ld	a2,16(a0)
ffffffffc0205718:	650c                	ld	a1,8(a0)
ffffffffc020571a:	6108                	ld	a0,0(a0)
ffffffffc020571c:	fc1fe06f          	j	ffffffffc02046dc <do_execve>

ffffffffc0205720 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205720:	650c                	ld	a1,8(a0)
ffffffffc0205722:	4108                	lw	a0,0(a0)
ffffffffc0205724:	d72ff06f          	j	ffffffffc0204c96 <do_wait>

ffffffffc0205728 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205728:	000cc797          	auipc	a5,0xcc
ffffffffc020572c:	e407b783          	ld	a5,-448(a5) # ffffffffc02d1568 <current>
ffffffffc0205730:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205732:	4501                	li	a0,0
ffffffffc0205734:	6a0c                	ld	a1,16(a2)
ffffffffc0205736:	f12fe06f          	j	ffffffffc0203e48 <do_fork>

ffffffffc020573a <sys_exit>:
    return do_exit(error_code);
ffffffffc020573a:	4108                	lw	a0,0(a0)
ffffffffc020573c:	b61fe06f          	j	ffffffffc020429c <do_exit>

ffffffffc0205740 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205740:	715d                	addi	sp,sp,-80
ffffffffc0205742:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205744:	000cc497          	auipc	s1,0xcc
ffffffffc0205748:	e2448493          	addi	s1,s1,-476 # ffffffffc02d1568 <current>
ffffffffc020574c:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020574e:	e0a2                	sd	s0,64(sp)
ffffffffc0205750:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205752:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205754:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205756:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc020575a:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020575e:	0327ee63          	bltu	a5,s2,ffffffffc020579a <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc0205762:	00391713          	slli	a4,s2,0x3
ffffffffc0205766:	00002797          	auipc	a5,0x2
ffffffffc020576a:	2fa78793          	addi	a5,a5,762 # ffffffffc0207a60 <syscalls>
ffffffffc020576e:	97ba                	add	a5,a5,a4
ffffffffc0205770:	639c                	ld	a5,0(a5)
ffffffffc0205772:	c785                	beqz	a5,ffffffffc020579a <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc0205774:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205776:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205778:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020577a:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc020577c:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020577e:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205780:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205782:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205784:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205786:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205788:	0028                	addi	a0,sp,8
ffffffffc020578a:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020578c:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020578e:	e828                	sd	a0,80(s0)
}
ffffffffc0205790:	6406                	ld	s0,64(sp)
ffffffffc0205792:	74e2                	ld	s1,56(sp)
ffffffffc0205794:	7942                	ld	s2,48(sp)
ffffffffc0205796:	6161                	addi	sp,sp,80
ffffffffc0205798:	8082                	ret
    print_trapframe(tf);
ffffffffc020579a:	8522                	mv	a0,s0
ffffffffc020579c:	c02fb0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02057a0:	609c                	ld	a5,0(s1)
ffffffffc02057a2:	86ca                	mv	a3,s2
ffffffffc02057a4:	00002617          	auipc	a2,0x2
ffffffffc02057a8:	27460613          	addi	a2,a2,628 # ffffffffc0207a18 <default_pmm_manager+0xf50>
ffffffffc02057ac:	43d8                	lw	a4,4(a5)
ffffffffc02057ae:	06c00593          	li	a1,108
ffffffffc02057b2:	0b478793          	addi	a5,a5,180
ffffffffc02057b6:	00002517          	auipc	a0,0x2
ffffffffc02057ba:	29250513          	addi	a0,a0,658 # ffffffffc0207a48 <default_pmm_manager+0xf80>
ffffffffc02057be:	cd5fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02057c2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02057c2:	9e3707b7          	lui	a5,0x9e370
ffffffffc02057c6:	2785                	addiw	a5,a5,1
ffffffffc02057c8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02057cc:	02000793          	li	a5,32
ffffffffc02057d0:	9f8d                	subw	a5,a5,a1
}
ffffffffc02057d2:	00f5553b          	srlw	a0,a0,a5
ffffffffc02057d6:	8082                	ret

ffffffffc02057d8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02057d8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02057dc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02057de:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02057e2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02057e4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02057e8:	f022                	sd	s0,32(sp)
ffffffffc02057ea:	ec26                	sd	s1,24(sp)
ffffffffc02057ec:	e84a                	sd	s2,16(sp)
ffffffffc02057ee:	f406                	sd	ra,40(sp)
ffffffffc02057f0:	e44e                	sd	s3,8(sp)
ffffffffc02057f2:	84aa                	mv	s1,a0
ffffffffc02057f4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02057f6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02057fa:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02057fc:	03067e63          	bgeu	a2,a6,ffffffffc0205838 <printnum+0x60>
ffffffffc0205800:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205802:	00805763          	blez	s0,ffffffffc0205810 <printnum+0x38>
ffffffffc0205806:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205808:	85ca                	mv	a1,s2
ffffffffc020580a:	854e                	mv	a0,s3
ffffffffc020580c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020580e:	fc65                	bnez	s0,ffffffffc0205806 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205810:	1a02                	slli	s4,s4,0x20
ffffffffc0205812:	00003797          	auipc	a5,0x3
ffffffffc0205816:	a4e78793          	addi	a5,a5,-1458 # ffffffffc0208260 <syscalls+0x800>
ffffffffc020581a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020581e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205820:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205822:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205826:	70a2                	ld	ra,40(sp)
ffffffffc0205828:	69a2                	ld	s3,8(sp)
ffffffffc020582a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020582c:	85ca                	mv	a1,s2
ffffffffc020582e:	87a6                	mv	a5,s1
}
ffffffffc0205830:	6942                	ld	s2,16(sp)
ffffffffc0205832:	64e2                	ld	s1,24(sp)
ffffffffc0205834:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205836:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205838:	03065633          	divu	a2,a2,a6
ffffffffc020583c:	8722                	mv	a4,s0
ffffffffc020583e:	f9bff0ef          	jal	ra,ffffffffc02057d8 <printnum>
ffffffffc0205842:	b7f9                	j	ffffffffc0205810 <printnum+0x38>

ffffffffc0205844 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205844:	7119                	addi	sp,sp,-128
ffffffffc0205846:	f4a6                	sd	s1,104(sp)
ffffffffc0205848:	f0ca                	sd	s2,96(sp)
ffffffffc020584a:	ecce                	sd	s3,88(sp)
ffffffffc020584c:	e8d2                	sd	s4,80(sp)
ffffffffc020584e:	e4d6                	sd	s5,72(sp)
ffffffffc0205850:	e0da                	sd	s6,64(sp)
ffffffffc0205852:	fc5e                	sd	s7,56(sp)
ffffffffc0205854:	f06a                	sd	s10,32(sp)
ffffffffc0205856:	fc86                	sd	ra,120(sp)
ffffffffc0205858:	f8a2                	sd	s0,112(sp)
ffffffffc020585a:	f862                	sd	s8,48(sp)
ffffffffc020585c:	f466                	sd	s9,40(sp)
ffffffffc020585e:	ec6e                	sd	s11,24(sp)
ffffffffc0205860:	892a                	mv	s2,a0
ffffffffc0205862:	84ae                	mv	s1,a1
ffffffffc0205864:	8d32                	mv	s10,a2
ffffffffc0205866:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205868:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020586c:	5b7d                	li	s6,-1
ffffffffc020586e:	00003a97          	auipc	s5,0x3
ffffffffc0205872:	a1ea8a93          	addi	s5,s5,-1506 # ffffffffc020828c <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205876:	00003b97          	auipc	s7,0x3
ffffffffc020587a:	c32b8b93          	addi	s7,s7,-974 # ffffffffc02084a8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020587e:	000d4503          	lbu	a0,0(s10)
ffffffffc0205882:	001d0413          	addi	s0,s10,1
ffffffffc0205886:	01350a63          	beq	a0,s3,ffffffffc020589a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020588a:	c121                	beqz	a0,ffffffffc02058ca <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020588c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020588e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205890:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205892:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205896:	ff351ae3          	bne	a0,s3,ffffffffc020588a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020589a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020589e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02058a2:	4c81                	li	s9,0
ffffffffc02058a4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02058a6:	5c7d                	li	s8,-1
ffffffffc02058a8:	5dfd                	li	s11,-1
ffffffffc02058aa:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02058ae:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02058b0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02058b4:	0ff5f593          	zext.b	a1,a1
ffffffffc02058b8:	00140d13          	addi	s10,s0,1
ffffffffc02058bc:	04b56263          	bltu	a0,a1,ffffffffc0205900 <vprintfmt+0xbc>
ffffffffc02058c0:	058a                	slli	a1,a1,0x2
ffffffffc02058c2:	95d6                	add	a1,a1,s5
ffffffffc02058c4:	4194                	lw	a3,0(a1)
ffffffffc02058c6:	96d6                	add	a3,a3,s5
ffffffffc02058c8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02058ca:	70e6                	ld	ra,120(sp)
ffffffffc02058cc:	7446                	ld	s0,112(sp)
ffffffffc02058ce:	74a6                	ld	s1,104(sp)
ffffffffc02058d0:	7906                	ld	s2,96(sp)
ffffffffc02058d2:	69e6                	ld	s3,88(sp)
ffffffffc02058d4:	6a46                	ld	s4,80(sp)
ffffffffc02058d6:	6aa6                	ld	s5,72(sp)
ffffffffc02058d8:	6b06                	ld	s6,64(sp)
ffffffffc02058da:	7be2                	ld	s7,56(sp)
ffffffffc02058dc:	7c42                	ld	s8,48(sp)
ffffffffc02058de:	7ca2                	ld	s9,40(sp)
ffffffffc02058e0:	7d02                	ld	s10,32(sp)
ffffffffc02058e2:	6de2                	ld	s11,24(sp)
ffffffffc02058e4:	6109                	addi	sp,sp,128
ffffffffc02058e6:	8082                	ret
            padc = '0';
ffffffffc02058e8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02058ea:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02058ee:	846a                	mv	s0,s10
ffffffffc02058f0:	00140d13          	addi	s10,s0,1
ffffffffc02058f4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02058f8:	0ff5f593          	zext.b	a1,a1
ffffffffc02058fc:	fcb572e3          	bgeu	a0,a1,ffffffffc02058c0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205900:	85a6                	mv	a1,s1
ffffffffc0205902:	02500513          	li	a0,37
ffffffffc0205906:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205908:	fff44783          	lbu	a5,-1(s0)
ffffffffc020590c:	8d22                	mv	s10,s0
ffffffffc020590e:	f73788e3          	beq	a5,s3,ffffffffc020587e <vprintfmt+0x3a>
ffffffffc0205912:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205916:	1d7d                	addi	s10,s10,-1
ffffffffc0205918:	ff379de3          	bne	a5,s3,ffffffffc0205912 <vprintfmt+0xce>
ffffffffc020591c:	b78d                	j	ffffffffc020587e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020591e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205922:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205926:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205928:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020592c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205930:	02d86463          	bltu	a6,a3,ffffffffc0205958 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205934:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205938:	002c169b          	slliw	a3,s8,0x2
ffffffffc020593c:	0186873b          	addw	a4,a3,s8
ffffffffc0205940:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205944:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205946:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020594a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020594c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205950:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205954:	fed870e3          	bgeu	a6,a3,ffffffffc0205934 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205958:	f40ddce3          	bgez	s11,ffffffffc02058b0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020595c:	8de2                	mv	s11,s8
ffffffffc020595e:	5c7d                	li	s8,-1
ffffffffc0205960:	bf81                	j	ffffffffc02058b0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205962:	fffdc693          	not	a3,s11
ffffffffc0205966:	96fd                	srai	a3,a3,0x3f
ffffffffc0205968:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020596c:	00144603          	lbu	a2,1(s0)
ffffffffc0205970:	2d81                	sext.w	s11,s11
ffffffffc0205972:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205974:	bf35                	j	ffffffffc02058b0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205976:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020597a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020597e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205980:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205982:	bfd9                	j	ffffffffc0205958 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205984:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205986:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020598a:	01174463          	blt	a4,a7,ffffffffc0205992 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020598e:	1a088e63          	beqz	a7,ffffffffc0205b4a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205992:	000a3603          	ld	a2,0(s4)
ffffffffc0205996:	46c1                	li	a3,16
ffffffffc0205998:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020599a:	2781                	sext.w	a5,a5
ffffffffc020599c:	876e                	mv	a4,s11
ffffffffc020599e:	85a6                	mv	a1,s1
ffffffffc02059a0:	854a                	mv	a0,s2
ffffffffc02059a2:	e37ff0ef          	jal	ra,ffffffffc02057d8 <printnum>
            break;
ffffffffc02059a6:	bde1                	j	ffffffffc020587e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02059a8:	000a2503          	lw	a0,0(s4)
ffffffffc02059ac:	85a6                	mv	a1,s1
ffffffffc02059ae:	0a21                	addi	s4,s4,8
ffffffffc02059b0:	9902                	jalr	s2
            break;
ffffffffc02059b2:	b5f1                	j	ffffffffc020587e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02059b4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02059b6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02059ba:	01174463          	blt	a4,a7,ffffffffc02059c2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02059be:	18088163          	beqz	a7,ffffffffc0205b40 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02059c2:	000a3603          	ld	a2,0(s4)
ffffffffc02059c6:	46a9                	li	a3,10
ffffffffc02059c8:	8a2e                	mv	s4,a1
ffffffffc02059ca:	bfc1                	j	ffffffffc020599a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059cc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02059d0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059d2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02059d4:	bdf1                	j	ffffffffc02058b0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02059d6:	85a6                	mv	a1,s1
ffffffffc02059d8:	02500513          	li	a0,37
ffffffffc02059dc:	9902                	jalr	s2
            break;
ffffffffc02059de:	b545                	j	ffffffffc020587e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059e0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02059e4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059e6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02059e8:	b5e1                	j	ffffffffc02058b0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02059ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02059ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02059f0:	01174463          	blt	a4,a7,ffffffffc02059f8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02059f4:	14088163          	beqz	a7,ffffffffc0205b36 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02059f8:	000a3603          	ld	a2,0(s4)
ffffffffc02059fc:	46a1                	li	a3,8
ffffffffc02059fe:	8a2e                	mv	s4,a1
ffffffffc0205a00:	bf69                	j	ffffffffc020599a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205a02:	03000513          	li	a0,48
ffffffffc0205a06:	85a6                	mv	a1,s1
ffffffffc0205a08:	e03e                	sd	a5,0(sp)
ffffffffc0205a0a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205a0c:	85a6                	mv	a1,s1
ffffffffc0205a0e:	07800513          	li	a0,120
ffffffffc0205a12:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205a14:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205a16:	6782                	ld	a5,0(sp)
ffffffffc0205a18:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205a1a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205a1e:	bfb5                	j	ffffffffc020599a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205a20:	000a3403          	ld	s0,0(s4)
ffffffffc0205a24:	008a0713          	addi	a4,s4,8
ffffffffc0205a28:	e03a                	sd	a4,0(sp)
ffffffffc0205a2a:	14040263          	beqz	s0,ffffffffc0205b6e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205a2e:	0fb05763          	blez	s11,ffffffffc0205b1c <vprintfmt+0x2d8>
ffffffffc0205a32:	02d00693          	li	a3,45
ffffffffc0205a36:	0cd79163          	bne	a5,a3,ffffffffc0205af8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205a3a:	00044783          	lbu	a5,0(s0)
ffffffffc0205a3e:	0007851b          	sext.w	a0,a5
ffffffffc0205a42:	cf85                	beqz	a5,ffffffffc0205a7a <vprintfmt+0x236>
ffffffffc0205a44:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205a48:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205a4c:	000c4563          	bltz	s8,ffffffffc0205a56 <vprintfmt+0x212>
ffffffffc0205a50:	3c7d                	addiw	s8,s8,-1
ffffffffc0205a52:	036c0263          	beq	s8,s6,ffffffffc0205a76 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205a56:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205a58:	0e0c8e63          	beqz	s9,ffffffffc0205b54 <vprintfmt+0x310>
ffffffffc0205a5c:	3781                	addiw	a5,a5,-32
ffffffffc0205a5e:	0ef47b63          	bgeu	s0,a5,ffffffffc0205b54 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205a62:	03f00513          	li	a0,63
ffffffffc0205a66:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205a68:	000a4783          	lbu	a5,0(s4)
ffffffffc0205a6c:	3dfd                	addiw	s11,s11,-1
ffffffffc0205a6e:	0a05                	addi	s4,s4,1
ffffffffc0205a70:	0007851b          	sext.w	a0,a5
ffffffffc0205a74:	ffe1                	bnez	a5,ffffffffc0205a4c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205a76:	01b05963          	blez	s11,ffffffffc0205a88 <vprintfmt+0x244>
ffffffffc0205a7a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205a7c:	85a6                	mv	a1,s1
ffffffffc0205a7e:	02000513          	li	a0,32
ffffffffc0205a82:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205a84:	fe0d9be3          	bnez	s11,ffffffffc0205a7a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205a88:	6a02                	ld	s4,0(sp)
ffffffffc0205a8a:	bbd5                	j	ffffffffc020587e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205a8c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205a8e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205a92:	01174463          	blt	a4,a7,ffffffffc0205a9a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205a96:	08088d63          	beqz	a7,ffffffffc0205b30 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205a9a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205a9e:	0a044d63          	bltz	s0,ffffffffc0205b58 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205aa2:	8622                	mv	a2,s0
ffffffffc0205aa4:	8a66                	mv	s4,s9
ffffffffc0205aa6:	46a9                	li	a3,10
ffffffffc0205aa8:	bdcd                	j	ffffffffc020599a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205aaa:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205aae:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205ab0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205ab2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205ab6:	8fb5                	xor	a5,a5,a3
ffffffffc0205ab8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205abc:	02d74163          	blt	a4,a3,ffffffffc0205ade <vprintfmt+0x29a>
ffffffffc0205ac0:	00369793          	slli	a5,a3,0x3
ffffffffc0205ac4:	97de                	add	a5,a5,s7
ffffffffc0205ac6:	639c                	ld	a5,0(a5)
ffffffffc0205ac8:	cb99                	beqz	a5,ffffffffc0205ade <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205aca:	86be                	mv	a3,a5
ffffffffc0205acc:	00000617          	auipc	a2,0x0
ffffffffc0205ad0:	1f460613          	addi	a2,a2,500 # ffffffffc0205cc0 <etext+0x2e>
ffffffffc0205ad4:	85a6                	mv	a1,s1
ffffffffc0205ad6:	854a                	mv	a0,s2
ffffffffc0205ad8:	0ce000ef          	jal	ra,ffffffffc0205ba6 <printfmt>
ffffffffc0205adc:	b34d                	j	ffffffffc020587e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205ade:	00002617          	auipc	a2,0x2
ffffffffc0205ae2:	7a260613          	addi	a2,a2,1954 # ffffffffc0208280 <syscalls+0x820>
ffffffffc0205ae6:	85a6                	mv	a1,s1
ffffffffc0205ae8:	854a                	mv	a0,s2
ffffffffc0205aea:	0bc000ef          	jal	ra,ffffffffc0205ba6 <printfmt>
ffffffffc0205aee:	bb41                	j	ffffffffc020587e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205af0:	00002417          	auipc	s0,0x2
ffffffffc0205af4:	78840413          	addi	s0,s0,1928 # ffffffffc0208278 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205af8:	85e2                	mv	a1,s8
ffffffffc0205afa:	8522                	mv	a0,s0
ffffffffc0205afc:	e43e                	sd	a5,8(sp)
ffffffffc0205afe:	0e2000ef          	jal	ra,ffffffffc0205be0 <strnlen>
ffffffffc0205b02:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205b06:	01b05b63          	blez	s11,ffffffffc0205b1c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205b0a:	67a2                	ld	a5,8(sp)
ffffffffc0205b0c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205b10:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205b12:	85a6                	mv	a1,s1
ffffffffc0205b14:	8552                	mv	a0,s4
ffffffffc0205b16:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205b18:	fe0d9ce3          	bnez	s11,ffffffffc0205b10 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b1c:	00044783          	lbu	a5,0(s0)
ffffffffc0205b20:	00140a13          	addi	s4,s0,1
ffffffffc0205b24:	0007851b          	sext.w	a0,a5
ffffffffc0205b28:	d3a5                	beqz	a5,ffffffffc0205a88 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205b2a:	05e00413          	li	s0,94
ffffffffc0205b2e:	bf39                	j	ffffffffc0205a4c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205b30:	000a2403          	lw	s0,0(s4)
ffffffffc0205b34:	b7ad                	j	ffffffffc0205a9e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205b36:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b3a:	46a1                	li	a3,8
ffffffffc0205b3c:	8a2e                	mv	s4,a1
ffffffffc0205b3e:	bdb1                	j	ffffffffc020599a <vprintfmt+0x156>
ffffffffc0205b40:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b44:	46a9                	li	a3,10
ffffffffc0205b46:	8a2e                	mv	s4,a1
ffffffffc0205b48:	bd89                	j	ffffffffc020599a <vprintfmt+0x156>
ffffffffc0205b4a:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b4e:	46c1                	li	a3,16
ffffffffc0205b50:	8a2e                	mv	s4,a1
ffffffffc0205b52:	b5a1                	j	ffffffffc020599a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205b54:	9902                	jalr	s2
ffffffffc0205b56:	bf09                	j	ffffffffc0205a68 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205b58:	85a6                	mv	a1,s1
ffffffffc0205b5a:	02d00513          	li	a0,45
ffffffffc0205b5e:	e03e                	sd	a5,0(sp)
ffffffffc0205b60:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205b62:	6782                	ld	a5,0(sp)
ffffffffc0205b64:	8a66                	mv	s4,s9
ffffffffc0205b66:	40800633          	neg	a2,s0
ffffffffc0205b6a:	46a9                	li	a3,10
ffffffffc0205b6c:	b53d                	j	ffffffffc020599a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205b6e:	03b05163          	blez	s11,ffffffffc0205b90 <vprintfmt+0x34c>
ffffffffc0205b72:	02d00693          	li	a3,45
ffffffffc0205b76:	f6d79de3          	bne	a5,a3,ffffffffc0205af0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205b7a:	00002417          	auipc	s0,0x2
ffffffffc0205b7e:	6fe40413          	addi	s0,s0,1790 # ffffffffc0208278 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b82:	02800793          	li	a5,40
ffffffffc0205b86:	02800513          	li	a0,40
ffffffffc0205b8a:	00140a13          	addi	s4,s0,1
ffffffffc0205b8e:	bd6d                	j	ffffffffc0205a48 <vprintfmt+0x204>
ffffffffc0205b90:	00002a17          	auipc	s4,0x2
ffffffffc0205b94:	6e9a0a13          	addi	s4,s4,1769 # ffffffffc0208279 <syscalls+0x819>
ffffffffc0205b98:	02800513          	li	a0,40
ffffffffc0205b9c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205ba0:	05e00413          	li	s0,94
ffffffffc0205ba4:	b565                	j	ffffffffc0205a4c <vprintfmt+0x208>

ffffffffc0205ba6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205ba6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205ba8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205bac:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205bae:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205bb0:	ec06                	sd	ra,24(sp)
ffffffffc0205bb2:	f83a                	sd	a4,48(sp)
ffffffffc0205bb4:	fc3e                	sd	a5,56(sp)
ffffffffc0205bb6:	e0c2                	sd	a6,64(sp)
ffffffffc0205bb8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205bba:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205bbc:	c89ff0ef          	jal	ra,ffffffffc0205844 <vprintfmt>
}
ffffffffc0205bc0:	60e2                	ld	ra,24(sp)
ffffffffc0205bc2:	6161                	addi	sp,sp,80
ffffffffc0205bc4:	8082                	ret

ffffffffc0205bc6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205bc6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205bca:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205bcc:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205bce:	cb81                	beqz	a5,ffffffffc0205bde <strlen+0x18>
        cnt ++;
ffffffffc0205bd0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205bd2:	00a707b3          	add	a5,a4,a0
ffffffffc0205bd6:	0007c783          	lbu	a5,0(a5)
ffffffffc0205bda:	fbfd                	bnez	a5,ffffffffc0205bd0 <strlen+0xa>
ffffffffc0205bdc:	8082                	ret
    }
    return cnt;
}
ffffffffc0205bde:	8082                	ret

ffffffffc0205be0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205be0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205be2:	e589                	bnez	a1,ffffffffc0205bec <strnlen+0xc>
ffffffffc0205be4:	a811                	j	ffffffffc0205bf8 <strnlen+0x18>
        cnt ++;
ffffffffc0205be6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205be8:	00f58863          	beq	a1,a5,ffffffffc0205bf8 <strnlen+0x18>
ffffffffc0205bec:	00f50733          	add	a4,a0,a5
ffffffffc0205bf0:	00074703          	lbu	a4,0(a4)
ffffffffc0205bf4:	fb6d                	bnez	a4,ffffffffc0205be6 <strnlen+0x6>
ffffffffc0205bf6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205bf8:	852e                	mv	a0,a1
ffffffffc0205bfa:	8082                	ret

ffffffffc0205bfc <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205bfc:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205bfe:	0005c703          	lbu	a4,0(a1)
ffffffffc0205c02:	0785                	addi	a5,a5,1
ffffffffc0205c04:	0585                	addi	a1,a1,1
ffffffffc0205c06:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205c0a:	fb75                	bnez	a4,ffffffffc0205bfe <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205c0c:	8082                	ret

ffffffffc0205c0e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205c0e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c12:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205c16:	cb89                	beqz	a5,ffffffffc0205c28 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205c18:	0505                	addi	a0,a0,1
ffffffffc0205c1a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205c1c:	fee789e3          	beq	a5,a4,ffffffffc0205c0e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c20:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205c24:	9d19                	subw	a0,a0,a4
ffffffffc0205c26:	8082                	ret
ffffffffc0205c28:	4501                	li	a0,0
ffffffffc0205c2a:	bfed                	j	ffffffffc0205c24 <strcmp+0x16>

ffffffffc0205c2c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c2c:	c20d                	beqz	a2,ffffffffc0205c4e <strncmp+0x22>
ffffffffc0205c2e:	962e                	add	a2,a2,a1
ffffffffc0205c30:	a031                	j	ffffffffc0205c3c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205c32:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c34:	00e79a63          	bne	a5,a4,ffffffffc0205c48 <strncmp+0x1c>
ffffffffc0205c38:	00b60b63          	beq	a2,a1,ffffffffc0205c4e <strncmp+0x22>
ffffffffc0205c3c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205c40:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c42:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205c46:	f7f5                	bnez	a5,ffffffffc0205c32 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c48:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205c4c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c4e:	4501                	li	a0,0
ffffffffc0205c50:	8082                	ret

ffffffffc0205c52 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205c52:	00054783          	lbu	a5,0(a0)
ffffffffc0205c56:	c799                	beqz	a5,ffffffffc0205c64 <strchr+0x12>
        if (*s == c) {
ffffffffc0205c58:	00f58763          	beq	a1,a5,ffffffffc0205c66 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205c5c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205c60:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205c62:	fbfd                	bnez	a5,ffffffffc0205c58 <strchr+0x6>
    }
    return NULL;
ffffffffc0205c64:	4501                	li	a0,0
}
ffffffffc0205c66:	8082                	ret

ffffffffc0205c68 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205c68:	ca01                	beqz	a2,ffffffffc0205c78 <memset+0x10>
ffffffffc0205c6a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205c6c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205c6e:	0785                	addi	a5,a5,1
ffffffffc0205c70:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205c74:	fec79de3          	bne	a5,a2,ffffffffc0205c6e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205c78:	8082                	ret

ffffffffc0205c7a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205c7a:	ca19                	beqz	a2,ffffffffc0205c90 <memcpy+0x16>
ffffffffc0205c7c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205c7e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205c80:	0005c703          	lbu	a4,0(a1)
ffffffffc0205c84:	0585                	addi	a1,a1,1
ffffffffc0205c86:	0785                	addi	a5,a5,1
ffffffffc0205c88:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205c8c:	fec59ae3          	bne	a1,a2,ffffffffc0205c80 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205c90:	8082                	ret
