import sys
import json
import os

def patch_file(filename, rom_data):
	with open(filename, 'r') as f:
		data = json.load(f)
		for i in range(len(data["SubChips"])):
			if data["SubChips"][i]["Label"]=="ROM_0":
				data["SubChips"][i]["InternalData"]=rom_data
				print(data["SubChips"][i])
				print()
		
	os.rename(filename,filename+".bak")
	with open(filename, 'w') as f:
		json.dump(data, f, indent=4)

regs=["R0","R1","R2","R3","R4","R5","R6","R7","R8","R9","RA","RB","RC","RD","RE","RF"]

linetypes={
	"error":{"char":"", "code":0},
	"comment":{"char":";", "code":100},
	"preproc":{"char":".", "code":10},
	"op":{"char":"", "code":1},
	"label":{"char":":", "code":2},
}

preproc = {
	".org":{"params":1},
	".equ":{"params":2},
	".db":{"params":-1},
	".include":{"params":1},
}

op = {
	"idl":{"code":0x00,"mask":0x0f,"params":1,"next":0},
	
	"inc":{"code":0x10,"mask":0x0f,"params":1,"next":0},# R(N)+1
	"dec":{"code":0x20,"mask":0x0f,"params":1,"next":0},# R(N)-1

	"b":{"code":0x30,"mask":0x00,"params":1,"next":1},# Y->R)(P)
	"bne":{"code":0x31,"mask":0x00,"params":1,"next":1}, # D!=0
	"beq":{"code":0x32,"mask":0x00,"params":1,"next":1}, # D==0
	"bdf":{"code":0x33,"mask":0x00,"params":1,"next":1},
	
	"b1":{"code":0x34,"mask":0x00,"params":1,"next":1},
	"b2":{"code":0x35,"mask":0x00,"params":1,"next":1},
	"b3":{"code":0x36,"mask":0x00,"params":1,"next":1},
	"b4":{"code":0x37,"mask":0x00,"params":1,"next":1},

	"lda":{"code":0x40,"mask":0x0f,"params":1,"next":0}, # M(R(N))->D, R(N)+1
	"str":{"code":0x50,"mask":0x0f,"params":1,"next":0}, # D->M(R(N))
	
	"inp":{"code":0x68,"mask":0x00,"params":0,"next":0}, #bus->M(R(X))
	
	"ret":{"code":0x70,"mask":0x00,"params":0,"next":0}, # M(R(X))->XP, R(X)+1, reset IM
	"sav":{"code":0x78,"mask":0x00,"params":0,"next":0}, # T->M(R(X))
	
	"glo":{"code":0x80,"mask":0x0f,"params":1,"next":0}, # R0(N)->D
	"ghi":{"code":0x90,"mask":0x0f,"params":1,"next":0}, # R1(N)->D

	"plo":{"code":0xA0,"mask":0x0f,"params":1,"next":0}, # D->R0(N)
	"phi":{"code":0xB0,"mask":0x0f,"params":1,"next":0}, # D->R1(N)

	"plolo":{"code":0xC0,"mask":0x0f,"params":1,"next":0}, # D0->R00(N)

	"sep":{"code":0xD0,"mask":0x0f,"params":1,"next":0}, # N->P 
	"sex":{"code":0xE0,"mask":0x0f,"params":1,"next":0}, # N->X

	"ldx":{"code":0xf0,"mask":0x00,"params":0,"next":0}, # M(R(X))->D
	"or":{"code":0xf1,"mask":0x00,"params":0,"next":0}, # M(R(X)) | D->D
	"and":{"code":0xf2,"mask":0x00,"params":0,"next":0}, # M(R(X)) & D->D
	"xor":{"code":0xf3,"mask":0x00,"params":0,"next":0}, # M(R(X)) ^ D->D
	"add":{"code":0xf4,"mask":0x00,"params":0,"next":0}, # M(R(X)) + D->D
	"sub":{"code":0xf5,"mask":0x00,"params":0,"next":0}, # M(R(X)) - D->D
	"shr":{"code":0xf6,"mask":0x00,"params":0,"next":0}, # D>>1->D
	"spare":{"code":0xf7,"mask":0x00,"params":0,"next":0},
		
}

def line_clean(line):
	scp = line.find(linetypes["comment"]["char"])
	if scp>=0:
		line = line[:scp]
	return line.strip()

def line_segment(line):
	def first_other(line):
		fs = line.find(" ")
		if fs>=0:
			return (line[:fs],line[fs:].strip())
		else:	
			return (line,None)
			
	pp = line.find(linetypes["preproc"]["char"])
	lp = line.find(linetypes["label"]["char"])
	
	if pp>=0 and lp>=0:
		return (linetypes["error"]["code"], "syntax error")
	elif pp>=0:
		return (linetypes["preproc"]["code"], first_other(line))
	elif lp>=0:
		return (linetypes["label"]["code"], line[:lp])
	else:	
		return (linetypes["op"]["code"], first_other(line))
		
def line_validate():
	pass
	
class code:
	def __init__(self):
		self.__len = 256
		self.__code = [0]*self.__len
		self.__dirty = [0]*self.__len

	def add(self,addr,data):
		added=0
		
		if addr>=len(self.__code):
			tmpc=self.__code
			tmpd=self.__dirty
			
			self.__code = [0]*self.__len*2
			self.__dirty = [0]*self.__len*2
			for i in range(self.__len):
				self.__code[i]=tmpc[i]
				self.__dirty[i]=tmpd[i]
			self.__len*=2
		else:
			if self.__dirty[addr]:
				#~ pass
				raise RuntimeError("adress regions overlapped!!!")
			else:	
				self.__code[addr]=data
				self.__dirty[addr]=1
				added=1
				
		if not added:	
			self.add(addr,data)

	def get(self):
		return self.__code

def fn_or_im(equ,defer,pc,val):
	hip = val.find("HI") 
	lop = val.find("LO")
	ob = val.find("(")
	cb = val.find(")")
	ret = 1
	if  ob>=0 and cb>=0 :
		par = val[ob+1:cb]
		if hip==0 :
			val = equ.get(par,par)
			try:
				val = int( val ,16)
			except:
				if defer.get(val):
					defer[val].append( (pc,1) )
				else:	
					defer[val] = [ (pc,1) ]	
				val = 0
				ret = 0
			return (ret,(val>>8)&0xff)
		elif lop==0 :
			val = equ.get(par,par)
			try:
				val = int( val ,16)
			except:
				if defer.get(val):
					defer[val].append( (pc,0) )
				else:	
					defer[val] = [ (pc,0) ]	
				val = 0
				ret = 0				
			return (ret,(val>>0)&0xff)
		else:
			raise RuntimeError("syntax error!!! " + val)
	else:
		return (ret,int(val,16))

def main():
	name = "tst2.asm"
	
	PC=0
	LL={}
	DEFER={}
	EQU={}
	
	CODE = code()
	
	with open(name,"rt") as f:
		while 1:
			line = f.readline()
			if not line:
				break
			line = line_clean(line)
			if line:
				ls = line_segment(line)				
			
				if ls[0]==linetypes["preproc"]["code"]:
					if ls[1][0]==".org":
						PC=int(ls[1][1],16)
					if ls[1][0]==".db":
						n=ls[1][1]
						n=EQU.get(n,n)

						#~ CODE.add(PC, int(n,16) )
						ret = fn_or_im(EQU,DEFER,PC,n)
						if ret[0]:
							CODE.add(PC,ret[1])
						PC+=1
					if ls[1][0]==".equ":
						pv = ls[1][1].split()
						EQU[pv[0].strip()]=pv[1].strip()
						
				if ls[0]==linetypes["label"]["code"]:
					
					if LL.get(ls[1]):
						raise RuntimeError("multiple label!!!")
					else:
						LL[ls[1]]=PC
					
				if ls[0]==linetypes["op"]["code"]:
					arg = 0
					if ls[1][1]:
						n=ls[1][1]
						n=EQU.get(n,n)
							
						if n in regs:
							arg=int("0x"+n[1:],16)
						else:
							if not op[ls[1][0]]["next"]:
								raise RuntimeError("wrong arg!!! "+ls[1][1])
							else:
								pass

					CODE.add(PC, op[ls[1][0]]["code"]|(arg&op[ls[1][0]]["mask"]) )
					PC+=1
					
					if ls[1][0]=="b" or ls[1][0]=="bne" or ls[1][0]=="beq" or ls[1][0]=="bdf":
						if LL.get(ls[1][1]):
							CODE.add(PC, LL[ls[1][1]] )
						else:	
							if DEFER.get(ls[1][1]):
								DEFER[ls[1][1]].append( (PC,0) )
							else:	
								DEFER[ls[1][1]] = [ (PC,0) ]	
						PC+=1
						
	# populate defer
	for k,v in DEFER.items():
		for j in v:
			#~ print(k,j)
			CODE.add( j[0] , ( LL[k] >> (j[1]*8) )&0xff )
	
	#~ print(CODE.get())
	lp = 0	
	for i in CODE.get():
		lp+=1
		print ( hex(i)[2:].rjust(2,"0"), end="\t" )
		if lp ==16:
			lp=0
			print()
	patch_file("system-00/Chips/LOGIC-3.json",CODE.get())
	
if __name__=="__main__":
	main()
