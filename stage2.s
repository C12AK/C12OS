[BITS 16]
[ORG 0x6000]

start:
    ; 初步加载内核
    call load_kernel

    ; 打开 A20（第 21 根地址线，在实模式下屏蔽），从而支持访问 1MB 以上内存
    call enable_a20
    
    ; 设置 GDT（全局描述符表），保护模式下段寄存器存的是选择子，而不是基地址
    call setup_gdt

    ; 切换到 32 位保护模式
    jmp switch_to_protected_mode

load_kernel:
    ; 先读取内核到 0x10000 地址
    mov ah, 0x02
    mov al, 1                   ; 内核占的扇区数    [#modify]
    mov ch, 0
    mov cl, 4                   ; 扇区号
    mov dh, 0
    mov dl, 0x80
    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    int 0x13
    jc error
    ret

error:
    mov ah, 0x0E
    mov al, 'S'
    int 0x10
    mov al, 't'
    int 0x10
    mov al, 'a'
    int 0x10
    mov al, 'g'
    int 0x10
    mov al, 'e'
    int 0x10
    mov al, '2'
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 'E'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, 'o'
    int 0x10
    mov al, 'r'
    int 0x10

hang:
    jmp hang

enable_a20:
    ; 将 I/O 端口 0x92（System Control Port A）的第 1 位置为 1，表示开启 A20
    in al, 0x92
    or al, 0x02
    out 0x92, al
    ret

setup_gdt:
    lgdt [gdt_descriptor]   ; 存。lgdt 本身就只加载 6 字节
    ret

gdt_start:
    ; 第 0 个描述符，必须为全零
    dd 0x00000000
    dd 0x00000000

    ; --------------------------------
    ; 第 1 个描述符，代码段
    ; Limit = 0x F FFFF
    ; Base = 0x 0000 0000
    ; Access = 0x9A = 1001 1010 b
    ;     P=1，段存在；DPL=00，特权级 0，内核；S=1，代码或数据段；Type=1010，可执行、可读、不可写
    ; Flags = 11 b
    ;     G=1，粒度 4KB；D=1，32位段
    ; --------------------------------
    dw 0xFFFF       ; Limit 的低 16 位
    dw 0x0000       ; Base 的低 16 位
    db 0x00         ; Base 的中间 8 位
    db 0x9A         ; Access
    db 0xCF         ; 即 1100 1111，Flags + 空两位 + Limit 的高 4 位
    db 0x00         ; Base 的高 8 位

    ; 第 2 个描述符：数据段，和代码段区别仅有 Type=0010b，可读写、不可执行
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00
gdt_end:

; GDT 的描述符存在 GDTR 寄存器，共 6 字节：前 2 字节是 GDT 长度 - 1，后 4 字节是 GDT 起始物理地址
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

switch_to_protected_mode:
    cli                             ; 关中断

    ; CR0 寄存器的 PE 位置位，表示切换到保护模式
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

    ; far jump 不是为了跳转，是为了设置代码段选择子，并强制刷新流水线，清除旧的实模式指令
    jmp 0x08:protected_mode_entry

    [BITS 32]
    protected_mode_entry:

    ; 代码段寄存器 cs 已经设为 0x08，接下来把用于普通数据访问的 ds es fs gs 统一设为数据段选择子
    ; 栈段寄存器 ss 也要设为数据段
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    cld                         ; Clear Direction Flag，即设置 DF=0，从低地址往高地址复制
    mov esi, 0x00010000         ; 原地址
    mov edi, 0x00100000         ; 新地址
    mov ecx, (1 * 512) / 4      ; 共 1 扇区；movsd 一次搬一个 dword 即 4 字节
    rep movsd                   ; 一直搬，直到 ecx = 0

    ; 0x08 不是段地址而是选择子，其值即 0000 0000 0000 1000 b，低 2 位是 RPL=00，表示请求特权级 0（最高）
    ; 下一位是 TI（用来选择 GDT 或者 LDT），高 13 位是 IDX；TI=0 且 IDX=1，即指向 GDT 的第 1 个描述符
    jmp dword 0x08:0x10000

times 1024 - ($ - $$) db 0
