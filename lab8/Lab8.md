## Lab8

## 练习1: 完成读文件操作的实现（需要编码）

首先了解打开文件的处理流程，然后参考本实验后续的文件读写操作的过程分析，填写在 kern/fs/sfs/sfs_inode.c中 的sfs_io_nolock()函数，实现读文件中数据的代码。

**打开文件的处理流程（open 系统调用）：**

`open` 系统调用的执行流程跨越了三个主要层次：通用文件访问接口层、文件系统抽象层 (VFS) 和 具体文件系统层 (SFS)。

- 通用文件访问接口层

  经过`syscall.c`的处理之后，进入内核态，执行`sysfile_open()`，调用 `copy_path` 将用户空间传递的路径字符串 `__path` 拷贝到内核空间的 `path` 中，随后调用 `file_open` 进入下一层处理。

- 文件系统抽象层 VFS

   `file_open` -> `fd_array_alloc` 在当前进程的打开文件表`fd_array`中分配一个空闲的  `struct file` ，此时 `struct file` 里的 `node` 指针还是 NULL，之后调用 `vfs_open`，试图找到文件对应的 inode-> `vfs_open`调用`vfs_lookup` ，`vfs_lookup` 首先调用 `get_device`。如果路径包含设备前缀，则找到该设备的根 inode；否则从当前工作目录（cwd）开始，之后调用 `vop_lookup`，这是一个宏，如果当前文件系统是 SFS，它实际上会调用 `sfs_lookup`。

- 文件系统层 SFS

  `sfs_lookup` 调用 `sfs_lookup_once`->`sfs_dirent_search_nolock`，读取目录文件数据块，逐个比对 `sfs_disk_entry`目录项，寻找匹配的文件名，匹配成功，拿到该文件对应的 inode 编号 `ino`，之后通过`sfs_load_inode`在内存中分配一个 `struct inode`并填入信息，最后，`vfs_open` 终于可以带着找到的 `inode` 返回到 `file_open`，执行 `file->node = node;`将 file 和 node 绑定，设置文件状态为打开状态，最终返回文件描述符 fd。

最终，系统调用结束，用户进程拿到了一个整数 fd。自此，用户进程后续就可以通过这个 fd，索引到内核中的 file 结构，进而找到 inode，对文件进行读写操作。

**读文件的处理流程 （read 系统调用）：**

用户进程：`read(fd, data, len);`

- 通用文件访问接口层

  `read->sys_read->sysfile_read(fd, base, len)`

- 文件系统抽象层 VFS

  `sysfile_read` 循环读取文件，计算循环要读多少，取 `len` 和 `IOBUF_SIZE` 的较小值作为`alen`，调用下一层的 `file_read`，将数据从磁盘读入内核的 `buffer`，之后调用调用 `copy_to_user(mm, base, buffer, alen)`，将内核 `buffer` 里的数据拷贝到用户空间的 `base` 地址，重复直到读完所有数据。

  `file_read` 函数：调用 `fd2file(fd, &file)`拿到对应的 `struct file` 结构体，之后初始化`struct iobuf`，调用 `vop_read(file->node, iob)`进行读文件。

- 文件系统层 SFS

  `vop_read`->`sfs_read`->`sfs_io`->`sfs_io_nolock`读文件。

- 设备I/O层

  经过层层调用最后将磁盘数据真正搬运到内存中。

练习1即为`sfs_io_nolock`的实现：



## 练习2: 完成基于文件系统的执行程序机制的实现（需要编码）

改写proc.c中的load_icode函数和其他相关函数，实现基于文件系统的执行程序机制。执行：make qemu。如果能看看到sh用户程序的执行界面，则基本成功了。如果在sh用户界面上可以执行`exit`, `hello`（更多用户程序放在`user`目录下）等其他放置在`sfs`文件系统中的其他执行程序，则可以认为本实验基本成功。

## 扩展练习 Challenge1：完成基于“UNIX的PIPE机制”的设计方案

如果要在ucore里加入UNIX的管道（Pipe）机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的PIPE机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

## 扩展练习 Challenge2：完成基于“UNIX的软连接和硬连接机制”的设计方案

如果要在ucore里加入UNIX的软连接和硬连接机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的软连接和硬连接机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）