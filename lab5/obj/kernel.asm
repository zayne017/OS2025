
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

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
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	1f650513          	addi	a0,a0,502 # ffffffffc02a6240 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	69260613          	addi	a2,a2,1682 # ffffffffc02aa6e4 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	64c050ef          	jal	ra,ffffffffc02056ae <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	66a58593          	addi	a1,a1,1642 # ffffffffc02056d8 <etext>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	68250513          	addi	a0,a0,1666 # ffffffffc02056f8 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	690020ef          	jal	ra,ffffffffc0202716 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	15d030ef          	jal	ra,ffffffffc02039ee <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	56b040ef          	jal	ra,ffffffffc0204e00 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	6f7040ef          	jal	ra,ffffffffc0204f98 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	64450513          	addi	a0,a0,1604 # ffffffffc0205700 <etext+0x28>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	16eb8b93          	addi	s7,s7,366 # ffffffffc02a6240 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	11250513          	addi	a0,a0,274 # ffffffffc02a6240 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	102050ef          	jal	ra,ffffffffc020528a <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	0cc050ef          	jal	ra,ffffffffc020528a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	4ea50513          	addi	a0,a0,1258 # ffffffffc0205708 <etext+0x30>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	4f450513          	addi	a0,a0,1268 # ffffffffc0205728 <etext+0x50>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	49858593          	addi	a1,a1,1176 # ffffffffc02056d8 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	50050513          	addi	a0,a0,1280 # ffffffffc0205748 <etext+0x70>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	fec58593          	addi	a1,a1,-20 # ffffffffc02a6240 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	50c50513          	addi	a0,a0,1292 # ffffffffc0205768 <etext+0x90>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	47c58593          	addi	a1,a1,1148 # ffffffffc02aa6e4 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	51850513          	addi	a0,a0,1304 # ffffffffc0205788 <etext+0xb0>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	86758593          	addi	a1,a1,-1945 # ffffffffc02aaae3 <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	50a50513          	addi	a0,a0,1290 # ffffffffc02057a8 <etext+0xd0>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	52c60613          	addi	a2,a2,1324 # ffffffffc02057d8 <etext+0x100>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	53850513          	addi	a0,a0,1336 # ffffffffc02057f0 <etext+0x118>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	54060613          	addi	a2,a2,1344 # ffffffffc0205808 <etext+0x130>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	55858593          	addi	a1,a1,1368 # ffffffffc0205828 <etext+0x150>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	55850513          	addi	a0,a0,1368 # ffffffffc0205830 <etext+0x158>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	55a60613          	addi	a2,a2,1370 # ffffffffc0205840 <etext+0x168>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	57a58593          	addi	a1,a1,1402 # ffffffffc0205868 <etext+0x190>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	53a50513          	addi	a0,a0,1338 # ffffffffc0205830 <etext+0x158>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	57660613          	addi	a2,a2,1398 # ffffffffc0205878 <etext+0x1a0>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	58e58593          	addi	a1,a1,1422 # ffffffffc0205898 <etext+0x1c0>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	51e50513          	addi	a0,a0,1310 # ffffffffc0205830 <etext+0x158>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	55c50513          	addi	a0,a0,1372 # ffffffffc02058a8 <etext+0x1d0>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	56250513          	addi	a0,a0,1378 # ffffffffc02058d0 <etext+0x1f8>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	5bcc0c13          	addi	s8,s8,1468 # ffffffffc0205940 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	56c90913          	addi	s2,s2,1388 # ffffffffc02058f8 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	56c48493          	addi	s1,s1,1388 # ffffffffc0205900 <etext+0x228>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	56ab0b13          	addi	s6,s6,1386 # ffffffffc0205908 <etext+0x230>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	482a0a13          	addi	s4,s4,1154 # ffffffffc0205828 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	578d0d13          	addi	s10,s10,1400 # ffffffffc0205940 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	27e050ef          	jal	ra,ffffffffc0205654 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	26a050ef          	jal	ra,ffffffffc0205654 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	270050ef          	jal	ra,ffffffffc0205698 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	232050ef          	jal	ra,ffffffffc0205698 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	4a850513          	addi	a0,a0,1192 # ffffffffc0205928 <etext+0x250>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	1da30313          	addi	t1,t1,474 # ffffffffc02aa668 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	4cc50513          	addi	a0,a0,1228 # ffffffffc0205988 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	5ae50513          	addi	a0,a0,1454 # ffffffffc0206a80 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	4a250513          	addi	a0,a0,1186 # ffffffffc02059a8 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	55a50513          	addi	a0,a0,1370 # ffffffffc0206a80 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd588>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	12f73c23          	sd	a5,312(a4) # ffffffffc02aa678 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	46850513          	addi	a0,a0,1128 # ffffffffc02059c8 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1007b423          	sd	zero,264(a5) # ffffffffc02aa670 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	1027b783          	ld	a5,258(a5) # ffffffffc02aa678 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	3e850513          	addi	a0,a0,1000 # ffffffffc02059e8 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	3ca50513          	addi	a0,a0,970 # ffffffffc02059f8 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	3c450513          	addi	a0,a0,964 # ffffffffc0205a08 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	3cc50513          	addi	a0,a0,972 # ffffffffc0205a20 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe35809>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	36290913          	addi	s2,s2,866 # ffffffffc0205a70 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	34c48493          	addi	s1,s1,844 # ffffffffc0205a68 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	37850513          	addi	a0,a0,888 # ffffffffc0205ae8 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	3a450513          	addi	a0,a0,932 # ffffffffc0205b20 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	28450513          	addi	a0,a0,644 # ffffffffc0205a40 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	643040ef          	jal	ra,ffffffffc020560c <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	69b040ef          	jal	ra,ffffffffc0205672 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	5e7040ef          	jal	ra,ffffffffc0205654 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	1f650513          	addi	a0,a0,502 # ffffffffc0205a78 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	14850513          	addi	a0,a0,328 # ffffffffc0205a98 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	14e50513          	addi	a0,a0,334 # ffffffffc0205ab0 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	15c50513          	addi	a0,a0,348 # ffffffffc0205ad0 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	1a050513          	addi	a0,a0,416 # ffffffffc0205b20 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	ce87bc23          	sd	s0,-776(a5) # ffffffffc02aa680 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	cf67bc23          	sd	s6,-776(a5) # ffffffffc02aa688 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	ce653503          	ld	a0,-794(a0) # ffffffffc02aa680 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	ce453503          	ld	a0,-796(a0) # ffffffffc02aa688 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	48478793          	addi	a5,a5,1156 # ffffffffc0200e44 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	15a50513          	addi	a0,a0,346 # ffffffffc0205b38 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	16250513          	addi	a0,a0,354 # ffffffffc0205b50 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	16c50513          	addi	a0,a0,364 # ffffffffc0205b68 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	17650513          	addi	a0,a0,374 # ffffffffc0205b80 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	18050513          	addi	a0,a0,384 # ffffffffc0205b98 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	18a50513          	addi	a0,a0,394 # ffffffffc0205bb0 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	19450513          	addi	a0,a0,404 # ffffffffc0205bc8 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	19e50513          	addi	a0,a0,414 # ffffffffc0205be0 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	1a850513          	addi	a0,a0,424 # ffffffffc0205bf8 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	1b250513          	addi	a0,a0,434 # ffffffffc0205c10 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	1bc50513          	addi	a0,a0,444 # ffffffffc0205c28 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	1c650513          	addi	a0,a0,454 # ffffffffc0205c40 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	1d050513          	addi	a0,a0,464 # ffffffffc0205c58 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	1da50513          	addi	a0,a0,474 # ffffffffc0205c70 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	1e450513          	addi	a0,a0,484 # ffffffffc0205c88 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	1ee50513          	addi	a0,a0,494 # ffffffffc0205ca0 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	1f850513          	addi	a0,a0,504 # ffffffffc0205cb8 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	20250513          	addi	a0,a0,514 # ffffffffc0205cd0 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	20c50513          	addi	a0,a0,524 # ffffffffc0205ce8 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	21650513          	addi	a0,a0,534 # ffffffffc0205d00 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	22050513          	addi	a0,a0,544 # ffffffffc0205d18 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	22a50513          	addi	a0,a0,554 # ffffffffc0205d30 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	23450513          	addi	a0,a0,564 # ffffffffc0205d48 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	23e50513          	addi	a0,a0,574 # ffffffffc0205d60 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	24850513          	addi	a0,a0,584 # ffffffffc0205d78 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	25250513          	addi	a0,a0,594 # ffffffffc0205d90 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	25c50513          	addi	a0,a0,604 # ffffffffc0205da8 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	26650513          	addi	a0,a0,614 # ffffffffc0205dc0 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	27050513          	addi	a0,a0,624 # ffffffffc0205dd8 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	27a50513          	addi	a0,a0,634 # ffffffffc0205df0 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	28450513          	addi	a0,a0,644 # ffffffffc0205e08 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	28a50513          	addi	a0,a0,650 # ffffffffc0205e20 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	28c50513          	addi	a0,a0,652 # ffffffffc0205e38 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	28c50513          	addi	a0,a0,652 # ffffffffc0205e50 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	29450513          	addi	a0,a0,660 # ffffffffc0205e68 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	29c50513          	addi	a0,a0,668 # ffffffffc0205e80 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	29850513          	addi	a0,a0,664 # ffffffffc0205e90 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	08f76463          	bltu	a4,a5,ffffffffc0200c98 <interrupt_handler+0x92>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	33470713          	addi	a4,a4,820 # ffffffffc0205f48 <commands+0x608>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	2e250513          	addi	a0,a0,738 # ffffffffc0205f08 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	2b650513          	addi	a0,a0,694 # ffffffffc0205ee8 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	26a50513          	addi	a0,a0,618 # ffffffffc0205ea8 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	27e50513          	addi	a0,a0,638 # ffffffffc0205ec8 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，
          如果有则标记该进程需要被重新调度（current->need_resched）
         */
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        ticks++;
ffffffffc0200c5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200c62:	a1278793          	addi	a5,a5,-1518 # ffffffffc02aa670 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
ffffffffc0200c68:	0705                	addi	a4,a4,1
ffffffffc0200c6a:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0)
ffffffffc0200c6c:	639c                	ld	a5,0(a5)
ffffffffc0200c6e:	06400713          	li	a4,100
ffffffffc0200c72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c76:	eb81                	bnez	a5,ffffffffc0200c86 <interrupt_handler+0x80>
        {
            if (current != NULL)//确保当前有进程在运行
ffffffffc0200c78:	000aa797          	auipc	a5,0xaa
ffffffffc0200c7c:	a507b783          	ld	a5,-1456(a5) # ffffffffc02aa6c8 <current>
ffffffffc0200c80:	c399                	beqz	a5,ffffffffc0200c86 <interrupt_handler+0x80>
            {
                current->need_resched = 1;// 标记：该进程时间片用完了，申请调度
ffffffffc0200c82:	4705                	li	a4,1
ffffffffc0200c84:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c86:	60a2                	ld	ra,8(sp)
ffffffffc0200c88:	0141                	addi	sp,sp,16
ffffffffc0200c8a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	29c50513          	addi	a0,a0,668 # ffffffffc0205f28 <commands+0x5e8>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c98:	b731                	j	ffffffffc0200ba4 <print_trapframe>

ffffffffc0200c9a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c9a:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c9e:	1141                	addi	sp,sp,-16
ffffffffc0200ca0:	e022                	sd	s0,0(sp)
ffffffffc0200ca2:	e406                	sd	ra,8(sp)
ffffffffc0200ca4:	473d                	li	a4,15
ffffffffc0200ca6:	842a                	mv	s0,a0
ffffffffc0200ca8:	0cf76463          	bltu	a4,a5,ffffffffc0200d70 <exception_handler+0xd6>
ffffffffc0200cac:	00005717          	auipc	a4,0x5
ffffffffc0200cb0:	45c70713          	addi	a4,a4,1116 # ffffffffc0206108 <commands+0x7c8>
ffffffffc0200cb4:	078a                	slli	a5,a5,0x2
ffffffffc0200cb6:	97ba                	add	a5,a5,a4
ffffffffc0200cb8:	439c                	lw	a5,0(a5)
ffffffffc0200cba:	97ba                	add	a5,a5,a4
ffffffffc0200cbc:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cbe:	00005517          	auipc	a0,0x5
ffffffffc0200cc2:	3a250513          	addi	a0,a0,930 # ffffffffc0206060 <commands+0x720>
ffffffffc0200cc6:	cceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cca:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cce:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cd0:	0791                	addi	a5,a5,4
ffffffffc0200cd2:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cd6:	6402                	ld	s0,0(sp)
ffffffffc0200cd8:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cda:	4ae0406f          	j	ffffffffc0205188 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cde:	00005517          	auipc	a0,0x5
ffffffffc0200ce2:	3a250513          	addi	a0,a0,930 # ffffffffc0206080 <commands+0x740>
}
ffffffffc0200ce6:	6402                	ld	s0,0(sp)
ffffffffc0200ce8:	60a2                	ld	ra,8(sp)
ffffffffc0200cea:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200cec:	ca8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cf0:	00005517          	auipc	a0,0x5
ffffffffc0200cf4:	3b050513          	addi	a0,a0,944 # ffffffffc02060a0 <commands+0x760>
ffffffffc0200cf8:	b7fd                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200cfa:	00005517          	auipc	a0,0x5
ffffffffc0200cfe:	3c650513          	addi	a0,a0,966 # ffffffffc02060c0 <commands+0x780>
ffffffffc0200d02:	b7d5                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200d04:	00005517          	auipc	a0,0x5
ffffffffc0200d08:	3d450513          	addi	a0,a0,980 # ffffffffc02060d8 <commands+0x798>
ffffffffc0200d0c:	bfe9                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d0e:	00005517          	auipc	a0,0x5
ffffffffc0200d12:	3e250513          	addi	a0,a0,994 # ffffffffc02060f0 <commands+0x7b0>
ffffffffc0200d16:	bfc1                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d18:	00005517          	auipc	a0,0x5
ffffffffc0200d1c:	26050513          	addi	a0,a0,608 # ffffffffc0205f78 <commands+0x638>
ffffffffc0200d20:	b7d9                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	27650513          	addi	a0,a0,630 # ffffffffc0205f98 <commands+0x658>
ffffffffc0200d2a:	bf75                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d2c:	00005517          	auipc	a0,0x5
ffffffffc0200d30:	28c50513          	addi	a0,a0,652 # ffffffffc0205fb8 <commands+0x678>
ffffffffc0200d34:	bf4d                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d36:	00005517          	auipc	a0,0x5
ffffffffc0200d3a:	29a50513          	addi	a0,a0,666 # ffffffffc0205fd0 <commands+0x690>
ffffffffc0200d3e:	c56ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d42:	6458                	ld	a4,136(s0)
ffffffffc0200d44:	47a9                	li	a5,10
ffffffffc0200d46:	04f70663          	beq	a4,a5,ffffffffc0200d92 <exception_handler+0xf8>
}
ffffffffc0200d4a:	60a2                	ld	ra,8(sp)
ffffffffc0200d4c:	6402                	ld	s0,0(sp)
ffffffffc0200d4e:	0141                	addi	sp,sp,16
ffffffffc0200d50:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d52:	00005517          	auipc	a0,0x5
ffffffffc0200d56:	28e50513          	addi	a0,a0,654 # ffffffffc0205fe0 <commands+0x6a0>
ffffffffc0200d5a:	b771                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d5c:	00005517          	auipc	a0,0x5
ffffffffc0200d60:	2a450513          	addi	a0,a0,676 # ffffffffc0206000 <commands+0x6c0>
ffffffffc0200d64:	b749                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d66:	00005517          	auipc	a0,0x5
ffffffffc0200d6a:	2e250513          	addi	a0,a0,738 # ffffffffc0206048 <commands+0x708>
ffffffffc0200d6e:	bfa5                	j	ffffffffc0200ce6 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d70:	8522                	mv	a0,s0
}
ffffffffc0200d72:	6402                	ld	s0,0(sp)
ffffffffc0200d74:	60a2                	ld	ra,8(sp)
ffffffffc0200d76:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d78:	b535                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d7a:	00005617          	auipc	a2,0x5
ffffffffc0200d7e:	29e60613          	addi	a2,a2,670 # ffffffffc0206018 <commands+0x6d8>
ffffffffc0200d82:	0c200593          	li	a1,194
ffffffffc0200d86:	00005517          	auipc	a0,0x5
ffffffffc0200d8a:	2aa50513          	addi	a0,a0,682 # ffffffffc0206030 <commands+0x6f0>
ffffffffc0200d8e:	f00ff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200d92:	10843783          	ld	a5,264(s0)
ffffffffc0200d96:	0791                	addi	a5,a5,4
ffffffffc0200d98:	10f43423          	sd	a5,264(s0)
            syscall();// 这里面调用了 sys_exec -> do_execve
ffffffffc0200d9c:	3ec040ef          	jal	ra,ffffffffc0205188 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);//sret返回用户态
ffffffffc0200da0:	000aa797          	auipc	a5,0xaa
ffffffffc0200da4:	9287b783          	ld	a5,-1752(a5) # ffffffffc02aa6c8 <current>
ffffffffc0200da8:	6b9c                	ld	a5,16(a5)
ffffffffc0200daa:	8522                	mv	a0,s0
}
ffffffffc0200dac:	6402                	ld	s0,0(sp)
ffffffffc0200dae:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);//sret返回用户态
ffffffffc0200db0:	6589                	lui	a1,0x2
ffffffffc0200db2:	95be                	add	a1,a1,a5
}
ffffffffc0200db4:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);//sret返回用户态
ffffffffc0200db6:	aab1                	j	ffffffffc0200f12 <kernel_execve_ret>

ffffffffc0200db8 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200db8:	1101                	addi	sp,sp,-32
ffffffffc0200dba:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200dbc:	000aa417          	auipc	s0,0xaa
ffffffffc0200dc0:	90c40413          	addi	s0,s0,-1780 # ffffffffc02aa6c8 <current>
ffffffffc0200dc4:	6018                	ld	a4,0(s0)
{
ffffffffc0200dc6:	ec06                	sd	ra,24(sp)
ffffffffc0200dc8:	e426                	sd	s1,8(sp)
ffffffffc0200dca:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dcc:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200dd0:	cf1d                	beqz	a4,ffffffffc0200e0e <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dd2:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200dd6:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200dda:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200ddc:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200de0:	0206c463          	bltz	a3,ffffffffc0200e08 <trap+0x50>
        exception_handler(tf);
ffffffffc0200de4:	eb7ff0ef          	jal	ra,ffffffffc0200c9a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200de8:	601c                	ld	a5,0(s0)
ffffffffc0200dea:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200dee:	e499                	bnez	s1,ffffffffc0200dfc <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200df0:	0b07a703          	lw	a4,176(a5)
ffffffffc0200df4:	8b05                	andi	a4,a4,1
ffffffffc0200df6:	e329                	bnez	a4,ffffffffc0200e38 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200df8:	6f9c                	ld	a5,24(a5)
ffffffffc0200dfa:	eb85                	bnez	a5,ffffffffc0200e2a <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200dfc:	60e2                	ld	ra,24(sp)
ffffffffc0200dfe:	6442                	ld	s0,16(sp)
ffffffffc0200e00:	64a2                	ld	s1,8(sp)
ffffffffc0200e02:	6902                	ld	s2,0(sp)
ffffffffc0200e04:	6105                	addi	sp,sp,32
ffffffffc0200e06:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e08:	dffff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e0c:	bff1                	j	ffffffffc0200de8 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e0e:	0006c863          	bltz	a3,ffffffffc0200e1e <trap+0x66>
}
ffffffffc0200e12:	6442                	ld	s0,16(sp)
ffffffffc0200e14:	60e2                	ld	ra,24(sp)
ffffffffc0200e16:	64a2                	ld	s1,8(sp)
ffffffffc0200e18:	6902                	ld	s2,0(sp)
ffffffffc0200e1a:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e1c:	bdbd                	j	ffffffffc0200c9a <exception_handler>
}
ffffffffc0200e1e:	6442                	ld	s0,16(sp)
ffffffffc0200e20:	60e2                	ld	ra,24(sp)
ffffffffc0200e22:	64a2                	ld	s1,8(sp)
ffffffffc0200e24:	6902                	ld	s2,0(sp)
ffffffffc0200e26:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e28:	bbf9                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e2a:	6442                	ld	s0,16(sp)
ffffffffc0200e2c:	60e2                	ld	ra,24(sp)
ffffffffc0200e2e:	64a2                	ld	s1,8(sp)
ffffffffc0200e30:	6902                	ld	s2,0(sp)
ffffffffc0200e32:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e34:	2680406f          	j	ffffffffc020509c <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e38:	555d                	li	a0,-9
ffffffffc0200e3a:	5a8030ef          	jal	ra,ffffffffc02043e2 <do_exit>
            if (current->need_resched)
ffffffffc0200e3e:	601c                	ld	a5,0(s0)
ffffffffc0200e40:	bf65                	j	ffffffffc0200df8 <trap+0x40>
	...

ffffffffc0200e44 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)# 如果我们要回用户态，sp 就从内核栈指回了用户栈指针
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e44:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e48:	00011463          	bnez	sp,ffffffffc0200e50 <__alltraps+0xc>
ffffffffc0200e4c:	14002173          	csrr	sp,sscratch
ffffffffc0200e50:	712d                	addi	sp,sp,-288
ffffffffc0200e52:	e002                	sd	zero,0(sp)
ffffffffc0200e54:	e406                	sd	ra,8(sp)
ffffffffc0200e56:	ec0e                	sd	gp,24(sp)
ffffffffc0200e58:	f012                	sd	tp,32(sp)
ffffffffc0200e5a:	f416                	sd	t0,40(sp)
ffffffffc0200e5c:	f81a                	sd	t1,48(sp)
ffffffffc0200e5e:	fc1e                	sd	t2,56(sp)
ffffffffc0200e60:	e0a2                	sd	s0,64(sp)
ffffffffc0200e62:	e4a6                	sd	s1,72(sp)
ffffffffc0200e64:	e8aa                	sd	a0,80(sp)
ffffffffc0200e66:	ecae                	sd	a1,88(sp)
ffffffffc0200e68:	f0b2                	sd	a2,96(sp)
ffffffffc0200e6a:	f4b6                	sd	a3,104(sp)
ffffffffc0200e6c:	f8ba                	sd	a4,112(sp)
ffffffffc0200e6e:	fcbe                	sd	a5,120(sp)
ffffffffc0200e70:	e142                	sd	a6,128(sp)
ffffffffc0200e72:	e546                	sd	a7,136(sp)
ffffffffc0200e74:	e94a                	sd	s2,144(sp)
ffffffffc0200e76:	ed4e                	sd	s3,152(sp)
ffffffffc0200e78:	f152                	sd	s4,160(sp)
ffffffffc0200e7a:	f556                	sd	s5,168(sp)
ffffffffc0200e7c:	f95a                	sd	s6,176(sp)
ffffffffc0200e7e:	fd5e                	sd	s7,184(sp)
ffffffffc0200e80:	e1e2                	sd	s8,192(sp)
ffffffffc0200e82:	e5e6                	sd	s9,200(sp)
ffffffffc0200e84:	e9ea                	sd	s10,208(sp)
ffffffffc0200e86:	edee                	sd	s11,216(sp)
ffffffffc0200e88:	f1f2                	sd	t3,224(sp)
ffffffffc0200e8a:	f5f6                	sd	t4,232(sp)
ffffffffc0200e8c:	f9fa                	sd	t5,240(sp)
ffffffffc0200e8e:	fdfe                	sd	t6,248(sp)
ffffffffc0200e90:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e94:	100024f3          	csrr	s1,sstatus
ffffffffc0200e98:	14102973          	csrr	s2,sepc
ffffffffc0200e9c:	143029f3          	csrr	s3,stval
ffffffffc0200ea0:	14202a73          	csrr	s4,scause
ffffffffc0200ea4:	e822                	sd	s0,16(sp)
ffffffffc0200ea6:	e226                	sd	s1,256(sp)
ffffffffc0200ea8:	e64a                	sd	s2,264(sp)
ffffffffc0200eaa:	ea4e                	sd	s3,272(sp)
ffffffffc0200eac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200eae:	850a                	mv	a0,sp
    jal trap
ffffffffc0200eb0:	f09ff0ef          	jal	ra,ffffffffc0200db8 <trap>

ffffffffc0200eb4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200eb4:	6492                	ld	s1,256(sp)
ffffffffc0200eb6:	6932                	ld	s2,264(sp)
ffffffffc0200eb8:	1004f413          	andi	s0,s1,256
ffffffffc0200ebc:	e401                	bnez	s0,ffffffffc0200ec4 <__trapret+0x10>
ffffffffc0200ebe:	1200                	addi	s0,sp,288
ffffffffc0200ec0:	14041073          	csrw	sscratch,s0
ffffffffc0200ec4:	10049073          	csrw	sstatus,s1
ffffffffc0200ec8:	14191073          	csrw	sepc,s2
ffffffffc0200ecc:	60a2                	ld	ra,8(sp)
ffffffffc0200ece:	61e2                	ld	gp,24(sp)
ffffffffc0200ed0:	7202                	ld	tp,32(sp)
ffffffffc0200ed2:	72a2                	ld	t0,40(sp)
ffffffffc0200ed4:	7342                	ld	t1,48(sp)
ffffffffc0200ed6:	73e2                	ld	t2,56(sp)
ffffffffc0200ed8:	6406                	ld	s0,64(sp)
ffffffffc0200eda:	64a6                	ld	s1,72(sp)
ffffffffc0200edc:	6546                	ld	a0,80(sp)
ffffffffc0200ede:	65e6                	ld	a1,88(sp)
ffffffffc0200ee0:	7606                	ld	a2,96(sp)
ffffffffc0200ee2:	76a6                	ld	a3,104(sp)
ffffffffc0200ee4:	7746                	ld	a4,112(sp)
ffffffffc0200ee6:	77e6                	ld	a5,120(sp)
ffffffffc0200ee8:	680a                	ld	a6,128(sp)
ffffffffc0200eea:	68aa                	ld	a7,136(sp)
ffffffffc0200eec:	694a                	ld	s2,144(sp)
ffffffffc0200eee:	69ea                	ld	s3,152(sp)
ffffffffc0200ef0:	7a0a                	ld	s4,160(sp)
ffffffffc0200ef2:	7aaa                	ld	s5,168(sp)
ffffffffc0200ef4:	7b4a                	ld	s6,176(sp)
ffffffffc0200ef6:	7bea                	ld	s7,184(sp)
ffffffffc0200ef8:	6c0e                	ld	s8,192(sp)
ffffffffc0200efa:	6cae                	ld	s9,200(sp)
ffffffffc0200efc:	6d4e                	ld	s10,208(sp)
ffffffffc0200efe:	6dee                	ld	s11,216(sp)
ffffffffc0200f00:	7e0e                	ld	t3,224(sp)
ffffffffc0200f02:	7eae                	ld	t4,232(sp)
ffffffffc0200f04:	7f4e                	ld	t5,240(sp)
ffffffffc0200f06:	7fee                	ld	t6,248(sp)
ffffffffc0200f08:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f0a:	10200073          	sret

ffffffffc0200f0e <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f0e:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f10:	b755                	j	ffffffffc0200eb4 <__trapret>

ffffffffc0200f12 <kernel_execve_ret>:
    .global kernel_execve_ret
kernel_execve_ret:
    # 参数 a0: 旧的 trapframe 地址 (在栈的中间某个位置)
    # 参数 a1: 内核栈的栈底 (最高地址，kstack + KSTACKSIZE)
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f12:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc0>
    // 往低地址移动 36 个寄存器的大小，腾出空间放新的 TrapFrame

    // 用 s1 做搬运工，把 a0 (旧地址) 里的寄存器值，一个个搬到 a1 (新地址)。
    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f16:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f1a:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f1e:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f22:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f26:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f2a:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f2e:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f32:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f36:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f38:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f3a:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f3c:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f3e:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f40:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f42:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f44:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f46:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f48:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f4a:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f4c:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f4e:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f50:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f52:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f54:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f56:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f58:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f5a:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f5c:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f5e:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f60:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f62:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f64:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f66:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f68:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f6a:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f6c:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f6e:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f70:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f72:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f74:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f76:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f78:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f7a:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f7c:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f7e:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f80:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f82:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f84:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f86:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f88:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f8a:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f8c:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f8e:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f90:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f92:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f94:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f96:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f98:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f9a:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f9c:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f9e:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200fa0:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200fa2:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200fa4:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200fa6:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200fa8:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200faa:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200fac:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200fae:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200fb0:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200fb2:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200fb4:	e184                	sd	s1,0(a1)

    // 把 sp 指向这个位于栈顶的、全新的 TrapFrame
    // acutually adjust sp
    move sp, a1
ffffffffc0200fb6:	812e                	mv	sp,a1
    j __trapret
ffffffffc0200fb8:	bdf5                	j	ffffffffc0200eb4 <__trapret>

ffffffffc0200fba <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200fba:	000a5797          	auipc	a5,0xa5
ffffffffc0200fbe:	68678793          	addi	a5,a5,1670 # ffffffffc02a6640 <free_area>
ffffffffc0200fc2:	e79c                	sd	a5,8(a5)
ffffffffc0200fc4:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200fc6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fca:	8082                	ret

ffffffffc0200fcc <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fcc:	000a5517          	auipc	a0,0xa5
ffffffffc0200fd0:	68456503          	lwu	a0,1668(a0) # ffffffffc02a6650 <free_area+0x10>
ffffffffc0200fd4:	8082                	ret

ffffffffc0200fd6 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200fd6:	715d                	addi	sp,sp,-80
ffffffffc0200fd8:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fda:	000a5417          	auipc	s0,0xa5
ffffffffc0200fde:	66640413          	addi	s0,s0,1638 # ffffffffc02a6640 <free_area>
ffffffffc0200fe2:	641c                	ld	a5,8(s0)
ffffffffc0200fe4:	e486                	sd	ra,72(sp)
ffffffffc0200fe6:	fc26                	sd	s1,56(sp)
ffffffffc0200fe8:	f84a                	sd	s2,48(sp)
ffffffffc0200fea:	f44e                	sd	s3,40(sp)
ffffffffc0200fec:	f052                	sd	s4,32(sp)
ffffffffc0200fee:	ec56                	sd	s5,24(sp)
ffffffffc0200ff0:	e85a                	sd	s6,16(sp)
ffffffffc0200ff2:	e45e                	sd	s7,8(sp)
ffffffffc0200ff4:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ff6:	2a878d63          	beq	a5,s0,ffffffffc02012b0 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200ffa:	4481                	li	s1,0
ffffffffc0200ffc:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ffe:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201002:	8b09                	andi	a4,a4,2
ffffffffc0201004:	2a070a63          	beqz	a4,ffffffffc02012b8 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0201008:	ff87a703          	lw	a4,-8(a5)
ffffffffc020100c:	679c                	ld	a5,8(a5)
ffffffffc020100e:	2905                	addiw	s2,s2,1
ffffffffc0201010:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201012:	fe8796e3          	bne	a5,s0,ffffffffc0200ffe <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201016:	89a6                	mv	s3,s1
ffffffffc0201018:	6df000ef          	jal	ra,ffffffffc0201ef6 <nr_free_pages>
ffffffffc020101c:	6f351e63          	bne	a0,s3,ffffffffc0201718 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201020:	4505                	li	a0,1
ffffffffc0201022:	657000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc0201026:	8aaa                	mv	s5,a0
ffffffffc0201028:	42050863          	beqz	a0,ffffffffc0201458 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020102c:	4505                	li	a0,1
ffffffffc020102e:	64b000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc0201032:	89aa                	mv	s3,a0
ffffffffc0201034:	70050263          	beqz	a0,ffffffffc0201738 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201038:	4505                	li	a0,1
ffffffffc020103a:	63f000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020103e:	8a2a                	mv	s4,a0
ffffffffc0201040:	48050c63          	beqz	a0,ffffffffc02014d8 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201044:	293a8a63          	beq	s5,s3,ffffffffc02012d8 <default_check+0x302>
ffffffffc0201048:	28aa8863          	beq	s5,a0,ffffffffc02012d8 <default_check+0x302>
ffffffffc020104c:	28a98663          	beq	s3,a0,ffffffffc02012d8 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201050:	000aa783          	lw	a5,0(s5)
ffffffffc0201054:	2a079263          	bnez	a5,ffffffffc02012f8 <default_check+0x322>
ffffffffc0201058:	0009a783          	lw	a5,0(s3)
ffffffffc020105c:	28079e63          	bnez	a5,ffffffffc02012f8 <default_check+0x322>
ffffffffc0201060:	411c                	lw	a5,0(a0)
ffffffffc0201062:	28079b63          	bnez	a5,ffffffffc02012f8 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201066:	000a9797          	auipc	a5,0xa9
ffffffffc020106a:	64a7b783          	ld	a5,1610(a5) # ffffffffc02aa6b0 <pages>
ffffffffc020106e:	40fa8733          	sub	a4,s5,a5
ffffffffc0201072:	00006617          	auipc	a2,0x6
ffffffffc0201076:	7be63603          	ld	a2,1982(a2) # ffffffffc0207830 <nbase>
ffffffffc020107a:	8719                	srai	a4,a4,0x6
ffffffffc020107c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020107e:	000a9697          	auipc	a3,0xa9
ffffffffc0201082:	62a6b683          	ld	a3,1578(a3) # ffffffffc02aa6a8 <npage>
ffffffffc0201086:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201088:	0732                	slli	a4,a4,0xc
ffffffffc020108a:	28d77763          	bgeu	a4,a3,ffffffffc0201318 <default_check+0x342>
    return page - pages + nbase;
ffffffffc020108e:	40f98733          	sub	a4,s3,a5
ffffffffc0201092:	8719                	srai	a4,a4,0x6
ffffffffc0201094:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201096:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201098:	4cd77063          	bgeu	a4,a3,ffffffffc0201558 <default_check+0x582>
    return page - pages + nbase;
ffffffffc020109c:	40f507b3          	sub	a5,a0,a5
ffffffffc02010a0:	8799                	srai	a5,a5,0x6
ffffffffc02010a2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010a4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010a6:	30d7f963          	bgeu	a5,a3,ffffffffc02013b8 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02010aa:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010ac:	00043c03          	ld	s8,0(s0)
ffffffffc02010b0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02010b4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02010b8:	e400                	sd	s0,8(s0)
ffffffffc02010ba:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010bc:	000a5797          	auipc	a5,0xa5
ffffffffc02010c0:	5807aa23          	sw	zero,1428(a5) # ffffffffc02a6650 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010c4:	5b5000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc02010c8:	2c051863          	bnez	a0,ffffffffc0201398 <default_check+0x3c2>
    free_page(p0);
ffffffffc02010cc:	4585                	li	a1,1
ffffffffc02010ce:	8556                	mv	a0,s5
ffffffffc02010d0:	5e7000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    free_page(p1);
ffffffffc02010d4:	4585                	li	a1,1
ffffffffc02010d6:	854e                	mv	a0,s3
ffffffffc02010d8:	5df000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    free_page(p2);
ffffffffc02010dc:	4585                	li	a1,1
ffffffffc02010de:	8552                	mv	a0,s4
ffffffffc02010e0:	5d7000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    assert(nr_free == 3);
ffffffffc02010e4:	4818                	lw	a4,16(s0)
ffffffffc02010e6:	478d                	li	a5,3
ffffffffc02010e8:	28f71863          	bne	a4,a5,ffffffffc0201378 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010ec:	4505                	li	a0,1
ffffffffc02010ee:	58b000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc02010f2:	89aa                	mv	s3,a0
ffffffffc02010f4:	26050263          	beqz	a0,ffffffffc0201358 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010f8:	4505                	li	a0,1
ffffffffc02010fa:	57f000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc02010fe:	8aaa                	mv	s5,a0
ffffffffc0201100:	3a050c63          	beqz	a0,ffffffffc02014b8 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201104:	4505                	li	a0,1
ffffffffc0201106:	573000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020110a:	8a2a                	mv	s4,a0
ffffffffc020110c:	38050663          	beqz	a0,ffffffffc0201498 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201110:	4505                	li	a0,1
ffffffffc0201112:	567000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc0201116:	36051163          	bnez	a0,ffffffffc0201478 <default_check+0x4a2>
    free_page(p0);
ffffffffc020111a:	4585                	li	a1,1
ffffffffc020111c:	854e                	mv	a0,s3
ffffffffc020111e:	599000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201122:	641c                	ld	a5,8(s0)
ffffffffc0201124:	20878a63          	beq	a5,s0,ffffffffc0201338 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201128:	4505                	li	a0,1
ffffffffc020112a:	54f000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020112e:	30a99563          	bne	s3,a0,ffffffffc0201438 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201132:	4505                	li	a0,1
ffffffffc0201134:	545000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc0201138:	2e051063          	bnez	a0,ffffffffc0201418 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020113c:	481c                	lw	a5,16(s0)
ffffffffc020113e:	2a079d63          	bnez	a5,ffffffffc02013f8 <default_check+0x422>
    free_page(p);
ffffffffc0201142:	854e                	mv	a0,s3
ffffffffc0201144:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201146:	01843023          	sd	s8,0(s0)
ffffffffc020114a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020114e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201152:	565000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    free_page(p1);
ffffffffc0201156:	4585                	li	a1,1
ffffffffc0201158:	8556                	mv	a0,s5
ffffffffc020115a:	55d000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    free_page(p2);
ffffffffc020115e:	4585                	li	a1,1
ffffffffc0201160:	8552                	mv	a0,s4
ffffffffc0201162:	555000ef          	jal	ra,ffffffffc0201eb6 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201166:	4515                	li	a0,5
ffffffffc0201168:	511000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020116c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020116e:	26050563          	beqz	a0,ffffffffc02013d8 <default_check+0x402>
ffffffffc0201172:	651c                	ld	a5,8(a0)
ffffffffc0201174:	8385                	srli	a5,a5,0x1
ffffffffc0201176:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201178:	54079063          	bnez	a5,ffffffffc02016b8 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020117c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020117e:	00043b03          	ld	s6,0(s0)
ffffffffc0201182:	00843a83          	ld	s5,8(s0)
ffffffffc0201186:	e000                	sd	s0,0(s0)
ffffffffc0201188:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020118a:	4ef000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020118e:	50051563          	bnez	a0,ffffffffc0201698 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201192:	08098a13          	addi	s4,s3,128
ffffffffc0201196:	8552                	mv	a0,s4
ffffffffc0201198:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020119a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020119e:	000a5797          	auipc	a5,0xa5
ffffffffc02011a2:	4a07a923          	sw	zero,1202(a5) # ffffffffc02a6650 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011a6:	511000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011aa:	4511                	li	a0,4
ffffffffc02011ac:	4cd000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc02011b0:	4c051463          	bnez	a0,ffffffffc0201678 <default_check+0x6a2>
ffffffffc02011b4:	0889b783          	ld	a5,136(s3)
ffffffffc02011b8:	8385                	srli	a5,a5,0x1
ffffffffc02011ba:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011bc:	48078e63          	beqz	a5,ffffffffc0201658 <default_check+0x682>
ffffffffc02011c0:	0909a703          	lw	a4,144(s3)
ffffffffc02011c4:	478d                	li	a5,3
ffffffffc02011c6:	48f71963          	bne	a4,a5,ffffffffc0201658 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011ca:	450d                	li	a0,3
ffffffffc02011cc:	4ad000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc02011d0:	8c2a                	mv	s8,a0
ffffffffc02011d2:	46050363          	beqz	a0,ffffffffc0201638 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02011d6:	4505                	li	a0,1
ffffffffc02011d8:	4a1000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc02011dc:	42051e63          	bnez	a0,ffffffffc0201618 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02011e0:	418a1c63          	bne	s4,s8,ffffffffc02015f8 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011e4:	4585                	li	a1,1
ffffffffc02011e6:	854e                	mv	a0,s3
ffffffffc02011e8:	4cf000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    free_pages(p1, 3);
ffffffffc02011ec:	458d                	li	a1,3
ffffffffc02011ee:	8552                	mv	a0,s4
ffffffffc02011f0:	4c7000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
ffffffffc02011f4:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02011f8:	04098c13          	addi	s8,s3,64
ffffffffc02011fc:	8385                	srli	a5,a5,0x1
ffffffffc02011fe:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201200:	3c078c63          	beqz	a5,ffffffffc02015d8 <default_check+0x602>
ffffffffc0201204:	0109a703          	lw	a4,16(s3)
ffffffffc0201208:	4785                	li	a5,1
ffffffffc020120a:	3cf71763          	bne	a4,a5,ffffffffc02015d8 <default_check+0x602>
ffffffffc020120e:	008a3783          	ld	a5,8(s4)
ffffffffc0201212:	8385                	srli	a5,a5,0x1
ffffffffc0201214:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201216:	3a078163          	beqz	a5,ffffffffc02015b8 <default_check+0x5e2>
ffffffffc020121a:	010a2703          	lw	a4,16(s4)
ffffffffc020121e:	478d                	li	a5,3
ffffffffc0201220:	38f71c63          	bne	a4,a5,ffffffffc02015b8 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201224:	4505                	li	a0,1
ffffffffc0201226:	453000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020122a:	36a99763          	bne	s3,a0,ffffffffc0201598 <default_check+0x5c2>
    free_page(p0);
ffffffffc020122e:	4585                	li	a1,1
ffffffffc0201230:	487000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201234:	4509                	li	a0,2
ffffffffc0201236:	443000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020123a:	32aa1f63          	bne	s4,a0,ffffffffc0201578 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020123e:	4589                	li	a1,2
ffffffffc0201240:	477000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    free_page(p2);
ffffffffc0201244:	4585                	li	a1,1
ffffffffc0201246:	8562                	mv	a0,s8
ffffffffc0201248:	46f000ef          	jal	ra,ffffffffc0201eb6 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020124c:	4515                	li	a0,5
ffffffffc020124e:	42b000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc0201252:	89aa                	mv	s3,a0
ffffffffc0201254:	48050263          	beqz	a0,ffffffffc02016d8 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201258:	4505                	li	a0,1
ffffffffc020125a:	41f000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020125e:	2c051d63          	bnez	a0,ffffffffc0201538 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201262:	481c                	lw	a5,16(s0)
ffffffffc0201264:	2a079a63          	bnez	a5,ffffffffc0201518 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201268:	4595                	li	a1,5
ffffffffc020126a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020126c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201270:	01643023          	sd	s6,0(s0)
ffffffffc0201274:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201278:	43f000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    return listelm->next;
ffffffffc020127c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020127e:	00878963          	beq	a5,s0,ffffffffc0201290 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201282:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201286:	679c                	ld	a5,8(a5)
ffffffffc0201288:	397d                	addiw	s2,s2,-1
ffffffffc020128a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020128c:	fe879be3          	bne	a5,s0,ffffffffc0201282 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201290:	26091463          	bnez	s2,ffffffffc02014f8 <default_check+0x522>
    assert(total == 0);
ffffffffc0201294:	46049263          	bnez	s1,ffffffffc02016f8 <default_check+0x722>
}
ffffffffc0201298:	60a6                	ld	ra,72(sp)
ffffffffc020129a:	6406                	ld	s0,64(sp)
ffffffffc020129c:	74e2                	ld	s1,56(sp)
ffffffffc020129e:	7942                	ld	s2,48(sp)
ffffffffc02012a0:	79a2                	ld	s3,40(sp)
ffffffffc02012a2:	7a02                	ld	s4,32(sp)
ffffffffc02012a4:	6ae2                	ld	s5,24(sp)
ffffffffc02012a6:	6b42                	ld	s6,16(sp)
ffffffffc02012a8:	6ba2                	ld	s7,8(sp)
ffffffffc02012aa:	6c02                	ld	s8,0(sp)
ffffffffc02012ac:	6161                	addi	sp,sp,80
ffffffffc02012ae:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02012b0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02012b2:	4481                	li	s1,0
ffffffffc02012b4:	4901                	li	s2,0
ffffffffc02012b6:	b38d                	j	ffffffffc0201018 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02012b8:	00005697          	auipc	a3,0x5
ffffffffc02012bc:	e9068693          	addi	a3,a3,-368 # ffffffffc0206148 <commands+0x808>
ffffffffc02012c0:	00005617          	auipc	a2,0x5
ffffffffc02012c4:	e9860613          	addi	a2,a2,-360 # ffffffffc0206158 <commands+0x818>
ffffffffc02012c8:	11000593          	li	a1,272
ffffffffc02012cc:	00005517          	auipc	a0,0x5
ffffffffc02012d0:	ea450513          	addi	a0,a0,-348 # ffffffffc0206170 <commands+0x830>
ffffffffc02012d4:	9baff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012d8:	00005697          	auipc	a3,0x5
ffffffffc02012dc:	f3068693          	addi	a3,a3,-208 # ffffffffc0206208 <commands+0x8c8>
ffffffffc02012e0:	00005617          	auipc	a2,0x5
ffffffffc02012e4:	e7860613          	addi	a2,a2,-392 # ffffffffc0206158 <commands+0x818>
ffffffffc02012e8:	0db00593          	li	a1,219
ffffffffc02012ec:	00005517          	auipc	a0,0x5
ffffffffc02012f0:	e8450513          	addi	a0,a0,-380 # ffffffffc0206170 <commands+0x830>
ffffffffc02012f4:	99aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012f8:	00005697          	auipc	a3,0x5
ffffffffc02012fc:	f3868693          	addi	a3,a3,-200 # ffffffffc0206230 <commands+0x8f0>
ffffffffc0201300:	00005617          	auipc	a2,0x5
ffffffffc0201304:	e5860613          	addi	a2,a2,-424 # ffffffffc0206158 <commands+0x818>
ffffffffc0201308:	0dc00593          	li	a1,220
ffffffffc020130c:	00005517          	auipc	a0,0x5
ffffffffc0201310:	e6450513          	addi	a0,a0,-412 # ffffffffc0206170 <commands+0x830>
ffffffffc0201314:	97aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201318:	00005697          	auipc	a3,0x5
ffffffffc020131c:	f5868693          	addi	a3,a3,-168 # ffffffffc0206270 <commands+0x930>
ffffffffc0201320:	00005617          	auipc	a2,0x5
ffffffffc0201324:	e3860613          	addi	a2,a2,-456 # ffffffffc0206158 <commands+0x818>
ffffffffc0201328:	0de00593          	li	a1,222
ffffffffc020132c:	00005517          	auipc	a0,0x5
ffffffffc0201330:	e4450513          	addi	a0,a0,-444 # ffffffffc0206170 <commands+0x830>
ffffffffc0201334:	95aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201338:	00005697          	auipc	a3,0x5
ffffffffc020133c:	fc068693          	addi	a3,a3,-64 # ffffffffc02062f8 <commands+0x9b8>
ffffffffc0201340:	00005617          	auipc	a2,0x5
ffffffffc0201344:	e1860613          	addi	a2,a2,-488 # ffffffffc0206158 <commands+0x818>
ffffffffc0201348:	0f700593          	li	a1,247
ffffffffc020134c:	00005517          	auipc	a0,0x5
ffffffffc0201350:	e2450513          	addi	a0,a0,-476 # ffffffffc0206170 <commands+0x830>
ffffffffc0201354:	93aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201358:	00005697          	auipc	a3,0x5
ffffffffc020135c:	e5068693          	addi	a3,a3,-432 # ffffffffc02061a8 <commands+0x868>
ffffffffc0201360:	00005617          	auipc	a2,0x5
ffffffffc0201364:	df860613          	addi	a2,a2,-520 # ffffffffc0206158 <commands+0x818>
ffffffffc0201368:	0f000593          	li	a1,240
ffffffffc020136c:	00005517          	auipc	a0,0x5
ffffffffc0201370:	e0450513          	addi	a0,a0,-508 # ffffffffc0206170 <commands+0x830>
ffffffffc0201374:	91aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc0201378:	00005697          	auipc	a3,0x5
ffffffffc020137c:	f7068693          	addi	a3,a3,-144 # ffffffffc02062e8 <commands+0x9a8>
ffffffffc0201380:	00005617          	auipc	a2,0x5
ffffffffc0201384:	dd860613          	addi	a2,a2,-552 # ffffffffc0206158 <commands+0x818>
ffffffffc0201388:	0ee00593          	li	a1,238
ffffffffc020138c:	00005517          	auipc	a0,0x5
ffffffffc0201390:	de450513          	addi	a0,a0,-540 # ffffffffc0206170 <commands+0x830>
ffffffffc0201394:	8faff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201398:	00005697          	auipc	a3,0x5
ffffffffc020139c:	f3868693          	addi	a3,a3,-200 # ffffffffc02062d0 <commands+0x990>
ffffffffc02013a0:	00005617          	auipc	a2,0x5
ffffffffc02013a4:	db860613          	addi	a2,a2,-584 # ffffffffc0206158 <commands+0x818>
ffffffffc02013a8:	0e900593          	li	a1,233
ffffffffc02013ac:	00005517          	auipc	a0,0x5
ffffffffc02013b0:	dc450513          	addi	a0,a0,-572 # ffffffffc0206170 <commands+0x830>
ffffffffc02013b4:	8daff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02013b8:	00005697          	auipc	a3,0x5
ffffffffc02013bc:	ef868693          	addi	a3,a3,-264 # ffffffffc02062b0 <commands+0x970>
ffffffffc02013c0:	00005617          	auipc	a2,0x5
ffffffffc02013c4:	d9860613          	addi	a2,a2,-616 # ffffffffc0206158 <commands+0x818>
ffffffffc02013c8:	0e000593          	li	a1,224
ffffffffc02013cc:	00005517          	auipc	a0,0x5
ffffffffc02013d0:	da450513          	addi	a0,a0,-604 # ffffffffc0206170 <commands+0x830>
ffffffffc02013d4:	8baff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02013d8:	00005697          	auipc	a3,0x5
ffffffffc02013dc:	f6868693          	addi	a3,a3,-152 # ffffffffc0206340 <commands+0xa00>
ffffffffc02013e0:	00005617          	auipc	a2,0x5
ffffffffc02013e4:	d7860613          	addi	a2,a2,-648 # ffffffffc0206158 <commands+0x818>
ffffffffc02013e8:	11800593          	li	a1,280
ffffffffc02013ec:	00005517          	auipc	a0,0x5
ffffffffc02013f0:	d8450513          	addi	a0,a0,-636 # ffffffffc0206170 <commands+0x830>
ffffffffc02013f4:	89aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02013f8:	00005697          	auipc	a3,0x5
ffffffffc02013fc:	f3868693          	addi	a3,a3,-200 # ffffffffc0206330 <commands+0x9f0>
ffffffffc0201400:	00005617          	auipc	a2,0x5
ffffffffc0201404:	d5860613          	addi	a2,a2,-680 # ffffffffc0206158 <commands+0x818>
ffffffffc0201408:	0fd00593          	li	a1,253
ffffffffc020140c:	00005517          	auipc	a0,0x5
ffffffffc0201410:	d6450513          	addi	a0,a0,-668 # ffffffffc0206170 <commands+0x830>
ffffffffc0201414:	87aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201418:	00005697          	auipc	a3,0x5
ffffffffc020141c:	eb868693          	addi	a3,a3,-328 # ffffffffc02062d0 <commands+0x990>
ffffffffc0201420:	00005617          	auipc	a2,0x5
ffffffffc0201424:	d3860613          	addi	a2,a2,-712 # ffffffffc0206158 <commands+0x818>
ffffffffc0201428:	0fb00593          	li	a1,251
ffffffffc020142c:	00005517          	auipc	a0,0x5
ffffffffc0201430:	d4450513          	addi	a0,a0,-700 # ffffffffc0206170 <commands+0x830>
ffffffffc0201434:	85aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201438:	00005697          	auipc	a3,0x5
ffffffffc020143c:	ed868693          	addi	a3,a3,-296 # ffffffffc0206310 <commands+0x9d0>
ffffffffc0201440:	00005617          	auipc	a2,0x5
ffffffffc0201444:	d1860613          	addi	a2,a2,-744 # ffffffffc0206158 <commands+0x818>
ffffffffc0201448:	0fa00593          	li	a1,250
ffffffffc020144c:	00005517          	auipc	a0,0x5
ffffffffc0201450:	d2450513          	addi	a0,a0,-732 # ffffffffc0206170 <commands+0x830>
ffffffffc0201454:	83aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201458:	00005697          	auipc	a3,0x5
ffffffffc020145c:	d5068693          	addi	a3,a3,-688 # ffffffffc02061a8 <commands+0x868>
ffffffffc0201460:	00005617          	auipc	a2,0x5
ffffffffc0201464:	cf860613          	addi	a2,a2,-776 # ffffffffc0206158 <commands+0x818>
ffffffffc0201468:	0d700593          	li	a1,215
ffffffffc020146c:	00005517          	auipc	a0,0x5
ffffffffc0201470:	d0450513          	addi	a0,a0,-764 # ffffffffc0206170 <commands+0x830>
ffffffffc0201474:	81aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201478:	00005697          	auipc	a3,0x5
ffffffffc020147c:	e5868693          	addi	a3,a3,-424 # ffffffffc02062d0 <commands+0x990>
ffffffffc0201480:	00005617          	auipc	a2,0x5
ffffffffc0201484:	cd860613          	addi	a2,a2,-808 # ffffffffc0206158 <commands+0x818>
ffffffffc0201488:	0f400593          	li	a1,244
ffffffffc020148c:	00005517          	auipc	a0,0x5
ffffffffc0201490:	ce450513          	addi	a0,a0,-796 # ffffffffc0206170 <commands+0x830>
ffffffffc0201494:	ffbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201498:	00005697          	auipc	a3,0x5
ffffffffc020149c:	d5068693          	addi	a3,a3,-688 # ffffffffc02061e8 <commands+0x8a8>
ffffffffc02014a0:	00005617          	auipc	a2,0x5
ffffffffc02014a4:	cb860613          	addi	a2,a2,-840 # ffffffffc0206158 <commands+0x818>
ffffffffc02014a8:	0f200593          	li	a1,242
ffffffffc02014ac:	00005517          	auipc	a0,0x5
ffffffffc02014b0:	cc450513          	addi	a0,a0,-828 # ffffffffc0206170 <commands+0x830>
ffffffffc02014b4:	fdbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014b8:	00005697          	auipc	a3,0x5
ffffffffc02014bc:	d1068693          	addi	a3,a3,-752 # ffffffffc02061c8 <commands+0x888>
ffffffffc02014c0:	00005617          	auipc	a2,0x5
ffffffffc02014c4:	c9860613          	addi	a2,a2,-872 # ffffffffc0206158 <commands+0x818>
ffffffffc02014c8:	0f100593          	li	a1,241
ffffffffc02014cc:	00005517          	auipc	a0,0x5
ffffffffc02014d0:	ca450513          	addi	a0,a0,-860 # ffffffffc0206170 <commands+0x830>
ffffffffc02014d4:	fbbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014d8:	00005697          	auipc	a3,0x5
ffffffffc02014dc:	d1068693          	addi	a3,a3,-752 # ffffffffc02061e8 <commands+0x8a8>
ffffffffc02014e0:	00005617          	auipc	a2,0x5
ffffffffc02014e4:	c7860613          	addi	a2,a2,-904 # ffffffffc0206158 <commands+0x818>
ffffffffc02014e8:	0d900593          	li	a1,217
ffffffffc02014ec:	00005517          	auipc	a0,0x5
ffffffffc02014f0:	c8450513          	addi	a0,a0,-892 # ffffffffc0206170 <commands+0x830>
ffffffffc02014f4:	f9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02014f8:	00005697          	auipc	a3,0x5
ffffffffc02014fc:	f9868693          	addi	a3,a3,-104 # ffffffffc0206490 <commands+0xb50>
ffffffffc0201500:	00005617          	auipc	a2,0x5
ffffffffc0201504:	c5860613          	addi	a2,a2,-936 # ffffffffc0206158 <commands+0x818>
ffffffffc0201508:	14600593          	li	a1,326
ffffffffc020150c:	00005517          	auipc	a0,0x5
ffffffffc0201510:	c6450513          	addi	a0,a0,-924 # ffffffffc0206170 <commands+0x830>
ffffffffc0201514:	f7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201518:	00005697          	auipc	a3,0x5
ffffffffc020151c:	e1868693          	addi	a3,a3,-488 # ffffffffc0206330 <commands+0x9f0>
ffffffffc0201520:	00005617          	auipc	a2,0x5
ffffffffc0201524:	c3860613          	addi	a2,a2,-968 # ffffffffc0206158 <commands+0x818>
ffffffffc0201528:	13a00593          	li	a1,314
ffffffffc020152c:	00005517          	auipc	a0,0x5
ffffffffc0201530:	c4450513          	addi	a0,a0,-956 # ffffffffc0206170 <commands+0x830>
ffffffffc0201534:	f5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201538:	00005697          	auipc	a3,0x5
ffffffffc020153c:	d9868693          	addi	a3,a3,-616 # ffffffffc02062d0 <commands+0x990>
ffffffffc0201540:	00005617          	auipc	a2,0x5
ffffffffc0201544:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206158 <commands+0x818>
ffffffffc0201548:	13800593          	li	a1,312
ffffffffc020154c:	00005517          	auipc	a0,0x5
ffffffffc0201550:	c2450513          	addi	a0,a0,-988 # ffffffffc0206170 <commands+0x830>
ffffffffc0201554:	f3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201558:	00005697          	auipc	a3,0x5
ffffffffc020155c:	d3868693          	addi	a3,a3,-712 # ffffffffc0206290 <commands+0x950>
ffffffffc0201560:	00005617          	auipc	a2,0x5
ffffffffc0201564:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206158 <commands+0x818>
ffffffffc0201568:	0df00593          	li	a1,223
ffffffffc020156c:	00005517          	auipc	a0,0x5
ffffffffc0201570:	c0450513          	addi	a0,a0,-1020 # ffffffffc0206170 <commands+0x830>
ffffffffc0201574:	f1bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201578:	00005697          	auipc	a3,0x5
ffffffffc020157c:	ed868693          	addi	a3,a3,-296 # ffffffffc0206450 <commands+0xb10>
ffffffffc0201580:	00005617          	auipc	a2,0x5
ffffffffc0201584:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206158 <commands+0x818>
ffffffffc0201588:	13200593          	li	a1,306
ffffffffc020158c:	00005517          	auipc	a0,0x5
ffffffffc0201590:	be450513          	addi	a0,a0,-1052 # ffffffffc0206170 <commands+0x830>
ffffffffc0201594:	efbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201598:	00005697          	auipc	a3,0x5
ffffffffc020159c:	e9868693          	addi	a3,a3,-360 # ffffffffc0206430 <commands+0xaf0>
ffffffffc02015a0:	00005617          	auipc	a2,0x5
ffffffffc02015a4:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206158 <commands+0x818>
ffffffffc02015a8:	13000593          	li	a1,304
ffffffffc02015ac:	00005517          	auipc	a0,0x5
ffffffffc02015b0:	bc450513          	addi	a0,a0,-1084 # ffffffffc0206170 <commands+0x830>
ffffffffc02015b4:	edbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02015b8:	00005697          	auipc	a3,0x5
ffffffffc02015bc:	e5068693          	addi	a3,a3,-432 # ffffffffc0206408 <commands+0xac8>
ffffffffc02015c0:	00005617          	auipc	a2,0x5
ffffffffc02015c4:	b9860613          	addi	a2,a2,-1128 # ffffffffc0206158 <commands+0x818>
ffffffffc02015c8:	12e00593          	li	a1,302
ffffffffc02015cc:	00005517          	auipc	a0,0x5
ffffffffc02015d0:	ba450513          	addi	a0,a0,-1116 # ffffffffc0206170 <commands+0x830>
ffffffffc02015d4:	ebbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015d8:	00005697          	auipc	a3,0x5
ffffffffc02015dc:	e0868693          	addi	a3,a3,-504 # ffffffffc02063e0 <commands+0xaa0>
ffffffffc02015e0:	00005617          	auipc	a2,0x5
ffffffffc02015e4:	b7860613          	addi	a2,a2,-1160 # ffffffffc0206158 <commands+0x818>
ffffffffc02015e8:	12d00593          	li	a1,301
ffffffffc02015ec:	00005517          	auipc	a0,0x5
ffffffffc02015f0:	b8450513          	addi	a0,a0,-1148 # ffffffffc0206170 <commands+0x830>
ffffffffc02015f4:	e9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015f8:	00005697          	auipc	a3,0x5
ffffffffc02015fc:	dd868693          	addi	a3,a3,-552 # ffffffffc02063d0 <commands+0xa90>
ffffffffc0201600:	00005617          	auipc	a2,0x5
ffffffffc0201604:	b5860613          	addi	a2,a2,-1192 # ffffffffc0206158 <commands+0x818>
ffffffffc0201608:	12800593          	li	a1,296
ffffffffc020160c:	00005517          	auipc	a0,0x5
ffffffffc0201610:	b6450513          	addi	a0,a0,-1180 # ffffffffc0206170 <commands+0x830>
ffffffffc0201614:	e7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201618:	00005697          	auipc	a3,0x5
ffffffffc020161c:	cb868693          	addi	a3,a3,-840 # ffffffffc02062d0 <commands+0x990>
ffffffffc0201620:	00005617          	auipc	a2,0x5
ffffffffc0201624:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206158 <commands+0x818>
ffffffffc0201628:	12700593          	li	a1,295
ffffffffc020162c:	00005517          	auipc	a0,0x5
ffffffffc0201630:	b4450513          	addi	a0,a0,-1212 # ffffffffc0206170 <commands+0x830>
ffffffffc0201634:	e5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201638:	00005697          	auipc	a3,0x5
ffffffffc020163c:	d7868693          	addi	a3,a3,-648 # ffffffffc02063b0 <commands+0xa70>
ffffffffc0201640:	00005617          	auipc	a2,0x5
ffffffffc0201644:	b1860613          	addi	a2,a2,-1256 # ffffffffc0206158 <commands+0x818>
ffffffffc0201648:	12600593          	li	a1,294
ffffffffc020164c:	00005517          	auipc	a0,0x5
ffffffffc0201650:	b2450513          	addi	a0,a0,-1244 # ffffffffc0206170 <commands+0x830>
ffffffffc0201654:	e3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201658:	00005697          	auipc	a3,0x5
ffffffffc020165c:	d2868693          	addi	a3,a3,-728 # ffffffffc0206380 <commands+0xa40>
ffffffffc0201660:	00005617          	auipc	a2,0x5
ffffffffc0201664:	af860613          	addi	a2,a2,-1288 # ffffffffc0206158 <commands+0x818>
ffffffffc0201668:	12500593          	li	a1,293
ffffffffc020166c:	00005517          	auipc	a0,0x5
ffffffffc0201670:	b0450513          	addi	a0,a0,-1276 # ffffffffc0206170 <commands+0x830>
ffffffffc0201674:	e1bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201678:	00005697          	auipc	a3,0x5
ffffffffc020167c:	cf068693          	addi	a3,a3,-784 # ffffffffc0206368 <commands+0xa28>
ffffffffc0201680:	00005617          	auipc	a2,0x5
ffffffffc0201684:	ad860613          	addi	a2,a2,-1320 # ffffffffc0206158 <commands+0x818>
ffffffffc0201688:	12400593          	li	a1,292
ffffffffc020168c:	00005517          	auipc	a0,0x5
ffffffffc0201690:	ae450513          	addi	a0,a0,-1308 # ffffffffc0206170 <commands+0x830>
ffffffffc0201694:	dfbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201698:	00005697          	auipc	a3,0x5
ffffffffc020169c:	c3868693          	addi	a3,a3,-968 # ffffffffc02062d0 <commands+0x990>
ffffffffc02016a0:	00005617          	auipc	a2,0x5
ffffffffc02016a4:	ab860613          	addi	a2,a2,-1352 # ffffffffc0206158 <commands+0x818>
ffffffffc02016a8:	11e00593          	li	a1,286
ffffffffc02016ac:	00005517          	auipc	a0,0x5
ffffffffc02016b0:	ac450513          	addi	a0,a0,-1340 # ffffffffc0206170 <commands+0x830>
ffffffffc02016b4:	ddbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc02016b8:	00005697          	auipc	a3,0x5
ffffffffc02016bc:	c9868693          	addi	a3,a3,-872 # ffffffffc0206350 <commands+0xa10>
ffffffffc02016c0:	00005617          	auipc	a2,0x5
ffffffffc02016c4:	a9860613          	addi	a2,a2,-1384 # ffffffffc0206158 <commands+0x818>
ffffffffc02016c8:	11900593          	li	a1,281
ffffffffc02016cc:	00005517          	auipc	a0,0x5
ffffffffc02016d0:	aa450513          	addi	a0,a0,-1372 # ffffffffc0206170 <commands+0x830>
ffffffffc02016d4:	dbbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016d8:	00005697          	auipc	a3,0x5
ffffffffc02016dc:	d9868693          	addi	a3,a3,-616 # ffffffffc0206470 <commands+0xb30>
ffffffffc02016e0:	00005617          	auipc	a2,0x5
ffffffffc02016e4:	a7860613          	addi	a2,a2,-1416 # ffffffffc0206158 <commands+0x818>
ffffffffc02016e8:	13700593          	li	a1,311
ffffffffc02016ec:	00005517          	auipc	a0,0x5
ffffffffc02016f0:	a8450513          	addi	a0,a0,-1404 # ffffffffc0206170 <commands+0x830>
ffffffffc02016f4:	d9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02016f8:	00005697          	auipc	a3,0x5
ffffffffc02016fc:	da868693          	addi	a3,a3,-600 # ffffffffc02064a0 <commands+0xb60>
ffffffffc0201700:	00005617          	auipc	a2,0x5
ffffffffc0201704:	a5860613          	addi	a2,a2,-1448 # ffffffffc0206158 <commands+0x818>
ffffffffc0201708:	14700593          	li	a1,327
ffffffffc020170c:	00005517          	auipc	a0,0x5
ffffffffc0201710:	a6450513          	addi	a0,a0,-1436 # ffffffffc0206170 <commands+0x830>
ffffffffc0201714:	d7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc0201718:	00005697          	auipc	a3,0x5
ffffffffc020171c:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206188 <commands+0x848>
ffffffffc0201720:	00005617          	auipc	a2,0x5
ffffffffc0201724:	a3860613          	addi	a2,a2,-1480 # ffffffffc0206158 <commands+0x818>
ffffffffc0201728:	11300593          	li	a1,275
ffffffffc020172c:	00005517          	auipc	a0,0x5
ffffffffc0201730:	a4450513          	addi	a0,a0,-1468 # ffffffffc0206170 <commands+0x830>
ffffffffc0201734:	d5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201738:	00005697          	auipc	a3,0x5
ffffffffc020173c:	a9068693          	addi	a3,a3,-1392 # ffffffffc02061c8 <commands+0x888>
ffffffffc0201740:	00005617          	auipc	a2,0x5
ffffffffc0201744:	a1860613          	addi	a2,a2,-1512 # ffffffffc0206158 <commands+0x818>
ffffffffc0201748:	0d800593          	li	a1,216
ffffffffc020174c:	00005517          	auipc	a0,0x5
ffffffffc0201750:	a2450513          	addi	a0,a0,-1500 # ffffffffc0206170 <commands+0x830>
ffffffffc0201754:	d3bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201758 <default_free_pages>:
{
ffffffffc0201758:	1141                	addi	sp,sp,-16
ffffffffc020175a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020175c:	14058463          	beqz	a1,ffffffffc02018a4 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201760:	00659693          	slli	a3,a1,0x6
ffffffffc0201764:	96aa                	add	a3,a3,a0
ffffffffc0201766:	87aa                	mv	a5,a0
ffffffffc0201768:	02d50263          	beq	a0,a3,ffffffffc020178c <default_free_pages+0x34>
ffffffffc020176c:	6798                	ld	a4,8(a5)
ffffffffc020176e:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201770:	10071a63          	bnez	a4,ffffffffc0201884 <default_free_pages+0x12c>
ffffffffc0201774:	6798                	ld	a4,8(a5)
ffffffffc0201776:	8b09                	andi	a4,a4,2
ffffffffc0201778:	10071663          	bnez	a4,ffffffffc0201884 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc020177c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201780:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201784:	04078793          	addi	a5,a5,64
ffffffffc0201788:	fed792e3          	bne	a5,a3,ffffffffc020176c <default_free_pages+0x14>
    base->property = n;
ffffffffc020178c:	2581                	sext.w	a1,a1
ffffffffc020178e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201790:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201794:	4789                	li	a5,2
ffffffffc0201796:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020179a:	000a5697          	auipc	a3,0xa5
ffffffffc020179e:	ea668693          	addi	a3,a3,-346 # ffffffffc02a6640 <free_area>
ffffffffc02017a2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017a4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017a6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017aa:	9db9                	addw	a1,a1,a4
ffffffffc02017ac:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02017ae:	0ad78463          	beq	a5,a3,ffffffffc0201856 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02017b2:	fe878713          	addi	a4,a5,-24
ffffffffc02017b6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02017ba:	4581                	li	a1,0
            if (base < page)
ffffffffc02017bc:	00e56a63          	bltu	a0,a4,ffffffffc02017d0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017c0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017c2:	04d70c63          	beq	a4,a3,ffffffffc020181a <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02017c6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017c8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017cc:	fee57ae3          	bgeu	a0,a4,ffffffffc02017c0 <default_free_pages+0x68>
ffffffffc02017d0:	c199                	beqz	a1,ffffffffc02017d6 <default_free_pages+0x7e>
ffffffffc02017d2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017d6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017d8:	e390                	sd	a2,0(a5)
ffffffffc02017da:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017dc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017de:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02017e0:	00d70d63          	beq	a4,a3,ffffffffc02017fa <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017e4:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017e8:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017ec:	02059813          	slli	a6,a1,0x20
ffffffffc02017f0:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017f4:	97b2                	add	a5,a5,a2
ffffffffc02017f6:	02f50c63          	beq	a0,a5,ffffffffc020182e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017fa:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017fc:	00d78c63          	beq	a5,a3,ffffffffc0201814 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201800:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201802:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201806:	02061593          	slli	a1,a2,0x20
ffffffffc020180a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020180e:	972a                	add	a4,a4,a0
ffffffffc0201810:	04e68a63          	beq	a3,a4,ffffffffc0201864 <default_free_pages+0x10c>
}
ffffffffc0201814:	60a2                	ld	ra,8(sp)
ffffffffc0201816:	0141                	addi	sp,sp,16
ffffffffc0201818:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020181a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020181c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020181e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201820:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201822:	02d70763          	beq	a4,a3,ffffffffc0201850 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201826:	8832                	mv	a6,a2
ffffffffc0201828:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020182a:	87ba                	mv	a5,a4
ffffffffc020182c:	bf71                	j	ffffffffc02017c8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020182e:	491c                	lw	a5,16(a0)
ffffffffc0201830:	9dbd                	addw	a1,a1,a5
ffffffffc0201832:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201836:	57f5                	li	a5,-3
ffffffffc0201838:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020183c:	01853803          	ld	a6,24(a0)
ffffffffc0201840:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201842:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201844:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201848:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020184a:	0105b023          	sd	a6,0(a1)
ffffffffc020184e:	b77d                	j	ffffffffc02017fc <default_free_pages+0xa4>
ffffffffc0201850:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201852:	873e                	mv	a4,a5
ffffffffc0201854:	bf41                	j	ffffffffc02017e4 <default_free_pages+0x8c>
}
ffffffffc0201856:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201858:	e390                	sd	a2,0(a5)
ffffffffc020185a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020185c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020185e:	ed1c                	sd	a5,24(a0)
ffffffffc0201860:	0141                	addi	sp,sp,16
ffffffffc0201862:	8082                	ret
            base->property += p->property;
ffffffffc0201864:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201868:	ff078693          	addi	a3,a5,-16
ffffffffc020186c:	9e39                	addw	a2,a2,a4
ffffffffc020186e:	c910                	sw	a2,16(a0)
ffffffffc0201870:	5775                	li	a4,-3
ffffffffc0201872:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201876:	6398                	ld	a4,0(a5)
ffffffffc0201878:	679c                	ld	a5,8(a5)
}
ffffffffc020187a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020187c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020187e:	e398                	sd	a4,0(a5)
ffffffffc0201880:	0141                	addi	sp,sp,16
ffffffffc0201882:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201884:	00005697          	auipc	a3,0x5
ffffffffc0201888:	c3468693          	addi	a3,a3,-972 # ffffffffc02064b8 <commands+0xb78>
ffffffffc020188c:	00005617          	auipc	a2,0x5
ffffffffc0201890:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0206158 <commands+0x818>
ffffffffc0201894:	09400593          	li	a1,148
ffffffffc0201898:	00005517          	auipc	a0,0x5
ffffffffc020189c:	8d850513          	addi	a0,a0,-1832 # ffffffffc0206170 <commands+0x830>
ffffffffc02018a0:	beffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc02018a4:	00005697          	auipc	a3,0x5
ffffffffc02018a8:	c0c68693          	addi	a3,a3,-1012 # ffffffffc02064b0 <commands+0xb70>
ffffffffc02018ac:	00005617          	auipc	a2,0x5
ffffffffc02018b0:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0206158 <commands+0x818>
ffffffffc02018b4:	09000593          	li	a1,144
ffffffffc02018b8:	00005517          	auipc	a0,0x5
ffffffffc02018bc:	8b850513          	addi	a0,a0,-1864 # ffffffffc0206170 <commands+0x830>
ffffffffc02018c0:	bcffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02018c4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018c4:	c941                	beqz	a0,ffffffffc0201954 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02018c6:	000a5597          	auipc	a1,0xa5
ffffffffc02018ca:	d7a58593          	addi	a1,a1,-646 # ffffffffc02a6640 <free_area>
ffffffffc02018ce:	0105a803          	lw	a6,16(a1)
ffffffffc02018d2:	872a                	mv	a4,a0
ffffffffc02018d4:	02081793          	slli	a5,a6,0x20
ffffffffc02018d8:	9381                	srli	a5,a5,0x20
ffffffffc02018da:	00a7ee63          	bltu	a5,a0,ffffffffc02018f6 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02018de:	87ae                	mv	a5,a1
ffffffffc02018e0:	a801                	j	ffffffffc02018f0 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02018e2:	ff87a683          	lw	a3,-8(a5)
ffffffffc02018e6:	02069613          	slli	a2,a3,0x20
ffffffffc02018ea:	9201                	srli	a2,a2,0x20
ffffffffc02018ec:	00e67763          	bgeu	a2,a4,ffffffffc02018fa <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02018f0:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018f2:	feb798e3          	bne	a5,a1,ffffffffc02018e2 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02018f6:	4501                	li	a0,0
}
ffffffffc02018f8:	8082                	ret
    return listelm->prev;
ffffffffc02018fa:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018fe:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201902:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201906:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020190a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020190e:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201912:	02c77863          	bgeu	a4,a2,ffffffffc0201942 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201916:	071a                	slli	a4,a4,0x6
ffffffffc0201918:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020191a:	41c686bb          	subw	a3,a3,t3
ffffffffc020191e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201920:	00870613          	addi	a2,a4,8
ffffffffc0201924:	4689                	li	a3,2
ffffffffc0201926:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020192a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020192e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201932:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201936:	e290                	sd	a2,0(a3)
ffffffffc0201938:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020193c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020193e:	01173c23          	sd	a7,24(a4)
ffffffffc0201942:	41c8083b          	subw	a6,a6,t3
ffffffffc0201946:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020194a:	5775                	li	a4,-3
ffffffffc020194c:	17c1                	addi	a5,a5,-16
ffffffffc020194e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201952:	8082                	ret
{
ffffffffc0201954:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201956:	00005697          	auipc	a3,0x5
ffffffffc020195a:	b5a68693          	addi	a3,a3,-1190 # ffffffffc02064b0 <commands+0xb70>
ffffffffc020195e:	00004617          	auipc	a2,0x4
ffffffffc0201962:	7fa60613          	addi	a2,a2,2042 # ffffffffc0206158 <commands+0x818>
ffffffffc0201966:	06c00593          	li	a1,108
ffffffffc020196a:	00005517          	auipc	a0,0x5
ffffffffc020196e:	80650513          	addi	a0,a0,-2042 # ffffffffc0206170 <commands+0x830>
{
ffffffffc0201972:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201974:	b1bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201978 <default_init_memmap>:
{
ffffffffc0201978:	1141                	addi	sp,sp,-16
ffffffffc020197a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020197c:	c5f1                	beqz	a1,ffffffffc0201a48 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc020197e:	00659693          	slli	a3,a1,0x6
ffffffffc0201982:	96aa                	add	a3,a3,a0
ffffffffc0201984:	87aa                	mv	a5,a0
ffffffffc0201986:	00d50f63          	beq	a0,a3,ffffffffc02019a4 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020198a:	6798                	ld	a4,8(a5)
ffffffffc020198c:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc020198e:	cf49                	beqz	a4,ffffffffc0201a28 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201990:	0007a823          	sw	zero,16(a5)
ffffffffc0201994:	0007b423          	sd	zero,8(a5)
ffffffffc0201998:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020199c:	04078793          	addi	a5,a5,64
ffffffffc02019a0:	fed795e3          	bne	a5,a3,ffffffffc020198a <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019a4:	2581                	sext.w	a1,a1
ffffffffc02019a6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019a8:	4789                	li	a5,2
ffffffffc02019aa:	00850713          	addi	a4,a0,8
ffffffffc02019ae:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02019b2:	000a5697          	auipc	a3,0xa5
ffffffffc02019b6:	c8e68693          	addi	a3,a3,-882 # ffffffffc02a6640 <free_area>
ffffffffc02019ba:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019bc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019be:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019c2:	9db9                	addw	a1,a1,a4
ffffffffc02019c4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019c6:	04d78a63          	beq	a5,a3,ffffffffc0201a1a <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02019ca:	fe878713          	addi	a4,a5,-24
ffffffffc02019ce:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019d2:	4581                	li	a1,0
            if (base < page)
ffffffffc02019d4:	00e56a63          	bltu	a0,a4,ffffffffc02019e8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019d8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019da:	02d70263          	beq	a4,a3,ffffffffc02019fe <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02019de:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019e0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019e4:	fee57ae3          	bgeu	a0,a4,ffffffffc02019d8 <default_init_memmap+0x60>
ffffffffc02019e8:	c199                	beqz	a1,ffffffffc02019ee <default_init_memmap+0x76>
ffffffffc02019ea:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019ee:	6398                	ld	a4,0(a5)
}
ffffffffc02019f0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019f2:	e390                	sd	a2,0(a5)
ffffffffc02019f4:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02019f6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019f8:	ed18                	sd	a4,24(a0)
ffffffffc02019fa:	0141                	addi	sp,sp,16
ffffffffc02019fc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019fe:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a00:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a02:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a04:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a06:	00d70663          	beq	a4,a3,ffffffffc0201a12 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a0a:	8832                	mv	a6,a2
ffffffffc0201a0c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a0e:	87ba                	mv	a5,a4
ffffffffc0201a10:	bfc1                	j	ffffffffc02019e0 <default_init_memmap+0x68>
}
ffffffffc0201a12:	60a2                	ld	ra,8(sp)
ffffffffc0201a14:	e290                	sd	a2,0(a3)
ffffffffc0201a16:	0141                	addi	sp,sp,16
ffffffffc0201a18:	8082                	ret
ffffffffc0201a1a:	60a2                	ld	ra,8(sp)
ffffffffc0201a1c:	e390                	sd	a2,0(a5)
ffffffffc0201a1e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a20:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a22:	ed1c                	sd	a5,24(a0)
ffffffffc0201a24:	0141                	addi	sp,sp,16
ffffffffc0201a26:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a28:	00005697          	auipc	a3,0x5
ffffffffc0201a2c:	ab868693          	addi	a3,a3,-1352 # ffffffffc02064e0 <commands+0xba0>
ffffffffc0201a30:	00004617          	auipc	a2,0x4
ffffffffc0201a34:	72860613          	addi	a2,a2,1832 # ffffffffc0206158 <commands+0x818>
ffffffffc0201a38:	04b00593          	li	a1,75
ffffffffc0201a3c:	00004517          	auipc	a0,0x4
ffffffffc0201a40:	73450513          	addi	a0,a0,1844 # ffffffffc0206170 <commands+0x830>
ffffffffc0201a44:	a4bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a48:	00005697          	auipc	a3,0x5
ffffffffc0201a4c:	a6868693          	addi	a3,a3,-1432 # ffffffffc02064b0 <commands+0xb70>
ffffffffc0201a50:	00004617          	auipc	a2,0x4
ffffffffc0201a54:	70860613          	addi	a2,a2,1800 # ffffffffc0206158 <commands+0x818>
ffffffffc0201a58:	04700593          	li	a1,71
ffffffffc0201a5c:	00004517          	auipc	a0,0x4
ffffffffc0201a60:	71450513          	addi	a0,a0,1812 # ffffffffc0206170 <commands+0x830>
ffffffffc0201a64:	a2bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a68 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a68:	c94d                	beqz	a0,ffffffffc0201b1a <slob_free+0xb2>
{
ffffffffc0201a6a:	1141                	addi	sp,sp,-16
ffffffffc0201a6c:	e022                	sd	s0,0(sp)
ffffffffc0201a6e:	e406                	sd	ra,8(sp)
ffffffffc0201a70:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201a72:	e9c1                	bnez	a1,ffffffffc0201b02 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a74:	100027f3          	csrr	a5,sstatus
ffffffffc0201a78:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a7a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a7c:	ebd9                	bnez	a5,ffffffffc0201b12 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a7e:	000a4617          	auipc	a2,0xa4
ffffffffc0201a82:	7b260613          	addi	a2,a2,1970 # ffffffffc02a6230 <slobfree>
ffffffffc0201a86:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a88:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a8a:	679c                	ld	a5,8(a5)
ffffffffc0201a8c:	02877a63          	bgeu	a4,s0,ffffffffc0201ac0 <slob_free+0x58>
ffffffffc0201a90:	00f46463          	bltu	s0,a5,ffffffffc0201a98 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a94:	fef76ae3          	bltu	a4,a5,ffffffffc0201a88 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a98:	400c                	lw	a1,0(s0)
ffffffffc0201a9a:	00459693          	slli	a3,a1,0x4
ffffffffc0201a9e:	96a2                	add	a3,a3,s0
ffffffffc0201aa0:	02d78a63          	beq	a5,a3,ffffffffc0201ad4 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201aa4:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201aa6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201aa8:	00469793          	slli	a5,a3,0x4
ffffffffc0201aac:	97ba                	add	a5,a5,a4
ffffffffc0201aae:	02f40e63          	beq	s0,a5,ffffffffc0201aea <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201ab2:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201ab4:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201ab6:	e129                	bnez	a0,ffffffffc0201af8 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201ab8:	60a2                	ld	ra,8(sp)
ffffffffc0201aba:	6402                	ld	s0,0(sp)
ffffffffc0201abc:	0141                	addi	sp,sp,16
ffffffffc0201abe:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ac0:	fcf764e3          	bltu	a4,a5,ffffffffc0201a88 <slob_free+0x20>
ffffffffc0201ac4:	fcf472e3          	bgeu	s0,a5,ffffffffc0201a88 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201ac8:	400c                	lw	a1,0(s0)
ffffffffc0201aca:	00459693          	slli	a3,a1,0x4
ffffffffc0201ace:	96a2                	add	a3,a3,s0
ffffffffc0201ad0:	fcd79ae3          	bne	a5,a3,ffffffffc0201aa4 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201ad4:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201ad6:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201ad8:	9db5                	addw	a1,a1,a3
ffffffffc0201ada:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201adc:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201ade:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ae0:	00469793          	slli	a5,a3,0x4
ffffffffc0201ae4:	97ba                	add	a5,a5,a4
ffffffffc0201ae6:	fcf416e3          	bne	s0,a5,ffffffffc0201ab2 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201aea:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201aec:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201aee:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201af0:	9ebd                	addw	a3,a3,a5
ffffffffc0201af2:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201af4:	e70c                	sd	a1,8(a4)
ffffffffc0201af6:	d169                	beqz	a0,ffffffffc0201ab8 <slob_free+0x50>
}
ffffffffc0201af8:	6402                	ld	s0,0(sp)
ffffffffc0201afa:	60a2                	ld	ra,8(sp)
ffffffffc0201afc:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201afe:	eb1fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b02:	25bd                	addiw	a1,a1,15
ffffffffc0201b04:	8191                	srli	a1,a1,0x4
ffffffffc0201b06:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b08:	100027f3          	csrr	a5,sstatus
ffffffffc0201b0c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b0e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b10:	d7bd                	beqz	a5,ffffffffc0201a7e <slob_free+0x16>
        intr_disable();
ffffffffc0201b12:	ea3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b16:	4505                	li	a0,1
ffffffffc0201b18:	b79d                	j	ffffffffc0201a7e <slob_free+0x16>
ffffffffc0201b1a:	8082                	ret

ffffffffc0201b1c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b1c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b1e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b20:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b24:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b26:	352000ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
	if (!page)
ffffffffc0201b2a:	c91d                	beqz	a0,ffffffffc0201b60 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b2c:	000a9697          	auipc	a3,0xa9
ffffffffc0201b30:	b846b683          	ld	a3,-1148(a3) # ffffffffc02aa6b0 <pages>
ffffffffc0201b34:	8d15                	sub	a0,a0,a3
ffffffffc0201b36:	8519                	srai	a0,a0,0x6
ffffffffc0201b38:	00006697          	auipc	a3,0x6
ffffffffc0201b3c:	cf86b683          	ld	a3,-776(a3) # ffffffffc0207830 <nbase>
ffffffffc0201b40:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201b42:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b46:	83b1                	srli	a5,a5,0xc
ffffffffc0201b48:	000a9717          	auipc	a4,0xa9
ffffffffc0201b4c:	b6073703          	ld	a4,-1184(a4) # ffffffffc02aa6a8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b50:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b52:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b66 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b56:	000a9697          	auipc	a3,0xa9
ffffffffc0201b5a:	b6a6b683          	ld	a3,-1174(a3) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0201b5e:	9536                	add	a0,a0,a3
}
ffffffffc0201b60:	60a2                	ld	ra,8(sp)
ffffffffc0201b62:	0141                	addi	sp,sp,16
ffffffffc0201b64:	8082                	ret
ffffffffc0201b66:	86aa                	mv	a3,a0
ffffffffc0201b68:	00005617          	auipc	a2,0x5
ffffffffc0201b6c:	9d860613          	addi	a2,a2,-1576 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0201b70:	07100593          	li	a1,113
ffffffffc0201b74:	00005517          	auipc	a0,0x5
ffffffffc0201b78:	9f450513          	addi	a0,a0,-1548 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0201b7c:	913fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b80 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b80:	1101                	addi	sp,sp,-32
ffffffffc0201b82:	ec06                	sd	ra,24(sp)
ffffffffc0201b84:	e822                	sd	s0,16(sp)
ffffffffc0201b86:	e426                	sd	s1,8(sp)
ffffffffc0201b88:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b8a:	01050713          	addi	a4,a0,16
ffffffffc0201b8e:	6785                	lui	a5,0x1
ffffffffc0201b90:	0cf77363          	bgeu	a4,a5,ffffffffc0201c56 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b94:	00f50493          	addi	s1,a0,15
ffffffffc0201b98:	8091                	srli	s1,s1,0x4
ffffffffc0201b9a:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b9c:	10002673          	csrr	a2,sstatus
ffffffffc0201ba0:	8a09                	andi	a2,a2,2
ffffffffc0201ba2:	e25d                	bnez	a2,ffffffffc0201c48 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201ba4:	000a4917          	auipc	s2,0xa4
ffffffffc0201ba8:	68c90913          	addi	s2,s2,1676 # ffffffffc02a6230 <slobfree>
ffffffffc0201bac:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bb0:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201bb2:	4398                	lw	a4,0(a5)
ffffffffc0201bb4:	08975e63          	bge	a4,s1,ffffffffc0201c50 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201bb8:	00f68b63          	beq	a3,a5,ffffffffc0201bce <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bbc:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bbe:	4018                	lw	a4,0(s0)
ffffffffc0201bc0:	02975a63          	bge	a4,s1,ffffffffc0201bf4 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201bc4:	00093683          	ld	a3,0(s2)
ffffffffc0201bc8:	87a2                	mv	a5,s0
ffffffffc0201bca:	fef699e3          	bne	a3,a5,ffffffffc0201bbc <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201bce:	ee31                	bnez	a2,ffffffffc0201c2a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bd0:	4501                	li	a0,0
ffffffffc0201bd2:	f4bff0ef          	jal	ra,ffffffffc0201b1c <__slob_get_free_pages.constprop.0>
ffffffffc0201bd6:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201bd8:	cd05                	beqz	a0,ffffffffc0201c10 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201bda:	6585                	lui	a1,0x1
ffffffffc0201bdc:	e8dff0ef          	jal	ra,ffffffffc0201a68 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201be0:	10002673          	csrr	a2,sstatus
ffffffffc0201be4:	8a09                	andi	a2,a2,2
ffffffffc0201be6:	ee05                	bnez	a2,ffffffffc0201c1e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201be8:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bec:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bee:	4018                	lw	a4,0(s0)
ffffffffc0201bf0:	fc974ae3          	blt	a4,s1,ffffffffc0201bc4 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201bf4:	04e48763          	beq	s1,a4,ffffffffc0201c42 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201bf8:	00449693          	slli	a3,s1,0x4
ffffffffc0201bfc:	96a2                	add	a3,a3,s0
ffffffffc0201bfe:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c00:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c02:	9f05                	subw	a4,a4,s1
ffffffffc0201c04:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c06:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c08:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c0a:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c0e:	e20d                	bnez	a2,ffffffffc0201c30 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c10:	60e2                	ld	ra,24(sp)
ffffffffc0201c12:	8522                	mv	a0,s0
ffffffffc0201c14:	6442                	ld	s0,16(sp)
ffffffffc0201c16:	64a2                	ld	s1,8(sp)
ffffffffc0201c18:	6902                	ld	s2,0(sp)
ffffffffc0201c1a:	6105                	addi	sp,sp,32
ffffffffc0201c1c:	8082                	ret
        intr_disable();
ffffffffc0201c1e:	d97fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c22:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c26:	4605                	li	a2,1
ffffffffc0201c28:	b7d1                	j	ffffffffc0201bec <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c2a:	d85fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c2e:	b74d                	j	ffffffffc0201bd0 <slob_alloc.constprop.0+0x50>
ffffffffc0201c30:	d7ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c34:	60e2                	ld	ra,24(sp)
ffffffffc0201c36:	8522                	mv	a0,s0
ffffffffc0201c38:	6442                	ld	s0,16(sp)
ffffffffc0201c3a:	64a2                	ld	s1,8(sp)
ffffffffc0201c3c:	6902                	ld	s2,0(sp)
ffffffffc0201c3e:	6105                	addi	sp,sp,32
ffffffffc0201c40:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c42:	6418                	ld	a4,8(s0)
ffffffffc0201c44:	e798                	sd	a4,8(a5)
ffffffffc0201c46:	b7d1                	j	ffffffffc0201c0a <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201c48:	d6dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201c4c:	4605                	li	a2,1
ffffffffc0201c4e:	bf99                	j	ffffffffc0201ba4 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201c50:	843e                	mv	s0,a5
ffffffffc0201c52:	87b6                	mv	a5,a3
ffffffffc0201c54:	b745                	j	ffffffffc0201bf4 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c56:	00005697          	auipc	a3,0x5
ffffffffc0201c5a:	92268693          	addi	a3,a3,-1758 # ffffffffc0206578 <default_pmm_manager+0x70>
ffffffffc0201c5e:	00004617          	auipc	a2,0x4
ffffffffc0201c62:	4fa60613          	addi	a2,a2,1274 # ffffffffc0206158 <commands+0x818>
ffffffffc0201c66:	06300593          	li	a1,99
ffffffffc0201c6a:	00005517          	auipc	a0,0x5
ffffffffc0201c6e:	92e50513          	addi	a0,a0,-1746 # ffffffffc0206598 <default_pmm_manager+0x90>
ffffffffc0201c72:	81dfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c76 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c76:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c78:	00005517          	auipc	a0,0x5
ffffffffc0201c7c:	93850513          	addi	a0,a0,-1736 # ffffffffc02065b0 <default_pmm_manager+0xa8>
{
ffffffffc0201c80:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201c82:	d12fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c86:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c88:	00005517          	auipc	a0,0x5
ffffffffc0201c8c:	94050513          	addi	a0,a0,-1728 # ffffffffc02065c8 <default_pmm_manager+0xc0>
}
ffffffffc0201c90:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c92:	d02fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201c96 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201c96:	4501                	li	a0,0
ffffffffc0201c98:	8082                	ret

ffffffffc0201c9a <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c9a:	1101                	addi	sp,sp,-32
ffffffffc0201c9c:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c9e:	6905                	lui	s2,0x1
{
ffffffffc0201ca0:	e822                	sd	s0,16(sp)
ffffffffc0201ca2:	ec06                	sd	ra,24(sp)
ffffffffc0201ca4:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ca6:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb1>
{
ffffffffc0201caa:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cac:	04a7f963          	bgeu	a5,a0,ffffffffc0201cfe <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cb0:	4561                	li	a0,24
ffffffffc0201cb2:	ecfff0ef          	jal	ra,ffffffffc0201b80 <slob_alloc.constprop.0>
ffffffffc0201cb6:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201cb8:	c929                	beqz	a0,ffffffffc0201d0a <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201cba:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201cbe:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201cc0:	00f95763          	bge	s2,a5,ffffffffc0201cce <kmalloc+0x34>
ffffffffc0201cc4:	6705                	lui	a4,0x1
ffffffffc0201cc6:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201cc8:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cca:	fef74ee3          	blt	a4,a5,ffffffffc0201cc6 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201cce:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201cd0:	e4dff0ef          	jal	ra,ffffffffc0201b1c <__slob_get_free_pages.constprop.0>
ffffffffc0201cd4:	e488                	sd	a0,8(s1)
ffffffffc0201cd6:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201cd8:	c525                	beqz	a0,ffffffffc0201d40 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cda:	100027f3          	csrr	a5,sstatus
ffffffffc0201cde:	8b89                	andi	a5,a5,2
ffffffffc0201ce0:	ef8d                	bnez	a5,ffffffffc0201d1a <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201ce2:	000a9797          	auipc	a5,0xa9
ffffffffc0201ce6:	9ae78793          	addi	a5,a5,-1618 # ffffffffc02aa690 <bigblocks>
ffffffffc0201cea:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201cec:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201cee:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201cf0:	60e2                	ld	ra,24(sp)
ffffffffc0201cf2:	8522                	mv	a0,s0
ffffffffc0201cf4:	6442                	ld	s0,16(sp)
ffffffffc0201cf6:	64a2                	ld	s1,8(sp)
ffffffffc0201cf8:	6902                	ld	s2,0(sp)
ffffffffc0201cfa:	6105                	addi	sp,sp,32
ffffffffc0201cfc:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201cfe:	0541                	addi	a0,a0,16
ffffffffc0201d00:	e81ff0ef          	jal	ra,ffffffffc0201b80 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d04:	01050413          	addi	s0,a0,16
ffffffffc0201d08:	f565                	bnez	a0,ffffffffc0201cf0 <kmalloc+0x56>
ffffffffc0201d0a:	4401                	li	s0,0
}
ffffffffc0201d0c:	60e2                	ld	ra,24(sp)
ffffffffc0201d0e:	8522                	mv	a0,s0
ffffffffc0201d10:	6442                	ld	s0,16(sp)
ffffffffc0201d12:	64a2                	ld	s1,8(sp)
ffffffffc0201d14:	6902                	ld	s2,0(sp)
ffffffffc0201d16:	6105                	addi	sp,sp,32
ffffffffc0201d18:	8082                	ret
        intr_disable();
ffffffffc0201d1a:	c9bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d1e:	000a9797          	auipc	a5,0xa9
ffffffffc0201d22:	97278793          	addi	a5,a5,-1678 # ffffffffc02aa690 <bigblocks>
ffffffffc0201d26:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d28:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d2a:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d2c:	c83fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d30:	6480                	ld	s0,8(s1)
}
ffffffffc0201d32:	60e2                	ld	ra,24(sp)
ffffffffc0201d34:	64a2                	ld	s1,8(sp)
ffffffffc0201d36:	8522                	mv	a0,s0
ffffffffc0201d38:	6442                	ld	s0,16(sp)
ffffffffc0201d3a:	6902                	ld	s2,0(sp)
ffffffffc0201d3c:	6105                	addi	sp,sp,32
ffffffffc0201d3e:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d40:	45e1                	li	a1,24
ffffffffc0201d42:	8526                	mv	a0,s1
ffffffffc0201d44:	d25ff0ef          	jal	ra,ffffffffc0201a68 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201d48:	b765                	j	ffffffffc0201cf0 <kmalloc+0x56>

ffffffffc0201d4a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d4a:	c169                	beqz	a0,ffffffffc0201e0c <kfree+0xc2>
{
ffffffffc0201d4c:	1101                	addi	sp,sp,-32
ffffffffc0201d4e:	e822                	sd	s0,16(sp)
ffffffffc0201d50:	ec06                	sd	ra,24(sp)
ffffffffc0201d52:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d54:	03451793          	slli	a5,a0,0x34
ffffffffc0201d58:	842a                	mv	s0,a0
ffffffffc0201d5a:	e3d9                	bnez	a5,ffffffffc0201de0 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d5c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d60:	8b89                	andi	a5,a5,2
ffffffffc0201d62:	e7d9                	bnez	a5,ffffffffc0201df0 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d64:	000a9797          	auipc	a5,0xa9
ffffffffc0201d68:	92c7b783          	ld	a5,-1748(a5) # ffffffffc02aa690 <bigblocks>
    return 0;
ffffffffc0201d6c:	4601                	li	a2,0
ffffffffc0201d6e:	cbad                	beqz	a5,ffffffffc0201de0 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d70:	000a9697          	auipc	a3,0xa9
ffffffffc0201d74:	92068693          	addi	a3,a3,-1760 # ffffffffc02aa690 <bigblocks>
ffffffffc0201d78:	a021                	j	ffffffffc0201d80 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d7a:	01048693          	addi	a3,s1,16
ffffffffc0201d7e:	c3a5                	beqz	a5,ffffffffc0201dde <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201d80:	6798                	ld	a4,8(a5)
ffffffffc0201d82:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201d84:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d86:	fe871ae3          	bne	a4,s0,ffffffffc0201d7a <kfree+0x30>
				*last = bb->next;
ffffffffc0201d8a:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201d8c:	ee2d                	bnez	a2,ffffffffc0201e06 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201d8e:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d92:	4098                	lw	a4,0(s1)
ffffffffc0201d94:	08f46963          	bltu	s0,a5,ffffffffc0201e26 <kfree+0xdc>
ffffffffc0201d98:	000a9697          	auipc	a3,0xa9
ffffffffc0201d9c:	9286b683          	ld	a3,-1752(a3) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0201da0:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201da2:	8031                	srli	s0,s0,0xc
ffffffffc0201da4:	000a9797          	auipc	a5,0xa9
ffffffffc0201da8:	9047b783          	ld	a5,-1788(a5) # ffffffffc02aa6a8 <npage>
ffffffffc0201dac:	06f47163          	bgeu	s0,a5,ffffffffc0201e0e <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201db0:	00006517          	auipc	a0,0x6
ffffffffc0201db4:	a8053503          	ld	a0,-1408(a0) # ffffffffc0207830 <nbase>
ffffffffc0201db8:	8c09                	sub	s0,s0,a0
ffffffffc0201dba:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201dbc:	000a9517          	auipc	a0,0xa9
ffffffffc0201dc0:	8f453503          	ld	a0,-1804(a0) # ffffffffc02aa6b0 <pages>
ffffffffc0201dc4:	4585                	li	a1,1
ffffffffc0201dc6:	9522                	add	a0,a0,s0
ffffffffc0201dc8:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201dcc:	0ea000ef          	jal	ra,ffffffffc0201eb6 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201dd0:	6442                	ld	s0,16(sp)
ffffffffc0201dd2:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dd4:	8526                	mv	a0,s1
}
ffffffffc0201dd6:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dd8:	45e1                	li	a1,24
}
ffffffffc0201dda:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ddc:	b171                	j	ffffffffc0201a68 <slob_free>
ffffffffc0201dde:	e20d                	bnez	a2,ffffffffc0201e00 <kfree+0xb6>
ffffffffc0201de0:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201de4:	6442                	ld	s0,16(sp)
ffffffffc0201de6:	60e2                	ld	ra,24(sp)
ffffffffc0201de8:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dea:	4581                	li	a1,0
}
ffffffffc0201dec:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dee:	b9ad                	j	ffffffffc0201a68 <slob_free>
        intr_disable();
ffffffffc0201df0:	bc5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201df4:	000a9797          	auipc	a5,0xa9
ffffffffc0201df8:	89c7b783          	ld	a5,-1892(a5) # ffffffffc02aa690 <bigblocks>
        return 1;
ffffffffc0201dfc:	4605                	li	a2,1
ffffffffc0201dfe:	fbad                	bnez	a5,ffffffffc0201d70 <kfree+0x26>
        intr_enable();
ffffffffc0201e00:	baffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e04:	bff1                	j	ffffffffc0201de0 <kfree+0x96>
ffffffffc0201e06:	ba9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e0a:	b751                	j	ffffffffc0201d8e <kfree+0x44>
ffffffffc0201e0c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e0e:	00005617          	auipc	a2,0x5
ffffffffc0201e12:	80260613          	addi	a2,a2,-2046 # ffffffffc0206610 <default_pmm_manager+0x108>
ffffffffc0201e16:	06900593          	li	a1,105
ffffffffc0201e1a:	00004517          	auipc	a0,0x4
ffffffffc0201e1e:	74e50513          	addi	a0,a0,1870 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0201e22:	e6cfe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e26:	86a2                	mv	a3,s0
ffffffffc0201e28:	00004617          	auipc	a2,0x4
ffffffffc0201e2c:	7c060613          	addi	a2,a2,1984 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc0201e30:	07700593          	li	a1,119
ffffffffc0201e34:	00004517          	auipc	a0,0x4
ffffffffc0201e38:	73450513          	addi	a0,a0,1844 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0201e3c:	e52fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e40 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e40:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e42:	00004617          	auipc	a2,0x4
ffffffffc0201e46:	7ce60613          	addi	a2,a2,1998 # ffffffffc0206610 <default_pmm_manager+0x108>
ffffffffc0201e4a:	06900593          	li	a1,105
ffffffffc0201e4e:	00004517          	auipc	a0,0x4
ffffffffc0201e52:	71a50513          	addi	a0,a0,1818 # ffffffffc0206568 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201e56:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e58:	e36fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e5c <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201e5c:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201e5e:	00004617          	auipc	a2,0x4
ffffffffc0201e62:	7d260613          	addi	a2,a2,2002 # ffffffffc0206630 <default_pmm_manager+0x128>
ffffffffc0201e66:	07f00593          	li	a1,127
ffffffffc0201e6a:	00004517          	auipc	a0,0x4
ffffffffc0201e6e:	6fe50513          	addi	a0,a0,1790 # ffffffffc0206568 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201e72:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201e74:	e1afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e78 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e78:	100027f3          	csrr	a5,sstatus
ffffffffc0201e7c:	8b89                	andi	a5,a5,2
ffffffffc0201e7e:	e799                	bnez	a5,ffffffffc0201e8c <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e80:	000a9797          	auipc	a5,0xa9
ffffffffc0201e84:	8387b783          	ld	a5,-1992(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201e88:	6f9c                	ld	a5,24(a5)
ffffffffc0201e8a:	8782                	jr	a5
{
ffffffffc0201e8c:	1141                	addi	sp,sp,-16
ffffffffc0201e8e:	e406                	sd	ra,8(sp)
ffffffffc0201e90:	e022                	sd	s0,0(sp)
ffffffffc0201e92:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201e94:	b21fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e98:	000a9797          	auipc	a5,0xa9
ffffffffc0201e9c:	8207b783          	ld	a5,-2016(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201ea0:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea2:	8522                	mv	a0,s0
ffffffffc0201ea4:	9782                	jalr	a5
ffffffffc0201ea6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ea8:	b07fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201eac:	60a2                	ld	ra,8(sp)
ffffffffc0201eae:	8522                	mv	a0,s0
ffffffffc0201eb0:	6402                	ld	s0,0(sp)
ffffffffc0201eb2:	0141                	addi	sp,sp,16
ffffffffc0201eb4:	8082                	ret

ffffffffc0201eb6 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eb6:	100027f3          	csrr	a5,sstatus
ffffffffc0201eba:	8b89                	andi	a5,a5,2
ffffffffc0201ebc:	e799                	bnez	a5,ffffffffc0201eca <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ebe:	000a8797          	auipc	a5,0xa8
ffffffffc0201ec2:	7fa7b783          	ld	a5,2042(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201ec6:	739c                	ld	a5,32(a5)
ffffffffc0201ec8:	8782                	jr	a5
{
ffffffffc0201eca:	1101                	addi	sp,sp,-32
ffffffffc0201ecc:	ec06                	sd	ra,24(sp)
ffffffffc0201ece:	e822                	sd	s0,16(sp)
ffffffffc0201ed0:	e426                	sd	s1,8(sp)
ffffffffc0201ed2:	842a                	mv	s0,a0
ffffffffc0201ed4:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ed6:	adffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201eda:	000a8797          	auipc	a5,0xa8
ffffffffc0201ede:	7de7b783          	ld	a5,2014(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201ee2:	739c                	ld	a5,32(a5)
ffffffffc0201ee4:	85a6                	mv	a1,s1
ffffffffc0201ee6:	8522                	mv	a0,s0
ffffffffc0201ee8:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201eea:	6442                	ld	s0,16(sp)
ffffffffc0201eec:	60e2                	ld	ra,24(sp)
ffffffffc0201eee:	64a2                	ld	s1,8(sp)
ffffffffc0201ef0:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ef2:	abdfe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201ef6 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ef6:	100027f3          	csrr	a5,sstatus
ffffffffc0201efa:	8b89                	andi	a5,a5,2
ffffffffc0201efc:	e799                	bnez	a5,ffffffffc0201f0a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201efe:	000a8797          	auipc	a5,0xa8
ffffffffc0201f02:	7ba7b783          	ld	a5,1978(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201f06:	779c                	ld	a5,40(a5)
ffffffffc0201f08:	8782                	jr	a5
{
ffffffffc0201f0a:	1141                	addi	sp,sp,-16
ffffffffc0201f0c:	e406                	sd	ra,8(sp)
ffffffffc0201f0e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f10:	aa5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f14:	000a8797          	auipc	a5,0xa8
ffffffffc0201f18:	7a47b783          	ld	a5,1956(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201f1c:	779c                	ld	a5,40(a5)
ffffffffc0201f1e:	9782                	jalr	a5
ffffffffc0201f20:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f22:	a8dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f26:	60a2                	ld	ra,8(sp)
ffffffffc0201f28:	8522                	mv	a0,s0
ffffffffc0201f2a:	6402                	ld	s0,0(sp)
ffffffffc0201f2c:	0141                	addi	sp,sp,16
ffffffffc0201f2e:	8082                	ret

ffffffffc0201f30 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f30:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f34:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f38:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f3a:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f3c:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f3e:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f42:	6094                	ld	a3,0(s1)
{
ffffffffc0201f44:	f04a                	sd	s2,32(sp)
ffffffffc0201f46:	ec4e                	sd	s3,24(sp)
ffffffffc0201f48:	e852                	sd	s4,16(sp)
ffffffffc0201f4a:	fc06                	sd	ra,56(sp)
ffffffffc0201f4c:	f822                	sd	s0,48(sp)
ffffffffc0201f4e:	e456                	sd	s5,8(sp)
ffffffffc0201f50:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f52:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f56:	892e                	mv	s2,a1
ffffffffc0201f58:	8a32                	mv	s4,a2
ffffffffc0201f5a:	000a8997          	auipc	s3,0xa8
ffffffffc0201f5e:	74e98993          	addi	s3,s3,1870 # ffffffffc02aa6a8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f62:	efbd                	bnez	a5,ffffffffc0201fe0 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f64:	14060c63          	beqz	a2,ffffffffc02020bc <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f68:	100027f3          	csrr	a5,sstatus
ffffffffc0201f6c:	8b89                	andi	a5,a5,2
ffffffffc0201f6e:	14079963          	bnez	a5,ffffffffc02020c0 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f72:	000a8797          	auipc	a5,0xa8
ffffffffc0201f76:	7467b783          	ld	a5,1862(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201f7a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f7c:	4505                	li	a0,1
ffffffffc0201f7e:	9782                	jalr	a5
ffffffffc0201f80:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f82:	12040d63          	beqz	s0,ffffffffc02020bc <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f86:	000a8b17          	auipc	s6,0xa8
ffffffffc0201f8a:	72ab0b13          	addi	s6,s6,1834 # ffffffffc02aa6b0 <pages>
ffffffffc0201f8e:	000b3503          	ld	a0,0(s6)
ffffffffc0201f92:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f96:	000a8997          	auipc	s3,0xa8
ffffffffc0201f9a:	71298993          	addi	s3,s3,1810 # ffffffffc02aa6a8 <npage>
ffffffffc0201f9e:	40a40533          	sub	a0,s0,a0
ffffffffc0201fa2:	8519                	srai	a0,a0,0x6
ffffffffc0201fa4:	9556                	add	a0,a0,s5
ffffffffc0201fa6:	0009b703          	ld	a4,0(s3)
ffffffffc0201faa:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201fae:	4685                	li	a3,1
ffffffffc0201fb0:	c014                	sw	a3,0(s0)
ffffffffc0201fb2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fb4:	0532                	slli	a0,a0,0xc
ffffffffc0201fb6:	16e7f763          	bgeu	a5,a4,ffffffffc0202124 <get_pte+0x1f4>
ffffffffc0201fba:	000a8797          	auipc	a5,0xa8
ffffffffc0201fbe:	7067b783          	ld	a5,1798(a5) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0201fc2:	6605                	lui	a2,0x1
ffffffffc0201fc4:	4581                	li	a1,0
ffffffffc0201fc6:	953e                	add	a0,a0,a5
ffffffffc0201fc8:	6e6030ef          	jal	ra,ffffffffc02056ae <memset>
    return page - pages + nbase;
ffffffffc0201fcc:	000b3683          	ld	a3,0(s6)
ffffffffc0201fd0:	40d406b3          	sub	a3,s0,a3
ffffffffc0201fd4:	8699                	srai	a3,a3,0x6
ffffffffc0201fd6:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fd8:	06aa                	slli	a3,a3,0xa
ffffffffc0201fda:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fde:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201fe0:	77fd                	lui	a5,0xfffff
ffffffffc0201fe2:	068a                	slli	a3,a3,0x2
ffffffffc0201fe4:	0009b703          	ld	a4,0(s3)
ffffffffc0201fe8:	8efd                	and	a3,a3,a5
ffffffffc0201fea:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fee:	10e7ff63          	bgeu	a5,a4,ffffffffc020210c <get_pte+0x1dc>
ffffffffc0201ff2:	000a8a97          	auipc	s5,0xa8
ffffffffc0201ff6:	6cea8a93          	addi	s5,s5,1742 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0201ffa:	000ab403          	ld	s0,0(s5)
ffffffffc0201ffe:	01595793          	srli	a5,s2,0x15
ffffffffc0202002:	1ff7f793          	andi	a5,a5,511
ffffffffc0202006:	96a2                	add	a3,a3,s0
ffffffffc0202008:	00379413          	slli	s0,a5,0x3
ffffffffc020200c:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc020200e:	6014                	ld	a3,0(s0)
ffffffffc0202010:	0016f793          	andi	a5,a3,1
ffffffffc0202014:	ebad                	bnez	a5,ffffffffc0202086 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202016:	0a0a0363          	beqz	s4,ffffffffc02020bc <get_pte+0x18c>
ffffffffc020201a:	100027f3          	csrr	a5,sstatus
ffffffffc020201e:	8b89                	andi	a5,a5,2
ffffffffc0202020:	efcd                	bnez	a5,ffffffffc02020da <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202022:	000a8797          	auipc	a5,0xa8
ffffffffc0202026:	6967b783          	ld	a5,1686(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020202a:	6f9c                	ld	a5,24(a5)
ffffffffc020202c:	4505                	li	a0,1
ffffffffc020202e:	9782                	jalr	a5
ffffffffc0202030:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202032:	c4c9                	beqz	s1,ffffffffc02020bc <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202034:	000a8b17          	auipc	s6,0xa8
ffffffffc0202038:	67cb0b13          	addi	s6,s6,1660 # ffffffffc02aa6b0 <pages>
ffffffffc020203c:	000b3503          	ld	a0,0(s6)
ffffffffc0202040:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202044:	0009b703          	ld	a4,0(s3)
ffffffffc0202048:	40a48533          	sub	a0,s1,a0
ffffffffc020204c:	8519                	srai	a0,a0,0x6
ffffffffc020204e:	9552                	add	a0,a0,s4
ffffffffc0202050:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202054:	4685                	li	a3,1
ffffffffc0202056:	c094                	sw	a3,0(s1)
ffffffffc0202058:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020205a:	0532                	slli	a0,a0,0xc
ffffffffc020205c:	0ee7f163          	bgeu	a5,a4,ffffffffc020213e <get_pte+0x20e>
ffffffffc0202060:	000ab783          	ld	a5,0(s5)
ffffffffc0202064:	6605                	lui	a2,0x1
ffffffffc0202066:	4581                	li	a1,0
ffffffffc0202068:	953e                	add	a0,a0,a5
ffffffffc020206a:	644030ef          	jal	ra,ffffffffc02056ae <memset>
    return page - pages + nbase;
ffffffffc020206e:	000b3683          	ld	a3,0(s6)
ffffffffc0202072:	40d486b3          	sub	a3,s1,a3
ffffffffc0202076:	8699                	srai	a3,a3,0x6
ffffffffc0202078:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020207a:	06aa                	slli	a3,a3,0xa
ffffffffc020207c:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202080:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202082:	0009b703          	ld	a4,0(s3)
ffffffffc0202086:	068a                	slli	a3,a3,0x2
ffffffffc0202088:	757d                	lui	a0,0xfffff
ffffffffc020208a:	8ee9                	and	a3,a3,a0
ffffffffc020208c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202090:	06e7f263          	bgeu	a5,a4,ffffffffc02020f4 <get_pte+0x1c4>
ffffffffc0202094:	000ab503          	ld	a0,0(s5)
ffffffffc0202098:	00c95913          	srli	s2,s2,0xc
ffffffffc020209c:	1ff97913          	andi	s2,s2,511
ffffffffc02020a0:	96aa                	add	a3,a3,a0
ffffffffc02020a2:	00391513          	slli	a0,s2,0x3
ffffffffc02020a6:	9536                	add	a0,a0,a3
}
ffffffffc02020a8:	70e2                	ld	ra,56(sp)
ffffffffc02020aa:	7442                	ld	s0,48(sp)
ffffffffc02020ac:	74a2                	ld	s1,40(sp)
ffffffffc02020ae:	7902                	ld	s2,32(sp)
ffffffffc02020b0:	69e2                	ld	s3,24(sp)
ffffffffc02020b2:	6a42                	ld	s4,16(sp)
ffffffffc02020b4:	6aa2                	ld	s5,8(sp)
ffffffffc02020b6:	6b02                	ld	s6,0(sp)
ffffffffc02020b8:	6121                	addi	sp,sp,64
ffffffffc02020ba:	8082                	ret
            return NULL;
ffffffffc02020bc:	4501                	li	a0,0
ffffffffc02020be:	b7ed                	j	ffffffffc02020a8 <get_pte+0x178>
        intr_disable();
ffffffffc02020c0:	8f5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020c4:	000a8797          	auipc	a5,0xa8
ffffffffc02020c8:	5f47b783          	ld	a5,1524(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc02020cc:	6f9c                	ld	a5,24(a5)
ffffffffc02020ce:	4505                	li	a0,1
ffffffffc02020d0:	9782                	jalr	a5
ffffffffc02020d2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020d4:	8dbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020d8:	b56d                	j	ffffffffc0201f82 <get_pte+0x52>
        intr_disable();
ffffffffc02020da:	8dbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02020de:	000a8797          	auipc	a5,0xa8
ffffffffc02020e2:	5da7b783          	ld	a5,1498(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc02020e6:	6f9c                	ld	a5,24(a5)
ffffffffc02020e8:	4505                	li	a0,1
ffffffffc02020ea:	9782                	jalr	a5
ffffffffc02020ec:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02020ee:	8c1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020f2:	b781                	j	ffffffffc0202032 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020f4:	00004617          	auipc	a2,0x4
ffffffffc02020f8:	44c60613          	addi	a2,a2,1100 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc02020fc:	0fa00593          	li	a1,250
ffffffffc0202100:	00004517          	auipc	a0,0x4
ffffffffc0202104:	55850513          	addi	a0,a0,1368 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202108:	b86fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020210c:	00004617          	auipc	a2,0x4
ffffffffc0202110:	43460613          	addi	a2,a2,1076 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0202114:	0ed00593          	li	a1,237
ffffffffc0202118:	00004517          	auipc	a0,0x4
ffffffffc020211c:	54050513          	addi	a0,a0,1344 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202120:	b6efe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202124:	86aa                	mv	a3,a0
ffffffffc0202126:	00004617          	auipc	a2,0x4
ffffffffc020212a:	41a60613          	addi	a2,a2,1050 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc020212e:	0e900593          	li	a1,233
ffffffffc0202132:	00004517          	auipc	a0,0x4
ffffffffc0202136:	52650513          	addi	a0,a0,1318 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc020213a:	b54fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020213e:	86aa                	mv	a3,a0
ffffffffc0202140:	00004617          	auipc	a2,0x4
ffffffffc0202144:	40060613          	addi	a2,a2,1024 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0202148:	0f700593          	li	a1,247
ffffffffc020214c:	00004517          	auipc	a0,0x4
ffffffffc0202150:	50c50513          	addi	a0,a0,1292 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202154:	b3afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202158 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202158:	1141                	addi	sp,sp,-16
ffffffffc020215a:	e022                	sd	s0,0(sp)
ffffffffc020215c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020215e:	4601                	li	a2,0
{
ffffffffc0202160:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202162:	dcfff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
    if (ptep_store != NULL)
ffffffffc0202166:	c011                	beqz	s0,ffffffffc020216a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202168:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020216a:	c511                	beqz	a0,ffffffffc0202176 <get_page+0x1e>
ffffffffc020216c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020216e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202170:	0017f713          	andi	a4,a5,1
ffffffffc0202174:	e709                	bnez	a4,ffffffffc020217e <get_page+0x26>
}
ffffffffc0202176:	60a2                	ld	ra,8(sp)
ffffffffc0202178:	6402                	ld	s0,0(sp)
ffffffffc020217a:	0141                	addi	sp,sp,16
ffffffffc020217c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020217e:	078a                	slli	a5,a5,0x2
ffffffffc0202180:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202182:	000a8717          	auipc	a4,0xa8
ffffffffc0202186:	52673703          	ld	a4,1318(a4) # ffffffffc02aa6a8 <npage>
ffffffffc020218a:	00e7ff63          	bgeu	a5,a4,ffffffffc02021a8 <get_page+0x50>
ffffffffc020218e:	60a2                	ld	ra,8(sp)
ffffffffc0202190:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202192:	fff80537          	lui	a0,0xfff80
ffffffffc0202196:	97aa                	add	a5,a5,a0
ffffffffc0202198:	079a                	slli	a5,a5,0x6
ffffffffc020219a:	000a8517          	auipc	a0,0xa8
ffffffffc020219e:	51653503          	ld	a0,1302(a0) # ffffffffc02aa6b0 <pages>
ffffffffc02021a2:	953e                	add	a0,a0,a5
ffffffffc02021a4:	0141                	addi	sp,sp,16
ffffffffc02021a6:	8082                	ret
ffffffffc02021a8:	c99ff0ef          	jal	ra,ffffffffc0201e40 <pa2page.part.0>

ffffffffc02021ac <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021ac:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ae:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021b2:	f486                	sd	ra,104(sp)
ffffffffc02021b4:	f0a2                	sd	s0,96(sp)
ffffffffc02021b6:	eca6                	sd	s1,88(sp)
ffffffffc02021b8:	e8ca                	sd	s2,80(sp)
ffffffffc02021ba:	e4ce                	sd	s3,72(sp)
ffffffffc02021bc:	e0d2                	sd	s4,64(sp)
ffffffffc02021be:	fc56                	sd	s5,56(sp)
ffffffffc02021c0:	f85a                	sd	s6,48(sp)
ffffffffc02021c2:	f45e                	sd	s7,40(sp)
ffffffffc02021c4:	f062                	sd	s8,32(sp)
ffffffffc02021c6:	ec66                	sd	s9,24(sp)
ffffffffc02021c8:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ca:	17d2                	slli	a5,a5,0x34
ffffffffc02021cc:	e3ed                	bnez	a5,ffffffffc02022ae <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02021ce:	002007b7          	lui	a5,0x200
ffffffffc02021d2:	842e                	mv	s0,a1
ffffffffc02021d4:	0ef5ed63          	bltu	a1,a5,ffffffffc02022ce <unmap_range+0x122>
ffffffffc02021d8:	8932                	mv	s2,a2
ffffffffc02021da:	0ec5fa63          	bgeu	a1,a2,ffffffffc02022ce <unmap_range+0x122>
ffffffffc02021de:	4785                	li	a5,1
ffffffffc02021e0:	07fe                	slli	a5,a5,0x1f
ffffffffc02021e2:	0ec7e663          	bltu	a5,a2,ffffffffc02022ce <unmap_range+0x122>
ffffffffc02021e6:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021e8:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02021ea:	000a8c97          	auipc	s9,0xa8
ffffffffc02021ee:	4bec8c93          	addi	s9,s9,1214 # ffffffffc02aa6a8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021f2:	000a8c17          	auipc	s8,0xa8
ffffffffc02021f6:	4bec0c13          	addi	s8,s8,1214 # ffffffffc02aa6b0 <pages>
ffffffffc02021fa:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02021fe:	000a8d17          	auipc	s10,0xa8
ffffffffc0202202:	4bad0d13          	addi	s10,s10,1210 # ffffffffc02aa6b8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202206:	00200b37          	lui	s6,0x200
ffffffffc020220a:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020220e:	4601                	li	a2,0
ffffffffc0202210:	85a2                	mv	a1,s0
ffffffffc0202212:	854e                	mv	a0,s3
ffffffffc0202214:	d1dff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
ffffffffc0202218:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020221a:	cd29                	beqz	a0,ffffffffc0202274 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc020221c:	611c                	ld	a5,0(a0)
ffffffffc020221e:	e395                	bnez	a5,ffffffffc0202242 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202220:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202222:	ff2466e3          	bltu	s0,s2,ffffffffc020220e <unmap_range+0x62>
}
ffffffffc0202226:	70a6                	ld	ra,104(sp)
ffffffffc0202228:	7406                	ld	s0,96(sp)
ffffffffc020222a:	64e6                	ld	s1,88(sp)
ffffffffc020222c:	6946                	ld	s2,80(sp)
ffffffffc020222e:	69a6                	ld	s3,72(sp)
ffffffffc0202230:	6a06                	ld	s4,64(sp)
ffffffffc0202232:	7ae2                	ld	s5,56(sp)
ffffffffc0202234:	7b42                	ld	s6,48(sp)
ffffffffc0202236:	7ba2                	ld	s7,40(sp)
ffffffffc0202238:	7c02                	ld	s8,32(sp)
ffffffffc020223a:	6ce2                	ld	s9,24(sp)
ffffffffc020223c:	6d42                	ld	s10,16(sp)
ffffffffc020223e:	6165                	addi	sp,sp,112
ffffffffc0202240:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202242:	0017f713          	andi	a4,a5,1
ffffffffc0202246:	df69                	beqz	a4,ffffffffc0202220 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202248:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020224c:	078a                	slli	a5,a5,0x2
ffffffffc020224e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202250:	08e7ff63          	bgeu	a5,a4,ffffffffc02022ee <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202254:	000c3503          	ld	a0,0(s8)
ffffffffc0202258:	97de                	add	a5,a5,s7
ffffffffc020225a:	079a                	slli	a5,a5,0x6
ffffffffc020225c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020225e:	411c                	lw	a5,0(a0)
ffffffffc0202260:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202264:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202266:	cf11                	beqz	a4,ffffffffc0202282 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc0202268:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020226c:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202270:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202272:	bf45                	j	ffffffffc0202222 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202274:	945a                	add	s0,s0,s6
ffffffffc0202276:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020227a:	d455                	beqz	s0,ffffffffc0202226 <unmap_range+0x7a>
ffffffffc020227c:	f92469e3          	bltu	s0,s2,ffffffffc020220e <unmap_range+0x62>
ffffffffc0202280:	b75d                	j	ffffffffc0202226 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202282:	100027f3          	csrr	a5,sstatus
ffffffffc0202286:	8b89                	andi	a5,a5,2
ffffffffc0202288:	e799                	bnez	a5,ffffffffc0202296 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020228a:	000d3783          	ld	a5,0(s10)
ffffffffc020228e:	4585                	li	a1,1
ffffffffc0202290:	739c                	ld	a5,32(a5)
ffffffffc0202292:	9782                	jalr	a5
    if (flag)
ffffffffc0202294:	bfd1                	j	ffffffffc0202268 <unmap_range+0xbc>
ffffffffc0202296:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202298:	f1cfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020229c:	000d3783          	ld	a5,0(s10)
ffffffffc02022a0:	6522                	ld	a0,8(sp)
ffffffffc02022a2:	4585                	li	a1,1
ffffffffc02022a4:	739c                	ld	a5,32(a5)
ffffffffc02022a6:	9782                	jalr	a5
        intr_enable();
ffffffffc02022a8:	f06fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022ac:	bf75                	j	ffffffffc0202268 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022ae:	00004697          	auipc	a3,0x4
ffffffffc02022b2:	3ba68693          	addi	a3,a3,954 # ffffffffc0206668 <default_pmm_manager+0x160>
ffffffffc02022b6:	00004617          	auipc	a2,0x4
ffffffffc02022ba:	ea260613          	addi	a2,a2,-350 # ffffffffc0206158 <commands+0x818>
ffffffffc02022be:	12000593          	li	a1,288
ffffffffc02022c2:	00004517          	auipc	a0,0x4
ffffffffc02022c6:	39650513          	addi	a0,a0,918 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02022ca:	9c4fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022ce:	00004697          	auipc	a3,0x4
ffffffffc02022d2:	3ca68693          	addi	a3,a3,970 # ffffffffc0206698 <default_pmm_manager+0x190>
ffffffffc02022d6:	00004617          	auipc	a2,0x4
ffffffffc02022da:	e8260613          	addi	a2,a2,-382 # ffffffffc0206158 <commands+0x818>
ffffffffc02022de:	12100593          	li	a1,289
ffffffffc02022e2:	00004517          	auipc	a0,0x4
ffffffffc02022e6:	37650513          	addi	a0,a0,886 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02022ea:	9a4fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02022ee:	b53ff0ef          	jal	ra,ffffffffc0201e40 <pa2page.part.0>

ffffffffc02022f2 <exit_range>:
{
ffffffffc02022f2:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022f4:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02022f8:	fc86                	sd	ra,120(sp)
ffffffffc02022fa:	f8a2                	sd	s0,112(sp)
ffffffffc02022fc:	f4a6                	sd	s1,104(sp)
ffffffffc02022fe:	f0ca                	sd	s2,96(sp)
ffffffffc0202300:	ecce                	sd	s3,88(sp)
ffffffffc0202302:	e8d2                	sd	s4,80(sp)
ffffffffc0202304:	e4d6                	sd	s5,72(sp)
ffffffffc0202306:	e0da                	sd	s6,64(sp)
ffffffffc0202308:	fc5e                	sd	s7,56(sp)
ffffffffc020230a:	f862                	sd	s8,48(sp)
ffffffffc020230c:	f466                	sd	s9,40(sp)
ffffffffc020230e:	f06a                	sd	s10,32(sp)
ffffffffc0202310:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202312:	17d2                	slli	a5,a5,0x34
ffffffffc0202314:	20079a63          	bnez	a5,ffffffffc0202528 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202318:	002007b7          	lui	a5,0x200
ffffffffc020231c:	24f5e463          	bltu	a1,a5,ffffffffc0202564 <exit_range+0x272>
ffffffffc0202320:	8ab2                	mv	s5,a2
ffffffffc0202322:	24c5f163          	bgeu	a1,a2,ffffffffc0202564 <exit_range+0x272>
ffffffffc0202326:	4785                	li	a5,1
ffffffffc0202328:	07fe                	slli	a5,a5,0x1f
ffffffffc020232a:	22c7ed63          	bltu	a5,a2,ffffffffc0202564 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020232e:	c00009b7          	lui	s3,0xc0000
ffffffffc0202332:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202336:	ffe00937          	lui	s2,0xffe00
ffffffffc020233a:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020233e:	5cfd                	li	s9,-1
ffffffffc0202340:	8c2a                	mv	s8,a0
ffffffffc0202342:	0125f933          	and	s2,a1,s2
ffffffffc0202346:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202348:	000a8d17          	auipc	s10,0xa8
ffffffffc020234c:	360d0d13          	addi	s10,s10,864 # ffffffffc02aa6a8 <npage>
    return KADDR(page2pa(page));
ffffffffc0202350:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202354:	000a8717          	auipc	a4,0xa8
ffffffffc0202358:	35c70713          	addi	a4,a4,860 # ffffffffc02aa6b0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020235c:	000a8d97          	auipc	s11,0xa8
ffffffffc0202360:	35cd8d93          	addi	s11,s11,860 # ffffffffc02aa6b8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202364:	c0000437          	lui	s0,0xc0000
ffffffffc0202368:	944e                	add	s0,s0,s3
ffffffffc020236a:	8079                	srli	s0,s0,0x1e
ffffffffc020236c:	1ff47413          	andi	s0,s0,511
ffffffffc0202370:	040e                	slli	s0,s0,0x3
ffffffffc0202372:	9462                	add	s0,s0,s8
ffffffffc0202374:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee8>
        if (pde1 & PTE_V)
ffffffffc0202378:	001a7793          	andi	a5,s4,1
ffffffffc020237c:	eb99                	bnez	a5,ffffffffc0202392 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020237e:	12098463          	beqz	s3,ffffffffc02024a6 <exit_range+0x1b4>
ffffffffc0202382:	400007b7          	lui	a5,0x40000
ffffffffc0202386:	97ce                	add	a5,a5,s3
ffffffffc0202388:	894e                	mv	s2,s3
ffffffffc020238a:	1159fe63          	bgeu	s3,s5,ffffffffc02024a6 <exit_range+0x1b4>
ffffffffc020238e:	89be                	mv	s3,a5
ffffffffc0202390:	bfd1                	j	ffffffffc0202364 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202392:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202396:	0a0a                	slli	s4,s4,0x2
ffffffffc0202398:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc020239c:	1cfa7263          	bgeu	s4,a5,ffffffffc0202560 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023a0:	fff80637          	lui	a2,0xfff80
ffffffffc02023a4:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02023a6:	000806b7          	lui	a3,0x80
ffffffffc02023aa:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02023ac:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02023b0:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023b4:	18f5fa63          	bgeu	a1,a5,ffffffffc0202548 <exit_range+0x256>
ffffffffc02023b8:	000a8817          	auipc	a6,0xa8
ffffffffc02023bc:	30880813          	addi	a6,a6,776 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc02023c0:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02023c4:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02023c6:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02023ca:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02023cc:	00080337          	lui	t1,0x80
ffffffffc02023d0:	6885                	lui	a7,0x1
ffffffffc02023d2:	a819                	j	ffffffffc02023e8 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02023d4:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02023d6:	002007b7          	lui	a5,0x200
ffffffffc02023da:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023dc:	08090c63          	beqz	s2,ffffffffc0202474 <exit_range+0x182>
ffffffffc02023e0:	09397a63          	bgeu	s2,s3,ffffffffc0202474 <exit_range+0x182>
ffffffffc02023e4:	0f597063          	bgeu	s2,s5,ffffffffc02024c4 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023e8:	01595493          	srli	s1,s2,0x15
ffffffffc02023ec:	1ff4f493          	andi	s1,s1,511
ffffffffc02023f0:	048e                	slli	s1,s1,0x3
ffffffffc02023f2:	94da                	add	s1,s1,s6
ffffffffc02023f4:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02023f6:	0017f693          	andi	a3,a5,1
ffffffffc02023fa:	dee9                	beqz	a3,ffffffffc02023d4 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02023fc:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202400:	078a                	slli	a5,a5,0x2
ffffffffc0202402:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202404:	14b7fe63          	bgeu	a5,a1,ffffffffc0202560 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202408:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020240a:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020240e:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202412:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202416:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202418:	12bef863          	bgeu	t4,a1,ffffffffc0202548 <exit_range+0x256>
ffffffffc020241c:	00083783          	ld	a5,0(a6)
ffffffffc0202420:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202422:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0202426:	629c                	ld	a5,0(a3)
ffffffffc0202428:	8b85                	andi	a5,a5,1
ffffffffc020242a:	f7d5                	bnez	a5,ffffffffc02023d6 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020242c:	06a1                	addi	a3,a3,8
ffffffffc020242e:	fed59ce3          	bne	a1,a3,ffffffffc0202426 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202432:	631c                	ld	a5,0(a4)
ffffffffc0202434:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202436:	100027f3          	csrr	a5,sstatus
ffffffffc020243a:	8b89                	andi	a5,a5,2
ffffffffc020243c:	e7d9                	bnez	a5,ffffffffc02024ca <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020243e:	000db783          	ld	a5,0(s11)
ffffffffc0202442:	4585                	li	a1,1
ffffffffc0202444:	e032                	sd	a2,0(sp)
ffffffffc0202446:	739c                	ld	a5,32(a5)
ffffffffc0202448:	9782                	jalr	a5
    if (flag)
ffffffffc020244a:	6602                	ld	a2,0(sp)
ffffffffc020244c:	000a8817          	auipc	a6,0xa8
ffffffffc0202450:	27480813          	addi	a6,a6,628 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0202454:	fff80e37          	lui	t3,0xfff80
ffffffffc0202458:	00080337          	lui	t1,0x80
ffffffffc020245c:	6885                	lui	a7,0x1
ffffffffc020245e:	000a8717          	auipc	a4,0xa8
ffffffffc0202462:	25270713          	addi	a4,a4,594 # ffffffffc02aa6b0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202466:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020246a:	002007b7          	lui	a5,0x200
ffffffffc020246e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202470:	f60918e3          	bnez	s2,ffffffffc02023e0 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202474:	f00b85e3          	beqz	s7,ffffffffc020237e <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202478:	000d3783          	ld	a5,0(s10)
ffffffffc020247c:	0efa7263          	bgeu	s4,a5,ffffffffc0202560 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202480:	6308                	ld	a0,0(a4)
ffffffffc0202482:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202484:	100027f3          	csrr	a5,sstatus
ffffffffc0202488:	8b89                	andi	a5,a5,2
ffffffffc020248a:	efad                	bnez	a5,ffffffffc0202504 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc020248c:	000db783          	ld	a5,0(s11)
ffffffffc0202490:	4585                	li	a1,1
ffffffffc0202492:	739c                	ld	a5,32(a5)
ffffffffc0202494:	9782                	jalr	a5
ffffffffc0202496:	000a8717          	auipc	a4,0xa8
ffffffffc020249a:	21a70713          	addi	a4,a4,538 # ffffffffc02aa6b0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020249e:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02024a2:	ee0990e3          	bnez	s3,ffffffffc0202382 <exit_range+0x90>
}
ffffffffc02024a6:	70e6                	ld	ra,120(sp)
ffffffffc02024a8:	7446                	ld	s0,112(sp)
ffffffffc02024aa:	74a6                	ld	s1,104(sp)
ffffffffc02024ac:	7906                	ld	s2,96(sp)
ffffffffc02024ae:	69e6                	ld	s3,88(sp)
ffffffffc02024b0:	6a46                	ld	s4,80(sp)
ffffffffc02024b2:	6aa6                	ld	s5,72(sp)
ffffffffc02024b4:	6b06                	ld	s6,64(sp)
ffffffffc02024b6:	7be2                	ld	s7,56(sp)
ffffffffc02024b8:	7c42                	ld	s8,48(sp)
ffffffffc02024ba:	7ca2                	ld	s9,40(sp)
ffffffffc02024bc:	7d02                	ld	s10,32(sp)
ffffffffc02024be:	6de2                	ld	s11,24(sp)
ffffffffc02024c0:	6109                	addi	sp,sp,128
ffffffffc02024c2:	8082                	ret
            if (free_pd0)
ffffffffc02024c4:	ea0b8fe3          	beqz	s7,ffffffffc0202382 <exit_range+0x90>
ffffffffc02024c8:	bf45                	j	ffffffffc0202478 <exit_range+0x186>
ffffffffc02024ca:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02024cc:	e42a                	sd	a0,8(sp)
ffffffffc02024ce:	ce6fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024d2:	000db783          	ld	a5,0(s11)
ffffffffc02024d6:	6522                	ld	a0,8(sp)
ffffffffc02024d8:	4585                	li	a1,1
ffffffffc02024da:	739c                	ld	a5,32(a5)
ffffffffc02024dc:	9782                	jalr	a5
        intr_enable();
ffffffffc02024de:	cd0fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02024e2:	6602                	ld	a2,0(sp)
ffffffffc02024e4:	000a8717          	auipc	a4,0xa8
ffffffffc02024e8:	1cc70713          	addi	a4,a4,460 # ffffffffc02aa6b0 <pages>
ffffffffc02024ec:	6885                	lui	a7,0x1
ffffffffc02024ee:	00080337          	lui	t1,0x80
ffffffffc02024f2:	fff80e37          	lui	t3,0xfff80
ffffffffc02024f6:	000a8817          	auipc	a6,0xa8
ffffffffc02024fa:	1ca80813          	addi	a6,a6,458 # ffffffffc02aa6c0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024fe:	0004b023          	sd	zero,0(s1)
ffffffffc0202502:	b7a5                	j	ffffffffc020246a <exit_range+0x178>
ffffffffc0202504:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202506:	caefe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020250a:	000db783          	ld	a5,0(s11)
ffffffffc020250e:	6502                	ld	a0,0(sp)
ffffffffc0202510:	4585                	li	a1,1
ffffffffc0202512:	739c                	ld	a5,32(a5)
ffffffffc0202514:	9782                	jalr	a5
        intr_enable();
ffffffffc0202516:	c98fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020251a:	000a8717          	auipc	a4,0xa8
ffffffffc020251e:	19670713          	addi	a4,a4,406 # ffffffffc02aa6b0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202522:	00043023          	sd	zero,0(s0)
ffffffffc0202526:	bfb5                	j	ffffffffc02024a2 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202528:	00004697          	auipc	a3,0x4
ffffffffc020252c:	14068693          	addi	a3,a3,320 # ffffffffc0206668 <default_pmm_manager+0x160>
ffffffffc0202530:	00004617          	auipc	a2,0x4
ffffffffc0202534:	c2860613          	addi	a2,a2,-984 # ffffffffc0206158 <commands+0x818>
ffffffffc0202538:	13500593          	li	a1,309
ffffffffc020253c:	00004517          	auipc	a0,0x4
ffffffffc0202540:	11c50513          	addi	a0,a0,284 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202544:	f4bfd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202548:	00004617          	auipc	a2,0x4
ffffffffc020254c:	ff860613          	addi	a2,a2,-8 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0202550:	07100593          	li	a1,113
ffffffffc0202554:	00004517          	auipc	a0,0x4
ffffffffc0202558:	01450513          	addi	a0,a0,20 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc020255c:	f33fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202560:	8e1ff0ef          	jal	ra,ffffffffc0201e40 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202564:	00004697          	auipc	a3,0x4
ffffffffc0202568:	13468693          	addi	a3,a3,308 # ffffffffc0206698 <default_pmm_manager+0x190>
ffffffffc020256c:	00004617          	auipc	a2,0x4
ffffffffc0202570:	bec60613          	addi	a2,a2,-1044 # ffffffffc0206158 <commands+0x818>
ffffffffc0202574:	13600593          	li	a1,310
ffffffffc0202578:	00004517          	auipc	a0,0x4
ffffffffc020257c:	0e050513          	addi	a0,a0,224 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202580:	f0ffd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202584 <page_remove>:
{
ffffffffc0202584:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202586:	4601                	li	a2,0
{
ffffffffc0202588:	ec26                	sd	s1,24(sp)
ffffffffc020258a:	f406                	sd	ra,40(sp)
ffffffffc020258c:	f022                	sd	s0,32(sp)
ffffffffc020258e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202590:	9a1ff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
    if (ptep != NULL)
ffffffffc0202594:	c511                	beqz	a0,ffffffffc02025a0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0202596:	611c                	ld	a5,0(a0)
ffffffffc0202598:	842a                	mv	s0,a0
ffffffffc020259a:	0017f713          	andi	a4,a5,1
ffffffffc020259e:	e711                	bnez	a4,ffffffffc02025aa <page_remove+0x26>
}
ffffffffc02025a0:	70a2                	ld	ra,40(sp)
ffffffffc02025a2:	7402                	ld	s0,32(sp)
ffffffffc02025a4:	64e2                	ld	s1,24(sp)
ffffffffc02025a6:	6145                	addi	sp,sp,48
ffffffffc02025a8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02025aa:	078a                	slli	a5,a5,0x2
ffffffffc02025ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025ae:	000a8717          	auipc	a4,0xa8
ffffffffc02025b2:	0fa73703          	ld	a4,250(a4) # ffffffffc02aa6a8 <npage>
ffffffffc02025b6:	06e7f363          	bgeu	a5,a4,ffffffffc020261c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ba:	fff80537          	lui	a0,0xfff80
ffffffffc02025be:	97aa                	add	a5,a5,a0
ffffffffc02025c0:	079a                	slli	a5,a5,0x6
ffffffffc02025c2:	000a8517          	auipc	a0,0xa8
ffffffffc02025c6:	0ee53503          	ld	a0,238(a0) # ffffffffc02aa6b0 <pages>
ffffffffc02025ca:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02025cc:	411c                	lw	a5,0(a0)
ffffffffc02025ce:	fff7871b          	addiw	a4,a5,-1
ffffffffc02025d2:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02025d4:	cb11                	beqz	a4,ffffffffc02025e8 <page_remove+0x64>
        *ptep = 0;
ffffffffc02025d6:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025da:	12048073          	sfence.vma	s1
}
ffffffffc02025de:	70a2                	ld	ra,40(sp)
ffffffffc02025e0:	7402                	ld	s0,32(sp)
ffffffffc02025e2:	64e2                	ld	s1,24(sp)
ffffffffc02025e4:	6145                	addi	sp,sp,48
ffffffffc02025e6:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025e8:	100027f3          	csrr	a5,sstatus
ffffffffc02025ec:	8b89                	andi	a5,a5,2
ffffffffc02025ee:	eb89                	bnez	a5,ffffffffc0202600 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02025f0:	000a8797          	auipc	a5,0xa8
ffffffffc02025f4:	0c87b783          	ld	a5,200(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc02025f8:	739c                	ld	a5,32(a5)
ffffffffc02025fa:	4585                	li	a1,1
ffffffffc02025fc:	9782                	jalr	a5
    if (flag)
ffffffffc02025fe:	bfe1                	j	ffffffffc02025d6 <page_remove+0x52>
        intr_disable();
ffffffffc0202600:	e42a                	sd	a0,8(sp)
ffffffffc0202602:	bb2fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202606:	000a8797          	auipc	a5,0xa8
ffffffffc020260a:	0b27b783          	ld	a5,178(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020260e:	739c                	ld	a5,32(a5)
ffffffffc0202610:	6522                	ld	a0,8(sp)
ffffffffc0202612:	4585                	li	a1,1
ffffffffc0202614:	9782                	jalr	a5
        intr_enable();
ffffffffc0202616:	b98fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020261a:	bf75                	j	ffffffffc02025d6 <page_remove+0x52>
ffffffffc020261c:	825ff0ef          	jal	ra,ffffffffc0201e40 <pa2page.part.0>

ffffffffc0202620 <page_insert>:
{
ffffffffc0202620:	7139                	addi	sp,sp,-64
ffffffffc0202622:	e852                	sd	s4,16(sp)
ffffffffc0202624:	8a32                	mv	s4,a2
ffffffffc0202626:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202628:	4605                	li	a2,1
{
ffffffffc020262a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020262c:	85d2                	mv	a1,s4
{
ffffffffc020262e:	f426                	sd	s1,40(sp)
ffffffffc0202630:	fc06                	sd	ra,56(sp)
ffffffffc0202632:	f04a                	sd	s2,32(sp)
ffffffffc0202634:	ec4e                	sd	s3,24(sp)
ffffffffc0202636:	e456                	sd	s5,8(sp)
ffffffffc0202638:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020263a:	8f7ff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
    if (ptep == NULL)
ffffffffc020263e:	c961                	beqz	a0,ffffffffc020270e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202640:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202642:	611c                	ld	a5,0(a0)
ffffffffc0202644:	89aa                	mv	s3,a0
ffffffffc0202646:	0016871b          	addiw	a4,a3,1
ffffffffc020264a:	c018                	sw	a4,0(s0)
ffffffffc020264c:	0017f713          	andi	a4,a5,1
ffffffffc0202650:	ef05                	bnez	a4,ffffffffc0202688 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202652:	000a8717          	auipc	a4,0xa8
ffffffffc0202656:	05e73703          	ld	a4,94(a4) # ffffffffc02aa6b0 <pages>
ffffffffc020265a:	8c19                	sub	s0,s0,a4
ffffffffc020265c:	000807b7          	lui	a5,0x80
ffffffffc0202660:	8419                	srai	s0,s0,0x6
ffffffffc0202662:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202664:	042a                	slli	s0,s0,0xa
ffffffffc0202666:	8cc1                	or	s1,s1,s0
ffffffffc0202668:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020266c:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202670:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202674:	4501                	li	a0,0
}
ffffffffc0202676:	70e2                	ld	ra,56(sp)
ffffffffc0202678:	7442                	ld	s0,48(sp)
ffffffffc020267a:	74a2                	ld	s1,40(sp)
ffffffffc020267c:	7902                	ld	s2,32(sp)
ffffffffc020267e:	69e2                	ld	s3,24(sp)
ffffffffc0202680:	6a42                	ld	s4,16(sp)
ffffffffc0202682:	6aa2                	ld	s5,8(sp)
ffffffffc0202684:	6121                	addi	sp,sp,64
ffffffffc0202686:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202688:	078a                	slli	a5,a5,0x2
ffffffffc020268a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020268c:	000a8717          	auipc	a4,0xa8
ffffffffc0202690:	01c73703          	ld	a4,28(a4) # ffffffffc02aa6a8 <npage>
ffffffffc0202694:	06e7ff63          	bgeu	a5,a4,ffffffffc0202712 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202698:	000a8a97          	auipc	s5,0xa8
ffffffffc020269c:	018a8a93          	addi	s5,s5,24 # ffffffffc02aa6b0 <pages>
ffffffffc02026a0:	000ab703          	ld	a4,0(s5)
ffffffffc02026a4:	fff80937          	lui	s2,0xfff80
ffffffffc02026a8:	993e                	add	s2,s2,a5
ffffffffc02026aa:	091a                	slli	s2,s2,0x6
ffffffffc02026ac:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02026ae:	01240c63          	beq	s0,s2,ffffffffc02026c6 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02026b2:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd591c>
ffffffffc02026b6:	fff7869b          	addiw	a3,a5,-1
ffffffffc02026ba:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02026be:	c691                	beqz	a3,ffffffffc02026ca <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026c0:	120a0073          	sfence.vma	s4
}
ffffffffc02026c4:	bf59                	j	ffffffffc020265a <page_insert+0x3a>
ffffffffc02026c6:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02026c8:	bf49                	j	ffffffffc020265a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026ca:	100027f3          	csrr	a5,sstatus
ffffffffc02026ce:	8b89                	andi	a5,a5,2
ffffffffc02026d0:	ef91                	bnez	a5,ffffffffc02026ec <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02026d2:	000a8797          	auipc	a5,0xa8
ffffffffc02026d6:	fe67b783          	ld	a5,-26(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc02026da:	739c                	ld	a5,32(a5)
ffffffffc02026dc:	4585                	li	a1,1
ffffffffc02026de:	854a                	mv	a0,s2
ffffffffc02026e0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02026e2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026e6:	120a0073          	sfence.vma	s4
ffffffffc02026ea:	bf85                	j	ffffffffc020265a <page_insert+0x3a>
        intr_disable();
ffffffffc02026ec:	ac8fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026f0:	000a8797          	auipc	a5,0xa8
ffffffffc02026f4:	fc87b783          	ld	a5,-56(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc02026f8:	739c                	ld	a5,32(a5)
ffffffffc02026fa:	4585                	li	a1,1
ffffffffc02026fc:	854a                	mv	a0,s2
ffffffffc02026fe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202700:	aaefe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202704:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202708:	120a0073          	sfence.vma	s4
ffffffffc020270c:	b7b9                	j	ffffffffc020265a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020270e:	5571                	li	a0,-4
ffffffffc0202710:	b79d                	j	ffffffffc0202676 <page_insert+0x56>
ffffffffc0202712:	f2eff0ef          	jal	ra,ffffffffc0201e40 <pa2page.part.0>

ffffffffc0202716 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202716:	00004797          	auipc	a5,0x4
ffffffffc020271a:	df278793          	addi	a5,a5,-526 # ffffffffc0206508 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020271e:	638c                	ld	a1,0(a5)
{
ffffffffc0202720:	7159                	addi	sp,sp,-112
ffffffffc0202722:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202724:	00004517          	auipc	a0,0x4
ffffffffc0202728:	f8c50513          	addi	a0,a0,-116 # ffffffffc02066b0 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc020272c:	000a8b17          	auipc	s6,0xa8
ffffffffc0202730:	f8cb0b13          	addi	s6,s6,-116 # ffffffffc02aa6b8 <pmm_manager>
{
ffffffffc0202734:	f486                	sd	ra,104(sp)
ffffffffc0202736:	e8ca                	sd	s2,80(sp)
ffffffffc0202738:	e4ce                	sd	s3,72(sp)
ffffffffc020273a:	f0a2                	sd	s0,96(sp)
ffffffffc020273c:	eca6                	sd	s1,88(sp)
ffffffffc020273e:	e0d2                	sd	s4,64(sp)
ffffffffc0202740:	fc56                	sd	s5,56(sp)
ffffffffc0202742:	f45e                	sd	s7,40(sp)
ffffffffc0202744:	f062                	sd	s8,32(sp)
ffffffffc0202746:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202748:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020274c:	a49fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202750:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202754:	000a8997          	auipc	s3,0xa8
ffffffffc0202758:	f6c98993          	addi	s3,s3,-148 # ffffffffc02aa6c0 <va_pa_offset>
    pmm_manager->init();
ffffffffc020275c:	679c                	ld	a5,8(a5)
ffffffffc020275e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202760:	57f5                	li	a5,-3
ffffffffc0202762:	07fa                	slli	a5,a5,0x1e
ffffffffc0202764:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202768:	a32fe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc020276c:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020276e:	a36fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202772:	200505e3          	beqz	a0,ffffffffc020317c <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202776:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202778:	00004517          	auipc	a0,0x4
ffffffffc020277c:	f7050513          	addi	a0,a0,-144 # ffffffffc02066e8 <default_pmm_manager+0x1e0>
ffffffffc0202780:	a15fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202784:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202788:	fff40693          	addi	a3,s0,-1
ffffffffc020278c:	864a                	mv	a2,s2
ffffffffc020278e:	85a6                	mv	a1,s1
ffffffffc0202790:	00004517          	auipc	a0,0x4
ffffffffc0202794:	f7050513          	addi	a0,a0,-144 # ffffffffc0206700 <default_pmm_manager+0x1f8>
ffffffffc0202798:	9fdfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020279c:	c8000737          	lui	a4,0xc8000
ffffffffc02027a0:	87a2                	mv	a5,s0
ffffffffc02027a2:	54876163          	bltu	a4,s0,ffffffffc0202ce4 <pmm_init+0x5ce>
ffffffffc02027a6:	757d                	lui	a0,0xfffff
ffffffffc02027a8:	000a9617          	auipc	a2,0xa9
ffffffffc02027ac:	f3b60613          	addi	a2,a2,-197 # ffffffffc02ab6e3 <end+0xfff>
ffffffffc02027b0:	8e69                	and	a2,a2,a0
ffffffffc02027b2:	000a8497          	auipc	s1,0xa8
ffffffffc02027b6:	ef648493          	addi	s1,s1,-266 # ffffffffc02aa6a8 <npage>
ffffffffc02027ba:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027be:	000a8b97          	auipc	s7,0xa8
ffffffffc02027c2:	ef2b8b93          	addi	s7,s7,-270 # ffffffffc02aa6b0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02027c6:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027c8:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027cc:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027d0:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027d2:	02f50863          	beq	a0,a5,ffffffffc0202802 <pmm_init+0xec>
ffffffffc02027d6:	4781                	li	a5,0
ffffffffc02027d8:	4585                	li	a1,1
ffffffffc02027da:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02027de:	00679513          	slli	a0,a5,0x6
ffffffffc02027e2:	9532                	add	a0,a0,a2
ffffffffc02027e4:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd54924>
ffffffffc02027e8:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027ec:	6088                	ld	a0,0(s1)
ffffffffc02027ee:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02027f0:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027f4:	00d50733          	add	a4,a0,a3
ffffffffc02027f8:	fee7e3e3          	bltu	a5,a4,ffffffffc02027de <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027fc:	071a                	slli	a4,a4,0x6
ffffffffc02027fe:	00e606b3          	add	a3,a2,a4
ffffffffc0202802:	c02007b7          	lui	a5,0xc0200
ffffffffc0202806:	2ef6ece3          	bltu	a3,a5,ffffffffc02032fe <pmm_init+0xbe8>
ffffffffc020280a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020280e:	77fd                	lui	a5,0xfffff
ffffffffc0202810:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202812:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202814:	5086eb63          	bltu	a3,s0,ffffffffc0202d2a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202818:	00004517          	auipc	a0,0x4
ffffffffc020281c:	f1050513          	addi	a0,a0,-240 # ffffffffc0206728 <default_pmm_manager+0x220>
ffffffffc0202820:	975fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202824:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202828:	000a8917          	auipc	s2,0xa8
ffffffffc020282c:	e7890913          	addi	s2,s2,-392 # ffffffffc02aa6a0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202830:	7b9c                	ld	a5,48(a5)
ffffffffc0202832:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202834:	00004517          	auipc	a0,0x4
ffffffffc0202838:	f0c50513          	addi	a0,a0,-244 # ffffffffc0206740 <default_pmm_manager+0x238>
ffffffffc020283c:	959fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202840:	00007697          	auipc	a3,0x7
ffffffffc0202844:	7c068693          	addi	a3,a3,1984 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202848:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020284c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202850:	28f6ebe3          	bltu	a3,a5,ffffffffc02032e6 <pmm_init+0xbd0>
ffffffffc0202854:	0009b783          	ld	a5,0(s3)
ffffffffc0202858:	8e9d                	sub	a3,a3,a5
ffffffffc020285a:	000a8797          	auipc	a5,0xa8
ffffffffc020285e:	e2d7bf23          	sd	a3,-450(a5) # ffffffffc02aa698 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202862:	100027f3          	csrr	a5,sstatus
ffffffffc0202866:	8b89                	andi	a5,a5,2
ffffffffc0202868:	4a079763          	bnez	a5,ffffffffc0202d16 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020286c:	000b3783          	ld	a5,0(s6)
ffffffffc0202870:	779c                	ld	a5,40(a5)
ffffffffc0202872:	9782                	jalr	a5
ffffffffc0202874:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202876:	6098                	ld	a4,0(s1)
ffffffffc0202878:	c80007b7          	lui	a5,0xc8000
ffffffffc020287c:	83b1                	srli	a5,a5,0xc
ffffffffc020287e:	66e7e363          	bltu	a5,a4,ffffffffc0202ee4 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202882:	00093503          	ld	a0,0(s2)
ffffffffc0202886:	62050f63          	beqz	a0,ffffffffc0202ec4 <pmm_init+0x7ae>
ffffffffc020288a:	03451793          	slli	a5,a0,0x34
ffffffffc020288e:	62079b63          	bnez	a5,ffffffffc0202ec4 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202892:	4601                	li	a2,0
ffffffffc0202894:	4581                	li	a1,0
ffffffffc0202896:	8c3ff0ef          	jal	ra,ffffffffc0202158 <get_page>
ffffffffc020289a:	60051563          	bnez	a0,ffffffffc0202ea4 <pmm_init+0x78e>
ffffffffc020289e:	100027f3          	csrr	a5,sstatus
ffffffffc02028a2:	8b89                	andi	a5,a5,2
ffffffffc02028a4:	44079e63          	bnez	a5,ffffffffc0202d00 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028a8:	000b3783          	ld	a5,0(s6)
ffffffffc02028ac:	4505                	li	a0,1
ffffffffc02028ae:	6f9c                	ld	a5,24(a5)
ffffffffc02028b0:	9782                	jalr	a5
ffffffffc02028b2:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02028b4:	00093503          	ld	a0,0(s2)
ffffffffc02028b8:	4681                	li	a3,0
ffffffffc02028ba:	4601                	li	a2,0
ffffffffc02028bc:	85d2                	mv	a1,s4
ffffffffc02028be:	d63ff0ef          	jal	ra,ffffffffc0202620 <page_insert>
ffffffffc02028c2:	26051ae3          	bnez	a0,ffffffffc0203336 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028c6:	00093503          	ld	a0,0(s2)
ffffffffc02028ca:	4601                	li	a2,0
ffffffffc02028cc:	4581                	li	a1,0
ffffffffc02028ce:	e62ff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
ffffffffc02028d2:	240502e3          	beqz	a0,ffffffffc0203316 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02028d6:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028d8:	0017f713          	andi	a4,a5,1
ffffffffc02028dc:	5a070263          	beqz	a4,ffffffffc0202e80 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028e0:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028e2:	078a                	slli	a5,a5,0x2
ffffffffc02028e4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028e6:	58e7fb63          	bgeu	a5,a4,ffffffffc0202e7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ea:	000bb683          	ld	a3,0(s7)
ffffffffc02028ee:	fff80637          	lui	a2,0xfff80
ffffffffc02028f2:	97b2                	add	a5,a5,a2
ffffffffc02028f4:	079a                	slli	a5,a5,0x6
ffffffffc02028f6:	97b6                	add	a5,a5,a3
ffffffffc02028f8:	14fa17e3          	bne	s4,a5,ffffffffc0203246 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02028fc:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba0>
ffffffffc0202900:	4785                	li	a5,1
ffffffffc0202902:	12f692e3          	bne	a3,a5,ffffffffc0203226 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202906:	00093503          	ld	a0,0(s2)
ffffffffc020290a:	77fd                	lui	a5,0xfffff
ffffffffc020290c:	6114                	ld	a3,0(a0)
ffffffffc020290e:	068a                	slli	a3,a3,0x2
ffffffffc0202910:	8efd                	and	a3,a3,a5
ffffffffc0202912:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202916:	0ee67ce3          	bgeu	a2,a4,ffffffffc020320e <pmm_init+0xaf8>
ffffffffc020291a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020291e:	96e2                	add	a3,a3,s8
ffffffffc0202920:	0006ba83          	ld	s5,0(a3)
ffffffffc0202924:	0a8a                	slli	s5,s5,0x2
ffffffffc0202926:	00fafab3          	and	s5,s5,a5
ffffffffc020292a:	00cad793          	srli	a5,s5,0xc
ffffffffc020292e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02031f4 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202932:	4601                	li	a2,0
ffffffffc0202934:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202936:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202938:	df8ff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020293c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020293e:	55551363          	bne	a0,s5,ffffffffc0202e84 <pmm_init+0x76e>
ffffffffc0202942:	100027f3          	csrr	a5,sstatus
ffffffffc0202946:	8b89                	andi	a5,a5,2
ffffffffc0202948:	3a079163          	bnez	a5,ffffffffc0202cea <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020294c:	000b3783          	ld	a5,0(s6)
ffffffffc0202950:	4505                	li	a0,1
ffffffffc0202952:	6f9c                	ld	a5,24(a5)
ffffffffc0202954:	9782                	jalr	a5
ffffffffc0202956:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202958:	00093503          	ld	a0,0(s2)
ffffffffc020295c:	46d1                	li	a3,20
ffffffffc020295e:	6605                	lui	a2,0x1
ffffffffc0202960:	85e2                	mv	a1,s8
ffffffffc0202962:	cbfff0ef          	jal	ra,ffffffffc0202620 <page_insert>
ffffffffc0202966:	060517e3          	bnez	a0,ffffffffc02031d4 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020296a:	00093503          	ld	a0,0(s2)
ffffffffc020296e:	4601                	li	a2,0
ffffffffc0202970:	6585                	lui	a1,0x1
ffffffffc0202972:	dbeff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
ffffffffc0202976:	02050fe3          	beqz	a0,ffffffffc02031b4 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020297a:	611c                	ld	a5,0(a0)
ffffffffc020297c:	0107f713          	andi	a4,a5,16
ffffffffc0202980:	7c070e63          	beqz	a4,ffffffffc020315c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202984:	8b91                	andi	a5,a5,4
ffffffffc0202986:	7a078b63          	beqz	a5,ffffffffc020313c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020298a:	00093503          	ld	a0,0(s2)
ffffffffc020298e:	611c                	ld	a5,0(a0)
ffffffffc0202990:	8bc1                	andi	a5,a5,16
ffffffffc0202992:	78078563          	beqz	a5,ffffffffc020311c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202996:	000c2703          	lw	a4,0(s8)
ffffffffc020299a:	4785                	li	a5,1
ffffffffc020299c:	76f71063          	bne	a4,a5,ffffffffc02030fc <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029a0:	4681                	li	a3,0
ffffffffc02029a2:	6605                	lui	a2,0x1
ffffffffc02029a4:	85d2                	mv	a1,s4
ffffffffc02029a6:	c7bff0ef          	jal	ra,ffffffffc0202620 <page_insert>
ffffffffc02029aa:	72051963          	bnez	a0,ffffffffc02030dc <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02029ae:	000a2703          	lw	a4,0(s4)
ffffffffc02029b2:	4789                	li	a5,2
ffffffffc02029b4:	70f71463          	bne	a4,a5,ffffffffc02030bc <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02029b8:	000c2783          	lw	a5,0(s8)
ffffffffc02029bc:	6e079063          	bnez	a5,ffffffffc020309c <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029c0:	00093503          	ld	a0,0(s2)
ffffffffc02029c4:	4601                	li	a2,0
ffffffffc02029c6:	6585                	lui	a1,0x1
ffffffffc02029c8:	d68ff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
ffffffffc02029cc:	6a050863          	beqz	a0,ffffffffc020307c <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02029d0:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029d2:	00177793          	andi	a5,a4,1
ffffffffc02029d6:	4a078563          	beqz	a5,ffffffffc0202e80 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029da:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029dc:	00271793          	slli	a5,a4,0x2
ffffffffc02029e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029e2:	48d7fd63          	bgeu	a5,a3,ffffffffc0202e7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029e6:	000bb683          	ld	a3,0(s7)
ffffffffc02029ea:	fff80ab7          	lui	s5,0xfff80
ffffffffc02029ee:	97d6                	add	a5,a5,s5
ffffffffc02029f0:	079a                	slli	a5,a5,0x6
ffffffffc02029f2:	97b6                	add	a5,a5,a3
ffffffffc02029f4:	66fa1463          	bne	s4,a5,ffffffffc020305c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02029f8:	8b41                	andi	a4,a4,16
ffffffffc02029fa:	64071163          	bnez	a4,ffffffffc020303c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02029fe:	00093503          	ld	a0,0(s2)
ffffffffc0202a02:	4581                	li	a1,0
ffffffffc0202a04:	b81ff0ef          	jal	ra,ffffffffc0202584 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a08:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a0c:	4785                	li	a5,1
ffffffffc0202a0e:	60fc9763          	bne	s9,a5,ffffffffc020301c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a12:	000c2783          	lw	a5,0(s8)
ffffffffc0202a16:	5e079363          	bnez	a5,ffffffffc0202ffc <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a1a:	00093503          	ld	a0,0(s2)
ffffffffc0202a1e:	6585                	lui	a1,0x1
ffffffffc0202a20:	b65ff0ef          	jal	ra,ffffffffc0202584 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a24:	000a2783          	lw	a5,0(s4)
ffffffffc0202a28:	52079a63          	bnez	a5,ffffffffc0202f5c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a2c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a30:	50079663          	bnez	a5,ffffffffc0202f3c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a34:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a38:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a3a:	000a3683          	ld	a3,0(s4)
ffffffffc0202a3e:	068a                	slli	a3,a3,0x2
ffffffffc0202a40:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a42:	42b6fd63          	bgeu	a3,a1,ffffffffc0202e7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a46:	000bb503          	ld	a0,0(s7)
ffffffffc0202a4a:	96d6                	add	a3,a3,s5
ffffffffc0202a4c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202a4e:	00d507b3          	add	a5,a0,a3
ffffffffc0202a52:	439c                	lw	a5,0(a5)
ffffffffc0202a54:	4d979463          	bne	a5,s9,ffffffffc0202f1c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202a58:	8699                	srai	a3,a3,0x6
ffffffffc0202a5a:	00080637          	lui	a2,0x80
ffffffffc0202a5e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202a60:	00c69713          	slli	a4,a3,0xc
ffffffffc0202a64:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a66:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a68:	48b77e63          	bgeu	a4,a1,ffffffffc0202f04 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a6c:	0009b703          	ld	a4,0(s3)
ffffffffc0202a70:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a72:	629c                	ld	a5,0(a3)
ffffffffc0202a74:	078a                	slli	a5,a5,0x2
ffffffffc0202a76:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a78:	40b7f263          	bgeu	a5,a1,ffffffffc0202e7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a7c:	8f91                	sub	a5,a5,a2
ffffffffc0202a7e:	079a                	slli	a5,a5,0x6
ffffffffc0202a80:	953e                	add	a0,a0,a5
ffffffffc0202a82:	100027f3          	csrr	a5,sstatus
ffffffffc0202a86:	8b89                	andi	a5,a5,2
ffffffffc0202a88:	30079963          	bnez	a5,ffffffffc0202d9a <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202a8c:	000b3783          	ld	a5,0(s6)
ffffffffc0202a90:	4585                	li	a1,1
ffffffffc0202a92:	739c                	ld	a5,32(a5)
ffffffffc0202a94:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a96:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202a9a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a9c:	078a                	slli	a5,a5,0x2
ffffffffc0202a9e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aa0:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202e7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aa4:	000bb503          	ld	a0,0(s7)
ffffffffc0202aa8:	fff80737          	lui	a4,0xfff80
ffffffffc0202aac:	97ba                	add	a5,a5,a4
ffffffffc0202aae:	079a                	slli	a5,a5,0x6
ffffffffc0202ab0:	953e                	add	a0,a0,a5
ffffffffc0202ab2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ab6:	8b89                	andi	a5,a5,2
ffffffffc0202ab8:	2c079563          	bnez	a5,ffffffffc0202d82 <pmm_init+0x66c>
ffffffffc0202abc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ac0:	4585                	li	a1,1
ffffffffc0202ac2:	739c                	ld	a5,32(a5)
ffffffffc0202ac4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ac6:	00093783          	ld	a5,0(s2)
ffffffffc0202aca:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd5491c>
    asm volatile("sfence.vma");
ffffffffc0202ace:	12000073          	sfence.vma
ffffffffc0202ad2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ad6:	8b89                	andi	a5,a5,2
ffffffffc0202ad8:	28079b63          	bnez	a5,ffffffffc0202d6e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202adc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ae0:	779c                	ld	a5,40(a5)
ffffffffc0202ae2:	9782                	jalr	a5
ffffffffc0202ae4:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202ae6:	4b441b63          	bne	s0,s4,ffffffffc0202f9c <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202aea:	00004517          	auipc	a0,0x4
ffffffffc0202aee:	f7e50513          	addi	a0,a0,-130 # ffffffffc0206a68 <default_pmm_manager+0x560>
ffffffffc0202af2:	ea2fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202af6:	100027f3          	csrr	a5,sstatus
ffffffffc0202afa:	8b89                	andi	a5,a5,2
ffffffffc0202afc:	24079f63          	bnez	a5,ffffffffc0202d5a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b00:	000b3783          	ld	a5,0(s6)
ffffffffc0202b04:	779c                	ld	a5,40(a5)
ffffffffc0202b06:	9782                	jalr	a5
ffffffffc0202b08:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b0a:	6098                	ld	a4,0(s1)
ffffffffc0202b0c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b10:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b12:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b16:	6a05                	lui	s4,0x1
ffffffffc0202b18:	02f47c63          	bgeu	s0,a5,ffffffffc0202b50 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b1c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b20:	00093503          	ld	a0,0(s2)
ffffffffc0202b24:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e22 <pmm_init+0x70c>
ffffffffc0202b28:	0009b583          	ld	a1,0(s3)
ffffffffc0202b2c:	4601                	li	a2,0
ffffffffc0202b2e:	95a2                	add	a1,a1,s0
ffffffffc0202b30:	c00ff0ef          	jal	ra,ffffffffc0201f30 <get_pte>
ffffffffc0202b34:	32050463          	beqz	a0,ffffffffc0202e5c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b38:	611c                	ld	a5,0(a0)
ffffffffc0202b3a:	078a                	slli	a5,a5,0x2
ffffffffc0202b3c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202b40:	2e879e63          	bne	a5,s0,ffffffffc0202e3c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b44:	6098                	ld	a4,0(s1)
ffffffffc0202b46:	9452                	add	s0,s0,s4
ffffffffc0202b48:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b4c:	fcf468e3          	bltu	s0,a5,ffffffffc0202b1c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b50:	00093783          	ld	a5,0(s2)
ffffffffc0202b54:	639c                	ld	a5,0(a5)
ffffffffc0202b56:	42079363          	bnez	a5,ffffffffc0202f7c <pmm_init+0x866>
ffffffffc0202b5a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b5e:	8b89                	andi	a5,a5,2
ffffffffc0202b60:	24079963          	bnez	a5,ffffffffc0202db2 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b64:	000b3783          	ld	a5,0(s6)
ffffffffc0202b68:	4505                	li	a0,1
ffffffffc0202b6a:	6f9c                	ld	a5,24(a5)
ffffffffc0202b6c:	9782                	jalr	a5
ffffffffc0202b6e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b70:	00093503          	ld	a0,0(s2)
ffffffffc0202b74:	4699                	li	a3,6
ffffffffc0202b76:	10000613          	li	a2,256
ffffffffc0202b7a:	85d2                	mv	a1,s4
ffffffffc0202b7c:	aa5ff0ef          	jal	ra,ffffffffc0202620 <page_insert>
ffffffffc0202b80:	44051e63          	bnez	a0,ffffffffc0202fdc <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202b84:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba0>
ffffffffc0202b88:	4785                	li	a5,1
ffffffffc0202b8a:	42f71963          	bne	a4,a5,ffffffffc0202fbc <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202b8e:	00093503          	ld	a0,0(s2)
ffffffffc0202b92:	6405                	lui	s0,0x1
ffffffffc0202b94:	4699                	li	a3,6
ffffffffc0202b96:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa0>
ffffffffc0202b9a:	85d2                	mv	a1,s4
ffffffffc0202b9c:	a85ff0ef          	jal	ra,ffffffffc0202620 <page_insert>
ffffffffc0202ba0:	72051363          	bnez	a0,ffffffffc02032c6 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202ba4:	000a2703          	lw	a4,0(s4)
ffffffffc0202ba8:	4789                	li	a5,2
ffffffffc0202baa:	6ef71e63          	bne	a4,a5,ffffffffc02032a6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bae:	00004597          	auipc	a1,0x4
ffffffffc0202bb2:	00258593          	addi	a1,a1,2 # ffffffffc0206bb0 <default_pmm_manager+0x6a8>
ffffffffc0202bb6:	10000513          	li	a0,256
ffffffffc0202bba:	289020ef          	jal	ra,ffffffffc0205642 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202bbe:	10040593          	addi	a1,s0,256
ffffffffc0202bc2:	10000513          	li	a0,256
ffffffffc0202bc6:	28f020ef          	jal	ra,ffffffffc0205654 <strcmp>
ffffffffc0202bca:	6a051e63          	bnez	a0,ffffffffc0203286 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202bce:	000bb683          	ld	a3,0(s7)
ffffffffc0202bd2:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202bd6:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202bd8:	40da06b3          	sub	a3,s4,a3
ffffffffc0202bdc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202bde:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202be0:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202be2:	8031                	srli	s0,s0,0xc
ffffffffc0202be4:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202be8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bea:	30f77d63          	bgeu	a4,a5,ffffffffc0202f04 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bee:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202bf2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bf6:	96be                	add	a3,a3,a5
ffffffffc0202bf8:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202bfc:	211020ef          	jal	ra,ffffffffc020560c <strlen>
ffffffffc0202c00:	66051363          	bnez	a0,ffffffffc0203266 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c04:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c08:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c0a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd5491c>
ffffffffc0202c0e:	068a                	slli	a3,a3,0x2
ffffffffc0202c10:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c12:	26f6f563          	bgeu	a3,a5,ffffffffc0202e7c <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202c16:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c18:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c1a:	2ef47563          	bgeu	s0,a5,ffffffffc0202f04 <pmm_init+0x7ee>
ffffffffc0202c1e:	0009b403          	ld	s0,0(s3)
ffffffffc0202c22:	9436                	add	s0,s0,a3
ffffffffc0202c24:	100027f3          	csrr	a5,sstatus
ffffffffc0202c28:	8b89                	andi	a5,a5,2
ffffffffc0202c2a:	1e079163          	bnez	a5,ffffffffc0202e0c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c32:	4585                	li	a1,1
ffffffffc0202c34:	8552                	mv	a0,s4
ffffffffc0202c36:	739c                	ld	a5,32(a5)
ffffffffc0202c38:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c3a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202c3c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c3e:	078a                	slli	a5,a5,0x2
ffffffffc0202c40:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c42:	22e7fd63          	bgeu	a5,a4,ffffffffc0202e7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c46:	000bb503          	ld	a0,0(s7)
ffffffffc0202c4a:	fff80737          	lui	a4,0xfff80
ffffffffc0202c4e:	97ba                	add	a5,a5,a4
ffffffffc0202c50:	079a                	slli	a5,a5,0x6
ffffffffc0202c52:	953e                	add	a0,a0,a5
ffffffffc0202c54:	100027f3          	csrr	a5,sstatus
ffffffffc0202c58:	8b89                	andi	a5,a5,2
ffffffffc0202c5a:	18079d63          	bnez	a5,ffffffffc0202df4 <pmm_init+0x6de>
ffffffffc0202c5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c62:	4585                	li	a1,1
ffffffffc0202c64:	739c                	ld	a5,32(a5)
ffffffffc0202c66:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c68:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c6c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c6e:	078a                	slli	a5,a5,0x2
ffffffffc0202c70:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c72:	20e7f563          	bgeu	a5,a4,ffffffffc0202e7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c76:	000bb503          	ld	a0,0(s7)
ffffffffc0202c7a:	fff80737          	lui	a4,0xfff80
ffffffffc0202c7e:	97ba                	add	a5,a5,a4
ffffffffc0202c80:	079a                	slli	a5,a5,0x6
ffffffffc0202c82:	953e                	add	a0,a0,a5
ffffffffc0202c84:	100027f3          	csrr	a5,sstatus
ffffffffc0202c88:	8b89                	andi	a5,a5,2
ffffffffc0202c8a:	14079963          	bnez	a5,ffffffffc0202ddc <pmm_init+0x6c6>
ffffffffc0202c8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c92:	4585                	li	a1,1
ffffffffc0202c94:	739c                	ld	a5,32(a5)
ffffffffc0202c96:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c98:	00093783          	ld	a5,0(s2)
ffffffffc0202c9c:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202ca0:	12000073          	sfence.vma
ffffffffc0202ca4:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca8:	8b89                	andi	a5,a5,2
ffffffffc0202caa:	10079f63          	bnez	a5,ffffffffc0202dc8 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cae:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb2:	779c                	ld	a5,40(a5)
ffffffffc0202cb4:	9782                	jalr	a5
ffffffffc0202cb6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202cb8:	4c8c1e63          	bne	s8,s0,ffffffffc0203194 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202cbc:	00004517          	auipc	a0,0x4
ffffffffc0202cc0:	f6c50513          	addi	a0,a0,-148 # ffffffffc0206c28 <default_pmm_manager+0x720>
ffffffffc0202cc4:	cd0fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202cc8:	7406                	ld	s0,96(sp)
ffffffffc0202cca:	70a6                	ld	ra,104(sp)
ffffffffc0202ccc:	64e6                	ld	s1,88(sp)
ffffffffc0202cce:	6946                	ld	s2,80(sp)
ffffffffc0202cd0:	69a6                	ld	s3,72(sp)
ffffffffc0202cd2:	6a06                	ld	s4,64(sp)
ffffffffc0202cd4:	7ae2                	ld	s5,56(sp)
ffffffffc0202cd6:	7b42                	ld	s6,48(sp)
ffffffffc0202cd8:	7ba2                	ld	s7,40(sp)
ffffffffc0202cda:	7c02                	ld	s8,32(sp)
ffffffffc0202cdc:	6ce2                	ld	s9,24(sp)
ffffffffc0202cde:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202ce0:	f97fe06f          	j	ffffffffc0201c76 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202ce4:	c80007b7          	lui	a5,0xc8000
ffffffffc0202ce8:	bc7d                	j	ffffffffc02027a6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202cea:	ccbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cee:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf2:	4505                	li	a0,1
ffffffffc0202cf4:	6f9c                	ld	a5,24(a5)
ffffffffc0202cf6:	9782                	jalr	a5
ffffffffc0202cf8:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202cfa:	cb5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202cfe:	b9a9                	j	ffffffffc0202958 <pmm_init+0x242>
        intr_disable();
ffffffffc0202d00:	cb5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d04:	000b3783          	ld	a5,0(s6)
ffffffffc0202d08:	4505                	li	a0,1
ffffffffc0202d0a:	6f9c                	ld	a5,24(a5)
ffffffffc0202d0c:	9782                	jalr	a5
ffffffffc0202d0e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d10:	c9ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d14:	b645                	j	ffffffffc02028b4 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202d16:	c9ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d1e:	779c                	ld	a5,40(a5)
ffffffffc0202d20:	9782                	jalr	a5
ffffffffc0202d22:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d24:	c8bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d28:	b6b9                	j	ffffffffc0202876 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d2a:	6705                	lui	a4,0x1
ffffffffc0202d2c:	177d                	addi	a4,a4,-1
ffffffffc0202d2e:	96ba                	add	a3,a3,a4
ffffffffc0202d30:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d32:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d36:	14a77363          	bgeu	a4,a0,ffffffffc0202e7c <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d3a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202d3e:	fff80537          	lui	a0,0xfff80
ffffffffc0202d42:	972a                	add	a4,a4,a0
ffffffffc0202d44:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d46:	8c1d                	sub	s0,s0,a5
ffffffffc0202d48:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202d4c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d50:	9532                	add	a0,a0,a2
ffffffffc0202d52:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d54:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d58:	b4c1                	j	ffffffffc0202818 <pmm_init+0x102>
        intr_disable();
ffffffffc0202d5a:	c5bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d62:	779c                	ld	a5,40(a5)
ffffffffc0202d64:	9782                	jalr	a5
ffffffffc0202d66:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d68:	c47fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d6c:	bb79                	j	ffffffffc0202b0a <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202d6e:	c47fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d72:	000b3783          	ld	a5,0(s6)
ffffffffc0202d76:	779c                	ld	a5,40(a5)
ffffffffc0202d78:	9782                	jalr	a5
ffffffffc0202d7a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d7c:	c33fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d80:	b39d                	j	ffffffffc0202ae6 <pmm_init+0x3d0>
ffffffffc0202d82:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d84:	c31fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d88:	000b3783          	ld	a5,0(s6)
ffffffffc0202d8c:	6522                	ld	a0,8(sp)
ffffffffc0202d8e:	4585                	li	a1,1
ffffffffc0202d90:	739c                	ld	a5,32(a5)
ffffffffc0202d92:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d94:	c1bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d98:	b33d                	j	ffffffffc0202ac6 <pmm_init+0x3b0>
ffffffffc0202d9a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d9c:	c19fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202da0:	000b3783          	ld	a5,0(s6)
ffffffffc0202da4:	6522                	ld	a0,8(sp)
ffffffffc0202da6:	4585                	li	a1,1
ffffffffc0202da8:	739c                	ld	a5,32(a5)
ffffffffc0202daa:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dac:	c03fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202db0:	b1dd                	j	ffffffffc0202a96 <pmm_init+0x380>
        intr_disable();
ffffffffc0202db2:	c03fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202db6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dba:	4505                	li	a0,1
ffffffffc0202dbc:	6f9c                	ld	a5,24(a5)
ffffffffc0202dbe:	9782                	jalr	a5
ffffffffc0202dc0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dc2:	bedfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dc6:	b36d                	j	ffffffffc0202b70 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202dc8:	bedfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dcc:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd0:	779c                	ld	a5,40(a5)
ffffffffc0202dd2:	9782                	jalr	a5
ffffffffc0202dd4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dd6:	bd9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dda:	bdf9                	j	ffffffffc0202cb8 <pmm_init+0x5a2>
ffffffffc0202ddc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dde:	bd7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202de2:	000b3783          	ld	a5,0(s6)
ffffffffc0202de6:	6522                	ld	a0,8(sp)
ffffffffc0202de8:	4585                	li	a1,1
ffffffffc0202dea:	739c                	ld	a5,32(a5)
ffffffffc0202dec:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dee:	bc1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202df2:	b55d                	j	ffffffffc0202c98 <pmm_init+0x582>
ffffffffc0202df4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202df6:	bbffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dfa:	000b3783          	ld	a5,0(s6)
ffffffffc0202dfe:	6522                	ld	a0,8(sp)
ffffffffc0202e00:	4585                	li	a1,1
ffffffffc0202e02:	739c                	ld	a5,32(a5)
ffffffffc0202e04:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e06:	ba9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e0a:	bdb9                	j	ffffffffc0202c68 <pmm_init+0x552>
        intr_disable();
ffffffffc0202e0c:	ba9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e10:	000b3783          	ld	a5,0(s6)
ffffffffc0202e14:	4585                	li	a1,1
ffffffffc0202e16:	8552                	mv	a0,s4
ffffffffc0202e18:	739c                	ld	a5,32(a5)
ffffffffc0202e1a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e1c:	b93fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e20:	bd29                	j	ffffffffc0202c3a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e22:	86a2                	mv	a3,s0
ffffffffc0202e24:	00003617          	auipc	a2,0x3
ffffffffc0202e28:	71c60613          	addi	a2,a2,1820 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0202e2c:	24e00593          	li	a1,590
ffffffffc0202e30:	00004517          	auipc	a0,0x4
ffffffffc0202e34:	82850513          	addi	a0,a0,-2008 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202e38:	e56fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e3c:	00004697          	auipc	a3,0x4
ffffffffc0202e40:	c8c68693          	addi	a3,a3,-884 # ffffffffc0206ac8 <default_pmm_manager+0x5c0>
ffffffffc0202e44:	00003617          	auipc	a2,0x3
ffffffffc0202e48:	31460613          	addi	a2,a2,788 # ffffffffc0206158 <commands+0x818>
ffffffffc0202e4c:	24f00593          	li	a1,591
ffffffffc0202e50:	00004517          	auipc	a0,0x4
ffffffffc0202e54:	80850513          	addi	a0,a0,-2040 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202e58:	e36fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e5c:	00004697          	auipc	a3,0x4
ffffffffc0202e60:	c2c68693          	addi	a3,a3,-980 # ffffffffc0206a88 <default_pmm_manager+0x580>
ffffffffc0202e64:	00003617          	auipc	a2,0x3
ffffffffc0202e68:	2f460613          	addi	a2,a2,756 # ffffffffc0206158 <commands+0x818>
ffffffffc0202e6c:	24e00593          	li	a1,590
ffffffffc0202e70:	00003517          	auipc	a0,0x3
ffffffffc0202e74:	7e850513          	addi	a0,a0,2024 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202e78:	e16fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202e7c:	fc5fe0ef          	jal	ra,ffffffffc0201e40 <pa2page.part.0>
ffffffffc0202e80:	fddfe0ef          	jal	ra,ffffffffc0201e5c <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202e84:	00004697          	auipc	a3,0x4
ffffffffc0202e88:	9fc68693          	addi	a3,a3,-1540 # ffffffffc0206880 <default_pmm_manager+0x378>
ffffffffc0202e8c:	00003617          	auipc	a2,0x3
ffffffffc0202e90:	2cc60613          	addi	a2,a2,716 # ffffffffc0206158 <commands+0x818>
ffffffffc0202e94:	21e00593          	li	a1,542
ffffffffc0202e98:	00003517          	auipc	a0,0x3
ffffffffc0202e9c:	7c050513          	addi	a0,a0,1984 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202ea0:	deefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202ea4:	00004697          	auipc	a3,0x4
ffffffffc0202ea8:	91c68693          	addi	a3,a3,-1764 # ffffffffc02067c0 <default_pmm_manager+0x2b8>
ffffffffc0202eac:	00003617          	auipc	a2,0x3
ffffffffc0202eb0:	2ac60613          	addi	a2,a2,684 # ffffffffc0206158 <commands+0x818>
ffffffffc0202eb4:	21100593          	li	a1,529
ffffffffc0202eb8:	00003517          	auipc	a0,0x3
ffffffffc0202ebc:	7a050513          	addi	a0,a0,1952 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202ec0:	dcefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202ec4:	00004697          	auipc	a3,0x4
ffffffffc0202ec8:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0206780 <default_pmm_manager+0x278>
ffffffffc0202ecc:	00003617          	auipc	a2,0x3
ffffffffc0202ed0:	28c60613          	addi	a2,a2,652 # ffffffffc0206158 <commands+0x818>
ffffffffc0202ed4:	21000593          	li	a1,528
ffffffffc0202ed8:	00003517          	auipc	a0,0x3
ffffffffc0202edc:	78050513          	addi	a0,a0,1920 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202ee0:	daefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ee4:	00004697          	auipc	a3,0x4
ffffffffc0202ee8:	87c68693          	addi	a3,a3,-1924 # ffffffffc0206760 <default_pmm_manager+0x258>
ffffffffc0202eec:	00003617          	auipc	a2,0x3
ffffffffc0202ef0:	26c60613          	addi	a2,a2,620 # ffffffffc0206158 <commands+0x818>
ffffffffc0202ef4:	20f00593          	li	a1,527
ffffffffc0202ef8:	00003517          	auipc	a0,0x3
ffffffffc0202efc:	76050513          	addi	a0,a0,1888 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202f00:	d8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f04:	00003617          	auipc	a2,0x3
ffffffffc0202f08:	63c60613          	addi	a2,a2,1596 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0202f0c:	07100593          	li	a1,113
ffffffffc0202f10:	00003517          	auipc	a0,0x3
ffffffffc0202f14:	65850513          	addi	a0,a0,1624 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0202f18:	d76fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f1c:	00004697          	auipc	a3,0x4
ffffffffc0202f20:	af468693          	addi	a3,a3,-1292 # ffffffffc0206a10 <default_pmm_manager+0x508>
ffffffffc0202f24:	00003617          	auipc	a2,0x3
ffffffffc0202f28:	23460613          	addi	a2,a2,564 # ffffffffc0206158 <commands+0x818>
ffffffffc0202f2c:	23700593          	li	a1,567
ffffffffc0202f30:	00003517          	auipc	a0,0x3
ffffffffc0202f34:	72850513          	addi	a0,a0,1832 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202f38:	d56fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f3c:	00004697          	auipc	a3,0x4
ffffffffc0202f40:	a8c68693          	addi	a3,a3,-1396 # ffffffffc02069c8 <default_pmm_manager+0x4c0>
ffffffffc0202f44:	00003617          	auipc	a2,0x3
ffffffffc0202f48:	21460613          	addi	a2,a2,532 # ffffffffc0206158 <commands+0x818>
ffffffffc0202f4c:	23500593          	li	a1,565
ffffffffc0202f50:	00003517          	auipc	a0,0x3
ffffffffc0202f54:	70850513          	addi	a0,a0,1800 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202f58:	d36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f5c:	00004697          	auipc	a3,0x4
ffffffffc0202f60:	a9c68693          	addi	a3,a3,-1380 # ffffffffc02069f8 <default_pmm_manager+0x4f0>
ffffffffc0202f64:	00003617          	auipc	a2,0x3
ffffffffc0202f68:	1f460613          	addi	a2,a2,500 # ffffffffc0206158 <commands+0x818>
ffffffffc0202f6c:	23400593          	li	a1,564
ffffffffc0202f70:	00003517          	auipc	a0,0x3
ffffffffc0202f74:	6e850513          	addi	a0,a0,1768 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202f78:	d16fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f7c:	00004697          	auipc	a3,0x4
ffffffffc0202f80:	b6468693          	addi	a3,a3,-1180 # ffffffffc0206ae0 <default_pmm_manager+0x5d8>
ffffffffc0202f84:	00003617          	auipc	a2,0x3
ffffffffc0202f88:	1d460613          	addi	a2,a2,468 # ffffffffc0206158 <commands+0x818>
ffffffffc0202f8c:	25200593          	li	a1,594
ffffffffc0202f90:	00003517          	auipc	a0,0x3
ffffffffc0202f94:	6c850513          	addi	a0,a0,1736 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202f98:	cf6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f9c:	00004697          	auipc	a3,0x4
ffffffffc0202fa0:	aa468693          	addi	a3,a3,-1372 # ffffffffc0206a40 <default_pmm_manager+0x538>
ffffffffc0202fa4:	00003617          	auipc	a2,0x3
ffffffffc0202fa8:	1b460613          	addi	a2,a2,436 # ffffffffc0206158 <commands+0x818>
ffffffffc0202fac:	23f00593          	li	a1,575
ffffffffc0202fb0:	00003517          	auipc	a0,0x3
ffffffffc0202fb4:	6a850513          	addi	a0,a0,1704 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202fb8:	cd6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fbc:	00004697          	auipc	a3,0x4
ffffffffc0202fc0:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0206b38 <default_pmm_manager+0x630>
ffffffffc0202fc4:	00003617          	auipc	a2,0x3
ffffffffc0202fc8:	19460613          	addi	a2,a2,404 # ffffffffc0206158 <commands+0x818>
ffffffffc0202fcc:	25700593          	li	a1,599
ffffffffc0202fd0:	00003517          	auipc	a0,0x3
ffffffffc0202fd4:	68850513          	addi	a0,a0,1672 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202fd8:	cb6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fdc:	00004697          	auipc	a3,0x4
ffffffffc0202fe0:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0206af8 <default_pmm_manager+0x5f0>
ffffffffc0202fe4:	00003617          	auipc	a2,0x3
ffffffffc0202fe8:	17460613          	addi	a2,a2,372 # ffffffffc0206158 <commands+0x818>
ffffffffc0202fec:	25600593          	li	a1,598
ffffffffc0202ff0:	00003517          	auipc	a0,0x3
ffffffffc0202ff4:	66850513          	addi	a0,a0,1640 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0202ff8:	c96fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ffc:	00004697          	auipc	a3,0x4
ffffffffc0203000:	9cc68693          	addi	a3,a3,-1588 # ffffffffc02069c8 <default_pmm_manager+0x4c0>
ffffffffc0203004:	00003617          	auipc	a2,0x3
ffffffffc0203008:	15460613          	addi	a2,a2,340 # ffffffffc0206158 <commands+0x818>
ffffffffc020300c:	23100593          	li	a1,561
ffffffffc0203010:	00003517          	auipc	a0,0x3
ffffffffc0203014:	64850513          	addi	a0,a0,1608 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203018:	c76fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020301c:	00004697          	auipc	a3,0x4
ffffffffc0203020:	84c68693          	addi	a3,a3,-1972 # ffffffffc0206868 <default_pmm_manager+0x360>
ffffffffc0203024:	00003617          	auipc	a2,0x3
ffffffffc0203028:	13460613          	addi	a2,a2,308 # ffffffffc0206158 <commands+0x818>
ffffffffc020302c:	23000593          	li	a1,560
ffffffffc0203030:	00003517          	auipc	a0,0x3
ffffffffc0203034:	62850513          	addi	a0,a0,1576 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203038:	c56fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020303c:	00004697          	auipc	a3,0x4
ffffffffc0203040:	9a468693          	addi	a3,a3,-1628 # ffffffffc02069e0 <default_pmm_manager+0x4d8>
ffffffffc0203044:	00003617          	auipc	a2,0x3
ffffffffc0203048:	11460613          	addi	a2,a2,276 # ffffffffc0206158 <commands+0x818>
ffffffffc020304c:	22d00593          	li	a1,557
ffffffffc0203050:	00003517          	auipc	a0,0x3
ffffffffc0203054:	60850513          	addi	a0,a0,1544 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203058:	c36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020305c:	00003697          	auipc	a3,0x3
ffffffffc0203060:	7f468693          	addi	a3,a3,2036 # ffffffffc0206850 <default_pmm_manager+0x348>
ffffffffc0203064:	00003617          	auipc	a2,0x3
ffffffffc0203068:	0f460613          	addi	a2,a2,244 # ffffffffc0206158 <commands+0x818>
ffffffffc020306c:	22c00593          	li	a1,556
ffffffffc0203070:	00003517          	auipc	a0,0x3
ffffffffc0203074:	5e850513          	addi	a0,a0,1512 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203078:	c16fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020307c:	00004697          	auipc	a3,0x4
ffffffffc0203080:	87468693          	addi	a3,a3,-1932 # ffffffffc02068f0 <default_pmm_manager+0x3e8>
ffffffffc0203084:	00003617          	auipc	a2,0x3
ffffffffc0203088:	0d460613          	addi	a2,a2,212 # ffffffffc0206158 <commands+0x818>
ffffffffc020308c:	22b00593          	li	a1,555
ffffffffc0203090:	00003517          	auipc	a0,0x3
ffffffffc0203094:	5c850513          	addi	a0,a0,1480 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203098:	bf6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020309c:	00004697          	auipc	a3,0x4
ffffffffc02030a0:	92c68693          	addi	a3,a3,-1748 # ffffffffc02069c8 <default_pmm_manager+0x4c0>
ffffffffc02030a4:	00003617          	auipc	a2,0x3
ffffffffc02030a8:	0b460613          	addi	a2,a2,180 # ffffffffc0206158 <commands+0x818>
ffffffffc02030ac:	22a00593          	li	a1,554
ffffffffc02030b0:	00003517          	auipc	a0,0x3
ffffffffc02030b4:	5a850513          	addi	a0,a0,1448 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02030b8:	bd6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030bc:	00004697          	auipc	a3,0x4
ffffffffc02030c0:	8f468693          	addi	a3,a3,-1804 # ffffffffc02069b0 <default_pmm_manager+0x4a8>
ffffffffc02030c4:	00003617          	auipc	a2,0x3
ffffffffc02030c8:	09460613          	addi	a2,a2,148 # ffffffffc0206158 <commands+0x818>
ffffffffc02030cc:	22900593          	li	a1,553
ffffffffc02030d0:	00003517          	auipc	a0,0x3
ffffffffc02030d4:	58850513          	addi	a0,a0,1416 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02030d8:	bb6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030dc:	00004697          	auipc	a3,0x4
ffffffffc02030e0:	8a468693          	addi	a3,a3,-1884 # ffffffffc0206980 <default_pmm_manager+0x478>
ffffffffc02030e4:	00003617          	auipc	a2,0x3
ffffffffc02030e8:	07460613          	addi	a2,a2,116 # ffffffffc0206158 <commands+0x818>
ffffffffc02030ec:	22800593          	li	a1,552
ffffffffc02030f0:	00003517          	auipc	a0,0x3
ffffffffc02030f4:	56850513          	addi	a0,a0,1384 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02030f8:	b96fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02030fc:	00004697          	auipc	a3,0x4
ffffffffc0203100:	86c68693          	addi	a3,a3,-1940 # ffffffffc0206968 <default_pmm_manager+0x460>
ffffffffc0203104:	00003617          	auipc	a2,0x3
ffffffffc0203108:	05460613          	addi	a2,a2,84 # ffffffffc0206158 <commands+0x818>
ffffffffc020310c:	22600593          	li	a1,550
ffffffffc0203110:	00003517          	auipc	a0,0x3
ffffffffc0203114:	54850513          	addi	a0,a0,1352 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203118:	b76fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020311c:	00004697          	auipc	a3,0x4
ffffffffc0203120:	82c68693          	addi	a3,a3,-2004 # ffffffffc0206948 <default_pmm_manager+0x440>
ffffffffc0203124:	00003617          	auipc	a2,0x3
ffffffffc0203128:	03460613          	addi	a2,a2,52 # ffffffffc0206158 <commands+0x818>
ffffffffc020312c:	22500593          	li	a1,549
ffffffffc0203130:	00003517          	auipc	a0,0x3
ffffffffc0203134:	52850513          	addi	a0,a0,1320 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203138:	b56fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc020313c:	00003697          	auipc	a3,0x3
ffffffffc0203140:	7fc68693          	addi	a3,a3,2044 # ffffffffc0206938 <default_pmm_manager+0x430>
ffffffffc0203144:	00003617          	auipc	a2,0x3
ffffffffc0203148:	01460613          	addi	a2,a2,20 # ffffffffc0206158 <commands+0x818>
ffffffffc020314c:	22400593          	li	a1,548
ffffffffc0203150:	00003517          	auipc	a0,0x3
ffffffffc0203154:	50850513          	addi	a0,a0,1288 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203158:	b36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc020315c:	00003697          	auipc	a3,0x3
ffffffffc0203160:	7cc68693          	addi	a3,a3,1996 # ffffffffc0206928 <default_pmm_manager+0x420>
ffffffffc0203164:	00003617          	auipc	a2,0x3
ffffffffc0203168:	ff460613          	addi	a2,a2,-12 # ffffffffc0206158 <commands+0x818>
ffffffffc020316c:	22300593          	li	a1,547
ffffffffc0203170:	00003517          	auipc	a0,0x3
ffffffffc0203174:	4e850513          	addi	a0,a0,1256 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203178:	b16fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc020317c:	00003617          	auipc	a2,0x3
ffffffffc0203180:	54c60613          	addi	a2,a2,1356 # ffffffffc02066c8 <default_pmm_manager+0x1c0>
ffffffffc0203184:	06500593          	li	a1,101
ffffffffc0203188:	00003517          	auipc	a0,0x3
ffffffffc020318c:	4d050513          	addi	a0,a0,1232 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203190:	afefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203194:	00004697          	auipc	a3,0x4
ffffffffc0203198:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0206a40 <default_pmm_manager+0x538>
ffffffffc020319c:	00003617          	auipc	a2,0x3
ffffffffc02031a0:	fbc60613          	addi	a2,a2,-68 # ffffffffc0206158 <commands+0x818>
ffffffffc02031a4:	26900593          	li	a1,617
ffffffffc02031a8:	00003517          	auipc	a0,0x3
ffffffffc02031ac:	4b050513          	addi	a0,a0,1200 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02031b0:	adefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031b4:	00003697          	auipc	a3,0x3
ffffffffc02031b8:	73c68693          	addi	a3,a3,1852 # ffffffffc02068f0 <default_pmm_manager+0x3e8>
ffffffffc02031bc:	00003617          	auipc	a2,0x3
ffffffffc02031c0:	f9c60613          	addi	a2,a2,-100 # ffffffffc0206158 <commands+0x818>
ffffffffc02031c4:	22200593          	li	a1,546
ffffffffc02031c8:	00003517          	auipc	a0,0x3
ffffffffc02031cc:	49050513          	addi	a0,a0,1168 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02031d0:	abefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031d4:	00003697          	auipc	a3,0x3
ffffffffc02031d8:	6dc68693          	addi	a3,a3,1756 # ffffffffc02068b0 <default_pmm_manager+0x3a8>
ffffffffc02031dc:	00003617          	auipc	a2,0x3
ffffffffc02031e0:	f7c60613          	addi	a2,a2,-132 # ffffffffc0206158 <commands+0x818>
ffffffffc02031e4:	22100593          	li	a1,545
ffffffffc02031e8:	00003517          	auipc	a0,0x3
ffffffffc02031ec:	47050513          	addi	a0,a0,1136 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02031f0:	a9efd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02031f4:	86d6                	mv	a3,s5
ffffffffc02031f6:	00003617          	auipc	a2,0x3
ffffffffc02031fa:	34a60613          	addi	a2,a2,842 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc02031fe:	21d00593          	li	a1,541
ffffffffc0203202:	00003517          	auipc	a0,0x3
ffffffffc0203206:	45650513          	addi	a0,a0,1110 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc020320a:	a84fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020320e:	00003617          	auipc	a2,0x3
ffffffffc0203212:	33260613          	addi	a2,a2,818 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0203216:	21c00593          	li	a1,540
ffffffffc020321a:	00003517          	auipc	a0,0x3
ffffffffc020321e:	43e50513          	addi	a0,a0,1086 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203222:	a6cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203226:	00003697          	auipc	a3,0x3
ffffffffc020322a:	64268693          	addi	a3,a3,1602 # ffffffffc0206868 <default_pmm_manager+0x360>
ffffffffc020322e:	00003617          	auipc	a2,0x3
ffffffffc0203232:	f2a60613          	addi	a2,a2,-214 # ffffffffc0206158 <commands+0x818>
ffffffffc0203236:	21a00593          	li	a1,538
ffffffffc020323a:	00003517          	auipc	a0,0x3
ffffffffc020323e:	41e50513          	addi	a0,a0,1054 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203242:	a4cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203246:	00003697          	auipc	a3,0x3
ffffffffc020324a:	60a68693          	addi	a3,a3,1546 # ffffffffc0206850 <default_pmm_manager+0x348>
ffffffffc020324e:	00003617          	auipc	a2,0x3
ffffffffc0203252:	f0a60613          	addi	a2,a2,-246 # ffffffffc0206158 <commands+0x818>
ffffffffc0203256:	21900593          	li	a1,537
ffffffffc020325a:	00003517          	auipc	a0,0x3
ffffffffc020325e:	3fe50513          	addi	a0,a0,1022 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203262:	a2cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203266:	00004697          	auipc	a3,0x4
ffffffffc020326a:	99a68693          	addi	a3,a3,-1638 # ffffffffc0206c00 <default_pmm_manager+0x6f8>
ffffffffc020326e:	00003617          	auipc	a2,0x3
ffffffffc0203272:	eea60613          	addi	a2,a2,-278 # ffffffffc0206158 <commands+0x818>
ffffffffc0203276:	26000593          	li	a1,608
ffffffffc020327a:	00003517          	auipc	a0,0x3
ffffffffc020327e:	3de50513          	addi	a0,a0,990 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203282:	a0cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203286:	00004697          	auipc	a3,0x4
ffffffffc020328a:	94268693          	addi	a3,a3,-1726 # ffffffffc0206bc8 <default_pmm_manager+0x6c0>
ffffffffc020328e:	00003617          	auipc	a2,0x3
ffffffffc0203292:	eca60613          	addi	a2,a2,-310 # ffffffffc0206158 <commands+0x818>
ffffffffc0203296:	25d00593          	li	a1,605
ffffffffc020329a:	00003517          	auipc	a0,0x3
ffffffffc020329e:	3be50513          	addi	a0,a0,958 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02032a2:	9ecfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032a6:	00004697          	auipc	a3,0x4
ffffffffc02032aa:	8f268693          	addi	a3,a3,-1806 # ffffffffc0206b98 <default_pmm_manager+0x690>
ffffffffc02032ae:	00003617          	auipc	a2,0x3
ffffffffc02032b2:	eaa60613          	addi	a2,a2,-342 # ffffffffc0206158 <commands+0x818>
ffffffffc02032b6:	25900593          	li	a1,601
ffffffffc02032ba:	00003517          	auipc	a0,0x3
ffffffffc02032be:	39e50513          	addi	a0,a0,926 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02032c2:	9ccfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02032c6:	00004697          	auipc	a3,0x4
ffffffffc02032ca:	88a68693          	addi	a3,a3,-1910 # ffffffffc0206b50 <default_pmm_manager+0x648>
ffffffffc02032ce:	00003617          	auipc	a2,0x3
ffffffffc02032d2:	e8a60613          	addi	a2,a2,-374 # ffffffffc0206158 <commands+0x818>
ffffffffc02032d6:	25800593          	li	a1,600
ffffffffc02032da:	00003517          	auipc	a0,0x3
ffffffffc02032de:	37e50513          	addi	a0,a0,894 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02032e2:	9acfd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02032e6:	00003617          	auipc	a2,0x3
ffffffffc02032ea:	30260613          	addi	a2,a2,770 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc02032ee:	0c900593          	li	a1,201
ffffffffc02032f2:	00003517          	auipc	a0,0x3
ffffffffc02032f6:	36650513          	addi	a0,a0,870 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02032fa:	994fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02032fe:	00003617          	auipc	a2,0x3
ffffffffc0203302:	2ea60613          	addi	a2,a2,746 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc0203306:	08100593          	li	a1,129
ffffffffc020330a:	00003517          	auipc	a0,0x3
ffffffffc020330e:	34e50513          	addi	a0,a0,846 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203312:	97cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203316:	00003697          	auipc	a3,0x3
ffffffffc020331a:	50a68693          	addi	a3,a3,1290 # ffffffffc0206820 <default_pmm_manager+0x318>
ffffffffc020331e:	00003617          	auipc	a2,0x3
ffffffffc0203322:	e3a60613          	addi	a2,a2,-454 # ffffffffc0206158 <commands+0x818>
ffffffffc0203326:	21800593          	li	a1,536
ffffffffc020332a:	00003517          	auipc	a0,0x3
ffffffffc020332e:	32e50513          	addi	a0,a0,814 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203332:	95cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203336:	00003697          	auipc	a3,0x3
ffffffffc020333a:	4ba68693          	addi	a3,a3,1210 # ffffffffc02067f0 <default_pmm_manager+0x2e8>
ffffffffc020333e:	00003617          	auipc	a2,0x3
ffffffffc0203342:	e1a60613          	addi	a2,a2,-486 # ffffffffc0206158 <commands+0x818>
ffffffffc0203346:	21500593          	li	a1,533
ffffffffc020334a:	00003517          	auipc	a0,0x3
ffffffffc020334e:	30e50513          	addi	a0,a0,782 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203352:	93cfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203356 <copy_range>:
{
ffffffffc0203356:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203358:	00d667b3          	or	a5,a2,a3
{
ffffffffc020335c:	f486                	sd	ra,104(sp)
ffffffffc020335e:	f0a2                	sd	s0,96(sp)
ffffffffc0203360:	eca6                	sd	s1,88(sp)
ffffffffc0203362:	e8ca                	sd	s2,80(sp)
ffffffffc0203364:	e4ce                	sd	s3,72(sp)
ffffffffc0203366:	e0d2                	sd	s4,64(sp)
ffffffffc0203368:	fc56                	sd	s5,56(sp)
ffffffffc020336a:	f85a                	sd	s6,48(sp)
ffffffffc020336c:	f45e                	sd	s7,40(sp)
ffffffffc020336e:	f062                	sd	s8,32(sp)
ffffffffc0203370:	ec66                	sd	s9,24(sp)
ffffffffc0203372:	e86a                	sd	s10,16(sp)
ffffffffc0203374:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203376:	17d2                	slli	a5,a5,0x34
ffffffffc0203378:	20079f63          	bnez	a5,ffffffffc0203596 <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc020337c:	002007b7          	lui	a5,0x200
ffffffffc0203380:	8432                	mv	s0,a2
ffffffffc0203382:	1af66263          	bltu	a2,a5,ffffffffc0203526 <copy_range+0x1d0>
ffffffffc0203386:	8936                	mv	s2,a3
ffffffffc0203388:	18d67f63          	bgeu	a2,a3,ffffffffc0203526 <copy_range+0x1d0>
ffffffffc020338c:	4785                	li	a5,1
ffffffffc020338e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203390:	18d7eb63          	bltu	a5,a3,ffffffffc0203526 <copy_range+0x1d0>
ffffffffc0203394:	5b7d                	li	s6,-1
ffffffffc0203396:	8aaa                	mv	s5,a0
ffffffffc0203398:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc020339a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020339c:	000a7c17          	auipc	s8,0xa7
ffffffffc02033a0:	30cc0c13          	addi	s8,s8,780 # ffffffffc02aa6a8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02033a4:	000a7b97          	auipc	s7,0xa7
ffffffffc02033a8:	30cb8b93          	addi	s7,s7,780 # ffffffffc02aa6b0 <pages>
    return KADDR(page2pa(page));
ffffffffc02033ac:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02033b0:	000a7c97          	auipc	s9,0xa7
ffffffffc02033b4:	308c8c93          	addi	s9,s9,776 # ffffffffc02aa6b8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02033b8:	4601                	li	a2,0
ffffffffc02033ba:	85a2                	mv	a1,s0
ffffffffc02033bc:	854e                	mv	a0,s3
ffffffffc02033be:	b73fe0ef          	jal	ra,ffffffffc0201f30 <get_pte>
ffffffffc02033c2:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02033c4:	0e050c63          	beqz	a0,ffffffffc02034bc <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc02033c8:	611c                	ld	a5,0(a0)
ffffffffc02033ca:	8b85                	andi	a5,a5,1
ffffffffc02033cc:	e785                	bnez	a5,ffffffffc02033f4 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02033ce:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02033d0:	ff2464e3          	bltu	s0,s2,ffffffffc02033b8 <copy_range+0x62>
    return 0;
ffffffffc02033d4:	4501                	li	a0,0
}
ffffffffc02033d6:	70a6                	ld	ra,104(sp)
ffffffffc02033d8:	7406                	ld	s0,96(sp)
ffffffffc02033da:	64e6                	ld	s1,88(sp)
ffffffffc02033dc:	6946                	ld	s2,80(sp)
ffffffffc02033de:	69a6                	ld	s3,72(sp)
ffffffffc02033e0:	6a06                	ld	s4,64(sp)
ffffffffc02033e2:	7ae2                	ld	s5,56(sp)
ffffffffc02033e4:	7b42                	ld	s6,48(sp)
ffffffffc02033e6:	7ba2                	ld	s7,40(sp)
ffffffffc02033e8:	7c02                	ld	s8,32(sp)
ffffffffc02033ea:	6ce2                	ld	s9,24(sp)
ffffffffc02033ec:	6d42                	ld	s10,16(sp)
ffffffffc02033ee:	6da2                	ld	s11,8(sp)
ffffffffc02033f0:	6165                	addi	sp,sp,112
ffffffffc02033f2:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02033f4:	4605                	li	a2,1
ffffffffc02033f6:	85a2                	mv	a1,s0
ffffffffc02033f8:	8556                	mv	a0,s5
ffffffffc02033fa:	b37fe0ef          	jal	ra,ffffffffc0201f30 <get_pte>
ffffffffc02033fe:	c56d                	beqz	a0,ffffffffc02034e8 <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203400:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203402:	0017f713          	andi	a4,a5,1
ffffffffc0203406:	01f7f493          	andi	s1,a5,31
ffffffffc020340a:	16070a63          	beqz	a4,ffffffffc020357e <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc020340e:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203412:	078a                	slli	a5,a5,0x2
ffffffffc0203414:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203418:	14d77763          	bgeu	a4,a3,ffffffffc0203566 <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc020341c:	000bb783          	ld	a5,0(s7)
ffffffffc0203420:	fff806b7          	lui	a3,0xfff80
ffffffffc0203424:	9736                	add	a4,a4,a3
ffffffffc0203426:	071a                	slli	a4,a4,0x6
ffffffffc0203428:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020342c:	10002773          	csrr	a4,sstatus
ffffffffc0203430:	8b09                	andi	a4,a4,2
ffffffffc0203432:	e345                	bnez	a4,ffffffffc02034d2 <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203434:	000cb703          	ld	a4,0(s9)
ffffffffc0203438:	4505                	li	a0,1
ffffffffc020343a:	6f18                	ld	a4,24(a4)
ffffffffc020343c:	9702                	jalr	a4
ffffffffc020343e:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203440:	0c0d8363          	beqz	s11,ffffffffc0203506 <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc0203444:	100d0163          	beqz	s10,ffffffffc0203546 <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc0203448:	000bb703          	ld	a4,0(s7)
ffffffffc020344c:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203450:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203454:	40ed86b3          	sub	a3,s11,a4
ffffffffc0203458:	8699                	srai	a3,a3,0x6
ffffffffc020345a:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020345c:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203460:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203462:	08c7f663          	bgeu	a5,a2,ffffffffc02034ee <copy_range+0x198>
    return page - pages + nbase;
ffffffffc0203466:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc020346a:	000a7717          	auipc	a4,0xa7
ffffffffc020346e:	25670713          	addi	a4,a4,598 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0203472:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203474:	8799                	srai	a5,a5,0x6
ffffffffc0203476:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0203478:	0167f733          	and	a4,a5,s6
ffffffffc020347c:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203480:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203482:	06c77563          	bgeu	a4,a2,ffffffffc02034ec <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203486:	6605                	lui	a2,0x1
ffffffffc0203488:	953e                	add	a0,a0,a5
ffffffffc020348a:	236020ef          	jal	ra,ffffffffc02056c0 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc020348e:	86a6                	mv	a3,s1
ffffffffc0203490:	8622                	mv	a2,s0
ffffffffc0203492:	85ea                	mv	a1,s10
ffffffffc0203494:	8556                	mv	a0,s5
ffffffffc0203496:	98aff0ef          	jal	ra,ffffffffc0202620 <page_insert>
            assert(ret == 0);
ffffffffc020349a:	d915                	beqz	a0,ffffffffc02033ce <copy_range+0x78>
ffffffffc020349c:	00003697          	auipc	a3,0x3
ffffffffc02034a0:	7cc68693          	addi	a3,a3,1996 # ffffffffc0206c68 <default_pmm_manager+0x760>
ffffffffc02034a4:	00003617          	auipc	a2,0x3
ffffffffc02034a8:	cb460613          	addi	a2,a2,-844 # ffffffffc0206158 <commands+0x818>
ffffffffc02034ac:	1ad00593          	li	a1,429
ffffffffc02034b0:	00003517          	auipc	a0,0x3
ffffffffc02034b4:	1a850513          	addi	a0,a0,424 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02034b8:	fd7fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02034bc:	00200637          	lui	a2,0x200
ffffffffc02034c0:	9432                	add	s0,s0,a2
ffffffffc02034c2:	ffe00637          	lui	a2,0xffe00
ffffffffc02034c6:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02034c8:	f00406e3          	beqz	s0,ffffffffc02033d4 <copy_range+0x7e>
ffffffffc02034cc:	ef2466e3          	bltu	s0,s2,ffffffffc02033b8 <copy_range+0x62>
ffffffffc02034d0:	b711                	j	ffffffffc02033d4 <copy_range+0x7e>
        intr_disable();
ffffffffc02034d2:	ce2fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034d6:	000cb703          	ld	a4,0(s9)
ffffffffc02034da:	4505                	li	a0,1
ffffffffc02034dc:	6f18                	ld	a4,24(a4)
ffffffffc02034de:	9702                	jalr	a4
ffffffffc02034e0:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02034e2:	cccfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02034e6:	bfa9                	j	ffffffffc0203440 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc02034e8:	5571                	li	a0,-4
ffffffffc02034ea:	b5f5                	j	ffffffffc02033d6 <copy_range+0x80>
ffffffffc02034ec:	86be                	mv	a3,a5
ffffffffc02034ee:	00003617          	auipc	a2,0x3
ffffffffc02034f2:	05260613          	addi	a2,a2,82 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc02034f6:	07100593          	li	a1,113
ffffffffc02034fa:	00003517          	auipc	a0,0x3
ffffffffc02034fe:	06e50513          	addi	a0,a0,110 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0203502:	f8dfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203506:	00003697          	auipc	a3,0x3
ffffffffc020350a:	74268693          	addi	a3,a3,1858 # ffffffffc0206c48 <default_pmm_manager+0x740>
ffffffffc020350e:	00003617          	auipc	a2,0x3
ffffffffc0203512:	c4a60613          	addi	a2,a2,-950 # ffffffffc0206158 <commands+0x818>
ffffffffc0203516:	19400593          	li	a1,404
ffffffffc020351a:	00003517          	auipc	a0,0x3
ffffffffc020351e:	13e50513          	addi	a0,a0,318 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203522:	f6dfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203526:	00003697          	auipc	a3,0x3
ffffffffc020352a:	17268693          	addi	a3,a3,370 # ffffffffc0206698 <default_pmm_manager+0x190>
ffffffffc020352e:	00003617          	auipc	a2,0x3
ffffffffc0203532:	c2a60613          	addi	a2,a2,-982 # ffffffffc0206158 <commands+0x818>
ffffffffc0203536:	17c00593          	li	a1,380
ffffffffc020353a:	00003517          	auipc	a0,0x3
ffffffffc020353e:	11e50513          	addi	a0,a0,286 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203542:	f4dfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc0203546:	00003697          	auipc	a3,0x3
ffffffffc020354a:	71268693          	addi	a3,a3,1810 # ffffffffc0206c58 <default_pmm_manager+0x750>
ffffffffc020354e:	00003617          	auipc	a2,0x3
ffffffffc0203552:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0206158 <commands+0x818>
ffffffffc0203556:	19500593          	li	a1,405
ffffffffc020355a:	00003517          	auipc	a0,0x3
ffffffffc020355e:	0fe50513          	addi	a0,a0,254 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203562:	f2dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203566:	00003617          	auipc	a2,0x3
ffffffffc020356a:	0aa60613          	addi	a2,a2,170 # ffffffffc0206610 <default_pmm_manager+0x108>
ffffffffc020356e:	06900593          	li	a1,105
ffffffffc0203572:	00003517          	auipc	a0,0x3
ffffffffc0203576:	ff650513          	addi	a0,a0,-10 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc020357a:	f15fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020357e:	00003617          	auipc	a2,0x3
ffffffffc0203582:	0b260613          	addi	a2,a2,178 # ffffffffc0206630 <default_pmm_manager+0x128>
ffffffffc0203586:	07f00593          	li	a1,127
ffffffffc020358a:	00003517          	auipc	a0,0x3
ffffffffc020358e:	fde50513          	addi	a0,a0,-34 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0203592:	efdfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203596:	00003697          	auipc	a3,0x3
ffffffffc020359a:	0d268693          	addi	a3,a3,210 # ffffffffc0206668 <default_pmm_manager+0x160>
ffffffffc020359e:	00003617          	auipc	a2,0x3
ffffffffc02035a2:	bba60613          	addi	a2,a2,-1094 # ffffffffc0206158 <commands+0x818>
ffffffffc02035a6:	17b00593          	li	a1,379
ffffffffc02035aa:	00003517          	auipc	a0,0x3
ffffffffc02035ae:	0ae50513          	addi	a0,a0,174 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc02035b2:	eddfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035b6 <pgdir_alloc_page>:
{
ffffffffc02035b6:	7179                	addi	sp,sp,-48
ffffffffc02035b8:	ec26                	sd	s1,24(sp)
ffffffffc02035ba:	e84a                	sd	s2,16(sp)
ffffffffc02035bc:	e052                	sd	s4,0(sp)
ffffffffc02035be:	f406                	sd	ra,40(sp)
ffffffffc02035c0:	f022                	sd	s0,32(sp)
ffffffffc02035c2:	e44e                	sd	s3,8(sp)
ffffffffc02035c4:	8a2a                	mv	s4,a0
ffffffffc02035c6:	84ae                	mv	s1,a1
ffffffffc02035c8:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035ca:	100027f3          	csrr	a5,sstatus
ffffffffc02035ce:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02035d0:	000a7997          	auipc	s3,0xa7
ffffffffc02035d4:	0e898993          	addi	s3,s3,232 # ffffffffc02aa6b8 <pmm_manager>
ffffffffc02035d8:	ef8d                	bnez	a5,ffffffffc0203612 <pgdir_alloc_page+0x5c>
ffffffffc02035da:	0009b783          	ld	a5,0(s3)
ffffffffc02035de:	4505                	li	a0,1
ffffffffc02035e0:	6f9c                	ld	a5,24(a5)
ffffffffc02035e2:	9782                	jalr	a5
ffffffffc02035e4:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02035e6:	cc09                	beqz	s0,ffffffffc0203600 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02035e8:	86ca                	mv	a3,s2
ffffffffc02035ea:	8626                	mv	a2,s1
ffffffffc02035ec:	85a2                	mv	a1,s0
ffffffffc02035ee:	8552                	mv	a0,s4
ffffffffc02035f0:	830ff0ef          	jal	ra,ffffffffc0202620 <page_insert>
ffffffffc02035f4:	e915                	bnez	a0,ffffffffc0203628 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02035f6:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02035f8:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02035fa:	4785                	li	a5,1
ffffffffc02035fc:	04f71e63          	bne	a4,a5,ffffffffc0203658 <pgdir_alloc_page+0xa2>
}
ffffffffc0203600:	70a2                	ld	ra,40(sp)
ffffffffc0203602:	8522                	mv	a0,s0
ffffffffc0203604:	7402                	ld	s0,32(sp)
ffffffffc0203606:	64e2                	ld	s1,24(sp)
ffffffffc0203608:	6942                	ld	s2,16(sp)
ffffffffc020360a:	69a2                	ld	s3,8(sp)
ffffffffc020360c:	6a02                	ld	s4,0(sp)
ffffffffc020360e:	6145                	addi	sp,sp,48
ffffffffc0203610:	8082                	ret
        intr_disable();
ffffffffc0203612:	ba2fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203616:	0009b783          	ld	a5,0(s3)
ffffffffc020361a:	4505                	li	a0,1
ffffffffc020361c:	6f9c                	ld	a5,24(a5)
ffffffffc020361e:	9782                	jalr	a5
ffffffffc0203620:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203622:	b8cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203626:	b7c1                	j	ffffffffc02035e6 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203628:	100027f3          	csrr	a5,sstatus
ffffffffc020362c:	8b89                	andi	a5,a5,2
ffffffffc020362e:	eb89                	bnez	a5,ffffffffc0203640 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203630:	0009b783          	ld	a5,0(s3)
ffffffffc0203634:	8522                	mv	a0,s0
ffffffffc0203636:	4585                	li	a1,1
ffffffffc0203638:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020363a:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020363c:	9782                	jalr	a5
    if (flag)
ffffffffc020363e:	b7c9                	j	ffffffffc0203600 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203640:	b74fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203644:	0009b783          	ld	a5,0(s3)
ffffffffc0203648:	8522                	mv	a0,s0
ffffffffc020364a:	4585                	li	a1,1
ffffffffc020364c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020364e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203650:	9782                	jalr	a5
        intr_enable();
ffffffffc0203652:	b5cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203656:	b76d                	j	ffffffffc0203600 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203658:	00003697          	auipc	a3,0x3
ffffffffc020365c:	62068693          	addi	a3,a3,1568 # ffffffffc0206c78 <default_pmm_manager+0x770>
ffffffffc0203660:	00003617          	auipc	a2,0x3
ffffffffc0203664:	af860613          	addi	a2,a2,-1288 # ffffffffc0206158 <commands+0x818>
ffffffffc0203668:	1f600593          	li	a1,502
ffffffffc020366c:	00003517          	auipc	a0,0x3
ffffffffc0203670:	fec50513          	addi	a0,a0,-20 # ffffffffc0206658 <default_pmm_manager+0x150>
ffffffffc0203674:	e1bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203678 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203678:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020367a:	00003697          	auipc	a3,0x3
ffffffffc020367e:	61668693          	addi	a3,a3,1558 # ffffffffc0206c90 <default_pmm_manager+0x788>
ffffffffc0203682:	00003617          	auipc	a2,0x3
ffffffffc0203686:	ad660613          	addi	a2,a2,-1322 # ffffffffc0206158 <commands+0x818>
ffffffffc020368a:	07400593          	li	a1,116
ffffffffc020368e:	00003517          	auipc	a0,0x3
ffffffffc0203692:	62250513          	addi	a0,a0,1570 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203696:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203698:	df7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020369c <mm_create>:
{
ffffffffc020369c:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020369e:	04000513          	li	a0,64
{
ffffffffc02036a2:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036a4:	df6fe0ef          	jal	ra,ffffffffc0201c9a <kmalloc>
    if (mm != NULL)
ffffffffc02036a8:	cd19                	beqz	a0,ffffffffc02036c6 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036aa:	e508                	sd	a0,8(a0)
ffffffffc02036ac:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036ae:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036b2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036b6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036ba:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036be:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036c2:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036c6:	60a2                	ld	ra,8(sp)
ffffffffc02036c8:	0141                	addi	sp,sp,16
ffffffffc02036ca:	8082                	ret

ffffffffc02036cc <find_vma>:
{
ffffffffc02036cc:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02036ce:	c505                	beqz	a0,ffffffffc02036f6 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02036d0:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036d2:	c501                	beqz	a0,ffffffffc02036da <find_vma+0xe>
ffffffffc02036d4:	651c                	ld	a5,8(a0)
ffffffffc02036d6:	02f5f263          	bgeu	a1,a5,ffffffffc02036fa <find_vma+0x2e>
    return listelm->next;
ffffffffc02036da:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02036dc:	00f68d63          	beq	a3,a5,ffffffffc02036f6 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02036e0:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ed0>
ffffffffc02036e4:	00e5e663          	bltu	a1,a4,ffffffffc02036f0 <find_vma+0x24>
ffffffffc02036e8:	ff07b703          	ld	a4,-16(a5)
ffffffffc02036ec:	00e5ec63          	bltu	a1,a4,ffffffffc0203704 <find_vma+0x38>
ffffffffc02036f0:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02036f2:	fef697e3          	bne	a3,a5,ffffffffc02036e0 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02036f6:	4501                	li	a0,0
}
ffffffffc02036f8:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036fa:	691c                	ld	a5,16(a0)
ffffffffc02036fc:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02036da <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203700:	ea88                	sd	a0,16(a3)
ffffffffc0203702:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203704:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203708:	ea88                	sd	a0,16(a3)
ffffffffc020370a:	8082                	ret

ffffffffc020370c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020370c:	6590                	ld	a2,8(a1)
ffffffffc020370e:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ef8>
{
ffffffffc0203712:	1141                	addi	sp,sp,-16
ffffffffc0203714:	e406                	sd	ra,8(sp)
ffffffffc0203716:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203718:	01066763          	bltu	a2,a6,ffffffffc0203726 <insert_vma_struct+0x1a>
ffffffffc020371c:	a085                	j	ffffffffc020377c <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020371e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203722:	04e66863          	bltu	a2,a4,ffffffffc0203772 <insert_vma_struct+0x66>
ffffffffc0203726:	86be                	mv	a3,a5
ffffffffc0203728:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020372a:	fef51ae3          	bne	a0,a5,ffffffffc020371e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020372e:	02a68463          	beq	a3,a0,ffffffffc0203756 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203732:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203736:	fe86b883          	ld	a7,-24(a3)
ffffffffc020373a:	08e8f163          	bgeu	a7,a4,ffffffffc02037bc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020373e:	04e66f63          	bltu	a2,a4,ffffffffc020379c <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203742:	00f50a63          	beq	a0,a5,ffffffffc0203756 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203746:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020374a:	05076963          	bltu	a4,a6,ffffffffc020379c <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020374e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203752:	02c77363          	bgeu	a4,a2,ffffffffc0203778 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203756:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203758:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020375a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020375e:	e390                	sd	a2,0(a5)
ffffffffc0203760:	e690                	sd	a2,8(a3)
}
ffffffffc0203762:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203764:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203766:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203768:	0017079b          	addiw	a5,a4,1
ffffffffc020376c:	d11c                	sw	a5,32(a0)
}
ffffffffc020376e:	0141                	addi	sp,sp,16
ffffffffc0203770:	8082                	ret
    if (le_prev != list)
ffffffffc0203772:	fca690e3          	bne	a3,a0,ffffffffc0203732 <insert_vma_struct+0x26>
ffffffffc0203776:	bfd1                	j	ffffffffc020374a <insert_vma_struct+0x3e>
ffffffffc0203778:	f01ff0ef          	jal	ra,ffffffffc0203678 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020377c:	00003697          	auipc	a3,0x3
ffffffffc0203780:	54468693          	addi	a3,a3,1348 # ffffffffc0206cc0 <default_pmm_manager+0x7b8>
ffffffffc0203784:	00003617          	auipc	a2,0x3
ffffffffc0203788:	9d460613          	addi	a2,a2,-1580 # ffffffffc0206158 <commands+0x818>
ffffffffc020378c:	07a00593          	li	a1,122
ffffffffc0203790:	00003517          	auipc	a0,0x3
ffffffffc0203794:	52050513          	addi	a0,a0,1312 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203798:	cf7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020379c:	00003697          	auipc	a3,0x3
ffffffffc02037a0:	56468693          	addi	a3,a3,1380 # ffffffffc0206d00 <default_pmm_manager+0x7f8>
ffffffffc02037a4:	00003617          	auipc	a2,0x3
ffffffffc02037a8:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206158 <commands+0x818>
ffffffffc02037ac:	07300593          	li	a1,115
ffffffffc02037b0:	00003517          	auipc	a0,0x3
ffffffffc02037b4:	50050513          	addi	a0,a0,1280 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc02037b8:	cd7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037bc:	00003697          	auipc	a3,0x3
ffffffffc02037c0:	52468693          	addi	a3,a3,1316 # ffffffffc0206ce0 <default_pmm_manager+0x7d8>
ffffffffc02037c4:	00003617          	auipc	a2,0x3
ffffffffc02037c8:	99460613          	addi	a2,a2,-1644 # ffffffffc0206158 <commands+0x818>
ffffffffc02037cc:	07200593          	li	a1,114
ffffffffc02037d0:	00003517          	auipc	a0,0x3
ffffffffc02037d4:	4e050513          	addi	a0,a0,1248 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc02037d8:	cb7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037dc <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02037dc:	591c                	lw	a5,48(a0)
{
ffffffffc02037de:	1141                	addi	sp,sp,-16
ffffffffc02037e0:	e406                	sd	ra,8(sp)
ffffffffc02037e2:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02037e4:	e78d                	bnez	a5,ffffffffc020380e <mm_destroy+0x32>
ffffffffc02037e6:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02037e8:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02037ea:	00a40c63          	beq	s0,a0,ffffffffc0203802 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02037ee:	6118                	ld	a4,0(a0)
ffffffffc02037f0:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02037f2:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02037f4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02037f6:	e398                	sd	a4,0(a5)
ffffffffc02037f8:	d52fe0ef          	jal	ra,ffffffffc0201d4a <kfree>
    return listelm->next;
ffffffffc02037fc:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02037fe:	fea418e3          	bne	s0,a0,ffffffffc02037ee <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203802:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203804:	6402                	ld	s0,0(sp)
ffffffffc0203806:	60a2                	ld	ra,8(sp)
ffffffffc0203808:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020380a:	d40fe06f          	j	ffffffffc0201d4a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020380e:	00003697          	auipc	a3,0x3
ffffffffc0203812:	51268693          	addi	a3,a3,1298 # ffffffffc0206d20 <default_pmm_manager+0x818>
ffffffffc0203816:	00003617          	auipc	a2,0x3
ffffffffc020381a:	94260613          	addi	a2,a2,-1726 # ffffffffc0206158 <commands+0x818>
ffffffffc020381e:	09e00593          	li	a1,158
ffffffffc0203822:	00003517          	auipc	a0,0x3
ffffffffc0203826:	48e50513          	addi	a0,a0,1166 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc020382a:	c65fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020382e <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020382e:	7139                	addi	sp,sp,-64
ffffffffc0203830:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203832:	6405                	lui	s0,0x1
ffffffffc0203834:	147d                	addi	s0,s0,-1
ffffffffc0203836:	77fd                	lui	a5,0xfffff
ffffffffc0203838:	9622                	add	a2,a2,s0
ffffffffc020383a:	962e                	add	a2,a2,a1
{
ffffffffc020383c:	f426                	sd	s1,40(sp)
ffffffffc020383e:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203840:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203844:	f04a                	sd	s2,32(sp)
ffffffffc0203846:	ec4e                	sd	s3,24(sp)
ffffffffc0203848:	e852                	sd	s4,16(sp)
ffffffffc020384a:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020384c:	002005b7          	lui	a1,0x200
ffffffffc0203850:	00f67433          	and	s0,a2,a5
ffffffffc0203854:	06b4e363          	bltu	s1,a1,ffffffffc02038ba <mm_map+0x8c>
ffffffffc0203858:	0684f163          	bgeu	s1,s0,ffffffffc02038ba <mm_map+0x8c>
ffffffffc020385c:	4785                	li	a5,1
ffffffffc020385e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203860:	0487ed63          	bltu	a5,s0,ffffffffc02038ba <mm_map+0x8c>
ffffffffc0203864:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203866:	cd21                	beqz	a0,ffffffffc02038be <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203868:	85a6                	mv	a1,s1
ffffffffc020386a:	8ab6                	mv	s5,a3
ffffffffc020386c:	8a3a                	mv	s4,a4
ffffffffc020386e:	e5fff0ef          	jal	ra,ffffffffc02036cc <find_vma>
ffffffffc0203872:	c501                	beqz	a0,ffffffffc020387a <mm_map+0x4c>
ffffffffc0203874:	651c                	ld	a5,8(a0)
ffffffffc0203876:	0487e263          	bltu	a5,s0,ffffffffc02038ba <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020387a:	03000513          	li	a0,48
ffffffffc020387e:	c1cfe0ef          	jal	ra,ffffffffc0201c9a <kmalloc>
ffffffffc0203882:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203884:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203886:	02090163          	beqz	s2,ffffffffc02038a8 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020388a:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc020388c:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203890:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203894:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203898:	85ca                	mv	a1,s2
ffffffffc020389a:	e73ff0ef          	jal	ra,ffffffffc020370c <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc020389e:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02038a0:	000a0463          	beqz	s4,ffffffffc02038a8 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02038a4:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba0>

out:
    return ret;
}
ffffffffc02038a8:	70e2                	ld	ra,56(sp)
ffffffffc02038aa:	7442                	ld	s0,48(sp)
ffffffffc02038ac:	74a2                	ld	s1,40(sp)
ffffffffc02038ae:	7902                	ld	s2,32(sp)
ffffffffc02038b0:	69e2                	ld	s3,24(sp)
ffffffffc02038b2:	6a42                	ld	s4,16(sp)
ffffffffc02038b4:	6aa2                	ld	s5,8(sp)
ffffffffc02038b6:	6121                	addi	sp,sp,64
ffffffffc02038b8:	8082                	ret
        return -E_INVAL;
ffffffffc02038ba:	5575                	li	a0,-3
ffffffffc02038bc:	b7f5                	j	ffffffffc02038a8 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038be:	00003697          	auipc	a3,0x3
ffffffffc02038c2:	47a68693          	addi	a3,a3,1146 # ffffffffc0206d38 <default_pmm_manager+0x830>
ffffffffc02038c6:	00003617          	auipc	a2,0x3
ffffffffc02038ca:	89260613          	addi	a2,a2,-1902 # ffffffffc0206158 <commands+0x818>
ffffffffc02038ce:	0b300593          	li	a1,179
ffffffffc02038d2:	00003517          	auipc	a0,0x3
ffffffffc02038d6:	3de50513          	addi	a0,a0,990 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc02038da:	bb5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038de <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038de:	7139                	addi	sp,sp,-64
ffffffffc02038e0:	fc06                	sd	ra,56(sp)
ffffffffc02038e2:	f822                	sd	s0,48(sp)
ffffffffc02038e4:	f426                	sd	s1,40(sp)
ffffffffc02038e6:	f04a                	sd	s2,32(sp)
ffffffffc02038e8:	ec4e                	sd	s3,24(sp)
ffffffffc02038ea:	e852                	sd	s4,16(sp)
ffffffffc02038ec:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02038ee:	c52d                	beqz	a0,ffffffffc0203958 <dup_mmap+0x7a>
ffffffffc02038f0:	892a                	mv	s2,a0
ffffffffc02038f2:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02038f4:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02038f6:	e595                	bnez	a1,ffffffffc0203922 <dup_mmap+0x44>
ffffffffc02038f8:	a085                	j	ffffffffc0203958 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02038fa:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02038fc:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ef0>
        vma->vm_end = vm_end;
ffffffffc0203900:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203904:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203908:	e05ff0ef          	jal	ra,ffffffffc020370c <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020390c:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb0>
ffffffffc0203910:	fe843603          	ld	a2,-24(s0)
ffffffffc0203914:	6c8c                	ld	a1,24(s1)
ffffffffc0203916:	01893503          	ld	a0,24(s2)
ffffffffc020391a:	4701                	li	a4,0
ffffffffc020391c:	a3bff0ef          	jal	ra,ffffffffc0203356 <copy_range>
ffffffffc0203920:	e105                	bnez	a0,ffffffffc0203940 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203922:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203924:	02848863          	beq	s1,s0,ffffffffc0203954 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203928:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020392c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203930:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203934:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203938:	b62fe0ef          	jal	ra,ffffffffc0201c9a <kmalloc>
ffffffffc020393c:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020393e:	fd55                	bnez	a0,ffffffffc02038fa <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203940:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203942:	70e2                	ld	ra,56(sp)
ffffffffc0203944:	7442                	ld	s0,48(sp)
ffffffffc0203946:	74a2                	ld	s1,40(sp)
ffffffffc0203948:	7902                	ld	s2,32(sp)
ffffffffc020394a:	69e2                	ld	s3,24(sp)
ffffffffc020394c:	6a42                	ld	s4,16(sp)
ffffffffc020394e:	6aa2                	ld	s5,8(sp)
ffffffffc0203950:	6121                	addi	sp,sp,64
ffffffffc0203952:	8082                	ret
    return 0;
ffffffffc0203954:	4501                	li	a0,0
ffffffffc0203956:	b7f5                	j	ffffffffc0203942 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203958:	00003697          	auipc	a3,0x3
ffffffffc020395c:	3f068693          	addi	a3,a3,1008 # ffffffffc0206d48 <default_pmm_manager+0x840>
ffffffffc0203960:	00002617          	auipc	a2,0x2
ffffffffc0203964:	7f860613          	addi	a2,a2,2040 # ffffffffc0206158 <commands+0x818>
ffffffffc0203968:	0cf00593          	li	a1,207
ffffffffc020396c:	00003517          	auipc	a0,0x3
ffffffffc0203970:	34450513          	addi	a0,a0,836 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203974:	b1bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203978 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203978:	1101                	addi	sp,sp,-32
ffffffffc020397a:	ec06                	sd	ra,24(sp)
ffffffffc020397c:	e822                	sd	s0,16(sp)
ffffffffc020397e:	e426                	sd	s1,8(sp)
ffffffffc0203980:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203982:	c531                	beqz	a0,ffffffffc02039ce <exit_mmap+0x56>
ffffffffc0203984:	591c                	lw	a5,48(a0)
ffffffffc0203986:	84aa                	mv	s1,a0
ffffffffc0203988:	e3b9                	bnez	a5,ffffffffc02039ce <exit_mmap+0x56>
    return listelm->next;
ffffffffc020398a:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc020398c:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203990:	02850663          	beq	a0,s0,ffffffffc02039bc <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203994:	ff043603          	ld	a2,-16(s0)
ffffffffc0203998:	fe843583          	ld	a1,-24(s0)
ffffffffc020399c:	854a                	mv	a0,s2
ffffffffc020399e:	80ffe0ef          	jal	ra,ffffffffc02021ac <unmap_range>
ffffffffc02039a2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039a4:	fe8498e3          	bne	s1,s0,ffffffffc0203994 <exit_mmap+0x1c>
ffffffffc02039a8:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039aa:	00848c63          	beq	s1,s0,ffffffffc02039c2 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039ae:	ff043603          	ld	a2,-16(s0)
ffffffffc02039b2:	fe843583          	ld	a1,-24(s0)
ffffffffc02039b6:	854a                	mv	a0,s2
ffffffffc02039b8:	93bfe0ef          	jal	ra,ffffffffc02022f2 <exit_range>
ffffffffc02039bc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039be:	fe8498e3          	bne	s1,s0,ffffffffc02039ae <exit_mmap+0x36>
    }
}
ffffffffc02039c2:	60e2                	ld	ra,24(sp)
ffffffffc02039c4:	6442                	ld	s0,16(sp)
ffffffffc02039c6:	64a2                	ld	s1,8(sp)
ffffffffc02039c8:	6902                	ld	s2,0(sp)
ffffffffc02039ca:	6105                	addi	sp,sp,32
ffffffffc02039cc:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039ce:	00003697          	auipc	a3,0x3
ffffffffc02039d2:	39a68693          	addi	a3,a3,922 # ffffffffc0206d68 <default_pmm_manager+0x860>
ffffffffc02039d6:	00002617          	auipc	a2,0x2
ffffffffc02039da:	78260613          	addi	a2,a2,1922 # ffffffffc0206158 <commands+0x818>
ffffffffc02039de:	0e800593          	li	a1,232
ffffffffc02039e2:	00003517          	auipc	a0,0x3
ffffffffc02039e6:	2ce50513          	addi	a0,a0,718 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc02039ea:	aa5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039ee <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02039ee:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039f0:	04000513          	li	a0,64
{
ffffffffc02039f4:	fc06                	sd	ra,56(sp)
ffffffffc02039f6:	f822                	sd	s0,48(sp)
ffffffffc02039f8:	f426                	sd	s1,40(sp)
ffffffffc02039fa:	f04a                	sd	s2,32(sp)
ffffffffc02039fc:	ec4e                	sd	s3,24(sp)
ffffffffc02039fe:	e852                	sd	s4,16(sp)
ffffffffc0203a00:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a02:	a98fe0ef          	jal	ra,ffffffffc0201c9a <kmalloc>
    if (mm != NULL)
ffffffffc0203a06:	2e050663          	beqz	a0,ffffffffc0203cf2 <vmm_init+0x304>
ffffffffc0203a0a:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203a0c:	e508                	sd	a0,8(a0)
ffffffffc0203a0e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a10:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a14:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a18:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a1c:	02053423          	sd	zero,40(a0)
ffffffffc0203a20:	02052823          	sw	zero,48(a0)
ffffffffc0203a24:	02053c23          	sd	zero,56(a0)
ffffffffc0203a28:	03200413          	li	s0,50
ffffffffc0203a2c:	a811                	j	ffffffffc0203a40 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203a2e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a30:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a32:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203a36:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a38:	8526                	mv	a0,s1
ffffffffc0203a3a:	cd3ff0ef          	jal	ra,ffffffffc020370c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a3e:	c80d                	beqz	s0,ffffffffc0203a70 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a40:	03000513          	li	a0,48
ffffffffc0203a44:	a56fe0ef          	jal	ra,ffffffffc0201c9a <kmalloc>
ffffffffc0203a48:	85aa                	mv	a1,a0
ffffffffc0203a4a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a4e:	f165                	bnez	a0,ffffffffc0203a2e <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a50:	00003697          	auipc	a3,0x3
ffffffffc0203a54:	4b068693          	addi	a3,a3,1200 # ffffffffc0206f00 <default_pmm_manager+0x9f8>
ffffffffc0203a58:	00002617          	auipc	a2,0x2
ffffffffc0203a5c:	70060613          	addi	a2,a2,1792 # ffffffffc0206158 <commands+0x818>
ffffffffc0203a60:	12c00593          	li	a1,300
ffffffffc0203a64:	00003517          	auipc	a0,0x3
ffffffffc0203a68:	24c50513          	addi	a0,a0,588 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203a6c:	a23fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203a70:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a74:	1f900913          	li	s2,505
ffffffffc0203a78:	a819                	j	ffffffffc0203a8e <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203a7a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a7c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a7e:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a82:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a84:	8526                	mv	a0,s1
ffffffffc0203a86:	c87ff0ef          	jal	ra,ffffffffc020370c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a8a:	03240a63          	beq	s0,s2,ffffffffc0203abe <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a8e:	03000513          	li	a0,48
ffffffffc0203a92:	a08fe0ef          	jal	ra,ffffffffc0201c9a <kmalloc>
ffffffffc0203a96:	85aa                	mv	a1,a0
ffffffffc0203a98:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a9c:	fd79                	bnez	a0,ffffffffc0203a7a <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203a9e:	00003697          	auipc	a3,0x3
ffffffffc0203aa2:	46268693          	addi	a3,a3,1122 # ffffffffc0206f00 <default_pmm_manager+0x9f8>
ffffffffc0203aa6:	00002617          	auipc	a2,0x2
ffffffffc0203aaa:	6b260613          	addi	a2,a2,1714 # ffffffffc0206158 <commands+0x818>
ffffffffc0203aae:	13300593          	li	a1,307
ffffffffc0203ab2:	00003517          	auipc	a0,0x3
ffffffffc0203ab6:	1fe50513          	addi	a0,a0,510 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203aba:	9d5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203abe:	649c                	ld	a5,8(s1)
ffffffffc0203ac0:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ac2:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203ac6:	16f48663          	beq	s1,a5,ffffffffc0203c32 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203aca:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd54904>
ffffffffc0203ace:	ffe70693          	addi	a3,a4,-2
ffffffffc0203ad2:	10d61063          	bne	a2,a3,ffffffffc0203bd2 <vmm_init+0x1e4>
ffffffffc0203ad6:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203ada:	0ed71c63          	bne	a4,a3,ffffffffc0203bd2 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203ade:	0715                	addi	a4,a4,5
ffffffffc0203ae0:	679c                	ld	a5,8(a5)
ffffffffc0203ae2:	feb712e3          	bne	a4,a1,ffffffffc0203ac6 <vmm_init+0xd8>
ffffffffc0203ae6:	4a1d                	li	s4,7
ffffffffc0203ae8:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203aea:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203aee:	85a2                	mv	a1,s0
ffffffffc0203af0:	8526                	mv	a0,s1
ffffffffc0203af2:	bdbff0ef          	jal	ra,ffffffffc02036cc <find_vma>
ffffffffc0203af6:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203af8:	16050d63          	beqz	a0,ffffffffc0203c72 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203afc:	00140593          	addi	a1,s0,1
ffffffffc0203b00:	8526                	mv	a0,s1
ffffffffc0203b02:	bcbff0ef          	jal	ra,ffffffffc02036cc <find_vma>
ffffffffc0203b06:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b08:	14050563          	beqz	a0,ffffffffc0203c52 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b0c:	85d2                	mv	a1,s4
ffffffffc0203b0e:	8526                	mv	a0,s1
ffffffffc0203b10:	bbdff0ef          	jal	ra,ffffffffc02036cc <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b14:	16051f63          	bnez	a0,ffffffffc0203c92 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b18:	00340593          	addi	a1,s0,3
ffffffffc0203b1c:	8526                	mv	a0,s1
ffffffffc0203b1e:	bafff0ef          	jal	ra,ffffffffc02036cc <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b22:	1a051863          	bnez	a0,ffffffffc0203cd2 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b26:	00440593          	addi	a1,s0,4
ffffffffc0203b2a:	8526                	mv	a0,s1
ffffffffc0203b2c:	ba1ff0ef          	jal	ra,ffffffffc02036cc <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b30:	18051163          	bnez	a0,ffffffffc0203cb2 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b34:	00893783          	ld	a5,8(s2)
ffffffffc0203b38:	0a879d63          	bne	a5,s0,ffffffffc0203bf2 <vmm_init+0x204>
ffffffffc0203b3c:	01093783          	ld	a5,16(s2)
ffffffffc0203b40:	0b479963          	bne	a5,s4,ffffffffc0203bf2 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b44:	0089b783          	ld	a5,8(s3)
ffffffffc0203b48:	0c879563          	bne	a5,s0,ffffffffc0203c12 <vmm_init+0x224>
ffffffffc0203b4c:	0109b783          	ld	a5,16(s3)
ffffffffc0203b50:	0d479163          	bne	a5,s4,ffffffffc0203c12 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b54:	0415                	addi	s0,s0,5
ffffffffc0203b56:	0a15                	addi	s4,s4,5
ffffffffc0203b58:	f9541be3          	bne	s0,s5,ffffffffc0203aee <vmm_init+0x100>
ffffffffc0203b5c:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b5e:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b60:	85a2                	mv	a1,s0
ffffffffc0203b62:	8526                	mv	a0,s1
ffffffffc0203b64:	b69ff0ef          	jal	ra,ffffffffc02036cc <find_vma>
ffffffffc0203b68:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b6c:	c90d                	beqz	a0,ffffffffc0203b9e <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203b6e:	6914                	ld	a3,16(a0)
ffffffffc0203b70:	6510                	ld	a2,8(a0)
ffffffffc0203b72:	00003517          	auipc	a0,0x3
ffffffffc0203b76:	31650513          	addi	a0,a0,790 # ffffffffc0206e88 <default_pmm_manager+0x980>
ffffffffc0203b7a:	e1afc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b7e:	00003697          	auipc	a3,0x3
ffffffffc0203b82:	33268693          	addi	a3,a3,818 # ffffffffc0206eb0 <default_pmm_manager+0x9a8>
ffffffffc0203b86:	00002617          	auipc	a2,0x2
ffffffffc0203b8a:	5d260613          	addi	a2,a2,1490 # ffffffffc0206158 <commands+0x818>
ffffffffc0203b8e:	15900593          	li	a1,345
ffffffffc0203b92:	00003517          	auipc	a0,0x3
ffffffffc0203b96:	11e50513          	addi	a0,a0,286 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203b9a:	8f5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203b9e:	147d                	addi	s0,s0,-1
ffffffffc0203ba0:	fd2410e3          	bne	s0,s2,ffffffffc0203b60 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203ba4:	8526                	mv	a0,s1
ffffffffc0203ba6:	c37ff0ef          	jal	ra,ffffffffc02037dc <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203baa:	00003517          	auipc	a0,0x3
ffffffffc0203bae:	31e50513          	addi	a0,a0,798 # ffffffffc0206ec8 <default_pmm_manager+0x9c0>
ffffffffc0203bb2:	de2fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203bb6:	7442                	ld	s0,48(sp)
ffffffffc0203bb8:	70e2                	ld	ra,56(sp)
ffffffffc0203bba:	74a2                	ld	s1,40(sp)
ffffffffc0203bbc:	7902                	ld	s2,32(sp)
ffffffffc0203bbe:	69e2                	ld	s3,24(sp)
ffffffffc0203bc0:	6a42                	ld	s4,16(sp)
ffffffffc0203bc2:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bc4:	00003517          	auipc	a0,0x3
ffffffffc0203bc8:	32450513          	addi	a0,a0,804 # ffffffffc0206ee8 <default_pmm_manager+0x9e0>
}
ffffffffc0203bcc:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bce:	dc6fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bd2:	00003697          	auipc	a3,0x3
ffffffffc0203bd6:	1ce68693          	addi	a3,a3,462 # ffffffffc0206da0 <default_pmm_manager+0x898>
ffffffffc0203bda:	00002617          	auipc	a2,0x2
ffffffffc0203bde:	57e60613          	addi	a2,a2,1406 # ffffffffc0206158 <commands+0x818>
ffffffffc0203be2:	13d00593          	li	a1,317
ffffffffc0203be6:	00003517          	auipc	a0,0x3
ffffffffc0203bea:	0ca50513          	addi	a0,a0,202 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203bee:	8a1fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bf2:	00003697          	auipc	a3,0x3
ffffffffc0203bf6:	23668693          	addi	a3,a3,566 # ffffffffc0206e28 <default_pmm_manager+0x920>
ffffffffc0203bfa:	00002617          	auipc	a2,0x2
ffffffffc0203bfe:	55e60613          	addi	a2,a2,1374 # ffffffffc0206158 <commands+0x818>
ffffffffc0203c02:	14e00593          	li	a1,334
ffffffffc0203c06:	00003517          	auipc	a0,0x3
ffffffffc0203c0a:	0aa50513          	addi	a0,a0,170 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203c0e:	881fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c12:	00003697          	auipc	a3,0x3
ffffffffc0203c16:	24668693          	addi	a3,a3,582 # ffffffffc0206e58 <default_pmm_manager+0x950>
ffffffffc0203c1a:	00002617          	auipc	a2,0x2
ffffffffc0203c1e:	53e60613          	addi	a2,a2,1342 # ffffffffc0206158 <commands+0x818>
ffffffffc0203c22:	14f00593          	li	a1,335
ffffffffc0203c26:	00003517          	auipc	a0,0x3
ffffffffc0203c2a:	08a50513          	addi	a0,a0,138 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203c2e:	861fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c32:	00003697          	auipc	a3,0x3
ffffffffc0203c36:	15668693          	addi	a3,a3,342 # ffffffffc0206d88 <default_pmm_manager+0x880>
ffffffffc0203c3a:	00002617          	auipc	a2,0x2
ffffffffc0203c3e:	51e60613          	addi	a2,a2,1310 # ffffffffc0206158 <commands+0x818>
ffffffffc0203c42:	13b00593          	li	a1,315
ffffffffc0203c46:	00003517          	auipc	a0,0x3
ffffffffc0203c4a:	06a50513          	addi	a0,a0,106 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203c4e:	841fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c52:	00003697          	auipc	a3,0x3
ffffffffc0203c56:	19668693          	addi	a3,a3,406 # ffffffffc0206de8 <default_pmm_manager+0x8e0>
ffffffffc0203c5a:	00002617          	auipc	a2,0x2
ffffffffc0203c5e:	4fe60613          	addi	a2,a2,1278 # ffffffffc0206158 <commands+0x818>
ffffffffc0203c62:	14600593          	li	a1,326
ffffffffc0203c66:	00003517          	auipc	a0,0x3
ffffffffc0203c6a:	04a50513          	addi	a0,a0,74 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203c6e:	821fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203c72:	00003697          	auipc	a3,0x3
ffffffffc0203c76:	16668693          	addi	a3,a3,358 # ffffffffc0206dd8 <default_pmm_manager+0x8d0>
ffffffffc0203c7a:	00002617          	auipc	a2,0x2
ffffffffc0203c7e:	4de60613          	addi	a2,a2,1246 # ffffffffc0206158 <commands+0x818>
ffffffffc0203c82:	14400593          	li	a1,324
ffffffffc0203c86:	00003517          	auipc	a0,0x3
ffffffffc0203c8a:	02a50513          	addi	a0,a0,42 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203c8e:	801fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203c92:	00003697          	auipc	a3,0x3
ffffffffc0203c96:	16668693          	addi	a3,a3,358 # ffffffffc0206df8 <default_pmm_manager+0x8f0>
ffffffffc0203c9a:	00002617          	auipc	a2,0x2
ffffffffc0203c9e:	4be60613          	addi	a2,a2,1214 # ffffffffc0206158 <commands+0x818>
ffffffffc0203ca2:	14800593          	li	a1,328
ffffffffc0203ca6:	00003517          	auipc	a0,0x3
ffffffffc0203caa:	00a50513          	addi	a0,a0,10 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203cae:	fe0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203cb2:	00003697          	auipc	a3,0x3
ffffffffc0203cb6:	16668693          	addi	a3,a3,358 # ffffffffc0206e18 <default_pmm_manager+0x910>
ffffffffc0203cba:	00002617          	auipc	a2,0x2
ffffffffc0203cbe:	49e60613          	addi	a2,a2,1182 # ffffffffc0206158 <commands+0x818>
ffffffffc0203cc2:	14c00593          	li	a1,332
ffffffffc0203cc6:	00003517          	auipc	a0,0x3
ffffffffc0203cca:	fea50513          	addi	a0,a0,-22 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203cce:	fc0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203cd2:	00003697          	auipc	a3,0x3
ffffffffc0203cd6:	13668693          	addi	a3,a3,310 # ffffffffc0206e08 <default_pmm_manager+0x900>
ffffffffc0203cda:	00002617          	auipc	a2,0x2
ffffffffc0203cde:	47e60613          	addi	a2,a2,1150 # ffffffffc0206158 <commands+0x818>
ffffffffc0203ce2:	14a00593          	li	a1,330
ffffffffc0203ce6:	00003517          	auipc	a0,0x3
ffffffffc0203cea:	fca50513          	addi	a0,a0,-54 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203cee:	fa0fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203cf2:	00003697          	auipc	a3,0x3
ffffffffc0203cf6:	04668693          	addi	a3,a3,70 # ffffffffc0206d38 <default_pmm_manager+0x830>
ffffffffc0203cfa:	00002617          	auipc	a2,0x2
ffffffffc0203cfe:	45e60613          	addi	a2,a2,1118 # ffffffffc0206158 <commands+0x818>
ffffffffc0203d02:	12400593          	li	a1,292
ffffffffc0203d06:	00003517          	auipc	a0,0x3
ffffffffc0203d0a:	faa50513          	addi	a0,a0,-86 # ffffffffc0206cb0 <default_pmm_manager+0x7a8>
ffffffffc0203d0e:	f80fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d12 <user_mem_check>:
}
//内核在访问用户提供的内存指针之前，必须验证这段内存是否合法、是否存在、是否有对应的读写权限。 
//防止用户恶意传一个内核地址或无效地址导致内核崩溃。
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d12:	7179                	addi	sp,sp,-48
ffffffffc0203d14:	f022                	sd	s0,32(sp)
ffffffffc0203d16:	f406                	sd	ra,40(sp)
ffffffffc0203d18:	ec26                	sd	s1,24(sp)
ffffffffc0203d1a:	e84a                	sd	s2,16(sp)
ffffffffc0203d1c:	e44e                	sd	s3,8(sp)
ffffffffc0203d1e:	e052                	sd	s4,0(sp)
ffffffffc0203d20:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d22:	c135                	beqz	a0,ffffffffc0203d86 <user_mem_check+0x74>
    {
        // 1. 宏观边界检查
        // USER_ACCESS 通常检查 (addr + len) 是否超过了 USERTOP（用户空间的上限）。
        // 如果用户试图访问内核空间，直接拒绝。
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d24:	002007b7          	lui	a5,0x200
ffffffffc0203d28:	04f5e663          	bltu	a1,a5,ffffffffc0203d74 <user_mem_check+0x62>
ffffffffc0203d2c:	00c584b3          	add	s1,a1,a2
ffffffffc0203d30:	0495f263          	bgeu	a1,s1,ffffffffc0203d74 <user_mem_check+0x62>
ffffffffc0203d34:	4785                	li	a5,1
ffffffffc0203d36:	07fe                	slli	a5,a5,0x1f
ffffffffc0203d38:	0297ee63          	bltu	a5,s1,ffffffffc0203d74 <user_mem_check+0x62>
ffffffffc0203d3c:	892a                	mv	s2,a0
ffffffffc0203d3e:	89b6                	mv	s3,a3
            // 4. 栈溢出保护 (Stack Guard)
            // 如果是在写栈区 (VM_STACK)，且写入位置在 VMA 起始的一页 (PGSIZE) 之内。
            // 这通常是为了保留栈底的一页作为“警戒页”，防止栈溢出覆盖其他数据。
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d40:	6a05                	lui	s4,0x1
ffffffffc0203d42:	a821                	j	ffffffffc0203d5a <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d44:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d48:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d4a:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d4c:	c685                	beqz	a3,ffffffffc0203d74 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d4e:	c399                	beqz	a5,ffffffffc0203d54 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d50:	02e46263          	bltu	s0,a4,ffffffffc0203d74 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            // 检查完当前 VMA，跳到当前 VMA 的结束位置，继续检查下一段，直到覆盖整个 [addr, len]
            start = vma->vm_end;
ffffffffc0203d54:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203d56:	04947663          	bgeu	s0,s1,ffffffffc0203da2 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203d5a:	85a2                	mv	a1,s0
ffffffffc0203d5c:	854a                	mv	a0,s2
ffffffffc0203d5e:	96fff0ef          	jal	ra,ffffffffc02036cc <find_vma>
ffffffffc0203d62:	c909                	beqz	a0,ffffffffc0203d74 <user_mem_check+0x62>
ffffffffc0203d64:	6518                	ld	a4,8(a0)
ffffffffc0203d66:	00e46763          	bltu	s0,a4,ffffffffc0203d74 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d6a:	4d1c                	lw	a5,24(a0)
ffffffffc0203d6c:	fc099ce3          	bnez	s3,ffffffffc0203d44 <user_mem_check+0x32>
ffffffffc0203d70:	8b85                	andi	a5,a5,1
ffffffffc0203d72:	f3ed                	bnez	a5,ffffffffc0203d54 <user_mem_check+0x42>
            return 0;
ffffffffc0203d74:	4501                	li	a0,0
        }
        return 1;// 所有检查通过
    }
    // 如果 mm 为 NULL，说明是内核线程，使用内核的检查规则
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d76:	70a2                	ld	ra,40(sp)
ffffffffc0203d78:	7402                	ld	s0,32(sp)
ffffffffc0203d7a:	64e2                	ld	s1,24(sp)
ffffffffc0203d7c:	6942                	ld	s2,16(sp)
ffffffffc0203d7e:	69a2                	ld	s3,8(sp)
ffffffffc0203d80:	6a02                	ld	s4,0(sp)
ffffffffc0203d82:	6145                	addi	sp,sp,48
ffffffffc0203d84:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d86:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d8a:	4501                	li	a0,0
ffffffffc0203d8c:	fef5e5e3          	bltu	a1,a5,ffffffffc0203d76 <user_mem_check+0x64>
ffffffffc0203d90:	962e                	add	a2,a2,a1
ffffffffc0203d92:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203d76 <user_mem_check+0x64>
ffffffffc0203d96:	c8000537          	lui	a0,0xc8000
ffffffffc0203d9a:	0505                	addi	a0,a0,1
ffffffffc0203d9c:	00a63533          	sltu	a0,a2,a0
ffffffffc0203da0:	bfd9                	j	ffffffffc0203d76 <user_mem_check+0x64>
        return 1;// 所有检查通过
ffffffffc0203da2:	4505                	li	a0,1
ffffffffc0203da4:	bfc9                	j	ffffffffc0203d76 <user_mem_check+0x64>

ffffffffc0203da6 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203da6:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203da8:	9402                	jalr	s0

	jal do_exit
ffffffffc0203daa:	638000ef          	jal	ra,ffffffffc02043e2 <do_exit>

ffffffffc0203dae <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203dae:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203db0:	10800513          	li	a0,264
{
ffffffffc0203db4:	e022                	sd	s0,0(sp)
ffffffffc0203db6:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203db8:	ee3fd0ef          	jal	ra,ffffffffc0201c9a <kmalloc>
ffffffffc0203dbc:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203dbe:	cd21                	beqz	a0,ffffffffc0203e16 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;         // 状态：未初始化
ffffffffc0203dc0:	57fd                	li	a5,-1
ffffffffc0203dc2:	1782                	slli	a5,a5,0x20
ffffffffc0203dc4:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                    // 运行时间：0
        proc->kstack = 0;                  // 内核栈：暂无
        proc->need_resched = 0;            // 不需要调度
        proc->parent = NULL;               // 父进程：暂无
        proc->mm = NULL;                   // 内存管理：暂无
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
ffffffffc0203dc6:	07000613          	li	a2,112
ffffffffc0203dca:	4581                	li	a1,0
        proc->runs = 0;                    // 运行时间：0
ffffffffc0203dcc:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d55924>
        proc->kstack = 0;                  // 内核栈：暂无
ffffffffc0203dd0:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;            // 不需要调度
ffffffffc0203dd4:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;               // 父进程：暂无
ffffffffc0203dd8:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                   // 内存管理：暂无
ffffffffc0203ddc:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
ffffffffc0203de0:	03050513          	addi	a0,a0,48
ffffffffc0203de4:	0cb010ef          	jal	ra,ffffffffc02056ae <memset>
        proc->tf = NULL;                   // 中断帧：暂无
        proc->pgdir = boot_pgdir_pa;       // 页表：默认使用内核页表
ffffffffc0203de8:	000a7797          	auipc	a5,0xa7
ffffffffc0203dec:	8b07b783          	ld	a5,-1872(a5) # ffffffffc02aa698 <boot_pgdir_pa>
        proc->tf = NULL;                   // 中断帧：暂无
ffffffffc0203df0:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;       // 页表：默认使用内核页表
ffffffffc0203df4:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                   // 标志位：0
ffffffffc0203df6:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 名字清零
ffffffffc0203dfa:	4641                	li	a2,16
ffffffffc0203dfc:	4581                	li	a1,0
ffffffffc0203dfe:	0b440513          	addi	a0,s0,180
ffffffffc0203e02:	0ad010ef          	jal	ra,ffffffffc02056ae <memset>
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        // 1. 初始化等待状态
        // 0 表示没有在等待任何事情 (WT_INTERRUPTED 之类的状态在 wait 时才设置)
        proc->wait_state = 0;
ffffffffc0203e06:	0e042623          	sw	zero,236(s0)
        // 2. 初始化家族指针
        // 刚出生的进程没有孩子，也没有被挂到兄弟链表上，所以全是 NULL
        proc->cptr = NULL;  // 没有孩子 (Child Pointer)
ffffffffc0203e0a:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;  // 没有哥哥 (Older Sibling Pointer)
ffffffffc0203e0e:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;  // 没有弟弟 (Younger Sibling Pointer)
ffffffffc0203e12:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0203e16:	60a2                	ld	ra,8(sp)
ffffffffc0203e18:	8522                	mv	a0,s0
ffffffffc0203e1a:	6402                	ld	s0,0(sp)
ffffffffc0203e1c:	0141                	addi	sp,sp,16
ffffffffc0203e1e:	8082                	ret

ffffffffc0203e20 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e20:	000a7797          	auipc	a5,0xa7
ffffffffc0203e24:	8a87b783          	ld	a5,-1880(a5) # ffffffffc02aa6c8 <current>
ffffffffc0203e28:	73c8                	ld	a0,160(a5)
ffffffffc0203e2a:	8e4fd06f          	j	ffffffffc0200f0e <forkrets>

ffffffffc0203e2e <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e2e:	000a7797          	auipc	a5,0xa7
ffffffffc0203e32:	89a7b783          	ld	a5,-1894(a5) # ffffffffc02aa6c8 <current>
ffffffffc0203e36:	43cc                	lw	a1,4(a5)
{
ffffffffc0203e38:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e3a:	00003617          	auipc	a2,0x3
ffffffffc0203e3e:	0d660613          	addi	a2,a2,214 # ffffffffc0206f10 <default_pmm_manager+0xa08>
ffffffffc0203e42:	00003517          	auipc	a0,0x3
ffffffffc0203e46:	0de50513          	addi	a0,a0,222 # ffffffffc0206f20 <default_pmm_manager+0xa18>
{
ffffffffc0203e4a:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e4c:	b48fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203e50:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0203e54:	b1078793          	addi	a5,a5,-1264 # a960 <_binary_obj___user_forktest_out_size>
ffffffffc0203e58:	e43e                	sd	a5,8(sp)
ffffffffc0203e5a:	00003517          	auipc	a0,0x3
ffffffffc0203e5e:	0b650513          	addi	a0,a0,182 # ffffffffc0206f10 <default_pmm_manager+0xa08>
ffffffffc0203e62:	00046797          	auipc	a5,0x46
ffffffffc0203e66:	86e78793          	addi	a5,a5,-1938 # ffffffffc02496d0 <_binary_obj___user_forktest_out_start>
ffffffffc0203e6a:	f03e                	sd	a5,32(sp)
ffffffffc0203e6c:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203e6e:	e802                	sd	zero,16(sp)
ffffffffc0203e70:	79c010ef          	jal	ra,ffffffffc020560c <strlen>
ffffffffc0203e74:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203e76:	4511                	li	a0,4
ffffffffc0203e78:	55a2                	lw	a1,40(sp)
ffffffffc0203e7a:	4662                	lw	a2,24(sp)
ffffffffc0203e7c:	5682                	lw	a3,32(sp)
ffffffffc0203e7e:	4722                	lw	a4,8(sp)
ffffffffc0203e80:	48a9                	li	a7,10
ffffffffc0203e82:	9002                	ebreak
ffffffffc0203e84:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203e86:	65c2                	ld	a1,16(sp)
ffffffffc0203e88:	00003517          	auipc	a0,0x3
ffffffffc0203e8c:	0c050513          	addi	a0,a0,192 # ffffffffc0206f48 <default_pmm_manager+0xa40>
ffffffffc0203e90:	b04fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
    //找到内存中exit程序的二进制代码 覆盖当前内核线程 变成用户进程运行 
#endif
    panic("user_main execve failed.\n");//execve失败 
ffffffffc0203e94:	00003617          	auipc	a2,0x3
ffffffffc0203e98:	0c460613          	addi	a2,a2,196 # ffffffffc0206f58 <default_pmm_manager+0xa50>
ffffffffc0203e9c:	45000593          	li	a1,1104
ffffffffc0203ea0:	00003517          	auipc	a0,0x3
ffffffffc0203ea4:	0d850513          	addi	a0,a0,216 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0203ea8:	de6fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203eac <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203eac:	6d14                	ld	a3,24(a0)
{
ffffffffc0203eae:	1141                	addi	sp,sp,-16
ffffffffc0203eb0:	e406                	sd	ra,8(sp)
ffffffffc0203eb2:	c02007b7          	lui	a5,0xc0200
ffffffffc0203eb6:	02f6ee63          	bltu	a3,a5,ffffffffc0203ef2 <put_pgdir+0x46>
ffffffffc0203eba:	000a7517          	auipc	a0,0xa7
ffffffffc0203ebe:	80653503          	ld	a0,-2042(a0) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0203ec2:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203ec4:	82b1                	srli	a3,a3,0xc
ffffffffc0203ec6:	000a6797          	auipc	a5,0xa6
ffffffffc0203eca:	7e27b783          	ld	a5,2018(a5) # ffffffffc02aa6a8 <npage>
ffffffffc0203ece:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f0a <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ed2:	00004517          	auipc	a0,0x4
ffffffffc0203ed6:	95e53503          	ld	a0,-1698(a0) # ffffffffc0207830 <nbase>
}
ffffffffc0203eda:	60a2                	ld	ra,8(sp)
ffffffffc0203edc:	8e89                	sub	a3,a3,a0
ffffffffc0203ede:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203ee0:	000a6517          	auipc	a0,0xa6
ffffffffc0203ee4:	7d053503          	ld	a0,2000(a0) # ffffffffc02aa6b0 <pages>
ffffffffc0203ee8:	4585                	li	a1,1
ffffffffc0203eea:	9536                	add	a0,a0,a3
}
ffffffffc0203eec:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203eee:	fc9fd06f          	j	ffffffffc0201eb6 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203ef2:	00002617          	auipc	a2,0x2
ffffffffc0203ef6:	6f660613          	addi	a2,a2,1782 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc0203efa:	07700593          	li	a1,119
ffffffffc0203efe:	00002517          	auipc	a0,0x2
ffffffffc0203f02:	66a50513          	addi	a0,a0,1642 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0203f06:	d88fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f0a:	00002617          	auipc	a2,0x2
ffffffffc0203f0e:	70660613          	addi	a2,a2,1798 # ffffffffc0206610 <default_pmm_manager+0x108>
ffffffffc0203f12:	06900593          	li	a1,105
ffffffffc0203f16:	00002517          	auipc	a0,0x2
ffffffffc0203f1a:	65250513          	addi	a0,a0,1618 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0203f1e:	d70fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f22 <proc_run>:
{
ffffffffc0203f22:	7179                	addi	sp,sp,-48
ffffffffc0203f24:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203f26:	000a6917          	auipc	s2,0xa6
ffffffffc0203f2a:	7a290913          	addi	s2,s2,1954 # ffffffffc02aa6c8 <current>
{
ffffffffc0203f2e:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203f30:	00093483          	ld	s1,0(s2)
{
ffffffffc0203f34:	f406                	sd	ra,40(sp)
ffffffffc0203f36:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203f38:	02a48863          	beq	s1,a0,ffffffffc0203f68 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f3c:	100027f3          	csrr	a5,sstatus
ffffffffc0203f40:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f42:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f44:	ef9d                	bnez	a5,ffffffffc0203f82 <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203f46:	755c                	ld	a5,168(a0)
ffffffffc0203f48:	577d                	li	a4,-1
ffffffffc0203f4a:	177e                	slli	a4,a4,0x3f
ffffffffc0203f4c:	83b1                	srli	a5,a5,0xc
            current = proc;                   
ffffffffc0203f4e:	00a93023          	sd	a0,0(s2)
ffffffffc0203f52:	8fd9                	or	a5,a5,a4
ffffffffc0203f54:	18079073          	csrw	satp,a5
            switch_to(&(from->context), &(proc->context));
ffffffffc0203f58:	03050593          	addi	a1,a0,48
ffffffffc0203f5c:	03048513          	addi	a0,s1,48
ffffffffc0203f60:	052010ef          	jal	ra,ffffffffc0204fb2 <switch_to>
    if (flag)
ffffffffc0203f64:	00099863          	bnez	s3,ffffffffc0203f74 <proc_run+0x52>
}
ffffffffc0203f68:	70a2                	ld	ra,40(sp)
ffffffffc0203f6a:	7482                	ld	s1,32(sp)
ffffffffc0203f6c:	6962                	ld	s2,24(sp)
ffffffffc0203f6e:	69c2                	ld	s3,16(sp)
ffffffffc0203f70:	6145                	addi	sp,sp,48
ffffffffc0203f72:	8082                	ret
ffffffffc0203f74:	70a2                	ld	ra,40(sp)
ffffffffc0203f76:	7482                	ld	s1,32(sp)
ffffffffc0203f78:	6962                	ld	s2,24(sp)
ffffffffc0203f7a:	69c2                	ld	s3,16(sp)
ffffffffc0203f7c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203f7e:	a31fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0203f82:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203f84:	a31fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0203f88:	6522                	ld	a0,8(sp)
ffffffffc0203f8a:	4985                	li	s3,1
ffffffffc0203f8c:	bf6d                	j	ffffffffc0203f46 <proc_run+0x24>

ffffffffc0203f8e <do_fork>:
{
ffffffffc0203f8e:	7119                	addi	sp,sp,-128
ffffffffc0203f90:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f92:	000a6917          	auipc	s2,0xa6
ffffffffc0203f96:	74e90913          	addi	s2,s2,1870 # ffffffffc02aa6e0 <nr_process>
ffffffffc0203f9a:	00092703          	lw	a4,0(s2)
{
ffffffffc0203f9e:	fc86                	sd	ra,120(sp)
ffffffffc0203fa0:	f8a2                	sd	s0,112(sp)
ffffffffc0203fa2:	f4a6                	sd	s1,104(sp)
ffffffffc0203fa4:	ecce                	sd	s3,88(sp)
ffffffffc0203fa6:	e8d2                	sd	s4,80(sp)
ffffffffc0203fa8:	e4d6                	sd	s5,72(sp)
ffffffffc0203faa:	e0da                	sd	s6,64(sp)
ffffffffc0203fac:	fc5e                	sd	s7,56(sp)
ffffffffc0203fae:	f862                	sd	s8,48(sp)
ffffffffc0203fb0:	f466                	sd	s9,40(sp)
ffffffffc0203fb2:	f06a                	sd	s10,32(sp)
ffffffffc0203fb4:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203fb6:	6785                	lui	a5,0x1
ffffffffc0203fb8:	32f75b63          	bge	a4,a5,ffffffffc02042ee <do_fork+0x360>
ffffffffc0203fbc:	8a2a                	mv	s4,a0
ffffffffc0203fbe:	89ae                	mv	s3,a1
ffffffffc0203fc0:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203fc2:	dedff0ef          	jal	ra,ffffffffc0203dae <alloc_proc>
ffffffffc0203fc6:	84aa                	mv	s1,a0
ffffffffc0203fc8:	30050463          	beqz	a0,ffffffffc02042d0 <do_fork+0x342>
    proc->parent = current;  // 设置新进程的父亲为当前进程
ffffffffc0203fcc:	000a6c17          	auipc	s8,0xa6
ffffffffc0203fd0:	6fcc0c13          	addi	s8,s8,1788 # ffffffffc02aa6c8 <current>
ffffffffc0203fd4:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0203fd8:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8ab4>
    proc->parent = current;  // 设置新进程的父亲为当前进程
ffffffffc0203fdc:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0203fde:	30071d63          	bnez	a4,ffffffffc02042f8 <do_fork+0x36a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203fe2:	4509                	li	a0,2
ffffffffc0203fe4:	e95fd0ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
    if (page != NULL)
ffffffffc0203fe8:	2e050163          	beqz	a0,ffffffffc02042ca <do_fork+0x33c>
    return page - pages + nbase;
ffffffffc0203fec:	000a6a97          	auipc	s5,0xa6
ffffffffc0203ff0:	6c4a8a93          	addi	s5,s5,1732 # ffffffffc02aa6b0 <pages>
ffffffffc0203ff4:	000ab683          	ld	a3,0(s5)
ffffffffc0203ff8:	00004b17          	auipc	s6,0x4
ffffffffc0203ffc:	838b0b13          	addi	s6,s6,-1992 # ffffffffc0207830 <nbase>
ffffffffc0204000:	000b3783          	ld	a5,0(s6)
ffffffffc0204004:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204008:	000a6b97          	auipc	s7,0xa6
ffffffffc020400c:	6a0b8b93          	addi	s7,s7,1696 # ffffffffc02aa6a8 <npage>
    return page - pages + nbase;
ffffffffc0204010:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204012:	5dfd                	li	s11,-1
ffffffffc0204014:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204018:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020401a:	00cddd93          	srli	s11,s11,0xc
ffffffffc020401e:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204022:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204024:	2ee67a63          	bgeu	a2,a4,ffffffffc0204318 <do_fork+0x38a>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204028:	000c3603          	ld	a2,0(s8)
ffffffffc020402c:	000a6c17          	auipc	s8,0xa6
ffffffffc0204030:	694c0c13          	addi	s8,s8,1684 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0204034:	000c3703          	ld	a4,0(s8)
ffffffffc0204038:	02863d03          	ld	s10,40(a2)
ffffffffc020403c:	e43e                	sd	a5,8(sp)
ffffffffc020403e:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204040:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204042:	020d0863          	beqz	s10,ffffffffc0204072 <do_fork+0xe4>
    if (clone_flags & CLONE_VM)
ffffffffc0204046:	100a7a13          	andi	s4,s4,256
ffffffffc020404a:	1c0a0163          	beqz	s4,ffffffffc020420c <do_fork+0x27e>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020404e:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204052:	018d3783          	ld	a5,24(s10)
ffffffffc0204056:	c02006b7          	lui	a3,0xc0200
ffffffffc020405a:	2705                	addiw	a4,a4,1
ffffffffc020405c:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204060:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204064:	2ed7e263          	bltu	a5,a3,ffffffffc0204348 <do_fork+0x3ba>
ffffffffc0204068:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020406c:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020406e:	8f99                	sub	a5,a5,a4
ffffffffc0204070:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204072:	6789                	lui	a5,0x2
ffffffffc0204074:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc0>
ffffffffc0204078:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020407a:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020407c:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020407e:	87b6                	mv	a5,a3
ffffffffc0204080:	12040893          	addi	a7,s0,288
ffffffffc0204084:	00063803          	ld	a6,0(a2)
ffffffffc0204088:	6608                	ld	a0,8(a2)
ffffffffc020408a:	6a0c                	ld	a1,16(a2)
ffffffffc020408c:	6e18                	ld	a4,24(a2)
ffffffffc020408e:	0107b023          	sd	a6,0(a5)
ffffffffc0204092:	e788                	sd	a0,8(a5)
ffffffffc0204094:	eb8c                	sd	a1,16(a5)
ffffffffc0204096:	ef98                	sd	a4,24(a5)
ffffffffc0204098:	02060613          	addi	a2,a2,32
ffffffffc020409c:	02078793          	addi	a5,a5,32
ffffffffc02040a0:	ff1612e3          	bne	a2,a7,ffffffffc0204084 <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc02040a4:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02040a8:	12098f63          	beqz	s3,ffffffffc02041e6 <do_fork+0x258>
ffffffffc02040ac:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02040b0:	00000797          	auipc	a5,0x0
ffffffffc02040b4:	d7078793          	addi	a5,a5,-656 # ffffffffc0203e20 <forkret>
ffffffffc02040b8:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02040ba:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040bc:	100027f3          	csrr	a5,sstatus
ffffffffc02040c0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040c2:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040c4:	14079063          	bnez	a5,ffffffffc0204204 <do_fork+0x276>
    if (++last_pid >= MAX_PID)
ffffffffc02040c8:	000a2817          	auipc	a6,0xa2
ffffffffc02040cc:	17080813          	addi	a6,a6,368 # ffffffffc02a6238 <last_pid.1>
ffffffffc02040d0:	00082783          	lw	a5,0(a6)
ffffffffc02040d4:	6709                	lui	a4,0x2
ffffffffc02040d6:	0017851b          	addiw	a0,a5,1
ffffffffc02040da:	00a82023          	sw	a0,0(a6)
ffffffffc02040de:	08e55d63          	bge	a0,a4,ffffffffc0204178 <do_fork+0x1ea>
    if (last_pid >= next_safe)
ffffffffc02040e2:	000a2317          	auipc	t1,0xa2
ffffffffc02040e6:	15a30313          	addi	t1,t1,346 # ffffffffc02a623c <next_safe.0>
ffffffffc02040ea:	00032783          	lw	a5,0(t1)
ffffffffc02040ee:	000a6417          	auipc	s0,0xa6
ffffffffc02040f2:	56a40413          	addi	s0,s0,1386 # ffffffffc02aa658 <proc_list>
ffffffffc02040f6:	08f55963          	bge	a0,a5,ffffffffc0204188 <do_fork+0x1fa>
        proc->pid = get_pid();   // 给孩子分配一个唯一的 PID
ffffffffc02040fa:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02040fc:	45a9                	li	a1,10
ffffffffc02040fe:	2501                	sext.w	a0,a0
ffffffffc0204100:	108010ef          	jal	ra,ffffffffc0205208 <hash32>
ffffffffc0204104:	02051793          	slli	a5,a0,0x20
ffffffffc0204108:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020410c:	000a2797          	auipc	a5,0xa2
ffffffffc0204110:	54c78793          	addi	a5,a5,1356 # ffffffffc02a6658 <hash_list>
ffffffffc0204114:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204116:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204118:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020411a:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020411e:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204120:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204122:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204124:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204126:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc020412a:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020412c:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020412e:	e21c                	sd	a5,0(a2)
ffffffffc0204130:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204132:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204134:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204136:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020413a:	10e4b023          	sd	a4,256(s1)
ffffffffc020413e:	c311                	beqz	a4,ffffffffc0204142 <do_fork+0x1b4>
        proc->optr->yptr = proc;
ffffffffc0204140:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204142:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204146:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204148:	2785                	addiw	a5,a5,1
ffffffffc020414a:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc020414e:	18099363          	bnez	s3,ffffffffc02042d4 <do_fork+0x346>
    wakeup_proc(proc);
ffffffffc0204152:	8526                	mv	a0,s1
ffffffffc0204154:	6c9000ef          	jal	ra,ffffffffc020501c <wakeup_proc>
    ret = proc->pid;
ffffffffc0204158:	40c8                	lw	a0,4(s1)
}
ffffffffc020415a:	70e6                	ld	ra,120(sp)
ffffffffc020415c:	7446                	ld	s0,112(sp)
ffffffffc020415e:	74a6                	ld	s1,104(sp)
ffffffffc0204160:	7906                	ld	s2,96(sp)
ffffffffc0204162:	69e6                	ld	s3,88(sp)
ffffffffc0204164:	6a46                	ld	s4,80(sp)
ffffffffc0204166:	6aa6                	ld	s5,72(sp)
ffffffffc0204168:	6b06                	ld	s6,64(sp)
ffffffffc020416a:	7be2                	ld	s7,56(sp)
ffffffffc020416c:	7c42                	ld	s8,48(sp)
ffffffffc020416e:	7ca2                	ld	s9,40(sp)
ffffffffc0204170:	7d02                	ld	s10,32(sp)
ffffffffc0204172:	6de2                	ld	s11,24(sp)
ffffffffc0204174:	6109                	addi	sp,sp,128
ffffffffc0204176:	8082                	ret
        last_pid = 1;
ffffffffc0204178:	4785                	li	a5,1
ffffffffc020417a:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020417e:	4505                	li	a0,1
ffffffffc0204180:	000a2317          	auipc	t1,0xa2
ffffffffc0204184:	0bc30313          	addi	t1,t1,188 # ffffffffc02a623c <next_safe.0>
    return listelm->next;
ffffffffc0204188:	000a6417          	auipc	s0,0xa6
ffffffffc020418c:	4d040413          	addi	s0,s0,1232 # ffffffffc02aa658 <proc_list>
ffffffffc0204190:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204194:	6789                	lui	a5,0x2
ffffffffc0204196:	00f32023          	sw	a5,0(t1)
ffffffffc020419a:	86aa                	mv	a3,a0
ffffffffc020419c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020419e:	6e89                	lui	t4,0x2
ffffffffc02041a0:	148e0263          	beq	t3,s0,ffffffffc02042e4 <do_fork+0x356>
ffffffffc02041a4:	88ae                	mv	a7,a1
ffffffffc02041a6:	87f2                	mv	a5,t3
ffffffffc02041a8:	6609                	lui	a2,0x2
ffffffffc02041aa:	a811                	j	ffffffffc02041be <do_fork+0x230>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041ac:	00e6d663          	bge	a3,a4,ffffffffc02041b8 <do_fork+0x22a>
ffffffffc02041b0:	00c75463          	bge	a4,a2,ffffffffc02041b8 <do_fork+0x22a>
ffffffffc02041b4:	863a                	mv	a2,a4
ffffffffc02041b6:	4885                	li	a7,1
ffffffffc02041b8:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02041ba:	00878d63          	beq	a5,s0,ffffffffc02041d4 <do_fork+0x246>
            if (proc->pid == last_pid)
ffffffffc02041be:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c64>
ffffffffc02041c2:	fed715e3          	bne	a4,a3,ffffffffc02041ac <do_fork+0x21e>
                if (++last_pid >= next_safe)
ffffffffc02041c6:	2685                	addiw	a3,a3,1
ffffffffc02041c8:	10c6d963          	bge	a3,a2,ffffffffc02042da <do_fork+0x34c>
ffffffffc02041cc:	679c                	ld	a5,8(a5)
ffffffffc02041ce:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041d0:	fe8797e3          	bne	a5,s0,ffffffffc02041be <do_fork+0x230>
ffffffffc02041d4:	c581                	beqz	a1,ffffffffc02041dc <do_fork+0x24e>
ffffffffc02041d6:	00d82023          	sw	a3,0(a6)
ffffffffc02041da:	8536                	mv	a0,a3
ffffffffc02041dc:	f0088fe3          	beqz	a7,ffffffffc02040fa <do_fork+0x16c>
ffffffffc02041e0:	00c32023          	sw	a2,0(t1)
ffffffffc02041e4:	bf19                	j	ffffffffc02040fa <do_fork+0x16c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02041e6:	89b6                	mv	s3,a3
ffffffffc02041e8:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02041ec:	00000797          	auipc	a5,0x0
ffffffffc02041f0:	c3478793          	addi	a5,a5,-972 # ffffffffc0203e20 <forkret>
ffffffffc02041f4:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02041f6:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041f8:	100027f3          	csrr	a5,sstatus
ffffffffc02041fc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02041fe:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204200:	ec0784e3          	beqz	a5,ffffffffc02040c8 <do_fork+0x13a>
        intr_disable();
ffffffffc0204204:	fb0fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204208:	4985                	li	s3,1
ffffffffc020420a:	bd7d                	j	ffffffffc02040c8 <do_fork+0x13a>
    if ((mm = mm_create()) == NULL)
ffffffffc020420c:	c90ff0ef          	jal	ra,ffffffffc020369c <mm_create>
ffffffffc0204210:	8caa                	mv	s9,a0
ffffffffc0204212:	c541                	beqz	a0,ffffffffc020429a <do_fork+0x30c>
    if ((page = alloc_page()) == NULL)
ffffffffc0204214:	4505                	li	a0,1
ffffffffc0204216:	c63fd0ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc020421a:	cd2d                	beqz	a0,ffffffffc0204294 <do_fork+0x306>
    return page - pages + nbase;
ffffffffc020421c:	000ab683          	ld	a3,0(s5)
ffffffffc0204220:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204222:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204226:	40d506b3          	sub	a3,a0,a3
ffffffffc020422a:	8699                	srai	a3,a3,0x6
ffffffffc020422c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020422e:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204232:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204234:	0eedf263          	bgeu	s11,a4,ffffffffc0204318 <do_fork+0x38a>
ffffffffc0204238:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020423c:	6605                	lui	a2,0x1
ffffffffc020423e:	000a6597          	auipc	a1,0xa6
ffffffffc0204242:	4625b583          	ld	a1,1122(a1) # ffffffffc02aa6a0 <boot_pgdir_va>
ffffffffc0204246:	9a36                	add	s4,s4,a3
ffffffffc0204248:	8552                	mv	a0,s4
ffffffffc020424a:	476010ef          	jal	ra,ffffffffc02056c0 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020424e:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204252:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204256:	4785                	li	a5,1
ffffffffc0204258:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020425c:	8b85                	andi	a5,a5,1
ffffffffc020425e:	4a05                	li	s4,1
ffffffffc0204260:	c799                	beqz	a5,ffffffffc020426e <do_fork+0x2e0>
    {
        schedule();
ffffffffc0204262:	63b000ef          	jal	ra,ffffffffc020509c <schedule>
ffffffffc0204266:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020426a:	8b85                	andi	a5,a5,1
ffffffffc020426c:	fbfd                	bnez	a5,ffffffffc0204262 <do_fork+0x2d4>
        ret = dup_mmap(mm, oldmm);
ffffffffc020426e:	85ea                	mv	a1,s10
ffffffffc0204270:	8566                	mv	a0,s9
ffffffffc0204272:	e6cff0ef          	jal	ra,ffffffffc02038de <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204276:	57f9                	li	a5,-2
ffffffffc0204278:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020427c:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020427e:	0e078e63          	beqz	a5,ffffffffc020437a <do_fork+0x3ec>
good_mm:
ffffffffc0204282:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204284:	dc0505e3          	beqz	a0,ffffffffc020404e <do_fork+0xc0>
    exit_mmap(mm);
ffffffffc0204288:	8566                	mv	a0,s9
ffffffffc020428a:	eeeff0ef          	jal	ra,ffffffffc0203978 <exit_mmap>
    put_pgdir(mm);
ffffffffc020428e:	8566                	mv	a0,s9
ffffffffc0204290:	c1dff0ef          	jal	ra,ffffffffc0203eac <put_pgdir>
    mm_destroy(mm);
ffffffffc0204294:	8566                	mv	a0,s9
ffffffffc0204296:	d46ff0ef          	jal	ra,ffffffffc02037dc <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020429a:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020429c:	c02007b7          	lui	a5,0xc0200
ffffffffc02042a0:	0cf6e163          	bltu	a3,a5,ffffffffc0204362 <do_fork+0x3d4>
ffffffffc02042a4:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02042a8:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02042ac:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02042b0:	83b1                	srli	a5,a5,0xc
ffffffffc02042b2:	06e7ff63          	bgeu	a5,a4,ffffffffc0204330 <do_fork+0x3a2>
    return &pages[PPN(pa) - nbase];
ffffffffc02042b6:	000b3703          	ld	a4,0(s6)
ffffffffc02042ba:	000ab503          	ld	a0,0(s5)
ffffffffc02042be:	4589                	li	a1,2
ffffffffc02042c0:	8f99                	sub	a5,a5,a4
ffffffffc02042c2:	079a                	slli	a5,a5,0x6
ffffffffc02042c4:	953e                	add	a0,a0,a5
ffffffffc02042c6:	bf1fd0ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    kfree(proc);
ffffffffc02042ca:	8526                	mv	a0,s1
ffffffffc02042cc:	a7ffd0ef          	jal	ra,ffffffffc0201d4a <kfree>
    ret = -E_NO_MEM;
ffffffffc02042d0:	5571                	li	a0,-4
    return ret;
ffffffffc02042d2:	b561                	j	ffffffffc020415a <do_fork+0x1cc>
        intr_enable();
ffffffffc02042d4:	edafc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02042d8:	bdad                	j	ffffffffc0204152 <do_fork+0x1c4>
                    if (last_pid >= MAX_PID)
ffffffffc02042da:	01d6c363          	blt	a3,t4,ffffffffc02042e0 <do_fork+0x352>
                        last_pid = 1;
ffffffffc02042de:	4685                	li	a3,1
                    goto repeat;
ffffffffc02042e0:	4585                	li	a1,1
ffffffffc02042e2:	bd7d                	j	ffffffffc02041a0 <do_fork+0x212>
ffffffffc02042e4:	c599                	beqz	a1,ffffffffc02042f2 <do_fork+0x364>
ffffffffc02042e6:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02042ea:	8536                	mv	a0,a3
ffffffffc02042ec:	b539                	j	ffffffffc02040fa <do_fork+0x16c>
    int ret = -E_NO_FREE_PROC;
ffffffffc02042ee:	556d                	li	a0,-5
ffffffffc02042f0:	b5ad                	j	ffffffffc020415a <do_fork+0x1cc>
    return last_pid;
ffffffffc02042f2:	00082503          	lw	a0,0(a6)
ffffffffc02042f6:	b511                	j	ffffffffc02040fa <do_fork+0x16c>
    assert(current->wait_state == 0);
ffffffffc02042f8:	00003697          	auipc	a3,0x3
ffffffffc02042fc:	c9868693          	addi	a3,a3,-872 # ffffffffc0206f90 <default_pmm_manager+0xa88>
ffffffffc0204300:	00002617          	auipc	a2,0x2
ffffffffc0204304:	e5860613          	addi	a2,a2,-424 # ffffffffc0206158 <commands+0x818>
ffffffffc0204308:	1eb00593          	li	a1,491
ffffffffc020430c:	00003517          	auipc	a0,0x3
ffffffffc0204310:	c6c50513          	addi	a0,a0,-916 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204314:	97afc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204318:	00002617          	auipc	a2,0x2
ffffffffc020431c:	22860613          	addi	a2,a2,552 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0204320:	07100593          	li	a1,113
ffffffffc0204324:	00002517          	auipc	a0,0x2
ffffffffc0204328:	24450513          	addi	a0,a0,580 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc020432c:	962fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204330:	00002617          	auipc	a2,0x2
ffffffffc0204334:	2e060613          	addi	a2,a2,736 # ffffffffc0206610 <default_pmm_manager+0x108>
ffffffffc0204338:	06900593          	li	a1,105
ffffffffc020433c:	00002517          	auipc	a0,0x2
ffffffffc0204340:	22c50513          	addi	a0,a0,556 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0204344:	94afc0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204348:	86be                	mv	a3,a5
ffffffffc020434a:	00002617          	auipc	a2,0x2
ffffffffc020434e:	29e60613          	addi	a2,a2,670 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc0204352:	19500593          	li	a1,405
ffffffffc0204356:	00003517          	auipc	a0,0x3
ffffffffc020435a:	c2250513          	addi	a0,a0,-990 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc020435e:	930fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204362:	00002617          	auipc	a2,0x2
ffffffffc0204366:	28660613          	addi	a2,a2,646 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc020436a:	07700593          	li	a1,119
ffffffffc020436e:	00002517          	auipc	a0,0x2
ffffffffc0204372:	1fa50513          	addi	a0,a0,506 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0204376:	918fc0ef          	jal	ra,ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc020437a:	00003617          	auipc	a2,0x3
ffffffffc020437e:	c3660613          	addi	a2,a2,-970 # ffffffffc0206fb0 <default_pmm_manager+0xaa8>
ffffffffc0204382:	03f00593          	li	a1,63
ffffffffc0204386:	00003517          	auipc	a0,0x3
ffffffffc020438a:	c3a50513          	addi	a0,a0,-966 # ffffffffc0206fc0 <default_pmm_manager+0xab8>
ffffffffc020438e:	900fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204392 <kernel_thread>:
{
ffffffffc0204392:	7129                	addi	sp,sp,-320
ffffffffc0204394:	fa22                	sd	s0,304(sp)
ffffffffc0204396:	f626                	sd	s1,296(sp)
ffffffffc0204398:	f24a                	sd	s2,288(sp)
ffffffffc020439a:	84ae                	mv	s1,a1
ffffffffc020439c:	892a                	mv	s2,a0
ffffffffc020439e:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043a0:	4581                	li	a1,0
ffffffffc02043a2:	12000613          	li	a2,288
ffffffffc02043a6:	850a                	mv	a0,sp
{
ffffffffc02043a8:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043aa:	304010ef          	jal	ra,ffffffffc02056ae <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02043ae:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02043b0:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043b2:	100027f3          	csrr	a5,sstatus
ffffffffc02043b6:	edd7f793          	andi	a5,a5,-291
ffffffffc02043ba:	1207e793          	ori	a5,a5,288
ffffffffc02043be:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043c0:	860a                	mv	a2,sp
ffffffffc02043c2:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043c6:	00000797          	auipc	a5,0x0
ffffffffc02043ca:	9e078793          	addi	a5,a5,-1568 # ffffffffc0203da6 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043ce:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043d0:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043d2:	bbdff0ef          	jal	ra,ffffffffc0203f8e <do_fork>
}
ffffffffc02043d6:	70f2                	ld	ra,312(sp)
ffffffffc02043d8:	7452                	ld	s0,304(sp)
ffffffffc02043da:	74b2                	ld	s1,296(sp)
ffffffffc02043dc:	7912                	ld	s2,288(sp)
ffffffffc02043de:	6131                	addi	sp,sp,320
ffffffffc02043e0:	8082                	ret

ffffffffc02043e2 <do_exit>:
{
ffffffffc02043e2:	7179                	addi	sp,sp,-48
ffffffffc02043e4:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02043e6:	000a6417          	auipc	s0,0xa6
ffffffffc02043ea:	2e240413          	addi	s0,s0,738 # ffffffffc02aa6c8 <current>
ffffffffc02043ee:	601c                	ld	a5,0(s0)
{
ffffffffc02043f0:	f406                	sd	ra,40(sp)
ffffffffc02043f2:	ec26                	sd	s1,24(sp)
ffffffffc02043f4:	e84a                	sd	s2,16(sp)
ffffffffc02043f6:	e44e                	sd	s3,8(sp)
ffffffffc02043f8:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02043fa:	000a6717          	auipc	a4,0xa6
ffffffffc02043fe:	2d673703          	ld	a4,726(a4) # ffffffffc02aa6d0 <idleproc>
ffffffffc0204402:	0ce78c63          	beq	a5,a4,ffffffffc02044da <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204406:	000a6497          	auipc	s1,0xa6
ffffffffc020440a:	2d248493          	addi	s1,s1,722 # ffffffffc02aa6d8 <initproc>
ffffffffc020440e:	6098                	ld	a4,0(s1)
ffffffffc0204410:	0ee78b63          	beq	a5,a4,ffffffffc0204506 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204414:	0287b983          	ld	s3,40(a5)
ffffffffc0204418:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020441a:	02098663          	beqz	s3,ffffffffc0204446 <do_exit+0x64>
ffffffffc020441e:	000a6797          	auipc	a5,0xa6
ffffffffc0204422:	27a7b783          	ld	a5,634(a5) # ffffffffc02aa698 <boot_pgdir_pa>
ffffffffc0204426:	577d                	li	a4,-1
ffffffffc0204428:	177e                	slli	a4,a4,0x3f
ffffffffc020442a:	83b1                	srli	a5,a5,0xc
ffffffffc020442c:	8fd9                	or	a5,a5,a4
ffffffffc020442e:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204432:	0309a783          	lw	a5,48(s3)
ffffffffc0204436:	fff7871b          	addiw	a4,a5,-1
ffffffffc020443a:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020443e:	cb55                	beqz	a4,ffffffffc02044f2 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204440:	601c                	ld	a5,0(s0)
ffffffffc0204442:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204446:	601c                	ld	a5,0(s0)
ffffffffc0204448:	470d                	li	a4,3
ffffffffc020444a:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020444c:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204450:	100027f3          	csrr	a5,sstatus
ffffffffc0204454:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204456:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204458:	e3f9                	bnez	a5,ffffffffc020451e <do_exit+0x13c>
        proc = current->parent;
ffffffffc020445a:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020445c:	800007b7          	lui	a5,0x80000
ffffffffc0204460:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204462:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204464:	0ec52703          	lw	a4,236(a0)
ffffffffc0204468:	0af70f63          	beq	a4,a5,ffffffffc0204526 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc020446c:	6018                	ld	a4,0(s0)
ffffffffc020446e:	7b7c                	ld	a5,240(a4)
ffffffffc0204470:	c3a1                	beqz	a5,ffffffffc02044b0 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204472:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204476:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204478:	0985                	addi	s3,s3,1
ffffffffc020447a:	a021                	j	ffffffffc0204482 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc020447c:	6018                	ld	a4,0(s0)
ffffffffc020447e:	7b7c                	ld	a5,240(a4)
ffffffffc0204480:	cb85                	beqz	a5,ffffffffc02044b0 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204482:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204486:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204488:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020448a:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020448c:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204490:	10e7b023          	sd	a4,256(a5)
ffffffffc0204494:	c311                	beqz	a4,ffffffffc0204498 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204496:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204498:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020449a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020449c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020449e:	fd271fe3          	bne	a4,s2,ffffffffc020447c <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044a2:	0ec52783          	lw	a5,236(a0)
ffffffffc02044a6:	fd379be3          	bne	a5,s3,ffffffffc020447c <do_exit+0x9a>
                    wakeup_proc(initproc);//唤醒
ffffffffc02044aa:	373000ef          	jal	ra,ffffffffc020501c <wakeup_proc>
ffffffffc02044ae:	b7f9                	j	ffffffffc020447c <do_exit+0x9a>
    if (flag)
ffffffffc02044b0:	020a1263          	bnez	s4,ffffffffc02044d4 <do_exit+0xf2>
    schedule();
ffffffffc02044b4:	3e9000ef          	jal	ra,ffffffffc020509c <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02044b8:	601c                	ld	a5,0(s0)
ffffffffc02044ba:	00003617          	auipc	a2,0x3
ffffffffc02044be:	b3e60613          	addi	a2,a2,-1218 # ffffffffc0206ff8 <default_pmm_manager+0xaf0>
ffffffffc02044c2:	27200593          	li	a1,626
ffffffffc02044c6:	43d4                	lw	a3,4(a5)
ffffffffc02044c8:	00003517          	auipc	a0,0x3
ffffffffc02044cc:	ab050513          	addi	a0,a0,-1360 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc02044d0:	fbffb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02044d4:	cdafc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02044d8:	bff1                	j	ffffffffc02044b4 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02044da:	00003617          	auipc	a2,0x3
ffffffffc02044de:	afe60613          	addi	a2,a2,-1282 # ffffffffc0206fd8 <default_pmm_manager+0xad0>
ffffffffc02044e2:	22700593          	li	a1,551
ffffffffc02044e6:	00003517          	auipc	a0,0x3
ffffffffc02044ea:	a9250513          	addi	a0,a0,-1390 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc02044ee:	fa1fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc02044f2:	854e                	mv	a0,s3
ffffffffc02044f4:	c84ff0ef          	jal	ra,ffffffffc0203978 <exit_mmap>
            put_pgdir(mm);
ffffffffc02044f8:	854e                	mv	a0,s3
ffffffffc02044fa:	9b3ff0ef          	jal	ra,ffffffffc0203eac <put_pgdir>
            mm_destroy(mm);
ffffffffc02044fe:	854e                	mv	a0,s3
ffffffffc0204500:	adcff0ef          	jal	ra,ffffffffc02037dc <mm_destroy>
ffffffffc0204504:	bf35                	j	ffffffffc0204440 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204506:	00003617          	auipc	a2,0x3
ffffffffc020450a:	ae260613          	addi	a2,a2,-1310 # ffffffffc0206fe8 <default_pmm_manager+0xae0>
ffffffffc020450e:	22b00593          	li	a1,555
ffffffffc0204512:	00003517          	auipc	a0,0x3
ffffffffc0204516:	a6650513          	addi	a0,a0,-1434 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc020451a:	f75fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc020451e:	c96fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204522:	4a05                	li	s4,1
ffffffffc0204524:	bf1d                	j	ffffffffc020445a <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204526:	2f7000ef          	jal	ra,ffffffffc020501c <wakeup_proc>
ffffffffc020452a:	b789                	j	ffffffffc020446c <do_exit+0x8a>

ffffffffc020452c <do_wait.part.0>:
int do_wait(int pid, int *code_store)//父进程看子进程有没有僵尸 释放栈和PCB
ffffffffc020452c:	715d                	addi	sp,sp,-80
ffffffffc020452e:	f84a                	sd	s2,48(sp)
ffffffffc0204530:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204532:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204536:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)//父进程看子进程有没有僵尸 释放栈和PCB
ffffffffc0204538:	fc26                	sd	s1,56(sp)
ffffffffc020453a:	f052                	sd	s4,32(sp)
ffffffffc020453c:	ec56                	sd	s5,24(sp)
ffffffffc020453e:	e85a                	sd	s6,16(sp)
ffffffffc0204540:	e45e                	sd	s7,8(sp)
ffffffffc0204542:	e486                	sd	ra,72(sp)
ffffffffc0204544:	e0a2                	sd	s0,64(sp)
ffffffffc0204546:	84aa                	mv	s1,a0
ffffffffc0204548:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc020454a:	000a6b97          	auipc	s7,0xa6
ffffffffc020454e:	17eb8b93          	addi	s7,s7,382 # ffffffffc02aa6c8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204552:	00050b1b          	sext.w	s6,a0
ffffffffc0204556:	fff50a9b          	addiw	s5,a0,-1
ffffffffc020455a:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020455c:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020455e:	ccbd                	beqz	s1,ffffffffc02045dc <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204560:	0359e863          	bltu	s3,s5,ffffffffc0204590 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204564:	45a9                	li	a1,10
ffffffffc0204566:	855a                	mv	a0,s6
ffffffffc0204568:	4a1000ef          	jal	ra,ffffffffc0205208 <hash32>
ffffffffc020456c:	02051793          	slli	a5,a0,0x20
ffffffffc0204570:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204574:	000a2797          	auipc	a5,0xa2
ffffffffc0204578:	0e478793          	addi	a5,a5,228 # ffffffffc02a6658 <hash_list>
ffffffffc020457c:	953e                	add	a0,a0,a5
ffffffffc020457e:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204580:	a029                	j	ffffffffc020458a <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204582:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204586:	02978163          	beq	a5,s1,ffffffffc02045a8 <do_wait.part.0+0x7c>
ffffffffc020458a:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020458c:	fe851be3          	bne	a0,s0,ffffffffc0204582 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204590:	5579                	li	a0,-2
}
ffffffffc0204592:	60a6                	ld	ra,72(sp)
ffffffffc0204594:	6406                	ld	s0,64(sp)
ffffffffc0204596:	74e2                	ld	s1,56(sp)
ffffffffc0204598:	7942                	ld	s2,48(sp)
ffffffffc020459a:	79a2                	ld	s3,40(sp)
ffffffffc020459c:	7a02                	ld	s4,32(sp)
ffffffffc020459e:	6ae2                	ld	s5,24(sp)
ffffffffc02045a0:	6b42                	ld	s6,16(sp)
ffffffffc02045a2:	6ba2                	ld	s7,8(sp)
ffffffffc02045a4:	6161                	addi	sp,sp,80
ffffffffc02045a6:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02045a8:	000bb683          	ld	a3,0(s7)
ffffffffc02045ac:	f4843783          	ld	a5,-184(s0)
ffffffffc02045b0:	fed790e3          	bne	a5,a3,ffffffffc0204590 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045b4:	f2842703          	lw	a4,-216(s0)
ffffffffc02045b8:	478d                	li	a5,3
ffffffffc02045ba:	0ef70b63          	beq	a4,a5,ffffffffc02046b0 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;//父进程睡觉 调用schedule
ffffffffc02045be:	4785                	li	a5,1
ffffffffc02045c0:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02045c2:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02045c6:	2d7000ef          	jal	ra,ffffffffc020509c <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02045ca:	000bb783          	ld	a5,0(s7)
ffffffffc02045ce:	0b07a783          	lw	a5,176(a5)
ffffffffc02045d2:	8b85                	andi	a5,a5,1
ffffffffc02045d4:	d7c9                	beqz	a5,ffffffffc020455e <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02045d6:	555d                	li	a0,-9
ffffffffc02045d8:	e0bff0ef          	jal	ra,ffffffffc02043e2 <do_exit>
        proc = current->cptr;
ffffffffc02045dc:	000bb683          	ld	a3,0(s7)
ffffffffc02045e0:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02045e2:	d45d                	beqz	s0,ffffffffc0204590 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045e4:	470d                	li	a4,3
ffffffffc02045e6:	a021                	j	ffffffffc02045ee <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02045e8:	10043403          	ld	s0,256(s0)
ffffffffc02045ec:	d869                	beqz	s0,ffffffffc02045be <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045ee:	401c                	lw	a5,0(s0)
ffffffffc02045f0:	fee79ce3          	bne	a5,a4,ffffffffc02045e8 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02045f4:	000a6797          	auipc	a5,0xa6
ffffffffc02045f8:	0dc7b783          	ld	a5,220(a5) # ffffffffc02aa6d0 <idleproc>
ffffffffc02045fc:	0c878963          	beq	a5,s0,ffffffffc02046ce <do_wait.part.0+0x1a2>
ffffffffc0204600:	000a6797          	auipc	a5,0xa6
ffffffffc0204604:	0d87b783          	ld	a5,216(a5) # ffffffffc02aa6d8 <initproc>
ffffffffc0204608:	0cf40363          	beq	s0,a5,ffffffffc02046ce <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc020460c:	000a0663          	beqz	s4,ffffffffc0204618 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204610:	0e842783          	lw	a5,232(s0)
ffffffffc0204614:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204618:	100027f3          	csrr	a5,sstatus
ffffffffc020461c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020461e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204620:	e7c1                	bnez	a5,ffffffffc02046a8 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204622:	6c70                	ld	a2,216(s0)
ffffffffc0204624:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204626:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc020462a:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc020462c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020462e:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204630:	6470                	ld	a2,200(s0)
ffffffffc0204632:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204634:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204636:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204638:	c319                	beqz	a4,ffffffffc020463e <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc020463a:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc020463c:	7c7c                	ld	a5,248(s0)
ffffffffc020463e:	c3b5                	beqz	a5,ffffffffc02046a2 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204640:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204644:	000a6717          	auipc	a4,0xa6
ffffffffc0204648:	09c70713          	addi	a4,a4,156 # ffffffffc02aa6e0 <nr_process>
ffffffffc020464c:	431c                	lw	a5,0(a4)
ffffffffc020464e:	37fd                	addiw	a5,a5,-1
ffffffffc0204650:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204652:	e5a9                	bnez	a1,ffffffffc020469c <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204654:	6814                	ld	a3,16(s0)
ffffffffc0204656:	c02007b7          	lui	a5,0xc0200
ffffffffc020465a:	04f6ee63          	bltu	a3,a5,ffffffffc02046b6 <do_wait.part.0+0x18a>
ffffffffc020465e:	000a6797          	auipc	a5,0xa6
ffffffffc0204662:	0627b783          	ld	a5,98(a5) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0204666:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204668:	82b1                	srli	a3,a3,0xc
ffffffffc020466a:	000a6797          	auipc	a5,0xa6
ffffffffc020466e:	03e7b783          	ld	a5,62(a5) # ffffffffc02aa6a8 <npage>
ffffffffc0204672:	06f6fa63          	bgeu	a3,a5,ffffffffc02046e6 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204676:	00003517          	auipc	a0,0x3
ffffffffc020467a:	1ba53503          	ld	a0,442(a0) # ffffffffc0207830 <nbase>
ffffffffc020467e:	8e89                	sub	a3,a3,a0
ffffffffc0204680:	069a                	slli	a3,a3,0x6
ffffffffc0204682:	000a6517          	auipc	a0,0xa6
ffffffffc0204686:	02e53503          	ld	a0,46(a0) # ffffffffc02aa6b0 <pages>
ffffffffc020468a:	9536                	add	a0,a0,a3
ffffffffc020468c:	4589                	li	a1,2
ffffffffc020468e:	829fd0ef          	jal	ra,ffffffffc0201eb6 <free_pages>
    kfree(proc);
ffffffffc0204692:	8522                	mv	a0,s0
ffffffffc0204694:	eb6fd0ef          	jal	ra,ffffffffc0201d4a <kfree>
    return 0;
ffffffffc0204698:	4501                	li	a0,0
ffffffffc020469a:	bde5                	j	ffffffffc0204592 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020469c:	b12fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02046a0:	bf55                	j	ffffffffc0204654 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02046a2:	701c                	ld	a5,32(s0)
ffffffffc02046a4:	fbf8                	sd	a4,240(a5)
ffffffffc02046a6:	bf79                	j	ffffffffc0204644 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02046a8:	b0cfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046ac:	4585                	li	a1,1
ffffffffc02046ae:	bf95                	j	ffffffffc0204622 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02046b0:	f2840413          	addi	s0,s0,-216
ffffffffc02046b4:	b781                	j	ffffffffc02045f4 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02046b6:	00002617          	auipc	a2,0x2
ffffffffc02046ba:	f3260613          	addi	a2,a2,-206 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc02046be:	07700593          	li	a1,119
ffffffffc02046c2:	00002517          	auipc	a0,0x2
ffffffffc02046c6:	ea650513          	addi	a0,a0,-346 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc02046ca:	dc5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02046ce:	00003617          	auipc	a2,0x3
ffffffffc02046d2:	94a60613          	addi	a2,a2,-1718 # ffffffffc0207018 <default_pmm_manager+0xb10>
ffffffffc02046d6:	3f700593          	li	a1,1015
ffffffffc02046da:	00003517          	auipc	a0,0x3
ffffffffc02046de:	89e50513          	addi	a0,a0,-1890 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc02046e2:	dadfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02046e6:	00002617          	auipc	a2,0x2
ffffffffc02046ea:	f2a60613          	addi	a2,a2,-214 # ffffffffc0206610 <default_pmm_manager+0x108>
ffffffffc02046ee:	06900593          	li	a1,105
ffffffffc02046f2:	00002517          	auipc	a0,0x2
ffffffffc02046f6:	e7650513          	addi	a0,a0,-394 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc02046fa:	d95fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02046fe <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02046fe:	1141                	addi	sp,sp,-16
ffffffffc0204700:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();//剩下多少空闲页和分配多少内存
ffffffffc0204702:	ff4fd0ef          	jal	ra,ffffffffc0201ef6 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204706:	d90fd0ef          	jal	ra,ffffffffc0201c96 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);//创建内核线程执行user_main
ffffffffc020470a:	4601                	li	a2,0
ffffffffc020470c:	4581                	li	a1,0
ffffffffc020470e:	fffff517          	auipc	a0,0xfffff
ffffffffc0204712:	72050513          	addi	a0,a0,1824 # ffffffffc0203e2e <user_main>
ffffffffc0204716:	c7dff0ef          	jal	ra,ffffffffc0204392 <kernel_thread>
    if (pid <= 0)
ffffffffc020471a:	00a04563          	bgtz	a0,ffffffffc0204724 <init_main+0x26>
ffffffffc020471e:	a071                	j	ffffffffc02047aa <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)//等待所有子进程退出 等待user_main()退出
    {
        schedule();//收完一个子进程尸体 主动让出CPU一下
ffffffffc0204720:	17d000ef          	jal	ra,ffffffffc020509c <schedule>
    if (code_store != NULL)
ffffffffc0204724:	4581                	li	a1,0
ffffffffc0204726:	4501                	li	a0,0
ffffffffc0204728:	e05ff0ef          	jal	ra,ffffffffc020452c <do_wait.part.0>
    while (do_wait(0, NULL) == 0)//等待所有子进程退出 等待user_main()退出
ffffffffc020472c:	d975                	beqz	a0,ffffffffc0204720 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020472e:	00003517          	auipc	a0,0x3
ffffffffc0204732:	92a50513          	addi	a0,a0,-1750 # ffffffffc0207058 <default_pmm_manager+0xb50>
ffffffffc0204736:	a5ffb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020473a:	000a6797          	auipc	a5,0xa6
ffffffffc020473e:	f9e7b783          	ld	a5,-98(a5) # ffffffffc02aa6d8 <initproc>
ffffffffc0204742:	7bf8                	ld	a4,240(a5)
ffffffffc0204744:	e339                	bnez	a4,ffffffffc020478a <init_main+0x8c>
ffffffffc0204746:	7ff8                	ld	a4,248(a5)
ffffffffc0204748:	e329                	bnez	a4,ffffffffc020478a <init_main+0x8c>
ffffffffc020474a:	1007b703          	ld	a4,256(a5)
ffffffffc020474e:	ef15                	bnez	a4,ffffffffc020478a <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204750:	000a6697          	auipc	a3,0xa6
ffffffffc0204754:	f906a683          	lw	a3,-112(a3) # ffffffffc02aa6e0 <nr_process>
ffffffffc0204758:	4709                	li	a4,2
ffffffffc020475a:	0ae69463          	bne	a3,a4,ffffffffc0204802 <init_main+0x104>
    return listelm->next;
ffffffffc020475e:	000a6697          	auipc	a3,0xa6
ffffffffc0204762:	efa68693          	addi	a3,a3,-262 # ffffffffc02aa658 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204766:	6698                	ld	a4,8(a3)
ffffffffc0204768:	0c878793          	addi	a5,a5,200
ffffffffc020476c:	06f71b63          	bne	a4,a5,ffffffffc02047e2 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204770:	629c                	ld	a5,0(a3)
ffffffffc0204772:	04f71863          	bne	a4,a5,ffffffffc02047c2 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204776:	00003517          	auipc	a0,0x3
ffffffffc020477a:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0207140 <default_pmm_manager+0xc38>
ffffffffc020477e:	a17fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204782:	60a2                	ld	ra,8(sp)
ffffffffc0204784:	4501                	li	a0,0
ffffffffc0204786:	0141                	addi	sp,sp,16
ffffffffc0204788:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020478a:	00003697          	auipc	a3,0x3
ffffffffc020478e:	8f668693          	addi	a3,a3,-1802 # ffffffffc0207080 <default_pmm_manager+0xb78>
ffffffffc0204792:	00002617          	auipc	a2,0x2
ffffffffc0204796:	9c660613          	addi	a2,a2,-1594 # ffffffffc0206158 <commands+0x818>
ffffffffc020479a:	46600593          	li	a1,1126
ffffffffc020479e:	00002517          	auipc	a0,0x2
ffffffffc02047a2:	7da50513          	addi	a0,a0,2010 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc02047a6:	ce9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc02047aa:	00003617          	auipc	a2,0x3
ffffffffc02047ae:	88e60613          	addi	a2,a2,-1906 # ffffffffc0207038 <default_pmm_manager+0xb30>
ffffffffc02047b2:	45d00593          	li	a1,1117
ffffffffc02047b6:	00002517          	auipc	a0,0x2
ffffffffc02047ba:	7c250513          	addi	a0,a0,1986 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc02047be:	cd1fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047c2:	00003697          	auipc	a3,0x3
ffffffffc02047c6:	94e68693          	addi	a3,a3,-1714 # ffffffffc0207110 <default_pmm_manager+0xc08>
ffffffffc02047ca:	00002617          	auipc	a2,0x2
ffffffffc02047ce:	98e60613          	addi	a2,a2,-1650 # ffffffffc0206158 <commands+0x818>
ffffffffc02047d2:	46900593          	li	a1,1129
ffffffffc02047d6:	00002517          	auipc	a0,0x2
ffffffffc02047da:	7a250513          	addi	a0,a0,1954 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc02047de:	cb1fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02047e2:	00003697          	auipc	a3,0x3
ffffffffc02047e6:	8fe68693          	addi	a3,a3,-1794 # ffffffffc02070e0 <default_pmm_manager+0xbd8>
ffffffffc02047ea:	00002617          	auipc	a2,0x2
ffffffffc02047ee:	96e60613          	addi	a2,a2,-1682 # ffffffffc0206158 <commands+0x818>
ffffffffc02047f2:	46800593          	li	a1,1128
ffffffffc02047f6:	00002517          	auipc	a0,0x2
ffffffffc02047fa:	78250513          	addi	a0,a0,1922 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc02047fe:	c91fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204802:	00003697          	auipc	a3,0x3
ffffffffc0204806:	8ce68693          	addi	a3,a3,-1842 # ffffffffc02070d0 <default_pmm_manager+0xbc8>
ffffffffc020480a:	00002617          	auipc	a2,0x2
ffffffffc020480e:	94e60613          	addi	a2,a2,-1714 # ffffffffc0206158 <commands+0x818>
ffffffffc0204812:	46700593          	li	a1,1127
ffffffffc0204816:	00002517          	auipc	a0,0x2
ffffffffc020481a:	76250513          	addi	a0,a0,1890 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc020481e:	c71fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204822 <do_execve>:
{
ffffffffc0204822:	7171                	addi	sp,sp,-176
ffffffffc0204824:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204826:	000a6d97          	auipc	s11,0xa6
ffffffffc020482a:	ea2d8d93          	addi	s11,s11,-350 # ffffffffc02aa6c8 <current>
ffffffffc020482e:	000db783          	ld	a5,0(s11)
{
ffffffffc0204832:	e54e                	sd	s3,136(sp)
ffffffffc0204834:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204836:	0287b983          	ld	s3,40(a5)
{
ffffffffc020483a:	e94a                	sd	s2,144(sp)
ffffffffc020483c:	f4de                	sd	s7,104(sp)
ffffffffc020483e:	892a                	mv	s2,a0
ffffffffc0204840:	8bb2                	mv	s7,a2
ffffffffc0204842:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204844:	862e                	mv	a2,a1
ffffffffc0204846:	4681                	li	a3,0
ffffffffc0204848:	85aa                	mv	a1,a0
ffffffffc020484a:	854e                	mv	a0,s3
{
ffffffffc020484c:	f506                	sd	ra,168(sp)
ffffffffc020484e:	f122                	sd	s0,160(sp)
ffffffffc0204850:	e152                	sd	s4,128(sp)
ffffffffc0204852:	fcd6                	sd	s5,120(sp)
ffffffffc0204854:	f8da                	sd	s6,112(sp)
ffffffffc0204856:	f0e2                	sd	s8,96(sp)
ffffffffc0204858:	ece6                	sd	s9,88(sp)
ffffffffc020485a:	e8ea                	sd	s10,80(sp)
ffffffffc020485c:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020485e:	cb4ff0ef          	jal	ra,ffffffffc0203d12 <user_mem_check>
ffffffffc0204862:	40050a63          	beqz	a0,ffffffffc0204c76 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204866:	4641                	li	a2,16
ffffffffc0204868:	4581                	li	a1,0
ffffffffc020486a:	1808                	addi	a0,sp,48
ffffffffc020486c:	643000ef          	jal	ra,ffffffffc02056ae <memset>
    memcpy(local_name, name, len);// 从用户空间把字符串复制到内核空间
ffffffffc0204870:	47bd                	li	a5,15
ffffffffc0204872:	8626                	mv	a2,s1
ffffffffc0204874:	1e97e263          	bltu	a5,s1,ffffffffc0204a58 <do_execve+0x236>
ffffffffc0204878:	85ca                	mv	a1,s2
ffffffffc020487a:	1808                	addi	a0,sp,48
ffffffffc020487c:	645000ef          	jal	ra,ffffffffc02056c0 <memcpy>
    if (mm != NULL)
ffffffffc0204880:	1e098363          	beqz	s3,ffffffffc0204a66 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204884:	00002517          	auipc	a0,0x2
ffffffffc0204888:	4b450513          	addi	a0,a0,1204 # ffffffffc0206d38 <default_pmm_manager+0x830>
ffffffffc020488c:	941fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204890:	000a6797          	auipc	a5,0xa6
ffffffffc0204894:	e087b783          	ld	a5,-504(a5) # ffffffffc02aa698 <boot_pgdir_pa>
ffffffffc0204898:	577d                	li	a4,-1
ffffffffc020489a:	177e                	slli	a4,a4,0x3f
ffffffffc020489c:	83b1                	srli	a5,a5,0xc
ffffffffc020489e:	8fd9                	or	a5,a5,a4
ffffffffc02048a0:	18079073          	csrw	satp,a5
ffffffffc02048a4:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b70>
ffffffffc02048a8:	fff7871b          	addiw	a4,a5,-1
ffffffffc02048ac:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02048b0:	2c070463          	beqz	a4,ffffffffc0204b78 <do_execve+0x356>
        current->mm = NULL;
ffffffffc02048b4:	000db783          	ld	a5,0(s11)
ffffffffc02048b8:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02048bc:	de1fe0ef          	jal	ra,ffffffffc020369c <mm_create>
ffffffffc02048c0:	84aa                	mv	s1,a0
ffffffffc02048c2:	1c050d63          	beqz	a0,ffffffffc0204a9c <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc02048c6:	4505                	li	a0,1
ffffffffc02048c8:	db0fd0ef          	jal	ra,ffffffffc0201e78 <alloc_pages>
ffffffffc02048cc:	3a050963          	beqz	a0,ffffffffc0204c7e <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc02048d0:	000a6c97          	auipc	s9,0xa6
ffffffffc02048d4:	de0c8c93          	addi	s9,s9,-544 # ffffffffc02aa6b0 <pages>
ffffffffc02048d8:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02048dc:	000a6c17          	auipc	s8,0xa6
ffffffffc02048e0:	dccc0c13          	addi	s8,s8,-564 # ffffffffc02aa6a8 <npage>
    return page - pages + nbase;
ffffffffc02048e4:	00003717          	auipc	a4,0x3
ffffffffc02048e8:	f4c73703          	ld	a4,-180(a4) # ffffffffc0207830 <nbase>
ffffffffc02048ec:	40d506b3          	sub	a3,a0,a3
ffffffffc02048f0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02048f2:	5afd                	li	s5,-1
ffffffffc02048f4:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02048f8:	96ba                	add	a3,a3,a4
ffffffffc02048fa:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02048fc:	00cad713          	srli	a4,s5,0xc
ffffffffc0204900:	ec3a                	sd	a4,24(sp)
ffffffffc0204902:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204904:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204906:	38f77063          	bgeu	a4,a5,ffffffffc0204c86 <do_execve+0x464>
ffffffffc020490a:	000a6b17          	auipc	s6,0xa6
ffffffffc020490e:	db6b0b13          	addi	s6,s6,-586 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0204912:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204916:	6605                	lui	a2,0x1
ffffffffc0204918:	000a6597          	auipc	a1,0xa6
ffffffffc020491c:	d885b583          	ld	a1,-632(a1) # ffffffffc02aa6a0 <boot_pgdir_va>
ffffffffc0204920:	9936                	add	s2,s2,a3
ffffffffc0204922:	854a                	mv	a0,s2
ffffffffc0204924:	59d000ef          	jal	ra,ffffffffc02056c0 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204928:	7782                	ld	a5,32(sp)
ffffffffc020492a:	4398                	lw	a4,0(a5)
ffffffffc020492c:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204930:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204934:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9467>
ffffffffc0204938:	14f71863          	bne	a4,a5,ffffffffc0204a88 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020493c:	7682                	ld	a3,32(sp)
ffffffffc020493e:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204942:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204946:	00371793          	slli	a5,a4,0x3
ffffffffc020494a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020494c:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020494e:	078e                	slli	a5,a5,0x3
ffffffffc0204950:	97ce                	add	a5,a5,s3
ffffffffc0204952:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)// 遍历每一个段
ffffffffc0204954:	00f9fc63          	bgeu	s3,a5,ffffffffc020496c <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204958:	0009a783          	lw	a5,0(s3)
ffffffffc020495c:	4705                	li	a4,1
ffffffffc020495e:	14e78163          	beq	a5,a4,ffffffffc0204aa0 <do_execve+0x27e>
    for (; ph < ph_end; ph++)// 遍历每一个段
ffffffffc0204962:	77a2                	ld	a5,40(sp)
ffffffffc0204964:	03898993          	addi	s3,s3,56
ffffffffc0204968:	fef9e8e3          	bltu	s3,a5,ffffffffc0204958 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc020496c:	4701                	li	a4,0
ffffffffc020496e:	46ad                	li	a3,11
ffffffffc0204970:	00100637          	lui	a2,0x100
ffffffffc0204974:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204978:	8526                	mv	a0,s1
ffffffffc020497a:	eb5fe0ef          	jal	ra,ffffffffc020382e <mm_map>
ffffffffc020497e:	892a                	mv	s2,a0
ffffffffc0204980:	1e051263          	bnez	a0,ffffffffc0204b64 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204984:	6c88                	ld	a0,24(s1)
ffffffffc0204986:	467d                	li	a2,31
ffffffffc0204988:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc020498c:	c2bfe0ef          	jal	ra,ffffffffc02035b6 <pgdir_alloc_page>
ffffffffc0204990:	38050363          	beqz	a0,ffffffffc0204d16 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204994:	6c88                	ld	a0,24(s1)
ffffffffc0204996:	467d                	li	a2,31
ffffffffc0204998:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc020499c:	c1bfe0ef          	jal	ra,ffffffffc02035b6 <pgdir_alloc_page>
ffffffffc02049a0:	34050b63          	beqz	a0,ffffffffc0204cf6 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049a4:	6c88                	ld	a0,24(s1)
ffffffffc02049a6:	467d                	li	a2,31
ffffffffc02049a8:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02049ac:	c0bfe0ef          	jal	ra,ffffffffc02035b6 <pgdir_alloc_page>
ffffffffc02049b0:	32050363          	beqz	a0,ffffffffc0204cd6 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049b4:	6c88                	ld	a0,24(s1)
ffffffffc02049b6:	467d                	li	a2,31
ffffffffc02049b8:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02049bc:	bfbfe0ef          	jal	ra,ffffffffc02035b6 <pgdir_alloc_page>
ffffffffc02049c0:	2e050b63          	beqz	a0,ffffffffc0204cb6 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc02049c4:	589c                	lw	a5,48(s1)
    current->mm = mm;// 把 mm 挂到当前进程上
ffffffffc02049c6:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02049ca:	6c94                	ld	a3,24(s1)
ffffffffc02049cc:	2785                	addiw	a5,a5,1
ffffffffc02049ce:	d89c                	sw	a5,48(s1)
    current->mm = mm;// 把 mm 挂到当前进程上
ffffffffc02049d0:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02049d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02049d6:	2cf6e463          	bltu	a3,a5,ffffffffc0204c9e <do_execve+0x47c>
ffffffffc02049da:	000b3783          	ld	a5,0(s6)
ffffffffc02049de:	577d                	li	a4,-1
ffffffffc02049e0:	177e                	slli	a4,a4,0x3f
ffffffffc02049e2:	8e9d                	sub	a3,a3,a5
ffffffffc02049e4:	00c6d793          	srli	a5,a3,0xc
ffffffffc02049e8:	f654                	sd	a3,168(a2)
ffffffffc02049ea:	8fd9                	or	a5,a5,a4
ffffffffc02049ec:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02049f0:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));//清空旧的tf
ffffffffc02049f2:	4581                	li	a1,0
ffffffffc02049f4:	12000613          	li	a2,288
ffffffffc02049f8:	8526                	mv	a0,s1
ffffffffc02049fa:	4b5000ef          	jal	ra,ffffffffc02056ae <memset>
    tf->epc = elf->e_entry;
ffffffffc02049fe:	7782                	ld	a5,32(sp)
ffffffffc0204a00:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a02:	4785                	li	a5,1
ffffffffc0204a04:	07fe                	slli	a5,a5,0x1f
ffffffffc0204a06:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;
ffffffffc0204a08:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204a0c:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a10:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204a14:	edf7f793          	andi	a5,a5,-289
ffffffffc0204a18:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a1c:	0b440413          	addi	s0,s0,180
ffffffffc0204a20:	4641                	li	a2,16
ffffffffc0204a22:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204a24:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a28:	8522                	mv	a0,s0
ffffffffc0204a2a:	485000ef          	jal	ra,ffffffffc02056ae <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204a2e:	463d                	li	a2,15
ffffffffc0204a30:	180c                	addi	a1,sp,48
ffffffffc0204a32:	8522                	mv	a0,s0
ffffffffc0204a34:	48d000ef          	jal	ra,ffffffffc02056c0 <memcpy>
}
ffffffffc0204a38:	70aa                	ld	ra,168(sp)
ffffffffc0204a3a:	740a                	ld	s0,160(sp)
ffffffffc0204a3c:	64ea                	ld	s1,152(sp)
ffffffffc0204a3e:	69aa                	ld	s3,136(sp)
ffffffffc0204a40:	6a0a                	ld	s4,128(sp)
ffffffffc0204a42:	7ae6                	ld	s5,120(sp)
ffffffffc0204a44:	7b46                	ld	s6,112(sp)
ffffffffc0204a46:	7ba6                	ld	s7,104(sp)
ffffffffc0204a48:	7c06                	ld	s8,96(sp)
ffffffffc0204a4a:	6ce6                	ld	s9,88(sp)
ffffffffc0204a4c:	6d46                	ld	s10,80(sp)
ffffffffc0204a4e:	6da6                	ld	s11,72(sp)
ffffffffc0204a50:	854a                	mv	a0,s2
ffffffffc0204a52:	694a                	ld	s2,144(sp)
ffffffffc0204a54:	614d                	addi	sp,sp,176
ffffffffc0204a56:	8082                	ret
    memcpy(local_name, name, len);// 从用户空间把字符串复制到内核空间
ffffffffc0204a58:	463d                	li	a2,15
ffffffffc0204a5a:	85ca                	mv	a1,s2
ffffffffc0204a5c:	1808                	addi	a0,sp,48
ffffffffc0204a5e:	463000ef          	jal	ra,ffffffffc02056c0 <memcpy>
    if (mm != NULL)
ffffffffc0204a62:	e20991e3          	bnez	s3,ffffffffc0204884 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204a66:	000db783          	ld	a5,0(s11)
ffffffffc0204a6a:	779c                	ld	a5,40(a5)
ffffffffc0204a6c:	e40788e3          	beqz	a5,ffffffffc02048bc <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a70:	00002617          	auipc	a2,0x2
ffffffffc0204a74:	6f060613          	addi	a2,a2,1776 # ffffffffc0207160 <default_pmm_manager+0xc58>
ffffffffc0204a78:	27e00593          	li	a1,638
ffffffffc0204a7c:	00002517          	auipc	a0,0x2
ffffffffc0204a80:	4fc50513          	addi	a0,a0,1276 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204a84:	a0bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204a88:	8526                	mv	a0,s1
ffffffffc0204a8a:	c22ff0ef          	jal	ra,ffffffffc0203eac <put_pgdir>
    mm_destroy(mm);
ffffffffc0204a8e:	8526                	mv	a0,s1
ffffffffc0204a90:	d4dfe0ef          	jal	ra,ffffffffc02037dc <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204a94:	5961                	li	s2,-8
    do_exit(ret);
ffffffffc0204a96:	854a                	mv	a0,s2
ffffffffc0204a98:	94bff0ef          	jal	ra,ffffffffc02043e2 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204a9c:	5971                	li	s2,-4
ffffffffc0204a9e:	bfe5                	j	ffffffffc0204a96 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204aa0:	0289b603          	ld	a2,40(s3)
ffffffffc0204aa4:	0209b783          	ld	a5,32(s3)
ffffffffc0204aa8:	1cf66d63          	bltu	a2,a5,ffffffffc0204c82 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204aac:	0049a783          	lw	a5,4(s3)
ffffffffc0204ab0:	0017f693          	andi	a3,a5,1
ffffffffc0204ab4:	c291                	beqz	a3,ffffffffc0204ab8 <do_execve+0x296>
            vm_flags |= VM_EXEC;// 可执行
ffffffffc0204ab6:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204ab8:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204abc:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204abe:	e779                	bnez	a4,ffffffffc0204b8c <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;// 默认：用户态可访问(PTE_U)，有效(PTE_V)
ffffffffc0204ac0:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ac2:	c781                	beqz	a5,ffffffffc0204aca <do_execve+0x2a8>
            vm_flags |= VM_READ;// 可读
ffffffffc0204ac4:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204ac8:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204aca:	0026f793          	andi	a5,a3,2
ffffffffc0204ace:	e3f1                	bnez	a5,ffffffffc0204b92 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204ad0:	0046f793          	andi	a5,a3,4
ffffffffc0204ad4:	c399                	beqz	a5,ffffffffc0204ada <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204ad6:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204ada:	0109b583          	ld	a1,16(s3)
ffffffffc0204ade:	4701                	li	a4,0
ffffffffc0204ae0:	8526                	mv	a0,s1
ffffffffc0204ae2:	d4dfe0ef          	jal	ra,ffffffffc020382e <mm_map>
ffffffffc0204ae6:	892a                	mv	s2,a0
ffffffffc0204ae8:	ed35                	bnez	a0,ffffffffc0204b64 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204aea:	0109bb83          	ld	s7,16(s3)
ffffffffc0204aee:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;// 计算拷贝的终点 (只拷贝文件里有的内容)
ffffffffc0204af0:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204af4:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204af8:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204afc:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;// 计算拷贝的终点 (只拷贝文件里有的内容)
ffffffffc0204afe:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b00:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204b02:	054be963          	bltu	s7,s4,ffffffffc0204b54 <do_execve+0x332>
ffffffffc0204b06:	aa95                	j	ffffffffc0204c7a <do_execve+0x458>
            off = start - la; 
ffffffffc0204b08:	6785                	lui	a5,0x1
ffffffffc0204b0a:	415b8533          	sub	a0,s7,s5
            size = PGSIZE - off; 
ffffffffc0204b0e:	9abe                	add	s5,s5,a5
ffffffffc0204b10:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0204b14:	015a7463          	bgeu	s4,s5,ffffffffc0204b1c <do_execve+0x2fa>
                size -= la - end; 
ffffffffc0204b18:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204b1c:	000cb683          	ld	a3,0(s9)
ffffffffc0204b20:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b22:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204b26:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b2a:	8699                	srai	a3,a3,0x6
ffffffffc0204b2c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b2e:	67e2                	ld	a5,24(sp)
ffffffffc0204b30:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b34:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b36:	14b87863          	bgeu	a6,a1,ffffffffc0204c86 <do_execve+0x464>
ffffffffc0204b3a:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b3e:	85ca                	mv	a1,s2
            start += size; // 虚拟地址推进
ffffffffc0204b40:	9bb2                	add	s7,s7,a2
ffffffffc0204b42:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b44:	9536                	add	a0,a0,a3
            start += size; // 虚拟地址推进
ffffffffc0204b46:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b48:	379000ef          	jal	ra,ffffffffc02056c0 <memcpy>
            from += size;  // 文件指针推进
ffffffffc0204b4c:	6622                	ld	a2,8(sp)
ffffffffc0204b4e:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204b50:	054bf363          	bgeu	s7,s4,ffffffffc0204b96 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0204b54:	6c88                	ld	a0,24(s1)
ffffffffc0204b56:	866a                	mv	a2,s10
ffffffffc0204b58:	85d6                	mv	a1,s5
ffffffffc0204b5a:	a5dfe0ef          	jal	ra,ffffffffc02035b6 <pgdir_alloc_page>
ffffffffc0204b5e:	842a                	mv	s0,a0
ffffffffc0204b60:	f545                	bnez	a0,ffffffffc0204b08 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204b62:	5971                	li	s2,-4
    exit_mmap(mm);
ffffffffc0204b64:	8526                	mv	a0,s1
ffffffffc0204b66:	e13fe0ef          	jal	ra,ffffffffc0203978 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204b6a:	8526                	mv	a0,s1
ffffffffc0204b6c:	b40ff0ef          	jal	ra,ffffffffc0203eac <put_pgdir>
    mm_destroy(mm);
ffffffffc0204b70:	8526                	mv	a0,s1
ffffffffc0204b72:	c6bfe0ef          	jal	ra,ffffffffc02037dc <mm_destroy>
    return ret;
ffffffffc0204b76:	b705                	j	ffffffffc0204a96 <do_execve+0x274>
            exit_mmap(mm);// 释放 VMA 结构体
ffffffffc0204b78:	854e                	mv	a0,s3
ffffffffc0204b7a:	dfffe0ef          	jal	ra,ffffffffc0203978 <exit_mmap>
            put_pgdir(mm);// 释放页目录表
ffffffffc0204b7e:	854e                	mv	a0,s3
ffffffffc0204b80:	b2cff0ef          	jal	ra,ffffffffc0203eac <put_pgdir>
            mm_destroy(mm);// 销毁 mm 结构体
ffffffffc0204b84:	854e                	mv	a0,s3
ffffffffc0204b86:	c57fe0ef          	jal	ra,ffffffffc02037dc <mm_destroy>
ffffffffc0204b8a:	b32d                	j	ffffffffc02048b4 <do_execve+0x92>
            vm_flags |= VM_WRITE;// 可写
ffffffffc0204b8c:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b90:	fb95                	bnez	a5,ffffffffc0204ac4 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b92:	4d5d                	li	s10,23
ffffffffc0204b94:	bf35                	j	ffffffffc0204ad0 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204b96:	0109b683          	ld	a3,16(s3)
ffffffffc0204b9a:	0289b903          	ld	s2,40(s3)
ffffffffc0204b9e:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204ba0:	075bfd63          	bgeu	s7,s5,ffffffffc0204c1a <do_execve+0x3f8>
            if (start == end) { continue; }
ffffffffc0204ba4:	db790fe3          	beq	s2,s7,ffffffffc0204962 <do_execve+0x140>
            off = start + PGSIZE - la; 
ffffffffc0204ba8:	6785                	lui	a5,0x1
ffffffffc0204baa:	00fb8533          	add	a0,s7,a5
ffffffffc0204bae:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204bb2:	41790a33          	sub	s4,s2,s7
            if (end < la) {
ffffffffc0204bb6:	0b597d63          	bgeu	s2,s5,ffffffffc0204c70 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204bba:	000cb683          	ld	a3,0(s9)
ffffffffc0204bbe:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204bc0:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204bc4:	40d406b3          	sub	a3,s0,a3
ffffffffc0204bc8:	8699                	srai	a3,a3,0x6
ffffffffc0204bca:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204bcc:	67e2                	ld	a5,24(sp)
ffffffffc0204bce:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bd2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204bd4:	0ac5f963          	bgeu	a1,a2,ffffffffc0204c86 <do_execve+0x464>
ffffffffc0204bd8:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204bdc:	8652                	mv	a2,s4
ffffffffc0204bde:	4581                	li	a1,0
ffffffffc0204be0:	96c2                	add	a3,a3,a6
ffffffffc0204be2:	9536                	add	a0,a0,a3
ffffffffc0204be4:	2cb000ef          	jal	ra,ffffffffc02056ae <memset>
            start += size; // 推进 start
ffffffffc0204be8:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204bec:	03597463          	bgeu	s2,s5,ffffffffc0204c14 <do_execve+0x3f2>
ffffffffc0204bf0:	d6e909e3          	beq	s2,a4,ffffffffc0204962 <do_execve+0x140>
ffffffffc0204bf4:	00002697          	auipc	a3,0x2
ffffffffc0204bf8:	59468693          	addi	a3,a3,1428 # ffffffffc0207188 <default_pmm_manager+0xc80>
ffffffffc0204bfc:	00001617          	auipc	a2,0x1
ffffffffc0204c00:	55c60613          	addi	a2,a2,1372 # ffffffffc0206158 <commands+0x818>
ffffffffc0204c04:	31f00593          	li	a1,799
ffffffffc0204c08:	00002517          	auipc	a0,0x2
ffffffffc0204c0c:	37050513          	addi	a0,a0,880 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204c10:	87ffb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204c14:	ff5710e3          	bne	a4,s5,ffffffffc0204bf4 <do_execve+0x3d2>
ffffffffc0204c18:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204c1a:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204962 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0204c1e:	6c88                	ld	a0,24(s1)
ffffffffc0204c20:	866a                	mv	a2,s10
ffffffffc0204c22:	85d6                	mv	a1,s5
ffffffffc0204c24:	993fe0ef          	jal	ra,ffffffffc02035b6 <pgdir_alloc_page>
ffffffffc0204c28:	842a                	mv	s0,a0
ffffffffc0204c2a:	dd05                	beqz	a0,ffffffffc0204b62 <do_execve+0x340>
            off = start - la;
ffffffffc0204c2c:	6785                	lui	a5,0x1
ffffffffc0204c2e:	415b8533          	sub	a0,s7,s5
            size = PGSIZE - off;
ffffffffc0204c32:	9abe                	add	s5,s5,a5
ffffffffc0204c34:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0204c38:	01597463          	bgeu	s2,s5,ffffffffc0204c40 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204c3c:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204c40:	000cb683          	ld	a3,0(s9)
ffffffffc0204c44:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c46:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c4a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c4e:	8699                	srai	a3,a3,0x6
ffffffffc0204c50:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c52:	67e2                	ld	a5,24(sp)
ffffffffc0204c54:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c58:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c5a:	02b87663          	bgeu	a6,a1,ffffffffc0204c86 <do_execve+0x464>
ffffffffc0204c5e:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c62:	4581                	li	a1,0
            start += size;
ffffffffc0204c64:	9bb2                	add	s7,s7,a2
ffffffffc0204c66:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c68:	9536                	add	a0,a0,a3
ffffffffc0204c6a:	245000ef          	jal	ra,ffffffffc02056ae <memset>
ffffffffc0204c6e:	b775                	j	ffffffffc0204c1a <do_execve+0x3f8>
            size = PGSIZE - off;
ffffffffc0204c70:	417a8a33          	sub	s4,s5,s7
ffffffffc0204c74:	b799                	j	ffffffffc0204bba <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204c76:	5975                	li	s2,-3
ffffffffc0204c78:	b3c1                	j	ffffffffc0204a38 <do_execve+0x216>
        while (start < end)
ffffffffc0204c7a:	86de                	mv	a3,s7
ffffffffc0204c7c:	bf39                	j	ffffffffc0204b9a <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204c7e:	5971                	li	s2,-4
ffffffffc0204c80:	bdc5                	j	ffffffffc0204b70 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204c82:	5961                	li	s2,-8
ffffffffc0204c84:	b5c5                	j	ffffffffc0204b64 <do_execve+0x342>
ffffffffc0204c86:	00002617          	auipc	a2,0x2
ffffffffc0204c8a:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0206540 <default_pmm_manager+0x38>
ffffffffc0204c8e:	07100593          	li	a1,113
ffffffffc0204c92:	00002517          	auipc	a0,0x2
ffffffffc0204c96:	8d650513          	addi	a0,a0,-1834 # ffffffffc0206568 <default_pmm_manager+0x60>
ffffffffc0204c9a:	ff4fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204c9e:	00002617          	auipc	a2,0x2
ffffffffc0204ca2:	94a60613          	addi	a2,a2,-1718 # ffffffffc02065e8 <default_pmm_manager+0xe0>
ffffffffc0204ca6:	35400593          	li	a1,852
ffffffffc0204caa:	00002517          	auipc	a0,0x2
ffffffffc0204cae:	2ce50513          	addi	a0,a0,718 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204cb2:	fdcfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cb6:	00002697          	auipc	a3,0x2
ffffffffc0204cba:	5ea68693          	addi	a3,a3,1514 # ffffffffc02072a0 <default_pmm_manager+0xd98>
ffffffffc0204cbe:	00001617          	auipc	a2,0x1
ffffffffc0204cc2:	49a60613          	addi	a2,a2,1178 # ffffffffc0206158 <commands+0x818>
ffffffffc0204cc6:	34c00593          	li	a1,844
ffffffffc0204cca:	00002517          	auipc	a0,0x2
ffffffffc0204cce:	2ae50513          	addi	a0,a0,686 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204cd2:	fbcfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cd6:	00002697          	auipc	a3,0x2
ffffffffc0204cda:	58268693          	addi	a3,a3,1410 # ffffffffc0207258 <default_pmm_manager+0xd50>
ffffffffc0204cde:	00001617          	auipc	a2,0x1
ffffffffc0204ce2:	47a60613          	addi	a2,a2,1146 # ffffffffc0206158 <commands+0x818>
ffffffffc0204ce6:	34b00593          	li	a1,843
ffffffffc0204cea:	00002517          	auipc	a0,0x2
ffffffffc0204cee:	28e50513          	addi	a0,a0,654 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204cf2:	f9cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cf6:	00002697          	auipc	a3,0x2
ffffffffc0204cfa:	51a68693          	addi	a3,a3,1306 # ffffffffc0207210 <default_pmm_manager+0xd08>
ffffffffc0204cfe:	00001617          	auipc	a2,0x1
ffffffffc0204d02:	45a60613          	addi	a2,a2,1114 # ffffffffc0206158 <commands+0x818>
ffffffffc0204d06:	34a00593          	li	a1,842
ffffffffc0204d0a:	00002517          	auipc	a0,0x2
ffffffffc0204d0e:	26e50513          	addi	a0,a0,622 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204d12:	f7cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d16:	00002697          	auipc	a3,0x2
ffffffffc0204d1a:	4b268693          	addi	a3,a3,1202 # ffffffffc02071c8 <default_pmm_manager+0xcc0>
ffffffffc0204d1e:	00001617          	auipc	a2,0x1
ffffffffc0204d22:	43a60613          	addi	a2,a2,1082 # ffffffffc0206158 <commands+0x818>
ffffffffc0204d26:	34900593          	li	a1,841
ffffffffc0204d2a:	00002517          	auipc	a0,0x2
ffffffffc0204d2e:	24e50513          	addi	a0,a0,590 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204d32:	f5cfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204d36 <do_yield>:
    current->need_resched = 1;//自己让出CPU
ffffffffc0204d36:	000a6797          	auipc	a5,0xa6
ffffffffc0204d3a:	9927b783          	ld	a5,-1646(a5) # ffffffffc02aa6c8 <current>
ffffffffc0204d3e:	4705                	li	a4,1
ffffffffc0204d40:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d42:	4501                	li	a0,0
ffffffffc0204d44:	8082                	ret

ffffffffc0204d46 <do_wait>:
{
ffffffffc0204d46:	1101                	addi	sp,sp,-32
ffffffffc0204d48:	e822                	sd	s0,16(sp)
ffffffffc0204d4a:	e426                	sd	s1,8(sp)
ffffffffc0204d4c:	ec06                	sd	ra,24(sp)
ffffffffc0204d4e:	842e                	mv	s0,a1
ffffffffc0204d50:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204d52:	c999                	beqz	a1,ffffffffc0204d68 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204d54:	000a6797          	auipc	a5,0xa6
ffffffffc0204d58:	9747b783          	ld	a5,-1676(a5) # ffffffffc02aa6c8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d5c:	7788                	ld	a0,40(a5)
ffffffffc0204d5e:	4685                	li	a3,1
ffffffffc0204d60:	4611                	li	a2,4
ffffffffc0204d62:	fb1fe0ef          	jal	ra,ffffffffc0203d12 <user_mem_check>
ffffffffc0204d66:	c909                	beqz	a0,ffffffffc0204d78 <do_wait+0x32>
ffffffffc0204d68:	85a2                	mv	a1,s0
}
ffffffffc0204d6a:	6442                	ld	s0,16(sp)
ffffffffc0204d6c:	60e2                	ld	ra,24(sp)
ffffffffc0204d6e:	8526                	mv	a0,s1
ffffffffc0204d70:	64a2                	ld	s1,8(sp)
ffffffffc0204d72:	6105                	addi	sp,sp,32
ffffffffc0204d74:	fb8ff06f          	j	ffffffffc020452c <do_wait.part.0>
ffffffffc0204d78:	60e2                	ld	ra,24(sp)
ffffffffc0204d7a:	6442                	ld	s0,16(sp)
ffffffffc0204d7c:	64a2                	ld	s1,8(sp)
ffffffffc0204d7e:	5575                	li	a0,-3
ffffffffc0204d80:	6105                	addi	sp,sp,32
ffffffffc0204d82:	8082                	ret

ffffffffc0204d84 <do_kill>:
{
ffffffffc0204d84:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d86:	6789                	lui	a5,0x2
{
ffffffffc0204d88:	e406                	sd	ra,8(sp)
ffffffffc0204d8a:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d8c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d90:	17f9                	addi	a5,a5,-2
ffffffffc0204d92:	02e7e963          	bltu	a5,a4,ffffffffc0204dc4 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d96:	842a                	mv	s0,a0
ffffffffc0204d98:	45a9                	li	a1,10
ffffffffc0204d9a:	2501                	sext.w	a0,a0
ffffffffc0204d9c:	46c000ef          	jal	ra,ffffffffc0205208 <hash32>
ffffffffc0204da0:	02051793          	slli	a5,a0,0x20
ffffffffc0204da4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204da8:	000a2797          	auipc	a5,0xa2
ffffffffc0204dac:	8b078793          	addi	a5,a5,-1872 # ffffffffc02a6658 <hash_list>
ffffffffc0204db0:	953e                	add	a0,a0,a5
ffffffffc0204db2:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204db4:	a029                	j	ffffffffc0204dbe <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204db6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204dba:	00870b63          	beq	a4,s0,ffffffffc0204dd0 <do_kill+0x4c>
ffffffffc0204dbe:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204dc0:	fef51be3          	bne	a0,a5,ffffffffc0204db6 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204dc4:	5475                	li	s0,-3
}
ffffffffc0204dc6:	60a2                	ld	ra,8(sp)
ffffffffc0204dc8:	8522                	mv	a0,s0
ffffffffc0204dca:	6402                	ld	s0,0(sp)
ffffffffc0204dcc:	0141                	addi	sp,sp,16
ffffffffc0204dce:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204dd0:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204dd4:	00177693          	andi	a3,a4,1
ffffffffc0204dd8:	e295                	bnez	a3,ffffffffc0204dfc <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204dda:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204ddc:	00176713          	ori	a4,a4,1
ffffffffc0204de0:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204de4:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204de6:	fe06d0e3          	bgez	a3,ffffffffc0204dc6 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204dea:	f2878513          	addi	a0,a5,-216
ffffffffc0204dee:	22e000ef          	jal	ra,ffffffffc020501c <wakeup_proc>
}
ffffffffc0204df2:	60a2                	ld	ra,8(sp)
ffffffffc0204df4:	8522                	mv	a0,s0
ffffffffc0204df6:	6402                	ld	s0,0(sp)
ffffffffc0204df8:	0141                	addi	sp,sp,16
ffffffffc0204dfa:	8082                	ret
        return -E_KILLED;
ffffffffc0204dfc:	545d                	li	s0,-9
ffffffffc0204dfe:	b7e1                	j	ffffffffc0204dc6 <do_kill+0x42>

ffffffffc0204e00 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204e00:	1101                	addi	sp,sp,-32
ffffffffc0204e02:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204e04:	000a6797          	auipc	a5,0xa6
ffffffffc0204e08:	85478793          	addi	a5,a5,-1964 # ffffffffc02aa658 <proc_list>
ffffffffc0204e0c:	ec06                	sd	ra,24(sp)
ffffffffc0204e0e:	e822                	sd	s0,16(sp)
ffffffffc0204e10:	e04a                	sd	s2,0(sp)
ffffffffc0204e12:	000a2497          	auipc	s1,0xa2
ffffffffc0204e16:	84648493          	addi	s1,s1,-1978 # ffffffffc02a6658 <hash_list>
ffffffffc0204e1a:	e79c                	sd	a5,8(a5)
ffffffffc0204e1c:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204e1e:	000a6717          	auipc	a4,0xa6
ffffffffc0204e22:	83a70713          	addi	a4,a4,-1990 # ffffffffc02aa658 <proc_list>
ffffffffc0204e26:	87a6                	mv	a5,s1
ffffffffc0204e28:	e79c                	sd	a5,8(a5)
ffffffffc0204e2a:	e39c                	sd	a5,0(a5)
ffffffffc0204e2c:	07c1                	addi	a5,a5,16
ffffffffc0204e2e:	fef71de3          	bne	a4,a5,ffffffffc0204e28 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204e32:	f7dfe0ef          	jal	ra,ffffffffc0203dae <alloc_proc>
ffffffffc0204e36:	000a6917          	auipc	s2,0xa6
ffffffffc0204e3a:	89a90913          	addi	s2,s2,-1894 # ffffffffc02aa6d0 <idleproc>
ffffffffc0204e3e:	00a93023          	sd	a0,0(s2)
ffffffffc0204e42:	0e050f63          	beqz	a0,ffffffffc0204f40 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e46:	4789                	li	a5,2
ffffffffc0204e48:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e4a:	00003797          	auipc	a5,0x3
ffffffffc0204e4e:	1b678793          	addi	a5,a5,438 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e52:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e56:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204e58:	4785                	li	a5,1
ffffffffc0204e5a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e5c:	4641                	li	a2,16
ffffffffc0204e5e:	4581                	li	a1,0
ffffffffc0204e60:	8522                	mv	a0,s0
ffffffffc0204e62:	04d000ef          	jal	ra,ffffffffc02056ae <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e66:	463d                	li	a2,15
ffffffffc0204e68:	00002597          	auipc	a1,0x2
ffffffffc0204e6c:	49858593          	addi	a1,a1,1176 # ffffffffc0207300 <default_pmm_manager+0xdf8>
ffffffffc0204e70:	8522                	mv	a0,s0
ffffffffc0204e72:	04f000ef          	jal	ra,ffffffffc02056c0 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e76:	000a6717          	auipc	a4,0xa6
ffffffffc0204e7a:	86a70713          	addi	a4,a4,-1942 # ffffffffc02aa6e0 <nr_process>
ffffffffc0204e7e:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204e80:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e84:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e86:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e88:	4581                	li	a1,0
ffffffffc0204e8a:	00000517          	auipc	a0,0x0
ffffffffc0204e8e:	87450513          	addi	a0,a0,-1932 # ffffffffc02046fe <init_main>
    nr_process++;
ffffffffc0204e92:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204e94:	000a6797          	auipc	a5,0xa6
ffffffffc0204e98:	82d7ba23          	sd	a3,-1996(a5) # ffffffffc02aa6c8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e9c:	cf6ff0ef          	jal	ra,ffffffffc0204392 <kernel_thread>
ffffffffc0204ea0:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204ea2:	08a05363          	blez	a0,ffffffffc0204f28 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ea6:	6789                	lui	a5,0x2
ffffffffc0204ea8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204eac:	17f9                	addi	a5,a5,-2
ffffffffc0204eae:	2501                	sext.w	a0,a0
ffffffffc0204eb0:	02e7e363          	bltu	a5,a4,ffffffffc0204ed6 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204eb4:	45a9                	li	a1,10
ffffffffc0204eb6:	352000ef          	jal	ra,ffffffffc0205208 <hash32>
ffffffffc0204eba:	02051793          	slli	a5,a0,0x20
ffffffffc0204ebe:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204ec2:	96a6                	add	a3,a3,s1
ffffffffc0204ec4:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ec6:	a029                	j	ffffffffc0204ed0 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204ec8:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c74>
ffffffffc0204ecc:	04870b63          	beq	a4,s0,ffffffffc0204f22 <proc_init+0x122>
    return listelm->next;
ffffffffc0204ed0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ed2:	fef69be3          	bne	a3,a5,ffffffffc0204ec8 <proc_init+0xc8>
    return NULL;
ffffffffc0204ed6:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ed8:	0b478493          	addi	s1,a5,180
ffffffffc0204edc:	4641                	li	a2,16
ffffffffc0204ede:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204ee0:	000a5417          	auipc	s0,0xa5
ffffffffc0204ee4:	7f840413          	addi	s0,s0,2040 # ffffffffc02aa6d8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ee8:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204eea:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204eec:	7c2000ef          	jal	ra,ffffffffc02056ae <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ef0:	463d                	li	a2,15
ffffffffc0204ef2:	00002597          	auipc	a1,0x2
ffffffffc0204ef6:	43658593          	addi	a1,a1,1078 # ffffffffc0207328 <default_pmm_manager+0xe20>
ffffffffc0204efa:	8526                	mv	a0,s1
ffffffffc0204efc:	7c4000ef          	jal	ra,ffffffffc02056c0 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f00:	00093783          	ld	a5,0(s2)
ffffffffc0204f04:	cbb5                	beqz	a5,ffffffffc0204f78 <proc_init+0x178>
ffffffffc0204f06:	43dc                	lw	a5,4(a5)
ffffffffc0204f08:	eba5                	bnez	a5,ffffffffc0204f78 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f0a:	601c                	ld	a5,0(s0)
ffffffffc0204f0c:	c7b1                	beqz	a5,ffffffffc0204f58 <proc_init+0x158>
ffffffffc0204f0e:	43d8                	lw	a4,4(a5)
ffffffffc0204f10:	4785                	li	a5,1
ffffffffc0204f12:	04f71363          	bne	a4,a5,ffffffffc0204f58 <proc_init+0x158>
}
ffffffffc0204f16:	60e2                	ld	ra,24(sp)
ffffffffc0204f18:	6442                	ld	s0,16(sp)
ffffffffc0204f1a:	64a2                	ld	s1,8(sp)
ffffffffc0204f1c:	6902                	ld	s2,0(sp)
ffffffffc0204f1e:	6105                	addi	sp,sp,32
ffffffffc0204f20:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f22:	f2878793          	addi	a5,a5,-216
ffffffffc0204f26:	bf4d                	j	ffffffffc0204ed8 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204f28:	00002617          	auipc	a2,0x2
ffffffffc0204f2c:	3e060613          	addi	a2,a2,992 # ffffffffc0207308 <default_pmm_manager+0xe00>
ffffffffc0204f30:	48c00593          	li	a1,1164
ffffffffc0204f34:	00002517          	auipc	a0,0x2
ffffffffc0204f38:	04450513          	addi	a0,a0,68 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204f3c:	d52fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f40:	00002617          	auipc	a2,0x2
ffffffffc0204f44:	3a860613          	addi	a2,a2,936 # ffffffffc02072e8 <default_pmm_manager+0xde0>
ffffffffc0204f48:	47d00593          	li	a1,1149
ffffffffc0204f4c:	00002517          	auipc	a0,0x2
ffffffffc0204f50:	02c50513          	addi	a0,a0,44 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204f54:	d3afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f58:	00002697          	auipc	a3,0x2
ffffffffc0204f5c:	40068693          	addi	a3,a3,1024 # ffffffffc0207358 <default_pmm_manager+0xe50>
ffffffffc0204f60:	00001617          	auipc	a2,0x1
ffffffffc0204f64:	1f860613          	addi	a2,a2,504 # ffffffffc0206158 <commands+0x818>
ffffffffc0204f68:	49300593          	li	a1,1171
ffffffffc0204f6c:	00002517          	auipc	a0,0x2
ffffffffc0204f70:	00c50513          	addi	a0,a0,12 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204f74:	d1afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f78:	00002697          	auipc	a3,0x2
ffffffffc0204f7c:	3b868693          	addi	a3,a3,952 # ffffffffc0207330 <default_pmm_manager+0xe28>
ffffffffc0204f80:	00001617          	auipc	a2,0x1
ffffffffc0204f84:	1d860613          	addi	a2,a2,472 # ffffffffc0206158 <commands+0x818>
ffffffffc0204f88:	49200593          	li	a1,1170
ffffffffc0204f8c:	00002517          	auipc	a0,0x2
ffffffffc0204f90:	fec50513          	addi	a0,a0,-20 # ffffffffc0206f78 <default_pmm_manager+0xa70>
ffffffffc0204f94:	cfafb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204f98 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204f98:	1141                	addi	sp,sp,-16
ffffffffc0204f9a:	e022                	sd	s0,0(sp)
ffffffffc0204f9c:	e406                	sd	ra,8(sp)
ffffffffc0204f9e:	000a5417          	auipc	s0,0xa5
ffffffffc0204fa2:	72a40413          	addi	s0,s0,1834 # ffffffffc02aa6c8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204fa6:	6018                	ld	a4,0(s0)
ffffffffc0204fa8:	6f1c                	ld	a5,24(a4)
ffffffffc0204faa:	dffd                	beqz	a5,ffffffffc0204fa8 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204fac:	0f0000ef          	jal	ra,ffffffffc020509c <schedule>
ffffffffc0204fb0:	bfdd                	j	ffffffffc0204fa6 <cpu_idle+0xe>

ffffffffc0204fb2 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204fb2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204fb6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204fba:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204fbc:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204fbe:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204fc2:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204fc6:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204fca:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204fce:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204fd2:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204fd6:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204fda:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fde:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204fe2:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204fe6:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204fea:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204fee:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204ff0:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204ff2:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204ff6:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204ffa:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204ffe:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205002:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205006:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020500a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020500e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205012:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205016:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020501a:	8082                	ret

ffffffffc020501c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020501c:	4118                	lw	a4,0(a0)
{
ffffffffc020501e:	1101                	addi	sp,sp,-32
ffffffffc0205020:	ec06                	sd	ra,24(sp)
ffffffffc0205022:	e822                	sd	s0,16(sp)
ffffffffc0205024:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205026:	478d                	li	a5,3
ffffffffc0205028:	04f70b63          	beq	a4,a5,ffffffffc020507e <wakeup_proc+0x62>
ffffffffc020502c:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020502e:	100027f3          	csrr	a5,sstatus
ffffffffc0205032:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205034:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205036:	ef9d                	bnez	a5,ffffffffc0205074 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205038:	4789                	li	a5,2
ffffffffc020503a:	02f70163          	beq	a4,a5,ffffffffc020505c <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020503e:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205040:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205044:	e491                	bnez	s1,ffffffffc0205050 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205046:	60e2                	ld	ra,24(sp)
ffffffffc0205048:	6442                	ld	s0,16(sp)
ffffffffc020504a:	64a2                	ld	s1,8(sp)
ffffffffc020504c:	6105                	addi	sp,sp,32
ffffffffc020504e:	8082                	ret
ffffffffc0205050:	6442                	ld	s0,16(sp)
ffffffffc0205052:	60e2                	ld	ra,24(sp)
ffffffffc0205054:	64a2                	ld	s1,8(sp)
ffffffffc0205056:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205058:	957fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020505c:	00002617          	auipc	a2,0x2
ffffffffc0205060:	35c60613          	addi	a2,a2,860 # ffffffffc02073b8 <default_pmm_manager+0xeb0>
ffffffffc0205064:	45d1                	li	a1,20
ffffffffc0205066:	00002517          	auipc	a0,0x2
ffffffffc020506a:	33a50513          	addi	a0,a0,826 # ffffffffc02073a0 <default_pmm_manager+0xe98>
ffffffffc020506e:	c88fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205072:	bfc9                	j	ffffffffc0205044 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205074:	941fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205078:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020507a:	4485                	li	s1,1
ffffffffc020507c:	bf75                	j	ffffffffc0205038 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020507e:	00002697          	auipc	a3,0x2
ffffffffc0205082:	30268693          	addi	a3,a3,770 # ffffffffc0207380 <default_pmm_manager+0xe78>
ffffffffc0205086:	00001617          	auipc	a2,0x1
ffffffffc020508a:	0d260613          	addi	a2,a2,210 # ffffffffc0206158 <commands+0x818>
ffffffffc020508e:	45a5                	li	a1,9
ffffffffc0205090:	00002517          	auipc	a0,0x2
ffffffffc0205094:	31050513          	addi	a0,a0,784 # ffffffffc02073a0 <default_pmm_manager+0xe98>
ffffffffc0205098:	bf6fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020509c <schedule>:

void schedule(void)
{
ffffffffc020509c:	1141                	addi	sp,sp,-16
ffffffffc020509e:	e406                	sd	ra,8(sp)
ffffffffc02050a0:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02050a2:	100027f3          	csrr	a5,sstatus
ffffffffc02050a6:	8b89                	andi	a5,a5,2
ffffffffc02050a8:	4401                	li	s0,0
ffffffffc02050aa:	efbd                	bnez	a5,ffffffffc0205128 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02050ac:	000a5897          	auipc	a7,0xa5
ffffffffc02050b0:	61c8b883          	ld	a7,1564(a7) # ffffffffc02aa6c8 <current>
ffffffffc02050b4:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02050b8:	000a5517          	auipc	a0,0xa5
ffffffffc02050bc:	61853503          	ld	a0,1560(a0) # ffffffffc02aa6d0 <idleproc>
ffffffffc02050c0:	04a88e63          	beq	a7,a0,ffffffffc020511c <schedule+0x80>
ffffffffc02050c4:	0c888693          	addi	a3,a7,200
ffffffffc02050c8:	000a5617          	auipc	a2,0xa5
ffffffffc02050cc:	59060613          	addi	a2,a2,1424 # ffffffffc02aa658 <proc_list>
        le = last;
ffffffffc02050d0:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02050d2:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02050d4:	4809                	li	a6,2
ffffffffc02050d6:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02050d8:	00c78863          	beq	a5,a2,ffffffffc02050e8 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02050dc:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02050e0:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02050e4:	03070163          	beq	a4,a6,ffffffffc0205106 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02050e8:	fef697e3          	bne	a3,a5,ffffffffc02050d6 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02050ec:	ed89                	bnez	a1,ffffffffc0205106 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02050ee:	451c                	lw	a5,8(a0)
ffffffffc02050f0:	2785                	addiw	a5,a5,1
ffffffffc02050f2:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02050f4:	00a88463          	beq	a7,a0,ffffffffc02050fc <schedule+0x60>
        {
            proc_run(next);
ffffffffc02050f8:	e2bfe0ef          	jal	ra,ffffffffc0203f22 <proc_run>
    if (flag)
ffffffffc02050fc:	e819                	bnez	s0,ffffffffc0205112 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02050fe:	60a2                	ld	ra,8(sp)
ffffffffc0205100:	6402                	ld	s0,0(sp)
ffffffffc0205102:	0141                	addi	sp,sp,16
ffffffffc0205104:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205106:	4198                	lw	a4,0(a1)
ffffffffc0205108:	4789                	li	a5,2
ffffffffc020510a:	fef712e3          	bne	a4,a5,ffffffffc02050ee <schedule+0x52>
ffffffffc020510e:	852e                	mv	a0,a1
ffffffffc0205110:	bff9                	j	ffffffffc02050ee <schedule+0x52>
}
ffffffffc0205112:	6402                	ld	s0,0(sp)
ffffffffc0205114:	60a2                	ld	ra,8(sp)
ffffffffc0205116:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205118:	897fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020511c:	000a5617          	auipc	a2,0xa5
ffffffffc0205120:	53c60613          	addi	a2,a2,1340 # ffffffffc02aa658 <proc_list>
ffffffffc0205124:	86b2                	mv	a3,a2
ffffffffc0205126:	b76d                	j	ffffffffc02050d0 <schedule+0x34>
        intr_disable();
ffffffffc0205128:	88dfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020512c:	4405                	li	s0,1
ffffffffc020512e:	bfbd                	j	ffffffffc02050ac <schedule+0x10>

ffffffffc0205130 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205130:	000a5797          	auipc	a5,0xa5
ffffffffc0205134:	5987b783          	ld	a5,1432(a5) # ffffffffc02aa6c8 <current>
}
ffffffffc0205138:	43c8                	lw	a0,4(a5)
ffffffffc020513a:	8082                	ret

ffffffffc020513c <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020513c:	4501                	li	a0,0
ffffffffc020513e:	8082                	ret

ffffffffc0205140 <sys_putc>:
    cputchar(c);
ffffffffc0205140:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205142:	1141                	addi	sp,sp,-16
ffffffffc0205144:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205146:	884fb0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020514a:	60a2                	ld	ra,8(sp)
ffffffffc020514c:	4501                	li	a0,0
ffffffffc020514e:	0141                	addi	sp,sp,16
ffffffffc0205150:	8082                	ret

ffffffffc0205152 <sys_kill>:
    return do_kill(pid);
ffffffffc0205152:	4108                	lw	a0,0(a0)
ffffffffc0205154:	c31ff06f          	j	ffffffffc0204d84 <do_kill>

ffffffffc0205158 <sys_yield>:
    return do_yield();
ffffffffc0205158:	bdfff06f          	j	ffffffffc0204d36 <do_yield>

ffffffffc020515c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020515c:	6d14                	ld	a3,24(a0)
ffffffffc020515e:	6910                	ld	a2,16(a0)
ffffffffc0205160:	650c                	ld	a1,8(a0)
ffffffffc0205162:	6108                	ld	a0,0(a0)
ffffffffc0205164:	ebeff06f          	j	ffffffffc0204822 <do_execve>

ffffffffc0205168 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205168:	650c                	ld	a1,8(a0)
ffffffffc020516a:	4108                	lw	a0,0(a0)
ffffffffc020516c:	bdbff06f          	j	ffffffffc0204d46 <do_wait>

ffffffffc0205170 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205170:	000a5797          	auipc	a5,0xa5
ffffffffc0205174:	5587b783          	ld	a5,1368(a5) # ffffffffc02aa6c8 <current>
ffffffffc0205178:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020517a:	4501                	li	a0,0
ffffffffc020517c:	6a0c                	ld	a1,16(a2)
ffffffffc020517e:	e11fe06f          	j	ffffffffc0203f8e <do_fork>

ffffffffc0205182 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205182:	4108                	lw	a0,0(a0)
ffffffffc0205184:	a5eff06f          	j	ffffffffc02043e2 <do_exit>

ffffffffc0205188 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205188:	715d                	addi	sp,sp,-80
ffffffffc020518a:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020518c:	000a5497          	auipc	s1,0xa5
ffffffffc0205190:	53c48493          	addi	s1,s1,1340 # ffffffffc02aa6c8 <current>
ffffffffc0205194:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205196:	e0a2                	sd	s0,64(sp)
ffffffffc0205198:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020519a:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020519c:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020519e:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02051a0:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02051a4:	0327ee63          	bltu	a5,s2,ffffffffc02051e0 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02051a8:	00391713          	slli	a4,s2,0x3
ffffffffc02051ac:	00002797          	auipc	a5,0x2
ffffffffc02051b0:	27478793          	addi	a5,a5,628 # ffffffffc0207420 <syscalls>
ffffffffc02051b4:	97ba                	add	a5,a5,a4
ffffffffc02051b6:	639c                	ld	a5,0(a5)
ffffffffc02051b8:	c785                	beqz	a5,ffffffffc02051e0 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02051ba:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02051bc:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02051be:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02051c0:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02051c2:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02051c4:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02051c6:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02051c8:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02051ca:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02051cc:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02051ce:	0028                	addi	a0,sp,8
ffffffffc02051d0:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02051d2:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02051d4:	e828                	sd	a0,80(s0)
}
ffffffffc02051d6:	6406                	ld	s0,64(sp)
ffffffffc02051d8:	74e2                	ld	s1,56(sp)
ffffffffc02051da:	7942                	ld	s2,48(sp)
ffffffffc02051dc:	6161                	addi	sp,sp,80
ffffffffc02051de:	8082                	ret
    print_trapframe(tf);
ffffffffc02051e0:	8522                	mv	a0,s0
ffffffffc02051e2:	9c3fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02051e6:	609c                	ld	a5,0(s1)
ffffffffc02051e8:	86ca                	mv	a3,s2
ffffffffc02051ea:	00002617          	auipc	a2,0x2
ffffffffc02051ee:	1ee60613          	addi	a2,a2,494 # ffffffffc02073d8 <default_pmm_manager+0xed0>
ffffffffc02051f2:	43d8                	lw	a4,4(a5)
ffffffffc02051f4:	06200593          	li	a1,98
ffffffffc02051f8:	0b478793          	addi	a5,a5,180
ffffffffc02051fc:	00002517          	auipc	a0,0x2
ffffffffc0205200:	20c50513          	addi	a0,a0,524 # ffffffffc0207408 <default_pmm_manager+0xf00>
ffffffffc0205204:	a8afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205208 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205208:	9e3707b7          	lui	a5,0x9e370
ffffffffc020520c:	2785                	addiw	a5,a5,1
ffffffffc020520e:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205212:	02000793          	li	a5,32
ffffffffc0205216:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205218:	00f5553b          	srlw	a0,a0,a5
ffffffffc020521c:	8082                	ret

ffffffffc020521e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020521e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205222:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205224:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205228:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020522a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020522e:	f022                	sd	s0,32(sp)
ffffffffc0205230:	ec26                	sd	s1,24(sp)
ffffffffc0205232:	e84a                	sd	s2,16(sp)
ffffffffc0205234:	f406                	sd	ra,40(sp)
ffffffffc0205236:	e44e                	sd	s3,8(sp)
ffffffffc0205238:	84aa                	mv	s1,a0
ffffffffc020523a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020523c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205240:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205242:	03067e63          	bgeu	a2,a6,ffffffffc020527e <printnum+0x60>
ffffffffc0205246:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205248:	00805763          	blez	s0,ffffffffc0205256 <printnum+0x38>
ffffffffc020524c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020524e:	85ca                	mv	a1,s2
ffffffffc0205250:	854e                	mv	a0,s3
ffffffffc0205252:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205254:	fc65                	bnez	s0,ffffffffc020524c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205256:	1a02                	slli	s4,s4,0x20
ffffffffc0205258:	00002797          	auipc	a5,0x2
ffffffffc020525c:	2c878793          	addi	a5,a5,712 # ffffffffc0207520 <syscalls+0x100>
ffffffffc0205260:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205264:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205266:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205268:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020526c:	70a2                	ld	ra,40(sp)
ffffffffc020526e:	69a2                	ld	s3,8(sp)
ffffffffc0205270:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205272:	85ca                	mv	a1,s2
ffffffffc0205274:	87a6                	mv	a5,s1
}
ffffffffc0205276:	6942                	ld	s2,16(sp)
ffffffffc0205278:	64e2                	ld	s1,24(sp)
ffffffffc020527a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020527c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020527e:	03065633          	divu	a2,a2,a6
ffffffffc0205282:	8722                	mv	a4,s0
ffffffffc0205284:	f9bff0ef          	jal	ra,ffffffffc020521e <printnum>
ffffffffc0205288:	b7f9                	j	ffffffffc0205256 <printnum+0x38>

ffffffffc020528a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020528a:	7119                	addi	sp,sp,-128
ffffffffc020528c:	f4a6                	sd	s1,104(sp)
ffffffffc020528e:	f0ca                	sd	s2,96(sp)
ffffffffc0205290:	ecce                	sd	s3,88(sp)
ffffffffc0205292:	e8d2                	sd	s4,80(sp)
ffffffffc0205294:	e4d6                	sd	s5,72(sp)
ffffffffc0205296:	e0da                	sd	s6,64(sp)
ffffffffc0205298:	fc5e                	sd	s7,56(sp)
ffffffffc020529a:	f06a                	sd	s10,32(sp)
ffffffffc020529c:	fc86                	sd	ra,120(sp)
ffffffffc020529e:	f8a2                	sd	s0,112(sp)
ffffffffc02052a0:	f862                	sd	s8,48(sp)
ffffffffc02052a2:	f466                	sd	s9,40(sp)
ffffffffc02052a4:	ec6e                	sd	s11,24(sp)
ffffffffc02052a6:	892a                	mv	s2,a0
ffffffffc02052a8:	84ae                	mv	s1,a1
ffffffffc02052aa:	8d32                	mv	s10,a2
ffffffffc02052ac:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052ae:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02052b2:	5b7d                	li	s6,-1
ffffffffc02052b4:	00002a97          	auipc	s5,0x2
ffffffffc02052b8:	298a8a93          	addi	s5,s5,664 # ffffffffc020754c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02052bc:	00002b97          	auipc	s7,0x2
ffffffffc02052c0:	4acb8b93          	addi	s7,s7,1196 # ffffffffc0207768 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052c4:	000d4503          	lbu	a0,0(s10)
ffffffffc02052c8:	001d0413          	addi	s0,s10,1
ffffffffc02052cc:	01350a63          	beq	a0,s3,ffffffffc02052e0 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02052d0:	c121                	beqz	a0,ffffffffc0205310 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02052d2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052d4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02052d6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052d8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02052dc:	ff351ae3          	bne	a0,s3,ffffffffc02052d0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052e0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02052e4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02052e8:	4c81                	li	s9,0
ffffffffc02052ea:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02052ec:	5c7d                	li	s8,-1
ffffffffc02052ee:	5dfd                	li	s11,-1
ffffffffc02052f0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02052f4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052f6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02052fa:	0ff5f593          	zext.b	a1,a1
ffffffffc02052fe:	00140d13          	addi	s10,s0,1
ffffffffc0205302:	04b56263          	bltu	a0,a1,ffffffffc0205346 <vprintfmt+0xbc>
ffffffffc0205306:	058a                	slli	a1,a1,0x2
ffffffffc0205308:	95d6                	add	a1,a1,s5
ffffffffc020530a:	4194                	lw	a3,0(a1)
ffffffffc020530c:	96d6                	add	a3,a3,s5
ffffffffc020530e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205310:	70e6                	ld	ra,120(sp)
ffffffffc0205312:	7446                	ld	s0,112(sp)
ffffffffc0205314:	74a6                	ld	s1,104(sp)
ffffffffc0205316:	7906                	ld	s2,96(sp)
ffffffffc0205318:	69e6                	ld	s3,88(sp)
ffffffffc020531a:	6a46                	ld	s4,80(sp)
ffffffffc020531c:	6aa6                	ld	s5,72(sp)
ffffffffc020531e:	6b06                	ld	s6,64(sp)
ffffffffc0205320:	7be2                	ld	s7,56(sp)
ffffffffc0205322:	7c42                	ld	s8,48(sp)
ffffffffc0205324:	7ca2                	ld	s9,40(sp)
ffffffffc0205326:	7d02                	ld	s10,32(sp)
ffffffffc0205328:	6de2                	ld	s11,24(sp)
ffffffffc020532a:	6109                	addi	sp,sp,128
ffffffffc020532c:	8082                	ret
            padc = '0';
ffffffffc020532e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205330:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205334:	846a                	mv	s0,s10
ffffffffc0205336:	00140d13          	addi	s10,s0,1
ffffffffc020533a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020533e:	0ff5f593          	zext.b	a1,a1
ffffffffc0205342:	fcb572e3          	bgeu	a0,a1,ffffffffc0205306 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205346:	85a6                	mv	a1,s1
ffffffffc0205348:	02500513          	li	a0,37
ffffffffc020534c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020534e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205352:	8d22                	mv	s10,s0
ffffffffc0205354:	f73788e3          	beq	a5,s3,ffffffffc02052c4 <vprintfmt+0x3a>
ffffffffc0205358:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020535c:	1d7d                	addi	s10,s10,-1
ffffffffc020535e:	ff379de3          	bne	a5,s3,ffffffffc0205358 <vprintfmt+0xce>
ffffffffc0205362:	b78d                	j	ffffffffc02052c4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205364:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205368:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020536c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020536e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205372:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205376:	02d86463          	bltu	a6,a3,ffffffffc020539e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020537a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020537e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205382:	0186873b          	addw	a4,a3,s8
ffffffffc0205386:	0017171b          	slliw	a4,a4,0x1
ffffffffc020538a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020538c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205390:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205392:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205396:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020539a:	fed870e3          	bgeu	a6,a3,ffffffffc020537a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020539e:	f40ddce3          	bgez	s11,ffffffffc02052f6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02053a2:	8de2                	mv	s11,s8
ffffffffc02053a4:	5c7d                	li	s8,-1
ffffffffc02053a6:	bf81                	j	ffffffffc02052f6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02053a8:	fffdc693          	not	a3,s11
ffffffffc02053ac:	96fd                	srai	a3,a3,0x3f
ffffffffc02053ae:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053b2:	00144603          	lbu	a2,1(s0)
ffffffffc02053b6:	2d81                	sext.w	s11,s11
ffffffffc02053b8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02053ba:	bf35                	j	ffffffffc02052f6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02053bc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053c0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02053c4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053c6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02053c8:	bfd9                	j	ffffffffc020539e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02053ca:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053cc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02053d0:	01174463          	blt	a4,a7,ffffffffc02053d8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02053d4:	1a088e63          	beqz	a7,ffffffffc0205590 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02053d8:	000a3603          	ld	a2,0(s4)
ffffffffc02053dc:	46c1                	li	a3,16
ffffffffc02053de:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02053e0:	2781                	sext.w	a5,a5
ffffffffc02053e2:	876e                	mv	a4,s11
ffffffffc02053e4:	85a6                	mv	a1,s1
ffffffffc02053e6:	854a                	mv	a0,s2
ffffffffc02053e8:	e37ff0ef          	jal	ra,ffffffffc020521e <printnum>
            break;
ffffffffc02053ec:	bde1                	j	ffffffffc02052c4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02053ee:	000a2503          	lw	a0,0(s4)
ffffffffc02053f2:	85a6                	mv	a1,s1
ffffffffc02053f4:	0a21                	addi	s4,s4,8
ffffffffc02053f6:	9902                	jalr	s2
            break;
ffffffffc02053f8:	b5f1                	j	ffffffffc02052c4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02053fa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053fc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205400:	01174463          	blt	a4,a7,ffffffffc0205408 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205404:	18088163          	beqz	a7,ffffffffc0205586 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205408:	000a3603          	ld	a2,0(s4)
ffffffffc020540c:	46a9                	li	a3,10
ffffffffc020540e:	8a2e                	mv	s4,a1
ffffffffc0205410:	bfc1                	j	ffffffffc02053e0 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205412:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205416:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205418:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020541a:	bdf1                	j	ffffffffc02052f6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020541c:	85a6                	mv	a1,s1
ffffffffc020541e:	02500513          	li	a0,37
ffffffffc0205422:	9902                	jalr	s2
            break;
ffffffffc0205424:	b545                	j	ffffffffc02052c4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205426:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020542a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020542c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020542e:	b5e1                	j	ffffffffc02052f6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205430:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205432:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205436:	01174463          	blt	a4,a7,ffffffffc020543e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020543a:	14088163          	beqz	a7,ffffffffc020557c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020543e:	000a3603          	ld	a2,0(s4)
ffffffffc0205442:	46a1                	li	a3,8
ffffffffc0205444:	8a2e                	mv	s4,a1
ffffffffc0205446:	bf69                	j	ffffffffc02053e0 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205448:	03000513          	li	a0,48
ffffffffc020544c:	85a6                	mv	a1,s1
ffffffffc020544e:	e03e                	sd	a5,0(sp)
ffffffffc0205450:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205452:	85a6                	mv	a1,s1
ffffffffc0205454:	07800513          	li	a0,120
ffffffffc0205458:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020545a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020545c:	6782                	ld	a5,0(sp)
ffffffffc020545e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205460:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205464:	bfb5                	j	ffffffffc02053e0 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205466:	000a3403          	ld	s0,0(s4)
ffffffffc020546a:	008a0713          	addi	a4,s4,8
ffffffffc020546e:	e03a                	sd	a4,0(sp)
ffffffffc0205470:	14040263          	beqz	s0,ffffffffc02055b4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205474:	0fb05763          	blez	s11,ffffffffc0205562 <vprintfmt+0x2d8>
ffffffffc0205478:	02d00693          	li	a3,45
ffffffffc020547c:	0cd79163          	bne	a5,a3,ffffffffc020553e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205480:	00044783          	lbu	a5,0(s0)
ffffffffc0205484:	0007851b          	sext.w	a0,a5
ffffffffc0205488:	cf85                	beqz	a5,ffffffffc02054c0 <vprintfmt+0x236>
ffffffffc020548a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020548e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205492:	000c4563          	bltz	s8,ffffffffc020549c <vprintfmt+0x212>
ffffffffc0205496:	3c7d                	addiw	s8,s8,-1
ffffffffc0205498:	036c0263          	beq	s8,s6,ffffffffc02054bc <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020549c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020549e:	0e0c8e63          	beqz	s9,ffffffffc020559a <vprintfmt+0x310>
ffffffffc02054a2:	3781                	addiw	a5,a5,-32
ffffffffc02054a4:	0ef47b63          	bgeu	s0,a5,ffffffffc020559a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02054a8:	03f00513          	li	a0,63
ffffffffc02054ac:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02054ae:	000a4783          	lbu	a5,0(s4)
ffffffffc02054b2:	3dfd                	addiw	s11,s11,-1
ffffffffc02054b4:	0a05                	addi	s4,s4,1
ffffffffc02054b6:	0007851b          	sext.w	a0,a5
ffffffffc02054ba:	ffe1                	bnez	a5,ffffffffc0205492 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02054bc:	01b05963          	blez	s11,ffffffffc02054ce <vprintfmt+0x244>
ffffffffc02054c0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02054c2:	85a6                	mv	a1,s1
ffffffffc02054c4:	02000513          	li	a0,32
ffffffffc02054c8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02054ca:	fe0d9be3          	bnez	s11,ffffffffc02054c0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02054ce:	6a02                	ld	s4,0(sp)
ffffffffc02054d0:	bbd5                	j	ffffffffc02052c4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02054d2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054d4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02054d8:	01174463          	blt	a4,a7,ffffffffc02054e0 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02054dc:	08088d63          	beqz	a7,ffffffffc0205576 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02054e0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02054e4:	0a044d63          	bltz	s0,ffffffffc020559e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02054e8:	8622                	mv	a2,s0
ffffffffc02054ea:	8a66                	mv	s4,s9
ffffffffc02054ec:	46a9                	li	a3,10
ffffffffc02054ee:	bdcd                	j	ffffffffc02053e0 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02054f0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02054f4:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02054f6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02054f8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02054fc:	8fb5                	xor	a5,a5,a3
ffffffffc02054fe:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205502:	02d74163          	blt	a4,a3,ffffffffc0205524 <vprintfmt+0x29a>
ffffffffc0205506:	00369793          	slli	a5,a3,0x3
ffffffffc020550a:	97de                	add	a5,a5,s7
ffffffffc020550c:	639c                	ld	a5,0(a5)
ffffffffc020550e:	cb99                	beqz	a5,ffffffffc0205524 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205510:	86be                	mv	a3,a5
ffffffffc0205512:	00000617          	auipc	a2,0x0
ffffffffc0205516:	1ee60613          	addi	a2,a2,494 # ffffffffc0205700 <etext+0x28>
ffffffffc020551a:	85a6                	mv	a1,s1
ffffffffc020551c:	854a                	mv	a0,s2
ffffffffc020551e:	0ce000ef          	jal	ra,ffffffffc02055ec <printfmt>
ffffffffc0205522:	b34d                	j	ffffffffc02052c4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205524:	00002617          	auipc	a2,0x2
ffffffffc0205528:	01c60613          	addi	a2,a2,28 # ffffffffc0207540 <syscalls+0x120>
ffffffffc020552c:	85a6                	mv	a1,s1
ffffffffc020552e:	854a                	mv	a0,s2
ffffffffc0205530:	0bc000ef          	jal	ra,ffffffffc02055ec <printfmt>
ffffffffc0205534:	bb41                	j	ffffffffc02052c4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205536:	00002417          	auipc	s0,0x2
ffffffffc020553a:	00240413          	addi	s0,s0,2 # ffffffffc0207538 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020553e:	85e2                	mv	a1,s8
ffffffffc0205540:	8522                	mv	a0,s0
ffffffffc0205542:	e43e                	sd	a5,8(sp)
ffffffffc0205544:	0e2000ef          	jal	ra,ffffffffc0205626 <strnlen>
ffffffffc0205548:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020554c:	01b05b63          	blez	s11,ffffffffc0205562 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205550:	67a2                	ld	a5,8(sp)
ffffffffc0205552:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205556:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205558:	85a6                	mv	a1,s1
ffffffffc020555a:	8552                	mv	a0,s4
ffffffffc020555c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020555e:	fe0d9ce3          	bnez	s11,ffffffffc0205556 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205562:	00044783          	lbu	a5,0(s0)
ffffffffc0205566:	00140a13          	addi	s4,s0,1
ffffffffc020556a:	0007851b          	sext.w	a0,a5
ffffffffc020556e:	d3a5                	beqz	a5,ffffffffc02054ce <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205570:	05e00413          	li	s0,94
ffffffffc0205574:	bf39                	j	ffffffffc0205492 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205576:	000a2403          	lw	s0,0(s4)
ffffffffc020557a:	b7ad                	j	ffffffffc02054e4 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020557c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205580:	46a1                	li	a3,8
ffffffffc0205582:	8a2e                	mv	s4,a1
ffffffffc0205584:	bdb1                	j	ffffffffc02053e0 <vprintfmt+0x156>
ffffffffc0205586:	000a6603          	lwu	a2,0(s4)
ffffffffc020558a:	46a9                	li	a3,10
ffffffffc020558c:	8a2e                	mv	s4,a1
ffffffffc020558e:	bd89                	j	ffffffffc02053e0 <vprintfmt+0x156>
ffffffffc0205590:	000a6603          	lwu	a2,0(s4)
ffffffffc0205594:	46c1                	li	a3,16
ffffffffc0205596:	8a2e                	mv	s4,a1
ffffffffc0205598:	b5a1                	j	ffffffffc02053e0 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020559a:	9902                	jalr	s2
ffffffffc020559c:	bf09                	j	ffffffffc02054ae <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020559e:	85a6                	mv	a1,s1
ffffffffc02055a0:	02d00513          	li	a0,45
ffffffffc02055a4:	e03e                	sd	a5,0(sp)
ffffffffc02055a6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02055a8:	6782                	ld	a5,0(sp)
ffffffffc02055aa:	8a66                	mv	s4,s9
ffffffffc02055ac:	40800633          	neg	a2,s0
ffffffffc02055b0:	46a9                	li	a3,10
ffffffffc02055b2:	b53d                	j	ffffffffc02053e0 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02055b4:	03b05163          	blez	s11,ffffffffc02055d6 <vprintfmt+0x34c>
ffffffffc02055b8:	02d00693          	li	a3,45
ffffffffc02055bc:	f6d79de3          	bne	a5,a3,ffffffffc0205536 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02055c0:	00002417          	auipc	s0,0x2
ffffffffc02055c4:	f7840413          	addi	s0,s0,-136 # ffffffffc0207538 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055c8:	02800793          	li	a5,40
ffffffffc02055cc:	02800513          	li	a0,40
ffffffffc02055d0:	00140a13          	addi	s4,s0,1
ffffffffc02055d4:	bd6d                	j	ffffffffc020548e <vprintfmt+0x204>
ffffffffc02055d6:	00002a17          	auipc	s4,0x2
ffffffffc02055da:	f63a0a13          	addi	s4,s4,-157 # ffffffffc0207539 <syscalls+0x119>
ffffffffc02055de:	02800513          	li	a0,40
ffffffffc02055e2:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055e6:	05e00413          	li	s0,94
ffffffffc02055ea:	b565                	j	ffffffffc0205492 <vprintfmt+0x208>

ffffffffc02055ec <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055ec:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02055ee:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055f2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02055f4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055f6:	ec06                	sd	ra,24(sp)
ffffffffc02055f8:	f83a                	sd	a4,48(sp)
ffffffffc02055fa:	fc3e                	sd	a5,56(sp)
ffffffffc02055fc:	e0c2                	sd	a6,64(sp)
ffffffffc02055fe:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205600:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205602:	c89ff0ef          	jal	ra,ffffffffc020528a <vprintfmt>
}
ffffffffc0205606:	60e2                	ld	ra,24(sp)
ffffffffc0205608:	6161                	addi	sp,sp,80
ffffffffc020560a:	8082                	ret

ffffffffc020560c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020560c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205610:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205612:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205614:	cb81                	beqz	a5,ffffffffc0205624 <strlen+0x18>
        cnt ++;
ffffffffc0205616:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205618:	00a707b3          	add	a5,a4,a0
ffffffffc020561c:	0007c783          	lbu	a5,0(a5)
ffffffffc0205620:	fbfd                	bnez	a5,ffffffffc0205616 <strlen+0xa>
ffffffffc0205622:	8082                	ret
    }
    return cnt;
}
ffffffffc0205624:	8082                	ret

ffffffffc0205626 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205626:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205628:	e589                	bnez	a1,ffffffffc0205632 <strnlen+0xc>
ffffffffc020562a:	a811                	j	ffffffffc020563e <strnlen+0x18>
        cnt ++;
ffffffffc020562c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020562e:	00f58863          	beq	a1,a5,ffffffffc020563e <strnlen+0x18>
ffffffffc0205632:	00f50733          	add	a4,a0,a5
ffffffffc0205636:	00074703          	lbu	a4,0(a4)
ffffffffc020563a:	fb6d                	bnez	a4,ffffffffc020562c <strnlen+0x6>
ffffffffc020563c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020563e:	852e                	mv	a0,a1
ffffffffc0205640:	8082                	ret

ffffffffc0205642 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205642:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205644:	0005c703          	lbu	a4,0(a1)
ffffffffc0205648:	0785                	addi	a5,a5,1
ffffffffc020564a:	0585                	addi	a1,a1,1
ffffffffc020564c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205650:	fb75                	bnez	a4,ffffffffc0205644 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205652:	8082                	ret

ffffffffc0205654 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205654:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205658:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020565c:	cb89                	beqz	a5,ffffffffc020566e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020565e:	0505                	addi	a0,a0,1
ffffffffc0205660:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205662:	fee789e3          	beq	a5,a4,ffffffffc0205654 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205666:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020566a:	9d19                	subw	a0,a0,a4
ffffffffc020566c:	8082                	ret
ffffffffc020566e:	4501                	li	a0,0
ffffffffc0205670:	bfed                	j	ffffffffc020566a <strcmp+0x16>

ffffffffc0205672 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205672:	c20d                	beqz	a2,ffffffffc0205694 <strncmp+0x22>
ffffffffc0205674:	962e                	add	a2,a2,a1
ffffffffc0205676:	a031                	j	ffffffffc0205682 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205678:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020567a:	00e79a63          	bne	a5,a4,ffffffffc020568e <strncmp+0x1c>
ffffffffc020567e:	00b60b63          	beq	a2,a1,ffffffffc0205694 <strncmp+0x22>
ffffffffc0205682:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205686:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205688:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020568c:	f7f5                	bnez	a5,ffffffffc0205678 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020568e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205692:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205694:	4501                	li	a0,0
ffffffffc0205696:	8082                	ret

ffffffffc0205698 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205698:	00054783          	lbu	a5,0(a0)
ffffffffc020569c:	c799                	beqz	a5,ffffffffc02056aa <strchr+0x12>
        if (*s == c) {
ffffffffc020569e:	00f58763          	beq	a1,a5,ffffffffc02056ac <strchr+0x14>
    while (*s != '\0') {
ffffffffc02056a2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02056a6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02056a8:	fbfd                	bnez	a5,ffffffffc020569e <strchr+0x6>
    }
    return NULL;
ffffffffc02056aa:	4501                	li	a0,0
}
ffffffffc02056ac:	8082                	ret

ffffffffc02056ae <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02056ae:	ca01                	beqz	a2,ffffffffc02056be <memset+0x10>
ffffffffc02056b0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02056b2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02056b4:	0785                	addi	a5,a5,1
ffffffffc02056b6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02056ba:	fec79de3          	bne	a5,a2,ffffffffc02056b4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02056be:	8082                	ret

ffffffffc02056c0 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02056c0:	ca19                	beqz	a2,ffffffffc02056d6 <memcpy+0x16>
ffffffffc02056c2:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02056c4:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02056c6:	0005c703          	lbu	a4,0(a1)
ffffffffc02056ca:	0585                	addi	a1,a1,1
ffffffffc02056cc:	0785                	addi	a5,a5,1
ffffffffc02056ce:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02056d2:	fec59ae3          	bne	a1,a2,ffffffffc02056c6 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02056d6:	8082                	ret
