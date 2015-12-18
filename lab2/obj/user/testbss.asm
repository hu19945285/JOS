
obj/user/testbss:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 02 01 00 00       	call   800133 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	83 ec 18             	sub    $0x18,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  800046:	c7 04 24 28 10 80 00 	movl   $0x801028,(%esp)
  80004d:	e8 5c 02 00 00       	call   8002ae <cprintf>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
  800052:	83 3d 20 20 80 00 00 	cmpl   $0x0,0x802020
  800059:	75 11                	jne    80006c <umain+0x2c>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  80005b:	b8 01 00 00 00       	mov    $0x1,%eax
		if (bigarray[i] != 0)
  800060:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800067:	00 
  800068:	74 27                	je     800091 <umain+0x51>
  80006a:	eb 05                	jmp    800071 <umain+0x31>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  80006c:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
  800071:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800075:	c7 44 24 08 a3 10 80 	movl   $0x8010a3,0x8(%esp)
  80007c:	00 
  80007d:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
  800084:	00 
  800085:	c7 04 24 c0 10 80 00 	movl   $0x8010c0,(%esp)
  80008c:	e8 0b 01 00 00       	call   80019c <_panic>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  800091:	83 c0 01             	add    $0x1,%eax
  800094:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800099:	75 c5                	jne    800060 <umain+0x20>
  80009b:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  8000a0:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
  8000a7:	83 c0 01             	add    $0x1,%eax
  8000aa:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000af:	75 ef                	jne    8000a0 <umain+0x60>
  8000b1:	eb 70                	jmp    800123 <umain+0xe3>
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  8000b3:	3b 04 85 20 20 80 00 	cmp    0x802020(,%eax,4),%eax
  8000ba:	74 2b                	je     8000e7 <umain+0xa7>
  8000bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8000c0:	eb 05                	jmp    8000c7 <umain+0x87>
  8000c2:	b8 00 00 00 00       	mov    $0x0,%eax
			panic("bigarray[%d] didn't hold its value!\n", i);
  8000c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000cb:	c7 44 24 08 48 10 80 	movl   $0x801048,0x8(%esp)
  8000d2:	00 
  8000d3:	c7 44 24 04 16 00 00 	movl   $0x16,0x4(%esp)
  8000da:	00 
  8000db:	c7 04 24 c0 10 80 00 	movl   $0x8010c0,(%esp)
  8000e2:	e8 b5 00 00 00       	call   80019c <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  8000e7:	83 c0 01             	add    $0x1,%eax
  8000ea:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000ef:	75 c2                	jne    8000b3 <umain+0x73>
		if (bigarray[i] != i)
			panic("bigarray[%d] didn't hold its value!\n", i);

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000f1:	c7 04 24 70 10 80 00 	movl   $0x801070,(%esp)
  8000f8:	e8 b1 01 00 00       	call   8002ae <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000fd:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  800104:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  800107:	c7 44 24 08 cf 10 80 	movl   $0x8010cf,0x8(%esp)
  80010e:	00 
  80010f:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  800116:	00 
  800117:	c7 04 24 c0 10 80 00 	movl   $0x8010c0,(%esp)
  80011e:	e8 79 00 00 00       	call   80019c <_panic>
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  800123:	83 3d 20 20 80 00 00 	cmpl   $0x0,0x802020
  80012a:	75 96                	jne    8000c2 <umain+0x82>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  80012c:	b8 01 00 00 00       	mov    $0x1,%eax
  800131:	eb 80                	jmp    8000b3 <umain+0x73>

00800133 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800133:	55                   	push   %ebp
  800134:	89 e5                	mov    %esp,%ebp
  800136:	56                   	push   %esi
  800137:	53                   	push   %ebx
  800138:	83 ec 10             	sub    $0x10,%esp
  80013b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80013e:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800141:	c7 05 20 20 c0 00 00 	movl   $0x0,0xc02020
  800148:	00 00 00 
	//thisenv=envs+ENVX(sys_getenvid());
	int index=sys_getenvid();
  80014b:	e8 2b 0c 00 00       	call   800d7b <sys_getenvid>
        thisenv=&envs[ENVX(index)];
  800150:	25 ff 03 00 00       	and    $0x3ff,%eax
  800155:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800158:	c1 e0 05             	shl    $0x5,%eax
  80015b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800160:	a3 20 20 c0 00       	mov    %eax,0xc02020
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800165:	85 db                	test   %ebx,%ebx
  800167:	7e 07                	jle    800170 <libmain+0x3d>
		binaryname = argv[0];
  800169:	8b 06                	mov    (%esi),%eax
  80016b:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800170:	89 74 24 04          	mov    %esi,0x4(%esp)
  800174:	89 1c 24             	mov    %ebx,(%esp)
  800177:	e8 c4 fe ff ff       	call   800040 <umain>

	// exit gracefully
	exit();
  80017c:	e8 07 00 00 00       	call   800188 <exit>
}
  800181:	83 c4 10             	add    $0x10,%esp
  800184:	5b                   	pop    %ebx
  800185:	5e                   	pop    %esi
  800186:	5d                   	pop    %ebp
  800187:	c3                   	ret    

00800188 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800188:	55                   	push   %ebp
  800189:	89 e5                	mov    %esp,%ebp
  80018b:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80018e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800195:	e8 8f 0b 00 00       	call   800d29 <sys_env_destroy>
}
  80019a:	c9                   	leave  
  80019b:	c3                   	ret    

0080019c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80019c:	55                   	push   %ebp
  80019d:	89 e5                	mov    %esp,%ebp
  80019f:	56                   	push   %esi
  8001a0:	53                   	push   %ebx
  8001a1:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001a4:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  8001a7:	a1 24 20 c0 00       	mov    0xc02024,%eax
  8001ac:	85 c0                	test   %eax,%eax
  8001ae:	74 10                	je     8001c0 <_panic+0x24>
		cprintf("%s: ", argv0);
  8001b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001b4:	c7 04 24 f0 10 80 00 	movl   $0x8010f0,(%esp)
  8001bb:	e8 ee 00 00 00       	call   8002ae <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001c0:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8001c6:	e8 b0 0b 00 00       	call   800d7b <sys_getenvid>
  8001cb:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001ce:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001d2:	8b 55 08             	mov    0x8(%ebp),%edx
  8001d5:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001d9:	89 74 24 08          	mov    %esi,0x8(%esp)
  8001dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001e1:	c7 04 24 f8 10 80 00 	movl   $0x8010f8,(%esp)
  8001e8:	e8 c1 00 00 00       	call   8002ae <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001f1:	8b 45 10             	mov    0x10(%ebp),%eax
  8001f4:	89 04 24             	mov    %eax,(%esp)
  8001f7:	e8 51 00 00 00       	call   80024d <vcprintf>
	cprintf("\n");
  8001fc:	c7 04 24 be 10 80 00 	movl   $0x8010be,(%esp)
  800203:	e8 a6 00 00 00       	call   8002ae <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800208:	cc                   	int3   
  800209:	eb fd                	jmp    800208 <_panic+0x6c>

0080020b <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80020b:	55                   	push   %ebp
  80020c:	89 e5                	mov    %esp,%ebp
  80020e:	53                   	push   %ebx
  80020f:	83 ec 14             	sub    $0x14,%esp
  800212:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800215:	8b 13                	mov    (%ebx),%edx
  800217:	8d 42 01             	lea    0x1(%edx),%eax
  80021a:	89 03                	mov    %eax,(%ebx)
  80021c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80021f:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800223:	3d ff 00 00 00       	cmp    $0xff,%eax
  800228:	75 19                	jne    800243 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80022a:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800231:	00 
  800232:	8d 43 08             	lea    0x8(%ebx),%eax
  800235:	89 04 24             	mov    %eax,(%esp)
  800238:	e8 af 0a 00 00       	call   800cec <sys_cputs>
		b->idx = 0;
  80023d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800243:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800247:	83 c4 14             	add    $0x14,%esp
  80024a:	5b                   	pop    %ebx
  80024b:	5d                   	pop    %ebp
  80024c:	c3                   	ret    

0080024d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80024d:	55                   	push   %ebp
  80024e:	89 e5                	mov    %esp,%ebp
  800250:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800256:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80025d:	00 00 00 
	b.cnt = 0;
  800260:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800267:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80026a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80026d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800271:	8b 45 08             	mov    0x8(%ebp),%eax
  800274:	89 44 24 08          	mov    %eax,0x8(%esp)
  800278:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80027e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800282:	c7 04 24 0b 02 80 00 	movl   $0x80020b,(%esp)
  800289:	e8 b6 01 00 00       	call   800444 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80028e:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800294:	89 44 24 04          	mov    %eax,0x4(%esp)
  800298:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80029e:	89 04 24             	mov    %eax,(%esp)
  8002a1:	e8 46 0a 00 00       	call   800cec <sys_cputs>

	return b.cnt;
}
  8002a6:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002ac:	c9                   	leave  
  8002ad:	c3                   	ret    

008002ae <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002ae:	55                   	push   %ebp
  8002af:	89 e5                	mov    %esp,%ebp
  8002b1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002b4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8002be:	89 04 24             	mov    %eax,(%esp)
  8002c1:	e8 87 ff ff ff       	call   80024d <vcprintf>
	va_end(ap);

	return cnt;
}
  8002c6:	c9                   	leave  
  8002c7:	c3                   	ret    
  8002c8:	66 90                	xchg   %ax,%ax
  8002ca:	66 90                	xchg   %ax,%ax
  8002cc:	66 90                	xchg   %ax,%ax
  8002ce:	66 90                	xchg   %ax,%ax

008002d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002d0:	55                   	push   %ebp
  8002d1:	89 e5                	mov    %esp,%ebp
  8002d3:	57                   	push   %edi
  8002d4:	56                   	push   %esi
  8002d5:	53                   	push   %ebx
  8002d6:	83 ec 3c             	sub    $0x3c,%esp
  8002d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002dc:	89 d7                	mov    %edx,%edi
  8002de:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002e4:	8b 75 0c             	mov    0xc(%ebp),%esi
  8002e7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
  8002ea:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002ed:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002f5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8002f8:	39 f1                	cmp    %esi,%ecx
  8002fa:	72 14                	jb     800310 <printnum+0x40>
  8002fc:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8002ff:	76 0f                	jbe    800310 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800301:	8b 45 14             	mov    0x14(%ebp),%eax
  800304:	8d 70 ff             	lea    -0x1(%eax),%esi
  800307:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  80030a:	85 f6                	test   %esi,%esi
  80030c:	7f 60                	jg     80036e <printnum+0x9e>
  80030e:	eb 72                	jmp    800382 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800310:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800313:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800317:	8b 4d 14             	mov    0x14(%ebp),%ecx
  80031a:	8d 51 ff             	lea    -0x1(%ecx),%edx
  80031d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800321:	89 44 24 08          	mov    %eax,0x8(%esp)
  800325:	8b 44 24 08          	mov    0x8(%esp),%eax
  800329:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80032d:	89 c3                	mov    %eax,%ebx
  80032f:	89 d6                	mov    %edx,%esi
  800331:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800334:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800337:	89 54 24 08          	mov    %edx,0x8(%esp)
  80033b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80033f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800342:	89 04 24             	mov    %eax,(%esp)
  800345:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800348:	89 44 24 04          	mov    %eax,0x4(%esp)
  80034c:	e8 4f 0a 00 00       	call   800da0 <__udivdi3>
  800351:	89 d9                	mov    %ebx,%ecx
  800353:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800357:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80035b:	89 04 24             	mov    %eax,(%esp)
  80035e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800362:	89 fa                	mov    %edi,%edx
  800364:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800367:	e8 64 ff ff ff       	call   8002d0 <printnum>
  80036c:	eb 14                	jmp    800382 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80036e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800372:	8b 45 18             	mov    0x18(%ebp),%eax
  800375:	89 04 24             	mov    %eax,(%esp)
  800378:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80037a:	83 ee 01             	sub    $0x1,%esi
  80037d:	75 ef                	jne    80036e <printnum+0x9e>
  80037f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800382:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800386:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80038a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80038d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800390:	89 44 24 08          	mov    %eax,0x8(%esp)
  800394:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800398:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80039b:	89 04 24             	mov    %eax,(%esp)
  80039e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003a5:	e8 26 0b 00 00       	call   800ed0 <__umoddi3>
  8003aa:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003ae:	0f be 80 1c 11 80 00 	movsbl 0x80111c(%eax),%eax
  8003b5:	89 04 24             	mov    %eax,(%esp)
  8003b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8003bb:	ff d0                	call   *%eax
}
  8003bd:	83 c4 3c             	add    $0x3c,%esp
  8003c0:	5b                   	pop    %ebx
  8003c1:	5e                   	pop    %esi
  8003c2:	5f                   	pop    %edi
  8003c3:	5d                   	pop    %ebp
  8003c4:	c3                   	ret    

008003c5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003c5:	55                   	push   %ebp
  8003c6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003c8:	83 fa 01             	cmp    $0x1,%edx
  8003cb:	7e 0e                	jle    8003db <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003cd:	8b 10                	mov    (%eax),%edx
  8003cf:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003d2:	89 08                	mov    %ecx,(%eax)
  8003d4:	8b 02                	mov    (%edx),%eax
  8003d6:	8b 52 04             	mov    0x4(%edx),%edx
  8003d9:	eb 22                	jmp    8003fd <getuint+0x38>
	else if (lflag)
  8003db:	85 d2                	test   %edx,%edx
  8003dd:	74 10                	je     8003ef <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003df:	8b 10                	mov    (%eax),%edx
  8003e1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003e4:	89 08                	mov    %ecx,(%eax)
  8003e6:	8b 02                	mov    (%edx),%eax
  8003e8:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ed:	eb 0e                	jmp    8003fd <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003ef:	8b 10                	mov    (%eax),%edx
  8003f1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003f4:	89 08                	mov    %ecx,(%eax)
  8003f6:	8b 02                	mov    (%edx),%eax
  8003f8:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003fd:	5d                   	pop    %ebp
  8003fe:	c3                   	ret    

008003ff <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003ff:	55                   	push   %ebp
  800400:	89 e5                	mov    %esp,%ebp
  800402:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800405:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800409:	8b 10                	mov    (%eax),%edx
  80040b:	3b 50 04             	cmp    0x4(%eax),%edx
  80040e:	73 0a                	jae    80041a <sprintputch+0x1b>
		*b->buf++ = ch;
  800410:	8d 4a 01             	lea    0x1(%edx),%ecx
  800413:	89 08                	mov    %ecx,(%eax)
  800415:	8b 45 08             	mov    0x8(%ebp),%eax
  800418:	88 02                	mov    %al,(%edx)
}
  80041a:	5d                   	pop    %ebp
  80041b:	c3                   	ret    

0080041c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80041c:	55                   	push   %ebp
  80041d:	89 e5                	mov    %esp,%ebp
  80041f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800422:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800425:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800429:	8b 45 10             	mov    0x10(%ebp),%eax
  80042c:	89 44 24 08          	mov    %eax,0x8(%esp)
  800430:	8b 45 0c             	mov    0xc(%ebp),%eax
  800433:	89 44 24 04          	mov    %eax,0x4(%esp)
  800437:	8b 45 08             	mov    0x8(%ebp),%eax
  80043a:	89 04 24             	mov    %eax,(%esp)
  80043d:	e8 02 00 00 00       	call   800444 <vprintfmt>
	va_end(ap);
}
  800442:	c9                   	leave  
  800443:	c3                   	ret    

00800444 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800444:	55                   	push   %ebp
  800445:	89 e5                	mov    %esp,%ebp
  800447:	57                   	push   %edi
  800448:	56                   	push   %esi
  800449:	53                   	push   %ebx
  80044a:	83 ec 3c             	sub    $0x3c,%esp
  80044d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800450:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800453:	eb 18                	jmp    80046d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800455:	85 c0                	test   %eax,%eax
  800457:	0f 84 c3 03 00 00    	je     800820 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
  80045d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800461:	89 04 24             	mov    %eax,(%esp)
  800464:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800467:	89 f3                	mov    %esi,%ebx
  800469:	eb 02                	jmp    80046d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
  80046b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80046d:	8d 73 01             	lea    0x1(%ebx),%esi
  800470:	0f b6 03             	movzbl (%ebx),%eax
  800473:	83 f8 25             	cmp    $0x25,%eax
  800476:	75 dd                	jne    800455 <vprintfmt+0x11>
  800478:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
  80047c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800483:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  80048a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800491:	ba 00 00 00 00       	mov    $0x0,%edx
  800496:	eb 1d                	jmp    8004b5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800498:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80049a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
  80049e:	eb 15                	jmp    8004b5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a0:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004a2:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
  8004a6:	eb 0d                	jmp    8004b5 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8004ae:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b5:	8d 5e 01             	lea    0x1(%esi),%ebx
  8004b8:	0f b6 06             	movzbl (%esi),%eax
  8004bb:	0f b6 c8             	movzbl %al,%ecx
  8004be:	83 e8 23             	sub    $0x23,%eax
  8004c1:	3c 55                	cmp    $0x55,%al
  8004c3:	0f 87 2f 03 00 00    	ja     8007f8 <vprintfmt+0x3b4>
  8004c9:	0f b6 c0             	movzbl %al,%eax
  8004cc:	ff 24 85 ac 11 80 00 	jmp    *0x8011ac(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8004d3:	8d 41 d0             	lea    -0x30(%ecx),%eax
  8004d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
  8004d9:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
  8004dd:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004e0:	83 f9 09             	cmp    $0x9,%ecx
  8004e3:	77 50                	ja     800535 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e5:	89 de                	mov    %ebx,%esi
  8004e7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004ea:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
  8004ed:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8004f0:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8004f4:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8004f7:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8004fa:	83 fb 09             	cmp    $0x9,%ebx
  8004fd:	76 eb                	jbe    8004ea <vprintfmt+0xa6>
  8004ff:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  800502:	eb 33                	jmp    800537 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800504:	8b 45 14             	mov    0x14(%ebp),%eax
  800507:	8d 48 04             	lea    0x4(%eax),%ecx
  80050a:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80050d:	8b 00                	mov    (%eax),%eax
  80050f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800512:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800514:	eb 21                	jmp    800537 <vprintfmt+0xf3>
  800516:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800519:	85 c9                	test   %ecx,%ecx
  80051b:	b8 00 00 00 00       	mov    $0x0,%eax
  800520:	0f 49 c1             	cmovns %ecx,%eax
  800523:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800526:	89 de                	mov    %ebx,%esi
  800528:	eb 8b                	jmp    8004b5 <vprintfmt+0x71>
  80052a:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80052c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800533:	eb 80                	jmp    8004b5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800535:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  800537:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80053b:	0f 89 74 ff ff ff    	jns    8004b5 <vprintfmt+0x71>
  800541:	e9 62 ff ff ff       	jmp    8004a8 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800546:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800549:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80054b:	e9 65 ff ff ff       	jmp    8004b5 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800550:	8b 45 14             	mov    0x14(%ebp),%eax
  800553:	8d 50 04             	lea    0x4(%eax),%edx
  800556:	89 55 14             	mov    %edx,0x14(%ebp)
  800559:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80055d:	8b 00                	mov    (%eax),%eax
  80055f:	89 04 24             	mov    %eax,(%esp)
  800562:	ff 55 08             	call   *0x8(%ebp)
			break;
  800565:	e9 03 ff ff ff       	jmp    80046d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80056a:	8b 45 14             	mov    0x14(%ebp),%eax
  80056d:	8d 50 04             	lea    0x4(%eax),%edx
  800570:	89 55 14             	mov    %edx,0x14(%ebp)
  800573:	8b 00                	mov    (%eax),%eax
  800575:	99                   	cltd   
  800576:	31 d0                	xor    %edx,%eax
  800578:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80057a:	83 f8 06             	cmp    $0x6,%eax
  80057d:	7f 0b                	jg     80058a <vprintfmt+0x146>
  80057f:	8b 14 85 04 13 80 00 	mov    0x801304(,%eax,4),%edx
  800586:	85 d2                	test   %edx,%edx
  800588:	75 20                	jne    8005aa <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
  80058a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80058e:	c7 44 24 08 34 11 80 	movl   $0x801134,0x8(%esp)
  800595:	00 
  800596:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80059a:	8b 45 08             	mov    0x8(%ebp),%eax
  80059d:	89 04 24             	mov    %eax,(%esp)
  8005a0:	e8 77 fe ff ff       	call   80041c <printfmt>
  8005a5:	e9 c3 fe ff ff       	jmp    80046d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
  8005aa:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005ae:	c7 44 24 08 3d 11 80 	movl   $0x80113d,0x8(%esp)
  8005b5:	00 
  8005b6:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8005bd:	89 04 24             	mov    %eax,(%esp)
  8005c0:	e8 57 fe ff ff       	call   80041c <printfmt>
  8005c5:	e9 a3 fe ff ff       	jmp    80046d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ca:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8005cd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005d0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d3:	8d 50 04             	lea    0x4(%eax),%edx
  8005d6:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d9:	8b 00                	mov    (%eax),%eax
				p = "(null)";
  8005db:	85 c0                	test   %eax,%eax
  8005dd:	ba 2d 11 80 00       	mov    $0x80112d,%edx
  8005e2:	0f 45 d0             	cmovne %eax,%edx
  8005e5:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
  8005e8:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
  8005ec:	74 04                	je     8005f2 <vprintfmt+0x1ae>
  8005ee:	85 f6                	test   %esi,%esi
  8005f0:	7f 19                	jg     80060b <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005f2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005f5:	8d 70 01             	lea    0x1(%eax),%esi
  8005f8:	0f b6 10             	movzbl (%eax),%edx
  8005fb:	0f be c2             	movsbl %dl,%eax
  8005fe:	85 c0                	test   %eax,%eax
  800600:	0f 85 95 00 00 00    	jne    80069b <vprintfmt+0x257>
  800606:	e9 85 00 00 00       	jmp    800690 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80060b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80060f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800612:	89 04 24             	mov    %eax,(%esp)
  800615:	e8 b8 02 00 00       	call   8008d2 <strnlen>
  80061a:	29 c6                	sub    %eax,%esi
  80061c:	89 f0                	mov    %esi,%eax
  80061e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  800621:	85 f6                	test   %esi,%esi
  800623:	7e cd                	jle    8005f2 <vprintfmt+0x1ae>
					putch(padc, putdat);
  800625:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  800629:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80062c:	89 c3                	mov    %eax,%ebx
  80062e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800632:	89 34 24             	mov    %esi,(%esp)
  800635:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800638:	83 eb 01             	sub    $0x1,%ebx
  80063b:	75 f1                	jne    80062e <vprintfmt+0x1ea>
  80063d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800640:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800643:	eb ad                	jmp    8005f2 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800645:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800649:	74 1e                	je     800669 <vprintfmt+0x225>
  80064b:	0f be d2             	movsbl %dl,%edx
  80064e:	83 ea 20             	sub    $0x20,%edx
  800651:	83 fa 5e             	cmp    $0x5e,%edx
  800654:	76 13                	jbe    800669 <vprintfmt+0x225>
					putch('?', putdat);
  800656:	8b 45 0c             	mov    0xc(%ebp),%eax
  800659:	89 44 24 04          	mov    %eax,0x4(%esp)
  80065d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800664:	ff 55 08             	call   *0x8(%ebp)
  800667:	eb 0d                	jmp    800676 <vprintfmt+0x232>
				else
					putch(ch, putdat);
  800669:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80066c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800670:	89 04 24             	mov    %eax,(%esp)
  800673:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800676:	83 ef 01             	sub    $0x1,%edi
  800679:	83 c6 01             	add    $0x1,%esi
  80067c:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800680:	0f be c2             	movsbl %dl,%eax
  800683:	85 c0                	test   %eax,%eax
  800685:	75 20                	jne    8006a7 <vprintfmt+0x263>
  800687:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  80068a:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80068d:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800690:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800694:	7f 25                	jg     8006bb <vprintfmt+0x277>
  800696:	e9 d2 fd ff ff       	jmp    80046d <vprintfmt+0x29>
  80069b:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80069e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006a1:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8006a4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8006a7:	85 db                	test   %ebx,%ebx
  8006a9:	78 9a                	js     800645 <vprintfmt+0x201>
  8006ab:	83 eb 01             	sub    $0x1,%ebx
  8006ae:	79 95                	jns    800645 <vprintfmt+0x201>
  8006b0:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  8006b3:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8006b6:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8006b9:	eb d5                	jmp    800690 <vprintfmt+0x24c>
  8006bb:	8b 75 08             	mov    0x8(%ebp),%esi
  8006be:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8006c1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8006c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006c8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006cf:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006d1:	83 eb 01             	sub    $0x1,%ebx
  8006d4:	75 ee                	jne    8006c4 <vprintfmt+0x280>
  8006d6:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8006d9:	e9 8f fd ff ff       	jmp    80046d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006de:	83 fa 01             	cmp    $0x1,%edx
  8006e1:	7e 16                	jle    8006f9 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
  8006e3:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e6:	8d 50 08             	lea    0x8(%eax),%edx
  8006e9:	89 55 14             	mov    %edx,0x14(%ebp)
  8006ec:	8b 50 04             	mov    0x4(%eax),%edx
  8006ef:	8b 00                	mov    (%eax),%eax
  8006f1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006f4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8006f7:	eb 32                	jmp    80072b <vprintfmt+0x2e7>
	else if (lflag)
  8006f9:	85 d2                	test   %edx,%edx
  8006fb:	74 18                	je     800715 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
  8006fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800700:	8d 50 04             	lea    0x4(%eax),%edx
  800703:	89 55 14             	mov    %edx,0x14(%ebp)
  800706:	8b 30                	mov    (%eax),%esi
  800708:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80070b:	89 f0                	mov    %esi,%eax
  80070d:	c1 f8 1f             	sar    $0x1f,%eax
  800710:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800713:	eb 16                	jmp    80072b <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
  800715:	8b 45 14             	mov    0x14(%ebp),%eax
  800718:	8d 50 04             	lea    0x4(%eax),%edx
  80071b:	89 55 14             	mov    %edx,0x14(%ebp)
  80071e:	8b 30                	mov    (%eax),%esi
  800720:	89 75 d8             	mov    %esi,-0x28(%ebp)
  800723:	89 f0                	mov    %esi,%eax
  800725:	c1 f8 1f             	sar    $0x1f,%eax
  800728:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80072b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80072e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800731:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800736:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80073a:	0f 89 80 00 00 00    	jns    8007c0 <vprintfmt+0x37c>
				putch('-', putdat);
  800740:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800744:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80074b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  80074e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800751:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800754:	f7 d8                	neg    %eax
  800756:	83 d2 00             	adc    $0x0,%edx
  800759:	f7 da                	neg    %edx
			}
			base = 10;
  80075b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800760:	eb 5e                	jmp    8007c0 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800762:	8d 45 14             	lea    0x14(%ebp),%eax
  800765:	e8 5b fc ff ff       	call   8003c5 <getuint>
			base = 10;
  80076a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80076f:	eb 4f                	jmp    8007c0 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
  800771:	8d 45 14             	lea    0x14(%ebp),%eax
  800774:	e8 4c fc ff ff       	call   8003c5 <getuint>
			base = 8;
  800779:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80077e:	eb 40                	jmp    8007c0 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
  800780:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800784:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80078b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  80078e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800792:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800799:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80079c:	8b 45 14             	mov    0x14(%ebp),%eax
  80079f:	8d 50 04             	lea    0x4(%eax),%edx
  8007a2:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007a5:	8b 00                	mov    (%eax),%eax
  8007a7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007ac:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007b1:	eb 0d                	jmp    8007c0 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007b3:	8d 45 14             	lea    0x14(%ebp),%eax
  8007b6:	e8 0a fc ff ff       	call   8003c5 <getuint>
			base = 16;
  8007bb:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007c0:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  8007c4:	89 74 24 10          	mov    %esi,0x10(%esp)
  8007c8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  8007cb:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8007cf:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007d3:	89 04 24             	mov    %eax,(%esp)
  8007d6:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007da:	89 fa                	mov    %edi,%edx
  8007dc:	8b 45 08             	mov    0x8(%ebp),%eax
  8007df:	e8 ec fa ff ff       	call   8002d0 <printnum>
			break;
  8007e4:	e9 84 fc ff ff       	jmp    80046d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007e9:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007ed:	89 0c 24             	mov    %ecx,(%esp)
  8007f0:	ff 55 08             	call   *0x8(%ebp)
			break;
  8007f3:	e9 75 fc ff ff       	jmp    80046d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007fc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800803:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800806:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  80080a:	0f 84 5b fc ff ff    	je     80046b <vprintfmt+0x27>
  800810:	89 f3                	mov    %esi,%ebx
  800812:	83 eb 01             	sub    $0x1,%ebx
  800815:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800819:	75 f7                	jne    800812 <vprintfmt+0x3ce>
  80081b:	e9 4d fc ff ff       	jmp    80046d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
  800820:	83 c4 3c             	add    $0x3c,%esp
  800823:	5b                   	pop    %ebx
  800824:	5e                   	pop    %esi
  800825:	5f                   	pop    %edi
  800826:	5d                   	pop    %ebp
  800827:	c3                   	ret    

00800828 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800828:	55                   	push   %ebp
  800829:	89 e5                	mov    %esp,%ebp
  80082b:	83 ec 28             	sub    $0x28,%esp
  80082e:	8b 45 08             	mov    0x8(%ebp),%eax
  800831:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800834:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800837:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80083b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80083e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800845:	85 c0                	test   %eax,%eax
  800847:	74 30                	je     800879 <vsnprintf+0x51>
  800849:	85 d2                	test   %edx,%edx
  80084b:	7e 2c                	jle    800879 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80084d:	8b 45 14             	mov    0x14(%ebp),%eax
  800850:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800854:	8b 45 10             	mov    0x10(%ebp),%eax
  800857:	89 44 24 08          	mov    %eax,0x8(%esp)
  80085b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80085e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800862:	c7 04 24 ff 03 80 00 	movl   $0x8003ff,(%esp)
  800869:	e8 d6 fb ff ff       	call   800444 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80086e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800871:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800874:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800877:	eb 05                	jmp    80087e <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800879:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80087e:	c9                   	leave  
  80087f:	c3                   	ret    

00800880 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800880:	55                   	push   %ebp
  800881:	89 e5                	mov    %esp,%ebp
  800883:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800886:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800889:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80088d:	8b 45 10             	mov    0x10(%ebp),%eax
  800890:	89 44 24 08          	mov    %eax,0x8(%esp)
  800894:	8b 45 0c             	mov    0xc(%ebp),%eax
  800897:	89 44 24 04          	mov    %eax,0x4(%esp)
  80089b:	8b 45 08             	mov    0x8(%ebp),%eax
  80089e:	89 04 24             	mov    %eax,(%esp)
  8008a1:	e8 82 ff ff ff       	call   800828 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008a6:	c9                   	leave  
  8008a7:	c3                   	ret    
  8008a8:	66 90                	xchg   %ax,%ax
  8008aa:	66 90                	xchg   %ax,%ax
  8008ac:	66 90                	xchg   %ax,%ax
  8008ae:	66 90                	xchg   %ax,%ax

008008b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008b0:	55                   	push   %ebp
  8008b1:	89 e5                	mov    %esp,%ebp
  8008b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008b6:	80 3a 00             	cmpb   $0x0,(%edx)
  8008b9:	74 10                	je     8008cb <strlen+0x1b>
  8008bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  8008c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008c7:	75 f7                	jne    8008c0 <strlen+0x10>
  8008c9:	eb 05                	jmp    8008d0 <strlen+0x20>
  8008cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	53                   	push   %ebx
  8008d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008dc:	85 c9                	test   %ecx,%ecx
  8008de:	74 1c                	je     8008fc <strnlen+0x2a>
  8008e0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8008e3:	74 1e                	je     800903 <strnlen+0x31>
  8008e5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8008ea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008ec:	39 ca                	cmp    %ecx,%edx
  8008ee:	74 18                	je     800908 <strnlen+0x36>
  8008f0:	83 c2 01             	add    $0x1,%edx
  8008f3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8008f8:	75 f0                	jne    8008ea <strnlen+0x18>
  8008fa:	eb 0c                	jmp    800908 <strnlen+0x36>
  8008fc:	b8 00 00 00 00       	mov    $0x0,%eax
  800901:	eb 05                	jmp    800908 <strnlen+0x36>
  800903:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800908:	5b                   	pop    %ebx
  800909:	5d                   	pop    %ebp
  80090a:	c3                   	ret    

0080090b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80090b:	55                   	push   %ebp
  80090c:	89 e5                	mov    %esp,%ebp
  80090e:	53                   	push   %ebx
  80090f:	8b 45 08             	mov    0x8(%ebp),%eax
  800912:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800915:	89 c2                	mov    %eax,%edx
  800917:	83 c2 01             	add    $0x1,%edx
  80091a:	83 c1 01             	add    $0x1,%ecx
  80091d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800921:	88 5a ff             	mov    %bl,-0x1(%edx)
  800924:	84 db                	test   %bl,%bl
  800926:	75 ef                	jne    800917 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800928:	5b                   	pop    %ebx
  800929:	5d                   	pop    %ebp
  80092a:	c3                   	ret    

0080092b <strcat>:

char *
strcat(char *dst, const char *src)
{
  80092b:	55                   	push   %ebp
  80092c:	89 e5                	mov    %esp,%ebp
  80092e:	53                   	push   %ebx
  80092f:	83 ec 08             	sub    $0x8,%esp
  800932:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800935:	89 1c 24             	mov    %ebx,(%esp)
  800938:	e8 73 ff ff ff       	call   8008b0 <strlen>
	strcpy(dst + len, src);
  80093d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800940:	89 54 24 04          	mov    %edx,0x4(%esp)
  800944:	01 d8                	add    %ebx,%eax
  800946:	89 04 24             	mov    %eax,(%esp)
  800949:	e8 bd ff ff ff       	call   80090b <strcpy>
	return dst;
}
  80094e:	89 d8                	mov    %ebx,%eax
  800950:	83 c4 08             	add    $0x8,%esp
  800953:	5b                   	pop    %ebx
  800954:	5d                   	pop    %ebp
  800955:	c3                   	ret    

00800956 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800956:	55                   	push   %ebp
  800957:	89 e5                	mov    %esp,%ebp
  800959:	56                   	push   %esi
  80095a:	53                   	push   %ebx
  80095b:	8b 75 08             	mov    0x8(%ebp),%esi
  80095e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800961:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800964:	85 db                	test   %ebx,%ebx
  800966:	74 17                	je     80097f <strncpy+0x29>
  800968:	01 f3                	add    %esi,%ebx
  80096a:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
  80096c:	83 c1 01             	add    $0x1,%ecx
  80096f:	0f b6 02             	movzbl (%edx),%eax
  800972:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800975:	80 3a 01             	cmpb   $0x1,(%edx)
  800978:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80097b:	39 d9                	cmp    %ebx,%ecx
  80097d:	75 ed                	jne    80096c <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80097f:	89 f0                	mov    %esi,%eax
  800981:	5b                   	pop    %ebx
  800982:	5e                   	pop    %esi
  800983:	5d                   	pop    %ebp
  800984:	c3                   	ret    

00800985 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800985:	55                   	push   %ebp
  800986:	89 e5                	mov    %esp,%ebp
  800988:	57                   	push   %edi
  800989:	56                   	push   %esi
  80098a:	53                   	push   %ebx
  80098b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80098e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800991:	8b 75 10             	mov    0x10(%ebp),%esi
  800994:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800996:	85 f6                	test   %esi,%esi
  800998:	74 34                	je     8009ce <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
  80099a:	83 fe 01             	cmp    $0x1,%esi
  80099d:	74 26                	je     8009c5 <strlcpy+0x40>
  80099f:	0f b6 0b             	movzbl (%ebx),%ecx
  8009a2:	84 c9                	test   %cl,%cl
  8009a4:	74 23                	je     8009c9 <strlcpy+0x44>
  8009a6:	83 ee 02             	sub    $0x2,%esi
  8009a9:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
  8009ae:	83 c0 01             	add    $0x1,%eax
  8009b1:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8009b4:	39 f2                	cmp    %esi,%edx
  8009b6:	74 13                	je     8009cb <strlcpy+0x46>
  8009b8:	83 c2 01             	add    $0x1,%edx
  8009bb:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  8009bf:	84 c9                	test   %cl,%cl
  8009c1:	75 eb                	jne    8009ae <strlcpy+0x29>
  8009c3:	eb 06                	jmp    8009cb <strlcpy+0x46>
  8009c5:	89 f8                	mov    %edi,%eax
  8009c7:	eb 02                	jmp    8009cb <strlcpy+0x46>
  8009c9:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  8009cb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8009ce:	29 f8                	sub    %edi,%eax
}
  8009d0:	5b                   	pop    %ebx
  8009d1:	5e                   	pop    %esi
  8009d2:	5f                   	pop    %edi
  8009d3:	5d                   	pop    %ebp
  8009d4:	c3                   	ret    

008009d5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8009d5:	55                   	push   %ebp
  8009d6:	89 e5                	mov    %esp,%ebp
  8009d8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009db:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8009de:	0f b6 01             	movzbl (%ecx),%eax
  8009e1:	84 c0                	test   %al,%al
  8009e3:	74 15                	je     8009fa <strcmp+0x25>
  8009e5:	3a 02                	cmp    (%edx),%al
  8009e7:	75 11                	jne    8009fa <strcmp+0x25>
		p++, q++;
  8009e9:	83 c1 01             	add    $0x1,%ecx
  8009ec:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009ef:	0f b6 01             	movzbl (%ecx),%eax
  8009f2:	84 c0                	test   %al,%al
  8009f4:	74 04                	je     8009fa <strcmp+0x25>
  8009f6:	3a 02                	cmp    (%edx),%al
  8009f8:	74 ef                	je     8009e9 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009fa:	0f b6 c0             	movzbl %al,%eax
  8009fd:	0f b6 12             	movzbl (%edx),%edx
  800a00:	29 d0                	sub    %edx,%eax
}
  800a02:	5d                   	pop    %ebp
  800a03:	c3                   	ret    

00800a04 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800a04:	55                   	push   %ebp
  800a05:	89 e5                	mov    %esp,%ebp
  800a07:	56                   	push   %esi
  800a08:	53                   	push   %ebx
  800a09:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a0c:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a0f:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  800a12:	85 f6                	test   %esi,%esi
  800a14:	74 29                	je     800a3f <strncmp+0x3b>
  800a16:	0f b6 03             	movzbl (%ebx),%eax
  800a19:	84 c0                	test   %al,%al
  800a1b:	74 30                	je     800a4d <strncmp+0x49>
  800a1d:	3a 02                	cmp    (%edx),%al
  800a1f:	75 2c                	jne    800a4d <strncmp+0x49>
  800a21:	8d 43 01             	lea    0x1(%ebx),%eax
  800a24:	01 de                	add    %ebx,%esi
		n--, p++, q++;
  800a26:	89 c3                	mov    %eax,%ebx
  800a28:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800a2b:	39 f0                	cmp    %esi,%eax
  800a2d:	74 17                	je     800a46 <strncmp+0x42>
  800a2f:	0f b6 08             	movzbl (%eax),%ecx
  800a32:	84 c9                	test   %cl,%cl
  800a34:	74 17                	je     800a4d <strncmp+0x49>
  800a36:	83 c0 01             	add    $0x1,%eax
  800a39:	3a 0a                	cmp    (%edx),%cl
  800a3b:	74 e9                	je     800a26 <strncmp+0x22>
  800a3d:	eb 0e                	jmp    800a4d <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a3f:	b8 00 00 00 00       	mov    $0x0,%eax
  800a44:	eb 0f                	jmp    800a55 <strncmp+0x51>
  800a46:	b8 00 00 00 00       	mov    $0x0,%eax
  800a4b:	eb 08                	jmp    800a55 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a4d:	0f b6 03             	movzbl (%ebx),%eax
  800a50:	0f b6 12             	movzbl (%edx),%edx
  800a53:	29 d0                	sub    %edx,%eax
}
  800a55:	5b                   	pop    %ebx
  800a56:	5e                   	pop    %esi
  800a57:	5d                   	pop    %ebp
  800a58:	c3                   	ret    

00800a59 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a59:	55                   	push   %ebp
  800a5a:	89 e5                	mov    %esp,%ebp
  800a5c:	53                   	push   %ebx
  800a5d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a60:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a63:	0f b6 18             	movzbl (%eax),%ebx
  800a66:	84 db                	test   %bl,%bl
  800a68:	74 1d                	je     800a87 <strchr+0x2e>
  800a6a:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a6c:	38 d3                	cmp    %dl,%bl
  800a6e:	75 06                	jne    800a76 <strchr+0x1d>
  800a70:	eb 1a                	jmp    800a8c <strchr+0x33>
  800a72:	38 ca                	cmp    %cl,%dl
  800a74:	74 16                	je     800a8c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a76:	83 c0 01             	add    $0x1,%eax
  800a79:	0f b6 10             	movzbl (%eax),%edx
  800a7c:	84 d2                	test   %dl,%dl
  800a7e:	75 f2                	jne    800a72 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800a80:	b8 00 00 00 00       	mov    $0x0,%eax
  800a85:	eb 05                	jmp    800a8c <strchr+0x33>
  800a87:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a8c:	5b                   	pop    %ebx
  800a8d:	5d                   	pop    %ebp
  800a8e:	c3                   	ret    

00800a8f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a8f:	55                   	push   %ebp
  800a90:	89 e5                	mov    %esp,%ebp
  800a92:	53                   	push   %ebx
  800a93:	8b 45 08             	mov    0x8(%ebp),%eax
  800a96:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a99:	0f b6 18             	movzbl (%eax),%ebx
  800a9c:	84 db                	test   %bl,%bl
  800a9e:	74 16                	je     800ab6 <strfind+0x27>
  800aa0:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800aa2:	38 d3                	cmp    %dl,%bl
  800aa4:	75 06                	jne    800aac <strfind+0x1d>
  800aa6:	eb 0e                	jmp    800ab6 <strfind+0x27>
  800aa8:	38 ca                	cmp    %cl,%dl
  800aaa:	74 0a                	je     800ab6 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800aac:	83 c0 01             	add    $0x1,%eax
  800aaf:	0f b6 10             	movzbl (%eax),%edx
  800ab2:	84 d2                	test   %dl,%dl
  800ab4:	75 f2                	jne    800aa8 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800ab6:	5b                   	pop    %ebx
  800ab7:	5d                   	pop    %ebp
  800ab8:	c3                   	ret    

00800ab9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800ab9:	55                   	push   %ebp
  800aba:	89 e5                	mov    %esp,%ebp
  800abc:	57                   	push   %edi
  800abd:	56                   	push   %esi
  800abe:	53                   	push   %ebx
  800abf:	8b 7d 08             	mov    0x8(%ebp),%edi
  800ac2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800ac5:	85 c9                	test   %ecx,%ecx
  800ac7:	74 36                	je     800aff <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800ac9:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800acf:	75 28                	jne    800af9 <memset+0x40>
  800ad1:	f6 c1 03             	test   $0x3,%cl
  800ad4:	75 23                	jne    800af9 <memset+0x40>
		c &= 0xFF;
  800ad6:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800ada:	89 d3                	mov    %edx,%ebx
  800adc:	c1 e3 08             	shl    $0x8,%ebx
  800adf:	89 d6                	mov    %edx,%esi
  800ae1:	c1 e6 18             	shl    $0x18,%esi
  800ae4:	89 d0                	mov    %edx,%eax
  800ae6:	c1 e0 10             	shl    $0x10,%eax
  800ae9:	09 f0                	or     %esi,%eax
  800aeb:	09 c2                	or     %eax,%edx
  800aed:	89 d0                	mov    %edx,%eax
  800aef:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800af1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800af4:	fc                   	cld    
  800af5:	f3 ab                	rep stos %eax,%es:(%edi)
  800af7:	eb 06                	jmp    800aff <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800af9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800afc:	fc                   	cld    
  800afd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800aff:	89 f8                	mov    %edi,%eax
  800b01:	5b                   	pop    %ebx
  800b02:	5e                   	pop    %esi
  800b03:	5f                   	pop    %edi
  800b04:	5d                   	pop    %ebp
  800b05:	c3                   	ret    

00800b06 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b06:	55                   	push   %ebp
  800b07:	89 e5                	mov    %esp,%ebp
  800b09:	57                   	push   %edi
  800b0a:	56                   	push   %esi
  800b0b:	8b 45 08             	mov    0x8(%ebp),%eax
  800b0e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b11:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b14:	39 c6                	cmp    %eax,%esi
  800b16:	73 35                	jae    800b4d <memmove+0x47>
  800b18:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b1b:	39 d0                	cmp    %edx,%eax
  800b1d:	73 2e                	jae    800b4d <memmove+0x47>
		s += n;
		d += n;
  800b1f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800b22:	89 d6                	mov    %edx,%esi
  800b24:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b26:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800b2c:	75 13                	jne    800b41 <memmove+0x3b>
  800b2e:	f6 c1 03             	test   $0x3,%cl
  800b31:	75 0e                	jne    800b41 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800b33:	83 ef 04             	sub    $0x4,%edi
  800b36:	8d 72 fc             	lea    -0x4(%edx),%esi
  800b39:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800b3c:	fd                   	std    
  800b3d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b3f:	eb 09                	jmp    800b4a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800b41:	83 ef 01             	sub    $0x1,%edi
  800b44:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800b47:	fd                   	std    
  800b48:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800b4a:	fc                   	cld    
  800b4b:	eb 1d                	jmp    800b6a <memmove+0x64>
  800b4d:	89 f2                	mov    %esi,%edx
  800b4f:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b51:	f6 c2 03             	test   $0x3,%dl
  800b54:	75 0f                	jne    800b65 <memmove+0x5f>
  800b56:	f6 c1 03             	test   $0x3,%cl
  800b59:	75 0a                	jne    800b65 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800b5b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800b5e:	89 c7                	mov    %eax,%edi
  800b60:	fc                   	cld    
  800b61:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b63:	eb 05                	jmp    800b6a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b65:	89 c7                	mov    %eax,%edi
  800b67:	fc                   	cld    
  800b68:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b6a:	5e                   	pop    %esi
  800b6b:	5f                   	pop    %edi
  800b6c:	5d                   	pop    %ebp
  800b6d:	c3                   	ret    

00800b6e <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800b6e:	55                   	push   %ebp
  800b6f:	89 e5                	mov    %esp,%ebp
  800b71:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b74:	8b 45 10             	mov    0x10(%ebp),%eax
  800b77:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b7b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b7e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b82:	8b 45 08             	mov    0x8(%ebp),%eax
  800b85:	89 04 24             	mov    %eax,(%esp)
  800b88:	e8 79 ff ff ff       	call   800b06 <memmove>
}
  800b8d:	c9                   	leave  
  800b8e:	c3                   	ret    

00800b8f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b8f:	55                   	push   %ebp
  800b90:	89 e5                	mov    %esp,%ebp
  800b92:	57                   	push   %edi
  800b93:	56                   	push   %esi
  800b94:	53                   	push   %ebx
  800b95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800b98:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b9b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b9e:	8d 78 ff             	lea    -0x1(%eax),%edi
  800ba1:	85 c0                	test   %eax,%eax
  800ba3:	74 36                	je     800bdb <memcmp+0x4c>
		if (*s1 != *s2)
  800ba5:	0f b6 03             	movzbl (%ebx),%eax
  800ba8:	0f b6 0e             	movzbl (%esi),%ecx
  800bab:	ba 00 00 00 00       	mov    $0x0,%edx
  800bb0:	38 c8                	cmp    %cl,%al
  800bb2:	74 1c                	je     800bd0 <memcmp+0x41>
  800bb4:	eb 10                	jmp    800bc6 <memcmp+0x37>
  800bb6:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800bbb:	83 c2 01             	add    $0x1,%edx
  800bbe:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800bc2:	38 c8                	cmp    %cl,%al
  800bc4:	74 0a                	je     800bd0 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800bc6:	0f b6 c0             	movzbl %al,%eax
  800bc9:	0f b6 c9             	movzbl %cl,%ecx
  800bcc:	29 c8                	sub    %ecx,%eax
  800bce:	eb 10                	jmp    800be0 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bd0:	39 fa                	cmp    %edi,%edx
  800bd2:	75 e2                	jne    800bb6 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800bd4:	b8 00 00 00 00       	mov    $0x0,%eax
  800bd9:	eb 05                	jmp    800be0 <memcmp+0x51>
  800bdb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800be0:	5b                   	pop    %ebx
  800be1:	5e                   	pop    %esi
  800be2:	5f                   	pop    %edi
  800be3:	5d                   	pop    %ebp
  800be4:	c3                   	ret    

00800be5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800be5:	55                   	push   %ebp
  800be6:	89 e5                	mov    %esp,%ebp
  800be8:	53                   	push   %ebx
  800be9:	8b 45 08             	mov    0x8(%ebp),%eax
  800bec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800bef:	89 c2                	mov    %eax,%edx
  800bf1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800bf4:	39 d0                	cmp    %edx,%eax
  800bf6:	73 13                	jae    800c0b <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800bf8:	89 d9                	mov    %ebx,%ecx
  800bfa:	38 18                	cmp    %bl,(%eax)
  800bfc:	75 06                	jne    800c04 <memfind+0x1f>
  800bfe:	eb 0b                	jmp    800c0b <memfind+0x26>
  800c00:	38 08                	cmp    %cl,(%eax)
  800c02:	74 07                	je     800c0b <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c04:	83 c0 01             	add    $0x1,%eax
  800c07:	39 d0                	cmp    %edx,%eax
  800c09:	75 f5                	jne    800c00 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c0b:	5b                   	pop    %ebx
  800c0c:	5d                   	pop    %ebp
  800c0d:	c3                   	ret    

00800c0e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c0e:	55                   	push   %ebp
  800c0f:	89 e5                	mov    %esp,%ebp
  800c11:	57                   	push   %edi
  800c12:	56                   	push   %esi
  800c13:	53                   	push   %ebx
  800c14:	8b 55 08             	mov    0x8(%ebp),%edx
  800c17:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c1a:	0f b6 0a             	movzbl (%edx),%ecx
  800c1d:	80 f9 09             	cmp    $0x9,%cl
  800c20:	74 05                	je     800c27 <strtol+0x19>
  800c22:	80 f9 20             	cmp    $0x20,%cl
  800c25:	75 10                	jne    800c37 <strtol+0x29>
		s++;
  800c27:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c2a:	0f b6 0a             	movzbl (%edx),%ecx
  800c2d:	80 f9 09             	cmp    $0x9,%cl
  800c30:	74 f5                	je     800c27 <strtol+0x19>
  800c32:	80 f9 20             	cmp    $0x20,%cl
  800c35:	74 f0                	je     800c27 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c37:	80 f9 2b             	cmp    $0x2b,%cl
  800c3a:	75 0a                	jne    800c46 <strtol+0x38>
		s++;
  800c3c:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c3f:	bf 00 00 00 00       	mov    $0x0,%edi
  800c44:	eb 11                	jmp    800c57 <strtol+0x49>
  800c46:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c4b:	80 f9 2d             	cmp    $0x2d,%cl
  800c4e:	75 07                	jne    800c57 <strtol+0x49>
		s++, neg = 1;
  800c50:	83 c2 01             	add    $0x1,%edx
  800c53:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c57:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800c5c:	75 15                	jne    800c73 <strtol+0x65>
  800c5e:	80 3a 30             	cmpb   $0x30,(%edx)
  800c61:	75 10                	jne    800c73 <strtol+0x65>
  800c63:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800c67:	75 0a                	jne    800c73 <strtol+0x65>
		s += 2, base = 16;
  800c69:	83 c2 02             	add    $0x2,%edx
  800c6c:	b8 10 00 00 00       	mov    $0x10,%eax
  800c71:	eb 10                	jmp    800c83 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
  800c73:	85 c0                	test   %eax,%eax
  800c75:	75 0c                	jne    800c83 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800c77:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c79:	80 3a 30             	cmpb   $0x30,(%edx)
  800c7c:	75 05                	jne    800c83 <strtol+0x75>
		s++, base = 8;
  800c7e:	83 c2 01             	add    $0x1,%edx
  800c81:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800c83:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c88:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c8b:	0f b6 0a             	movzbl (%edx),%ecx
  800c8e:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800c91:	89 f0                	mov    %esi,%eax
  800c93:	3c 09                	cmp    $0x9,%al
  800c95:	77 08                	ja     800c9f <strtol+0x91>
			dig = *s - '0';
  800c97:	0f be c9             	movsbl %cl,%ecx
  800c9a:	83 e9 30             	sub    $0x30,%ecx
  800c9d:	eb 20                	jmp    800cbf <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
  800c9f:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800ca2:	89 f0                	mov    %esi,%eax
  800ca4:	3c 19                	cmp    $0x19,%al
  800ca6:	77 08                	ja     800cb0 <strtol+0xa2>
			dig = *s - 'a' + 10;
  800ca8:	0f be c9             	movsbl %cl,%ecx
  800cab:	83 e9 57             	sub    $0x57,%ecx
  800cae:	eb 0f                	jmp    800cbf <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
  800cb0:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800cb3:	89 f0                	mov    %esi,%eax
  800cb5:	3c 19                	cmp    $0x19,%al
  800cb7:	77 16                	ja     800ccf <strtol+0xc1>
			dig = *s - 'A' + 10;
  800cb9:	0f be c9             	movsbl %cl,%ecx
  800cbc:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800cbf:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800cc2:	7d 0f                	jge    800cd3 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800cc4:	83 c2 01             	add    $0x1,%edx
  800cc7:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800ccb:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800ccd:	eb bc                	jmp    800c8b <strtol+0x7d>
  800ccf:	89 d8                	mov    %ebx,%eax
  800cd1:	eb 02                	jmp    800cd5 <strtol+0xc7>
  800cd3:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800cd5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800cd9:	74 05                	je     800ce0 <strtol+0xd2>
		*endptr = (char *) s;
  800cdb:	8b 75 0c             	mov    0xc(%ebp),%esi
  800cde:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800ce0:	f7 d8                	neg    %eax
  800ce2:	85 ff                	test   %edi,%edi
  800ce4:	0f 44 c3             	cmove  %ebx,%eax
}
  800ce7:	5b                   	pop    %ebx
  800ce8:	5e                   	pop    %esi
  800ce9:	5f                   	pop    %edi
  800cea:	5d                   	pop    %ebp
  800ceb:	c3                   	ret    

00800cec <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800cec:	55                   	push   %ebp
  800ced:	89 e5                	mov    %esp,%ebp
  800cef:	57                   	push   %edi
  800cf0:	56                   	push   %esi
  800cf1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cf2:	b8 00 00 00 00       	mov    $0x0,%eax
  800cf7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cfa:	8b 55 08             	mov    0x8(%ebp),%edx
  800cfd:	89 c3                	mov    %eax,%ebx
  800cff:	89 c7                	mov    %eax,%edi
  800d01:	89 c6                	mov    %eax,%esi
  800d03:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800d05:	5b                   	pop    %ebx
  800d06:	5e                   	pop    %esi
  800d07:	5f                   	pop    %edi
  800d08:	5d                   	pop    %ebp
  800d09:	c3                   	ret    

00800d0a <sys_cgetc>:

int
sys_cgetc(void)
{
  800d0a:	55                   	push   %ebp
  800d0b:	89 e5                	mov    %esp,%ebp
  800d0d:	57                   	push   %edi
  800d0e:	56                   	push   %esi
  800d0f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d10:	ba 00 00 00 00       	mov    $0x0,%edx
  800d15:	b8 01 00 00 00       	mov    $0x1,%eax
  800d1a:	89 d1                	mov    %edx,%ecx
  800d1c:	89 d3                	mov    %edx,%ebx
  800d1e:	89 d7                	mov    %edx,%edi
  800d20:	89 d6                	mov    %edx,%esi
  800d22:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800d24:	5b                   	pop    %ebx
  800d25:	5e                   	pop    %esi
  800d26:	5f                   	pop    %edi
  800d27:	5d                   	pop    %ebp
  800d28:	c3                   	ret    

00800d29 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800d29:	55                   	push   %ebp
  800d2a:	89 e5                	mov    %esp,%ebp
  800d2c:	57                   	push   %edi
  800d2d:	56                   	push   %esi
  800d2e:	53                   	push   %ebx
  800d2f:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d32:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d37:	b8 03 00 00 00       	mov    $0x3,%eax
  800d3c:	8b 55 08             	mov    0x8(%ebp),%edx
  800d3f:	89 cb                	mov    %ecx,%ebx
  800d41:	89 cf                	mov    %ecx,%edi
  800d43:	89 ce                	mov    %ecx,%esi
  800d45:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d47:	85 c0                	test   %eax,%eax
  800d49:	7e 28                	jle    800d73 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d4b:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d4f:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800d56:	00 
  800d57:	c7 44 24 08 20 13 80 	movl   $0x801320,0x8(%esp)
  800d5e:	00 
  800d5f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d66:	00 
  800d67:	c7 04 24 3d 13 80 00 	movl   $0x80133d,(%esp)
  800d6e:	e8 29 f4 ff ff       	call   80019c <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800d73:	83 c4 2c             	add    $0x2c,%esp
  800d76:	5b                   	pop    %ebx
  800d77:	5e                   	pop    %esi
  800d78:	5f                   	pop    %edi
  800d79:	5d                   	pop    %ebp
  800d7a:	c3                   	ret    

00800d7b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800d7b:	55                   	push   %ebp
  800d7c:	89 e5                	mov    %esp,%ebp
  800d7e:	57                   	push   %edi
  800d7f:	56                   	push   %esi
  800d80:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d81:	ba 00 00 00 00       	mov    $0x0,%edx
  800d86:	b8 02 00 00 00       	mov    $0x2,%eax
  800d8b:	89 d1                	mov    %edx,%ecx
  800d8d:	89 d3                	mov    %edx,%ebx
  800d8f:	89 d7                	mov    %edx,%edi
  800d91:	89 d6                	mov    %edx,%esi
  800d93:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800d95:	5b                   	pop    %ebx
  800d96:	5e                   	pop    %esi
  800d97:	5f                   	pop    %edi
  800d98:	5d                   	pop    %ebp
  800d99:	c3                   	ret    
  800d9a:	66 90                	xchg   %ax,%ax
  800d9c:	66 90                	xchg   %ax,%ax
  800d9e:	66 90                	xchg   %ax,%ax

00800da0 <__udivdi3>:
  800da0:	55                   	push   %ebp
  800da1:	57                   	push   %edi
  800da2:	56                   	push   %esi
  800da3:	83 ec 0c             	sub    $0xc,%esp
  800da6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800daa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800dae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800db2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800db6:	85 c0                	test   %eax,%eax
  800db8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800dbc:	89 ea                	mov    %ebp,%edx
  800dbe:	89 0c 24             	mov    %ecx,(%esp)
  800dc1:	75 2d                	jne    800df0 <__udivdi3+0x50>
  800dc3:	39 e9                	cmp    %ebp,%ecx
  800dc5:	77 61                	ja     800e28 <__udivdi3+0x88>
  800dc7:	85 c9                	test   %ecx,%ecx
  800dc9:	89 ce                	mov    %ecx,%esi
  800dcb:	75 0b                	jne    800dd8 <__udivdi3+0x38>
  800dcd:	b8 01 00 00 00       	mov    $0x1,%eax
  800dd2:	31 d2                	xor    %edx,%edx
  800dd4:	f7 f1                	div    %ecx
  800dd6:	89 c6                	mov    %eax,%esi
  800dd8:	31 d2                	xor    %edx,%edx
  800dda:	89 e8                	mov    %ebp,%eax
  800ddc:	f7 f6                	div    %esi
  800dde:	89 c5                	mov    %eax,%ebp
  800de0:	89 f8                	mov    %edi,%eax
  800de2:	f7 f6                	div    %esi
  800de4:	89 ea                	mov    %ebp,%edx
  800de6:	83 c4 0c             	add    $0xc,%esp
  800de9:	5e                   	pop    %esi
  800dea:	5f                   	pop    %edi
  800deb:	5d                   	pop    %ebp
  800dec:	c3                   	ret    
  800ded:	8d 76 00             	lea    0x0(%esi),%esi
  800df0:	39 e8                	cmp    %ebp,%eax
  800df2:	77 24                	ja     800e18 <__udivdi3+0x78>
  800df4:	0f bd e8             	bsr    %eax,%ebp
  800df7:	83 f5 1f             	xor    $0x1f,%ebp
  800dfa:	75 3c                	jne    800e38 <__udivdi3+0x98>
  800dfc:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e00:	39 34 24             	cmp    %esi,(%esp)
  800e03:	0f 86 9f 00 00 00    	jbe    800ea8 <__udivdi3+0x108>
  800e09:	39 d0                	cmp    %edx,%eax
  800e0b:	0f 82 97 00 00 00    	jb     800ea8 <__udivdi3+0x108>
  800e11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e18:	31 d2                	xor    %edx,%edx
  800e1a:	31 c0                	xor    %eax,%eax
  800e1c:	83 c4 0c             	add    $0xc,%esp
  800e1f:	5e                   	pop    %esi
  800e20:	5f                   	pop    %edi
  800e21:	5d                   	pop    %ebp
  800e22:	c3                   	ret    
  800e23:	90                   	nop
  800e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e28:	89 f8                	mov    %edi,%eax
  800e2a:	f7 f1                	div    %ecx
  800e2c:	31 d2                	xor    %edx,%edx
  800e2e:	83 c4 0c             	add    $0xc,%esp
  800e31:	5e                   	pop    %esi
  800e32:	5f                   	pop    %edi
  800e33:	5d                   	pop    %ebp
  800e34:	c3                   	ret    
  800e35:	8d 76 00             	lea    0x0(%esi),%esi
  800e38:	89 e9                	mov    %ebp,%ecx
  800e3a:	8b 3c 24             	mov    (%esp),%edi
  800e3d:	d3 e0                	shl    %cl,%eax
  800e3f:	89 c6                	mov    %eax,%esi
  800e41:	b8 20 00 00 00       	mov    $0x20,%eax
  800e46:	29 e8                	sub    %ebp,%eax
  800e48:	89 c1                	mov    %eax,%ecx
  800e4a:	d3 ef                	shr    %cl,%edi
  800e4c:	89 e9                	mov    %ebp,%ecx
  800e4e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800e52:	8b 3c 24             	mov    (%esp),%edi
  800e55:	09 74 24 08          	or     %esi,0x8(%esp)
  800e59:	89 d6                	mov    %edx,%esi
  800e5b:	d3 e7                	shl    %cl,%edi
  800e5d:	89 c1                	mov    %eax,%ecx
  800e5f:	89 3c 24             	mov    %edi,(%esp)
  800e62:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800e66:	d3 ee                	shr    %cl,%esi
  800e68:	89 e9                	mov    %ebp,%ecx
  800e6a:	d3 e2                	shl    %cl,%edx
  800e6c:	89 c1                	mov    %eax,%ecx
  800e6e:	d3 ef                	shr    %cl,%edi
  800e70:	09 d7                	or     %edx,%edi
  800e72:	89 f2                	mov    %esi,%edx
  800e74:	89 f8                	mov    %edi,%eax
  800e76:	f7 74 24 08          	divl   0x8(%esp)
  800e7a:	89 d6                	mov    %edx,%esi
  800e7c:	89 c7                	mov    %eax,%edi
  800e7e:	f7 24 24             	mull   (%esp)
  800e81:	39 d6                	cmp    %edx,%esi
  800e83:	89 14 24             	mov    %edx,(%esp)
  800e86:	72 30                	jb     800eb8 <__udivdi3+0x118>
  800e88:	8b 54 24 04          	mov    0x4(%esp),%edx
  800e8c:	89 e9                	mov    %ebp,%ecx
  800e8e:	d3 e2                	shl    %cl,%edx
  800e90:	39 c2                	cmp    %eax,%edx
  800e92:	73 05                	jae    800e99 <__udivdi3+0xf9>
  800e94:	3b 34 24             	cmp    (%esp),%esi
  800e97:	74 1f                	je     800eb8 <__udivdi3+0x118>
  800e99:	89 f8                	mov    %edi,%eax
  800e9b:	31 d2                	xor    %edx,%edx
  800e9d:	e9 7a ff ff ff       	jmp    800e1c <__udivdi3+0x7c>
  800ea2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ea8:	31 d2                	xor    %edx,%edx
  800eaa:	b8 01 00 00 00       	mov    $0x1,%eax
  800eaf:	e9 68 ff ff ff       	jmp    800e1c <__udivdi3+0x7c>
  800eb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800eb8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800ebb:	31 d2                	xor    %edx,%edx
  800ebd:	83 c4 0c             	add    $0xc,%esp
  800ec0:	5e                   	pop    %esi
  800ec1:	5f                   	pop    %edi
  800ec2:	5d                   	pop    %ebp
  800ec3:	c3                   	ret    
  800ec4:	66 90                	xchg   %ax,%ax
  800ec6:	66 90                	xchg   %ax,%ax
  800ec8:	66 90                	xchg   %ax,%ax
  800eca:	66 90                	xchg   %ax,%ax
  800ecc:	66 90                	xchg   %ax,%ax
  800ece:	66 90                	xchg   %ax,%ax

00800ed0 <__umoddi3>:
  800ed0:	55                   	push   %ebp
  800ed1:	57                   	push   %edi
  800ed2:	56                   	push   %esi
  800ed3:	83 ec 14             	sub    $0x14,%esp
  800ed6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800eda:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800ede:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800ee2:	89 c7                	mov    %eax,%edi
  800ee4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ee8:	8b 44 24 30          	mov    0x30(%esp),%eax
  800eec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800ef0:	89 34 24             	mov    %esi,(%esp)
  800ef3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ef7:	85 c0                	test   %eax,%eax
  800ef9:	89 c2                	mov    %eax,%edx
  800efb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800eff:	75 17                	jne    800f18 <__umoddi3+0x48>
  800f01:	39 fe                	cmp    %edi,%esi
  800f03:	76 4b                	jbe    800f50 <__umoddi3+0x80>
  800f05:	89 c8                	mov    %ecx,%eax
  800f07:	89 fa                	mov    %edi,%edx
  800f09:	f7 f6                	div    %esi
  800f0b:	89 d0                	mov    %edx,%eax
  800f0d:	31 d2                	xor    %edx,%edx
  800f0f:	83 c4 14             	add    $0x14,%esp
  800f12:	5e                   	pop    %esi
  800f13:	5f                   	pop    %edi
  800f14:	5d                   	pop    %ebp
  800f15:	c3                   	ret    
  800f16:	66 90                	xchg   %ax,%ax
  800f18:	39 f8                	cmp    %edi,%eax
  800f1a:	77 54                	ja     800f70 <__umoddi3+0xa0>
  800f1c:	0f bd e8             	bsr    %eax,%ebp
  800f1f:	83 f5 1f             	xor    $0x1f,%ebp
  800f22:	75 5c                	jne    800f80 <__umoddi3+0xb0>
  800f24:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800f28:	39 3c 24             	cmp    %edi,(%esp)
  800f2b:	0f 87 e7 00 00 00    	ja     801018 <__umoddi3+0x148>
  800f31:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800f35:	29 f1                	sub    %esi,%ecx
  800f37:	19 c7                	sbb    %eax,%edi
  800f39:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f3d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800f41:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f45:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800f49:	83 c4 14             	add    $0x14,%esp
  800f4c:	5e                   	pop    %esi
  800f4d:	5f                   	pop    %edi
  800f4e:	5d                   	pop    %ebp
  800f4f:	c3                   	ret    
  800f50:	85 f6                	test   %esi,%esi
  800f52:	89 f5                	mov    %esi,%ebp
  800f54:	75 0b                	jne    800f61 <__umoddi3+0x91>
  800f56:	b8 01 00 00 00       	mov    $0x1,%eax
  800f5b:	31 d2                	xor    %edx,%edx
  800f5d:	f7 f6                	div    %esi
  800f5f:	89 c5                	mov    %eax,%ebp
  800f61:	8b 44 24 04          	mov    0x4(%esp),%eax
  800f65:	31 d2                	xor    %edx,%edx
  800f67:	f7 f5                	div    %ebp
  800f69:	89 c8                	mov    %ecx,%eax
  800f6b:	f7 f5                	div    %ebp
  800f6d:	eb 9c                	jmp    800f0b <__umoddi3+0x3b>
  800f6f:	90                   	nop
  800f70:	89 c8                	mov    %ecx,%eax
  800f72:	89 fa                	mov    %edi,%edx
  800f74:	83 c4 14             	add    $0x14,%esp
  800f77:	5e                   	pop    %esi
  800f78:	5f                   	pop    %edi
  800f79:	5d                   	pop    %ebp
  800f7a:	c3                   	ret    
  800f7b:	90                   	nop
  800f7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f80:	8b 04 24             	mov    (%esp),%eax
  800f83:	be 20 00 00 00       	mov    $0x20,%esi
  800f88:	89 e9                	mov    %ebp,%ecx
  800f8a:	29 ee                	sub    %ebp,%esi
  800f8c:	d3 e2                	shl    %cl,%edx
  800f8e:	89 f1                	mov    %esi,%ecx
  800f90:	d3 e8                	shr    %cl,%eax
  800f92:	89 e9                	mov    %ebp,%ecx
  800f94:	89 44 24 04          	mov    %eax,0x4(%esp)
  800f98:	8b 04 24             	mov    (%esp),%eax
  800f9b:	09 54 24 04          	or     %edx,0x4(%esp)
  800f9f:	89 fa                	mov    %edi,%edx
  800fa1:	d3 e0                	shl    %cl,%eax
  800fa3:	89 f1                	mov    %esi,%ecx
  800fa5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800fa9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800fad:	d3 ea                	shr    %cl,%edx
  800faf:	89 e9                	mov    %ebp,%ecx
  800fb1:	d3 e7                	shl    %cl,%edi
  800fb3:	89 f1                	mov    %esi,%ecx
  800fb5:	d3 e8                	shr    %cl,%eax
  800fb7:	89 e9                	mov    %ebp,%ecx
  800fb9:	09 f8                	or     %edi,%eax
  800fbb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800fbf:	f7 74 24 04          	divl   0x4(%esp)
  800fc3:	d3 e7                	shl    %cl,%edi
  800fc5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800fc9:	89 d7                	mov    %edx,%edi
  800fcb:	f7 64 24 08          	mull   0x8(%esp)
  800fcf:	39 d7                	cmp    %edx,%edi
  800fd1:	89 c1                	mov    %eax,%ecx
  800fd3:	89 14 24             	mov    %edx,(%esp)
  800fd6:	72 2c                	jb     801004 <__umoddi3+0x134>
  800fd8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800fdc:	72 22                	jb     801000 <__umoddi3+0x130>
  800fde:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800fe2:	29 c8                	sub    %ecx,%eax
  800fe4:	19 d7                	sbb    %edx,%edi
  800fe6:	89 e9                	mov    %ebp,%ecx
  800fe8:	89 fa                	mov    %edi,%edx
  800fea:	d3 e8                	shr    %cl,%eax
  800fec:	89 f1                	mov    %esi,%ecx
  800fee:	d3 e2                	shl    %cl,%edx
  800ff0:	89 e9                	mov    %ebp,%ecx
  800ff2:	d3 ef                	shr    %cl,%edi
  800ff4:	09 d0                	or     %edx,%eax
  800ff6:	89 fa                	mov    %edi,%edx
  800ff8:	83 c4 14             	add    $0x14,%esp
  800ffb:	5e                   	pop    %esi
  800ffc:	5f                   	pop    %edi
  800ffd:	5d                   	pop    %ebp
  800ffe:	c3                   	ret    
  800fff:	90                   	nop
  801000:	39 d7                	cmp    %edx,%edi
  801002:	75 da                	jne    800fde <__umoddi3+0x10e>
  801004:	8b 14 24             	mov    (%esp),%edx
  801007:	89 c1                	mov    %eax,%ecx
  801009:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80100d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801011:	eb cb                	jmp    800fde <__umoddi3+0x10e>
  801013:	90                   	nop
  801014:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801018:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80101c:	0f 82 0f ff ff ff    	jb     800f31 <__umoddi3+0x61>
  801022:	e9 1a ff ff ff       	jmp    800f41 <__umoddi3+0x71>
