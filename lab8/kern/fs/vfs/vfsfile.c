#include <defs.h>
#include <string.h>
#include <vfs.h>
#include <inode.h>
#include <unistd.h>
#include <error.h>
#include <assert.h>


// open file in vfs, get/create inode for file with filename path.
int
vfs_open(char *path, uint32_t open_flags, struct inode **node_store) {
    bool can_write = 0;
    switch (open_flags & O_ACCMODE) {
    case O_RDONLY:
        break;
    case O_WRONLY:
    case O_RDWR:
        can_write = 1;
        break;
    default:
        return -E_INVAL;
    }

    if (open_flags & O_TRUNC) {
        if (!can_write) {
            return -E_INVAL;
        }
    }

    int ret; 
    struct inode *node;
    bool excl = (open_flags & O_EXCL) != 0;
    bool create = (open_flags & O_CREAT) != 0;
    // 2. 【核心查找】先去看看这个房间存不存在？
    // vfs_lookup 会去硬盘目录树里找
    ret = vfs_lookup(path, &node);

    if (ret != 0) {// === 分支 A: 文件不存在 ===
        if (ret == -16 && (create)) {
            char *name;
            struct inode *dir;// 3.1 找父目录：要创建 /a/b，得先找到 /a 这个目录(dir)
            if ((ret = vfs_lookup_parent(path, &dir, &name)) != 0) {
                return ret;
            }
            ret = vop_create(dir, name, excl, &node);// 3.2 调用底层接口创建文件
        } else return ret;
    } else if (excl && create) {// === 分支 B: 文件存在 ===
        return -E_EXISTS;// 你说 O_CREAT (我要建新的) 且 O_EXCL (必须只有我一个)
        // 但文件居然已经存在了！那就报错。
    }
    assert(node != NULL);// 到这里，node 肯定拿到了（要么是找回来的，要么是刚建好的）
    // 4. 打开文件
    // 通知底层文件系统/设备：这个文件被打开了（比如增加引用计数）
    if ((ret = vop_open(node, open_flags)) != 0) {
        vop_ref_dec(node);
        return ret;
    }

    vop_open_inc(node);// 5. 处理截断 (O_TRUNC)
    if (open_flags & O_TRUNC || create) {
        if ((ret = vop_truncate(node, 0)) != 0) {
            vop_open_dec(node);
            vop_ref_dec(node);
            return ret;
        }
    }
    *node_store = node;// 6. 交货：把找到的 inode 指针给回上一层
    return 0;
}

// close file in vfs
int
vfs_close(struct inode *node) {
    vop_open_dec(node);
    vop_ref_dec(node);
    return 0;
}

// unimplement
int
vfs_unlink(char *path) {
    return -E_UNIMP;
}

// unimplement
int
vfs_rename(char *old_path, char *new_path) {
    return -E_UNIMP;
}

// unimplement
int
vfs_link(char *old_path, char *new_path) {
    return -E_UNIMP;
}

// unimplement
int
vfs_symlink(char *old_path, char *new_path) {
    return -E_UNIMP;
}

// unimplement
int
vfs_readlink(char *path, struct iobuf *iob) {
    return -E_UNIMP;
}

// unimplement
int
vfs_mkdir(char *path){
    return -E_UNIMP;
}
