#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddysystem_pmm.h>
#include <stdio.h>
#define MAX_ORDER 11  // 最大的内存块阶层（表示最大内存块大小为2^10，即1024）

// 每个阶层对应的空闲内存块链表
static free_area_t free_area[MAX_ORDER];  // 每个阶层存储对应的空闲块链表和空闲块数量

// 宏定义，方便访问指定阶层的空闲链表和空闲块数量
#define free_list(i) free_area[(i)].free_list
#define nr_free(i) free_area[(i)].nr_free

// 判断一个数字是否是2的幂
int IS_POWER_OF_2(int num)
{
    return num > 0 && !(num & (num - 1));  // 如果num是2的幂次方返回真
}

// 初始化指定阶层的空闲内存块链表
static void init_free_area(int order)
{
    list_init(&(free_area[order].free_list));  // 初始化链表为空
    free_area[order].nr_free = 0;              // 空闲块数量初始化为0
}

// 初始化整个伙伴系统，初始化所有阶层的空闲内存块链表
static void buddy_system_init(void)
{
    for (int i = 0; i < MAX_ORDER; i++)
    {
        init_free_area(i);  // 调用init_free_area初始化每一阶层
    }
}

// 初始化物理内存映射，将物理内存页加入到伙伴系统管理中
static void buddy_system_init_memmap(struct Page* base, size_t n)
{
    assert(n > 0);  
    struct Page* p = base;

    // 遍历每个页，清除属性和引用计数，确保页被释放
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));     // 页必须被保留
        p->flags = p->property = 0;  // 清除页的标志和属性
        set_page_ref(p, 0);          // 设置引用计数为0
    }

    size_t offset = 0;// 初始化偏移量
    
    // 开始处理每一个页，将其按大小加入伙伴系统
    while (n > 0)
    {
        uint32_t order = 0;  // 用来表示当前块的阶层（2的幂次方的页数）
        // 根据剩余的页数，计算需要分配的内存块的阶层（最大阶层为MAX_ORDER）
        while ((1 << order) <= n && order < MAX_ORDER) { order += 1; }
        if (order > 0) { order -= 1; }  // 将阶层减1，以确保不会超出可分配的最大块大小

        // 获取当前页面，并设置其大小属性
        p = base + offset;  // 计算当前页的地址
        p->property = 1 << order;// 设置当前页面的大小为2的阶层次方
        SetPageProperty(p);// 标记页面的属性为已使用
        
        // 将该页面加入到对应阶层的空闲链表中
        list_add(&(free_list(order)), &(p->page_link));
        nr_free(order) += 1;// 增加该阶层的空闲块数量

        offset += (1 << order);
        n -= (1 << order);
    }
}

// 将较大的内存块拆分为两个较小的块
static void split_page(int order)
{
    assert(order > 0 && order < MAX_ORDER);// 确保 order 在有效范围内：不能为 0，且小于最大阶层 MAX_ORDER

    if (list_empty(&(free_list(order)))) { split_page(order + 1); }// 如果当前阶层的空闲链表为空，递归拆分更大的阶层

    if (list_empty(&(free_list(order)))) { return; }// 如果当前阶层的空闲链表仍然为空，说明无法拆分，直接返回

    list_entry_t* le   = list_next(&(free_list(order)));// 获取当前阶层空闲链表的第一个空闲块 需要拆分他
    struct Page*  page = le2page(le, page_link);// 将链表条目转换为页面结构体
    
    list_del(&(page->page_link));// 从当前阶层的空闲链表中删除该页面
    nr_free(order) -= 1;// 更新该阶层空闲块的数量

    uint32_t size  = 1 << (order - 1);// 计算拆分后每个块的大小：size = 2^(order - 1)
    struct Page* buddy = page + size;// 获取拆分后的另一个伙伴块
    
    // 为拆分后的两个内存块（page 和 buddy）设置 property 标记这两个页面为有效
    page->property  = size;
    buddy->property = size;
    SetPageProperty(page);
    SetPageProperty(buddy);
    // 将拆分出来的两个块加入到较小的阶层空闲链表中
    list_add(&(free_list(order - 1)), &(page->page_link));
    list_add(&(free_list(order - 1)), &(buddy->page_link));
    nr_free(order - 1) += 2;// 更新该阶层空闲块的数量：当前阶层增加两个空闲块
}

// 分配页面
static struct Page* buddy_system_alloc_pages(size_t n)
{
    assert(n > 0);  // 确保要分配的页数大于0
    if (n > (1 << (MAX_ORDER - 1)))
    {                 // 请求的页数超过最大块大小
        return NULL;  // 无法满足请求
    }
    struct Page* page = NULL;// 用来存储将分配的页面

    // 计算需要的最小阶层
    uint32_t order = 0;
    while ((1 << order) < n && order < MAX_ORDER) { order += 1; }// 持续增加阶层直到满足内存请求
    if (order >= MAX_ORDER) { return NULL; }// 如果计算出的阶层大于等于最大阶层，则返回 NULL，表示无法分配

    uint32_t current_order = order;// 设置当前阶层为计算出来的阶层

    // 查找当前阶层是否有空闲块，如果没有，则逐步向上查找更大的阶层
    while (current_order < MAX_ORDER && list_empty(&(free_list(current_order)))) { current_order += 1; }

    if (current_order == MAX_ORDER) { return NULL; }// 如果找到了最大阶层仍然没有可用的内存块，返回 NULL

    // 如果 current_order 大于请求的阶层 order 逐级拆分，直到达到所需的阶层
    while (current_order > order)
    {
        split_page(current_order);
        current_order -= 1;
    }

    // 从空闲链表中获取块
    list_entry_t* le = list_next(&(free_list(order)));
    page = le2page(le, page_link);
    list_del(&(page->page_link));// 将该页面从空闲链表中删除
    nr_free(order) -= 1;// 更新当前阶层空闲块的数量，减少一个
    ClearPageProperty(page);

    return page;// 返回已分配的内存页面
}

// 将内存块插入到指定阶层的空闲链表中
static void add_page(uint32_t order, struct Page* base) 
{ list_add(&(free_list(order)), &(base->page_link)); }

// 合并相邻的伙伴块
static void merge_page(uint32_t order, struct Page* base)
{
    if (order >= MAX_ORDER - 1) // 如果当前阶已经达到或超过最大阶-1，说明无法继续向上合并
    {
        // 当达到最高阶层时，直接将页面添加回空闲链表
        add_page(order, base);// 将块加入当前阶的空闲链表
        nr_free(order) += 1;// 增加当前阶的空闲块计数
        return;// 结束递归
    }

    size_t       size       = 1 << order;// 计算当前阶块的大小（以页为单位）
    uintptr_t    addr       = page2pa(base);// 将页面指针转换为物理地址
    uintptr_t    buddy_addr = addr ^ (size << PGSHIFT);// 计算伙伴块的物理地址：通过异或操作翻转对应位
    struct Page* buddy      = pa2page(buddy_addr);// 将伙伴物理地址转换回页面指针

    if (buddy->property != size || !PageProperty(buddy)) // 检查伙伴块是否满足合并条件
    {
        // 伙伴不可合并 直接将当前块加入空闲链表
        add_page(order, base);
        nr_free(order) += 1;// 增加当前阶空闲块计数
        return;// 结束合并过程
    }

    // 伙伴可以合并，从当前阶层的空闲链表中移除伙伴块
    list_del(&(buddy->page_link));
    ClearPageProperty(buddy);
    nr_free(order) -= 1;

    // 选择地址较小的块作为新的基地址
    if (buddy < base) { base = buddy; }// 如果伙伴地址更小，使用伙伴作为基地址

    // 设置新的属性值
    base->property = size << 1;
    ClearPageProperty(base);

    // 递归合并到更高阶层
    merge_page(order + 1, base);
}

// 释放页面，将其重新加入空闲链表中
static void buddy_system_free_pages(struct Page* base, size_t n)
{
    assert(n > 0);
    assert(IS_POWER_OF_2(n));             // 页数必须是2的幂
    assert(n <= (1 << (MAX_ORDER - 1)));  // 页数不能超过最大阶层的块大小

    struct Page* p = base;
    // 遍历每个页，清除标志位和引用计数
    for (; p != base + n; p++)// 遍历从base到base+n的所有页面
    {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;  // 设置这个空闲块的大小为n页
    SetPageProperty(base);
    uint32_t order = 0;  // 计算对应的阶层
    size_t   temp  = n;
    while (temp > 1)
    {
        temp >>= 1;// 右移1位，相当于除以2
        order++;
    }
    // 尝试合并
    merge_page(order, base);
}

// 返回系统中所有空闲页面的总数量
static size_t buddy_system_nr_free_pages(void)
{
    size_t num = 0;
    for (int i = 0; i < MAX_ORDER; i++)
    {
        num += nr_free(i) * (1 << i);  // 计算每个阶层的空闲页数
    }
    return num;  // 返回总空闲页面数
}

// 伙伴系统检测函数
static void buddy_system_check(void)
{
    cprintf("========== 伙伴系统全面测试开始 ==========\n\n");
    
    size_t initial_free_pages = buddy_system_nr_free_pages();
    cprintf("初始空闲页面数: %d\n", initial_free_pages);
    
    // 测试1：基础单页面分配测试
    cprintf("\n--- 测试1: 基础单页面分配 ---\n");
    struct Page* single_page = buddy_system_alloc_pages(1);
    assert(single_page != NULL);
    cprintf("分配单个页面成功，地址: %p\n", single_page);
    
    size_t after_single_alloc = buddy_system_nr_free_pages();
    cprintf("分配后空闲页面: %d (应减少1页)\n", after_single_alloc);
    assert(after_single_alloc == initial_free_pages - 1);
    
    buddy_system_free_pages(single_page, 1);
    cprintf("释放单个页面成功\n");
    assert(buddy_system_nr_free_pages() == initial_free_pages);
    cprintf(" 基础单页面测试通过\n");
    
    // 测试2：非2的幂次方分配测试
    cprintf("\n--- 测试2: 非2的幂次方分配 ---\n");
    cprintf("测试分配3页（实际应分配4页）\n");
    struct Page* three_pages = buddy_system_alloc_pages(3);
    assert(three_pages != NULL);
    cprintf("分配3页请求成功，实际分配大小: %d页\n", three_pages->property);
    assert(three_pages->property == 4); // 应该向上取整到4页
    
    size_t after_three_alloc = buddy_system_nr_free_pages();
    cprintf("分配后空闲页面: %d (应减少4页)\n", after_three_alloc);
    assert(after_three_alloc == initial_free_pages - 4);
    
    buddy_system_free_pages(three_pages, 4); // 注意：释放4页而不是3页
    cprintf("释放4页成功\n");
    assert(buddy_system_nr_free_pages() == initial_free_pages);
    cprintf(" 非2的幂次方分配测试通过\n");
    
    // 测试3：多种大小混合分配测试
    cprintf("\n--- 测试3: 混合大小分配测试 ---\n");
    struct Page* pages_1 = buddy_system_alloc_pages(1);
    struct Page* pages_2 = buddy_system_alloc_pages(2);
    struct Page* pages_4 = buddy_system_alloc_pages(4);
    struct Page* pages_8 = buddy_system_alloc_pages(8);
    
    assert(pages_1 != NULL && pages_2 != NULL && pages_4 != NULL && pages_8 != NULL);
    cprintf("混合分配成功: 1页@%p, 2页@%p, 4页@%p, 8页@%p\n", 
            pages_1, pages_2, pages_4, pages_8);
    
    size_t after_mixed_alloc = buddy_system_nr_free_pages();
    cprintf("混合分配后空闲页面: %d (应减少15页)\n", after_mixed_alloc);
    assert(after_mixed_alloc == initial_free_pages - 15);
    
    // 乱序释放，测试合并机制
    buddy_system_free_pages(pages_4, 4);
    buddy_system_free_pages(pages_1, 1);
    buddy_system_free_pages(pages_8, 8);
    buddy_system_free_pages(pages_2, 2);
    cprintf("乱序释放所有页面\n");
    
    assert(buddy_system_nr_free_pages() == initial_free_pages);
    cprintf(" 混合分配测试通过\n");
    
    // 测试4：边界情况测试
cprintf("\n--- 测试4: 边界情况测试 ---\n");

// 测试分配超过最大限制
size_t max_allowed = 1 << (MAX_ORDER - 1);
struct Page* too_large = buddy_system_alloc_pages(max_allowed + 1);
assert(too_large == NULL);
cprintf("分配%d页(超限)测试: 正确返回NULL\n", max_allowed + 1);

// 测试精确最大分配
struct Page* max_page = buddy_system_alloc_pages(max_allowed);
assert(max_page != NULL);
cprintf("分配最大%d页测试: 成功\n", max_allowed);

buddy_system_free_pages(max_page, max_allowed);
cprintf("释放最大块成功\n");

cprintf(" 边界情况测试通过\n");
    
    // 测试5：伙伴合并验证测试
    cprintf("\n--- 测试5: 伙伴合并验证测试 ---\n");
    
    // 分配两个相邻的小块，然后释放看是否能合并
    struct Page* buddy1 = buddy_system_alloc_pages(4);
    struct Page* buddy2 = buddy_system_alloc_pages(4);
    
    cprintf("分配两个4页块: %p 和 %p\n", buddy1, buddy2);
    
    // 检查它们是否是伙伴（地址应该相差4页大小）
    uintptr_t addr1 = page2pa(buddy1);
    uintptr_t addr2 = page2pa(buddy2);
    uintptr_t expected_buddy_addr = addr1 ^ (4 << PGSHIFT);
    
    cprintf("块1地址: 0x%x, 块2地址: 0x%x, 期望伙伴地址: 0x%x\n", 
            addr1, addr2, expected_buddy_addr);
    
    // 释放第一个块
    buddy_system_free_pages(buddy1, 4);
    size_t after_first_free = buddy_system_nr_free_pages();
    cprintf("释放第一个4页块，当前空闲: %d\n", after_first_free);
    
    // 释放第二个块，应该触发合并
    buddy_system_free_pages(buddy2, 4);
    size_t after_second_free = buddy_system_nr_free_pages();
    cprintf("释放第二个4页块，当前空闲: %d\n", after_second_free);
    
    // 检查是否成功合并（空闲页面应该完全恢复）
    assert(buddy_system_nr_free_pages() == initial_free_pages);
    cprintf(" 伙伴合并测试通过\n");
    
    // 最终验证
    cprintf("\n========== 最终统计 ===============\n");
    cprintf("初始空闲页面: %d\n", initial_free_pages);
    cprintf("最终空闲页面: %d\n", buddy_system_nr_free_pages());
    cprintf("内存泄漏检查: %s\n", 
            initial_free_pages == buddy_system_nr_free_pages() ? "通过" : "失败");
    
    assert(initial_free_pages == buddy_system_nr_free_pages());
    cprintf("\n 所有伙伴系统测试均通过！\n");
    cprintf("====================================\n");
}

// 定义伙伴系统内存管理结构体
const struct pmm_manager buddy_system_pmm_manager = {
    .name          = "buddy_system_pmm_manager",  // 内存管理器名称
    .init          = buddy_system_init,           // 初始化函数
    .init_memmap   = buddy_system_init_memmap,    // 初始化内存映射函数
    .alloc_pages   = buddy_system_alloc_pages,    // 分配页面函数
    .free_pages    = buddy_system_free_pages,     // 释放页面函数
    .nr_free_pages = buddy_system_nr_free_pages,  // 获取空闲页面数量函数
    .check         = buddy_system_check,          // 检查函数
};
