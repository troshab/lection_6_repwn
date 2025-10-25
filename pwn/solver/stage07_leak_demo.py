
from pwn import *
io = process('build/stage07_leak_demo')  # local demo
io.sendline(b'LEAK')
print(io.recvline().decode().strip())
