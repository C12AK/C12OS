; MBR 引导程序（512 字节）
[BITS 16]       ; 设为 16 位实模式
[ORG 0x7C00]    ; BIOS 从磁盘第一个扇区加载 MBR 到 0x7C00 地址执行，故设基地址为 0x7C00

KERNEL_SECTOR equ 2         ; MBR 从磁盘第二个扇区读取内核
KERNEL_ADDR equ 0x10000    ; 读到内存 64KB 的位置


start:
    ; 打印加载提示
    mov ah, 0x0E    ; 调用 int 0x10 视频中断的子功能 0x0E Teletype 模式打印
    mov al, 'L'     ; 打印的字符是 'L'
    int 0x10        ; 触发视频中断，打印
    mov al, 'o'
    int 0x10
    mov al, 'a'
    int 0x10
    mov al, 'd'
    int 0x10
    mov al, 'i'
    int 0x10
    mov al, 'n'
    int 0x10
    mov al, 'g'
    int 0x10
    mov al, '.'
    int 0x10
    mov al, '.'
    int 0x10
    mov al, '.'
    int 0x10

    ; 尝试加载内核
    call read_kernel
    jc print_error

    jmp 0x1000:0


; 读取内核到内存的 KERNEL_ADDR（磁盘 CHS 寻址，内存分段寻址）
read_kernel:
    mov ah, 0x02                ; 调用 int 0x13 磁盘中断的子功能 0x02 读扇区
    mov al, 4                   ; 读 4 个扇区（2KB）
    mov ch, 0                   ; 磁道号 0
    mov cl, KERNEL_SECTOR       ; 扇区号 2
    mov dh, 0                   ; 磁头号 0
    mov dl, 0x80                ; 驱动器号 0x80，表示第一个硬盘
    mov bx, KERNEL_ADDR >> 4    ; es = 内核地址的段地址
    mov es, bx                  ; x86 实模式规定段寄存器不能接收立即数
    mov bx, KERNEL_ADDR & 0x0F  ; bx = 内核地址的偏移地址
    int 0x13                    ; 触发磁盘中断，读扇区
    ret


; 打印错误提示
print_error:
    mov ah, 0x0E
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


times 510 - ($ - $$) db 0   ; 填充本文件至 510 字节
dw 0xAA55                   ; 最后 2 字节设为启动标志
