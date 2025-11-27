ENTRY(kernel_main)

SECTIONS {
    /* 这个是设置地址基准，类似 [ORG 0x100000]，而不是链接后就存过去 */
    . = 0x100000;

    /* 代码段 */
    .text : {
        *(.text)
    } :text

    /* 只读数据段 */
    .rodata : {
        *(.rodata)
    } :rodata

    /* 已初始化的数据段 */
    .data : {
        *(.data)
    } :data

    /* 未初始化的数据段 */
    .bss : {
        *(.bss)
        *(COMMON)
    } :data

    /* 填充段，对齐到 2 扇区 */
    .pad : {
        . = ALIGN(1024);
    }
}

/* 程序头，指定每个段的权限 */
PHDRS {
    text   PT_LOAD FLAGS(rx);   /* 代码段：可读、可执行 */
    rodata PT_LOAD FLAGS(r);     /* 只读数据：只读 */
    data   PT_LOAD FLAGS(rw);   /* 数据段：可读写 */
}
