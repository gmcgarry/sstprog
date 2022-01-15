# sstprog
STC8951RC programmer for SST flash chips.

- ADDRL: port 0
- ADDRH: port 2
- DATA: port 1
- /CS: P3.7
- /OE: P3.6
- /WE: P3.5

Connect to programmer:

	$ screen /dev/ttyUSB0 19200

Cut-and-paste intel hex file into console
