all:	sstprog.hex

load:	sstprog.hex
	stcgal $(RATE) $<

connect:
	screen /dev/ttyUSB0 19200

clean:
	$(RM) *.hex

.SUFFIXES:	.hex .asm

.asm.hex:
	pasm-8051 -o $@ $<
