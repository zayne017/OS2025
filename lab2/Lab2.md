# Lab2

# 练习一 理解 first-fit 连续物理内存分配算法

first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合kern/mm/default_pmm.c中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：

你的first fit算法是否有进一步的改进空间？

first fit算法的主要策略是从空闲链表中找到第一个足够大的空闲块，然后分配请求的内存。default_pmm.c中的代码实现了使用first fit算法的物理内存分配管理器，具体由下面四个函数组成：

**default_init**: 初始化空闲链表free_list并初始化空闲页数nr_free为0。

主要作用是为后续的内存分配操作做准备。它创建一个空的链表，该链表将在后续的内存分配过程中存储空闲页面的地址。

**default_init_memmap**: 初始化一个连续的内存块，并将其插入空闲链表。

具体是将每个页面的标志位flags和属性property都清除，引用计数设置为 0，设置空闲块base的属性，并将其按照地址顺序插入到空闲链表。

**default_alloc_pages**: 使用first fit算法分配空闲内存页。

具体是遍历空闲链表，通过p->property >= n找到第一个足够大的空闲块，如果该空闲块的大小大于请求的内存页面数，则分割该块，后边的剩余部分重新加入空闲链表，然后更新nr_free。

**default_free_pages**: 释放内存页，并尝试与相邻的空闲块合并。

具体是先遍历base 到base+n范围内的页面，恢复到空闲状态，并设置第一个base页的property为n，更新nr_free。再将释放的内存块按照地址顺序插入空闲链表，并判断当前的空闲块是否和前面或后面的空闲块相邻，如果相邻就合并。

**改进空间**：

1.first fit算法可能会导致内存碎片化，因为它始终选择第一个满足要求的空闲块，而不考虑剩余空间的大小，会导致链表中出现很多小的碎片。如果使用best fit算法就可以避免这个问题，不会浪费过多的内存空间。

2.first fit算法需要遍历整个空闲链表，查找合适的内存块随着内存的增长，这个遍历过程可能变得低效，可以考虑使用更高效的数据结构（例如平衡二叉树或堆），以更快地找到合适的空闲块。

3.当前first fit算法中合并空闲块的时机是在释放内存时，为了进一步优化内存利用，可以在分配内存时进行合并操作，避免空闲块的浪费。

# 练习2 实现 Best-Fit 连续物理内存分配算法

在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：

你的 Best-Fit 算法是否有进一步的改进空间？

Best-Fit和First-Fit主要区别在alloc_pages部分，这里需要找到最小连续空闲页框数量并进行分配，而First-Fit只需找到满足大小的第一个空闲块。

**best_fit_init_memmap**:

主要是初始化空闲块并按物理地址递增的顺序插入free_list，这部分和first fit是完全一样的。
```
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        /*LAB2 EXERCISE 2: 2213523*/ 
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        // 这里和first fit完全一样，就是把这里信息清空
        p->flags = 0;  // 清空标志
        p->property = 0;  // 清空属性
        set_page_ref(p, 0);  // 设置引用计数为0
    }
    // base是空闲块头
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    // 若free_list为空，直接插入
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            /*LAB2 EXERCISE 2: 2213523*/ 
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
            // 2) 有序插入 free_list（保持从低地址到高地址）
            // 这里和first fit也是完全一样，就是从头往后遍历空闲链表，按照物理地址有序插入，best fit和first fit的主要区别在后面
            if (base < page) {
            list_add_before(le, &(base->page_link));
            break;
            } else if (list_next(le) == &free_list) {
            list_add(le, &(base->page_link));
            }
        }
    }
}
```

**best_fit_alloc_pages**:
主要思路是，我们顺序查找，通过预先定义的min_size记录最小连续空闲页框数量，如果有页面的property大于等于n并且property小于min_size，我们就用变量page记录改页面，并修改min_size为当前页面的property，如此往复直到循环结束。
此时，我们得到了满足需求的页面page，并且min_size是当前最小连续空闲页框数量。
```c
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
    
    /*LAB2 EXERCISE 2: 2311008*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_size) {
            page = p;
            min_size = p->property;
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

**best_fit_free_pages**:

```
static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: 2310413*/ 
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
                break;
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: YOUR CODE*/ 
        // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

//检查页面既不是保留页也不是空闲页

清除页面标志位

将页面引用计数设为0

设置释放页块属性

 按地址顺序插入空闲链表

合并相邻空闲块：

向前合并：检查与前一个页块是否连续

向后合并：检查与后一个页块是否连续
```
将pmm.c中的pmm_manager更改为best_fit_pmm_manager，通过make grade测试，结果如下

![lab2](./lab2.png)

**改进空间**

我们认为：
1. 可以考虑维护一个块大小的二级索引最小堆，这样在查找满足最小页面时，能将分配时间复杂度降低到$O(logn)$，原时间复杂度为$O(n)$。不过，这增加了空间复杂度和实现难度。
2. 使用内存回收策略，提高内存的利用率。
# Challenge 1 buddy system（伙伴系统）分配算法

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

伙伴分配的实质就是一种特殊的“分离适配”，即将内存按2的幂进行划分，相当于分离出若干个块大小一致的空闲链表，搜索该链表并给出同需求最佳匹配的大小。其优点是快速搜索合并（O(logN)时间复杂度）以及低外部碎片（最佳适配best-fit）；其缺点是内部碎片，因为按2的幂划分块，如果碰上66单位大小，那么必须划分128单位大小的块。但若需求本身就按2的幂分配，比如可以先分配若干个内存池，在其基础上进一步细分就很有吸引力了。

这里用多层的链表实现，`free_area_t` 用于管理每个阶层的空闲内存块链表和空闲块数量，`MAX_ORDER` 表示内存块的最大阶层。

**1.初始化指定阶层的空闲内存块链表，以及整个buddy system**

```
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
```

**2.初始物理内存映射，将物理内存页加入到伙伴系统管理中**

具体是将从base开始的n页进行初始化，首先遍历每个页并清除标志属性，设置引用计数为0，之后初始化偏移量，再通过while循环，根据剩余页数计算需要分配的内存块的阶层，然后初始化，循环直到分配结束。

```
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
```

**3.内存块拆分**

将较大的内存块拆分为两个较小的块，并将这些较小的块添加到相应的空闲链表中，以便之后使用。这个操作通常发生在内存分配时，系统发现当前空闲块比所需的内存块大，因此需要拆分它。

具体是通过递归调用 `split_page(order + 1)`进行拆分，如果即使经过递归拆分后，`free_list(order)` 仍然为空，说明系统已经无法进一步拆分更多的内存块，此时函数直接返回，表示没有足够的空闲块可用。

拆分过程中，首先获取当前阶层的第一个空闲块并拆分，将拆分后的两个块（`page` 和 `buddy`）添加到较小的阶层的空闲链表中，再更新空闲块的数量。

```
// 将较大的内存块拆分为两个较小的块
static void split_page(int order)
{
    assert(order > 0 && order < MAX_ORDER);// 确保 order 在有效范围内：不能为 0，且小于最大阶层 MAX_ORDER

    if (list_empty(&(free_list(order)))) { split_page(order + 1); }// 如果当前阶层的空闲链表为空，递归拆分更大的阶层

    if (list_empty(&(free_list(order)))) { return; }// 如果当前阶层的空闲链表仍然为空，说明无法拆分，直接返回

    list_entry_t* le   = list_next(&(free_list(order)));// 获取当前阶层空闲链表的第一个空闲块
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
```

**4.分配内存页**

根据请求的内存大小n找到适当大小的内存块，必要时将更大的内存块拆分成更小的块，最终从空闲链表中分配合适的内存块。

检查请求是否超出最大限制，之后通过while循环计算所需最小阶层order，然后从order层开始查找空闲块，如果当前阶层没有空闲块，逐步向上查找更大的阶层。如果当前阶层的空闲块大于所需大小，则逐级拆分更大的内存块，直到找到合适大小的内存块，也就是回到当前需要的order层。之后从order层空闲链表中获取第一个空闲块，删除该块并返回给用户使用，更新链表和空闲块数量，最终返回已分配的内存块。

```
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
```

**5.合并相邻内存伙伴块**

如果达到最高阶层，则直接将页面添加到空闲链表并结束递归，如果没有达到最高阶层，就通过`uintptr_t buddy_addr = addr ^ (size << PGSHIFT)`计算伙伴地址并转换回伙伴块指针，再检查伙伴块是否可以合并，如果可以合并就选择地址较小的块作为新的基地址，合并到更高一层，之后递归完成合并。

```
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
```

**6.释放页面**

判断页数必须是2的幂并不超过最大阶层，之后清除标志位和引用计数并设置空闲块，再计算对应阶层并通过`merge_page`进行递归的合并，如果释放后无法合并会直接加入对应层空闲链表，如果可以合并会与伙伴块合并直到无法合并。

```
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
```

**7.检查伙伴系统是否正常运行**

- 测试1：基础单页面分配 

  分配一个页面，检查是否成功，并检查空闲页面数减少1。

  然后释放该页面，检查空闲页面数是否恢复。

- 测试2：非2的幂次方分配测试

  请求3页，实际应该分配4页，并释放

- 测试3：混合大小分配测试

  验证不同大小的块能否正确分配，并验证乱序释放时，伙伴系统能否正确合并，检查是否稳

- 测试4：边界情况测试

  测试最大限制

- 测试5：伙伴合并验证测试

  分配两个相邻小块，之后检查伙伴块能否合并，并释放

通过make qemu测试，最终当所有测试都通过时，说明：

基本功能正常：能正确分配和释放内存

内部碎片处理正确：非2幂请求能向上取整

合并机制有效：小碎片能合并成大块

边界情况安全：非法请求会被拒绝

无内存泄漏：所有内存都能正确回收

# Challenge3 硬件的可用物理内存范围的获取方法

如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

本实验中，机器上电后，首先运行 OpenSBI。OpenSBI 会进行非常底层的硬件初始化，并探测系统的硬件组成。OpenSBI 扮演了 bootloader 的角色。

OpenSBI 根据探测到的硬件信息，在内存中生成一个 DTB 数据结构。

OpenSBI 将控制权移交给操作系统内核时，它会遵循 RISC-V 的调用约定，将 DTB 在物理内存中的起始地址存放在 a1 寄存器中。

操作系统的内核入口代码可以从 a1 寄存器中拿到 DTB 的地址，然后调用设备树解析器来读取。通过解析，内核就知道了物理内存的布局。

现代计算机通常通过BIOS或UEFI提供内存映射表，这些表包含了系统中所有可用和保留的物理内存区域的信息。

操作系统在启动过程中可以使用BIOS提供的中断调用（例如，INT 15h的E820 扩展内存检测）或通过UEFI的GetMemoryMap函数来获取这张内存映射表。这样可以准确地识别可用的物理内存范围。

操作系统可以通过硬件自检（POST）获取物理内存的信息。这通常在系统的启动过程中进行，硬件会检测到物理内存的数量并将其传递给启动引导程序，最终操作系统可以读取这些信息来确定可用的物理内存范围。

高级配置和电源接口（ACPI）标准定义了一系列内存映射表，操作系统可以从这些表中获取可用物理内存区域。ACPI 中的内存描述符包含了所有可用内存的起始地址、长度以及类型。OS 可以根据这些信息来初始化其内存管理模块。
# 知识点总结

1、内存管理：程序直接使用物理地址，会导致：安全冲突：所有程序（包括内核）都在同一个地址空间里，可以互相篡改数据。

内存碎片：程序需要大块的连续物理内存，但系统运行后可用内存会变得支离破碎，即使总空间足够，也无法分配。

页：将物理内存和虚拟内存都划分成固定大小的块（例如 4KB）。这一块连续的内存就是一个“页”。现在，“词典”里的一条记录不再对应1个字节，而是对应一个页（如4KB）。

翻译前：程序使用一个虚拟地址，它属于某个虚拟页。

翻译后：MMU查“词典”，找到这个虚拟页对应哪个物理页，然后访问那个物理页上的数据。

通过这种方式，程序A的 0x80200000 被翻译成了物理地址 0x12340000，而程序B的 0x80200000 却被翻译成了 0x56780000。它们彼此隔离，互不干扰。

2、页表：一个页表项是用来描述一个虚拟页号如何映射到物理页号的。如果一个虚拟页号通过某种手段找到了一个页表项，并通过读取上面的物理页号完成映射，那么我们称这个虚拟页号通过该页表项完成映射。

而我们的”词典“（页表）存储在内存里，由若干个格式固定的”词条“也就是页表项（PTE, Page Table Entry）组成。

多级页表：我们可以对页表进行“分级”，让它变成一个树状结构。也就是把很多页表项组合成一个“大页”，如果这些页表项都非法（没有对应的物理页），那么只需要用一个非法的页表项来覆盖这个大页，而不需要分别建立一大堆非法页表项。很多个大页(megapage)还可以组合起来变成大大页(gigapage!)，继而可以有更大的页。

在 CPU 内部，我们使用快表 (TLB, Translation Lookaside Buffer) 来记录近期已完成的虚拟页号到物理页号的映射。

由于局部性，当我们要做一个映射时，会有很大可能这个映射在近期被完成过，所以我们可以先到 TLB 里面去查一下，如果有的话我们就可以直接完成映射，而不用访问那么多次内存了。

3、要进入虚拟内存访问方式，需要如下步骤：

分配页表所在内存空间并初始化页表；（创建词典，并定义虚拟地址到物理地址的映射关系）

设置好页基址寄存器（指向页表起始地址）；（告诉mmu改用什么词典来翻译地址）

刷新 TLB。（刷新旧的无效地址映射）

4、First Fit算法就是当需要分配页面时，它会从空闲页块链表中找到第一个适合大小的空闲页块，然后进行分配。当释放页面时，它会将释放的页面添加回链表，并在必要时合并相邻的空闲页块，以最大限度地减少内存碎片。













