
obj/user/faultread:     file format elf32-i386


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
  80002c:	e8 1f 00 00 00       	call   800050 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	a1 00 00 00 00       	mov    0x0,%eax
  80003e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800042:	c7 04 24 48 0f 80 00 	movl   $0x800f48,(%esp)
  800049:	e8 0e 01 00 00       	call   80015c <cprintf>
}
  80004e:	c9                   	leave  
  80004f:	c3                   	ret    

00800050 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800050:	55                   	push   %ebp
  800051:	89 e5                	mov    %esp,%ebp
  800053:	56                   	push   %esi
  800054:	53                   	push   %ebx
  800055:	83 ec 10             	sub    $0x10,%esp
  800058:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005b:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005e:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800065:	00 00 00 
	//thisenv=envs+ENVX(sys_getenvid());
	int index=sys_getenvid();
  800068:	e8 be 0b 00 00       	call   800c2b <sys_getenvid>
        thisenv=&envs[ENVX(index)];
  80006d:	25 ff 03 00 00       	and    $0x3ff,%eax
  800072:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800075:	c1 e0 05             	shl    $0x5,%eax
  800078:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007d:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800082:	85 db                	test   %ebx,%ebx
  800084:	7e 07                	jle    80008d <libmain+0x3d>
		binaryname = argv[0];
  800086:	8b 06                	mov    (%esi),%eax
  800088:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80008d:	89 74 24 04          	mov    %esi,0x4(%esp)
  800091:	89 1c 24             	mov    %ebx,(%esp)
  800094:	e8 9a ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800099:	e8 07 00 00 00       	call   8000a5 <exit>
}
  80009e:	83 c4 10             	add    $0x10,%esp
  8000a1:	5b                   	pop    %ebx
  8000a2:	5e                   	pop    %esi
  8000a3:	5d                   	pop    %ebp
  8000a4:	c3                   	ret    

008000a5 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a5:	55                   	push   %ebp
  8000a6:	89 e5                	mov    %esp,%ebp
  8000a8:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000b2:	e8 22 0b 00 00       	call   800bd9 <sys_env_destroy>
}
  8000b7:	c9                   	leave  
  8000b8:	c3                   	ret    

008000b9 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b9:	55                   	push   %ebp
  8000ba:	89 e5                	mov    %esp,%ebp
  8000bc:	53                   	push   %ebx
  8000bd:	83 ec 14             	sub    $0x14,%esp
  8000c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c3:	8b 13                	mov    (%ebx),%edx
  8000c5:	8d 42 01             	lea    0x1(%edx),%eax
  8000c8:	89 03                	mov    %eax,(%ebx)
  8000ca:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cd:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d1:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d6:	75 19                	jne    8000f1 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000d8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000df:	00 
  8000e0:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e3:	89 04 24             	mov    %eax,(%esp)
  8000e6:	e8 b1 0a 00 00       	call   800b9c <sys_cputs>
		b->idx = 0;
  8000eb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000f1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f5:	83 c4 14             	add    $0x14,%esp
  8000f8:	5b                   	pop    %ebx
  8000f9:	5d                   	pop    %ebp
  8000fa:	c3                   	ret    

008000fb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fb:	55                   	push   %ebp
  8000fc:	89 e5                	mov    %esp,%ebp
  8000fe:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800104:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010b:	00 00 00 
	b.cnt = 0;
  80010e:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800115:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800118:	8b 45 0c             	mov    0xc(%ebp),%eax
  80011b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80011f:	8b 45 08             	mov    0x8(%ebp),%eax
  800122:	89 44 24 08          	mov    %eax,0x8(%esp)
  800126:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80012c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800130:	c7 04 24 b9 00 80 00 	movl   $0x8000b9,(%esp)
  800137:	e8 b8 01 00 00       	call   8002f4 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80013c:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800142:	89 44 24 04          	mov    %eax,0x4(%esp)
  800146:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80014c:	89 04 24             	mov    %eax,(%esp)
  80014f:	e8 48 0a 00 00       	call   800b9c <sys_cputs>

	return b.cnt;
}
  800154:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80015a:	c9                   	leave  
  80015b:	c3                   	ret    

0080015c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80015c:	55                   	push   %ebp
  80015d:	89 e5                	mov    %esp,%ebp
  80015f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800162:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800165:	89 44 24 04          	mov    %eax,0x4(%esp)
  800169:	8b 45 08             	mov    0x8(%ebp),%eax
  80016c:	89 04 24             	mov    %eax,(%esp)
  80016f:	e8 87 ff ff ff       	call   8000fb <vcprintf>
	va_end(ap);

	return cnt;
}
  800174:	c9                   	leave  
  800175:	c3                   	ret    
  800176:	66 90                	xchg   %ax,%ax
  800178:	66 90                	xchg   %ax,%ax
  80017a:	66 90                	xchg   %ax,%ax
  80017c:	66 90                	xchg   %ax,%ax
  80017e:	66 90                	xchg   %ax,%ax

00800180 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800180:	55                   	push   %ebp
  800181:	89 e5                	mov    %esp,%ebp
  800183:	57                   	push   %edi
  800184:	56                   	push   %esi
  800185:	53                   	push   %ebx
  800186:	83 ec 3c             	sub    $0x3c,%esp
  800189:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80018c:	89 d7                	mov    %edx,%edi
  80018e:	8b 45 08             	mov    0x8(%ebp),%eax
  800191:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800194:	8b 75 0c             	mov    0xc(%ebp),%esi
  800197:	89 75 d4             	mov    %esi,-0x2c(%ebp)
  80019a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80019d:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001a2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001a5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8001a8:	39 f1                	cmp    %esi,%ecx
  8001aa:	72 14                	jb     8001c0 <printnum+0x40>
  8001ac:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001af:	76 0f                	jbe    8001c0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8001b4:	8d 70 ff             	lea    -0x1(%eax),%esi
  8001b7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8001ba:	85 f6                	test   %esi,%esi
  8001bc:	7f 60                	jg     80021e <printnum+0x9e>
  8001be:	eb 72                	jmp    800232 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001c0:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001c3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001c7:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8001ca:	8d 51 ff             	lea    -0x1(%ecx),%edx
  8001cd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001d1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001d5:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001d9:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001dd:	89 c3                	mov    %eax,%ebx
  8001df:	89 d6                	mov    %edx,%esi
  8001e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001e4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001e7:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001eb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001f2:	89 04 24             	mov    %eax,(%esp)
  8001f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001fc:	e8 bf 0a 00 00       	call   800cc0 <__udivdi3>
  800201:	89 d9                	mov    %ebx,%ecx
  800203:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800207:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80020b:	89 04 24             	mov    %eax,(%esp)
  80020e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800212:	89 fa                	mov    %edi,%edx
  800214:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800217:	e8 64 ff ff ff       	call   800180 <printnum>
  80021c:	eb 14                	jmp    800232 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80021e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800222:	8b 45 18             	mov    0x18(%ebp),%eax
  800225:	89 04 24             	mov    %eax,(%esp)
  800228:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80022a:	83 ee 01             	sub    $0x1,%esi
  80022d:	75 ef                	jne    80021e <printnum+0x9e>
  80022f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800232:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800236:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80023a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80023d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800240:	89 44 24 08          	mov    %eax,0x8(%esp)
  800244:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800248:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80024b:	89 04 24             	mov    %eax,(%esp)
  80024e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800251:	89 44 24 04          	mov    %eax,0x4(%esp)
  800255:	e8 96 0b 00 00       	call   800df0 <__umoddi3>
  80025a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80025e:	0f be 80 70 0f 80 00 	movsbl 0x800f70(%eax),%eax
  800265:	89 04 24             	mov    %eax,(%esp)
  800268:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80026b:	ff d0                	call   *%eax
}
  80026d:	83 c4 3c             	add    $0x3c,%esp
  800270:	5b                   	pop    %ebx
  800271:	5e                   	pop    %esi
  800272:	5f                   	pop    %edi
  800273:	5d                   	pop    %ebp
  800274:	c3                   	ret    

00800275 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800275:	55                   	push   %ebp
  800276:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800278:	83 fa 01             	cmp    $0x1,%edx
  80027b:	7e 0e                	jle    80028b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80027d:	8b 10                	mov    (%eax),%edx
  80027f:	8d 4a 08             	lea    0x8(%edx),%ecx
  800282:	89 08                	mov    %ecx,(%eax)
  800284:	8b 02                	mov    (%edx),%eax
  800286:	8b 52 04             	mov    0x4(%edx),%edx
  800289:	eb 22                	jmp    8002ad <getuint+0x38>
	else if (lflag)
  80028b:	85 d2                	test   %edx,%edx
  80028d:	74 10                	je     80029f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80028f:	8b 10                	mov    (%eax),%edx
  800291:	8d 4a 04             	lea    0x4(%edx),%ecx
  800294:	89 08                	mov    %ecx,(%eax)
  800296:	8b 02                	mov    (%edx),%eax
  800298:	ba 00 00 00 00       	mov    $0x0,%edx
  80029d:	eb 0e                	jmp    8002ad <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80029f:	8b 10                	mov    (%eax),%edx
  8002a1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002a4:	89 08                	mov    %ecx,(%eax)
  8002a6:	8b 02                	mov    (%edx),%eax
  8002a8:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002ad:	5d                   	pop    %ebp
  8002ae:	c3                   	ret    

008002af <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002af:	55                   	push   %ebp
  8002b0:	89 e5                	mov    %esp,%ebp
  8002b2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002b5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002b9:	8b 10                	mov    (%eax),%edx
  8002bb:	3b 50 04             	cmp    0x4(%eax),%edx
  8002be:	73 0a                	jae    8002ca <sprintputch+0x1b>
		*b->buf++ = ch;
  8002c0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002c3:	89 08                	mov    %ecx,(%eax)
  8002c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c8:	88 02                	mov    %al,(%edx)
}
  8002ca:	5d                   	pop    %ebp
  8002cb:	c3                   	ret    

008002cc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002cc:	55                   	push   %ebp
  8002cd:	89 e5                	mov    %esp,%ebp
  8002cf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002d2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002d9:	8b 45 10             	mov    0x10(%ebp),%eax
  8002dc:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002e7:	8b 45 08             	mov    0x8(%ebp),%eax
  8002ea:	89 04 24             	mov    %eax,(%esp)
  8002ed:	e8 02 00 00 00       	call   8002f4 <vprintfmt>
	va_end(ap);
}
  8002f2:	c9                   	leave  
  8002f3:	c3                   	ret    

008002f4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002f4:	55                   	push   %ebp
  8002f5:	89 e5                	mov    %esp,%ebp
  8002f7:	57                   	push   %edi
  8002f8:	56                   	push   %esi
  8002f9:	53                   	push   %ebx
  8002fa:	83 ec 3c             	sub    $0x3c,%esp
  8002fd:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800300:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800303:	eb 18                	jmp    80031d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800305:	85 c0                	test   %eax,%eax
  800307:	0f 84 c3 03 00 00    	je     8006d0 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
  80030d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800311:	89 04 24             	mov    %eax,(%esp)
  800314:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800317:	89 f3                	mov    %esi,%ebx
  800319:	eb 02                	jmp    80031d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
  80031b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80031d:	8d 73 01             	lea    0x1(%ebx),%esi
  800320:	0f b6 03             	movzbl (%ebx),%eax
  800323:	83 f8 25             	cmp    $0x25,%eax
  800326:	75 dd                	jne    800305 <vprintfmt+0x11>
  800328:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
  80032c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800333:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  80033a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800341:	ba 00 00 00 00       	mov    $0x0,%edx
  800346:	eb 1d                	jmp    800365 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800348:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80034a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
  80034e:	eb 15                	jmp    800365 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800350:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800352:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
  800356:	eb 0d                	jmp    800365 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800358:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80035b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80035e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800365:	8d 5e 01             	lea    0x1(%esi),%ebx
  800368:	0f b6 06             	movzbl (%esi),%eax
  80036b:	0f b6 c8             	movzbl %al,%ecx
  80036e:	83 e8 23             	sub    $0x23,%eax
  800371:	3c 55                	cmp    $0x55,%al
  800373:	0f 87 2f 03 00 00    	ja     8006a8 <vprintfmt+0x3b4>
  800379:	0f b6 c0             	movzbl %al,%eax
  80037c:	ff 24 85 00 10 80 00 	jmp    *0x801000(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800383:	8d 41 d0             	lea    -0x30(%ecx),%eax
  800386:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
  800389:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
  80038d:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800390:	83 f9 09             	cmp    $0x9,%ecx
  800393:	77 50                	ja     8003e5 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800395:	89 de                	mov    %ebx,%esi
  800397:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80039a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
  80039d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8003a0:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8003a4:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8003a7:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8003aa:	83 fb 09             	cmp    $0x9,%ebx
  8003ad:	76 eb                	jbe    80039a <vprintfmt+0xa6>
  8003af:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8003b2:	eb 33                	jmp    8003e7 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b7:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ba:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003bd:	8b 00                	mov    (%eax),%eax
  8003bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c2:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003c4:	eb 21                	jmp    8003e7 <vprintfmt+0xf3>
  8003c6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003c9:	85 c9                	test   %ecx,%ecx
  8003cb:	b8 00 00 00 00       	mov    $0x0,%eax
  8003d0:	0f 49 c1             	cmovns %ecx,%eax
  8003d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d6:	89 de                	mov    %ebx,%esi
  8003d8:	eb 8b                	jmp    800365 <vprintfmt+0x71>
  8003da:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003dc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003e3:	eb 80                	jmp    800365 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e5:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8003e7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8003eb:	0f 89 74 ff ff ff    	jns    800365 <vprintfmt+0x71>
  8003f1:	e9 62 ff ff ff       	jmp    800358 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003f6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f9:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003fb:	e9 65 ff ff ff       	jmp    800365 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800400:	8b 45 14             	mov    0x14(%ebp),%eax
  800403:	8d 50 04             	lea    0x4(%eax),%edx
  800406:	89 55 14             	mov    %edx,0x14(%ebp)
  800409:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80040d:	8b 00                	mov    (%eax),%eax
  80040f:	89 04 24             	mov    %eax,(%esp)
  800412:	ff 55 08             	call   *0x8(%ebp)
			break;
  800415:	e9 03 ff ff ff       	jmp    80031d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80041a:	8b 45 14             	mov    0x14(%ebp),%eax
  80041d:	8d 50 04             	lea    0x4(%eax),%edx
  800420:	89 55 14             	mov    %edx,0x14(%ebp)
  800423:	8b 00                	mov    (%eax),%eax
  800425:	99                   	cltd   
  800426:	31 d0                	xor    %edx,%eax
  800428:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80042a:	83 f8 06             	cmp    $0x6,%eax
  80042d:	7f 0b                	jg     80043a <vprintfmt+0x146>
  80042f:	8b 14 85 58 11 80 00 	mov    0x801158(,%eax,4),%edx
  800436:	85 d2                	test   %edx,%edx
  800438:	75 20                	jne    80045a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
  80043a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80043e:	c7 44 24 08 88 0f 80 	movl   $0x800f88,0x8(%esp)
  800445:	00 
  800446:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80044a:	8b 45 08             	mov    0x8(%ebp),%eax
  80044d:	89 04 24             	mov    %eax,(%esp)
  800450:	e8 77 fe ff ff       	call   8002cc <printfmt>
  800455:	e9 c3 fe ff ff       	jmp    80031d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
  80045a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80045e:	c7 44 24 08 91 0f 80 	movl   $0x800f91,0x8(%esp)
  800465:	00 
  800466:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80046a:	8b 45 08             	mov    0x8(%ebp),%eax
  80046d:	89 04 24             	mov    %eax,(%esp)
  800470:	e8 57 fe ff ff       	call   8002cc <printfmt>
  800475:	e9 a3 fe ff ff       	jmp    80031d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80047a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80047d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800480:	8b 45 14             	mov    0x14(%ebp),%eax
  800483:	8d 50 04             	lea    0x4(%eax),%edx
  800486:	89 55 14             	mov    %edx,0x14(%ebp)
  800489:	8b 00                	mov    (%eax),%eax
				p = "(null)";
  80048b:	85 c0                	test   %eax,%eax
  80048d:	ba 81 0f 80 00       	mov    $0x800f81,%edx
  800492:	0f 45 d0             	cmovne %eax,%edx
  800495:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
  800498:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
  80049c:	74 04                	je     8004a2 <vprintfmt+0x1ae>
  80049e:	85 f6                	test   %esi,%esi
  8004a0:	7f 19                	jg     8004bb <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004a2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8004a5:	8d 70 01             	lea    0x1(%eax),%esi
  8004a8:	0f b6 10             	movzbl (%eax),%edx
  8004ab:	0f be c2             	movsbl %dl,%eax
  8004ae:	85 c0                	test   %eax,%eax
  8004b0:	0f 85 95 00 00 00    	jne    80054b <vprintfmt+0x257>
  8004b6:	e9 85 00 00 00       	jmp    800540 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8004c2:	89 04 24             	mov    %eax,(%esp)
  8004c5:	e8 b8 02 00 00       	call   800782 <strnlen>
  8004ca:	29 c6                	sub    %eax,%esi
  8004cc:	89 f0                	mov    %esi,%eax
  8004ce:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8004d1:	85 f6                	test   %esi,%esi
  8004d3:	7e cd                	jle    8004a2 <vprintfmt+0x1ae>
					putch(padc, putdat);
  8004d5:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  8004d9:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8004dc:	89 c3                	mov    %eax,%ebx
  8004de:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004e2:	89 34 24             	mov    %esi,(%esp)
  8004e5:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e8:	83 eb 01             	sub    $0x1,%ebx
  8004eb:	75 f1                	jne    8004de <vprintfmt+0x1ea>
  8004ed:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8004f0:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8004f3:	eb ad                	jmp    8004a2 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004f9:	74 1e                	je     800519 <vprintfmt+0x225>
  8004fb:	0f be d2             	movsbl %dl,%edx
  8004fe:	83 ea 20             	sub    $0x20,%edx
  800501:	83 fa 5e             	cmp    $0x5e,%edx
  800504:	76 13                	jbe    800519 <vprintfmt+0x225>
					putch('?', putdat);
  800506:	8b 45 0c             	mov    0xc(%ebp),%eax
  800509:	89 44 24 04          	mov    %eax,0x4(%esp)
  80050d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800514:	ff 55 08             	call   *0x8(%ebp)
  800517:	eb 0d                	jmp    800526 <vprintfmt+0x232>
				else
					putch(ch, putdat);
  800519:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80051c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800520:	89 04 24             	mov    %eax,(%esp)
  800523:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800526:	83 ef 01             	sub    $0x1,%edi
  800529:	83 c6 01             	add    $0x1,%esi
  80052c:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800530:	0f be c2             	movsbl %dl,%eax
  800533:	85 c0                	test   %eax,%eax
  800535:	75 20                	jne    800557 <vprintfmt+0x263>
  800537:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  80053a:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80053d:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800540:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800544:	7f 25                	jg     80056b <vprintfmt+0x277>
  800546:	e9 d2 fd ff ff       	jmp    80031d <vprintfmt+0x29>
  80054b:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80054e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800551:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800554:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800557:	85 db                	test   %ebx,%ebx
  800559:	78 9a                	js     8004f5 <vprintfmt+0x201>
  80055b:	83 eb 01             	sub    $0x1,%ebx
  80055e:	79 95                	jns    8004f5 <vprintfmt+0x201>
  800560:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  800563:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800566:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800569:	eb d5                	jmp    800540 <vprintfmt+0x24c>
  80056b:	8b 75 08             	mov    0x8(%ebp),%esi
  80056e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800571:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800574:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800578:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80057f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800581:	83 eb 01             	sub    $0x1,%ebx
  800584:	75 ee                	jne    800574 <vprintfmt+0x280>
  800586:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800589:	e9 8f fd ff ff       	jmp    80031d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80058e:	83 fa 01             	cmp    $0x1,%edx
  800591:	7e 16                	jle    8005a9 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
  800593:	8b 45 14             	mov    0x14(%ebp),%eax
  800596:	8d 50 08             	lea    0x8(%eax),%edx
  800599:	89 55 14             	mov    %edx,0x14(%ebp)
  80059c:	8b 50 04             	mov    0x4(%eax),%edx
  80059f:	8b 00                	mov    (%eax),%eax
  8005a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005a7:	eb 32                	jmp    8005db <vprintfmt+0x2e7>
	else if (lflag)
  8005a9:	85 d2                	test   %edx,%edx
  8005ab:	74 18                	je     8005c5 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
  8005ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b0:	8d 50 04             	lea    0x4(%eax),%edx
  8005b3:	89 55 14             	mov    %edx,0x14(%ebp)
  8005b6:	8b 30                	mov    (%eax),%esi
  8005b8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8005bb:	89 f0                	mov    %esi,%eax
  8005bd:	c1 f8 1f             	sar    $0x1f,%eax
  8005c0:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8005c3:	eb 16                	jmp    8005db <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
  8005c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c8:	8d 50 04             	lea    0x4(%eax),%edx
  8005cb:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ce:	8b 30                	mov    (%eax),%esi
  8005d0:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8005d3:	89 f0                	mov    %esi,%eax
  8005d5:	c1 f8 1f             	sar    $0x1f,%eax
  8005d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005db:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8005de:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005e1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005e6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005ea:	0f 89 80 00 00 00    	jns    800670 <vprintfmt+0x37c>
				putch('-', putdat);
  8005f0:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005f4:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005fb:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005fe:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800601:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800604:	f7 d8                	neg    %eax
  800606:	83 d2 00             	adc    $0x0,%edx
  800609:	f7 da                	neg    %edx
			}
			base = 10;
  80060b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800610:	eb 5e                	jmp    800670 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800612:	8d 45 14             	lea    0x14(%ebp),%eax
  800615:	e8 5b fc ff ff       	call   800275 <getuint>
			base = 10;
  80061a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80061f:	eb 4f                	jmp    800670 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
  800621:	8d 45 14             	lea    0x14(%ebp),%eax
  800624:	e8 4c fc ff ff       	call   800275 <getuint>
			base = 8;
  800629:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80062e:	eb 40                	jmp    800670 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
  800630:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800634:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80063b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  80063e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800642:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800649:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80064c:	8b 45 14             	mov    0x14(%ebp),%eax
  80064f:	8d 50 04             	lea    0x4(%eax),%edx
  800652:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800655:	8b 00                	mov    (%eax),%eax
  800657:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80065c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800661:	eb 0d                	jmp    800670 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800663:	8d 45 14             	lea    0x14(%ebp),%eax
  800666:	e8 0a fc ff ff       	call   800275 <getuint>
			base = 16;
  80066b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800670:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  800674:	89 74 24 10          	mov    %esi,0x10(%esp)
  800678:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80067b:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80067f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800683:	89 04 24             	mov    %eax,(%esp)
  800686:	89 54 24 04          	mov    %edx,0x4(%esp)
  80068a:	89 fa                	mov    %edi,%edx
  80068c:	8b 45 08             	mov    0x8(%ebp),%eax
  80068f:	e8 ec fa ff ff       	call   800180 <printnum>
			break;
  800694:	e9 84 fc ff ff       	jmp    80031d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800699:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80069d:	89 0c 24             	mov    %ecx,(%esp)
  8006a0:	ff 55 08             	call   *0x8(%ebp)
			break;
  8006a3:	e9 75 fc ff ff       	jmp    80031d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006ac:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006b3:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006b6:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  8006ba:	0f 84 5b fc ff ff    	je     80031b <vprintfmt+0x27>
  8006c0:	89 f3                	mov    %esi,%ebx
  8006c2:	83 eb 01             	sub    $0x1,%ebx
  8006c5:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8006c9:	75 f7                	jne    8006c2 <vprintfmt+0x3ce>
  8006cb:	e9 4d fc ff ff       	jmp    80031d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
  8006d0:	83 c4 3c             	add    $0x3c,%esp
  8006d3:	5b                   	pop    %ebx
  8006d4:	5e                   	pop    %esi
  8006d5:	5f                   	pop    %edi
  8006d6:	5d                   	pop    %ebp
  8006d7:	c3                   	ret    

008006d8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006d8:	55                   	push   %ebp
  8006d9:	89 e5                	mov    %esp,%ebp
  8006db:	83 ec 28             	sub    $0x28,%esp
  8006de:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006e7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006eb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006f5:	85 c0                	test   %eax,%eax
  8006f7:	74 30                	je     800729 <vsnprintf+0x51>
  8006f9:	85 d2                	test   %edx,%edx
  8006fb:	7e 2c                	jle    800729 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800700:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800704:	8b 45 10             	mov    0x10(%ebp),%eax
  800707:	89 44 24 08          	mov    %eax,0x8(%esp)
  80070b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80070e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800712:	c7 04 24 af 02 80 00 	movl   $0x8002af,(%esp)
  800719:	e8 d6 fb ff ff       	call   8002f4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80071e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800721:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800724:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800727:	eb 05                	jmp    80072e <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800729:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80072e:	c9                   	leave  
  80072f:	c3                   	ret    

00800730 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800730:	55                   	push   %ebp
  800731:	89 e5                	mov    %esp,%ebp
  800733:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800736:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800739:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80073d:	8b 45 10             	mov    0x10(%ebp),%eax
  800740:	89 44 24 08          	mov    %eax,0x8(%esp)
  800744:	8b 45 0c             	mov    0xc(%ebp),%eax
  800747:	89 44 24 04          	mov    %eax,0x4(%esp)
  80074b:	8b 45 08             	mov    0x8(%ebp),%eax
  80074e:	89 04 24             	mov    %eax,(%esp)
  800751:	e8 82 ff ff ff       	call   8006d8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800756:	c9                   	leave  
  800757:	c3                   	ret    
  800758:	66 90                	xchg   %ax,%ax
  80075a:	66 90                	xchg   %ax,%ax
  80075c:	66 90                	xchg   %ax,%ax
  80075e:	66 90                	xchg   %ax,%ax

00800760 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800760:	55                   	push   %ebp
  800761:	89 e5                	mov    %esp,%ebp
  800763:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800766:	80 3a 00             	cmpb   $0x0,(%edx)
  800769:	74 10                	je     80077b <strlen+0x1b>
  80076b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800770:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800773:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800777:	75 f7                	jne    800770 <strlen+0x10>
  800779:	eb 05                	jmp    800780 <strlen+0x20>
  80077b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800780:	5d                   	pop    %ebp
  800781:	c3                   	ret    

00800782 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800782:	55                   	push   %ebp
  800783:	89 e5                	mov    %esp,%ebp
  800785:	53                   	push   %ebx
  800786:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800789:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078c:	85 c9                	test   %ecx,%ecx
  80078e:	74 1c                	je     8007ac <strnlen+0x2a>
  800790:	80 3b 00             	cmpb   $0x0,(%ebx)
  800793:	74 1e                	je     8007b3 <strnlen+0x31>
  800795:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80079a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079c:	39 ca                	cmp    %ecx,%edx
  80079e:	74 18                	je     8007b8 <strnlen+0x36>
  8007a0:	83 c2 01             	add    $0x1,%edx
  8007a3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8007a8:	75 f0                	jne    80079a <strnlen+0x18>
  8007aa:	eb 0c                	jmp    8007b8 <strnlen+0x36>
  8007ac:	b8 00 00 00 00       	mov    $0x0,%eax
  8007b1:	eb 05                	jmp    8007b8 <strnlen+0x36>
  8007b3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8007b8:	5b                   	pop    %ebx
  8007b9:	5d                   	pop    %ebp
  8007ba:	c3                   	ret    

008007bb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007bb:	55                   	push   %ebp
  8007bc:	89 e5                	mov    %esp,%ebp
  8007be:	53                   	push   %ebx
  8007bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007c5:	89 c2                	mov    %eax,%edx
  8007c7:	83 c2 01             	add    $0x1,%edx
  8007ca:	83 c1 01             	add    $0x1,%ecx
  8007cd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007d1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007d4:	84 db                	test   %bl,%bl
  8007d6:	75 ef                	jne    8007c7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007d8:	5b                   	pop    %ebx
  8007d9:	5d                   	pop    %ebp
  8007da:	c3                   	ret    

008007db <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007db:	55                   	push   %ebp
  8007dc:	89 e5                	mov    %esp,%ebp
  8007de:	53                   	push   %ebx
  8007df:	83 ec 08             	sub    $0x8,%esp
  8007e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007e5:	89 1c 24             	mov    %ebx,(%esp)
  8007e8:	e8 73 ff ff ff       	call   800760 <strlen>
	strcpy(dst + len, src);
  8007ed:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007f0:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007f4:	01 d8                	add    %ebx,%eax
  8007f6:	89 04 24             	mov    %eax,(%esp)
  8007f9:	e8 bd ff ff ff       	call   8007bb <strcpy>
	return dst;
}
  8007fe:	89 d8                	mov    %ebx,%eax
  800800:	83 c4 08             	add    $0x8,%esp
  800803:	5b                   	pop    %ebx
  800804:	5d                   	pop    %ebp
  800805:	c3                   	ret    

00800806 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800806:	55                   	push   %ebp
  800807:	89 e5                	mov    %esp,%ebp
  800809:	56                   	push   %esi
  80080a:	53                   	push   %ebx
  80080b:	8b 75 08             	mov    0x8(%ebp),%esi
  80080e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800811:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800814:	85 db                	test   %ebx,%ebx
  800816:	74 17                	je     80082f <strncpy+0x29>
  800818:	01 f3                	add    %esi,%ebx
  80081a:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
  80081c:	83 c1 01             	add    $0x1,%ecx
  80081f:	0f b6 02             	movzbl (%edx),%eax
  800822:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800825:	80 3a 01             	cmpb   $0x1,(%edx)
  800828:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80082b:	39 d9                	cmp    %ebx,%ecx
  80082d:	75 ed                	jne    80081c <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80082f:	89 f0                	mov    %esi,%eax
  800831:	5b                   	pop    %ebx
  800832:	5e                   	pop    %esi
  800833:	5d                   	pop    %ebp
  800834:	c3                   	ret    

00800835 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800835:	55                   	push   %ebp
  800836:	89 e5                	mov    %esp,%ebp
  800838:	57                   	push   %edi
  800839:	56                   	push   %esi
  80083a:	53                   	push   %ebx
  80083b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80083e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800841:	8b 75 10             	mov    0x10(%ebp),%esi
  800844:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800846:	85 f6                	test   %esi,%esi
  800848:	74 34                	je     80087e <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
  80084a:	83 fe 01             	cmp    $0x1,%esi
  80084d:	74 26                	je     800875 <strlcpy+0x40>
  80084f:	0f b6 0b             	movzbl (%ebx),%ecx
  800852:	84 c9                	test   %cl,%cl
  800854:	74 23                	je     800879 <strlcpy+0x44>
  800856:	83 ee 02             	sub    $0x2,%esi
  800859:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
  80085e:	83 c0 01             	add    $0x1,%eax
  800861:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800864:	39 f2                	cmp    %esi,%edx
  800866:	74 13                	je     80087b <strlcpy+0x46>
  800868:	83 c2 01             	add    $0x1,%edx
  80086b:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80086f:	84 c9                	test   %cl,%cl
  800871:	75 eb                	jne    80085e <strlcpy+0x29>
  800873:	eb 06                	jmp    80087b <strlcpy+0x46>
  800875:	89 f8                	mov    %edi,%eax
  800877:	eb 02                	jmp    80087b <strlcpy+0x46>
  800879:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  80087b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80087e:	29 f8                	sub    %edi,%eax
}
  800880:	5b                   	pop    %ebx
  800881:	5e                   	pop    %esi
  800882:	5f                   	pop    %edi
  800883:	5d                   	pop    %ebp
  800884:	c3                   	ret    

00800885 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800885:	55                   	push   %ebp
  800886:	89 e5                	mov    %esp,%ebp
  800888:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80088b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80088e:	0f b6 01             	movzbl (%ecx),%eax
  800891:	84 c0                	test   %al,%al
  800893:	74 15                	je     8008aa <strcmp+0x25>
  800895:	3a 02                	cmp    (%edx),%al
  800897:	75 11                	jne    8008aa <strcmp+0x25>
		p++, q++;
  800899:	83 c1 01             	add    $0x1,%ecx
  80089c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80089f:	0f b6 01             	movzbl (%ecx),%eax
  8008a2:	84 c0                	test   %al,%al
  8008a4:	74 04                	je     8008aa <strcmp+0x25>
  8008a6:	3a 02                	cmp    (%edx),%al
  8008a8:	74 ef                	je     800899 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008aa:	0f b6 c0             	movzbl %al,%eax
  8008ad:	0f b6 12             	movzbl (%edx),%edx
  8008b0:	29 d0                	sub    %edx,%eax
}
  8008b2:	5d                   	pop    %ebp
  8008b3:	c3                   	ret    

008008b4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008b4:	55                   	push   %ebp
  8008b5:	89 e5                	mov    %esp,%ebp
  8008b7:	56                   	push   %esi
  8008b8:	53                   	push   %ebx
  8008b9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008bc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008bf:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8008c2:	85 f6                	test   %esi,%esi
  8008c4:	74 29                	je     8008ef <strncmp+0x3b>
  8008c6:	0f b6 03             	movzbl (%ebx),%eax
  8008c9:	84 c0                	test   %al,%al
  8008cb:	74 30                	je     8008fd <strncmp+0x49>
  8008cd:	3a 02                	cmp    (%edx),%al
  8008cf:	75 2c                	jne    8008fd <strncmp+0x49>
  8008d1:	8d 43 01             	lea    0x1(%ebx),%eax
  8008d4:	01 de                	add    %ebx,%esi
		n--, p++, q++;
  8008d6:	89 c3                	mov    %eax,%ebx
  8008d8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008db:	39 f0                	cmp    %esi,%eax
  8008dd:	74 17                	je     8008f6 <strncmp+0x42>
  8008df:	0f b6 08             	movzbl (%eax),%ecx
  8008e2:	84 c9                	test   %cl,%cl
  8008e4:	74 17                	je     8008fd <strncmp+0x49>
  8008e6:	83 c0 01             	add    $0x1,%eax
  8008e9:	3a 0a                	cmp    (%edx),%cl
  8008eb:	74 e9                	je     8008d6 <strncmp+0x22>
  8008ed:	eb 0e                	jmp    8008fd <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008ef:	b8 00 00 00 00       	mov    $0x0,%eax
  8008f4:	eb 0f                	jmp    800905 <strncmp+0x51>
  8008f6:	b8 00 00 00 00       	mov    $0x0,%eax
  8008fb:	eb 08                	jmp    800905 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008fd:	0f b6 03             	movzbl (%ebx),%eax
  800900:	0f b6 12             	movzbl (%edx),%edx
  800903:	29 d0                	sub    %edx,%eax
}
  800905:	5b                   	pop    %ebx
  800906:	5e                   	pop    %esi
  800907:	5d                   	pop    %ebp
  800908:	c3                   	ret    

00800909 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800909:	55                   	push   %ebp
  80090a:	89 e5                	mov    %esp,%ebp
  80090c:	53                   	push   %ebx
  80090d:	8b 45 08             	mov    0x8(%ebp),%eax
  800910:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800913:	0f b6 18             	movzbl (%eax),%ebx
  800916:	84 db                	test   %bl,%bl
  800918:	74 1d                	je     800937 <strchr+0x2e>
  80091a:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  80091c:	38 d3                	cmp    %dl,%bl
  80091e:	75 06                	jne    800926 <strchr+0x1d>
  800920:	eb 1a                	jmp    80093c <strchr+0x33>
  800922:	38 ca                	cmp    %cl,%dl
  800924:	74 16                	je     80093c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800926:	83 c0 01             	add    $0x1,%eax
  800929:	0f b6 10             	movzbl (%eax),%edx
  80092c:	84 d2                	test   %dl,%dl
  80092e:	75 f2                	jne    800922 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800930:	b8 00 00 00 00       	mov    $0x0,%eax
  800935:	eb 05                	jmp    80093c <strchr+0x33>
  800937:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80093c:	5b                   	pop    %ebx
  80093d:	5d                   	pop    %ebp
  80093e:	c3                   	ret    

0080093f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80093f:	55                   	push   %ebp
  800940:	89 e5                	mov    %esp,%ebp
  800942:	53                   	push   %ebx
  800943:	8b 45 08             	mov    0x8(%ebp),%eax
  800946:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800949:	0f b6 18             	movzbl (%eax),%ebx
  80094c:	84 db                	test   %bl,%bl
  80094e:	74 16                	je     800966 <strfind+0x27>
  800950:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800952:	38 d3                	cmp    %dl,%bl
  800954:	75 06                	jne    80095c <strfind+0x1d>
  800956:	eb 0e                	jmp    800966 <strfind+0x27>
  800958:	38 ca                	cmp    %cl,%dl
  80095a:	74 0a                	je     800966 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80095c:	83 c0 01             	add    $0x1,%eax
  80095f:	0f b6 10             	movzbl (%eax),%edx
  800962:	84 d2                	test   %dl,%dl
  800964:	75 f2                	jne    800958 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800966:	5b                   	pop    %ebx
  800967:	5d                   	pop    %ebp
  800968:	c3                   	ret    

00800969 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800969:	55                   	push   %ebp
  80096a:	89 e5                	mov    %esp,%ebp
  80096c:	57                   	push   %edi
  80096d:	56                   	push   %esi
  80096e:	53                   	push   %ebx
  80096f:	8b 7d 08             	mov    0x8(%ebp),%edi
  800972:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800975:	85 c9                	test   %ecx,%ecx
  800977:	74 36                	je     8009af <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800979:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80097f:	75 28                	jne    8009a9 <memset+0x40>
  800981:	f6 c1 03             	test   $0x3,%cl
  800984:	75 23                	jne    8009a9 <memset+0x40>
		c &= 0xFF;
  800986:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80098a:	89 d3                	mov    %edx,%ebx
  80098c:	c1 e3 08             	shl    $0x8,%ebx
  80098f:	89 d6                	mov    %edx,%esi
  800991:	c1 e6 18             	shl    $0x18,%esi
  800994:	89 d0                	mov    %edx,%eax
  800996:	c1 e0 10             	shl    $0x10,%eax
  800999:	09 f0                	or     %esi,%eax
  80099b:	09 c2                	or     %eax,%edx
  80099d:	89 d0                	mov    %edx,%eax
  80099f:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009a1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009a4:	fc                   	cld    
  8009a5:	f3 ab                	rep stos %eax,%es:(%edi)
  8009a7:	eb 06                	jmp    8009af <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ac:	fc                   	cld    
  8009ad:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009af:	89 f8                	mov    %edi,%eax
  8009b1:	5b                   	pop    %ebx
  8009b2:	5e                   	pop    %esi
  8009b3:	5f                   	pop    %edi
  8009b4:	5d                   	pop    %ebp
  8009b5:	c3                   	ret    

008009b6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009b6:	55                   	push   %ebp
  8009b7:	89 e5                	mov    %esp,%ebp
  8009b9:	57                   	push   %edi
  8009ba:	56                   	push   %esi
  8009bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8009be:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c4:	39 c6                	cmp    %eax,%esi
  8009c6:	73 35                	jae    8009fd <memmove+0x47>
  8009c8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009cb:	39 d0                	cmp    %edx,%eax
  8009cd:	73 2e                	jae    8009fd <memmove+0x47>
		s += n;
		d += n;
  8009cf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  8009d2:	89 d6                	mov    %edx,%esi
  8009d4:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d6:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009dc:	75 13                	jne    8009f1 <memmove+0x3b>
  8009de:	f6 c1 03             	test   $0x3,%cl
  8009e1:	75 0e                	jne    8009f1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8009e3:	83 ef 04             	sub    $0x4,%edi
  8009e6:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009e9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  8009ec:	fd                   	std    
  8009ed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009ef:	eb 09                	jmp    8009fa <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  8009f1:	83 ef 01             	sub    $0x1,%edi
  8009f4:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f7:	fd                   	std    
  8009f8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009fa:	fc                   	cld    
  8009fb:	eb 1d                	jmp    800a1a <memmove+0x64>
  8009fd:	89 f2                	mov    %esi,%edx
  8009ff:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a01:	f6 c2 03             	test   $0x3,%dl
  800a04:	75 0f                	jne    800a15 <memmove+0x5f>
  800a06:	f6 c1 03             	test   $0x3,%cl
  800a09:	75 0a                	jne    800a15 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a0b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a0e:	89 c7                	mov    %eax,%edi
  800a10:	fc                   	cld    
  800a11:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a13:	eb 05                	jmp    800a1a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a15:	89 c7                	mov    %eax,%edi
  800a17:	fc                   	cld    
  800a18:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a1a:	5e                   	pop    %esi
  800a1b:	5f                   	pop    %edi
  800a1c:	5d                   	pop    %ebp
  800a1d:	c3                   	ret    

00800a1e <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800a1e:	55                   	push   %ebp
  800a1f:	89 e5                	mov    %esp,%ebp
  800a21:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a24:	8b 45 10             	mov    0x10(%ebp),%eax
  800a27:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a2b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a2e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a32:	8b 45 08             	mov    0x8(%ebp),%eax
  800a35:	89 04 24             	mov    %eax,(%esp)
  800a38:	e8 79 ff ff ff       	call   8009b6 <memmove>
}
  800a3d:	c9                   	leave  
  800a3e:	c3                   	ret    

00800a3f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a3f:	55                   	push   %ebp
  800a40:	89 e5                	mov    %esp,%ebp
  800a42:	57                   	push   %edi
  800a43:	56                   	push   %esi
  800a44:	53                   	push   %ebx
  800a45:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a48:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a4b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a4e:	8d 78 ff             	lea    -0x1(%eax),%edi
  800a51:	85 c0                	test   %eax,%eax
  800a53:	74 36                	je     800a8b <memcmp+0x4c>
		if (*s1 != *s2)
  800a55:	0f b6 03             	movzbl (%ebx),%eax
  800a58:	0f b6 0e             	movzbl (%esi),%ecx
  800a5b:	ba 00 00 00 00       	mov    $0x0,%edx
  800a60:	38 c8                	cmp    %cl,%al
  800a62:	74 1c                	je     800a80 <memcmp+0x41>
  800a64:	eb 10                	jmp    800a76 <memcmp+0x37>
  800a66:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800a6b:	83 c2 01             	add    $0x1,%edx
  800a6e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800a72:	38 c8                	cmp    %cl,%al
  800a74:	74 0a                	je     800a80 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800a76:	0f b6 c0             	movzbl %al,%eax
  800a79:	0f b6 c9             	movzbl %cl,%ecx
  800a7c:	29 c8                	sub    %ecx,%eax
  800a7e:	eb 10                	jmp    800a90 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a80:	39 fa                	cmp    %edi,%edx
  800a82:	75 e2                	jne    800a66 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a84:	b8 00 00 00 00       	mov    $0x0,%eax
  800a89:	eb 05                	jmp    800a90 <memcmp+0x51>
  800a8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a90:	5b                   	pop    %ebx
  800a91:	5e                   	pop    %esi
  800a92:	5f                   	pop    %edi
  800a93:	5d                   	pop    %ebp
  800a94:	c3                   	ret    

00800a95 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a95:	55                   	push   %ebp
  800a96:	89 e5                	mov    %esp,%ebp
  800a98:	53                   	push   %ebx
  800a99:	8b 45 08             	mov    0x8(%ebp),%eax
  800a9c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800a9f:	89 c2                	mov    %eax,%edx
  800aa1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800aa4:	39 d0                	cmp    %edx,%eax
  800aa6:	73 13                	jae    800abb <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800aa8:	89 d9                	mov    %ebx,%ecx
  800aaa:	38 18                	cmp    %bl,(%eax)
  800aac:	75 06                	jne    800ab4 <memfind+0x1f>
  800aae:	eb 0b                	jmp    800abb <memfind+0x26>
  800ab0:	38 08                	cmp    %cl,(%eax)
  800ab2:	74 07                	je     800abb <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ab4:	83 c0 01             	add    $0x1,%eax
  800ab7:	39 d0                	cmp    %edx,%eax
  800ab9:	75 f5                	jne    800ab0 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800abb:	5b                   	pop    %ebx
  800abc:	5d                   	pop    %ebp
  800abd:	c3                   	ret    

00800abe <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800abe:	55                   	push   %ebp
  800abf:	89 e5                	mov    %esp,%ebp
  800ac1:	57                   	push   %edi
  800ac2:	56                   	push   %esi
  800ac3:	53                   	push   %ebx
  800ac4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ac7:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aca:	0f b6 0a             	movzbl (%edx),%ecx
  800acd:	80 f9 09             	cmp    $0x9,%cl
  800ad0:	74 05                	je     800ad7 <strtol+0x19>
  800ad2:	80 f9 20             	cmp    $0x20,%cl
  800ad5:	75 10                	jne    800ae7 <strtol+0x29>
		s++;
  800ad7:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ada:	0f b6 0a             	movzbl (%edx),%ecx
  800add:	80 f9 09             	cmp    $0x9,%cl
  800ae0:	74 f5                	je     800ad7 <strtol+0x19>
  800ae2:	80 f9 20             	cmp    $0x20,%cl
  800ae5:	74 f0                	je     800ad7 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ae7:	80 f9 2b             	cmp    $0x2b,%cl
  800aea:	75 0a                	jne    800af6 <strtol+0x38>
		s++;
  800aec:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800aef:	bf 00 00 00 00       	mov    $0x0,%edi
  800af4:	eb 11                	jmp    800b07 <strtol+0x49>
  800af6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800afb:	80 f9 2d             	cmp    $0x2d,%cl
  800afe:	75 07                	jne    800b07 <strtol+0x49>
		s++, neg = 1;
  800b00:	83 c2 01             	add    $0x1,%edx
  800b03:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b07:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b0c:	75 15                	jne    800b23 <strtol+0x65>
  800b0e:	80 3a 30             	cmpb   $0x30,(%edx)
  800b11:	75 10                	jne    800b23 <strtol+0x65>
  800b13:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b17:	75 0a                	jne    800b23 <strtol+0x65>
		s += 2, base = 16;
  800b19:	83 c2 02             	add    $0x2,%edx
  800b1c:	b8 10 00 00 00       	mov    $0x10,%eax
  800b21:	eb 10                	jmp    800b33 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
  800b23:	85 c0                	test   %eax,%eax
  800b25:	75 0c                	jne    800b33 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b27:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b29:	80 3a 30             	cmpb   $0x30,(%edx)
  800b2c:	75 05                	jne    800b33 <strtol+0x75>
		s++, base = 8;
  800b2e:	83 c2 01             	add    $0x1,%edx
  800b31:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b33:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b38:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b3b:	0f b6 0a             	movzbl (%edx),%ecx
  800b3e:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b41:	89 f0                	mov    %esi,%eax
  800b43:	3c 09                	cmp    $0x9,%al
  800b45:	77 08                	ja     800b4f <strtol+0x91>
			dig = *s - '0';
  800b47:	0f be c9             	movsbl %cl,%ecx
  800b4a:	83 e9 30             	sub    $0x30,%ecx
  800b4d:	eb 20                	jmp    800b6f <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
  800b4f:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b52:	89 f0                	mov    %esi,%eax
  800b54:	3c 19                	cmp    $0x19,%al
  800b56:	77 08                	ja     800b60 <strtol+0xa2>
			dig = *s - 'a' + 10;
  800b58:	0f be c9             	movsbl %cl,%ecx
  800b5b:	83 e9 57             	sub    $0x57,%ecx
  800b5e:	eb 0f                	jmp    800b6f <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
  800b60:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b63:	89 f0                	mov    %esi,%eax
  800b65:	3c 19                	cmp    $0x19,%al
  800b67:	77 16                	ja     800b7f <strtol+0xc1>
			dig = *s - 'A' + 10;
  800b69:	0f be c9             	movsbl %cl,%ecx
  800b6c:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b6f:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b72:	7d 0f                	jge    800b83 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800b74:	83 c2 01             	add    $0x1,%edx
  800b77:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800b7b:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800b7d:	eb bc                	jmp    800b3b <strtol+0x7d>
  800b7f:	89 d8                	mov    %ebx,%eax
  800b81:	eb 02                	jmp    800b85 <strtol+0xc7>
  800b83:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800b85:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b89:	74 05                	je     800b90 <strtol+0xd2>
		*endptr = (char *) s;
  800b8b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b8e:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800b90:	f7 d8                	neg    %eax
  800b92:	85 ff                	test   %edi,%edi
  800b94:	0f 44 c3             	cmove  %ebx,%eax
}
  800b97:	5b                   	pop    %ebx
  800b98:	5e                   	pop    %esi
  800b99:	5f                   	pop    %edi
  800b9a:	5d                   	pop    %ebp
  800b9b:	c3                   	ret    

00800b9c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b9c:	55                   	push   %ebp
  800b9d:	89 e5                	mov    %esp,%ebp
  800b9f:	57                   	push   %edi
  800ba0:	56                   	push   %esi
  800ba1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ba2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ba7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800baa:	8b 55 08             	mov    0x8(%ebp),%edx
  800bad:	89 c3                	mov    %eax,%ebx
  800baf:	89 c7                	mov    %eax,%edi
  800bb1:	89 c6                	mov    %eax,%esi
  800bb3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800bb5:	5b                   	pop    %ebx
  800bb6:	5e                   	pop    %esi
  800bb7:	5f                   	pop    %edi
  800bb8:	5d                   	pop    %ebp
  800bb9:	c3                   	ret    

00800bba <sys_cgetc>:

int
sys_cgetc(void)
{
  800bba:	55                   	push   %ebp
  800bbb:	89 e5                	mov    %esp,%ebp
  800bbd:	57                   	push   %edi
  800bbe:	56                   	push   %esi
  800bbf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bc0:	ba 00 00 00 00       	mov    $0x0,%edx
  800bc5:	b8 01 00 00 00       	mov    $0x1,%eax
  800bca:	89 d1                	mov    %edx,%ecx
  800bcc:	89 d3                	mov    %edx,%ebx
  800bce:	89 d7                	mov    %edx,%edi
  800bd0:	89 d6                	mov    %edx,%esi
  800bd2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800bd4:	5b                   	pop    %ebx
  800bd5:	5e                   	pop    %esi
  800bd6:	5f                   	pop    %edi
  800bd7:	5d                   	pop    %ebp
  800bd8:	c3                   	ret    

00800bd9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800bd9:	55                   	push   %ebp
  800bda:	89 e5                	mov    %esp,%ebp
  800bdc:	57                   	push   %edi
  800bdd:	56                   	push   %esi
  800bde:	53                   	push   %ebx
  800bdf:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800be2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800be7:	b8 03 00 00 00       	mov    $0x3,%eax
  800bec:	8b 55 08             	mov    0x8(%ebp),%edx
  800bef:	89 cb                	mov    %ecx,%ebx
  800bf1:	89 cf                	mov    %ecx,%edi
  800bf3:	89 ce                	mov    %ecx,%esi
  800bf5:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bf7:	85 c0                	test   %eax,%eax
  800bf9:	7e 28                	jle    800c23 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bfb:	89 44 24 10          	mov    %eax,0x10(%esp)
  800bff:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c06:	00 
  800c07:	c7 44 24 08 74 11 80 	movl   $0x801174,0x8(%esp)
  800c0e:	00 
  800c0f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c16:	00 
  800c17:	c7 04 24 91 11 80 00 	movl   $0x801191,(%esp)
  800c1e:	e8 27 00 00 00       	call   800c4a <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c23:	83 c4 2c             	add    $0x2c,%esp
  800c26:	5b                   	pop    %ebx
  800c27:	5e                   	pop    %esi
  800c28:	5f                   	pop    %edi
  800c29:	5d                   	pop    %ebp
  800c2a:	c3                   	ret    

00800c2b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c2b:	55                   	push   %ebp
  800c2c:	89 e5                	mov    %esp,%ebp
  800c2e:	57                   	push   %edi
  800c2f:	56                   	push   %esi
  800c30:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c31:	ba 00 00 00 00       	mov    $0x0,%edx
  800c36:	b8 02 00 00 00       	mov    $0x2,%eax
  800c3b:	89 d1                	mov    %edx,%ecx
  800c3d:	89 d3                	mov    %edx,%ebx
  800c3f:	89 d7                	mov    %edx,%edi
  800c41:	89 d6                	mov    %edx,%esi
  800c43:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c45:	5b                   	pop    %ebx
  800c46:	5e                   	pop    %esi
  800c47:	5f                   	pop    %edi
  800c48:	5d                   	pop    %ebp
  800c49:	c3                   	ret    

00800c4a <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800c4a:	55                   	push   %ebp
  800c4b:	89 e5                	mov    %esp,%ebp
  800c4d:	56                   	push   %esi
  800c4e:	53                   	push   %ebx
  800c4f:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800c52:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800c55:	a1 08 20 80 00       	mov    0x802008,%eax
  800c5a:	85 c0                	test   %eax,%eax
  800c5c:	74 10                	je     800c6e <_panic+0x24>
		cprintf("%s: ", argv0);
  800c5e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c62:	c7 04 24 9f 11 80 00 	movl   $0x80119f,(%esp)
  800c69:	e8 ee f4 ff ff       	call   80015c <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800c6e:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800c74:	e8 b2 ff ff ff       	call   800c2b <sys_getenvid>
  800c79:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c7c:	89 54 24 10          	mov    %edx,0x10(%esp)
  800c80:	8b 55 08             	mov    0x8(%ebp),%edx
  800c83:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800c87:	89 74 24 08          	mov    %esi,0x8(%esp)
  800c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c8f:	c7 04 24 a4 11 80 00 	movl   $0x8011a4,(%esp)
  800c96:	e8 c1 f4 ff ff       	call   80015c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800c9b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800c9f:	8b 45 10             	mov    0x10(%ebp),%eax
  800ca2:	89 04 24             	mov    %eax,(%esp)
  800ca5:	e8 51 f4 ff ff       	call   8000fb <vcprintf>
	cprintf("\n");
  800caa:	c7 04 24 64 0f 80 00 	movl   $0x800f64,(%esp)
  800cb1:	e8 a6 f4 ff ff       	call   80015c <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800cb6:	cc                   	int3   
  800cb7:	eb fd                	jmp    800cb6 <_panic+0x6c>
  800cb9:	66 90                	xchg   %ax,%ax
  800cbb:	66 90                	xchg   %ax,%ax
  800cbd:	66 90                	xchg   %ax,%ax
  800cbf:	90                   	nop

00800cc0 <__udivdi3>:
  800cc0:	55                   	push   %ebp
  800cc1:	57                   	push   %edi
  800cc2:	56                   	push   %esi
  800cc3:	83 ec 0c             	sub    $0xc,%esp
  800cc6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800cca:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800cce:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800cd2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800cd6:	85 c0                	test   %eax,%eax
  800cd8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800cdc:	89 ea                	mov    %ebp,%edx
  800cde:	89 0c 24             	mov    %ecx,(%esp)
  800ce1:	75 2d                	jne    800d10 <__udivdi3+0x50>
  800ce3:	39 e9                	cmp    %ebp,%ecx
  800ce5:	77 61                	ja     800d48 <__udivdi3+0x88>
  800ce7:	85 c9                	test   %ecx,%ecx
  800ce9:	89 ce                	mov    %ecx,%esi
  800ceb:	75 0b                	jne    800cf8 <__udivdi3+0x38>
  800ced:	b8 01 00 00 00       	mov    $0x1,%eax
  800cf2:	31 d2                	xor    %edx,%edx
  800cf4:	f7 f1                	div    %ecx
  800cf6:	89 c6                	mov    %eax,%esi
  800cf8:	31 d2                	xor    %edx,%edx
  800cfa:	89 e8                	mov    %ebp,%eax
  800cfc:	f7 f6                	div    %esi
  800cfe:	89 c5                	mov    %eax,%ebp
  800d00:	89 f8                	mov    %edi,%eax
  800d02:	f7 f6                	div    %esi
  800d04:	89 ea                	mov    %ebp,%edx
  800d06:	83 c4 0c             	add    $0xc,%esp
  800d09:	5e                   	pop    %esi
  800d0a:	5f                   	pop    %edi
  800d0b:	5d                   	pop    %ebp
  800d0c:	c3                   	ret    
  800d0d:	8d 76 00             	lea    0x0(%esi),%esi
  800d10:	39 e8                	cmp    %ebp,%eax
  800d12:	77 24                	ja     800d38 <__udivdi3+0x78>
  800d14:	0f bd e8             	bsr    %eax,%ebp
  800d17:	83 f5 1f             	xor    $0x1f,%ebp
  800d1a:	75 3c                	jne    800d58 <__udivdi3+0x98>
  800d1c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d20:	39 34 24             	cmp    %esi,(%esp)
  800d23:	0f 86 9f 00 00 00    	jbe    800dc8 <__udivdi3+0x108>
  800d29:	39 d0                	cmp    %edx,%eax
  800d2b:	0f 82 97 00 00 00    	jb     800dc8 <__udivdi3+0x108>
  800d31:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d38:	31 d2                	xor    %edx,%edx
  800d3a:	31 c0                	xor    %eax,%eax
  800d3c:	83 c4 0c             	add    $0xc,%esp
  800d3f:	5e                   	pop    %esi
  800d40:	5f                   	pop    %edi
  800d41:	5d                   	pop    %ebp
  800d42:	c3                   	ret    
  800d43:	90                   	nop
  800d44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d48:	89 f8                	mov    %edi,%eax
  800d4a:	f7 f1                	div    %ecx
  800d4c:	31 d2                	xor    %edx,%edx
  800d4e:	83 c4 0c             	add    $0xc,%esp
  800d51:	5e                   	pop    %esi
  800d52:	5f                   	pop    %edi
  800d53:	5d                   	pop    %ebp
  800d54:	c3                   	ret    
  800d55:	8d 76 00             	lea    0x0(%esi),%esi
  800d58:	89 e9                	mov    %ebp,%ecx
  800d5a:	8b 3c 24             	mov    (%esp),%edi
  800d5d:	d3 e0                	shl    %cl,%eax
  800d5f:	89 c6                	mov    %eax,%esi
  800d61:	b8 20 00 00 00       	mov    $0x20,%eax
  800d66:	29 e8                	sub    %ebp,%eax
  800d68:	89 c1                	mov    %eax,%ecx
  800d6a:	d3 ef                	shr    %cl,%edi
  800d6c:	89 e9                	mov    %ebp,%ecx
  800d6e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d72:	8b 3c 24             	mov    (%esp),%edi
  800d75:	09 74 24 08          	or     %esi,0x8(%esp)
  800d79:	89 d6                	mov    %edx,%esi
  800d7b:	d3 e7                	shl    %cl,%edi
  800d7d:	89 c1                	mov    %eax,%ecx
  800d7f:	89 3c 24             	mov    %edi,(%esp)
  800d82:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d86:	d3 ee                	shr    %cl,%esi
  800d88:	89 e9                	mov    %ebp,%ecx
  800d8a:	d3 e2                	shl    %cl,%edx
  800d8c:	89 c1                	mov    %eax,%ecx
  800d8e:	d3 ef                	shr    %cl,%edi
  800d90:	09 d7                	or     %edx,%edi
  800d92:	89 f2                	mov    %esi,%edx
  800d94:	89 f8                	mov    %edi,%eax
  800d96:	f7 74 24 08          	divl   0x8(%esp)
  800d9a:	89 d6                	mov    %edx,%esi
  800d9c:	89 c7                	mov    %eax,%edi
  800d9e:	f7 24 24             	mull   (%esp)
  800da1:	39 d6                	cmp    %edx,%esi
  800da3:	89 14 24             	mov    %edx,(%esp)
  800da6:	72 30                	jb     800dd8 <__udivdi3+0x118>
  800da8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800dac:	89 e9                	mov    %ebp,%ecx
  800dae:	d3 e2                	shl    %cl,%edx
  800db0:	39 c2                	cmp    %eax,%edx
  800db2:	73 05                	jae    800db9 <__udivdi3+0xf9>
  800db4:	3b 34 24             	cmp    (%esp),%esi
  800db7:	74 1f                	je     800dd8 <__udivdi3+0x118>
  800db9:	89 f8                	mov    %edi,%eax
  800dbb:	31 d2                	xor    %edx,%edx
  800dbd:	e9 7a ff ff ff       	jmp    800d3c <__udivdi3+0x7c>
  800dc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800dc8:	31 d2                	xor    %edx,%edx
  800dca:	b8 01 00 00 00       	mov    $0x1,%eax
  800dcf:	e9 68 ff ff ff       	jmp    800d3c <__udivdi3+0x7c>
  800dd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dd8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800ddb:	31 d2                	xor    %edx,%edx
  800ddd:	83 c4 0c             	add    $0xc,%esp
  800de0:	5e                   	pop    %esi
  800de1:	5f                   	pop    %edi
  800de2:	5d                   	pop    %ebp
  800de3:	c3                   	ret    
  800de4:	66 90                	xchg   %ax,%ax
  800de6:	66 90                	xchg   %ax,%ax
  800de8:	66 90                	xchg   %ax,%ax
  800dea:	66 90                	xchg   %ax,%ax
  800dec:	66 90                	xchg   %ax,%ax
  800dee:	66 90                	xchg   %ax,%ax

00800df0 <__umoddi3>:
  800df0:	55                   	push   %ebp
  800df1:	57                   	push   %edi
  800df2:	56                   	push   %esi
  800df3:	83 ec 14             	sub    $0x14,%esp
  800df6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800dfa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800dfe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800e02:	89 c7                	mov    %eax,%edi
  800e04:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e08:	8b 44 24 30          	mov    0x30(%esp),%eax
  800e0c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800e10:	89 34 24             	mov    %esi,(%esp)
  800e13:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e17:	85 c0                	test   %eax,%eax
  800e19:	89 c2                	mov    %eax,%edx
  800e1b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e1f:	75 17                	jne    800e38 <__umoddi3+0x48>
  800e21:	39 fe                	cmp    %edi,%esi
  800e23:	76 4b                	jbe    800e70 <__umoddi3+0x80>
  800e25:	89 c8                	mov    %ecx,%eax
  800e27:	89 fa                	mov    %edi,%edx
  800e29:	f7 f6                	div    %esi
  800e2b:	89 d0                	mov    %edx,%eax
  800e2d:	31 d2                	xor    %edx,%edx
  800e2f:	83 c4 14             	add    $0x14,%esp
  800e32:	5e                   	pop    %esi
  800e33:	5f                   	pop    %edi
  800e34:	5d                   	pop    %ebp
  800e35:	c3                   	ret    
  800e36:	66 90                	xchg   %ax,%ax
  800e38:	39 f8                	cmp    %edi,%eax
  800e3a:	77 54                	ja     800e90 <__umoddi3+0xa0>
  800e3c:	0f bd e8             	bsr    %eax,%ebp
  800e3f:	83 f5 1f             	xor    $0x1f,%ebp
  800e42:	75 5c                	jne    800ea0 <__umoddi3+0xb0>
  800e44:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e48:	39 3c 24             	cmp    %edi,(%esp)
  800e4b:	0f 87 e7 00 00 00    	ja     800f38 <__umoddi3+0x148>
  800e51:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800e55:	29 f1                	sub    %esi,%ecx
  800e57:	19 c7                	sbb    %eax,%edi
  800e59:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e5d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e61:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e65:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e69:	83 c4 14             	add    $0x14,%esp
  800e6c:	5e                   	pop    %esi
  800e6d:	5f                   	pop    %edi
  800e6e:	5d                   	pop    %ebp
  800e6f:	c3                   	ret    
  800e70:	85 f6                	test   %esi,%esi
  800e72:	89 f5                	mov    %esi,%ebp
  800e74:	75 0b                	jne    800e81 <__umoddi3+0x91>
  800e76:	b8 01 00 00 00       	mov    $0x1,%eax
  800e7b:	31 d2                	xor    %edx,%edx
  800e7d:	f7 f6                	div    %esi
  800e7f:	89 c5                	mov    %eax,%ebp
  800e81:	8b 44 24 04          	mov    0x4(%esp),%eax
  800e85:	31 d2                	xor    %edx,%edx
  800e87:	f7 f5                	div    %ebp
  800e89:	89 c8                	mov    %ecx,%eax
  800e8b:	f7 f5                	div    %ebp
  800e8d:	eb 9c                	jmp    800e2b <__umoddi3+0x3b>
  800e8f:	90                   	nop
  800e90:	89 c8                	mov    %ecx,%eax
  800e92:	89 fa                	mov    %edi,%edx
  800e94:	83 c4 14             	add    $0x14,%esp
  800e97:	5e                   	pop    %esi
  800e98:	5f                   	pop    %edi
  800e99:	5d                   	pop    %ebp
  800e9a:	c3                   	ret    
  800e9b:	90                   	nop
  800e9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ea0:	8b 04 24             	mov    (%esp),%eax
  800ea3:	be 20 00 00 00       	mov    $0x20,%esi
  800ea8:	89 e9                	mov    %ebp,%ecx
  800eaa:	29 ee                	sub    %ebp,%esi
  800eac:	d3 e2                	shl    %cl,%edx
  800eae:	89 f1                	mov    %esi,%ecx
  800eb0:	d3 e8                	shr    %cl,%eax
  800eb2:	89 e9                	mov    %ebp,%ecx
  800eb4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800eb8:	8b 04 24             	mov    (%esp),%eax
  800ebb:	09 54 24 04          	or     %edx,0x4(%esp)
  800ebf:	89 fa                	mov    %edi,%edx
  800ec1:	d3 e0                	shl    %cl,%eax
  800ec3:	89 f1                	mov    %esi,%ecx
  800ec5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ec9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ecd:	d3 ea                	shr    %cl,%edx
  800ecf:	89 e9                	mov    %ebp,%ecx
  800ed1:	d3 e7                	shl    %cl,%edi
  800ed3:	89 f1                	mov    %esi,%ecx
  800ed5:	d3 e8                	shr    %cl,%eax
  800ed7:	89 e9                	mov    %ebp,%ecx
  800ed9:	09 f8                	or     %edi,%eax
  800edb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800edf:	f7 74 24 04          	divl   0x4(%esp)
  800ee3:	d3 e7                	shl    %cl,%edi
  800ee5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ee9:	89 d7                	mov    %edx,%edi
  800eeb:	f7 64 24 08          	mull   0x8(%esp)
  800eef:	39 d7                	cmp    %edx,%edi
  800ef1:	89 c1                	mov    %eax,%ecx
  800ef3:	89 14 24             	mov    %edx,(%esp)
  800ef6:	72 2c                	jb     800f24 <__umoddi3+0x134>
  800ef8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800efc:	72 22                	jb     800f20 <__umoddi3+0x130>
  800efe:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f02:	29 c8                	sub    %ecx,%eax
  800f04:	19 d7                	sbb    %edx,%edi
  800f06:	89 e9                	mov    %ebp,%ecx
  800f08:	89 fa                	mov    %edi,%edx
  800f0a:	d3 e8                	shr    %cl,%eax
  800f0c:	89 f1                	mov    %esi,%ecx
  800f0e:	d3 e2                	shl    %cl,%edx
  800f10:	89 e9                	mov    %ebp,%ecx
  800f12:	d3 ef                	shr    %cl,%edi
  800f14:	09 d0                	or     %edx,%eax
  800f16:	89 fa                	mov    %edi,%edx
  800f18:	83 c4 14             	add    $0x14,%esp
  800f1b:	5e                   	pop    %esi
  800f1c:	5f                   	pop    %edi
  800f1d:	5d                   	pop    %ebp
  800f1e:	c3                   	ret    
  800f1f:	90                   	nop
  800f20:	39 d7                	cmp    %edx,%edi
  800f22:	75 da                	jne    800efe <__umoddi3+0x10e>
  800f24:	8b 14 24             	mov    (%esp),%edx
  800f27:	89 c1                	mov    %eax,%ecx
  800f29:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800f2d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800f31:	eb cb                	jmp    800efe <__umoddi3+0x10e>
  800f33:	90                   	nop
  800f34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f38:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800f3c:	0f 82 0f ff ff ff    	jb     800e51 <__umoddi3+0x61>
  800f42:	e9 1a ff ff ff       	jmp    800e61 <__umoddi3+0x71>
