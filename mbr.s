[BITS 16]       ; 设为 16 位实模式
[ORG 0x7C00]    ; BIOS 从磁盘第一个扇区加载 MBR 到 0x7C00 地址执行，故设基地址为 0x7C00

; 读取 bootloader stage2 到内存的 0x6000 位置（磁盘 CHS 寻址，内存分段寻址）
start:
    mov ah, 0x02                ; 调用 int 0x13 磁盘中断的子功能 0x02 读扇区
    mov al, 2                   ; 读 2 个扇区（1KB）
    mov ch, 0                   ; 磁道号 0
    mov cl, 2                   ; 扇区号 2
    mov dh, 0                   ; 磁头号 0
    mov dl, 0x80                ; 驱动器号 0x80，表示第一个硬盘

    ; 要加载到 0x6000，[es:bx] = (es << 4) + bx = 0x0600 << 4 = 0x6000
    mov bx, 0x0600
    mov es, bx
    xor bx, bx

    int 0x13                    ; 触发磁盘中断，读扇区
    jc error                    ; 若失败则 CF = 1，检测到 CF = 1 则报错

    jmp 0x0600:0x0000           ; 跳转到加载了 stage2 的位置，继续执行

error:
    mov ah, 0x0E    ; 调用 int 0x10 视频中断的子功能 0x0E Teletype 模式打印
    mov al, 'M'     ; 打印的字符是 'M'
    int 0x10        ; 触发视频中断，打印
    mov al, 'B'
    int 0x10
    mov al, 'R'
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

; 出错后要保持在一个稳定状态
hang:
    jmp hang

times 510 - ($ - $$) db 0   ; 填充本文件至 510 字节
dw 0xAA55                   ; 最后 2 字节设为启动标志
