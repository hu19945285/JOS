
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 d0 df 17 f0       	mov    $0xf017dfd0,%eax
f010004b:	2d a1 d0 17 f0       	sub    $0xf017d0a1,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 a1 d0 17 f0 	movl   $0xf017d0a1,(%esp)
f0100063:	e8 e1 4b 00 00       	call   f0104c49 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 dd 04 00 00       	call   f010054a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 51 10 f0 	movl   $0xf0105120,(%esp)
f010007c:	e8 d9 35 00 00       	call   f010365a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 06 12 00 00       	call   f010128c <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 8e 2f 00 00       	call   f0103019 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 48 36 00 00       	call   f01036dd <trap_init>

#if defined(TEST)

	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010009c:	00 
f010009d:	c7 44 24 04 62 78 00 	movl   $0x7862,0x4(%esp)
f01000a4:	00 
f01000a5:	c7 04 24 95 1c 13 f0 	movl   $0xf0131c95,(%esp)
f01000ac:	e8 68 31 00 00       	call   f0103219 <env_create>

	ENV_CREATE(user_hello, ENV_TYPE_USER);

#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b1:	a1 0c d3 17 f0       	mov    0xf017d30c,%eax
f01000b6:	89 04 24             	mov    %eax,(%esp)
f01000b9:	e8 d7 34 00 00       	call   f0103595 <env_run>

f01000be <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000be:	55                   	push   %ebp
f01000bf:	89 e5                	mov    %esp,%ebp
f01000c1:	56                   	push   %esi
f01000c2:	53                   	push   %ebx
f01000c3:	83 ec 10             	sub    $0x10,%esp
f01000c6:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c9:	83 3d c0 df 17 f0 00 	cmpl   $0x0,0xf017dfc0
f01000d0:	75 3d                	jne    f010010f <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000d2:	89 35 c0 df 17 f0    	mov    %esi,0xf017dfc0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d8:	fa                   	cli    
f01000d9:	fc                   	cld    

	va_start(ap, fmt);
f01000da:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01000e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000eb:	c7 04 24 3b 51 10 f0 	movl   $0xf010513b,(%esp)
f01000f2:	e8 63 35 00 00       	call   f010365a <cprintf>
	vcprintf(fmt, ap);
f01000f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000fb:	89 34 24             	mov    %esi,(%esp)
f01000fe:	e8 24 35 00 00       	call   f0103627 <vcprintf>
	cprintf("\n");
f0100103:	c7 04 24 56 60 10 f0 	movl   $0xf0106056,(%esp)
f010010a:	e8 4b 35 00 00       	call   f010365a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010010f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100116:	e8 4a 07 00 00       	call   f0100865 <monitor>
f010011b:	eb f2                	jmp    f010010f <_panic+0x51>

f010011d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011d:	55                   	push   %ebp
f010011e:	89 e5                	mov    %esp,%ebp
f0100120:	53                   	push   %ebx
f0100121:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100124:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100127:	8b 45 0c             	mov    0xc(%ebp),%eax
f010012a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010012e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100131:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100135:	c7 04 24 53 51 10 f0 	movl   $0xf0105153,(%esp)
f010013c:	e8 19 35 00 00       	call   f010365a <cprintf>
	vcprintf(fmt, ap);
f0100141:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100145:	8b 45 10             	mov    0x10(%ebp),%eax
f0100148:	89 04 24             	mov    %eax,(%esp)
f010014b:	e8 d7 34 00 00       	call   f0103627 <vcprintf>
	cprintf("\n");
f0100150:	c7 04 24 56 60 10 f0 	movl   $0xf0106056,(%esp)
f0100157:	e8 fe 34 00 00       	call   f010365a <cprintf>
	va_end(ap);
}
f010015c:	83 c4 14             	add    $0x14,%esp
f010015f:	5b                   	pop    %ebx
f0100160:	5d                   	pop    %ebp
f0100161:	c3                   	ret    
f0100162:	66 90                	xchg   %ax,%ax
f0100164:	66 90                	xchg   %ax,%ax
f0100166:	66 90                	xchg   %ax,%ax
f0100168:	66 90                	xchg   %ax,%ax
f010016a:	66 90                	xchg   %ax,%ax
f010016c:	66 90                	xchg   %ax,%ax
f010016e:	66 90                	xchg   %ax,%ax

f0100170 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100173:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100178:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100179:	a8 01                	test   $0x1,%al
f010017b:	74 08                	je     f0100185 <serial_proc_data+0x15>
f010017d:	b2 f8                	mov    $0xf8,%dl
f010017f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100180:	0f b6 c0             	movzbl %al,%eax
f0100183:	eb 05                	jmp    f010018a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100185:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010018a:	5d                   	pop    %ebp
f010018b:	c3                   	ret    

f010018c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018c:	55                   	push   %ebp
f010018d:	89 e5                	mov    %esp,%ebp
f010018f:	53                   	push   %ebx
f0100190:	83 ec 04             	sub    $0x4,%esp
f0100193:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100195:	eb 2a                	jmp    f01001c1 <cons_intr+0x35>
		if (c == 0)
f0100197:	85 d2                	test   %edx,%edx
f0100199:	74 26                	je     f01001c1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010019b:	a1 e4 d2 17 f0       	mov    0xf017d2e4,%eax
f01001a0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001a3:	89 0d e4 d2 17 f0    	mov    %ecx,0xf017d2e4
f01001a9:	88 90 e0 d0 17 f0    	mov    %dl,-0xfe82f20(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001af:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001b5:	75 0a                	jne    f01001c1 <cons_intr+0x35>
			cons.wpos = 0;
f01001b7:	c7 05 e4 d2 17 f0 00 	movl   $0x0,0xf017d2e4
f01001be:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001c1:	ff d3                	call   *%ebx
f01001c3:	89 c2                	mov    %eax,%edx
f01001c5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001c8:	75 cd                	jne    f0100197 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001ca:	83 c4 04             	add    $0x4,%esp
f01001cd:	5b                   	pop    %ebx
f01001ce:	5d                   	pop    %ebp
f01001cf:	c3                   	ret    

f01001d0 <kbd_proc_data>:
f01001d0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001d6:	a8 01                	test   $0x1,%al
f01001d8:	0f 84 ef 00 00 00    	je     f01002cd <kbd_proc_data+0xfd>
f01001de:	b2 60                	mov    $0x60,%dl
f01001e0:	ec                   	in     (%dx),%al
f01001e1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001e3:	3c e0                	cmp    $0xe0,%al
f01001e5:	75 0d                	jne    f01001f4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001e7:	83 0d c0 d0 17 f0 40 	orl    $0x40,0xf017d0c0
		return 0;
f01001ee:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001f3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001f4:	55                   	push   %ebp
f01001f5:	89 e5                	mov    %esp,%ebp
f01001f7:	53                   	push   %ebx
f01001f8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001fb:	84 c0                	test   %al,%al
f01001fd:	79 37                	jns    f0100236 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ff:	8b 0d c0 d0 17 f0    	mov    0xf017d0c0,%ecx
f0100205:	89 cb                	mov    %ecx,%ebx
f0100207:	83 e3 40             	and    $0x40,%ebx
f010020a:	83 e0 7f             	and    $0x7f,%eax
f010020d:	85 db                	test   %ebx,%ebx
f010020f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100212:	0f b6 d2             	movzbl %dl,%edx
f0100215:	0f b6 82 c0 52 10 f0 	movzbl -0xfefad40(%edx),%eax
f010021c:	83 c8 40             	or     $0x40,%eax
f010021f:	0f b6 c0             	movzbl %al,%eax
f0100222:	f7 d0                	not    %eax
f0100224:	21 c1                	and    %eax,%ecx
f0100226:	89 0d c0 d0 17 f0    	mov    %ecx,0xf017d0c0
		return 0;
f010022c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100231:	e9 9d 00 00 00       	jmp    f01002d3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100236:	8b 0d c0 d0 17 f0    	mov    0xf017d0c0,%ecx
f010023c:	f6 c1 40             	test   $0x40,%cl
f010023f:	74 0e                	je     f010024f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100241:	83 c8 80             	or     $0xffffff80,%eax
f0100244:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100246:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100249:	89 0d c0 d0 17 f0    	mov    %ecx,0xf017d0c0
	}

	shift |= shiftcode[data];
f010024f:	0f b6 d2             	movzbl %dl,%edx
f0100252:	0f b6 82 c0 52 10 f0 	movzbl -0xfefad40(%edx),%eax
f0100259:	0b 05 c0 d0 17 f0    	or     0xf017d0c0,%eax
	shift ^= togglecode[data];
f010025f:	0f b6 8a c0 51 10 f0 	movzbl -0xfefae40(%edx),%ecx
f0100266:	31 c8                	xor    %ecx,%eax
f0100268:	a3 c0 d0 17 f0       	mov    %eax,0xf017d0c0

	c = charcode[shift & (CTL | SHIFT)][data];
f010026d:	89 c1                	mov    %eax,%ecx
f010026f:	83 e1 03             	and    $0x3,%ecx
f0100272:	8b 0c 8d a0 51 10 f0 	mov    -0xfefae60(,%ecx,4),%ecx
f0100279:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010027d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100280:	a8 08                	test   $0x8,%al
f0100282:	74 1b                	je     f010029f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100284:	89 da                	mov    %ebx,%edx
f0100286:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100289:	83 f9 19             	cmp    $0x19,%ecx
f010028c:	77 05                	ja     f0100293 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010028e:	83 eb 20             	sub    $0x20,%ebx
f0100291:	eb 0c                	jmp    f010029f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100293:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100296:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100299:	83 fa 19             	cmp    $0x19,%edx
f010029c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010029f:	f7 d0                	not    %eax
f01002a1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a5:	f6 c2 06             	test   $0x6,%dl
f01002a8:	75 29                	jne    f01002d3 <kbd_proc_data+0x103>
f01002aa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b0:	75 21                	jne    f01002d3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002b2:	c7 04 24 6d 51 10 f0 	movl   $0xf010516d,(%esp)
f01002b9:	e8 9c 33 00 00       	call   f010365a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002be:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002c8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002c9:	89 d8                	mov    %ebx,%eax
f01002cb:	eb 06                	jmp    f01002d3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002d2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002d3:	83 c4 14             	add    $0x14,%esp
f01002d6:	5b                   	pop    %ebx
f01002d7:	5d                   	pop    %ebp
f01002d8:	c3                   	ret    

f01002d9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002d9:	55                   	push   %ebp
f01002da:	89 e5                	mov    %esp,%ebp
f01002dc:	57                   	push   %edi
f01002dd:	56                   	push   %esi
f01002de:	53                   	push   %ebx
f01002df:	83 ec 1c             	sub    $0x1c,%esp
f01002e2:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e4:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002e9:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002ea:	a8 20                	test   $0x20,%al
f01002ec:	75 27                	jne    f0100315 <cons_putc+0x3c>
f01002ee:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01002f3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002f8:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002fd:	89 ca                	mov    %ecx,%edx
f01002ff:	ec                   	in     (%dx),%al
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	89 ca                	mov    %ecx,%edx
f0100305:	ec                   	in     (%dx),%al
f0100306:	89 ca                	mov    %ecx,%edx
f0100308:	ec                   	in     (%dx),%al
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 05                	jne    f0100315 <cons_putc+0x3c>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100310:	83 eb 01             	sub    $0x1,%ebx
f0100313:	75 e8                	jne    f01002fd <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100315:	89 f8                	mov    %edi,%eax
f0100317:	0f b6 c0             	movzbl %al,%eax
f010031a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100323:	b2 79                	mov    $0x79,%dl
f0100325:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100326:	84 c0                	test   %al,%al
f0100328:	78 27                	js     f0100351 <cons_putc+0x78>
f010032a:	bb 00 32 00 00       	mov    $0x3200,%ebx
f010032f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100334:	be 79 03 00 00       	mov    $0x379,%esi
f0100339:	89 ca                	mov    %ecx,%edx
f010033b:	ec                   	in     (%dx),%al
f010033c:	89 ca                	mov    %ecx,%edx
f010033e:	ec                   	in     (%dx),%al
f010033f:	89 ca                	mov    %ecx,%edx
f0100341:	ec                   	in     (%dx),%al
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	89 f2                	mov    %esi,%edx
f0100347:	ec                   	in     (%dx),%al
f0100348:	84 c0                	test   %al,%al
f010034a:	78 05                	js     f0100351 <cons_putc+0x78>
f010034c:	83 eb 01             	sub    $0x1,%ebx
f010034f:	75 e8                	jne    f0100339 <cons_putc+0x60>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100351:	ba 78 03 00 00       	mov    $0x378,%edx
f0100356:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010035a:	ee                   	out    %al,(%dx)
f010035b:	b2 7a                	mov    $0x7a,%dl
f010035d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100362:	ee                   	out    %al,(%dx)
f0100363:	b8 08 00 00 00       	mov    $0x8,%eax
f0100368:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100369:	89 fa                	mov    %edi,%edx
f010036b:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100371:	89 f8                	mov    %edi,%eax
f0100373:	80 cc 07             	or     $0x7,%ah
f0100376:	85 d2                	test   %edx,%edx
f0100378:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010037b:	89 f8                	mov    %edi,%eax
f010037d:	0f b6 c0             	movzbl %al,%eax
f0100380:	83 f8 09             	cmp    $0x9,%eax
f0100383:	74 78                	je     f01003fd <cons_putc+0x124>
f0100385:	83 f8 09             	cmp    $0x9,%eax
f0100388:	7f 0b                	jg     f0100395 <cons_putc+0xbc>
f010038a:	83 f8 08             	cmp    $0x8,%eax
f010038d:	74 18                	je     f01003a7 <cons_putc+0xce>
f010038f:	90                   	nop
f0100390:	e9 9c 00 00 00       	jmp    f0100431 <cons_putc+0x158>
f0100395:	83 f8 0a             	cmp    $0xa,%eax
f0100398:	74 3d                	je     f01003d7 <cons_putc+0xfe>
f010039a:	83 f8 0d             	cmp    $0xd,%eax
f010039d:	8d 76 00             	lea    0x0(%esi),%esi
f01003a0:	74 3d                	je     f01003df <cons_putc+0x106>
f01003a2:	e9 8a 00 00 00       	jmp    f0100431 <cons_putc+0x158>
	case '\b':
		if (crt_pos > 0) {
f01003a7:	0f b7 05 e8 d2 17 f0 	movzwl 0xf017d2e8,%eax
f01003ae:	66 85 c0             	test   %ax,%ax
f01003b1:	0f 84 e5 00 00 00    	je     f010049c <cons_putc+0x1c3>
			crt_pos--;
f01003b7:	83 e8 01             	sub    $0x1,%eax
f01003ba:	66 a3 e8 d2 17 f0    	mov    %ax,0xf017d2e8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c0:	0f b7 c0             	movzwl %ax,%eax
f01003c3:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c8:	83 cf 20             	or     $0x20,%edi
f01003cb:	8b 15 ec d2 17 f0    	mov    0xf017d2ec,%edx
f01003d1:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003d5:	eb 78                	jmp    f010044f <cons_putc+0x176>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d7:	66 83 05 e8 d2 17 f0 	addw   $0x50,0xf017d2e8
f01003de:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003df:	0f b7 05 e8 d2 17 f0 	movzwl 0xf017d2e8,%eax
f01003e6:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ec:	c1 e8 16             	shr    $0x16,%eax
f01003ef:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003f2:	c1 e0 04             	shl    $0x4,%eax
f01003f5:	66 a3 e8 d2 17 f0    	mov    %ax,0xf017d2e8
f01003fb:	eb 52                	jmp    f010044f <cons_putc+0x176>
		break;
	case '\t':
		cons_putc(' ');
f01003fd:	b8 20 00 00 00       	mov    $0x20,%eax
f0100402:	e8 d2 fe ff ff       	call   f01002d9 <cons_putc>
		cons_putc(' ');
f0100407:	b8 20 00 00 00       	mov    $0x20,%eax
f010040c:	e8 c8 fe ff ff       	call   f01002d9 <cons_putc>
		cons_putc(' ');
f0100411:	b8 20 00 00 00       	mov    $0x20,%eax
f0100416:	e8 be fe ff ff       	call   f01002d9 <cons_putc>
		cons_putc(' ');
f010041b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100420:	e8 b4 fe ff ff       	call   f01002d9 <cons_putc>
		cons_putc(' ');
f0100425:	b8 20 00 00 00       	mov    $0x20,%eax
f010042a:	e8 aa fe ff ff       	call   f01002d9 <cons_putc>
f010042f:	eb 1e                	jmp    f010044f <cons_putc+0x176>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100431:	0f b7 05 e8 d2 17 f0 	movzwl 0xf017d2e8,%eax
f0100438:	8d 50 01             	lea    0x1(%eax),%edx
f010043b:	66 89 15 e8 d2 17 f0 	mov    %dx,0xf017d2e8
f0100442:	0f b7 c0             	movzwl %ax,%eax
f0100445:	8b 15 ec d2 17 f0    	mov    0xf017d2ec,%edx
f010044b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010044f:	66 81 3d e8 d2 17 f0 	cmpw   $0x7cf,0xf017d2e8
f0100456:	cf 07 
f0100458:	76 42                	jbe    f010049c <cons_putc+0x1c3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010045a:	a1 ec d2 17 f0       	mov    0xf017d2ec,%eax
f010045f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100466:	00 
f0100467:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010046d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100471:	89 04 24             	mov    %eax,(%esp)
f0100474:	e8 1d 48 00 00       	call   f0104c96 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100479:	8b 15 ec d2 17 f0    	mov    0xf017d2ec,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010047f:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100484:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048a:	83 c0 01             	add    $0x1,%eax
f010048d:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100492:	75 f0                	jne    f0100484 <cons_putc+0x1ab>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100494:	66 83 2d e8 d2 17 f0 	subw   $0x50,0xf017d2e8
f010049b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010049c:	8b 0d f0 d2 17 f0    	mov    0xf017d2f0,%ecx
f01004a2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a7:	89 ca                	mov    %ecx,%edx
f01004a9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004aa:	0f b7 1d e8 d2 17 f0 	movzwl 0xf017d2e8,%ebx
f01004b1:	8d 71 01             	lea    0x1(%ecx),%esi
f01004b4:	89 d8                	mov    %ebx,%eax
f01004b6:	66 c1 e8 08          	shr    $0x8,%ax
f01004ba:	89 f2                	mov    %esi,%edx
f01004bc:	ee                   	out    %al,(%dx)
f01004bd:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004c2:	89 ca                	mov    %ecx,%edx
f01004c4:	ee                   	out    %al,(%dx)
f01004c5:	89 d8                	mov    %ebx,%eax
f01004c7:	89 f2                	mov    %esi,%edx
f01004c9:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ca:	83 c4 1c             	add    $0x1c,%esp
f01004cd:	5b                   	pop    %ebx
f01004ce:	5e                   	pop    %esi
f01004cf:	5f                   	pop    %edi
f01004d0:	5d                   	pop    %ebp
f01004d1:	c3                   	ret    

f01004d2 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004d2:	83 3d f4 d2 17 f0 00 	cmpl   $0x0,0xf017d2f4
f01004d9:	74 11                	je     f01004ec <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004db:	55                   	push   %ebp
f01004dc:	89 e5                	mov    %esp,%ebp
f01004de:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004e1:	b8 70 01 10 f0       	mov    $0xf0100170,%eax
f01004e6:	e8 a1 fc ff ff       	call   f010018c <cons_intr>
}
f01004eb:	c9                   	leave  
f01004ec:	f3 c3                	repz ret 

f01004ee <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004ee:	55                   	push   %ebp
f01004ef:	89 e5                	mov    %esp,%ebp
f01004f1:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004f4:	b8 d0 01 10 f0       	mov    $0xf01001d0,%eax
f01004f9:	e8 8e fc ff ff       	call   f010018c <cons_intr>
}
f01004fe:	c9                   	leave  
f01004ff:	c3                   	ret    

f0100500 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100506:	e8 c7 ff ff ff       	call   f01004d2 <serial_intr>
	kbd_intr();
f010050b:	e8 de ff ff ff       	call   f01004ee <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100510:	a1 e0 d2 17 f0       	mov    0xf017d2e0,%eax
f0100515:	3b 05 e4 d2 17 f0    	cmp    0xf017d2e4,%eax
f010051b:	74 26                	je     f0100543 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010051d:	8d 50 01             	lea    0x1(%eax),%edx
f0100520:	89 15 e0 d2 17 f0    	mov    %edx,0xf017d2e0
f0100526:	0f b6 88 e0 d0 17 f0 	movzbl -0xfe82f20(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010052d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100535:	75 11                	jne    f0100548 <cons_getc+0x48>
			cons.rpos = 0;
f0100537:	c7 05 e0 d2 17 f0 00 	movl   $0x0,0xf017d2e0
f010053e:	00 00 00 
f0100541:	eb 05                	jmp    f0100548 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100543:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	57                   	push   %edi
f010054e:	56                   	push   %esi
f010054f:	53                   	push   %ebx
f0100550:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100553:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010055a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100561:	5a a5 
	if (*cp != 0xA55A) {
f0100563:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010056a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010056e:	74 11                	je     f0100581 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100570:	c7 05 f0 d2 17 f0 b4 	movl   $0x3b4,0xf017d2f0
f0100577:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010057a:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010057f:	eb 16                	jmp    f0100597 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100581:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100588:	c7 05 f0 d2 17 f0 d4 	movl   $0x3d4,0xf017d2f0
f010058f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100592:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100597:	8b 0d f0 d2 17 f0    	mov    0xf017d2f0,%ecx
f010059d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005a2:	89 ca                	mov    %ecx,%edx
f01005a4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a5:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a8:	89 da                	mov    %ebx,%edx
f01005aa:	ec                   	in     (%dx),%al
f01005ab:	0f b6 f0             	movzbl %al,%esi
f01005ae:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b6:	89 ca                	mov    %ecx,%edx
f01005b8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b9:	89 da                	mov    %ebx,%edx
f01005bb:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005bc:	89 3d ec d2 17 f0    	mov    %edi,0xf017d2ec
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005c2:	0f b6 d8             	movzbl %al,%ebx
f01005c5:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005c7:	66 89 35 e8 d2 17 f0 	mov    %si,0xf017d2e8
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ce:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01005d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d8:	ee                   	out    %al,(%dx)
f01005d9:	b2 fb                	mov    $0xfb,%dl
f01005db:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005e0:	ee                   	out    %al,(%dx)
f01005e1:	b2 f8                	mov    $0xf8,%dl
f01005e3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005e8:	ee                   	out    %al,(%dx)
f01005e9:	b2 f9                	mov    $0xf9,%dl
f01005eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f0:	ee                   	out    %al,(%dx)
f01005f1:	b2 fb                	mov    $0xfb,%dl
f01005f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01005f8:	ee                   	out    %al,(%dx)
f01005f9:	b2 fc                	mov    $0xfc,%dl
f01005fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100600:	ee                   	out    %al,(%dx)
f0100601:	b2 f9                	mov    $0xf9,%dl
f0100603:	b8 01 00 00 00       	mov    $0x1,%eax
f0100608:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100609:	b2 fd                	mov    $0xfd,%dl
f010060b:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060c:	3c ff                	cmp    $0xff,%al
f010060e:	0f 95 c1             	setne  %cl
f0100611:	0f b6 c9             	movzbl %cl,%ecx
f0100614:	89 0d f4 d2 17 f0    	mov    %ecx,0xf017d2f4
f010061a:	b2 fa                	mov    $0xfa,%dl
f010061c:	ec                   	in     (%dx),%al
f010061d:	b2 f8                	mov    $0xf8,%dl
f010061f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100620:	85 c9                	test   %ecx,%ecx
f0100622:	75 0c                	jne    f0100630 <cons_init+0xe6>
		cprintf("Serial port does not exist!\n");
f0100624:	c7 04 24 79 51 10 f0 	movl   $0xf0105179,(%esp)
f010062b:	e8 2a 30 00 00       	call   f010365a <cprintf>
}
f0100630:	83 c4 1c             	add    $0x1c,%esp
f0100633:	5b                   	pop    %ebx
f0100634:	5e                   	pop    %esi
f0100635:	5f                   	pop    %edi
f0100636:	5d                   	pop    %ebp
f0100637:	c3                   	ret    

f0100638 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100638:	55                   	push   %ebp
f0100639:	89 e5                	mov    %esp,%ebp
f010063b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010063e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100641:	e8 93 fc ff ff       	call   f01002d9 <cons_putc>
}
f0100646:	c9                   	leave  
f0100647:	c3                   	ret    

f0100648 <getchar>:

int
getchar(void)
{
f0100648:	55                   	push   %ebp
f0100649:	89 e5                	mov    %esp,%ebp
f010064b:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010064e:	e8 ad fe ff ff       	call   f0100500 <cons_getc>
f0100653:	85 c0                	test   %eax,%eax
f0100655:	74 f7                	je     f010064e <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100657:	c9                   	leave  
f0100658:	c3                   	ret    

f0100659 <iscons>:

int
iscons(int fdnum)
{
f0100659:	55                   	push   %ebp
f010065a:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100661:	5d                   	pop    %ebp
f0100662:	c3                   	ret    
f0100663:	66 90                	xchg   %ax,%ax
f0100665:	66 90                	xchg   %ax,%ax
f0100667:	66 90                	xchg   %ax,%ax
f0100669:	66 90                	xchg   %ax,%ax
f010066b:	66 90                	xchg   %ax,%ax
f010066d:	66 90                	xchg   %ax,%ax
f010066f:	90                   	nop

f0100670 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100670:	55                   	push   %ebp
f0100671:	89 e5                	mov    %esp,%ebp
f0100673:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100676:	c7 44 24 08 c0 53 10 	movl   $0xf01053c0,0x8(%esp)
f010067d:	f0 
f010067e:	c7 44 24 04 de 53 10 	movl   $0xf01053de,0x4(%esp)
f0100685:	f0 
f0100686:	c7 04 24 e3 53 10 f0 	movl   $0xf01053e3,(%esp)
f010068d:	e8 c8 2f 00 00       	call   f010365a <cprintf>
f0100692:	c7 44 24 08 84 54 10 	movl   $0xf0105484,0x8(%esp)
f0100699:	f0 
f010069a:	c7 44 24 04 ec 53 10 	movl   $0xf01053ec,0x4(%esp)
f01006a1:	f0 
f01006a2:	c7 04 24 e3 53 10 f0 	movl   $0xf01053e3,(%esp)
f01006a9:	e8 ac 2f 00 00       	call   f010365a <cprintf>
f01006ae:	c7 44 24 08 ac 54 10 	movl   $0xf01054ac,0x8(%esp)
f01006b5:	f0 
f01006b6:	c7 44 24 04 f5 53 10 	movl   $0xf01053f5,0x4(%esp)
f01006bd:	f0 
f01006be:	c7 04 24 e3 53 10 f0 	movl   $0xf01053e3,(%esp)
f01006c5:	e8 90 2f 00 00       	call   f010365a <cprintf>
	return 0;
}
f01006ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cf:	c9                   	leave  
f01006d0:	c3                   	ret    

f01006d1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d1:	55                   	push   %ebp
f01006d2:	89 e5                	mov    %esp,%ebp
f01006d4:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006d7:	c7 04 24 ff 53 10 f0 	movl   $0xf01053ff,(%esp)
f01006de:	e8 77 2f 00 00       	call   f010365a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e3:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ea:	00 
f01006eb:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006f2:	f0 
f01006f3:	c7 04 24 d8 54 10 f0 	movl   $0xf01054d8,(%esp)
f01006fa:	e8 5b 2f 00 00       	call   f010365a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ff:	c7 44 24 08 07 51 10 	movl   $0x105107,0x8(%esp)
f0100706:	00 
f0100707:	c7 44 24 04 07 51 10 	movl   $0xf0105107,0x4(%esp)
f010070e:	f0 
f010070f:	c7 04 24 fc 54 10 f0 	movl   $0xf01054fc,(%esp)
f0100716:	e8 3f 2f 00 00       	call   f010365a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010071b:	c7 44 24 08 a1 d0 17 	movl   $0x17d0a1,0x8(%esp)
f0100722:	00 
f0100723:	c7 44 24 04 a1 d0 17 	movl   $0xf017d0a1,0x4(%esp)
f010072a:	f0 
f010072b:	c7 04 24 20 55 10 f0 	movl   $0xf0105520,(%esp)
f0100732:	e8 23 2f 00 00       	call   f010365a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100737:	c7 44 24 08 d0 df 17 	movl   $0x17dfd0,0x8(%esp)
f010073e:	00 
f010073f:	c7 44 24 04 d0 df 17 	movl   $0xf017dfd0,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 44 55 10 f0 	movl   $0xf0105544,(%esp)
f010074e:	e8 07 2f 00 00       	call   f010365a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100753:	b8 cf e3 17 f0       	mov    $0xf017e3cf,%eax
f0100758:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010075d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100763:	85 c0                	test   %eax,%eax
f0100765:	0f 48 c2             	cmovs  %edx,%eax
f0100768:	c1 f8 0a             	sar    $0xa,%eax
f010076b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076f:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f0100776:	e8 df 2e 00 00       	call   f010365a <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010077b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100780:	c9                   	leave  
f0100781:	c3                   	ret    

f0100782 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100782:	55                   	push   %ebp
f0100783:	89 e5                	mov    %esp,%ebp
f0100785:	57                   	push   %edi
f0100786:	56                   	push   %esi
f0100787:	53                   	push   %ebx
f0100788:	83 ec 1c             	sub    $0x1c,%esp
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010078b:	8b 75 04             	mov    0x4(%ebp),%esi

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010078e:	89 ef                	mov    %ebp,%edi
f0100790:	89 fb                	mov    %edi,%ebx
	// Your code here.
	//Read the values of eip and ebp
	uint32_t eip=read_eip();
	uint32_t ebp=read_ebp();
	//Print current eip and ebp
	cprintf("Stack backtrace:\r\n");
f0100792:	c7 04 24 18 54 10 f0 	movl   $0xf0105418,(%esp)
f0100799:	e8 bc 2e 00 00       	call   f010365a <cprintf>
	cprintf(" ebp:%x eip:%x ",ebp,eip);
f010079e:	89 74 24 08          	mov    %esi,0x8(%esp)
f01007a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007a6:	c7 04 24 2b 54 10 f0 	movl   $0xf010542b,(%esp)
f01007ad:	e8 a8 2e 00 00       	call   f010365a <cprintf>
	//Print current fuction's args	
	uint32_t esp=ebp + 0x8;
f01007b2:	8d 77 08             	lea    0x8(%edi),%esi
	int i;
	cprintf("args:");
f01007b5:	c7 04 24 3b 54 10 f0 	movl   $0xf010543b,(%esp)
f01007bc:	e8 99 2e 00 00       	call   f010365a <cprintf>
f01007c1:	8d 47 1c             	lea    0x1c(%edi),%eax
f01007c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0;i<5;i++){
		cprintf("%x ",*(uint32_t *)(esp));
f01007c7:	8b 06                	mov    (%esi),%eax
f01007c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007cd:	c7 04 24 37 54 10 f0 	movl   $0xf0105437,(%esp)
f01007d4:	e8 81 2e 00 00       	call   f010365a <cprintf>
		esp=esp+0x4;	
f01007d9:	83 c6 04             	add    $0x4,%esi
	cprintf(" ebp:%x eip:%x ",ebp,eip);
	//Print current fuction's args	
	uint32_t esp=ebp + 0x8;
	int i;
	cprintf("args:");
	for(i=0;i<5;i++){
f01007dc:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01007df:	75 e6                	jne    f01007c7 <mon_backtrace+0x45>
		cprintf("%x ",*(uint32_t *)(esp));
		esp=esp+0x4;	
	}
	cprintf("\r\n");
f01007e1:	c7 04 24 55 60 10 f0 	movl   $0xf0106055,(%esp)
f01007e8:	e8 6d 2e 00 00       	call   f010365a <cprintf>
	//Print fuction before
	while(ebp!=0){
f01007ed:	85 ff                	test   %edi,%edi
f01007ef:	74 67                	je     f0100858 <mon_backtrace+0xd6>
		esp=ebp;
		if((ebp=*(uint32_t *)(esp))==0){
f01007f1:	8b 3f                	mov    (%edi),%edi
f01007f3:	85 ff                	test   %edi,%edi
f01007f5:	75 0f                	jne    f0100806 <mon_backtrace+0x84>
f01007f7:	eb 5f                	jmp    f0100858 <mon_backtrace+0xd6>
f01007f9:	8b 07                	mov    (%edi),%eax
f01007fb:	85 c0                	test   %eax,%eax
f01007fd:	8d 76 00             	lea    0x0(%esi),%esi
f0100800:	74 56                	je     f0100858 <mon_backtrace+0xd6>
f0100802:	89 fb                	mov    %edi,%ebx
f0100804:	89 c7                	mov    %eax,%edi
			break;
		}
		esp=esp+0x4;
		eip=*(uint32_t *)(esp);
		esp=esp+0x4;
f0100806:	8d 73 08             	lea    0x8(%ebx),%esi
		cprintf(" ebp:%x eip:%x ",ebp,eip);
f0100809:	8b 43 04             	mov    0x4(%ebx),%eax
f010080c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100810:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100814:	c7 04 24 2b 54 10 f0 	movl   $0xf010542b,(%esp)
f010081b:	e8 3a 2e 00 00       	call   f010365a <cprintf>
		cprintf("args:");
f0100820:	c7 04 24 3b 54 10 f0 	movl   $0xf010543b,(%esp)
f0100827:	e8 2e 2e 00 00       	call   f010365a <cprintf>
f010082c:	83 c3 1c             	add    $0x1c,%ebx
		for(i=0;i<5;i++){
			cprintf(" %x",*(uint32_t *)(esp));
f010082f:	8b 06                	mov    (%esi),%eax
f0100831:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100835:	c7 04 24 41 54 10 f0 	movl   $0xf0105441,(%esp)
f010083c:	e8 19 2e 00 00       	call   f010365a <cprintf>
			esp=esp+0x4;	
f0100841:	83 c6 04             	add    $0x4,%esi
		esp=esp+0x4;
		eip=*(uint32_t *)(esp);
		esp=esp+0x4;
		cprintf(" ebp:%x eip:%x ",ebp,eip);
		cprintf("args:");
		for(i=0;i<5;i++){
f0100844:	39 de                	cmp    %ebx,%esi
f0100846:	75 e7                	jne    f010082f <mon_backtrace+0xad>
			cprintf(" %x",*(uint32_t *)(esp));
			esp=esp+0x4;	
		}
		cprintf("\r\n");	
f0100848:	c7 04 24 55 60 10 f0 	movl   $0xf0106055,(%esp)
f010084f:	e8 06 2e 00 00       	call   f010365a <cprintf>
		cprintf("%x ",*(uint32_t *)(esp));
		esp=esp+0x4;	
	}
	cprintf("\r\n");
	//Print fuction before
	while(ebp!=0){
f0100854:	85 ff                	test   %edi,%edi
f0100856:	75 a1                	jne    f01007f9 <mon_backtrace+0x77>
			esp=esp+0x4;	
		}
		cprintf("\r\n");	
		}
	return 0;
}
f0100858:	b8 00 00 00 00       	mov    $0x0,%eax
f010085d:	83 c4 1c             	add    $0x1c,%esp
f0100860:	5b                   	pop    %ebx
f0100861:	5e                   	pop    %esi
f0100862:	5f                   	pop    %edi
f0100863:	5d                   	pop    %ebp
f0100864:	c3                   	ret    

f0100865 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100865:	55                   	push   %ebp
f0100866:	89 e5                	mov    %esp,%ebp
f0100868:	57                   	push   %edi
f0100869:	56                   	push   %esi
f010086a:	53                   	push   %ebx
f010086b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010086e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100875:	e8 e0 2d 00 00       	call   f010365a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010087a:	c7 04 24 b8 55 10 f0 	movl   $0xf01055b8,(%esp)
f0100881:	e8 d4 2d 00 00       	call   f010365a <cprintf>

	if (tf != NULL)
f0100886:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010088a:	74 0b                	je     f0100897 <monitor+0x32>
		print_trapframe(tf);
f010088c:	8b 45 08             	mov    0x8(%ebp),%eax
f010088f:	89 04 24             	mov    %eax,(%esp)
f0100892:	e8 28 32 00 00       	call   f0103abf <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100897:	c7 04 24 45 54 10 f0 	movl   $0xf0105445,(%esp)
f010089e:	e8 cd 40 00 00       	call   f0104970 <readline>
f01008a3:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	74 ee                	je     f0100897 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008a9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008b0:	be 00 00 00 00       	mov    $0x0,%esi
f01008b5:	eb 0a                	jmp    f01008c1 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008b7:	c6 03 00             	movb   $0x0,(%ebx)
f01008ba:	89 f7                	mov    %esi,%edi
f01008bc:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008bf:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008c1:	0f b6 03             	movzbl (%ebx),%eax
f01008c4:	84 c0                	test   %al,%al
f01008c6:	74 6a                	je     f0100932 <monitor+0xcd>
f01008c8:	0f be c0             	movsbl %al,%eax
f01008cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cf:	c7 04 24 49 54 10 f0 	movl   $0xf0105449,(%esp)
f01008d6:	e8 0e 43 00 00       	call   f0104be9 <strchr>
f01008db:	85 c0                	test   %eax,%eax
f01008dd:	75 d8                	jne    f01008b7 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f01008df:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008e2:	74 4e                	je     f0100932 <monitor+0xcd>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008e4:	83 fe 0f             	cmp    $0xf,%esi
f01008e7:	75 16                	jne    f01008ff <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008e9:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008f0:	00 
f01008f1:	c7 04 24 4e 54 10 f0 	movl   $0xf010544e,(%esp)
f01008f8:	e8 5d 2d 00 00       	call   f010365a <cprintf>
f01008fd:	eb 98                	jmp    f0100897 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f01008ff:	8d 7e 01             	lea    0x1(%esi),%edi
f0100902:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100906:	0f b6 03             	movzbl (%ebx),%eax
f0100909:	84 c0                	test   %al,%al
f010090b:	75 0c                	jne    f0100919 <monitor+0xb4>
f010090d:	eb b0                	jmp    f01008bf <monitor+0x5a>
			buf++;
f010090f:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100912:	0f b6 03             	movzbl (%ebx),%eax
f0100915:	84 c0                	test   %al,%al
f0100917:	74 a6                	je     f01008bf <monitor+0x5a>
f0100919:	0f be c0             	movsbl %al,%eax
f010091c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100920:	c7 04 24 49 54 10 f0 	movl   $0xf0105449,(%esp)
f0100927:	e8 bd 42 00 00       	call   f0104be9 <strchr>
f010092c:	85 c0                	test   %eax,%eax
f010092e:	74 df                	je     f010090f <monitor+0xaa>
f0100930:	eb 8d                	jmp    f01008bf <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100932:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100939:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010093a:	85 f6                	test   %esi,%esi
f010093c:	0f 84 55 ff ff ff    	je     f0100897 <monitor+0x32>
f0100942:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100947:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010094a:	8b 04 85 e0 55 10 f0 	mov    -0xfefaa20(,%eax,4),%eax
f0100951:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100955:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100958:	89 04 24             	mov    %eax,(%esp)
f010095b:	e8 05 42 00 00       	call   f0104b65 <strcmp>
f0100960:	85 c0                	test   %eax,%eax
f0100962:	75 24                	jne    f0100988 <monitor+0x123>
			return commands[i].func(argc, argv, tf);
f0100964:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100967:	8b 55 08             	mov    0x8(%ebp),%edx
f010096a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010096e:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100971:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100975:	89 34 24             	mov    %esi,(%esp)
f0100978:	ff 14 85 e8 55 10 f0 	call   *-0xfefaa18(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010097f:	85 c0                	test   %eax,%eax
f0100981:	78 27                	js     f01009aa <monitor+0x145>
f0100983:	e9 0f ff ff ff       	jmp    f0100897 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100988:	83 c3 01             	add    $0x1,%ebx
f010098b:	83 fb 03             	cmp    $0x3,%ebx
f010098e:	66 90                	xchg   %ax,%ax
f0100990:	75 b5                	jne    f0100947 <monitor+0xe2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100992:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100995:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100999:	c7 04 24 6b 54 10 f0 	movl   $0xf010546b,(%esp)
f01009a0:	e8 b5 2c 00 00       	call   f010365a <cprintf>
f01009a5:	e9 ed fe ff ff       	jmp    f0100897 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009aa:	83 c4 5c             	add    $0x5c,%esp
f01009ad:	5b                   	pop    %ebx
f01009ae:	5e                   	pop    %esi
f01009af:	5f                   	pop    %edi
f01009b0:	5d                   	pop    %ebp
f01009b1:	c3                   	ret    

f01009b2 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01009b2:	55                   	push   %ebp
f01009b3:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01009b5:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01009b8:	5d                   	pop    %ebp
f01009b9:	c3                   	ret    
f01009ba:	66 90                	xchg   %ax,%ax
f01009bc:	66 90                	xchg   %ax,%ax
f01009be:	66 90                	xchg   %ax,%ax

f01009c0 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009c0:	55                   	push   %ebp
f01009c1:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009c3:	83 3d f8 d2 17 f0 00 	cmpl   $0x0,0xf017d2f8
f01009ca:	75 11                	jne    f01009dd <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009cc:	ba cf ef 17 f0       	mov    $0xf017efcf,%edx
f01009d1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009d7:	89 15 f8 d2 17 f0    	mov    %edx,0xf017d2f8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result=nextfree;
f01009dd:	8b 15 f8 d2 17 f0    	mov    0xf017d2f8,%edx
	nextfree+=ROUNDUP(n,PGSIZE);
f01009e3:	05 ff 0f 00 00       	add    $0xfff,%eax
f01009e8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009ed:	01 d0                	add    %edx,%eax
f01009ef:	a3 f8 d2 17 f0       	mov    %eax,0xf017d2f8
    return result;
}
f01009f4:	89 d0                	mov    %edx,%eax
f01009f6:	5d                   	pop    %ebp
f01009f7:	c3                   	ret    

f01009f8 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01009f8:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f01009fe:	c1 f8 03             	sar    $0x3,%eax
f0100a01:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a04:	89 c2                	mov    %eax,%edx
f0100a06:	c1 ea 0c             	shr    $0xc,%edx
f0100a09:	3b 15 c4 df 17 f0    	cmp    0xf017dfc4,%edx
f0100a0f:	72 26                	jb     f0100a37 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct Page *pp)
{
f0100a11:	55                   	push   %ebp
f0100a12:	89 e5                	mov    %esp,%ebp
f0100a14:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a17:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a1b:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100a22:	f0 
f0100a23:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100a2a:	00 
f0100a2b:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0100a32:	e8 87 f6 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0100a37:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
}
f0100a3c:	c3                   	ret    

f0100a3d <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a3d:	89 d1                	mov    %edx,%ecx
f0100a3f:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a42:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a45:	a8 01                	test   $0x1,%al
f0100a47:	74 5d                	je     f0100aa6 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a4e:	89 c1                	mov    %eax,%ecx
f0100a50:	c1 e9 0c             	shr    $0xc,%ecx
f0100a53:	3b 0d c4 df 17 f0    	cmp    0xf017dfc4,%ecx
f0100a59:	72 26                	jb     f0100a81 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a5b:	55                   	push   %ebp
f0100a5c:	89 e5                	mov    %esp,%ebp
f0100a5e:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a61:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a65:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100a6c:	f0 
f0100a6d:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0100a74:	00 
f0100a75:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100a7c:	e8 3d f6 ff ff       	call   f01000be <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a81:	c1 ea 0c             	shr    $0xc,%edx
f0100a84:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a8a:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a91:	89 c2                	mov    %eax,%edx
f0100a93:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a96:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a9b:	85 d2                	test   %edx,%edx
f0100a9d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100aa2:	0f 44 c2             	cmove  %edx,%eax
f0100aa5:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100aa6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100aab:	c3                   	ret    

f0100aac <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100aac:	55                   	push   %ebp
f0100aad:	89 e5                	mov    %esp,%ebp
f0100aaf:	57                   	push   %edi
f0100ab0:	56                   	push   %esi
f0100ab1:	53                   	push   %ebx
f0100ab2:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ab5:	85 c0                	test   %eax,%eax
f0100ab7:	0f 85 35 03 00 00    	jne    f0100df2 <check_page_free_list+0x346>
f0100abd:	e9 42 03 00 00       	jmp    f0100e04 <check_page_free_list+0x358>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100ac2:	c7 44 24 08 28 56 10 	movl   $0xf0105628,0x8(%esp)
f0100ac9:	f0 
f0100aca:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0100ad1:	00 
f0100ad2:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100ad9:	e8 e0 f5 ff ff       	call   f01000be <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100ade:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ae1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ae4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ae7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aea:	89 c2                	mov    %eax,%edx
f0100aec:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100af2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100af8:	0f 95 c2             	setne  %dl
f0100afb:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100afe:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b02:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b04:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b08:	8b 00                	mov    (%eax),%eax
f0100b0a:	85 c0                	test   %eax,%eax
f0100b0c:	75 dc                	jne    f0100aea <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b0e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b11:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b17:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b1a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b1d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b1f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b22:	a3 00 d3 17 f0       	mov    %eax,0xf017d300
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b27:	89 c3                	mov    %eax,%ebx
f0100b29:	85 c0                	test   %eax,%eax
f0100b2b:	74 6c                	je     f0100b99 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b2d:	be 01 00 00 00       	mov    $0x1,%esi
f0100b32:	89 d8                	mov    %ebx,%eax
f0100b34:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f0100b3a:	c1 f8 03             	sar    $0x3,%eax
f0100b3d:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b40:	89 c2                	mov    %eax,%edx
f0100b42:	c1 ea 16             	shr    $0x16,%edx
f0100b45:	39 f2                	cmp    %esi,%edx
f0100b47:	73 4a                	jae    f0100b93 <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b49:	89 c2                	mov    %eax,%edx
f0100b4b:	c1 ea 0c             	shr    $0xc,%edx
f0100b4e:	3b 15 c4 df 17 f0    	cmp    0xf017dfc4,%edx
f0100b54:	72 20                	jb     f0100b76 <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b56:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b5a:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100b61:	f0 
f0100b62:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b69:	00 
f0100b6a:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0100b71:	e8 48 f5 ff ff       	call   f01000be <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b76:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b7d:	00 
f0100b7e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b85:	00 
	return (void *)(pa + KERNBASE);
f0100b86:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b8b:	89 04 24             	mov    %eax,(%esp)
f0100b8e:	e8 b6 40 00 00       	call   f0104c49 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b93:	8b 1b                	mov    (%ebx),%ebx
f0100b95:	85 db                	test   %ebx,%ebx
f0100b97:	75 99                	jne    f0100b32 <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b99:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b9e:	e8 1d fe ff ff       	call   f01009c0 <boot_alloc>
f0100ba3:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ba6:	8b 15 00 d3 17 f0    	mov    0xf017d300,%edx
f0100bac:	85 d2                	test   %edx,%edx
f0100bae:	0f 84 f2 01 00 00    	je     f0100da6 <check_page_free_list+0x2fa>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bb4:	8b 1d cc df 17 f0    	mov    0xf017dfcc,%ebx
f0100bba:	39 da                	cmp    %ebx,%edx
f0100bbc:	72 3f                	jb     f0100bfd <check_page_free_list+0x151>
		assert(pp < pages + npages);
f0100bbe:	a1 c4 df 17 f0       	mov    0xf017dfc4,%eax
f0100bc3:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100bc6:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100bc9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100bcc:	39 c2                	cmp    %eax,%edx
f0100bce:	73 56                	jae    f0100c26 <check_page_free_list+0x17a>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bd0:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100bd3:	89 d0                	mov    %edx,%eax
f0100bd5:	29 d8                	sub    %ebx,%eax
f0100bd7:	a8 07                	test   $0x7,%al
f0100bd9:	75 78                	jne    f0100c53 <check_page_free_list+0x1a7>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bdb:	c1 f8 03             	sar    $0x3,%eax
f0100bde:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100be1:	85 c0                	test   %eax,%eax
f0100be3:	0f 84 98 00 00 00    	je     f0100c81 <check_page_free_list+0x1d5>
		assert(page2pa(pp) != IOPHYSMEM);
f0100be9:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bee:	0f 85 dc 00 00 00    	jne    f0100cd0 <check_page_free_list+0x224>
f0100bf4:	e9 b3 00 00 00       	jmp    f0100cac <check_page_free_list+0x200>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bf9:	39 d3                	cmp    %edx,%ebx
f0100bfb:	76 24                	jbe    f0100c21 <check_page_free_list+0x175>
f0100bfd:	c7 44 24 0c 97 5d 10 	movl   $0xf0105d97,0xc(%esp)
f0100c04:	f0 
f0100c05:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100c0c:	f0 
f0100c0d:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0100c14:	00 
f0100c15:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100c1c:	e8 9d f4 ff ff       	call   f01000be <_panic>
		assert(pp < pages + npages);
f0100c21:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c24:	72 24                	jb     f0100c4a <check_page_free_list+0x19e>
f0100c26:	c7 44 24 0c b8 5d 10 	movl   $0xf0105db8,0xc(%esp)
f0100c2d:	f0 
f0100c2e:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100c35:	f0 
f0100c36:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0100c3d:	00 
f0100c3e:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100c45:	e8 74 f4 ff ff       	call   f01000be <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c4a:	89 d0                	mov    %edx,%eax
f0100c4c:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c4f:	a8 07                	test   $0x7,%al
f0100c51:	74 24                	je     f0100c77 <check_page_free_list+0x1cb>
f0100c53:	c7 44 24 0c 4c 56 10 	movl   $0xf010564c,0xc(%esp)
f0100c5a:	f0 
f0100c5b:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100c62:	f0 
f0100c63:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0100c6a:	00 
f0100c6b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100c72:	e8 47 f4 ff ff       	call   f01000be <_panic>
f0100c77:	c1 f8 03             	sar    $0x3,%eax
f0100c7a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c7d:	85 c0                	test   %eax,%eax
f0100c7f:	75 24                	jne    f0100ca5 <check_page_free_list+0x1f9>
f0100c81:	c7 44 24 0c cc 5d 10 	movl   $0xf0105dcc,0xc(%esp)
f0100c88:	f0 
f0100c89:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100c90:	f0 
f0100c91:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100c98:	00 
f0100c99:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100ca0:	e8 19 f4 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ca5:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100caa:	75 2e                	jne    f0100cda <check_page_free_list+0x22e>
f0100cac:	c7 44 24 0c dd 5d 10 	movl   $0xf0105ddd,0xc(%esp)
f0100cb3:	f0 
f0100cb4:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100cbb:	f0 
f0100cbc:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0100cc3:	00 
f0100cc4:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100ccb:	e8 ee f3 ff ff       	call   f01000be <_panic>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cd0:	be 00 00 00 00       	mov    $0x0,%esi
f0100cd5:	bf 00 00 00 00       	mov    $0x0,%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cda:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cdf:	75 24                	jne    f0100d05 <check_page_free_list+0x259>
f0100ce1:	c7 44 24 0c 80 56 10 	movl   $0xf0105680,0xc(%esp)
f0100ce8:	f0 
f0100ce9:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100cf0:	f0 
f0100cf1:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0100cf8:	00 
f0100cf9:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100d00:	e8 b9 f3 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d05:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d0a:	75 24                	jne    f0100d30 <check_page_free_list+0x284>
f0100d0c:	c7 44 24 0c f6 5d 10 	movl   $0xf0105df6,0xc(%esp)
f0100d13:	f0 
f0100d14:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100d1b:	f0 
f0100d1c:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0100d23:	00 
f0100d24:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100d2b:	e8 8e f3 ff ff       	call   f01000be <_panic>
f0100d30:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d32:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d37:	76 57                	jbe    f0100d90 <check_page_free_list+0x2e4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d39:	c1 e8 0c             	shr    $0xc,%eax
f0100d3c:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d3f:	77 20                	ja     f0100d61 <check_page_free_list+0x2b5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d41:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d45:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100d4c:	f0 
f0100d4d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d54:	00 
f0100d55:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0100d5c:	e8 5d f3 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0100d61:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d67:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0100d6a:	76 29                	jbe    f0100d95 <check_page_free_list+0x2e9>
f0100d6c:	c7 44 24 0c a4 56 10 	movl   $0xf01056a4,0xc(%esp)
f0100d73:	f0 
f0100d74:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100d7b:	f0 
f0100d7c:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
f0100d83:	00 
f0100d84:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100d8b:	e8 2e f3 ff ff       	call   f01000be <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d90:	83 c7 01             	add    $0x1,%edi
f0100d93:	eb 03                	jmp    f0100d98 <check_page_free_list+0x2ec>
		else
			++nfree_extmem;
f0100d95:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d98:	8b 12                	mov    (%edx),%edx
f0100d9a:	85 d2                	test   %edx,%edx
f0100d9c:	0f 85 57 fe ff ff    	jne    f0100bf9 <check_page_free_list+0x14d>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100da2:	85 ff                	test   %edi,%edi
f0100da4:	7f 24                	jg     f0100dca <check_page_free_list+0x31e>
f0100da6:	c7 44 24 0c 10 5e 10 	movl   $0xf0105e10,0xc(%esp)
f0100dad:	f0 
f0100dae:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100db5:	f0 
f0100db6:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0100dbd:	00 
f0100dbe:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100dc5:	e8 f4 f2 ff ff       	call   f01000be <_panic>
	assert(nfree_extmem > 0);
f0100dca:	85 f6                	test   %esi,%esi
f0100dcc:	7f 53                	jg     f0100e21 <check_page_free_list+0x375>
f0100dce:	c7 44 24 0c 22 5e 10 	movl   $0xf0105e22,0xc(%esp)
f0100dd5:	f0 
f0100dd6:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0100ddd:	f0 
f0100dde:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f0100de5:	00 
f0100de6:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0100ded:	e8 cc f2 ff ff       	call   f01000be <_panic>
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100df2:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f0100df7:	85 c0                	test   %eax,%eax
f0100df9:	0f 85 df fc ff ff    	jne    f0100ade <check_page_free_list+0x32>
f0100dff:	e9 be fc ff ff       	jmp    f0100ac2 <check_page_free_list+0x16>
f0100e04:	83 3d 00 d3 17 f0 00 	cmpl   $0x0,0xf017d300
f0100e0b:	0f 84 b1 fc ff ff    	je     f0100ac2 <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e11:	8b 1d 00 d3 17 f0    	mov    0xf017d300,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e17:	be 00 04 00 00       	mov    $0x400,%esi
f0100e1c:	e9 11 fd ff ff       	jmp    f0100b32 <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100e21:	83 c4 3c             	add    $0x3c,%esp
f0100e24:	5b                   	pop    %ebx
f0100e25:	5e                   	pop    %esi
f0100e26:	5f                   	pop    %edi
f0100e27:	5d                   	pop    %ebp
f0100e28:	c3                   	ret    

f0100e29 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e29:	55                   	push   %ebp
f0100e2a:	89 e5                	mov    %esp,%ebp
f0100e2c:	53                   	push   %ebx
f0100e2d:	83 ec 14             	sub    $0x14,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e30:	83 3d c4 df 17 f0 00 	cmpl   $0x0,0xf017dfc4
f0100e37:	0f 84 a5 00 00 00    	je     f0100ee2 <page_init+0xb9>
f0100e3d:	8b 1d 00 d3 17 f0    	mov    0xf017d300,%ebx
f0100e43:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e48:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e4f:	89 d1                	mov    %edx,%ecx
f0100e51:	03 0d cc df 17 f0    	add    0xf017dfcc,%ecx
f0100e57:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e5d:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100e5f:	03 15 cc df 17 f0    	add    0xf017dfcc,%edx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e65:	83 c0 01             	add    $0x1,%eax
f0100e68:	8b 0d c4 df 17 f0    	mov    0xf017dfc4,%ecx
f0100e6e:	39 c1                	cmp    %eax,%ecx
f0100e70:	76 04                	jbe    f0100e76 <page_init+0x4d>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100e72:	89 d3                	mov    %edx,%ebx
f0100e74:	eb d2                	jmp    f0100e48 <page_init+0x1f>
f0100e76:	89 15 00 d3 17 f0    	mov    %edx,0xf017d300
	}

	//change from here.
	//mark page0 as in used.
	pages[1].pp_link=NULL;
f0100e7c:	a1 cc df 17 f0       	mov    0xf017dfcc,%eax
f0100e81:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e88:	81 f9 a0 00 00 00    	cmp    $0xa0,%ecx
f0100e8e:	77 1c                	ja     f0100eac <page_init+0x83>
		panic("pa2page called with invalid pa");
f0100e90:	c7 44 24 08 ec 56 10 	movl   $0xf01056ec,0x8(%esp)
f0100e97:	f0 
f0100e98:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100e9f:	00 
f0100ea0:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0100ea7:	e8 12 f2 ff ff       	call   f01000be <_panic>
	//mark IO hole and kernel code inused.
	extern char end[];
	//find the start and end free page.
	struct Page* page_free_start=pa2page(IOPHYSMEM)-1;
f0100eac:	8d 98 f8 04 00 00    	lea    0x4f8(%eax),%ebx
	struct Page* page_free_end=pa2page((physaddr_t)(end-KERNBASE+PGSIZE+npages*sizeof(struct Page))+sizeof(struct Env)*NENV)+1;
f0100eb2:	8d 14 cd d0 6f 19 00 	lea    0x196fd0(,%ecx,8),%edx
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb9:	c1 ea 0c             	shr    $0xc,%edx
f0100ebc:	39 d1                	cmp    %edx,%ecx
f0100ebe:	77 1c                	ja     f0100edc <page_init+0xb3>
		panic("pa2page called with invalid pa");
f0100ec0:	c7 44 24 08 ec 56 10 	movl   $0xf01056ec,0x8(%esp)
f0100ec7:	f0 
f0100ec8:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100ecf:	00 
f0100ed0:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0100ed7:	e8 e2 f1 ff ff       	call   f01000be <_panic>
	page_free_end->pp_link=page_free_start;
f0100edc:	89 5c d0 08          	mov    %ebx,0x8(%eax,%edx,8)
f0100ee0:	eb 0e                	jmp    f0100ef0 <page_init+0xc7>
		page_free_list = &pages[i];
	}

	//change from here.
	//mark page0 as in used.
	pages[1].pp_link=NULL;
f0100ee2:	a1 cc df 17 f0       	mov    0xf017dfcc,%eax
f0100ee7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
f0100eee:	eb a0                	jmp    f0100e90 <page_init+0x67>
	extern char end[];
	//find the start and end free page.
	struct Page* page_free_start=pa2page(IOPHYSMEM)-1;
	struct Page* page_free_end=pa2page((physaddr_t)(end-KERNBASE+PGSIZE+npages*sizeof(struct Page))+sizeof(struct Env)*NENV)+1;
	page_free_end->pp_link=page_free_start;
}
f0100ef0:	83 c4 14             	add    $0x14,%esp
f0100ef3:	5b                   	pop    %ebx
f0100ef4:	5d                   	pop    %ebp
f0100ef5:	c3                   	ret    

f0100ef6 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100ef6:	55                   	push   %ebp
f0100ef7:	89 e5                	mov    %esp,%ebp
f0100ef9:	53                   	push   %ebx
f0100efa:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(page_free_list==NULL)
f0100efd:	8b 1d 00 d3 17 f0    	mov    0xf017d300,%ebx
f0100f03:	85 db                	test   %ebx,%ebx
f0100f05:	74 69                	je     f0100f70 <page_alloc+0x7a>
		return NULL;
	struct Page* res=page_free_list;
	//make the first free page to a use page.
	page_free_list=page_free_list->pp_link;
f0100f07:	8b 03                	mov    (%ebx),%eax
f0100f09:	a3 00 d3 17 f0       	mov    %eax,0xf017d300
	//page2kva():convert a page to kernel virtual addr. 
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(res),'\0',PGSIZE);
	}
	return res;
f0100f0e:	89 d8                	mov    %ebx,%eax
		return NULL;
	struct Page* res=page_free_list;
	//make the first free page to a use page.
	page_free_list=page_free_list->pp_link;
	//page2kva():convert a page to kernel virtual addr. 
	if(alloc_flags & ALLOC_ZERO){
f0100f10:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f14:	74 5f                	je     f0100f75 <page_alloc+0x7f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f16:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f0100f1c:	c1 f8 03             	sar    $0x3,%eax
f0100f1f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f22:	89 c2                	mov    %eax,%edx
f0100f24:	c1 ea 0c             	shr    $0xc,%edx
f0100f27:	3b 15 c4 df 17 f0    	cmp    0xf017dfc4,%edx
f0100f2d:	72 20                	jb     f0100f4f <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f33:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0100f3a:	f0 
f0100f3b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f42:	00 
f0100f43:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0100f4a:	e8 6f f1 ff ff       	call   f01000be <_panic>
		memset(page2kva(res),'\0',PGSIZE);
f0100f4f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f56:	00 
f0100f57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f5e:	00 
	return (void *)(pa + KERNBASE);
f0100f5f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f64:	89 04 24             	mov    %eax,(%esp)
f0100f67:	e8 dd 3c 00 00       	call   f0104c49 <memset>
	}
	return res;
f0100f6c:	89 d8                	mov    %ebx,%eax
f0100f6e:	eb 05                	jmp    f0100f75 <page_alloc+0x7f>
struct Page *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if(page_free_list==NULL)
		return NULL;
f0100f70:	b8 00 00 00 00       	mov    $0x0,%eax
	//page2kva():convert a page to kernel virtual addr. 
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(res),'\0',PGSIZE);
	}
	return res;
}
f0100f75:	83 c4 14             	add    $0x14,%esp
f0100f78:	5b                   	pop    %ebx
f0100f79:	5d                   	pop    %ebp
f0100f7a:	c3                   	ret    

f0100f7b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f7b:	55                   	push   %ebp
f0100f7c:	89 e5                	mov    %esp,%ebp
f0100f7e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link=page_free_list;
f0100f81:	8b 15 00 d3 17 f0    	mov    0xf017d300,%edx
f0100f87:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f0100f89:	a3 00 d3 17 f0       	mov    %eax,0xf017d300
}
f0100f8e:	5d                   	pop    %ebp
f0100f8f:	c3                   	ret    

f0100f90 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f90:	55                   	push   %ebp
f0100f91:	89 e5                	mov    %esp,%ebp
f0100f93:	83 ec 04             	sub    $0x4,%esp
f0100f96:	8b 45 08             	mov    0x8(%ebp),%eax
	pp->pp_ref--;
f0100f99:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f9d:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100fa0:	66 89 50 04          	mov    %dx,0x4(%eax)
	if (pp->pp_ref == 0)
f0100fa4:	66 85 d2             	test   %dx,%dx
f0100fa7:	75 08                	jne    f0100fb1 <page_decref+0x21>
		page_free(pp);
f0100fa9:	89 04 24             	mov    %eax,(%esp)
f0100fac:	e8 ca ff ff ff       	call   f0100f7b <page_free>
}
f0100fb1:	c9                   	leave  
f0100fb2:	c3                   	ret    

f0100fb3 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100fb3:	55                   	push   %ebp
f0100fb4:	89 e5                	mov    %esp,%ebp
f0100fb6:	56                   	push   %esi
f0100fb7:	53                   	push   %ebx
f0100fb8:	83 ec 10             	sub    $0x10,%esp
f0100fbb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	//code from here
	pte_t* res=NULL;
	//pgDirIndex is page director index.
	uintptr_t pgDirIndex=PDX(va);
f0100fbe:	89 de                	mov    %ebx,%esi
f0100fc0:	c1 ee 16             	shr    $0x16,%esi
	//page table is not exit.
	if(pgdir[pgDirIndex]==(pte_t)NULL){   
f0100fc3:	c1 e6 02             	shl    $0x2,%esi
f0100fc6:	03 75 08             	add    0x8(%ebp),%esi
f0100fc9:	8b 06                	mov    (%esi),%eax
f0100fcb:	85 c0                	test   %eax,%eax
f0100fcd:	75 76                	jne    f0101045 <pgdir_walk+0x92>
		if(create==0){   //create is false.
f0100fcf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fd3:	0f 84 d1 00 00 00    	je     f01010aa <pgdir_walk+0xf7>
			return NULL;
		}
		else{
			//creat a new page
			struct Page* newPage=page_alloc(1);
f0100fd9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fe0:	e8 11 ff ff ff       	call   f0100ef6 <page_alloc>
			//ifcreat failed.
			if(newPage==NULL){
f0100fe5:	85 c0                	test   %eax,%eax
f0100fe7:	0f 84 c4 00 00 00    	je     f01010b1 <pgdir_walk+0xfe>
				return NULL;
			}
			else{    //add refercencecout if creat succeed.
				newPage->pp_ref++;
f0100fed:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ff2:	89 c2                	mov    %eax,%edx
f0100ff4:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0100ffa:	c1 fa 03             	sar    $0x3,%edx
f0100ffd:	c1 e2 0c             	shl    $0xc,%edx
				//convert to physical addr and set flag.
				pgdir[pgDirIndex]=page2pa(newPage)|PTE_U|PTE_W|PTE_P;
f0101000:	83 ca 07             	or     $0x7,%edx
f0101003:	89 16                	mov    %edx,(%esi)
f0101005:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f010100b:	c1 f8 03             	sar    $0x3,%eax
f010100e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101011:	89 c2                	mov    %eax,%edx
f0101013:	c1 ea 0c             	shr    $0xc,%edx
f0101016:	3b 15 c4 df 17 f0    	cmp    0xf017dfc4,%edx
f010101c:	72 20                	jb     f010103e <pgdir_walk+0x8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010101e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101022:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0101029:	f0 
f010102a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101031:	00 
f0101032:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0101039:	e8 80 f0 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f010103e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101043:	eb 58                	jmp    f010109d <pgdir_walk+0xea>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101045:	c1 e8 0c             	shr    $0xc,%eax
f0101048:	8b 15 c4 df 17 f0    	mov    0xf017dfc4,%edx
f010104e:	39 d0                	cmp    %edx,%eax
f0101050:	72 1c                	jb     f010106e <pgdir_walk+0xbb>
		panic("pa2page called with invalid pa");
f0101052:	c7 44 24 08 ec 56 10 	movl   $0xf01056ec,0x8(%esp)
f0101059:	f0 
f010105a:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0101061:	00 
f0101062:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0101069:	e8 50 f0 ff ff       	call   f01000be <_panic>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010106e:	89 c1                	mov    %eax,%ecx
f0101070:	c1 e1 0c             	shl    $0xc,%ecx
f0101073:	39 d0                	cmp    %edx,%eax
f0101075:	72 20                	jb     f0101097 <pgdir_walk+0xe4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101077:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010107b:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0101082:	f0 
f0101083:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010108a:	00 
f010108b:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0101092:	e8 27 f0 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0101097:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
	}
	else{
		//convert pgdir to a pointer to PTE for 'va'
		res=page2kva(pa2page(PTE_ADDR(pgdir[pgDirIndex])));
	}
	return &res[PTX(va)];
f010109d:	c1 eb 0a             	shr    $0xa,%ebx
f01010a0:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f01010a6:	01 d8                	add    %ebx,%eax
f01010a8:	eb 0c                	jmp    f01010b6 <pgdir_walk+0x103>
	//pgDirIndex is page director index.
	uintptr_t pgDirIndex=PDX(va);
	//page table is not exit.
	if(pgdir[pgDirIndex]==(pte_t)NULL){   
		if(create==0){   //create is false.
			return NULL;
f01010aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01010af:	eb 05                	jmp    f01010b6 <pgdir_walk+0x103>
		else{
			//creat a new page
			struct Page* newPage=page_alloc(1);
			//ifcreat failed.
			if(newPage==NULL){
				return NULL;
f01010b1:	b8 00 00 00 00       	mov    $0x0,%eax
	else{
		//convert pgdir to a pointer to PTE for 'va'
		res=page2kva(pa2page(PTE_ADDR(pgdir[pgDirIndex])));
	}
	return &res[PTX(va)];
}
f01010b6:	83 c4 10             	add    $0x10,%esp
f01010b9:	5b                   	pop    %ebx
f01010ba:	5e                   	pop    %esi
f01010bb:	5d                   	pop    %ebp
f01010bc:	c3                   	ret    

f01010bd <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010bd:	55                   	push   %ebp
f01010be:	89 e5                	mov    %esp,%ebp
f01010c0:	57                   	push   %edi
f01010c1:	56                   	push   %esi
f01010c2:	53                   	push   %ebx
f01010c3:	83 ec 2c             	sub    $0x2c,%esp
f01010c6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Fill this function in
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f01010c9:	c1 e9 0c             	shr    $0xc,%ecx
f01010cc:	85 c9                	test   %ecx,%ecx
f01010ce:	74 6b                	je     f010113b <boot_map_region+0x7e>
f01010d0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010d3:	89 d3                	mov    %edx,%ebx
f01010d5:	be 00 00 00 00       	mov    $0x0,%esi
f01010da:	8b 45 08             	mov    0x8(%ebp),%eax
f01010dd:	29 d0                	sub    %edx,%eax
f01010df:	89 45 e0             	mov    %eax,-0x20(%ebp)
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
f01010e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010e5:	83 c8 01             	or     $0x1,%eax
f01010e8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010ee:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f01010f1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010f8:	00 
f01010f9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101100:	89 04 24             	mov    %eax,(%esp)
f0101103:	e8 ab fe ff ff       	call   f0100fb3 <pgdir_walk>
        if (!pte) panic("boot_map_region panic, out of memory");
f0101108:	85 c0                	test   %eax,%eax
f010110a:	75 1c                	jne    f0101128 <boot_map_region+0x6b>
f010110c:	c7 44 24 08 0c 57 10 	movl   $0xf010570c,0x8(%esp)
f0101113:	f0 
f0101114:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
f010111b:	00 
f010111c:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101123:	e8 96 ef ff ff       	call   f01000be <_panic>
        *pte = pa | perm | PTE_P;
f0101128:	0b 7d d8             	or     -0x28(%ebp),%edi
f010112b:	89 38                	mov    %edi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f010112d:	83 c6 01             	add    $0x1,%esi
f0101130:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101136:	3b 75 dc             	cmp    -0x24(%ebp),%esi
f0101139:	75 b0                	jne    f01010eb <boot_map_region+0x2e>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
    }
}
f010113b:	83 c4 2c             	add    $0x2c,%esp
f010113e:	5b                   	pop    %ebx
f010113f:	5e                   	pop    %esi
f0101140:	5f                   	pop    %edi
f0101141:	5d                   	pop    %ebp
f0101142:	c3                   	ret    

f0101143 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101143:	55                   	push   %ebp
f0101144:	89 e5                	mov    %esp,%ebp
f0101146:	53                   	push   %ebx
f0101147:	83 ec 14             	sub    $0x14,%esp
f010114a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	//
	// code from here
	//
	// pgTabEnt is page table entry.
	pte_t* pgTabEnt=pgdir_walk(pgdir,va,0);
f010114d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101154:	00 
f0101155:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101158:	89 44 24 04          	mov    %eax,0x4(%esp)
f010115c:	8b 45 08             	mov    0x8(%ebp),%eax
f010115f:	89 04 24             	mov    %eax,(%esp)
f0101162:	e8 4c fe ff ff       	call   f0100fb3 <pgdir_walk>
	if(pgTabEnt==NULL)
f0101167:	85 c0                	test   %eax,%eax
f0101169:	74 3e                	je     f01011a9 <page_lookup+0x66>
		return NULL;
	else{
		if(pte_store!=NULL){
f010116b:	85 db                	test   %ebx,%ebx
f010116d:	74 02                	je     f0101171 <page_lookup+0x2e>
			*pte_store=pgTabEnt;
f010116f:	89 03                	mov    %eax,(%ebx)
		}
		if(pgTabEnt[0]!=(pte_t)NULL){
f0101171:	8b 00                	mov    (%eax),%eax
f0101173:	85 c0                	test   %eax,%eax
f0101175:	74 39                	je     f01011b0 <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101177:	c1 e8 0c             	shr    $0xc,%eax
f010117a:	3b 05 c4 df 17 f0    	cmp    0xf017dfc4,%eax
f0101180:	72 1c                	jb     f010119e <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f0101182:	c7 44 24 08 ec 56 10 	movl   $0xf01056ec,0x8(%esp)
f0101189:	f0 
f010118a:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0101191:	00 
f0101192:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0101199:	e8 20 ef ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f010119e:	8b 15 cc df 17 f0    	mov    0xf017dfcc,%edx
f01011a4:	8d 04 c2             	lea    (%edx,%eax,8),%eax
			// return page table entry  kernel virtual addr.
			return pa2page(PTE_ADDR(pgTabEnt[0]));
f01011a7:	eb 0c                	jmp    f01011b5 <page_lookup+0x72>
	// code from here
	//
	// pgTabEnt is page table entry.
	pte_t* pgTabEnt=pgdir_walk(pgdir,va,0);
	if(pgTabEnt==NULL)
		return NULL;
f01011a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ae:	eb 05                	jmp    f01011b5 <page_lookup+0x72>
		if(pgTabEnt[0]!=(pte_t)NULL){
			// return page table entry  kernel virtual addr.
			return pa2page(PTE_ADDR(pgTabEnt[0]));
		}
		else{
			return NULL;
f01011b0:	b8 00 00 00 00       	mov    $0x0,%eax
		}
	}
}
f01011b5:	83 c4 14             	add    $0x14,%esp
f01011b8:	5b                   	pop    %ebx
f01011b9:	5d                   	pop    %ebp
f01011ba:	c3                   	ret    

f01011bb <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011bb:	55                   	push   %ebp
f01011bc:	89 e5                	mov    %esp,%ebp
f01011be:	53                   	push   %ebx
f01011bf:	83 ec 24             	sub    $0x24,%esp
f01011c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	// code from here
	//
	pte_t* pgTabEnt;
	struct Page* page=page_lookup(pgdir,va,&pgTabEnt);
f01011c5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011c8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d3:	89 04 24             	mov    %eax,(%esp)
f01011d6:	e8 68 ff ff ff       	call   f0101143 <page_lookup>
	if(page!=NULL){
f01011db:	85 c0                	test   %eax,%eax
f01011dd:	74 08                	je     f01011e7 <page_remove+0x2c>
		page_decref(page);
f01011df:	89 04 24             	mov    %eax,(%esp)
f01011e2:	e8 a9 fd ff ff       	call   f0100f90 <page_decref>
	}
	//can't be pgTabEnt[0]=NULL because of must be PGSIZE?
	pgTabEnt[0]=0;
f01011e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ea:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011f0:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir,va);
}
f01011f3:	83 c4 24             	add    $0x24,%esp
f01011f6:	5b                   	pop    %ebx
f01011f7:	5d                   	pop    %ebp
f01011f8:	c3                   	ret    

f01011f9 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01011f9:	55                   	push   %ebp
f01011fa:	89 e5                	mov    %esp,%ebp
f01011fc:	57                   	push   %edi
f01011fd:	56                   	push   %esi
f01011fe:	53                   	push   %ebx
f01011ff:	83 ec 1c             	sub    $0x1c,%esp
f0101202:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101205:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	//
	//code from here.
	pte_t* pte=pgdir_walk(pgdir,va,1);
f0101208:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010120f:	00 
f0101210:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101214:	8b 45 08             	mov    0x8(%ebp),%eax
f0101217:	89 04 24             	mov    %eax,(%esp)
f010121a:	e8 94 fd ff ff       	call   f0100fb3 <pgdir_walk>
f010121f:	89 c6                	mov    %eax,%esi
	if(pte==NULL){
f0101221:	85 c0                	test   %eax,%eax
f0101223:	74 5a                	je     f010127f <page_insert+0x86>
		return -E_NO_MEM;
	}
	if (*pte & PTE_P) {
f0101225:	8b 00                	mov    (%eax),%eax
f0101227:	a8 01                	test   $0x1,%al
f0101229:	74 30                	je     f010125b <page_insert+0x62>
		if (PTE_ADDR(*pte) == page2pa (pp)) {
f010122b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101230:	89 da                	mov    %ebx,%edx
f0101232:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0101238:	c1 fa 03             	sar    $0x3,%edx
f010123b:	c1 e2 0c             	shl    $0xc,%edx
f010123e:	39 d0                	cmp    %edx,%eax
f0101240:	75 0a                	jne    f010124c <page_insert+0x53>
f0101242:	0f 01 3f             	invlpg (%edi)
			tlb_invalidate (pgdir, va);
			pp -> pp_ref --;
f0101245:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f010124a:	eb 0f                	jmp    f010125b <page_insert+0x62>
		} else {
			page_remove (pgdir, va);
f010124c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101250:	8b 45 08             	mov    0x8(%ebp),%eax
f0101253:	89 04 24             	mov    %eax,(%esp)
f0101256:	e8 60 ff ff ff       	call   f01011bb <page_remove>
		}
	}
	*pte = page2pa (pp)|perm|PTE_P;
f010125b:	8b 55 14             	mov    0x14(%ebp),%edx
f010125e:	83 ca 01             	or     $0x1,%edx
f0101261:	89 d8                	mov    %ebx,%eax
f0101263:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f0101269:	c1 f8 03             	sar    $0x3,%eax
f010126c:	c1 e0 0c             	shl    $0xc,%eax
f010126f:	09 d0                	or     %edx,%eax
f0101271:	89 06                	mov    %eax,(%esi)
	pp -> pp_ref ++;
f0101273:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f0101278:	b8 00 00 00 00       	mov    $0x0,%eax
f010127d:	eb 05                	jmp    f0101284 <page_insert+0x8b>
	// Fill this function in
	//
	//code from here.
	pte_t* pte=pgdir_walk(pgdir,va,1);
	if(pte==NULL){
		return -E_NO_MEM;
f010127f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		}
	}
	*pte = page2pa (pp)|perm|PTE_P;
	pp -> pp_ref ++;
	return 0;
}
f0101284:	83 c4 1c             	add    $0x1c,%esp
f0101287:	5b                   	pop    %ebx
f0101288:	5e                   	pop    %esi
f0101289:	5f                   	pop    %edi
f010128a:	5d                   	pop    %ebp
f010128b:	c3                   	ret    

f010128c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010128c:	55                   	push   %ebp
f010128d:	89 e5                	mov    %esp,%ebp
f010128f:	57                   	push   %edi
f0101290:	56                   	push   %esi
f0101291:	53                   	push   %ebx
f0101292:	83 ec 3c             	sub    $0x3c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101295:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f010129c:	e8 49 23 00 00       	call   f01035ea <mc146818_read>
f01012a1:	89 c3                	mov    %eax,%ebx
f01012a3:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01012aa:	e8 3b 23 00 00       	call   f01035ea <mc146818_read>
f01012af:	c1 e0 08             	shl    $0x8,%eax
f01012b2:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01012b4:	89 d8                	mov    %ebx,%eax
f01012b6:	c1 e0 0a             	shl    $0xa,%eax
f01012b9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012bf:	85 c0                	test   %eax,%eax
f01012c1:	0f 48 c2             	cmovs  %edx,%eax
f01012c4:	c1 f8 0c             	sar    $0xc,%eax
f01012c7:	a3 04 d3 17 f0       	mov    %eax,0xf017d304
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01012cc:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01012d3:	e8 12 23 00 00       	call   f01035ea <mc146818_read>
f01012d8:	89 c3                	mov    %eax,%ebx
f01012da:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01012e1:	e8 04 23 00 00       	call   f01035ea <mc146818_read>
f01012e6:	c1 e0 08             	shl    $0x8,%eax
f01012e9:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012eb:	89 d8                	mov    %ebx,%eax
f01012ed:	c1 e0 0a             	shl    $0xa,%eax
f01012f0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012f6:	85 c0                	test   %eax,%eax
f01012f8:	0f 48 c2             	cmovs  %edx,%eax
f01012fb:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012fe:	85 c0                	test   %eax,%eax
f0101300:	74 0e                	je     f0101310 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101302:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101308:	89 15 c4 df 17 f0    	mov    %edx,0xf017dfc4
f010130e:	eb 0c                	jmp    f010131c <mem_init+0x90>
	else
		npages = npages_basemem;
f0101310:	8b 15 04 d3 17 f0    	mov    0xf017d304,%edx
f0101316:	89 15 c4 df 17 f0    	mov    %edx,0xf017dfc4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010131c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010131f:	c1 e8 0a             	shr    $0xa,%eax
f0101322:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101326:	a1 04 d3 17 f0       	mov    0xf017d304,%eax
f010132b:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010132e:	c1 e8 0a             	shr    $0xa,%eax
f0101331:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101335:	a1 c4 df 17 f0       	mov    0xf017dfc4,%eax
f010133a:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010133d:	c1 e8 0a             	shr    $0xa,%eax
f0101340:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101344:	c7 04 24 34 57 10 f0 	movl   $0xf0105734,(%esp)
f010134b:	e8 0a 23 00 00       	call   f010365a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101350:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101355:	e8 66 f6 ff ff       	call   f01009c0 <boot_alloc>
f010135a:	a3 c8 df 17 f0       	mov    %eax,0xf017dfc8
	memset(kern_pgdir, 0, PGSIZE);
f010135f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101366:	00 
f0101367:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010136e:	00 
f010136f:	89 04 24             	mov    %eax,(%esp)
f0101372:	e8 d2 38 00 00       	call   f0104c49 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101377:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010137c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101381:	77 20                	ja     f01013a3 <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101383:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101387:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f010138e:	f0 
f010138f:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f0101396:	00 
f0101397:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010139e:	e8 1b ed ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01013a3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013a9:	83 ca 05             	or     $0x5,%edx
f01013ac:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages=(struct Page*)boot_alloc(npages*sizeof(struct Page));
f01013b2:	a1 c4 df 17 f0       	mov    0xf017dfc4,%eax
f01013b7:	c1 e0 03             	shl    $0x3,%eax
f01013ba:	e8 01 f6 ff ff       	call   f01009c0 <boot_alloc>
f01013bf:	a3 cc df 17 f0       	mov    %eax,0xf017dfcc

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=(struct Env*)boot_alloc(sizeof(struct Env)* NENV);
f01013c4:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013c9:	e8 f2 f5 ff ff       	call   f01009c0 <boot_alloc>
f01013ce:	a3 0c d3 17 f0       	mov    %eax,0xf017d30c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013d3:	e8 51 fa ff ff       	call   f0100e29 <page_init>

	check_page_free_list(1);
f01013d8:	b8 01 00 00 00       	mov    $0x1,%eax
f01013dd:	e8 ca f6 ff ff       	call   f0100aac <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01013e2:	83 3d cc df 17 f0 00 	cmpl   $0x0,0xf017dfcc
f01013e9:	75 1c                	jne    f0101407 <mem_init+0x17b>
		panic("'pages' is a null pointer!");
f01013eb:	c7 44 24 08 33 5e 10 	movl   $0xf0105e33,0x8(%esp)
f01013f2:	f0 
f01013f3:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f01013fa:	00 
f01013fb:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101402:	e8 b7 ec ff ff       	call   f01000be <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101407:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f010140c:	85 c0                	test   %eax,%eax
f010140e:	74 10                	je     f0101420 <mem_init+0x194>
f0101410:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f0101415:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101418:	8b 00                	mov    (%eax),%eax
f010141a:	85 c0                	test   %eax,%eax
f010141c:	75 f7                	jne    f0101415 <mem_init+0x189>
f010141e:	eb 05                	jmp    f0101425 <mem_init+0x199>
f0101420:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101425:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010142c:	e8 c5 fa ff ff       	call   f0100ef6 <page_alloc>
f0101431:	89 c7                	mov    %eax,%edi
f0101433:	85 c0                	test   %eax,%eax
f0101435:	75 24                	jne    f010145b <mem_init+0x1cf>
f0101437:	c7 44 24 0c 4e 5e 10 	movl   $0xf0105e4e,0xc(%esp)
f010143e:	f0 
f010143f:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101446:	f0 
f0101447:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f010144e:	00 
f010144f:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101456:	e8 63 ec ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010145b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101462:	e8 8f fa ff ff       	call   f0100ef6 <page_alloc>
f0101467:	89 c6                	mov    %eax,%esi
f0101469:	85 c0                	test   %eax,%eax
f010146b:	75 24                	jne    f0101491 <mem_init+0x205>
f010146d:	c7 44 24 0c 64 5e 10 	movl   $0xf0105e64,0xc(%esp)
f0101474:	f0 
f0101475:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010147c:	f0 
f010147d:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0101484:	00 
f0101485:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010148c:	e8 2d ec ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101491:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101498:	e8 59 fa ff ff       	call   f0100ef6 <page_alloc>
f010149d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014a0:	85 c0                	test   %eax,%eax
f01014a2:	75 24                	jne    f01014c8 <mem_init+0x23c>
f01014a4:	c7 44 24 0c 7a 5e 10 	movl   $0xf0105e7a,0xc(%esp)
f01014ab:	f0 
f01014ac:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01014b3:	f0 
f01014b4:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f01014bb:	00 
f01014bc:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01014c3:	e8 f6 eb ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014c8:	39 f7                	cmp    %esi,%edi
f01014ca:	75 24                	jne    f01014f0 <mem_init+0x264>
f01014cc:	c7 44 24 0c 90 5e 10 	movl   $0xf0105e90,0xc(%esp)
f01014d3:	f0 
f01014d4:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01014db:	f0 
f01014dc:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01014e3:	00 
f01014e4:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01014eb:	e8 ce eb ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014f3:	39 c6                	cmp    %eax,%esi
f01014f5:	74 04                	je     f01014fb <mem_init+0x26f>
f01014f7:	39 c7                	cmp    %eax,%edi
f01014f9:	75 24                	jne    f010151f <mem_init+0x293>
f01014fb:	c7 44 24 0c 94 57 10 	movl   $0xf0105794,0xc(%esp)
f0101502:	f0 
f0101503:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010150a:	f0 
f010150b:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0101512:	00 
f0101513:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010151a:	e8 9f eb ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010151f:	8b 15 cc df 17 f0    	mov    0xf017dfcc,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101525:	a1 c4 df 17 f0       	mov    0xf017dfc4,%eax
f010152a:	c1 e0 0c             	shl    $0xc,%eax
f010152d:	89 f9                	mov    %edi,%ecx
f010152f:	29 d1                	sub    %edx,%ecx
f0101531:	c1 f9 03             	sar    $0x3,%ecx
f0101534:	c1 e1 0c             	shl    $0xc,%ecx
f0101537:	39 c1                	cmp    %eax,%ecx
f0101539:	72 24                	jb     f010155f <mem_init+0x2d3>
f010153b:	c7 44 24 0c a2 5e 10 	movl   $0xf0105ea2,0xc(%esp)
f0101542:	f0 
f0101543:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010154a:	f0 
f010154b:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101552:	00 
f0101553:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010155a:	e8 5f eb ff ff       	call   f01000be <_panic>
f010155f:	89 f1                	mov    %esi,%ecx
f0101561:	29 d1                	sub    %edx,%ecx
f0101563:	c1 f9 03             	sar    $0x3,%ecx
f0101566:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101569:	39 c8                	cmp    %ecx,%eax
f010156b:	77 24                	ja     f0101591 <mem_init+0x305>
f010156d:	c7 44 24 0c bf 5e 10 	movl   $0xf0105ebf,0xc(%esp)
f0101574:	f0 
f0101575:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010157c:	f0 
f010157d:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101584:	00 
f0101585:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010158c:	e8 2d eb ff ff       	call   f01000be <_panic>
f0101591:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101594:	29 d1                	sub    %edx,%ecx
f0101596:	89 ca                	mov    %ecx,%edx
f0101598:	c1 fa 03             	sar    $0x3,%edx
f010159b:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010159e:	39 d0                	cmp    %edx,%eax
f01015a0:	77 24                	ja     f01015c6 <mem_init+0x33a>
f01015a2:	c7 44 24 0c dc 5e 10 	movl   $0xf0105edc,0xc(%esp)
f01015a9:	f0 
f01015aa:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01015b1:	f0 
f01015b2:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f01015b9:	00 
f01015ba:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01015c1:	e8 f8 ea ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015c6:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f01015cb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015ce:	c7 05 00 d3 17 f0 00 	movl   $0x0,0xf017d300
f01015d5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015df:	e8 12 f9 ff ff       	call   f0100ef6 <page_alloc>
f01015e4:	85 c0                	test   %eax,%eax
f01015e6:	74 24                	je     f010160c <mem_init+0x380>
f01015e8:	c7 44 24 0c f9 5e 10 	movl   $0xf0105ef9,0xc(%esp)
f01015ef:	f0 
f01015f0:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01015f7:	f0 
f01015f8:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f01015ff:	00 
f0101600:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101607:	e8 b2 ea ff ff       	call   f01000be <_panic>

	// free and re-allocate?
	page_free(pp0);
f010160c:	89 3c 24             	mov    %edi,(%esp)
f010160f:	e8 67 f9 ff ff       	call   f0100f7b <page_free>
	page_free(pp1);
f0101614:	89 34 24             	mov    %esi,(%esp)
f0101617:	e8 5f f9 ff ff       	call   f0100f7b <page_free>
	page_free(pp2);
f010161c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010161f:	89 04 24             	mov    %eax,(%esp)
f0101622:	e8 54 f9 ff ff       	call   f0100f7b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101627:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010162e:	e8 c3 f8 ff ff       	call   f0100ef6 <page_alloc>
f0101633:	89 c6                	mov    %eax,%esi
f0101635:	85 c0                	test   %eax,%eax
f0101637:	75 24                	jne    f010165d <mem_init+0x3d1>
f0101639:	c7 44 24 0c 4e 5e 10 	movl   $0xf0105e4e,0xc(%esp)
f0101640:	f0 
f0101641:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101648:	f0 
f0101649:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0101650:	00 
f0101651:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101658:	e8 61 ea ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010165d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101664:	e8 8d f8 ff ff       	call   f0100ef6 <page_alloc>
f0101669:	89 c7                	mov    %eax,%edi
f010166b:	85 c0                	test   %eax,%eax
f010166d:	75 24                	jne    f0101693 <mem_init+0x407>
f010166f:	c7 44 24 0c 64 5e 10 	movl   $0xf0105e64,0xc(%esp)
f0101676:	f0 
f0101677:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010167e:	f0 
f010167f:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f0101686:	00 
f0101687:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010168e:	e8 2b ea ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101693:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010169a:	e8 57 f8 ff ff       	call   f0100ef6 <page_alloc>
f010169f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016a2:	85 c0                	test   %eax,%eax
f01016a4:	75 24                	jne    f01016ca <mem_init+0x43e>
f01016a6:	c7 44 24 0c 7a 5e 10 	movl   $0xf0105e7a,0xc(%esp)
f01016ad:	f0 
f01016ae:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01016b5:	f0 
f01016b6:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f01016bd:	00 
f01016be:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01016c5:	e8 f4 e9 ff ff       	call   f01000be <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016ca:	39 fe                	cmp    %edi,%esi
f01016cc:	75 24                	jne    f01016f2 <mem_init+0x466>
f01016ce:	c7 44 24 0c 90 5e 10 	movl   $0xf0105e90,0xc(%esp)
f01016d5:	f0 
f01016d6:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01016dd:	f0 
f01016de:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f01016e5:	00 
f01016e6:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01016ed:	e8 cc e9 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016f5:	39 c7                	cmp    %eax,%edi
f01016f7:	74 04                	je     f01016fd <mem_init+0x471>
f01016f9:	39 c6                	cmp    %eax,%esi
f01016fb:	75 24                	jne    f0101721 <mem_init+0x495>
f01016fd:	c7 44 24 0c 94 57 10 	movl   $0xf0105794,0xc(%esp)
f0101704:	f0 
f0101705:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010170c:	f0 
f010170d:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0101714:	00 
f0101715:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010171c:	e8 9d e9 ff ff       	call   f01000be <_panic>
	assert(!page_alloc(0));
f0101721:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101728:	e8 c9 f7 ff ff       	call   f0100ef6 <page_alloc>
f010172d:	85 c0                	test   %eax,%eax
f010172f:	74 24                	je     f0101755 <mem_init+0x4c9>
f0101731:	c7 44 24 0c f9 5e 10 	movl   $0xf0105ef9,0xc(%esp)
f0101738:	f0 
f0101739:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101740:	f0 
f0101741:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f0101748:	00 
f0101749:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101750:	e8 69 e9 ff ff       	call   f01000be <_panic>
f0101755:	89 f0                	mov    %esi,%eax
f0101757:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f010175d:	c1 f8 03             	sar    $0x3,%eax
f0101760:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101763:	89 c2                	mov    %eax,%edx
f0101765:	c1 ea 0c             	shr    $0xc,%edx
f0101768:	3b 15 c4 df 17 f0    	cmp    0xf017dfc4,%edx
f010176e:	72 20                	jb     f0101790 <mem_init+0x504>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101770:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101774:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f010177b:	f0 
f010177c:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101783:	00 
f0101784:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f010178b:	e8 2e e9 ff ff       	call   f01000be <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101790:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101797:	00 
f0101798:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010179f:	00 
	return (void *)(pa + KERNBASE);
f01017a0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01017a5:	89 04 24             	mov    %eax,(%esp)
f01017a8:	e8 9c 34 00 00       	call   f0104c49 <memset>
	page_free(pp0);
f01017ad:	89 34 24             	mov    %esi,(%esp)
f01017b0:	e8 c6 f7 ff ff       	call   f0100f7b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017b5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017bc:	e8 35 f7 ff ff       	call   f0100ef6 <page_alloc>
f01017c1:	85 c0                	test   %eax,%eax
f01017c3:	75 24                	jne    f01017e9 <mem_init+0x55d>
f01017c5:	c7 44 24 0c 08 5f 10 	movl   $0xf0105f08,0xc(%esp)
f01017cc:	f0 
f01017cd:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01017d4:	f0 
f01017d5:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f01017dc:	00 
f01017dd:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01017e4:	e8 d5 e8 ff ff       	call   f01000be <_panic>
	assert(pp && pp0 == pp);
f01017e9:	39 c6                	cmp    %eax,%esi
f01017eb:	74 24                	je     f0101811 <mem_init+0x585>
f01017ed:	c7 44 24 0c 26 5f 10 	movl   $0xf0105f26,0xc(%esp)
f01017f4:	f0 
f01017f5:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01017fc:	f0 
f01017fd:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0101804:	00 
f0101805:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010180c:	e8 ad e8 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101811:	89 f2                	mov    %esi,%edx
f0101813:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0101819:	c1 fa 03             	sar    $0x3,%edx
f010181c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010181f:	89 d0                	mov    %edx,%eax
f0101821:	c1 e8 0c             	shr    $0xc,%eax
f0101824:	3b 05 c4 df 17 f0    	cmp    0xf017dfc4,%eax
f010182a:	72 20                	jb     f010184c <mem_init+0x5c0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010182c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101830:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0101837:	f0 
f0101838:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010183f:	00 
f0101840:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0101847:	e8 72 e8 ff ff       	call   f01000be <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010184c:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101853:	75 11                	jne    f0101866 <mem_init+0x5da>
f0101855:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
f010185b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0101861:	80 38 00             	cmpb   $0x0,(%eax)
f0101864:	74 24                	je     f010188a <mem_init+0x5fe>
f0101866:	c7 44 24 0c 36 5f 10 	movl   $0xf0105f36,0xc(%esp)
f010186d:	f0 
f010186e:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101875:	f0 
f0101876:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f010187d:	00 
f010187e:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101885:	e8 34 e8 ff ff       	call   f01000be <_panic>
f010188a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010188d:	39 d0                	cmp    %edx,%eax
f010188f:	75 d0                	jne    f0101861 <mem_init+0x5d5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101891:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101894:	a3 00 d3 17 f0       	mov    %eax,0xf017d300

	// free the pages we took
	page_free(pp0);
f0101899:	89 34 24             	mov    %esi,(%esp)
f010189c:	e8 da f6 ff ff       	call   f0100f7b <page_free>
	page_free(pp1);
f01018a1:	89 3c 24             	mov    %edi,(%esp)
f01018a4:	e8 d2 f6 ff ff       	call   f0100f7b <page_free>
	page_free(pp2);
f01018a9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018ac:	89 04 24             	mov    %eax,(%esp)
f01018af:	e8 c7 f6 ff ff       	call   f0100f7b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018b4:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f01018b9:	85 c0                	test   %eax,%eax
f01018bb:	74 09                	je     f01018c6 <mem_init+0x63a>
		--nfree;
f01018bd:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018c0:	8b 00                	mov    (%eax),%eax
f01018c2:	85 c0                	test   %eax,%eax
f01018c4:	75 f7                	jne    f01018bd <mem_init+0x631>
		--nfree;
	assert(nfree == 0);
f01018c6:	85 db                	test   %ebx,%ebx
f01018c8:	74 24                	je     f01018ee <mem_init+0x662>
f01018ca:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f01018d1:	f0 
f01018d2:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01018d9:	f0 
f01018da:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f01018e1:	00 
f01018e2:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01018e9:	e8 d0 e7 ff ff       	call   f01000be <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01018ee:	c7 04 24 b4 57 10 f0 	movl   $0xf01057b4,(%esp)
f01018f5:	e8 60 1d 00 00       	call   f010365a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101901:	e8 f0 f5 ff ff       	call   f0100ef6 <page_alloc>
f0101906:	89 c3                	mov    %eax,%ebx
f0101908:	85 c0                	test   %eax,%eax
f010190a:	75 24                	jne    f0101930 <mem_init+0x6a4>
f010190c:	c7 44 24 0c 4e 5e 10 	movl   $0xf0105e4e,0xc(%esp)
f0101913:	f0 
f0101914:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010191b:	f0 
f010191c:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101923:	00 
f0101924:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010192b:	e8 8e e7 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101930:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101937:	e8 ba f5 ff ff       	call   f0100ef6 <page_alloc>
f010193c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010193f:	85 c0                	test   %eax,%eax
f0101941:	75 24                	jne    f0101967 <mem_init+0x6db>
f0101943:	c7 44 24 0c 64 5e 10 	movl   $0xf0105e64,0xc(%esp)
f010194a:	f0 
f010194b:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101952:	f0 
f0101953:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f010195a:	00 
f010195b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101962:	e8 57 e7 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101967:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010196e:	e8 83 f5 ff ff       	call   f0100ef6 <page_alloc>
f0101973:	89 c6                	mov    %eax,%esi
f0101975:	85 c0                	test   %eax,%eax
f0101977:	75 24                	jne    f010199d <mem_init+0x711>
f0101979:	c7 44 24 0c 7a 5e 10 	movl   $0xf0105e7a,0xc(%esp)
f0101980:	f0 
f0101981:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101988:	f0 
f0101989:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101990:	00 
f0101991:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101998:	e8 21 e7 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010199d:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01019a0:	75 24                	jne    f01019c6 <mem_init+0x73a>
f01019a2:	c7 44 24 0c 90 5e 10 	movl   $0xf0105e90,0xc(%esp)
f01019a9:	f0 
f01019aa:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01019b1:	f0 
f01019b2:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f01019b9:	00 
f01019ba:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01019c1:	e8 f8 e6 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019c6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019c9:	74 04                	je     f01019cf <mem_init+0x743>
f01019cb:	39 c3                	cmp    %eax,%ebx
f01019cd:	75 24                	jne    f01019f3 <mem_init+0x767>
f01019cf:	c7 44 24 0c 94 57 10 	movl   $0xf0105794,0xc(%esp)
f01019d6:	f0 
f01019d7:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01019de:	f0 
f01019df:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f01019e6:	00 
f01019e7:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01019ee:	e8 cb e6 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019f3:	a1 00 d3 17 f0       	mov    0xf017d300,%eax
f01019f8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01019fb:	c7 05 00 d3 17 f0 00 	movl   $0x0,0xf017d300
f0101a02:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a05:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a0c:	e8 e5 f4 ff ff       	call   f0100ef6 <page_alloc>
f0101a11:	85 c0                	test   %eax,%eax
f0101a13:	74 24                	je     f0101a39 <mem_init+0x7ad>
f0101a15:	c7 44 24 0c f9 5e 10 	movl   $0xf0105ef9,0xc(%esp)
f0101a1c:	f0 
f0101a1d:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101a24:	f0 
f0101a25:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101a2c:	00 
f0101a2d:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101a34:	e8 85 e6 ff ff       	call   f01000be <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a39:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a3c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a40:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a47:	00 
f0101a48:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101a4d:	89 04 24             	mov    %eax,(%esp)
f0101a50:	e8 ee f6 ff ff       	call   f0101143 <page_lookup>
f0101a55:	85 c0                	test   %eax,%eax
f0101a57:	74 24                	je     f0101a7d <mem_init+0x7f1>
f0101a59:	c7 44 24 0c d4 57 10 	movl   $0xf01057d4,0xc(%esp)
f0101a60:	f0 
f0101a61:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101a68:	f0 
f0101a69:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0101a70:	00 
f0101a71:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101a78:	e8 41 e6 ff ff       	call   f01000be <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a7d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a84:	00 
f0101a85:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a8c:	00 
f0101a8d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a94:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101a99:	89 04 24             	mov    %eax,(%esp)
f0101a9c:	e8 58 f7 ff ff       	call   f01011f9 <page_insert>
f0101aa1:	85 c0                	test   %eax,%eax
f0101aa3:	78 24                	js     f0101ac9 <mem_init+0x83d>
f0101aa5:	c7 44 24 0c 0c 58 10 	movl   $0xf010580c,0xc(%esp)
f0101aac:	f0 
f0101aad:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101ab4:	f0 
f0101ab5:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0101abc:	00 
f0101abd:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101ac4:	e8 f5 e5 ff ff       	call   f01000be <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101ac9:	89 1c 24             	mov    %ebx,(%esp)
f0101acc:	e8 aa f4 ff ff       	call   f0100f7b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ad1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ad8:	00 
f0101ad9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ae0:	00 
f0101ae1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ae4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ae8:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101aed:	89 04 24             	mov    %eax,(%esp)
f0101af0:	e8 04 f7 ff ff       	call   f01011f9 <page_insert>
f0101af5:	85 c0                	test   %eax,%eax
f0101af7:	74 24                	je     f0101b1d <mem_init+0x891>
f0101af9:	c7 44 24 0c 3c 58 10 	movl   $0xf010583c,0xc(%esp)
f0101b00:	f0 
f0101b01:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101b08:	f0 
f0101b09:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101b10:	00 
f0101b11:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101b18:	e8 a1 e5 ff ff       	call   f01000be <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b1d:	8b 3d c8 df 17 f0    	mov    0xf017dfc8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b23:	a1 cc df 17 f0       	mov    0xf017dfcc,%eax
f0101b28:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b2b:	8b 17                	mov    (%edi),%edx
f0101b2d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b33:	89 d9                	mov    %ebx,%ecx
f0101b35:	29 c1                	sub    %eax,%ecx
f0101b37:	89 c8                	mov    %ecx,%eax
f0101b39:	c1 f8 03             	sar    $0x3,%eax
f0101b3c:	c1 e0 0c             	shl    $0xc,%eax
f0101b3f:	39 c2                	cmp    %eax,%edx
f0101b41:	74 24                	je     f0101b67 <mem_init+0x8db>
f0101b43:	c7 44 24 0c 6c 58 10 	movl   $0xf010586c,0xc(%esp)
f0101b4a:	f0 
f0101b4b:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101b52:	f0 
f0101b53:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101b5a:	00 
f0101b5b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101b62:	e8 57 e5 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b67:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b6c:	89 f8                	mov    %edi,%eax
f0101b6e:	e8 ca ee ff ff       	call   f0100a3d <check_va2pa>
f0101b73:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b76:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b79:	c1 fa 03             	sar    $0x3,%edx
f0101b7c:	c1 e2 0c             	shl    $0xc,%edx
f0101b7f:	39 d0                	cmp    %edx,%eax
f0101b81:	74 24                	je     f0101ba7 <mem_init+0x91b>
f0101b83:	c7 44 24 0c 94 58 10 	movl   $0xf0105894,0xc(%esp)
f0101b8a:	f0 
f0101b8b:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101b92:	f0 
f0101b93:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0101b9a:	00 
f0101b9b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101ba2:	e8 17 e5 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f0101ba7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101baa:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101baf:	74 24                	je     f0101bd5 <mem_init+0x949>
f0101bb1:	c7 44 24 0c 4b 5f 10 	movl   $0xf0105f4b,0xc(%esp)
f0101bb8:	f0 
f0101bb9:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101bc0:	f0 
f0101bc1:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0101bc8:	00 
f0101bc9:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101bd0:	e8 e9 e4 ff ff       	call   f01000be <_panic>
	assert(pp0->pp_ref == 1);
f0101bd5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bda:	74 24                	je     f0101c00 <mem_init+0x974>
f0101bdc:	c7 44 24 0c 5c 5f 10 	movl   $0xf0105f5c,0xc(%esp)
f0101be3:	f0 
f0101be4:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101beb:	f0 
f0101bec:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0101bf3:	00 
f0101bf4:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101bfb:	e8 be e4 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c00:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c07:	00 
f0101c08:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c0f:	00 
f0101c10:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c14:	89 3c 24             	mov    %edi,(%esp)
f0101c17:	e8 dd f5 ff ff       	call   f01011f9 <page_insert>
f0101c1c:	85 c0                	test   %eax,%eax
f0101c1e:	74 24                	je     f0101c44 <mem_init+0x9b8>
f0101c20:	c7 44 24 0c c4 58 10 	movl   $0xf01058c4,0xc(%esp)
f0101c27:	f0 
f0101c28:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101c2f:	f0 
f0101c30:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101c37:	00 
f0101c38:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101c3f:	e8 7a e4 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c44:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c49:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101c4e:	e8 ea ed ff ff       	call   f0100a3d <check_va2pa>
f0101c53:	89 f2                	mov    %esi,%edx
f0101c55:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0101c5b:	c1 fa 03             	sar    $0x3,%edx
f0101c5e:	c1 e2 0c             	shl    $0xc,%edx
f0101c61:	39 d0                	cmp    %edx,%eax
f0101c63:	74 24                	je     f0101c89 <mem_init+0x9fd>
f0101c65:	c7 44 24 0c 00 59 10 	movl   $0xf0105900,0xc(%esp)
f0101c6c:	f0 
f0101c6d:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101c74:	f0 
f0101c75:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0101c7c:	00 
f0101c7d:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101c84:	e8 35 e4 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101c89:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c8e:	74 24                	je     f0101cb4 <mem_init+0xa28>
f0101c90:	c7 44 24 0c 6d 5f 10 	movl   $0xf0105f6d,0xc(%esp)
f0101c97:	f0 
f0101c98:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101c9f:	f0 
f0101ca0:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0101ca7:	00 
f0101ca8:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101caf:	e8 0a e4 ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101cb4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cbb:	e8 36 f2 ff ff       	call   f0100ef6 <page_alloc>
f0101cc0:	85 c0                	test   %eax,%eax
f0101cc2:	74 24                	je     f0101ce8 <mem_init+0xa5c>
f0101cc4:	c7 44 24 0c f9 5e 10 	movl   $0xf0105ef9,0xc(%esp)
f0101ccb:	f0 
f0101ccc:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101cd3:	f0 
f0101cd4:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0101cdb:	00 
f0101cdc:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101ce3:	e8 d6 e3 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ce8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cef:	00 
f0101cf0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cf7:	00 
f0101cf8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cfc:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101d01:	89 04 24             	mov    %eax,(%esp)
f0101d04:	e8 f0 f4 ff ff       	call   f01011f9 <page_insert>
f0101d09:	85 c0                	test   %eax,%eax
f0101d0b:	74 24                	je     f0101d31 <mem_init+0xaa5>
f0101d0d:	c7 44 24 0c c4 58 10 	movl   $0xf01058c4,0xc(%esp)
f0101d14:	f0 
f0101d15:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101d1c:	f0 
f0101d1d:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101d24:	00 
f0101d25:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101d2c:	e8 8d e3 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d31:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d36:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101d3b:	e8 fd ec ff ff       	call   f0100a3d <check_va2pa>
f0101d40:	89 f2                	mov    %esi,%edx
f0101d42:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0101d48:	c1 fa 03             	sar    $0x3,%edx
f0101d4b:	c1 e2 0c             	shl    $0xc,%edx
f0101d4e:	39 d0                	cmp    %edx,%eax
f0101d50:	74 24                	je     f0101d76 <mem_init+0xaea>
f0101d52:	c7 44 24 0c 00 59 10 	movl   $0xf0105900,0xc(%esp)
f0101d59:	f0 
f0101d5a:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101d61:	f0 
f0101d62:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f0101d69:	00 
f0101d6a:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101d71:	e8 48 e3 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101d76:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d7b:	74 24                	je     f0101da1 <mem_init+0xb15>
f0101d7d:	c7 44 24 0c 6d 5f 10 	movl   $0xf0105f6d,0xc(%esp)
f0101d84:	f0 
f0101d85:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101d8c:	f0 
f0101d8d:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0101d94:	00 
f0101d95:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101d9c:	e8 1d e3 ff ff       	call   f01000be <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101da1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101da8:	e8 49 f1 ff ff       	call   f0100ef6 <page_alloc>
f0101dad:	85 c0                	test   %eax,%eax
f0101daf:	74 24                	je     f0101dd5 <mem_init+0xb49>
f0101db1:	c7 44 24 0c f9 5e 10 	movl   $0xf0105ef9,0xc(%esp)
f0101db8:	f0 
f0101db9:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101dc0:	f0 
f0101dc1:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101dc8:	00 
f0101dc9:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101dd0:	e8 e9 e2 ff ff       	call   f01000be <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101dd5:	8b 15 c8 df 17 f0    	mov    0xf017dfc8,%edx
f0101ddb:	8b 02                	mov    (%edx),%eax
f0101ddd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101de2:	89 c1                	mov    %eax,%ecx
f0101de4:	c1 e9 0c             	shr    $0xc,%ecx
f0101de7:	3b 0d c4 df 17 f0    	cmp    0xf017dfc4,%ecx
f0101ded:	72 20                	jb     f0101e0f <mem_init+0xb83>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101def:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101df3:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0101dfa:	f0 
f0101dfb:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0101e02:	00 
f0101e03:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101e0a:	e8 af e2 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0101e0f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e14:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101e17:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e1e:	00 
f0101e1f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e26:	00 
f0101e27:	89 14 24             	mov    %edx,(%esp)
f0101e2a:	e8 84 f1 ff ff       	call   f0100fb3 <pgdir_walk>
f0101e2f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101e32:	8d 51 04             	lea    0x4(%ecx),%edx
f0101e35:	39 d0                	cmp    %edx,%eax
f0101e37:	74 24                	je     f0101e5d <mem_init+0xbd1>
f0101e39:	c7 44 24 0c 30 59 10 	movl   $0xf0105930,0xc(%esp)
f0101e40:	f0 
f0101e41:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101e48:	f0 
f0101e49:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0101e50:	00 
f0101e51:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101e58:	e8 61 e2 ff ff       	call   f01000be <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e5d:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e64:	00 
f0101e65:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e6c:	00 
f0101e6d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e71:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101e76:	89 04 24             	mov    %eax,(%esp)
f0101e79:	e8 7b f3 ff ff       	call   f01011f9 <page_insert>
f0101e7e:	85 c0                	test   %eax,%eax
f0101e80:	74 24                	je     f0101ea6 <mem_init+0xc1a>
f0101e82:	c7 44 24 0c 70 59 10 	movl   $0xf0105970,0xc(%esp)
f0101e89:	f0 
f0101e8a:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101e91:	f0 
f0101e92:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101e99:	00 
f0101e9a:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101ea1:	e8 18 e2 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ea6:	8b 3d c8 df 17 f0    	mov    0xf017dfc8,%edi
f0101eac:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eb1:	89 f8                	mov    %edi,%eax
f0101eb3:	e8 85 eb ff ff       	call   f0100a3d <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101eb8:	89 f2                	mov    %esi,%edx
f0101eba:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0101ec0:	c1 fa 03             	sar    $0x3,%edx
f0101ec3:	c1 e2 0c             	shl    $0xc,%edx
f0101ec6:	39 d0                	cmp    %edx,%eax
f0101ec8:	74 24                	je     f0101eee <mem_init+0xc62>
f0101eca:	c7 44 24 0c 00 59 10 	movl   $0xf0105900,0xc(%esp)
f0101ed1:	f0 
f0101ed2:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101ed9:	f0 
f0101eda:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0101ee1:	00 
f0101ee2:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101ee9:	e8 d0 e1 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101eee:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ef3:	74 24                	je     f0101f19 <mem_init+0xc8d>
f0101ef5:	c7 44 24 0c 6d 5f 10 	movl   $0xf0105f6d,0xc(%esp)
f0101efc:	f0 
f0101efd:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101f04:	f0 
f0101f05:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0101f0c:	00 
f0101f0d:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101f14:	e8 a5 e1 ff ff       	call   f01000be <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101f19:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f20:	00 
f0101f21:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f28:	00 
f0101f29:	89 3c 24             	mov    %edi,(%esp)
f0101f2c:	e8 82 f0 ff ff       	call   f0100fb3 <pgdir_walk>
f0101f31:	f6 00 04             	testb  $0x4,(%eax)
f0101f34:	75 24                	jne    f0101f5a <mem_init+0xcce>
f0101f36:	c7 44 24 0c b0 59 10 	movl   $0xf01059b0,0xc(%esp)
f0101f3d:	f0 
f0101f3e:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101f45:	f0 
f0101f46:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0101f4d:	00 
f0101f4e:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101f55:	e8 64 e1 ff ff       	call   f01000be <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f5a:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101f5f:	f6 00 04             	testb  $0x4,(%eax)
f0101f62:	75 24                	jne    f0101f88 <mem_init+0xcfc>
f0101f64:	c7 44 24 0c 7e 5f 10 	movl   $0xf0105f7e,0xc(%esp)
f0101f6b:	f0 
f0101f6c:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101f73:	f0 
f0101f74:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0101f7b:	00 
f0101f7c:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101f83:	e8 36 e1 ff ff       	call   f01000be <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f88:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f8f:	00 
f0101f90:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f97:	00 
f0101f98:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101f9c:	89 04 24             	mov    %eax,(%esp)
f0101f9f:	e8 55 f2 ff ff       	call   f01011f9 <page_insert>
f0101fa4:	85 c0                	test   %eax,%eax
f0101fa6:	78 24                	js     f0101fcc <mem_init+0xd40>
f0101fa8:	c7 44 24 0c e4 59 10 	movl   $0xf01059e4,0xc(%esp)
f0101faf:	f0 
f0101fb0:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0101fb7:	f0 
f0101fb8:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0101fbf:	00 
f0101fc0:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0101fc7:	e8 f2 e0 ff ff       	call   f01000be <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fcc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fd3:	00 
f0101fd4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fdb:	00 
f0101fdc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fdf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101fe3:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0101fe8:	89 04 24             	mov    %eax,(%esp)
f0101feb:	e8 09 f2 ff ff       	call   f01011f9 <page_insert>
f0101ff0:	85 c0                	test   %eax,%eax
f0101ff2:	74 24                	je     f0102018 <mem_init+0xd8c>
f0101ff4:	c7 44 24 0c 1c 5a 10 	movl   $0xf0105a1c,0xc(%esp)
f0101ffb:	f0 
f0101ffc:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102003:	f0 
f0102004:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f010200b:	00 
f010200c:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102013:	e8 a6 e0 ff ff       	call   f01000be <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102018:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010201f:	00 
f0102020:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102027:	00 
f0102028:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f010202d:	89 04 24             	mov    %eax,(%esp)
f0102030:	e8 7e ef ff ff       	call   f0100fb3 <pgdir_walk>
f0102035:	f6 00 04             	testb  $0x4,(%eax)
f0102038:	74 24                	je     f010205e <mem_init+0xdd2>
f010203a:	c7 44 24 0c 58 5a 10 	movl   $0xf0105a58,0xc(%esp)
f0102041:	f0 
f0102042:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102049:	f0 
f010204a:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102051:	00 
f0102052:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102059:	e8 60 e0 ff ff       	call   f01000be <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010205e:	8b 3d c8 df 17 f0    	mov    0xf017dfc8,%edi
f0102064:	ba 00 00 00 00       	mov    $0x0,%edx
f0102069:	89 f8                	mov    %edi,%eax
f010206b:	e8 cd e9 ff ff       	call   f0100a3d <check_va2pa>
f0102070:	89 c1                	mov    %eax,%ecx
f0102072:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102075:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102078:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f010207e:	c1 f8 03             	sar    $0x3,%eax
f0102081:	c1 e0 0c             	shl    $0xc,%eax
f0102084:	39 c1                	cmp    %eax,%ecx
f0102086:	74 24                	je     f01020ac <mem_init+0xe20>
f0102088:	c7 44 24 0c 90 5a 10 	movl   $0xf0105a90,0xc(%esp)
f010208f:	f0 
f0102090:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102097:	f0 
f0102098:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f010209f:	00 
f01020a0:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01020a7:	e8 12 e0 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020ac:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020b1:	89 f8                	mov    %edi,%eax
f01020b3:	e8 85 e9 ff ff       	call   f0100a3d <check_va2pa>
f01020b8:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01020bb:	74 24                	je     f01020e1 <mem_init+0xe55>
f01020bd:	c7 44 24 0c bc 5a 10 	movl   $0xf0105abc,0xc(%esp)
f01020c4:	f0 
f01020c5:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01020cc:	f0 
f01020cd:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01020d4:	00 
f01020d5:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01020dc:	e8 dd df ff ff       	call   f01000be <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e4:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f01020e9:	74 24                	je     f010210f <mem_init+0xe83>
f01020eb:	c7 44 24 0c 94 5f 10 	movl   $0xf0105f94,0xc(%esp)
f01020f2:	f0 
f01020f3:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01020fa:	f0 
f01020fb:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102102:	00 
f0102103:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010210a:	e8 af df ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f010210f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102114:	74 24                	je     f010213a <mem_init+0xeae>
f0102116:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f010211d:	f0 
f010211e:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102125:	f0 
f0102126:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f010212d:	00 
f010212e:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102135:	e8 84 df ff ff       	call   f01000be <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010213a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102141:	e8 b0 ed ff ff       	call   f0100ef6 <page_alloc>
f0102146:	85 c0                	test   %eax,%eax
f0102148:	74 04                	je     f010214e <mem_init+0xec2>
f010214a:	39 c6                	cmp    %eax,%esi
f010214c:	74 24                	je     f0102172 <mem_init+0xee6>
f010214e:	c7 44 24 0c ec 5a 10 	movl   $0xf0105aec,0xc(%esp)
f0102155:	f0 
f0102156:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010215d:	f0 
f010215e:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102165:	00 
f0102166:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010216d:	e8 4c df ff ff       	call   f01000be <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102172:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102179:	00 
f010217a:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f010217f:	89 04 24             	mov    %eax,(%esp)
f0102182:	e8 34 f0 ff ff       	call   f01011bb <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102187:	8b 3d c8 df 17 f0    	mov    0xf017dfc8,%edi
f010218d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102192:	89 f8                	mov    %edi,%eax
f0102194:	e8 a4 e8 ff ff       	call   f0100a3d <check_va2pa>
f0102199:	83 f8 ff             	cmp    $0xffffffff,%eax
f010219c:	74 24                	je     f01021c2 <mem_init+0xf36>
f010219e:	c7 44 24 0c 10 5b 10 	movl   $0xf0105b10,0xc(%esp)
f01021a5:	f0 
f01021a6:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01021ad:	f0 
f01021ae:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f01021b5:	00 
f01021b6:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01021bd:	e8 fc de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021c2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021c7:	89 f8                	mov    %edi,%eax
f01021c9:	e8 6f e8 ff ff       	call   f0100a3d <check_va2pa>
f01021ce:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01021d1:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f01021d7:	c1 fa 03             	sar    $0x3,%edx
f01021da:	c1 e2 0c             	shl    $0xc,%edx
f01021dd:	39 d0                	cmp    %edx,%eax
f01021df:	74 24                	je     f0102205 <mem_init+0xf79>
f01021e1:	c7 44 24 0c bc 5a 10 	movl   $0xf0105abc,0xc(%esp)
f01021e8:	f0 
f01021e9:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01021f0:	f0 
f01021f1:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f01021f8:	00 
f01021f9:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102200:	e8 b9 de ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f0102205:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102208:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010220d:	74 24                	je     f0102233 <mem_init+0xfa7>
f010220f:	c7 44 24 0c 4b 5f 10 	movl   $0xf0105f4b,0xc(%esp)
f0102216:	f0 
f0102217:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010221e:	f0 
f010221f:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102226:	00 
f0102227:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010222e:	e8 8b de ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f0102233:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102238:	74 24                	je     f010225e <mem_init+0xfd2>
f010223a:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f0102241:	f0 
f0102242:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102249:	f0 
f010224a:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102251:	00 
f0102252:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102259:	e8 60 de ff ff       	call   f01000be <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010225e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102265:	00 
f0102266:	89 3c 24             	mov    %edi,(%esp)
f0102269:	e8 4d ef ff ff       	call   f01011bb <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010226e:	8b 3d c8 df 17 f0    	mov    0xf017dfc8,%edi
f0102274:	ba 00 00 00 00       	mov    $0x0,%edx
f0102279:	89 f8                	mov    %edi,%eax
f010227b:	e8 bd e7 ff ff       	call   f0100a3d <check_va2pa>
f0102280:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102283:	74 24                	je     f01022a9 <mem_init+0x101d>
f0102285:	c7 44 24 0c 10 5b 10 	movl   $0xf0105b10,0xc(%esp)
f010228c:	f0 
f010228d:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102294:	f0 
f0102295:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f010229c:	00 
f010229d:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01022a4:	e8 15 de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01022a9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022ae:	89 f8                	mov    %edi,%eax
f01022b0:	e8 88 e7 ff ff       	call   f0100a3d <check_va2pa>
f01022b5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022b8:	74 24                	je     f01022de <mem_init+0x1052>
f01022ba:	c7 44 24 0c 34 5b 10 	movl   $0xf0105b34,0xc(%esp)
f01022c1:	f0 
f01022c2:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01022c9:	f0 
f01022ca:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f01022d1:	00 
f01022d2:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01022d9:	e8 e0 dd ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f01022de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022e1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01022e6:	74 24                	je     f010230c <mem_init+0x1080>
f01022e8:	c7 44 24 0c b6 5f 10 	movl   $0xf0105fb6,0xc(%esp)
f01022ef:	f0 
f01022f0:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01022f7:	f0 
f01022f8:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01022ff:	00 
f0102300:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102307:	e8 b2 dd ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f010230c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102311:	74 24                	je     f0102337 <mem_init+0x10ab>
f0102313:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f010231a:	f0 
f010231b:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102322:	f0 
f0102323:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f010232a:	00 
f010232b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102332:	e8 87 dd ff ff       	call   f01000be <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102337:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010233e:	e8 b3 eb ff ff       	call   f0100ef6 <page_alloc>
f0102343:	85 c0                	test   %eax,%eax
f0102345:	74 05                	je     f010234c <mem_init+0x10c0>
f0102347:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010234a:	74 24                	je     f0102370 <mem_init+0x10e4>
f010234c:	c7 44 24 0c 5c 5b 10 	movl   $0xf0105b5c,0xc(%esp)
f0102353:	f0 
f0102354:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010235b:	f0 
f010235c:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102363:	00 
f0102364:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010236b:	e8 4e dd ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102370:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102377:	e8 7a eb ff ff       	call   f0100ef6 <page_alloc>
f010237c:	85 c0                	test   %eax,%eax
f010237e:	74 24                	je     f01023a4 <mem_init+0x1118>
f0102380:	c7 44 24 0c f9 5e 10 	movl   $0xf0105ef9,0xc(%esp)
f0102387:	f0 
f0102388:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010238f:	f0 
f0102390:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102397:	00 
f0102398:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010239f:	e8 1a dd ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023a4:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f01023a9:	8b 08                	mov    (%eax),%ecx
f01023ab:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01023b1:	89 da                	mov    %ebx,%edx
f01023b3:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f01023b9:	c1 fa 03             	sar    $0x3,%edx
f01023bc:	c1 e2 0c             	shl    $0xc,%edx
f01023bf:	39 d1                	cmp    %edx,%ecx
f01023c1:	74 24                	je     f01023e7 <mem_init+0x115b>
f01023c3:	c7 44 24 0c 6c 58 10 	movl   $0xf010586c,0xc(%esp)
f01023ca:	f0 
f01023cb:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01023d2:	f0 
f01023d3:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f01023da:	00 
f01023db:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01023e2:	e8 d7 dc ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f01023e7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01023ed:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023f2:	74 24                	je     f0102418 <mem_init+0x118c>
f01023f4:	c7 44 24 0c 5c 5f 10 	movl   $0xf0105f5c,0xc(%esp)
f01023fb:	f0 
f01023fc:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102403:	f0 
f0102404:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f010240b:	00 
f010240c:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102413:	e8 a6 dc ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f0102418:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010241e:	89 1c 24             	mov    %ebx,(%esp)
f0102421:	e8 55 eb ff ff       	call   f0100f7b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102426:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010242d:	00 
f010242e:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102435:	00 
f0102436:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f010243b:	89 04 24             	mov    %eax,(%esp)
f010243e:	e8 70 eb ff ff       	call   f0100fb3 <pgdir_walk>
f0102443:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102446:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102449:	8b 15 c8 df 17 f0    	mov    0xf017dfc8,%edx
f010244f:	8b 7a 04             	mov    0x4(%edx),%edi
f0102452:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102458:	8b 0d c4 df 17 f0    	mov    0xf017dfc4,%ecx
f010245e:	89 f8                	mov    %edi,%eax
f0102460:	c1 e8 0c             	shr    $0xc,%eax
f0102463:	39 c8                	cmp    %ecx,%eax
f0102465:	72 20                	jb     f0102487 <mem_init+0x11fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102467:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010246b:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0102472:	f0 
f0102473:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f010247a:	00 
f010247b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102482:	e8 37 dc ff ff       	call   f01000be <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102487:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010248d:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102490:	74 24                	je     f01024b6 <mem_init+0x122a>
f0102492:	c7 44 24 0c c7 5f 10 	movl   $0xf0105fc7,0xc(%esp)
f0102499:	f0 
f010249a:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01024a1:	f0 
f01024a2:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f01024a9:	00 
f01024aa:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01024b1:	e8 08 dc ff ff       	call   f01000be <_panic>
	kern_pgdir[PDX(va)] = 0;
f01024b6:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01024bd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c3:	89 d8                	mov    %ebx,%eax
f01024c5:	2b 05 cc df 17 f0    	sub    0xf017dfcc,%eax
f01024cb:	c1 f8 03             	sar    $0x3,%eax
f01024ce:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024d1:	89 c2                	mov    %eax,%edx
f01024d3:	c1 ea 0c             	shr    $0xc,%edx
f01024d6:	39 d1                	cmp    %edx,%ecx
f01024d8:	77 20                	ja     f01024fa <mem_init+0x126e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024de:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01024e5:	f0 
f01024e6:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01024ed:	00 
f01024ee:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f01024f5:	e8 c4 db ff ff       	call   f01000be <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01024fa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102501:	00 
f0102502:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102509:	00 
	return (void *)(pa + KERNBASE);
f010250a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010250f:	89 04 24             	mov    %eax,(%esp)
f0102512:	e8 32 27 00 00       	call   f0104c49 <memset>
	page_free(pp0);
f0102517:	89 1c 24             	mov    %ebx,(%esp)
f010251a:	e8 5c ea ff ff       	call   f0100f7b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010251f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102526:	00 
f0102527:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010252e:	00 
f010252f:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0102534:	89 04 24             	mov    %eax,(%esp)
f0102537:	e8 77 ea ff ff       	call   f0100fb3 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010253c:	89 da                	mov    %ebx,%edx
f010253e:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0102544:	c1 fa 03             	sar    $0x3,%edx
f0102547:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010254a:	89 d0                	mov    %edx,%eax
f010254c:	c1 e8 0c             	shr    $0xc,%eax
f010254f:	3b 05 c4 df 17 f0    	cmp    0xf017dfc4,%eax
f0102555:	72 20                	jb     f0102577 <mem_init+0x12eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102557:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010255b:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f0102562:	f0 
f0102563:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010256a:	00 
f010256b:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f0102572:	e8 47 db ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0102577:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010257d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102580:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102587:	75 11                	jne    f010259a <mem_init+0x130e>
f0102589:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
f010258f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0102595:	f6 00 01             	testb  $0x1,(%eax)
f0102598:	74 24                	je     f01025be <mem_init+0x1332>
f010259a:	c7 44 24 0c df 5f 10 	movl   $0xf0105fdf,0xc(%esp)
f01025a1:	f0 
f01025a2:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01025a9:	f0 
f01025aa:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f01025b1:	00 
f01025b2:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01025b9:	e8 00 db ff ff       	call   f01000be <_panic>
f01025be:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01025c1:	39 d0                	cmp    %edx,%eax
f01025c3:	75 d0                	jne    f0102595 <mem_init+0x1309>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01025c5:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f01025ca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01025d0:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f01025d6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01025d9:	a3 00 d3 17 f0       	mov    %eax,0xf017d300

	// free the pages we took
	page_free(pp0);
f01025de:	89 1c 24             	mov    %ebx,(%esp)
f01025e1:	e8 95 e9 ff ff       	call   f0100f7b <page_free>
	page_free(pp1);
f01025e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025e9:	89 04 24             	mov    %eax,(%esp)
f01025ec:	e8 8a e9 ff ff       	call   f0100f7b <page_free>
	page_free(pp2);
f01025f1:	89 34 24             	mov    %esi,(%esp)
f01025f4:	e8 82 e9 ff ff       	call   f0100f7b <page_free>

	cprintf("check_page() succeeded!\n");
f01025f9:	c7 04 24 f6 5f 10 f0 	movl   $0xf0105ff6,(%esp)
f0102600:	e8 55 10 00 00       	call   f010365a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f0102605:	a1 cc df 17 f0       	mov    0xf017dfcc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010260a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010260f:	77 20                	ja     f0102631 <mem_init+0x13a5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102611:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102615:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f010261c:	f0 
f010261d:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
f0102624:	00 
f0102625:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010262c:	e8 8d da ff ff       	call   f01000be <_panic>
f0102631:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102638:	00 
	return (physaddr_t)kva - KERNBASE;
f0102639:	05 00 00 00 10       	add    $0x10000000,%eax
f010263e:	89 04 24             	mov    %eax,(%esp)
f0102641:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102646:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010264b:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0102650:	e8 68 ea ff ff       	call   f01010bd <boot_map_region>
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U);
f0102655:	a1 0c d3 17 f0       	mov    0xf017d30c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010265a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010265f:	77 20                	ja     f0102681 <mem_init+0x13f5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102661:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102665:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f010266c:	f0 
f010266d:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
f0102674:	00 
f0102675:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010267c:	e8 3d da ff ff       	call   f01000be <_panic>
f0102681:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102688:	00 
	return (physaddr_t)kva - KERNBASE;
f0102689:	05 00 00 00 10       	add    $0x10000000,%eax
f010268e:	89 04 24             	mov    %eax,(%esp)
f0102691:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102696:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010269b:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f01026a0:	e8 18 ea ff ff       	call   f01010bd <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a5:	bb 00 10 11 f0       	mov    $0xf0111000,%ebx
f01026aa:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026b0:	77 20                	ja     f01026d2 <mem_init+0x1446>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01026b6:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f01026bd:	f0 
f01026be:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
f01026c5:	00 
f01026c6:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01026cd:	e8 ec d9 ff ff       	call   f01000be <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f01026d2:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01026d9:	00 
f01026da:	c7 04 24 00 10 11 00 	movl   $0x111000,(%esp)
f01026e1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026e6:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01026eb:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f01026f0:	e8 c8 e9 ff ff       	call   f01010bd <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff+1-KERNBASE,(physaddr_t)0,PTE_W);
f01026f5:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01026fc:	00 
f01026fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102704:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102709:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010270e:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0102713:	e8 a5 e9 ff ff       	call   f01010bd <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102718:	8b 3d c8 df 17 f0    	mov    0xf017dfc8,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f010271e:	a1 c4 df 17 f0       	mov    0xf017dfc4,%eax
f0102723:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102726:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f010272d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102732:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102735:	75 37                	jne    f010276e <mem_init+0x14e2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102737:	8b 35 0c d3 17 f0    	mov    0xf017d30c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010273d:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102740:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102745:	89 f8                	mov    %edi,%eax
f0102747:	e8 f1 e2 ff ff       	call   f0100a3d <check_va2pa>
f010274c:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102752:	0f 86 a0 00 00 00    	jbe    f01027f8 <mem_init+0x156c>
f0102758:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010275d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102760:	81 c1 00 00 40 21    	add    $0x21400000,%ecx
f0102766:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102769:	e9 aa 00 00 00       	jmp    f0102818 <mem_init+0x158c>
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010276e:	8b 35 cc df 17 f0    	mov    0xf017dfcc,%esi
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102774:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010277a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010277d:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102782:	89 f8                	mov    %edi,%eax
f0102784:	e8 b4 e2 ff ff       	call   f0100a3d <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102789:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010278f:	77 20                	ja     f01027b1 <mem_init+0x1525>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102791:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102795:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f010279c:	f0 
f010279d:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f01027a4:	00 
f01027a5:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01027ac:	e8 0d d9 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027b1:	ba 00 00 00 00       	mov    $0x0,%edx
f01027b6:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01027b9:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027bc:	39 c1                	cmp    %eax,%ecx
f01027be:	74 24                	je     f01027e4 <mem_init+0x1558>
f01027c0:	c7 44 24 0c 80 5b 10 	movl   $0xf0105b80,0xc(%esp)
f01027c7:	f0 
f01027c8:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01027cf:	f0 
f01027d0:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f01027d7:	00 
f01027d8:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01027df:	e8 da d8 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027e4:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f01027ea:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f01027ed:	0f 87 af 05 00 00    	ja     f0102da2 <mem_init+0x1b16>
f01027f3:	e9 3f ff ff ff       	jmp    f0102737 <mem_init+0x14ab>
f01027f8:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01027fc:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0102803:	f0 
f0102804:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f010280b:	00 
f010280c:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102813:	e8 a6 d8 ff ff       	call   f01000be <_panic>
f0102818:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010281b:	8d 14 31             	lea    (%ecx,%esi,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010281e:	39 c2                	cmp    %eax,%edx
f0102820:	74 24                	je     f0102846 <mem_init+0x15ba>
f0102822:	c7 44 24 0c b4 5b 10 	movl   $0xf0105bb4,0xc(%esp)
f0102829:	f0 
f010282a:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102831:	f0 
f0102832:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0102839:	00 
f010283a:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102841:	e8 78 d8 ff ff       	call   f01000be <_panic>
f0102846:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010284c:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102852:	0f 85 3c 05 00 00    	jne    f0102d94 <mem_init+0x1b08>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102858:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010285b:	c1 e0 0c             	shl    $0xc,%eax
f010285e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102861:	85 c0                	test   %eax,%eax
f0102863:	0f 84 0c 05 00 00    	je     f0102d75 <mem_init+0x1ae9>
f0102869:	be 00 00 00 00       	mov    $0x0,%esi
f010286e:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102874:	89 f8                	mov    %edi,%eax
f0102876:	e8 c2 e1 ff ff       	call   f0100a3d <check_va2pa>
f010287b:	39 c6                	cmp    %eax,%esi
f010287d:	74 24                	je     f01028a3 <mem_init+0x1617>
f010287f:	c7 44 24 0c e8 5b 10 	movl   $0xf0105be8,0xc(%esp)
f0102886:	f0 
f0102887:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010288e:	f0 
f010288f:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0102896:	00 
f0102897:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010289e:	e8 1b d8 ff ff       	call   f01000be <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028a3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028a9:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01028ac:	72 c0                	jb     f010286e <mem_init+0x15e2>
f01028ae:	e9 c2 04 00 00       	jmp    f0102d75 <mem_init+0x1ae9>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028b3:	39 c6                	cmp    %eax,%esi
f01028b5:	74 24                	je     f01028db <mem_init+0x164f>
f01028b7:	c7 44 24 0c 10 5c 10 	movl   $0xf0105c10,0xc(%esp)
f01028be:	f0 
f01028bf:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01028c6:	f0 
f01028c7:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f01028ce:	00 
f01028cf:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01028d6:	e8 e3 d7 ff ff       	call   f01000be <_panic>
f01028db:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028e1:	81 fe 00 90 11 00    	cmp    $0x119000,%esi
f01028e7:	0f 85 77 04 00 00    	jne    f0102d64 <mem_init+0x1ad8>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028ed:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01028f2:	89 f8                	mov    %edi,%eax
f01028f4:	e8 44 e1 ff ff       	call   f0100a3d <check_va2pa>
f01028f9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028fc:	74 24                	je     f0102922 <mem_init+0x1696>
f01028fe:	c7 44 24 0c 58 5c 10 	movl   $0xf0105c58,0xc(%esp)
f0102905:	f0 
f0102906:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010290d:	f0 
f010290e:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0102915:	00 
f0102916:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010291d:	e8 9c d7 ff ff       	call   f01000be <_panic>
f0102922:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102927:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010292d:	83 fa 03             	cmp    $0x3,%edx
f0102930:	77 2e                	ja     f0102960 <mem_init+0x16d4>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102932:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102936:	0f 85 aa 00 00 00    	jne    f01029e6 <mem_init+0x175a>
f010293c:	c7 44 24 0c 0f 60 10 	movl   $0xf010600f,0xc(%esp)
f0102943:	f0 
f0102944:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010294b:	f0 
f010294c:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0102953:	00 
f0102954:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010295b:	e8 5e d7 ff ff       	call   f01000be <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102960:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102965:	76 55                	jbe    f01029bc <mem_init+0x1730>
				assert(pgdir[i] & PTE_P);
f0102967:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010296a:	f6 c2 01             	test   $0x1,%dl
f010296d:	75 24                	jne    f0102993 <mem_init+0x1707>
f010296f:	c7 44 24 0c 0f 60 10 	movl   $0xf010600f,0xc(%esp)
f0102976:	f0 
f0102977:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f010297e:	f0 
f010297f:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0102986:	00 
f0102987:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f010298e:	e8 2b d7 ff ff       	call   f01000be <_panic>
				assert(pgdir[i] & PTE_W);
f0102993:	f6 c2 02             	test   $0x2,%dl
f0102996:	75 4e                	jne    f01029e6 <mem_init+0x175a>
f0102998:	c7 44 24 0c 20 60 10 	movl   $0xf0106020,0xc(%esp)
f010299f:	f0 
f01029a0:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01029a7:	f0 
f01029a8:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f01029af:	00 
f01029b0:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01029b7:	e8 02 d7 ff ff       	call   f01000be <_panic>
			} else
				assert(pgdir[i] == 0);
f01029bc:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029c0:	74 24                	je     f01029e6 <mem_init+0x175a>
f01029c2:	c7 44 24 0c 31 60 10 	movl   $0xf0106031,0xc(%esp)
f01029c9:	f0 
f01029ca:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f01029d1:	f0 
f01029d2:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f01029d9:	00 
f01029da:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f01029e1:	e8 d8 d6 ff ff       	call   f01000be <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01029e6:	83 c0 01             	add    $0x1,%eax
f01029e9:	3d 00 04 00 00       	cmp    $0x400,%eax
f01029ee:	0f 85 33 ff ff ff    	jne    f0102927 <mem_init+0x169b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01029f4:	c7 04 24 88 5c 10 f0 	movl   $0xf0105c88,(%esp)
f01029fb:	e8 5a 0c 00 00       	call   f010365a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a00:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a05:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a0a:	77 20                	ja     f0102a2c <mem_init+0x17a0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a0c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a10:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0102a17:	f0 
f0102a18:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
f0102a1f:	00 
f0102a20:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102a27:	e8 92 d6 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a2c:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a31:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a34:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a39:	e8 6e e0 ff ff       	call   f0100aac <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a3e:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a41:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a44:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a49:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a4c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a53:	e8 9e e4 ff ff       	call   f0100ef6 <page_alloc>
f0102a58:	89 c3                	mov    %eax,%ebx
f0102a5a:	85 c0                	test   %eax,%eax
f0102a5c:	75 24                	jne    f0102a82 <mem_init+0x17f6>
f0102a5e:	c7 44 24 0c 4e 5e 10 	movl   $0xf0105e4e,0xc(%esp)
f0102a65:	f0 
f0102a66:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102a6d:	f0 
f0102a6e:	c7 44 24 04 dd 03 00 	movl   $0x3dd,0x4(%esp)
f0102a75:	00 
f0102a76:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102a7d:	e8 3c d6 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0102a82:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a89:	e8 68 e4 ff ff       	call   f0100ef6 <page_alloc>
f0102a8e:	89 c7                	mov    %eax,%edi
f0102a90:	85 c0                	test   %eax,%eax
f0102a92:	75 24                	jne    f0102ab8 <mem_init+0x182c>
f0102a94:	c7 44 24 0c 64 5e 10 	movl   $0xf0105e64,0xc(%esp)
f0102a9b:	f0 
f0102a9c:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102aa3:	f0 
f0102aa4:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102aab:	00 
f0102aac:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102ab3:	e8 06 d6 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0102ab8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102abf:	e8 32 e4 ff ff       	call   f0100ef6 <page_alloc>
f0102ac4:	89 c6                	mov    %eax,%esi
f0102ac6:	85 c0                	test   %eax,%eax
f0102ac8:	75 24                	jne    f0102aee <mem_init+0x1862>
f0102aca:	c7 44 24 0c 7a 5e 10 	movl   $0xf0105e7a,0xc(%esp)
f0102ad1:	f0 
f0102ad2:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102ad9:	f0 
f0102ada:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0102ae1:	00 
f0102ae2:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102ae9:	e8 d0 d5 ff ff       	call   f01000be <_panic>
	page_free(pp0);
f0102aee:	89 1c 24             	mov    %ebx,(%esp)
f0102af1:	e8 85 e4 ff ff       	call   f0100f7b <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102af6:	89 f8                	mov    %edi,%eax
f0102af8:	e8 fb de ff ff       	call   f01009f8 <page2kva>
f0102afd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b04:	00 
f0102b05:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102b0c:	00 
f0102b0d:	89 04 24             	mov    %eax,(%esp)
f0102b10:	e8 34 21 00 00       	call   f0104c49 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b15:	89 f0                	mov    %esi,%eax
f0102b17:	e8 dc de ff ff       	call   f01009f8 <page2kva>
f0102b1c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b23:	00 
f0102b24:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102b2b:	00 
f0102b2c:	89 04 24             	mov    %eax,(%esp)
f0102b2f:	e8 15 21 00 00       	call   f0104c49 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b34:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b3b:	00 
f0102b3c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b43:	00 
f0102b44:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b48:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0102b4d:	89 04 24             	mov    %eax,(%esp)
f0102b50:	e8 a4 e6 ff ff       	call   f01011f9 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b55:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b5a:	74 24                	je     f0102b80 <mem_init+0x18f4>
f0102b5c:	c7 44 24 0c 4b 5f 10 	movl   $0xf0105f4b,0xc(%esp)
f0102b63:	f0 
f0102b64:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102b6b:	f0 
f0102b6c:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0102b73:	00 
f0102b74:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102b7b:	e8 3e d5 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b80:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b87:	01 01 01 
f0102b8a:	74 24                	je     f0102bb0 <mem_init+0x1924>
f0102b8c:	c7 44 24 0c a8 5c 10 	movl   $0xf0105ca8,0xc(%esp)
f0102b93:	f0 
f0102b94:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102b9b:	f0 
f0102b9c:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102ba3:	00 
f0102ba4:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102bab:	e8 0e d5 ff ff       	call   f01000be <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bb0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bb7:	00 
f0102bb8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bbf:	00 
f0102bc0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102bc4:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0102bc9:	89 04 24             	mov    %eax,(%esp)
f0102bcc:	e8 28 e6 ff ff       	call   f01011f9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bd1:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bd8:	02 02 02 
f0102bdb:	74 24                	je     f0102c01 <mem_init+0x1975>
f0102bdd:	c7 44 24 0c cc 5c 10 	movl   $0xf0105ccc,0xc(%esp)
f0102be4:	f0 
f0102be5:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102bec:	f0 
f0102bed:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102bf4:	00 
f0102bf5:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102bfc:	e8 bd d4 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0102c01:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c06:	74 24                	je     f0102c2c <mem_init+0x19a0>
f0102c08:	c7 44 24 0c 6d 5f 10 	movl   $0xf0105f6d,0xc(%esp)
f0102c0f:	f0 
f0102c10:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102c17:	f0 
f0102c18:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f0102c1f:	00 
f0102c20:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102c27:	e8 92 d4 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f0102c2c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c31:	74 24                	je     f0102c57 <mem_init+0x19cb>
f0102c33:	c7 44 24 0c b6 5f 10 	movl   $0xf0105fb6,0xc(%esp)
f0102c3a:	f0 
f0102c3b:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102c42:	f0 
f0102c43:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102c4a:	00 
f0102c4b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102c52:	e8 67 d4 ff ff       	call   f01000be <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c57:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c5e:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c61:	89 f0                	mov    %esi,%eax
f0102c63:	e8 90 dd ff ff       	call   f01009f8 <page2kva>
f0102c68:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102c6e:	74 24                	je     f0102c94 <mem_init+0x1a08>
f0102c70:	c7 44 24 0c f0 5c 10 	movl   $0xf0105cf0,0xc(%esp)
f0102c77:	f0 
f0102c78:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102c7f:	f0 
f0102c80:	c7 44 24 04 eb 03 00 	movl   $0x3eb,0x4(%esp)
f0102c87:	00 
f0102c88:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102c8f:	e8 2a d4 ff ff       	call   f01000be <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c94:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c9b:	00 
f0102c9c:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0102ca1:	89 04 24             	mov    %eax,(%esp)
f0102ca4:	e8 12 e5 ff ff       	call   f01011bb <page_remove>
	assert(pp2->pp_ref == 0);
f0102ca9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102cae:	74 24                	je     f0102cd4 <mem_init+0x1a48>
f0102cb0:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f0102cb7:	f0 
f0102cb8:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102cbf:	f0 
f0102cc0:	c7 44 24 04 ed 03 00 	movl   $0x3ed,0x4(%esp)
f0102cc7:	00 
f0102cc8:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102ccf:	e8 ea d3 ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cd4:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0102cd9:	8b 08                	mov    (%eax),%ecx
f0102cdb:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ce1:	89 da                	mov    %ebx,%edx
f0102ce3:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f0102ce9:	c1 fa 03             	sar    $0x3,%edx
f0102cec:	c1 e2 0c             	shl    $0xc,%edx
f0102cef:	39 d1                	cmp    %edx,%ecx
f0102cf1:	74 24                	je     f0102d17 <mem_init+0x1a8b>
f0102cf3:	c7 44 24 0c 6c 58 10 	movl   $0xf010586c,0xc(%esp)
f0102cfa:	f0 
f0102cfb:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102d02:	f0 
f0102d03:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f0102d0a:	00 
f0102d0b:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102d12:	e8 a7 d3 ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f0102d17:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d1d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d22:	74 24                	je     f0102d48 <mem_init+0x1abc>
f0102d24:	c7 44 24 0c 5c 5f 10 	movl   $0xf0105f5c,0xc(%esp)
f0102d2b:	f0 
f0102d2c:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0102d33:	f0 
f0102d34:	c7 44 24 04 f2 03 00 	movl   $0x3f2,0x4(%esp)
f0102d3b:	00 
f0102d3c:	c7 04 24 8b 5d 10 f0 	movl   $0xf0105d8b,(%esp)
f0102d43:	e8 76 d3 ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f0102d48:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102d4e:	89 1c 24             	mov    %ebx,(%esp)
f0102d51:	e8 25 e2 ff ff       	call   f0100f7b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d56:	c7 04 24 1c 5d 10 f0 	movl   $0xf0105d1c,(%esp)
f0102d5d:	e8 f8 08 00 00       	call   f010365a <cprintf>
f0102d62:	eb 52                	jmp    f0102db6 <mem_init+0x1b2a>
f0102d64:	8d 14 33             	lea    (%ebx,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102d67:	89 f8                	mov    %edi,%eax
f0102d69:	e8 cf dc ff ff       	call   f0100a3d <check_va2pa>
f0102d6e:	66 90                	xchg   %ax,%ax
f0102d70:	e9 3e fb ff ff       	jmp    f01028b3 <mem_init+0x1627>
f0102d75:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102d7a:	89 f8                	mov    %edi,%eax
f0102d7c:	e8 bc dc ff ff       	call   f0100a3d <check_va2pa>
f0102d81:	be 00 10 11 00       	mov    $0x111000,%esi
f0102d86:	ba 00 80 bf df       	mov    $0xdfbf8000,%edx
f0102d8b:	29 da                	sub    %ebx,%edx
f0102d8d:	89 d3                	mov    %edx,%ebx
f0102d8f:	e9 1f fb ff ff       	jmp    f01028b3 <mem_init+0x1627>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102d94:	89 f2                	mov    %esi,%edx
f0102d96:	89 f8                	mov    %edi,%eax
f0102d98:	e8 a0 dc ff ff       	call   f0100a3d <check_va2pa>
f0102d9d:	e9 76 fa ff ff       	jmp    f0102818 <mem_init+0x158c>
f0102da2:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102da8:	89 f8                	mov    %edi,%eax
f0102daa:	e8 8e dc ff ff       	call   f0100a3d <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102daf:	89 f2                	mov    %esi,%edx
f0102db1:	e9 00 fa ff ff       	jmp    f01027b6 <mem_init+0x152a>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102db6:	83 c4 3c             	add    $0x3c,%esp
f0102db9:	5b                   	pop    %ebx
f0102dba:	5e                   	pop    %esi
f0102dbb:	5f                   	pop    %edi
f0102dbc:	5d                   	pop    %ebp
f0102dbd:	c3                   	ret    

f0102dbe <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102dbe:	55                   	push   %ebp
f0102dbf:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102dc1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dc4:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102dc7:	5d                   	pop    %ebp
f0102dc8:	c3                   	ret    

f0102dc9 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102dc9:	55                   	push   %ebp
f0102dca:	89 e5                	mov    %esp,%ebp
f0102dcc:	57                   	push   %edi
f0102dcd:	56                   	push   %esi
f0102dce:	53                   	push   %ebx
f0102dcf:	83 ec 3c             	sub    $0x3c,%esp
f0102dd2:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	     int i=0;
		int res=0;
		int t=(int)va;
		for(i=ROUNDDOWN(t,PGSIZE);i<ROUNDUP(t+len,PGSIZE);i+=PGSIZE)
f0102dd5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dd8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102dde:	8b 45 10             	mov    0x10(%ebp),%eax
f0102de1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102de4:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0102deb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102df0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102df3:	39 c3                	cmp    %eax,%ebx
f0102df5:	0f 83 8e 00 00 00    	jae    f0102e89 <user_mem_check+0xc0>
f0102dfb:	89 de                	mov    %ebx,%esi
			pte_t* store=0;
			struct Page* pg=page_lookup(env->env_pgdir, (void*)i, &store);
			if(store!=NULL)
			{
				//cprintf("pte!=NULL %08x\r\n",*store);
			   if((((*store) &(perm|PTE_P))!=(perm|PTE_P)) || i>ULIM)
f0102dfd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e00:	83 c8 01             	or     $0x1,%eax
f0102e03:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	     int i=0;
		int res=0;
		int t=(int)va;
		for(i=ROUNDDOWN(t,PGSIZE);i<ROUNDUP(t+len,PGSIZE);i+=PGSIZE)
		{
			pte_t* store=0;
f0102e06:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			struct Page* pg=page_lookup(env->env_pgdir, (void*)i, &store);
f0102e0d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102e10:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102e14:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102e18:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102e1b:	89 04 24             	mov    %eax,(%esp)
f0102e1e:	e8 20 e3 ff ff       	call   f0101143 <page_lookup>
			if(store!=NULL)
f0102e23:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e26:	85 c0                	test   %eax,%eax
f0102e28:	74 2e                	je     f0102e58 <user_mem_check+0x8f>
			{
				//cprintf("pte!=NULL %08x\r\n",*store);
			   if((((*store) &(perm|PTE_P))!=(perm|PTE_P)) || i>ULIM)
f0102e2a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102e2d:	89 ca                	mov    %ecx,%edx
f0102e2f:	23 10                	and    (%eax),%edx
f0102e31:	39 d1                	cmp    %edx,%ecx
f0102e33:	75 08                	jne    f0102e3d <user_mem_check+0x74>
f0102e35:	81 fe 00 00 80 ef    	cmp    $0xef800000,%esi
f0102e3b:	76 36                	jbe    f0102e73 <user_mem_check+0xaa>
			   {
				cprintf("pte protect!\r\n");
f0102e3d:	c7 04 24 3f 60 10 f0 	movl   $0xf010603f,(%esp)
f0102e44:	e8 11 08 00 00       	call   f010365a <cprintf>
				res=-E_FAULT;
				if(i<(uint32_t)va)
					user_mem_check_addr=(uint32_t)va;
f0102e49:	39 75 0c             	cmp    %esi,0xc(%ebp)
f0102e4c:	0f 47 75 0c          	cmova  0xc(%ebp),%esi
f0102e50:	89 35 fc d2 17 f0    	mov    %esi,0xf017d2fc
f0102e56:	eb 2a                	jmp    f0102e82 <user_mem_check+0xb9>
				break;
			   }
			}
			else
			{
				cprintf("no pte!\r\n");
f0102e58:	c7 04 24 4e 60 10 f0 	movl   $0xf010604e,(%esp)
f0102e5f:	e8 f6 07 00 00       	call   f010365a <cprintf>
				res=-E_FAULT;
				if(i<(uint32_t)va)
					user_mem_check_addr=(uint32_t)va;
f0102e64:	39 75 0c             	cmp    %esi,0xc(%ebp)
f0102e67:	0f 47 75 0c          	cmova  0xc(%ebp),%esi
f0102e6b:	89 35 fc d2 17 f0    	mov    %esi,0xf017d2fc
f0102e71:	eb 0f                	jmp    f0102e82 <user_mem_check+0xb9>
{
	// LAB 3: Your code here.
	     int i=0;
		int res=0;
		int t=(int)va;
		for(i=ROUNDDOWN(t,PGSIZE);i<ROUNDUP(t+len,PGSIZE);i+=PGSIZE)
f0102e73:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e79:	89 de                	mov    %ebx,%esi
f0102e7b:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f0102e7e:	72 86                	jb     f0102e06 <user_mem_check+0x3d>
f0102e80:	eb 0e                	jmp    f0102e90 <user_mem_check+0xc7>
				res=-E_FAULT;
				if(i<(uint32_t)va)
					user_mem_check_addr=(uint32_t)va;
				else
					user_mem_check_addr=i;
				break;
f0102e82:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e87:	eb 0c                	jmp    f0102e95 <user_mem_check+0xcc>
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	     int i=0;
		int res=0;
f0102e89:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e8e:	eb 05                	jmp    f0102e95 <user_mem_check+0xcc>
f0102e90:	b8 00 00 00 00       	mov    $0x0,%eax
				break;
			}

		}
          return res;
}
f0102e95:	83 c4 3c             	add    $0x3c,%esp
f0102e98:	5b                   	pop    %ebx
f0102e99:	5e                   	pop    %esi
f0102e9a:	5f                   	pop    %edi
f0102e9b:	5d                   	pop    %ebp
f0102e9c:	c3                   	ret    

f0102e9d <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102e9d:	55                   	push   %ebp
f0102e9e:	89 e5                	mov    %esp,%ebp
f0102ea0:	53                   	push   %ebx
f0102ea1:	83 ec 14             	sub    $0x14,%esp
f0102ea4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102ea7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eaa:	83 c8 04             	or     $0x4,%eax
f0102ead:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102eb1:	8b 45 10             	mov    0x10(%ebp),%eax
f0102eb4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102eb8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ebb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ebf:	89 1c 24             	mov    %ebx,(%esp)
f0102ec2:	e8 02 ff ff ff       	call   f0102dc9 <user_mem_check>
f0102ec7:	85 c0                	test   %eax,%eax
f0102ec9:	79 24                	jns    f0102eef <user_mem_assert+0x52>
		cprintf(".%08x. user_mem_check assertion failure for "
f0102ecb:	a1 fc d2 17 f0       	mov    0xf017d2fc,%eax
f0102ed0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102ed4:	8b 43 48             	mov    0x48(%ebx),%eax
f0102ed7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102edb:	c7 04 24 48 5d 10 f0 	movl   $0xf0105d48,(%esp)
f0102ee2:	e8 73 07 00 00       	call   f010365a <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102ee7:	89 1c 24             	mov    %ebx,(%esp)
f0102eea:	e8 4f 06 00 00       	call   f010353e <env_destroy>
	}
}
f0102eef:	83 c4 14             	add    $0x14,%esp
f0102ef2:	5b                   	pop    %ebx
f0102ef3:	5d                   	pop    %ebp
f0102ef4:	c3                   	ret    

f0102ef5 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102ef5:	55                   	push   %ebp
f0102ef6:	89 e5                	mov    %esp,%ebp
f0102ef8:	57                   	push   %edi
f0102ef9:	56                   	push   %esi
f0102efa:	53                   	push   %ebx
f0102efb:	83 ec 1c             	sub    $0x1c,%esp
f0102efe:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//
	void* bottom=ROUNDDOWN(va,PGSIZE);  //round down for 4k.
f0102f00:	89 d3                	mov    %edx,%ebx
f0102f02:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* top=ROUNDUP(va+len,PGSIZE);   //round up for 4k
f0102f08:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102f0f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	void* i=bottom;
	for(;i<top;i+=PGSIZE){
f0102f15:	39 f3                	cmp    %esi,%ebx
f0102f17:	73 51                	jae    f0102f6a <region_alloc+0x75>
		struct Page* p=page_alloc(0); //not zero
f0102f19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f20:	e8 d1 df ff ff       	call   f0100ef6 <page_alloc>
		if(p==NULL){
f0102f25:	85 c0                	test   %eax,%eax
f0102f27:	75 1c                	jne    f0102f45 <region_alloc+0x50>
			panic("Memory is full!");
f0102f29:	c7 44 24 08 58 60 10 	movl   $0xf0106058,0x8(%esp)
f0102f30:	f0 
f0102f31:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
f0102f38:	00 
f0102f39:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f0102f40:	e8 79 d1 ff ff       	call   f01000be <_panic>
		}
		page_insert(e->env_pgdir,p,i,PTE_W|PTE_U);  //map env at va.
f0102f45:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102f4c:	00 
f0102f4d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102f51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f55:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f58:	89 04 24             	mov    %eax,(%esp)
f0102f5b:	e8 99 e2 ff ff       	call   f01011f9 <page_insert>
	//   (Watch out for corner-cases!)
	//
	void* bottom=ROUNDDOWN(va,PGSIZE);  //round down for 4k.
	void* top=ROUNDUP(va+len,PGSIZE);   //round up for 4k
	void* i=bottom;
	for(;i<top;i+=PGSIZE){
f0102f60:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f66:	39 de                	cmp    %ebx,%esi
f0102f68:	77 af                	ja     f0102f19 <region_alloc+0x24>
		if(p==NULL){
			panic("Memory is full!");
		}
		page_insert(e->env_pgdir,p,i,PTE_W|PTE_U);  //map env at va.
	}
}
f0102f6a:	83 c4 1c             	add    $0x1c,%esp
f0102f6d:	5b                   	pop    %ebx
f0102f6e:	5e                   	pop    %esi
f0102f6f:	5f                   	pop    %edi
f0102f70:	5d                   	pop    %ebp
f0102f71:	c3                   	ret    

f0102f72 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102f72:	55                   	push   %ebp
f0102f73:	89 e5                	mov    %esp,%ebp
f0102f75:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102f78:	85 c0                	test   %eax,%eax
f0102f7a:	75 11                	jne    f0102f8d <envid2env+0x1b>
		*env_store = curenv;
f0102f7c:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0102f81:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102f84:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102f86:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f8b:	eb 60                	jmp    f0102fed <envid2env+0x7b>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102f8d:	89 c2                	mov    %eax,%edx
f0102f8f:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102f95:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102f98:	c1 e2 05             	shl    $0x5,%edx
f0102f9b:	03 15 0c d3 17 f0    	add    0xf017d30c,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102fa1:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0102fa5:	74 05                	je     f0102fac <envid2env+0x3a>
f0102fa7:	39 42 48             	cmp    %eax,0x48(%edx)
f0102faa:	74 10                	je     f0102fbc <envid2env+0x4a>
		*env_store = 0;
f0102fac:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102faf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102fb5:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102fba:	eb 31                	jmp    f0102fed <envid2env+0x7b>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102fbc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102fc0:	74 21                	je     f0102fe3 <envid2env+0x71>
f0102fc2:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0102fc7:	39 c2                	cmp    %eax,%edx
f0102fc9:	74 18                	je     f0102fe3 <envid2env+0x71>
f0102fcb:	8b 40 48             	mov    0x48(%eax),%eax
f0102fce:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0102fd1:	74 10                	je     f0102fe3 <envid2env+0x71>
		*env_store = 0;
f0102fd3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fd6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102fdc:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102fe1:	eb 0a                	jmp    f0102fed <envid2env+0x7b>
	}

	*env_store = e;
f0102fe3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fe6:	89 10                	mov    %edx,(%eax)
	return 0;
f0102fe8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fed:	5d                   	pop    %ebp
f0102fee:	c3                   	ret    

f0102fef <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102fef:	55                   	push   %ebp
f0102ff0:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102ff2:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102ff7:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102ffa:	b8 23 00 00 00       	mov    $0x23,%eax
f0102fff:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103001:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103003:	b0 10                	mov    $0x10,%al
f0103005:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0103007:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0103009:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010300b:	ea 12 30 10 f0 08 00 	ljmp   $0x8,$0xf0103012
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0103012:	b0 00                	mov    $0x0,%al
f0103014:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103017:	5d                   	pop    %ebp
f0103018:	c3                   	ret    

f0103019 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103019:	55                   	push   %ebp
f010301a:	89 e5                	mov    %esp,%ebp
f010301c:	57                   	push   %edi
f010301d:	56                   	push   %esi
f010301e:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i=0;
	for(i=0;i<NENV;i++){
		envs[i].env_id=0;
f010301f:	8b 1d 0c d3 17 f0    	mov    0xf017d30c,%ebx
f0103025:	c7 43 48 00 00 00 00 	movl   $0x0,0x48(%ebx)
f010302c:	89 df                	mov    %ebx,%edi
f010302e:	8d 53 60             	lea    0x60(%ebx),%edx
f0103031:	89 de                	mov    %ebx,%esi
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i=0;
	for(i=0;i<NENV;i++){
f0103033:	b8 00 00 00 00       	mov    $0x0,%eax
		envs[i].env_id=0;
f0103038:	b9 00 00 00 00       	mov    $0x0,%ecx
f010303d:	eb 02                	jmp    f0103041 <env_init+0x28>
f010303f:	89 fb                	mov    %edi,%ebx
		if(i!=NENV-1){
			envs[i].env_link=&envs[i+1];
f0103041:	8d 4c 49 03          	lea    0x3(%ecx,%ecx,2),%ecx
f0103045:	c1 e1 05             	shl    $0x5,%ecx
f0103048:	01 cb                	add    %ecx,%ebx
f010304a:	89 5e 44             	mov    %ebx,0x44(%esi)
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i=0;
	for(i=0;i<NENV;i++){
f010304d:	83 c0 01             	add    $0x1,%eax
		envs[i].env_id=0;
f0103050:	89 c1                	mov    %eax,%ecx
f0103052:	89 d6                	mov    %edx,%esi
f0103054:	c7 42 48 00 00 00 00 	movl   $0x0,0x48(%edx)
f010305b:	83 c2 60             	add    $0x60,%edx
		if(i!=NENV-1){
f010305e:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0103063:	75 da                	jne    f010303f <env_init+0x26>
			envs[i].env_link=&envs[i+1];
		}
	}
	env_free_list=envs;
f0103065:	a1 0c d3 17 f0       	mov    0xf017d30c,%eax
f010306a:	a3 10 d3 17 f0       	mov    %eax,0xf017d310
	// Per-CPU part of the initialization
	env_init_percpu();
f010306f:	e8 7b ff ff ff       	call   f0102fef <env_init_percpu>
}
f0103074:	5b                   	pop    %ebx
f0103075:	5e                   	pop    %esi
f0103076:	5f                   	pop    %edi
f0103077:	5d                   	pop    %ebp
f0103078:	c3                   	ret    

f0103079 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103079:	55                   	push   %ebp
f010307a:	89 e5                	mov    %esp,%ebp
f010307c:	53                   	push   %ebx
f010307d:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103080:	8b 1d 10 d3 17 f0    	mov    0xf017d310,%ebx
f0103086:	85 db                	test   %ebx,%ebx
f0103088:	0f 84 79 01 00 00    	je     f0103207 <env_alloc+0x18e>
static int
env_setup_vm(struct Env *e)
{
	int i;
	struct Page *p = NULL;
	cprintf("env_setup_vm\r\n");
f010308e:	c7 04 24 73 60 10 f0 	movl   $0xf0106073,(%esp)
f0103095:	e8 c0 05 00 00       	call   f010365a <cprintf>

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010309a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01030a1:	e8 50 de ff ff       	call   f0100ef6 <page_alloc>
f01030a6:	85 c0                	test   %eax,%eax
f01030a8:	0f 84 60 01 00 00    	je     f010320e <env_alloc+0x195>
f01030ae:	89 c2                	mov    %eax,%edx
f01030b0:	2b 15 cc df 17 f0    	sub    0xf017dfcc,%edx
f01030b6:	c1 fa 03             	sar    $0x3,%edx
f01030b9:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01030bc:	89 d1                	mov    %edx,%ecx
f01030be:	c1 e9 0c             	shr    $0xc,%ecx
f01030c1:	3b 0d c4 df 17 f0    	cmp    0xf017dfc4,%ecx
f01030c7:	72 20                	jb     f01030e9 <env_alloc+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01030c9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01030cd:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f01030d4:	f0 
f01030d5:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01030dc:	00 
f01030dd:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f01030e4:	e8 d5 cf ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f01030e9:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01030ef:	89 53 5c             	mov    %edx,0x5c(%ebx)
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir=(pde_t*)page2kva(p);
	p->pp_ref++;  //increase th reference count.
f01030f2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

	//for(i=PDX(UTOP);i<1024;i++)
	//	e->env_pgdir[i]=kern_pgdir[i];
	memmove(e->env_pgdir,kern_pgdir,PGSIZE);  //copy pgdir.
f01030f7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01030fe:	00 
f01030ff:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
f0103104:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103108:	8b 43 5c             	mov    0x5c(%ebx),%eax
f010310b:	89 04 24             	mov    %eax,(%esp)
f010310e:	e8 83 1b 00 00       	call   f0104c96 <memmove>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103113:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103116:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010311b:	77 20                	ja     f010313d <env_alloc+0xc4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010311d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103121:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0103128:	f0 
f0103129:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f0103130:	00 
f0103131:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f0103138:	e8 81 cf ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f010313d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103143:	83 ca 05             	or     $0x5,%edx
f0103146:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010314c:	8b 43 48             	mov    0x48(%ebx),%eax
f010314f:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103154:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103159:	ba 00 10 00 00       	mov    $0x1000,%edx
f010315e:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103161:	89 da                	mov    %ebx,%edx
f0103163:	2b 15 0c d3 17 f0    	sub    0xf017d30c,%edx
f0103169:	c1 fa 05             	sar    $0x5,%edx
f010316c:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103172:	09 d0                	or     %edx,%eax
f0103174:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103177:	8b 45 0c             	mov    0xc(%ebp),%eax
f010317a:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010317d:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103184:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f010318b:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103192:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103199:	00 
f010319a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01031a1:	00 
f01031a2:	89 1c 24             	mov    %ebx,(%esp)
f01031a5:	e8 9f 1a 00 00       	call   f0104c49 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01031aa:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01031b0:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01031b6:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01031bc:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01031c3:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01031c9:	8b 43 44             	mov    0x44(%ebx),%eax
f01031cc:	a3 10 d3 17 f0       	mov    %eax,0xf017d310
	*newenv_store = e;
f01031d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01031d4:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031d6:	8b 53 48             	mov    0x48(%ebx),%edx
f01031d9:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f01031de:	85 c0                	test   %eax,%eax
f01031e0:	74 05                	je     f01031e7 <env_alloc+0x16e>
f01031e2:	8b 40 48             	mov    0x48(%eax),%eax
f01031e5:	eb 05                	jmp    f01031ec <env_alloc+0x173>
f01031e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01031ec:	89 54 24 08          	mov    %edx,0x8(%esp)
f01031f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031f4:	c7 04 24 82 60 10 f0 	movl   $0xf0106082,(%esp)
f01031fb:	e8 5a 04 00 00       	call   f010365a <cprintf>
	return 0;
f0103200:	b8 00 00 00 00       	mov    $0x0,%eax
f0103205:	eb 0c                	jmp    f0103213 <env_alloc+0x19a>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103207:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010320c:	eb 05                	jmp    f0103213 <env_alloc+0x19a>
	struct Page *p = NULL;
	cprintf("env_setup_vm\r\n");

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010320e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103213:	83 c4 14             	add    $0x14,%esp
f0103216:	5b                   	pop    %ebx
f0103217:	5d                   	pop    %ebp
f0103218:	c3                   	ret    

f0103219 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f0103219:	55                   	push   %ebp
f010321a:	89 e5                	mov    %esp,%ebp
f010321c:	57                   	push   %edi
f010321d:	56                   	push   %esi
f010321e:	53                   	push   %ebx
f010321f:	83 ec 3c             	sub    $0x3c,%esp
f0103222:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *temp;
	env_alloc(&temp,0);
f0103225:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010322c:	00 
f010322d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103230:	89 04 24             	mov    %eax,(%esp)
f0103233:	e8 41 fe ff ff       	call   f0103079 <env_alloc>
	temp->env_type=type;
f0103238:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010323b:	89 c2                	mov    %eax,%edx
f010323d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103240:	8b 45 10             	mov    0x10(%ebp),%eax
f0103243:	89 42 50             	mov    %eax,0x50(%edx)
	//
	// read elf file.

	struct Elf* ELFHDR=(struct Elf*)binary;
	//is this a valid ELF?
	if(ELFHDR->e_magic!=ELF_MAGIC)
f0103246:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010324c:	74 1c                	je     f010326a <env_create+0x51>
		panic("Not executable elf file!");
f010324e:	c7 44 24 08 97 60 10 	movl   $0xf0106097,0x8(%esp)
f0103255:	f0 
f0103256:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
f010325d:	00 
f010325e:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f0103265:	e8 54 ce ff ff       	call   f01000be <_panic>
	//load each program segment
	struct Proghdr *ph,*eph;
	ph=(struct Proghdr*)((uint8_t*)ELFHDR+ELFHDR->e_phoff);
f010326a:	89 fb                	mov    %edi,%ebx
f010326c:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph=ph+ELFHDR->e_phnum;
f010326f:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103273:	c1 e6 05             	shl    $0x5,%esi
f0103276:	01 de                	add    %ebx,%esi
	//load env pgdir.
	lcr3(PADDR(e->env_pgdir));
f0103278:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010327b:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010327e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103283:	77 20                	ja     f01032a5 <env_create+0x8c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103285:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103289:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0103290:	f0 
f0103291:	c7 44 24 04 6c 01 00 	movl   $0x16c,0x4(%esp)
f0103298:	00 
f0103299:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f01032a0:	e8 19 ce ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032a5:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01032aa:	0f 22 d8             	mov    %eax,%cr3
	for(;ph<eph;ph++){
f01032ad:	39 f3                	cmp    %esi,%ebx
f01032af:	73 4f                	jae    f0103300 <env_create+0xe7>
		if(ph->p_type==ELF_PROG_LOAD){   
f01032b1:	83 3b 01             	cmpl   $0x1,(%ebx)
f01032b4:	75 43                	jne    f01032f9 <env_create+0xe0>
			region_alloc(e,(void*)ph->p_va,ph->p_memsz);
f01032b6:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01032b9:	8b 53 08             	mov    0x8(%ebx),%edx
f01032bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032bf:	e8 31 fc ff ff       	call   f0102ef5 <region_alloc>
			//initial to '0'
			memset((void *)ph->p_va,0,ph->p_memsz);
f01032c4:	8b 43 14             	mov    0x14(%ebx),%eax
f01032c7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01032d2:	00 
f01032d3:	8b 43 08             	mov    0x8(%ebx),%eax
f01032d6:	89 04 24             	mov    %eax,(%esp)
f01032d9:	e8 6b 19 00 00       	call   f0104c49 <memset>
			memmove((void *)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f01032de:	8b 43 10             	mov    0x10(%ebx),%eax
f01032e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032e5:	89 f8                	mov    %edi,%eax
f01032e7:	03 43 04             	add    0x4(%ebx),%eax
f01032ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032ee:	8b 43 08             	mov    0x8(%ebx),%eax
f01032f1:	89 04 24             	mov    %eax,(%esp)
f01032f4:	e8 9d 19 00 00       	call   f0104c96 <memmove>
	struct Proghdr *ph,*eph;
	ph=(struct Proghdr*)((uint8_t*)ELFHDR+ELFHDR->e_phoff);
	eph=ph+ELFHDR->e_phnum;
	//load env pgdir.
	lcr3(PADDR(e->env_pgdir));
	for(;ph<eph;ph++){
f01032f9:	83 c3 20             	add    $0x20,%ebx
f01032fc:	39 de                	cmp    %ebx,%esi
f01032fe:	77 b1                	ja     f01032b1 <env_create+0x98>
			//for(i=0;i<ph->p_filesz;i++)
			//	va[i]=binary[ph->p_offset+i];
		}
	}
	//make sure env starts here.
	e->env_tf.tf_eip=ELFHDR->e_entry;
f0103300:	8b 47 18             	mov    0x18(%edi),%eax
f0103303:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103306:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);
f0103309:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010330e:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103313:	89 f8                	mov    %edi,%eax
f0103315:	e8 db fb ff ff       	call   f0102ef5 <region_alloc>
	//return to kern pgdir.
	lcr3(PADDR(kern_pgdir));
f010331a:	a1 c8 df 17 f0       	mov    0xf017dfc8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010331f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103324:	77 20                	ja     f0103346 <env_create+0x12d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103326:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010332a:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0103331:	f0 
f0103332:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
f0103339:	00 
f010333a:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f0103341:	e8 78 cd ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103346:	05 00 00 00 10       	add    $0x10000000,%eax
f010334b:	0f 22 d8             	mov    %eax,%cr3
	// LAB 3: Your code here.
	struct Env *temp;
	env_alloc(&temp,0);
	temp->env_type=type;
	load_icode(temp,binary,size);
}
f010334e:	83 c4 3c             	add    $0x3c,%esp
f0103351:	5b                   	pop    %ebx
f0103352:	5e                   	pop    %esi
f0103353:	5f                   	pop    %edi
f0103354:	5d                   	pop    %ebp
f0103355:	c3                   	ret    

f0103356 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103356:	55                   	push   %ebp
f0103357:	89 e5                	mov    %esp,%ebp
f0103359:	57                   	push   %edi
f010335a:	56                   	push   %esi
f010335b:	53                   	push   %ebx
f010335c:	83 ec 2c             	sub    $0x2c,%esp
f010335f:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103362:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103367:	39 c7                	cmp    %eax,%edi
f0103369:	75 37                	jne    f01033a2 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f010336b:	8b 15 c8 df 17 f0    	mov    0xf017dfc8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103371:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103377:	77 20                	ja     f0103399 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103379:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010337d:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0103384:	f0 
f0103385:	c7 44 24 04 a3 01 00 	movl   $0x1a3,0x4(%esp)
f010338c:	00 
f010338d:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f0103394:	e8 25 cd ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103399:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010339f:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01033a2:	8b 57 48             	mov    0x48(%edi),%edx
f01033a5:	85 c0                	test   %eax,%eax
f01033a7:	74 05                	je     f01033ae <env_free+0x58>
f01033a9:	8b 40 48             	mov    0x48(%eax),%eax
f01033ac:	eb 05                	jmp    f01033b3 <env_free+0x5d>
f01033ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01033b3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01033b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033bb:	c7 04 24 b0 60 10 f0 	movl   $0xf01060b0,(%esp)
f01033c2:	e8 93 02 00 00       	call   f010365a <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01033c7:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033ce:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01033d1:	89 c8                	mov    %ecx,%eax
f01033d3:	c1 e0 02             	shl    $0x2,%eax
f01033d6:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01033d9:	8b 47 5c             	mov    0x5c(%edi),%eax
f01033dc:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f01033df:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01033e5:	0f 84 b7 00 00 00    	je     f01034a2 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01033eb:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033f1:	89 f0                	mov    %esi,%eax
f01033f3:	c1 e8 0c             	shr    $0xc,%eax
f01033f6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01033f9:	3b 05 c4 df 17 f0    	cmp    0xf017dfc4,%eax
f01033ff:	72 20                	jb     f0103421 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103401:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103405:	c7 44 24 08 04 56 10 	movl   $0xf0105604,0x8(%esp)
f010340c:	f0 
f010340d:	c7 44 24 04 b2 01 00 	movl   $0x1b2,0x4(%esp)
f0103414:	00 
f0103415:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f010341c:	e8 9d cc ff ff       	call   f01000be <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103421:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103424:	c1 e0 16             	shl    $0x16,%eax
f0103427:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010342a:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010342f:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103436:	01 
f0103437:	74 17                	je     f0103450 <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103439:	89 d8                	mov    %ebx,%eax
f010343b:	c1 e0 0c             	shl    $0xc,%eax
f010343e:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103441:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103445:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103448:	89 04 24             	mov    %eax,(%esp)
f010344b:	e8 6b dd ff ff       	call   f01011bb <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103450:	83 c3 01             	add    $0x1,%ebx
f0103453:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103459:	75 d4                	jne    f010342f <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010345b:	8b 47 5c             	mov    0x5c(%edi),%eax
f010345e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103461:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103468:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010346b:	3b 05 c4 df 17 f0    	cmp    0xf017dfc4,%eax
f0103471:	72 1c                	jb     f010348f <env_free+0x139>
		panic("pa2page called with invalid pa");
f0103473:	c7 44 24 08 ec 56 10 	movl   $0xf01056ec,0x8(%esp)
f010347a:	f0 
f010347b:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103482:	00 
f0103483:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f010348a:	e8 2f cc ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f010348f:	a1 cc df 17 f0       	mov    0xf017dfcc,%eax
f0103494:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103497:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f010349a:	89 04 24             	mov    %eax,(%esp)
f010349d:	e8 ee da ff ff       	call   f0100f90 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034a2:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01034a6:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f01034ad:	0f 85 1b ff ff ff    	jne    f01033ce <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01034b3:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034b6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034bb:	77 20                	ja     f01034dd <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034c1:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f01034c8:	f0 
f01034c9:	c7 44 24 04 c0 01 00 	movl   $0x1c0,0x4(%esp)
f01034d0:	00 
f01034d1:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f01034d8:	e8 e1 cb ff ff       	call   f01000be <_panic>
	e->env_pgdir = 0;
f01034dd:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f01034e4:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034e9:	c1 e8 0c             	shr    $0xc,%eax
f01034ec:	3b 05 c4 df 17 f0    	cmp    0xf017dfc4,%eax
f01034f2:	72 1c                	jb     f0103510 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f01034f4:	c7 44 24 08 ec 56 10 	movl   $0xf01056ec,0x8(%esp)
f01034fb:	f0 
f01034fc:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103503:	00 
f0103504:	c7 04 24 7d 5d 10 f0 	movl   $0xf0105d7d,(%esp)
f010350b:	e8 ae cb ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f0103510:	8b 15 cc df 17 f0    	mov    0xf017dfcc,%edx
f0103516:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103519:	89 04 24             	mov    %eax,(%esp)
f010351c:	e8 6f da ff ff       	call   f0100f90 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103521:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103528:	a1 10 d3 17 f0       	mov    0xf017d310,%eax
f010352d:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103530:	89 3d 10 d3 17 f0    	mov    %edi,0xf017d310
}
f0103536:	83 c4 2c             	add    $0x2c,%esp
f0103539:	5b                   	pop    %ebx
f010353a:	5e                   	pop    %esi
f010353b:	5f                   	pop    %edi
f010353c:	5d                   	pop    %ebp
f010353d:	c3                   	ret    

f010353e <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f010353e:	55                   	push   %ebp
f010353f:	89 e5                	mov    %esp,%ebp
f0103541:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0103544:	8b 45 08             	mov    0x8(%ebp),%eax
f0103547:	89 04 24             	mov    %eax,(%esp)
f010354a:	e8 07 fe ff ff       	call   f0103356 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010354f:	c7 04 24 d4 60 10 f0 	movl   $0xf01060d4,(%esp)
f0103556:	e8 ff 00 00 00       	call   f010365a <cprintf>
	while (1)
		monitor(NULL);
f010355b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103562:	e8 fe d2 ff ff       	call   f0100865 <monitor>
f0103567:	eb f2                	jmp    f010355b <env_destroy+0x1d>

f0103569 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103569:	55                   	push   %ebp
f010356a:	89 e5                	mov    %esp,%ebp
f010356c:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f010356f:	8b 65 08             	mov    0x8(%ebp),%esp
f0103572:	61                   	popa   
f0103573:	07                   	pop    %es
f0103574:	1f                   	pop    %ds
f0103575:	83 c4 08             	add    $0x8,%esp
f0103578:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103579:	c7 44 24 08 c6 60 10 	movl   $0xf01060c6,0x8(%esp)
f0103580:	f0 
f0103581:	c7 44 24 04 e8 01 00 	movl   $0x1e8,0x4(%esp)
f0103588:	00 
f0103589:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f0103590:	e8 29 cb ff ff       	call   f01000be <_panic>

f0103595 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103595:	55                   	push   %ebp
f0103596:	89 e5                	mov    %esp,%ebp
f0103598:	83 ec 18             	sub    $0x18,%esp
f010359b:	8b 45 08             	mov    0x8(%ebp),%eax

	// LAB 3: Your code here.
	if(e->env_status==ENV_RUNNING){
		e->env_status=ENV_RUNNABLE;
	}
	curenv=e;
f010359e:	a3 08 d3 17 f0       	mov    %eax,0xf017d308
	e->env_status=ENV_RUNNING;
f01035a3:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	e->env_runs++;
f01035aa:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f01035ae:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01035b1:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01035b7:	77 20                	ja     f01035d9 <env_run+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035b9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01035bd:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f01035c4:	f0 
f01035c5:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
f01035cc:	00 
f01035cd:	c7 04 24 68 60 10 f0 	movl   $0xf0106068,(%esp)
f01035d4:	e8 e5 ca ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01035d9:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01035df:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&e->env_tf);
f01035e2:	89 04 24             	mov    %eax,(%esp)
f01035e5:	e8 7f ff ff ff       	call   f0103569 <env_pop_tf>

f01035ea <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01035ea:	55                   	push   %ebp
f01035eb:	89 e5                	mov    %esp,%ebp
f01035ed:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035f1:	ba 70 00 00 00       	mov    $0x70,%edx
f01035f6:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01035f7:	b2 71                	mov    $0x71,%dl
f01035f9:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01035fa:	0f b6 c0             	movzbl %al,%eax
}
f01035fd:	5d                   	pop    %ebp
f01035fe:	c3                   	ret    

f01035ff <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01035ff:	55                   	push   %ebp
f0103600:	89 e5                	mov    %esp,%ebp
f0103602:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103606:	ba 70 00 00 00       	mov    $0x70,%edx
f010360b:	ee                   	out    %al,(%dx)
f010360c:	b2 71                	mov    $0x71,%dl
f010360e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103611:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103612:	5d                   	pop    %ebp
f0103613:	c3                   	ret    

f0103614 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103614:	55                   	push   %ebp
f0103615:	89 e5                	mov    %esp,%ebp
f0103617:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010361a:	8b 45 08             	mov    0x8(%ebp),%eax
f010361d:	89 04 24             	mov    %eax,(%esp)
f0103620:	e8 13 d0 ff ff       	call   f0100638 <cputchar>
	*cnt++;
}
f0103625:	c9                   	leave  
f0103626:	c3                   	ret    

f0103627 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103627:	55                   	push   %ebp
f0103628:	89 e5                	mov    %esp,%ebp
f010362a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010362d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103634:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103637:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010363b:	8b 45 08             	mov    0x8(%ebp),%eax
f010363e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103642:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103645:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103649:	c7 04 24 14 36 10 f0 	movl   $0xf0103614,(%esp)
f0103650:	e8 af 0e 00 00       	call   f0104504 <vprintfmt>
	return cnt;
}
f0103655:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103658:	c9                   	leave  
f0103659:	c3                   	ret    

f010365a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010365a:	55                   	push   %ebp
f010365b:	89 e5                	mov    %esp,%ebp
f010365d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103660:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103663:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103667:	8b 45 08             	mov    0x8(%ebp),%eax
f010366a:	89 04 24             	mov    %eax,(%esp)
f010366d:	e8 b5 ff ff ff       	call   f0103627 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103672:	c9                   	leave  
f0103673:	c3                   	ret    
f0103674:	66 90                	xchg   %ax,%ax
f0103676:	66 90                	xchg   %ax,%ax
f0103678:	66 90                	xchg   %ax,%ax
f010367a:	66 90                	xchg   %ax,%ax
f010367c:	66 90                	xchg   %ax,%ax
f010367e:	66 90                	xchg   %ax,%ax

f0103680 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103680:	55                   	push   %ebp
f0103681:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103683:	c7 05 44 db 17 f0 00 	movl   $0xefc00000,0xf017db44
f010368a:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f010368d:	66 c7 05 48 db 17 f0 	movw   $0x10,0xf017db48
f0103694:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103696:	66 c7 05 48 b3 11 f0 	movw   $0x68,0xf011b348
f010369d:	68 00 
f010369f:	b8 40 db 17 f0       	mov    $0xf017db40,%eax
f01036a4:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f01036aa:	89 c2                	mov    %eax,%edx
f01036ac:	c1 ea 10             	shr    $0x10,%edx
f01036af:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f01036b5:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f01036bc:	c1 e8 18             	shr    $0x18,%eax
f01036bf:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01036c4:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01036cb:	b8 28 00 00 00       	mov    $0x28,%eax
f01036d0:	0f 00 d8             	ltr    %ax
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01036d3:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f01036d8:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01036db:	5d                   	pop    %ebp
f01036dc:	c3                   	ret    

f01036dd <trap_init>:
}


void
trap_init(void)
{
f01036dd:	55                   	push   %ebp
f01036de:	89 e5                	mov    %esp,%ebp
	extern void routine_align();
	extern void routine_mchk();
	extern void routine_simderr();
	extern void routine_syscall();

    SETGATE(idt[T_DIVIDE], 0, GD_KT, routine_divide, 0);
f01036e0:	b8 12 3e 10 f0       	mov    $0xf0103e12,%eax
f01036e5:	66 a3 20 d3 17 f0    	mov    %ax,0xf017d320
f01036eb:	66 c7 05 22 d3 17 f0 	movw   $0x8,0xf017d322
f01036f2:	08 00 
f01036f4:	c6 05 24 d3 17 f0 00 	movb   $0x0,0xf017d324
f01036fb:	c6 05 25 d3 17 f0 8e 	movb   $0x8e,0xf017d325
f0103702:	c1 e8 10             	shr    $0x10,%eax
f0103705:	66 a3 26 d3 17 f0    	mov    %ax,0xf017d326
    SETGATE(idt[T_DEBUG], 0, GD_KT, routine_debug, 0);
f010370b:	b8 18 3e 10 f0       	mov    $0xf0103e18,%eax
f0103710:	66 a3 28 d3 17 f0    	mov    %ax,0xf017d328
f0103716:	66 c7 05 2a d3 17 f0 	movw   $0x8,0xf017d32a
f010371d:	08 00 
f010371f:	c6 05 2c d3 17 f0 00 	movb   $0x0,0xf017d32c
f0103726:	c6 05 2d d3 17 f0 8e 	movb   $0x8e,0xf017d32d
f010372d:	c1 e8 10             	shr    $0x10,%eax
f0103730:	66 a3 2e d3 17 f0    	mov    %ax,0xf017d32e
    SETGATE(idt[T_NMI], 0, GD_KT, routine_nmi, 0);
f0103736:	b8 1e 3e 10 f0       	mov    $0xf0103e1e,%eax
f010373b:	66 a3 30 d3 17 f0    	mov    %ax,0xf017d330
f0103741:	66 c7 05 32 d3 17 f0 	movw   $0x8,0xf017d332
f0103748:	08 00 
f010374a:	c6 05 34 d3 17 f0 00 	movb   $0x0,0xf017d334
f0103751:	c6 05 35 d3 17 f0 8e 	movb   $0x8e,0xf017d335
f0103758:	c1 e8 10             	shr    $0x10,%eax
f010375b:	66 a3 36 d3 17 f0    	mov    %ax,0xf017d336
	SETGATE(idt[T_BRKPT], 0, GD_KT, routine_brkpt, 3);
f0103761:	b8 24 3e 10 f0       	mov    $0xf0103e24,%eax
f0103766:	66 a3 38 d3 17 f0    	mov    %ax,0xf017d338
f010376c:	66 c7 05 3a d3 17 f0 	movw   $0x8,0xf017d33a
f0103773:	08 00 
f0103775:	c6 05 3c d3 17 f0 00 	movb   $0x0,0xf017d33c
f010377c:	c6 05 3d d3 17 f0 ee 	movb   $0xee,0xf017d33d
f0103783:	c1 e8 10             	shr    $0x10,%eax
f0103786:	66 a3 3e d3 17 f0    	mov    %ax,0xf017d33e
    SETGATE(idt[T_OFLOW], 0, GD_KT, routine_oflow, 3);
f010378c:	b8 2a 3e 10 f0       	mov    $0xf0103e2a,%eax
f0103791:	66 a3 40 d3 17 f0    	mov    %ax,0xf017d340
f0103797:	66 c7 05 42 d3 17 f0 	movw   $0x8,0xf017d342
f010379e:	08 00 
f01037a0:	c6 05 44 d3 17 f0 00 	movb   $0x0,0xf017d344
f01037a7:	c6 05 45 d3 17 f0 ee 	movb   $0xee,0xf017d345
f01037ae:	c1 e8 10             	shr    $0x10,%eax
f01037b1:	66 a3 46 d3 17 f0    	mov    %ax,0xf017d346
    SETGATE(idt[T_BOUND], 0, GD_KT, routine_bound, 3);
f01037b7:	b8 30 3e 10 f0       	mov    $0xf0103e30,%eax
f01037bc:	66 a3 48 d3 17 f0    	mov    %ax,0xf017d348
f01037c2:	66 c7 05 4a d3 17 f0 	movw   $0x8,0xf017d34a
f01037c9:	08 00 
f01037cb:	c6 05 4c d3 17 f0 00 	movb   $0x0,0xf017d34c
f01037d2:	c6 05 4d d3 17 f0 ee 	movb   $0xee,0xf017d34d
f01037d9:	c1 e8 10             	shr    $0x10,%eax
f01037dc:	66 a3 4e d3 17 f0    	mov    %ax,0xf017d34e
	SETGATE(idt[T_ILLOP], 0, GD_KT, routine_illop, 0);
f01037e2:	b8 36 3e 10 f0       	mov    $0xf0103e36,%eax
f01037e7:	66 a3 50 d3 17 f0    	mov    %ax,0xf017d350
f01037ed:	66 c7 05 52 d3 17 f0 	movw   $0x8,0xf017d352
f01037f4:	08 00 
f01037f6:	c6 05 54 d3 17 f0 00 	movb   $0x0,0xf017d354
f01037fd:	c6 05 55 d3 17 f0 8e 	movb   $0x8e,0xf017d355
f0103804:	c1 e8 10             	shr    $0x10,%eax
f0103807:	66 a3 56 d3 17 f0    	mov    %ax,0xf017d356
    SETGATE(idt[T_DEVICE], 0, GD_KT, routine_device, 0);
f010380d:	b8 3c 3e 10 f0       	mov    $0xf0103e3c,%eax
f0103812:	66 a3 58 d3 17 f0    	mov    %ax,0xf017d358
f0103818:	66 c7 05 5a d3 17 f0 	movw   $0x8,0xf017d35a
f010381f:	08 00 
f0103821:	c6 05 5c d3 17 f0 00 	movb   $0x0,0xf017d35c
f0103828:	c6 05 5d d3 17 f0 8e 	movb   $0x8e,0xf017d35d
f010382f:	c1 e8 10             	shr    $0x10,%eax
f0103832:	66 a3 5e d3 17 f0    	mov    %ax,0xf017d35e
    SETGATE(idt[T_DBLFLT], 0, GD_KT, routine_dblflt, 0);
f0103838:	b8 42 3e 10 f0       	mov    $0xf0103e42,%eax
f010383d:	66 a3 60 d3 17 f0    	mov    %ax,0xf017d360
f0103843:	66 c7 05 62 d3 17 f0 	movw   $0x8,0xf017d362
f010384a:	08 00 
f010384c:	c6 05 64 d3 17 f0 00 	movb   $0x0,0xf017d364
f0103853:	c6 05 65 d3 17 f0 8e 	movb   $0x8e,0xf017d365
f010385a:	c1 e8 10             	shr    $0x10,%eax
f010385d:	66 a3 66 d3 17 f0    	mov    %ax,0xf017d366
    SETGATE(idt[T_TSS], 0, GD_KT, routine_tss, 0);
f0103863:	b8 46 3e 10 f0       	mov    $0xf0103e46,%eax
f0103868:	66 a3 70 d3 17 f0    	mov    %ax,0xf017d370
f010386e:	66 c7 05 72 d3 17 f0 	movw   $0x8,0xf017d372
f0103875:	08 00 
f0103877:	c6 05 74 d3 17 f0 00 	movb   $0x0,0xf017d374
f010387e:	c6 05 75 d3 17 f0 8e 	movb   $0x8e,0xf017d375
f0103885:	c1 e8 10             	shr    $0x10,%eax
f0103888:	66 a3 76 d3 17 f0    	mov    %ax,0xf017d376
    SETGATE(idt[T_SEGNP], 0, GD_KT, routine_segnp, 0);
f010388e:	b8 4a 3e 10 f0       	mov    $0xf0103e4a,%eax
f0103893:	66 a3 78 d3 17 f0    	mov    %ax,0xf017d378
f0103899:	66 c7 05 7a d3 17 f0 	movw   $0x8,0xf017d37a
f01038a0:	08 00 
f01038a2:	c6 05 7c d3 17 f0 00 	movb   $0x0,0xf017d37c
f01038a9:	c6 05 7d d3 17 f0 8e 	movb   $0x8e,0xf017d37d
f01038b0:	c1 e8 10             	shr    $0x10,%eax
f01038b3:	66 a3 7e d3 17 f0    	mov    %ax,0xf017d37e
    SETGATE(idt[T_STACK], 0, GD_KT, routine_stack, 0);
f01038b9:	b8 4e 3e 10 f0       	mov    $0xf0103e4e,%eax
f01038be:	66 a3 80 d3 17 f0    	mov    %ax,0xf017d380
f01038c4:	66 c7 05 82 d3 17 f0 	movw   $0x8,0xf017d382
f01038cb:	08 00 
f01038cd:	c6 05 84 d3 17 f0 00 	movb   $0x0,0xf017d384
f01038d4:	c6 05 85 d3 17 f0 8e 	movb   $0x8e,0xf017d385
f01038db:	c1 e8 10             	shr    $0x10,%eax
f01038de:	66 a3 86 d3 17 f0    	mov    %ax,0xf017d386
    SETGATE(idt[T_GPFLT], 0, GD_KT, routine_gpflt, 0);
f01038e4:	b8 52 3e 10 f0       	mov    $0xf0103e52,%eax
f01038e9:	66 a3 88 d3 17 f0    	mov    %ax,0xf017d388
f01038ef:	66 c7 05 8a d3 17 f0 	movw   $0x8,0xf017d38a
f01038f6:	08 00 
f01038f8:	c6 05 8c d3 17 f0 00 	movb   $0x0,0xf017d38c
f01038ff:	c6 05 8d d3 17 f0 8e 	movb   $0x8e,0xf017d38d
f0103906:	c1 e8 10             	shr    $0x10,%eax
f0103909:	66 a3 8e d3 17 f0    	mov    %ax,0xf017d38e
    SETGATE(idt[T_PGFLT], 0, GD_KT, routine_pgflt, 0);
f010390f:	b8 56 3e 10 f0       	mov    $0xf0103e56,%eax
f0103914:	66 a3 90 d3 17 f0    	mov    %ax,0xf017d390
f010391a:	66 c7 05 92 d3 17 f0 	movw   $0x8,0xf017d392
f0103921:	08 00 
f0103923:	c6 05 94 d3 17 f0 00 	movb   $0x0,0xf017d394
f010392a:	c6 05 95 d3 17 f0 8e 	movb   $0x8e,0xf017d395
f0103931:	c1 e8 10             	shr    $0x10,%eax
f0103934:	66 a3 96 d3 17 f0    	mov    %ax,0xf017d396
    SETGATE(idt[T_FPERR], 0, GD_KT, routine_fperr, 0);
f010393a:	b8 5a 3e 10 f0       	mov    $0xf0103e5a,%eax
f010393f:	66 a3 a0 d3 17 f0    	mov    %ax,0xf017d3a0
f0103945:	66 c7 05 a2 d3 17 f0 	movw   $0x8,0xf017d3a2
f010394c:	08 00 
f010394e:	c6 05 a4 d3 17 f0 00 	movb   $0x0,0xf017d3a4
f0103955:	c6 05 a5 d3 17 f0 8e 	movb   $0x8e,0xf017d3a5
f010395c:	c1 e8 10             	shr    $0x10,%eax
f010395f:	66 a3 a6 d3 17 f0    	mov    %ax,0xf017d3a6
    SETGATE(idt[T_ALIGN], 0, GD_KT, routine_align, 0);
f0103965:	b8 60 3e 10 f0       	mov    $0xf0103e60,%eax
f010396a:	66 a3 a8 d3 17 f0    	mov    %ax,0xf017d3a8
f0103970:	66 c7 05 aa d3 17 f0 	movw   $0x8,0xf017d3aa
f0103977:	08 00 
f0103979:	c6 05 ac d3 17 f0 00 	movb   $0x0,0xf017d3ac
f0103980:	c6 05 ad d3 17 f0 8e 	movb   $0x8e,0xf017d3ad
f0103987:	c1 e8 10             	shr    $0x10,%eax
f010398a:	66 a3 ae d3 17 f0    	mov    %ax,0xf017d3ae
    SETGATE(idt[T_MCHK], 0, GD_KT, routine_mchk, 0);
f0103990:	b8 64 3e 10 f0       	mov    $0xf0103e64,%eax
f0103995:	66 a3 b0 d3 17 f0    	mov    %ax,0xf017d3b0
f010399b:	66 c7 05 b2 d3 17 f0 	movw   $0x8,0xf017d3b2
f01039a2:	08 00 
f01039a4:	c6 05 b4 d3 17 f0 00 	movb   $0x0,0xf017d3b4
f01039ab:	c6 05 b5 d3 17 f0 8e 	movb   $0x8e,0xf017d3b5
f01039b2:	c1 e8 10             	shr    $0x10,%eax
f01039b5:	66 a3 b6 d3 17 f0    	mov    %ax,0xf017d3b6
    SETGATE(idt[T_SIMDERR], 0, GD_KT, routine_simderr, 0);
f01039bb:	b8 6a 3e 10 f0       	mov    $0xf0103e6a,%eax
f01039c0:	66 a3 b8 d3 17 f0    	mov    %ax,0xf017d3b8
f01039c6:	66 c7 05 ba d3 17 f0 	movw   $0x8,0xf017d3ba
f01039cd:	08 00 
f01039cf:	c6 05 bc d3 17 f0 00 	movb   $0x0,0xf017d3bc
f01039d6:	c6 05 bd d3 17 f0 8e 	movb   $0x8e,0xf017d3bd
f01039dd:	c1 e8 10             	shr    $0x10,%eax
f01039e0:	66 a3 be d3 17 f0    	mov    %ax,0xf017d3be

	SETGATE(idt[T_SYSCALL],0,GD_KT,routine_syscall,3);
f01039e6:	b8 70 3e 10 f0       	mov    $0xf0103e70,%eax
f01039eb:	66 a3 a0 d4 17 f0    	mov    %ax,0xf017d4a0
f01039f1:	66 c7 05 a2 d4 17 f0 	movw   $0x8,0xf017d4a2
f01039f8:	08 00 
f01039fa:	c6 05 a4 d4 17 f0 00 	movb   $0x0,0xf017d4a4
f0103a01:	c6 05 a5 d4 17 f0 ee 	movb   $0xee,0xf017d4a5
f0103a08:	c1 e8 10             	shr    $0x10,%eax
f0103a0b:	66 a3 a6 d4 17 f0    	mov    %ax,0xf017d4a6

	// Per-CPU setup 
	trap_init_percpu();
f0103a11:	e8 6a fc ff ff       	call   f0103680 <trap_init_percpu>
}
f0103a16:	5d                   	pop    %ebp
f0103a17:	c3                   	ret    

f0103a18 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a18:	55                   	push   %ebp
f0103a19:	89 e5                	mov    %esp,%ebp
f0103a1b:	53                   	push   %ebx
f0103a1c:	83 ec 14             	sub    $0x14,%esp
f0103a1f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a22:	8b 03                	mov    (%ebx),%eax
f0103a24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a28:	c7 04 24 0a 61 10 f0 	movl   $0xf010610a,(%esp)
f0103a2f:	e8 26 fc ff ff       	call   f010365a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a34:	8b 43 04             	mov    0x4(%ebx),%eax
f0103a37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a3b:	c7 04 24 19 61 10 f0 	movl   $0xf0106119,(%esp)
f0103a42:	e8 13 fc ff ff       	call   f010365a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a47:	8b 43 08             	mov    0x8(%ebx),%eax
f0103a4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a4e:	c7 04 24 28 61 10 f0 	movl   $0xf0106128,(%esp)
f0103a55:	e8 00 fc ff ff       	call   f010365a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a5a:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103a5d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a61:	c7 04 24 37 61 10 f0 	movl   $0xf0106137,(%esp)
f0103a68:	e8 ed fb ff ff       	call   f010365a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a6d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103a70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a74:	c7 04 24 46 61 10 f0 	movl   $0xf0106146,(%esp)
f0103a7b:	e8 da fb ff ff       	call   f010365a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a80:	8b 43 14             	mov    0x14(%ebx),%eax
f0103a83:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a87:	c7 04 24 55 61 10 f0 	movl   $0xf0106155,(%esp)
f0103a8e:	e8 c7 fb ff ff       	call   f010365a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a93:	8b 43 18             	mov    0x18(%ebx),%eax
f0103a96:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a9a:	c7 04 24 64 61 10 f0 	movl   $0xf0106164,(%esp)
f0103aa1:	e8 b4 fb ff ff       	call   f010365a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103aa6:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103aa9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aad:	c7 04 24 73 61 10 f0 	movl   $0xf0106173,(%esp)
f0103ab4:	e8 a1 fb ff ff       	call   f010365a <cprintf>
}
f0103ab9:	83 c4 14             	add    $0x14,%esp
f0103abc:	5b                   	pop    %ebx
f0103abd:	5d                   	pop    %ebp
f0103abe:	c3                   	ret    

f0103abf <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103abf:	55                   	push   %ebp
f0103ac0:	89 e5                	mov    %esp,%ebp
f0103ac2:	56                   	push   %esi
f0103ac3:	53                   	push   %ebx
f0103ac4:	83 ec 10             	sub    $0x10,%esp
f0103ac7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103aca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103ace:	c7 04 24 bc 62 10 f0 	movl   $0xf01062bc,(%esp)
f0103ad5:	e8 80 fb ff ff       	call   f010365a <cprintf>
	print_regs(&tf->tf_regs);
f0103ada:	89 1c 24             	mov    %ebx,(%esp)
f0103add:	e8 36 ff ff ff       	call   f0103a18 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103ae2:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103ae6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aea:	c7 04 24 c4 61 10 f0 	movl   $0xf01061c4,(%esp)
f0103af1:	e8 64 fb ff ff       	call   f010365a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103af6:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103afa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103afe:	c7 04 24 d7 61 10 f0 	movl   $0xf01061d7,(%esp)
f0103b05:	e8 50 fb ff ff       	call   f010365a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b0a:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103b0d:	83 f8 13             	cmp    $0x13,%eax
f0103b10:	77 09                	ja     f0103b1b <print_trapframe+0x5c>
		return excnames[trapno];
f0103b12:	8b 14 85 a0 64 10 f0 	mov    -0xfef9b60(,%eax,4),%edx
f0103b19:	eb 10                	jmp    f0103b2b <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103b1b:	83 f8 30             	cmp    $0x30,%eax
f0103b1e:	ba 82 61 10 f0       	mov    $0xf0106182,%edx
f0103b23:	b9 8e 61 10 f0       	mov    $0xf010618e,%ecx
f0103b28:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b2b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103b2f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b33:	c7 04 24 ea 61 10 f0 	movl   $0xf01061ea,(%esp)
f0103b3a:	e8 1b fb ff ff       	call   f010365a <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b3f:	3b 1d 20 db 17 f0    	cmp    0xf017db20,%ebx
f0103b45:	75 19                	jne    f0103b60 <print_trapframe+0xa1>
f0103b47:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b4b:	75 13                	jne    f0103b60 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b4d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b50:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b54:	c7 04 24 fc 61 10 f0 	movl   $0xf01061fc,(%esp)
f0103b5b:	e8 fa fa ff ff       	call   f010365a <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103b60:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103b63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b67:	c7 04 24 0b 62 10 f0 	movl   $0xf010620b,(%esp)
f0103b6e:	e8 e7 fa ff ff       	call   f010365a <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b73:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b77:	75 51                	jne    f0103bca <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b79:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b7c:	89 c2                	mov    %eax,%edx
f0103b7e:	83 e2 01             	and    $0x1,%edx
f0103b81:	ba 9d 61 10 f0       	mov    $0xf010619d,%edx
f0103b86:	b9 a8 61 10 f0       	mov    $0xf01061a8,%ecx
f0103b8b:	0f 45 ca             	cmovne %edx,%ecx
f0103b8e:	89 c2                	mov    %eax,%edx
f0103b90:	83 e2 02             	and    $0x2,%edx
f0103b93:	ba b4 61 10 f0       	mov    $0xf01061b4,%edx
f0103b98:	be ba 61 10 f0       	mov    $0xf01061ba,%esi
f0103b9d:	0f 44 d6             	cmove  %esi,%edx
f0103ba0:	83 e0 04             	and    $0x4,%eax
f0103ba3:	b8 bf 61 10 f0       	mov    $0xf01061bf,%eax
f0103ba8:	be e7 62 10 f0       	mov    $0xf01062e7,%esi
f0103bad:	0f 44 c6             	cmove  %esi,%eax
f0103bb0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103bb4:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103bb8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bbc:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0103bc3:	e8 92 fa ff ff       	call   f010365a <cprintf>
f0103bc8:	eb 0c                	jmp    f0103bd6 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103bca:	c7 04 24 56 60 10 f0 	movl   $0xf0106056,(%esp)
f0103bd1:	e8 84 fa ff ff       	call   f010365a <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103bd6:	8b 43 30             	mov    0x30(%ebx),%eax
f0103bd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bdd:	c7 04 24 28 62 10 f0 	movl   $0xf0106228,(%esp)
f0103be4:	e8 71 fa ff ff       	call   f010365a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103be9:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103bed:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf1:	c7 04 24 37 62 10 f0 	movl   $0xf0106237,(%esp)
f0103bf8:	e8 5d fa ff ff       	call   f010365a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103bfd:	8b 43 38             	mov    0x38(%ebx),%eax
f0103c00:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c04:	c7 04 24 4a 62 10 f0 	movl   $0xf010624a,(%esp)
f0103c0b:	e8 4a fa ff ff       	call   f010365a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c10:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c14:	74 27                	je     f0103c3d <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c16:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c19:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c1d:	c7 04 24 59 62 10 f0 	movl   $0xf0106259,(%esp)
f0103c24:	e8 31 fa ff ff       	call   f010365a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c29:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c2d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c31:	c7 04 24 68 62 10 f0 	movl   $0xf0106268,(%esp)
f0103c38:	e8 1d fa ff ff       	call   f010365a <cprintf>
	}
}
f0103c3d:	83 c4 10             	add    $0x10,%esp
f0103c40:	5b                   	pop    %ebx
f0103c41:	5e                   	pop    %esi
f0103c42:	5d                   	pop    %ebp
f0103c43:	c3                   	ret    

f0103c44 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c44:	55                   	push   %ebp
f0103c45:	89 e5                	mov    %esp,%ebp
f0103c47:	53                   	push   %ebx
f0103c48:	83 ec 14             	sub    $0x14,%esp
f0103c4b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c4e:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs&3)==0)
f0103c51:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c55:	75 1c                	jne    f0103c73 <page_fault_handler+0x2f>
		panic("Kernel page fault!");
f0103c57:	c7 44 24 08 7b 62 10 	movl   $0xf010627b,0x8(%esp)
f0103c5e:	f0 
f0103c5f:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
f0103c66:	00 
f0103c67:	c7 04 24 8e 62 10 f0 	movl   $0xf010628e,(%esp)
f0103c6e:	e8 4b c4 ff ff       	call   f01000be <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c73:	8b 53 30             	mov    0x30(%ebx),%edx
f0103c76:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c7a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c7e:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103c83:	8b 40 48             	mov    0x48(%eax),%eax
f0103c86:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c8a:	c7 04 24 34 64 10 f0 	movl   $0xf0106434,(%esp)
f0103c91:	e8 c4 f9 ff ff       	call   f010365a <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103c96:	89 1c 24             	mov    %ebx,(%esp)
f0103c99:	e8 21 fe ff ff       	call   f0103abf <print_trapframe>
	env_destroy(curenv);
f0103c9e:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103ca3:	89 04 24             	mov    %eax,(%esp)
f0103ca6:	e8 93 f8 ff ff       	call   f010353e <env_destroy>
}
f0103cab:	83 c4 14             	add    $0x14,%esp
f0103cae:	5b                   	pop    %ebx
f0103caf:	5d                   	pop    %ebp
f0103cb0:	c3                   	ret    

f0103cb1 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103cb1:	55                   	push   %ebp
f0103cb2:	89 e5                	mov    %esp,%ebp
f0103cb4:	57                   	push   %edi
f0103cb5:	56                   	push   %esi
f0103cb6:	83 ec 20             	sub    $0x20,%esp
f0103cb9:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cbc:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103cbd:	9c                   	pushf  
f0103cbe:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103cbf:	f6 c4 02             	test   $0x2,%ah
f0103cc2:	74 24                	je     f0103ce8 <trap+0x37>
f0103cc4:	c7 44 24 0c 9a 62 10 	movl   $0xf010629a,0xc(%esp)
f0103ccb:	f0 
f0103ccc:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0103cd3:	f0 
f0103cd4:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
f0103cdb:	00 
f0103cdc:	c7 04 24 8e 62 10 f0 	movl   $0xf010628e,(%esp)
f0103ce3:	e8 d6 c3 ff ff       	call   f01000be <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103ce8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103cec:	c7 04 24 b3 62 10 f0 	movl   $0xf01062b3,(%esp)
f0103cf3:	e8 62 f9 ff ff       	call   f010365a <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103cf8:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103cfc:	83 e0 03             	and    $0x3,%eax
f0103cff:	66 83 f8 03          	cmp    $0x3,%ax
f0103d03:	75 3c                	jne    f0103d41 <trap+0x90>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103d05:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103d0a:	85 c0                	test   %eax,%eax
f0103d0c:	75 24                	jne    f0103d32 <trap+0x81>
f0103d0e:	c7 44 24 0c ce 62 10 	movl   $0xf01062ce,0xc(%esp)
f0103d15:	f0 
f0103d16:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0103d1d:	f0 
f0103d1e:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f0103d25:	00 
f0103d26:	c7 04 24 8e 62 10 f0 	movl   $0xf010628e,(%esp)
f0103d2d:	e8 8c c3 ff ff       	call   f01000be <_panic>
		curenv->env_tf = *tf;
f0103d32:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103d37:	89 c7                	mov    %eax,%edi
f0103d39:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103d3b:	8b 35 08 d3 17 f0    	mov    0xf017d308,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103d41:	89 35 20 db 17 f0    	mov    %esi,0xf017db20
trap_dispatch(struct Trapframe *tf)
{
//print_trapframe(tf);
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno==T_PGFLT){
f0103d47:	8b 46 28             	mov    0x28(%esi),%eax
f0103d4a:	83 f8 0e             	cmp    $0xe,%eax
f0103d4d:	75 0a                	jne    f0103d59 <trap+0xa8>
		page_fault_handler(tf);
f0103d4f:	89 34 24             	mov    %esi,(%esp)
f0103d52:	e8 ed fe ff ff       	call   f0103c44 <page_fault_handler>
f0103d57:	eb 7e                	jmp    f0103dd7 <trap+0x126>
                return;
	}
	if(tf->tf_trapno==T_BRKPT){
f0103d59:	83 f8 03             	cmp    $0x3,%eax
f0103d5c:	75 0a                	jne    f0103d68 <trap+0xb7>
		monitor(tf);
f0103d5e:	89 34 24             	mov    %esi,(%esp)
f0103d61:	e8 ff ca ff ff       	call   f0100865 <monitor>
f0103d66:	eb 6f                	jmp    f0103dd7 <trap+0x126>
                return;
	}
	if(tf->tf_trapno==T_SYSCALL){
f0103d68:	83 f8 30             	cmp    $0x30,%eax
f0103d6b:	75 32                	jne    f0103d9f <trap+0xee>
		tf->tf_regs.reg_eax=
			syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,
f0103d6d:	8b 46 04             	mov    0x4(%esi),%eax
f0103d70:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103d74:	8b 06                	mov    (%esi),%eax
f0103d76:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103d7a:	8b 46 10             	mov    0x10(%esi),%eax
f0103d7d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d81:	8b 46 18             	mov    0x18(%esi),%eax
f0103d84:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d88:	8b 46 14             	mov    0x14(%esi),%eax
f0103d8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d8f:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103d92:	89 04 24             	mov    %eax,(%esp)
f0103d95:	e8 f6 00 00 00       	call   f0103e90 <syscall>
	if(tf->tf_trapno==T_BRKPT){
		monitor(tf);
                return;
	}
	if(tf->tf_trapno==T_SYSCALL){
		tf->tf_regs.reg_eax=
f0103d9a:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103d9d:	eb 38                	jmp    f0103dd7 <trap+0x126>
					tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,
					tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
                return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103d9f:	89 34 24             	mov    %esi,(%esp)
f0103da2:	e8 18 fd ff ff       	call   f0103abf <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103da7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103dac:	75 1c                	jne    f0103dca <trap+0x119>
		panic("unhandled trap in kernel");
f0103dae:	c7 44 24 08 d5 62 10 	movl   $0xf01062d5,0x8(%esp)
f0103db5:	f0 
f0103db6:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
f0103dbd:	00 
f0103dbe:	c7 04 24 8e 62 10 f0 	movl   $0xf010628e,(%esp)
f0103dc5:	e8 f4 c2 ff ff       	call   f01000be <_panic>
	else {
		env_destroy(curenv);
f0103dca:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103dcf:	89 04 24             	mov    %eax,(%esp)
f0103dd2:	e8 67 f7 ff ff       	call   f010353e <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103dd7:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103ddc:	85 c0                	test   %eax,%eax
f0103dde:	74 06                	je     f0103de6 <trap+0x135>
f0103de0:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0103de4:	74 24                	je     f0103e0a <trap+0x159>
f0103de6:	c7 44 24 0c 58 64 10 	movl   $0xf0106458,0xc(%esp)
f0103ded:	f0 
f0103dee:	c7 44 24 08 a3 5d 10 	movl   $0xf0105da3,0x8(%esp)
f0103df5:	f0 
f0103df6:	c7 44 24 04 f7 00 00 	movl   $0xf7,0x4(%esp)
f0103dfd:	00 
f0103dfe:	c7 04 24 8e 62 10 f0 	movl   $0xf010628e,(%esp)
f0103e05:	e8 b4 c2 ff ff       	call   f01000be <_panic>
	env_run(curenv);
f0103e0a:	89 04 24             	mov    %eax,(%esp)
f0103e0d:	e8 83 f7 ff ff       	call   f0103595 <env_run>

f0103e12 <routine_divide>:
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */


	TRAPHANDLER_NOEC(routine_divide, T_DIVIDE)
f0103e12:	6a 00                	push   $0x0
f0103e14:	6a 00                	push   $0x0
f0103e16:	eb 5e                	jmp    f0103e76 <_alltraps>

f0103e18 <routine_debug>:
	TRAPHANDLER_NOEC(routine_debug, T_DEBUG)
f0103e18:	6a 00                	push   $0x0
f0103e1a:	6a 01                	push   $0x1
f0103e1c:	eb 58                	jmp    f0103e76 <_alltraps>

f0103e1e <routine_nmi>:
	TRAPHANDLER_NOEC(routine_nmi, T_NMI)
f0103e1e:	6a 00                	push   $0x0
f0103e20:	6a 02                	push   $0x2
f0103e22:	eb 52                	jmp    f0103e76 <_alltraps>

f0103e24 <routine_brkpt>:
	TRAPHANDLER_NOEC(routine_brkpt, T_BRKPT)
f0103e24:	6a 00                	push   $0x0
f0103e26:	6a 03                	push   $0x3
f0103e28:	eb 4c                	jmp    f0103e76 <_alltraps>

f0103e2a <routine_oflow>:
	TRAPHANDLER_NOEC(routine_oflow, T_OFLOW)
f0103e2a:	6a 00                	push   $0x0
f0103e2c:	6a 04                	push   $0x4
f0103e2e:	eb 46                	jmp    f0103e76 <_alltraps>

f0103e30 <routine_bound>:
	TRAPHANDLER_NOEC(routine_bound, T_BOUND)
f0103e30:	6a 00                	push   $0x0
f0103e32:	6a 05                	push   $0x5
f0103e34:	eb 40                	jmp    f0103e76 <_alltraps>

f0103e36 <routine_illop>:
	TRAPHANDLER_NOEC(routine_illop, T_ILLOP)
f0103e36:	6a 00                	push   $0x0
f0103e38:	6a 06                	push   $0x6
f0103e3a:	eb 3a                	jmp    f0103e76 <_alltraps>

f0103e3c <routine_device>:
	TRAPHANDLER_NOEC(routine_device, T_DEVICE)
f0103e3c:	6a 00                	push   $0x0
f0103e3e:	6a 07                	push   $0x7
f0103e40:	eb 34                	jmp    f0103e76 <_alltraps>

f0103e42 <routine_dblflt>:
	TRAPHANDLER(routine_dblflt, T_DBLFLT)
f0103e42:	6a 08                	push   $0x8
f0103e44:	eb 30                	jmp    f0103e76 <_alltraps>

f0103e46 <routine_tss>:
	TRAPHANDLER(routine_tss, T_TSS)
f0103e46:	6a 0a                	push   $0xa
f0103e48:	eb 2c                	jmp    f0103e76 <_alltraps>

f0103e4a <routine_segnp>:
	TRAPHANDLER(routine_segnp, T_SEGNP)
f0103e4a:	6a 0b                	push   $0xb
f0103e4c:	eb 28                	jmp    f0103e76 <_alltraps>

f0103e4e <routine_stack>:
	TRAPHANDLER(routine_stack, T_STACK)
f0103e4e:	6a 0c                	push   $0xc
f0103e50:	eb 24                	jmp    f0103e76 <_alltraps>

f0103e52 <routine_gpflt>:
	TRAPHANDLER(routine_gpflt, T_GPFLT)
f0103e52:	6a 0d                	push   $0xd
f0103e54:	eb 20                	jmp    f0103e76 <_alltraps>

f0103e56 <routine_pgflt>:
	TRAPHANDLER(routine_pgflt, T_PGFLT)
f0103e56:	6a 0e                	push   $0xe
f0103e58:	eb 1c                	jmp    f0103e76 <_alltraps>

f0103e5a <routine_fperr>:
	TRAPHANDLER_NOEC(routine_fperr, T_FPERR)
f0103e5a:	6a 00                	push   $0x0
f0103e5c:	6a 10                	push   $0x10
f0103e5e:	eb 16                	jmp    f0103e76 <_alltraps>

f0103e60 <routine_align>:
	TRAPHANDLER(routine_align, T_ALIGN)
f0103e60:	6a 11                	push   $0x11
f0103e62:	eb 12                	jmp    f0103e76 <_alltraps>

f0103e64 <routine_mchk>:
	TRAPHANDLER_NOEC(routine_mchk, T_MCHK)
f0103e64:	6a 00                	push   $0x0
f0103e66:	6a 12                	push   $0x12
f0103e68:	eb 0c                	jmp    f0103e76 <_alltraps>

f0103e6a <routine_simderr>:
	TRAPHANDLER_NOEC(routine_simderr, T_SIMDERR)
f0103e6a:	6a 00                	push   $0x0
f0103e6c:	6a 13                	push   $0x13
f0103e6e:	eb 06                	jmp    f0103e76 <_alltraps>

f0103e70 <routine_syscall>:

	TRAPHANDLER_NOEC(routine_syscall,T_SYSCALL);
f0103e70:	6a 00                	push   $0x0
f0103e72:	6a 30                	push   $0x30
f0103e74:	eb 00                	jmp    f0103e76 <_alltraps>

f0103e76 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
 pushl %ds
f0103e76:	1e                   	push   %ds
 pushl %es
f0103e77:	06                   	push   %es
 pushal
f0103e78:	60                   	pusha  
 pushl $GD_KD  //load GD_KD into %ds and %es
f0103e79:	6a 10                	push   $0x10
 popl %ds
f0103e7b:	1f                   	pop    %ds
 pushl $GD_KD
f0103e7c:	6a 10                	push   $0x10
 popl %es
f0103e7e:	07                   	pop    %es
 pushl %esp        //pushl esp to pass a pointer to the trapframe as an argu                   //ment to trap
f0103e7f:	54                   	push   %esp
 call trap
f0103e80:	e8 2c fe ff ff       	call   f0103cb1 <trap>
f0103e85:	66 90                	xchg   %ax,%ax
f0103e87:	66 90                	xchg   %ax,%ax
f0103e89:	66 90                	xchg   %ax,%ax
f0103e8b:	66 90                	xchg   %ax,%ax
f0103e8d:	66 90                	xchg   %ax,%ax
f0103e8f:	90                   	nop

f0103e90 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103e90:	55                   	push   %ebp
f0103e91:	89 e5                	mov    %esp,%ebp
f0103e93:	83 ec 28             	sub    $0x28,%esp
f0103e96:	8b 45 08             	mov    0x8(%ebp),%eax
			ret=-E_INVAL;
	}
	return ret;
	panic("syscall not implemented");
*/
   if(syscallno==SYS_cputs)
f0103e99:	85 c0                	test   %eax,%eax
f0103e9b:	75 47                	jne    f0103ee4 <syscall+0x54>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv,s,len,PTE_U);
f0103e9d:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0103ea4:	00 
f0103ea5:	8b 45 10             	mov    0x10(%ebp),%eax
f0103ea8:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103eac:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103eaf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103eb3:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103eb8:	89 04 24             	mov    %eax,(%esp)
f0103ebb:	e8 dd ef ff ff       	call   f0102e9d <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103ec0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ec3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ec7:	8b 45 10             	mov    0x10(%ebp),%eax
f0103eca:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ece:	c7 04 24 f0 64 10 f0 	movl   $0xf01064f0,(%esp)
f0103ed5:	e8 80 f7 ff ff       	call   f010365a <cprintf>
	panic("syscall not implemented");
*/
   if(syscallno==SYS_cputs)
   {
	   sys_cputs((const char*)a1, a2);
	   return 0;
f0103eda:	b8 00 00 00 00       	mov    $0x0,%eax
f0103edf:	e9 b0 00 00 00       	jmp    f0103f94 <syscall+0x104>
   }
	if(syscallno==SYS_cgetc)
f0103ee4:	83 f8 01             	cmp    $0x1,%eax
f0103ee7:	75 0c                	jne    f0103ef5 <syscall+0x65>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103ee9:	e8 12 c6 ff ff       	call   f0100500 <cons_getc>
	   return 0;
   }
	if(syscallno==SYS_cgetc)
	   {

		   return sys_cgetc();
f0103eee:	66 90                	xchg   %ax,%ax
f0103ef0:	e9 9f 00 00 00       	jmp    f0103f94 <syscall+0x104>
	   }
	if(syscallno==SYS_getenvid)
f0103ef5:	83 f8 02             	cmp    $0x2,%eax
f0103ef8:	75 0d                	jne    f0103f07 <syscall+0x77>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103efa:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0103eff:	8b 40 48             	mov    0x48(%eax),%eax
		   return sys_cgetc();
	   }
	if(syscallno==SYS_getenvid)
	{

		return sys_getenvid();
f0103f02:	e9 8d 00 00 00       	jmp    f0103f94 <syscall+0x104>
	}
	if(syscallno==SYS_env_destroy)
f0103f07:	83 f8 03             	cmp    $0x3,%eax
f0103f0a:	75 6c                	jne    f0103f78 <syscall+0xe8>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103f0c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0103f13:	00 
f0103f14:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103f17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f1b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f1e:	89 04 24             	mov    %eax,(%esp)
f0103f21:	e8 4c f0 ff ff       	call   f0102f72 <envid2env>
f0103f26:	85 c0                	test   %eax,%eax
f0103f28:	78 6a                	js     f0103f94 <syscall+0x104>
		return r;
	if (e == curenv)
f0103f2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103f2d:	8b 15 08 d3 17 f0    	mov    0xf017d308,%edx
f0103f33:	39 d0                	cmp    %edx,%eax
f0103f35:	75 15                	jne    f0103f4c <syscall+0xbc>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103f37:	8b 40 48             	mov    0x48(%eax),%eax
f0103f3a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f3e:	c7 04 24 f5 64 10 f0 	movl   $0xf01064f5,(%esp)
f0103f45:	e8 10 f7 ff ff       	call   f010365a <cprintf>
f0103f4a:	eb 1a                	jmp    f0103f66 <syscall+0xd6>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103f4c:	8b 40 48             	mov    0x48(%eax),%eax
f0103f4f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f53:	8b 42 48             	mov    0x48(%edx),%eax
f0103f56:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f5a:	c7 04 24 10 65 10 f0 	movl   $0xf0106510,(%esp)
f0103f61:	e8 f4 f6 ff ff       	call   f010365a <cprintf>
	env_destroy(e);
f0103f66:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103f69:	89 04 24             	mov    %eax,(%esp)
f0103f6c:	e8 cd f5 ff ff       	call   f010353e <env_destroy>
	return 0;
f0103f71:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f76:	eb 1c                	jmp    f0103f94 <syscall+0x104>
	if(syscallno==SYS_env_destroy)
		{

			return sys_env_destroy(a1);
		}
	panic("invalid syscall num!");
f0103f78:	c7 44 24 08 28 65 10 	movl   $0xf0106528,0x8(%esp)
f0103f7f:	f0 
f0103f80:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
f0103f87:	00 
f0103f88:	c7 04 24 3d 65 10 f0 	movl   $0xf010653d,(%esp)
f0103f8f:	e8 2a c1 ff ff       	call   f01000be <_panic>
	return 0;
}
f0103f94:	c9                   	leave  
f0103f95:	c3                   	ret    
f0103f96:	66 90                	xchg   %ax,%ax
f0103f98:	66 90                	xchg   %ax,%ax
f0103f9a:	66 90                	xchg   %ax,%ax
f0103f9c:	66 90                	xchg   %ax,%ax
f0103f9e:	66 90                	xchg   %ax,%ax

f0103fa0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103fa0:	55                   	push   %ebp
f0103fa1:	89 e5                	mov    %esp,%ebp
f0103fa3:	57                   	push   %edi
f0103fa4:	56                   	push   %esi
f0103fa5:	53                   	push   %ebx
f0103fa6:	83 ec 14             	sub    $0x14,%esp
f0103fa9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103fac:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103faf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103fb2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103fb5:	8b 1a                	mov    (%edx),%ebx
f0103fb7:	8b 01                	mov    (%ecx),%eax
f0103fb9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	
	while (l <= r) {
f0103fbc:	39 c3                	cmp    %eax,%ebx
f0103fbe:	0f 8f 9a 00 00 00    	jg     f010405e <stab_binsearch+0xbe>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0103fc4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103fcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103fce:	01 d8                	add    %ebx,%eax
f0103fd0:	89 c7                	mov    %eax,%edi
f0103fd2:	c1 ef 1f             	shr    $0x1f,%edi
f0103fd5:	01 c7                	add    %eax,%edi
f0103fd7:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103fd9:	39 df                	cmp    %ebx,%edi
f0103fdb:	0f 8c c4 00 00 00    	jl     f01040a5 <stab_binsearch+0x105>
f0103fe1:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103fe4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103fe7:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103fea:	0f b6 42 04          	movzbl 0x4(%edx),%eax
f0103fee:	39 f0                	cmp    %esi,%eax
f0103ff0:	0f 84 b4 00 00 00    	je     f01040aa <stab_binsearch+0x10a>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103ff6:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103ff8:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103ffb:	39 d8                	cmp    %ebx,%eax
f0103ffd:	0f 8c a2 00 00 00    	jl     f01040a5 <stab_binsearch+0x105>
f0104003:	0f b6 4a f8          	movzbl -0x8(%edx),%ecx
f0104007:	83 ea 0c             	sub    $0xc,%edx
f010400a:	39 f1                	cmp    %esi,%ecx
f010400c:	75 ea                	jne    f0103ff8 <stab_binsearch+0x58>
f010400e:	e9 99 00 00 00       	jmp    f01040ac <stab_binsearch+0x10c>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104013:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104016:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104018:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010401b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104022:	eb 2b                	jmp    f010404f <stab_binsearch+0xaf>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104024:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104027:	76 14                	jbe    f010403d <stab_binsearch+0x9d>
			*region_right = m - 1;
f0104029:	83 e8 01             	sub    $0x1,%eax
f010402c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010402f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104032:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104034:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010403b:	eb 12                	jmp    f010404f <stab_binsearch+0xaf>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010403d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104040:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0104042:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104046:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104048:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f010404f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104052:	0f 8e 73 ff ff ff    	jle    f0103fcb <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104058:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010405c:	75 0f                	jne    f010406d <stab_binsearch+0xcd>
		*region_right = *region_left - 1;
f010405e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104061:	8b 00                	mov    (%eax),%eax
f0104063:	83 e8 01             	sub    $0x1,%eax
f0104066:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104069:	89 06                	mov    %eax,(%esi)
f010406b:	eb 57                	jmp    f01040c4 <stab_binsearch+0x124>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010406d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104070:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104072:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104075:	8b 0f                	mov    (%edi),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104077:	39 c8                	cmp    %ecx,%eax
f0104079:	7e 23                	jle    f010409e <stab_binsearch+0xfe>
		     l > *region_left && stabs[l].n_type != type;
f010407b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010407e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104081:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104084:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104088:	39 f3                	cmp    %esi,%ebx
f010408a:	74 12                	je     f010409e <stab_binsearch+0xfe>
		     l--)
f010408c:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010408f:	39 c8                	cmp    %ecx,%eax
f0104091:	7e 0b                	jle    f010409e <stab_binsearch+0xfe>
		     l > *region_left && stabs[l].n_type != type;
f0104093:	0f b6 5a f8          	movzbl -0x8(%edx),%ebx
f0104097:	83 ea 0c             	sub    $0xc,%edx
f010409a:	39 f3                	cmp    %esi,%ebx
f010409c:	75 ee                	jne    f010408c <stab_binsearch+0xec>
		     l--)
			/* do nothing */;
		*region_left = l;
f010409e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01040a1:	89 06                	mov    %eax,(%esi)
f01040a3:	eb 1f                	jmp    f01040c4 <stab_binsearch+0x124>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01040a5:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01040a8:	eb a5                	jmp    f010404f <stab_binsearch+0xaf>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01040aa:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01040ac:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01040af:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040b2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01040b6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01040b9:	0f 82 54 ff ff ff    	jb     f0104013 <stab_binsearch+0x73>
f01040bf:	e9 60 ff ff ff       	jmp    f0104024 <stab_binsearch+0x84>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f01040c4:	83 c4 14             	add    $0x14,%esp
f01040c7:	5b                   	pop    %ebx
f01040c8:	5e                   	pop    %esi
f01040c9:	5f                   	pop    %edi
f01040ca:	5d                   	pop    %ebp
f01040cb:	c3                   	ret    

f01040cc <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01040cc:	55                   	push   %ebp
f01040cd:	89 e5                	mov    %esp,%ebp
f01040cf:	57                   	push   %edi
f01040d0:	56                   	push   %esi
f01040d1:	53                   	push   %ebx
f01040d2:	83 ec 3c             	sub    $0x3c,%esp
f01040d5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01040d8:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01040db:	c7 06 4c 65 10 f0    	movl   $0xf010654c,(%esi)
	info->eip_line = 0;
f01040e1:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01040e8:	c7 46 08 4c 65 10 f0 	movl   $0xf010654c,0x8(%esi)
	info->eip_fn_namelen = 9;
f01040ef:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01040f6:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01040f9:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104100:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104106:	0f 87 ae 00 00 00    	ja     f01041ba <debuginfo_eip+0xee>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		//
	    if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_U)<0)
f010410c:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104113:	00 
f0104114:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f010411b:	00 
f010411c:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104123:	00 
f0104124:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f0104129:	89 04 24             	mov    %eax,(%esp)
f010412c:	e8 98 ec ff ff       	call   f0102dc9 <user_mem_check>
f0104131:	85 c0                	test   %eax,%eax
f0104133:	0f 88 01 02 00 00    	js     f010433a <debuginfo_eip+0x26e>
			return -1;


		stabs = usd->stabs;
f0104139:	a1 00 00 20 00       	mov    0x200000,%eax
f010413e:	89 c1                	mov    %eax,%ecx
f0104140:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0104143:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104149:	a1 08 00 20 00       	mov    0x200008,%eax
f010414e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		stabstr_end = usd->stabstr_end;
f0104151:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104157:	89 55 cc             	mov    %edx,-0x34(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,stabs,stab_end-stabs,PTE_U)<0)
f010415a:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104161:	00 
f0104162:	89 d8                	mov    %ebx,%eax
f0104164:	29 c8                	sub    %ecx,%eax
f0104166:	c1 f8 02             	sar    $0x2,%eax
f0104169:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010416f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104173:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104177:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f010417c:	89 04 24             	mov    %eax,(%esp)
f010417f:	e8 45 ec ff ff       	call   f0102dc9 <user_mem_check>
f0104184:	85 c0                	test   %eax,%eax
f0104186:	0f 88 b5 01 00 00    	js     f0104341 <debuginfo_eip+0x275>
			return -1;
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_U)<0)
f010418c:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104193:	00 
f0104194:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0104197:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010419a:	29 ca                	sub    %ecx,%edx
f010419c:	89 54 24 08          	mov    %edx,0x8(%esp)
f01041a0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01041a4:	a1 08 d3 17 f0       	mov    0xf017d308,%eax
f01041a9:	89 04 24             	mov    %eax,(%esp)
f01041ac:	e8 18 ec ff ff       	call   f0102dc9 <user_mem_check>
f01041b1:	85 c0                	test   %eax,%eax
f01041b3:	79 1f                	jns    f01041d4 <debuginfo_eip+0x108>
f01041b5:	e9 8e 01 00 00       	jmp    f0104348 <debuginfo_eip+0x27c>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01041ba:	c7 45 cc 8c 0f 11 f0 	movl   $0xf0110f8c,-0x34(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01041c1:	c7 45 d0 65 e5 10 f0 	movl   $0xf010e565,-0x30(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01041c8:	bb 64 e5 10 f0       	mov    $0xf010e564,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01041cd:	c7 45 d4 64 67 10 f0 	movl   $0xf0106764,-0x2c(%ebp)
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_U)<0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01041d4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01041d7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01041da:	0f 83 6f 01 00 00    	jae    f010434f <debuginfo_eip+0x283>
f01041e0:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01041e4:	0f 85 6c 01 00 00    	jne    f0104356 <debuginfo_eip+0x28a>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01041ea:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01041f1:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f01041f4:	c1 fb 02             	sar    $0x2,%ebx
f01041f7:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01041fd:	83 e8 01             	sub    $0x1,%eax
f0104200:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104203:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104207:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010420e:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104211:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104214:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104217:	89 d8                	mov    %ebx,%eax
f0104219:	e8 82 fd ff ff       	call   f0103fa0 <stab_binsearch>
	if (lfile == 0)
f010421e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104221:	85 c0                	test   %eax,%eax
f0104223:	0f 84 34 01 00 00    	je     f010435d <debuginfo_eip+0x291>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104229:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010422c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010422f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104232:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104236:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010423d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104240:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104243:	89 d8                	mov    %ebx,%eax
f0104245:	e8 56 fd ff ff       	call   f0103fa0 <stab_binsearch>

	if (lfun <= rfun) {
f010424a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010424d:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0104250:	7f 23                	jg     f0104275 <debuginfo_eip+0x1a9>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104252:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104255:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104258:	8d 04 87             	lea    (%edi,%eax,4),%eax
f010425b:	8b 10                	mov    (%eax),%edx
f010425d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104260:	2b 4d d0             	sub    -0x30(%ebp),%ecx
f0104263:	39 ca                	cmp    %ecx,%edx
f0104265:	73 06                	jae    f010426d <debuginfo_eip+0x1a1>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104267:	03 55 d0             	add    -0x30(%ebp),%edx
f010426a:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010426d:	8b 40 08             	mov    0x8(%eax),%eax
f0104270:	89 46 10             	mov    %eax,0x10(%esi)
f0104273:	eb 06                	jmp    f010427b <debuginfo_eip+0x1af>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104275:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104278:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010427b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104282:	00 
f0104283:	8b 46 08             	mov    0x8(%esi),%eax
f0104286:	89 04 24             	mov    %eax,(%esp)
f0104289:	e8 91 09 00 00       	call   f0104c1f <strfind>
f010428e:	2b 46 08             	sub    0x8(%esi),%eax
f0104291:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104294:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104297:	39 fb                	cmp    %edi,%ebx
f0104299:	7c 5f                	jl     f01042fa <debuginfo_eip+0x22e>
	       && stabs[lline].n_type != N_SOL
f010429b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010429e:	c1 e0 02             	shl    $0x2,%eax
f01042a1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01042a4:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f01042a7:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01042aa:	0f b6 52 04          	movzbl 0x4(%edx),%edx
f01042ae:	80 fa 84             	cmp    $0x84,%dl
f01042b1:	74 2f                	je     f01042e2 <debuginfo_eip+0x216>
f01042b3:	8d 44 01 f4          	lea    -0xc(%ecx,%eax,1),%eax
f01042b7:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01042ba:	eb 15                	jmp    f01042d1 <debuginfo_eip+0x205>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01042bc:	83 eb 01             	sub    $0x1,%ebx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01042bf:	39 fb                	cmp    %edi,%ebx
f01042c1:	7c 37                	jl     f01042fa <debuginfo_eip+0x22e>
	       && stabs[lline].n_type != N_SOL
f01042c3:	89 c1                	mov    %eax,%ecx
f01042c5:	83 e8 0c             	sub    $0xc,%eax
f01042c8:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f01042cc:	80 fa 84             	cmp    $0x84,%dl
f01042cf:	74 11                	je     f01042e2 <debuginfo_eip+0x216>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01042d1:	80 fa 64             	cmp    $0x64,%dl
f01042d4:	75 e6                	jne    f01042bc <debuginfo_eip+0x1f0>
f01042d6:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f01042da:	74 e0                	je     f01042bc <debuginfo_eip+0x1f0>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01042dc:	39 df                	cmp    %ebx,%edi
f01042de:	66 90                	xchg   %ax,%ax
f01042e0:	7f 18                	jg     f01042fa <debuginfo_eip+0x22e>
f01042e2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01042e5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01042e8:	8b 04 87             	mov    (%edi,%eax,4),%eax
f01042eb:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01042ee:	2b 55 d0             	sub    -0x30(%ebp),%edx
f01042f1:	39 d0                	cmp    %edx,%eax
f01042f3:	73 05                	jae    f01042fa <debuginfo_eip+0x22e>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01042f5:	03 45 d0             	add    -0x30(%ebp),%eax
f01042f8:	89 06                	mov    %eax,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01042fa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01042fd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0104300:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104305:	39 ca                	cmp    %ecx,%edx
f0104307:	7d 75                	jge    f010437e <debuginfo_eip+0x2b2>
		for (lline = lfun + 1;
f0104309:	8d 42 01             	lea    0x1(%edx),%eax
f010430c:	39 c1                	cmp    %eax,%ecx
f010430e:	7e 54                	jle    f0104364 <debuginfo_eip+0x298>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104310:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104313:	c1 e2 02             	shl    $0x2,%edx
f0104316:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104319:	80 7c 17 04 a0       	cmpb   $0xa0,0x4(%edi,%edx,1)
f010431e:	75 4b                	jne    f010436b <debuginfo_eip+0x29f>
f0104320:	8d 54 17 f4          	lea    -0xc(%edi,%edx,1),%edx
		     lline++)
			info->eip_fn_narg++;
f0104324:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0104328:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010432b:	39 c1                	cmp    %eax,%ecx
f010432d:	7e 43                	jle    f0104372 <debuginfo_eip+0x2a6>
f010432f:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104332:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0104336:	74 ec                	je     f0104324 <debuginfo_eip+0x258>
f0104338:	eb 3f                	jmp    f0104379 <debuginfo_eip+0x2ad>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		//
	    if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_U)<0)
			return -1;
f010433a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010433f:	eb 3d                	jmp    f010437e <debuginfo_eip+0x2b2>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,stabs,stab_end-stabs,PTE_U)<0)
			return -1;
f0104341:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104346:	eb 36                	jmp    f010437e <debuginfo_eip+0x2b2>
		if(user_mem_check(curenv,stabstr,stabstr_end-stabstr,PTE_U)<0)
			return -1;
f0104348:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010434d:	eb 2f                	jmp    f010437e <debuginfo_eip+0x2b2>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010434f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104354:	eb 28                	jmp    f010437e <debuginfo_eip+0x2b2>
f0104356:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010435b:	eb 21                	jmp    f010437e <debuginfo_eip+0x2b2>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010435d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104362:	eb 1a                	jmp    f010437e <debuginfo_eip+0x2b2>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0104364:	b8 00 00 00 00       	mov    $0x0,%eax
f0104369:	eb 13                	jmp    f010437e <debuginfo_eip+0x2b2>
f010436b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104370:	eb 0c                	jmp    f010437e <debuginfo_eip+0x2b2>
f0104372:	b8 00 00 00 00       	mov    $0x0,%eax
f0104377:	eb 05                	jmp    f010437e <debuginfo_eip+0x2b2>
f0104379:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010437e:	83 c4 3c             	add    $0x3c,%esp
f0104381:	5b                   	pop    %ebx
f0104382:	5e                   	pop    %esi
f0104383:	5f                   	pop    %edi
f0104384:	5d                   	pop    %ebp
f0104385:	c3                   	ret    
f0104386:	66 90                	xchg   %ax,%ax
f0104388:	66 90                	xchg   %ax,%ax
f010438a:	66 90                	xchg   %ax,%ax
f010438c:	66 90                	xchg   %ax,%ax
f010438e:	66 90                	xchg   %ax,%ax

f0104390 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104390:	55                   	push   %ebp
f0104391:	89 e5                	mov    %esp,%ebp
f0104393:	57                   	push   %edi
f0104394:	56                   	push   %esi
f0104395:	53                   	push   %ebx
f0104396:	83 ec 3c             	sub    $0x3c,%esp
f0104399:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010439c:	89 d7                	mov    %edx,%edi
f010439e:	8b 45 08             	mov    0x8(%ebp),%eax
f01043a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01043a4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043a7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01043aa:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01043ad:	b9 00 00 00 00       	mov    $0x0,%ecx
f01043b2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01043b5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01043b8:	39 f1                	cmp    %esi,%ecx
f01043ba:	72 14                	jb     f01043d0 <printnum+0x40>
f01043bc:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01043bf:	76 0f                	jbe    f01043d0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01043c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01043c4:	8d 70 ff             	lea    -0x1(%eax),%esi
f01043c7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01043ca:	85 f6                	test   %esi,%esi
f01043cc:	7f 60                	jg     f010442e <printnum+0x9e>
f01043ce:	eb 72                	jmp    f0104442 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01043d0:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01043d3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01043d7:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01043da:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01043dd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01043e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01043e5:	8b 44 24 08          	mov    0x8(%esp),%eax
f01043e9:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01043ed:	89 c3                	mov    %eax,%ebx
f01043ef:	89 d6                	mov    %edx,%esi
f01043f1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01043f4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01043f7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043fb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104402:	89 04 24             	mov    %eax,(%esp)
f0104405:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104408:	89 44 24 04          	mov    %eax,0x4(%esp)
f010440c:	e8 6f 0a 00 00       	call   f0104e80 <__udivdi3>
f0104411:	89 d9                	mov    %ebx,%ecx
f0104413:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104417:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010441b:	89 04 24             	mov    %eax,(%esp)
f010441e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104422:	89 fa                	mov    %edi,%edx
f0104424:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104427:	e8 64 ff ff ff       	call   f0104390 <printnum>
f010442c:	eb 14                	jmp    f0104442 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010442e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104432:	8b 45 18             	mov    0x18(%ebp),%eax
f0104435:	89 04 24             	mov    %eax,(%esp)
f0104438:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010443a:	83 ee 01             	sub    $0x1,%esi
f010443d:	75 ef                	jne    f010442e <printnum+0x9e>
f010443f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104442:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104446:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010444a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010444d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104450:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104454:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104458:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010445b:	89 04 24             	mov    %eax,(%esp)
f010445e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104461:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104465:	e8 46 0b 00 00       	call   f0104fb0 <__umoddi3>
f010446a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010446e:	0f be 80 56 65 10 f0 	movsbl -0xfef9aaa(%eax),%eax
f0104475:	89 04 24             	mov    %eax,(%esp)
f0104478:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010447b:	ff d0                	call   *%eax
}
f010447d:	83 c4 3c             	add    $0x3c,%esp
f0104480:	5b                   	pop    %ebx
f0104481:	5e                   	pop    %esi
f0104482:	5f                   	pop    %edi
f0104483:	5d                   	pop    %ebp
f0104484:	c3                   	ret    

f0104485 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104485:	55                   	push   %ebp
f0104486:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104488:	83 fa 01             	cmp    $0x1,%edx
f010448b:	7e 0e                	jle    f010449b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010448d:	8b 10                	mov    (%eax),%edx
f010448f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104492:	89 08                	mov    %ecx,(%eax)
f0104494:	8b 02                	mov    (%edx),%eax
f0104496:	8b 52 04             	mov    0x4(%edx),%edx
f0104499:	eb 22                	jmp    f01044bd <getuint+0x38>
	else if (lflag)
f010449b:	85 d2                	test   %edx,%edx
f010449d:	74 10                	je     f01044af <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010449f:	8b 10                	mov    (%eax),%edx
f01044a1:	8d 4a 04             	lea    0x4(%edx),%ecx
f01044a4:	89 08                	mov    %ecx,(%eax)
f01044a6:	8b 02                	mov    (%edx),%eax
f01044a8:	ba 00 00 00 00       	mov    $0x0,%edx
f01044ad:	eb 0e                	jmp    f01044bd <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01044af:	8b 10                	mov    (%eax),%edx
f01044b1:	8d 4a 04             	lea    0x4(%edx),%ecx
f01044b4:	89 08                	mov    %ecx,(%eax)
f01044b6:	8b 02                	mov    (%edx),%eax
f01044b8:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01044bd:	5d                   	pop    %ebp
f01044be:	c3                   	ret    

f01044bf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01044bf:	55                   	push   %ebp
f01044c0:	89 e5                	mov    %esp,%ebp
f01044c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01044c5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01044c9:	8b 10                	mov    (%eax),%edx
f01044cb:	3b 50 04             	cmp    0x4(%eax),%edx
f01044ce:	73 0a                	jae    f01044da <sprintputch+0x1b>
		*b->buf++ = ch;
f01044d0:	8d 4a 01             	lea    0x1(%edx),%ecx
f01044d3:	89 08                	mov    %ecx,(%eax)
f01044d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01044d8:	88 02                	mov    %al,(%edx)
}
f01044da:	5d                   	pop    %ebp
f01044db:	c3                   	ret    

f01044dc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01044dc:	55                   	push   %ebp
f01044dd:	89 e5                	mov    %esp,%ebp
f01044df:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01044e2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01044e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01044e9:	8b 45 10             	mov    0x10(%ebp),%eax
f01044ec:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044f0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01044f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01044fa:	89 04 24             	mov    %eax,(%esp)
f01044fd:	e8 02 00 00 00       	call   f0104504 <vprintfmt>
	va_end(ap);
}
f0104502:	c9                   	leave  
f0104503:	c3                   	ret    

f0104504 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104504:	55                   	push   %ebp
f0104505:	89 e5                	mov    %esp,%ebp
f0104507:	57                   	push   %edi
f0104508:	56                   	push   %esi
f0104509:	53                   	push   %ebx
f010450a:	83 ec 3c             	sub    $0x3c,%esp
f010450d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104510:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104513:	eb 18                	jmp    f010452d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104515:	85 c0                	test   %eax,%eax
f0104517:	0f 84 c3 03 00 00    	je     f01048e0 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
f010451d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104521:	89 04 24             	mov    %eax,(%esp)
f0104524:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104527:	89 f3                	mov    %esi,%ebx
f0104529:	eb 02                	jmp    f010452d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f010452b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010452d:	8d 73 01             	lea    0x1(%ebx),%esi
f0104530:	0f b6 03             	movzbl (%ebx),%eax
f0104533:	83 f8 25             	cmp    $0x25,%eax
f0104536:	75 dd                	jne    f0104515 <vprintfmt+0x11>
f0104538:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f010453c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104543:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f010454a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0104551:	ba 00 00 00 00       	mov    $0x0,%edx
f0104556:	eb 1d                	jmp    f0104575 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104558:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010455a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f010455e:	eb 15                	jmp    f0104575 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104560:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104562:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0104566:	eb 0d                	jmp    f0104575 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0104568:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010456b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010456e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104575:	8d 5e 01             	lea    0x1(%esi),%ebx
f0104578:	0f b6 06             	movzbl (%esi),%eax
f010457b:	0f b6 c8             	movzbl %al,%ecx
f010457e:	83 e8 23             	sub    $0x23,%eax
f0104581:	3c 55                	cmp    $0x55,%al
f0104583:	0f 87 2f 03 00 00    	ja     f01048b8 <vprintfmt+0x3b4>
f0104589:	0f b6 c0             	movzbl %al,%eax
f010458c:	ff 24 85 e0 65 10 f0 	jmp    *-0xfef9a20(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104593:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0104596:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0104599:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010459d:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01045a0:	83 f9 09             	cmp    $0x9,%ecx
f01045a3:	77 50                	ja     f01045f5 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045a5:	89 de                	mov    %ebx,%esi
f01045a7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01045aa:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01045ad:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01045b0:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01045b4:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01045b7:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01045ba:	83 fb 09             	cmp    $0x9,%ebx
f01045bd:	76 eb                	jbe    f01045aa <vprintfmt+0xa6>
f01045bf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01045c2:	eb 33                	jmp    f01045f7 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01045c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01045c7:	8d 48 04             	lea    0x4(%eax),%ecx
f01045ca:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01045cd:	8b 00                	mov    (%eax),%eax
f01045cf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045d2:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01045d4:	eb 21                	jmp    f01045f7 <vprintfmt+0xf3>
f01045d6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01045d9:	85 c9                	test   %ecx,%ecx
f01045db:	b8 00 00 00 00       	mov    $0x0,%eax
f01045e0:	0f 49 c1             	cmovns %ecx,%eax
f01045e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045e6:	89 de                	mov    %ebx,%esi
f01045e8:	eb 8b                	jmp    f0104575 <vprintfmt+0x71>
f01045ea:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01045ec:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01045f3:	eb 80                	jmp    f0104575 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045f5:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01045f7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01045fb:	0f 89 74 ff ff ff    	jns    f0104575 <vprintfmt+0x71>
f0104601:	e9 62 ff ff ff       	jmp    f0104568 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104606:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104609:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010460b:	e9 65 ff ff ff       	jmp    f0104575 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104610:	8b 45 14             	mov    0x14(%ebp),%eax
f0104613:	8d 50 04             	lea    0x4(%eax),%edx
f0104616:	89 55 14             	mov    %edx,0x14(%ebp)
f0104619:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010461d:	8b 00                	mov    (%eax),%eax
f010461f:	89 04 24             	mov    %eax,(%esp)
f0104622:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104625:	e9 03 ff ff ff       	jmp    f010452d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010462a:	8b 45 14             	mov    0x14(%ebp),%eax
f010462d:	8d 50 04             	lea    0x4(%eax),%edx
f0104630:	89 55 14             	mov    %edx,0x14(%ebp)
f0104633:	8b 00                	mov    (%eax),%eax
f0104635:	99                   	cltd   
f0104636:	31 d0                	xor    %edx,%eax
f0104638:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010463a:	83 f8 06             	cmp    $0x6,%eax
f010463d:	7f 0b                	jg     f010464a <vprintfmt+0x146>
f010463f:	8b 14 85 38 67 10 f0 	mov    -0xfef98c8(,%eax,4),%edx
f0104646:	85 d2                	test   %edx,%edx
f0104648:	75 20                	jne    f010466a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f010464a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010464e:	c7 44 24 08 6e 65 10 	movl   $0xf010656e,0x8(%esp)
f0104655:	f0 
f0104656:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010465a:	8b 45 08             	mov    0x8(%ebp),%eax
f010465d:	89 04 24             	mov    %eax,(%esp)
f0104660:	e8 77 fe ff ff       	call   f01044dc <printfmt>
f0104665:	e9 c3 fe ff ff       	jmp    f010452d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
f010466a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010466e:	c7 44 24 08 b5 5d 10 	movl   $0xf0105db5,0x8(%esp)
f0104675:	f0 
f0104676:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010467a:	8b 45 08             	mov    0x8(%ebp),%eax
f010467d:	89 04 24             	mov    %eax,(%esp)
f0104680:	e8 57 fe ff ff       	call   f01044dc <printfmt>
f0104685:	e9 a3 fe ff ff       	jmp    f010452d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010468a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010468d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104690:	8b 45 14             	mov    0x14(%ebp),%eax
f0104693:	8d 50 04             	lea    0x4(%eax),%edx
f0104696:	89 55 14             	mov    %edx,0x14(%ebp)
f0104699:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010469b:	85 c0                	test   %eax,%eax
f010469d:	ba 67 65 10 f0       	mov    $0xf0106567,%edx
f01046a2:	0f 45 d0             	cmovne %eax,%edx
f01046a5:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f01046a8:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f01046ac:	74 04                	je     f01046b2 <vprintfmt+0x1ae>
f01046ae:	85 f6                	test   %esi,%esi
f01046b0:	7f 19                	jg     f01046cb <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01046b2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01046b5:	8d 70 01             	lea    0x1(%eax),%esi
f01046b8:	0f b6 10             	movzbl (%eax),%edx
f01046bb:	0f be c2             	movsbl %dl,%eax
f01046be:	85 c0                	test   %eax,%eax
f01046c0:	0f 85 95 00 00 00    	jne    f010475b <vprintfmt+0x257>
f01046c6:	e9 85 00 00 00       	jmp    f0104750 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046cb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01046cf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01046d2:	89 04 24             	mov    %eax,(%esp)
f01046d5:	e8 88 03 00 00       	call   f0104a62 <strnlen>
f01046da:	29 c6                	sub    %eax,%esi
f01046dc:	89 f0                	mov    %esi,%eax
f01046de:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01046e1:	85 f6                	test   %esi,%esi
f01046e3:	7e cd                	jle    f01046b2 <vprintfmt+0x1ae>
					putch(padc, putdat);
f01046e5:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01046e9:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01046ec:	89 c3                	mov    %eax,%ebx
f01046ee:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01046f2:	89 34 24             	mov    %esi,(%esp)
f01046f5:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046f8:	83 eb 01             	sub    $0x1,%ebx
f01046fb:	75 f1                	jne    f01046ee <vprintfmt+0x1ea>
f01046fd:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104700:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104703:	eb ad                	jmp    f01046b2 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104705:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104709:	74 1e                	je     f0104729 <vprintfmt+0x225>
f010470b:	0f be d2             	movsbl %dl,%edx
f010470e:	83 ea 20             	sub    $0x20,%edx
f0104711:	83 fa 5e             	cmp    $0x5e,%edx
f0104714:	76 13                	jbe    f0104729 <vprintfmt+0x225>
					putch('?', putdat);
f0104716:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104719:	89 44 24 04          	mov    %eax,0x4(%esp)
f010471d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104724:	ff 55 08             	call   *0x8(%ebp)
f0104727:	eb 0d                	jmp    f0104736 <vprintfmt+0x232>
				else
					putch(ch, putdat);
f0104729:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010472c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104730:	89 04 24             	mov    %eax,(%esp)
f0104733:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104736:	83 ef 01             	sub    $0x1,%edi
f0104739:	83 c6 01             	add    $0x1,%esi
f010473c:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0104740:	0f be c2             	movsbl %dl,%eax
f0104743:	85 c0                	test   %eax,%eax
f0104745:	75 20                	jne    f0104767 <vprintfmt+0x263>
f0104747:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f010474a:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010474d:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104750:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104754:	7f 25                	jg     f010477b <vprintfmt+0x277>
f0104756:	e9 d2 fd ff ff       	jmp    f010452d <vprintfmt+0x29>
f010475b:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010475e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104761:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104764:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104767:	85 db                	test   %ebx,%ebx
f0104769:	78 9a                	js     f0104705 <vprintfmt+0x201>
f010476b:	83 eb 01             	sub    $0x1,%ebx
f010476e:	79 95                	jns    f0104705 <vprintfmt+0x201>
f0104770:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0104773:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104776:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104779:	eb d5                	jmp    f0104750 <vprintfmt+0x24c>
f010477b:	8b 75 08             	mov    0x8(%ebp),%esi
f010477e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104781:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104784:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104788:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010478f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104791:	83 eb 01             	sub    $0x1,%ebx
f0104794:	75 ee                	jne    f0104784 <vprintfmt+0x280>
f0104796:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104799:	e9 8f fd ff ff       	jmp    f010452d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010479e:	83 fa 01             	cmp    $0x1,%edx
f01047a1:	7e 16                	jle    f01047b9 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
f01047a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01047a6:	8d 50 08             	lea    0x8(%eax),%edx
f01047a9:	89 55 14             	mov    %edx,0x14(%ebp)
f01047ac:	8b 50 04             	mov    0x4(%eax),%edx
f01047af:	8b 00                	mov    (%eax),%eax
f01047b1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01047b4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01047b7:	eb 32                	jmp    f01047eb <vprintfmt+0x2e7>
	else if (lflag)
f01047b9:	85 d2                	test   %edx,%edx
f01047bb:	74 18                	je     f01047d5 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
f01047bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01047c0:	8d 50 04             	lea    0x4(%eax),%edx
f01047c3:	89 55 14             	mov    %edx,0x14(%ebp)
f01047c6:	8b 30                	mov    (%eax),%esi
f01047c8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01047cb:	89 f0                	mov    %esi,%eax
f01047cd:	c1 f8 1f             	sar    $0x1f,%eax
f01047d0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01047d3:	eb 16                	jmp    f01047eb <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
f01047d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01047d8:	8d 50 04             	lea    0x4(%eax),%edx
f01047db:	89 55 14             	mov    %edx,0x14(%ebp)
f01047de:	8b 30                	mov    (%eax),%esi
f01047e0:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01047e3:	89 f0                	mov    %esi,%eax
f01047e5:	c1 f8 1f             	sar    $0x1f,%eax
f01047e8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01047eb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01047ee:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01047f1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01047f6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01047fa:	0f 89 80 00 00 00    	jns    f0104880 <vprintfmt+0x37c>
				putch('-', putdat);
f0104800:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104804:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010480b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010480e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104811:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104814:	f7 d8                	neg    %eax
f0104816:	83 d2 00             	adc    $0x0,%edx
f0104819:	f7 da                	neg    %edx
			}
			base = 10;
f010481b:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104820:	eb 5e                	jmp    f0104880 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104822:	8d 45 14             	lea    0x14(%ebp),%eax
f0104825:	e8 5b fc ff ff       	call   f0104485 <getuint>
			base = 10;
f010482a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010482f:	eb 4f                	jmp    f0104880 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0104831:	8d 45 14             	lea    0x14(%ebp),%eax
f0104834:	e8 4c fc ff ff       	call   f0104485 <getuint>
			base = 8;
f0104839:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010483e:	eb 40                	jmp    f0104880 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
f0104840:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104844:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010484b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010484e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104852:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104859:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010485c:	8b 45 14             	mov    0x14(%ebp),%eax
f010485f:	8d 50 04             	lea    0x4(%eax),%edx
f0104862:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104865:	8b 00                	mov    (%eax),%eax
f0104867:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010486c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104871:	eb 0d                	jmp    f0104880 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104873:	8d 45 14             	lea    0x14(%ebp),%eax
f0104876:	e8 0a fc ff ff       	call   f0104485 <getuint>
			base = 16;
f010487b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104880:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0104884:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104888:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010488b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010488f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104893:	89 04 24             	mov    %eax,(%esp)
f0104896:	89 54 24 04          	mov    %edx,0x4(%esp)
f010489a:	89 fa                	mov    %edi,%edx
f010489c:	8b 45 08             	mov    0x8(%ebp),%eax
f010489f:	e8 ec fa ff ff       	call   f0104390 <printnum>
			break;
f01048a4:	e9 84 fc ff ff       	jmp    f010452d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01048a9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01048ad:	89 0c 24             	mov    %ecx,(%esp)
f01048b0:	ff 55 08             	call   *0x8(%ebp)
			break;
f01048b3:	e9 75 fc ff ff       	jmp    f010452d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01048b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01048bc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01048c3:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01048c6:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01048ca:	0f 84 5b fc ff ff    	je     f010452b <vprintfmt+0x27>
f01048d0:	89 f3                	mov    %esi,%ebx
f01048d2:	83 eb 01             	sub    $0x1,%ebx
f01048d5:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01048d9:	75 f7                	jne    f01048d2 <vprintfmt+0x3ce>
f01048db:	e9 4d fc ff ff       	jmp    f010452d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f01048e0:	83 c4 3c             	add    $0x3c,%esp
f01048e3:	5b                   	pop    %ebx
f01048e4:	5e                   	pop    %esi
f01048e5:	5f                   	pop    %edi
f01048e6:	5d                   	pop    %ebp
f01048e7:	c3                   	ret    

f01048e8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01048e8:	55                   	push   %ebp
f01048e9:	89 e5                	mov    %esp,%ebp
f01048eb:	83 ec 28             	sub    $0x28,%esp
f01048ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01048f1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01048f4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01048f7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01048fb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01048fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104905:	85 c0                	test   %eax,%eax
f0104907:	74 30                	je     f0104939 <vsnprintf+0x51>
f0104909:	85 d2                	test   %edx,%edx
f010490b:	7e 2c                	jle    f0104939 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010490d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104910:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104914:	8b 45 10             	mov    0x10(%ebp),%eax
f0104917:	89 44 24 08          	mov    %eax,0x8(%esp)
f010491b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010491e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104922:	c7 04 24 bf 44 10 f0 	movl   $0xf01044bf,(%esp)
f0104929:	e8 d6 fb ff ff       	call   f0104504 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010492e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104931:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104934:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104937:	eb 05                	jmp    f010493e <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104939:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010493e:	c9                   	leave  
f010493f:	c3                   	ret    

f0104940 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104940:	55                   	push   %ebp
f0104941:	89 e5                	mov    %esp,%ebp
f0104943:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104946:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104949:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010494d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104950:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104954:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104957:	89 44 24 04          	mov    %eax,0x4(%esp)
f010495b:	8b 45 08             	mov    0x8(%ebp),%eax
f010495e:	89 04 24             	mov    %eax,(%esp)
f0104961:	e8 82 ff ff ff       	call   f01048e8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104966:	c9                   	leave  
f0104967:	c3                   	ret    
f0104968:	66 90                	xchg   %ax,%ax
f010496a:	66 90                	xchg   %ax,%ax
f010496c:	66 90                	xchg   %ax,%ax
f010496e:	66 90                	xchg   %ax,%ax

f0104970 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104970:	55                   	push   %ebp
f0104971:	89 e5                	mov    %esp,%ebp
f0104973:	57                   	push   %edi
f0104974:	56                   	push   %esi
f0104975:	53                   	push   %ebx
f0104976:	83 ec 1c             	sub    $0x1c,%esp
f0104979:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010497c:	85 c0                	test   %eax,%eax
f010497e:	74 10                	je     f0104990 <readline+0x20>
		cprintf("%s", prompt);
f0104980:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104984:	c7 04 24 b5 5d 10 f0 	movl   $0xf0105db5,(%esp)
f010498b:	e8 ca ec ff ff       	call   f010365a <cprintf>

	i = 0;
	echoing = iscons(0);
f0104990:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104997:	e8 bd bc ff ff       	call   f0100659 <iscons>
f010499c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010499e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01049a3:	e8 a0 bc ff ff       	call   f0100648 <getchar>
f01049a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01049aa:	85 c0                	test   %eax,%eax
f01049ac:	79 17                	jns    f01049c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01049ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049b2:	c7 04 24 54 67 10 f0 	movl   $0xf0106754,(%esp)
f01049b9:	e8 9c ec ff ff       	call   f010365a <cprintf>
			return NULL;
f01049be:	b8 00 00 00 00       	mov    $0x0,%eax
f01049c3:	eb 6d                	jmp    f0104a32 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01049c5:	83 f8 7f             	cmp    $0x7f,%eax
f01049c8:	74 05                	je     f01049cf <readline+0x5f>
f01049ca:	83 f8 08             	cmp    $0x8,%eax
f01049cd:	75 19                	jne    f01049e8 <readline+0x78>
f01049cf:	85 f6                	test   %esi,%esi
f01049d1:	7e 15                	jle    f01049e8 <readline+0x78>
			if (echoing)
f01049d3:	85 ff                	test   %edi,%edi
f01049d5:	74 0c                	je     f01049e3 <readline+0x73>
				cputchar('\b');
f01049d7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01049de:	e8 55 bc ff ff       	call   f0100638 <cputchar>
			i--;
f01049e3:	83 ee 01             	sub    $0x1,%esi
f01049e6:	eb bb                	jmp    f01049a3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01049e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01049ee:	7f 1c                	jg     f0104a0c <readline+0x9c>
f01049f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01049f3:	7e 17                	jle    f0104a0c <readline+0x9c>
			if (echoing)
f01049f5:	85 ff                	test   %edi,%edi
f01049f7:	74 08                	je     f0104a01 <readline+0x91>
				cputchar(c);
f01049f9:	89 1c 24             	mov    %ebx,(%esp)
f01049fc:	e8 37 bc ff ff       	call   f0100638 <cputchar>
			buf[i++] = c;
f0104a01:	88 9e c0 db 17 f0    	mov    %bl,-0xfe82440(%esi)
f0104a07:	8d 76 01             	lea    0x1(%esi),%esi
f0104a0a:	eb 97                	jmp    f01049a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104a0c:	83 fb 0d             	cmp    $0xd,%ebx
f0104a0f:	74 05                	je     f0104a16 <readline+0xa6>
f0104a11:	83 fb 0a             	cmp    $0xa,%ebx
f0104a14:	75 8d                	jne    f01049a3 <readline+0x33>
			if (echoing)
f0104a16:	85 ff                	test   %edi,%edi
f0104a18:	74 0c                	je     f0104a26 <readline+0xb6>
				cputchar('\n');
f0104a1a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104a21:	e8 12 bc ff ff       	call   f0100638 <cputchar>
			buf[i] = 0;
f0104a26:	c6 86 c0 db 17 f0 00 	movb   $0x0,-0xfe82440(%esi)
			return buf;
f0104a2d:	b8 c0 db 17 f0       	mov    $0xf017dbc0,%eax
		}
	}
}
f0104a32:	83 c4 1c             	add    $0x1c,%esp
f0104a35:	5b                   	pop    %ebx
f0104a36:	5e                   	pop    %esi
f0104a37:	5f                   	pop    %edi
f0104a38:	5d                   	pop    %ebp
f0104a39:	c3                   	ret    
f0104a3a:	66 90                	xchg   %ax,%ax
f0104a3c:	66 90                	xchg   %ax,%ax
f0104a3e:	66 90                	xchg   %ax,%ax

f0104a40 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104a40:	55                   	push   %ebp
f0104a41:	89 e5                	mov    %esp,%ebp
f0104a43:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a46:	80 3a 00             	cmpb   $0x0,(%edx)
f0104a49:	74 10                	je     f0104a5b <strlen+0x1b>
f0104a4b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0104a50:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a53:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104a57:	75 f7                	jne    f0104a50 <strlen+0x10>
f0104a59:	eb 05                	jmp    f0104a60 <strlen+0x20>
f0104a5b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0104a60:	5d                   	pop    %ebp
f0104a61:	c3                   	ret    

f0104a62 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104a62:	55                   	push   %ebp
f0104a63:	89 e5                	mov    %esp,%ebp
f0104a65:	53                   	push   %ebx
f0104a66:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104a69:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a6c:	85 c9                	test   %ecx,%ecx
f0104a6e:	74 1c                	je     f0104a8c <strnlen+0x2a>
f0104a70:	80 3b 00             	cmpb   $0x0,(%ebx)
f0104a73:	74 1e                	je     f0104a93 <strnlen+0x31>
f0104a75:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0104a7a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a7c:	39 ca                	cmp    %ecx,%edx
f0104a7e:	74 18                	je     f0104a98 <strnlen+0x36>
f0104a80:	83 c2 01             	add    $0x1,%edx
f0104a83:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0104a88:	75 f0                	jne    f0104a7a <strnlen+0x18>
f0104a8a:	eb 0c                	jmp    f0104a98 <strnlen+0x36>
f0104a8c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a91:	eb 05                	jmp    f0104a98 <strnlen+0x36>
f0104a93:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0104a98:	5b                   	pop    %ebx
f0104a99:	5d                   	pop    %ebp
f0104a9a:	c3                   	ret    

f0104a9b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104a9b:	55                   	push   %ebp
f0104a9c:	89 e5                	mov    %esp,%ebp
f0104a9e:	53                   	push   %ebx
f0104a9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104aa2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104aa5:	89 c2                	mov    %eax,%edx
f0104aa7:	83 c2 01             	add    $0x1,%edx
f0104aaa:	83 c1 01             	add    $0x1,%ecx
f0104aad:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104ab1:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104ab4:	84 db                	test   %bl,%bl
f0104ab6:	75 ef                	jne    f0104aa7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104ab8:	5b                   	pop    %ebx
f0104ab9:	5d                   	pop    %ebp
f0104aba:	c3                   	ret    

f0104abb <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104abb:	55                   	push   %ebp
f0104abc:	89 e5                	mov    %esp,%ebp
f0104abe:	53                   	push   %ebx
f0104abf:	83 ec 08             	sub    $0x8,%esp
f0104ac2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104ac5:	89 1c 24             	mov    %ebx,(%esp)
f0104ac8:	e8 73 ff ff ff       	call   f0104a40 <strlen>
	strcpy(dst + len, src);
f0104acd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104ad0:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104ad4:	01 d8                	add    %ebx,%eax
f0104ad6:	89 04 24             	mov    %eax,(%esp)
f0104ad9:	e8 bd ff ff ff       	call   f0104a9b <strcpy>
	return dst;
}
f0104ade:	89 d8                	mov    %ebx,%eax
f0104ae0:	83 c4 08             	add    $0x8,%esp
f0104ae3:	5b                   	pop    %ebx
f0104ae4:	5d                   	pop    %ebp
f0104ae5:	c3                   	ret    

f0104ae6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104ae6:	55                   	push   %ebp
f0104ae7:	89 e5                	mov    %esp,%ebp
f0104ae9:	56                   	push   %esi
f0104aea:	53                   	push   %ebx
f0104aeb:	8b 75 08             	mov    0x8(%ebp),%esi
f0104aee:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104af1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104af4:	85 db                	test   %ebx,%ebx
f0104af6:	74 17                	je     f0104b0f <strncpy+0x29>
f0104af8:	01 f3                	add    %esi,%ebx
f0104afa:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0104afc:	83 c1 01             	add    $0x1,%ecx
f0104aff:	0f b6 02             	movzbl (%edx),%eax
f0104b02:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104b05:	80 3a 01             	cmpb   $0x1,(%edx)
f0104b08:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b0b:	39 d9                	cmp    %ebx,%ecx
f0104b0d:	75 ed                	jne    f0104afc <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104b0f:	89 f0                	mov    %esi,%eax
f0104b11:	5b                   	pop    %ebx
f0104b12:	5e                   	pop    %esi
f0104b13:	5d                   	pop    %ebp
f0104b14:	c3                   	ret    

f0104b15 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104b15:	55                   	push   %ebp
f0104b16:	89 e5                	mov    %esp,%ebp
f0104b18:	57                   	push   %edi
f0104b19:	56                   	push   %esi
f0104b1a:	53                   	push   %ebx
f0104b1b:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104b1e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b21:	8b 75 10             	mov    0x10(%ebp),%esi
f0104b24:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104b26:	85 f6                	test   %esi,%esi
f0104b28:	74 34                	je     f0104b5e <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f0104b2a:	83 fe 01             	cmp    $0x1,%esi
f0104b2d:	74 26                	je     f0104b55 <strlcpy+0x40>
f0104b2f:	0f b6 0b             	movzbl (%ebx),%ecx
f0104b32:	84 c9                	test   %cl,%cl
f0104b34:	74 23                	je     f0104b59 <strlcpy+0x44>
f0104b36:	83 ee 02             	sub    $0x2,%esi
f0104b39:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0104b3e:	83 c0 01             	add    $0x1,%eax
f0104b41:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104b44:	39 f2                	cmp    %esi,%edx
f0104b46:	74 13                	je     f0104b5b <strlcpy+0x46>
f0104b48:	83 c2 01             	add    $0x1,%edx
f0104b4b:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0104b4f:	84 c9                	test   %cl,%cl
f0104b51:	75 eb                	jne    f0104b3e <strlcpy+0x29>
f0104b53:	eb 06                	jmp    f0104b5b <strlcpy+0x46>
f0104b55:	89 f8                	mov    %edi,%eax
f0104b57:	eb 02                	jmp    f0104b5b <strlcpy+0x46>
f0104b59:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104b5b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104b5e:	29 f8                	sub    %edi,%eax
}
f0104b60:	5b                   	pop    %ebx
f0104b61:	5e                   	pop    %esi
f0104b62:	5f                   	pop    %edi
f0104b63:	5d                   	pop    %ebp
f0104b64:	c3                   	ret    

f0104b65 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104b65:	55                   	push   %ebp
f0104b66:	89 e5                	mov    %esp,%ebp
f0104b68:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b6b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104b6e:	0f b6 01             	movzbl (%ecx),%eax
f0104b71:	84 c0                	test   %al,%al
f0104b73:	74 15                	je     f0104b8a <strcmp+0x25>
f0104b75:	3a 02                	cmp    (%edx),%al
f0104b77:	75 11                	jne    f0104b8a <strcmp+0x25>
		p++, q++;
f0104b79:	83 c1 01             	add    $0x1,%ecx
f0104b7c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104b7f:	0f b6 01             	movzbl (%ecx),%eax
f0104b82:	84 c0                	test   %al,%al
f0104b84:	74 04                	je     f0104b8a <strcmp+0x25>
f0104b86:	3a 02                	cmp    (%edx),%al
f0104b88:	74 ef                	je     f0104b79 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b8a:	0f b6 c0             	movzbl %al,%eax
f0104b8d:	0f b6 12             	movzbl (%edx),%edx
f0104b90:	29 d0                	sub    %edx,%eax
}
f0104b92:	5d                   	pop    %ebp
f0104b93:	c3                   	ret    

f0104b94 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104b94:	55                   	push   %ebp
f0104b95:	89 e5                	mov    %esp,%ebp
f0104b97:	56                   	push   %esi
f0104b98:	53                   	push   %ebx
f0104b99:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104b9c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b9f:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0104ba2:	85 f6                	test   %esi,%esi
f0104ba4:	74 29                	je     f0104bcf <strncmp+0x3b>
f0104ba6:	0f b6 03             	movzbl (%ebx),%eax
f0104ba9:	84 c0                	test   %al,%al
f0104bab:	74 30                	je     f0104bdd <strncmp+0x49>
f0104bad:	3a 02                	cmp    (%edx),%al
f0104baf:	75 2c                	jne    f0104bdd <strncmp+0x49>
f0104bb1:	8d 43 01             	lea    0x1(%ebx),%eax
f0104bb4:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f0104bb6:	89 c3                	mov    %eax,%ebx
f0104bb8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104bbb:	39 f0                	cmp    %esi,%eax
f0104bbd:	74 17                	je     f0104bd6 <strncmp+0x42>
f0104bbf:	0f b6 08             	movzbl (%eax),%ecx
f0104bc2:	84 c9                	test   %cl,%cl
f0104bc4:	74 17                	je     f0104bdd <strncmp+0x49>
f0104bc6:	83 c0 01             	add    $0x1,%eax
f0104bc9:	3a 0a                	cmp    (%edx),%cl
f0104bcb:	74 e9                	je     f0104bb6 <strncmp+0x22>
f0104bcd:	eb 0e                	jmp    f0104bdd <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104bcf:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bd4:	eb 0f                	jmp    f0104be5 <strncmp+0x51>
f0104bd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bdb:	eb 08                	jmp    f0104be5 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104bdd:	0f b6 03             	movzbl (%ebx),%eax
f0104be0:	0f b6 12             	movzbl (%edx),%edx
f0104be3:	29 d0                	sub    %edx,%eax
}
f0104be5:	5b                   	pop    %ebx
f0104be6:	5e                   	pop    %esi
f0104be7:	5d                   	pop    %ebp
f0104be8:	c3                   	ret    

f0104be9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104be9:	55                   	push   %ebp
f0104bea:	89 e5                	mov    %esp,%ebp
f0104bec:	53                   	push   %ebx
f0104bed:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bf0:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0104bf3:	0f b6 18             	movzbl (%eax),%ebx
f0104bf6:	84 db                	test   %bl,%bl
f0104bf8:	74 1d                	je     f0104c17 <strchr+0x2e>
f0104bfa:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0104bfc:	38 d3                	cmp    %dl,%bl
f0104bfe:	75 06                	jne    f0104c06 <strchr+0x1d>
f0104c00:	eb 1a                	jmp    f0104c1c <strchr+0x33>
f0104c02:	38 ca                	cmp    %cl,%dl
f0104c04:	74 16                	je     f0104c1c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c06:	83 c0 01             	add    $0x1,%eax
f0104c09:	0f b6 10             	movzbl (%eax),%edx
f0104c0c:	84 d2                	test   %dl,%dl
f0104c0e:	75 f2                	jne    f0104c02 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0104c10:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c15:	eb 05                	jmp    f0104c1c <strchr+0x33>
f0104c17:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c1c:	5b                   	pop    %ebx
f0104c1d:	5d                   	pop    %ebp
f0104c1e:	c3                   	ret    

f0104c1f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104c1f:	55                   	push   %ebp
f0104c20:	89 e5                	mov    %esp,%ebp
f0104c22:	53                   	push   %ebx
f0104c23:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c26:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0104c29:	0f b6 18             	movzbl (%eax),%ebx
f0104c2c:	84 db                	test   %bl,%bl
f0104c2e:	74 16                	je     f0104c46 <strfind+0x27>
f0104c30:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0104c32:	38 d3                	cmp    %dl,%bl
f0104c34:	75 06                	jne    f0104c3c <strfind+0x1d>
f0104c36:	eb 0e                	jmp    f0104c46 <strfind+0x27>
f0104c38:	38 ca                	cmp    %cl,%dl
f0104c3a:	74 0a                	je     f0104c46 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104c3c:	83 c0 01             	add    $0x1,%eax
f0104c3f:	0f b6 10             	movzbl (%eax),%edx
f0104c42:	84 d2                	test   %dl,%dl
f0104c44:	75 f2                	jne    f0104c38 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0104c46:	5b                   	pop    %ebx
f0104c47:	5d                   	pop    %ebp
f0104c48:	c3                   	ret    

f0104c49 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104c49:	55                   	push   %ebp
f0104c4a:	89 e5                	mov    %esp,%ebp
f0104c4c:	57                   	push   %edi
f0104c4d:	56                   	push   %esi
f0104c4e:	53                   	push   %ebx
f0104c4f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104c52:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104c55:	85 c9                	test   %ecx,%ecx
f0104c57:	74 36                	je     f0104c8f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104c59:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104c5f:	75 28                	jne    f0104c89 <memset+0x40>
f0104c61:	f6 c1 03             	test   $0x3,%cl
f0104c64:	75 23                	jne    f0104c89 <memset+0x40>
		c &= 0xFF;
f0104c66:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104c6a:	89 d3                	mov    %edx,%ebx
f0104c6c:	c1 e3 08             	shl    $0x8,%ebx
f0104c6f:	89 d6                	mov    %edx,%esi
f0104c71:	c1 e6 18             	shl    $0x18,%esi
f0104c74:	89 d0                	mov    %edx,%eax
f0104c76:	c1 e0 10             	shl    $0x10,%eax
f0104c79:	09 f0                	or     %esi,%eax
f0104c7b:	09 c2                	or     %eax,%edx
f0104c7d:	89 d0                	mov    %edx,%eax
f0104c7f:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104c81:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104c84:	fc                   	cld    
f0104c85:	f3 ab                	rep stos %eax,%es:(%edi)
f0104c87:	eb 06                	jmp    f0104c8f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104c89:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c8c:	fc                   	cld    
f0104c8d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104c8f:	89 f8                	mov    %edi,%eax
f0104c91:	5b                   	pop    %ebx
f0104c92:	5e                   	pop    %esi
f0104c93:	5f                   	pop    %edi
f0104c94:	5d                   	pop    %ebp
f0104c95:	c3                   	ret    

f0104c96 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104c96:	55                   	push   %ebp
f0104c97:	89 e5                	mov    %esp,%ebp
f0104c99:	57                   	push   %edi
f0104c9a:	56                   	push   %esi
f0104c9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c9e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104ca1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104ca4:	39 c6                	cmp    %eax,%esi
f0104ca6:	73 35                	jae    f0104cdd <memmove+0x47>
f0104ca8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104cab:	39 d0                	cmp    %edx,%eax
f0104cad:	73 2e                	jae    f0104cdd <memmove+0x47>
		s += n;
		d += n;
f0104caf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104cb2:	89 d6                	mov    %edx,%esi
f0104cb4:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104cb6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104cbc:	75 13                	jne    f0104cd1 <memmove+0x3b>
f0104cbe:	f6 c1 03             	test   $0x3,%cl
f0104cc1:	75 0e                	jne    f0104cd1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104cc3:	83 ef 04             	sub    $0x4,%edi
f0104cc6:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104cc9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104ccc:	fd                   	std    
f0104ccd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104ccf:	eb 09                	jmp    f0104cda <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104cd1:	83 ef 01             	sub    $0x1,%edi
f0104cd4:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104cd7:	fd                   	std    
f0104cd8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104cda:	fc                   	cld    
f0104cdb:	eb 1d                	jmp    f0104cfa <memmove+0x64>
f0104cdd:	89 f2                	mov    %esi,%edx
f0104cdf:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104ce1:	f6 c2 03             	test   $0x3,%dl
f0104ce4:	75 0f                	jne    f0104cf5 <memmove+0x5f>
f0104ce6:	f6 c1 03             	test   $0x3,%cl
f0104ce9:	75 0a                	jne    f0104cf5 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104ceb:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104cee:	89 c7                	mov    %eax,%edi
f0104cf0:	fc                   	cld    
f0104cf1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104cf3:	eb 05                	jmp    f0104cfa <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104cf5:	89 c7                	mov    %eax,%edi
f0104cf7:	fc                   	cld    
f0104cf8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104cfa:	5e                   	pop    %esi
f0104cfb:	5f                   	pop    %edi
f0104cfc:	5d                   	pop    %ebp
f0104cfd:	c3                   	ret    

f0104cfe <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0104cfe:	55                   	push   %ebp
f0104cff:	89 e5                	mov    %esp,%ebp
f0104d01:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104d04:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d07:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104d0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d12:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d15:	89 04 24             	mov    %eax,(%esp)
f0104d18:	e8 79 ff ff ff       	call   f0104c96 <memmove>
}
f0104d1d:	c9                   	leave  
f0104d1e:	c3                   	ret    

f0104d1f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104d1f:	55                   	push   %ebp
f0104d20:	89 e5                	mov    %esp,%ebp
f0104d22:	57                   	push   %edi
f0104d23:	56                   	push   %esi
f0104d24:	53                   	push   %ebx
f0104d25:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104d28:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d2b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d2e:	8d 78 ff             	lea    -0x1(%eax),%edi
f0104d31:	85 c0                	test   %eax,%eax
f0104d33:	74 36                	je     f0104d6b <memcmp+0x4c>
		if (*s1 != *s2)
f0104d35:	0f b6 03             	movzbl (%ebx),%eax
f0104d38:	0f b6 0e             	movzbl (%esi),%ecx
f0104d3b:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d40:	38 c8                	cmp    %cl,%al
f0104d42:	74 1c                	je     f0104d60 <memcmp+0x41>
f0104d44:	eb 10                	jmp    f0104d56 <memcmp+0x37>
f0104d46:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104d4b:	83 c2 01             	add    $0x1,%edx
f0104d4e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0104d52:	38 c8                	cmp    %cl,%al
f0104d54:	74 0a                	je     f0104d60 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0104d56:	0f b6 c0             	movzbl %al,%eax
f0104d59:	0f b6 c9             	movzbl %cl,%ecx
f0104d5c:	29 c8                	sub    %ecx,%eax
f0104d5e:	eb 10                	jmp    f0104d70 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d60:	39 fa                	cmp    %edi,%edx
f0104d62:	75 e2                	jne    f0104d46 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104d64:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d69:	eb 05                	jmp    f0104d70 <memcmp+0x51>
f0104d6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d70:	5b                   	pop    %ebx
f0104d71:	5e                   	pop    %esi
f0104d72:	5f                   	pop    %edi
f0104d73:	5d                   	pop    %ebp
f0104d74:	c3                   	ret    

f0104d75 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104d75:	55                   	push   %ebp
f0104d76:	89 e5                	mov    %esp,%ebp
f0104d78:	53                   	push   %ebx
f0104d79:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d7c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0104d7f:	89 c2                	mov    %eax,%edx
f0104d81:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104d84:	39 d0                	cmp    %edx,%eax
f0104d86:	73 13                	jae    f0104d9b <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104d88:	89 d9                	mov    %ebx,%ecx
f0104d8a:	38 18                	cmp    %bl,(%eax)
f0104d8c:	75 06                	jne    f0104d94 <memfind+0x1f>
f0104d8e:	eb 0b                	jmp    f0104d9b <memfind+0x26>
f0104d90:	38 08                	cmp    %cl,(%eax)
f0104d92:	74 07                	je     f0104d9b <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104d94:	83 c0 01             	add    $0x1,%eax
f0104d97:	39 d0                	cmp    %edx,%eax
f0104d99:	75 f5                	jne    f0104d90 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104d9b:	5b                   	pop    %ebx
f0104d9c:	5d                   	pop    %ebp
f0104d9d:	c3                   	ret    

f0104d9e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104d9e:	55                   	push   %ebp
f0104d9f:	89 e5                	mov    %esp,%ebp
f0104da1:	57                   	push   %edi
f0104da2:	56                   	push   %esi
f0104da3:	53                   	push   %ebx
f0104da4:	8b 55 08             	mov    0x8(%ebp),%edx
f0104da7:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104daa:	0f b6 0a             	movzbl (%edx),%ecx
f0104dad:	80 f9 09             	cmp    $0x9,%cl
f0104db0:	74 05                	je     f0104db7 <strtol+0x19>
f0104db2:	80 f9 20             	cmp    $0x20,%cl
f0104db5:	75 10                	jne    f0104dc7 <strtol+0x29>
		s++;
f0104db7:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104dba:	0f b6 0a             	movzbl (%edx),%ecx
f0104dbd:	80 f9 09             	cmp    $0x9,%cl
f0104dc0:	74 f5                	je     f0104db7 <strtol+0x19>
f0104dc2:	80 f9 20             	cmp    $0x20,%cl
f0104dc5:	74 f0                	je     f0104db7 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104dc7:	80 f9 2b             	cmp    $0x2b,%cl
f0104dca:	75 0a                	jne    f0104dd6 <strtol+0x38>
		s++;
f0104dcc:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104dcf:	bf 00 00 00 00       	mov    $0x0,%edi
f0104dd4:	eb 11                	jmp    f0104de7 <strtol+0x49>
f0104dd6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104ddb:	80 f9 2d             	cmp    $0x2d,%cl
f0104dde:	75 07                	jne    f0104de7 <strtol+0x49>
		s++, neg = 1;
f0104de0:	83 c2 01             	add    $0x1,%edx
f0104de3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104de7:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104dec:	75 15                	jne    f0104e03 <strtol+0x65>
f0104dee:	80 3a 30             	cmpb   $0x30,(%edx)
f0104df1:	75 10                	jne    f0104e03 <strtol+0x65>
f0104df3:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104df7:	75 0a                	jne    f0104e03 <strtol+0x65>
		s += 2, base = 16;
f0104df9:	83 c2 02             	add    $0x2,%edx
f0104dfc:	b8 10 00 00 00       	mov    $0x10,%eax
f0104e01:	eb 10                	jmp    f0104e13 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f0104e03:	85 c0                	test   %eax,%eax
f0104e05:	75 0c                	jne    f0104e13 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e07:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e09:	80 3a 30             	cmpb   $0x30,(%edx)
f0104e0c:	75 05                	jne    f0104e13 <strtol+0x75>
		s++, base = 8;
f0104e0e:	83 c2 01             	add    $0x1,%edx
f0104e11:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104e13:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104e18:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e1b:	0f b6 0a             	movzbl (%edx),%ecx
f0104e1e:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104e21:	89 f0                	mov    %esi,%eax
f0104e23:	3c 09                	cmp    $0x9,%al
f0104e25:	77 08                	ja     f0104e2f <strtol+0x91>
			dig = *s - '0';
f0104e27:	0f be c9             	movsbl %cl,%ecx
f0104e2a:	83 e9 30             	sub    $0x30,%ecx
f0104e2d:	eb 20                	jmp    f0104e4f <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0104e2f:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104e32:	89 f0                	mov    %esi,%eax
f0104e34:	3c 19                	cmp    $0x19,%al
f0104e36:	77 08                	ja     f0104e40 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0104e38:	0f be c9             	movsbl %cl,%ecx
f0104e3b:	83 e9 57             	sub    $0x57,%ecx
f0104e3e:	eb 0f                	jmp    f0104e4f <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0104e40:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104e43:	89 f0                	mov    %esi,%eax
f0104e45:	3c 19                	cmp    $0x19,%al
f0104e47:	77 16                	ja     f0104e5f <strtol+0xc1>
			dig = *s - 'A' + 10;
f0104e49:	0f be c9             	movsbl %cl,%ecx
f0104e4c:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104e4f:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104e52:	7d 0f                	jge    f0104e63 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0104e54:	83 c2 01             	add    $0x1,%edx
f0104e57:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104e5b:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104e5d:	eb bc                	jmp    f0104e1b <strtol+0x7d>
f0104e5f:	89 d8                	mov    %ebx,%eax
f0104e61:	eb 02                	jmp    f0104e65 <strtol+0xc7>
f0104e63:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104e65:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104e69:	74 05                	je     f0104e70 <strtol+0xd2>
		*endptr = (char *) s;
f0104e6b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e6e:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104e70:	f7 d8                	neg    %eax
f0104e72:	85 ff                	test   %edi,%edi
f0104e74:	0f 44 c3             	cmove  %ebx,%eax
}
f0104e77:	5b                   	pop    %ebx
f0104e78:	5e                   	pop    %esi
f0104e79:	5f                   	pop    %edi
f0104e7a:	5d                   	pop    %ebp
f0104e7b:	c3                   	ret    
f0104e7c:	66 90                	xchg   %ax,%ax
f0104e7e:	66 90                	xchg   %ax,%ax

f0104e80 <__udivdi3>:
f0104e80:	55                   	push   %ebp
f0104e81:	57                   	push   %edi
f0104e82:	56                   	push   %esi
f0104e83:	83 ec 0c             	sub    $0xc,%esp
f0104e86:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104e8a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104e8e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104e92:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104e96:	85 c0                	test   %eax,%eax
f0104e98:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104e9c:	89 ea                	mov    %ebp,%edx
f0104e9e:	89 0c 24             	mov    %ecx,(%esp)
f0104ea1:	75 2d                	jne    f0104ed0 <__udivdi3+0x50>
f0104ea3:	39 e9                	cmp    %ebp,%ecx
f0104ea5:	77 61                	ja     f0104f08 <__udivdi3+0x88>
f0104ea7:	85 c9                	test   %ecx,%ecx
f0104ea9:	89 ce                	mov    %ecx,%esi
f0104eab:	75 0b                	jne    f0104eb8 <__udivdi3+0x38>
f0104ead:	b8 01 00 00 00       	mov    $0x1,%eax
f0104eb2:	31 d2                	xor    %edx,%edx
f0104eb4:	f7 f1                	div    %ecx
f0104eb6:	89 c6                	mov    %eax,%esi
f0104eb8:	31 d2                	xor    %edx,%edx
f0104eba:	89 e8                	mov    %ebp,%eax
f0104ebc:	f7 f6                	div    %esi
f0104ebe:	89 c5                	mov    %eax,%ebp
f0104ec0:	89 f8                	mov    %edi,%eax
f0104ec2:	f7 f6                	div    %esi
f0104ec4:	89 ea                	mov    %ebp,%edx
f0104ec6:	83 c4 0c             	add    $0xc,%esp
f0104ec9:	5e                   	pop    %esi
f0104eca:	5f                   	pop    %edi
f0104ecb:	5d                   	pop    %ebp
f0104ecc:	c3                   	ret    
f0104ecd:	8d 76 00             	lea    0x0(%esi),%esi
f0104ed0:	39 e8                	cmp    %ebp,%eax
f0104ed2:	77 24                	ja     f0104ef8 <__udivdi3+0x78>
f0104ed4:	0f bd e8             	bsr    %eax,%ebp
f0104ed7:	83 f5 1f             	xor    $0x1f,%ebp
f0104eda:	75 3c                	jne    f0104f18 <__udivdi3+0x98>
f0104edc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104ee0:	39 34 24             	cmp    %esi,(%esp)
f0104ee3:	0f 86 9f 00 00 00    	jbe    f0104f88 <__udivdi3+0x108>
f0104ee9:	39 d0                	cmp    %edx,%eax
f0104eeb:	0f 82 97 00 00 00    	jb     f0104f88 <__udivdi3+0x108>
f0104ef1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104ef8:	31 d2                	xor    %edx,%edx
f0104efa:	31 c0                	xor    %eax,%eax
f0104efc:	83 c4 0c             	add    $0xc,%esp
f0104eff:	5e                   	pop    %esi
f0104f00:	5f                   	pop    %edi
f0104f01:	5d                   	pop    %ebp
f0104f02:	c3                   	ret    
f0104f03:	90                   	nop
f0104f04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104f08:	89 f8                	mov    %edi,%eax
f0104f0a:	f7 f1                	div    %ecx
f0104f0c:	31 d2                	xor    %edx,%edx
f0104f0e:	83 c4 0c             	add    $0xc,%esp
f0104f11:	5e                   	pop    %esi
f0104f12:	5f                   	pop    %edi
f0104f13:	5d                   	pop    %ebp
f0104f14:	c3                   	ret    
f0104f15:	8d 76 00             	lea    0x0(%esi),%esi
f0104f18:	89 e9                	mov    %ebp,%ecx
f0104f1a:	8b 3c 24             	mov    (%esp),%edi
f0104f1d:	d3 e0                	shl    %cl,%eax
f0104f1f:	89 c6                	mov    %eax,%esi
f0104f21:	b8 20 00 00 00       	mov    $0x20,%eax
f0104f26:	29 e8                	sub    %ebp,%eax
f0104f28:	89 c1                	mov    %eax,%ecx
f0104f2a:	d3 ef                	shr    %cl,%edi
f0104f2c:	89 e9                	mov    %ebp,%ecx
f0104f2e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104f32:	8b 3c 24             	mov    (%esp),%edi
f0104f35:	09 74 24 08          	or     %esi,0x8(%esp)
f0104f39:	89 d6                	mov    %edx,%esi
f0104f3b:	d3 e7                	shl    %cl,%edi
f0104f3d:	89 c1                	mov    %eax,%ecx
f0104f3f:	89 3c 24             	mov    %edi,(%esp)
f0104f42:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104f46:	d3 ee                	shr    %cl,%esi
f0104f48:	89 e9                	mov    %ebp,%ecx
f0104f4a:	d3 e2                	shl    %cl,%edx
f0104f4c:	89 c1                	mov    %eax,%ecx
f0104f4e:	d3 ef                	shr    %cl,%edi
f0104f50:	09 d7                	or     %edx,%edi
f0104f52:	89 f2                	mov    %esi,%edx
f0104f54:	89 f8                	mov    %edi,%eax
f0104f56:	f7 74 24 08          	divl   0x8(%esp)
f0104f5a:	89 d6                	mov    %edx,%esi
f0104f5c:	89 c7                	mov    %eax,%edi
f0104f5e:	f7 24 24             	mull   (%esp)
f0104f61:	39 d6                	cmp    %edx,%esi
f0104f63:	89 14 24             	mov    %edx,(%esp)
f0104f66:	72 30                	jb     f0104f98 <__udivdi3+0x118>
f0104f68:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104f6c:	89 e9                	mov    %ebp,%ecx
f0104f6e:	d3 e2                	shl    %cl,%edx
f0104f70:	39 c2                	cmp    %eax,%edx
f0104f72:	73 05                	jae    f0104f79 <__udivdi3+0xf9>
f0104f74:	3b 34 24             	cmp    (%esp),%esi
f0104f77:	74 1f                	je     f0104f98 <__udivdi3+0x118>
f0104f79:	89 f8                	mov    %edi,%eax
f0104f7b:	31 d2                	xor    %edx,%edx
f0104f7d:	e9 7a ff ff ff       	jmp    f0104efc <__udivdi3+0x7c>
f0104f82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104f88:	31 d2                	xor    %edx,%edx
f0104f8a:	b8 01 00 00 00       	mov    $0x1,%eax
f0104f8f:	e9 68 ff ff ff       	jmp    f0104efc <__udivdi3+0x7c>
f0104f94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104f98:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104f9b:	31 d2                	xor    %edx,%edx
f0104f9d:	83 c4 0c             	add    $0xc,%esp
f0104fa0:	5e                   	pop    %esi
f0104fa1:	5f                   	pop    %edi
f0104fa2:	5d                   	pop    %ebp
f0104fa3:	c3                   	ret    
f0104fa4:	66 90                	xchg   %ax,%ax
f0104fa6:	66 90                	xchg   %ax,%ax
f0104fa8:	66 90                	xchg   %ax,%ax
f0104faa:	66 90                	xchg   %ax,%ax
f0104fac:	66 90                	xchg   %ax,%ax
f0104fae:	66 90                	xchg   %ax,%ax

f0104fb0 <__umoddi3>:
f0104fb0:	55                   	push   %ebp
f0104fb1:	57                   	push   %edi
f0104fb2:	56                   	push   %esi
f0104fb3:	83 ec 14             	sub    $0x14,%esp
f0104fb6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104fba:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104fbe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104fc2:	89 c7                	mov    %eax,%edi
f0104fc4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104fc8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0104fcc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104fd0:	89 34 24             	mov    %esi,(%esp)
f0104fd3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104fd7:	85 c0                	test   %eax,%eax
f0104fd9:	89 c2                	mov    %eax,%edx
f0104fdb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104fdf:	75 17                	jne    f0104ff8 <__umoddi3+0x48>
f0104fe1:	39 fe                	cmp    %edi,%esi
f0104fe3:	76 4b                	jbe    f0105030 <__umoddi3+0x80>
f0104fe5:	89 c8                	mov    %ecx,%eax
f0104fe7:	89 fa                	mov    %edi,%edx
f0104fe9:	f7 f6                	div    %esi
f0104feb:	89 d0                	mov    %edx,%eax
f0104fed:	31 d2                	xor    %edx,%edx
f0104fef:	83 c4 14             	add    $0x14,%esp
f0104ff2:	5e                   	pop    %esi
f0104ff3:	5f                   	pop    %edi
f0104ff4:	5d                   	pop    %ebp
f0104ff5:	c3                   	ret    
f0104ff6:	66 90                	xchg   %ax,%ax
f0104ff8:	39 f8                	cmp    %edi,%eax
f0104ffa:	77 54                	ja     f0105050 <__umoddi3+0xa0>
f0104ffc:	0f bd e8             	bsr    %eax,%ebp
f0104fff:	83 f5 1f             	xor    $0x1f,%ebp
f0105002:	75 5c                	jne    f0105060 <__umoddi3+0xb0>
f0105004:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0105008:	39 3c 24             	cmp    %edi,(%esp)
f010500b:	0f 87 e7 00 00 00    	ja     f01050f8 <__umoddi3+0x148>
f0105011:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105015:	29 f1                	sub    %esi,%ecx
f0105017:	19 c7                	sbb    %eax,%edi
f0105019:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010501d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105021:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105025:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105029:	83 c4 14             	add    $0x14,%esp
f010502c:	5e                   	pop    %esi
f010502d:	5f                   	pop    %edi
f010502e:	5d                   	pop    %ebp
f010502f:	c3                   	ret    
f0105030:	85 f6                	test   %esi,%esi
f0105032:	89 f5                	mov    %esi,%ebp
f0105034:	75 0b                	jne    f0105041 <__umoddi3+0x91>
f0105036:	b8 01 00 00 00       	mov    $0x1,%eax
f010503b:	31 d2                	xor    %edx,%edx
f010503d:	f7 f6                	div    %esi
f010503f:	89 c5                	mov    %eax,%ebp
f0105041:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105045:	31 d2                	xor    %edx,%edx
f0105047:	f7 f5                	div    %ebp
f0105049:	89 c8                	mov    %ecx,%eax
f010504b:	f7 f5                	div    %ebp
f010504d:	eb 9c                	jmp    f0104feb <__umoddi3+0x3b>
f010504f:	90                   	nop
f0105050:	89 c8                	mov    %ecx,%eax
f0105052:	89 fa                	mov    %edi,%edx
f0105054:	83 c4 14             	add    $0x14,%esp
f0105057:	5e                   	pop    %esi
f0105058:	5f                   	pop    %edi
f0105059:	5d                   	pop    %ebp
f010505a:	c3                   	ret    
f010505b:	90                   	nop
f010505c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105060:	8b 04 24             	mov    (%esp),%eax
f0105063:	be 20 00 00 00       	mov    $0x20,%esi
f0105068:	89 e9                	mov    %ebp,%ecx
f010506a:	29 ee                	sub    %ebp,%esi
f010506c:	d3 e2                	shl    %cl,%edx
f010506e:	89 f1                	mov    %esi,%ecx
f0105070:	d3 e8                	shr    %cl,%eax
f0105072:	89 e9                	mov    %ebp,%ecx
f0105074:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105078:	8b 04 24             	mov    (%esp),%eax
f010507b:	09 54 24 04          	or     %edx,0x4(%esp)
f010507f:	89 fa                	mov    %edi,%edx
f0105081:	d3 e0                	shl    %cl,%eax
f0105083:	89 f1                	mov    %esi,%ecx
f0105085:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105089:	8b 44 24 10          	mov    0x10(%esp),%eax
f010508d:	d3 ea                	shr    %cl,%edx
f010508f:	89 e9                	mov    %ebp,%ecx
f0105091:	d3 e7                	shl    %cl,%edi
f0105093:	89 f1                	mov    %esi,%ecx
f0105095:	d3 e8                	shr    %cl,%eax
f0105097:	89 e9                	mov    %ebp,%ecx
f0105099:	09 f8                	or     %edi,%eax
f010509b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010509f:	f7 74 24 04          	divl   0x4(%esp)
f01050a3:	d3 e7                	shl    %cl,%edi
f01050a5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01050a9:	89 d7                	mov    %edx,%edi
f01050ab:	f7 64 24 08          	mull   0x8(%esp)
f01050af:	39 d7                	cmp    %edx,%edi
f01050b1:	89 c1                	mov    %eax,%ecx
f01050b3:	89 14 24             	mov    %edx,(%esp)
f01050b6:	72 2c                	jb     f01050e4 <__umoddi3+0x134>
f01050b8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01050bc:	72 22                	jb     f01050e0 <__umoddi3+0x130>
f01050be:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01050c2:	29 c8                	sub    %ecx,%eax
f01050c4:	19 d7                	sbb    %edx,%edi
f01050c6:	89 e9                	mov    %ebp,%ecx
f01050c8:	89 fa                	mov    %edi,%edx
f01050ca:	d3 e8                	shr    %cl,%eax
f01050cc:	89 f1                	mov    %esi,%ecx
f01050ce:	d3 e2                	shl    %cl,%edx
f01050d0:	89 e9                	mov    %ebp,%ecx
f01050d2:	d3 ef                	shr    %cl,%edi
f01050d4:	09 d0                	or     %edx,%eax
f01050d6:	89 fa                	mov    %edi,%edx
f01050d8:	83 c4 14             	add    $0x14,%esp
f01050db:	5e                   	pop    %esi
f01050dc:	5f                   	pop    %edi
f01050dd:	5d                   	pop    %ebp
f01050de:	c3                   	ret    
f01050df:	90                   	nop
f01050e0:	39 d7                	cmp    %edx,%edi
f01050e2:	75 da                	jne    f01050be <__umoddi3+0x10e>
f01050e4:	8b 14 24             	mov    (%esp),%edx
f01050e7:	89 c1                	mov    %eax,%ecx
f01050e9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01050ed:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01050f1:	eb cb                	jmp    f01050be <__umoddi3+0x10e>
f01050f3:	90                   	nop
f01050f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01050f8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01050fc:	0f 82 0f ff ff ff    	jb     f0105011 <__umoddi3+0x61>
f0105102:	e9 1a ff ff ff       	jmp    f0105021 <__umoddi3+0x71>
