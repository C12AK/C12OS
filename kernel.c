const char *msg = "Hello World!";

void kernel_main() {
    char *video = (char *)0xB8000;      // 文本模式显存基址
    for (int i = 0; msg[i]; i++) {
        video[i << 1] = msg[i];         // 要显示的字符
        video[i << 1 | 1] = 0x07;       // 属性：灰底白字
    }
    while (1) { __asm__ __volatile__("hlt"); }
}
