
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
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 8c 79 11 f0       	mov    $0xf011798c,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 27 38 00 00       	call   f010388f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 ad 04 00 00       	call   f010051a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 3d 10 f0 	movl   $0xf0103d60,(%esp)
f010007c:	e8 70 2c 00 00       	call   f0102cf1 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 c6 11 00 00       	call   f010124c <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 a3 07 00 00       	call   f0100835 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 00 73 11 f0 00 	cmpl   $0x0,0xf0117300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 73 11 f0    	mov    %esi,0xf0117300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 7b 3d 10 f0 	movl   $0xf0103d7b,(%esp)
f01000c8:	e8 24 2c 00 00       	call   f0102cf1 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 e5 2b 00 00       	call   f0102cbe <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 69 40 10 f0 	movl   $0xf0104069,(%esp)
f01000e0:	e8 0c 2c 00 00       	call   f0102cf1 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 44 07 00 00       	call   f0100835 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 93 3d 10 f0 	movl   $0xf0103d93,(%esp)
f0100112:	e8 da 2b 00 00       	call   f0102cf1 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 98 2b 00 00       	call   f0102cbe <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 69 40 10 f0 	movl   $0xf0104069,(%esp)
f010012d:	e8 bf 2b 00 00       	call   f0102cf1 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 44 75 11 f0       	mov    0xf0117544,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 44 75 11 f0    	mov    %ecx,0xf0117544
f0100179:	88 90 40 73 11 f0    	mov    %dl,-0xfee8cc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 44 75 11 f0 00 	movl   $0x0,0xf0117544
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 ef 00 00 00    	je     f010029d <kbd_proc_data+0xfd>
f01001ae:	b2 60                	mov    $0x60,%dl
f01001b0:	ec                   	in     (%dx),%al
f01001b1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b3:	3c e0                	cmp    $0xe0,%al
f01001b5:	75 0d                	jne    f01001c4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001b7:	83 0d 20 73 11 f0 40 	orl    $0x40,0xf0117320
		return 0;
f01001be:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001c3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	53                   	push   %ebx
f01001c8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001cb:	84 c0                	test   %al,%al
f01001cd:	79 37                	jns    f0100206 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cf:	8b 0d 20 73 11 f0    	mov    0xf0117320,%ecx
f01001d5:	89 cb                	mov    %ecx,%ebx
f01001d7:	83 e3 40             	and    $0x40,%ebx
f01001da:	83 e0 7f             	and    $0x7f,%eax
f01001dd:	85 db                	test   %ebx,%ebx
f01001df:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e2:	0f b6 d2             	movzbl %dl,%edx
f01001e5:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f01001ec:	83 c8 40             	or     $0x40,%eax
f01001ef:	0f b6 c0             	movzbl %al,%eax
f01001f2:	f7 d0                	not    %eax
f01001f4:	21 c1                	and    %eax,%ecx
f01001f6:	89 0d 20 73 11 f0    	mov    %ecx,0xf0117320
		return 0;
f01001fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100201:	e9 9d 00 00 00       	jmp    f01002a3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100206:	8b 0d 20 73 11 f0    	mov    0xf0117320,%ecx
f010020c:	f6 c1 40             	test   $0x40,%cl
f010020f:	74 0e                	je     f010021f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100211:	83 c8 80             	or     $0xffffff80,%eax
f0100214:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100216:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100219:	89 0d 20 73 11 f0    	mov    %ecx,0xf0117320
	}

	shift |= shiftcode[data];
f010021f:	0f b6 d2             	movzbl %dl,%edx
f0100222:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f0100229:	0b 05 20 73 11 f0    	or     0xf0117320,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a 00 3e 10 f0 	movzbl -0xfefc200(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 20 73 11 f0       	mov    %eax,0xf0117320

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d e0 3d 10 f0 	mov    -0xfefc220(,%ecx,4),%ecx
f0100249:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100250:	a8 08                	test   $0x8,%al
f0100252:	74 1b                	je     f010026f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100254:	89 da                	mov    %ebx,%edx
f0100256:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100259:	83 f9 19             	cmp    $0x19,%ecx
f010025c:	77 05                	ja     f0100263 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010025e:	83 eb 20             	sub    $0x20,%ebx
f0100261:	eb 0c                	jmp    f010026f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100263:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100266:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100269:	83 fa 19             	cmp    $0x19,%edx
f010026c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026f:	f7 d0                	not    %eax
f0100271:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100273:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100275:	f6 c2 06             	test   $0x6,%dl
f0100278:	75 29                	jne    f01002a3 <kbd_proc_data+0x103>
f010027a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100280:	75 21                	jne    f01002a3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100282:	c7 04 24 ad 3d 10 f0 	movl   $0xf0103dad,(%esp)
f0100289:	e8 63 2a 00 00       	call   f0102cf1 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100293:	b8 03 00 00 00       	mov    $0x3,%eax
f0100298:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100299:	89 d8                	mov    %ebx,%eax
f010029b:	eb 06                	jmp    f01002a3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010029d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002a3:	83 c4 14             	add    $0x14,%esp
f01002a6:	5b                   	pop    %ebx
f01002a7:	5d                   	pop    %ebp
f01002a8:	c3                   	ret    

f01002a9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a9:	55                   	push   %ebp
f01002aa:	89 e5                	mov    %esp,%ebp
f01002ac:	57                   	push   %edi
f01002ad:	56                   	push   %esi
f01002ae:	53                   	push   %ebx
f01002af:	83 ec 1c             	sub    $0x1c,%esp
f01002b2:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b4:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002b9:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002ba:	a8 20                	test   $0x20,%al
f01002bc:	75 27                	jne    f01002e5 <cons_putc+0x3c>
f01002be:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01002c3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c8:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cd:	89 ca                	mov    %ecx,%edx
f01002cf:	ec                   	in     (%dx),%al
f01002d0:	89 ca                	mov    %ecx,%edx
f01002d2:	ec                   	in     (%dx),%al
f01002d3:	89 ca                	mov    %ecx,%edx
f01002d5:	ec                   	in     (%dx),%al
f01002d6:	89 ca                	mov    %ecx,%edx
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 f2                	mov    %esi,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	a8 20                	test   $0x20,%al
f01002de:	75 05                	jne    f01002e5 <cons_putc+0x3c>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	83 eb 01             	sub    $0x1,%ebx
f01002e3:	75 e8                	jne    f01002cd <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01002e5:	89 f8                	mov    %edi,%eax
f01002e7:	0f b6 c0             	movzbl %al,%eax
f01002ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f3:	b2 79                	mov    $0x79,%dl
f01002f5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002f6:	84 c0                	test   %al,%al
f01002f8:	78 27                	js     f0100321 <cons_putc+0x78>
f01002fa:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01002ff:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100304:	be 79 03 00 00       	mov    $0x379,%esi
f0100309:	89 ca                	mov    %ecx,%edx
f010030b:	ec                   	in     (%dx),%al
f010030c:	89 ca                	mov    %ecx,%edx
f010030e:	ec                   	in     (%dx),%al
f010030f:	89 ca                	mov    %ecx,%edx
f0100311:	ec                   	in     (%dx),%al
f0100312:	89 ca                	mov    %ecx,%edx
f0100314:	ec                   	in     (%dx),%al
f0100315:	89 f2                	mov    %esi,%edx
f0100317:	ec                   	in     (%dx),%al
f0100318:	84 c0                	test   %al,%al
f010031a:	78 05                	js     f0100321 <cons_putc+0x78>
f010031c:	83 eb 01             	sub    $0x1,%ebx
f010031f:	75 e8                	jne    f0100309 <cons_putc+0x60>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100321:	ba 78 03 00 00       	mov    $0x378,%edx
f0100326:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010032a:	ee                   	out    %al,(%dx)
f010032b:	b2 7a                	mov    $0x7a,%dl
f010032d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100332:	ee                   	out    %al,(%dx)
f0100333:	b8 08 00 00 00       	mov    $0x8,%eax
f0100338:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100339:	89 fa                	mov    %edi,%edx
f010033b:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	80 cc 07             	or     $0x7,%ah
f0100346:	85 d2                	test   %edx,%edx
f0100348:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010034b:	89 f8                	mov    %edi,%eax
f010034d:	0f b6 c0             	movzbl %al,%eax
f0100350:	83 f8 09             	cmp    $0x9,%eax
f0100353:	74 78                	je     f01003cd <cons_putc+0x124>
f0100355:	83 f8 09             	cmp    $0x9,%eax
f0100358:	7f 0b                	jg     f0100365 <cons_putc+0xbc>
f010035a:	83 f8 08             	cmp    $0x8,%eax
f010035d:	74 18                	je     f0100377 <cons_putc+0xce>
f010035f:	90                   	nop
f0100360:	e9 9c 00 00 00       	jmp    f0100401 <cons_putc+0x158>
f0100365:	83 f8 0a             	cmp    $0xa,%eax
f0100368:	74 3d                	je     f01003a7 <cons_putc+0xfe>
f010036a:	83 f8 0d             	cmp    $0xd,%eax
f010036d:	8d 76 00             	lea    0x0(%esi),%esi
f0100370:	74 3d                	je     f01003af <cons_putc+0x106>
f0100372:	e9 8a 00 00 00       	jmp    f0100401 <cons_putc+0x158>
	case '\b':
		if (crt_pos > 0) {
f0100377:	0f b7 05 48 75 11 f0 	movzwl 0xf0117548,%eax
f010037e:	66 85 c0             	test   %ax,%ax
f0100381:	0f 84 e5 00 00 00    	je     f010046c <cons_putc+0x1c3>
			crt_pos--;
f0100387:	83 e8 01             	sub    $0x1,%eax
f010038a:	66 a3 48 75 11 f0    	mov    %ax,0xf0117548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100390:	0f b7 c0             	movzwl %ax,%eax
f0100393:	66 81 e7 00 ff       	and    $0xff00,%di
f0100398:	83 cf 20             	or     $0x20,%edi
f010039b:	8b 15 4c 75 11 f0    	mov    0xf011754c,%edx
f01003a1:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003a5:	eb 78                	jmp    f010041f <cons_putc+0x176>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003a7:	66 83 05 48 75 11 f0 	addw   $0x50,0xf0117548
f01003ae:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003af:	0f b7 05 48 75 11 f0 	movzwl 0xf0117548,%eax
f01003b6:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003bc:	c1 e8 16             	shr    $0x16,%eax
f01003bf:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c2:	c1 e0 04             	shl    $0x4,%eax
f01003c5:	66 a3 48 75 11 f0    	mov    %ax,0xf0117548
f01003cb:	eb 52                	jmp    f010041f <cons_putc+0x176>
		break;
	case '\t':
		cons_putc(' ');
f01003cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d2:	e8 d2 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003d7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003dc:	e8 c8 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e6:	e8 be fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003eb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f0:	e8 b4 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003f5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fa:	e8 aa fe ff ff       	call   f01002a9 <cons_putc>
f01003ff:	eb 1e                	jmp    f010041f <cons_putc+0x176>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100401:	0f b7 05 48 75 11 f0 	movzwl 0xf0117548,%eax
f0100408:	8d 50 01             	lea    0x1(%eax),%edx
f010040b:	66 89 15 48 75 11 f0 	mov    %dx,0xf0117548
f0100412:	0f b7 c0             	movzwl %ax,%eax
f0100415:	8b 15 4c 75 11 f0    	mov    0xf011754c,%edx
f010041b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010041f:	66 81 3d 48 75 11 f0 	cmpw   $0x7cf,0xf0117548
f0100426:	cf 07 
f0100428:	76 42                	jbe    f010046c <cons_putc+0x1c3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042a:	a1 4c 75 11 f0       	mov    0xf011754c,%eax
f010042f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100436:	00 
f0100437:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010043d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100441:	89 04 24             	mov    %eax,(%esp)
f0100444:	e8 93 34 00 00       	call   f01038dc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100449:	8b 15 4c 75 11 f0    	mov    0xf011754c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100454:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010045a:	83 c0 01             	add    $0x1,%eax
f010045d:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100462:	75 f0                	jne    f0100454 <cons_putc+0x1ab>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100464:	66 83 2d 48 75 11 f0 	subw   $0x50,0xf0117548
f010046b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010046c:	8b 0d 50 75 11 f0    	mov    0xf0117550,%ecx
f0100472:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047a:	0f b7 1d 48 75 11 f0 	movzwl 0xf0117548,%ebx
f0100481:	8d 71 01             	lea    0x1(%ecx),%esi
f0100484:	89 d8                	mov    %ebx,%eax
f0100486:	66 c1 e8 08          	shr    $0x8,%ax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
f010048d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100492:	89 ca                	mov    %ecx,%edx
f0100494:	ee                   	out    %al,(%dx)
f0100495:	89 d8                	mov    %ebx,%eax
f0100497:	89 f2                	mov    %esi,%edx
f0100499:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010049a:	83 c4 1c             	add    $0x1c,%esp
f010049d:	5b                   	pop    %ebx
f010049e:	5e                   	pop    %esi
f010049f:	5f                   	pop    %edi
f01004a0:	5d                   	pop    %ebp
f01004a1:	c3                   	ret    

f01004a2 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004a2:	83 3d 54 75 11 f0 00 	cmpl   $0x0,0xf0117554
f01004a9:	74 11                	je     f01004bc <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004ab:	55                   	push   %ebp
f01004ac:	89 e5                	mov    %esp,%ebp
f01004ae:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004b1:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004b6:	e8 a1 fc ff ff       	call   f010015c <cons_intr>
}
f01004bb:	c9                   	leave  
f01004bc:	f3 c3                	repz ret 

f01004be <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004be:	55                   	push   %ebp
f01004bf:	89 e5                	mov    %esp,%ebp
f01004c1:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004c4:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004c9:	e8 8e fc ff ff       	call   f010015c <cons_intr>
}
f01004ce:	c9                   	leave  
f01004cf:	c3                   	ret    

f01004d0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004d0:	55                   	push   %ebp
f01004d1:	89 e5                	mov    %esp,%ebp
f01004d3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004d6:	e8 c7 ff ff ff       	call   f01004a2 <serial_intr>
	kbd_intr();
f01004db:	e8 de ff ff ff       	call   f01004be <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004e0:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01004e5:	3b 05 44 75 11 f0    	cmp    0xf0117544,%eax
f01004eb:	74 26                	je     f0100513 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004ed:	8d 50 01             	lea    0x1(%eax),%edx
f01004f0:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
f01004f6:	0f b6 88 40 73 11 f0 	movzbl -0xfee8cc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004fd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004ff:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100505:	75 11                	jne    f0100518 <cons_getc+0x48>
			cons.rpos = 0;
f0100507:	c7 05 40 75 11 f0 00 	movl   $0x0,0xf0117540
f010050e:	00 00 00 
f0100511:	eb 05                	jmp    f0100518 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100513:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100518:	c9                   	leave  
f0100519:	c3                   	ret    

f010051a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	57                   	push   %edi
f010051e:	56                   	push   %esi
f010051f:	53                   	push   %ebx
f0100520:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100523:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100531:	5a a5 
	if (*cp != 0xA55A) {
f0100533:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010053e:	74 11                	je     f0100551 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100540:	c7 05 50 75 11 f0 b4 	movl   $0x3b4,0xf0117550
f0100547:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054a:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010054f:	eb 16                	jmp    f0100567 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100551:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100558:	c7 05 50 75 11 f0 d4 	movl   $0x3d4,0xf0117550
f010055f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100562:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100567:	8b 0d 50 75 11 f0    	mov    0xf0117550,%ecx
f010056d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100572:	89 ca                	mov    %ecx,%edx
f0100574:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100575:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100578:	89 da                	mov    %ebx,%edx
f010057a:	ec                   	in     (%dx),%al
f010057b:	0f b6 f0             	movzbl %al,%esi
f010057e:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100581:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100586:	89 ca                	mov    %ecx,%edx
f0100588:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100589:	89 da                	mov    %ebx,%edx
f010058b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010058c:	89 3d 4c 75 11 f0    	mov    %edi,0xf011754c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100592:	0f b6 d8             	movzbl %al,%ebx
f0100595:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100597:	66 89 35 48 75 11 f0 	mov    %si,0xf0117548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010059e:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01005a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a8:	ee                   	out    %al,(%dx)
f01005a9:	b2 fb                	mov    $0xfb,%dl
f01005ab:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b0:	ee                   	out    %al,(%dx)
f01005b1:	b2 f8                	mov    $0xf8,%dl
f01005b3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b8:	ee                   	out    %al,(%dx)
f01005b9:	b2 f9                	mov    $0xf9,%dl
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	b2 fb                	mov    $0xfb,%dl
f01005c3:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c8:	ee                   	out    %al,(%dx)
f01005c9:	b2 fc                	mov    $0xfc,%dl
f01005cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d0:	ee                   	out    %al,(%dx)
f01005d1:	b2 f9                	mov    $0xf9,%dl
f01005d3:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d9:	b2 fd                	mov    $0xfd,%dl
f01005db:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005dc:	3c ff                	cmp    $0xff,%al
f01005de:	0f 95 c1             	setne  %cl
f01005e1:	0f b6 c9             	movzbl %cl,%ecx
f01005e4:	89 0d 54 75 11 f0    	mov    %ecx,0xf0117554
f01005ea:	b2 fa                	mov    $0xfa,%dl
f01005ec:	ec                   	in     (%dx),%al
f01005ed:	b2 f8                	mov    $0xf8,%dl
f01005ef:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f0:	85 c9                	test   %ecx,%ecx
f01005f2:	75 0c                	jne    f0100600 <cons_init+0xe6>
		cprintf("Serial port does not exist!\n");
f01005f4:	c7 04 24 b9 3d 10 f0 	movl   $0xf0103db9,(%esp)
f01005fb:	e8 f1 26 00 00       	call   f0102cf1 <cprintf>
}
f0100600:	83 c4 1c             	add    $0x1c,%esp
f0100603:	5b                   	pop    %ebx
f0100604:	5e                   	pop    %esi
f0100605:	5f                   	pop    %edi
f0100606:	5d                   	pop    %ebp
f0100607:	c3                   	ret    

f0100608 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100608:	55                   	push   %ebp
f0100609:	89 e5                	mov    %esp,%ebp
f010060b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100611:	e8 93 fc ff ff       	call   f01002a9 <cons_putc>
}
f0100616:	c9                   	leave  
f0100617:	c3                   	ret    

f0100618 <getchar>:

int
getchar(void)
{
f0100618:	55                   	push   %ebp
f0100619:	89 e5                	mov    %esp,%ebp
f010061b:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061e:	e8 ad fe ff ff       	call   f01004d0 <cons_getc>
f0100623:	85 c0                	test   %eax,%eax
f0100625:	74 f7                	je     f010061e <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100627:	c9                   	leave  
f0100628:	c3                   	ret    

f0100629 <iscons>:

int
iscons(int fdnum)
{
f0100629:	55                   	push   %ebp
f010062a:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100631:	5d                   	pop    %ebp
f0100632:	c3                   	ret    
f0100633:	66 90                	xchg   %ax,%ax
f0100635:	66 90                	xchg   %ax,%ax
f0100637:	66 90                	xchg   %ax,%ax
f0100639:	66 90                	xchg   %ax,%ax
f010063b:	66 90                	xchg   %ax,%ax
f010063d:	66 90                	xchg   %ax,%ax
f010063f:	90                   	nop

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	c7 44 24 08 00 40 10 	movl   $0xf0104000,0x8(%esp)
f010064d:	f0 
f010064e:	c7 44 24 04 1e 40 10 	movl   $0xf010401e,0x4(%esp)
f0100655:	f0 
f0100656:	c7 04 24 23 40 10 f0 	movl   $0xf0104023,(%esp)
f010065d:	e8 8f 26 00 00       	call   f0102cf1 <cprintf>
f0100662:	c7 44 24 08 c4 40 10 	movl   $0xf01040c4,0x8(%esp)
f0100669:	f0 
f010066a:	c7 44 24 04 2c 40 10 	movl   $0xf010402c,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 23 40 10 f0 	movl   $0xf0104023,(%esp)
f0100679:	e8 73 26 00 00       	call   f0102cf1 <cprintf>
f010067e:	c7 44 24 08 ec 40 10 	movl   $0xf01040ec,0x8(%esp)
f0100685:	f0 
f0100686:	c7 44 24 04 35 40 10 	movl   $0xf0104035,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 23 40 10 f0 	movl   $0xf0104023,(%esp)
f0100695:	e8 57 26 00 00       	call   f0102cf1 <cprintf>
	return 0;
}
f010069a:	b8 00 00 00 00       	mov    $0x0,%eax
f010069f:	c9                   	leave  
f01006a0:	c3                   	ret    

f01006a1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a1:	55                   	push   %ebp
f01006a2:	89 e5                	mov    %esp,%ebp
f01006a4:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a7:	c7 04 24 3f 40 10 f0 	movl   $0xf010403f,(%esp)
f01006ae:	e8 3e 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b3:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ba:	00 
f01006bb:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c2:	f0 
f01006c3:	c7 04 24 18 41 10 f0 	movl   $0xf0104118,(%esp)
f01006ca:	e8 22 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006cf:	c7 44 24 08 57 3d 10 	movl   $0x103d57,0x8(%esp)
f01006d6:	00 
f01006d7:	c7 44 24 04 57 3d 10 	movl   $0xf0103d57,0x4(%esp)
f01006de:	f0 
f01006df:	c7 04 24 3c 41 10 f0 	movl   $0xf010413c,(%esp)
f01006e6:	e8 06 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006eb:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006f2:	00 
f01006f3:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006fa:	f0 
f01006fb:	c7 04 24 60 41 10 f0 	movl   $0xf0104160,(%esp)
f0100702:	e8 ea 25 00 00       	call   f0102cf1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100707:	c7 44 24 08 8c 79 11 	movl   $0x11798c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 8c 79 11 	movl   $0xf011798c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 84 41 10 f0 	movl   $0xf0104184,(%esp)
f010071e:	e8 ce 25 00 00       	call   f0102cf1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100723:	b8 8b 7d 11 f0       	mov    $0xf0117d8b,%eax
f0100728:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010072d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100733:	85 c0                	test   %eax,%eax
f0100735:	0f 48 c2             	cmovs  %edx,%eax
f0100738:	c1 f8 0a             	sar    $0xa,%eax
f010073b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010073f:	c7 04 24 a8 41 10 f0 	movl   $0xf01041a8,(%esp)
f0100746:	e8 a6 25 00 00       	call   f0102cf1 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010074b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100750:	c9                   	leave  
f0100751:	c3                   	ret    

f0100752 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100752:	55                   	push   %ebp
f0100753:	89 e5                	mov    %esp,%ebp
f0100755:	57                   	push   %edi
f0100756:	56                   	push   %esi
f0100757:	53                   	push   %ebx
f0100758:	83 ec 1c             	sub    $0x1c,%esp
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010075b:	8b 75 04             	mov    0x4(%ebp),%esi

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010075e:	89 ef                	mov    %ebp,%edi
f0100760:	89 fb                	mov    %edi,%ebx
	// Your code here.
	//Read the values of eip and ebp
	uint32_t eip=read_eip();
	uint32_t ebp=read_ebp();
	//Print current eip and ebp
	cprintf("Stack backtrace:\r\n");
f0100762:	c7 04 24 58 40 10 f0 	movl   $0xf0104058,(%esp)
f0100769:	e8 83 25 00 00       	call   f0102cf1 <cprintf>
	cprintf(" ebp:%x eip:%x ",ebp,eip);
f010076e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100772:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100776:	c7 04 24 6b 40 10 f0 	movl   $0xf010406b,(%esp)
f010077d:	e8 6f 25 00 00       	call   f0102cf1 <cprintf>
	//Print current fuction's args	
	uint32_t esp=ebp + 0x8;
f0100782:	8d 77 08             	lea    0x8(%edi),%esi
	int i;
	cprintf("args:");
f0100785:	c7 04 24 7b 40 10 f0 	movl   $0xf010407b,(%esp)
f010078c:	e8 60 25 00 00       	call   f0102cf1 <cprintf>
f0100791:	8d 47 1c             	lea    0x1c(%edi),%eax
f0100794:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0;i<5;i++){
		cprintf("%x ",*(uint32_t *)(esp));
f0100797:	8b 06                	mov    (%esi),%eax
f0100799:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079d:	c7 04 24 77 40 10 f0 	movl   $0xf0104077,(%esp)
f01007a4:	e8 48 25 00 00       	call   f0102cf1 <cprintf>
		esp=esp+0x4;	
f01007a9:	83 c6 04             	add    $0x4,%esi
	cprintf(" ebp:%x eip:%x ",ebp,eip);
	//Print current fuction's args	
	uint32_t esp=ebp + 0x8;
	int i;
	cprintf("args:");
	for(i=0;i<5;i++){
f01007ac:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01007af:	75 e6                	jne    f0100797 <mon_backtrace+0x45>
		cprintf("%x ",*(uint32_t *)(esp));
		esp=esp+0x4;	
	}
	cprintf("\r\n");
f01007b1:	c7 04 24 68 40 10 f0 	movl   $0xf0104068,(%esp)
f01007b8:	e8 34 25 00 00       	call   f0102cf1 <cprintf>
	//Print fuction before
	while(ebp!=0){
f01007bd:	85 ff                	test   %edi,%edi
f01007bf:	74 67                	je     f0100828 <mon_backtrace+0xd6>
		esp=ebp;
		if((ebp=*(uint32_t *)(esp))==0){
f01007c1:	8b 3f                	mov    (%edi),%edi
f01007c3:	85 ff                	test   %edi,%edi
f01007c5:	75 0f                	jne    f01007d6 <mon_backtrace+0x84>
f01007c7:	eb 5f                	jmp    f0100828 <mon_backtrace+0xd6>
f01007c9:	8b 07                	mov    (%edi),%eax
f01007cb:	85 c0                	test   %eax,%eax
f01007cd:	8d 76 00             	lea    0x0(%esi),%esi
f01007d0:	74 56                	je     f0100828 <mon_backtrace+0xd6>
f01007d2:	89 fb                	mov    %edi,%ebx
f01007d4:	89 c7                	mov    %eax,%edi
			break;
		}
		esp=esp+0x4;
		eip=*(uint32_t *)(esp);
		esp=esp+0x4;
f01007d6:	8d 73 08             	lea    0x8(%ebx),%esi
		cprintf(" ebp:%x eip:%x ",ebp,eip);
f01007d9:	8b 43 04             	mov    0x4(%ebx),%eax
f01007dc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007e0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007e4:	c7 04 24 6b 40 10 f0 	movl   $0xf010406b,(%esp)
f01007eb:	e8 01 25 00 00       	call   f0102cf1 <cprintf>
		cprintf("args:");
f01007f0:	c7 04 24 7b 40 10 f0 	movl   $0xf010407b,(%esp)
f01007f7:	e8 f5 24 00 00       	call   f0102cf1 <cprintf>
f01007fc:	83 c3 1c             	add    $0x1c,%ebx
		for(i=0;i<5;i++){
			cprintf(" %x",*(uint32_t *)(esp));
f01007ff:	8b 06                	mov    (%esi),%eax
f0100801:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100805:	c7 04 24 81 40 10 f0 	movl   $0xf0104081,(%esp)
f010080c:	e8 e0 24 00 00       	call   f0102cf1 <cprintf>
			esp=esp+0x4;	
f0100811:	83 c6 04             	add    $0x4,%esi
		esp=esp+0x4;
		eip=*(uint32_t *)(esp);
		esp=esp+0x4;
		cprintf(" ebp:%x eip:%x ",ebp,eip);
		cprintf("args:");
		for(i=0;i<5;i++){
f0100814:	39 de                	cmp    %ebx,%esi
f0100816:	75 e7                	jne    f01007ff <mon_backtrace+0xad>
			cprintf(" %x",*(uint32_t *)(esp));
			esp=esp+0x4;	
		}
		cprintf("\r\n");	
f0100818:	c7 04 24 68 40 10 f0 	movl   $0xf0104068,(%esp)
f010081f:	e8 cd 24 00 00       	call   f0102cf1 <cprintf>
		cprintf("%x ",*(uint32_t *)(esp));
		esp=esp+0x4;	
	}
	cprintf("\r\n");
	//Print fuction before
	while(ebp!=0){
f0100824:	85 ff                	test   %edi,%edi
f0100826:	75 a1                	jne    f01007c9 <mon_backtrace+0x77>
			esp=esp+0x4;	
		}
		cprintf("\r\n");	
		}
	return 0;
}
f0100828:	b8 00 00 00 00       	mov    $0x0,%eax
f010082d:	83 c4 1c             	add    $0x1c,%esp
f0100830:	5b                   	pop    %ebx
f0100831:	5e                   	pop    %esi
f0100832:	5f                   	pop    %edi
f0100833:	5d                   	pop    %ebp
f0100834:	c3                   	ret    

f0100835 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100835:	55                   	push   %ebp
f0100836:	89 e5                	mov    %esp,%ebp
f0100838:	57                   	push   %edi
f0100839:	56                   	push   %esi
f010083a:	53                   	push   %ebx
f010083b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010083e:	c7 04 24 d4 41 10 f0 	movl   $0xf01041d4,(%esp)
f0100845:	e8 a7 24 00 00       	call   f0102cf1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010084a:	c7 04 24 f8 41 10 f0 	movl   $0xf01041f8,(%esp)
f0100851:	e8 9b 24 00 00       	call   f0102cf1 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100856:	c7 04 24 85 40 10 f0 	movl   $0xf0104085,(%esp)
f010085d:	e8 7e 2d 00 00       	call   f01035e0 <readline>
f0100862:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100864:	85 c0                	test   %eax,%eax
f0100866:	74 ee                	je     f0100856 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100868:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010086f:	be 00 00 00 00       	mov    $0x0,%esi
f0100874:	eb 0a                	jmp    f0100880 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100876:	c6 03 00             	movb   $0x0,(%ebx)
f0100879:	89 f7                	mov    %esi,%edi
f010087b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010087e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100880:	0f b6 03             	movzbl (%ebx),%eax
f0100883:	84 c0                	test   %al,%al
f0100885:	74 6a                	je     f01008f1 <monitor+0xbc>
f0100887:	0f be c0             	movsbl %al,%eax
f010088a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088e:	c7 04 24 89 40 10 f0 	movl   $0xf0104089,(%esp)
f0100895:	e8 94 2f 00 00       	call   f010382e <strchr>
f010089a:	85 c0                	test   %eax,%eax
f010089c:	75 d8                	jne    f0100876 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010089e:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a1:	74 4e                	je     f01008f1 <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a3:	83 fe 0f             	cmp    $0xf,%esi
f01008a6:	75 16                	jne    f01008be <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a8:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008af:	00 
f01008b0:	c7 04 24 8e 40 10 f0 	movl   $0xf010408e,(%esp)
f01008b7:	e8 35 24 00 00       	call   f0102cf1 <cprintf>
f01008bc:	eb 98                	jmp    f0100856 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008be:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c5:	0f b6 03             	movzbl (%ebx),%eax
f01008c8:	84 c0                	test   %al,%al
f01008ca:	75 0c                	jne    f01008d8 <monitor+0xa3>
f01008cc:	eb b0                	jmp    f010087e <monitor+0x49>
			buf++;
f01008ce:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d1:	0f b6 03             	movzbl (%ebx),%eax
f01008d4:	84 c0                	test   %al,%al
f01008d6:	74 a6                	je     f010087e <monitor+0x49>
f01008d8:	0f be c0             	movsbl %al,%eax
f01008db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008df:	c7 04 24 89 40 10 f0 	movl   $0xf0104089,(%esp)
f01008e6:	e8 43 2f 00 00       	call   f010382e <strchr>
f01008eb:	85 c0                	test   %eax,%eax
f01008ed:	74 df                	je     f01008ce <monitor+0x99>
f01008ef:	eb 8d                	jmp    f010087e <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008f1:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f9:	85 f6                	test   %esi,%esi
f01008fb:	0f 84 55 ff ff ff    	je     f0100856 <monitor+0x21>
f0100901:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100906:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100909:	8b 04 85 20 42 10 f0 	mov    -0xfefbde0(,%eax,4),%eax
f0100910:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100914:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100917:	89 04 24             	mov    %eax,(%esp)
f010091a:	e8 8b 2e 00 00       	call   f01037aa <strcmp>
f010091f:	85 c0                	test   %eax,%eax
f0100921:	75 24                	jne    f0100947 <monitor+0x112>
			return commands[i].func(argc, argv, tf);
f0100923:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100926:	8b 55 08             	mov    0x8(%ebp),%edx
f0100929:	89 54 24 08          	mov    %edx,0x8(%esp)
f010092d:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100930:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100934:	89 34 24             	mov    %esi,(%esp)
f0100937:	ff 14 85 28 42 10 f0 	call   *-0xfefbdd8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010093e:	85 c0                	test   %eax,%eax
f0100940:	78 28                	js     f010096a <monitor+0x135>
f0100942:	e9 0f ff ff ff       	jmp    f0100856 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100947:	83 c3 01             	add    $0x1,%ebx
f010094a:	83 fb 03             	cmp    $0x3,%ebx
f010094d:	8d 76 00             	lea    0x0(%esi),%esi
f0100950:	75 b4                	jne    f0100906 <monitor+0xd1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100952:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100955:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100959:	c7 04 24 ab 40 10 f0 	movl   $0xf01040ab,(%esp)
f0100960:	e8 8c 23 00 00       	call   f0102cf1 <cprintf>
f0100965:	e9 ec fe ff ff       	jmp    f0100856 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010096a:	83 c4 5c             	add    $0x5c,%esp
f010096d:	5b                   	pop    %ebx
f010096e:	5e                   	pop    %esi
f010096f:	5f                   	pop    %edi
f0100970:	5d                   	pop    %ebp
f0100971:	c3                   	ret    

f0100972 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100972:	55                   	push   %ebp
f0100973:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100975:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100978:	5d                   	pop    %ebp
f0100979:	c3                   	ret    
f010097a:	66 90                	xchg   %ax,%ax
f010097c:	66 90                	xchg   %ax,%ax
f010097e:	66 90                	xchg   %ax,%ax

f0100980 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100983:	83 3d 58 75 11 f0 00 	cmpl   $0x0,0xf0117558
f010098a:	75 11                	jne    f010099d <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010098c:	ba 8b 89 11 f0       	mov    $0xf011898b,%edx
f0100991:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100997:	89 15 58 75 11 f0    	mov    %edx,0xf0117558
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result=nextfree;
f010099d:	8b 15 58 75 11 f0    	mov    0xf0117558,%edx
	nextfree+=ROUNDUP(n,PGSIZE);
f01009a3:	05 ff 0f 00 00       	add    $0xfff,%eax
f01009a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009ad:	01 d0                	add    %edx,%eax
f01009af:	a3 58 75 11 f0       	mov    %eax,0xf0117558
    return result;
}
f01009b4:	89 d0                	mov    %edx,%eax
f01009b6:	5d                   	pop    %ebp
f01009b7:	c3                   	ret    

f01009b8 <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01009b8:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01009be:	c1 f8 03             	sar    $0x3,%eax
f01009c1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009c4:	89 c2                	mov    %eax,%edx
f01009c6:	c1 ea 0c             	shr    $0xc,%edx
f01009c9:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f01009cf:	72 26                	jb     f01009f7 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct Page *pp)
{
f01009d1:	55                   	push   %ebp
f01009d2:	89 e5                	mov    %esp,%ebp
f01009d4:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009d7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009db:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f01009e2:	f0 
f01009e3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01009ea:	00 
f01009eb:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f01009f2:	e8 9d f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01009f7:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
}
f01009fc:	c3                   	ret    

f01009fd <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009fd:	89 d1                	mov    %edx,%ecx
f01009ff:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a02:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a05:	a8 01                	test   $0x1,%al
f0100a07:	74 5d                	je     f0100a66 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a09:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a0e:	89 c1                	mov    %eax,%ecx
f0100a10:	c1 e9 0c             	shr    $0xc,%ecx
f0100a13:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f0100a19:	72 26                	jb     f0100a41 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a1b:	55                   	push   %ebp
f0100a1c:	89 e5                	mov    %esp,%ebp
f0100a1e:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a21:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a25:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0100a2c:	f0 
f0100a2d:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0100a34:	00 
f0100a35:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100a3c:	e8 53 f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a41:	c1 ea 0c             	shr    $0xc,%edx
f0100a44:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a4a:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a51:	89 c2                	mov    %eax,%edx
f0100a53:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a56:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a5b:	85 d2                	test   %edx,%edx
f0100a5d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a62:	0f 44 c2             	cmove  %edx,%eax
f0100a65:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a6b:	c3                   	ret    

f0100a6c <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a6c:	55                   	push   %ebp
f0100a6d:	89 e5                	mov    %esp,%ebp
f0100a6f:	57                   	push   %edi
f0100a70:	56                   	push   %esi
f0100a71:	53                   	push   %ebx
f0100a72:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a75:	85 c0                	test   %eax,%eax
f0100a77:	0f 85 35 03 00 00    	jne    f0100db2 <check_page_free_list+0x346>
f0100a7d:	e9 42 03 00 00       	jmp    f0100dc4 <check_page_free_list+0x358>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a82:	c7 44 24 08 68 42 10 	movl   $0xf0104268,0x8(%esp)
f0100a89:	f0 
f0100a8a:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
f0100a91:	00 
f0100a92:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100a99:	e8 f6 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100a9e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100aa1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100aa4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aa7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aaa:	89 c2                	mov    %eax,%edx
f0100aac:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ab2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ab8:	0f 95 c2             	setne  %dl
f0100abb:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100abe:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ac2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ac4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ac8:	8b 00                	mov    (%eax),%eax
f0100aca:	85 c0                	test   %eax,%eax
f0100acc:	75 dc                	jne    f0100aaa <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ace:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ad7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ada:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100add:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100adf:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ae2:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ae7:	89 c3                	mov    %eax,%ebx
f0100ae9:	85 c0                	test   %eax,%eax
f0100aeb:	74 6c                	je     f0100b59 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aed:	be 01 00 00 00       	mov    $0x1,%esi
f0100af2:	89 d8                	mov    %ebx,%eax
f0100af4:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100afa:	c1 f8 03             	sar    $0x3,%eax
f0100afd:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b00:	89 c2                	mov    %eax,%edx
f0100b02:	c1 ea 16             	shr    $0x16,%edx
f0100b05:	39 f2                	cmp    %esi,%edx
f0100b07:	73 4a                	jae    f0100b53 <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b09:	89 c2                	mov    %eax,%edx
f0100b0b:	c1 ea 0c             	shr    $0xc,%edx
f0100b0e:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100b14:	72 20                	jb     f0100b36 <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b16:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b1a:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0100b21:	f0 
f0100b22:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b29:	00 
f0100b2a:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0100b31:	e8 5e f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b36:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b3d:	00 
f0100b3e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b45:	00 
	return (void *)(pa + KERNBASE);
f0100b46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b4b:	89 04 24             	mov    %eax,(%esp)
f0100b4e:	e8 3c 2d 00 00       	call   f010388f <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b53:	8b 1b                	mov    (%ebx),%ebx
f0100b55:	85 db                	test   %ebx,%ebx
f0100b57:	75 99                	jne    f0100af2 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b59:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b5e:	e8 1d fe ff ff       	call   f0100980 <boot_alloc>
f0100b63:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b66:	8b 15 5c 75 11 f0    	mov    0xf011755c,%edx
f0100b6c:	85 d2                	test   %edx,%edx
f0100b6e:	0f 84 f2 01 00 00    	je     f0100d66 <check_page_free_list+0x2fa>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b74:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100b7a:	39 da                	cmp    %ebx,%edx
f0100b7c:	72 3f                	jb     f0100bbd <check_page_free_list+0x151>
		assert(pp < pages + npages);
f0100b7e:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0100b83:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b86:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b8c:	39 c2                	cmp    %eax,%edx
f0100b8e:	73 56                	jae    f0100be6 <check_page_free_list+0x17a>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b90:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b93:	89 d0                	mov    %edx,%eax
f0100b95:	29 d8                	sub    %ebx,%eax
f0100b97:	a8 07                	test   $0x7,%al
f0100b99:	75 78                	jne    f0100c13 <check_page_free_list+0x1a7>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b9b:	c1 f8 03             	sar    $0x3,%eax
f0100b9e:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ba1:	85 c0                	test   %eax,%eax
f0100ba3:	0f 84 98 00 00 00    	je     f0100c41 <check_page_free_list+0x1d5>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ba9:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bae:	0f 85 dc 00 00 00    	jne    f0100c90 <check_page_free_list+0x224>
f0100bb4:	e9 b3 00 00 00       	jmp    f0100c6c <check_page_free_list+0x200>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bb9:	39 d3                	cmp    %edx,%ebx
f0100bbb:	76 24                	jbe    f0100be1 <check_page_free_list+0x175>
f0100bbd:	c7 44 24 0c 6e 49 10 	movl   $0xf010496e,0xc(%esp)
f0100bc4:	f0 
f0100bc5:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100bcc:	f0 
f0100bcd:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
f0100bd4:	00 
f0100bd5:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100bdc:	e8 b3 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100be1:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100be4:	72 24                	jb     f0100c0a <check_page_free_list+0x19e>
f0100be6:	c7 44 24 0c 8f 49 10 	movl   $0xf010498f,0xc(%esp)
f0100bed:	f0 
f0100bee:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100bf5:	f0 
f0100bf6:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100bfd:	00 
f0100bfe:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100c05:	e8 8a f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c0a:	89 d0                	mov    %edx,%eax
f0100c0c:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c0f:	a8 07                	test   $0x7,%al
f0100c11:	74 24                	je     f0100c37 <check_page_free_list+0x1cb>
f0100c13:	c7 44 24 0c 8c 42 10 	movl   $0xf010428c,0xc(%esp)
f0100c1a:	f0 
f0100c1b:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100c22:	f0 
f0100c23:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100c2a:	00 
f0100c2b:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100c32:	e8 5d f4 ff ff       	call   f0100094 <_panic>
f0100c37:	c1 f8 03             	sar    $0x3,%eax
f0100c3a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c3d:	85 c0                	test   %eax,%eax
f0100c3f:	75 24                	jne    f0100c65 <check_page_free_list+0x1f9>
f0100c41:	c7 44 24 0c a3 49 10 	movl   $0xf01049a3,0xc(%esp)
f0100c48:	f0 
f0100c49:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100c50:	f0 
f0100c51:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0100c58:	00 
f0100c59:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100c60:	e8 2f f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c65:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c6a:	75 2e                	jne    f0100c9a <check_page_free_list+0x22e>
f0100c6c:	c7 44 24 0c b4 49 10 	movl   $0xf01049b4,0xc(%esp)
f0100c73:	f0 
f0100c74:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100c7b:	f0 
f0100c7c:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0100c83:	00 
f0100c84:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100c8b:	e8 04 f4 ff ff       	call   f0100094 <_panic>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c90:	be 00 00 00 00       	mov    $0x0,%esi
f0100c95:	bf 00 00 00 00       	mov    $0x0,%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c9a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c9f:	75 24                	jne    f0100cc5 <check_page_free_list+0x259>
f0100ca1:	c7 44 24 0c c0 42 10 	movl   $0xf01042c0,0xc(%esp)
f0100ca8:	f0 
f0100ca9:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100cb0:	f0 
f0100cb1:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f0100cb8:	00 
f0100cb9:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100cc0:	e8 cf f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cca:	75 24                	jne    f0100cf0 <check_page_free_list+0x284>
f0100ccc:	c7 44 24 0c cd 49 10 	movl   $0xf01049cd,0xc(%esp)
f0100cd3:	f0 
f0100cd4:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100cdb:	f0 
f0100cdc:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
f0100ce3:	00 
f0100ce4:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100ceb:	e8 a4 f3 ff ff       	call   f0100094 <_panic>
f0100cf0:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf2:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cf7:	76 57                	jbe    f0100d50 <check_page_free_list+0x2e4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cf9:	c1 e8 0c             	shr    $0xc,%eax
f0100cfc:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100cff:	77 20                	ja     f0100d21 <check_page_free_list+0x2b5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d01:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d05:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0100d0c:	f0 
f0100d0d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d14:	00 
f0100d15:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0100d1c:	e8 73 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d21:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d27:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0100d2a:	76 29                	jbe    f0100d55 <check_page_free_list+0x2e9>
f0100d2c:	c7 44 24 0c e4 42 10 	movl   $0xf01042e4,0xc(%esp)
f0100d33:	f0 
f0100d34:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100d3b:	f0 
f0100d3c:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
f0100d43:	00 
f0100d44:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100d4b:	e8 44 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d50:	83 c7 01             	add    $0x1,%edi
f0100d53:	eb 03                	jmp    f0100d58 <check_page_free_list+0x2ec>
		else
			++nfree_extmem;
f0100d55:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d58:	8b 12                	mov    (%edx),%edx
f0100d5a:	85 d2                	test   %edx,%edx
f0100d5c:	0f 85 57 fe ff ff    	jne    f0100bb9 <check_page_free_list+0x14d>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d62:	85 ff                	test   %edi,%edi
f0100d64:	7f 24                	jg     f0100d8a <check_page_free_list+0x31e>
f0100d66:	c7 44 24 0c e7 49 10 	movl   $0xf01049e7,0xc(%esp)
f0100d6d:	f0 
f0100d6e:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100d75:	f0 
f0100d76:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0100d7d:	00 
f0100d7e:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100d85:	e8 0a f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d8a:	85 f6                	test   %esi,%esi
f0100d8c:	7f 53                	jg     f0100de1 <check_page_free_list+0x375>
f0100d8e:	c7 44 24 0c f9 49 10 	movl   $0xf01049f9,0xc(%esp)
f0100d95:	f0 
f0100d96:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0100d9d:	f0 
f0100d9e:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f0100da5:	00 
f0100da6:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100dad:	e8 e2 f2 ff ff       	call   f0100094 <_panic>
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100db2:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f0100db7:	85 c0                	test   %eax,%eax
f0100db9:	0f 85 df fc ff ff    	jne    f0100a9e <check_page_free_list+0x32>
f0100dbf:	e9 be fc ff ff       	jmp    f0100a82 <check_page_free_list+0x16>
f0100dc4:	83 3d 5c 75 11 f0 00 	cmpl   $0x0,0xf011755c
f0100dcb:	0f 84 b1 fc ff ff    	je     f0100a82 <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dd1:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dd7:	be 00 04 00 00       	mov    $0x400,%esi
f0100ddc:	e9 11 fd ff ff       	jmp    f0100af2 <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100de1:	83 c4 3c             	add    $0x3c,%esp
f0100de4:	5b                   	pop    %ebx
f0100de5:	5e                   	pop    %esi
f0100de6:	5f                   	pop    %edi
f0100de7:	5d                   	pop    %ebp
f0100de8:	c3                   	ret    

f0100de9 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100de9:	55                   	push   %ebp
f0100dea:	89 e5                	mov    %esp,%ebp
f0100dec:	53                   	push   %ebx
f0100ded:	83 ec 14             	sub    $0x14,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100df0:	83 3d 80 79 11 f0 00 	cmpl   $0x0,0xf0117980
f0100df7:	0f 84 a5 00 00 00    	je     f0100ea2 <page_init+0xb9>
f0100dfd:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100e03:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e08:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e0f:	89 d1                	mov    %edx,%ecx
f0100e11:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
f0100e17:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e1d:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100e1f:	03 15 88 79 11 f0    	add    0xf0117988,%edx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e25:	83 c0 01             	add    $0x1,%eax
f0100e28:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f0100e2e:	39 c1                	cmp    %eax,%ecx
f0100e30:	76 04                	jbe    f0100e36 <page_init+0x4d>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100e32:	89 d3                	mov    %edx,%ebx
f0100e34:	eb d2                	jmp    f0100e08 <page_init+0x1f>
f0100e36:	89 15 5c 75 11 f0    	mov    %edx,0xf011755c
	}

	//change from here.
	//mark page0 as in used.
	pages[1].pp_link=NULL;
f0100e3c:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0100e41:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e48:	81 f9 a0 00 00 00    	cmp    $0xa0,%ecx
f0100e4e:	77 1c                	ja     f0100e6c <page_init+0x83>
		panic("pa2page called with invalid pa");
f0100e50:	c7 44 24 08 2c 43 10 	movl   $0xf010432c,0x8(%esp)
f0100e57:	f0 
f0100e58:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0100e5f:	00 
f0100e60:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0100e67:	e8 28 f2 ff ff       	call   f0100094 <_panic>
	//mark IO hole and kernel code inused.
	extern char end[];
	//find the start and end free page.
	struct Page* page_free_start=pa2page(IOPHYSMEM)-1;
f0100e6c:	8d 98 f8 04 00 00    	lea    0x4f8(%eax),%ebx
	struct Page* page_free_end=pa2page((physaddr_t)(end-KERNBASE+PGSIZE+npages*sizeof(struct Page)))+1;
f0100e72:	8d 14 cd 8c 89 11 00 	lea    0x11898c(,%ecx,8),%edx
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e79:	c1 ea 0c             	shr    $0xc,%edx
f0100e7c:	39 d1                	cmp    %edx,%ecx
f0100e7e:	77 1c                	ja     f0100e9c <page_init+0xb3>
		panic("pa2page called with invalid pa");
f0100e80:	c7 44 24 08 2c 43 10 	movl   $0xf010432c,0x8(%esp)
f0100e87:	f0 
f0100e88:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0100e8f:	00 
f0100e90:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0100e97:	e8 f8 f1 ff ff       	call   f0100094 <_panic>
	page_free_end->pp_link=page_free_start;
f0100e9c:	89 5c d0 08          	mov    %ebx,0x8(%eax,%edx,8)
f0100ea0:	eb 0e                	jmp    f0100eb0 <page_init+0xc7>
		page_free_list = &pages[i];
	}

	//change from here.
	//mark page0 as in used.
	pages[1].pp_link=NULL;
f0100ea2:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0100ea7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
f0100eae:	eb a0                	jmp    f0100e50 <page_init+0x67>
	extern char end[];
	//find the start and end free page.
	struct Page* page_free_start=pa2page(IOPHYSMEM)-1;
	struct Page* page_free_end=pa2page((physaddr_t)(end-KERNBASE+PGSIZE+npages*sizeof(struct Page)))+1;
	page_free_end->pp_link=page_free_start;
}
f0100eb0:	83 c4 14             	add    $0x14,%esp
f0100eb3:	5b                   	pop    %ebx
f0100eb4:	5d                   	pop    %ebp
f0100eb5:	c3                   	ret    

f0100eb6 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100eb6:	55                   	push   %ebp
f0100eb7:	89 e5                	mov    %esp,%ebp
f0100eb9:	53                   	push   %ebx
f0100eba:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(page_free_list==NULL)
f0100ebd:	8b 1d 5c 75 11 f0    	mov    0xf011755c,%ebx
f0100ec3:	85 db                	test   %ebx,%ebx
f0100ec5:	74 69                	je     f0100f30 <page_alloc+0x7a>
		return NULL;
	struct Page* res=page_free_list;
	//make the first free page to a use page.
	page_free_list=page_free_list->pp_link;
f0100ec7:	8b 03                	mov    (%ebx),%eax
f0100ec9:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
	//page2kva():convert a page to kernel virtual addr. 
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(res),'\0',PGSIZE);
	}
	return res;
f0100ece:	89 d8                	mov    %ebx,%eax
		return NULL;
	struct Page* res=page_free_list;
	//make the first free page to a use page.
	page_free_list=page_free_list->pp_link;
	//page2kva():convert a page to kernel virtual addr. 
	if(alloc_flags & ALLOC_ZERO){
f0100ed0:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ed4:	74 5f                	je     f0100f35 <page_alloc+0x7f>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ed6:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100edc:	c1 f8 03             	sar    $0x3,%eax
f0100edf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ee2:	89 c2                	mov    %eax,%edx
f0100ee4:	c1 ea 0c             	shr    $0xc,%edx
f0100ee7:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100eed:	72 20                	jb     f0100f0f <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ef3:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0100efa:	f0 
f0100efb:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f02:	00 
f0100f03:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0100f0a:	e8 85 f1 ff ff       	call   f0100094 <_panic>
		memset(page2kva(res),'\0',PGSIZE);
f0100f0f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f16:	00 
f0100f17:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f1e:	00 
	return (void *)(pa + KERNBASE);
f0100f1f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f24:	89 04 24             	mov    %eax,(%esp)
f0100f27:	e8 63 29 00 00       	call   f010388f <memset>
	}
	return res;
f0100f2c:	89 d8                	mov    %ebx,%eax
f0100f2e:	eb 05                	jmp    f0100f35 <page_alloc+0x7f>
struct Page *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if(page_free_list==NULL)
		return NULL;
f0100f30:	b8 00 00 00 00       	mov    $0x0,%eax
	//page2kva():convert a page to kernel virtual addr. 
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(res),'\0',PGSIZE);
	}
	return res;
}
f0100f35:	83 c4 14             	add    $0x14,%esp
f0100f38:	5b                   	pop    %ebx
f0100f39:	5d                   	pop    %ebp
f0100f3a:	c3                   	ret    

f0100f3b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f3b:	55                   	push   %ebp
f0100f3c:	89 e5                	mov    %esp,%ebp
f0100f3e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link=page_free_list;
f0100f41:	8b 15 5c 75 11 f0    	mov    0xf011755c,%edx
f0100f47:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f0100f49:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
}
f0100f4e:	5d                   	pop    %ebp
f0100f4f:	c3                   	ret    

f0100f50 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f50:	55                   	push   %ebp
f0100f51:	89 e5                	mov    %esp,%ebp
f0100f53:	83 ec 04             	sub    $0x4,%esp
f0100f56:	8b 45 08             	mov    0x8(%ebp),%eax
	pp->pp_ref--;
f0100f59:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f5d:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f60:	66 89 50 04          	mov    %dx,0x4(%eax)
	if (pp->pp_ref == 0)
f0100f64:	66 85 d2             	test   %dx,%dx
f0100f67:	75 08                	jne    f0100f71 <page_decref+0x21>
		page_free(pp);
f0100f69:	89 04 24             	mov    %eax,(%esp)
f0100f6c:	e8 ca ff ff ff       	call   f0100f3b <page_free>
}
f0100f71:	c9                   	leave  
f0100f72:	c3                   	ret    

f0100f73 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f73:	55                   	push   %ebp
f0100f74:	89 e5                	mov    %esp,%ebp
f0100f76:	56                   	push   %esi
f0100f77:	53                   	push   %ebx
f0100f78:	83 ec 10             	sub    $0x10,%esp
f0100f7b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	//code from here
	pte_t* res=NULL;
	//pgDirIndex is page director index.
	uintptr_t pgDirIndex=PDX(va);
f0100f7e:	89 de                	mov    %ebx,%esi
f0100f80:	c1 ee 16             	shr    $0x16,%esi
	//page table is not exit.
	if(pgdir[pgDirIndex]==(pte_t)NULL){   
f0100f83:	c1 e6 02             	shl    $0x2,%esi
f0100f86:	03 75 08             	add    0x8(%ebp),%esi
f0100f89:	8b 06                	mov    (%esi),%eax
f0100f8b:	85 c0                	test   %eax,%eax
f0100f8d:	75 76                	jne    f0101005 <pgdir_walk+0x92>
		if(create==0){   //create is false.
f0100f8f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f93:	0f 84 d1 00 00 00    	je     f010106a <pgdir_walk+0xf7>
			return NULL;
		}
		else{
			//creat a new page
			struct Page* newPage=page_alloc(1);
f0100f99:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fa0:	e8 11 ff ff ff       	call   f0100eb6 <page_alloc>
			//ifcreat failed.
			if(newPage==NULL){
f0100fa5:	85 c0                	test   %eax,%eax
f0100fa7:	0f 84 c4 00 00 00    	je     f0101071 <pgdir_walk+0xfe>
				return NULL;
			}
			else{    //add refercencecout if creat succeed.
				newPage->pp_ref++;
f0100fad:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fb2:	89 c2                	mov    %eax,%edx
f0100fb4:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0100fba:	c1 fa 03             	sar    $0x3,%edx
f0100fbd:	c1 e2 0c             	shl    $0xc,%edx
				//convert to physical addr and set flag.
				pgdir[pgDirIndex]=page2pa(newPage)|PTE_U|PTE_W|PTE_P;
f0100fc0:	83 ca 07             	or     $0x7,%edx
f0100fc3:	89 16                	mov    %edx,(%esi)
f0100fc5:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100fcb:	c1 f8 03             	sar    $0x3,%eax
f0100fce:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fd1:	89 c2                	mov    %eax,%edx
f0100fd3:	c1 ea 0c             	shr    $0xc,%edx
f0100fd6:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100fdc:	72 20                	jb     f0100ffe <pgdir_walk+0x8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fde:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fe2:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0100fe9:	f0 
f0100fea:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ff1:	00 
f0100ff2:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0100ff9:	e8 96 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100ffe:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101003:	eb 58                	jmp    f010105d <pgdir_walk+0xea>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101005:	c1 e8 0c             	shr    $0xc,%eax
f0101008:	8b 15 80 79 11 f0    	mov    0xf0117980,%edx
f010100e:	39 d0                	cmp    %edx,%eax
f0101010:	72 1c                	jb     f010102e <pgdir_walk+0xbb>
		panic("pa2page called with invalid pa");
f0101012:	c7 44 24 08 2c 43 10 	movl   $0xf010432c,0x8(%esp)
f0101019:	f0 
f010101a:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101021:	00 
f0101022:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0101029:	e8 66 f0 ff ff       	call   f0100094 <_panic>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010102e:	89 c1                	mov    %eax,%ecx
f0101030:	c1 e1 0c             	shl    $0xc,%ecx
f0101033:	39 d0                	cmp    %edx,%eax
f0101035:	72 20                	jb     f0101057 <pgdir_walk+0xe4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101037:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010103b:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0101042:	f0 
f0101043:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010104a:	00 
f010104b:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0101052:	e8 3d f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101057:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
	}
	else{
		//convert pgdir to a pointer to PTE for 'va'
		res=page2kva(pa2page(PTE_ADDR(pgdir[pgDirIndex])));
	}
	return &res[PTX(va)];
f010105d:	c1 eb 0a             	shr    $0xa,%ebx
f0101060:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101066:	01 d8                	add    %ebx,%eax
f0101068:	eb 0c                	jmp    f0101076 <pgdir_walk+0x103>
	//pgDirIndex is page director index.
	uintptr_t pgDirIndex=PDX(va);
	//page table is not exit.
	if(pgdir[pgDirIndex]==(pte_t)NULL){   
		if(create==0){   //create is false.
			return NULL;
f010106a:	b8 00 00 00 00       	mov    $0x0,%eax
f010106f:	eb 05                	jmp    f0101076 <pgdir_walk+0x103>
		else{
			//creat a new page
			struct Page* newPage=page_alloc(1);
			//ifcreat failed.
			if(newPage==NULL){
				return NULL;
f0101071:	b8 00 00 00 00       	mov    $0x0,%eax
	else{
		//convert pgdir to a pointer to PTE for 'va'
		res=page2kva(pa2page(PTE_ADDR(pgdir[pgDirIndex])));
	}
	return &res[PTX(va)];
}
f0101076:	83 c4 10             	add    $0x10,%esp
f0101079:	5b                   	pop    %ebx
f010107a:	5e                   	pop    %esi
f010107b:	5d                   	pop    %ebp
f010107c:	c3                   	ret    

f010107d <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010107d:	55                   	push   %ebp
f010107e:	89 e5                	mov    %esp,%ebp
f0101080:	57                   	push   %edi
f0101081:	56                   	push   %esi
f0101082:	53                   	push   %ebx
f0101083:	83 ec 2c             	sub    $0x2c,%esp
f0101086:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Fill this function in
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0101089:	c1 e9 0c             	shr    $0xc,%ecx
f010108c:	85 c9                	test   %ecx,%ecx
f010108e:	74 6b                	je     f01010fb <boot_map_region+0x7e>
f0101090:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101093:	89 d3                	mov    %edx,%ebx
f0101095:	be 00 00 00 00       	mov    $0x0,%esi
f010109a:	8b 45 08             	mov    0x8(%ebp),%eax
f010109d:	29 d0                	sub    %edx,%eax
f010109f:	89 45 e0             	mov    %eax,-0x20(%ebp)
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
f01010a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010a5:	83 c8 01             	or     $0x1,%eax
f01010a8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010ae:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f01010b1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010b8:	00 
f01010b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010c0:	89 04 24             	mov    %eax,(%esp)
f01010c3:	e8 ab fe ff ff       	call   f0100f73 <pgdir_walk>
        if (!pte) panic("boot_map_region panic, out of memory");
f01010c8:	85 c0                	test   %eax,%eax
f01010ca:	75 1c                	jne    f01010e8 <boot_map_region+0x6b>
f01010cc:	c7 44 24 08 4c 43 10 	movl   $0xf010434c,0x8(%esp)
f01010d3:	f0 
f01010d4:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f01010db:	00 
f01010dc:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01010e3:	e8 ac ef ff ff       	call   f0100094 <_panic>
        *pte = pa | perm | PTE_P;
f01010e8:	0b 7d d8             	or     -0x28(%ebp),%edi
f01010eb:	89 38                	mov    %edi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f01010ed:	83 c6 01             	add    $0x1,%esi
f01010f0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010f6:	3b 75 dc             	cmp    -0x24(%ebp),%esi
f01010f9:	75 b0                	jne    f01010ab <boot_map_region+0x2e>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
    }
}
f01010fb:	83 c4 2c             	add    $0x2c,%esp
f01010fe:	5b                   	pop    %ebx
f01010ff:	5e                   	pop    %esi
f0101100:	5f                   	pop    %edi
f0101101:	5d                   	pop    %ebp
f0101102:	c3                   	ret    

f0101103 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101103:	55                   	push   %ebp
f0101104:	89 e5                	mov    %esp,%ebp
f0101106:	53                   	push   %ebx
f0101107:	83 ec 14             	sub    $0x14,%esp
f010110a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	//
	// code from here
	//
	// pgTabEnt is page table entry.
	pte_t* pgTabEnt=pgdir_walk(pgdir,va,0);
f010110d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101114:	00 
f0101115:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101118:	89 44 24 04          	mov    %eax,0x4(%esp)
f010111c:	8b 45 08             	mov    0x8(%ebp),%eax
f010111f:	89 04 24             	mov    %eax,(%esp)
f0101122:	e8 4c fe ff ff       	call   f0100f73 <pgdir_walk>
	if(pgTabEnt==NULL)
f0101127:	85 c0                	test   %eax,%eax
f0101129:	74 3e                	je     f0101169 <page_lookup+0x66>
		return NULL;
	else{
		if(pte_store!=NULL){
f010112b:	85 db                	test   %ebx,%ebx
f010112d:	74 02                	je     f0101131 <page_lookup+0x2e>
			*pte_store=pgTabEnt;
f010112f:	89 03                	mov    %eax,(%ebx)
		}
		if(pgTabEnt[0]!=(pte_t)NULL){
f0101131:	8b 00                	mov    (%eax),%eax
f0101133:	85 c0                	test   %eax,%eax
f0101135:	74 39                	je     f0101170 <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101137:	c1 e8 0c             	shr    $0xc,%eax
f010113a:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0101140:	72 1c                	jb     f010115e <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f0101142:	c7 44 24 08 2c 43 10 	movl   $0xf010432c,0x8(%esp)
f0101149:	f0 
f010114a:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101151:	00 
f0101152:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0101159:	e8 36 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010115e:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
f0101164:	8d 04 c2             	lea    (%edx,%eax,8),%eax
			// return page table entry  kernel virtual addr.
			return pa2page(PTE_ADDR(pgTabEnt[0]));
f0101167:	eb 0c                	jmp    f0101175 <page_lookup+0x72>
	// code from here
	//
	// pgTabEnt is page table entry.
	pte_t* pgTabEnt=pgdir_walk(pgdir,va,0);
	if(pgTabEnt==NULL)
		return NULL;
f0101169:	b8 00 00 00 00       	mov    $0x0,%eax
f010116e:	eb 05                	jmp    f0101175 <page_lookup+0x72>
		if(pgTabEnt[0]!=(pte_t)NULL){
			// return page table entry  kernel virtual addr.
			return pa2page(PTE_ADDR(pgTabEnt[0]));
		}
		else{
			return NULL;
f0101170:	b8 00 00 00 00       	mov    $0x0,%eax
		}
	}
}
f0101175:	83 c4 14             	add    $0x14,%esp
f0101178:	5b                   	pop    %ebx
f0101179:	5d                   	pop    %ebp
f010117a:	c3                   	ret    

f010117b <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010117b:	55                   	push   %ebp
f010117c:	89 e5                	mov    %esp,%ebp
f010117e:	53                   	push   %ebx
f010117f:	83 ec 24             	sub    $0x24,%esp
f0101182:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	// code from here
	//
	pte_t* pgTabEnt;
	struct Page* page=page_lookup(pgdir,va,&pgTabEnt);
f0101185:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101188:	89 44 24 08          	mov    %eax,0x8(%esp)
f010118c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101190:	8b 45 08             	mov    0x8(%ebp),%eax
f0101193:	89 04 24             	mov    %eax,(%esp)
f0101196:	e8 68 ff ff ff       	call   f0101103 <page_lookup>
	if(page!=NULL){
f010119b:	85 c0                	test   %eax,%eax
f010119d:	74 08                	je     f01011a7 <page_remove+0x2c>
		page_decref(page);
f010119f:	89 04 24             	mov    %eax,(%esp)
f01011a2:	e8 a9 fd ff ff       	call   f0100f50 <page_decref>
	}
	//can't be pgTabEnt[0]=NULL because of must be PGSIZE?
	pgTabEnt[0]=0;
f01011a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011aa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011b0:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir,va);
}
f01011b3:	83 c4 24             	add    $0x24,%esp
f01011b6:	5b                   	pop    %ebx
f01011b7:	5d                   	pop    %ebp
f01011b8:	c3                   	ret    

f01011b9 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01011b9:	55                   	push   %ebp
f01011ba:	89 e5                	mov    %esp,%ebp
f01011bc:	57                   	push   %edi
f01011bd:	56                   	push   %esi
f01011be:	53                   	push   %ebx
f01011bf:	83 ec 1c             	sub    $0x1c,%esp
f01011c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01011c5:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	//
	//code from here.
	pte_t* pte=pgdir_walk(pgdir,va,1);
f01011c8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011cf:	00 
f01011d0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d7:	89 04 24             	mov    %eax,(%esp)
f01011da:	e8 94 fd ff ff       	call   f0100f73 <pgdir_walk>
f01011df:	89 c6                	mov    %eax,%esi
	if(pte==NULL){
f01011e1:	85 c0                	test   %eax,%eax
f01011e3:	74 5a                	je     f010123f <page_insert+0x86>
		return -E_NO_MEM;
	}
	if (*pte & PTE_P) {
f01011e5:	8b 00                	mov    (%eax),%eax
f01011e7:	a8 01                	test   $0x1,%al
f01011e9:	74 30                	je     f010121b <page_insert+0x62>
		if (PTE_ADDR(*pte) == page2pa (pp)) {
f01011eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01011f0:	89 da                	mov    %ebx,%edx
f01011f2:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01011f8:	c1 fa 03             	sar    $0x3,%edx
f01011fb:	c1 e2 0c             	shl    $0xc,%edx
f01011fe:	39 d0                	cmp    %edx,%eax
f0101200:	75 0a                	jne    f010120c <page_insert+0x53>
f0101202:	0f 01 3f             	invlpg (%edi)
			tlb_invalidate (pgdir, va);
			pp -> pp_ref --;
f0101205:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f010120a:	eb 0f                	jmp    f010121b <page_insert+0x62>
		} else {
			page_remove (pgdir, va);
f010120c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101210:	8b 45 08             	mov    0x8(%ebp),%eax
f0101213:	89 04 24             	mov    %eax,(%esp)
f0101216:	e8 60 ff ff ff       	call   f010117b <page_remove>
		}
	}
	*pte = page2pa (pp)|perm|PTE_P;
f010121b:	8b 55 14             	mov    0x14(%ebp),%edx
f010121e:	83 ca 01             	or     $0x1,%edx
f0101221:	89 d8                	mov    %ebx,%eax
f0101223:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101229:	c1 f8 03             	sar    $0x3,%eax
f010122c:	c1 e0 0c             	shl    $0xc,%eax
f010122f:	09 d0                	or     %edx,%eax
f0101231:	89 06                	mov    %eax,(%esi)
	pp -> pp_ref ++;
f0101233:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f0101238:	b8 00 00 00 00       	mov    $0x0,%eax
f010123d:	eb 05                	jmp    f0101244 <page_insert+0x8b>
	// Fill this function in
	//
	//code from here.
	pte_t* pte=pgdir_walk(pgdir,va,1);
	if(pte==NULL){
		return -E_NO_MEM;
f010123f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		}
	}
	*pte = page2pa (pp)|perm|PTE_P;
	pp -> pp_ref ++;
	return 0;
}
f0101244:	83 c4 1c             	add    $0x1c,%esp
f0101247:	5b                   	pop    %ebx
f0101248:	5e                   	pop    %esi
f0101249:	5f                   	pop    %edi
f010124a:	5d                   	pop    %ebp
f010124b:	c3                   	ret    

f010124c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010124c:	55                   	push   %ebp
f010124d:	89 e5                	mov    %esp,%ebp
f010124f:	57                   	push   %edi
f0101250:	56                   	push   %esi
f0101251:	53                   	push   %ebx
f0101252:	83 ec 3c             	sub    $0x3c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101255:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f010125c:	e8 20 1a 00 00       	call   f0102c81 <mc146818_read>
f0101261:	89 c3                	mov    %eax,%ebx
f0101263:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010126a:	e8 12 1a 00 00       	call   f0102c81 <mc146818_read>
f010126f:	c1 e0 08             	shl    $0x8,%eax
f0101272:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101274:	89 d8                	mov    %ebx,%eax
f0101276:	c1 e0 0a             	shl    $0xa,%eax
f0101279:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010127f:	85 c0                	test   %eax,%eax
f0101281:	0f 48 c2             	cmovs  %edx,%eax
f0101284:	c1 f8 0c             	sar    $0xc,%eax
f0101287:	a3 60 75 11 f0       	mov    %eax,0xf0117560
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010128c:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101293:	e8 e9 19 00 00       	call   f0102c81 <mc146818_read>
f0101298:	89 c3                	mov    %eax,%ebx
f010129a:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01012a1:	e8 db 19 00 00       	call   f0102c81 <mc146818_read>
f01012a6:	c1 e0 08             	shl    $0x8,%eax
f01012a9:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012ab:	89 d8                	mov    %ebx,%eax
f01012ad:	c1 e0 0a             	shl    $0xa,%eax
f01012b0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012b6:	85 c0                	test   %eax,%eax
f01012b8:	0f 48 c2             	cmovs  %edx,%eax
f01012bb:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012be:	85 c0                	test   %eax,%eax
f01012c0:	74 0e                	je     f01012d0 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012c2:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012c8:	89 15 80 79 11 f0    	mov    %edx,0xf0117980
f01012ce:	eb 0c                	jmp    f01012dc <mem_init+0x90>
	else
		npages = npages_basemem;
f01012d0:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f01012d6:	89 15 80 79 11 f0    	mov    %edx,0xf0117980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012dc:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012df:	c1 e8 0a             	shr    $0xa,%eax
f01012e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012e6:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f01012eb:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ee:	c1 e8 0a             	shr    $0xa,%eax
f01012f1:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01012f5:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01012fa:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012fd:	c1 e8 0a             	shr    $0xa,%eax
f0101300:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101304:	c7 04 24 74 43 10 f0 	movl   $0xf0104374,(%esp)
f010130b:	e8 e1 19 00 00       	call   f0102cf1 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101310:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101315:	e8 66 f6 ff ff       	call   f0100980 <boot_alloc>
f010131a:	a3 84 79 11 f0       	mov    %eax,0xf0117984
	memset(kern_pgdir, 0, PGSIZE);
f010131f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101326:	00 
f0101327:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010132e:	00 
f010132f:	89 04 24             	mov    %eax,(%esp)
f0101332:	e8 58 25 00 00       	call   f010388f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101337:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010133c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101341:	77 20                	ja     f0101363 <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101343:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101347:	c7 44 24 08 b0 43 10 	movl   $0xf01043b0,0x8(%esp)
f010134e:	f0 
f010134f:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
f0101356:	00 
f0101357:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010135e:	e8 31 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101363:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101369:	83 ca 05             	or     $0x5,%edx
f010136c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages=(struct Page*)boot_alloc(npages*sizeof(struct Page));
f0101372:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0101377:	c1 e0 03             	shl    $0x3,%eax
f010137a:	e8 01 f6 ff ff       	call   f0100980 <boot_alloc>
f010137f:	a3 88 79 11 f0       	mov    %eax,0xf0117988
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101384:	e8 60 fa ff ff       	call   f0100de9 <page_init>

	check_page_free_list(1);
f0101389:	b8 01 00 00 00       	mov    $0x1,%eax
f010138e:	e8 d9 f6 ff ff       	call   f0100a6c <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101393:	83 3d 88 79 11 f0 00 	cmpl   $0x0,0xf0117988
f010139a:	75 1c                	jne    f01013b8 <mem_init+0x16c>
		panic("'pages' is a null pointer!");
f010139c:	c7 44 24 08 0a 4a 10 	movl   $0xf0104a0a,0x8(%esp)
f01013a3:	f0 
f01013a4:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f01013ab:	00 
f01013ac:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01013b3:	e8 dc ec ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b8:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01013bd:	85 c0                	test   %eax,%eax
f01013bf:	74 10                	je     f01013d1 <mem_init+0x185>
f01013c1:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f01013c6:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013c9:	8b 00                	mov    (%eax),%eax
f01013cb:	85 c0                	test   %eax,%eax
f01013cd:	75 f7                	jne    f01013c6 <mem_init+0x17a>
f01013cf:	eb 05                	jmp    f01013d6 <mem_init+0x18a>
f01013d1:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013dd:	e8 d4 fa ff ff       	call   f0100eb6 <page_alloc>
f01013e2:	89 c7                	mov    %eax,%edi
f01013e4:	85 c0                	test   %eax,%eax
f01013e6:	75 24                	jne    f010140c <mem_init+0x1c0>
f01013e8:	c7 44 24 0c 25 4a 10 	movl   $0xf0104a25,0xc(%esp)
f01013ef:	f0 
f01013f0:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01013f7:	f0 
f01013f8:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f01013ff:	00 
f0101400:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101407:	e8 88 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010140c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101413:	e8 9e fa ff ff       	call   f0100eb6 <page_alloc>
f0101418:	89 c6                	mov    %eax,%esi
f010141a:	85 c0                	test   %eax,%eax
f010141c:	75 24                	jne    f0101442 <mem_init+0x1f6>
f010141e:	c7 44 24 0c 3b 4a 10 	movl   $0xf0104a3b,0xc(%esp)
f0101425:	f0 
f0101426:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010142d:	f0 
f010142e:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f0101435:	00 
f0101436:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010143d:	e8 52 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101442:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101449:	e8 68 fa ff ff       	call   f0100eb6 <page_alloc>
f010144e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101451:	85 c0                	test   %eax,%eax
f0101453:	75 24                	jne    f0101479 <mem_init+0x22d>
f0101455:	c7 44 24 0c 51 4a 10 	movl   $0xf0104a51,0xc(%esp)
f010145c:	f0 
f010145d:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101464:	f0 
f0101465:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f010146c:	00 
f010146d:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101474:	e8 1b ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101479:	39 f7                	cmp    %esi,%edi
f010147b:	75 24                	jne    f01014a1 <mem_init+0x255>
f010147d:	c7 44 24 0c 67 4a 10 	movl   $0xf0104a67,0xc(%esp)
f0101484:	f0 
f0101485:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010148c:	f0 
f010148d:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101494:	00 
f0101495:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010149c:	e8 f3 eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014a4:	39 c6                	cmp    %eax,%esi
f01014a6:	74 04                	je     f01014ac <mem_init+0x260>
f01014a8:	39 c7                	cmp    %eax,%edi
f01014aa:	75 24                	jne    f01014d0 <mem_init+0x284>
f01014ac:	c7 44 24 0c d4 43 10 	movl   $0xf01043d4,0xc(%esp)
f01014b3:	f0 
f01014b4:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01014bb:	f0 
f01014bc:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f01014c3:	00 
f01014c4:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01014cb:	e8 c4 eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01014d0:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014d6:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01014db:	c1 e0 0c             	shl    $0xc,%eax
f01014de:	89 f9                	mov    %edi,%ecx
f01014e0:	29 d1                	sub    %edx,%ecx
f01014e2:	c1 f9 03             	sar    $0x3,%ecx
f01014e5:	c1 e1 0c             	shl    $0xc,%ecx
f01014e8:	39 c1                	cmp    %eax,%ecx
f01014ea:	72 24                	jb     f0101510 <mem_init+0x2c4>
f01014ec:	c7 44 24 0c 79 4a 10 	movl   $0xf0104a79,0xc(%esp)
f01014f3:	f0 
f01014f4:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01014fb:	f0 
f01014fc:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0101503:	00 
f0101504:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010150b:	e8 84 eb ff ff       	call   f0100094 <_panic>
f0101510:	89 f1                	mov    %esi,%ecx
f0101512:	29 d1                	sub    %edx,%ecx
f0101514:	c1 f9 03             	sar    $0x3,%ecx
f0101517:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010151a:	39 c8                	cmp    %ecx,%eax
f010151c:	77 24                	ja     f0101542 <mem_init+0x2f6>
f010151e:	c7 44 24 0c 96 4a 10 	movl   $0xf0104a96,0xc(%esp)
f0101525:	f0 
f0101526:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010152d:	f0 
f010152e:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f0101535:	00 
f0101536:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010153d:	e8 52 eb ff ff       	call   f0100094 <_panic>
f0101542:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101545:	29 d1                	sub    %edx,%ecx
f0101547:	89 ca                	mov    %ecx,%edx
f0101549:	c1 fa 03             	sar    $0x3,%edx
f010154c:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010154f:	39 d0                	cmp    %edx,%eax
f0101551:	77 24                	ja     f0101577 <mem_init+0x32b>
f0101553:	c7 44 24 0c b3 4a 10 	movl   $0xf0104ab3,0xc(%esp)
f010155a:	f0 
f010155b:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101562:	f0 
f0101563:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f010156a:	00 
f010156b:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101572:	e8 1d eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101577:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f010157c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010157f:	c7 05 5c 75 11 f0 00 	movl   $0x0,0xf011755c
f0101586:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101589:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101590:	e8 21 f9 ff ff       	call   f0100eb6 <page_alloc>
f0101595:	85 c0                	test   %eax,%eax
f0101597:	74 24                	je     f01015bd <mem_init+0x371>
f0101599:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f01015a0:	f0 
f01015a1:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01015a8:	f0 
f01015a9:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01015b0:	00 
f01015b1:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01015b8:	e8 d7 ea ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015bd:	89 3c 24             	mov    %edi,(%esp)
f01015c0:	e8 76 f9 ff ff       	call   f0100f3b <page_free>
	page_free(pp1);
f01015c5:	89 34 24             	mov    %esi,(%esp)
f01015c8:	e8 6e f9 ff ff       	call   f0100f3b <page_free>
	page_free(pp2);
f01015cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015d0:	89 04 24             	mov    %eax,(%esp)
f01015d3:	e8 63 f9 ff ff       	call   f0100f3b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015df:	e8 d2 f8 ff ff       	call   f0100eb6 <page_alloc>
f01015e4:	89 c6                	mov    %eax,%esi
f01015e6:	85 c0                	test   %eax,%eax
f01015e8:	75 24                	jne    f010160e <mem_init+0x3c2>
f01015ea:	c7 44 24 0c 25 4a 10 	movl   $0xf0104a25,0xc(%esp)
f01015f1:	f0 
f01015f2:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01015f9:	f0 
f01015fa:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f0101601:	00 
f0101602:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101609:	e8 86 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010160e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101615:	e8 9c f8 ff ff       	call   f0100eb6 <page_alloc>
f010161a:	89 c7                	mov    %eax,%edi
f010161c:	85 c0                	test   %eax,%eax
f010161e:	75 24                	jne    f0101644 <mem_init+0x3f8>
f0101620:	c7 44 24 0c 3b 4a 10 	movl   $0xf0104a3b,0xc(%esp)
f0101627:	f0 
f0101628:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010162f:	f0 
f0101630:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0101637:	00 
f0101638:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010163f:	e8 50 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101644:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010164b:	e8 66 f8 ff ff       	call   f0100eb6 <page_alloc>
f0101650:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101653:	85 c0                	test   %eax,%eax
f0101655:	75 24                	jne    f010167b <mem_init+0x42f>
f0101657:	c7 44 24 0c 51 4a 10 	movl   $0xf0104a51,0xc(%esp)
f010165e:	f0 
f010165f:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101666:	f0 
f0101667:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f010166e:	00 
f010166f:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101676:	e8 19 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010167b:	39 fe                	cmp    %edi,%esi
f010167d:	75 24                	jne    f01016a3 <mem_init+0x457>
f010167f:	c7 44 24 0c 67 4a 10 	movl   $0xf0104a67,0xc(%esp)
f0101686:	f0 
f0101687:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010168e:	f0 
f010168f:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101696:	00 
f0101697:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010169e:	e8 f1 e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016a6:	39 c7                	cmp    %eax,%edi
f01016a8:	74 04                	je     f01016ae <mem_init+0x462>
f01016aa:	39 c6                	cmp    %eax,%esi
f01016ac:	75 24                	jne    f01016d2 <mem_init+0x486>
f01016ae:	c7 44 24 0c d4 43 10 	movl   $0xf01043d4,0xc(%esp)
f01016b5:	f0 
f01016b6:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01016bd:	f0 
f01016be:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f01016c5:	00 
f01016c6:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01016cd:	e8 c2 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016d2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016d9:	e8 d8 f7 ff ff       	call   f0100eb6 <page_alloc>
f01016de:	85 c0                	test   %eax,%eax
f01016e0:	74 24                	je     f0101706 <mem_init+0x4ba>
f01016e2:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f01016e9:	f0 
f01016ea:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01016f1:	f0 
f01016f2:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01016f9:	00 
f01016fa:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101701:	e8 8e e9 ff ff       	call   f0100094 <_panic>
f0101706:	89 f0                	mov    %esi,%eax
f0101708:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010170e:	c1 f8 03             	sar    $0x3,%eax
f0101711:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101714:	89 c2                	mov    %eax,%edx
f0101716:	c1 ea 0c             	shr    $0xc,%edx
f0101719:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f010171f:	72 20                	jb     f0101741 <mem_init+0x4f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101721:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101725:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f010172c:	f0 
f010172d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101734:	00 
f0101735:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f010173c:	e8 53 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101741:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101748:	00 
f0101749:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101750:	00 
	return (void *)(pa + KERNBASE);
f0101751:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101756:	89 04 24             	mov    %eax,(%esp)
f0101759:	e8 31 21 00 00       	call   f010388f <memset>
	page_free(pp0);
f010175e:	89 34 24             	mov    %esi,(%esp)
f0101761:	e8 d5 f7 ff ff       	call   f0100f3b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101766:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010176d:	e8 44 f7 ff ff       	call   f0100eb6 <page_alloc>
f0101772:	85 c0                	test   %eax,%eax
f0101774:	75 24                	jne    f010179a <mem_init+0x54e>
f0101776:	c7 44 24 0c df 4a 10 	movl   $0xf0104adf,0xc(%esp)
f010177d:	f0 
f010177e:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101785:	f0 
f0101786:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f010178d:	00 
f010178e:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101795:	e8 fa e8 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010179a:	39 c6                	cmp    %eax,%esi
f010179c:	74 24                	je     f01017c2 <mem_init+0x576>
f010179e:	c7 44 24 0c fd 4a 10 	movl   $0xf0104afd,0xc(%esp)
f01017a5:	f0 
f01017a6:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01017ad:	f0 
f01017ae:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f01017b5:	00 
f01017b6:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01017bd:	e8 d2 e8 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01017c2:	89 f2                	mov    %esi,%edx
f01017c4:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01017ca:	c1 fa 03             	sar    $0x3,%edx
f01017cd:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017d0:	89 d0                	mov    %edx,%eax
f01017d2:	c1 e8 0c             	shr    $0xc,%eax
f01017d5:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01017db:	72 20                	jb     f01017fd <mem_init+0x5b1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017dd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017e1:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f01017e8:	f0 
f01017e9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017f0:	00 
f01017f1:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f01017f8:	e8 97 e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017fd:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101804:	75 11                	jne    f0101817 <mem_init+0x5cb>
f0101806:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
f010180c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0101812:	80 38 00             	cmpb   $0x0,(%eax)
f0101815:	74 24                	je     f010183b <mem_init+0x5ef>
f0101817:	c7 44 24 0c 0d 4b 10 	movl   $0xf0104b0d,0xc(%esp)
f010181e:	f0 
f010181f:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101826:	f0 
f0101827:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f010182e:	00 
f010182f:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101836:	e8 59 e8 ff ff       	call   f0100094 <_panic>
f010183b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010183e:	39 d0                	cmp    %edx,%eax
f0101840:	75 d0                	jne    f0101812 <mem_init+0x5c6>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101842:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101845:	a3 5c 75 11 f0       	mov    %eax,0xf011755c

	// free the pages we took
	page_free(pp0);
f010184a:	89 34 24             	mov    %esi,(%esp)
f010184d:	e8 e9 f6 ff ff       	call   f0100f3b <page_free>
	page_free(pp1);
f0101852:	89 3c 24             	mov    %edi,(%esp)
f0101855:	e8 e1 f6 ff ff       	call   f0100f3b <page_free>
	page_free(pp2);
f010185a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010185d:	89 04 24             	mov    %eax,(%esp)
f0101860:	e8 d6 f6 ff ff       	call   f0100f3b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101865:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f010186a:	85 c0                	test   %eax,%eax
f010186c:	74 09                	je     f0101877 <mem_init+0x62b>
		--nfree;
f010186e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101871:	8b 00                	mov    (%eax),%eax
f0101873:	85 c0                	test   %eax,%eax
f0101875:	75 f7                	jne    f010186e <mem_init+0x622>
		--nfree;
	assert(nfree == 0);
f0101877:	85 db                	test   %ebx,%ebx
f0101879:	74 24                	je     f010189f <mem_init+0x653>
f010187b:	c7 44 24 0c 17 4b 10 	movl   $0xf0104b17,0xc(%esp)
f0101882:	f0 
f0101883:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010188a:	f0 
f010188b:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0101892:	00 
f0101893:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010189a:	e8 f5 e7 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010189f:	c7 04 24 f4 43 10 f0 	movl   $0xf01043f4,(%esp)
f01018a6:	e8 46 14 00 00       	call   f0102cf1 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018b2:	e8 ff f5 ff ff       	call   f0100eb6 <page_alloc>
f01018b7:	89 c3                	mov    %eax,%ebx
f01018b9:	85 c0                	test   %eax,%eax
f01018bb:	75 24                	jne    f01018e1 <mem_init+0x695>
f01018bd:	c7 44 24 0c 25 4a 10 	movl   $0xf0104a25,0xc(%esp)
f01018c4:	f0 
f01018c5:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01018cc:	f0 
f01018cd:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01018d4:	00 
f01018d5:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01018dc:	e8 b3 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018e8:	e8 c9 f5 ff ff       	call   f0100eb6 <page_alloc>
f01018ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018f0:	85 c0                	test   %eax,%eax
f01018f2:	75 24                	jne    f0101918 <mem_init+0x6cc>
f01018f4:	c7 44 24 0c 3b 4a 10 	movl   $0xf0104a3b,0xc(%esp)
f01018fb:	f0 
f01018fc:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101903:	f0 
f0101904:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f010190b:	00 
f010190c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101913:	e8 7c e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101918:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010191f:	e8 92 f5 ff ff       	call   f0100eb6 <page_alloc>
f0101924:	89 c6                	mov    %eax,%esi
f0101926:	85 c0                	test   %eax,%eax
f0101928:	75 24                	jne    f010194e <mem_init+0x702>
f010192a:	c7 44 24 0c 51 4a 10 	movl   $0xf0104a51,0xc(%esp)
f0101931:	f0 
f0101932:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101939:	f0 
f010193a:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f0101941:	00 
f0101942:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101949:	e8 46 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010194e:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101951:	75 24                	jne    f0101977 <mem_init+0x72b>
f0101953:	c7 44 24 0c 67 4a 10 	movl   $0xf0104a67,0xc(%esp)
f010195a:	f0 
f010195b:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101962:	f0 
f0101963:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f010196a:	00 
f010196b:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101972:	e8 1d e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101977:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010197a:	74 04                	je     f0101980 <mem_init+0x734>
f010197c:	39 c3                	cmp    %eax,%ebx
f010197e:	75 24                	jne    f01019a4 <mem_init+0x758>
f0101980:	c7 44 24 0c d4 43 10 	movl   $0xf01043d4,0xc(%esp)
f0101987:	f0 
f0101988:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010198f:	f0 
f0101990:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f0101997:	00 
f0101998:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010199f:	e8 f0 e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019a4:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
f01019a9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01019ac:	c7 05 5c 75 11 f0 00 	movl   $0x0,0xf011755c
f01019b3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019b6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019bd:	e8 f4 f4 ff ff       	call   f0100eb6 <page_alloc>
f01019c2:	85 c0                	test   %eax,%eax
f01019c4:	74 24                	je     f01019ea <mem_init+0x79e>
f01019c6:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f01019cd:	f0 
f01019ce:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01019d5:	f0 
f01019d6:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f01019dd:	00 
f01019de:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01019e5:	e8 aa e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019ea:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019ed:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019f8:	00 
f01019f9:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01019fe:	89 04 24             	mov    %eax,(%esp)
f0101a01:	e8 fd f6 ff ff       	call   f0101103 <page_lookup>
f0101a06:	85 c0                	test   %eax,%eax
f0101a08:	74 24                	je     f0101a2e <mem_init+0x7e2>
f0101a0a:	c7 44 24 0c 14 44 10 	movl   $0xf0104414,0xc(%esp)
f0101a11:	f0 
f0101a12:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101a19:	f0 
f0101a1a:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101a21:	00 
f0101a22:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101a29:	e8 66 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a2e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a35:	00 
f0101a36:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a3d:	00 
f0101a3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a41:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a45:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101a4a:	89 04 24             	mov    %eax,(%esp)
f0101a4d:	e8 67 f7 ff ff       	call   f01011b9 <page_insert>
f0101a52:	85 c0                	test   %eax,%eax
f0101a54:	78 24                	js     f0101a7a <mem_init+0x82e>
f0101a56:	c7 44 24 0c 4c 44 10 	movl   $0xf010444c,0xc(%esp)
f0101a5d:	f0 
f0101a5e:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101a65:	f0 
f0101a66:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101a6d:	00 
f0101a6e:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101a75:	e8 1a e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a7a:	89 1c 24             	mov    %ebx,(%esp)
f0101a7d:	e8 b9 f4 ff ff       	call   f0100f3b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a82:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a89:	00 
f0101a8a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a91:	00 
f0101a92:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a95:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a99:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101a9e:	89 04 24             	mov    %eax,(%esp)
f0101aa1:	e8 13 f7 ff ff       	call   f01011b9 <page_insert>
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	74 24                	je     f0101ace <mem_init+0x882>
f0101aaa:	c7 44 24 0c 7c 44 10 	movl   $0xf010447c,0xc(%esp)
f0101ab1:	f0 
f0101ab2:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101ab9:	f0 
f0101aba:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101ac1:	00 
f0101ac2:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101ac9:	e8 c6 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ace:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ad4:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0101ad9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101adc:	8b 17                	mov    (%edi),%edx
f0101ade:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ae4:	89 d9                	mov    %ebx,%ecx
f0101ae6:	29 c1                	sub    %eax,%ecx
f0101ae8:	89 c8                	mov    %ecx,%eax
f0101aea:	c1 f8 03             	sar    $0x3,%eax
f0101aed:	c1 e0 0c             	shl    $0xc,%eax
f0101af0:	39 c2                	cmp    %eax,%edx
f0101af2:	74 24                	je     f0101b18 <mem_init+0x8cc>
f0101af4:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f0101afb:	f0 
f0101afc:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101b03:	f0 
f0101b04:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101b0b:	00 
f0101b0c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101b13:	e8 7c e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b18:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b1d:	89 f8                	mov    %edi,%eax
f0101b1f:	e8 d9 ee ff ff       	call   f01009fd <check_va2pa>
f0101b24:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b27:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b2a:	c1 fa 03             	sar    $0x3,%edx
f0101b2d:	c1 e2 0c             	shl    $0xc,%edx
f0101b30:	39 d0                	cmp    %edx,%eax
f0101b32:	74 24                	je     f0101b58 <mem_init+0x90c>
f0101b34:	c7 44 24 0c d4 44 10 	movl   $0xf01044d4,0xc(%esp)
f0101b3b:	f0 
f0101b3c:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101b43:	f0 
f0101b44:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101b4b:	00 
f0101b4c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101b53:	e8 3c e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b5b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b60:	74 24                	je     f0101b86 <mem_init+0x93a>
f0101b62:	c7 44 24 0c 22 4b 10 	movl   $0xf0104b22,0xc(%esp)
f0101b69:	f0 
f0101b6a:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101b71:	f0 
f0101b72:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101b79:	00 
f0101b7a:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101b81:	e8 0e e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b86:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b8b:	74 24                	je     f0101bb1 <mem_init+0x965>
f0101b8d:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f0101b94:	f0 
f0101b95:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101b9c:	f0 
f0101b9d:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101ba4:	00 
f0101ba5:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101bac:	e8 e3 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bb1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bb8:	00 
f0101bb9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bc0:	00 
f0101bc1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bc5:	89 3c 24             	mov    %edi,(%esp)
f0101bc8:	e8 ec f5 ff ff       	call   f01011b9 <page_insert>
f0101bcd:	85 c0                	test   %eax,%eax
f0101bcf:	74 24                	je     f0101bf5 <mem_init+0x9a9>
f0101bd1:	c7 44 24 0c 04 45 10 	movl   $0xf0104504,0xc(%esp)
f0101bd8:	f0 
f0101bd9:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101be0:	f0 
f0101be1:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101be8:	00 
f0101be9:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101bf0:	e8 9f e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bf5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bfa:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101bff:	e8 f9 ed ff ff       	call   f01009fd <check_va2pa>
f0101c04:	89 f2                	mov    %esi,%edx
f0101c06:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101c0c:	c1 fa 03             	sar    $0x3,%edx
f0101c0f:	c1 e2 0c             	shl    $0xc,%edx
f0101c12:	39 d0                	cmp    %edx,%eax
f0101c14:	74 24                	je     f0101c3a <mem_init+0x9ee>
f0101c16:	c7 44 24 0c 40 45 10 	movl   $0xf0104540,0xc(%esp)
f0101c1d:	f0 
f0101c1e:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101c25:	f0 
f0101c26:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101c2d:	00 
f0101c2e:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101c35:	e8 5a e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c3a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c3f:	74 24                	je     f0101c65 <mem_init+0xa19>
f0101c41:	c7 44 24 0c 44 4b 10 	movl   $0xf0104b44,0xc(%esp)
f0101c48:	f0 
f0101c49:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101c50:	f0 
f0101c51:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101c58:	00 
f0101c59:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101c60:	e8 2f e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c65:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c6c:	e8 45 f2 ff ff       	call   f0100eb6 <page_alloc>
f0101c71:	85 c0                	test   %eax,%eax
f0101c73:	74 24                	je     f0101c99 <mem_init+0xa4d>
f0101c75:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f0101c7c:	f0 
f0101c7d:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101c8c:	00 
f0101c8d:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101c94:	e8 fb e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c99:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ca0:	00 
f0101ca1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ca8:	00 
f0101ca9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cad:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101cb2:	89 04 24             	mov    %eax,(%esp)
f0101cb5:	e8 ff f4 ff ff       	call   f01011b9 <page_insert>
f0101cba:	85 c0                	test   %eax,%eax
f0101cbc:	74 24                	je     f0101ce2 <mem_init+0xa96>
f0101cbe:	c7 44 24 0c 04 45 10 	movl   $0xf0104504,0xc(%esp)
f0101cc5:	f0 
f0101cc6:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101ccd:	f0 
f0101cce:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101cd5:	00 
f0101cd6:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101cdd:	e8 b2 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ce2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce7:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101cec:	e8 0c ed ff ff       	call   f01009fd <check_va2pa>
f0101cf1:	89 f2                	mov    %esi,%edx
f0101cf3:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101cf9:	c1 fa 03             	sar    $0x3,%edx
f0101cfc:	c1 e2 0c             	shl    $0xc,%edx
f0101cff:	39 d0                	cmp    %edx,%eax
f0101d01:	74 24                	je     f0101d27 <mem_init+0xadb>
f0101d03:	c7 44 24 0c 40 45 10 	movl   $0xf0104540,0xc(%esp)
f0101d0a:	f0 
f0101d0b:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101d12:	f0 
f0101d13:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101d1a:	00 
f0101d1b:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101d22:	e8 6d e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d27:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d2c:	74 24                	je     f0101d52 <mem_init+0xb06>
f0101d2e:	c7 44 24 0c 44 4b 10 	movl   $0xf0104b44,0xc(%esp)
f0101d35:	f0 
f0101d36:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101d3d:	f0 
f0101d3e:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101d45:	00 
f0101d46:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101d4d:	e8 42 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d59:	e8 58 f1 ff ff       	call   f0100eb6 <page_alloc>
f0101d5e:	85 c0                	test   %eax,%eax
f0101d60:	74 24                	je     f0101d86 <mem_init+0xb3a>
f0101d62:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f0101d69:	f0 
f0101d6a:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101d71:	f0 
f0101d72:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0101d79:	00 
f0101d7a:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101d81:	e8 0e e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d86:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0101d8c:	8b 02                	mov    (%edx),%eax
f0101d8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d93:	89 c1                	mov    %eax,%ecx
f0101d95:	c1 e9 0c             	shr    $0xc,%ecx
f0101d98:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f0101d9e:	72 20                	jb     f0101dc0 <mem_init+0xb74>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101da0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101da4:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0101dab:	f0 
f0101dac:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101db3:	00 
f0101db4:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101dbb:	e8 d4 e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101dc0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101dc5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101dc8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dcf:	00 
f0101dd0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101dd7:	00 
f0101dd8:	89 14 24             	mov    %edx,(%esp)
f0101ddb:	e8 93 f1 ff ff       	call   f0100f73 <pgdir_walk>
f0101de0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101de3:	8d 51 04             	lea    0x4(%ecx),%edx
f0101de6:	39 d0                	cmp    %edx,%eax
f0101de8:	74 24                	je     f0101e0e <mem_init+0xbc2>
f0101dea:	c7 44 24 0c 70 45 10 	movl   $0xf0104570,0xc(%esp)
f0101df1:	f0 
f0101df2:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101df9:	f0 
f0101dfa:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101e01:	00 
f0101e02:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101e09:	e8 86 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e0e:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e15:	00 
f0101e16:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e1d:	00 
f0101e1e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e22:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101e27:	89 04 24             	mov    %eax,(%esp)
f0101e2a:	e8 8a f3 ff ff       	call   f01011b9 <page_insert>
f0101e2f:	85 c0                	test   %eax,%eax
f0101e31:	74 24                	je     f0101e57 <mem_init+0xc0b>
f0101e33:	c7 44 24 0c b0 45 10 	movl   $0xf01045b0,0xc(%esp)
f0101e3a:	f0 
f0101e3b:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101e42:	f0 
f0101e43:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101e4a:	00 
f0101e4b:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101e52:	e8 3d e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e57:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0101e5d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e62:	89 f8                	mov    %edi,%eax
f0101e64:	e8 94 eb ff ff       	call   f01009fd <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e69:	89 f2                	mov    %esi,%edx
f0101e6b:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101e71:	c1 fa 03             	sar    $0x3,%edx
f0101e74:	c1 e2 0c             	shl    $0xc,%edx
f0101e77:	39 d0                	cmp    %edx,%eax
f0101e79:	74 24                	je     f0101e9f <mem_init+0xc53>
f0101e7b:	c7 44 24 0c 40 45 10 	movl   $0xf0104540,0xc(%esp)
f0101e82:	f0 
f0101e83:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101e8a:	f0 
f0101e8b:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101e92:	00 
f0101e93:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101e9a:	e8 f5 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e9f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ea4:	74 24                	je     f0101eca <mem_init+0xc7e>
f0101ea6:	c7 44 24 0c 44 4b 10 	movl   $0xf0104b44,0xc(%esp)
f0101ead:	f0 
f0101eae:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101eb5:	f0 
f0101eb6:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101ebd:	00 
f0101ebe:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101ec5:	e8 ca e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101eca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ed1:	00 
f0101ed2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ed9:	00 
f0101eda:	89 3c 24             	mov    %edi,(%esp)
f0101edd:	e8 91 f0 ff ff       	call   f0100f73 <pgdir_walk>
f0101ee2:	f6 00 04             	testb  $0x4,(%eax)
f0101ee5:	75 24                	jne    f0101f0b <mem_init+0xcbf>
f0101ee7:	c7 44 24 0c f0 45 10 	movl   $0xf01045f0,0xc(%esp)
f0101eee:	f0 
f0101eef:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101ef6:	f0 
f0101ef7:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101efe:	00 
f0101eff:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101f06:	e8 89 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f0b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f10:	f6 00 04             	testb  $0x4,(%eax)
f0101f13:	75 24                	jne    f0101f39 <mem_init+0xced>
f0101f15:	c7 44 24 0c 55 4b 10 	movl   $0xf0104b55,0xc(%esp)
f0101f1c:	f0 
f0101f1d:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101f24:	f0 
f0101f25:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101f2c:	00 
f0101f2d:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101f34:	e8 5b e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f39:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f40:	00 
f0101f41:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f48:	00 
f0101f49:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f4d:	89 04 24             	mov    %eax,(%esp)
f0101f50:	e8 64 f2 ff ff       	call   f01011b9 <page_insert>
f0101f55:	85 c0                	test   %eax,%eax
f0101f57:	78 24                	js     f0101f7d <mem_init+0xd31>
f0101f59:	c7 44 24 0c 24 46 10 	movl   $0xf0104624,0xc(%esp)
f0101f60:	f0 
f0101f61:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101f68:	f0 
f0101f69:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101f70:	00 
f0101f71:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101f78:	e8 17 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f7d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f84:	00 
f0101f85:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f8c:	00 
f0101f8d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f94:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f99:	89 04 24             	mov    %eax,(%esp)
f0101f9c:	e8 18 f2 ff ff       	call   f01011b9 <page_insert>
f0101fa1:	85 c0                	test   %eax,%eax
f0101fa3:	74 24                	je     f0101fc9 <mem_init+0xd7d>
f0101fa5:	c7 44 24 0c 5c 46 10 	movl   $0xf010465c,0xc(%esp)
f0101fac:	f0 
f0101fad:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101fb4:	f0 
f0101fb5:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101fbc:	00 
f0101fbd:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0101fc4:	e8 cb e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fc9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fd0:	00 
f0101fd1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fd8:	00 
f0101fd9:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101fde:	89 04 24             	mov    %eax,(%esp)
f0101fe1:	e8 8d ef ff ff       	call   f0100f73 <pgdir_walk>
f0101fe6:	f6 00 04             	testb  $0x4,(%eax)
f0101fe9:	74 24                	je     f010200f <mem_init+0xdc3>
f0101feb:	c7 44 24 0c 98 46 10 	movl   $0xf0104698,0xc(%esp)
f0101ff2:	f0 
f0101ff3:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0101ffa:	f0 
f0101ffb:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0102002:	00 
f0102003:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010200a:	e8 85 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010200f:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0102015:	ba 00 00 00 00       	mov    $0x0,%edx
f010201a:	89 f8                	mov    %edi,%eax
f010201c:	e8 dc e9 ff ff       	call   f01009fd <check_va2pa>
f0102021:	89 c1                	mov    %eax,%ecx
f0102023:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102026:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102029:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010202f:	c1 f8 03             	sar    $0x3,%eax
f0102032:	c1 e0 0c             	shl    $0xc,%eax
f0102035:	39 c1                	cmp    %eax,%ecx
f0102037:	74 24                	je     f010205d <mem_init+0xe11>
f0102039:	c7 44 24 0c d0 46 10 	movl   $0xf01046d0,0xc(%esp)
f0102040:	f0 
f0102041:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102048:	f0 
f0102049:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102050:	00 
f0102051:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102058:	e8 37 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010205d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102062:	89 f8                	mov    %edi,%eax
f0102064:	e8 94 e9 ff ff       	call   f01009fd <check_va2pa>
f0102069:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010206c:	74 24                	je     f0102092 <mem_init+0xe46>
f010206e:	c7 44 24 0c fc 46 10 	movl   $0xf01046fc,0xc(%esp)
f0102075:	f0 
f0102076:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010207d:	f0 
f010207e:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0102085:	00 
f0102086:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010208d:	e8 02 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102092:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102095:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f010209a:	74 24                	je     f01020c0 <mem_init+0xe74>
f010209c:	c7 44 24 0c 6b 4b 10 	movl   $0xf0104b6b,0xc(%esp)
f01020a3:	f0 
f01020a4:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01020ab:	f0 
f01020ac:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f01020b3:	00 
f01020b4:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01020bb:	e8 d4 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01020c0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020c5:	74 24                	je     f01020eb <mem_init+0xe9f>
f01020c7:	c7 44 24 0c 7c 4b 10 	movl   $0xf0104b7c,0xc(%esp)
f01020ce:	f0 
f01020cf:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01020d6:	f0 
f01020d7:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f01020de:	00 
f01020df:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01020e6:	e8 a9 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020f2:	e8 bf ed ff ff       	call   f0100eb6 <page_alloc>
f01020f7:	85 c0                	test   %eax,%eax
f01020f9:	74 04                	je     f01020ff <mem_init+0xeb3>
f01020fb:	39 c6                	cmp    %eax,%esi
f01020fd:	74 24                	je     f0102123 <mem_init+0xed7>
f01020ff:	c7 44 24 0c 2c 47 10 	movl   $0xf010472c,0xc(%esp)
f0102106:	f0 
f0102107:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010210e:	f0 
f010210f:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0102116:	00 
f0102117:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010211e:	e8 71 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102123:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010212a:	00 
f010212b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102130:	89 04 24             	mov    %eax,(%esp)
f0102133:	e8 43 f0 ff ff       	call   f010117b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102138:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f010213e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102143:	89 f8                	mov    %edi,%eax
f0102145:	e8 b3 e8 ff ff       	call   f01009fd <check_va2pa>
f010214a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010214d:	74 24                	je     f0102173 <mem_init+0xf27>
f010214f:	c7 44 24 0c 50 47 10 	movl   $0xf0104750,0xc(%esp)
f0102156:	f0 
f0102157:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010215e:	f0 
f010215f:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102166:	00 
f0102167:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010216e:	e8 21 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102173:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102178:	89 f8                	mov    %edi,%eax
f010217a:	e8 7e e8 ff ff       	call   f01009fd <check_va2pa>
f010217f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102182:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102188:	c1 fa 03             	sar    $0x3,%edx
f010218b:	c1 e2 0c             	shl    $0xc,%edx
f010218e:	39 d0                	cmp    %edx,%eax
f0102190:	74 24                	je     f01021b6 <mem_init+0xf6a>
f0102192:	c7 44 24 0c fc 46 10 	movl   $0xf01046fc,0xc(%esp)
f0102199:	f0 
f010219a:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01021a1:	f0 
f01021a2:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01021a9:	00 
f01021aa:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01021b1:	e8 de de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021b9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021be:	74 24                	je     f01021e4 <mem_init+0xf98>
f01021c0:	c7 44 24 0c 22 4b 10 	movl   $0xf0104b22,0xc(%esp)
f01021c7:	f0 
f01021c8:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01021cf:	f0 
f01021d0:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f01021d7:	00 
f01021d8:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01021df:	e8 b0 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021e4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021e9:	74 24                	je     f010220f <mem_init+0xfc3>
f01021eb:	c7 44 24 0c 7c 4b 10 	movl   $0xf0104b7c,0xc(%esp)
f01021f2:	f0 
f01021f3:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01021fa:	f0 
f01021fb:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0102202:	00 
f0102203:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010220a:	e8 85 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010220f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102216:	00 
f0102217:	89 3c 24             	mov    %edi,(%esp)
f010221a:	e8 5c ef ff ff       	call   f010117b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010221f:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi
f0102225:	ba 00 00 00 00       	mov    $0x0,%edx
f010222a:	89 f8                	mov    %edi,%eax
f010222c:	e8 cc e7 ff ff       	call   f01009fd <check_va2pa>
f0102231:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102234:	74 24                	je     f010225a <mem_init+0x100e>
f0102236:	c7 44 24 0c 50 47 10 	movl   $0xf0104750,0xc(%esp)
f010223d:	f0 
f010223e:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102245:	f0 
f0102246:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f010224d:	00 
f010224e:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102255:	e8 3a de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010225a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010225f:	89 f8                	mov    %edi,%eax
f0102261:	e8 97 e7 ff ff       	call   f01009fd <check_va2pa>
f0102266:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102269:	74 24                	je     f010228f <mem_init+0x1043>
f010226b:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f0102272:	f0 
f0102273:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010227a:	f0 
f010227b:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102282:	00 
f0102283:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010228a:	e8 05 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010228f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102292:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102297:	74 24                	je     f01022bd <mem_init+0x1071>
f0102299:	c7 44 24 0c 8d 4b 10 	movl   $0xf0104b8d,0xc(%esp)
f01022a0:	f0 
f01022a1:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01022a8:	f0 
f01022a9:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f01022b0:	00 
f01022b1:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01022b8:	e8 d7 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01022bd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022c2:	74 24                	je     f01022e8 <mem_init+0x109c>
f01022c4:	c7 44 24 0c 7c 4b 10 	movl   $0xf0104b7c,0xc(%esp)
f01022cb:	f0 
f01022cc:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01022d3:	f0 
f01022d4:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01022db:	00 
f01022dc:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01022e3:	e8 ac dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01022e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022ef:	e8 c2 eb ff ff       	call   f0100eb6 <page_alloc>
f01022f4:	85 c0                	test   %eax,%eax
f01022f6:	74 05                	je     f01022fd <mem_init+0x10b1>
f01022f8:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01022fb:	74 24                	je     f0102321 <mem_init+0x10d5>
f01022fd:	c7 44 24 0c 9c 47 10 	movl   $0xf010479c,0xc(%esp)
f0102304:	f0 
f0102305:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010230c:	f0 
f010230d:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0102314:	00 
f0102315:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010231c:	e8 73 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102321:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102328:	e8 89 eb ff ff       	call   f0100eb6 <page_alloc>
f010232d:	85 c0                	test   %eax,%eax
f010232f:	74 24                	je     f0102355 <mem_init+0x1109>
f0102331:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f0102338:	f0 
f0102339:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102340:	f0 
f0102341:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102348:	00 
f0102349:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102350:	e8 3f dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102355:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010235a:	8b 08                	mov    (%eax),%ecx
f010235c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102362:	89 da                	mov    %ebx,%edx
f0102364:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f010236a:	c1 fa 03             	sar    $0x3,%edx
f010236d:	c1 e2 0c             	shl    $0xc,%edx
f0102370:	39 d1                	cmp    %edx,%ecx
f0102372:	74 24                	je     f0102398 <mem_init+0x114c>
f0102374:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f010237b:	f0 
f010237c:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102383:	f0 
f0102384:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f010238b:	00 
f010238c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102393:	e8 fc dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102398:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010239e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023a3:	74 24                	je     f01023c9 <mem_init+0x117d>
f01023a5:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f01023ac:	f0 
f01023ad:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01023b4:	f0 
f01023b5:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f01023bc:	00 
f01023bd:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01023c4:	e8 cb dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01023c9:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01023cf:	89 1c 24             	mov    %ebx,(%esp)
f01023d2:	e8 64 eb ff ff       	call   f0100f3b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023d7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023de:	00 
f01023df:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023e6:	00 
f01023e7:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01023ec:	89 04 24             	mov    %eax,(%esp)
f01023ef:	e8 7f eb ff ff       	call   f0100f73 <pgdir_walk>
f01023f4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01023f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023fa:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0102400:	8b 7a 04             	mov    0x4(%edx),%edi
f0102403:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102409:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f010240f:	89 f8                	mov    %edi,%eax
f0102411:	c1 e8 0c             	shr    $0xc,%eax
f0102414:	39 c8                	cmp    %ecx,%eax
f0102416:	72 20                	jb     f0102438 <mem_init+0x11ec>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102418:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010241c:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0102423:	f0 
f0102424:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f010242b:	00 
f010242c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102433:	e8 5c dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102438:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010243e:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102441:	74 24                	je     f0102467 <mem_init+0x121b>
f0102443:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f010244a:	f0 
f010244b:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102452:	f0 
f0102453:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f010245a:	00 
f010245b:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102462:	e8 2d dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102467:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f010246e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102474:	89 d8                	mov    %ebx,%eax
f0102476:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010247c:	c1 f8 03             	sar    $0x3,%eax
f010247f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102482:	89 c2                	mov    %eax,%edx
f0102484:	c1 ea 0c             	shr    $0xc,%edx
f0102487:	39 d1                	cmp    %edx,%ecx
f0102489:	77 20                	ja     f01024ab <mem_init+0x125f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010248b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010248f:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0102496:	f0 
f0102497:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010249e:	00 
f010249f:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f01024a6:	e8 e9 db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01024ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024b2:	00 
f01024b3:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01024ba:	00 
	return (void *)(pa + KERNBASE);
f01024bb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024c0:	89 04 24             	mov    %eax,(%esp)
f01024c3:	e8 c7 13 00 00       	call   f010388f <memset>
	page_free(pp0);
f01024c8:	89 1c 24             	mov    %ebx,(%esp)
f01024cb:	e8 6b ea ff ff       	call   f0100f3b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024d0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024d7:	00 
f01024d8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024df:	00 
f01024e0:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01024e5:	89 04 24             	mov    %eax,(%esp)
f01024e8:	e8 86 ea ff ff       	call   f0100f73 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024ed:	89 da                	mov    %ebx,%edx
f01024ef:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01024f5:	c1 fa 03             	sar    $0x3,%edx
f01024f8:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024fb:	89 d0                	mov    %edx,%eax
f01024fd:	c1 e8 0c             	shr    $0xc,%eax
f0102500:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0102506:	72 20                	jb     f0102528 <mem_init+0x12dc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102508:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010250c:	c7 44 24 08 44 42 10 	movl   $0xf0104244,0x8(%esp)
f0102513:	f0 
f0102514:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010251b:	00 
f010251c:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0102523:	e8 6c db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102528:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010252e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102531:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102538:	75 11                	jne    f010254b <mem_init+0x12ff>
f010253a:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
f0102540:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0102546:	f6 00 01             	testb  $0x1,(%eax)
f0102549:	74 24                	je     f010256f <mem_init+0x1323>
f010254b:	c7 44 24 0c b6 4b 10 	movl   $0xf0104bb6,0xc(%esp)
f0102552:	f0 
f0102553:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010255a:	f0 
f010255b:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102562:	00 
f0102563:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010256a:	e8 25 db ff ff       	call   f0100094 <_panic>
f010256f:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102572:	39 d0                	cmp    %edx,%eax
f0102574:	75 d0                	jne    f0102546 <mem_init+0x12fa>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102576:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010257b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102581:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102587:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010258a:	a3 5c 75 11 f0       	mov    %eax,0xf011755c

	// free the pages we took
	page_free(pp0);
f010258f:	89 1c 24             	mov    %ebx,(%esp)
f0102592:	e8 a4 e9 ff ff       	call   f0100f3b <page_free>
	page_free(pp1);
f0102597:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010259a:	89 04 24             	mov    %eax,(%esp)
f010259d:	e8 99 e9 ff ff       	call   f0100f3b <page_free>
	page_free(pp2);
f01025a2:	89 34 24             	mov    %esi,(%esp)
f01025a5:	e8 91 e9 ff ff       	call   f0100f3b <page_free>

	cprintf("check_page() succeeded!\n");
f01025aa:	c7 04 24 cd 4b 10 f0 	movl   $0xf0104bcd,(%esp)
f01025b1:	e8 3b 07 00 00       	call   f0102cf1 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f01025b6:	a1 88 79 11 f0       	mov    0xf0117988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025c0:	77 20                	ja     f01025e2 <mem_init+0x1396>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025c6:	c7 44 24 08 b0 43 10 	movl   $0xf01043b0,0x8(%esp)
f01025cd:	f0 
f01025ce:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
f01025d5:	00 
f01025d6:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01025dd:	e8 b2 da ff ff       	call   f0100094 <_panic>
f01025e2:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01025e9:	00 
	return (physaddr_t)kva - KERNBASE;
f01025ea:	05 00 00 00 10       	add    $0x10000000,%eax
f01025ef:	89 04 24             	mov    %eax,(%esp)
f01025f2:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025f7:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025fc:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102601:	e8 77 ea ff ff       	call   f010107d <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102606:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f010260b:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102611:	77 20                	ja     f0102633 <mem_init+0x13e7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102613:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102617:	c7 44 24 08 b0 43 10 	movl   $0xf01043b0,0x8(%esp)
f010261e:	f0 
f010261f:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
f0102626:	00 
f0102627:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010262e:	e8 61 da ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102633:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010263a:	00 
f010263b:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102642:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102647:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010264c:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102651:	e8 27 ea ff ff       	call   f010107d <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff+1-KERNBASE,(physaddr_t)0,PTE_W);
f0102656:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010265d:	00 
f010265e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102665:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010266a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010266f:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102674:	e8 04 ea ff ff       	call   f010107d <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102679:	8b 3d 84 79 11 f0    	mov    0xf0117984,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f010267f:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0102684:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102687:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f010268e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102693:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102696:	0f 84 84 00 00 00    	je     f0102720 <mem_init+0x14d4>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010269c:	8b 35 88 79 11 f0    	mov    0xf0117988,%esi
	return (physaddr_t)kva - KERNBASE;
f01026a2:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01026a8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026ab:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026b0:	89 f8                	mov    %edi,%eax
f01026b2:	e8 46 e3 ff ff       	call   f01009fd <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026b7:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01026bd:	77 20                	ja     f01026df <mem_init+0x1493>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026bf:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01026c3:	c7 44 24 08 b0 43 10 	movl   $0xf01043b0,0x8(%esp)
f01026ca:	f0 
f01026cb:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f01026d2:	00 
f01026d3:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01026da:	e8 b5 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026df:	ba 00 00 00 00       	mov    $0x0,%edx
f01026e4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01026e7:	01 d1                	add    %edx,%ecx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026e9:	39 c1                	cmp    %eax,%ecx
f01026eb:	74 24                	je     f0102711 <mem_init+0x14c5>
f01026ed:	c7 44 24 0c c0 47 10 	movl   $0xf01047c0,0xc(%esp)
f01026f4:	f0 
f01026f5:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01026fc:	f0 
f01026fd:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0102704:	00 
f0102705:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010270c:	e8 83 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102711:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f0102717:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f010271a:	0f 87 3a 05 00 00    	ja     f0102c5a <mem_init+0x1a0e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102720:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102723:	c1 e0 0c             	shl    $0xc,%eax
f0102726:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102729:	85 c0                	test   %eax,%eax
f010272b:	0f 84 0a 05 00 00    	je     f0102c3b <mem_init+0x19ef>
f0102731:	be 00 00 00 00       	mov    $0x0,%esi
f0102736:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010273c:	89 f8                	mov    %edi,%eax
f010273e:	e8 ba e2 ff ff       	call   f01009fd <check_va2pa>
f0102743:	39 c6                	cmp    %eax,%esi
f0102745:	74 24                	je     f010276b <mem_init+0x151f>
f0102747:	c7 44 24 0c f4 47 10 	movl   $0xf01047f4,0xc(%esp)
f010274e:	f0 
f010274f:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102756:	f0 
f0102757:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f010275e:	00 
f010275f:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102766:	e8 29 d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010276b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102771:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102774:	72 c0                	jb     f0102736 <mem_init+0x14ea>
f0102776:	e9 c0 04 00 00       	jmp    f0102c3b <mem_init+0x19ef>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010277b:	39 c6                	cmp    %eax,%esi
f010277d:	74 24                	je     f01027a3 <mem_init+0x1557>
f010277f:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f0102786:	f0 
f0102787:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010278e:	f0 
f010278f:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f0102796:	00 
f0102797:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010279e:	e8 f1 d8 ff ff       	call   f0100094 <_panic>
f01027a3:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027a9:	81 fe 00 50 11 00    	cmp    $0x115000,%esi
f01027af:	0f 85 77 04 00 00    	jne    f0102c2c <mem_init+0x19e0>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01027b5:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01027ba:	89 f8                	mov    %edi,%eax
f01027bc:	e8 3c e2 ff ff       	call   f01009fd <check_va2pa>
f01027c1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027c4:	74 24                	je     f01027ea <mem_init+0x159e>
f01027c6:	c7 44 24 0c 64 48 10 	movl   $0xf0104864,0xc(%esp)
f01027cd:	f0 
f01027ce:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f01027dd:	00 
f01027de:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01027e5:	e8 aa d8 ff ff       	call   f0100094 <_panic>
f01027ea:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027ef:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01027f5:	83 fa 02             	cmp    $0x2,%edx
f01027f8:	77 2e                	ja     f0102828 <mem_init+0x15dc>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01027fa:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01027fe:	0f 85 aa 00 00 00    	jne    f01028ae <mem_init+0x1662>
f0102804:	c7 44 24 0c e6 4b 10 	movl   $0xf0104be6,0xc(%esp)
f010280b:	f0 
f010280c:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102813:	f0 
f0102814:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f010281b:	00 
f010281c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102823:	e8 6c d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102828:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010282d:	76 55                	jbe    f0102884 <mem_init+0x1638>
				assert(pgdir[i] & PTE_P);
f010282f:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102832:	f6 c2 01             	test   $0x1,%dl
f0102835:	75 24                	jne    f010285b <mem_init+0x160f>
f0102837:	c7 44 24 0c e6 4b 10 	movl   $0xf0104be6,0xc(%esp)
f010283e:	f0 
f010283f:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102846:	f0 
f0102847:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f010284e:	00 
f010284f:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102856:	e8 39 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f010285b:	f6 c2 02             	test   $0x2,%dl
f010285e:	75 4e                	jne    f01028ae <mem_init+0x1662>
f0102860:	c7 44 24 0c f7 4b 10 	movl   $0xf0104bf7,0xc(%esp)
f0102867:	f0 
f0102868:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010286f:	f0 
f0102870:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0102877:	00 
f0102878:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010287f:	e8 10 d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102884:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102888:	74 24                	je     f01028ae <mem_init+0x1662>
f010288a:	c7 44 24 0c 08 4c 10 	movl   $0xf0104c08,0xc(%esp)
f0102891:	f0 
f0102892:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102899:	f0 
f010289a:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f01028a1:	00 
f01028a2:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01028a9:	e8 e6 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028ae:	83 c0 01             	add    $0x1,%eax
f01028b1:	3d 00 04 00 00       	cmp    $0x400,%eax
f01028b6:	0f 85 33 ff ff ff    	jne    f01027ef <mem_init+0x15a3>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028bc:	c7 04 24 94 48 10 f0 	movl   $0xf0104894,(%esp)
f01028c3:	e8 29 04 00 00       	call   f0102cf1 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028c8:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028cd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028d2:	77 20                	ja     f01028f4 <mem_init+0x16a8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028d8:	c7 44 24 08 b0 43 10 	movl   $0xf01043b0,0x8(%esp)
f01028df:	f0 
f01028e0:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
f01028e7:	00 
f01028e8:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01028ef:	e8 a0 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028f4:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01028f9:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102901:	e8 66 e1 ff ff       	call   f0100a6c <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102906:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102909:	83 e0 f3             	and    $0xfffffff3,%eax
f010290c:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102911:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102914:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010291b:	e8 96 e5 ff ff       	call   f0100eb6 <page_alloc>
f0102920:	89 c3                	mov    %eax,%ebx
f0102922:	85 c0                	test   %eax,%eax
f0102924:	75 24                	jne    f010294a <mem_init+0x16fe>
f0102926:	c7 44 24 0c 25 4a 10 	movl   $0xf0104a25,0xc(%esp)
f010292d:	f0 
f010292e:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102935:	f0 
f0102936:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f010293d:	00 
f010293e:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102945:	e8 4a d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010294a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102951:	e8 60 e5 ff ff       	call   f0100eb6 <page_alloc>
f0102956:	89 c7                	mov    %eax,%edi
f0102958:	85 c0                	test   %eax,%eax
f010295a:	75 24                	jne    f0102980 <mem_init+0x1734>
f010295c:	c7 44 24 0c 3b 4a 10 	movl   $0xf0104a3b,0xc(%esp)
f0102963:	f0 
f0102964:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f010296b:	f0 
f010296c:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102973:	00 
f0102974:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f010297b:	e8 14 d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102980:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102987:	e8 2a e5 ff ff       	call   f0100eb6 <page_alloc>
f010298c:	89 c6                	mov    %eax,%esi
f010298e:	85 c0                	test   %eax,%eax
f0102990:	75 24                	jne    f01029b6 <mem_init+0x176a>
f0102992:	c7 44 24 0c 51 4a 10 	movl   $0xf0104a51,0xc(%esp)
f0102999:	f0 
f010299a:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f01029a1:	f0 
f01029a2:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f01029a9:	00 
f01029aa:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f01029b1:	e8 de d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01029b6:	89 1c 24             	mov    %ebx,(%esp)
f01029b9:	e8 7d e5 ff ff       	call   f0100f3b <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01029be:	89 f8                	mov    %edi,%eax
f01029c0:	e8 f3 df ff ff       	call   f01009b8 <page2kva>
f01029c5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029cc:	00 
f01029cd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01029d4:	00 
f01029d5:	89 04 24             	mov    %eax,(%esp)
f01029d8:	e8 b2 0e 00 00       	call   f010388f <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01029dd:	89 f0                	mov    %esi,%eax
f01029df:	e8 d4 df ff ff       	call   f01009b8 <page2kva>
f01029e4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029eb:	00 
f01029ec:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029f3:	00 
f01029f4:	89 04 24             	mov    %eax,(%esp)
f01029f7:	e8 93 0e 00 00       	call   f010388f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01029fc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a03:	00 
f0102a04:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a0b:	00 
f0102a0c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a10:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102a15:	89 04 24             	mov    %eax,(%esp)
f0102a18:	e8 9c e7 ff ff       	call   f01011b9 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a1d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a22:	74 24                	je     f0102a48 <mem_init+0x17fc>
f0102a24:	c7 44 24 0c 22 4b 10 	movl   $0xf0104b22,0xc(%esp)
f0102a2b:	f0 
f0102a2c:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102a33:	f0 
f0102a34:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102a3b:	00 
f0102a3c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102a43:	e8 4c d6 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a48:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a4f:	01 01 01 
f0102a52:	74 24                	je     f0102a78 <mem_init+0x182c>
f0102a54:	c7 44 24 0c b4 48 10 	movl   $0xf01048b4,0xc(%esp)
f0102a5b:	f0 
f0102a5c:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102a63:	f0 
f0102a64:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0102a6b:	00 
f0102a6c:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102a73:	e8 1c d6 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a78:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a7f:	00 
f0102a80:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a87:	00 
f0102a88:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102a8c:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102a91:	89 04 24             	mov    %eax,(%esp)
f0102a94:	e8 20 e7 ff ff       	call   f01011b9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a99:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102aa0:	02 02 02 
f0102aa3:	74 24                	je     f0102ac9 <mem_init+0x187d>
f0102aa5:	c7 44 24 0c d8 48 10 	movl   $0xf01048d8,0xc(%esp)
f0102aac:	f0 
f0102aad:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102ab4:	f0 
f0102ab5:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102abc:	00 
f0102abd:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102ac4:	e8 cb d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102ac9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ace:	74 24                	je     f0102af4 <mem_init+0x18a8>
f0102ad0:	c7 44 24 0c 44 4b 10 	movl   $0xf0104b44,0xc(%esp)
f0102ad7:	f0 
f0102ad8:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102adf:	f0 
f0102ae0:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102ae7:	00 
f0102ae8:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102aef:	e8 a0 d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102af4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102af9:	74 24                	je     f0102b1f <mem_init+0x18d3>
f0102afb:	c7 44 24 0c 8d 4b 10 	movl   $0xf0104b8d,0xc(%esp)
f0102b02:	f0 
f0102b03:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102b0a:	f0 
f0102b0b:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0102b12:	00 
f0102b13:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102b1a:	e8 75 d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b1f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b26:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b29:	89 f0                	mov    %esi,%eax
f0102b2b:	e8 88 de ff ff       	call   f01009b8 <page2kva>
f0102b30:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102b36:	74 24                	je     f0102b5c <mem_init+0x1910>
f0102b38:	c7 44 24 0c fc 48 10 	movl   $0xf01048fc,0xc(%esp)
f0102b3f:	f0 
f0102b40:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102b47:	f0 
f0102b48:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102b4f:	00 
f0102b50:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102b57:	e8 38 d5 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b5c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b63:	00 
f0102b64:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102b69:	89 04 24             	mov    %eax,(%esp)
f0102b6c:	e8 0a e6 ff ff       	call   f010117b <page_remove>
	assert(pp2->pp_ref == 0);
f0102b71:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102b76:	74 24                	je     f0102b9c <mem_init+0x1950>
f0102b78:	c7 44 24 0c 7c 4b 10 	movl   $0xf0104b7c,0xc(%esp)
f0102b7f:	f0 
f0102b80:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102b87:	f0 
f0102b88:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102b8f:	00 
f0102b90:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102b97:	e8 f8 d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b9c:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102ba1:	8b 08                	mov    (%eax),%ecx
f0102ba3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ba9:	89 da                	mov    %ebx,%edx
f0102bab:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102bb1:	c1 fa 03             	sar    $0x3,%edx
f0102bb4:	c1 e2 0c             	shl    $0xc,%edx
f0102bb7:	39 d1                	cmp    %edx,%ecx
f0102bb9:	74 24                	je     f0102bdf <mem_init+0x1993>
f0102bbb:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f0102bc2:	f0 
f0102bc3:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102bca:	f0 
f0102bcb:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102bd2:	00 
f0102bd3:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102bda:	e8 b5 d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102bdf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102be5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102bea:	74 24                	je     f0102c10 <mem_init+0x19c4>
f0102bec:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f0102bf3:	f0 
f0102bf4:	c7 44 24 08 7a 49 10 	movl   $0xf010497a,0x8(%esp)
f0102bfb:	f0 
f0102bfc:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0102c03:	00 
f0102c04:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0102c0b:	e8 84 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102c10:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c16:	89 1c 24             	mov    %ebx,(%esp)
f0102c19:	e8 1d e3 ff ff       	call   f0100f3b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c1e:	c7 04 24 28 49 10 f0 	movl   $0xf0104928,(%esp)
f0102c25:	e8 c7 00 00 00       	call   f0102cf1 <cprintf>
f0102c2a:	eb 42                	jmp    f0102c6e <mem_init+0x1a22>
f0102c2c:	8d 14 33             	lea    (%ebx,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c2f:	89 f8                	mov    %edi,%eax
f0102c31:	e8 c7 dd ff ff       	call   f01009fd <check_va2pa>
f0102c36:	e9 40 fb ff ff       	jmp    f010277b <mem_init+0x152f>
f0102c3b:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102c40:	89 f8                	mov    %edi,%eax
f0102c42:	e8 b6 dd ff ff       	call   f01009fd <check_va2pa>
f0102c47:	be 00 d0 10 00       	mov    $0x10d000,%esi
f0102c4c:	ba 00 80 bf df       	mov    $0xdfbf8000,%edx
f0102c51:	29 da                	sub    %ebx,%edx
f0102c53:	89 d3                	mov    %edx,%ebx
f0102c55:	e9 21 fb ff ff       	jmp    f010277b <mem_init+0x152f>
f0102c5a:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102c60:	89 f8                	mov    %edi,%eax
f0102c62:	e8 96 dd ff ff       	call   f01009fd <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102c67:	89 f2                	mov    %esi,%edx
f0102c69:	e9 76 fa ff ff       	jmp    f01026e4 <mem_init+0x1498>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c6e:	83 c4 3c             	add    $0x3c,%esp
f0102c71:	5b                   	pop    %ebx
f0102c72:	5e                   	pop    %esi
f0102c73:	5f                   	pop    %edi
f0102c74:	5d                   	pop    %ebp
f0102c75:	c3                   	ret    

f0102c76 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102c76:	55                   	push   %ebp
f0102c77:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102c79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c7c:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102c7f:	5d                   	pop    %ebp
f0102c80:	c3                   	ret    

f0102c81 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102c81:	55                   	push   %ebp
f0102c82:	89 e5                	mov    %esp,%ebp
f0102c84:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c88:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c8d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102c8e:	b2 71                	mov    $0x71,%dl
f0102c90:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102c91:	0f b6 c0             	movzbl %al,%eax
}
f0102c94:	5d                   	pop    %ebp
f0102c95:	c3                   	ret    

f0102c96 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102c96:	55                   	push   %ebp
f0102c97:	89 e5                	mov    %esp,%ebp
f0102c99:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c9d:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ca2:	ee                   	out    %al,(%dx)
f0102ca3:	b2 71                	mov    $0x71,%dl
f0102ca5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ca8:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ca9:	5d                   	pop    %ebp
f0102caa:	c3                   	ret    

f0102cab <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102cab:	55                   	push   %ebp
f0102cac:	89 e5                	mov    %esp,%ebp
f0102cae:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102cb1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cb4:	89 04 24             	mov    %eax,(%esp)
f0102cb7:	e8 4c d9 ff ff       	call   f0100608 <cputchar>
	*cnt++;
}
f0102cbc:	c9                   	leave  
f0102cbd:	c3                   	ret    

f0102cbe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102cbe:	55                   	push   %ebp
f0102cbf:	89 e5                	mov    %esp,%ebp
f0102cc1:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102cc4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ccb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cce:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102cd2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cd5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102cd9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102cdc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ce0:	c7 04 24 ab 2c 10 f0 	movl   $0xf0102cab,(%esp)
f0102ce7:	e8 88 04 00 00       	call   f0103174 <vprintfmt>
	return cnt;
}
f0102cec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102cef:	c9                   	leave  
f0102cf0:	c3                   	ret    

f0102cf1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102cf1:	55                   	push   %ebp
f0102cf2:	89 e5                	mov    %esp,%ebp
f0102cf4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102cf7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102cfa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d01:	89 04 24             	mov    %eax,(%esp)
f0102d04:	e8 b5 ff ff ff       	call   f0102cbe <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d09:	c9                   	leave  
f0102d0a:	c3                   	ret    
f0102d0b:	66 90                	xchg   %ax,%ax
f0102d0d:	66 90                	xchg   %ax,%ax
f0102d0f:	90                   	nop

f0102d10 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d10:	55                   	push   %ebp
f0102d11:	89 e5                	mov    %esp,%ebp
f0102d13:	57                   	push   %edi
f0102d14:	56                   	push   %esi
f0102d15:	53                   	push   %ebx
f0102d16:	83 ec 10             	sub    $0x10,%esp
f0102d19:	89 c6                	mov    %eax,%esi
f0102d1b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d1e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d21:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d24:	8b 1a                	mov    (%edx),%ebx
f0102d26:	8b 01                	mov    (%ecx),%eax
f0102d28:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d2b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102d32:	eb 77                	jmp    f0102dab <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102d34:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d37:	01 d8                	add    %ebx,%eax
f0102d39:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102d3e:	99                   	cltd   
f0102d3f:	f7 f9                	idiv   %ecx
f0102d41:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d43:	eb 01                	jmp    f0102d46 <stab_binsearch+0x36>
			m--;
f0102d45:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d46:	39 d9                	cmp    %ebx,%ecx
f0102d48:	7c 1d                	jl     f0102d67 <stab_binsearch+0x57>
f0102d4a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102d4d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102d52:	39 fa                	cmp    %edi,%edx
f0102d54:	75 ef                	jne    f0102d45 <stab_binsearch+0x35>
f0102d56:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102d59:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102d5c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102d60:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102d63:	73 18                	jae    f0102d7d <stab_binsearch+0x6d>
f0102d65:	eb 05                	jmp    f0102d6c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102d67:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102d6a:	eb 3f                	jmp    f0102dab <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102d6c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102d6f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102d71:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d74:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102d7b:	eb 2e                	jmp    f0102dab <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102d7d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102d80:	73 15                	jae    f0102d97 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102d82:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102d85:	48                   	dec    %eax
f0102d86:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d89:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102d8c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d8e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102d95:	eb 14                	jmp    f0102dab <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102d97:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102d9a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102d9d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102d9f:	ff 45 0c             	incl   0xc(%ebp)
f0102da2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102da4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102dab:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102dae:	7e 84                	jle    f0102d34 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102db0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102db4:	75 0d                	jne    f0102dc3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102db6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102db9:	8b 00                	mov    (%eax),%eax
f0102dbb:	48                   	dec    %eax
f0102dbc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dbf:	89 07                	mov    %eax,(%edi)
f0102dc1:	eb 22                	jmp    f0102de5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dc3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dc6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102dc8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102dcb:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dcd:	eb 01                	jmp    f0102dd0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102dcf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dd0:	39 c1                	cmp    %eax,%ecx
f0102dd2:	7d 0c                	jge    f0102de0 <stab_binsearch+0xd0>
f0102dd4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102dd7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102ddc:	39 fa                	cmp    %edi,%edx
f0102dde:	75 ef                	jne    f0102dcf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102de0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102de3:	89 07                	mov    %eax,(%edi)
	}
}
f0102de5:	83 c4 10             	add    $0x10,%esp
f0102de8:	5b                   	pop    %ebx
f0102de9:	5e                   	pop    %esi
f0102dea:	5f                   	pop    %edi
f0102deb:	5d                   	pop    %ebp
f0102dec:	c3                   	ret    

f0102ded <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102ded:	55                   	push   %ebp
f0102dee:	89 e5                	mov    %esp,%ebp
f0102df0:	57                   	push   %edi
f0102df1:	56                   	push   %esi
f0102df2:	53                   	push   %ebx
f0102df3:	83 ec 2c             	sub    $0x2c,%esp
f0102df6:	8b 75 08             	mov    0x8(%ebp),%esi
f0102df9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102dfc:	c7 03 16 4c 10 f0    	movl   $0xf0104c16,(%ebx)
	info->eip_line = 0;
f0102e02:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e09:	c7 43 08 16 4c 10 f0 	movl   $0xf0104c16,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e10:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e17:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e1a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e21:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e27:	76 12                	jbe    f0102e3b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e29:	b8 ae c8 10 f0       	mov    $0xf010c8ae,%eax
f0102e2e:	3d 4d ab 10 f0       	cmp    $0xf010ab4d,%eax
f0102e33:	0f 86 8b 01 00 00    	jbe    f0102fc4 <debuginfo_eip+0x1d7>
f0102e39:	eb 1c                	jmp    f0102e57 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e3b:	c7 44 24 08 20 4c 10 	movl   $0xf0104c20,0x8(%esp)
f0102e42:	f0 
f0102e43:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102e4a:	00 
f0102e4b:	c7 04 24 2d 4c 10 f0 	movl   $0xf0104c2d,(%esp)
f0102e52:	e8 3d d2 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e57:	80 3d ad c8 10 f0 00 	cmpb   $0x0,0xf010c8ad
f0102e5e:	0f 85 67 01 00 00    	jne    f0102fcb <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102e64:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102e6b:	b8 4c ab 10 f0       	mov    $0xf010ab4c,%eax
f0102e70:	2d 4c 4e 10 f0       	sub    $0xf0104e4c,%eax
f0102e75:	c1 f8 02             	sar    $0x2,%eax
f0102e78:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102e7e:	83 e8 01             	sub    $0x1,%eax
f0102e81:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102e84:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e88:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102e8f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102e92:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102e95:	b8 4c 4e 10 f0       	mov    $0xf0104e4c,%eax
f0102e9a:	e8 71 fe ff ff       	call   f0102d10 <stab_binsearch>
	if (lfile == 0)
f0102e9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ea2:	85 c0                	test   %eax,%eax
f0102ea4:	0f 84 28 01 00 00    	je     f0102fd2 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102eaa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102ead:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102eb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102eb3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102eb7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102ebe:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102ec1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102ec4:	b8 4c 4e 10 f0       	mov    $0xf0104e4c,%eax
f0102ec9:	e8 42 fe ff ff       	call   f0102d10 <stab_binsearch>

	if (lfun <= rfun) {
f0102ece:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102ed1:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102ed4:	7f 2e                	jg     f0102f04 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102ed6:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102ed9:	8d 90 4c 4e 10 f0    	lea    -0xfefb1b4(%eax),%edx
f0102edf:	8b 80 4c 4e 10 f0    	mov    -0xfefb1b4(%eax),%eax
f0102ee5:	b9 ae c8 10 f0       	mov    $0xf010c8ae,%ecx
f0102eea:	81 e9 4d ab 10 f0    	sub    $0xf010ab4d,%ecx
f0102ef0:	39 c8                	cmp    %ecx,%eax
f0102ef2:	73 08                	jae    f0102efc <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102ef4:	05 4d ab 10 f0       	add    $0xf010ab4d,%eax
f0102ef9:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102efc:	8b 42 08             	mov    0x8(%edx),%eax
f0102eff:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f02:	eb 06                	jmp    f0102f0a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f04:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f0a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f11:	00 
f0102f12:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f15:	89 04 24             	mov    %eax,(%esp)
f0102f18:	e8 47 09 00 00       	call   f0103864 <strfind>
f0102f1d:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f20:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f23:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102f26:	39 cf                	cmp    %ecx,%edi
f0102f28:	7c 5c                	jl     f0102f86 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0102f2a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f2d:	8d b0 4c 4e 10 f0    	lea    -0xfefb1b4(%eax),%esi
f0102f33:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0102f37:	80 fa 84             	cmp    $0x84,%dl
f0102f3a:	74 2b                	je     f0102f67 <debuginfo_eip+0x17a>
f0102f3c:	05 40 4e 10 f0       	add    $0xf0104e40,%eax
f0102f41:	eb 15                	jmp    f0102f58 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102f43:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f46:	39 cf                	cmp    %ecx,%edi
f0102f48:	7c 3c                	jl     f0102f86 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0102f4a:	89 c6                	mov    %eax,%esi
f0102f4c:	83 e8 0c             	sub    $0xc,%eax
f0102f4f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0102f53:	80 fa 84             	cmp    $0x84,%dl
f0102f56:	74 0f                	je     f0102f67 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102f58:	80 fa 64             	cmp    $0x64,%dl
f0102f5b:	75 e6                	jne    f0102f43 <debuginfo_eip+0x156>
f0102f5d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0102f61:	74 e0                	je     f0102f43 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102f63:	39 f9                	cmp    %edi,%ecx
f0102f65:	7f 1f                	jg     f0102f86 <debuginfo_eip+0x199>
f0102f67:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102f6a:	8b 87 4c 4e 10 f0    	mov    -0xfefb1b4(%edi),%eax
f0102f70:	ba ae c8 10 f0       	mov    $0xf010c8ae,%edx
f0102f75:	81 ea 4d ab 10 f0    	sub    $0xf010ab4d,%edx
f0102f7b:	39 d0                	cmp    %edx,%eax
f0102f7d:	73 07                	jae    f0102f86 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102f7f:	05 4d ab 10 f0       	add    $0xf010ab4d,%eax
f0102f84:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102f86:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f89:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102f8c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102f91:	39 ca                	cmp    %ecx,%edx
f0102f93:	7d 5e                	jge    f0102ff3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0102f95:	8d 42 01             	lea    0x1(%edx),%eax
f0102f98:	39 c1                	cmp    %eax,%ecx
f0102f9a:	7e 3d                	jle    f0102fd9 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102f9c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0102f9f:	80 ba 50 4e 10 f0 a0 	cmpb   $0xa0,-0xfefb1b0(%edx)
f0102fa6:	75 38                	jne    f0102fe0 <debuginfo_eip+0x1f3>
f0102fa8:	81 c2 40 4e 10 f0    	add    $0xf0104e40,%edx
		     lline++)
			info->eip_fn_narg++;
f0102fae:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102fb2:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102fb5:	39 c1                	cmp    %eax,%ecx
f0102fb7:	7e 2e                	jle    f0102fe7 <debuginfo_eip+0x1fa>
f0102fb9:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102fbc:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0102fc0:	74 ec                	je     f0102fae <debuginfo_eip+0x1c1>
f0102fc2:	eb 2a                	jmp    f0102fee <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102fc4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fc9:	eb 28                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fcb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fd0:	eb 21                	jmp    f0102ff3 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102fd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fd7:	eb 1a                	jmp    f0102ff3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102fd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fde:	eb 13                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fe0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fe5:	eb 0c                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fe7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fec:	eb 05                	jmp    f0102ff3 <debuginfo_eip+0x206>
f0102fee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ff3:	83 c4 2c             	add    $0x2c,%esp
f0102ff6:	5b                   	pop    %ebx
f0102ff7:	5e                   	pop    %esi
f0102ff8:	5f                   	pop    %edi
f0102ff9:	5d                   	pop    %ebp
f0102ffa:	c3                   	ret    
f0102ffb:	66 90                	xchg   %ax,%ax
f0102ffd:	66 90                	xchg   %ax,%ax
f0102fff:	90                   	nop

f0103000 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103000:	55                   	push   %ebp
f0103001:	89 e5                	mov    %esp,%ebp
f0103003:	57                   	push   %edi
f0103004:	56                   	push   %esi
f0103005:	53                   	push   %ebx
f0103006:	83 ec 3c             	sub    $0x3c,%esp
f0103009:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010300c:	89 d7                	mov    %edx,%edi
f010300e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103011:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103014:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103017:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010301a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010301d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103022:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103025:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103028:	39 f1                	cmp    %esi,%ecx
f010302a:	72 14                	jb     f0103040 <printnum+0x40>
f010302c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f010302f:	76 0f                	jbe    f0103040 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103031:	8b 45 14             	mov    0x14(%ebp),%eax
f0103034:	8d 70 ff             	lea    -0x1(%eax),%esi
f0103037:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010303a:	85 f6                	test   %esi,%esi
f010303c:	7f 60                	jg     f010309e <printnum+0x9e>
f010303e:	eb 72                	jmp    f01030b2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103040:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103043:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103047:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010304a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f010304d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103051:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103055:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103059:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010305d:	89 c3                	mov    %eax,%ebx
f010305f:	89 d6                	mov    %edx,%esi
f0103061:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103064:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103067:	89 54 24 08          	mov    %edx,0x8(%esp)
f010306b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010306f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103072:	89 04 24             	mov    %eax,(%esp)
f0103075:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103078:	89 44 24 04          	mov    %eax,0x4(%esp)
f010307c:	e8 4f 0a 00 00       	call   f0103ad0 <__udivdi3>
f0103081:	89 d9                	mov    %ebx,%ecx
f0103083:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103087:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010308b:	89 04 24             	mov    %eax,(%esp)
f010308e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103092:	89 fa                	mov    %edi,%edx
f0103094:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103097:	e8 64 ff ff ff       	call   f0103000 <printnum>
f010309c:	eb 14                	jmp    f01030b2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010309e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030a2:	8b 45 18             	mov    0x18(%ebp),%eax
f01030a5:	89 04 24             	mov    %eax,(%esp)
f01030a8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030aa:	83 ee 01             	sub    $0x1,%esi
f01030ad:	75 ef                	jne    f010309e <printnum+0x9e>
f01030af:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01030b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030b6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01030bd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030c4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01030c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030cb:	89 04 24             	mov    %eax,(%esp)
f01030ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030d5:	e8 26 0b 00 00       	call   f0103c00 <__umoddi3>
f01030da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030de:	0f be 80 3b 4c 10 f0 	movsbl -0xfefb3c5(%eax),%eax
f01030e5:	89 04 24             	mov    %eax,(%esp)
f01030e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030eb:	ff d0                	call   *%eax
}
f01030ed:	83 c4 3c             	add    $0x3c,%esp
f01030f0:	5b                   	pop    %ebx
f01030f1:	5e                   	pop    %esi
f01030f2:	5f                   	pop    %edi
f01030f3:	5d                   	pop    %ebp
f01030f4:	c3                   	ret    

f01030f5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01030f5:	55                   	push   %ebp
f01030f6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01030f8:	83 fa 01             	cmp    $0x1,%edx
f01030fb:	7e 0e                	jle    f010310b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01030fd:	8b 10                	mov    (%eax),%edx
f01030ff:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103102:	89 08                	mov    %ecx,(%eax)
f0103104:	8b 02                	mov    (%edx),%eax
f0103106:	8b 52 04             	mov    0x4(%edx),%edx
f0103109:	eb 22                	jmp    f010312d <getuint+0x38>
	else if (lflag)
f010310b:	85 d2                	test   %edx,%edx
f010310d:	74 10                	je     f010311f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010310f:	8b 10                	mov    (%eax),%edx
f0103111:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103114:	89 08                	mov    %ecx,(%eax)
f0103116:	8b 02                	mov    (%edx),%eax
f0103118:	ba 00 00 00 00       	mov    $0x0,%edx
f010311d:	eb 0e                	jmp    f010312d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010311f:	8b 10                	mov    (%eax),%edx
f0103121:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103124:	89 08                	mov    %ecx,(%eax)
f0103126:	8b 02                	mov    (%edx),%eax
f0103128:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010312d:	5d                   	pop    %ebp
f010312e:	c3                   	ret    

f010312f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010312f:	55                   	push   %ebp
f0103130:	89 e5                	mov    %esp,%ebp
f0103132:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103135:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103139:	8b 10                	mov    (%eax),%edx
f010313b:	3b 50 04             	cmp    0x4(%eax),%edx
f010313e:	73 0a                	jae    f010314a <sprintputch+0x1b>
		*b->buf++ = ch;
f0103140:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103143:	89 08                	mov    %ecx,(%eax)
f0103145:	8b 45 08             	mov    0x8(%ebp),%eax
f0103148:	88 02                	mov    %al,(%edx)
}
f010314a:	5d                   	pop    %ebp
f010314b:	c3                   	ret    

f010314c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010314c:	55                   	push   %ebp
f010314d:	89 e5                	mov    %esp,%ebp
f010314f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103152:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103155:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103159:	8b 45 10             	mov    0x10(%ebp),%eax
f010315c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103160:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103163:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103167:	8b 45 08             	mov    0x8(%ebp),%eax
f010316a:	89 04 24             	mov    %eax,(%esp)
f010316d:	e8 02 00 00 00       	call   f0103174 <vprintfmt>
	va_end(ap);
}
f0103172:	c9                   	leave  
f0103173:	c3                   	ret    

f0103174 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103174:	55                   	push   %ebp
f0103175:	89 e5                	mov    %esp,%ebp
f0103177:	57                   	push   %edi
f0103178:	56                   	push   %esi
f0103179:	53                   	push   %ebx
f010317a:	83 ec 3c             	sub    $0x3c,%esp
f010317d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103180:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103183:	eb 18                	jmp    f010319d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103185:	85 c0                	test   %eax,%eax
f0103187:	0f 84 c3 03 00 00    	je     f0103550 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
f010318d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103191:	89 04 24             	mov    %eax,(%esp)
f0103194:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103197:	89 f3                	mov    %esi,%ebx
f0103199:	eb 02                	jmp    f010319d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f010319b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010319d:	8d 73 01             	lea    0x1(%ebx),%esi
f01031a0:	0f b6 03             	movzbl (%ebx),%eax
f01031a3:	83 f8 25             	cmp    $0x25,%eax
f01031a6:	75 dd                	jne    f0103185 <vprintfmt+0x11>
f01031a8:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f01031ac:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01031b3:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01031ba:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01031c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01031c6:	eb 1d                	jmp    f01031e5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031c8:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01031ca:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f01031ce:	eb 15                	jmp    f01031e5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031d0:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01031d2:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f01031d6:	eb 0d                	jmp    f01031e5 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01031d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031db:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01031de:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031e5:	8d 5e 01             	lea    0x1(%esi),%ebx
f01031e8:	0f b6 06             	movzbl (%esi),%eax
f01031eb:	0f b6 c8             	movzbl %al,%ecx
f01031ee:	83 e8 23             	sub    $0x23,%eax
f01031f1:	3c 55                	cmp    $0x55,%al
f01031f3:	0f 87 2f 03 00 00    	ja     f0103528 <vprintfmt+0x3b4>
f01031f9:	0f b6 c0             	movzbl %al,%eax
f01031fc:	ff 24 85 c8 4c 10 f0 	jmp    *-0xfefb338(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103203:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0103206:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0103209:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010320d:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0103210:	83 f9 09             	cmp    $0x9,%ecx
f0103213:	77 50                	ja     f0103265 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103215:	89 de                	mov    %ebx,%esi
f0103217:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010321a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f010321d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103220:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103224:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103227:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010322a:	83 fb 09             	cmp    $0x9,%ebx
f010322d:	76 eb                	jbe    f010321a <vprintfmt+0xa6>
f010322f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103232:	eb 33                	jmp    f0103267 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103234:	8b 45 14             	mov    0x14(%ebp),%eax
f0103237:	8d 48 04             	lea    0x4(%eax),%ecx
f010323a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010323d:	8b 00                	mov    (%eax),%eax
f010323f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103242:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103244:	eb 21                	jmp    f0103267 <vprintfmt+0xf3>
f0103246:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103249:	85 c9                	test   %ecx,%ecx
f010324b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103250:	0f 49 c1             	cmovns %ecx,%eax
f0103253:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103256:	89 de                	mov    %ebx,%esi
f0103258:	eb 8b                	jmp    f01031e5 <vprintfmt+0x71>
f010325a:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010325c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103263:	eb 80                	jmp    f01031e5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103265:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0103267:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010326b:	0f 89 74 ff ff ff    	jns    f01031e5 <vprintfmt+0x71>
f0103271:	e9 62 ff ff ff       	jmp    f01031d8 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103276:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103279:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010327b:	e9 65 ff ff ff       	jmp    f01031e5 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103280:	8b 45 14             	mov    0x14(%ebp),%eax
f0103283:	8d 50 04             	lea    0x4(%eax),%edx
f0103286:	89 55 14             	mov    %edx,0x14(%ebp)
f0103289:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010328d:	8b 00                	mov    (%eax),%eax
f010328f:	89 04 24             	mov    %eax,(%esp)
f0103292:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103295:	e9 03 ff ff ff       	jmp    f010319d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010329a:	8b 45 14             	mov    0x14(%ebp),%eax
f010329d:	8d 50 04             	lea    0x4(%eax),%edx
f01032a0:	89 55 14             	mov    %edx,0x14(%ebp)
f01032a3:	8b 00                	mov    (%eax),%eax
f01032a5:	99                   	cltd   
f01032a6:	31 d0                	xor    %edx,%eax
f01032a8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01032aa:	83 f8 06             	cmp    $0x6,%eax
f01032ad:	7f 0b                	jg     f01032ba <vprintfmt+0x146>
f01032af:	8b 14 85 20 4e 10 f0 	mov    -0xfefb1e0(,%eax,4),%edx
f01032b6:	85 d2                	test   %edx,%edx
f01032b8:	75 20                	jne    f01032da <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f01032ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032be:	c7 44 24 08 53 4c 10 	movl   $0xf0104c53,0x8(%esp)
f01032c5:	f0 
f01032c6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01032cd:	89 04 24             	mov    %eax,(%esp)
f01032d0:	e8 77 fe ff ff       	call   f010314c <printfmt>
f01032d5:	e9 c3 fe ff ff       	jmp    f010319d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
f01032da:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01032de:	c7 44 24 08 8c 49 10 	movl   $0xf010498c,0x8(%esp)
f01032e5:	f0 
f01032e6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01032ed:	89 04 24             	mov    %eax,(%esp)
f01032f0:	e8 57 fe ff ff       	call   f010314c <printfmt>
f01032f5:	e9 a3 fe ff ff       	jmp    f010319d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032fa:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01032fd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103300:	8b 45 14             	mov    0x14(%ebp),%eax
f0103303:	8d 50 04             	lea    0x4(%eax),%edx
f0103306:	89 55 14             	mov    %edx,0x14(%ebp)
f0103309:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010330b:	85 c0                	test   %eax,%eax
f010330d:	ba 4c 4c 10 f0       	mov    $0xf0104c4c,%edx
f0103312:	0f 45 d0             	cmovne %eax,%edx
f0103315:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0103318:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010331c:	74 04                	je     f0103322 <vprintfmt+0x1ae>
f010331e:	85 f6                	test   %esi,%esi
f0103320:	7f 19                	jg     f010333b <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103322:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103325:	8d 70 01             	lea    0x1(%eax),%esi
f0103328:	0f b6 10             	movzbl (%eax),%edx
f010332b:	0f be c2             	movsbl %dl,%eax
f010332e:	85 c0                	test   %eax,%eax
f0103330:	0f 85 95 00 00 00    	jne    f01033cb <vprintfmt+0x257>
f0103336:	e9 85 00 00 00       	jmp    f01033c0 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010333b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010333f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103342:	89 04 24             	mov    %eax,(%esp)
f0103345:	e8 88 03 00 00       	call   f01036d2 <strnlen>
f010334a:	29 c6                	sub    %eax,%esi
f010334c:	89 f0                	mov    %esi,%eax
f010334e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103351:	85 f6                	test   %esi,%esi
f0103353:	7e cd                	jle    f0103322 <vprintfmt+0x1ae>
					putch(padc, putdat);
f0103355:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0103359:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010335c:	89 c3                	mov    %eax,%ebx
f010335e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103362:	89 34 24             	mov    %esi,(%esp)
f0103365:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103368:	83 eb 01             	sub    $0x1,%ebx
f010336b:	75 f1                	jne    f010335e <vprintfmt+0x1ea>
f010336d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103370:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103373:	eb ad                	jmp    f0103322 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103375:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103379:	74 1e                	je     f0103399 <vprintfmt+0x225>
f010337b:	0f be d2             	movsbl %dl,%edx
f010337e:	83 ea 20             	sub    $0x20,%edx
f0103381:	83 fa 5e             	cmp    $0x5e,%edx
f0103384:	76 13                	jbe    f0103399 <vprintfmt+0x225>
					putch('?', putdat);
f0103386:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103389:	89 44 24 04          	mov    %eax,0x4(%esp)
f010338d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103394:	ff 55 08             	call   *0x8(%ebp)
f0103397:	eb 0d                	jmp    f01033a6 <vprintfmt+0x232>
				else
					putch(ch, putdat);
f0103399:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010339c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01033a0:	89 04 24             	mov    %eax,(%esp)
f01033a3:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033a6:	83 ef 01             	sub    $0x1,%edi
f01033a9:	83 c6 01             	add    $0x1,%esi
f01033ac:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01033b0:	0f be c2             	movsbl %dl,%eax
f01033b3:	85 c0                	test   %eax,%eax
f01033b5:	75 20                	jne    f01033d7 <vprintfmt+0x263>
f01033b7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01033ba:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01033c0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01033c4:	7f 25                	jg     f01033eb <vprintfmt+0x277>
f01033c6:	e9 d2 fd ff ff       	jmp    f010319d <vprintfmt+0x29>
f01033cb:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01033ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01033d1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01033d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033d7:	85 db                	test   %ebx,%ebx
f01033d9:	78 9a                	js     f0103375 <vprintfmt+0x201>
f01033db:	83 eb 01             	sub    $0x1,%ebx
f01033de:	79 95                	jns    f0103375 <vprintfmt+0x201>
f01033e0:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01033e3:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033e6:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01033e9:	eb d5                	jmp    f01033c0 <vprintfmt+0x24c>
f01033eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01033ee:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01033f1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01033f4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033f8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01033ff:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103401:	83 eb 01             	sub    $0x1,%ebx
f0103404:	75 ee                	jne    f01033f4 <vprintfmt+0x280>
f0103406:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103409:	e9 8f fd ff ff       	jmp    f010319d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010340e:	83 fa 01             	cmp    $0x1,%edx
f0103411:	7e 16                	jle    f0103429 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
f0103413:	8b 45 14             	mov    0x14(%ebp),%eax
f0103416:	8d 50 08             	lea    0x8(%eax),%edx
f0103419:	89 55 14             	mov    %edx,0x14(%ebp)
f010341c:	8b 50 04             	mov    0x4(%eax),%edx
f010341f:	8b 00                	mov    (%eax),%eax
f0103421:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103424:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103427:	eb 32                	jmp    f010345b <vprintfmt+0x2e7>
	else if (lflag)
f0103429:	85 d2                	test   %edx,%edx
f010342b:	74 18                	je     f0103445 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
f010342d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103430:	8d 50 04             	lea    0x4(%eax),%edx
f0103433:	89 55 14             	mov    %edx,0x14(%ebp)
f0103436:	8b 30                	mov    (%eax),%esi
f0103438:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010343b:	89 f0                	mov    %esi,%eax
f010343d:	c1 f8 1f             	sar    $0x1f,%eax
f0103440:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103443:	eb 16                	jmp    f010345b <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
f0103445:	8b 45 14             	mov    0x14(%ebp),%eax
f0103448:	8d 50 04             	lea    0x4(%eax),%edx
f010344b:	89 55 14             	mov    %edx,0x14(%ebp)
f010344e:	8b 30                	mov    (%eax),%esi
f0103450:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0103453:	89 f0                	mov    %esi,%eax
f0103455:	c1 f8 1f             	sar    $0x1f,%eax
f0103458:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010345b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010345e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103461:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103466:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010346a:	0f 89 80 00 00 00    	jns    f01034f0 <vprintfmt+0x37c>
				putch('-', putdat);
f0103470:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103474:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010347b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010347e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103481:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103484:	f7 d8                	neg    %eax
f0103486:	83 d2 00             	adc    $0x0,%edx
f0103489:	f7 da                	neg    %edx
			}
			base = 10;
f010348b:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103490:	eb 5e                	jmp    f01034f0 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103492:	8d 45 14             	lea    0x14(%ebp),%eax
f0103495:	e8 5b fc ff ff       	call   f01030f5 <getuint>
			base = 10;
f010349a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010349f:	eb 4f                	jmp    f01034f0 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f01034a1:	8d 45 14             	lea    0x14(%ebp),%eax
f01034a4:	e8 4c fc ff ff       	call   f01030f5 <getuint>
			base = 8;
f01034a9:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01034ae:	eb 40                	jmp    f01034f0 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
f01034b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034b4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01034bb:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01034be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034c2:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01034c9:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01034cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01034cf:	8d 50 04             	lea    0x4(%eax),%edx
f01034d2:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01034d5:	8b 00                	mov    (%eax),%eax
f01034d7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01034dc:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01034e1:	eb 0d                	jmp    f01034f0 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01034e3:	8d 45 14             	lea    0x14(%ebp),%eax
f01034e6:	e8 0a fc ff ff       	call   f01030f5 <getuint>
			base = 16;
f01034eb:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01034f0:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01034f4:	89 74 24 10          	mov    %esi,0x10(%esp)
f01034f8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01034fb:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01034ff:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103503:	89 04 24             	mov    %eax,(%esp)
f0103506:	89 54 24 04          	mov    %edx,0x4(%esp)
f010350a:	89 fa                	mov    %edi,%edx
f010350c:	8b 45 08             	mov    0x8(%ebp),%eax
f010350f:	e8 ec fa ff ff       	call   f0103000 <printnum>
			break;
f0103514:	e9 84 fc ff ff       	jmp    f010319d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103519:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010351d:	89 0c 24             	mov    %ecx,(%esp)
f0103520:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103523:	e9 75 fc ff ff       	jmp    f010319d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103528:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010352c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103533:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103536:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010353a:	0f 84 5b fc ff ff    	je     f010319b <vprintfmt+0x27>
f0103540:	89 f3                	mov    %esi,%ebx
f0103542:	83 eb 01             	sub    $0x1,%ebx
f0103545:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103549:	75 f7                	jne    f0103542 <vprintfmt+0x3ce>
f010354b:	e9 4d fc ff ff       	jmp    f010319d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f0103550:	83 c4 3c             	add    $0x3c,%esp
f0103553:	5b                   	pop    %ebx
f0103554:	5e                   	pop    %esi
f0103555:	5f                   	pop    %edi
f0103556:	5d                   	pop    %ebp
f0103557:	c3                   	ret    

f0103558 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103558:	55                   	push   %ebp
f0103559:	89 e5                	mov    %esp,%ebp
f010355b:	83 ec 28             	sub    $0x28,%esp
f010355e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103561:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103564:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103567:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010356b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010356e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103575:	85 c0                	test   %eax,%eax
f0103577:	74 30                	je     f01035a9 <vsnprintf+0x51>
f0103579:	85 d2                	test   %edx,%edx
f010357b:	7e 2c                	jle    f01035a9 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010357d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103580:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103584:	8b 45 10             	mov    0x10(%ebp),%eax
f0103587:	89 44 24 08          	mov    %eax,0x8(%esp)
f010358b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010358e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103592:	c7 04 24 2f 31 10 f0 	movl   $0xf010312f,(%esp)
f0103599:	e8 d6 fb ff ff       	call   f0103174 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010359e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035a1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01035a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035a7:	eb 05                	jmp    f01035ae <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01035a9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01035ae:	c9                   	leave  
f01035af:	c3                   	ret    

f01035b0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01035b0:	55                   	push   %ebp
f01035b1:	89 e5                	mov    %esp,%ebp
f01035b3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01035b6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01035b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01035c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01035ce:	89 04 24             	mov    %eax,(%esp)
f01035d1:	e8 82 ff ff ff       	call   f0103558 <vsnprintf>
	va_end(ap);

	return rc;
}
f01035d6:	c9                   	leave  
f01035d7:	c3                   	ret    
f01035d8:	66 90                	xchg   %ax,%ax
f01035da:	66 90                	xchg   %ax,%ax
f01035dc:	66 90                	xchg   %ax,%ax
f01035de:	66 90                	xchg   %ax,%ax

f01035e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01035e0:	55                   	push   %ebp
f01035e1:	89 e5                	mov    %esp,%ebp
f01035e3:	57                   	push   %edi
f01035e4:	56                   	push   %esi
f01035e5:	53                   	push   %ebx
f01035e6:	83 ec 1c             	sub    $0x1c,%esp
f01035e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01035ec:	85 c0                	test   %eax,%eax
f01035ee:	74 10                	je     f0103600 <readline+0x20>
		cprintf("%s", prompt);
f01035f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035f4:	c7 04 24 8c 49 10 f0 	movl   $0xf010498c,(%esp)
f01035fb:	e8 f1 f6 ff ff       	call   f0102cf1 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103600:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103607:	e8 1d d0 ff ff       	call   f0100629 <iscons>
f010360c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010360e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103613:	e8 00 d0 ff ff       	call   f0100618 <getchar>
f0103618:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010361a:	85 c0                	test   %eax,%eax
f010361c:	79 17                	jns    f0103635 <readline+0x55>
			cprintf("read error: %e\n", c);
f010361e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103622:	c7 04 24 3c 4e 10 f0 	movl   $0xf0104e3c,(%esp)
f0103629:	e8 c3 f6 ff ff       	call   f0102cf1 <cprintf>
			return NULL;
f010362e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103633:	eb 6d                	jmp    f01036a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103635:	83 f8 7f             	cmp    $0x7f,%eax
f0103638:	74 05                	je     f010363f <readline+0x5f>
f010363a:	83 f8 08             	cmp    $0x8,%eax
f010363d:	75 19                	jne    f0103658 <readline+0x78>
f010363f:	85 f6                	test   %esi,%esi
f0103641:	7e 15                	jle    f0103658 <readline+0x78>
			if (echoing)
f0103643:	85 ff                	test   %edi,%edi
f0103645:	74 0c                	je     f0103653 <readline+0x73>
				cputchar('\b');
f0103647:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010364e:	e8 b5 cf ff ff       	call   f0100608 <cputchar>
			i--;
f0103653:	83 ee 01             	sub    $0x1,%esi
f0103656:	eb bb                	jmp    f0103613 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103658:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010365e:	7f 1c                	jg     f010367c <readline+0x9c>
f0103660:	83 fb 1f             	cmp    $0x1f,%ebx
f0103663:	7e 17                	jle    f010367c <readline+0x9c>
			if (echoing)
f0103665:	85 ff                	test   %edi,%edi
f0103667:	74 08                	je     f0103671 <readline+0x91>
				cputchar(c);
f0103669:	89 1c 24             	mov    %ebx,(%esp)
f010366c:	e8 97 cf ff ff       	call   f0100608 <cputchar>
			buf[i++] = c;
f0103671:	88 9e 80 75 11 f0    	mov    %bl,-0xfee8a80(%esi)
f0103677:	8d 76 01             	lea    0x1(%esi),%esi
f010367a:	eb 97                	jmp    f0103613 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010367c:	83 fb 0d             	cmp    $0xd,%ebx
f010367f:	74 05                	je     f0103686 <readline+0xa6>
f0103681:	83 fb 0a             	cmp    $0xa,%ebx
f0103684:	75 8d                	jne    f0103613 <readline+0x33>
			if (echoing)
f0103686:	85 ff                	test   %edi,%edi
f0103688:	74 0c                	je     f0103696 <readline+0xb6>
				cputchar('\n');
f010368a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103691:	e8 72 cf ff ff       	call   f0100608 <cputchar>
			buf[i] = 0;
f0103696:	c6 86 80 75 11 f0 00 	movb   $0x0,-0xfee8a80(%esi)
			return buf;
f010369d:	b8 80 75 11 f0       	mov    $0xf0117580,%eax
		}
	}
}
f01036a2:	83 c4 1c             	add    $0x1c,%esp
f01036a5:	5b                   	pop    %ebx
f01036a6:	5e                   	pop    %esi
f01036a7:	5f                   	pop    %edi
f01036a8:	5d                   	pop    %ebp
f01036a9:	c3                   	ret    
f01036aa:	66 90                	xchg   %ax,%ax
f01036ac:	66 90                	xchg   %ax,%ax
f01036ae:	66 90                	xchg   %ax,%ax

f01036b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01036b0:	55                   	push   %ebp
f01036b1:	89 e5                	mov    %esp,%ebp
f01036b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01036b6:	80 3a 00             	cmpb   $0x0,(%edx)
f01036b9:	74 10                	je     f01036cb <strlen+0x1b>
f01036bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01036c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01036c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01036c7:	75 f7                	jne    f01036c0 <strlen+0x10>
f01036c9:	eb 05                	jmp    f01036d0 <strlen+0x20>
f01036cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01036d0:	5d                   	pop    %ebp
f01036d1:	c3                   	ret    

f01036d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01036d2:	55                   	push   %ebp
f01036d3:	89 e5                	mov    %esp,%ebp
f01036d5:	53                   	push   %ebx
f01036d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01036d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036dc:	85 c9                	test   %ecx,%ecx
f01036de:	74 1c                	je     f01036fc <strnlen+0x2a>
f01036e0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01036e3:	74 1e                	je     f0103703 <strnlen+0x31>
f01036e5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01036ea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036ec:	39 ca                	cmp    %ecx,%edx
f01036ee:	74 18                	je     f0103708 <strnlen+0x36>
f01036f0:	83 c2 01             	add    $0x1,%edx
f01036f3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01036f8:	75 f0                	jne    f01036ea <strnlen+0x18>
f01036fa:	eb 0c                	jmp    f0103708 <strnlen+0x36>
f01036fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0103701:	eb 05                	jmp    f0103708 <strnlen+0x36>
f0103703:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103708:	5b                   	pop    %ebx
f0103709:	5d                   	pop    %ebp
f010370a:	c3                   	ret    

f010370b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010370b:	55                   	push   %ebp
f010370c:	89 e5                	mov    %esp,%ebp
f010370e:	53                   	push   %ebx
f010370f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103712:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103715:	89 c2                	mov    %eax,%edx
f0103717:	83 c2 01             	add    $0x1,%edx
f010371a:	83 c1 01             	add    $0x1,%ecx
f010371d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103721:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103724:	84 db                	test   %bl,%bl
f0103726:	75 ef                	jne    f0103717 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103728:	5b                   	pop    %ebx
f0103729:	5d                   	pop    %ebp
f010372a:	c3                   	ret    

f010372b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010372b:	55                   	push   %ebp
f010372c:	89 e5                	mov    %esp,%ebp
f010372e:	56                   	push   %esi
f010372f:	53                   	push   %ebx
f0103730:	8b 75 08             	mov    0x8(%ebp),%esi
f0103733:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103736:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103739:	85 db                	test   %ebx,%ebx
f010373b:	74 17                	je     f0103754 <strncpy+0x29>
f010373d:	01 f3                	add    %esi,%ebx
f010373f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0103741:	83 c1 01             	add    $0x1,%ecx
f0103744:	0f b6 02             	movzbl (%edx),%eax
f0103747:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010374a:	80 3a 01             	cmpb   $0x1,(%edx)
f010374d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103750:	39 d9                	cmp    %ebx,%ecx
f0103752:	75 ed                	jne    f0103741 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103754:	89 f0                	mov    %esi,%eax
f0103756:	5b                   	pop    %ebx
f0103757:	5e                   	pop    %esi
f0103758:	5d                   	pop    %ebp
f0103759:	c3                   	ret    

f010375a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010375a:	55                   	push   %ebp
f010375b:	89 e5                	mov    %esp,%ebp
f010375d:	57                   	push   %edi
f010375e:	56                   	push   %esi
f010375f:	53                   	push   %ebx
f0103760:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103763:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103766:	8b 75 10             	mov    0x10(%ebp),%esi
f0103769:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010376b:	85 f6                	test   %esi,%esi
f010376d:	74 34                	je     f01037a3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010376f:	83 fe 01             	cmp    $0x1,%esi
f0103772:	74 26                	je     f010379a <strlcpy+0x40>
f0103774:	0f b6 0b             	movzbl (%ebx),%ecx
f0103777:	84 c9                	test   %cl,%cl
f0103779:	74 23                	je     f010379e <strlcpy+0x44>
f010377b:	83 ee 02             	sub    $0x2,%esi
f010377e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0103783:	83 c0 01             	add    $0x1,%eax
f0103786:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103789:	39 f2                	cmp    %esi,%edx
f010378b:	74 13                	je     f01037a0 <strlcpy+0x46>
f010378d:	83 c2 01             	add    $0x1,%edx
f0103790:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103794:	84 c9                	test   %cl,%cl
f0103796:	75 eb                	jne    f0103783 <strlcpy+0x29>
f0103798:	eb 06                	jmp    f01037a0 <strlcpy+0x46>
f010379a:	89 f8                	mov    %edi,%eax
f010379c:	eb 02                	jmp    f01037a0 <strlcpy+0x46>
f010379e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01037a0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01037a3:	29 f8                	sub    %edi,%eax
}
f01037a5:	5b                   	pop    %ebx
f01037a6:	5e                   	pop    %esi
f01037a7:	5f                   	pop    %edi
f01037a8:	5d                   	pop    %ebp
f01037a9:	c3                   	ret    

f01037aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01037aa:	55                   	push   %ebp
f01037ab:	89 e5                	mov    %esp,%ebp
f01037ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037b0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01037b3:	0f b6 01             	movzbl (%ecx),%eax
f01037b6:	84 c0                	test   %al,%al
f01037b8:	74 15                	je     f01037cf <strcmp+0x25>
f01037ba:	3a 02                	cmp    (%edx),%al
f01037bc:	75 11                	jne    f01037cf <strcmp+0x25>
		p++, q++;
f01037be:	83 c1 01             	add    $0x1,%ecx
f01037c1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01037c4:	0f b6 01             	movzbl (%ecx),%eax
f01037c7:	84 c0                	test   %al,%al
f01037c9:	74 04                	je     f01037cf <strcmp+0x25>
f01037cb:	3a 02                	cmp    (%edx),%al
f01037cd:	74 ef                	je     f01037be <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01037cf:	0f b6 c0             	movzbl %al,%eax
f01037d2:	0f b6 12             	movzbl (%edx),%edx
f01037d5:	29 d0                	sub    %edx,%eax
}
f01037d7:	5d                   	pop    %ebp
f01037d8:	c3                   	ret    

f01037d9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01037d9:	55                   	push   %ebp
f01037da:	89 e5                	mov    %esp,%ebp
f01037dc:	56                   	push   %esi
f01037dd:	53                   	push   %ebx
f01037de:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01037e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037e4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01037e7:	85 f6                	test   %esi,%esi
f01037e9:	74 29                	je     f0103814 <strncmp+0x3b>
f01037eb:	0f b6 03             	movzbl (%ebx),%eax
f01037ee:	84 c0                	test   %al,%al
f01037f0:	74 30                	je     f0103822 <strncmp+0x49>
f01037f2:	3a 02                	cmp    (%edx),%al
f01037f4:	75 2c                	jne    f0103822 <strncmp+0x49>
f01037f6:	8d 43 01             	lea    0x1(%ebx),%eax
f01037f9:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01037fb:	89 c3                	mov    %eax,%ebx
f01037fd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103800:	39 f0                	cmp    %esi,%eax
f0103802:	74 17                	je     f010381b <strncmp+0x42>
f0103804:	0f b6 08             	movzbl (%eax),%ecx
f0103807:	84 c9                	test   %cl,%cl
f0103809:	74 17                	je     f0103822 <strncmp+0x49>
f010380b:	83 c0 01             	add    $0x1,%eax
f010380e:	3a 0a                	cmp    (%edx),%cl
f0103810:	74 e9                	je     f01037fb <strncmp+0x22>
f0103812:	eb 0e                	jmp    f0103822 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103814:	b8 00 00 00 00       	mov    $0x0,%eax
f0103819:	eb 0f                	jmp    f010382a <strncmp+0x51>
f010381b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103820:	eb 08                	jmp    f010382a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103822:	0f b6 03             	movzbl (%ebx),%eax
f0103825:	0f b6 12             	movzbl (%edx),%edx
f0103828:	29 d0                	sub    %edx,%eax
}
f010382a:	5b                   	pop    %ebx
f010382b:	5e                   	pop    %esi
f010382c:	5d                   	pop    %ebp
f010382d:	c3                   	ret    

f010382e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010382e:	55                   	push   %ebp
f010382f:	89 e5                	mov    %esp,%ebp
f0103831:	53                   	push   %ebx
f0103832:	8b 45 08             	mov    0x8(%ebp),%eax
f0103835:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0103838:	0f b6 18             	movzbl (%eax),%ebx
f010383b:	84 db                	test   %bl,%bl
f010383d:	74 1d                	je     f010385c <strchr+0x2e>
f010383f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103841:	38 d3                	cmp    %dl,%bl
f0103843:	75 06                	jne    f010384b <strchr+0x1d>
f0103845:	eb 1a                	jmp    f0103861 <strchr+0x33>
f0103847:	38 ca                	cmp    %cl,%dl
f0103849:	74 16                	je     f0103861 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010384b:	83 c0 01             	add    $0x1,%eax
f010384e:	0f b6 10             	movzbl (%eax),%edx
f0103851:	84 d2                	test   %dl,%dl
f0103853:	75 f2                	jne    f0103847 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0103855:	b8 00 00 00 00       	mov    $0x0,%eax
f010385a:	eb 05                	jmp    f0103861 <strchr+0x33>
f010385c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103861:	5b                   	pop    %ebx
f0103862:	5d                   	pop    %ebp
f0103863:	c3                   	ret    

f0103864 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103864:	55                   	push   %ebp
f0103865:	89 e5                	mov    %esp,%ebp
f0103867:	53                   	push   %ebx
f0103868:	8b 45 08             	mov    0x8(%ebp),%eax
f010386b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010386e:	0f b6 18             	movzbl (%eax),%ebx
f0103871:	84 db                	test   %bl,%bl
f0103873:	74 17                	je     f010388c <strfind+0x28>
f0103875:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103877:	38 d3                	cmp    %dl,%bl
f0103879:	75 07                	jne    f0103882 <strfind+0x1e>
f010387b:	eb 0f                	jmp    f010388c <strfind+0x28>
f010387d:	38 ca                	cmp    %cl,%dl
f010387f:	90                   	nop
f0103880:	74 0a                	je     f010388c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103882:	83 c0 01             	add    $0x1,%eax
f0103885:	0f b6 10             	movzbl (%eax),%edx
f0103888:	84 d2                	test   %dl,%dl
f010388a:	75 f1                	jne    f010387d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010388c:	5b                   	pop    %ebx
f010388d:	5d                   	pop    %ebp
f010388e:	c3                   	ret    

f010388f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010388f:	55                   	push   %ebp
f0103890:	89 e5                	mov    %esp,%ebp
f0103892:	57                   	push   %edi
f0103893:	56                   	push   %esi
f0103894:	53                   	push   %ebx
f0103895:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103898:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010389b:	85 c9                	test   %ecx,%ecx
f010389d:	74 36                	je     f01038d5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010389f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01038a5:	75 28                	jne    f01038cf <memset+0x40>
f01038a7:	f6 c1 03             	test   $0x3,%cl
f01038aa:	75 23                	jne    f01038cf <memset+0x40>
		c &= 0xFF;
f01038ac:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01038b0:	89 d3                	mov    %edx,%ebx
f01038b2:	c1 e3 08             	shl    $0x8,%ebx
f01038b5:	89 d6                	mov    %edx,%esi
f01038b7:	c1 e6 18             	shl    $0x18,%esi
f01038ba:	89 d0                	mov    %edx,%eax
f01038bc:	c1 e0 10             	shl    $0x10,%eax
f01038bf:	09 f0                	or     %esi,%eax
f01038c1:	09 c2                	or     %eax,%edx
f01038c3:	89 d0                	mov    %edx,%eax
f01038c5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01038c7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01038ca:	fc                   	cld    
f01038cb:	f3 ab                	rep stos %eax,%es:(%edi)
f01038cd:	eb 06                	jmp    f01038d5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01038cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038d2:	fc                   	cld    
f01038d3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01038d5:	89 f8                	mov    %edi,%eax
f01038d7:	5b                   	pop    %ebx
f01038d8:	5e                   	pop    %esi
f01038d9:	5f                   	pop    %edi
f01038da:	5d                   	pop    %ebp
f01038db:	c3                   	ret    

f01038dc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01038dc:	55                   	push   %ebp
f01038dd:	89 e5                	mov    %esp,%ebp
f01038df:	57                   	push   %edi
f01038e0:	56                   	push   %esi
f01038e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01038e7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01038ea:	39 c6                	cmp    %eax,%esi
f01038ec:	73 35                	jae    f0103923 <memmove+0x47>
f01038ee:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01038f1:	39 d0                	cmp    %edx,%eax
f01038f3:	73 2e                	jae    f0103923 <memmove+0x47>
		s += n;
		d += n;
f01038f5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01038f8:	89 d6                	mov    %edx,%esi
f01038fa:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038fc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103902:	75 13                	jne    f0103917 <memmove+0x3b>
f0103904:	f6 c1 03             	test   $0x3,%cl
f0103907:	75 0e                	jne    f0103917 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103909:	83 ef 04             	sub    $0x4,%edi
f010390c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010390f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103912:	fd                   	std    
f0103913:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103915:	eb 09                	jmp    f0103920 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103917:	83 ef 01             	sub    $0x1,%edi
f010391a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010391d:	fd                   	std    
f010391e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103920:	fc                   	cld    
f0103921:	eb 1d                	jmp    f0103940 <memmove+0x64>
f0103923:	89 f2                	mov    %esi,%edx
f0103925:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103927:	f6 c2 03             	test   $0x3,%dl
f010392a:	75 0f                	jne    f010393b <memmove+0x5f>
f010392c:	f6 c1 03             	test   $0x3,%cl
f010392f:	75 0a                	jne    f010393b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103931:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103934:	89 c7                	mov    %eax,%edi
f0103936:	fc                   	cld    
f0103937:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103939:	eb 05                	jmp    f0103940 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010393b:	89 c7                	mov    %eax,%edi
f010393d:	fc                   	cld    
f010393e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103940:	5e                   	pop    %esi
f0103941:	5f                   	pop    %edi
f0103942:	5d                   	pop    %ebp
f0103943:	c3                   	ret    

f0103944 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103944:	55                   	push   %ebp
f0103945:	89 e5                	mov    %esp,%ebp
f0103947:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010394a:	8b 45 10             	mov    0x10(%ebp),%eax
f010394d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103951:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103954:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103958:	8b 45 08             	mov    0x8(%ebp),%eax
f010395b:	89 04 24             	mov    %eax,(%esp)
f010395e:	e8 79 ff ff ff       	call   f01038dc <memmove>
}
f0103963:	c9                   	leave  
f0103964:	c3                   	ret    

f0103965 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103965:	55                   	push   %ebp
f0103966:	89 e5                	mov    %esp,%ebp
f0103968:	57                   	push   %edi
f0103969:	56                   	push   %esi
f010396a:	53                   	push   %ebx
f010396b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010396e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103971:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103974:	8d 78 ff             	lea    -0x1(%eax),%edi
f0103977:	85 c0                	test   %eax,%eax
f0103979:	74 36                	je     f01039b1 <memcmp+0x4c>
		if (*s1 != *s2)
f010397b:	0f b6 03             	movzbl (%ebx),%eax
f010397e:	0f b6 0e             	movzbl (%esi),%ecx
f0103981:	ba 00 00 00 00       	mov    $0x0,%edx
f0103986:	38 c8                	cmp    %cl,%al
f0103988:	74 1c                	je     f01039a6 <memcmp+0x41>
f010398a:	eb 10                	jmp    f010399c <memcmp+0x37>
f010398c:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103991:	83 c2 01             	add    $0x1,%edx
f0103994:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103998:	38 c8                	cmp    %cl,%al
f010399a:	74 0a                	je     f01039a6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010399c:	0f b6 c0             	movzbl %al,%eax
f010399f:	0f b6 c9             	movzbl %cl,%ecx
f01039a2:	29 c8                	sub    %ecx,%eax
f01039a4:	eb 10                	jmp    f01039b6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01039a6:	39 fa                	cmp    %edi,%edx
f01039a8:	75 e2                	jne    f010398c <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01039aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01039af:	eb 05                	jmp    f01039b6 <memcmp+0x51>
f01039b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039b6:	5b                   	pop    %ebx
f01039b7:	5e                   	pop    %esi
f01039b8:	5f                   	pop    %edi
f01039b9:	5d                   	pop    %ebp
f01039ba:	c3                   	ret    

f01039bb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01039bb:	55                   	push   %ebp
f01039bc:	89 e5                	mov    %esp,%ebp
f01039be:	53                   	push   %ebx
f01039bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01039c5:	89 c2                	mov    %eax,%edx
f01039c7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01039ca:	39 d0                	cmp    %edx,%eax
f01039cc:	73 14                	jae    f01039e2 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f01039ce:	89 d9                	mov    %ebx,%ecx
f01039d0:	38 18                	cmp    %bl,(%eax)
f01039d2:	75 06                	jne    f01039da <memfind+0x1f>
f01039d4:	eb 0c                	jmp    f01039e2 <memfind+0x27>
f01039d6:	38 08                	cmp    %cl,(%eax)
f01039d8:	74 08                	je     f01039e2 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01039da:	83 c0 01             	add    $0x1,%eax
f01039dd:	39 d0                	cmp    %edx,%eax
f01039df:	90                   	nop
f01039e0:	75 f4                	jne    f01039d6 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01039e2:	5b                   	pop    %ebx
f01039e3:	5d                   	pop    %ebp
f01039e4:	c3                   	ret    

f01039e5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01039e5:	55                   	push   %ebp
f01039e6:	89 e5                	mov    %esp,%ebp
f01039e8:	57                   	push   %edi
f01039e9:	56                   	push   %esi
f01039ea:	53                   	push   %ebx
f01039eb:	8b 55 08             	mov    0x8(%ebp),%edx
f01039ee:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039f1:	0f b6 0a             	movzbl (%edx),%ecx
f01039f4:	80 f9 09             	cmp    $0x9,%cl
f01039f7:	74 05                	je     f01039fe <strtol+0x19>
f01039f9:	80 f9 20             	cmp    $0x20,%cl
f01039fc:	75 10                	jne    f0103a0e <strtol+0x29>
		s++;
f01039fe:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a01:	0f b6 0a             	movzbl (%edx),%ecx
f0103a04:	80 f9 09             	cmp    $0x9,%cl
f0103a07:	74 f5                	je     f01039fe <strtol+0x19>
f0103a09:	80 f9 20             	cmp    $0x20,%cl
f0103a0c:	74 f0                	je     f01039fe <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103a0e:	80 f9 2b             	cmp    $0x2b,%cl
f0103a11:	75 0a                	jne    f0103a1d <strtol+0x38>
		s++;
f0103a13:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103a16:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a1b:	eb 11                	jmp    f0103a2e <strtol+0x49>
f0103a1d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103a22:	80 f9 2d             	cmp    $0x2d,%cl
f0103a25:	75 07                	jne    f0103a2e <strtol+0x49>
		s++, neg = 1;
f0103a27:	83 c2 01             	add    $0x1,%edx
f0103a2a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a2e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103a33:	75 15                	jne    f0103a4a <strtol+0x65>
f0103a35:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a38:	75 10                	jne    f0103a4a <strtol+0x65>
f0103a3a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103a3e:	75 0a                	jne    f0103a4a <strtol+0x65>
		s += 2, base = 16;
f0103a40:	83 c2 02             	add    $0x2,%edx
f0103a43:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a48:	eb 10                	jmp    f0103a5a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f0103a4a:	85 c0                	test   %eax,%eax
f0103a4c:	75 0c                	jne    f0103a5a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103a4e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a50:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a53:	75 05                	jne    f0103a5a <strtol+0x75>
		s++, base = 8;
f0103a55:	83 c2 01             	add    $0x1,%edx
f0103a58:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103a5a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a5f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a62:	0f b6 0a             	movzbl (%edx),%ecx
f0103a65:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103a68:	89 f0                	mov    %esi,%eax
f0103a6a:	3c 09                	cmp    $0x9,%al
f0103a6c:	77 08                	ja     f0103a76 <strtol+0x91>
			dig = *s - '0';
f0103a6e:	0f be c9             	movsbl %cl,%ecx
f0103a71:	83 e9 30             	sub    $0x30,%ecx
f0103a74:	eb 20                	jmp    f0103a96 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0103a76:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103a79:	89 f0                	mov    %esi,%eax
f0103a7b:	3c 19                	cmp    $0x19,%al
f0103a7d:	77 08                	ja     f0103a87 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0103a7f:	0f be c9             	movsbl %cl,%ecx
f0103a82:	83 e9 57             	sub    $0x57,%ecx
f0103a85:	eb 0f                	jmp    f0103a96 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0103a87:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103a8a:	89 f0                	mov    %esi,%eax
f0103a8c:	3c 19                	cmp    $0x19,%al
f0103a8e:	77 16                	ja     f0103aa6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0103a90:	0f be c9             	movsbl %cl,%ecx
f0103a93:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103a96:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103a99:	7d 0f                	jge    f0103aaa <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103a9b:	83 c2 01             	add    $0x1,%edx
f0103a9e:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103aa2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103aa4:	eb bc                	jmp    f0103a62 <strtol+0x7d>
f0103aa6:	89 d8                	mov    %ebx,%eax
f0103aa8:	eb 02                	jmp    f0103aac <strtol+0xc7>
f0103aaa:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103aac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103ab0:	74 05                	je     f0103ab7 <strtol+0xd2>
		*endptr = (char *) s;
f0103ab2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ab5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103ab7:	f7 d8                	neg    %eax
f0103ab9:	85 ff                	test   %edi,%edi
f0103abb:	0f 44 c3             	cmove  %ebx,%eax
}
f0103abe:	5b                   	pop    %ebx
f0103abf:	5e                   	pop    %esi
f0103ac0:	5f                   	pop    %edi
f0103ac1:	5d                   	pop    %ebp
f0103ac2:	c3                   	ret    
f0103ac3:	66 90                	xchg   %ax,%ax
f0103ac5:	66 90                	xchg   %ax,%ax
f0103ac7:	66 90                	xchg   %ax,%ax
f0103ac9:	66 90                	xchg   %ax,%ax
f0103acb:	66 90                	xchg   %ax,%ax
f0103acd:	66 90                	xchg   %ax,%ax
f0103acf:	90                   	nop

f0103ad0 <__udivdi3>:
f0103ad0:	55                   	push   %ebp
f0103ad1:	57                   	push   %edi
f0103ad2:	56                   	push   %esi
f0103ad3:	83 ec 0c             	sub    $0xc,%esp
f0103ad6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103ada:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103ade:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103ae2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103ae6:	85 c0                	test   %eax,%eax
f0103ae8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103aec:	89 ea                	mov    %ebp,%edx
f0103aee:	89 0c 24             	mov    %ecx,(%esp)
f0103af1:	75 2d                	jne    f0103b20 <__udivdi3+0x50>
f0103af3:	39 e9                	cmp    %ebp,%ecx
f0103af5:	77 61                	ja     f0103b58 <__udivdi3+0x88>
f0103af7:	85 c9                	test   %ecx,%ecx
f0103af9:	89 ce                	mov    %ecx,%esi
f0103afb:	75 0b                	jne    f0103b08 <__udivdi3+0x38>
f0103afd:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b02:	31 d2                	xor    %edx,%edx
f0103b04:	f7 f1                	div    %ecx
f0103b06:	89 c6                	mov    %eax,%esi
f0103b08:	31 d2                	xor    %edx,%edx
f0103b0a:	89 e8                	mov    %ebp,%eax
f0103b0c:	f7 f6                	div    %esi
f0103b0e:	89 c5                	mov    %eax,%ebp
f0103b10:	89 f8                	mov    %edi,%eax
f0103b12:	f7 f6                	div    %esi
f0103b14:	89 ea                	mov    %ebp,%edx
f0103b16:	83 c4 0c             	add    $0xc,%esp
f0103b19:	5e                   	pop    %esi
f0103b1a:	5f                   	pop    %edi
f0103b1b:	5d                   	pop    %ebp
f0103b1c:	c3                   	ret    
f0103b1d:	8d 76 00             	lea    0x0(%esi),%esi
f0103b20:	39 e8                	cmp    %ebp,%eax
f0103b22:	77 24                	ja     f0103b48 <__udivdi3+0x78>
f0103b24:	0f bd e8             	bsr    %eax,%ebp
f0103b27:	83 f5 1f             	xor    $0x1f,%ebp
f0103b2a:	75 3c                	jne    f0103b68 <__udivdi3+0x98>
f0103b2c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103b30:	39 34 24             	cmp    %esi,(%esp)
f0103b33:	0f 86 9f 00 00 00    	jbe    f0103bd8 <__udivdi3+0x108>
f0103b39:	39 d0                	cmp    %edx,%eax
f0103b3b:	0f 82 97 00 00 00    	jb     f0103bd8 <__udivdi3+0x108>
f0103b41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b48:	31 d2                	xor    %edx,%edx
f0103b4a:	31 c0                	xor    %eax,%eax
f0103b4c:	83 c4 0c             	add    $0xc,%esp
f0103b4f:	5e                   	pop    %esi
f0103b50:	5f                   	pop    %edi
f0103b51:	5d                   	pop    %ebp
f0103b52:	c3                   	ret    
f0103b53:	90                   	nop
f0103b54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b58:	89 f8                	mov    %edi,%eax
f0103b5a:	f7 f1                	div    %ecx
f0103b5c:	31 d2                	xor    %edx,%edx
f0103b5e:	83 c4 0c             	add    $0xc,%esp
f0103b61:	5e                   	pop    %esi
f0103b62:	5f                   	pop    %edi
f0103b63:	5d                   	pop    %ebp
f0103b64:	c3                   	ret    
f0103b65:	8d 76 00             	lea    0x0(%esi),%esi
f0103b68:	89 e9                	mov    %ebp,%ecx
f0103b6a:	8b 3c 24             	mov    (%esp),%edi
f0103b6d:	d3 e0                	shl    %cl,%eax
f0103b6f:	89 c6                	mov    %eax,%esi
f0103b71:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b76:	29 e8                	sub    %ebp,%eax
f0103b78:	89 c1                	mov    %eax,%ecx
f0103b7a:	d3 ef                	shr    %cl,%edi
f0103b7c:	89 e9                	mov    %ebp,%ecx
f0103b7e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103b82:	8b 3c 24             	mov    (%esp),%edi
f0103b85:	09 74 24 08          	or     %esi,0x8(%esp)
f0103b89:	89 d6                	mov    %edx,%esi
f0103b8b:	d3 e7                	shl    %cl,%edi
f0103b8d:	89 c1                	mov    %eax,%ecx
f0103b8f:	89 3c 24             	mov    %edi,(%esp)
f0103b92:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103b96:	d3 ee                	shr    %cl,%esi
f0103b98:	89 e9                	mov    %ebp,%ecx
f0103b9a:	d3 e2                	shl    %cl,%edx
f0103b9c:	89 c1                	mov    %eax,%ecx
f0103b9e:	d3 ef                	shr    %cl,%edi
f0103ba0:	09 d7                	or     %edx,%edi
f0103ba2:	89 f2                	mov    %esi,%edx
f0103ba4:	89 f8                	mov    %edi,%eax
f0103ba6:	f7 74 24 08          	divl   0x8(%esp)
f0103baa:	89 d6                	mov    %edx,%esi
f0103bac:	89 c7                	mov    %eax,%edi
f0103bae:	f7 24 24             	mull   (%esp)
f0103bb1:	39 d6                	cmp    %edx,%esi
f0103bb3:	89 14 24             	mov    %edx,(%esp)
f0103bb6:	72 30                	jb     f0103be8 <__udivdi3+0x118>
f0103bb8:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103bbc:	89 e9                	mov    %ebp,%ecx
f0103bbe:	d3 e2                	shl    %cl,%edx
f0103bc0:	39 c2                	cmp    %eax,%edx
f0103bc2:	73 05                	jae    f0103bc9 <__udivdi3+0xf9>
f0103bc4:	3b 34 24             	cmp    (%esp),%esi
f0103bc7:	74 1f                	je     f0103be8 <__udivdi3+0x118>
f0103bc9:	89 f8                	mov    %edi,%eax
f0103bcb:	31 d2                	xor    %edx,%edx
f0103bcd:	e9 7a ff ff ff       	jmp    f0103b4c <__udivdi3+0x7c>
f0103bd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103bd8:	31 d2                	xor    %edx,%edx
f0103bda:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bdf:	e9 68 ff ff ff       	jmp    f0103b4c <__udivdi3+0x7c>
f0103be4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103be8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103beb:	31 d2                	xor    %edx,%edx
f0103bed:	83 c4 0c             	add    $0xc,%esp
f0103bf0:	5e                   	pop    %esi
f0103bf1:	5f                   	pop    %edi
f0103bf2:	5d                   	pop    %ebp
f0103bf3:	c3                   	ret    
f0103bf4:	66 90                	xchg   %ax,%ax
f0103bf6:	66 90                	xchg   %ax,%ax
f0103bf8:	66 90                	xchg   %ax,%ax
f0103bfa:	66 90                	xchg   %ax,%ax
f0103bfc:	66 90                	xchg   %ax,%ax
f0103bfe:	66 90                	xchg   %ax,%ax

f0103c00 <__umoddi3>:
f0103c00:	55                   	push   %ebp
f0103c01:	57                   	push   %edi
f0103c02:	56                   	push   %esi
f0103c03:	83 ec 14             	sub    $0x14,%esp
f0103c06:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103c0a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103c0e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103c12:	89 c7                	mov    %eax,%edi
f0103c14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c18:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103c1c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103c20:	89 34 24             	mov    %esi,(%esp)
f0103c23:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c27:	85 c0                	test   %eax,%eax
f0103c29:	89 c2                	mov    %eax,%edx
f0103c2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c2f:	75 17                	jne    f0103c48 <__umoddi3+0x48>
f0103c31:	39 fe                	cmp    %edi,%esi
f0103c33:	76 4b                	jbe    f0103c80 <__umoddi3+0x80>
f0103c35:	89 c8                	mov    %ecx,%eax
f0103c37:	89 fa                	mov    %edi,%edx
f0103c39:	f7 f6                	div    %esi
f0103c3b:	89 d0                	mov    %edx,%eax
f0103c3d:	31 d2                	xor    %edx,%edx
f0103c3f:	83 c4 14             	add    $0x14,%esp
f0103c42:	5e                   	pop    %esi
f0103c43:	5f                   	pop    %edi
f0103c44:	5d                   	pop    %ebp
f0103c45:	c3                   	ret    
f0103c46:	66 90                	xchg   %ax,%ax
f0103c48:	39 f8                	cmp    %edi,%eax
f0103c4a:	77 54                	ja     f0103ca0 <__umoddi3+0xa0>
f0103c4c:	0f bd e8             	bsr    %eax,%ebp
f0103c4f:	83 f5 1f             	xor    $0x1f,%ebp
f0103c52:	75 5c                	jne    f0103cb0 <__umoddi3+0xb0>
f0103c54:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103c58:	39 3c 24             	cmp    %edi,(%esp)
f0103c5b:	0f 87 e7 00 00 00    	ja     f0103d48 <__umoddi3+0x148>
f0103c61:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c65:	29 f1                	sub    %esi,%ecx
f0103c67:	19 c7                	sbb    %eax,%edi
f0103c69:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c6d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c71:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c75:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103c79:	83 c4 14             	add    $0x14,%esp
f0103c7c:	5e                   	pop    %esi
f0103c7d:	5f                   	pop    %edi
f0103c7e:	5d                   	pop    %ebp
f0103c7f:	c3                   	ret    
f0103c80:	85 f6                	test   %esi,%esi
f0103c82:	89 f5                	mov    %esi,%ebp
f0103c84:	75 0b                	jne    f0103c91 <__umoddi3+0x91>
f0103c86:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c8b:	31 d2                	xor    %edx,%edx
f0103c8d:	f7 f6                	div    %esi
f0103c8f:	89 c5                	mov    %eax,%ebp
f0103c91:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103c95:	31 d2                	xor    %edx,%edx
f0103c97:	f7 f5                	div    %ebp
f0103c99:	89 c8                	mov    %ecx,%eax
f0103c9b:	f7 f5                	div    %ebp
f0103c9d:	eb 9c                	jmp    f0103c3b <__umoddi3+0x3b>
f0103c9f:	90                   	nop
f0103ca0:	89 c8                	mov    %ecx,%eax
f0103ca2:	89 fa                	mov    %edi,%edx
f0103ca4:	83 c4 14             	add    $0x14,%esp
f0103ca7:	5e                   	pop    %esi
f0103ca8:	5f                   	pop    %edi
f0103ca9:	5d                   	pop    %ebp
f0103caa:	c3                   	ret    
f0103cab:	90                   	nop
f0103cac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cb0:	8b 04 24             	mov    (%esp),%eax
f0103cb3:	be 20 00 00 00       	mov    $0x20,%esi
f0103cb8:	89 e9                	mov    %ebp,%ecx
f0103cba:	29 ee                	sub    %ebp,%esi
f0103cbc:	d3 e2                	shl    %cl,%edx
f0103cbe:	89 f1                	mov    %esi,%ecx
f0103cc0:	d3 e8                	shr    %cl,%eax
f0103cc2:	89 e9                	mov    %ebp,%ecx
f0103cc4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc8:	8b 04 24             	mov    (%esp),%eax
f0103ccb:	09 54 24 04          	or     %edx,0x4(%esp)
f0103ccf:	89 fa                	mov    %edi,%edx
f0103cd1:	d3 e0                	shl    %cl,%eax
f0103cd3:	89 f1                	mov    %esi,%ecx
f0103cd5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cd9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103cdd:	d3 ea                	shr    %cl,%edx
f0103cdf:	89 e9                	mov    %ebp,%ecx
f0103ce1:	d3 e7                	shl    %cl,%edi
f0103ce3:	89 f1                	mov    %esi,%ecx
f0103ce5:	d3 e8                	shr    %cl,%eax
f0103ce7:	89 e9                	mov    %ebp,%ecx
f0103ce9:	09 f8                	or     %edi,%eax
f0103ceb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103cef:	f7 74 24 04          	divl   0x4(%esp)
f0103cf3:	d3 e7                	shl    %cl,%edi
f0103cf5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103cf9:	89 d7                	mov    %edx,%edi
f0103cfb:	f7 64 24 08          	mull   0x8(%esp)
f0103cff:	39 d7                	cmp    %edx,%edi
f0103d01:	89 c1                	mov    %eax,%ecx
f0103d03:	89 14 24             	mov    %edx,(%esp)
f0103d06:	72 2c                	jb     f0103d34 <__umoddi3+0x134>
f0103d08:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103d0c:	72 22                	jb     f0103d30 <__umoddi3+0x130>
f0103d0e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103d12:	29 c8                	sub    %ecx,%eax
f0103d14:	19 d7                	sbb    %edx,%edi
f0103d16:	89 e9                	mov    %ebp,%ecx
f0103d18:	89 fa                	mov    %edi,%edx
f0103d1a:	d3 e8                	shr    %cl,%eax
f0103d1c:	89 f1                	mov    %esi,%ecx
f0103d1e:	d3 e2                	shl    %cl,%edx
f0103d20:	89 e9                	mov    %ebp,%ecx
f0103d22:	d3 ef                	shr    %cl,%edi
f0103d24:	09 d0                	or     %edx,%eax
f0103d26:	89 fa                	mov    %edi,%edx
f0103d28:	83 c4 14             	add    $0x14,%esp
f0103d2b:	5e                   	pop    %esi
f0103d2c:	5f                   	pop    %edi
f0103d2d:	5d                   	pop    %ebp
f0103d2e:	c3                   	ret    
f0103d2f:	90                   	nop
f0103d30:	39 d7                	cmp    %edx,%edi
f0103d32:	75 da                	jne    f0103d0e <__umoddi3+0x10e>
f0103d34:	8b 14 24             	mov    (%esp),%edx
f0103d37:	89 c1                	mov    %eax,%ecx
f0103d39:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103d3d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103d41:	eb cb                	jmp    f0103d0e <__umoddi3+0x10e>
f0103d43:	90                   	nop
f0103d44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d48:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103d4c:	0f 82 0f ff ff ff    	jb     f0103c61 <__umoddi3+0x61>
f0103d52:	e9 1a ff ff ff       	jmp    f0103c71 <__umoddi3+0x71>
