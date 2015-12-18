
obj/user/breakpoint:     file format elf32-i386


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
  80002c:	e8 08 00 00 00       	call   800039 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $3");
  800036:	cc                   	int3   
}
  800037:	5d                   	pop    %ebp
  800038:	c3                   	ret    

00800039 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800039:	55                   	push   %ebp
  80003a:	89 e5                	mov    %esp,%ebp
  80003c:	56                   	push   %esi
  80003d:	53                   	push   %ebx
  80003e:	83 ec 10             	sub    $0x10,%esp
  800041:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800044:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800047:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80004e:	00 00 00 
	//thisenv=envs+ENVX(sys_getenvid());
	int index=sys_getenvid();
  800051:	e8 db 00 00 00       	call   800131 <sys_getenvid>
        thisenv=&envs[ENVX(index)];
  800056:	25 ff 03 00 00       	and    $0x3ff,%eax
  80005b:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80005e:	c1 e0 05             	shl    $0x5,%eax
  800061:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800066:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80006b:	85 db                	test   %ebx,%ebx
  80006d:	7e 07                	jle    800076 <libmain+0x3d>
		binaryname = argv[0];
  80006f:	8b 06                	mov    (%esi),%eax
  800071:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800076:	89 74 24 04          	mov    %esi,0x4(%esp)
  80007a:	89 1c 24             	mov    %ebx,(%esp)
  80007d:	e8 b1 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800082:	e8 07 00 00 00       	call   80008e <exit>
}
  800087:	83 c4 10             	add    $0x10,%esp
  80008a:	5b                   	pop    %ebx
  80008b:	5e                   	pop    %esi
  80008c:	5d                   	pop    %ebp
  80008d:	c3                   	ret    

0080008e <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80008e:	55                   	push   %ebp
  80008f:	89 e5                	mov    %esp,%ebp
  800091:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800094:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80009b:	e8 3f 00 00 00       	call   8000df <sys_env_destroy>
}
  8000a0:	c9                   	leave  
  8000a1:	c3                   	ret    

008000a2 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a2:	55                   	push   %ebp
  8000a3:	89 e5                	mov    %esp,%ebp
  8000a5:	57                   	push   %edi
  8000a6:	56                   	push   %esi
  8000a7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a8:	b8 00 00 00 00       	mov    $0x0,%eax
  8000ad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b0:	8b 55 08             	mov    0x8(%ebp),%edx
  8000b3:	89 c3                	mov    %eax,%ebx
  8000b5:	89 c7                	mov    %eax,%edi
  8000b7:	89 c6                	mov    %eax,%esi
  8000b9:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000bb:	5b                   	pop    %ebx
  8000bc:	5e                   	pop    %esi
  8000bd:	5f                   	pop    %edi
  8000be:	5d                   	pop    %ebp
  8000bf:	c3                   	ret    

008000c0 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000c0:	55                   	push   %ebp
  8000c1:	89 e5                	mov    %esp,%ebp
  8000c3:	57                   	push   %edi
  8000c4:	56                   	push   %esi
  8000c5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000cb:	b8 01 00 00 00       	mov    $0x1,%eax
  8000d0:	89 d1                	mov    %edx,%ecx
  8000d2:	89 d3                	mov    %edx,%ebx
  8000d4:	89 d7                	mov    %edx,%edi
  8000d6:	89 d6                	mov    %edx,%esi
  8000d8:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000da:	5b                   	pop    %ebx
  8000db:	5e                   	pop    %esi
  8000dc:	5f                   	pop    %edi
  8000dd:	5d                   	pop    %ebp
  8000de:	c3                   	ret    

008000df <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000df:	55                   	push   %ebp
  8000e0:	89 e5                	mov    %esp,%ebp
  8000e2:	57                   	push   %edi
  8000e3:	56                   	push   %esi
  8000e4:	53                   	push   %ebx
  8000e5:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000ed:	b8 03 00 00 00       	mov    $0x3,%eax
  8000f2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000f5:	89 cb                	mov    %ecx,%ebx
  8000f7:	89 cf                	mov    %ecx,%edi
  8000f9:	89 ce                	mov    %ecx,%esi
  8000fb:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000fd:	85 c0                	test   %eax,%eax
  8000ff:	7e 28                	jle    800129 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800101:	89 44 24 10          	mov    %eax,0x10(%esp)
  800105:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80010c:	00 
  80010d:	c7 44 24 08 32 0f 80 	movl   $0x800f32,0x8(%esp)
  800114:	00 
  800115:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80011c:	00 
  80011d:	c7 04 24 4f 0f 80 00 	movl   $0x800f4f,(%esp)
  800124:	e8 27 00 00 00       	call   800150 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800129:	83 c4 2c             	add    $0x2c,%esp
  80012c:	5b                   	pop    %ebx
  80012d:	5e                   	pop    %esi
  80012e:	5f                   	pop    %edi
  80012f:	5d                   	pop    %ebp
  800130:	c3                   	ret    

00800131 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800131:	55                   	push   %ebp
  800132:	89 e5                	mov    %esp,%ebp
  800134:	57                   	push   %edi
  800135:	56                   	push   %esi
  800136:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800137:	ba 00 00 00 00       	mov    $0x0,%edx
  80013c:	b8 02 00 00 00       	mov    $0x2,%eax
  800141:	89 d1                	mov    %edx,%ecx
  800143:	89 d3                	mov    %edx,%ebx
  800145:	89 d7                	mov    %edx,%edi
  800147:	89 d6                	mov    %edx,%esi
  800149:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80014b:	5b                   	pop    %ebx
  80014c:	5e                   	pop    %esi
  80014d:	5f                   	pop    %edi
  80014e:	5d                   	pop    %ebp
  80014f:	c3                   	ret    

00800150 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800150:	55                   	push   %ebp
  800151:	89 e5                	mov    %esp,%ebp
  800153:	56                   	push   %esi
  800154:	53                   	push   %ebx
  800155:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800158:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  80015b:	a1 08 20 80 00       	mov    0x802008,%eax
  800160:	85 c0                	test   %eax,%eax
  800162:	74 10                	je     800174 <_panic+0x24>
		cprintf("%s: ", argv0);
  800164:	89 44 24 04          	mov    %eax,0x4(%esp)
  800168:	c7 04 24 5d 0f 80 00 	movl   $0x800f5d,(%esp)
  80016f:	e8 ee 00 00 00       	call   800262 <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800174:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80017a:	e8 b2 ff ff ff       	call   800131 <sys_getenvid>
  80017f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800182:	89 54 24 10          	mov    %edx,0x10(%esp)
  800186:	8b 55 08             	mov    0x8(%ebp),%edx
  800189:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80018d:	89 74 24 08          	mov    %esi,0x8(%esp)
  800191:	89 44 24 04          	mov    %eax,0x4(%esp)
  800195:	c7 04 24 64 0f 80 00 	movl   $0x800f64,(%esp)
  80019c:	e8 c1 00 00 00       	call   800262 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001a1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001a5:	8b 45 10             	mov    0x10(%ebp),%eax
  8001a8:	89 04 24             	mov    %eax,(%esp)
  8001ab:	e8 51 00 00 00       	call   800201 <vcprintf>
	cprintf("\n");
  8001b0:	c7 04 24 62 0f 80 00 	movl   $0x800f62,(%esp)
  8001b7:	e8 a6 00 00 00       	call   800262 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001bc:	cc                   	int3   
  8001bd:	eb fd                	jmp    8001bc <_panic+0x6c>

008001bf <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001bf:	55                   	push   %ebp
  8001c0:	89 e5                	mov    %esp,%ebp
  8001c2:	53                   	push   %ebx
  8001c3:	83 ec 14             	sub    $0x14,%esp
  8001c6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001c9:	8b 13                	mov    (%ebx),%edx
  8001cb:	8d 42 01             	lea    0x1(%edx),%eax
  8001ce:	89 03                	mov    %eax,(%ebx)
  8001d0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001d3:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001d7:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001dc:	75 19                	jne    8001f7 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001de:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001e5:	00 
  8001e6:	8d 43 08             	lea    0x8(%ebx),%eax
  8001e9:	89 04 24             	mov    %eax,(%esp)
  8001ec:	e8 b1 fe ff ff       	call   8000a2 <sys_cputs>
		b->idx = 0;
  8001f1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001f7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001fb:	83 c4 14             	add    $0x14,%esp
  8001fe:	5b                   	pop    %ebx
  8001ff:	5d                   	pop    %ebp
  800200:	c3                   	ret    

00800201 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800201:	55                   	push   %ebp
  800202:	89 e5                	mov    %esp,%ebp
  800204:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80020a:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800211:	00 00 00 
	b.cnt = 0;
  800214:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80021b:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80021e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800221:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800225:	8b 45 08             	mov    0x8(%ebp),%eax
  800228:	89 44 24 08          	mov    %eax,0x8(%esp)
  80022c:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800232:	89 44 24 04          	mov    %eax,0x4(%esp)
  800236:	c7 04 24 bf 01 80 00 	movl   $0x8001bf,(%esp)
  80023d:	e8 b2 01 00 00       	call   8003f4 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800242:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800248:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024c:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800252:	89 04 24             	mov    %eax,(%esp)
  800255:	e8 48 fe ff ff       	call   8000a2 <sys_cputs>

	return b.cnt;
}
  80025a:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800260:	c9                   	leave  
  800261:	c3                   	ret    

00800262 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800262:	55                   	push   %ebp
  800263:	89 e5                	mov    %esp,%ebp
  800265:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800268:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80026b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80026f:	8b 45 08             	mov    0x8(%ebp),%eax
  800272:	89 04 24             	mov    %eax,(%esp)
  800275:	e8 87 ff ff ff       	call   800201 <vcprintf>
	va_end(ap);

	return cnt;
}
  80027a:	c9                   	leave  
  80027b:	c3                   	ret    
  80027c:	66 90                	xchg   %ax,%ax
  80027e:	66 90                	xchg   %ax,%ax

00800280 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800280:	55                   	push   %ebp
  800281:	89 e5                	mov    %esp,%ebp
  800283:	57                   	push   %edi
  800284:	56                   	push   %esi
  800285:	53                   	push   %ebx
  800286:	83 ec 3c             	sub    $0x3c,%esp
  800289:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80028c:	89 d7                	mov    %edx,%edi
  80028e:	8b 45 08             	mov    0x8(%ebp),%eax
  800291:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800294:	8b 75 0c             	mov    0xc(%ebp),%esi
  800297:	89 75 d4             	mov    %esi,-0x2c(%ebp)
  80029a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80029d:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002a2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002a5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8002a8:	39 f1                	cmp    %esi,%ecx
  8002aa:	72 14                	jb     8002c0 <printnum+0x40>
  8002ac:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8002af:	76 0f                	jbe    8002c0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8002b4:	8d 70 ff             	lea    -0x1(%eax),%esi
  8002b7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8002ba:	85 f6                	test   %esi,%esi
  8002bc:	7f 60                	jg     80031e <printnum+0x9e>
  8002be:	eb 72                	jmp    800332 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002c0:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8002c3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8002c7:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8002ca:	8d 51 ff             	lea    -0x1(%ecx),%edx
  8002cd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8002d1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002d5:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002d9:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002dd:	89 c3                	mov    %eax,%ebx
  8002df:	89 d6                	mov    %edx,%esi
  8002e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002e4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002e7:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002eb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002f2:	89 04 24             	mov    %eax,(%esp)
  8002f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002fc:	e8 9f 09 00 00       	call   800ca0 <__udivdi3>
  800301:	89 d9                	mov    %ebx,%ecx
  800303:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800307:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80030b:	89 04 24             	mov    %eax,(%esp)
  80030e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800312:	89 fa                	mov    %edi,%edx
  800314:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800317:	e8 64 ff ff ff       	call   800280 <printnum>
  80031c:	eb 14                	jmp    800332 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80031e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800322:	8b 45 18             	mov    0x18(%ebp),%eax
  800325:	89 04 24             	mov    %eax,(%esp)
  800328:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80032a:	83 ee 01             	sub    $0x1,%esi
  80032d:	75 ef                	jne    80031e <printnum+0x9e>
  80032f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800332:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800336:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80033a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80033d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800340:	89 44 24 08          	mov    %eax,0x8(%esp)
  800344:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800348:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80034b:	89 04 24             	mov    %eax,(%esp)
  80034e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800351:	89 44 24 04          	mov    %eax,0x4(%esp)
  800355:	e8 76 0a 00 00       	call   800dd0 <__umoddi3>
  80035a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80035e:	0f be 80 88 0f 80 00 	movsbl 0x800f88(%eax),%eax
  800365:	89 04 24             	mov    %eax,(%esp)
  800368:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80036b:	ff d0                	call   *%eax
}
  80036d:	83 c4 3c             	add    $0x3c,%esp
  800370:	5b                   	pop    %ebx
  800371:	5e                   	pop    %esi
  800372:	5f                   	pop    %edi
  800373:	5d                   	pop    %ebp
  800374:	c3                   	ret    

00800375 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800375:	55                   	push   %ebp
  800376:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800378:	83 fa 01             	cmp    $0x1,%edx
  80037b:	7e 0e                	jle    80038b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80037d:	8b 10                	mov    (%eax),%edx
  80037f:	8d 4a 08             	lea    0x8(%edx),%ecx
  800382:	89 08                	mov    %ecx,(%eax)
  800384:	8b 02                	mov    (%edx),%eax
  800386:	8b 52 04             	mov    0x4(%edx),%edx
  800389:	eb 22                	jmp    8003ad <getuint+0x38>
	else if (lflag)
  80038b:	85 d2                	test   %edx,%edx
  80038d:	74 10                	je     80039f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80038f:	8b 10                	mov    (%eax),%edx
  800391:	8d 4a 04             	lea    0x4(%edx),%ecx
  800394:	89 08                	mov    %ecx,(%eax)
  800396:	8b 02                	mov    (%edx),%eax
  800398:	ba 00 00 00 00       	mov    $0x0,%edx
  80039d:	eb 0e                	jmp    8003ad <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80039f:	8b 10                	mov    (%eax),%edx
  8003a1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003a4:	89 08                	mov    %ecx,(%eax)
  8003a6:	8b 02                	mov    (%edx),%eax
  8003a8:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003ad:	5d                   	pop    %ebp
  8003ae:	c3                   	ret    

008003af <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003af:	55                   	push   %ebp
  8003b0:	89 e5                	mov    %esp,%ebp
  8003b2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003b5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003b9:	8b 10                	mov    (%eax),%edx
  8003bb:	3b 50 04             	cmp    0x4(%eax),%edx
  8003be:	73 0a                	jae    8003ca <sprintputch+0x1b>
		*b->buf++ = ch;
  8003c0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8003c3:	89 08                	mov    %ecx,(%eax)
  8003c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8003c8:	88 02                	mov    %al,(%edx)
}
  8003ca:	5d                   	pop    %ebp
  8003cb:	c3                   	ret    

008003cc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003cc:	55                   	push   %ebp
  8003cd:	89 e5                	mov    %esp,%ebp
  8003cf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003d2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003d9:	8b 45 10             	mov    0x10(%ebp),%eax
  8003dc:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003e7:	8b 45 08             	mov    0x8(%ebp),%eax
  8003ea:	89 04 24             	mov    %eax,(%esp)
  8003ed:	e8 02 00 00 00       	call   8003f4 <vprintfmt>
	va_end(ap);
}
  8003f2:	c9                   	leave  
  8003f3:	c3                   	ret    

008003f4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003f4:	55                   	push   %ebp
  8003f5:	89 e5                	mov    %esp,%ebp
  8003f7:	57                   	push   %edi
  8003f8:	56                   	push   %esi
  8003f9:	53                   	push   %ebx
  8003fa:	83 ec 3c             	sub    $0x3c,%esp
  8003fd:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800400:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800403:	eb 18                	jmp    80041d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800405:	85 c0                	test   %eax,%eax
  800407:	0f 84 c3 03 00 00    	je     8007d0 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
  80040d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800411:	89 04 24             	mov    %eax,(%esp)
  800414:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800417:	89 f3                	mov    %esi,%ebx
  800419:	eb 02                	jmp    80041d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
  80041b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80041d:	8d 73 01             	lea    0x1(%ebx),%esi
  800420:	0f b6 03             	movzbl (%ebx),%eax
  800423:	83 f8 25             	cmp    $0x25,%eax
  800426:	75 dd                	jne    800405 <vprintfmt+0x11>
  800428:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
  80042c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800433:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  80043a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800441:	ba 00 00 00 00       	mov    $0x0,%edx
  800446:	eb 1d                	jmp    800465 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800448:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80044a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
  80044e:	eb 15                	jmp    800465 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800450:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800452:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
  800456:	eb 0d                	jmp    800465 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800458:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80045b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80045e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800465:	8d 5e 01             	lea    0x1(%esi),%ebx
  800468:	0f b6 06             	movzbl (%esi),%eax
  80046b:	0f b6 c8             	movzbl %al,%ecx
  80046e:	83 e8 23             	sub    $0x23,%eax
  800471:	3c 55                	cmp    $0x55,%al
  800473:	0f 87 2f 03 00 00    	ja     8007a8 <vprintfmt+0x3b4>
  800479:	0f b6 c0             	movzbl %al,%eax
  80047c:	ff 24 85 18 10 80 00 	jmp    *0x801018(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800483:	8d 41 d0             	lea    -0x30(%ecx),%eax
  800486:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
  800489:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
  80048d:	8d 48 d0             	lea    -0x30(%eax),%ecx
  800490:	83 f9 09             	cmp    $0x9,%ecx
  800493:	77 50                	ja     8004e5 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800495:	89 de                	mov    %ebx,%esi
  800497:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80049a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
  80049d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8004a0:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8004a4:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8004a7:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8004aa:	83 fb 09             	cmp    $0x9,%ebx
  8004ad:	76 eb                	jbe    80049a <vprintfmt+0xa6>
  8004af:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8004b2:	eb 33                	jmp    8004e7 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b7:	8d 48 04             	lea    0x4(%eax),%ecx
  8004ba:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004bd:	8b 00                	mov    (%eax),%eax
  8004bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c2:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004c4:	eb 21                	jmp    8004e7 <vprintfmt+0xf3>
  8004c6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8004c9:	85 c9                	test   %ecx,%ecx
  8004cb:	b8 00 00 00 00       	mov    $0x0,%eax
  8004d0:	0f 49 c1             	cmovns %ecx,%eax
  8004d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d6:	89 de                	mov    %ebx,%esi
  8004d8:	eb 8b                	jmp    800465 <vprintfmt+0x71>
  8004da:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004dc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8004e3:	eb 80                	jmp    800465 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e5:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8004e7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004eb:	0f 89 74 ff ff ff    	jns    800465 <vprintfmt+0x71>
  8004f1:	e9 62 ff ff ff       	jmp    800458 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004f6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f9:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004fb:	e9 65 ff ff ff       	jmp    800465 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800500:	8b 45 14             	mov    0x14(%ebp),%eax
  800503:	8d 50 04             	lea    0x4(%eax),%edx
  800506:	89 55 14             	mov    %edx,0x14(%ebp)
  800509:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80050d:	8b 00                	mov    (%eax),%eax
  80050f:	89 04 24             	mov    %eax,(%esp)
  800512:	ff 55 08             	call   *0x8(%ebp)
			break;
  800515:	e9 03 ff ff ff       	jmp    80041d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80051a:	8b 45 14             	mov    0x14(%ebp),%eax
  80051d:	8d 50 04             	lea    0x4(%eax),%edx
  800520:	89 55 14             	mov    %edx,0x14(%ebp)
  800523:	8b 00                	mov    (%eax),%eax
  800525:	99                   	cltd   
  800526:	31 d0                	xor    %edx,%eax
  800528:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80052a:	83 f8 06             	cmp    $0x6,%eax
  80052d:	7f 0b                	jg     80053a <vprintfmt+0x146>
  80052f:	8b 14 85 70 11 80 00 	mov    0x801170(,%eax,4),%edx
  800536:	85 d2                	test   %edx,%edx
  800538:	75 20                	jne    80055a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
  80053a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80053e:	c7 44 24 08 a0 0f 80 	movl   $0x800fa0,0x8(%esp)
  800545:	00 
  800546:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80054a:	8b 45 08             	mov    0x8(%ebp),%eax
  80054d:	89 04 24             	mov    %eax,(%esp)
  800550:	e8 77 fe ff ff       	call   8003cc <printfmt>
  800555:	e9 c3 fe ff ff       	jmp    80041d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
  80055a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80055e:	c7 44 24 08 a9 0f 80 	movl   $0x800fa9,0x8(%esp)
  800565:	00 
  800566:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80056a:	8b 45 08             	mov    0x8(%ebp),%eax
  80056d:	89 04 24             	mov    %eax,(%esp)
  800570:	e8 57 fe ff ff       	call   8003cc <printfmt>
  800575:	e9 a3 fe ff ff       	jmp    80041d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80057a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80057d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800580:	8b 45 14             	mov    0x14(%ebp),%eax
  800583:	8d 50 04             	lea    0x4(%eax),%edx
  800586:	89 55 14             	mov    %edx,0x14(%ebp)
  800589:	8b 00                	mov    (%eax),%eax
				p = "(null)";
  80058b:	85 c0                	test   %eax,%eax
  80058d:	ba 99 0f 80 00       	mov    $0x800f99,%edx
  800592:	0f 45 d0             	cmovne %eax,%edx
  800595:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
  800598:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
  80059c:	74 04                	je     8005a2 <vprintfmt+0x1ae>
  80059e:	85 f6                	test   %esi,%esi
  8005a0:	7f 19                	jg     8005bb <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005a2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005a5:	8d 70 01             	lea    0x1(%eax),%esi
  8005a8:	0f b6 10             	movzbl (%eax),%edx
  8005ab:	0f be c2             	movsbl %dl,%eax
  8005ae:	85 c0                	test   %eax,%eax
  8005b0:	0f 85 95 00 00 00    	jne    80064b <vprintfmt+0x257>
  8005b6:	e9 85 00 00 00       	jmp    800640 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005bb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005c2:	89 04 24             	mov    %eax,(%esp)
  8005c5:	e8 b8 02 00 00       	call   800882 <strnlen>
  8005ca:	29 c6                	sub    %eax,%esi
  8005cc:	89 f0                	mov    %esi,%eax
  8005ce:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8005d1:	85 f6                	test   %esi,%esi
  8005d3:	7e cd                	jle    8005a2 <vprintfmt+0x1ae>
					putch(padc, putdat);
  8005d5:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  8005d9:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005dc:	89 c3                	mov    %eax,%ebx
  8005de:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005e2:	89 34 24             	mov    %esi,(%esp)
  8005e5:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005e8:	83 eb 01             	sub    $0x1,%ebx
  8005eb:	75 f1                	jne    8005de <vprintfmt+0x1ea>
  8005ed:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8005f0:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8005f3:	eb ad                	jmp    8005a2 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005f5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8005f9:	74 1e                	je     800619 <vprintfmt+0x225>
  8005fb:	0f be d2             	movsbl %dl,%edx
  8005fe:	83 ea 20             	sub    $0x20,%edx
  800601:	83 fa 5e             	cmp    $0x5e,%edx
  800604:	76 13                	jbe    800619 <vprintfmt+0x225>
					putch('?', putdat);
  800606:	8b 45 0c             	mov    0xc(%ebp),%eax
  800609:	89 44 24 04          	mov    %eax,0x4(%esp)
  80060d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800614:	ff 55 08             	call   *0x8(%ebp)
  800617:	eb 0d                	jmp    800626 <vprintfmt+0x232>
				else
					putch(ch, putdat);
  800619:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80061c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800620:	89 04 24             	mov    %eax,(%esp)
  800623:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800626:	83 ef 01             	sub    $0x1,%edi
  800629:	83 c6 01             	add    $0x1,%esi
  80062c:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800630:	0f be c2             	movsbl %dl,%eax
  800633:	85 c0                	test   %eax,%eax
  800635:	75 20                	jne    800657 <vprintfmt+0x263>
  800637:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  80063a:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80063d:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800640:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800644:	7f 25                	jg     80066b <vprintfmt+0x277>
  800646:	e9 d2 fd ff ff       	jmp    80041d <vprintfmt+0x29>
  80064b:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80064e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800651:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800654:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800657:	85 db                	test   %ebx,%ebx
  800659:	78 9a                	js     8005f5 <vprintfmt+0x201>
  80065b:	83 eb 01             	sub    $0x1,%ebx
  80065e:	79 95                	jns    8005f5 <vprintfmt+0x201>
  800660:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  800663:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800666:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800669:	eb d5                	jmp    800640 <vprintfmt+0x24c>
  80066b:	8b 75 08             	mov    0x8(%ebp),%esi
  80066e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800671:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800674:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800678:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80067f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800681:	83 eb 01             	sub    $0x1,%ebx
  800684:	75 ee                	jne    800674 <vprintfmt+0x280>
  800686:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800689:	e9 8f fd ff ff       	jmp    80041d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80068e:	83 fa 01             	cmp    $0x1,%edx
  800691:	7e 16                	jle    8006a9 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
  800693:	8b 45 14             	mov    0x14(%ebp),%eax
  800696:	8d 50 08             	lea    0x8(%eax),%edx
  800699:	89 55 14             	mov    %edx,0x14(%ebp)
  80069c:	8b 50 04             	mov    0x4(%eax),%edx
  80069f:	8b 00                	mov    (%eax),%eax
  8006a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006a4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8006a7:	eb 32                	jmp    8006db <vprintfmt+0x2e7>
	else if (lflag)
  8006a9:	85 d2                	test   %edx,%edx
  8006ab:	74 18                	je     8006c5 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
  8006ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b0:	8d 50 04             	lea    0x4(%eax),%edx
  8006b3:	89 55 14             	mov    %edx,0x14(%ebp)
  8006b6:	8b 30                	mov    (%eax),%esi
  8006b8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8006bb:	89 f0                	mov    %esi,%eax
  8006bd:	c1 f8 1f             	sar    $0x1f,%eax
  8006c0:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8006c3:	eb 16                	jmp    8006db <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
  8006c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c8:	8d 50 04             	lea    0x4(%eax),%edx
  8006cb:	89 55 14             	mov    %edx,0x14(%ebp)
  8006ce:	8b 30                	mov    (%eax),%esi
  8006d0:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8006d3:	89 f0                	mov    %esi,%eax
  8006d5:	c1 f8 1f             	sar    $0x1f,%eax
  8006d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006db:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8006de:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006e1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006e6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8006ea:	0f 89 80 00 00 00    	jns    800770 <vprintfmt+0x37c>
				putch('-', putdat);
  8006f0:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006f4:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006fb:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006fe:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800701:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800704:	f7 d8                	neg    %eax
  800706:	83 d2 00             	adc    $0x0,%edx
  800709:	f7 da                	neg    %edx
			}
			base = 10;
  80070b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800710:	eb 5e                	jmp    800770 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800712:	8d 45 14             	lea    0x14(%ebp),%eax
  800715:	e8 5b fc ff ff       	call   800375 <getuint>
			base = 10;
  80071a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80071f:	eb 4f                	jmp    800770 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
  800721:	8d 45 14             	lea    0x14(%ebp),%eax
  800724:	e8 4c fc ff ff       	call   800375 <getuint>
			base = 8;
  800729:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80072e:	eb 40                	jmp    800770 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
  800730:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800734:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80073b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  80073e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800742:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800749:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80074c:	8b 45 14             	mov    0x14(%ebp),%eax
  80074f:	8d 50 04             	lea    0x4(%eax),%edx
  800752:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800755:	8b 00                	mov    (%eax),%eax
  800757:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80075c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800761:	eb 0d                	jmp    800770 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800763:	8d 45 14             	lea    0x14(%ebp),%eax
  800766:	e8 0a fc ff ff       	call   800375 <getuint>
			base = 16;
  80076b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800770:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  800774:	89 74 24 10          	mov    %esi,0x10(%esp)
  800778:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80077b:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80077f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800783:	89 04 24             	mov    %eax,(%esp)
  800786:	89 54 24 04          	mov    %edx,0x4(%esp)
  80078a:	89 fa                	mov    %edi,%edx
  80078c:	8b 45 08             	mov    0x8(%ebp),%eax
  80078f:	e8 ec fa ff ff       	call   800280 <printnum>
			break;
  800794:	e9 84 fc ff ff       	jmp    80041d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800799:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80079d:	89 0c 24             	mov    %ecx,(%esp)
  8007a0:	ff 55 08             	call   *0x8(%ebp)
			break;
  8007a3:	e9 75 fc ff ff       	jmp    80041d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007ac:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007b3:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007b6:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  8007ba:	0f 84 5b fc ff ff    	je     80041b <vprintfmt+0x27>
  8007c0:	89 f3                	mov    %esi,%ebx
  8007c2:	83 eb 01             	sub    $0x1,%ebx
  8007c5:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8007c9:	75 f7                	jne    8007c2 <vprintfmt+0x3ce>
  8007cb:	e9 4d fc ff ff       	jmp    80041d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
  8007d0:	83 c4 3c             	add    $0x3c,%esp
  8007d3:	5b                   	pop    %ebx
  8007d4:	5e                   	pop    %esi
  8007d5:	5f                   	pop    %edi
  8007d6:	5d                   	pop    %ebp
  8007d7:	c3                   	ret    

008007d8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007d8:	55                   	push   %ebp
  8007d9:	89 e5                	mov    %esp,%ebp
  8007db:	83 ec 28             	sub    $0x28,%esp
  8007de:	8b 45 08             	mov    0x8(%ebp),%eax
  8007e1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007e7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007eb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007f5:	85 c0                	test   %eax,%eax
  8007f7:	74 30                	je     800829 <vsnprintf+0x51>
  8007f9:	85 d2                	test   %edx,%edx
  8007fb:	7e 2c                	jle    800829 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800800:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800804:	8b 45 10             	mov    0x10(%ebp),%eax
  800807:	89 44 24 08          	mov    %eax,0x8(%esp)
  80080b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80080e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800812:	c7 04 24 af 03 80 00 	movl   $0x8003af,(%esp)
  800819:	e8 d6 fb ff ff       	call   8003f4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80081e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800821:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800824:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800827:	eb 05                	jmp    80082e <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800829:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80082e:	c9                   	leave  
  80082f:	c3                   	ret    

00800830 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800830:	55                   	push   %ebp
  800831:	89 e5                	mov    %esp,%ebp
  800833:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800836:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800839:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80083d:	8b 45 10             	mov    0x10(%ebp),%eax
  800840:	89 44 24 08          	mov    %eax,0x8(%esp)
  800844:	8b 45 0c             	mov    0xc(%ebp),%eax
  800847:	89 44 24 04          	mov    %eax,0x4(%esp)
  80084b:	8b 45 08             	mov    0x8(%ebp),%eax
  80084e:	89 04 24             	mov    %eax,(%esp)
  800851:	e8 82 ff ff ff       	call   8007d8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800856:	c9                   	leave  
  800857:	c3                   	ret    
  800858:	66 90                	xchg   %ax,%ax
  80085a:	66 90                	xchg   %ax,%ax
  80085c:	66 90                	xchg   %ax,%ax
  80085e:	66 90                	xchg   %ax,%ax

00800860 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800860:	55                   	push   %ebp
  800861:	89 e5                	mov    %esp,%ebp
  800863:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800866:	80 3a 00             	cmpb   $0x0,(%edx)
  800869:	74 10                	je     80087b <strlen+0x1b>
  80086b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800870:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800873:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800877:	75 f7                	jne    800870 <strlen+0x10>
  800879:	eb 05                	jmp    800880 <strlen+0x20>
  80087b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800880:	5d                   	pop    %ebp
  800881:	c3                   	ret    

00800882 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800882:	55                   	push   %ebp
  800883:	89 e5                	mov    %esp,%ebp
  800885:	53                   	push   %ebx
  800886:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800889:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80088c:	85 c9                	test   %ecx,%ecx
  80088e:	74 1c                	je     8008ac <strnlen+0x2a>
  800890:	80 3b 00             	cmpb   $0x0,(%ebx)
  800893:	74 1e                	je     8008b3 <strnlen+0x31>
  800895:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  80089a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80089c:	39 ca                	cmp    %ecx,%edx
  80089e:	74 18                	je     8008b8 <strnlen+0x36>
  8008a0:	83 c2 01             	add    $0x1,%edx
  8008a3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8008a8:	75 f0                	jne    80089a <strnlen+0x18>
  8008aa:	eb 0c                	jmp    8008b8 <strnlen+0x36>
  8008ac:	b8 00 00 00 00       	mov    $0x0,%eax
  8008b1:	eb 05                	jmp    8008b8 <strnlen+0x36>
  8008b3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8008b8:	5b                   	pop    %ebx
  8008b9:	5d                   	pop    %ebp
  8008ba:	c3                   	ret    

008008bb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008bb:	55                   	push   %ebp
  8008bc:	89 e5                	mov    %esp,%ebp
  8008be:	53                   	push   %ebx
  8008bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008c5:	89 c2                	mov    %eax,%edx
  8008c7:	83 c2 01             	add    $0x1,%edx
  8008ca:	83 c1 01             	add    $0x1,%ecx
  8008cd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008d1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008d4:	84 db                	test   %bl,%bl
  8008d6:	75 ef                	jne    8008c7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008d8:	5b                   	pop    %ebx
  8008d9:	5d                   	pop    %ebp
  8008da:	c3                   	ret    

008008db <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008db:	55                   	push   %ebp
  8008dc:	89 e5                	mov    %esp,%ebp
  8008de:	53                   	push   %ebx
  8008df:	83 ec 08             	sub    $0x8,%esp
  8008e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008e5:	89 1c 24             	mov    %ebx,(%esp)
  8008e8:	e8 73 ff ff ff       	call   800860 <strlen>
	strcpy(dst + len, src);
  8008ed:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008f0:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008f4:	01 d8                	add    %ebx,%eax
  8008f6:	89 04 24             	mov    %eax,(%esp)
  8008f9:	e8 bd ff ff ff       	call   8008bb <strcpy>
	return dst;
}
  8008fe:	89 d8                	mov    %ebx,%eax
  800900:	83 c4 08             	add    $0x8,%esp
  800903:	5b                   	pop    %ebx
  800904:	5d                   	pop    %ebp
  800905:	c3                   	ret    

00800906 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800906:	55                   	push   %ebp
  800907:	89 e5                	mov    %esp,%ebp
  800909:	56                   	push   %esi
  80090a:	53                   	push   %ebx
  80090b:	8b 75 08             	mov    0x8(%ebp),%esi
  80090e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800911:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800914:	85 db                	test   %ebx,%ebx
  800916:	74 17                	je     80092f <strncpy+0x29>
  800918:	01 f3                	add    %esi,%ebx
  80091a:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
  80091c:	83 c1 01             	add    $0x1,%ecx
  80091f:	0f b6 02             	movzbl (%edx),%eax
  800922:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800925:	80 3a 01             	cmpb   $0x1,(%edx)
  800928:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80092b:	39 d9                	cmp    %ebx,%ecx
  80092d:	75 ed                	jne    80091c <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80092f:	89 f0                	mov    %esi,%eax
  800931:	5b                   	pop    %ebx
  800932:	5e                   	pop    %esi
  800933:	5d                   	pop    %ebp
  800934:	c3                   	ret    

00800935 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800935:	55                   	push   %ebp
  800936:	89 e5                	mov    %esp,%ebp
  800938:	57                   	push   %edi
  800939:	56                   	push   %esi
  80093a:	53                   	push   %ebx
  80093b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80093e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800941:	8b 75 10             	mov    0x10(%ebp),%esi
  800944:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800946:	85 f6                	test   %esi,%esi
  800948:	74 34                	je     80097e <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
  80094a:	83 fe 01             	cmp    $0x1,%esi
  80094d:	74 26                	je     800975 <strlcpy+0x40>
  80094f:	0f b6 0b             	movzbl (%ebx),%ecx
  800952:	84 c9                	test   %cl,%cl
  800954:	74 23                	je     800979 <strlcpy+0x44>
  800956:	83 ee 02             	sub    $0x2,%esi
  800959:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
  80095e:	83 c0 01             	add    $0x1,%eax
  800961:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800964:	39 f2                	cmp    %esi,%edx
  800966:	74 13                	je     80097b <strlcpy+0x46>
  800968:	83 c2 01             	add    $0x1,%edx
  80096b:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80096f:	84 c9                	test   %cl,%cl
  800971:	75 eb                	jne    80095e <strlcpy+0x29>
  800973:	eb 06                	jmp    80097b <strlcpy+0x46>
  800975:	89 f8                	mov    %edi,%eax
  800977:	eb 02                	jmp    80097b <strlcpy+0x46>
  800979:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  80097b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80097e:	29 f8                	sub    %edi,%eax
}
  800980:	5b                   	pop    %ebx
  800981:	5e                   	pop    %esi
  800982:	5f                   	pop    %edi
  800983:	5d                   	pop    %ebp
  800984:	c3                   	ret    

00800985 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800985:	55                   	push   %ebp
  800986:	89 e5                	mov    %esp,%ebp
  800988:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80098b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80098e:	0f b6 01             	movzbl (%ecx),%eax
  800991:	84 c0                	test   %al,%al
  800993:	74 15                	je     8009aa <strcmp+0x25>
  800995:	3a 02                	cmp    (%edx),%al
  800997:	75 11                	jne    8009aa <strcmp+0x25>
		p++, q++;
  800999:	83 c1 01             	add    $0x1,%ecx
  80099c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80099f:	0f b6 01             	movzbl (%ecx),%eax
  8009a2:	84 c0                	test   %al,%al
  8009a4:	74 04                	je     8009aa <strcmp+0x25>
  8009a6:	3a 02                	cmp    (%edx),%al
  8009a8:	74 ef                	je     800999 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009aa:	0f b6 c0             	movzbl %al,%eax
  8009ad:	0f b6 12             	movzbl (%edx),%edx
  8009b0:	29 d0                	sub    %edx,%eax
}
  8009b2:	5d                   	pop    %ebp
  8009b3:	c3                   	ret    

008009b4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009b4:	55                   	push   %ebp
  8009b5:	89 e5                	mov    %esp,%ebp
  8009b7:	56                   	push   %esi
  8009b8:	53                   	push   %ebx
  8009b9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8009bc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009bf:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8009c2:	85 f6                	test   %esi,%esi
  8009c4:	74 29                	je     8009ef <strncmp+0x3b>
  8009c6:	0f b6 03             	movzbl (%ebx),%eax
  8009c9:	84 c0                	test   %al,%al
  8009cb:	74 30                	je     8009fd <strncmp+0x49>
  8009cd:	3a 02                	cmp    (%edx),%al
  8009cf:	75 2c                	jne    8009fd <strncmp+0x49>
  8009d1:	8d 43 01             	lea    0x1(%ebx),%eax
  8009d4:	01 de                	add    %ebx,%esi
		n--, p++, q++;
  8009d6:	89 c3                	mov    %eax,%ebx
  8009d8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009db:	39 f0                	cmp    %esi,%eax
  8009dd:	74 17                	je     8009f6 <strncmp+0x42>
  8009df:	0f b6 08             	movzbl (%eax),%ecx
  8009e2:	84 c9                	test   %cl,%cl
  8009e4:	74 17                	je     8009fd <strncmp+0x49>
  8009e6:	83 c0 01             	add    $0x1,%eax
  8009e9:	3a 0a                	cmp    (%edx),%cl
  8009eb:	74 e9                	je     8009d6 <strncmp+0x22>
  8009ed:	eb 0e                	jmp    8009fd <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009ef:	b8 00 00 00 00       	mov    $0x0,%eax
  8009f4:	eb 0f                	jmp    800a05 <strncmp+0x51>
  8009f6:	b8 00 00 00 00       	mov    $0x0,%eax
  8009fb:	eb 08                	jmp    800a05 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8009fd:	0f b6 03             	movzbl (%ebx),%eax
  800a00:	0f b6 12             	movzbl (%edx),%edx
  800a03:	29 d0                	sub    %edx,%eax
}
  800a05:	5b                   	pop    %ebx
  800a06:	5e                   	pop    %esi
  800a07:	5d                   	pop    %ebp
  800a08:	c3                   	ret    

00800a09 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a09:	55                   	push   %ebp
  800a0a:	89 e5                	mov    %esp,%ebp
  800a0c:	53                   	push   %ebx
  800a0d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a10:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a13:	0f b6 18             	movzbl (%eax),%ebx
  800a16:	84 db                	test   %bl,%bl
  800a18:	74 1d                	je     800a37 <strchr+0x2e>
  800a1a:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a1c:	38 d3                	cmp    %dl,%bl
  800a1e:	75 06                	jne    800a26 <strchr+0x1d>
  800a20:	eb 1a                	jmp    800a3c <strchr+0x33>
  800a22:	38 ca                	cmp    %cl,%dl
  800a24:	74 16                	je     800a3c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a26:	83 c0 01             	add    $0x1,%eax
  800a29:	0f b6 10             	movzbl (%eax),%edx
  800a2c:	84 d2                	test   %dl,%dl
  800a2e:	75 f2                	jne    800a22 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800a30:	b8 00 00 00 00       	mov    $0x0,%eax
  800a35:	eb 05                	jmp    800a3c <strchr+0x33>
  800a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a3c:	5b                   	pop    %ebx
  800a3d:	5d                   	pop    %ebp
  800a3e:	c3                   	ret    

00800a3f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a3f:	55                   	push   %ebp
  800a40:	89 e5                	mov    %esp,%ebp
  800a42:	53                   	push   %ebx
  800a43:	8b 45 08             	mov    0x8(%ebp),%eax
  800a46:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a49:	0f b6 18             	movzbl (%eax),%ebx
  800a4c:	84 db                	test   %bl,%bl
  800a4e:	74 16                	je     800a66 <strfind+0x27>
  800a50:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a52:	38 d3                	cmp    %dl,%bl
  800a54:	75 06                	jne    800a5c <strfind+0x1d>
  800a56:	eb 0e                	jmp    800a66 <strfind+0x27>
  800a58:	38 ca                	cmp    %cl,%dl
  800a5a:	74 0a                	je     800a66 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a5c:	83 c0 01             	add    $0x1,%eax
  800a5f:	0f b6 10             	movzbl (%eax),%edx
  800a62:	84 d2                	test   %dl,%dl
  800a64:	75 f2                	jne    800a58 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800a66:	5b                   	pop    %ebx
  800a67:	5d                   	pop    %ebp
  800a68:	c3                   	ret    

00800a69 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a69:	55                   	push   %ebp
  800a6a:	89 e5                	mov    %esp,%ebp
  800a6c:	57                   	push   %edi
  800a6d:	56                   	push   %esi
  800a6e:	53                   	push   %ebx
  800a6f:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a72:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a75:	85 c9                	test   %ecx,%ecx
  800a77:	74 36                	je     800aaf <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a79:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a7f:	75 28                	jne    800aa9 <memset+0x40>
  800a81:	f6 c1 03             	test   $0x3,%cl
  800a84:	75 23                	jne    800aa9 <memset+0x40>
		c &= 0xFF;
  800a86:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a8a:	89 d3                	mov    %edx,%ebx
  800a8c:	c1 e3 08             	shl    $0x8,%ebx
  800a8f:	89 d6                	mov    %edx,%esi
  800a91:	c1 e6 18             	shl    $0x18,%esi
  800a94:	89 d0                	mov    %edx,%eax
  800a96:	c1 e0 10             	shl    $0x10,%eax
  800a99:	09 f0                	or     %esi,%eax
  800a9b:	09 c2                	or     %eax,%edx
  800a9d:	89 d0                	mov    %edx,%eax
  800a9f:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800aa1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800aa4:	fc                   	cld    
  800aa5:	f3 ab                	rep stos %eax,%es:(%edi)
  800aa7:	eb 06                	jmp    800aaf <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800aa9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aac:	fc                   	cld    
  800aad:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800aaf:	89 f8                	mov    %edi,%eax
  800ab1:	5b                   	pop    %ebx
  800ab2:	5e                   	pop    %esi
  800ab3:	5f                   	pop    %edi
  800ab4:	5d                   	pop    %ebp
  800ab5:	c3                   	ret    

00800ab6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800ab6:	55                   	push   %ebp
  800ab7:	89 e5                	mov    %esp,%ebp
  800ab9:	57                   	push   %edi
  800aba:	56                   	push   %esi
  800abb:	8b 45 08             	mov    0x8(%ebp),%eax
  800abe:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ac1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800ac4:	39 c6                	cmp    %eax,%esi
  800ac6:	73 35                	jae    800afd <memmove+0x47>
  800ac8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800acb:	39 d0                	cmp    %edx,%eax
  800acd:	73 2e                	jae    800afd <memmove+0x47>
		s += n;
		d += n;
  800acf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800ad2:	89 d6                	mov    %edx,%esi
  800ad4:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ad6:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800adc:	75 13                	jne    800af1 <memmove+0x3b>
  800ade:	f6 c1 03             	test   $0x3,%cl
  800ae1:	75 0e                	jne    800af1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ae3:	83 ef 04             	sub    $0x4,%edi
  800ae6:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ae9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800aec:	fd                   	std    
  800aed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aef:	eb 09                	jmp    800afa <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800af1:	83 ef 01             	sub    $0x1,%edi
  800af4:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800af7:	fd                   	std    
  800af8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800afa:	fc                   	cld    
  800afb:	eb 1d                	jmp    800b1a <memmove+0x64>
  800afd:	89 f2                	mov    %esi,%edx
  800aff:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b01:	f6 c2 03             	test   $0x3,%dl
  800b04:	75 0f                	jne    800b15 <memmove+0x5f>
  800b06:	f6 c1 03             	test   $0x3,%cl
  800b09:	75 0a                	jne    800b15 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800b0b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800b0e:	89 c7                	mov    %eax,%edi
  800b10:	fc                   	cld    
  800b11:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b13:	eb 05                	jmp    800b1a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b15:	89 c7                	mov    %eax,%edi
  800b17:	fc                   	cld    
  800b18:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b1a:	5e                   	pop    %esi
  800b1b:	5f                   	pop    %edi
  800b1c:	5d                   	pop    %ebp
  800b1d:	c3                   	ret    

00800b1e <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800b1e:	55                   	push   %ebp
  800b1f:	89 e5                	mov    %esp,%ebp
  800b21:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b24:	8b 45 10             	mov    0x10(%ebp),%eax
  800b27:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b2b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b2e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b32:	8b 45 08             	mov    0x8(%ebp),%eax
  800b35:	89 04 24             	mov    %eax,(%esp)
  800b38:	e8 79 ff ff ff       	call   800ab6 <memmove>
}
  800b3d:	c9                   	leave  
  800b3e:	c3                   	ret    

00800b3f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b3f:	55                   	push   %ebp
  800b40:	89 e5                	mov    %esp,%ebp
  800b42:	57                   	push   %edi
  800b43:	56                   	push   %esi
  800b44:	53                   	push   %ebx
  800b45:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800b48:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b4b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b4e:	8d 78 ff             	lea    -0x1(%eax),%edi
  800b51:	85 c0                	test   %eax,%eax
  800b53:	74 36                	je     800b8b <memcmp+0x4c>
		if (*s1 != *s2)
  800b55:	0f b6 03             	movzbl (%ebx),%eax
  800b58:	0f b6 0e             	movzbl (%esi),%ecx
  800b5b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b60:	38 c8                	cmp    %cl,%al
  800b62:	74 1c                	je     800b80 <memcmp+0x41>
  800b64:	eb 10                	jmp    800b76 <memcmp+0x37>
  800b66:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800b6b:	83 c2 01             	add    $0x1,%edx
  800b6e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800b72:	38 c8                	cmp    %cl,%al
  800b74:	74 0a                	je     800b80 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800b76:	0f b6 c0             	movzbl %al,%eax
  800b79:	0f b6 c9             	movzbl %cl,%ecx
  800b7c:	29 c8                	sub    %ecx,%eax
  800b7e:	eb 10                	jmp    800b90 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b80:	39 fa                	cmp    %edi,%edx
  800b82:	75 e2                	jne    800b66 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b84:	b8 00 00 00 00       	mov    $0x0,%eax
  800b89:	eb 05                	jmp    800b90 <memcmp+0x51>
  800b8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b90:	5b                   	pop    %ebx
  800b91:	5e                   	pop    %esi
  800b92:	5f                   	pop    %edi
  800b93:	5d                   	pop    %ebp
  800b94:	c3                   	ret    

00800b95 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b95:	55                   	push   %ebp
  800b96:	89 e5                	mov    %esp,%ebp
  800b98:	53                   	push   %ebx
  800b99:	8b 45 08             	mov    0x8(%ebp),%eax
  800b9c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800b9f:	89 c2                	mov    %eax,%edx
  800ba1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ba4:	39 d0                	cmp    %edx,%eax
  800ba6:	73 13                	jae    800bbb <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ba8:	89 d9                	mov    %ebx,%ecx
  800baa:	38 18                	cmp    %bl,(%eax)
  800bac:	75 06                	jne    800bb4 <memfind+0x1f>
  800bae:	eb 0b                	jmp    800bbb <memfind+0x26>
  800bb0:	38 08                	cmp    %cl,(%eax)
  800bb2:	74 07                	je     800bbb <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800bb4:	83 c0 01             	add    $0x1,%eax
  800bb7:	39 d0                	cmp    %edx,%eax
  800bb9:	75 f5                	jne    800bb0 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800bbb:	5b                   	pop    %ebx
  800bbc:	5d                   	pop    %ebp
  800bbd:	c3                   	ret    

00800bbe <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800bbe:	55                   	push   %ebp
  800bbf:	89 e5                	mov    %esp,%ebp
  800bc1:	57                   	push   %edi
  800bc2:	56                   	push   %esi
  800bc3:	53                   	push   %ebx
  800bc4:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc7:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800bca:	0f b6 0a             	movzbl (%edx),%ecx
  800bcd:	80 f9 09             	cmp    $0x9,%cl
  800bd0:	74 05                	je     800bd7 <strtol+0x19>
  800bd2:	80 f9 20             	cmp    $0x20,%cl
  800bd5:	75 10                	jne    800be7 <strtol+0x29>
		s++;
  800bd7:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800bda:	0f b6 0a             	movzbl (%edx),%ecx
  800bdd:	80 f9 09             	cmp    $0x9,%cl
  800be0:	74 f5                	je     800bd7 <strtol+0x19>
  800be2:	80 f9 20             	cmp    $0x20,%cl
  800be5:	74 f0                	je     800bd7 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
  800be7:	80 f9 2b             	cmp    $0x2b,%cl
  800bea:	75 0a                	jne    800bf6 <strtol+0x38>
		s++;
  800bec:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800bef:	bf 00 00 00 00       	mov    $0x0,%edi
  800bf4:	eb 11                	jmp    800c07 <strtol+0x49>
  800bf6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800bfb:	80 f9 2d             	cmp    $0x2d,%cl
  800bfe:	75 07                	jne    800c07 <strtol+0x49>
		s++, neg = 1;
  800c00:	83 c2 01             	add    $0x1,%edx
  800c03:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c07:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800c0c:	75 15                	jne    800c23 <strtol+0x65>
  800c0e:	80 3a 30             	cmpb   $0x30,(%edx)
  800c11:	75 10                	jne    800c23 <strtol+0x65>
  800c13:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800c17:	75 0a                	jne    800c23 <strtol+0x65>
		s += 2, base = 16;
  800c19:	83 c2 02             	add    $0x2,%edx
  800c1c:	b8 10 00 00 00       	mov    $0x10,%eax
  800c21:	eb 10                	jmp    800c33 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
  800c23:	85 c0                	test   %eax,%eax
  800c25:	75 0c                	jne    800c33 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800c27:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c29:	80 3a 30             	cmpb   $0x30,(%edx)
  800c2c:	75 05                	jne    800c33 <strtol+0x75>
		s++, base = 8;
  800c2e:	83 c2 01             	add    $0x1,%edx
  800c31:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800c33:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c38:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c3b:	0f b6 0a             	movzbl (%edx),%ecx
  800c3e:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800c41:	89 f0                	mov    %esi,%eax
  800c43:	3c 09                	cmp    $0x9,%al
  800c45:	77 08                	ja     800c4f <strtol+0x91>
			dig = *s - '0';
  800c47:	0f be c9             	movsbl %cl,%ecx
  800c4a:	83 e9 30             	sub    $0x30,%ecx
  800c4d:	eb 20                	jmp    800c6f <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
  800c4f:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800c52:	89 f0                	mov    %esi,%eax
  800c54:	3c 19                	cmp    $0x19,%al
  800c56:	77 08                	ja     800c60 <strtol+0xa2>
			dig = *s - 'a' + 10;
  800c58:	0f be c9             	movsbl %cl,%ecx
  800c5b:	83 e9 57             	sub    $0x57,%ecx
  800c5e:	eb 0f                	jmp    800c6f <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
  800c60:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c63:	89 f0                	mov    %esi,%eax
  800c65:	3c 19                	cmp    $0x19,%al
  800c67:	77 16                	ja     800c7f <strtol+0xc1>
			dig = *s - 'A' + 10;
  800c69:	0f be c9             	movsbl %cl,%ecx
  800c6c:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c6f:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800c72:	7d 0f                	jge    800c83 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800c74:	83 c2 01             	add    $0x1,%edx
  800c77:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800c7b:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800c7d:	eb bc                	jmp    800c3b <strtol+0x7d>
  800c7f:	89 d8                	mov    %ebx,%eax
  800c81:	eb 02                	jmp    800c85 <strtol+0xc7>
  800c83:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800c85:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c89:	74 05                	je     800c90 <strtol+0xd2>
		*endptr = (char *) s;
  800c8b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c8e:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800c90:	f7 d8                	neg    %eax
  800c92:	85 ff                	test   %edi,%edi
  800c94:	0f 44 c3             	cmove  %ebx,%eax
}
  800c97:	5b                   	pop    %ebx
  800c98:	5e                   	pop    %esi
  800c99:	5f                   	pop    %edi
  800c9a:	5d                   	pop    %ebp
  800c9b:	c3                   	ret    
  800c9c:	66 90                	xchg   %ax,%ax
  800c9e:	66 90                	xchg   %ax,%ax

00800ca0 <__udivdi3>:
  800ca0:	55                   	push   %ebp
  800ca1:	57                   	push   %edi
  800ca2:	56                   	push   %esi
  800ca3:	83 ec 0c             	sub    $0xc,%esp
  800ca6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800caa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800cae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800cb2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800cb6:	85 c0                	test   %eax,%eax
  800cb8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800cbc:	89 ea                	mov    %ebp,%edx
  800cbe:	89 0c 24             	mov    %ecx,(%esp)
  800cc1:	75 2d                	jne    800cf0 <__udivdi3+0x50>
  800cc3:	39 e9                	cmp    %ebp,%ecx
  800cc5:	77 61                	ja     800d28 <__udivdi3+0x88>
  800cc7:	85 c9                	test   %ecx,%ecx
  800cc9:	89 ce                	mov    %ecx,%esi
  800ccb:	75 0b                	jne    800cd8 <__udivdi3+0x38>
  800ccd:	b8 01 00 00 00       	mov    $0x1,%eax
  800cd2:	31 d2                	xor    %edx,%edx
  800cd4:	f7 f1                	div    %ecx
  800cd6:	89 c6                	mov    %eax,%esi
  800cd8:	31 d2                	xor    %edx,%edx
  800cda:	89 e8                	mov    %ebp,%eax
  800cdc:	f7 f6                	div    %esi
  800cde:	89 c5                	mov    %eax,%ebp
  800ce0:	89 f8                	mov    %edi,%eax
  800ce2:	f7 f6                	div    %esi
  800ce4:	89 ea                	mov    %ebp,%edx
  800ce6:	83 c4 0c             	add    $0xc,%esp
  800ce9:	5e                   	pop    %esi
  800cea:	5f                   	pop    %edi
  800ceb:	5d                   	pop    %ebp
  800cec:	c3                   	ret    
  800ced:	8d 76 00             	lea    0x0(%esi),%esi
  800cf0:	39 e8                	cmp    %ebp,%eax
  800cf2:	77 24                	ja     800d18 <__udivdi3+0x78>
  800cf4:	0f bd e8             	bsr    %eax,%ebp
  800cf7:	83 f5 1f             	xor    $0x1f,%ebp
  800cfa:	75 3c                	jne    800d38 <__udivdi3+0x98>
  800cfc:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d00:	39 34 24             	cmp    %esi,(%esp)
  800d03:	0f 86 9f 00 00 00    	jbe    800da8 <__udivdi3+0x108>
  800d09:	39 d0                	cmp    %edx,%eax
  800d0b:	0f 82 97 00 00 00    	jb     800da8 <__udivdi3+0x108>
  800d11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d18:	31 d2                	xor    %edx,%edx
  800d1a:	31 c0                	xor    %eax,%eax
  800d1c:	83 c4 0c             	add    $0xc,%esp
  800d1f:	5e                   	pop    %esi
  800d20:	5f                   	pop    %edi
  800d21:	5d                   	pop    %ebp
  800d22:	c3                   	ret    
  800d23:	90                   	nop
  800d24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d28:	89 f8                	mov    %edi,%eax
  800d2a:	f7 f1                	div    %ecx
  800d2c:	31 d2                	xor    %edx,%edx
  800d2e:	83 c4 0c             	add    $0xc,%esp
  800d31:	5e                   	pop    %esi
  800d32:	5f                   	pop    %edi
  800d33:	5d                   	pop    %ebp
  800d34:	c3                   	ret    
  800d35:	8d 76 00             	lea    0x0(%esi),%esi
  800d38:	89 e9                	mov    %ebp,%ecx
  800d3a:	8b 3c 24             	mov    (%esp),%edi
  800d3d:	d3 e0                	shl    %cl,%eax
  800d3f:	89 c6                	mov    %eax,%esi
  800d41:	b8 20 00 00 00       	mov    $0x20,%eax
  800d46:	29 e8                	sub    %ebp,%eax
  800d48:	89 c1                	mov    %eax,%ecx
  800d4a:	d3 ef                	shr    %cl,%edi
  800d4c:	89 e9                	mov    %ebp,%ecx
  800d4e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d52:	8b 3c 24             	mov    (%esp),%edi
  800d55:	09 74 24 08          	or     %esi,0x8(%esp)
  800d59:	89 d6                	mov    %edx,%esi
  800d5b:	d3 e7                	shl    %cl,%edi
  800d5d:	89 c1                	mov    %eax,%ecx
  800d5f:	89 3c 24             	mov    %edi,(%esp)
  800d62:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d66:	d3 ee                	shr    %cl,%esi
  800d68:	89 e9                	mov    %ebp,%ecx
  800d6a:	d3 e2                	shl    %cl,%edx
  800d6c:	89 c1                	mov    %eax,%ecx
  800d6e:	d3 ef                	shr    %cl,%edi
  800d70:	09 d7                	or     %edx,%edi
  800d72:	89 f2                	mov    %esi,%edx
  800d74:	89 f8                	mov    %edi,%eax
  800d76:	f7 74 24 08          	divl   0x8(%esp)
  800d7a:	89 d6                	mov    %edx,%esi
  800d7c:	89 c7                	mov    %eax,%edi
  800d7e:	f7 24 24             	mull   (%esp)
  800d81:	39 d6                	cmp    %edx,%esi
  800d83:	89 14 24             	mov    %edx,(%esp)
  800d86:	72 30                	jb     800db8 <__udivdi3+0x118>
  800d88:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d8c:	89 e9                	mov    %ebp,%ecx
  800d8e:	d3 e2                	shl    %cl,%edx
  800d90:	39 c2                	cmp    %eax,%edx
  800d92:	73 05                	jae    800d99 <__udivdi3+0xf9>
  800d94:	3b 34 24             	cmp    (%esp),%esi
  800d97:	74 1f                	je     800db8 <__udivdi3+0x118>
  800d99:	89 f8                	mov    %edi,%eax
  800d9b:	31 d2                	xor    %edx,%edx
  800d9d:	e9 7a ff ff ff       	jmp    800d1c <__udivdi3+0x7c>
  800da2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800da8:	31 d2                	xor    %edx,%edx
  800daa:	b8 01 00 00 00       	mov    $0x1,%eax
  800daf:	e9 68 ff ff ff       	jmp    800d1c <__udivdi3+0x7c>
  800db4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800db8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800dbb:	31 d2                	xor    %edx,%edx
  800dbd:	83 c4 0c             	add    $0xc,%esp
  800dc0:	5e                   	pop    %esi
  800dc1:	5f                   	pop    %edi
  800dc2:	5d                   	pop    %ebp
  800dc3:	c3                   	ret    
  800dc4:	66 90                	xchg   %ax,%ax
  800dc6:	66 90                	xchg   %ax,%ax
  800dc8:	66 90                	xchg   %ax,%ax
  800dca:	66 90                	xchg   %ax,%ax
  800dcc:	66 90                	xchg   %ax,%ax
  800dce:	66 90                	xchg   %ax,%ax

00800dd0 <__umoddi3>:
  800dd0:	55                   	push   %ebp
  800dd1:	57                   	push   %edi
  800dd2:	56                   	push   %esi
  800dd3:	83 ec 14             	sub    $0x14,%esp
  800dd6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800dda:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800dde:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800de2:	89 c7                	mov    %eax,%edi
  800de4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800de8:	8b 44 24 30          	mov    0x30(%esp),%eax
  800dec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800df0:	89 34 24             	mov    %esi,(%esp)
  800df3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800df7:	85 c0                	test   %eax,%eax
  800df9:	89 c2                	mov    %eax,%edx
  800dfb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800dff:	75 17                	jne    800e18 <__umoddi3+0x48>
  800e01:	39 fe                	cmp    %edi,%esi
  800e03:	76 4b                	jbe    800e50 <__umoddi3+0x80>
  800e05:	89 c8                	mov    %ecx,%eax
  800e07:	89 fa                	mov    %edi,%edx
  800e09:	f7 f6                	div    %esi
  800e0b:	89 d0                	mov    %edx,%eax
  800e0d:	31 d2                	xor    %edx,%edx
  800e0f:	83 c4 14             	add    $0x14,%esp
  800e12:	5e                   	pop    %esi
  800e13:	5f                   	pop    %edi
  800e14:	5d                   	pop    %ebp
  800e15:	c3                   	ret    
  800e16:	66 90                	xchg   %ax,%ax
  800e18:	39 f8                	cmp    %edi,%eax
  800e1a:	77 54                	ja     800e70 <__umoddi3+0xa0>
  800e1c:	0f bd e8             	bsr    %eax,%ebp
  800e1f:	83 f5 1f             	xor    $0x1f,%ebp
  800e22:	75 5c                	jne    800e80 <__umoddi3+0xb0>
  800e24:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e28:	39 3c 24             	cmp    %edi,(%esp)
  800e2b:	0f 87 e7 00 00 00    	ja     800f18 <__umoddi3+0x148>
  800e31:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800e35:	29 f1                	sub    %esi,%ecx
  800e37:	19 c7                	sbb    %eax,%edi
  800e39:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e3d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e41:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e45:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e49:	83 c4 14             	add    $0x14,%esp
  800e4c:	5e                   	pop    %esi
  800e4d:	5f                   	pop    %edi
  800e4e:	5d                   	pop    %ebp
  800e4f:	c3                   	ret    
  800e50:	85 f6                	test   %esi,%esi
  800e52:	89 f5                	mov    %esi,%ebp
  800e54:	75 0b                	jne    800e61 <__umoddi3+0x91>
  800e56:	b8 01 00 00 00       	mov    $0x1,%eax
  800e5b:	31 d2                	xor    %edx,%edx
  800e5d:	f7 f6                	div    %esi
  800e5f:	89 c5                	mov    %eax,%ebp
  800e61:	8b 44 24 04          	mov    0x4(%esp),%eax
  800e65:	31 d2                	xor    %edx,%edx
  800e67:	f7 f5                	div    %ebp
  800e69:	89 c8                	mov    %ecx,%eax
  800e6b:	f7 f5                	div    %ebp
  800e6d:	eb 9c                	jmp    800e0b <__umoddi3+0x3b>
  800e6f:	90                   	nop
  800e70:	89 c8                	mov    %ecx,%eax
  800e72:	89 fa                	mov    %edi,%edx
  800e74:	83 c4 14             	add    $0x14,%esp
  800e77:	5e                   	pop    %esi
  800e78:	5f                   	pop    %edi
  800e79:	5d                   	pop    %ebp
  800e7a:	c3                   	ret    
  800e7b:	90                   	nop
  800e7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e80:	8b 04 24             	mov    (%esp),%eax
  800e83:	be 20 00 00 00       	mov    $0x20,%esi
  800e88:	89 e9                	mov    %ebp,%ecx
  800e8a:	29 ee                	sub    %ebp,%esi
  800e8c:	d3 e2                	shl    %cl,%edx
  800e8e:	89 f1                	mov    %esi,%ecx
  800e90:	d3 e8                	shr    %cl,%eax
  800e92:	89 e9                	mov    %ebp,%ecx
  800e94:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e98:	8b 04 24             	mov    (%esp),%eax
  800e9b:	09 54 24 04          	or     %edx,0x4(%esp)
  800e9f:	89 fa                	mov    %edi,%edx
  800ea1:	d3 e0                	shl    %cl,%eax
  800ea3:	89 f1                	mov    %esi,%ecx
  800ea5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ea9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ead:	d3 ea                	shr    %cl,%edx
  800eaf:	89 e9                	mov    %ebp,%ecx
  800eb1:	d3 e7                	shl    %cl,%edi
  800eb3:	89 f1                	mov    %esi,%ecx
  800eb5:	d3 e8                	shr    %cl,%eax
  800eb7:	89 e9                	mov    %ebp,%ecx
  800eb9:	09 f8                	or     %edi,%eax
  800ebb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800ebf:	f7 74 24 04          	divl   0x4(%esp)
  800ec3:	d3 e7                	shl    %cl,%edi
  800ec5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ec9:	89 d7                	mov    %edx,%edi
  800ecb:	f7 64 24 08          	mull   0x8(%esp)
  800ecf:	39 d7                	cmp    %edx,%edi
  800ed1:	89 c1                	mov    %eax,%ecx
  800ed3:	89 14 24             	mov    %edx,(%esp)
  800ed6:	72 2c                	jb     800f04 <__umoddi3+0x134>
  800ed8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800edc:	72 22                	jb     800f00 <__umoddi3+0x130>
  800ede:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800ee2:	29 c8                	sub    %ecx,%eax
  800ee4:	19 d7                	sbb    %edx,%edi
  800ee6:	89 e9                	mov    %ebp,%ecx
  800ee8:	89 fa                	mov    %edi,%edx
  800eea:	d3 e8                	shr    %cl,%eax
  800eec:	89 f1                	mov    %esi,%ecx
  800eee:	d3 e2                	shl    %cl,%edx
  800ef0:	89 e9                	mov    %ebp,%ecx
  800ef2:	d3 ef                	shr    %cl,%edi
  800ef4:	09 d0                	or     %edx,%eax
  800ef6:	89 fa                	mov    %edi,%edx
  800ef8:	83 c4 14             	add    $0x14,%esp
  800efb:	5e                   	pop    %esi
  800efc:	5f                   	pop    %edi
  800efd:	5d                   	pop    %ebp
  800efe:	c3                   	ret    
  800eff:	90                   	nop
  800f00:	39 d7                	cmp    %edx,%edi
  800f02:	75 da                	jne    800ede <__umoddi3+0x10e>
  800f04:	8b 14 24             	mov    (%esp),%edx
  800f07:	89 c1                	mov    %eax,%ecx
  800f09:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800f0d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800f11:	eb cb                	jmp    800ede <__umoddi3+0x10e>
  800f13:	90                   	nop
  800f14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f18:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800f1c:	0f 82 0f ff ff ff    	jb     800e31 <__umoddi3+0x61>
  800f22:	e9 1a ff ff ff       	jmp    800e41 <__umoddi3+0x71>
