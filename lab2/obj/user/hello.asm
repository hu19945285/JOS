
obj/user/hello:     file format elf32-i386


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
  80002c:	e8 2e 00 00 00       	call   80005f <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("hello, world\n");
  800039:	c7 04 24 58 0f 80 00 	movl   $0x800f58,(%esp)
  800040:	e8 26 01 00 00       	call   80016b <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800045:	a1 04 20 80 00       	mov    0x802004,%eax
  80004a:	8b 40 48             	mov    0x48(%eax),%eax
  80004d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800051:	c7 04 24 66 0f 80 00 	movl   $0x800f66,(%esp)
  800058:	e8 0e 01 00 00       	call   80016b <cprintf>
}
  80005d:	c9                   	leave  
  80005e:	c3                   	ret    

0080005f <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005f:	55                   	push   %ebp
  800060:	89 e5                	mov    %esp,%ebp
  800062:	56                   	push   %esi
  800063:	53                   	push   %ebx
  800064:	83 ec 10             	sub    $0x10,%esp
  800067:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80006a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006d:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800074:	00 00 00 
	//thisenv=envs+ENVX(sys_getenvid());
	int index=sys_getenvid();
  800077:	e8 bf 0b 00 00       	call   800c3b <sys_getenvid>
        thisenv=&envs[ENVX(index)];
  80007c:	25 ff 03 00 00       	and    $0x3ff,%eax
  800081:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800084:	c1 e0 05             	shl    $0x5,%eax
  800087:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80008c:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800091:	85 db                	test   %ebx,%ebx
  800093:	7e 07                	jle    80009c <libmain+0x3d>
		binaryname = argv[0];
  800095:	8b 06                	mov    (%esi),%eax
  800097:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80009c:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000a0:	89 1c 24             	mov    %ebx,(%esp)
  8000a3:	e8 8b ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000a8:	e8 07 00 00 00       	call   8000b4 <exit>
}
  8000ad:	83 c4 10             	add    $0x10,%esp
  8000b0:	5b                   	pop    %ebx
  8000b1:	5e                   	pop    %esi
  8000b2:	5d                   	pop    %ebp
  8000b3:	c3                   	ret    

008000b4 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000b4:	55                   	push   %ebp
  8000b5:	89 e5                	mov    %esp,%ebp
  8000b7:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000c1:	e8 23 0b 00 00       	call   800be9 <sys_env_destroy>
}
  8000c6:	c9                   	leave  
  8000c7:	c3                   	ret    

008000c8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000c8:	55                   	push   %ebp
  8000c9:	89 e5                	mov    %esp,%ebp
  8000cb:	53                   	push   %ebx
  8000cc:	83 ec 14             	sub    $0x14,%esp
  8000cf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000d2:	8b 13                	mov    (%ebx),%edx
  8000d4:	8d 42 01             	lea    0x1(%edx),%eax
  8000d7:	89 03                	mov    %eax,(%ebx)
  8000d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000dc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000e0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000e5:	75 19                	jne    800100 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000e7:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000ee:	00 
  8000ef:	8d 43 08             	lea    0x8(%ebx),%eax
  8000f2:	89 04 24             	mov    %eax,(%esp)
  8000f5:	e8 b2 0a 00 00       	call   800bac <sys_cputs>
		b->idx = 0;
  8000fa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800100:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800104:	83 c4 14             	add    $0x14,%esp
  800107:	5b                   	pop    %ebx
  800108:	5d                   	pop    %ebp
  800109:	c3                   	ret    

0080010a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80010a:	55                   	push   %ebp
  80010b:	89 e5                	mov    %esp,%ebp
  80010d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800113:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80011a:	00 00 00 
	b.cnt = 0;
  80011d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800124:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800127:	8b 45 0c             	mov    0xc(%ebp),%eax
  80012a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80012e:	8b 45 08             	mov    0x8(%ebp),%eax
  800131:	89 44 24 08          	mov    %eax,0x8(%esp)
  800135:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80013b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80013f:	c7 04 24 c8 00 80 00 	movl   $0x8000c8,(%esp)
  800146:	e8 b9 01 00 00       	call   800304 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80014b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800151:	89 44 24 04          	mov    %eax,0x4(%esp)
  800155:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80015b:	89 04 24             	mov    %eax,(%esp)
  80015e:	e8 49 0a 00 00       	call   800bac <sys_cputs>

	return b.cnt;
}
  800163:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800169:	c9                   	leave  
  80016a:	c3                   	ret    

0080016b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80016b:	55                   	push   %ebp
  80016c:	89 e5                	mov    %esp,%ebp
  80016e:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800171:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800174:	89 44 24 04          	mov    %eax,0x4(%esp)
  800178:	8b 45 08             	mov    0x8(%ebp),%eax
  80017b:	89 04 24             	mov    %eax,(%esp)
  80017e:	e8 87 ff ff ff       	call   80010a <vcprintf>
	va_end(ap);

	return cnt;
}
  800183:	c9                   	leave  
  800184:	c3                   	ret    
  800185:	66 90                	xchg   %ax,%ax
  800187:	66 90                	xchg   %ax,%ax
  800189:	66 90                	xchg   %ax,%ax
  80018b:	66 90                	xchg   %ax,%ax
  80018d:	66 90                	xchg   %ax,%ax
  80018f:	90                   	nop

00800190 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800190:	55                   	push   %ebp
  800191:	89 e5                	mov    %esp,%ebp
  800193:	57                   	push   %edi
  800194:	56                   	push   %esi
  800195:	53                   	push   %ebx
  800196:	83 ec 3c             	sub    $0x3c,%esp
  800199:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80019c:	89 d7                	mov    %edx,%edi
  80019e:	8b 45 08             	mov    0x8(%ebp),%eax
  8001a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001a4:	8b 75 0c             	mov    0xc(%ebp),%esi
  8001a7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
  8001aa:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001ad:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001b2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001b5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8001b8:	39 f1                	cmp    %esi,%ecx
  8001ba:	72 14                	jb     8001d0 <printnum+0x40>
  8001bc:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001bf:	76 0f                	jbe    8001d0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8001c4:	8d 70 ff             	lea    -0x1(%eax),%esi
  8001c7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8001ca:	85 f6                	test   %esi,%esi
  8001cc:	7f 60                	jg     80022e <printnum+0x9e>
  8001ce:	eb 72                	jmp    800242 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001d0:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001d3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001d7:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8001da:	8d 51 ff             	lea    -0x1(%ecx),%edx
  8001dd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001e1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001e5:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001e9:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001ed:	89 c3                	mov    %eax,%ebx
  8001ef:	89 d6                	mov    %edx,%esi
  8001f1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001f4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001f7:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001fb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800202:	89 04 24             	mov    %eax,(%esp)
  800205:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800208:	89 44 24 04          	mov    %eax,0x4(%esp)
  80020c:	e8 bf 0a 00 00       	call   800cd0 <__udivdi3>
  800211:	89 d9                	mov    %ebx,%ecx
  800213:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800217:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80021b:	89 04 24             	mov    %eax,(%esp)
  80021e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800222:	89 fa                	mov    %edi,%edx
  800224:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800227:	e8 64 ff ff ff       	call   800190 <printnum>
  80022c:	eb 14                	jmp    800242 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80022e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800232:	8b 45 18             	mov    0x18(%ebp),%eax
  800235:	89 04 24             	mov    %eax,(%esp)
  800238:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80023a:	83 ee 01             	sub    $0x1,%esi
  80023d:	75 ef                	jne    80022e <printnum+0x9e>
  80023f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800242:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800246:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80024a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80024d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800250:	89 44 24 08          	mov    %eax,0x8(%esp)
  800254:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800258:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80025b:	89 04 24             	mov    %eax,(%esp)
  80025e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800261:	89 44 24 04          	mov    %eax,0x4(%esp)
  800265:	e8 96 0b 00 00       	call   800e00 <__umoddi3>
  80026a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80026e:	0f be 80 87 0f 80 00 	movsbl 0x800f87(%eax),%eax
  800275:	89 04 24             	mov    %eax,(%esp)
  800278:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80027b:	ff d0                	call   *%eax
}
  80027d:	83 c4 3c             	add    $0x3c,%esp
  800280:	5b                   	pop    %ebx
  800281:	5e                   	pop    %esi
  800282:	5f                   	pop    %edi
  800283:	5d                   	pop    %ebp
  800284:	c3                   	ret    

00800285 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800285:	55                   	push   %ebp
  800286:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800288:	83 fa 01             	cmp    $0x1,%edx
  80028b:	7e 0e                	jle    80029b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80028d:	8b 10                	mov    (%eax),%edx
  80028f:	8d 4a 08             	lea    0x8(%edx),%ecx
  800292:	89 08                	mov    %ecx,(%eax)
  800294:	8b 02                	mov    (%edx),%eax
  800296:	8b 52 04             	mov    0x4(%edx),%edx
  800299:	eb 22                	jmp    8002bd <getuint+0x38>
	else if (lflag)
  80029b:	85 d2                	test   %edx,%edx
  80029d:	74 10                	je     8002af <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80029f:	8b 10                	mov    (%eax),%edx
  8002a1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002a4:	89 08                	mov    %ecx,(%eax)
  8002a6:	8b 02                	mov    (%edx),%eax
  8002a8:	ba 00 00 00 00       	mov    $0x0,%edx
  8002ad:	eb 0e                	jmp    8002bd <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002af:	8b 10                	mov    (%eax),%edx
  8002b1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002b4:	89 08                	mov    %ecx,(%eax)
  8002b6:	8b 02                	mov    (%edx),%eax
  8002b8:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002bd:	5d                   	pop    %ebp
  8002be:	c3                   	ret    

008002bf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002bf:	55                   	push   %ebp
  8002c0:	89 e5                	mov    %esp,%ebp
  8002c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002c9:	8b 10                	mov    (%eax),%edx
  8002cb:	3b 50 04             	cmp    0x4(%eax),%edx
  8002ce:	73 0a                	jae    8002da <sprintputch+0x1b>
		*b->buf++ = ch;
  8002d0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002d3:	89 08                	mov    %ecx,(%eax)
  8002d5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d8:	88 02                	mov    %al,(%edx)
}
  8002da:	5d                   	pop    %ebp
  8002db:	c3                   	ret    

008002dc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002dc:	55                   	push   %ebp
  8002dd:	89 e5                	mov    %esp,%ebp
  8002df:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002e2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002e9:	8b 45 10             	mov    0x10(%ebp),%eax
  8002ec:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8002fa:	89 04 24             	mov    %eax,(%esp)
  8002fd:	e8 02 00 00 00       	call   800304 <vprintfmt>
	va_end(ap);
}
  800302:	c9                   	leave  
  800303:	c3                   	ret    

00800304 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800304:	55                   	push   %ebp
  800305:	89 e5                	mov    %esp,%ebp
  800307:	57                   	push   %edi
  800308:	56                   	push   %esi
  800309:	53                   	push   %ebx
  80030a:	83 ec 3c             	sub    $0x3c,%esp
  80030d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800310:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800313:	eb 18                	jmp    80032d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800315:	85 c0                	test   %eax,%eax
  800317:	0f 84 c3 03 00 00    	je     8006e0 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
  80031d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800321:	89 04 24             	mov    %eax,(%esp)
  800324:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800327:	89 f3                	mov    %esi,%ebx
  800329:	eb 02                	jmp    80032d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
  80032b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80032d:	8d 73 01             	lea    0x1(%ebx),%esi
  800330:	0f b6 03             	movzbl (%ebx),%eax
  800333:	83 f8 25             	cmp    $0x25,%eax
  800336:	75 dd                	jne    800315 <vprintfmt+0x11>
  800338:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
  80033c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800343:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  80034a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800351:	ba 00 00 00 00       	mov    $0x0,%edx
  800356:	eb 1d                	jmp    800375 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800358:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80035a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
  80035e:	eb 15                	jmp    800375 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800360:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800362:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
  800366:	eb 0d                	jmp    800375 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800368:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80036b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80036e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800375:	8d 5e 01             	lea    0x1(%esi),%ebx
  800378:	0f b6 06             	movzbl (%esi),%eax
  80037b:	0f b6 c8             	movzbl %al,%ecx
  80037e:	83 e8 23             	sub    $0x23,%eax
  800381:	3c 55                	cmp    $0x55,%al
  800383:	0f 87 2f 03 00 00    	ja     8006b8 <vprintfmt+0x3b4>
  800389:	0f b6 c0             	movzbl %al,%eax
  80038c:	ff 24 85 14 10 80 00 	jmp    *0x801014(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800393:	8d 41 d0             	lea    -0x30(%ecx),%eax
  800396:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
  800399:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
  80039d:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8003a0:	83 f9 09             	cmp    $0x9,%ecx
  8003a3:	77 50                	ja     8003f5 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a5:	89 de                	mov    %ebx,%esi
  8003a7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003aa:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
  8003ad:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8003b0:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8003b4:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8003b7:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8003ba:	83 fb 09             	cmp    $0x9,%ebx
  8003bd:	76 eb                	jbe    8003aa <vprintfmt+0xa6>
  8003bf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8003c2:	eb 33                	jmp    8003f7 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c7:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ca:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003cd:	8b 00                	mov    (%eax),%eax
  8003cf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d2:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003d4:	eb 21                	jmp    8003f7 <vprintfmt+0xf3>
  8003d6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003d9:	85 c9                	test   %ecx,%ecx
  8003db:	b8 00 00 00 00       	mov    $0x0,%eax
  8003e0:	0f 49 c1             	cmovns %ecx,%eax
  8003e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e6:	89 de                	mov    %ebx,%esi
  8003e8:	eb 8b                	jmp    800375 <vprintfmt+0x71>
  8003ea:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003ec:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003f3:	eb 80                	jmp    800375 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f5:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8003f7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8003fb:	0f 89 74 ff ff ff    	jns    800375 <vprintfmt+0x71>
  800401:	e9 62 ff ff ff       	jmp    800368 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800406:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800409:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80040b:	e9 65 ff ff ff       	jmp    800375 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800410:	8b 45 14             	mov    0x14(%ebp),%eax
  800413:	8d 50 04             	lea    0x4(%eax),%edx
  800416:	89 55 14             	mov    %edx,0x14(%ebp)
  800419:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80041d:	8b 00                	mov    (%eax),%eax
  80041f:	89 04 24             	mov    %eax,(%esp)
  800422:	ff 55 08             	call   *0x8(%ebp)
			break;
  800425:	e9 03 ff ff ff       	jmp    80032d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80042a:	8b 45 14             	mov    0x14(%ebp),%eax
  80042d:	8d 50 04             	lea    0x4(%eax),%edx
  800430:	89 55 14             	mov    %edx,0x14(%ebp)
  800433:	8b 00                	mov    (%eax),%eax
  800435:	99                   	cltd   
  800436:	31 d0                	xor    %edx,%eax
  800438:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80043a:	83 f8 06             	cmp    $0x6,%eax
  80043d:	7f 0b                	jg     80044a <vprintfmt+0x146>
  80043f:	8b 14 85 6c 11 80 00 	mov    0x80116c(,%eax,4),%edx
  800446:	85 d2                	test   %edx,%edx
  800448:	75 20                	jne    80046a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
  80044a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80044e:	c7 44 24 08 9f 0f 80 	movl   $0x800f9f,0x8(%esp)
  800455:	00 
  800456:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80045a:	8b 45 08             	mov    0x8(%ebp),%eax
  80045d:	89 04 24             	mov    %eax,(%esp)
  800460:	e8 77 fe ff ff       	call   8002dc <printfmt>
  800465:	e9 c3 fe ff ff       	jmp    80032d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
  80046a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80046e:	c7 44 24 08 a8 0f 80 	movl   $0x800fa8,0x8(%esp)
  800475:	00 
  800476:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80047a:	8b 45 08             	mov    0x8(%ebp),%eax
  80047d:	89 04 24             	mov    %eax,(%esp)
  800480:	e8 57 fe ff ff       	call   8002dc <printfmt>
  800485:	e9 a3 fe ff ff       	jmp    80032d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80048d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800490:	8b 45 14             	mov    0x14(%ebp),%eax
  800493:	8d 50 04             	lea    0x4(%eax),%edx
  800496:	89 55 14             	mov    %edx,0x14(%ebp)
  800499:	8b 00                	mov    (%eax),%eax
				p = "(null)";
  80049b:	85 c0                	test   %eax,%eax
  80049d:	ba 98 0f 80 00       	mov    $0x800f98,%edx
  8004a2:	0f 45 d0             	cmovne %eax,%edx
  8004a5:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
  8004a8:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
  8004ac:	74 04                	je     8004b2 <vprintfmt+0x1ae>
  8004ae:	85 f6                	test   %esi,%esi
  8004b0:	7f 19                	jg     8004cb <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004b2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8004b5:	8d 70 01             	lea    0x1(%eax),%esi
  8004b8:	0f b6 10             	movzbl (%eax),%edx
  8004bb:	0f be c2             	movsbl %dl,%eax
  8004be:	85 c0                	test   %eax,%eax
  8004c0:	0f 85 95 00 00 00    	jne    80055b <vprintfmt+0x257>
  8004c6:	e9 85 00 00 00       	jmp    800550 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004cf:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8004d2:	89 04 24             	mov    %eax,(%esp)
  8004d5:	e8 b8 02 00 00       	call   800792 <strnlen>
  8004da:	29 c6                	sub    %eax,%esi
  8004dc:	89 f0                	mov    %esi,%eax
  8004de:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8004e1:	85 f6                	test   %esi,%esi
  8004e3:	7e cd                	jle    8004b2 <vprintfmt+0x1ae>
					putch(padc, putdat);
  8004e5:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  8004e9:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8004ec:	89 c3                	mov    %eax,%ebx
  8004ee:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004f2:	89 34 24             	mov    %esi,(%esp)
  8004f5:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f8:	83 eb 01             	sub    $0x1,%ebx
  8004fb:	75 f1                	jne    8004ee <vprintfmt+0x1ea>
  8004fd:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800500:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800503:	eb ad                	jmp    8004b2 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800505:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800509:	74 1e                	je     800529 <vprintfmt+0x225>
  80050b:	0f be d2             	movsbl %dl,%edx
  80050e:	83 ea 20             	sub    $0x20,%edx
  800511:	83 fa 5e             	cmp    $0x5e,%edx
  800514:	76 13                	jbe    800529 <vprintfmt+0x225>
					putch('?', putdat);
  800516:	8b 45 0c             	mov    0xc(%ebp),%eax
  800519:	89 44 24 04          	mov    %eax,0x4(%esp)
  80051d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800524:	ff 55 08             	call   *0x8(%ebp)
  800527:	eb 0d                	jmp    800536 <vprintfmt+0x232>
				else
					putch(ch, putdat);
  800529:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80052c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800530:	89 04 24             	mov    %eax,(%esp)
  800533:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800536:	83 ef 01             	sub    $0x1,%edi
  800539:	83 c6 01             	add    $0x1,%esi
  80053c:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800540:	0f be c2             	movsbl %dl,%eax
  800543:	85 c0                	test   %eax,%eax
  800545:	75 20                	jne    800567 <vprintfmt+0x263>
  800547:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  80054a:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80054d:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800550:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800554:	7f 25                	jg     80057b <vprintfmt+0x277>
  800556:	e9 d2 fd ff ff       	jmp    80032d <vprintfmt+0x29>
  80055b:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80055e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800561:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800564:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800567:	85 db                	test   %ebx,%ebx
  800569:	78 9a                	js     800505 <vprintfmt+0x201>
  80056b:	83 eb 01             	sub    $0x1,%ebx
  80056e:	79 95                	jns    800505 <vprintfmt+0x201>
  800570:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  800573:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800576:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800579:	eb d5                	jmp    800550 <vprintfmt+0x24c>
  80057b:	8b 75 08             	mov    0x8(%ebp),%esi
  80057e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800581:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800584:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800588:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80058f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800591:	83 eb 01             	sub    $0x1,%ebx
  800594:	75 ee                	jne    800584 <vprintfmt+0x280>
  800596:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800599:	e9 8f fd ff ff       	jmp    80032d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80059e:	83 fa 01             	cmp    $0x1,%edx
  8005a1:	7e 16                	jle    8005b9 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
  8005a3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a6:	8d 50 08             	lea    0x8(%eax),%edx
  8005a9:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ac:	8b 50 04             	mov    0x4(%eax),%edx
  8005af:	8b 00                	mov    (%eax),%eax
  8005b1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005b4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005b7:	eb 32                	jmp    8005eb <vprintfmt+0x2e7>
	else if (lflag)
  8005b9:	85 d2                	test   %edx,%edx
  8005bb:	74 18                	je     8005d5 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
  8005bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c0:	8d 50 04             	lea    0x4(%eax),%edx
  8005c3:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c6:	8b 30                	mov    (%eax),%esi
  8005c8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8005cb:	89 f0                	mov    %esi,%eax
  8005cd:	c1 f8 1f             	sar    $0x1f,%eax
  8005d0:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8005d3:	eb 16                	jmp    8005eb <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
  8005d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d8:	8d 50 04             	lea    0x4(%eax),%edx
  8005db:	89 55 14             	mov    %edx,0x14(%ebp)
  8005de:	8b 30                	mov    (%eax),%esi
  8005e0:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8005e3:	89 f0                	mov    %esi,%eax
  8005e5:	c1 f8 1f             	sar    $0x1f,%eax
  8005e8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005eb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8005ee:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005f1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005fa:	0f 89 80 00 00 00    	jns    800680 <vprintfmt+0x37c>
				putch('-', putdat);
  800600:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800604:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80060b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  80060e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800611:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800614:	f7 d8                	neg    %eax
  800616:	83 d2 00             	adc    $0x0,%edx
  800619:	f7 da                	neg    %edx
			}
			base = 10;
  80061b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800620:	eb 5e                	jmp    800680 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800622:	8d 45 14             	lea    0x14(%ebp),%eax
  800625:	e8 5b fc ff ff       	call   800285 <getuint>
			base = 10;
  80062a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80062f:	eb 4f                	jmp    800680 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
  800631:	8d 45 14             	lea    0x14(%ebp),%eax
  800634:	e8 4c fc ff ff       	call   800285 <getuint>
			base = 8;
  800639:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80063e:	eb 40                	jmp    800680 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
  800640:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800644:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80064b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  80064e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800652:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800659:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80065c:	8b 45 14             	mov    0x14(%ebp),%eax
  80065f:	8d 50 04             	lea    0x4(%eax),%edx
  800662:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800665:	8b 00                	mov    (%eax),%eax
  800667:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80066c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800671:	eb 0d                	jmp    800680 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800673:	8d 45 14             	lea    0x14(%ebp),%eax
  800676:	e8 0a fc ff ff       	call   800285 <getuint>
			base = 16;
  80067b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800680:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  800684:	89 74 24 10          	mov    %esi,0x10(%esp)
  800688:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80068b:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80068f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800693:	89 04 24             	mov    %eax,(%esp)
  800696:	89 54 24 04          	mov    %edx,0x4(%esp)
  80069a:	89 fa                	mov    %edi,%edx
  80069c:	8b 45 08             	mov    0x8(%ebp),%eax
  80069f:	e8 ec fa ff ff       	call   800190 <printnum>
			break;
  8006a4:	e9 84 fc ff ff       	jmp    80032d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006a9:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006ad:	89 0c 24             	mov    %ecx,(%esp)
  8006b0:	ff 55 08             	call   *0x8(%ebp)
			break;
  8006b3:	e9 75 fc ff ff       	jmp    80032d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006bc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006c3:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006c6:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  8006ca:	0f 84 5b fc ff ff    	je     80032b <vprintfmt+0x27>
  8006d0:	89 f3                	mov    %esi,%ebx
  8006d2:	83 eb 01             	sub    $0x1,%ebx
  8006d5:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8006d9:	75 f7                	jne    8006d2 <vprintfmt+0x3ce>
  8006db:	e9 4d fc ff ff       	jmp    80032d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
  8006e0:	83 c4 3c             	add    $0x3c,%esp
  8006e3:	5b                   	pop    %ebx
  8006e4:	5e                   	pop    %esi
  8006e5:	5f                   	pop    %edi
  8006e6:	5d                   	pop    %ebp
  8006e7:	c3                   	ret    

008006e8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006e8:	55                   	push   %ebp
  8006e9:	89 e5                	mov    %esp,%ebp
  8006eb:	83 ec 28             	sub    $0x28,%esp
  8006ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006f4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006f7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006fb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800705:	85 c0                	test   %eax,%eax
  800707:	74 30                	je     800739 <vsnprintf+0x51>
  800709:	85 d2                	test   %edx,%edx
  80070b:	7e 2c                	jle    800739 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80070d:	8b 45 14             	mov    0x14(%ebp),%eax
  800710:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800714:	8b 45 10             	mov    0x10(%ebp),%eax
  800717:	89 44 24 08          	mov    %eax,0x8(%esp)
  80071b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80071e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800722:	c7 04 24 bf 02 80 00 	movl   $0x8002bf,(%esp)
  800729:	e8 d6 fb ff ff       	call   800304 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80072e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800731:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800734:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800737:	eb 05                	jmp    80073e <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800739:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80073e:	c9                   	leave  
  80073f:	c3                   	ret    

00800740 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800740:	55                   	push   %ebp
  800741:	89 e5                	mov    %esp,%ebp
  800743:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800746:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800749:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80074d:	8b 45 10             	mov    0x10(%ebp),%eax
  800750:	89 44 24 08          	mov    %eax,0x8(%esp)
  800754:	8b 45 0c             	mov    0xc(%ebp),%eax
  800757:	89 44 24 04          	mov    %eax,0x4(%esp)
  80075b:	8b 45 08             	mov    0x8(%ebp),%eax
  80075e:	89 04 24             	mov    %eax,(%esp)
  800761:	e8 82 ff ff ff       	call   8006e8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800766:	c9                   	leave  
  800767:	c3                   	ret    
  800768:	66 90                	xchg   %ax,%ax
  80076a:	66 90                	xchg   %ax,%ax
  80076c:	66 90                	xchg   %ax,%ax
  80076e:	66 90                	xchg   %ax,%ax

00800770 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800770:	55                   	push   %ebp
  800771:	89 e5                	mov    %esp,%ebp
  800773:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800776:	80 3a 00             	cmpb   $0x0,(%edx)
  800779:	74 10                	je     80078b <strlen+0x1b>
  80077b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800780:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800783:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800787:	75 f7                	jne    800780 <strlen+0x10>
  800789:	eb 05                	jmp    800790 <strlen+0x20>
  80078b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800790:	5d                   	pop    %ebp
  800791:	c3                   	ret    

00800792 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800792:	55                   	push   %ebp
  800793:	89 e5                	mov    %esp,%ebp
  800795:	53                   	push   %ebx
  800796:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800799:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079c:	85 c9                	test   %ecx,%ecx
  80079e:	74 1c                	je     8007bc <strnlen+0x2a>
  8007a0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8007a3:	74 1e                	je     8007c3 <strnlen+0x31>
  8007a5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8007aa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ac:	39 ca                	cmp    %ecx,%edx
  8007ae:	74 18                	je     8007c8 <strnlen+0x36>
  8007b0:	83 c2 01             	add    $0x1,%edx
  8007b3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8007b8:	75 f0                	jne    8007aa <strnlen+0x18>
  8007ba:	eb 0c                	jmp    8007c8 <strnlen+0x36>
  8007bc:	b8 00 00 00 00       	mov    $0x0,%eax
  8007c1:	eb 05                	jmp    8007c8 <strnlen+0x36>
  8007c3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8007c8:	5b                   	pop    %ebx
  8007c9:	5d                   	pop    %ebp
  8007ca:	c3                   	ret    

008007cb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007cb:	55                   	push   %ebp
  8007cc:	89 e5                	mov    %esp,%ebp
  8007ce:	53                   	push   %ebx
  8007cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007d5:	89 c2                	mov    %eax,%edx
  8007d7:	83 c2 01             	add    $0x1,%edx
  8007da:	83 c1 01             	add    $0x1,%ecx
  8007dd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007e1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007e4:	84 db                	test   %bl,%bl
  8007e6:	75 ef                	jne    8007d7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007e8:	5b                   	pop    %ebx
  8007e9:	5d                   	pop    %ebp
  8007ea:	c3                   	ret    

008007eb <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007eb:	55                   	push   %ebp
  8007ec:	89 e5                	mov    %esp,%ebp
  8007ee:	53                   	push   %ebx
  8007ef:	83 ec 08             	sub    $0x8,%esp
  8007f2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007f5:	89 1c 24             	mov    %ebx,(%esp)
  8007f8:	e8 73 ff ff ff       	call   800770 <strlen>
	strcpy(dst + len, src);
  8007fd:	8b 55 0c             	mov    0xc(%ebp),%edx
  800800:	89 54 24 04          	mov    %edx,0x4(%esp)
  800804:	01 d8                	add    %ebx,%eax
  800806:	89 04 24             	mov    %eax,(%esp)
  800809:	e8 bd ff ff ff       	call   8007cb <strcpy>
	return dst;
}
  80080e:	89 d8                	mov    %ebx,%eax
  800810:	83 c4 08             	add    $0x8,%esp
  800813:	5b                   	pop    %ebx
  800814:	5d                   	pop    %ebp
  800815:	c3                   	ret    

00800816 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800816:	55                   	push   %ebp
  800817:	89 e5                	mov    %esp,%ebp
  800819:	56                   	push   %esi
  80081a:	53                   	push   %ebx
  80081b:	8b 75 08             	mov    0x8(%ebp),%esi
  80081e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800821:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800824:	85 db                	test   %ebx,%ebx
  800826:	74 17                	je     80083f <strncpy+0x29>
  800828:	01 f3                	add    %esi,%ebx
  80082a:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
  80082c:	83 c1 01             	add    $0x1,%ecx
  80082f:	0f b6 02             	movzbl (%edx),%eax
  800832:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800835:	80 3a 01             	cmpb   $0x1,(%edx)
  800838:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80083b:	39 d9                	cmp    %ebx,%ecx
  80083d:	75 ed                	jne    80082c <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80083f:	89 f0                	mov    %esi,%eax
  800841:	5b                   	pop    %ebx
  800842:	5e                   	pop    %esi
  800843:	5d                   	pop    %ebp
  800844:	c3                   	ret    

00800845 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800845:	55                   	push   %ebp
  800846:	89 e5                	mov    %esp,%ebp
  800848:	57                   	push   %edi
  800849:	56                   	push   %esi
  80084a:	53                   	push   %ebx
  80084b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80084e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800851:	8b 75 10             	mov    0x10(%ebp),%esi
  800854:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800856:	85 f6                	test   %esi,%esi
  800858:	74 34                	je     80088e <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
  80085a:	83 fe 01             	cmp    $0x1,%esi
  80085d:	74 26                	je     800885 <strlcpy+0x40>
  80085f:	0f b6 0b             	movzbl (%ebx),%ecx
  800862:	84 c9                	test   %cl,%cl
  800864:	74 23                	je     800889 <strlcpy+0x44>
  800866:	83 ee 02             	sub    $0x2,%esi
  800869:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
  80086e:	83 c0 01             	add    $0x1,%eax
  800871:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800874:	39 f2                	cmp    %esi,%edx
  800876:	74 13                	je     80088b <strlcpy+0x46>
  800878:	83 c2 01             	add    $0x1,%edx
  80087b:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80087f:	84 c9                	test   %cl,%cl
  800881:	75 eb                	jne    80086e <strlcpy+0x29>
  800883:	eb 06                	jmp    80088b <strlcpy+0x46>
  800885:	89 f8                	mov    %edi,%eax
  800887:	eb 02                	jmp    80088b <strlcpy+0x46>
  800889:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  80088b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80088e:	29 f8                	sub    %edi,%eax
}
  800890:	5b                   	pop    %ebx
  800891:	5e                   	pop    %esi
  800892:	5f                   	pop    %edi
  800893:	5d                   	pop    %ebp
  800894:	c3                   	ret    

00800895 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800895:	55                   	push   %ebp
  800896:	89 e5                	mov    %esp,%ebp
  800898:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80089b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80089e:	0f b6 01             	movzbl (%ecx),%eax
  8008a1:	84 c0                	test   %al,%al
  8008a3:	74 15                	je     8008ba <strcmp+0x25>
  8008a5:	3a 02                	cmp    (%edx),%al
  8008a7:	75 11                	jne    8008ba <strcmp+0x25>
		p++, q++;
  8008a9:	83 c1 01             	add    $0x1,%ecx
  8008ac:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008af:	0f b6 01             	movzbl (%ecx),%eax
  8008b2:	84 c0                	test   %al,%al
  8008b4:	74 04                	je     8008ba <strcmp+0x25>
  8008b6:	3a 02                	cmp    (%edx),%al
  8008b8:	74 ef                	je     8008a9 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ba:	0f b6 c0             	movzbl %al,%eax
  8008bd:	0f b6 12             	movzbl (%edx),%edx
  8008c0:	29 d0                	sub    %edx,%eax
}
  8008c2:	5d                   	pop    %ebp
  8008c3:	c3                   	ret    

008008c4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008c4:	55                   	push   %ebp
  8008c5:	89 e5                	mov    %esp,%ebp
  8008c7:	56                   	push   %esi
  8008c8:	53                   	push   %ebx
  8008c9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8008cc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008cf:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8008d2:	85 f6                	test   %esi,%esi
  8008d4:	74 29                	je     8008ff <strncmp+0x3b>
  8008d6:	0f b6 03             	movzbl (%ebx),%eax
  8008d9:	84 c0                	test   %al,%al
  8008db:	74 30                	je     80090d <strncmp+0x49>
  8008dd:	3a 02                	cmp    (%edx),%al
  8008df:	75 2c                	jne    80090d <strncmp+0x49>
  8008e1:	8d 43 01             	lea    0x1(%ebx),%eax
  8008e4:	01 de                	add    %ebx,%esi
		n--, p++, q++;
  8008e6:	89 c3                	mov    %eax,%ebx
  8008e8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008eb:	39 f0                	cmp    %esi,%eax
  8008ed:	74 17                	je     800906 <strncmp+0x42>
  8008ef:	0f b6 08             	movzbl (%eax),%ecx
  8008f2:	84 c9                	test   %cl,%cl
  8008f4:	74 17                	je     80090d <strncmp+0x49>
  8008f6:	83 c0 01             	add    $0x1,%eax
  8008f9:	3a 0a                	cmp    (%edx),%cl
  8008fb:	74 e9                	je     8008e6 <strncmp+0x22>
  8008fd:	eb 0e                	jmp    80090d <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008ff:	b8 00 00 00 00       	mov    $0x0,%eax
  800904:	eb 0f                	jmp    800915 <strncmp+0x51>
  800906:	b8 00 00 00 00       	mov    $0x0,%eax
  80090b:	eb 08                	jmp    800915 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80090d:	0f b6 03             	movzbl (%ebx),%eax
  800910:	0f b6 12             	movzbl (%edx),%edx
  800913:	29 d0                	sub    %edx,%eax
}
  800915:	5b                   	pop    %ebx
  800916:	5e                   	pop    %esi
  800917:	5d                   	pop    %ebp
  800918:	c3                   	ret    

00800919 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800919:	55                   	push   %ebp
  80091a:	89 e5                	mov    %esp,%ebp
  80091c:	53                   	push   %ebx
  80091d:	8b 45 08             	mov    0x8(%ebp),%eax
  800920:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800923:	0f b6 18             	movzbl (%eax),%ebx
  800926:	84 db                	test   %bl,%bl
  800928:	74 1d                	je     800947 <strchr+0x2e>
  80092a:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  80092c:	38 d3                	cmp    %dl,%bl
  80092e:	75 06                	jne    800936 <strchr+0x1d>
  800930:	eb 1a                	jmp    80094c <strchr+0x33>
  800932:	38 ca                	cmp    %cl,%dl
  800934:	74 16                	je     80094c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800936:	83 c0 01             	add    $0x1,%eax
  800939:	0f b6 10             	movzbl (%eax),%edx
  80093c:	84 d2                	test   %dl,%dl
  80093e:	75 f2                	jne    800932 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800940:	b8 00 00 00 00       	mov    $0x0,%eax
  800945:	eb 05                	jmp    80094c <strchr+0x33>
  800947:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80094c:	5b                   	pop    %ebx
  80094d:	5d                   	pop    %ebp
  80094e:	c3                   	ret    

0080094f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80094f:	55                   	push   %ebp
  800950:	89 e5                	mov    %esp,%ebp
  800952:	53                   	push   %ebx
  800953:	8b 45 08             	mov    0x8(%ebp),%eax
  800956:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800959:	0f b6 18             	movzbl (%eax),%ebx
  80095c:	84 db                	test   %bl,%bl
  80095e:	74 16                	je     800976 <strfind+0x27>
  800960:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800962:	38 d3                	cmp    %dl,%bl
  800964:	75 06                	jne    80096c <strfind+0x1d>
  800966:	eb 0e                	jmp    800976 <strfind+0x27>
  800968:	38 ca                	cmp    %cl,%dl
  80096a:	74 0a                	je     800976 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80096c:	83 c0 01             	add    $0x1,%eax
  80096f:	0f b6 10             	movzbl (%eax),%edx
  800972:	84 d2                	test   %dl,%dl
  800974:	75 f2                	jne    800968 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800976:	5b                   	pop    %ebx
  800977:	5d                   	pop    %ebp
  800978:	c3                   	ret    

00800979 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800979:	55                   	push   %ebp
  80097a:	89 e5                	mov    %esp,%ebp
  80097c:	57                   	push   %edi
  80097d:	56                   	push   %esi
  80097e:	53                   	push   %ebx
  80097f:	8b 7d 08             	mov    0x8(%ebp),%edi
  800982:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800985:	85 c9                	test   %ecx,%ecx
  800987:	74 36                	je     8009bf <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800989:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80098f:	75 28                	jne    8009b9 <memset+0x40>
  800991:	f6 c1 03             	test   $0x3,%cl
  800994:	75 23                	jne    8009b9 <memset+0x40>
		c &= 0xFF;
  800996:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80099a:	89 d3                	mov    %edx,%ebx
  80099c:	c1 e3 08             	shl    $0x8,%ebx
  80099f:	89 d6                	mov    %edx,%esi
  8009a1:	c1 e6 18             	shl    $0x18,%esi
  8009a4:	89 d0                	mov    %edx,%eax
  8009a6:	c1 e0 10             	shl    $0x10,%eax
  8009a9:	09 f0                	or     %esi,%eax
  8009ab:	09 c2                	or     %eax,%edx
  8009ad:	89 d0                	mov    %edx,%eax
  8009af:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009b1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009b4:	fc                   	cld    
  8009b5:	f3 ab                	rep stos %eax,%es:(%edi)
  8009b7:	eb 06                	jmp    8009bf <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009b9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009bc:	fc                   	cld    
  8009bd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009bf:	89 f8                	mov    %edi,%eax
  8009c1:	5b                   	pop    %ebx
  8009c2:	5e                   	pop    %esi
  8009c3:	5f                   	pop    %edi
  8009c4:	5d                   	pop    %ebp
  8009c5:	c3                   	ret    

008009c6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009c6:	55                   	push   %ebp
  8009c7:	89 e5                	mov    %esp,%ebp
  8009c9:	57                   	push   %edi
  8009ca:	56                   	push   %esi
  8009cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ce:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009d1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009d4:	39 c6                	cmp    %eax,%esi
  8009d6:	73 35                	jae    800a0d <memmove+0x47>
  8009d8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009db:	39 d0                	cmp    %edx,%eax
  8009dd:	73 2e                	jae    800a0d <memmove+0x47>
		s += n;
		d += n;
  8009df:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  8009e2:	89 d6                	mov    %edx,%esi
  8009e4:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009e6:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009ec:	75 13                	jne    800a01 <memmove+0x3b>
  8009ee:	f6 c1 03             	test   $0x3,%cl
  8009f1:	75 0e                	jne    800a01 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8009f3:	83 ef 04             	sub    $0x4,%edi
  8009f6:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009f9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  8009fc:	fd                   	std    
  8009fd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009ff:	eb 09                	jmp    800a0a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a01:	83 ef 01             	sub    $0x1,%edi
  800a04:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a07:	fd                   	std    
  800a08:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a0a:	fc                   	cld    
  800a0b:	eb 1d                	jmp    800a2a <memmove+0x64>
  800a0d:	89 f2                	mov    %esi,%edx
  800a0f:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a11:	f6 c2 03             	test   $0x3,%dl
  800a14:	75 0f                	jne    800a25 <memmove+0x5f>
  800a16:	f6 c1 03             	test   $0x3,%cl
  800a19:	75 0a                	jne    800a25 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a1b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a1e:	89 c7                	mov    %eax,%edi
  800a20:	fc                   	cld    
  800a21:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a23:	eb 05                	jmp    800a2a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a25:	89 c7                	mov    %eax,%edi
  800a27:	fc                   	cld    
  800a28:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a2a:	5e                   	pop    %esi
  800a2b:	5f                   	pop    %edi
  800a2c:	5d                   	pop    %ebp
  800a2d:	c3                   	ret    

00800a2e <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800a2e:	55                   	push   %ebp
  800a2f:	89 e5                	mov    %esp,%ebp
  800a31:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a34:	8b 45 10             	mov    0x10(%ebp),%eax
  800a37:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a3b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a3e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a42:	8b 45 08             	mov    0x8(%ebp),%eax
  800a45:	89 04 24             	mov    %eax,(%esp)
  800a48:	e8 79 ff ff ff       	call   8009c6 <memmove>
}
  800a4d:	c9                   	leave  
  800a4e:	c3                   	ret    

00800a4f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a4f:	55                   	push   %ebp
  800a50:	89 e5                	mov    %esp,%ebp
  800a52:	57                   	push   %edi
  800a53:	56                   	push   %esi
  800a54:	53                   	push   %ebx
  800a55:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800a58:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a5b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a5e:	8d 78 ff             	lea    -0x1(%eax),%edi
  800a61:	85 c0                	test   %eax,%eax
  800a63:	74 36                	je     800a9b <memcmp+0x4c>
		if (*s1 != *s2)
  800a65:	0f b6 03             	movzbl (%ebx),%eax
  800a68:	0f b6 0e             	movzbl (%esi),%ecx
  800a6b:	ba 00 00 00 00       	mov    $0x0,%edx
  800a70:	38 c8                	cmp    %cl,%al
  800a72:	74 1c                	je     800a90 <memcmp+0x41>
  800a74:	eb 10                	jmp    800a86 <memcmp+0x37>
  800a76:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800a7b:	83 c2 01             	add    $0x1,%edx
  800a7e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800a82:	38 c8                	cmp    %cl,%al
  800a84:	74 0a                	je     800a90 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800a86:	0f b6 c0             	movzbl %al,%eax
  800a89:	0f b6 c9             	movzbl %cl,%ecx
  800a8c:	29 c8                	sub    %ecx,%eax
  800a8e:	eb 10                	jmp    800aa0 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a90:	39 fa                	cmp    %edi,%edx
  800a92:	75 e2                	jne    800a76 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a94:	b8 00 00 00 00       	mov    $0x0,%eax
  800a99:	eb 05                	jmp    800aa0 <memcmp+0x51>
  800a9b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800aa0:	5b                   	pop    %ebx
  800aa1:	5e                   	pop    %esi
  800aa2:	5f                   	pop    %edi
  800aa3:	5d                   	pop    %ebp
  800aa4:	c3                   	ret    

00800aa5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800aa5:	55                   	push   %ebp
  800aa6:	89 e5                	mov    %esp,%ebp
  800aa8:	53                   	push   %ebx
  800aa9:	8b 45 08             	mov    0x8(%ebp),%eax
  800aac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800aaf:	89 c2                	mov    %eax,%edx
  800ab1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ab4:	39 d0                	cmp    %edx,%eax
  800ab6:	73 13                	jae    800acb <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ab8:	89 d9                	mov    %ebx,%ecx
  800aba:	38 18                	cmp    %bl,(%eax)
  800abc:	75 06                	jne    800ac4 <memfind+0x1f>
  800abe:	eb 0b                	jmp    800acb <memfind+0x26>
  800ac0:	38 08                	cmp    %cl,(%eax)
  800ac2:	74 07                	je     800acb <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ac4:	83 c0 01             	add    $0x1,%eax
  800ac7:	39 d0                	cmp    %edx,%eax
  800ac9:	75 f5                	jne    800ac0 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800acb:	5b                   	pop    %ebx
  800acc:	5d                   	pop    %ebp
  800acd:	c3                   	ret    

00800ace <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800ace:	55                   	push   %ebp
  800acf:	89 e5                	mov    %esp,%ebp
  800ad1:	57                   	push   %edi
  800ad2:	56                   	push   %esi
  800ad3:	53                   	push   %ebx
  800ad4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ad7:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ada:	0f b6 0a             	movzbl (%edx),%ecx
  800add:	80 f9 09             	cmp    $0x9,%cl
  800ae0:	74 05                	je     800ae7 <strtol+0x19>
  800ae2:	80 f9 20             	cmp    $0x20,%cl
  800ae5:	75 10                	jne    800af7 <strtol+0x29>
		s++;
  800ae7:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aea:	0f b6 0a             	movzbl (%edx),%ecx
  800aed:	80 f9 09             	cmp    $0x9,%cl
  800af0:	74 f5                	je     800ae7 <strtol+0x19>
  800af2:	80 f9 20             	cmp    $0x20,%cl
  800af5:	74 f0                	je     800ae7 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
  800af7:	80 f9 2b             	cmp    $0x2b,%cl
  800afa:	75 0a                	jne    800b06 <strtol+0x38>
		s++;
  800afc:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800aff:	bf 00 00 00 00       	mov    $0x0,%edi
  800b04:	eb 11                	jmp    800b17 <strtol+0x49>
  800b06:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b0b:	80 f9 2d             	cmp    $0x2d,%cl
  800b0e:	75 07                	jne    800b17 <strtol+0x49>
		s++, neg = 1;
  800b10:	83 c2 01             	add    $0x1,%edx
  800b13:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b17:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b1c:	75 15                	jne    800b33 <strtol+0x65>
  800b1e:	80 3a 30             	cmpb   $0x30,(%edx)
  800b21:	75 10                	jne    800b33 <strtol+0x65>
  800b23:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b27:	75 0a                	jne    800b33 <strtol+0x65>
		s += 2, base = 16;
  800b29:	83 c2 02             	add    $0x2,%edx
  800b2c:	b8 10 00 00 00       	mov    $0x10,%eax
  800b31:	eb 10                	jmp    800b43 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
  800b33:	85 c0                	test   %eax,%eax
  800b35:	75 0c                	jne    800b43 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b37:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b39:	80 3a 30             	cmpb   $0x30,(%edx)
  800b3c:	75 05                	jne    800b43 <strtol+0x75>
		s++, base = 8;
  800b3e:	83 c2 01             	add    $0x1,%edx
  800b41:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b43:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b48:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b4b:	0f b6 0a             	movzbl (%edx),%ecx
  800b4e:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b51:	89 f0                	mov    %esi,%eax
  800b53:	3c 09                	cmp    $0x9,%al
  800b55:	77 08                	ja     800b5f <strtol+0x91>
			dig = *s - '0';
  800b57:	0f be c9             	movsbl %cl,%ecx
  800b5a:	83 e9 30             	sub    $0x30,%ecx
  800b5d:	eb 20                	jmp    800b7f <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
  800b5f:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b62:	89 f0                	mov    %esi,%eax
  800b64:	3c 19                	cmp    $0x19,%al
  800b66:	77 08                	ja     800b70 <strtol+0xa2>
			dig = *s - 'a' + 10;
  800b68:	0f be c9             	movsbl %cl,%ecx
  800b6b:	83 e9 57             	sub    $0x57,%ecx
  800b6e:	eb 0f                	jmp    800b7f <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
  800b70:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b73:	89 f0                	mov    %esi,%eax
  800b75:	3c 19                	cmp    $0x19,%al
  800b77:	77 16                	ja     800b8f <strtol+0xc1>
			dig = *s - 'A' + 10;
  800b79:	0f be c9             	movsbl %cl,%ecx
  800b7c:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b7f:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b82:	7d 0f                	jge    800b93 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800b84:	83 c2 01             	add    $0x1,%edx
  800b87:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800b8b:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800b8d:	eb bc                	jmp    800b4b <strtol+0x7d>
  800b8f:	89 d8                	mov    %ebx,%eax
  800b91:	eb 02                	jmp    800b95 <strtol+0xc7>
  800b93:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800b95:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b99:	74 05                	je     800ba0 <strtol+0xd2>
		*endptr = (char *) s;
  800b9b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b9e:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800ba0:	f7 d8                	neg    %eax
  800ba2:	85 ff                	test   %edi,%edi
  800ba4:	0f 44 c3             	cmove  %ebx,%eax
}
  800ba7:	5b                   	pop    %ebx
  800ba8:	5e                   	pop    %esi
  800ba9:	5f                   	pop    %edi
  800baa:	5d                   	pop    %ebp
  800bab:	c3                   	ret    

00800bac <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800bac:	55                   	push   %ebp
  800bad:	89 e5                	mov    %esp,%ebp
  800baf:	57                   	push   %edi
  800bb0:	56                   	push   %esi
  800bb1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bb2:	b8 00 00 00 00       	mov    $0x0,%eax
  800bb7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bba:	8b 55 08             	mov    0x8(%ebp),%edx
  800bbd:	89 c3                	mov    %eax,%ebx
  800bbf:	89 c7                	mov    %eax,%edi
  800bc1:	89 c6                	mov    %eax,%esi
  800bc3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800bc5:	5b                   	pop    %ebx
  800bc6:	5e                   	pop    %esi
  800bc7:	5f                   	pop    %edi
  800bc8:	5d                   	pop    %ebp
  800bc9:	c3                   	ret    

00800bca <sys_cgetc>:

int
sys_cgetc(void)
{
  800bca:	55                   	push   %ebp
  800bcb:	89 e5                	mov    %esp,%ebp
  800bcd:	57                   	push   %edi
  800bce:	56                   	push   %esi
  800bcf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bd0:	ba 00 00 00 00       	mov    $0x0,%edx
  800bd5:	b8 01 00 00 00       	mov    $0x1,%eax
  800bda:	89 d1                	mov    %edx,%ecx
  800bdc:	89 d3                	mov    %edx,%ebx
  800bde:	89 d7                	mov    %edx,%edi
  800be0:	89 d6                	mov    %edx,%esi
  800be2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800be4:	5b                   	pop    %ebx
  800be5:	5e                   	pop    %esi
  800be6:	5f                   	pop    %edi
  800be7:	5d                   	pop    %ebp
  800be8:	c3                   	ret    

00800be9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800be9:	55                   	push   %ebp
  800bea:	89 e5                	mov    %esp,%ebp
  800bec:	57                   	push   %edi
  800bed:	56                   	push   %esi
  800bee:	53                   	push   %ebx
  800bef:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bf7:	b8 03 00 00 00       	mov    $0x3,%eax
  800bfc:	8b 55 08             	mov    0x8(%ebp),%edx
  800bff:	89 cb                	mov    %ecx,%ebx
  800c01:	89 cf                	mov    %ecx,%edi
  800c03:	89 ce                	mov    %ecx,%esi
  800c05:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c07:	85 c0                	test   %eax,%eax
  800c09:	7e 28                	jle    800c33 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c0b:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c0f:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c16:	00 
  800c17:	c7 44 24 08 88 11 80 	movl   $0x801188,0x8(%esp)
  800c1e:	00 
  800c1f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c26:	00 
  800c27:	c7 04 24 a5 11 80 00 	movl   $0x8011a5,(%esp)
  800c2e:	e8 27 00 00 00       	call   800c5a <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c33:	83 c4 2c             	add    $0x2c,%esp
  800c36:	5b                   	pop    %ebx
  800c37:	5e                   	pop    %esi
  800c38:	5f                   	pop    %edi
  800c39:	5d                   	pop    %ebp
  800c3a:	c3                   	ret    

00800c3b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c3b:	55                   	push   %ebp
  800c3c:	89 e5                	mov    %esp,%ebp
  800c3e:	57                   	push   %edi
  800c3f:	56                   	push   %esi
  800c40:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c41:	ba 00 00 00 00       	mov    $0x0,%edx
  800c46:	b8 02 00 00 00       	mov    $0x2,%eax
  800c4b:	89 d1                	mov    %edx,%ecx
  800c4d:	89 d3                	mov    %edx,%ebx
  800c4f:	89 d7                	mov    %edx,%edi
  800c51:	89 d6                	mov    %edx,%esi
  800c53:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c55:	5b                   	pop    %ebx
  800c56:	5e                   	pop    %esi
  800c57:	5f                   	pop    %edi
  800c58:	5d                   	pop    %ebp
  800c59:	c3                   	ret    

00800c5a <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800c5a:	55                   	push   %ebp
  800c5b:	89 e5                	mov    %esp,%ebp
  800c5d:	56                   	push   %esi
  800c5e:	53                   	push   %ebx
  800c5f:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800c62:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800c65:	a1 08 20 80 00       	mov    0x802008,%eax
  800c6a:	85 c0                	test   %eax,%eax
  800c6c:	74 10                	je     800c7e <_panic+0x24>
		cprintf("%s: ", argv0);
  800c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c72:	c7 04 24 b3 11 80 00 	movl   $0x8011b3,(%esp)
  800c79:	e8 ed f4 ff ff       	call   80016b <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800c7e:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800c84:	e8 b2 ff ff ff       	call   800c3b <sys_getenvid>
  800c89:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c8c:	89 54 24 10          	mov    %edx,0x10(%esp)
  800c90:	8b 55 08             	mov    0x8(%ebp),%edx
  800c93:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800c97:	89 74 24 08          	mov    %esi,0x8(%esp)
  800c9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c9f:	c7 04 24 b8 11 80 00 	movl   $0x8011b8,(%esp)
  800ca6:	e8 c0 f4 ff ff       	call   80016b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800cab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800caf:	8b 45 10             	mov    0x10(%ebp),%eax
  800cb2:	89 04 24             	mov    %eax,(%esp)
  800cb5:	e8 50 f4 ff ff       	call   80010a <vcprintf>
	cprintf("\n");
  800cba:	c7 04 24 64 0f 80 00 	movl   $0x800f64,(%esp)
  800cc1:	e8 a5 f4 ff ff       	call   80016b <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800cc6:	cc                   	int3   
  800cc7:	eb fd                	jmp    800cc6 <_panic+0x6c>
  800cc9:	66 90                	xchg   %ax,%ax
  800ccb:	66 90                	xchg   %ax,%ax
  800ccd:	66 90                	xchg   %ax,%ax
  800ccf:	90                   	nop

00800cd0 <__udivdi3>:
  800cd0:	55                   	push   %ebp
  800cd1:	57                   	push   %edi
  800cd2:	56                   	push   %esi
  800cd3:	83 ec 0c             	sub    $0xc,%esp
  800cd6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800cda:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800cde:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800ce2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800ce6:	85 c0                	test   %eax,%eax
  800ce8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800cec:	89 ea                	mov    %ebp,%edx
  800cee:	89 0c 24             	mov    %ecx,(%esp)
  800cf1:	75 2d                	jne    800d20 <__udivdi3+0x50>
  800cf3:	39 e9                	cmp    %ebp,%ecx
  800cf5:	77 61                	ja     800d58 <__udivdi3+0x88>
  800cf7:	85 c9                	test   %ecx,%ecx
  800cf9:	89 ce                	mov    %ecx,%esi
  800cfb:	75 0b                	jne    800d08 <__udivdi3+0x38>
  800cfd:	b8 01 00 00 00       	mov    $0x1,%eax
  800d02:	31 d2                	xor    %edx,%edx
  800d04:	f7 f1                	div    %ecx
  800d06:	89 c6                	mov    %eax,%esi
  800d08:	31 d2                	xor    %edx,%edx
  800d0a:	89 e8                	mov    %ebp,%eax
  800d0c:	f7 f6                	div    %esi
  800d0e:	89 c5                	mov    %eax,%ebp
  800d10:	89 f8                	mov    %edi,%eax
  800d12:	f7 f6                	div    %esi
  800d14:	89 ea                	mov    %ebp,%edx
  800d16:	83 c4 0c             	add    $0xc,%esp
  800d19:	5e                   	pop    %esi
  800d1a:	5f                   	pop    %edi
  800d1b:	5d                   	pop    %ebp
  800d1c:	c3                   	ret    
  800d1d:	8d 76 00             	lea    0x0(%esi),%esi
  800d20:	39 e8                	cmp    %ebp,%eax
  800d22:	77 24                	ja     800d48 <__udivdi3+0x78>
  800d24:	0f bd e8             	bsr    %eax,%ebp
  800d27:	83 f5 1f             	xor    $0x1f,%ebp
  800d2a:	75 3c                	jne    800d68 <__udivdi3+0x98>
  800d2c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d30:	39 34 24             	cmp    %esi,(%esp)
  800d33:	0f 86 9f 00 00 00    	jbe    800dd8 <__udivdi3+0x108>
  800d39:	39 d0                	cmp    %edx,%eax
  800d3b:	0f 82 97 00 00 00    	jb     800dd8 <__udivdi3+0x108>
  800d41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d48:	31 d2                	xor    %edx,%edx
  800d4a:	31 c0                	xor    %eax,%eax
  800d4c:	83 c4 0c             	add    $0xc,%esp
  800d4f:	5e                   	pop    %esi
  800d50:	5f                   	pop    %edi
  800d51:	5d                   	pop    %ebp
  800d52:	c3                   	ret    
  800d53:	90                   	nop
  800d54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d58:	89 f8                	mov    %edi,%eax
  800d5a:	f7 f1                	div    %ecx
  800d5c:	31 d2                	xor    %edx,%edx
  800d5e:	83 c4 0c             	add    $0xc,%esp
  800d61:	5e                   	pop    %esi
  800d62:	5f                   	pop    %edi
  800d63:	5d                   	pop    %ebp
  800d64:	c3                   	ret    
  800d65:	8d 76 00             	lea    0x0(%esi),%esi
  800d68:	89 e9                	mov    %ebp,%ecx
  800d6a:	8b 3c 24             	mov    (%esp),%edi
  800d6d:	d3 e0                	shl    %cl,%eax
  800d6f:	89 c6                	mov    %eax,%esi
  800d71:	b8 20 00 00 00       	mov    $0x20,%eax
  800d76:	29 e8                	sub    %ebp,%eax
  800d78:	89 c1                	mov    %eax,%ecx
  800d7a:	d3 ef                	shr    %cl,%edi
  800d7c:	89 e9                	mov    %ebp,%ecx
  800d7e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d82:	8b 3c 24             	mov    (%esp),%edi
  800d85:	09 74 24 08          	or     %esi,0x8(%esp)
  800d89:	89 d6                	mov    %edx,%esi
  800d8b:	d3 e7                	shl    %cl,%edi
  800d8d:	89 c1                	mov    %eax,%ecx
  800d8f:	89 3c 24             	mov    %edi,(%esp)
  800d92:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d96:	d3 ee                	shr    %cl,%esi
  800d98:	89 e9                	mov    %ebp,%ecx
  800d9a:	d3 e2                	shl    %cl,%edx
  800d9c:	89 c1                	mov    %eax,%ecx
  800d9e:	d3 ef                	shr    %cl,%edi
  800da0:	09 d7                	or     %edx,%edi
  800da2:	89 f2                	mov    %esi,%edx
  800da4:	89 f8                	mov    %edi,%eax
  800da6:	f7 74 24 08          	divl   0x8(%esp)
  800daa:	89 d6                	mov    %edx,%esi
  800dac:	89 c7                	mov    %eax,%edi
  800dae:	f7 24 24             	mull   (%esp)
  800db1:	39 d6                	cmp    %edx,%esi
  800db3:	89 14 24             	mov    %edx,(%esp)
  800db6:	72 30                	jb     800de8 <__udivdi3+0x118>
  800db8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800dbc:	89 e9                	mov    %ebp,%ecx
  800dbe:	d3 e2                	shl    %cl,%edx
  800dc0:	39 c2                	cmp    %eax,%edx
  800dc2:	73 05                	jae    800dc9 <__udivdi3+0xf9>
  800dc4:	3b 34 24             	cmp    (%esp),%esi
  800dc7:	74 1f                	je     800de8 <__udivdi3+0x118>
  800dc9:	89 f8                	mov    %edi,%eax
  800dcb:	31 d2                	xor    %edx,%edx
  800dcd:	e9 7a ff ff ff       	jmp    800d4c <__udivdi3+0x7c>
  800dd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800dd8:	31 d2                	xor    %edx,%edx
  800dda:	b8 01 00 00 00       	mov    $0x1,%eax
  800ddf:	e9 68 ff ff ff       	jmp    800d4c <__udivdi3+0x7c>
  800de4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800de8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800deb:	31 d2                	xor    %edx,%edx
  800ded:	83 c4 0c             	add    $0xc,%esp
  800df0:	5e                   	pop    %esi
  800df1:	5f                   	pop    %edi
  800df2:	5d                   	pop    %ebp
  800df3:	c3                   	ret    
  800df4:	66 90                	xchg   %ax,%ax
  800df6:	66 90                	xchg   %ax,%ax
  800df8:	66 90                	xchg   %ax,%ax
  800dfa:	66 90                	xchg   %ax,%ax
  800dfc:	66 90                	xchg   %ax,%ax
  800dfe:	66 90                	xchg   %ax,%ax

00800e00 <__umoddi3>:
  800e00:	55                   	push   %ebp
  800e01:	57                   	push   %edi
  800e02:	56                   	push   %esi
  800e03:	83 ec 14             	sub    $0x14,%esp
  800e06:	8b 44 24 28          	mov    0x28(%esp),%eax
  800e0a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800e0e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800e12:	89 c7                	mov    %eax,%edi
  800e14:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e18:	8b 44 24 30          	mov    0x30(%esp),%eax
  800e1c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800e20:	89 34 24             	mov    %esi,(%esp)
  800e23:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e27:	85 c0                	test   %eax,%eax
  800e29:	89 c2                	mov    %eax,%edx
  800e2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e2f:	75 17                	jne    800e48 <__umoddi3+0x48>
  800e31:	39 fe                	cmp    %edi,%esi
  800e33:	76 4b                	jbe    800e80 <__umoddi3+0x80>
  800e35:	89 c8                	mov    %ecx,%eax
  800e37:	89 fa                	mov    %edi,%edx
  800e39:	f7 f6                	div    %esi
  800e3b:	89 d0                	mov    %edx,%eax
  800e3d:	31 d2                	xor    %edx,%edx
  800e3f:	83 c4 14             	add    $0x14,%esp
  800e42:	5e                   	pop    %esi
  800e43:	5f                   	pop    %edi
  800e44:	5d                   	pop    %ebp
  800e45:	c3                   	ret    
  800e46:	66 90                	xchg   %ax,%ax
  800e48:	39 f8                	cmp    %edi,%eax
  800e4a:	77 54                	ja     800ea0 <__umoddi3+0xa0>
  800e4c:	0f bd e8             	bsr    %eax,%ebp
  800e4f:	83 f5 1f             	xor    $0x1f,%ebp
  800e52:	75 5c                	jne    800eb0 <__umoddi3+0xb0>
  800e54:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e58:	39 3c 24             	cmp    %edi,(%esp)
  800e5b:	0f 87 e7 00 00 00    	ja     800f48 <__umoddi3+0x148>
  800e61:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800e65:	29 f1                	sub    %esi,%ecx
  800e67:	19 c7                	sbb    %eax,%edi
  800e69:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e6d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e71:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e75:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e79:	83 c4 14             	add    $0x14,%esp
  800e7c:	5e                   	pop    %esi
  800e7d:	5f                   	pop    %edi
  800e7e:	5d                   	pop    %ebp
  800e7f:	c3                   	ret    
  800e80:	85 f6                	test   %esi,%esi
  800e82:	89 f5                	mov    %esi,%ebp
  800e84:	75 0b                	jne    800e91 <__umoddi3+0x91>
  800e86:	b8 01 00 00 00       	mov    $0x1,%eax
  800e8b:	31 d2                	xor    %edx,%edx
  800e8d:	f7 f6                	div    %esi
  800e8f:	89 c5                	mov    %eax,%ebp
  800e91:	8b 44 24 04          	mov    0x4(%esp),%eax
  800e95:	31 d2                	xor    %edx,%edx
  800e97:	f7 f5                	div    %ebp
  800e99:	89 c8                	mov    %ecx,%eax
  800e9b:	f7 f5                	div    %ebp
  800e9d:	eb 9c                	jmp    800e3b <__umoddi3+0x3b>
  800e9f:	90                   	nop
  800ea0:	89 c8                	mov    %ecx,%eax
  800ea2:	89 fa                	mov    %edi,%edx
  800ea4:	83 c4 14             	add    $0x14,%esp
  800ea7:	5e                   	pop    %esi
  800ea8:	5f                   	pop    %edi
  800ea9:	5d                   	pop    %ebp
  800eaa:	c3                   	ret    
  800eab:	90                   	nop
  800eac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800eb0:	8b 04 24             	mov    (%esp),%eax
  800eb3:	be 20 00 00 00       	mov    $0x20,%esi
  800eb8:	89 e9                	mov    %ebp,%ecx
  800eba:	29 ee                	sub    %ebp,%esi
  800ebc:	d3 e2                	shl    %cl,%edx
  800ebe:	89 f1                	mov    %esi,%ecx
  800ec0:	d3 e8                	shr    %cl,%eax
  800ec2:	89 e9                	mov    %ebp,%ecx
  800ec4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ec8:	8b 04 24             	mov    (%esp),%eax
  800ecb:	09 54 24 04          	or     %edx,0x4(%esp)
  800ecf:	89 fa                	mov    %edi,%edx
  800ed1:	d3 e0                	shl    %cl,%eax
  800ed3:	89 f1                	mov    %esi,%ecx
  800ed5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ed9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800edd:	d3 ea                	shr    %cl,%edx
  800edf:	89 e9                	mov    %ebp,%ecx
  800ee1:	d3 e7                	shl    %cl,%edi
  800ee3:	89 f1                	mov    %esi,%ecx
  800ee5:	d3 e8                	shr    %cl,%eax
  800ee7:	89 e9                	mov    %ebp,%ecx
  800ee9:	09 f8                	or     %edi,%eax
  800eeb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800eef:	f7 74 24 04          	divl   0x4(%esp)
  800ef3:	d3 e7                	shl    %cl,%edi
  800ef5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ef9:	89 d7                	mov    %edx,%edi
  800efb:	f7 64 24 08          	mull   0x8(%esp)
  800eff:	39 d7                	cmp    %edx,%edi
  800f01:	89 c1                	mov    %eax,%ecx
  800f03:	89 14 24             	mov    %edx,(%esp)
  800f06:	72 2c                	jb     800f34 <__umoddi3+0x134>
  800f08:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800f0c:	72 22                	jb     800f30 <__umoddi3+0x130>
  800f0e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f12:	29 c8                	sub    %ecx,%eax
  800f14:	19 d7                	sbb    %edx,%edi
  800f16:	89 e9                	mov    %ebp,%ecx
  800f18:	89 fa                	mov    %edi,%edx
  800f1a:	d3 e8                	shr    %cl,%eax
  800f1c:	89 f1                	mov    %esi,%ecx
  800f1e:	d3 e2                	shl    %cl,%edx
  800f20:	89 e9                	mov    %ebp,%ecx
  800f22:	d3 ef                	shr    %cl,%edi
  800f24:	09 d0                	or     %edx,%eax
  800f26:	89 fa                	mov    %edi,%edx
  800f28:	83 c4 14             	add    $0x14,%esp
  800f2b:	5e                   	pop    %esi
  800f2c:	5f                   	pop    %edi
  800f2d:	5d                   	pop    %ebp
  800f2e:	c3                   	ret    
  800f2f:	90                   	nop
  800f30:	39 d7                	cmp    %edx,%edi
  800f32:	75 da                	jne    800f0e <__umoddi3+0x10e>
  800f34:	8b 14 24             	mov    (%esp),%edx
  800f37:	89 c1                	mov    %eax,%ecx
  800f39:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800f3d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800f41:	eb cb                	jmp    800f0e <__umoddi3+0x10e>
  800f43:	90                   	nop
  800f44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f48:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800f4c:	0f 82 0f ff ff ff    	jb     800e61 <__umoddi3+0x61>
  800f52:	e9 1a ff ff ff       	jmp    800e71 <__umoddi3+0x71>
