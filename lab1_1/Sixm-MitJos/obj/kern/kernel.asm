
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 a0 1a 10 f0 	movl   $0xf0101aa0,(%esp)
f0100055:	e8 c6 09 00 00       	call   f0100a20 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 2b 07 00 00       	call   f01007b2 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 bc 1a 10 f0 	movl   $0xf0101abc,(%esp)
f0100092:	e8 89 09 00 00       	call   f0100a20 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 fa 14 00 00       	call   f01015bf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 b0 04 00 00       	call   f010057a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 1a 10 f0 	movl   $0xf0101ad7,(%esp)
f01000d9:	e8 42 09 00 00       	call   f0100a20 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 9f 07 00 00       	call   f0100895 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 f2 1a 10 f0 	movl   $0xf0101af2,(%esp)
f010012c:	e8 ef 08 00 00       	call   f0100a20 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 b0 08 00 00       	call   f01009ed <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 e9 1d 10 f0 	movl   $0xf0101de9,(%esp)
f0100144:	e8 d7 08 00 00       	call   f0100a20 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 40 07 00 00       	call   f0100895 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 0a 1b 10 f0 	movl   $0xf0101b0a,(%esp)
f0100176:	e8 a5 08 00 00       	call   f0100a20 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 63 08 00 00       	call   f01009ed <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 e9 1d 10 f0 	movl   $0xf0101de9,(%esp)
f0100191:	e8 8a 08 00 00       	call   f0100a20 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001d9:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 80 1c 10 f0 	movzbl -0xfefe380(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 80 1c 10 f0 	movzbl -0xfefe380(%edx),%eax
f0100289:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 80 1b 10 f0 	movzbl -0xfefe480(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 60 1b 10 f0 	mov    -0xfefe4a0(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 24 1b 10 f0 	movl   $0xf0101b24,(%esp)
f01002e9:	e8 32 07 00 00       	call   f0100a20 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100314:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100319:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 27                	jne    f0100345 <cons_putc+0x3c>
f010031e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100323:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100328:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	89 ca                	mov    %ecx,%edx
f0100332:	ec                   	in     (%dx),%al
f0100333:	89 ca                	mov    %ecx,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	89 ca                	mov    %ecx,%edx
f0100338:	ec                   	in     (%dx),%al
f0100339:	89 f2                	mov    %esi,%edx
f010033b:	ec                   	in     (%dx),%al
f010033c:	a8 20                	test   $0x20,%al
f010033e:	75 05                	jne    f0100345 <cons_putc+0x3c>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100340:	83 eb 01             	sub    $0x1,%ebx
f0100343:	75 e8                	jne    f010032d <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100345:	89 f8                	mov    %edi,%eax
f0100347:	0f b6 c0             	movzbl %al,%eax
f010034a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100352:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100353:	b2 79                	mov    $0x79,%dl
f0100355:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100356:	84 c0                	test   %al,%al
f0100358:	78 27                	js     f0100381 <cons_putc+0x78>
f010035a:	bb 00 32 00 00       	mov    $0x3200,%ebx
f010035f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100364:	be 79 03 00 00       	mov    $0x379,%esi
f0100369:	89 ca                	mov    %ecx,%edx
f010036b:	ec                   	in     (%dx),%al
f010036c:	89 ca                	mov    %ecx,%edx
f010036e:	ec                   	in     (%dx),%al
f010036f:	89 ca                	mov    %ecx,%edx
f0100371:	ec                   	in     (%dx),%al
f0100372:	89 ca                	mov    %ecx,%edx
f0100374:	ec                   	in     (%dx),%al
f0100375:	89 f2                	mov    %esi,%edx
f0100377:	ec                   	in     (%dx),%al
f0100378:	84 c0                	test   %al,%al
f010037a:	78 05                	js     f0100381 <cons_putc+0x78>
f010037c:	83 eb 01             	sub    $0x1,%ebx
f010037f:	75 e8                	jne    f0100369 <cons_putc+0x60>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100381:	ba 78 03 00 00       	mov    $0x378,%edx
f0100386:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010038a:	ee                   	out    %al,(%dx)
f010038b:	b2 7a                	mov    $0x7a,%dl
f010038d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100392:	ee                   	out    %al,(%dx)
f0100393:	b8 08 00 00 00       	mov    $0x8,%eax
f0100398:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100399:	89 fa                	mov    %edi,%edx
f010039b:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003a1:	89 f8                	mov    %edi,%eax
f01003a3:	80 cc 07             	or     $0x7,%ah
f01003a6:	85 d2                	test   %edx,%edx
f01003a8:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003ab:	89 f8                	mov    %edi,%eax
f01003ad:	0f b6 c0             	movzbl %al,%eax
f01003b0:	83 f8 09             	cmp    $0x9,%eax
f01003b3:	74 78                	je     f010042d <cons_putc+0x124>
f01003b5:	83 f8 09             	cmp    $0x9,%eax
f01003b8:	7f 0b                	jg     f01003c5 <cons_putc+0xbc>
f01003ba:	83 f8 08             	cmp    $0x8,%eax
f01003bd:	74 18                	je     f01003d7 <cons_putc+0xce>
f01003bf:	90                   	nop
f01003c0:	e9 9c 00 00 00       	jmp    f0100461 <cons_putc+0x158>
f01003c5:	83 f8 0a             	cmp    $0xa,%eax
f01003c8:	74 3d                	je     f0100407 <cons_putc+0xfe>
f01003ca:	83 f8 0d             	cmp    $0xd,%eax
f01003cd:	8d 76 00             	lea    0x0(%esi),%esi
f01003d0:	74 3d                	je     f010040f <cons_putc+0x106>
f01003d2:	e9 8a 00 00 00       	jmp    f0100461 <cons_putc+0x158>
	case '\b':
		if (crt_pos > 0) {
f01003d7:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003de:	66 85 c0             	test   %ax,%ax
f01003e1:	0f 84 e5 00 00 00    	je     f01004cc <cons_putc+0x1c3>
			crt_pos--;
f01003e7:	83 e8 01             	sub    $0x1,%eax
f01003ea:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003f0:	0f b7 c0             	movzwl %ax,%eax
f01003f3:	66 81 e7 00 ff       	and    $0xff00,%di
f01003f8:	83 cf 20             	or     $0x20,%edi
f01003fb:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100401:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100405:	eb 78                	jmp    f010047f <cons_putc+0x176>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100407:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f010040e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010040f:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f0100416:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010041c:	c1 e8 16             	shr    $0x16,%eax
f010041f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100422:	c1 e0 04             	shl    $0x4,%eax
f0100425:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f010042b:	eb 52                	jmp    f010047f <cons_putc+0x176>
		break;
	case '\t':
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 d2 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100437:	b8 20 00 00 00       	mov    $0x20,%eax
f010043c:	e8 c8 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100441:	b8 20 00 00 00       	mov    $0x20,%eax
f0100446:	e8 be fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010044b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100450:	e8 b4 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100455:	b8 20 00 00 00       	mov    $0x20,%eax
f010045a:	e8 aa fe ff ff       	call   f0100309 <cons_putc>
f010045f:	eb 1e                	jmp    f010047f <cons_putc+0x176>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100461:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f0100468:	8d 50 01             	lea    0x1(%eax),%edx
f010046b:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100472:	0f b7 c0             	movzwl %ax,%eax
f0100475:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f010047b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010047f:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f0100486:	cf 07 
f0100488:	76 42                	jbe    f01004cc <cons_putc+0x1c3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010048a:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f010048f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100496:	00 
f0100497:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010049d:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004a1:	89 04 24             	mov    %eax,(%esp)
f01004a4:	e8 63 11 00 00       	call   f010160c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004b4:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004ba:	83 c0 01             	add    $0x1,%eax
f01004bd:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004c2:	75 f0                	jne    f01004b4 <cons_putc+0x1ab>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004c4:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004cb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004cc:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004d2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004da:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004e1:	8d 71 01             	lea    0x1(%ecx),%esi
f01004e4:	89 d8                	mov    %ebx,%eax
f01004e6:	66 c1 e8 08          	shr    $0x8,%ax
f01004ea:	89 f2                	mov    %esi,%edx
f01004ec:	ee                   	out    %al,(%dx)
f01004ed:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004f2:	89 ca                	mov    %ecx,%edx
f01004f4:	ee                   	out    %al,(%dx)
f01004f5:	89 d8                	mov    %ebx,%eax
f01004f7:	89 f2                	mov    %esi,%edx
f01004f9:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004fa:	83 c4 1c             	add    $0x1c,%esp
f01004fd:	5b                   	pop    %ebx
f01004fe:	5e                   	pop    %esi
f01004ff:	5f                   	pop    %edi
f0100500:	5d                   	pop    %ebp
f0100501:	c3                   	ret    

f0100502 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100502:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f0100509:	74 11                	je     f010051c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010050b:	55                   	push   %ebp
f010050c:	89 e5                	mov    %esp,%ebp
f010050e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100511:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f0100516:	e8 a1 fc ff ff       	call   f01001bc <cons_intr>
}
f010051b:	c9                   	leave  
f010051c:	f3 c3                	repz ret 

f010051e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010051e:	55                   	push   %ebp
f010051f:	89 e5                	mov    %esp,%ebp
f0100521:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100524:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f0100529:	e8 8e fc ff ff       	call   f01001bc <cons_intr>
}
f010052e:	c9                   	leave  
f010052f:	c3                   	ret    

f0100530 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100530:	55                   	push   %ebp
f0100531:	89 e5                	mov    %esp,%ebp
f0100533:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100536:	e8 c7 ff ff ff       	call   f0100502 <serial_intr>
	kbd_intr();
f010053b:	e8 de ff ff ff       	call   f010051e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100540:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f0100545:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f010054b:	74 26                	je     f0100573 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010054d:	8d 50 01             	lea    0x1(%eax),%edx
f0100550:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f0100556:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010055d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010055f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100565:	75 11                	jne    f0100578 <cons_getc+0x48>
			cons.rpos = 0;
f0100567:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f010056e:	00 00 00 
f0100571:	eb 05                	jmp    f0100578 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100573:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100578:	c9                   	leave  
f0100579:	c3                   	ret    

f010057a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010057a:	55                   	push   %ebp
f010057b:	89 e5                	mov    %esp,%ebp
f010057d:	57                   	push   %edi
f010057e:	56                   	push   %esi
f010057f:	53                   	push   %ebx
f0100580:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100583:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010058a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100591:	5a a5 
	if (*cp != 0xA55A) {
f0100593:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010059a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010059e:	74 11                	je     f01005b1 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005a0:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f01005a7:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005aa:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005af:	eb 16                	jmp    f01005c7 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005b1:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005b8:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f01005bf:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005c2:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005c7:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01005cd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005d2:	89 ca                	mov    %ecx,%edx
f01005d4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005d5:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d8:	89 da                	mov    %ebx,%edx
f01005da:	ec                   	in     (%dx),%al
f01005db:	0f b6 f0             	movzbl %al,%esi
f01005de:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005e6:	89 ca                	mov    %ecx,%edx
f01005e8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e9:	89 da                	mov    %ebx,%edx
f01005eb:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ec:	89 3d 4c 25 11 f0    	mov    %edi,0xf011254c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005f2:	0f b6 d8             	movzbl %al,%ebx
f01005f5:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005f7:	66 89 35 48 25 11 f0 	mov    %si,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005fe:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100603:	b8 00 00 00 00       	mov    $0x0,%eax
f0100608:	ee                   	out    %al,(%dx)
f0100609:	b2 fb                	mov    $0xfb,%dl
f010060b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	b2 f8                	mov    $0xf8,%dl
f0100613:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100618:	ee                   	out    %al,(%dx)
f0100619:	b2 f9                	mov    $0xf9,%dl
f010061b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100620:	ee                   	out    %al,(%dx)
f0100621:	b2 fb                	mov    $0xfb,%dl
f0100623:	b8 03 00 00 00       	mov    $0x3,%eax
f0100628:	ee                   	out    %al,(%dx)
f0100629:	b2 fc                	mov    $0xfc,%dl
f010062b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100630:	ee                   	out    %al,(%dx)
f0100631:	b2 f9                	mov    $0xf9,%dl
f0100633:	b8 01 00 00 00       	mov    $0x1,%eax
f0100638:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100639:	b2 fd                	mov    $0xfd,%dl
f010063b:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010063c:	3c ff                	cmp    $0xff,%al
f010063e:	0f 95 c1             	setne  %cl
f0100641:	0f b6 c9             	movzbl %cl,%ecx
f0100644:	89 0d 54 25 11 f0    	mov    %ecx,0xf0112554
f010064a:	b2 fa                	mov    $0xfa,%dl
f010064c:	ec                   	in     (%dx),%al
f010064d:	b2 f8                	mov    $0xf8,%dl
f010064f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100650:	85 c9                	test   %ecx,%ecx
f0100652:	75 0c                	jne    f0100660 <cons_init+0xe6>
		cprintf("Serial port does not exist!\n");
f0100654:	c7 04 24 30 1b 10 f0 	movl   $0xf0101b30,(%esp)
f010065b:	e8 c0 03 00 00       	call   f0100a20 <cprintf>
}
f0100660:	83 c4 1c             	add    $0x1c,%esp
f0100663:	5b                   	pop    %ebx
f0100664:	5e                   	pop    %esi
f0100665:	5f                   	pop    %edi
f0100666:	5d                   	pop    %ebp
f0100667:	c3                   	ret    

f0100668 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100668:	55                   	push   %ebp
f0100669:	89 e5                	mov    %esp,%ebp
f010066b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010066e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100671:	e8 93 fc ff ff       	call   f0100309 <cons_putc>
}
f0100676:	c9                   	leave  
f0100677:	c3                   	ret    

f0100678 <getchar>:

int
getchar(void)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010067e:	e8 ad fe ff ff       	call   f0100530 <cons_getc>
f0100683:	85 c0                	test   %eax,%eax
f0100685:	74 f7                	je     f010067e <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100687:	c9                   	leave  
f0100688:	c3                   	ret    

f0100689 <iscons>:

int
iscons(int fdnum)
{
f0100689:	55                   	push   %ebp
f010068a:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010068c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100691:	5d                   	pop    %ebp
f0100692:	c3                   	ret    
f0100693:	66 90                	xchg   %ax,%ax
f0100695:	66 90                	xchg   %ax,%ax
f0100697:	66 90                	xchg   %ax,%ax
f0100699:	66 90                	xchg   %ax,%ax
f010069b:	66 90                	xchg   %ax,%ax
f010069d:	66 90                	xchg   %ax,%ax
f010069f:	90                   	nop

f01006a0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
f01006a3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006a6:	c7 44 24 08 80 1d 10 	movl   $0xf0101d80,0x8(%esp)
f01006ad:	f0 
f01006ae:	c7 44 24 04 9e 1d 10 	movl   $0xf0101d9e,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 a3 1d 10 f0 	movl   $0xf0101da3,(%esp)
f01006bd:	e8 5e 03 00 00       	call   f0100a20 <cprintf>
f01006c2:	c7 44 24 08 44 1e 10 	movl   $0xf0101e44,0x8(%esp)
f01006c9:	f0 
f01006ca:	c7 44 24 04 ac 1d 10 	movl   $0xf0101dac,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 a3 1d 10 f0 	movl   $0xf0101da3,(%esp)
f01006d9:	e8 42 03 00 00       	call   f0100a20 <cprintf>
f01006de:	c7 44 24 08 6c 1e 10 	movl   $0xf0101e6c,0x8(%esp)
f01006e5:	f0 
f01006e6:	c7 44 24 04 b5 1d 10 	movl   $0xf0101db5,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 a3 1d 10 f0 	movl   $0xf0101da3,(%esp)
f01006f5:	e8 26 03 00 00       	call   f0100a20 <cprintf>
	return 0;
}
f01006fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ff:	c9                   	leave  
f0100700:	c3                   	ret    

f0100701 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100701:	55                   	push   %ebp
f0100702:	89 e5                	mov    %esp,%ebp
f0100704:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100707:	c7 04 24 bf 1d 10 f0 	movl   $0xf0101dbf,(%esp)
f010070e:	e8 0d 03 00 00       	call   f0100a20 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100713:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010071a:	00 
f010071b:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100722:	f0 
f0100723:	c7 04 24 98 1e 10 f0 	movl   $0xf0101e98,(%esp)
f010072a:	e8 f1 02 00 00       	call   f0100a20 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010072f:	c7 44 24 08 87 1a 10 	movl   $0x101a87,0x8(%esp)
f0100736:	00 
f0100737:	c7 44 24 04 87 1a 10 	movl   $0xf0101a87,0x4(%esp)
f010073e:	f0 
f010073f:	c7 04 24 bc 1e 10 f0 	movl   $0xf0101ebc,(%esp)
f0100746:	e8 d5 02 00 00       	call   f0100a20 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010074b:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100752:	00 
f0100753:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010075a:	f0 
f010075b:	c7 04 24 e0 1e 10 f0 	movl   $0xf0101ee0,(%esp)
f0100762:	e8 b9 02 00 00       	call   f0100a20 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100767:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010076e:	00 
f010076f:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100776:	f0 
f0100777:	c7 04 24 04 1f 10 f0 	movl   $0xf0101f04,(%esp)
f010077e:	e8 9d 02 00 00       	call   f0100a20 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100783:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100788:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010078d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100793:	85 c0                	test   %eax,%eax
f0100795:	0f 48 c2             	cmovs  %edx,%eax
f0100798:	c1 f8 0a             	sar    $0xa,%eax
f010079b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079f:	c7 04 24 28 1f 10 f0 	movl   $0xf0101f28,(%esp)
f01007a6:	e8 75 02 00 00       	call   f0100a20 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01007ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b0:	c9                   	leave  
f01007b1:	c3                   	ret    

f01007b2 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007b2:	55                   	push   %ebp
f01007b3:	89 e5                	mov    %esp,%ebp
f01007b5:	57                   	push   %edi
f01007b6:	56                   	push   %esi
f01007b7:	53                   	push   %ebx
f01007b8:	83 ec 1c             	sub    $0x1c,%esp
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01007bb:	8b 75 04             	mov    0x4(%ebp),%esi

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007be:	89 ef                	mov    %ebp,%edi
f01007c0:	89 fb                	mov    %edi,%ebx
	//homework2 we need to do. By Sixm
	//Read the values of eip and ebp
	uint32_t eip=read_eip();
	uint32_t ebp=read_ebp();
	//Print current eip and ebp
	cprintf("Stack backtrace:\r\n");
f01007c2:	c7 04 24 d8 1d 10 f0 	movl   $0xf0101dd8,(%esp)
f01007c9:	e8 52 02 00 00       	call   f0100a20 <cprintf>
	cprintf(" ebp:%x eip:%x ",ebp,eip);
f01007ce:	89 74 24 08          	mov    %esi,0x8(%esp)
f01007d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007d6:	c7 04 24 eb 1d 10 f0 	movl   $0xf0101deb,(%esp)
f01007dd:	e8 3e 02 00 00       	call   f0100a20 <cprintf>
	//Print current fuction's args	
	uint32_t esp=ebp + 0x8;
f01007e2:	8d 77 08             	lea    0x8(%edi),%esi
	int i;
	cprintf("args:");
f01007e5:	c7 04 24 fb 1d 10 f0 	movl   $0xf0101dfb,(%esp)
f01007ec:	e8 2f 02 00 00       	call   f0100a20 <cprintf>
f01007f1:	8d 47 1c             	lea    0x1c(%edi),%eax
f01007f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0;i<5;i++){
		cprintf("%x ",*(uint32_t *)(esp));
f01007f7:	8b 06                	mov    (%esi),%eax
f01007f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fd:	c7 04 24 f7 1d 10 f0 	movl   $0xf0101df7,(%esp)
f0100804:	e8 17 02 00 00       	call   f0100a20 <cprintf>
		esp=esp+0x4;	
f0100809:	83 c6 04             	add    $0x4,%esi
	cprintf(" ebp:%x eip:%x ",ebp,eip);
	//Print current fuction's args	
	uint32_t esp=ebp + 0x8;
	int i;
	cprintf("args:");
	for(i=0;i<5;i++){
f010080c:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010080f:	75 e6                	jne    f01007f7 <mon_backtrace+0x45>
		cprintf("%x ",*(uint32_t *)(esp));
		esp=esp+0x4;	
	}
	cprintf("\r\n");
f0100811:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f0100818:	e8 03 02 00 00       	call   f0100a20 <cprintf>
	//Print fuction before
	while(ebp!=0){
f010081d:	85 ff                	test   %edi,%edi
f010081f:	74 67                	je     f0100888 <mon_backtrace+0xd6>
		esp=ebp;
		if((ebp=*(uint32_t *)(esp))==0){
f0100821:	8b 3f                	mov    (%edi),%edi
f0100823:	85 ff                	test   %edi,%edi
f0100825:	75 0f                	jne    f0100836 <mon_backtrace+0x84>
f0100827:	eb 5f                	jmp    f0100888 <mon_backtrace+0xd6>
f0100829:	8b 07                	mov    (%edi),%eax
f010082b:	85 c0                	test   %eax,%eax
f010082d:	8d 76 00             	lea    0x0(%esi),%esi
f0100830:	74 56                	je     f0100888 <mon_backtrace+0xd6>
f0100832:	89 fb                	mov    %edi,%ebx
f0100834:	89 c7                	mov    %eax,%edi
			break;
		}
		esp=esp+0x4;
		eip=*(uint32_t *)(esp);
		esp=esp+0x4;
f0100836:	8d 73 08             	lea    0x8(%ebx),%esi
		cprintf(" ebp:%x eip:%x ",ebp,eip);
f0100839:	8b 43 04             	mov    0x4(%ebx),%eax
f010083c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100840:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100844:	c7 04 24 eb 1d 10 f0 	movl   $0xf0101deb,(%esp)
f010084b:	e8 d0 01 00 00       	call   f0100a20 <cprintf>
		cprintf("args:");
f0100850:	c7 04 24 fb 1d 10 f0 	movl   $0xf0101dfb,(%esp)
f0100857:	e8 c4 01 00 00       	call   f0100a20 <cprintf>
f010085c:	83 c3 1c             	add    $0x1c,%ebx
		for(i=0;i<5;i++){
			cprintf(" %x",*(uint32_t *)(esp));
f010085f:	8b 06                	mov    (%esi),%eax
f0100861:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100865:	c7 04 24 01 1e 10 f0 	movl   $0xf0101e01,(%esp)
f010086c:	e8 af 01 00 00       	call   f0100a20 <cprintf>
			esp=esp+0x4;	
f0100871:	83 c6 04             	add    $0x4,%esi
		esp=esp+0x4;
		eip=*(uint32_t *)(esp);
		esp=esp+0x4;
		cprintf(" ebp:%x eip:%x ",ebp,eip);
		cprintf("args:");
		for(i=0;i<5;i++){
f0100874:	39 de                	cmp    %ebx,%esi
f0100876:	75 e7                	jne    f010085f <mon_backtrace+0xad>
			cprintf(" %x",*(uint32_t *)(esp));
			esp=esp+0x4;	
		}
		cprintf("\r\n");	
f0100878:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f010087f:	e8 9c 01 00 00       	call   f0100a20 <cprintf>
		cprintf("%x ",*(uint32_t *)(esp));
		esp=esp+0x4;	
	}
	cprintf("\r\n");
	//Print fuction before
	while(ebp!=0){
f0100884:	85 ff                	test   %edi,%edi
f0100886:	75 a1                	jne    f0100829 <mon_backtrace+0x77>
			esp=esp+0x4;	
		}
		cprintf("\r\n");	
		}
	return 0;
}
f0100888:	b8 00 00 00 00       	mov    $0x0,%eax
f010088d:	83 c4 1c             	add    $0x1c,%esp
f0100890:	5b                   	pop    %ebx
f0100891:	5e                   	pop    %esi
f0100892:	5f                   	pop    %edi
f0100893:	5d                   	pop    %ebp
f0100894:	c3                   	ret    

f0100895 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100895:	55                   	push   %ebp
f0100896:	89 e5                	mov    %esp,%ebp
f0100898:	57                   	push   %edi
f0100899:	56                   	push   %esi
f010089a:	53                   	push   %ebx
f010089b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010089e:	c7 04 24 54 1f 10 f0 	movl   $0xf0101f54,(%esp)
f01008a5:	e8 76 01 00 00       	call   f0100a20 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008aa:	c7 04 24 78 1f 10 f0 	movl   $0xf0101f78,(%esp)
f01008b1:	e8 6a 01 00 00       	call   f0100a20 <cprintf>


	while (1) {
		buf = readline("K> ");
f01008b6:	c7 04 24 05 1e 10 f0 	movl   $0xf0101e05,(%esp)
f01008bd:	e8 4e 0a 00 00       	call   f0101310 <readline>
f01008c2:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008c4:	85 c0                	test   %eax,%eax
f01008c6:	74 ee                	je     f01008b6 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008cf:	be 00 00 00 00       	mov    $0x0,%esi
f01008d4:	eb 0a                	jmp    f01008e0 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d6:	c6 03 00             	movb   $0x0,(%ebx)
f01008d9:	89 f7                	mov    %esi,%edi
f01008db:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008de:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008e0:	0f b6 03             	movzbl (%ebx),%eax
f01008e3:	84 c0                	test   %al,%al
f01008e5:	74 6a                	je     f0100951 <monitor+0xbc>
f01008e7:	0f be c0             	movsbl %al,%eax
f01008ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ee:	c7 04 24 09 1e 10 f0 	movl   $0xf0101e09,(%esp)
f01008f5:	e8 64 0c 00 00       	call   f010155e <strchr>
f01008fa:	85 c0                	test   %eax,%eax
f01008fc:	75 d8                	jne    f01008d6 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008fe:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100901:	74 4e                	je     f0100951 <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100903:	83 fe 0f             	cmp    $0xf,%esi
f0100906:	75 16                	jne    f010091e <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100908:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010090f:	00 
f0100910:	c7 04 24 0e 1e 10 f0 	movl   $0xf0101e0e,(%esp)
f0100917:	e8 04 01 00 00       	call   f0100a20 <cprintf>
f010091c:	eb 98                	jmp    f01008b6 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010091e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100921:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100925:	0f b6 03             	movzbl (%ebx),%eax
f0100928:	84 c0                	test   %al,%al
f010092a:	75 0c                	jne    f0100938 <monitor+0xa3>
f010092c:	eb b0                	jmp    f01008de <monitor+0x49>
			buf++;
f010092e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100931:	0f b6 03             	movzbl (%ebx),%eax
f0100934:	84 c0                	test   %al,%al
f0100936:	74 a6                	je     f01008de <monitor+0x49>
f0100938:	0f be c0             	movsbl %al,%eax
f010093b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093f:	c7 04 24 09 1e 10 f0 	movl   $0xf0101e09,(%esp)
f0100946:	e8 13 0c 00 00       	call   f010155e <strchr>
f010094b:	85 c0                	test   %eax,%eax
f010094d:	74 df                	je     f010092e <monitor+0x99>
f010094f:	eb 8d                	jmp    f01008de <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100951:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100958:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100959:	85 f6                	test   %esi,%esi
f010095b:	0f 84 55 ff ff ff    	je     f01008b6 <monitor+0x21>
f0100961:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100966:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100969:	8b 04 85 a0 1f 10 f0 	mov    -0xfefe060(,%eax,4),%eax
f0100970:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100974:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100977:	89 04 24             	mov    %eax,(%esp)
f010097a:	e8 5b 0b 00 00       	call   f01014da <strcmp>
f010097f:	85 c0                	test   %eax,%eax
f0100981:	75 24                	jne    f01009a7 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f0100983:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100986:	8b 55 08             	mov    0x8(%ebp),%edx
f0100989:	89 54 24 08          	mov    %edx,0x8(%esp)
f010098d:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100990:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100994:	89 34 24             	mov    %esi,(%esp)
f0100997:	ff 14 85 a8 1f 10 f0 	call   *-0xfefe058(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010099e:	85 c0                	test   %eax,%eax
f01009a0:	78 28                	js     f01009ca <monitor+0x135>
f01009a2:	e9 0f ff ff ff       	jmp    f01008b6 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009a7:	83 c3 01             	add    $0x1,%ebx
f01009aa:	83 fb 03             	cmp    $0x3,%ebx
f01009ad:	8d 76 00             	lea    0x0(%esi),%esi
f01009b0:	75 b4                	jne    f0100966 <monitor+0xd1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009b2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b9:	c7 04 24 2b 1e 10 f0 	movl   $0xf0101e2b,(%esp)
f01009c0:	e8 5b 00 00 00       	call   f0100a20 <cprintf>
f01009c5:	e9 ec fe ff ff       	jmp    f01008b6 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009ca:	83 c4 5c             	add    $0x5c,%esp
f01009cd:	5b                   	pop    %ebx
f01009ce:	5e                   	pop    %esi
f01009cf:	5f                   	pop    %edi
f01009d0:	5d                   	pop    %ebp
f01009d1:	c3                   	ret    

f01009d2 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01009d2:	55                   	push   %ebp
f01009d3:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01009d5:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01009d8:	5d                   	pop    %ebp
f01009d9:	c3                   	ret    

f01009da <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009da:	55                   	push   %ebp
f01009db:	89 e5                	mov    %esp,%ebp
f01009dd:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01009e3:	89 04 24             	mov    %eax,(%esp)
f01009e6:	e8 7d fc ff ff       	call   f0100668 <cputchar>
	*cnt++;
}
f01009eb:	c9                   	leave  
f01009ec:	c3                   	ret    

f01009ed <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009ed:	55                   	push   %ebp
f01009ee:	89 e5                	mov    %esp,%ebp
f01009f0:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009f3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009fd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a01:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a04:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a08:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a0f:	c7 04 24 da 09 10 f0 	movl   $0xf01009da,(%esp)
f0100a16:	e8 89 04 00 00       	call   f0100ea4 <vprintfmt>
	return cnt;
}
f0100a1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a1e:	c9                   	leave  
f0100a1f:	c3                   	ret    

f0100a20 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a26:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a29:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a30:	89 04 24             	mov    %eax,(%esp)
f0100a33:	e8 b5 ff ff ff       	call   f01009ed <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a38:	c9                   	leave  
f0100a39:	c3                   	ret    
f0100a3a:	66 90                	xchg   %ax,%ax
f0100a3c:	66 90                	xchg   %ax,%ax
f0100a3e:	66 90                	xchg   %ax,%ax

f0100a40 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a40:	55                   	push   %ebp
f0100a41:	89 e5                	mov    %esp,%ebp
f0100a43:	57                   	push   %edi
f0100a44:	56                   	push   %esi
f0100a45:	53                   	push   %ebx
f0100a46:	83 ec 10             	sub    $0x10,%esp
f0100a49:	89 c6                	mov    %eax,%esi
f0100a4b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a4e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a51:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a54:	8b 1a                	mov    (%edx),%ebx
f0100a56:	8b 01                	mov    (%ecx),%eax
f0100a58:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a5b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a62:	eb 77                	jmp    f0100adb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a67:	01 d8                	add    %ebx,%eax
f0100a69:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a6e:	99                   	cltd   
f0100a6f:	f7 f9                	idiv   %ecx
f0100a71:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a73:	eb 01                	jmp    f0100a76 <stab_binsearch+0x36>
			m--;
f0100a75:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a76:	39 d9                	cmp    %ebx,%ecx
f0100a78:	7c 1d                	jl     f0100a97 <stab_binsearch+0x57>
f0100a7a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a7d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a82:	39 fa                	cmp    %edi,%edx
f0100a84:	75 ef                	jne    f0100a75 <stab_binsearch+0x35>
f0100a86:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a89:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a8c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a90:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a93:	73 18                	jae    f0100aad <stab_binsearch+0x6d>
f0100a95:	eb 05                	jmp    f0100a9c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a97:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a9a:	eb 3f                	jmp    f0100adb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a9c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a9f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100aa1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aa4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100aab:	eb 2e                	jmp    f0100adb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100aad:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100ab0:	73 15                	jae    f0100ac7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100ab2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100ab5:	48                   	dec    %eax
f0100ab6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ab9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100abc:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100abe:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ac5:	eb 14                	jmp    f0100adb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ac7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100aca:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100acd:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100acf:	ff 45 0c             	incl   0xc(%ebp)
f0100ad2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ad4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100adb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ade:	7e 84                	jle    f0100a64 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ae0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ae4:	75 0d                	jne    f0100af3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ae6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ae9:	8b 00                	mov    (%eax),%eax
f0100aeb:	48                   	dec    %eax
f0100aec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100aef:	89 07                	mov    %eax,(%edi)
f0100af1:	eb 22                	jmp    f0100b15 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100af3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100af8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100afb:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100afd:	eb 01                	jmp    f0100b00 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100aff:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b00:	39 c1                	cmp    %eax,%ecx
f0100b02:	7d 0c                	jge    f0100b10 <stab_binsearch+0xd0>
f0100b04:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100b07:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100b0c:	39 fa                	cmp    %edi,%edx
f0100b0e:	75 ef                	jne    f0100aff <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b10:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100b13:	89 07                	mov    %eax,(%edi)
	}
}
f0100b15:	83 c4 10             	add    $0x10,%esp
f0100b18:	5b                   	pop    %ebx
f0100b19:	5e                   	pop    %esi
f0100b1a:	5f                   	pop    %edi
f0100b1b:	5d                   	pop    %ebp
f0100b1c:	c3                   	ret    

f0100b1d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b1d:	55                   	push   %ebp
f0100b1e:	89 e5                	mov    %esp,%ebp
f0100b20:	57                   	push   %edi
f0100b21:	56                   	push   %esi
f0100b22:	53                   	push   %ebx
f0100b23:	83 ec 2c             	sub    $0x2c,%esp
f0100b26:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b29:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b2c:	c7 03 c4 1f 10 f0    	movl   $0xf0101fc4,(%ebx)
	info->eip_line = 0;
f0100b32:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b39:	c7 43 08 c4 1f 10 f0 	movl   $0xf0101fc4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b40:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b47:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b4a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b51:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b57:	76 12                	jbe    f0100b6b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b59:	b8 cb 74 10 f0       	mov    $0xf01074cb,%eax
f0100b5e:	3d 75 5b 10 f0       	cmp    $0xf0105b75,%eax
f0100b63:	0f 86 8b 01 00 00    	jbe    f0100cf4 <debuginfo_eip+0x1d7>
f0100b69:	eb 1c                	jmp    f0100b87 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b6b:	c7 44 24 08 ce 1f 10 	movl   $0xf0101fce,0x8(%esp)
f0100b72:	f0 
f0100b73:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b7a:	00 
f0100b7b:	c7 04 24 db 1f 10 f0 	movl   $0xf0101fdb,(%esp)
f0100b82:	e8 71 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b87:	80 3d ca 74 10 f0 00 	cmpb   $0x0,0xf01074ca
f0100b8e:	0f 85 67 01 00 00    	jne    f0100cfb <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b94:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b9b:	b8 74 5b 10 f0       	mov    $0xf0105b74,%eax
f0100ba0:	2d fc 21 10 f0       	sub    $0xf01021fc,%eax
f0100ba5:	c1 f8 02             	sar    $0x2,%eax
f0100ba8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100bae:	83 e8 01             	sub    $0x1,%eax
f0100bb1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bb4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bb8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bbf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bc2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bc5:	b8 fc 21 10 f0       	mov    $0xf01021fc,%eax
f0100bca:	e8 71 fe ff ff       	call   f0100a40 <stab_binsearch>
	if (lfile == 0)
f0100bcf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bd2:	85 c0                	test   %eax,%eax
f0100bd4:	0f 84 28 01 00 00    	je     f0100d02 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bda:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bdd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100be0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100be3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100be7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bee:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bf1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bf4:	b8 fc 21 10 f0       	mov    $0xf01021fc,%eax
f0100bf9:	e8 42 fe ff ff       	call   f0100a40 <stab_binsearch>

	if (lfun <= rfun) {
f0100bfe:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100c01:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100c04:	7f 2e                	jg     f0100c34 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c06:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100c09:	8d 90 fc 21 10 f0    	lea    -0xfefde04(%eax),%edx
f0100c0f:	8b 80 fc 21 10 f0    	mov    -0xfefde04(%eax),%eax
f0100c15:	b9 cb 74 10 f0       	mov    $0xf01074cb,%ecx
f0100c1a:	81 e9 75 5b 10 f0    	sub    $0xf0105b75,%ecx
f0100c20:	39 c8                	cmp    %ecx,%eax
f0100c22:	73 08                	jae    f0100c2c <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c24:	05 75 5b 10 f0       	add    $0xf0105b75,%eax
f0100c29:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c2c:	8b 42 08             	mov    0x8(%edx),%eax
f0100c2f:	89 43 10             	mov    %eax,0x10(%ebx)
f0100c32:	eb 06                	jmp    f0100c3a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c34:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c37:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c3a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c41:	00 
f0100c42:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c45:	89 04 24             	mov    %eax,(%esp)
f0100c48:	e8 47 09 00 00       	call   f0101594 <strfind>
f0100c4d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c50:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c53:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c56:	39 cf                	cmp    %ecx,%edi
f0100c58:	7c 5c                	jl     f0100cb6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100c5a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100c5d:	8d b0 fc 21 10 f0    	lea    -0xfefde04(%eax),%esi
f0100c63:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100c67:	80 fa 84             	cmp    $0x84,%dl
f0100c6a:	74 2b                	je     f0100c97 <debuginfo_eip+0x17a>
f0100c6c:	05 f0 21 10 f0       	add    $0xf01021f0,%eax
f0100c71:	eb 15                	jmp    f0100c88 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c73:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c76:	39 cf                	cmp    %ecx,%edi
f0100c78:	7c 3c                	jl     f0100cb6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100c7a:	89 c6                	mov    %eax,%esi
f0100c7c:	83 e8 0c             	sub    $0xc,%eax
f0100c7f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100c83:	80 fa 84             	cmp    $0x84,%dl
f0100c86:	74 0f                	je     f0100c97 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c88:	80 fa 64             	cmp    $0x64,%dl
f0100c8b:	75 e6                	jne    f0100c73 <debuginfo_eip+0x156>
f0100c8d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100c91:	74 e0                	je     f0100c73 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c93:	39 f9                	cmp    %edi,%ecx
f0100c95:	7f 1f                	jg     f0100cb6 <debuginfo_eip+0x199>
f0100c97:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c9a:	8b 87 fc 21 10 f0    	mov    -0xfefde04(%edi),%eax
f0100ca0:	ba cb 74 10 f0       	mov    $0xf01074cb,%edx
f0100ca5:	81 ea 75 5b 10 f0    	sub    $0xf0105b75,%edx
f0100cab:	39 d0                	cmp    %edx,%eax
f0100cad:	73 07                	jae    f0100cb6 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100caf:	05 75 5b 10 f0       	add    $0xf0105b75,%eax
f0100cb4:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cb6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cb9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100cbc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cc1:	39 ca                	cmp    %ecx,%edx
f0100cc3:	7d 5e                	jge    f0100d23 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0100cc5:	8d 42 01             	lea    0x1(%edx),%eax
f0100cc8:	39 c1                	cmp    %eax,%ecx
f0100cca:	7e 3d                	jle    f0100d09 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100ccc:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100ccf:	80 ba 00 22 10 f0 a0 	cmpb   $0xa0,-0xfefde00(%edx)
f0100cd6:	75 38                	jne    f0100d10 <debuginfo_eip+0x1f3>
f0100cd8:	81 c2 f0 21 10 f0    	add    $0xf01021f0,%edx
		     lline++)
			info->eip_fn_narg++;
f0100cde:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100ce2:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100ce5:	39 c1                	cmp    %eax,%ecx
f0100ce7:	7e 2e                	jle    f0100d17 <debuginfo_eip+0x1fa>
f0100ce9:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cec:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100cf0:	74 ec                	je     f0100cde <debuginfo_eip+0x1c1>
f0100cf2:	eb 2a                	jmp    f0100d1e <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cf4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cf9:	eb 28                	jmp    f0100d23 <debuginfo_eip+0x206>
f0100cfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d00:	eb 21                	jmp    f0100d23 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d07:	eb 1a                	jmp    f0100d23 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d09:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d0e:	eb 13                	jmp    f0100d23 <debuginfo_eip+0x206>
f0100d10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d15:	eb 0c                	jmp    f0100d23 <debuginfo_eip+0x206>
f0100d17:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1c:	eb 05                	jmp    f0100d23 <debuginfo_eip+0x206>
f0100d1e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d23:	83 c4 2c             	add    $0x2c,%esp
f0100d26:	5b                   	pop    %ebx
f0100d27:	5e                   	pop    %esi
f0100d28:	5f                   	pop    %edi
f0100d29:	5d                   	pop    %ebp
f0100d2a:	c3                   	ret    
f0100d2b:	66 90                	xchg   %ax,%ax
f0100d2d:	66 90                	xchg   %ax,%ax
f0100d2f:	90                   	nop

f0100d30 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d30:	55                   	push   %ebp
f0100d31:	89 e5                	mov    %esp,%ebp
f0100d33:	57                   	push   %edi
f0100d34:	56                   	push   %esi
f0100d35:	53                   	push   %ebx
f0100d36:	83 ec 3c             	sub    $0x3c,%esp
f0100d39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d3c:	89 d7                	mov    %edx,%edi
f0100d3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d44:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100d47:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d4a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d4d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d52:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d55:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d58:	39 f1                	cmp    %esi,%ecx
f0100d5a:	72 14                	jb     f0100d70 <printnum+0x40>
f0100d5c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d5f:	76 0f                	jbe    f0100d70 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d61:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d64:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100d67:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d6a:	85 f6                	test   %esi,%esi
f0100d6c:	7f 60                	jg     f0100dce <printnum+0x9e>
f0100d6e:	eb 72                	jmp    f0100de2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d70:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d73:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d77:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100d7a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100d7d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d81:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d85:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d89:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d8d:	89 c3                	mov    %eax,%ebx
f0100d8f:	89 d6                	mov    %edx,%esi
f0100d91:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d94:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d97:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d9b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100da2:	89 04 24             	mov    %eax,(%esp)
f0100da5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100da8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dac:	e8 4f 0a 00 00       	call   f0101800 <__udivdi3>
f0100db1:	89 d9                	mov    %ebx,%ecx
f0100db3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100db7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dbb:	89 04 24             	mov    %eax,(%esp)
f0100dbe:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dc2:	89 fa                	mov    %edi,%edx
f0100dc4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dc7:	e8 64 ff ff ff       	call   f0100d30 <printnum>
f0100dcc:	eb 14                	jmp    f0100de2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dce:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dd2:	8b 45 18             	mov    0x18(%ebp),%eax
f0100dd5:	89 04 24             	mov    %eax,(%esp)
f0100dd8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dda:	83 ee 01             	sub    $0x1,%esi
f0100ddd:	75 ef                	jne    f0100dce <printnum+0x9e>
f0100ddf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100de2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100de6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100dea:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ded:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100df0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100df4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100df8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dfb:	89 04 24             	mov    %eax,(%esp)
f0100dfe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e01:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e05:	e8 26 0b 00 00       	call   f0101930 <__umoddi3>
f0100e0a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e0e:	0f be 80 e9 1f 10 f0 	movsbl -0xfefe017(%eax),%eax
f0100e15:	89 04 24             	mov    %eax,(%esp)
f0100e18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e1b:	ff d0                	call   *%eax
}
f0100e1d:	83 c4 3c             	add    $0x3c,%esp
f0100e20:	5b                   	pop    %ebx
f0100e21:	5e                   	pop    %esi
f0100e22:	5f                   	pop    %edi
f0100e23:	5d                   	pop    %ebp
f0100e24:	c3                   	ret    

f0100e25 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e25:	55                   	push   %ebp
f0100e26:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e28:	83 fa 01             	cmp    $0x1,%edx
f0100e2b:	7e 0e                	jle    f0100e3b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e2d:	8b 10                	mov    (%eax),%edx
f0100e2f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e32:	89 08                	mov    %ecx,(%eax)
f0100e34:	8b 02                	mov    (%edx),%eax
f0100e36:	8b 52 04             	mov    0x4(%edx),%edx
f0100e39:	eb 22                	jmp    f0100e5d <getuint+0x38>
	else if (lflag)
f0100e3b:	85 d2                	test   %edx,%edx
f0100e3d:	74 10                	je     f0100e4f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e3f:	8b 10                	mov    (%eax),%edx
f0100e41:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e44:	89 08                	mov    %ecx,(%eax)
f0100e46:	8b 02                	mov    (%edx),%eax
f0100e48:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e4d:	eb 0e                	jmp    f0100e5d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e4f:	8b 10                	mov    (%eax),%edx
f0100e51:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e54:	89 08                	mov    %ecx,(%eax)
f0100e56:	8b 02                	mov    (%edx),%eax
f0100e58:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e5d:	5d                   	pop    %ebp
f0100e5e:	c3                   	ret    

f0100e5f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e5f:	55                   	push   %ebp
f0100e60:	89 e5                	mov    %esp,%ebp
f0100e62:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e65:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e69:	8b 10                	mov    (%eax),%edx
f0100e6b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e6e:	73 0a                	jae    f0100e7a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e70:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e73:	89 08                	mov    %ecx,(%eax)
f0100e75:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e78:	88 02                	mov    %al,(%edx)
}
f0100e7a:	5d                   	pop    %ebp
f0100e7b:	c3                   	ret    

f0100e7c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e7c:	55                   	push   %ebp
f0100e7d:	89 e5                	mov    %esp,%ebp
f0100e7f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e82:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e85:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e89:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e8c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e90:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e93:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e97:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e9a:	89 04 24             	mov    %eax,(%esp)
f0100e9d:	e8 02 00 00 00       	call   f0100ea4 <vprintfmt>
	va_end(ap);
}
f0100ea2:	c9                   	leave  
f0100ea3:	c3                   	ret    

f0100ea4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ea4:	55                   	push   %ebp
f0100ea5:	89 e5                	mov    %esp,%ebp
f0100ea7:	57                   	push   %edi
f0100ea8:	56                   	push   %esi
f0100ea9:	53                   	push   %ebx
f0100eaa:	83 ec 3c             	sub    $0x3c,%esp
f0100ead:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100eb0:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100eb3:	eb 18                	jmp    f0100ecd <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100eb5:	85 c0                	test   %eax,%eax
f0100eb7:	0f 84 c3 03 00 00    	je     f0101280 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
f0100ebd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ec1:	89 04 24             	mov    %eax,(%esp)
f0100ec4:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ec7:	89 f3                	mov    %esi,%ebx
f0100ec9:	eb 02                	jmp    f0100ecd <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100ecb:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ecd:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ed0:	0f b6 03             	movzbl (%ebx),%eax
f0100ed3:	83 f8 25             	cmp    $0x25,%eax
f0100ed6:	75 dd                	jne    f0100eb5 <vprintfmt+0x11>
f0100ed8:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100edc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ee3:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100eea:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100ef1:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ef6:	eb 1d                	jmp    f0100f15 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef8:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100efa:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100efe:	eb 15                	jmp    f0100f15 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f00:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f02:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100f06:	eb 0d                	jmp    f0100f15 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f0b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f0e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f15:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f18:	0f b6 06             	movzbl (%esi),%eax
f0100f1b:	0f b6 c8             	movzbl %al,%ecx
f0100f1e:	83 e8 23             	sub    $0x23,%eax
f0100f21:	3c 55                	cmp    $0x55,%al
f0100f23:	0f 87 2f 03 00 00    	ja     f0101258 <vprintfmt+0x3b4>
f0100f29:	0f b6 c0             	movzbl %al,%eax
f0100f2c:	ff 24 85 78 20 10 f0 	jmp    *-0xfefdf88(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f33:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100f36:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100f39:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f3d:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f40:	83 f9 09             	cmp    $0x9,%ecx
f0100f43:	77 50                	ja     f0100f95 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f45:	89 de                	mov    %ebx,%esi
f0100f47:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f4a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f4d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f50:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f54:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f57:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f5a:	83 fb 09             	cmp    $0x9,%ebx
f0100f5d:	76 eb                	jbe    f0100f4a <vprintfmt+0xa6>
f0100f5f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100f62:	eb 33                	jmp    f0100f97 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f64:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f67:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f6a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f6d:	8b 00                	mov    (%eax),%eax
f0100f6f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f72:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f74:	eb 21                	jmp    f0100f97 <vprintfmt+0xf3>
f0100f76:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f79:	85 c9                	test   %ecx,%ecx
f0100f7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f80:	0f 49 c1             	cmovns %ecx,%eax
f0100f83:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f86:	89 de                	mov    %ebx,%esi
f0100f88:	eb 8b                	jmp    f0100f15 <vprintfmt+0x71>
f0100f8a:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f8c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f93:	eb 80                	jmp    f0100f15 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f95:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100f97:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f9b:	0f 89 74 ff ff ff    	jns    f0100f15 <vprintfmt+0x71>
f0100fa1:	e9 62 ff ff ff       	jmp    f0100f08 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fa6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa9:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fab:	e9 65 ff ff ff       	jmp    f0100f15 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fb0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb3:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fb9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fbd:	8b 00                	mov    (%eax),%eax
f0100fbf:	89 04 24             	mov    %eax,(%esp)
f0100fc2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fc5:	e9 03 ff ff ff       	jmp    f0100ecd <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fca:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fcd:	8d 50 04             	lea    0x4(%eax),%edx
f0100fd0:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fd3:	8b 00                	mov    (%eax),%eax
f0100fd5:	99                   	cltd   
f0100fd6:	31 d0                	xor    %edx,%eax
f0100fd8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fda:	83 f8 06             	cmp    $0x6,%eax
f0100fdd:	7f 0b                	jg     f0100fea <vprintfmt+0x146>
f0100fdf:	8b 14 85 d0 21 10 f0 	mov    -0xfefde30(,%eax,4),%edx
f0100fe6:	85 d2                	test   %edx,%edx
f0100fe8:	75 20                	jne    f010100a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f0100fea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fee:	c7 44 24 08 01 20 10 	movl   $0xf0102001,0x8(%esp)
f0100ff5:	f0 
f0100ff6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ffa:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ffd:	89 04 24             	mov    %eax,(%esp)
f0101000:	e8 77 fe ff ff       	call   f0100e7c <printfmt>
f0101005:	e9 c3 fe ff ff       	jmp    f0100ecd <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
f010100a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010100e:	c7 44 24 08 0a 20 10 	movl   $0xf010200a,0x8(%esp)
f0101015:	f0 
f0101016:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010101a:	8b 45 08             	mov    0x8(%ebp),%eax
f010101d:	89 04 24             	mov    %eax,(%esp)
f0101020:	e8 57 fe ff ff       	call   f0100e7c <printfmt>
f0101025:	e9 a3 fe ff ff       	jmp    f0100ecd <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010102d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101030:	8b 45 14             	mov    0x14(%ebp),%eax
f0101033:	8d 50 04             	lea    0x4(%eax),%edx
f0101036:	89 55 14             	mov    %edx,0x14(%ebp)
f0101039:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010103b:	85 c0                	test   %eax,%eax
f010103d:	ba fa 1f 10 f0       	mov    $0xf0101ffa,%edx
f0101042:	0f 45 d0             	cmovne %eax,%edx
f0101045:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0101048:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010104c:	74 04                	je     f0101052 <vprintfmt+0x1ae>
f010104e:	85 f6                	test   %esi,%esi
f0101050:	7f 19                	jg     f010106b <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101052:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101055:	8d 70 01             	lea    0x1(%eax),%esi
f0101058:	0f b6 10             	movzbl (%eax),%edx
f010105b:	0f be c2             	movsbl %dl,%eax
f010105e:	85 c0                	test   %eax,%eax
f0101060:	0f 85 95 00 00 00    	jne    f01010fb <vprintfmt+0x257>
f0101066:	e9 85 00 00 00       	jmp    f01010f0 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010106b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010106f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101072:	89 04 24             	mov    %eax,(%esp)
f0101075:	e8 88 03 00 00       	call   f0101402 <strnlen>
f010107a:	29 c6                	sub    %eax,%esi
f010107c:	89 f0                	mov    %esi,%eax
f010107e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101081:	85 f6                	test   %esi,%esi
f0101083:	7e cd                	jle    f0101052 <vprintfmt+0x1ae>
					putch(padc, putdat);
f0101085:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101089:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010108c:	89 c3                	mov    %eax,%ebx
f010108e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101092:	89 34 24             	mov    %esi,(%esp)
f0101095:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101098:	83 eb 01             	sub    $0x1,%ebx
f010109b:	75 f1                	jne    f010108e <vprintfmt+0x1ea>
f010109d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01010a0:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010a3:	eb ad                	jmp    f0101052 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010a5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010a9:	74 1e                	je     f01010c9 <vprintfmt+0x225>
f01010ab:	0f be d2             	movsbl %dl,%edx
f01010ae:	83 ea 20             	sub    $0x20,%edx
f01010b1:	83 fa 5e             	cmp    $0x5e,%edx
f01010b4:	76 13                	jbe    f01010c9 <vprintfmt+0x225>
					putch('?', putdat);
f01010b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010bd:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010c4:	ff 55 08             	call   *0x8(%ebp)
f01010c7:	eb 0d                	jmp    f01010d6 <vprintfmt+0x232>
				else
					putch(ch, putdat);
f01010c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01010cc:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010d0:	89 04 24             	mov    %eax,(%esp)
f01010d3:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010d6:	83 ef 01             	sub    $0x1,%edi
f01010d9:	83 c6 01             	add    $0x1,%esi
f01010dc:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010e0:	0f be c2             	movsbl %dl,%eax
f01010e3:	85 c0                	test   %eax,%eax
f01010e5:	75 20                	jne    f0101107 <vprintfmt+0x263>
f01010e7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01010ea:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010ed:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010f0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010f4:	7f 25                	jg     f010111b <vprintfmt+0x277>
f01010f6:	e9 d2 fd ff ff       	jmp    f0100ecd <vprintfmt+0x29>
f01010fb:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101101:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101104:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101107:	85 db                	test   %ebx,%ebx
f0101109:	78 9a                	js     f01010a5 <vprintfmt+0x201>
f010110b:	83 eb 01             	sub    $0x1,%ebx
f010110e:	79 95                	jns    f01010a5 <vprintfmt+0x201>
f0101110:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0101113:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101116:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101119:	eb d5                	jmp    f01010f0 <vprintfmt+0x24c>
f010111b:	8b 75 08             	mov    0x8(%ebp),%esi
f010111e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101121:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101124:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101128:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010112f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101131:	83 eb 01             	sub    $0x1,%ebx
f0101134:	75 ee                	jne    f0101124 <vprintfmt+0x280>
f0101136:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101139:	e9 8f fd ff ff       	jmp    f0100ecd <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010113e:	83 fa 01             	cmp    $0x1,%edx
f0101141:	7e 16                	jle    f0101159 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
f0101143:	8b 45 14             	mov    0x14(%ebp),%eax
f0101146:	8d 50 08             	lea    0x8(%eax),%edx
f0101149:	89 55 14             	mov    %edx,0x14(%ebp)
f010114c:	8b 50 04             	mov    0x4(%eax),%edx
f010114f:	8b 00                	mov    (%eax),%eax
f0101151:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101154:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101157:	eb 32                	jmp    f010118b <vprintfmt+0x2e7>
	else if (lflag)
f0101159:	85 d2                	test   %edx,%edx
f010115b:	74 18                	je     f0101175 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
f010115d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101160:	8d 50 04             	lea    0x4(%eax),%edx
f0101163:	89 55 14             	mov    %edx,0x14(%ebp)
f0101166:	8b 30                	mov    (%eax),%esi
f0101168:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010116b:	89 f0                	mov    %esi,%eax
f010116d:	c1 f8 1f             	sar    $0x1f,%eax
f0101170:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101173:	eb 16                	jmp    f010118b <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
f0101175:	8b 45 14             	mov    0x14(%ebp),%eax
f0101178:	8d 50 04             	lea    0x4(%eax),%edx
f010117b:	89 55 14             	mov    %edx,0x14(%ebp)
f010117e:	8b 30                	mov    (%eax),%esi
f0101180:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101183:	89 f0                	mov    %esi,%eax
f0101185:	c1 f8 1f             	sar    $0x1f,%eax
f0101188:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010118b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010118e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101191:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101196:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010119a:	0f 89 80 00 00 00    	jns    f0101220 <vprintfmt+0x37c>
				putch('-', putdat);
f01011a0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a4:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011ab:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011ae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01011b1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011b4:	f7 d8                	neg    %eax
f01011b6:	83 d2 00             	adc    $0x0,%edx
f01011b9:	f7 da                	neg    %edx
			}
			base = 10;
f01011bb:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011c0:	eb 5e                	jmp    f0101220 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011c2:	8d 45 14             	lea    0x14(%ebp),%eax
f01011c5:	e8 5b fc ff ff       	call   f0100e25 <getuint>
			base = 10;
f01011ca:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011cf:	eb 4f                	jmp    f0101220 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			// It's homework1 we need to do. by Sixm
			num = getuint(&ap,lflag);
f01011d1:	8d 45 14             	lea    0x14(%ebp),%eax
f01011d4:	e8 4c fc ff ff       	call   f0100e25 <getuint>
			base = 8;
f01011d9:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011de:	eb 40                	jmp    f0101220 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
f01011e0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011e4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011eb:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011ee:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011f2:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011f9:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011fc:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ff:	8d 50 04             	lea    0x4(%eax),%edx
f0101202:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101205:	8b 00                	mov    (%eax),%eax
f0101207:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010120c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101211:	eb 0d                	jmp    f0101220 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101213:	8d 45 14             	lea    0x14(%ebp),%eax
f0101216:	e8 0a fc ff ff       	call   f0100e25 <getuint>
			base = 16;
f010121b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101220:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101224:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101228:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010122b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010122f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101233:	89 04 24             	mov    %eax,(%esp)
f0101236:	89 54 24 04          	mov    %edx,0x4(%esp)
f010123a:	89 fa                	mov    %edi,%edx
f010123c:	8b 45 08             	mov    0x8(%ebp),%eax
f010123f:	e8 ec fa ff ff       	call   f0100d30 <printnum>
			break;
f0101244:	e9 84 fc ff ff       	jmp    f0100ecd <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101249:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010124d:	89 0c 24             	mov    %ecx,(%esp)
f0101250:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101253:	e9 75 fc ff ff       	jmp    f0100ecd <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101258:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010125c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101263:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101266:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010126a:	0f 84 5b fc ff ff    	je     f0100ecb <vprintfmt+0x27>
f0101270:	89 f3                	mov    %esi,%ebx
f0101272:	83 eb 01             	sub    $0x1,%ebx
f0101275:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101279:	75 f7                	jne    f0101272 <vprintfmt+0x3ce>
f010127b:	e9 4d fc ff ff       	jmp    f0100ecd <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f0101280:	83 c4 3c             	add    $0x3c,%esp
f0101283:	5b                   	pop    %ebx
f0101284:	5e                   	pop    %esi
f0101285:	5f                   	pop    %edi
f0101286:	5d                   	pop    %ebp
f0101287:	c3                   	ret    

f0101288 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101288:	55                   	push   %ebp
f0101289:	89 e5                	mov    %esp,%ebp
f010128b:	83 ec 28             	sub    $0x28,%esp
f010128e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101291:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101294:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101297:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010129b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010129e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012a5:	85 c0                	test   %eax,%eax
f01012a7:	74 30                	je     f01012d9 <vsnprintf+0x51>
f01012a9:	85 d2                	test   %edx,%edx
f01012ab:	7e 2c                	jle    f01012d9 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01012b7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012bb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c2:	c7 04 24 5f 0e 10 f0 	movl   $0xf0100e5f,(%esp)
f01012c9:	e8 d6 fb ff ff       	call   f0100ea4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012d1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012d7:	eb 05                	jmp    f01012de <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012d9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012de:	c9                   	leave  
f01012df:	c3                   	ret    

f01012e0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012e0:	55                   	push   %ebp
f01012e1:	89 e5                	mov    %esp,%ebp
f01012e3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012e6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012ed:	8b 45 10             	mov    0x10(%ebp),%eax
f01012f0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01012fe:	89 04 24             	mov    %eax,(%esp)
f0101301:	e8 82 ff ff ff       	call   f0101288 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101306:	c9                   	leave  
f0101307:	c3                   	ret    
f0101308:	66 90                	xchg   %ax,%ax
f010130a:	66 90                	xchg   %ax,%ax
f010130c:	66 90                	xchg   %ax,%ax
f010130e:	66 90                	xchg   %ax,%ax

f0101310 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101310:	55                   	push   %ebp
f0101311:	89 e5                	mov    %esp,%ebp
f0101313:	57                   	push   %edi
f0101314:	56                   	push   %esi
f0101315:	53                   	push   %ebx
f0101316:	83 ec 1c             	sub    $0x1c,%esp
f0101319:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010131c:	85 c0                	test   %eax,%eax
f010131e:	74 10                	je     f0101330 <readline+0x20>
		cprintf("%s", prompt);
f0101320:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101324:	c7 04 24 0a 20 10 f0 	movl   $0xf010200a,(%esp)
f010132b:	e8 f0 f6 ff ff       	call   f0100a20 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101330:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101337:	e8 4d f3 ff ff       	call   f0100689 <iscons>
f010133c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010133e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101343:	e8 30 f3 ff ff       	call   f0100678 <getchar>
f0101348:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010134a:	85 c0                	test   %eax,%eax
f010134c:	79 17                	jns    f0101365 <readline+0x55>
			cprintf("read error: %e\n", c);
f010134e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101352:	c7 04 24 ec 21 10 f0 	movl   $0xf01021ec,(%esp)
f0101359:	e8 c2 f6 ff ff       	call   f0100a20 <cprintf>
			return NULL;
f010135e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101363:	eb 6d                	jmp    f01013d2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101365:	83 f8 7f             	cmp    $0x7f,%eax
f0101368:	74 05                	je     f010136f <readline+0x5f>
f010136a:	83 f8 08             	cmp    $0x8,%eax
f010136d:	75 19                	jne    f0101388 <readline+0x78>
f010136f:	85 f6                	test   %esi,%esi
f0101371:	7e 15                	jle    f0101388 <readline+0x78>
			if (echoing)
f0101373:	85 ff                	test   %edi,%edi
f0101375:	74 0c                	je     f0101383 <readline+0x73>
				cputchar('\b');
f0101377:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010137e:	e8 e5 f2 ff ff       	call   f0100668 <cputchar>
			i--;
f0101383:	83 ee 01             	sub    $0x1,%esi
f0101386:	eb bb                	jmp    f0101343 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101388:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010138e:	7f 1c                	jg     f01013ac <readline+0x9c>
f0101390:	83 fb 1f             	cmp    $0x1f,%ebx
f0101393:	7e 17                	jle    f01013ac <readline+0x9c>
			if (echoing)
f0101395:	85 ff                	test   %edi,%edi
f0101397:	74 08                	je     f01013a1 <readline+0x91>
				cputchar(c);
f0101399:	89 1c 24             	mov    %ebx,(%esp)
f010139c:	e8 c7 f2 ff ff       	call   f0100668 <cputchar>
			buf[i++] = c;
f01013a1:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f01013a7:	8d 76 01             	lea    0x1(%esi),%esi
f01013aa:	eb 97                	jmp    f0101343 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013ac:	83 fb 0d             	cmp    $0xd,%ebx
f01013af:	74 05                	je     f01013b6 <readline+0xa6>
f01013b1:	83 fb 0a             	cmp    $0xa,%ebx
f01013b4:	75 8d                	jne    f0101343 <readline+0x33>
			if (echoing)
f01013b6:	85 ff                	test   %edi,%edi
f01013b8:	74 0c                	je     f01013c6 <readline+0xb6>
				cputchar('\n');
f01013ba:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013c1:	e8 a2 f2 ff ff       	call   f0100668 <cputchar>
			buf[i] = 0;
f01013c6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01013cd:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f01013d2:	83 c4 1c             	add    $0x1c,%esp
f01013d5:	5b                   	pop    %ebx
f01013d6:	5e                   	pop    %esi
f01013d7:	5f                   	pop    %edi
f01013d8:	5d                   	pop    %ebp
f01013d9:	c3                   	ret    
f01013da:	66 90                	xchg   %ax,%ax
f01013dc:	66 90                	xchg   %ax,%ax
f01013de:	66 90                	xchg   %ax,%ax

f01013e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013e0:	55                   	push   %ebp
f01013e1:	89 e5                	mov    %esp,%ebp
f01013e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013e6:	80 3a 00             	cmpb   $0x0,(%edx)
f01013e9:	74 10                	je     f01013fb <strlen+0x1b>
f01013eb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01013f0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013f3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013f7:	75 f7                	jne    f01013f0 <strlen+0x10>
f01013f9:	eb 05                	jmp    f0101400 <strlen+0x20>
f01013fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	53                   	push   %ebx
f0101406:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101409:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010140c:	85 c9                	test   %ecx,%ecx
f010140e:	74 1c                	je     f010142c <strnlen+0x2a>
f0101410:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101413:	74 1e                	je     f0101433 <strnlen+0x31>
f0101415:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010141a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010141c:	39 ca                	cmp    %ecx,%edx
f010141e:	74 18                	je     f0101438 <strnlen+0x36>
f0101420:	83 c2 01             	add    $0x1,%edx
f0101423:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101428:	75 f0                	jne    f010141a <strnlen+0x18>
f010142a:	eb 0c                	jmp    f0101438 <strnlen+0x36>
f010142c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101431:	eb 05                	jmp    f0101438 <strnlen+0x36>
f0101433:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101438:	5b                   	pop    %ebx
f0101439:	5d                   	pop    %ebp
f010143a:	c3                   	ret    

f010143b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010143b:	55                   	push   %ebp
f010143c:	89 e5                	mov    %esp,%ebp
f010143e:	53                   	push   %ebx
f010143f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101442:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101445:	89 c2                	mov    %eax,%edx
f0101447:	83 c2 01             	add    $0x1,%edx
f010144a:	83 c1 01             	add    $0x1,%ecx
f010144d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101451:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101454:	84 db                	test   %bl,%bl
f0101456:	75 ef                	jne    f0101447 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101458:	5b                   	pop    %ebx
f0101459:	5d                   	pop    %ebp
f010145a:	c3                   	ret    

f010145b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010145b:	55                   	push   %ebp
f010145c:	89 e5                	mov    %esp,%ebp
f010145e:	56                   	push   %esi
f010145f:	53                   	push   %ebx
f0101460:	8b 75 08             	mov    0x8(%ebp),%esi
f0101463:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101466:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101469:	85 db                	test   %ebx,%ebx
f010146b:	74 17                	je     f0101484 <strncpy+0x29>
f010146d:	01 f3                	add    %esi,%ebx
f010146f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101471:	83 c1 01             	add    $0x1,%ecx
f0101474:	0f b6 02             	movzbl (%edx),%eax
f0101477:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010147a:	80 3a 01             	cmpb   $0x1,(%edx)
f010147d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101480:	39 d9                	cmp    %ebx,%ecx
f0101482:	75 ed                	jne    f0101471 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101484:	89 f0                	mov    %esi,%eax
f0101486:	5b                   	pop    %ebx
f0101487:	5e                   	pop    %esi
f0101488:	5d                   	pop    %ebp
f0101489:	c3                   	ret    

f010148a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010148a:	55                   	push   %ebp
f010148b:	89 e5                	mov    %esp,%ebp
f010148d:	57                   	push   %edi
f010148e:	56                   	push   %esi
f010148f:	53                   	push   %ebx
f0101490:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101493:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101496:	8b 75 10             	mov    0x10(%ebp),%esi
f0101499:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010149b:	85 f6                	test   %esi,%esi
f010149d:	74 34                	je     f01014d3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010149f:	83 fe 01             	cmp    $0x1,%esi
f01014a2:	74 26                	je     f01014ca <strlcpy+0x40>
f01014a4:	0f b6 0b             	movzbl (%ebx),%ecx
f01014a7:	84 c9                	test   %cl,%cl
f01014a9:	74 23                	je     f01014ce <strlcpy+0x44>
f01014ab:	83 ee 02             	sub    $0x2,%esi
f01014ae:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f01014b3:	83 c0 01             	add    $0x1,%eax
f01014b6:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014b9:	39 f2                	cmp    %esi,%edx
f01014bb:	74 13                	je     f01014d0 <strlcpy+0x46>
f01014bd:	83 c2 01             	add    $0x1,%edx
f01014c0:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014c4:	84 c9                	test   %cl,%cl
f01014c6:	75 eb                	jne    f01014b3 <strlcpy+0x29>
f01014c8:	eb 06                	jmp    f01014d0 <strlcpy+0x46>
f01014ca:	89 f8                	mov    %edi,%eax
f01014cc:	eb 02                	jmp    f01014d0 <strlcpy+0x46>
f01014ce:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01014d0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014d3:	29 f8                	sub    %edi,%eax
}
f01014d5:	5b                   	pop    %ebx
f01014d6:	5e                   	pop    %esi
f01014d7:	5f                   	pop    %edi
f01014d8:	5d                   	pop    %ebp
f01014d9:	c3                   	ret    

f01014da <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014da:	55                   	push   %ebp
f01014db:	89 e5                	mov    %esp,%ebp
f01014dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014e0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014e3:	0f b6 01             	movzbl (%ecx),%eax
f01014e6:	84 c0                	test   %al,%al
f01014e8:	74 15                	je     f01014ff <strcmp+0x25>
f01014ea:	3a 02                	cmp    (%edx),%al
f01014ec:	75 11                	jne    f01014ff <strcmp+0x25>
		p++, q++;
f01014ee:	83 c1 01             	add    $0x1,%ecx
f01014f1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014f4:	0f b6 01             	movzbl (%ecx),%eax
f01014f7:	84 c0                	test   %al,%al
f01014f9:	74 04                	je     f01014ff <strcmp+0x25>
f01014fb:	3a 02                	cmp    (%edx),%al
f01014fd:	74 ef                	je     f01014ee <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014ff:	0f b6 c0             	movzbl %al,%eax
f0101502:	0f b6 12             	movzbl (%edx),%edx
f0101505:	29 d0                	sub    %edx,%eax
}
f0101507:	5d                   	pop    %ebp
f0101508:	c3                   	ret    

f0101509 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101509:	55                   	push   %ebp
f010150a:	89 e5                	mov    %esp,%ebp
f010150c:	56                   	push   %esi
f010150d:	53                   	push   %ebx
f010150e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101511:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101514:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0101517:	85 f6                	test   %esi,%esi
f0101519:	74 29                	je     f0101544 <strncmp+0x3b>
f010151b:	0f b6 03             	movzbl (%ebx),%eax
f010151e:	84 c0                	test   %al,%al
f0101520:	74 30                	je     f0101552 <strncmp+0x49>
f0101522:	3a 02                	cmp    (%edx),%al
f0101524:	75 2c                	jne    f0101552 <strncmp+0x49>
f0101526:	8d 43 01             	lea    0x1(%ebx),%eax
f0101529:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f010152b:	89 c3                	mov    %eax,%ebx
f010152d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101530:	39 f0                	cmp    %esi,%eax
f0101532:	74 17                	je     f010154b <strncmp+0x42>
f0101534:	0f b6 08             	movzbl (%eax),%ecx
f0101537:	84 c9                	test   %cl,%cl
f0101539:	74 17                	je     f0101552 <strncmp+0x49>
f010153b:	83 c0 01             	add    $0x1,%eax
f010153e:	3a 0a                	cmp    (%edx),%cl
f0101540:	74 e9                	je     f010152b <strncmp+0x22>
f0101542:	eb 0e                	jmp    f0101552 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101544:	b8 00 00 00 00       	mov    $0x0,%eax
f0101549:	eb 0f                	jmp    f010155a <strncmp+0x51>
f010154b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101550:	eb 08                	jmp    f010155a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101552:	0f b6 03             	movzbl (%ebx),%eax
f0101555:	0f b6 12             	movzbl (%edx),%edx
f0101558:	29 d0                	sub    %edx,%eax
}
f010155a:	5b                   	pop    %ebx
f010155b:	5e                   	pop    %esi
f010155c:	5d                   	pop    %ebp
f010155d:	c3                   	ret    

f010155e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010155e:	55                   	push   %ebp
f010155f:	89 e5                	mov    %esp,%ebp
f0101561:	53                   	push   %ebx
f0101562:	8b 45 08             	mov    0x8(%ebp),%eax
f0101565:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101568:	0f b6 18             	movzbl (%eax),%ebx
f010156b:	84 db                	test   %bl,%bl
f010156d:	74 1d                	je     f010158c <strchr+0x2e>
f010156f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101571:	38 d3                	cmp    %dl,%bl
f0101573:	75 06                	jne    f010157b <strchr+0x1d>
f0101575:	eb 1a                	jmp    f0101591 <strchr+0x33>
f0101577:	38 ca                	cmp    %cl,%dl
f0101579:	74 16                	je     f0101591 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010157b:	83 c0 01             	add    $0x1,%eax
f010157e:	0f b6 10             	movzbl (%eax),%edx
f0101581:	84 d2                	test   %dl,%dl
f0101583:	75 f2                	jne    f0101577 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101585:	b8 00 00 00 00       	mov    $0x0,%eax
f010158a:	eb 05                	jmp    f0101591 <strchr+0x33>
f010158c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101591:	5b                   	pop    %ebx
f0101592:	5d                   	pop    %ebp
f0101593:	c3                   	ret    

f0101594 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101594:	55                   	push   %ebp
f0101595:	89 e5                	mov    %esp,%ebp
f0101597:	53                   	push   %ebx
f0101598:	8b 45 08             	mov    0x8(%ebp),%eax
f010159b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010159e:	0f b6 18             	movzbl (%eax),%ebx
f01015a1:	84 db                	test   %bl,%bl
f01015a3:	74 17                	je     f01015bc <strfind+0x28>
f01015a5:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01015a7:	38 d3                	cmp    %dl,%bl
f01015a9:	75 07                	jne    f01015b2 <strfind+0x1e>
f01015ab:	eb 0f                	jmp    f01015bc <strfind+0x28>
f01015ad:	38 ca                	cmp    %cl,%dl
f01015af:	90                   	nop
f01015b0:	74 0a                	je     f01015bc <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01015b2:	83 c0 01             	add    $0x1,%eax
f01015b5:	0f b6 10             	movzbl (%eax),%edx
f01015b8:	84 d2                	test   %dl,%dl
f01015ba:	75 f1                	jne    f01015ad <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01015bc:	5b                   	pop    %ebx
f01015bd:	5d                   	pop    %ebp
f01015be:	c3                   	ret    

f01015bf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015bf:	55                   	push   %ebp
f01015c0:	89 e5                	mov    %esp,%ebp
f01015c2:	57                   	push   %edi
f01015c3:	56                   	push   %esi
f01015c4:	53                   	push   %ebx
f01015c5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015c8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015cb:	85 c9                	test   %ecx,%ecx
f01015cd:	74 36                	je     f0101605 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015cf:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015d5:	75 28                	jne    f01015ff <memset+0x40>
f01015d7:	f6 c1 03             	test   $0x3,%cl
f01015da:	75 23                	jne    f01015ff <memset+0x40>
		c &= 0xFF;
f01015dc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015e0:	89 d3                	mov    %edx,%ebx
f01015e2:	c1 e3 08             	shl    $0x8,%ebx
f01015e5:	89 d6                	mov    %edx,%esi
f01015e7:	c1 e6 18             	shl    $0x18,%esi
f01015ea:	89 d0                	mov    %edx,%eax
f01015ec:	c1 e0 10             	shl    $0x10,%eax
f01015ef:	09 f0                	or     %esi,%eax
f01015f1:	09 c2                	or     %eax,%edx
f01015f3:	89 d0                	mov    %edx,%eax
f01015f5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015f7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015fa:	fc                   	cld    
f01015fb:	f3 ab                	rep stos %eax,%es:(%edi)
f01015fd:	eb 06                	jmp    f0101605 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015ff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101602:	fc                   	cld    
f0101603:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101605:	89 f8                	mov    %edi,%eax
f0101607:	5b                   	pop    %ebx
f0101608:	5e                   	pop    %esi
f0101609:	5f                   	pop    %edi
f010160a:	5d                   	pop    %ebp
f010160b:	c3                   	ret    

f010160c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010160c:	55                   	push   %ebp
f010160d:	89 e5                	mov    %esp,%ebp
f010160f:	57                   	push   %edi
f0101610:	56                   	push   %esi
f0101611:	8b 45 08             	mov    0x8(%ebp),%eax
f0101614:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101617:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010161a:	39 c6                	cmp    %eax,%esi
f010161c:	73 35                	jae    f0101653 <memmove+0x47>
f010161e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101621:	39 d0                	cmp    %edx,%eax
f0101623:	73 2e                	jae    f0101653 <memmove+0x47>
		s += n;
		d += n;
f0101625:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101628:	89 d6                	mov    %edx,%esi
f010162a:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010162c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101632:	75 13                	jne    f0101647 <memmove+0x3b>
f0101634:	f6 c1 03             	test   $0x3,%cl
f0101637:	75 0e                	jne    f0101647 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101639:	83 ef 04             	sub    $0x4,%edi
f010163c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010163f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101642:	fd                   	std    
f0101643:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101645:	eb 09                	jmp    f0101650 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101647:	83 ef 01             	sub    $0x1,%edi
f010164a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010164d:	fd                   	std    
f010164e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101650:	fc                   	cld    
f0101651:	eb 1d                	jmp    f0101670 <memmove+0x64>
f0101653:	89 f2                	mov    %esi,%edx
f0101655:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101657:	f6 c2 03             	test   $0x3,%dl
f010165a:	75 0f                	jne    f010166b <memmove+0x5f>
f010165c:	f6 c1 03             	test   $0x3,%cl
f010165f:	75 0a                	jne    f010166b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101661:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101664:	89 c7                	mov    %eax,%edi
f0101666:	fc                   	cld    
f0101667:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101669:	eb 05                	jmp    f0101670 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010166b:	89 c7                	mov    %eax,%edi
f010166d:	fc                   	cld    
f010166e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101670:	5e                   	pop    %esi
f0101671:	5f                   	pop    %edi
f0101672:	5d                   	pop    %ebp
f0101673:	c3                   	ret    

f0101674 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101674:	55                   	push   %ebp
f0101675:	89 e5                	mov    %esp,%ebp
f0101677:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010167a:	8b 45 10             	mov    0x10(%ebp),%eax
f010167d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101681:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101684:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101688:	8b 45 08             	mov    0x8(%ebp),%eax
f010168b:	89 04 24             	mov    %eax,(%esp)
f010168e:	e8 79 ff ff ff       	call   f010160c <memmove>
}
f0101693:	c9                   	leave  
f0101694:	c3                   	ret    

f0101695 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101695:	55                   	push   %ebp
f0101696:	89 e5                	mov    %esp,%ebp
f0101698:	57                   	push   %edi
f0101699:	56                   	push   %esi
f010169a:	53                   	push   %ebx
f010169b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010169e:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016a1:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016a4:	8d 78 ff             	lea    -0x1(%eax),%edi
f01016a7:	85 c0                	test   %eax,%eax
f01016a9:	74 36                	je     f01016e1 <memcmp+0x4c>
		if (*s1 != *s2)
f01016ab:	0f b6 03             	movzbl (%ebx),%eax
f01016ae:	0f b6 0e             	movzbl (%esi),%ecx
f01016b1:	ba 00 00 00 00       	mov    $0x0,%edx
f01016b6:	38 c8                	cmp    %cl,%al
f01016b8:	74 1c                	je     f01016d6 <memcmp+0x41>
f01016ba:	eb 10                	jmp    f01016cc <memcmp+0x37>
f01016bc:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01016c1:	83 c2 01             	add    $0x1,%edx
f01016c4:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01016c8:	38 c8                	cmp    %cl,%al
f01016ca:	74 0a                	je     f01016d6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01016cc:	0f b6 c0             	movzbl %al,%eax
f01016cf:	0f b6 c9             	movzbl %cl,%ecx
f01016d2:	29 c8                	sub    %ecx,%eax
f01016d4:	eb 10                	jmp    f01016e6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016d6:	39 fa                	cmp    %edi,%edx
f01016d8:	75 e2                	jne    f01016bc <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016da:	b8 00 00 00 00       	mov    $0x0,%eax
f01016df:	eb 05                	jmp    f01016e6 <memcmp+0x51>
f01016e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016e6:	5b                   	pop    %ebx
f01016e7:	5e                   	pop    %esi
f01016e8:	5f                   	pop    %edi
f01016e9:	5d                   	pop    %ebp
f01016ea:	c3                   	ret    

f01016eb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016eb:	55                   	push   %ebp
f01016ec:	89 e5                	mov    %esp,%ebp
f01016ee:	53                   	push   %ebx
f01016ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01016f2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01016f5:	89 c2                	mov    %eax,%edx
f01016f7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016fa:	39 d0                	cmp    %edx,%eax
f01016fc:	73 14                	jae    f0101712 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016fe:	89 d9                	mov    %ebx,%ecx
f0101700:	38 18                	cmp    %bl,(%eax)
f0101702:	75 06                	jne    f010170a <memfind+0x1f>
f0101704:	eb 0c                	jmp    f0101712 <memfind+0x27>
f0101706:	38 08                	cmp    %cl,(%eax)
f0101708:	74 08                	je     f0101712 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010170a:	83 c0 01             	add    $0x1,%eax
f010170d:	39 d0                	cmp    %edx,%eax
f010170f:	90                   	nop
f0101710:	75 f4                	jne    f0101706 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101712:	5b                   	pop    %ebx
f0101713:	5d                   	pop    %ebp
f0101714:	c3                   	ret    

f0101715 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101715:	55                   	push   %ebp
f0101716:	89 e5                	mov    %esp,%ebp
f0101718:	57                   	push   %edi
f0101719:	56                   	push   %esi
f010171a:	53                   	push   %ebx
f010171b:	8b 55 08             	mov    0x8(%ebp),%edx
f010171e:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101721:	0f b6 0a             	movzbl (%edx),%ecx
f0101724:	80 f9 09             	cmp    $0x9,%cl
f0101727:	74 05                	je     f010172e <strtol+0x19>
f0101729:	80 f9 20             	cmp    $0x20,%cl
f010172c:	75 10                	jne    f010173e <strtol+0x29>
		s++;
f010172e:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101731:	0f b6 0a             	movzbl (%edx),%ecx
f0101734:	80 f9 09             	cmp    $0x9,%cl
f0101737:	74 f5                	je     f010172e <strtol+0x19>
f0101739:	80 f9 20             	cmp    $0x20,%cl
f010173c:	74 f0                	je     f010172e <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f010173e:	80 f9 2b             	cmp    $0x2b,%cl
f0101741:	75 0a                	jne    f010174d <strtol+0x38>
		s++;
f0101743:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101746:	bf 00 00 00 00       	mov    $0x0,%edi
f010174b:	eb 11                	jmp    f010175e <strtol+0x49>
f010174d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101752:	80 f9 2d             	cmp    $0x2d,%cl
f0101755:	75 07                	jne    f010175e <strtol+0x49>
		s++, neg = 1;
f0101757:	83 c2 01             	add    $0x1,%edx
f010175a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010175e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101763:	75 15                	jne    f010177a <strtol+0x65>
f0101765:	80 3a 30             	cmpb   $0x30,(%edx)
f0101768:	75 10                	jne    f010177a <strtol+0x65>
f010176a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010176e:	75 0a                	jne    f010177a <strtol+0x65>
		s += 2, base = 16;
f0101770:	83 c2 02             	add    $0x2,%edx
f0101773:	b8 10 00 00 00       	mov    $0x10,%eax
f0101778:	eb 10                	jmp    f010178a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010177a:	85 c0                	test   %eax,%eax
f010177c:	75 0c                	jne    f010178a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010177e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101780:	80 3a 30             	cmpb   $0x30,(%edx)
f0101783:	75 05                	jne    f010178a <strtol+0x75>
		s++, base = 8;
f0101785:	83 c2 01             	add    $0x1,%edx
f0101788:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010178a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010178f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101792:	0f b6 0a             	movzbl (%edx),%ecx
f0101795:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101798:	89 f0                	mov    %esi,%eax
f010179a:	3c 09                	cmp    $0x9,%al
f010179c:	77 08                	ja     f01017a6 <strtol+0x91>
			dig = *s - '0';
f010179e:	0f be c9             	movsbl %cl,%ecx
f01017a1:	83 e9 30             	sub    $0x30,%ecx
f01017a4:	eb 20                	jmp    f01017c6 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f01017a6:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01017a9:	89 f0                	mov    %esi,%eax
f01017ab:	3c 19                	cmp    $0x19,%al
f01017ad:	77 08                	ja     f01017b7 <strtol+0xa2>
			dig = *s - 'a' + 10;
f01017af:	0f be c9             	movsbl %cl,%ecx
f01017b2:	83 e9 57             	sub    $0x57,%ecx
f01017b5:	eb 0f                	jmp    f01017c6 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f01017b7:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01017ba:	89 f0                	mov    %esi,%eax
f01017bc:	3c 19                	cmp    $0x19,%al
f01017be:	77 16                	ja     f01017d6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01017c0:	0f be c9             	movsbl %cl,%ecx
f01017c3:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017c6:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01017c9:	7d 0f                	jge    f01017da <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01017cb:	83 c2 01             	add    $0x1,%edx
f01017ce:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01017d2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01017d4:	eb bc                	jmp    f0101792 <strtol+0x7d>
f01017d6:	89 d8                	mov    %ebx,%eax
f01017d8:	eb 02                	jmp    f01017dc <strtol+0xc7>
f01017da:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01017dc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017e0:	74 05                	je     f01017e7 <strtol+0xd2>
		*endptr = (char *) s;
f01017e2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017e5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01017e7:	f7 d8                	neg    %eax
f01017e9:	85 ff                	test   %edi,%edi
f01017eb:	0f 44 c3             	cmove  %ebx,%eax
}
f01017ee:	5b                   	pop    %ebx
f01017ef:	5e                   	pop    %esi
f01017f0:	5f                   	pop    %edi
f01017f1:	5d                   	pop    %ebp
f01017f2:	c3                   	ret    
f01017f3:	66 90                	xchg   %ax,%ax
f01017f5:	66 90                	xchg   %ax,%ax
f01017f7:	66 90                	xchg   %ax,%ax
f01017f9:	66 90                	xchg   %ax,%ax
f01017fb:	66 90                	xchg   %ax,%ax
f01017fd:	66 90                	xchg   %ax,%ax
f01017ff:	90                   	nop

f0101800 <__udivdi3>:
f0101800:	55                   	push   %ebp
f0101801:	57                   	push   %edi
f0101802:	56                   	push   %esi
f0101803:	83 ec 0c             	sub    $0xc,%esp
f0101806:	8b 44 24 28          	mov    0x28(%esp),%eax
f010180a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010180e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101812:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101816:	85 c0                	test   %eax,%eax
f0101818:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010181c:	89 ea                	mov    %ebp,%edx
f010181e:	89 0c 24             	mov    %ecx,(%esp)
f0101821:	75 2d                	jne    f0101850 <__udivdi3+0x50>
f0101823:	39 e9                	cmp    %ebp,%ecx
f0101825:	77 61                	ja     f0101888 <__udivdi3+0x88>
f0101827:	85 c9                	test   %ecx,%ecx
f0101829:	89 ce                	mov    %ecx,%esi
f010182b:	75 0b                	jne    f0101838 <__udivdi3+0x38>
f010182d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101832:	31 d2                	xor    %edx,%edx
f0101834:	f7 f1                	div    %ecx
f0101836:	89 c6                	mov    %eax,%esi
f0101838:	31 d2                	xor    %edx,%edx
f010183a:	89 e8                	mov    %ebp,%eax
f010183c:	f7 f6                	div    %esi
f010183e:	89 c5                	mov    %eax,%ebp
f0101840:	89 f8                	mov    %edi,%eax
f0101842:	f7 f6                	div    %esi
f0101844:	89 ea                	mov    %ebp,%edx
f0101846:	83 c4 0c             	add    $0xc,%esp
f0101849:	5e                   	pop    %esi
f010184a:	5f                   	pop    %edi
f010184b:	5d                   	pop    %ebp
f010184c:	c3                   	ret    
f010184d:	8d 76 00             	lea    0x0(%esi),%esi
f0101850:	39 e8                	cmp    %ebp,%eax
f0101852:	77 24                	ja     f0101878 <__udivdi3+0x78>
f0101854:	0f bd e8             	bsr    %eax,%ebp
f0101857:	83 f5 1f             	xor    $0x1f,%ebp
f010185a:	75 3c                	jne    f0101898 <__udivdi3+0x98>
f010185c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101860:	39 34 24             	cmp    %esi,(%esp)
f0101863:	0f 86 9f 00 00 00    	jbe    f0101908 <__udivdi3+0x108>
f0101869:	39 d0                	cmp    %edx,%eax
f010186b:	0f 82 97 00 00 00    	jb     f0101908 <__udivdi3+0x108>
f0101871:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101878:	31 d2                	xor    %edx,%edx
f010187a:	31 c0                	xor    %eax,%eax
f010187c:	83 c4 0c             	add    $0xc,%esp
f010187f:	5e                   	pop    %esi
f0101880:	5f                   	pop    %edi
f0101881:	5d                   	pop    %ebp
f0101882:	c3                   	ret    
f0101883:	90                   	nop
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	89 f8                	mov    %edi,%eax
f010188a:	f7 f1                	div    %ecx
f010188c:	31 d2                	xor    %edx,%edx
f010188e:	83 c4 0c             	add    $0xc,%esp
f0101891:	5e                   	pop    %esi
f0101892:	5f                   	pop    %edi
f0101893:	5d                   	pop    %ebp
f0101894:	c3                   	ret    
f0101895:	8d 76 00             	lea    0x0(%esi),%esi
f0101898:	89 e9                	mov    %ebp,%ecx
f010189a:	8b 3c 24             	mov    (%esp),%edi
f010189d:	d3 e0                	shl    %cl,%eax
f010189f:	89 c6                	mov    %eax,%esi
f01018a1:	b8 20 00 00 00       	mov    $0x20,%eax
f01018a6:	29 e8                	sub    %ebp,%eax
f01018a8:	89 c1                	mov    %eax,%ecx
f01018aa:	d3 ef                	shr    %cl,%edi
f01018ac:	89 e9                	mov    %ebp,%ecx
f01018ae:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01018b2:	8b 3c 24             	mov    (%esp),%edi
f01018b5:	09 74 24 08          	or     %esi,0x8(%esp)
f01018b9:	89 d6                	mov    %edx,%esi
f01018bb:	d3 e7                	shl    %cl,%edi
f01018bd:	89 c1                	mov    %eax,%ecx
f01018bf:	89 3c 24             	mov    %edi,(%esp)
f01018c2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018c6:	d3 ee                	shr    %cl,%esi
f01018c8:	89 e9                	mov    %ebp,%ecx
f01018ca:	d3 e2                	shl    %cl,%edx
f01018cc:	89 c1                	mov    %eax,%ecx
f01018ce:	d3 ef                	shr    %cl,%edi
f01018d0:	09 d7                	or     %edx,%edi
f01018d2:	89 f2                	mov    %esi,%edx
f01018d4:	89 f8                	mov    %edi,%eax
f01018d6:	f7 74 24 08          	divl   0x8(%esp)
f01018da:	89 d6                	mov    %edx,%esi
f01018dc:	89 c7                	mov    %eax,%edi
f01018de:	f7 24 24             	mull   (%esp)
f01018e1:	39 d6                	cmp    %edx,%esi
f01018e3:	89 14 24             	mov    %edx,(%esp)
f01018e6:	72 30                	jb     f0101918 <__udivdi3+0x118>
f01018e8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018ec:	89 e9                	mov    %ebp,%ecx
f01018ee:	d3 e2                	shl    %cl,%edx
f01018f0:	39 c2                	cmp    %eax,%edx
f01018f2:	73 05                	jae    f01018f9 <__udivdi3+0xf9>
f01018f4:	3b 34 24             	cmp    (%esp),%esi
f01018f7:	74 1f                	je     f0101918 <__udivdi3+0x118>
f01018f9:	89 f8                	mov    %edi,%eax
f01018fb:	31 d2                	xor    %edx,%edx
f01018fd:	e9 7a ff ff ff       	jmp    f010187c <__udivdi3+0x7c>
f0101902:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101908:	31 d2                	xor    %edx,%edx
f010190a:	b8 01 00 00 00       	mov    $0x1,%eax
f010190f:	e9 68 ff ff ff       	jmp    f010187c <__udivdi3+0x7c>
f0101914:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101918:	8d 47 ff             	lea    -0x1(%edi),%eax
f010191b:	31 d2                	xor    %edx,%edx
f010191d:	83 c4 0c             	add    $0xc,%esp
f0101920:	5e                   	pop    %esi
f0101921:	5f                   	pop    %edi
f0101922:	5d                   	pop    %ebp
f0101923:	c3                   	ret    
f0101924:	66 90                	xchg   %ax,%ax
f0101926:	66 90                	xchg   %ax,%ax
f0101928:	66 90                	xchg   %ax,%ax
f010192a:	66 90                	xchg   %ax,%ax
f010192c:	66 90                	xchg   %ax,%ax
f010192e:	66 90                	xchg   %ax,%ax

f0101930 <__umoddi3>:
f0101930:	55                   	push   %ebp
f0101931:	57                   	push   %edi
f0101932:	56                   	push   %esi
f0101933:	83 ec 14             	sub    $0x14,%esp
f0101936:	8b 44 24 28          	mov    0x28(%esp),%eax
f010193a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010193e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101942:	89 c7                	mov    %eax,%edi
f0101944:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101948:	8b 44 24 30          	mov    0x30(%esp),%eax
f010194c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101950:	89 34 24             	mov    %esi,(%esp)
f0101953:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101957:	85 c0                	test   %eax,%eax
f0101959:	89 c2                	mov    %eax,%edx
f010195b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010195f:	75 17                	jne    f0101978 <__umoddi3+0x48>
f0101961:	39 fe                	cmp    %edi,%esi
f0101963:	76 4b                	jbe    f01019b0 <__umoddi3+0x80>
f0101965:	89 c8                	mov    %ecx,%eax
f0101967:	89 fa                	mov    %edi,%edx
f0101969:	f7 f6                	div    %esi
f010196b:	89 d0                	mov    %edx,%eax
f010196d:	31 d2                	xor    %edx,%edx
f010196f:	83 c4 14             	add    $0x14,%esp
f0101972:	5e                   	pop    %esi
f0101973:	5f                   	pop    %edi
f0101974:	5d                   	pop    %ebp
f0101975:	c3                   	ret    
f0101976:	66 90                	xchg   %ax,%ax
f0101978:	39 f8                	cmp    %edi,%eax
f010197a:	77 54                	ja     f01019d0 <__umoddi3+0xa0>
f010197c:	0f bd e8             	bsr    %eax,%ebp
f010197f:	83 f5 1f             	xor    $0x1f,%ebp
f0101982:	75 5c                	jne    f01019e0 <__umoddi3+0xb0>
f0101984:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101988:	39 3c 24             	cmp    %edi,(%esp)
f010198b:	0f 87 e7 00 00 00    	ja     f0101a78 <__umoddi3+0x148>
f0101991:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101995:	29 f1                	sub    %esi,%ecx
f0101997:	19 c7                	sbb    %eax,%edi
f0101999:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010199d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019a1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019a5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01019a9:	83 c4 14             	add    $0x14,%esp
f01019ac:	5e                   	pop    %esi
f01019ad:	5f                   	pop    %edi
f01019ae:	5d                   	pop    %ebp
f01019af:	c3                   	ret    
f01019b0:	85 f6                	test   %esi,%esi
f01019b2:	89 f5                	mov    %esi,%ebp
f01019b4:	75 0b                	jne    f01019c1 <__umoddi3+0x91>
f01019b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01019bb:	31 d2                	xor    %edx,%edx
f01019bd:	f7 f6                	div    %esi
f01019bf:	89 c5                	mov    %eax,%ebp
f01019c1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019c5:	31 d2                	xor    %edx,%edx
f01019c7:	f7 f5                	div    %ebp
f01019c9:	89 c8                	mov    %ecx,%eax
f01019cb:	f7 f5                	div    %ebp
f01019cd:	eb 9c                	jmp    f010196b <__umoddi3+0x3b>
f01019cf:	90                   	nop
f01019d0:	89 c8                	mov    %ecx,%eax
f01019d2:	89 fa                	mov    %edi,%edx
f01019d4:	83 c4 14             	add    $0x14,%esp
f01019d7:	5e                   	pop    %esi
f01019d8:	5f                   	pop    %edi
f01019d9:	5d                   	pop    %ebp
f01019da:	c3                   	ret    
f01019db:	90                   	nop
f01019dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019e0:	8b 04 24             	mov    (%esp),%eax
f01019e3:	be 20 00 00 00       	mov    $0x20,%esi
f01019e8:	89 e9                	mov    %ebp,%ecx
f01019ea:	29 ee                	sub    %ebp,%esi
f01019ec:	d3 e2                	shl    %cl,%edx
f01019ee:	89 f1                	mov    %esi,%ecx
f01019f0:	d3 e8                	shr    %cl,%eax
f01019f2:	89 e9                	mov    %ebp,%ecx
f01019f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019f8:	8b 04 24             	mov    (%esp),%eax
f01019fb:	09 54 24 04          	or     %edx,0x4(%esp)
f01019ff:	89 fa                	mov    %edi,%edx
f0101a01:	d3 e0                	shl    %cl,%eax
f0101a03:	89 f1                	mov    %esi,%ecx
f0101a05:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a09:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101a0d:	d3 ea                	shr    %cl,%edx
f0101a0f:	89 e9                	mov    %ebp,%ecx
f0101a11:	d3 e7                	shl    %cl,%edi
f0101a13:	89 f1                	mov    %esi,%ecx
f0101a15:	d3 e8                	shr    %cl,%eax
f0101a17:	89 e9                	mov    %ebp,%ecx
f0101a19:	09 f8                	or     %edi,%eax
f0101a1b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0101a1f:	f7 74 24 04          	divl   0x4(%esp)
f0101a23:	d3 e7                	shl    %cl,%edi
f0101a25:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a29:	89 d7                	mov    %edx,%edi
f0101a2b:	f7 64 24 08          	mull   0x8(%esp)
f0101a2f:	39 d7                	cmp    %edx,%edi
f0101a31:	89 c1                	mov    %eax,%ecx
f0101a33:	89 14 24             	mov    %edx,(%esp)
f0101a36:	72 2c                	jb     f0101a64 <__umoddi3+0x134>
f0101a38:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101a3c:	72 22                	jb     f0101a60 <__umoddi3+0x130>
f0101a3e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a42:	29 c8                	sub    %ecx,%eax
f0101a44:	19 d7                	sbb    %edx,%edi
f0101a46:	89 e9                	mov    %ebp,%ecx
f0101a48:	89 fa                	mov    %edi,%edx
f0101a4a:	d3 e8                	shr    %cl,%eax
f0101a4c:	89 f1                	mov    %esi,%ecx
f0101a4e:	d3 e2                	shl    %cl,%edx
f0101a50:	89 e9                	mov    %ebp,%ecx
f0101a52:	d3 ef                	shr    %cl,%edi
f0101a54:	09 d0                	or     %edx,%eax
f0101a56:	89 fa                	mov    %edi,%edx
f0101a58:	83 c4 14             	add    $0x14,%esp
f0101a5b:	5e                   	pop    %esi
f0101a5c:	5f                   	pop    %edi
f0101a5d:	5d                   	pop    %ebp
f0101a5e:	c3                   	ret    
f0101a5f:	90                   	nop
f0101a60:	39 d7                	cmp    %edx,%edi
f0101a62:	75 da                	jne    f0101a3e <__umoddi3+0x10e>
f0101a64:	8b 14 24             	mov    (%esp),%edx
f0101a67:	89 c1                	mov    %eax,%ecx
f0101a69:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a6d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a71:	eb cb                	jmp    f0101a3e <__umoddi3+0x10e>
f0101a73:	90                   	nop
f0101a74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a78:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a7c:	0f 82 0f ff ff ff    	jb     f0101991 <__umoddi3+0x61>
f0101a82:	e9 1a ff ff ff       	jmp    f01019a1 <__umoddi3+0x71>
