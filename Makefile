# apt install iverilog
# apt install gtkwave

CC=iverilog
SIM=vvp
RM=rm
WAVE=gtkwave
TARGETDIR=design
HDLDIR=modules
WAVEDIR=sim
ASM=tools/asmx

SRC=test.asm
#~ SRC=blink.asm
#~ SRC=rca_1802_test.asm
SRCDIR=src

TARGET=core
TB=testbench
SRCS=$(TB).v core.v $(HDLDIR)/memory.v $(HDLDIR)/incdec.v $(HDLDIR)/fsm.v
SRCS+=$(HDLDIR)/regs.v $(HDLDIR)/hilo.v $(HDLDIR)/alu.v $(HDLDIR)/expander.v 
SRCS+=$(HDLDIR)/resync.v

BINARY_NAME=$(TARGETDIR)/$(TARGET).txt

WAVE_FLAGS=$(WAVEDIR)/$(TARGET).gtkw -r $(WAVEDIR)/gtkwaverc
CC_FLAGS=-D 'DUMP_FILE_NAME="$(TARGETDIR)/$(TB).vcd"'
CC_FLAGS+=-D 'FIRMWARE="$(BINARY_NAME)"'

ASM_FLAGS=-C 1802 -l -w -e -B

all: dir hex $(TARGET).vcd  model

$(TARGET).dsn: $(SRCS)
	$(CC) $(CC_FLAGS) -o $(TARGETDIR)/$(TARGET).dsn $(SRCS)

$(TARGET).vcd: $(TARGET).dsn
	$(SIM) $(TARGETDIR)/$(TARGET).dsn

clean:
	rm -rf $(TARGETDIR)

model:
	$(WAVE) $(TARGETDIR)/$(TB).vcd $(WAVE_FLAGS) 

hex:
	$(ASM) $(ASM_FLAGS) -o $(BINARY_NAME) $(SRCDIR)/$(SRC) 

dir:
	mkdir -p $(TARGETDIR)
