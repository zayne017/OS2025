
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	61c50513          	addi	a0,a0,1564 # ffffffffc0201668 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	62650513          	addi	a0,a0,1574 # ffffffffc0201688 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	5f458593          	addi	a1,a1,1524 # ffffffffc0201662 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	63250513          	addi	a0,a0,1586 # ffffffffc02016a8 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	63e50513          	addi	a0,a0,1598 # ffffffffc02016c8 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	64a50513          	addi	a0,a0,1610 # ffffffffc02016e8 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0205477 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	63c50513          	addi	a0,a0,1596 # ffffffffc0201708 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <free_area>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	560010ef          	jal	ra,ffffffffc0201650 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	63c50513          	addi	a0,a0,1596 # ffffffffc0201738 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	6eb000ef          	jal	ra,ffffffffc0200ff6 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	0fa010ef          	jal	ra,ffffffffc020123a <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	0c4010ef          	jal	ra,ffffffffc020123a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0205030 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	56650513          	addi	a0,a0,1382 # ffffffffc0201758 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	52850513          	addi	a0,a0,1320 # ffffffffc0201730 <etext+0xce>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	3a00106f          	j	ffffffffc02015bc <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	55650513          	addi	a0,a0,1366 # ffffffffc0201778 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	53850513          	addi	a0,a0,1336 # ffffffffc0201788 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00005417          	auipc	s0,0x5
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0205008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	53250513          	addi	a0,a0,1330 # ffffffffc0201798 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	53a50513          	addi	a0,a0,1338 # ffffffffc02017b0 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedae75>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	4d090913          	addi	s2,s2,1232 # ffffffffc0201800 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	4ba48493          	addi	s1,s1,1210 # ffffffffc02017f8 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	4e650513          	addi	a0,a0,1254 # ffffffffc0201878 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	51250513          	addi	a0,a0,1298 # ffffffffc02018b0 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	3f250513          	addi	a0,a0,1010 # ffffffffc02017d0 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	1ea010ef          	jal	ra,ffffffffc02015d6 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	230010ef          	jal	ra,ffffffffc020162a <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	17c010ef          	jal	ra,ffffffffc020160c <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	36450513          	addi	a0,a0,868 # ffffffffc0201808 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	2b650513          	addi	a0,a0,694 # ffffffffc0201828 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	2bc50513          	addi	a0,a0,700 # ffffffffc0201840 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	2ca50513          	addi	a0,a0,714 # ffffffffc0201860 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	30e50513          	addi	a0,a0,782 # ffffffffc02018b0 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00005797          	auipc	a5,0x5
ffffffffc02005ae:	a887b723          	sd	s0,-1394(a5) # ffffffffc0205038 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00005797          	auipc	a5,0x5
ffffffffc02005b6:	a967b723          	sd	s6,-1394(a5) # ffffffffc0205040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	a7c53503          	ld	a0,-1412(a0) # ffffffffc0205038 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00005517          	auipc	a0,0x5
ffffffffc02005ca:	a7a53503          	ld	a0,-1414(a0) # ffffffffc0205040 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00005797          	auipc	a5,0x5
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0205018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005e2:	00005517          	auipc	a0,0x5
ffffffffc02005e6:	a4656503          	lwu	a0,-1466(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005ec:	cd49                	beqz	a0,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02005ee:	00005617          	auipc	a2,0x5
ffffffffc02005f2:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0205018 <free_area>
ffffffffc02005f6:	01062803          	lw	a6,16(a2)
ffffffffc02005fa:	86aa                	mv	a3,a0
ffffffffc02005fc:	02081793          	slli	a5,a6,0x20
ffffffffc0200600:	9381                	srli	a5,a5,0x20
ffffffffc0200602:	08a7e063          	bltu	a5,a0,ffffffffc0200682 <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200606:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200608:	0018059b          	addiw	a1,a6,1
ffffffffc020060c:	1582                	slli	a1,a1,0x20
ffffffffc020060e:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200610:	4501                	li	a0,0
while ((le = list_next(le)) != &free_list) {
ffffffffc0200612:	06c78763          	beq	a5,a2,ffffffffc0200680 <best_fit_alloc_pages+0x94>
    if (p->property >= n && p->property < min_size) {
ffffffffc0200616:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020061a:	00d76763          	bltu	a4,a3,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
ffffffffc020061e:	00b77563          	bgeu	a4,a1,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
    struct Page *p = le2page(le, page_link);
ffffffffc0200622:	fe878513          	addi	a0,a5,-24
ffffffffc0200626:	85ba                	mv	a1,a4
ffffffffc0200628:	679c                	ld	a5,8(a5)
while ((le = list_next(le)) != &free_list) {
ffffffffc020062a:	fec796e3          	bne	a5,a2,ffffffffc0200616 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc020062e:	c929                	beqz	a0,ffffffffc0200680 <best_fit_alloc_pages+0x94>
        if (page->property > n) {//如果足够用还有空闲 就要拆分再把剩下的放进空闲链表
ffffffffc0200630:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200634:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200636:	710c                	ld	a1,32(a0)
ffffffffc0200638:	02089793          	slli	a5,a7,0x20
ffffffffc020063c:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020063e:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200640:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc0200642:	0006831b          	sext.w	t1,a3
        if (page->property > n) {//如果足够用还有空闲 就要拆分再把剩下的放进空闲链表
ffffffffc0200646:	02f6f563          	bgeu	a3,a5,ffffffffc0200670 <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020064a:	00269793          	slli	a5,a3,0x2
ffffffffc020064e:	97b6                	add	a5,a5,a3
ffffffffc0200650:	078e                	slli	a5,a5,0x3
ffffffffc0200652:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc0200654:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200656:	406888bb          	subw	a7,a7,t1
ffffffffc020065a:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc020065e:	0026e693          	ori	a3,a3,2
ffffffffc0200662:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200664:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200668:	e194                	sd	a3,0(a1)
ffffffffc020066a:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020066c:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc020066e:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200670:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc0200672:	4068083b          	subw	a6,a6,t1
ffffffffc0200676:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc020067a:	9bf5                	andi	a5,a5,-3
ffffffffc020067c:	e51c                	sd	a5,8(a0)
ffffffffc020067e:	8082                	ret
}
ffffffffc0200680:	8082                	ret
        return NULL;
ffffffffc0200682:	4501                	li	a0,0
ffffffffc0200684:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200686:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200688:	00001697          	auipc	a3,0x1
ffffffffc020068c:	24068693          	addi	a3,a3,576 # ffffffffc02018c8 <etext+0x266>
ffffffffc0200690:	00001617          	auipc	a2,0x1
ffffffffc0200694:	24060613          	addi	a2,a2,576 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200698:	07100593          	li	a1,113
ffffffffc020069c:	00001517          	auipc	a0,0x1
ffffffffc02006a0:	24c50513          	addi	a0,a0,588 # ffffffffc02018e8 <etext+0x286>
best_fit_alloc_pages(size_t n) {
ffffffffc02006a4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006a6:	b1dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02006aa <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02006aa:	715d                	addi	sp,sp,-80
ffffffffc02006ac:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02006ae:	00005417          	auipc	s0,0x5
ffffffffc02006b2:	96a40413          	addi	s0,s0,-1686 # ffffffffc0205018 <free_area>
ffffffffc02006b6:	641c                	ld	a5,8(s0)
ffffffffc02006b8:	e486                	sd	ra,72(sp)
ffffffffc02006ba:	fc26                	sd	s1,56(sp)
ffffffffc02006bc:	f84a                	sd	s2,48(sp)
ffffffffc02006be:	f44e                	sd	s3,40(sp)
ffffffffc02006c0:	f052                	sd	s4,32(sp)
ffffffffc02006c2:	ec56                	sd	s5,24(sp)
ffffffffc02006c4:	e85a                	sd	s6,16(sp)
ffffffffc02006c6:	e45e                	sd	s7,8(sp)
ffffffffc02006c8:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ca:	26878963          	beq	a5,s0,ffffffffc020093c <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc02006ce:	4481                	li	s1,0
ffffffffc02006d0:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006d2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006d6:	8b09                	andi	a4,a4,2
ffffffffc02006d8:	26070663          	beqz	a4,ffffffffc0200944 <best_fit_check+0x29a>
        count ++, total += p->property;
ffffffffc02006dc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006e0:	679c                	ld	a5,8(a5)
ffffffffc02006e2:	2905                	addiw	s2,s2,1
ffffffffc02006e4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006e6:	fe8796e3          	bne	a5,s0,ffffffffc02006d2 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006ea:	89a6                	mv	s3,s1
ffffffffc02006ec:	0ff000ef          	jal	ra,ffffffffc0200fea <nr_free_pages>
ffffffffc02006f0:	33351a63          	bne	a0,s3,ffffffffc0200a24 <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006f4:	4505                	li	a0,1
ffffffffc02006f6:	0dd000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02006fa:	8a2a                	mv	s4,a0
ffffffffc02006fc:	36050463          	beqz	a0,ffffffffc0200a64 <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200700:	4505                	li	a0,1
ffffffffc0200702:	0d1000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200706:	89aa                	mv	s3,a0
ffffffffc0200708:	32050e63          	beqz	a0,ffffffffc0200a44 <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020070c:	4505                	li	a0,1
ffffffffc020070e:	0c5000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200712:	8aaa                	mv	s5,a0
ffffffffc0200714:	2c050863          	beqz	a0,ffffffffc02009e4 <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200718:	253a0663          	beq	s4,s3,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc020071c:	24aa0463          	beq	s4,a0,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc0200720:	24a98263          	beq	s3,a0,ffffffffc0200964 <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200724:	000a2783          	lw	a5,0(s4)
ffffffffc0200728:	24079e63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc020072c:	0009a783          	lw	a5,0(s3)
ffffffffc0200730:	24079a63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc0200734:	411c                	lw	a5,0(a0)
ffffffffc0200736:	24079763          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020073a:	00005797          	auipc	a5,0x5
ffffffffc020073e:	9167b783          	ld	a5,-1770(a5) # ffffffffc0205050 <pages>
ffffffffc0200742:	40fa0733          	sub	a4,s4,a5
ffffffffc0200746:	870d                	srai	a4,a4,0x3
ffffffffc0200748:	00002597          	auipc	a1,0x2
ffffffffc020074c:	8905b583          	ld	a1,-1904(a1) # ffffffffc0201fd8 <error_string+0x38>
ffffffffc0200750:	02b70733          	mul	a4,a4,a1
ffffffffc0200754:	00002617          	auipc	a2,0x2
ffffffffc0200758:	88c63603          	ld	a2,-1908(a2) # ffffffffc0201fe0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020075c:	00005697          	auipc	a3,0x5
ffffffffc0200760:	8ec6b683          	ld	a3,-1812(a3) # ffffffffc0205048 <npage>
ffffffffc0200764:	06b2                	slli	a3,a3,0xc
ffffffffc0200766:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200768:	0732                	slli	a4,a4,0xc
ffffffffc020076a:	22d77d63          	bgeu	a4,a3,ffffffffc02009a4 <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020076e:	40f98733          	sub	a4,s3,a5
ffffffffc0200772:	870d                	srai	a4,a4,0x3
ffffffffc0200774:	02b70733          	mul	a4,a4,a1
ffffffffc0200778:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020077a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020077c:	3ed77463          	bgeu	a4,a3,ffffffffc0200b64 <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200780:	40f507b3          	sub	a5,a0,a5
ffffffffc0200784:	878d                	srai	a5,a5,0x3
ffffffffc0200786:	02b787b3          	mul	a5,a5,a1
ffffffffc020078a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020078c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020078e:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200b44 <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200792:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200794:	00043c03          	ld	s8,0(s0)
ffffffffc0200798:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020079c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02007a0:	e400                	sd	s0,8(s0)
ffffffffc02007a2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02007a4:	00005797          	auipc	a5,0x5
ffffffffc02007a8:	8807a223          	sw	zero,-1916(a5) # ffffffffc0205028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007ac:	027000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007b0:	36051a63          	bnez	a0,ffffffffc0200b24 <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02007b4:	4585                	li	a1,1
ffffffffc02007b6:	8552                	mv	a0,s4
ffffffffc02007b8:	027000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p1);
ffffffffc02007bc:	4585                	li	a1,1
ffffffffc02007be:	854e                	mv	a0,s3
ffffffffc02007c0:	01f000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p2);
ffffffffc02007c4:	4585                	li	a1,1
ffffffffc02007c6:	8556                	mv	a0,s5
ffffffffc02007c8:	017000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(nr_free == 3);
ffffffffc02007cc:	4818                	lw	a4,16(s0)
ffffffffc02007ce:	478d                	li	a5,3
ffffffffc02007d0:	32f71a63          	bne	a4,a5,ffffffffc0200b04 <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007d4:	4505                	li	a0,1
ffffffffc02007d6:	7fc000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007da:	89aa                	mv	s3,a0
ffffffffc02007dc:	30050463          	beqz	a0,ffffffffc0200ae4 <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007e0:	4505                	li	a0,1
ffffffffc02007e2:	7f0000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007e6:	8aaa                	mv	s5,a0
ffffffffc02007e8:	2c050e63          	beqz	a0,ffffffffc0200ac4 <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007ec:	4505                	li	a0,1
ffffffffc02007ee:	7e4000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007f2:	8a2a                	mv	s4,a0
ffffffffc02007f4:	2a050863          	beqz	a0,ffffffffc0200aa4 <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc02007f8:	4505                	li	a0,1
ffffffffc02007fa:	7d8000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007fe:	28051363          	bnez	a0,ffffffffc0200a84 <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0200802:	4585                	li	a1,1
ffffffffc0200804:	854e                	mv	a0,s3
ffffffffc0200806:	7d8000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020080a:	641c                	ld	a5,8(s0)
ffffffffc020080c:	1a878c63          	beq	a5,s0,ffffffffc02009c4 <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200810:	4505                	li	a0,1
ffffffffc0200812:	7c0000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200816:	52a99763          	bne	s3,a0,ffffffffc0200d44 <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc020081a:	4505                	li	a0,1
ffffffffc020081c:	7b6000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200820:	50051263          	bnez	a0,ffffffffc0200d24 <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0200824:	481c                	lw	a5,16(s0)
ffffffffc0200826:	4c079f63          	bnez	a5,ffffffffc0200d04 <best_fit_check+0x65a>
    free_page(p);
ffffffffc020082a:	854e                	mv	a0,s3
ffffffffc020082c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020082e:	01843023          	sd	s8,0(s0)
ffffffffc0200832:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200836:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020083a:	7a4000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p1);
ffffffffc020083e:	4585                	li	a1,1
ffffffffc0200840:	8556                	mv	a0,s5
ffffffffc0200842:	79c000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p2);
ffffffffc0200846:	4585                	li	a1,1
ffffffffc0200848:	8552                	mv	a0,s4
ffffffffc020084a:	794000ef          	jal	ra,ffffffffc0200fde <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020084e:	4515                	li	a0,5
ffffffffc0200850:	782000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200854:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200856:	48050763          	beqz	a0,ffffffffc0200ce4 <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc020085a:	651c                	ld	a5,8(a0)
ffffffffc020085c:	8b89                	andi	a5,a5,2
ffffffffc020085e:	46079363          	bnez	a5,ffffffffc0200cc4 <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200862:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200864:	00043b03          	ld	s6,0(s0)
ffffffffc0200868:	00843a83          	ld	s5,8(s0)
ffffffffc020086c:	e000                	sd	s0,0(s0)
ffffffffc020086e:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200870:	762000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200874:	42051863          	bnez	a0,ffffffffc0200ca4 <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200878:	4589                	li	a1,2
ffffffffc020087a:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc020087e:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200882:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200886:	00004797          	auipc	a5,0x4
ffffffffc020088a:	7a07a123          	sw	zero,1954(a5) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc020088e:	750000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200892:	8562                	mv	a0,s8
ffffffffc0200894:	4585                	li	a1,1
ffffffffc0200896:	748000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020089a:	4511                	li	a0,4
ffffffffc020089c:	736000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008a0:	3e051263          	bnez	a0,ffffffffc0200c84 <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008a4:	0309b783          	ld	a5,48(s3)
ffffffffc02008a8:	8b89                	andi	a5,a5,2
ffffffffc02008aa:	3a078d63          	beqz	a5,ffffffffc0200c64 <best_fit_check+0x5ba>
ffffffffc02008ae:	0389a703          	lw	a4,56(s3)
ffffffffc02008b2:	4789                	li	a5,2
ffffffffc02008b4:	3af71863          	bne	a4,a5,ffffffffc0200c64 <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008b8:	4505                	li	a0,1
ffffffffc02008ba:	718000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008be:	8a2a                	mv	s4,a0
ffffffffc02008c0:	38050263          	beqz	a0,ffffffffc0200c44 <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008c4:	4509                	li	a0,2
ffffffffc02008c6:	70c000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008ca:	34050d63          	beqz	a0,ffffffffc0200c24 <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc02008ce:	334c1b63          	bne	s8,s4,ffffffffc0200c04 <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008d2:	854e                	mv	a0,s3
ffffffffc02008d4:	4595                	li	a1,5
ffffffffc02008d6:	708000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008da:	4515                	li	a0,5
ffffffffc02008dc:	6f6000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008e0:	89aa                	mv	s3,a0
ffffffffc02008e2:	30050163          	beqz	a0,ffffffffc0200be4 <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc02008e6:	4505                	li	a0,1
ffffffffc02008e8:	6ea000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008ec:	2c051c63          	bnez	a0,ffffffffc0200bc4 <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008f0:	481c                	lw	a5,16(s0)
ffffffffc02008f2:	2a079963          	bnez	a5,ffffffffc0200ba4 <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008f6:	4595                	li	a1,5
ffffffffc02008f8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02008fa:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02008fe:	01643023          	sd	s6,0(s0)
ffffffffc0200902:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200906:	6d8000ef          	jal	ra,ffffffffc0200fde <free_pages>
    return listelm->next;
ffffffffc020090a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	00878963          	beq	a5,s0,ffffffffc020091e <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200910:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200914:	679c                	ld	a5,8(a5)
ffffffffc0200916:	397d                	addiw	s2,s2,-1
ffffffffc0200918:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020091a:	fe879be3          	bne	a5,s0,ffffffffc0200910 <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc020091e:	26091363          	bnez	s2,ffffffffc0200b84 <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200922:	e0ed                	bnez	s1,ffffffffc0200a04 <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200924:	60a6                	ld	ra,72(sp)
ffffffffc0200926:	6406                	ld	s0,64(sp)
ffffffffc0200928:	74e2                	ld	s1,56(sp)
ffffffffc020092a:	7942                	ld	s2,48(sp)
ffffffffc020092c:	79a2                	ld	s3,40(sp)
ffffffffc020092e:	7a02                	ld	s4,32(sp)
ffffffffc0200930:	6ae2                	ld	s5,24(sp)
ffffffffc0200932:	6b42                	ld	s6,16(sp)
ffffffffc0200934:	6ba2                	ld	s7,8(sp)
ffffffffc0200936:	6c02                	ld	s8,0(sp)
ffffffffc0200938:	6161                	addi	sp,sp,80
ffffffffc020093a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020093c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020093e:	4481                	li	s1,0
ffffffffc0200940:	4901                	li	s2,0
ffffffffc0200942:	b36d                	j	ffffffffc02006ec <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200944:	00001697          	auipc	a3,0x1
ffffffffc0200948:	fbc68693          	addi	a3,a3,-68 # ffffffffc0201900 <etext+0x29e>
ffffffffc020094c:	00001617          	auipc	a2,0x1
ffffffffc0200950:	f8460613          	addi	a2,a2,-124 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200954:	11800593          	li	a1,280
ffffffffc0200958:	00001517          	auipc	a0,0x1
ffffffffc020095c:	f9050513          	addi	a0,a0,-112 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200960:	863ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200964:	00001697          	auipc	a3,0x1
ffffffffc0200968:	02c68693          	addi	a3,a3,44 # ffffffffc0201990 <etext+0x32e>
ffffffffc020096c:	00001617          	auipc	a2,0x1
ffffffffc0200970:	f6460613          	addi	a2,a2,-156 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200974:	0e400593          	li	a1,228
ffffffffc0200978:	00001517          	auipc	a0,0x1
ffffffffc020097c:	f7050513          	addi	a0,a0,-144 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200980:	843ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200984:	00001697          	auipc	a3,0x1
ffffffffc0200988:	03468693          	addi	a3,a3,52 # ffffffffc02019b8 <etext+0x356>
ffffffffc020098c:	00001617          	auipc	a2,0x1
ffffffffc0200990:	f4460613          	addi	a2,a2,-188 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200994:	0e500593          	li	a1,229
ffffffffc0200998:	00001517          	auipc	a0,0x1
ffffffffc020099c:	f5050513          	addi	a0,a0,-176 # ffffffffc02018e8 <etext+0x286>
ffffffffc02009a0:	823ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009a4:	00001697          	auipc	a3,0x1
ffffffffc02009a8:	05468693          	addi	a3,a3,84 # ffffffffc02019f8 <etext+0x396>
ffffffffc02009ac:	00001617          	auipc	a2,0x1
ffffffffc02009b0:	f2460613          	addi	a2,a2,-220 # ffffffffc02018d0 <etext+0x26e>
ffffffffc02009b4:	0e700593          	li	a1,231
ffffffffc02009b8:	00001517          	auipc	a0,0x1
ffffffffc02009bc:	f3050513          	addi	a0,a0,-208 # ffffffffc02018e8 <etext+0x286>
ffffffffc02009c0:	803ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009c4:	00001697          	auipc	a3,0x1
ffffffffc02009c8:	0bc68693          	addi	a3,a3,188 # ffffffffc0201a80 <etext+0x41e>
ffffffffc02009cc:	00001617          	auipc	a2,0x1
ffffffffc02009d0:	f0460613          	addi	a2,a2,-252 # ffffffffc02018d0 <etext+0x26e>
ffffffffc02009d4:	10000593          	li	a1,256
ffffffffc02009d8:	00001517          	auipc	a0,0x1
ffffffffc02009dc:	f1050513          	addi	a0,a0,-240 # ffffffffc02018e8 <etext+0x286>
ffffffffc02009e0:	fe2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009e4:	00001697          	auipc	a3,0x1
ffffffffc02009e8:	f8c68693          	addi	a3,a3,-116 # ffffffffc0201970 <etext+0x30e>
ffffffffc02009ec:	00001617          	auipc	a2,0x1
ffffffffc02009f0:	ee460613          	addi	a2,a2,-284 # ffffffffc02018d0 <etext+0x26e>
ffffffffc02009f4:	0e200593          	li	a1,226
ffffffffc02009f8:	00001517          	auipc	a0,0x1
ffffffffc02009fc:	ef050513          	addi	a0,a0,-272 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200a00:	fc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200a04:	00001697          	auipc	a3,0x1
ffffffffc0200a08:	1ac68693          	addi	a3,a3,428 # ffffffffc0201bb0 <etext+0x54e>
ffffffffc0200a0c:	00001617          	auipc	a2,0x1
ffffffffc0200a10:	ec460613          	addi	a2,a2,-316 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200a14:	15a00593          	li	a1,346
ffffffffc0200a18:	00001517          	auipc	a0,0x1
ffffffffc0200a1c:	ed050513          	addi	a0,a0,-304 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200a20:	fa2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a24:	00001697          	auipc	a3,0x1
ffffffffc0200a28:	eec68693          	addi	a3,a3,-276 # ffffffffc0201910 <etext+0x2ae>
ffffffffc0200a2c:	00001617          	auipc	a2,0x1
ffffffffc0200a30:	ea460613          	addi	a2,a2,-348 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200a34:	11b00593          	li	a1,283
ffffffffc0200a38:	00001517          	auipc	a0,0x1
ffffffffc0200a3c:	eb050513          	addi	a0,a0,-336 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200a40:	f82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a44:	00001697          	auipc	a3,0x1
ffffffffc0200a48:	f0c68693          	addi	a3,a3,-244 # ffffffffc0201950 <etext+0x2ee>
ffffffffc0200a4c:	00001617          	auipc	a2,0x1
ffffffffc0200a50:	e8460613          	addi	a2,a2,-380 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200a54:	0e100593          	li	a1,225
ffffffffc0200a58:	00001517          	auipc	a0,0x1
ffffffffc0200a5c:	e9050513          	addi	a0,a0,-368 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200a60:	f62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a64:	00001697          	auipc	a3,0x1
ffffffffc0200a68:	ecc68693          	addi	a3,a3,-308 # ffffffffc0201930 <etext+0x2ce>
ffffffffc0200a6c:	00001617          	auipc	a2,0x1
ffffffffc0200a70:	e6460613          	addi	a2,a2,-412 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200a74:	0e000593          	li	a1,224
ffffffffc0200a78:	00001517          	auipc	a0,0x1
ffffffffc0200a7c:	e7050513          	addi	a0,a0,-400 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200a80:	f42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a84:	00001697          	auipc	a3,0x1
ffffffffc0200a88:	fd468693          	addi	a3,a3,-44 # ffffffffc0201a58 <etext+0x3f6>
ffffffffc0200a8c:	00001617          	auipc	a2,0x1
ffffffffc0200a90:	e4460613          	addi	a2,a2,-444 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200a94:	0fd00593          	li	a1,253
ffffffffc0200a98:	00001517          	auipc	a0,0x1
ffffffffc0200a9c:	e5050513          	addi	a0,a0,-432 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200aa0:	f22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aa4:	00001697          	auipc	a3,0x1
ffffffffc0200aa8:	ecc68693          	addi	a3,a3,-308 # ffffffffc0201970 <etext+0x30e>
ffffffffc0200aac:	00001617          	auipc	a2,0x1
ffffffffc0200ab0:	e2460613          	addi	a2,a2,-476 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200ab4:	0fb00593          	li	a1,251
ffffffffc0200ab8:	00001517          	auipc	a0,0x1
ffffffffc0200abc:	e3050513          	addi	a0,a0,-464 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200ac0:	f02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ac4:	00001697          	auipc	a3,0x1
ffffffffc0200ac8:	e8c68693          	addi	a3,a3,-372 # ffffffffc0201950 <etext+0x2ee>
ffffffffc0200acc:	00001617          	auipc	a2,0x1
ffffffffc0200ad0:	e0460613          	addi	a2,a2,-508 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200ad4:	0fa00593          	li	a1,250
ffffffffc0200ad8:	00001517          	auipc	a0,0x1
ffffffffc0200adc:	e1050513          	addi	a0,a0,-496 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200ae0:	ee2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ae4:	00001697          	auipc	a3,0x1
ffffffffc0200ae8:	e4c68693          	addi	a3,a3,-436 # ffffffffc0201930 <etext+0x2ce>
ffffffffc0200aec:	00001617          	auipc	a2,0x1
ffffffffc0200af0:	de460613          	addi	a2,a2,-540 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200af4:	0f900593          	li	a1,249
ffffffffc0200af8:	00001517          	auipc	a0,0x1
ffffffffc0200afc:	df050513          	addi	a0,a0,-528 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200b00:	ec2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200b04:	00001697          	auipc	a3,0x1
ffffffffc0200b08:	f6c68693          	addi	a3,a3,-148 # ffffffffc0201a70 <etext+0x40e>
ffffffffc0200b0c:	00001617          	auipc	a2,0x1
ffffffffc0200b10:	dc460613          	addi	a2,a2,-572 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200b14:	0f700593          	li	a1,247
ffffffffc0200b18:	00001517          	auipc	a0,0x1
ffffffffc0200b1c:	dd050513          	addi	a0,a0,-560 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200b20:	ea2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b24:	00001697          	auipc	a3,0x1
ffffffffc0200b28:	f3468693          	addi	a3,a3,-204 # ffffffffc0201a58 <etext+0x3f6>
ffffffffc0200b2c:	00001617          	auipc	a2,0x1
ffffffffc0200b30:	da460613          	addi	a2,a2,-604 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200b34:	0f200593          	li	a1,242
ffffffffc0200b38:	00001517          	auipc	a0,0x1
ffffffffc0200b3c:	db050513          	addi	a0,a0,-592 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200b40:	e82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b44:	00001697          	auipc	a3,0x1
ffffffffc0200b48:	ef468693          	addi	a3,a3,-268 # ffffffffc0201a38 <etext+0x3d6>
ffffffffc0200b4c:	00001617          	auipc	a2,0x1
ffffffffc0200b50:	d8460613          	addi	a2,a2,-636 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200b54:	0e900593          	li	a1,233
ffffffffc0200b58:	00001517          	auipc	a0,0x1
ffffffffc0200b5c:	d9050513          	addi	a0,a0,-624 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200b60:	e62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b64:	00001697          	auipc	a3,0x1
ffffffffc0200b68:	eb468693          	addi	a3,a3,-332 # ffffffffc0201a18 <etext+0x3b6>
ffffffffc0200b6c:	00001617          	auipc	a2,0x1
ffffffffc0200b70:	d6460613          	addi	a2,a2,-668 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200b74:	0e800593          	li	a1,232
ffffffffc0200b78:	00001517          	auipc	a0,0x1
ffffffffc0200b7c:	d7050513          	addi	a0,a0,-656 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200b80:	e42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200b84:	00001697          	auipc	a3,0x1
ffffffffc0200b88:	01c68693          	addi	a3,a3,28 # ffffffffc0201ba0 <etext+0x53e>
ffffffffc0200b8c:	00001617          	auipc	a2,0x1
ffffffffc0200b90:	d4460613          	addi	a2,a2,-700 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200b94:	15900593          	li	a1,345
ffffffffc0200b98:	00001517          	auipc	a0,0x1
ffffffffc0200b9c:	d5050513          	addi	a0,a0,-688 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200ba0:	e22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200ba4:	00001697          	auipc	a3,0x1
ffffffffc0200ba8:	f1468693          	addi	a3,a3,-236 # ffffffffc0201ab8 <etext+0x456>
ffffffffc0200bac:	00001617          	auipc	a2,0x1
ffffffffc0200bb0:	d2460613          	addi	a2,a2,-732 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200bb4:	14e00593          	li	a1,334
ffffffffc0200bb8:	00001517          	auipc	a0,0x1
ffffffffc0200bbc:	d3050513          	addi	a0,a0,-720 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200bc0:	e02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bc4:	00001697          	auipc	a3,0x1
ffffffffc0200bc8:	e9468693          	addi	a3,a3,-364 # ffffffffc0201a58 <etext+0x3f6>
ffffffffc0200bcc:	00001617          	auipc	a2,0x1
ffffffffc0200bd0:	d0460613          	addi	a2,a2,-764 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200bd4:	14800593          	li	a1,328
ffffffffc0200bd8:	00001517          	auipc	a0,0x1
ffffffffc0200bdc:	d1050513          	addi	a0,a0,-752 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200be0:	de2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200be4:	00001697          	auipc	a3,0x1
ffffffffc0200be8:	f9c68693          	addi	a3,a3,-100 # ffffffffc0201b80 <etext+0x51e>
ffffffffc0200bec:	00001617          	auipc	a2,0x1
ffffffffc0200bf0:	ce460613          	addi	a2,a2,-796 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200bf4:	14700593          	li	a1,327
ffffffffc0200bf8:	00001517          	auipc	a0,0x1
ffffffffc0200bfc:	cf050513          	addi	a0,a0,-784 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200c00:	dc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c04:	00001697          	auipc	a3,0x1
ffffffffc0200c08:	f6c68693          	addi	a3,a3,-148 # ffffffffc0201b70 <etext+0x50e>
ffffffffc0200c0c:	00001617          	auipc	a2,0x1
ffffffffc0200c10:	cc460613          	addi	a2,a2,-828 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200c14:	13f00593          	li	a1,319
ffffffffc0200c18:	00001517          	auipc	a0,0x1
ffffffffc0200c1c:	cd050513          	addi	a0,a0,-816 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200c20:	da2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c24:	00001697          	auipc	a3,0x1
ffffffffc0200c28:	f3468693          	addi	a3,a3,-204 # ffffffffc0201b58 <etext+0x4f6>
ffffffffc0200c2c:	00001617          	auipc	a2,0x1
ffffffffc0200c30:	ca460613          	addi	a2,a2,-860 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200c34:	13e00593          	li	a1,318
ffffffffc0200c38:	00001517          	auipc	a0,0x1
ffffffffc0200c3c:	cb050513          	addi	a0,a0,-848 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200c40:	d82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c44:	00001697          	auipc	a3,0x1
ffffffffc0200c48:	ef468693          	addi	a3,a3,-268 # ffffffffc0201b38 <etext+0x4d6>
ffffffffc0200c4c:	00001617          	auipc	a2,0x1
ffffffffc0200c50:	c8460613          	addi	a2,a2,-892 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200c54:	13d00593          	li	a1,317
ffffffffc0200c58:	00001517          	auipc	a0,0x1
ffffffffc0200c5c:	c9050513          	addi	a0,a0,-880 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200c60:	d62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c64:	00001697          	auipc	a3,0x1
ffffffffc0200c68:	ea468693          	addi	a3,a3,-348 # ffffffffc0201b08 <etext+0x4a6>
ffffffffc0200c6c:	00001617          	auipc	a2,0x1
ffffffffc0200c70:	c6460613          	addi	a2,a2,-924 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200c74:	13b00593          	li	a1,315
ffffffffc0200c78:	00001517          	auipc	a0,0x1
ffffffffc0200c7c:	c7050513          	addi	a0,a0,-912 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200c80:	d42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c84:	00001697          	auipc	a3,0x1
ffffffffc0200c88:	e6c68693          	addi	a3,a3,-404 # ffffffffc0201af0 <etext+0x48e>
ffffffffc0200c8c:	00001617          	auipc	a2,0x1
ffffffffc0200c90:	c4460613          	addi	a2,a2,-956 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200c94:	13a00593          	li	a1,314
ffffffffc0200c98:	00001517          	auipc	a0,0x1
ffffffffc0200c9c:	c5050513          	addi	a0,a0,-944 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200ca0:	d22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ca4:	00001697          	auipc	a3,0x1
ffffffffc0200ca8:	db468693          	addi	a3,a3,-588 # ffffffffc0201a58 <etext+0x3f6>
ffffffffc0200cac:	00001617          	auipc	a2,0x1
ffffffffc0200cb0:	c2460613          	addi	a2,a2,-988 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200cb4:	12e00593          	li	a1,302
ffffffffc0200cb8:	00001517          	auipc	a0,0x1
ffffffffc0200cbc:	c3050513          	addi	a0,a0,-976 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200cc0:	d02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cc4:	00001697          	auipc	a3,0x1
ffffffffc0200cc8:	e1468693          	addi	a3,a3,-492 # ffffffffc0201ad8 <etext+0x476>
ffffffffc0200ccc:	00001617          	auipc	a2,0x1
ffffffffc0200cd0:	c0460613          	addi	a2,a2,-1020 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200cd4:	12500593          	li	a1,293
ffffffffc0200cd8:	00001517          	auipc	a0,0x1
ffffffffc0200cdc:	c1050513          	addi	a0,a0,-1008 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200ce0:	ce2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200ce4:	00001697          	auipc	a3,0x1
ffffffffc0200ce8:	de468693          	addi	a3,a3,-540 # ffffffffc0201ac8 <etext+0x466>
ffffffffc0200cec:	00001617          	auipc	a2,0x1
ffffffffc0200cf0:	be460613          	addi	a2,a2,-1052 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200cf4:	12400593          	li	a1,292
ffffffffc0200cf8:	00001517          	auipc	a0,0x1
ffffffffc0200cfc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200d00:	cc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200d04:	00001697          	auipc	a3,0x1
ffffffffc0200d08:	db468693          	addi	a3,a3,-588 # ffffffffc0201ab8 <etext+0x456>
ffffffffc0200d0c:	00001617          	auipc	a2,0x1
ffffffffc0200d10:	bc460613          	addi	a2,a2,-1084 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200d14:	10600593          	li	a1,262
ffffffffc0200d18:	00001517          	auipc	a0,0x1
ffffffffc0200d1c:	bd050513          	addi	a0,a0,-1072 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200d20:	ca2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d24:	00001697          	auipc	a3,0x1
ffffffffc0200d28:	d3468693          	addi	a3,a3,-716 # ffffffffc0201a58 <etext+0x3f6>
ffffffffc0200d2c:	00001617          	auipc	a2,0x1
ffffffffc0200d30:	ba460613          	addi	a2,a2,-1116 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200d34:	10400593          	li	a1,260
ffffffffc0200d38:	00001517          	auipc	a0,0x1
ffffffffc0200d3c:	bb050513          	addi	a0,a0,-1104 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200d40:	c82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d44:	00001697          	auipc	a3,0x1
ffffffffc0200d48:	d5468693          	addi	a3,a3,-684 # ffffffffc0201a98 <etext+0x436>
ffffffffc0200d4c:	00001617          	auipc	a2,0x1
ffffffffc0200d50:	b8460613          	addi	a2,a2,-1148 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200d54:	10300593          	li	a1,259
ffffffffc0200d58:	00001517          	auipc	a0,0x1
ffffffffc0200d5c:	b9050513          	addi	a0,a0,-1136 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200d60:	c62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d64 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d64:	1141                	addi	sp,sp,-16
ffffffffc0200d66:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d68:	14058c63          	beqz	a1,ffffffffc0200ec0 <best_fit_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0200d6c:	00259693          	slli	a3,a1,0x2
ffffffffc0200d70:	96ae                	add	a3,a3,a1
ffffffffc0200d72:	068e                	slli	a3,a3,0x3
ffffffffc0200d74:	96aa                	add	a3,a3,a0
ffffffffc0200d76:	87aa                	mv	a5,a0
ffffffffc0200d78:	00d50e63          	beq	a0,a3,ffffffffc0200d94 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d7c:	6798                	ld	a4,8(a5)
ffffffffc0200d7e:	8b0d                	andi	a4,a4,3
ffffffffc0200d80:	12071063          	bnez	a4,ffffffffc0200ea0 <best_fit_free_pages+0x13c>
        p->flags = 0;
ffffffffc0200d84:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d88:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d8c:	02878793          	addi	a5,a5,40
ffffffffc0200d90:	fed796e3          	bne	a5,a3,ffffffffc0200d7c <best_fit_free_pages+0x18>
SetPageProperty(base);
ffffffffc0200d94:	00853883          	ld	a7,8(a0)
nr_free += n;
ffffffffc0200d98:	00004697          	auipc	a3,0x4
ffffffffc0200d9c:	28068693          	addi	a3,a3,640 # ffffffffc0205018 <free_area>
ffffffffc0200da0:	4a98                	lw	a4,16(a3)
base->property = n;
ffffffffc0200da2:	2581                	sext.w	a1,a1
SetPageProperty(base);
ffffffffc0200da4:	0028e613          	ori	a2,a7,2
    return list->next == list;
ffffffffc0200da8:	669c                	ld	a5,8(a3)
base->property = n;
ffffffffc0200daa:	c90c                	sw	a1,16(a0)
SetPageProperty(base);
ffffffffc0200dac:	e510                	sd	a2,8(a0)
nr_free += n;
ffffffffc0200dae:	9f2d                	addw	a4,a4,a1
ffffffffc0200db0:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200db2:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200db6:	0ad78b63          	beq	a5,a3,ffffffffc0200e6c <best_fit_free_pages+0x108>
            struct Page* page = le2page(le, page_link);
ffffffffc0200dba:	fe878713          	addi	a4,a5,-24
ffffffffc0200dbe:	0006b303          	ld	t1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200dc2:	4801                	li	a6,0
            if (base < page) {
ffffffffc0200dc4:	00e56a63          	bltu	a0,a4,ffffffffc0200dd8 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200dc8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200dca:	06d70563          	beq	a4,a3,ffffffffc0200e34 <best_fit_free_pages+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0200dce:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200dd0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dd4:	fee57ae3          	bgeu	a0,a4,ffffffffc0200dc8 <best_fit_free_pages+0x64>
ffffffffc0200dd8:	00080463          	beqz	a6,ffffffffc0200de0 <best_fit_free_pages+0x7c>
ffffffffc0200ddc:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200de0:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200de4:	e390                	sd	a2,0(a5)
ffffffffc0200de6:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc0200dea:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200dec:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200df0:	02d80463          	beq	a6,a3,ffffffffc0200e18 <best_fit_free_pages+0xb4>
    if (p + p->property == base) {
ffffffffc0200df4:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200df8:	fe880313          	addi	t1,a6,-24
    if (p + p->property == base) {
ffffffffc0200dfc:	020e1613          	slli	a2,t3,0x20
ffffffffc0200e00:	9201                	srli	a2,a2,0x20
ffffffffc0200e02:	00261713          	slli	a4,a2,0x2
ffffffffc0200e06:	9732                	add	a4,a4,a2
ffffffffc0200e08:	070e                	slli	a4,a4,0x3
ffffffffc0200e0a:	971a                	add	a4,a4,t1
ffffffffc0200e0c:	02e50e63          	beq	a0,a4,ffffffffc0200e48 <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200e10:	00d78f63          	beq	a5,a3,ffffffffc0200e2e <best_fit_free_pages+0xca>
ffffffffc0200e14:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc0200e18:	490c                	lw	a1,16(a0)
ffffffffc0200e1a:	02059613          	slli	a2,a1,0x20
ffffffffc0200e1e:	9201                	srli	a2,a2,0x20
ffffffffc0200e20:	00261693          	slli	a3,a2,0x2
ffffffffc0200e24:	96b2                	add	a3,a3,a2
ffffffffc0200e26:	068e                	slli	a3,a3,0x3
ffffffffc0200e28:	96aa                	add	a3,a3,a0
ffffffffc0200e2a:	04d70863          	beq	a4,a3,ffffffffc0200e7a <best_fit_free_pages+0x116>
}
ffffffffc0200e2e:	60a2                	ld	ra,8(sp)
ffffffffc0200e30:	0141                	addi	sp,sp,16
ffffffffc0200e32:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e34:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e36:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e38:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e3a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3c:	02d70463          	beq	a4,a3,ffffffffc0200e64 <best_fit_free_pages+0x100>
    prev->next = next->prev = elm;
ffffffffc0200e40:	8332                	mv	t1,a2
ffffffffc0200e42:	4805                	li	a6,1
    for (; p != base + n; p ++) {
ffffffffc0200e44:	87ba                	mv	a5,a4
ffffffffc0200e46:	b769                	j	ffffffffc0200dd0 <best_fit_free_pages+0x6c>
        p->property += base->property;
ffffffffc0200e48:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e4c:	feb82c23          	sw	a1,-8(a6)
        ClearPageProperty(base);
ffffffffc0200e50:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e54:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e58:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e5c:	0107b023          	sd	a6,0(a5)
        base = p;
ffffffffc0200e60:	851a                	mv	a0,t1
ffffffffc0200e62:	b77d                	j	ffffffffc0200e10 <best_fit_free_pages+0xac>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e64:	883e                	mv	a6,a5
ffffffffc0200e66:	e290                	sd	a2,0(a3)
ffffffffc0200e68:	87b6                	mv	a5,a3
ffffffffc0200e6a:	b769                	j	ffffffffc0200df4 <best_fit_free_pages+0x90>
}
ffffffffc0200e6c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200e6e:	e390                	sd	a2,0(a5)
ffffffffc0200e70:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e72:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e74:	ed1c                	sd	a5,24(a0)
ffffffffc0200e76:	0141                	addi	sp,sp,16
ffffffffc0200e78:	8082                	ret
            base->property += p->property;
ffffffffc0200e7a:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e7e:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e82:	0007b803          	ld	a6,0(a5)
ffffffffc0200e86:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e88:	9db5                	addw	a1,a1,a3
ffffffffc0200e8a:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200e8c:	9b75                	andi	a4,a4,-3
ffffffffc0200e8e:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e92:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e94:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e98:	01063023          	sd	a6,0(a2)
ffffffffc0200e9c:	0141                	addi	sp,sp,16
ffffffffc0200e9e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ea0:	00001697          	auipc	a3,0x1
ffffffffc0200ea4:	d2068693          	addi	a3,a3,-736 # ffffffffc0201bc0 <etext+0x55e>
ffffffffc0200ea8:	00001617          	auipc	a2,0x1
ffffffffc0200eac:	a2860613          	addi	a2,a2,-1496 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200eb0:	09900593          	li	a1,153
ffffffffc0200eb4:	00001517          	auipc	a0,0x1
ffffffffc0200eb8:	a3450513          	addi	a0,a0,-1484 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200ebc:	b06ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200ec0:	00001697          	auipc	a3,0x1
ffffffffc0200ec4:	a0868693          	addi	a3,a3,-1528 # ffffffffc02018c8 <etext+0x266>
ffffffffc0200ec8:	00001617          	auipc	a2,0x1
ffffffffc0200ecc:	a0860613          	addi	a2,a2,-1528 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200ed0:	09600593          	li	a1,150
ffffffffc0200ed4:	00001517          	auipc	a0,0x1
ffffffffc0200ed8:	a1450513          	addi	a0,a0,-1516 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200edc:	ae6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200ee0 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200ee0:	1141                	addi	sp,sp,-16
ffffffffc0200ee2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ee4:	c5f9                	beqz	a1,ffffffffc0200fb2 <best_fit_init_memmap+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0200ee6:	00259693          	slli	a3,a1,0x2
ffffffffc0200eea:	96ae                	add	a3,a3,a1
ffffffffc0200eec:	068e                	slli	a3,a3,0x3
ffffffffc0200eee:	96aa                	add	a3,a3,a0
ffffffffc0200ef0:	87aa                	mv	a5,a0
ffffffffc0200ef2:	00d50f63          	beq	a0,a3,ffffffffc0200f10 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200ef6:	6798                	ld	a4,8(a5)
ffffffffc0200ef8:	8b05                	andi	a4,a4,1
ffffffffc0200efa:	cf41                	beqz	a4,ffffffffc0200f92 <best_fit_init_memmap+0xb2>
        p->flags = 0;  // 清空标志
ffffffffc0200efc:	0007b423          	sd	zero,8(a5)
        p->property = 0;  // 清空属性
ffffffffc0200f00:	0007a823          	sw	zero,16(a5)
ffffffffc0200f04:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f08:	02878793          	addi	a5,a5,40
ffffffffc0200f0c:	fed795e3          	bne	a5,a3,ffffffffc0200ef6 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f10:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f12:	00004697          	auipc	a3,0x4
ffffffffc0200f16:	10668693          	addi	a3,a3,262 # ffffffffc0205018 <free_area>
ffffffffc0200f1a:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f1c:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200f1e:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc0200f22:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200f24:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f26:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f28:	9db9                	addw	a1,a1,a4
ffffffffc0200f2a:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f2c:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200f30:	04d78a63          	beq	a5,a3,ffffffffc0200f84 <best_fit_init_memmap+0xa4>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f34:	fe878713          	addi	a4,a5,-24
ffffffffc0200f38:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f3c:	4581                	li	a1,0
            if (base < page) {
ffffffffc0200f3e:	00e56a63          	bltu	a0,a4,ffffffffc0200f52 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200f42:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200f44:	02d70263          	beq	a4,a3,ffffffffc0200f68 <best_fit_init_memmap+0x88>
    for (; p != base + n; p ++) {
ffffffffc0200f48:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f4a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f4e:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f42 <best_fit_init_memmap+0x62>
ffffffffc0200f52:	c199                	beqz	a1,ffffffffc0200f58 <best_fit_init_memmap+0x78>
ffffffffc0200f54:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f58:	6398                	ld	a4,0(a5)
}
ffffffffc0200f5a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f5c:	e390                	sd	a2,0(a5)
ffffffffc0200f5e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200f60:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f62:	ed18                	sd	a4,24(a0)
ffffffffc0200f64:	0141                	addi	sp,sp,16
ffffffffc0200f66:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200f68:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f6a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200f6c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200f6e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f70:	00d70663          	beq	a4,a3,ffffffffc0200f7c <best_fit_init_memmap+0x9c>
    prev->next = next->prev = elm;
ffffffffc0200f74:	8832                	mv	a6,a2
ffffffffc0200f76:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0200f78:	87ba                	mv	a5,a4
ffffffffc0200f7a:	bfc1                	j	ffffffffc0200f4a <best_fit_init_memmap+0x6a>
}
ffffffffc0200f7c:	60a2                	ld	ra,8(sp)
ffffffffc0200f7e:	e290                	sd	a2,0(a3)
ffffffffc0200f80:	0141                	addi	sp,sp,16
ffffffffc0200f82:	8082                	ret
ffffffffc0200f84:	60a2                	ld	ra,8(sp)
ffffffffc0200f86:	e390                	sd	a2,0(a5)
ffffffffc0200f88:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f8a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f8c:	ed1c                	sd	a5,24(a0)
ffffffffc0200f8e:	0141                	addi	sp,sp,16
ffffffffc0200f90:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f92:	00001697          	auipc	a3,0x1
ffffffffc0200f96:	c5668693          	addi	a3,a3,-938 # ffffffffc0201be8 <etext+0x586>
ffffffffc0200f9a:	00001617          	auipc	a2,0x1
ffffffffc0200f9e:	93660613          	addi	a2,a2,-1738 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200fa2:	04a00593          	li	a1,74
ffffffffc0200fa6:	00001517          	auipc	a0,0x1
ffffffffc0200faa:	94250513          	addi	a0,a0,-1726 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200fae:	a14ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200fb2:	00001697          	auipc	a3,0x1
ffffffffc0200fb6:	91668693          	addi	a3,a3,-1770 # ffffffffc02018c8 <etext+0x266>
ffffffffc0200fba:	00001617          	auipc	a2,0x1
ffffffffc0200fbe:	91660613          	addi	a2,a2,-1770 # ffffffffc02018d0 <etext+0x26e>
ffffffffc0200fc2:	04700593          	li	a1,71
ffffffffc0200fc6:	00001517          	auipc	a0,0x1
ffffffffc0200fca:	92250513          	addi	a0,a0,-1758 # ffffffffc02018e8 <etext+0x286>
ffffffffc0200fce:	9f4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200fd2 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200fd2:	00004797          	auipc	a5,0x4
ffffffffc0200fd6:	0867b783          	ld	a5,134(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200fda:	6f9c                	ld	a5,24(a5)
ffffffffc0200fdc:	8782                	jr	a5

ffffffffc0200fde <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200fde:	00004797          	auipc	a5,0x4
ffffffffc0200fe2:	07a7b783          	ld	a5,122(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200fe6:	739c                	ld	a5,32(a5)
ffffffffc0200fe8:	8782                	jr	a5

ffffffffc0200fea <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200fea:	00004797          	auipc	a5,0x4
ffffffffc0200fee:	06e7b783          	ld	a5,110(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200ff2:	779c                	ld	a5,40(a5)
ffffffffc0200ff4:	8782                	jr	a5

ffffffffc0200ff6 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200ff6:	00001797          	auipc	a5,0x1
ffffffffc0200ffa:	c1a78793          	addi	a5,a5,-998 # ffffffffc0201c10 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ffe:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201000:	7179                	addi	sp,sp,-48
ffffffffc0201002:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201004:	00001517          	auipc	a0,0x1
ffffffffc0201008:	c4450513          	addi	a0,a0,-956 # ffffffffc0201c48 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020100c:	00004417          	auipc	s0,0x4
ffffffffc0201010:	04c40413          	addi	s0,s0,76 # ffffffffc0205058 <pmm_manager>
void pmm_init(void) {
ffffffffc0201014:	f406                	sd	ra,40(sp)
ffffffffc0201016:	ec26                	sd	s1,24(sp)
ffffffffc0201018:	e44e                	sd	s3,8(sp)
ffffffffc020101a:	e84a                	sd	s2,16(sp)
ffffffffc020101c:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020101e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201020:	92cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0201024:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201026:	00004497          	auipc	s1,0x4
ffffffffc020102a:	04a48493          	addi	s1,s1,74 # ffffffffc0205070 <va_pa_offset>
    pmm_manager->init();
ffffffffc020102e:	679c                	ld	a5,8(a5)
ffffffffc0201030:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201032:	57f5                	li	a5,-3
ffffffffc0201034:	07fa                	slli	a5,a5,0x1e
ffffffffc0201036:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201038:	d84ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc020103c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020103e:	d88ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201042:	14050d63          	beqz	a0,ffffffffc020119c <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201046:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201048:	00001517          	auipc	a0,0x1
ffffffffc020104c:	c4850513          	addi	a0,a0,-952 # ffffffffc0201c90 <best_fit_pmm_manager+0x80>
ffffffffc0201050:	8fcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201054:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201058:	864e                	mv	a2,s3
ffffffffc020105a:	fffa0693          	addi	a3,s4,-1
ffffffffc020105e:	85ca                	mv	a1,s2
ffffffffc0201060:	00001517          	auipc	a0,0x1
ffffffffc0201064:	c4850513          	addi	a0,a0,-952 # ffffffffc0201ca8 <best_fit_pmm_manager+0x98>
ffffffffc0201068:	8e4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020106c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201070:	8652                	mv	a2,s4
ffffffffc0201072:	0d47e463          	bltu	a5,s4,ffffffffc020113a <pmm_init+0x144>
ffffffffc0201076:	00005797          	auipc	a5,0x5
ffffffffc020107a:	00178793          	addi	a5,a5,1 # ffffffffc0206077 <end+0xfff>
ffffffffc020107e:	757d                	lui	a0,0xfffff
ffffffffc0201080:	8d7d                	and	a0,a0,a5
ffffffffc0201082:	8231                	srli	a2,a2,0xc
ffffffffc0201084:	00004797          	auipc	a5,0x4
ffffffffc0201088:	fcc7b223          	sd	a2,-60(a5) # ffffffffc0205048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020108c:	00004797          	auipc	a5,0x4
ffffffffc0201090:	fca7b223          	sd	a0,-60(a5) # ffffffffc0205050 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201094:	000807b7          	lui	a5,0x80
ffffffffc0201098:	002005b7          	lui	a1,0x200
ffffffffc020109c:	02f60563          	beq	a2,a5,ffffffffc02010c6 <pmm_init+0xd0>
ffffffffc02010a0:	00261593          	slli	a1,a2,0x2
ffffffffc02010a4:	00c586b3          	add	a3,a1,a2
ffffffffc02010a8:	fec007b7          	lui	a5,0xfec00
ffffffffc02010ac:	97aa                	add	a5,a5,a0
ffffffffc02010ae:	068e                	slli	a3,a3,0x3
ffffffffc02010b0:	96be                	add	a3,a3,a5
ffffffffc02010b2:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc02010b4:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010b6:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc02010ba:	00176713          	ori	a4,a4,1
ffffffffc02010be:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010c2:	fef699e3          	bne	a3,a5,ffffffffc02010b4 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c6:	95b2                	add	a1,a1,a2
ffffffffc02010c8:	fec006b7          	lui	a3,0xfec00
ffffffffc02010cc:	96aa                	add	a3,a3,a0
ffffffffc02010ce:	058e                	slli	a1,a1,0x3
ffffffffc02010d0:	96ae                	add	a3,a3,a1
ffffffffc02010d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02010d6:	0af6e763          	bltu	a3,a5,ffffffffc0201184 <pmm_init+0x18e>
ffffffffc02010da:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02010dc:	77fd                	lui	a5,0xfffff
ffffffffc02010de:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010e2:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010e4:	04b6ee63          	bltu	a3,a1,ffffffffc0201140 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010e8:	601c                	ld	a5,0(s0)
ffffffffc02010ea:	7b9c                	ld	a5,48(a5)
ffffffffc02010ec:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010ee:	00001517          	auipc	a0,0x1
ffffffffc02010f2:	c4250513          	addi	a0,a0,-958 # ffffffffc0201d30 <best_fit_pmm_manager+0x120>
ffffffffc02010f6:	856ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010fa:	00003597          	auipc	a1,0x3
ffffffffc02010fe:	f0658593          	addi	a1,a1,-250 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0201102:	00004797          	auipc	a5,0x4
ffffffffc0201106:	f6b7b323          	sd	a1,-154(a5) # ffffffffc0205068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020110a:	c02007b7          	lui	a5,0xc0200
ffffffffc020110e:	0af5e363          	bltu	a1,a5,ffffffffc02011b4 <pmm_init+0x1be>
ffffffffc0201112:	6090                	ld	a2,0(s1)
}
ffffffffc0201114:	7402                	ld	s0,32(sp)
ffffffffc0201116:	70a2                	ld	ra,40(sp)
ffffffffc0201118:	64e2                	ld	s1,24(sp)
ffffffffc020111a:	6942                	ld	s2,16(sp)
ffffffffc020111c:	69a2                	ld	s3,8(sp)
ffffffffc020111e:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201120:	40c58633          	sub	a2,a1,a2
ffffffffc0201124:	00004797          	auipc	a5,0x4
ffffffffc0201128:	f2c7be23          	sd	a2,-196(a5) # ffffffffc0205060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020112c:	00001517          	auipc	a0,0x1
ffffffffc0201130:	c2450513          	addi	a0,a0,-988 # ffffffffc0201d50 <best_fit_pmm_manager+0x140>
}
ffffffffc0201134:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201136:	816ff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020113a:	c8000637          	lui	a2,0xc8000
ffffffffc020113e:	bf25                	j	ffffffffc0201076 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201140:	6705                	lui	a4,0x1
ffffffffc0201142:	177d                	addi	a4,a4,-1
ffffffffc0201144:	96ba                	add	a3,a3,a4
ffffffffc0201146:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201148:	00c6d793          	srli	a5,a3,0xc
ffffffffc020114c:	02c7f063          	bgeu	a5,a2,ffffffffc020116c <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0201150:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201152:	fff80737          	lui	a4,0xfff80
ffffffffc0201156:	973e                	add	a4,a4,a5
ffffffffc0201158:	00271793          	slli	a5,a4,0x2
ffffffffc020115c:	97ba                	add	a5,a5,a4
ffffffffc020115e:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201160:	8d95                	sub	a1,a1,a3
ffffffffc0201162:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201164:	81b1                	srli	a1,a1,0xc
ffffffffc0201166:	953e                	add	a0,a0,a5
ffffffffc0201168:	9702                	jalr	a4
}
ffffffffc020116a:	bfbd                	j	ffffffffc02010e8 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc020116c:	00001617          	auipc	a2,0x1
ffffffffc0201170:	b9460613          	addi	a2,a2,-1132 # ffffffffc0201d00 <best_fit_pmm_manager+0xf0>
ffffffffc0201174:	06a00593          	li	a1,106
ffffffffc0201178:	00001517          	auipc	a0,0x1
ffffffffc020117c:	ba850513          	addi	a0,a0,-1112 # ffffffffc0201d20 <best_fit_pmm_manager+0x110>
ffffffffc0201180:	842ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201184:	00001617          	auipc	a2,0x1
ffffffffc0201188:	b5460613          	addi	a2,a2,-1196 # ffffffffc0201cd8 <best_fit_pmm_manager+0xc8>
ffffffffc020118c:	05f00593          	li	a1,95
ffffffffc0201190:	00001517          	auipc	a0,0x1
ffffffffc0201194:	af050513          	addi	a0,a0,-1296 # ffffffffc0201c80 <best_fit_pmm_manager+0x70>
ffffffffc0201198:	82aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc020119c:	00001617          	auipc	a2,0x1
ffffffffc02011a0:	ac460613          	addi	a2,a2,-1340 # ffffffffc0201c60 <best_fit_pmm_manager+0x50>
ffffffffc02011a4:	04700593          	li	a1,71
ffffffffc02011a8:	00001517          	auipc	a0,0x1
ffffffffc02011ac:	ad850513          	addi	a0,a0,-1320 # ffffffffc0201c80 <best_fit_pmm_manager+0x70>
ffffffffc02011b0:	812ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011b4:	86ae                	mv	a3,a1
ffffffffc02011b6:	00001617          	auipc	a2,0x1
ffffffffc02011ba:	b2260613          	addi	a2,a2,-1246 # ffffffffc0201cd8 <best_fit_pmm_manager+0xc8>
ffffffffc02011be:	07a00593          	li	a1,122
ffffffffc02011c2:	00001517          	auipc	a0,0x1
ffffffffc02011c6:	abe50513          	addi	a0,a0,-1346 # ffffffffc0201c80 <best_fit_pmm_manager+0x70>
ffffffffc02011ca:	ff9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02011ce <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02011ce:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011d2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02011d4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011d8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011da:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011de:	f022                	sd	s0,32(sp)
ffffffffc02011e0:	ec26                	sd	s1,24(sp)
ffffffffc02011e2:	e84a                	sd	s2,16(sp)
ffffffffc02011e4:	f406                	sd	ra,40(sp)
ffffffffc02011e6:	e44e                	sd	s3,8(sp)
ffffffffc02011e8:	84aa                	mv	s1,a0
ffffffffc02011ea:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011ec:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02011f0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02011f2:	03067e63          	bgeu	a2,a6,ffffffffc020122e <printnum+0x60>
ffffffffc02011f6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02011f8:	00805763          	blez	s0,ffffffffc0201206 <printnum+0x38>
ffffffffc02011fc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02011fe:	85ca                	mv	a1,s2
ffffffffc0201200:	854e                	mv	a0,s3
ffffffffc0201202:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201204:	fc65                	bnez	s0,ffffffffc02011fc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201206:	1a02                	slli	s4,s4,0x20
ffffffffc0201208:	00001797          	auipc	a5,0x1
ffffffffc020120c:	b8878793          	addi	a5,a5,-1144 # ffffffffc0201d90 <best_fit_pmm_manager+0x180>
ffffffffc0201210:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201214:	9a3e                	add	s4,s4,a5
}
ffffffffc0201216:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201218:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020121c:	70a2                	ld	ra,40(sp)
ffffffffc020121e:	69a2                	ld	s3,8(sp)
ffffffffc0201220:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201222:	85ca                	mv	a1,s2
ffffffffc0201224:	87a6                	mv	a5,s1
}
ffffffffc0201226:	6942                	ld	s2,16(sp)
ffffffffc0201228:	64e2                	ld	s1,24(sp)
ffffffffc020122a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020122c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020122e:	03065633          	divu	a2,a2,a6
ffffffffc0201232:	8722                	mv	a4,s0
ffffffffc0201234:	f9bff0ef          	jal	ra,ffffffffc02011ce <printnum>
ffffffffc0201238:	b7f9                	j	ffffffffc0201206 <printnum+0x38>

ffffffffc020123a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020123a:	7119                	addi	sp,sp,-128
ffffffffc020123c:	f4a6                	sd	s1,104(sp)
ffffffffc020123e:	f0ca                	sd	s2,96(sp)
ffffffffc0201240:	ecce                	sd	s3,88(sp)
ffffffffc0201242:	e8d2                	sd	s4,80(sp)
ffffffffc0201244:	e4d6                	sd	s5,72(sp)
ffffffffc0201246:	e0da                	sd	s6,64(sp)
ffffffffc0201248:	fc5e                	sd	s7,56(sp)
ffffffffc020124a:	f06a                	sd	s10,32(sp)
ffffffffc020124c:	fc86                	sd	ra,120(sp)
ffffffffc020124e:	f8a2                	sd	s0,112(sp)
ffffffffc0201250:	f862                	sd	s8,48(sp)
ffffffffc0201252:	f466                	sd	s9,40(sp)
ffffffffc0201254:	ec6e                	sd	s11,24(sp)
ffffffffc0201256:	892a                	mv	s2,a0
ffffffffc0201258:	84ae                	mv	s1,a1
ffffffffc020125a:	8d32                	mv	s10,a2
ffffffffc020125c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020125e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201262:	5b7d                	li	s6,-1
ffffffffc0201264:	00001a97          	auipc	s5,0x1
ffffffffc0201268:	b60a8a93          	addi	s5,s5,-1184 # ffffffffc0201dc4 <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020126c:	00001b97          	auipc	s7,0x1
ffffffffc0201270:	d34b8b93          	addi	s7,s7,-716 # ffffffffc0201fa0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201274:	000d4503          	lbu	a0,0(s10)
ffffffffc0201278:	001d0413          	addi	s0,s10,1
ffffffffc020127c:	01350a63          	beq	a0,s3,ffffffffc0201290 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201280:	c121                	beqz	a0,ffffffffc02012c0 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201282:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201284:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201286:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201288:	fff44503          	lbu	a0,-1(s0)
ffffffffc020128c:	ff351ae3          	bne	a0,s3,ffffffffc0201280 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201290:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201294:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201298:	4c81                	li	s9,0
ffffffffc020129a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020129c:	5c7d                	li	s8,-1
ffffffffc020129e:	5dfd                	li	s11,-1
ffffffffc02012a0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02012a4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012a6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02012aa:	0ff5f593          	zext.b	a1,a1
ffffffffc02012ae:	00140d13          	addi	s10,s0,1
ffffffffc02012b2:	04b56263          	bltu	a0,a1,ffffffffc02012f6 <vprintfmt+0xbc>
ffffffffc02012b6:	058a                	slli	a1,a1,0x2
ffffffffc02012b8:	95d6                	add	a1,a1,s5
ffffffffc02012ba:	4194                	lw	a3,0(a1)
ffffffffc02012bc:	96d6                	add	a3,a3,s5
ffffffffc02012be:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02012c0:	70e6                	ld	ra,120(sp)
ffffffffc02012c2:	7446                	ld	s0,112(sp)
ffffffffc02012c4:	74a6                	ld	s1,104(sp)
ffffffffc02012c6:	7906                	ld	s2,96(sp)
ffffffffc02012c8:	69e6                	ld	s3,88(sp)
ffffffffc02012ca:	6a46                	ld	s4,80(sp)
ffffffffc02012cc:	6aa6                	ld	s5,72(sp)
ffffffffc02012ce:	6b06                	ld	s6,64(sp)
ffffffffc02012d0:	7be2                	ld	s7,56(sp)
ffffffffc02012d2:	7c42                	ld	s8,48(sp)
ffffffffc02012d4:	7ca2                	ld	s9,40(sp)
ffffffffc02012d6:	7d02                	ld	s10,32(sp)
ffffffffc02012d8:	6de2                	ld	s11,24(sp)
ffffffffc02012da:	6109                	addi	sp,sp,128
ffffffffc02012dc:	8082                	ret
            padc = '0';
ffffffffc02012de:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02012e0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e4:	846a                	mv	s0,s10
ffffffffc02012e6:	00140d13          	addi	s10,s0,1
ffffffffc02012ea:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02012ee:	0ff5f593          	zext.b	a1,a1
ffffffffc02012f2:	fcb572e3          	bgeu	a0,a1,ffffffffc02012b6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02012f6:	85a6                	mv	a1,s1
ffffffffc02012f8:	02500513          	li	a0,37
ffffffffc02012fc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02012fe:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201302:	8d22                	mv	s10,s0
ffffffffc0201304:	f73788e3          	beq	a5,s3,ffffffffc0201274 <vprintfmt+0x3a>
ffffffffc0201308:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020130c:	1d7d                	addi	s10,s10,-1
ffffffffc020130e:	ff379de3          	bne	a5,s3,ffffffffc0201308 <vprintfmt+0xce>
ffffffffc0201312:	b78d                	j	ffffffffc0201274 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201314:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201318:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020131c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020131e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201322:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201326:	02d86463          	bltu	a6,a3,ffffffffc020134e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020132a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020132e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201332:	0186873b          	addw	a4,a3,s8
ffffffffc0201336:	0017171b          	slliw	a4,a4,0x1
ffffffffc020133a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020133c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201340:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201342:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201346:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020134a:	fed870e3          	bgeu	a6,a3,ffffffffc020132a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020134e:	f40ddce3          	bgez	s11,ffffffffc02012a6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201352:	8de2                	mv	s11,s8
ffffffffc0201354:	5c7d                	li	s8,-1
ffffffffc0201356:	bf81                	j	ffffffffc02012a6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201358:	fffdc693          	not	a3,s11
ffffffffc020135c:	96fd                	srai	a3,a3,0x3f
ffffffffc020135e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201362:	00144603          	lbu	a2,1(s0)
ffffffffc0201366:	2d81                	sext.w	s11,s11
ffffffffc0201368:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020136a:	bf35                	j	ffffffffc02012a6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020136c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201370:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201374:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201376:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201378:	bfd9                	j	ffffffffc020134e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020137a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020137c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201380:	01174463          	blt	a4,a7,ffffffffc0201388 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201384:	1a088e63          	beqz	a7,ffffffffc0201540 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201388:	000a3603          	ld	a2,0(s4)
ffffffffc020138c:	46c1                	li	a3,16
ffffffffc020138e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201390:	2781                	sext.w	a5,a5
ffffffffc0201392:	876e                	mv	a4,s11
ffffffffc0201394:	85a6                	mv	a1,s1
ffffffffc0201396:	854a                	mv	a0,s2
ffffffffc0201398:	e37ff0ef          	jal	ra,ffffffffc02011ce <printnum>
            break;
ffffffffc020139c:	bde1                	j	ffffffffc0201274 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020139e:	000a2503          	lw	a0,0(s4)
ffffffffc02013a2:	85a6                	mv	a1,s1
ffffffffc02013a4:	0a21                	addi	s4,s4,8
ffffffffc02013a6:	9902                	jalr	s2
            break;
ffffffffc02013a8:	b5f1                	j	ffffffffc0201274 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013aa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013ac:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013b0:	01174463          	blt	a4,a7,ffffffffc02013b8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02013b4:	18088163          	beqz	a7,ffffffffc0201536 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02013b8:	000a3603          	ld	a2,0(s4)
ffffffffc02013bc:	46a9                	li	a3,10
ffffffffc02013be:	8a2e                	mv	s4,a1
ffffffffc02013c0:	bfc1                	j	ffffffffc0201390 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013c2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02013c6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013c8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013ca:	bdf1                	j	ffffffffc02012a6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02013cc:	85a6                	mv	a1,s1
ffffffffc02013ce:	02500513          	li	a0,37
ffffffffc02013d2:	9902                	jalr	s2
            break;
ffffffffc02013d4:	b545                	j	ffffffffc0201274 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013d6:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02013da:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013dc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013de:	b5e1                	j	ffffffffc02012a6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02013e0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013e2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013e6:	01174463          	blt	a4,a7,ffffffffc02013ee <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02013ea:	14088163          	beqz	a7,ffffffffc020152c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02013ee:	000a3603          	ld	a2,0(s4)
ffffffffc02013f2:	46a1                	li	a3,8
ffffffffc02013f4:	8a2e                	mv	s4,a1
ffffffffc02013f6:	bf69                	j	ffffffffc0201390 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02013f8:	03000513          	li	a0,48
ffffffffc02013fc:	85a6                	mv	a1,s1
ffffffffc02013fe:	e03e                	sd	a5,0(sp)
ffffffffc0201400:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201402:	85a6                	mv	a1,s1
ffffffffc0201404:	07800513          	li	a0,120
ffffffffc0201408:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020140a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020140c:	6782                	ld	a5,0(sp)
ffffffffc020140e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201410:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201414:	bfb5                	j	ffffffffc0201390 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201416:	000a3403          	ld	s0,0(s4)
ffffffffc020141a:	008a0713          	addi	a4,s4,8
ffffffffc020141e:	e03a                	sd	a4,0(sp)
ffffffffc0201420:	14040263          	beqz	s0,ffffffffc0201564 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201424:	0fb05763          	blez	s11,ffffffffc0201512 <vprintfmt+0x2d8>
ffffffffc0201428:	02d00693          	li	a3,45
ffffffffc020142c:	0cd79163          	bne	a5,a3,ffffffffc02014ee <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201430:	00044783          	lbu	a5,0(s0)
ffffffffc0201434:	0007851b          	sext.w	a0,a5
ffffffffc0201438:	cf85                	beqz	a5,ffffffffc0201470 <vprintfmt+0x236>
ffffffffc020143a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020143e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201442:	000c4563          	bltz	s8,ffffffffc020144c <vprintfmt+0x212>
ffffffffc0201446:	3c7d                	addiw	s8,s8,-1
ffffffffc0201448:	036c0263          	beq	s8,s6,ffffffffc020146c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020144c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020144e:	0e0c8e63          	beqz	s9,ffffffffc020154a <vprintfmt+0x310>
ffffffffc0201452:	3781                	addiw	a5,a5,-32
ffffffffc0201454:	0ef47b63          	bgeu	s0,a5,ffffffffc020154a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201458:	03f00513          	li	a0,63
ffffffffc020145c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020145e:	000a4783          	lbu	a5,0(s4)
ffffffffc0201462:	3dfd                	addiw	s11,s11,-1
ffffffffc0201464:	0a05                	addi	s4,s4,1
ffffffffc0201466:	0007851b          	sext.w	a0,a5
ffffffffc020146a:	ffe1                	bnez	a5,ffffffffc0201442 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020146c:	01b05963          	blez	s11,ffffffffc020147e <vprintfmt+0x244>
ffffffffc0201470:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201472:	85a6                	mv	a1,s1
ffffffffc0201474:	02000513          	li	a0,32
ffffffffc0201478:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020147a:	fe0d9be3          	bnez	s11,ffffffffc0201470 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020147e:	6a02                	ld	s4,0(sp)
ffffffffc0201480:	bbd5                	j	ffffffffc0201274 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201482:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201484:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201488:	01174463          	blt	a4,a7,ffffffffc0201490 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020148c:	08088d63          	beqz	a7,ffffffffc0201526 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201490:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201494:	0a044d63          	bltz	s0,ffffffffc020154e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201498:	8622                	mv	a2,s0
ffffffffc020149a:	8a66                	mv	s4,s9
ffffffffc020149c:	46a9                	li	a3,10
ffffffffc020149e:	bdcd                	j	ffffffffc0201390 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02014a0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014a4:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02014a6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02014a8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02014ac:	8fb5                	xor	a5,a5,a3
ffffffffc02014ae:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014b2:	02d74163          	blt	a4,a3,ffffffffc02014d4 <vprintfmt+0x29a>
ffffffffc02014b6:	00369793          	slli	a5,a3,0x3
ffffffffc02014ba:	97de                	add	a5,a5,s7
ffffffffc02014bc:	639c                	ld	a5,0(a5)
ffffffffc02014be:	cb99                	beqz	a5,ffffffffc02014d4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02014c0:	86be                	mv	a3,a5
ffffffffc02014c2:	00001617          	auipc	a2,0x1
ffffffffc02014c6:	8fe60613          	addi	a2,a2,-1794 # ffffffffc0201dc0 <best_fit_pmm_manager+0x1b0>
ffffffffc02014ca:	85a6                	mv	a1,s1
ffffffffc02014cc:	854a                	mv	a0,s2
ffffffffc02014ce:	0ce000ef          	jal	ra,ffffffffc020159c <printfmt>
ffffffffc02014d2:	b34d                	j	ffffffffc0201274 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02014d4:	00001617          	auipc	a2,0x1
ffffffffc02014d8:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0201db0 <best_fit_pmm_manager+0x1a0>
ffffffffc02014dc:	85a6                	mv	a1,s1
ffffffffc02014de:	854a                	mv	a0,s2
ffffffffc02014e0:	0bc000ef          	jal	ra,ffffffffc020159c <printfmt>
ffffffffc02014e4:	bb41                	j	ffffffffc0201274 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02014e6:	00001417          	auipc	s0,0x1
ffffffffc02014ea:	8c240413          	addi	s0,s0,-1854 # ffffffffc0201da8 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014ee:	85e2                	mv	a1,s8
ffffffffc02014f0:	8522                	mv	a0,s0
ffffffffc02014f2:	e43e                	sd	a5,8(sp)
ffffffffc02014f4:	0fc000ef          	jal	ra,ffffffffc02015f0 <strnlen>
ffffffffc02014f8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02014fc:	01b05b63          	blez	s11,ffffffffc0201512 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201500:	67a2                	ld	a5,8(sp)
ffffffffc0201502:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201506:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201508:	85a6                	mv	a1,s1
ffffffffc020150a:	8552                	mv	a0,s4
ffffffffc020150c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020150e:	fe0d9ce3          	bnez	s11,ffffffffc0201506 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201512:	00044783          	lbu	a5,0(s0)
ffffffffc0201516:	00140a13          	addi	s4,s0,1
ffffffffc020151a:	0007851b          	sext.w	a0,a5
ffffffffc020151e:	d3a5                	beqz	a5,ffffffffc020147e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201520:	05e00413          	li	s0,94
ffffffffc0201524:	bf39                	j	ffffffffc0201442 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201526:	000a2403          	lw	s0,0(s4)
ffffffffc020152a:	b7ad                	j	ffffffffc0201494 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020152c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201530:	46a1                	li	a3,8
ffffffffc0201532:	8a2e                	mv	s4,a1
ffffffffc0201534:	bdb1                	j	ffffffffc0201390 <vprintfmt+0x156>
ffffffffc0201536:	000a6603          	lwu	a2,0(s4)
ffffffffc020153a:	46a9                	li	a3,10
ffffffffc020153c:	8a2e                	mv	s4,a1
ffffffffc020153e:	bd89                	j	ffffffffc0201390 <vprintfmt+0x156>
ffffffffc0201540:	000a6603          	lwu	a2,0(s4)
ffffffffc0201544:	46c1                	li	a3,16
ffffffffc0201546:	8a2e                	mv	s4,a1
ffffffffc0201548:	b5a1                	j	ffffffffc0201390 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020154a:	9902                	jalr	s2
ffffffffc020154c:	bf09                	j	ffffffffc020145e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020154e:	85a6                	mv	a1,s1
ffffffffc0201550:	02d00513          	li	a0,45
ffffffffc0201554:	e03e                	sd	a5,0(sp)
ffffffffc0201556:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201558:	6782                	ld	a5,0(sp)
ffffffffc020155a:	8a66                	mv	s4,s9
ffffffffc020155c:	40800633          	neg	a2,s0
ffffffffc0201560:	46a9                	li	a3,10
ffffffffc0201562:	b53d                	j	ffffffffc0201390 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201564:	03b05163          	blez	s11,ffffffffc0201586 <vprintfmt+0x34c>
ffffffffc0201568:	02d00693          	li	a3,45
ffffffffc020156c:	f6d79de3          	bne	a5,a3,ffffffffc02014e6 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201570:	00001417          	auipc	s0,0x1
ffffffffc0201574:	83840413          	addi	s0,s0,-1992 # ffffffffc0201da8 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201578:	02800793          	li	a5,40
ffffffffc020157c:	02800513          	li	a0,40
ffffffffc0201580:	00140a13          	addi	s4,s0,1
ffffffffc0201584:	bd6d                	j	ffffffffc020143e <vprintfmt+0x204>
ffffffffc0201586:	00001a17          	auipc	s4,0x1
ffffffffc020158a:	823a0a13          	addi	s4,s4,-2013 # ffffffffc0201da9 <best_fit_pmm_manager+0x199>
ffffffffc020158e:	02800513          	li	a0,40
ffffffffc0201592:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201596:	05e00413          	li	s0,94
ffffffffc020159a:	b565                	j	ffffffffc0201442 <vprintfmt+0x208>

ffffffffc020159c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020159c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020159e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015a2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015a4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015a6:	ec06                	sd	ra,24(sp)
ffffffffc02015a8:	f83a                	sd	a4,48(sp)
ffffffffc02015aa:	fc3e                	sd	a5,56(sp)
ffffffffc02015ac:	e0c2                	sd	a6,64(sp)
ffffffffc02015ae:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02015b0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015b2:	c89ff0ef          	jal	ra,ffffffffc020123a <vprintfmt>
}
ffffffffc02015b6:	60e2                	ld	ra,24(sp)
ffffffffc02015b8:	6161                	addi	sp,sp,80
ffffffffc02015ba:	8082                	ret

ffffffffc02015bc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02015bc:	4781                	li	a5,0
ffffffffc02015be:	00004717          	auipc	a4,0x4
ffffffffc02015c2:	a5273703          	ld	a4,-1454(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02015c6:	88ba                	mv	a7,a4
ffffffffc02015c8:	852a                	mv	a0,a0
ffffffffc02015ca:	85be                	mv	a1,a5
ffffffffc02015cc:	863e                	mv	a2,a5
ffffffffc02015ce:	00000073          	ecall
ffffffffc02015d2:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015d4:	8082                	ret

ffffffffc02015d6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02015d6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02015da:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02015dc:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02015de:	cb81                	beqz	a5,ffffffffc02015ee <strlen+0x18>
        cnt ++;
ffffffffc02015e0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02015e2:	00a707b3          	add	a5,a4,a0
ffffffffc02015e6:	0007c783          	lbu	a5,0(a5)
ffffffffc02015ea:	fbfd                	bnez	a5,ffffffffc02015e0 <strlen+0xa>
ffffffffc02015ec:	8082                	ret
    }
    return cnt;
}
ffffffffc02015ee:	8082                	ret

ffffffffc02015f0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02015f0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015f2:	e589                	bnez	a1,ffffffffc02015fc <strnlen+0xc>
ffffffffc02015f4:	a811                	j	ffffffffc0201608 <strnlen+0x18>
        cnt ++;
ffffffffc02015f6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015f8:	00f58863          	beq	a1,a5,ffffffffc0201608 <strnlen+0x18>
ffffffffc02015fc:	00f50733          	add	a4,a0,a5
ffffffffc0201600:	00074703          	lbu	a4,0(a4)
ffffffffc0201604:	fb6d                	bnez	a4,ffffffffc02015f6 <strnlen+0x6>
ffffffffc0201606:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201608:	852e                	mv	a0,a1
ffffffffc020160a:	8082                	ret

ffffffffc020160c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020160c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201610:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201614:	cb89                	beqz	a5,ffffffffc0201626 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201616:	0505                	addi	a0,a0,1
ffffffffc0201618:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020161a:	fee789e3          	beq	a5,a4,ffffffffc020160c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020161e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201622:	9d19                	subw	a0,a0,a4
ffffffffc0201624:	8082                	ret
ffffffffc0201626:	4501                	li	a0,0
ffffffffc0201628:	bfed                	j	ffffffffc0201622 <strcmp+0x16>

ffffffffc020162a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020162a:	c20d                	beqz	a2,ffffffffc020164c <strncmp+0x22>
ffffffffc020162c:	962e                	add	a2,a2,a1
ffffffffc020162e:	a031                	j	ffffffffc020163a <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201630:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201632:	00e79a63          	bne	a5,a4,ffffffffc0201646 <strncmp+0x1c>
ffffffffc0201636:	00b60b63          	beq	a2,a1,ffffffffc020164c <strncmp+0x22>
ffffffffc020163a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020163e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201640:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201644:	f7f5                	bnez	a5,ffffffffc0201630 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201646:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020164a:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020164c:	4501                	li	a0,0
ffffffffc020164e:	8082                	ret

ffffffffc0201650 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201650:	ca01                	beqz	a2,ffffffffc0201660 <memset+0x10>
ffffffffc0201652:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201654:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201656:	0785                	addi	a5,a5,1
ffffffffc0201658:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020165c:	fec79de3          	bne	a5,a2,ffffffffc0201656 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201660:	8082                	ret
