
obj/user/faultwrite:     file format elf32-i386


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
  80002c:	e8 11 00 00 00       	call   800042 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	*(unsigned*)0 = 0;
  800036:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  80003d:	00 00 00 
}
  800040:	5d                   	pop    %ebp
  800041:	c3                   	ret    

00800042 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800042:	55                   	push   %ebp
  800043:	89 e5                	mov    %esp,%ebp
  800045:	56                   	push   %esi
  800046:	53                   	push   %ebx
  800047:	83 ec 10             	sub    $0x10,%esp
  80004a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80004d:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800050:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800057:	00 00 00 
	//thisenv=envs+ENVX(sys_getenvid());
	int index=sys_getenvid();
  80005a:	e8 db 00 00 00       	call   80013a <sys_getenvid>
        thisenv=&envs[ENVX(index)];
  80005f:	25 ff 03 00 00       	and    $0x3ff,%eax
  800064:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800067:	c1 e0 05             	shl    $0x5,%eax
  80006a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006f:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800074:	85 db                	test   %ebx,%ebx
  800076:	7e 07                	jle    80007f <libmain+0x3d>
		binaryname = argv[0];
  800078:	8b 06                	mov    (%esi),%eax
  80007a:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80007f:	89 74 24 04          	mov    %esi,0x4(%esp)
  800083:	89 1c 24             	mov    %ebx,(%esp)
  800086:	e8 a8 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008b:	e8 07 00 00 00       	call   800097 <exit>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	5b                   	pop    %ebx
  800094:	5e                   	pop    %esi
  800095:	5d                   	pop    %ebp
  800096:	c3                   	ret    

00800097 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800097:	55                   	push   %ebp
  800098:	89 e5                	mov    %esp,%ebp
  80009a:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80009d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000a4:	e8 3f 00 00 00       	call   8000e8 <sys_env_destroy>
}
  8000a9:	c9                   	leave  
  8000aa:	c3                   	ret    

008000ab <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000ab:	55                   	push   %ebp
  8000ac:	89 e5                	mov    %esp,%ebp
  8000ae:	57                   	push   %edi
  8000af:	56                   	push   %esi
  8000b0:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b9:	8b 55 08             	mov    0x8(%ebp),%edx
  8000bc:	89 c3                	mov    %eax,%ebx
  8000be:	89 c7                	mov    %eax,%edi
  8000c0:	89 c6                	mov    %eax,%esi
  8000c2:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c4:	5b                   	pop    %ebx
  8000c5:	5e                   	pop    %esi
  8000c6:	5f                   	pop    %edi
  8000c7:	5d                   	pop    %ebp
  8000c8:	c3                   	ret    

008000c9 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000c9:	55                   	push   %ebp
  8000ca:	89 e5                	mov    %esp,%ebp
  8000cc:	57                   	push   %edi
  8000cd:	56                   	push   %esi
  8000ce:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000cf:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d4:	b8 01 00 00 00       	mov    $0x1,%eax
  8000d9:	89 d1                	mov    %edx,%ecx
  8000db:	89 d3                	mov    %edx,%ebx
  8000dd:	89 d7                	mov    %edx,%edi
  8000df:	89 d6                	mov    %edx,%esi
  8000e1:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e3:	5b                   	pop    %ebx
  8000e4:	5e                   	pop    %esi
  8000e5:	5f                   	pop    %edi
  8000e6:	5d                   	pop    %ebp
  8000e7:	c3                   	ret    

008000e8 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e8:	55                   	push   %ebp
  8000e9:	89 e5                	mov    %esp,%ebp
  8000eb:	57                   	push   %edi
  8000ec:	56                   	push   %esi
  8000ed:	53                   	push   %ebx
  8000ee:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000f1:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f6:	b8 03 00 00 00       	mov    $0x3,%eax
  8000fb:	8b 55 08             	mov    0x8(%ebp),%edx
  8000fe:	89 cb                	mov    %ecx,%ebx
  800100:	89 cf                	mov    %ecx,%edi
  800102:	89 ce                	mov    %ecx,%esi
  800104:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800106:	85 c0                	test   %eax,%eax
  800108:	7e 28                	jle    800132 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  80010a:	89 44 24 10          	mov    %eax,0x10(%esp)
  80010e:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800115:	00 
  800116:	c7 44 24 08 42 0f 80 	movl   $0x800f42,0x8(%esp)
  80011d:	00 
  80011e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800125:	00 
  800126:	c7 04 24 5f 0f 80 00 	movl   $0x800f5f,(%esp)
  80012d:	e8 27 00 00 00       	call   800159 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800132:	83 c4 2c             	add    $0x2c,%esp
  800135:	5b                   	pop    %ebx
  800136:	5e                   	pop    %esi
  800137:	5f                   	pop    %edi
  800138:	5d                   	pop    %ebp
  800139:	c3                   	ret    

0080013a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80013a:	55                   	push   %ebp
  80013b:	89 e5                	mov    %esp,%ebp
  80013d:	57                   	push   %edi
  80013e:	56                   	push   %esi
  80013f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800140:	ba 00 00 00 00       	mov    $0x0,%edx
  800145:	b8 02 00 00 00       	mov    $0x2,%eax
  80014a:	89 d1                	mov    %edx,%ecx
  80014c:	89 d3                	mov    %edx,%ebx
  80014e:	89 d7                	mov    %edx,%edi
  800150:	89 d6                	mov    %edx,%esi
  800152:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800154:	5b                   	pop    %ebx
  800155:	5e                   	pop    %esi
  800156:	5f                   	pop    %edi
  800157:	5d                   	pop    %ebp
  800158:	c3                   	ret    

00800159 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800159:	55                   	push   %ebp
  80015a:	89 e5                	mov    %esp,%ebp
  80015c:	56                   	push   %esi
  80015d:	53                   	push   %ebx
  80015e:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800161:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	if (argv0)
  800164:	a1 08 20 80 00       	mov    0x802008,%eax
  800169:	85 c0                	test   %eax,%eax
  80016b:	74 10                	je     80017d <_panic+0x24>
		cprintf("%s: ", argv0);
  80016d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800171:	c7 04 24 6d 0f 80 00 	movl   $0x800f6d,(%esp)
  800178:	e8 ee 00 00 00       	call   80026b <cprintf>
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80017d:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800183:	e8 b2 ff ff ff       	call   80013a <sys_getenvid>
  800188:	8b 55 0c             	mov    0xc(%ebp),%edx
  80018b:	89 54 24 10          	mov    %edx,0x10(%esp)
  80018f:	8b 55 08             	mov    0x8(%ebp),%edx
  800192:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800196:	89 74 24 08          	mov    %esi,0x8(%esp)
  80019a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80019e:	c7 04 24 74 0f 80 00 	movl   $0x800f74,(%esp)
  8001a5:	e8 c1 00 00 00       	call   80026b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001ae:	8b 45 10             	mov    0x10(%ebp),%eax
  8001b1:	89 04 24             	mov    %eax,(%esp)
  8001b4:	e8 51 00 00 00       	call   80020a <vcprintf>
	cprintf("\n");
  8001b9:	c7 04 24 72 0f 80 00 	movl   $0x800f72,(%esp)
  8001c0:	e8 a6 00 00 00       	call   80026b <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001c5:	cc                   	int3   
  8001c6:	eb fd                	jmp    8001c5 <_panic+0x6c>

008001c8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001c8:	55                   	push   %ebp
  8001c9:	89 e5                	mov    %esp,%ebp
  8001cb:	53                   	push   %ebx
  8001cc:	83 ec 14             	sub    $0x14,%esp
  8001cf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001d2:	8b 13                	mov    (%ebx),%edx
  8001d4:	8d 42 01             	lea    0x1(%edx),%eax
  8001d7:	89 03                	mov    %eax,(%ebx)
  8001d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001dc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001e0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001e5:	75 19                	jne    800200 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001e7:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001ee:	00 
  8001ef:	8d 43 08             	lea    0x8(%ebx),%eax
  8001f2:	89 04 24             	mov    %eax,(%esp)
  8001f5:	e8 b1 fe ff ff       	call   8000ab <sys_cputs>
		b->idx = 0;
  8001fa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800200:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800204:	83 c4 14             	add    $0x14,%esp
  800207:	5b                   	pop    %ebx
  800208:	5d                   	pop    %ebp
  800209:	c3                   	ret    

0080020a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80020a:	55                   	push   %ebp
  80020b:	89 e5                	mov    %esp,%ebp
  80020d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800213:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80021a:	00 00 00 
	b.cnt = 0;
  80021d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800224:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800227:	8b 45 0c             	mov    0xc(%ebp),%eax
  80022a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80022e:	8b 45 08             	mov    0x8(%ebp),%eax
  800231:	89 44 24 08          	mov    %eax,0x8(%esp)
  800235:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80023b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80023f:	c7 04 24 c8 01 80 00 	movl   $0x8001c8,(%esp)
  800246:	e8 b9 01 00 00       	call   800404 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80024b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800251:	89 44 24 04          	mov    %eax,0x4(%esp)
  800255:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80025b:	89 04 24             	mov    %eax,(%esp)
  80025e:	e8 48 fe ff ff       	call   8000ab <sys_cputs>

	return b.cnt;
}
  800263:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800269:	c9                   	leave  
  80026a:	c3                   	ret    

0080026b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80026b:	55                   	push   %ebp
  80026c:	89 e5                	mov    %esp,%ebp
  80026e:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800271:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800274:	89 44 24 04          	mov    %eax,0x4(%esp)
  800278:	8b 45 08             	mov    0x8(%ebp),%eax
  80027b:	89 04 24             	mov    %eax,(%esp)
  80027e:	e8 87 ff ff ff       	call   80020a <vcprintf>
	va_end(ap);

	return cnt;
}
  800283:	c9                   	leave  
  800284:	c3                   	ret    
  800285:	66 90                	xchg   %ax,%ax
  800287:	66 90                	xchg   %ax,%ax
  800289:	66 90                	xchg   %ax,%ax
  80028b:	66 90                	xchg   %ax,%ax
  80028d:	66 90                	xchg   %ax,%ax
  80028f:	90                   	nop

00800290 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800290:	55                   	push   %ebp
  800291:	89 e5                	mov    %esp,%ebp
  800293:	57                   	push   %edi
  800294:	56                   	push   %esi
  800295:	53                   	push   %ebx
  800296:	83 ec 3c             	sub    $0x3c,%esp
  800299:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80029c:	89 d7                	mov    %edx,%edi
  80029e:	8b 45 08             	mov    0x8(%ebp),%eax
  8002a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002a4:	8b 75 0c             	mov    0xc(%ebp),%esi
  8002a7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
  8002aa:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002ad:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002b2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002b5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8002b8:	39 f1                	cmp    %esi,%ecx
  8002ba:	72 14                	jb     8002d0 <printnum+0x40>
  8002bc:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8002bf:	76 0f                	jbe    8002d0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8002c4:	8d 70 ff             	lea    -0x1(%eax),%esi
  8002c7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  8002ca:	85 f6                	test   %esi,%esi
  8002cc:	7f 60                	jg     80032e <printnum+0x9e>
  8002ce:	eb 72                	jmp    800342 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002d0:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8002d3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8002d7:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8002da:	8d 51 ff             	lea    -0x1(%ecx),%edx
  8002dd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8002e1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002e5:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002e9:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002ed:	89 c3                	mov    %eax,%ebx
  8002ef:	89 d6                	mov    %edx,%esi
  8002f1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002f4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002f7:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002fb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800302:	89 04 24             	mov    %eax,(%esp)
  800305:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800308:	89 44 24 04          	mov    %eax,0x4(%esp)
  80030c:	e8 9f 09 00 00       	call   800cb0 <__udivdi3>
  800311:	89 d9                	mov    %ebx,%ecx
  800313:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800317:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80031b:	89 04 24             	mov    %eax,(%esp)
  80031e:	89 54 24 04          	mov    %edx,0x4(%esp)
  800322:	89 fa                	mov    %edi,%edx
  800324:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800327:	e8 64 ff ff ff       	call   800290 <printnum>
  80032c:	eb 14                	jmp    800342 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80032e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800332:	8b 45 18             	mov    0x18(%ebp),%eax
  800335:	89 04 24             	mov    %eax,(%esp)
  800338:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80033a:	83 ee 01             	sub    $0x1,%esi
  80033d:	75 ef                	jne    80032e <printnum+0x9e>
  80033f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800342:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800346:	8b 7c 24 04          	mov    0x4(%esp),%edi
  80034a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80034d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800350:	89 44 24 08          	mov    %eax,0x8(%esp)
  800354:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800358:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80035b:	89 04 24             	mov    %eax,(%esp)
  80035e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800361:	89 44 24 04          	mov    %eax,0x4(%esp)
  800365:	e8 76 0a 00 00       	call   800de0 <__umoddi3>
  80036a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80036e:	0f be 80 98 0f 80 00 	movsbl 0x800f98(%eax),%eax
  800375:	89 04 24             	mov    %eax,(%esp)
  800378:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80037b:	ff d0                	call   *%eax
}
  80037d:	83 c4 3c             	add    $0x3c,%esp
  800380:	5b                   	pop    %ebx
  800381:	5e                   	pop    %esi
  800382:	5f                   	pop    %edi
  800383:	5d                   	pop    %ebp
  800384:	c3                   	ret    

00800385 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800385:	55                   	push   %ebp
  800386:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800388:	83 fa 01             	cmp    $0x1,%edx
  80038b:	7e 0e                	jle    80039b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80038d:	8b 10                	mov    (%eax),%edx
  80038f:	8d 4a 08             	lea    0x8(%edx),%ecx
  800392:	89 08                	mov    %ecx,(%eax)
  800394:	8b 02                	mov    (%edx),%eax
  800396:	8b 52 04             	mov    0x4(%edx),%edx
  800399:	eb 22                	jmp    8003bd <getuint+0x38>
	else if (lflag)
  80039b:	85 d2                	test   %edx,%edx
  80039d:	74 10                	je     8003af <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80039f:	8b 10                	mov    (%eax),%edx
  8003a1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003a4:	89 08                	mov    %ecx,(%eax)
  8003a6:	8b 02                	mov    (%edx),%eax
  8003a8:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ad:	eb 0e                	jmp    8003bd <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003af:	8b 10                	mov    (%eax),%edx
  8003b1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003b4:	89 08                	mov    %ecx,(%eax)
  8003b6:	8b 02                	mov    (%edx),%eax
  8003b8:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003bd:	5d                   	pop    %ebp
  8003be:	c3                   	ret    

008003bf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003bf:	55                   	push   %ebp
  8003c0:	89 e5                	mov    %esp,%ebp
  8003c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003c5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003c9:	8b 10                	mov    (%eax),%edx
  8003cb:	3b 50 04             	cmp    0x4(%eax),%edx
  8003ce:	73 0a                	jae    8003da <sprintputch+0x1b>
		*b->buf++ = ch;
  8003d0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8003d3:	89 08                	mov    %ecx,(%eax)
  8003d5:	8b 45 08             	mov    0x8(%ebp),%eax
  8003d8:	88 02                	mov    %al,(%edx)
}
  8003da:	5d                   	pop    %ebp
  8003db:	c3                   	ret    

008003dc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003dc:	55                   	push   %ebp
  8003dd:	89 e5                	mov    %esp,%ebp
  8003df:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003e2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003e9:	8b 45 10             	mov    0x10(%ebp),%eax
  8003ec:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8003fa:	89 04 24             	mov    %eax,(%esp)
  8003fd:	e8 02 00 00 00       	call   800404 <vprintfmt>
	va_end(ap);
}
  800402:	c9                   	leave  
  800403:	c3                   	ret    

00800404 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800404:	55                   	push   %ebp
  800405:	89 e5                	mov    %esp,%ebp
  800407:	57                   	push   %edi
  800408:	56                   	push   %esi
  800409:	53                   	push   %ebx
  80040a:	83 ec 3c             	sub    $0x3c,%esp
  80040d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800410:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800413:	eb 18                	jmp    80042d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800415:	85 c0                	test   %eax,%eax
  800417:	0f 84 c3 03 00 00    	je     8007e0 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
  80041d:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800421:	89 04 24             	mov    %eax,(%esp)
  800424:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800427:	89 f3                	mov    %esi,%ebx
  800429:	eb 02                	jmp    80042d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
  80042b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80042d:	8d 73 01             	lea    0x1(%ebx),%esi
  800430:	0f b6 03             	movzbl (%ebx),%eax
  800433:	83 f8 25             	cmp    $0x25,%eax
  800436:	75 dd                	jne    800415 <vprintfmt+0x11>
  800438:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
  80043c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800443:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  80044a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800451:	ba 00 00 00 00       	mov    $0x0,%edx
  800456:	eb 1d                	jmp    800475 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800458:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80045a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
  80045e:	eb 15                	jmp    800475 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800460:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800462:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
  800466:	eb 0d                	jmp    800475 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800468:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80046b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80046e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800475:	8d 5e 01             	lea    0x1(%esi),%ebx
  800478:	0f b6 06             	movzbl (%esi),%eax
  80047b:	0f b6 c8             	movzbl %al,%ecx
  80047e:	83 e8 23             	sub    $0x23,%eax
  800481:	3c 55                	cmp    $0x55,%al
  800483:	0f 87 2f 03 00 00    	ja     8007b8 <vprintfmt+0x3b4>
  800489:	0f b6 c0             	movzbl %al,%eax
  80048c:	ff 24 85 28 10 80 00 	jmp    *0x801028(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800493:	8d 41 d0             	lea    -0x30(%ecx),%eax
  800496:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
  800499:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
  80049d:	8d 48 d0             	lea    -0x30(%eax),%ecx
  8004a0:	83 f9 09             	cmp    $0x9,%ecx
  8004a3:	77 50                	ja     8004f5 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a5:	89 de                	mov    %ebx,%esi
  8004a7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004aa:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
  8004ad:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8004b0:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8004b4:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8004b7:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8004ba:	83 fb 09             	cmp    $0x9,%ebx
  8004bd:	76 eb                	jbe    8004aa <vprintfmt+0xa6>
  8004bf:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  8004c2:	eb 33                	jmp    8004f7 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c7:	8d 48 04             	lea    0x4(%eax),%ecx
  8004ca:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004cd:	8b 00                	mov    (%eax),%eax
  8004cf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d2:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004d4:	eb 21                	jmp    8004f7 <vprintfmt+0xf3>
  8004d6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8004d9:	85 c9                	test   %ecx,%ecx
  8004db:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e0:	0f 49 c1             	cmovns %ecx,%eax
  8004e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e6:	89 de                	mov    %ebx,%esi
  8004e8:	eb 8b                	jmp    800475 <vprintfmt+0x71>
  8004ea:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004ec:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8004f3:	eb 80                	jmp    800475 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f5:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  8004f7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004fb:	0f 89 74 ff ff ff    	jns    800475 <vprintfmt+0x71>
  800501:	e9 62 ff ff ff       	jmp    800468 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800506:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800509:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80050b:	e9 65 ff ff ff       	jmp    800475 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800510:	8b 45 14             	mov    0x14(%ebp),%eax
  800513:	8d 50 04             	lea    0x4(%eax),%edx
  800516:	89 55 14             	mov    %edx,0x14(%ebp)
  800519:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80051d:	8b 00                	mov    (%eax),%eax
  80051f:	89 04 24             	mov    %eax,(%esp)
  800522:	ff 55 08             	call   *0x8(%ebp)
			break;
  800525:	e9 03 ff ff ff       	jmp    80042d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80052a:	8b 45 14             	mov    0x14(%ebp),%eax
  80052d:	8d 50 04             	lea    0x4(%eax),%edx
  800530:	89 55 14             	mov    %edx,0x14(%ebp)
  800533:	8b 00                	mov    (%eax),%eax
  800535:	99                   	cltd   
  800536:	31 d0                	xor    %edx,%eax
  800538:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80053a:	83 f8 06             	cmp    $0x6,%eax
  80053d:	7f 0b                	jg     80054a <vprintfmt+0x146>
  80053f:	8b 14 85 80 11 80 00 	mov    0x801180(,%eax,4),%edx
  800546:	85 d2                	test   %edx,%edx
  800548:	75 20                	jne    80056a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
  80054a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80054e:	c7 44 24 08 b0 0f 80 	movl   $0x800fb0,0x8(%esp)
  800555:	00 
  800556:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80055a:	8b 45 08             	mov    0x8(%ebp),%eax
  80055d:	89 04 24             	mov    %eax,(%esp)
  800560:	e8 77 fe ff ff       	call   8003dc <printfmt>
  800565:	e9 c3 fe ff ff       	jmp    80042d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
  80056a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80056e:	c7 44 24 08 b9 0f 80 	movl   $0x800fb9,0x8(%esp)
  800575:	00 
  800576:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80057a:	8b 45 08             	mov    0x8(%ebp),%eax
  80057d:	89 04 24             	mov    %eax,(%esp)
  800580:	e8 57 fe ff ff       	call   8003dc <printfmt>
  800585:	e9 a3 fe ff ff       	jmp    80042d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80058d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800590:	8b 45 14             	mov    0x14(%ebp),%eax
  800593:	8d 50 04             	lea    0x4(%eax),%edx
  800596:	89 55 14             	mov    %edx,0x14(%ebp)
  800599:	8b 00                	mov    (%eax),%eax
				p = "(null)";
  80059b:	85 c0                	test   %eax,%eax
  80059d:	ba a9 0f 80 00       	mov    $0x800fa9,%edx
  8005a2:	0f 45 d0             	cmovne %eax,%edx
  8005a5:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
  8005a8:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
  8005ac:	74 04                	je     8005b2 <vprintfmt+0x1ae>
  8005ae:	85 f6                	test   %esi,%esi
  8005b0:	7f 19                	jg     8005cb <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005b2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005b5:	8d 70 01             	lea    0x1(%eax),%esi
  8005b8:	0f b6 10             	movzbl (%eax),%edx
  8005bb:	0f be c2             	movsbl %dl,%eax
  8005be:	85 c0                	test   %eax,%eax
  8005c0:	0f 85 95 00 00 00    	jne    80065b <vprintfmt+0x257>
  8005c6:	e9 85 00 00 00       	jmp    800650 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005cb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005cf:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8005d2:	89 04 24             	mov    %eax,(%esp)
  8005d5:	e8 b8 02 00 00       	call   800892 <strnlen>
  8005da:	29 c6                	sub    %eax,%esi
  8005dc:	89 f0                	mov    %esi,%eax
  8005de:	89 75 e4             	mov    %esi,-0x1c(%ebp)
  8005e1:	85 f6                	test   %esi,%esi
  8005e3:	7e cd                	jle    8005b2 <vprintfmt+0x1ae>
					putch(padc, putdat);
  8005e5:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  8005e9:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005ec:	89 c3                	mov    %eax,%ebx
  8005ee:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005f2:	89 34 24             	mov    %esi,(%esp)
  8005f5:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005f8:	83 eb 01             	sub    $0x1,%ebx
  8005fb:	75 f1                	jne    8005ee <vprintfmt+0x1ea>
  8005fd:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800600:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800603:	eb ad                	jmp    8005b2 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800605:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800609:	74 1e                	je     800629 <vprintfmt+0x225>
  80060b:	0f be d2             	movsbl %dl,%edx
  80060e:	83 ea 20             	sub    $0x20,%edx
  800611:	83 fa 5e             	cmp    $0x5e,%edx
  800614:	76 13                	jbe    800629 <vprintfmt+0x225>
					putch('?', putdat);
  800616:	8b 45 0c             	mov    0xc(%ebp),%eax
  800619:	89 44 24 04          	mov    %eax,0x4(%esp)
  80061d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800624:	ff 55 08             	call   *0x8(%ebp)
  800627:	eb 0d                	jmp    800636 <vprintfmt+0x232>
				else
					putch(ch, putdat);
  800629:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80062c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800630:	89 04 24             	mov    %eax,(%esp)
  800633:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800636:	83 ef 01             	sub    $0x1,%edi
  800639:	83 c6 01             	add    $0x1,%esi
  80063c:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800640:	0f be c2             	movsbl %dl,%eax
  800643:	85 c0                	test   %eax,%eax
  800645:	75 20                	jne    800667 <vprintfmt+0x263>
  800647:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  80064a:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80064d:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800650:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800654:	7f 25                	jg     80067b <vprintfmt+0x277>
  800656:	e9 d2 fd ff ff       	jmp    80042d <vprintfmt+0x29>
  80065b:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80065e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800661:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800664:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800667:	85 db                	test   %ebx,%ebx
  800669:	78 9a                	js     800605 <vprintfmt+0x201>
  80066b:	83 eb 01             	sub    $0x1,%ebx
  80066e:	79 95                	jns    800605 <vprintfmt+0x201>
  800670:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  800673:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800676:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800679:	eb d5                	jmp    800650 <vprintfmt+0x24c>
  80067b:	8b 75 08             	mov    0x8(%ebp),%esi
  80067e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800681:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800684:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800688:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80068f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800691:	83 eb 01             	sub    $0x1,%ebx
  800694:	75 ee                	jne    800684 <vprintfmt+0x280>
  800696:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800699:	e9 8f fd ff ff       	jmp    80042d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80069e:	83 fa 01             	cmp    $0x1,%edx
  8006a1:	7e 16                	jle    8006b9 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
  8006a3:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a6:	8d 50 08             	lea    0x8(%eax),%edx
  8006a9:	89 55 14             	mov    %edx,0x14(%ebp)
  8006ac:	8b 50 04             	mov    0x4(%eax),%edx
  8006af:	8b 00                	mov    (%eax),%eax
  8006b1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006b4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8006b7:	eb 32                	jmp    8006eb <vprintfmt+0x2e7>
	else if (lflag)
  8006b9:	85 d2                	test   %edx,%edx
  8006bb:	74 18                	je     8006d5 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
  8006bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c0:	8d 50 04             	lea    0x4(%eax),%edx
  8006c3:	89 55 14             	mov    %edx,0x14(%ebp)
  8006c6:	8b 30                	mov    (%eax),%esi
  8006c8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8006cb:	89 f0                	mov    %esi,%eax
  8006cd:	c1 f8 1f             	sar    $0x1f,%eax
  8006d0:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8006d3:	eb 16                	jmp    8006eb <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
  8006d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d8:	8d 50 04             	lea    0x4(%eax),%edx
  8006db:	89 55 14             	mov    %edx,0x14(%ebp)
  8006de:	8b 30                	mov    (%eax),%esi
  8006e0:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8006e3:	89 f0                	mov    %esi,%eax
  8006e5:	c1 f8 1f             	sar    $0x1f,%eax
  8006e8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006eb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8006ee:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006f1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006f6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8006fa:	0f 89 80 00 00 00    	jns    800780 <vprintfmt+0x37c>
				putch('-', putdat);
  800700:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800704:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80070b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  80070e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800711:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800714:	f7 d8                	neg    %eax
  800716:	83 d2 00             	adc    $0x0,%edx
  800719:	f7 da                	neg    %edx
			}
			base = 10;
  80071b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800720:	eb 5e                	jmp    800780 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800722:	8d 45 14             	lea    0x14(%ebp),%eax
  800725:	e8 5b fc ff ff       	call   800385 <getuint>
			base = 10;
  80072a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80072f:	eb 4f                	jmp    800780 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
  800731:	8d 45 14             	lea    0x14(%ebp),%eax
  800734:	e8 4c fc ff ff       	call   800385 <getuint>
			base = 8;
  800739:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80073e:	eb 40                	jmp    800780 <vprintfmt+0x37c>

		// pointer
		case 'p':
			putch('0', putdat);
  800740:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800744:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80074b:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  80074e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800752:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  800759:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80075c:	8b 45 14             	mov    0x14(%ebp),%eax
  80075f:	8d 50 04             	lea    0x4(%eax),%edx
  800762:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800765:	8b 00                	mov    (%eax),%eax
  800767:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80076c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800771:	eb 0d                	jmp    800780 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800773:	8d 45 14             	lea    0x14(%ebp),%eax
  800776:	e8 0a fc ff ff       	call   800385 <getuint>
			base = 16;
  80077b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800780:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
  800784:	89 74 24 10          	mov    %esi,0x10(%esp)
  800788:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  80078b:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80078f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800793:	89 04 24             	mov    %eax,(%esp)
  800796:	89 54 24 04          	mov    %edx,0x4(%esp)
  80079a:	89 fa                	mov    %edi,%edx
  80079c:	8b 45 08             	mov    0x8(%ebp),%eax
  80079f:	e8 ec fa ff ff       	call   800290 <printnum>
			break;
  8007a4:	e9 84 fc ff ff       	jmp    80042d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007a9:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007ad:	89 0c 24             	mov    %ecx,(%esp)
  8007b0:	ff 55 08             	call   *0x8(%ebp)
			break;
  8007b3:	e9 75 fc ff ff       	jmp    80042d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007bc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007c3:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007c6:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  8007ca:	0f 84 5b fc ff ff    	je     80042b <vprintfmt+0x27>
  8007d0:	89 f3                	mov    %esi,%ebx
  8007d2:	83 eb 01             	sub    $0x1,%ebx
  8007d5:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8007d9:	75 f7                	jne    8007d2 <vprintfmt+0x3ce>
  8007db:	e9 4d fc ff ff       	jmp    80042d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
  8007e0:	83 c4 3c             	add    $0x3c,%esp
  8007e3:	5b                   	pop    %ebx
  8007e4:	5e                   	pop    %esi
  8007e5:	5f                   	pop    %edi
  8007e6:	5d                   	pop    %ebp
  8007e7:	c3                   	ret    

008007e8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007e8:	55                   	push   %ebp
  8007e9:	89 e5                	mov    %esp,%ebp
  8007eb:	83 ec 28             	sub    $0x28,%esp
  8007ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8007f1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007f4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007f7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007fb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800805:	85 c0                	test   %eax,%eax
  800807:	74 30                	je     800839 <vsnprintf+0x51>
  800809:	85 d2                	test   %edx,%edx
  80080b:	7e 2c                	jle    800839 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80080d:	8b 45 14             	mov    0x14(%ebp),%eax
  800810:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800814:	8b 45 10             	mov    0x10(%ebp),%eax
  800817:	89 44 24 08          	mov    %eax,0x8(%esp)
  80081b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80081e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800822:	c7 04 24 bf 03 80 00 	movl   $0x8003bf,(%esp)
  800829:	e8 d6 fb ff ff       	call   800404 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80082e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800831:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800834:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800837:	eb 05                	jmp    80083e <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800839:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80083e:	c9                   	leave  
  80083f:	c3                   	ret    

00800840 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800840:	55                   	push   %ebp
  800841:	89 e5                	mov    %esp,%ebp
  800843:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800846:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800849:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80084d:	8b 45 10             	mov    0x10(%ebp),%eax
  800850:	89 44 24 08          	mov    %eax,0x8(%esp)
  800854:	8b 45 0c             	mov    0xc(%ebp),%eax
  800857:	89 44 24 04          	mov    %eax,0x4(%esp)
  80085b:	8b 45 08             	mov    0x8(%ebp),%eax
  80085e:	89 04 24             	mov    %eax,(%esp)
  800861:	e8 82 ff ff ff       	call   8007e8 <vsnprintf>
	va_end(ap);

	return rc;
}
  800866:	c9                   	leave  
  800867:	c3                   	ret    
  800868:	66 90                	xchg   %ax,%ax
  80086a:	66 90                	xchg   %ax,%ax
  80086c:	66 90                	xchg   %ax,%ax
  80086e:	66 90                	xchg   %ax,%ax

00800870 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800870:	55                   	push   %ebp
  800871:	89 e5                	mov    %esp,%ebp
  800873:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800876:	80 3a 00             	cmpb   $0x0,(%edx)
  800879:	74 10                	je     80088b <strlen+0x1b>
  80087b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
  800880:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800883:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800887:	75 f7                	jne    800880 <strlen+0x10>
  800889:	eb 05                	jmp    800890 <strlen+0x20>
  80088b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  800890:	5d                   	pop    %ebp
  800891:	c3                   	ret    

00800892 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800892:	55                   	push   %ebp
  800893:	89 e5                	mov    %esp,%ebp
  800895:	53                   	push   %ebx
  800896:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800899:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80089c:	85 c9                	test   %ecx,%ecx
  80089e:	74 1c                	je     8008bc <strnlen+0x2a>
  8008a0:	80 3b 00             	cmpb   $0x0,(%ebx)
  8008a3:	74 1e                	je     8008c3 <strnlen+0x31>
  8008a5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
  8008aa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008ac:	39 ca                	cmp    %ecx,%edx
  8008ae:	74 18                	je     8008c8 <strnlen+0x36>
  8008b0:	83 c2 01             	add    $0x1,%edx
  8008b3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
  8008b8:	75 f0                	jne    8008aa <strnlen+0x18>
  8008ba:	eb 0c                	jmp    8008c8 <strnlen+0x36>
  8008bc:	b8 00 00 00 00       	mov    $0x0,%eax
  8008c1:	eb 05                	jmp    8008c8 <strnlen+0x36>
  8008c3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
  8008c8:	5b                   	pop    %ebx
  8008c9:	5d                   	pop    %ebp
  8008ca:	c3                   	ret    

008008cb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008cb:	55                   	push   %ebp
  8008cc:	89 e5                	mov    %esp,%ebp
  8008ce:	53                   	push   %ebx
  8008cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008d5:	89 c2                	mov    %eax,%edx
  8008d7:	83 c2 01             	add    $0x1,%edx
  8008da:	83 c1 01             	add    $0x1,%ecx
  8008dd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008e1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008e4:	84 db                	test   %bl,%bl
  8008e6:	75 ef                	jne    8008d7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008e8:	5b                   	pop    %ebx
  8008e9:	5d                   	pop    %ebp
  8008ea:	c3                   	ret    

008008eb <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008eb:	55                   	push   %ebp
  8008ec:	89 e5                	mov    %esp,%ebp
  8008ee:	53                   	push   %ebx
  8008ef:	83 ec 08             	sub    $0x8,%esp
  8008f2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008f5:	89 1c 24             	mov    %ebx,(%esp)
  8008f8:	e8 73 ff ff ff       	call   800870 <strlen>
	strcpy(dst + len, src);
  8008fd:	8b 55 0c             	mov    0xc(%ebp),%edx
  800900:	89 54 24 04          	mov    %edx,0x4(%esp)
  800904:	01 d8                	add    %ebx,%eax
  800906:	89 04 24             	mov    %eax,(%esp)
  800909:	e8 bd ff ff ff       	call   8008cb <strcpy>
	return dst;
}
  80090e:	89 d8                	mov    %ebx,%eax
  800910:	83 c4 08             	add    $0x8,%esp
  800913:	5b                   	pop    %ebx
  800914:	5d                   	pop    %ebp
  800915:	c3                   	ret    

00800916 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800916:	55                   	push   %ebp
  800917:	89 e5                	mov    %esp,%ebp
  800919:	56                   	push   %esi
  80091a:	53                   	push   %ebx
  80091b:	8b 75 08             	mov    0x8(%ebp),%esi
  80091e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800921:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800924:	85 db                	test   %ebx,%ebx
  800926:	74 17                	je     80093f <strncpy+0x29>
  800928:	01 f3                	add    %esi,%ebx
  80092a:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
  80092c:	83 c1 01             	add    $0x1,%ecx
  80092f:	0f b6 02             	movzbl (%edx),%eax
  800932:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800935:	80 3a 01             	cmpb   $0x1,(%edx)
  800938:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80093b:	39 d9                	cmp    %ebx,%ecx
  80093d:	75 ed                	jne    80092c <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80093f:	89 f0                	mov    %esi,%eax
  800941:	5b                   	pop    %ebx
  800942:	5e                   	pop    %esi
  800943:	5d                   	pop    %ebp
  800944:	c3                   	ret    

00800945 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800945:	55                   	push   %ebp
  800946:	89 e5                	mov    %esp,%ebp
  800948:	57                   	push   %edi
  800949:	56                   	push   %esi
  80094a:	53                   	push   %ebx
  80094b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80094e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800951:	8b 75 10             	mov    0x10(%ebp),%esi
  800954:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800956:	85 f6                	test   %esi,%esi
  800958:	74 34                	je     80098e <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
  80095a:	83 fe 01             	cmp    $0x1,%esi
  80095d:	74 26                	je     800985 <strlcpy+0x40>
  80095f:	0f b6 0b             	movzbl (%ebx),%ecx
  800962:	84 c9                	test   %cl,%cl
  800964:	74 23                	je     800989 <strlcpy+0x44>
  800966:	83 ee 02             	sub    $0x2,%esi
  800969:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
  80096e:	83 c0 01             	add    $0x1,%eax
  800971:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800974:	39 f2                	cmp    %esi,%edx
  800976:	74 13                	je     80098b <strlcpy+0x46>
  800978:	83 c2 01             	add    $0x1,%edx
  80097b:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80097f:	84 c9                	test   %cl,%cl
  800981:	75 eb                	jne    80096e <strlcpy+0x29>
  800983:	eb 06                	jmp    80098b <strlcpy+0x46>
  800985:	89 f8                	mov    %edi,%eax
  800987:	eb 02                	jmp    80098b <strlcpy+0x46>
  800989:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
  80098b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80098e:	29 f8                	sub    %edi,%eax
}
  800990:	5b                   	pop    %ebx
  800991:	5e                   	pop    %esi
  800992:	5f                   	pop    %edi
  800993:	5d                   	pop    %ebp
  800994:	c3                   	ret    

00800995 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800995:	55                   	push   %ebp
  800996:	89 e5                	mov    %esp,%ebp
  800998:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80099b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80099e:	0f b6 01             	movzbl (%ecx),%eax
  8009a1:	84 c0                	test   %al,%al
  8009a3:	74 15                	je     8009ba <strcmp+0x25>
  8009a5:	3a 02                	cmp    (%edx),%al
  8009a7:	75 11                	jne    8009ba <strcmp+0x25>
		p++, q++;
  8009a9:	83 c1 01             	add    $0x1,%ecx
  8009ac:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009af:	0f b6 01             	movzbl (%ecx),%eax
  8009b2:	84 c0                	test   %al,%al
  8009b4:	74 04                	je     8009ba <strcmp+0x25>
  8009b6:	3a 02                	cmp    (%edx),%al
  8009b8:	74 ef                	je     8009a9 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009ba:	0f b6 c0             	movzbl %al,%eax
  8009bd:	0f b6 12             	movzbl (%edx),%edx
  8009c0:	29 d0                	sub    %edx,%eax
}
  8009c2:	5d                   	pop    %ebp
  8009c3:	c3                   	ret    

008009c4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009c4:	55                   	push   %ebp
  8009c5:	89 e5                	mov    %esp,%ebp
  8009c7:	56                   	push   %esi
  8009c8:	53                   	push   %ebx
  8009c9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8009cc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009cf:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
  8009d2:	85 f6                	test   %esi,%esi
  8009d4:	74 29                	je     8009ff <strncmp+0x3b>
  8009d6:	0f b6 03             	movzbl (%ebx),%eax
  8009d9:	84 c0                	test   %al,%al
  8009db:	74 30                	je     800a0d <strncmp+0x49>
  8009dd:	3a 02                	cmp    (%edx),%al
  8009df:	75 2c                	jne    800a0d <strncmp+0x49>
  8009e1:	8d 43 01             	lea    0x1(%ebx),%eax
  8009e4:	01 de                	add    %ebx,%esi
		n--, p++, q++;
  8009e6:	89 c3                	mov    %eax,%ebx
  8009e8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009eb:	39 f0                	cmp    %esi,%eax
  8009ed:	74 17                	je     800a06 <strncmp+0x42>
  8009ef:	0f b6 08             	movzbl (%eax),%ecx
  8009f2:	84 c9                	test   %cl,%cl
  8009f4:	74 17                	je     800a0d <strncmp+0x49>
  8009f6:	83 c0 01             	add    $0x1,%eax
  8009f9:	3a 0a                	cmp    (%edx),%cl
  8009fb:	74 e9                	je     8009e6 <strncmp+0x22>
  8009fd:	eb 0e                	jmp    800a0d <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009ff:	b8 00 00 00 00       	mov    $0x0,%eax
  800a04:	eb 0f                	jmp    800a15 <strncmp+0x51>
  800a06:	b8 00 00 00 00       	mov    $0x0,%eax
  800a0b:	eb 08                	jmp    800a15 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a0d:	0f b6 03             	movzbl (%ebx),%eax
  800a10:	0f b6 12             	movzbl (%edx),%edx
  800a13:	29 d0                	sub    %edx,%eax
}
  800a15:	5b                   	pop    %ebx
  800a16:	5e                   	pop    %esi
  800a17:	5d                   	pop    %ebp
  800a18:	c3                   	ret    

00800a19 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a19:	55                   	push   %ebp
  800a1a:	89 e5                	mov    %esp,%ebp
  800a1c:	53                   	push   %ebx
  800a1d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a20:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a23:	0f b6 18             	movzbl (%eax),%ebx
  800a26:	84 db                	test   %bl,%bl
  800a28:	74 1d                	je     800a47 <strchr+0x2e>
  800a2a:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a2c:	38 d3                	cmp    %dl,%bl
  800a2e:	75 06                	jne    800a36 <strchr+0x1d>
  800a30:	eb 1a                	jmp    800a4c <strchr+0x33>
  800a32:	38 ca                	cmp    %cl,%dl
  800a34:	74 16                	je     800a4c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a36:	83 c0 01             	add    $0x1,%eax
  800a39:	0f b6 10             	movzbl (%eax),%edx
  800a3c:	84 d2                	test   %dl,%dl
  800a3e:	75 f2                	jne    800a32 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
  800a40:	b8 00 00 00 00       	mov    $0x0,%eax
  800a45:	eb 05                	jmp    800a4c <strchr+0x33>
  800a47:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a4c:	5b                   	pop    %ebx
  800a4d:	5d                   	pop    %ebp
  800a4e:	c3                   	ret    

00800a4f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a4f:	55                   	push   %ebp
  800a50:	89 e5                	mov    %esp,%ebp
  800a52:	53                   	push   %ebx
  800a53:	8b 45 08             	mov    0x8(%ebp),%eax
  800a56:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
  800a59:	0f b6 18             	movzbl (%eax),%ebx
  800a5c:	84 db                	test   %bl,%bl
  800a5e:	74 16                	je     800a76 <strfind+0x27>
  800a60:	89 d1                	mov    %edx,%ecx
		if (*s == c)
  800a62:	38 d3                	cmp    %dl,%bl
  800a64:	75 06                	jne    800a6c <strfind+0x1d>
  800a66:	eb 0e                	jmp    800a76 <strfind+0x27>
  800a68:	38 ca                	cmp    %cl,%dl
  800a6a:	74 0a                	je     800a76 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a6c:	83 c0 01             	add    $0x1,%eax
  800a6f:	0f b6 10             	movzbl (%eax),%edx
  800a72:	84 d2                	test   %dl,%dl
  800a74:	75 f2                	jne    800a68 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
  800a76:	5b                   	pop    %ebx
  800a77:	5d                   	pop    %ebp
  800a78:	c3                   	ret    

00800a79 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a79:	55                   	push   %ebp
  800a7a:	89 e5                	mov    %esp,%ebp
  800a7c:	57                   	push   %edi
  800a7d:	56                   	push   %esi
  800a7e:	53                   	push   %ebx
  800a7f:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a82:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a85:	85 c9                	test   %ecx,%ecx
  800a87:	74 36                	je     800abf <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a89:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a8f:	75 28                	jne    800ab9 <memset+0x40>
  800a91:	f6 c1 03             	test   $0x3,%cl
  800a94:	75 23                	jne    800ab9 <memset+0x40>
		c &= 0xFF;
  800a96:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a9a:	89 d3                	mov    %edx,%ebx
  800a9c:	c1 e3 08             	shl    $0x8,%ebx
  800a9f:	89 d6                	mov    %edx,%esi
  800aa1:	c1 e6 18             	shl    $0x18,%esi
  800aa4:	89 d0                	mov    %edx,%eax
  800aa6:	c1 e0 10             	shl    $0x10,%eax
  800aa9:	09 f0                	or     %esi,%eax
  800aab:	09 c2                	or     %eax,%edx
  800aad:	89 d0                	mov    %edx,%eax
  800aaf:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800ab1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800ab4:	fc                   	cld    
  800ab5:	f3 ab                	rep stos %eax,%es:(%edi)
  800ab7:	eb 06                	jmp    800abf <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800ab9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800abc:	fc                   	cld    
  800abd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800abf:	89 f8                	mov    %edi,%eax
  800ac1:	5b                   	pop    %ebx
  800ac2:	5e                   	pop    %esi
  800ac3:	5f                   	pop    %edi
  800ac4:	5d                   	pop    %ebp
  800ac5:	c3                   	ret    

00800ac6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800ac6:	55                   	push   %ebp
  800ac7:	89 e5                	mov    %esp,%ebp
  800ac9:	57                   	push   %edi
  800aca:	56                   	push   %esi
  800acb:	8b 45 08             	mov    0x8(%ebp),%eax
  800ace:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ad1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800ad4:	39 c6                	cmp    %eax,%esi
  800ad6:	73 35                	jae    800b0d <memmove+0x47>
  800ad8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800adb:	39 d0                	cmp    %edx,%eax
  800add:	73 2e                	jae    800b0d <memmove+0x47>
		s += n;
		d += n;
  800adf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800ae2:	89 d6                	mov    %edx,%esi
  800ae4:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ae6:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800aec:	75 13                	jne    800b01 <memmove+0x3b>
  800aee:	f6 c1 03             	test   $0x3,%cl
  800af1:	75 0e                	jne    800b01 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800af3:	83 ef 04             	sub    $0x4,%edi
  800af6:	8d 72 fc             	lea    -0x4(%edx),%esi
  800af9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800afc:	fd                   	std    
  800afd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800aff:	eb 09                	jmp    800b0a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800b01:	83 ef 01             	sub    $0x1,%edi
  800b04:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800b07:	fd                   	std    
  800b08:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800b0a:	fc                   	cld    
  800b0b:	eb 1d                	jmp    800b2a <memmove+0x64>
  800b0d:	89 f2                	mov    %esi,%edx
  800b0f:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b11:	f6 c2 03             	test   $0x3,%dl
  800b14:	75 0f                	jne    800b25 <memmove+0x5f>
  800b16:	f6 c1 03             	test   $0x3,%cl
  800b19:	75 0a                	jne    800b25 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800b1b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800b1e:	89 c7                	mov    %eax,%edi
  800b20:	fc                   	cld    
  800b21:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b23:	eb 05                	jmp    800b2a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b25:	89 c7                	mov    %eax,%edi
  800b27:	fc                   	cld    
  800b28:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b2a:	5e                   	pop    %esi
  800b2b:	5f                   	pop    %edi
  800b2c:	5d                   	pop    %ebp
  800b2d:	c3                   	ret    

00800b2e <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
  800b2e:	55                   	push   %ebp
  800b2f:	89 e5                	mov    %esp,%ebp
  800b31:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b34:	8b 45 10             	mov    0x10(%ebp),%eax
  800b37:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b3b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b3e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b42:	8b 45 08             	mov    0x8(%ebp),%eax
  800b45:	89 04 24             	mov    %eax,(%esp)
  800b48:	e8 79 ff ff ff       	call   800ac6 <memmove>
}
  800b4d:	c9                   	leave  
  800b4e:	c3                   	ret    

00800b4f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b4f:	55                   	push   %ebp
  800b50:	89 e5                	mov    %esp,%ebp
  800b52:	57                   	push   %edi
  800b53:	56                   	push   %esi
  800b54:	53                   	push   %ebx
  800b55:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800b58:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b5b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b5e:	8d 78 ff             	lea    -0x1(%eax),%edi
  800b61:	85 c0                	test   %eax,%eax
  800b63:	74 36                	je     800b9b <memcmp+0x4c>
		if (*s1 != *s2)
  800b65:	0f b6 03             	movzbl (%ebx),%eax
  800b68:	0f b6 0e             	movzbl (%esi),%ecx
  800b6b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b70:	38 c8                	cmp    %cl,%al
  800b72:	74 1c                	je     800b90 <memcmp+0x41>
  800b74:	eb 10                	jmp    800b86 <memcmp+0x37>
  800b76:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
  800b7b:	83 c2 01             	add    $0x1,%edx
  800b7e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
  800b82:	38 c8                	cmp    %cl,%al
  800b84:	74 0a                	je     800b90 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
  800b86:	0f b6 c0             	movzbl %al,%eax
  800b89:	0f b6 c9             	movzbl %cl,%ecx
  800b8c:	29 c8                	sub    %ecx,%eax
  800b8e:	eb 10                	jmp    800ba0 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b90:	39 fa                	cmp    %edi,%edx
  800b92:	75 e2                	jne    800b76 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b94:	b8 00 00 00 00       	mov    $0x0,%eax
  800b99:	eb 05                	jmp    800ba0 <memcmp+0x51>
  800b9b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ba0:	5b                   	pop    %ebx
  800ba1:	5e                   	pop    %esi
  800ba2:	5f                   	pop    %edi
  800ba3:	5d                   	pop    %ebp
  800ba4:	c3                   	ret    

00800ba5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ba5:	55                   	push   %ebp
  800ba6:	89 e5                	mov    %esp,%ebp
  800ba8:	53                   	push   %ebx
  800ba9:	8b 45 08             	mov    0x8(%ebp),%eax
  800bac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
  800baf:	89 c2                	mov    %eax,%edx
  800bb1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800bb4:	39 d0                	cmp    %edx,%eax
  800bb6:	73 13                	jae    800bcb <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
  800bb8:	89 d9                	mov    %ebx,%ecx
  800bba:	38 18                	cmp    %bl,(%eax)
  800bbc:	75 06                	jne    800bc4 <memfind+0x1f>
  800bbe:	eb 0b                	jmp    800bcb <memfind+0x26>
  800bc0:	38 08                	cmp    %cl,(%eax)
  800bc2:	74 07                	je     800bcb <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800bc4:	83 c0 01             	add    $0x1,%eax
  800bc7:	39 d0                	cmp    %edx,%eax
  800bc9:	75 f5                	jne    800bc0 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800bcb:	5b                   	pop    %ebx
  800bcc:	5d                   	pop    %ebp
  800bcd:	c3                   	ret    

00800bce <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800bce:	55                   	push   %ebp
  800bcf:	89 e5                	mov    %esp,%ebp
  800bd1:	57                   	push   %edi
  800bd2:	56                   	push   %esi
  800bd3:	53                   	push   %ebx
  800bd4:	8b 55 08             	mov    0x8(%ebp),%edx
  800bd7:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800bda:	0f b6 0a             	movzbl (%edx),%ecx
  800bdd:	80 f9 09             	cmp    $0x9,%cl
  800be0:	74 05                	je     800be7 <strtol+0x19>
  800be2:	80 f9 20             	cmp    $0x20,%cl
  800be5:	75 10                	jne    800bf7 <strtol+0x29>
		s++;
  800be7:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800bea:	0f b6 0a             	movzbl (%edx),%ecx
  800bed:	80 f9 09             	cmp    $0x9,%cl
  800bf0:	74 f5                	je     800be7 <strtol+0x19>
  800bf2:	80 f9 20             	cmp    $0x20,%cl
  800bf5:	74 f0                	je     800be7 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
  800bf7:	80 f9 2b             	cmp    $0x2b,%cl
  800bfa:	75 0a                	jne    800c06 <strtol+0x38>
		s++;
  800bfc:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800bff:	bf 00 00 00 00       	mov    $0x0,%edi
  800c04:	eb 11                	jmp    800c17 <strtol+0x49>
  800c06:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c0b:	80 f9 2d             	cmp    $0x2d,%cl
  800c0e:	75 07                	jne    800c17 <strtol+0x49>
		s++, neg = 1;
  800c10:	83 c2 01             	add    $0x1,%edx
  800c13:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c17:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800c1c:	75 15                	jne    800c33 <strtol+0x65>
  800c1e:	80 3a 30             	cmpb   $0x30,(%edx)
  800c21:	75 10                	jne    800c33 <strtol+0x65>
  800c23:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800c27:	75 0a                	jne    800c33 <strtol+0x65>
		s += 2, base = 16;
  800c29:	83 c2 02             	add    $0x2,%edx
  800c2c:	b8 10 00 00 00       	mov    $0x10,%eax
  800c31:	eb 10                	jmp    800c43 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
  800c33:	85 c0                	test   %eax,%eax
  800c35:	75 0c                	jne    800c43 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800c37:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800c39:	80 3a 30             	cmpb   $0x30,(%edx)
  800c3c:	75 05                	jne    800c43 <strtol+0x75>
		s++, base = 8;
  800c3e:	83 c2 01             	add    $0x1,%edx
  800c41:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800c43:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c48:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800c4b:	0f b6 0a             	movzbl (%edx),%ecx
  800c4e:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800c51:	89 f0                	mov    %esi,%eax
  800c53:	3c 09                	cmp    $0x9,%al
  800c55:	77 08                	ja     800c5f <strtol+0x91>
			dig = *s - '0';
  800c57:	0f be c9             	movsbl %cl,%ecx
  800c5a:	83 e9 30             	sub    $0x30,%ecx
  800c5d:	eb 20                	jmp    800c7f <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
  800c5f:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800c62:	89 f0                	mov    %esi,%eax
  800c64:	3c 19                	cmp    $0x19,%al
  800c66:	77 08                	ja     800c70 <strtol+0xa2>
			dig = *s - 'a' + 10;
  800c68:	0f be c9             	movsbl %cl,%ecx
  800c6b:	83 e9 57             	sub    $0x57,%ecx
  800c6e:	eb 0f                	jmp    800c7f <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
  800c70:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c73:	89 f0                	mov    %esi,%eax
  800c75:	3c 19                	cmp    $0x19,%al
  800c77:	77 16                	ja     800c8f <strtol+0xc1>
			dig = *s - 'A' + 10;
  800c79:	0f be c9             	movsbl %cl,%ecx
  800c7c:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c7f:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800c82:	7d 0f                	jge    800c93 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  800c84:	83 c2 01             	add    $0x1,%edx
  800c87:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800c8b:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800c8d:	eb bc                	jmp    800c4b <strtol+0x7d>
  800c8f:	89 d8                	mov    %ebx,%eax
  800c91:	eb 02                	jmp    800c95 <strtol+0xc7>
  800c93:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800c95:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c99:	74 05                	je     800ca0 <strtol+0xd2>
		*endptr = (char *) s;
  800c9b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c9e:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800ca0:	f7 d8                	neg    %eax
  800ca2:	85 ff                	test   %edi,%edi
  800ca4:	0f 44 c3             	cmove  %ebx,%eax
}
  800ca7:	5b                   	pop    %ebx
  800ca8:	5e                   	pop    %esi
  800ca9:	5f                   	pop    %edi
  800caa:	5d                   	pop    %ebp
  800cab:	c3                   	ret    
  800cac:	66 90                	xchg   %ax,%ax
  800cae:	66 90                	xchg   %ax,%ax

00800cb0 <__udivdi3>:
  800cb0:	55                   	push   %ebp
  800cb1:	57                   	push   %edi
  800cb2:	56                   	push   %esi
  800cb3:	83 ec 0c             	sub    $0xc,%esp
  800cb6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800cba:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800cbe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800cc2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800cc6:	85 c0                	test   %eax,%eax
  800cc8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800ccc:	89 ea                	mov    %ebp,%edx
  800cce:	89 0c 24             	mov    %ecx,(%esp)
  800cd1:	75 2d                	jne    800d00 <__udivdi3+0x50>
  800cd3:	39 e9                	cmp    %ebp,%ecx
  800cd5:	77 61                	ja     800d38 <__udivdi3+0x88>
  800cd7:	85 c9                	test   %ecx,%ecx
  800cd9:	89 ce                	mov    %ecx,%esi
  800cdb:	75 0b                	jne    800ce8 <__udivdi3+0x38>
  800cdd:	b8 01 00 00 00       	mov    $0x1,%eax
  800ce2:	31 d2                	xor    %edx,%edx
  800ce4:	f7 f1                	div    %ecx
  800ce6:	89 c6                	mov    %eax,%esi
  800ce8:	31 d2                	xor    %edx,%edx
  800cea:	89 e8                	mov    %ebp,%eax
  800cec:	f7 f6                	div    %esi
  800cee:	89 c5                	mov    %eax,%ebp
  800cf0:	89 f8                	mov    %edi,%eax
  800cf2:	f7 f6                	div    %esi
  800cf4:	89 ea                	mov    %ebp,%edx
  800cf6:	83 c4 0c             	add    $0xc,%esp
  800cf9:	5e                   	pop    %esi
  800cfa:	5f                   	pop    %edi
  800cfb:	5d                   	pop    %ebp
  800cfc:	c3                   	ret    
  800cfd:	8d 76 00             	lea    0x0(%esi),%esi
  800d00:	39 e8                	cmp    %ebp,%eax
  800d02:	77 24                	ja     800d28 <__udivdi3+0x78>
  800d04:	0f bd e8             	bsr    %eax,%ebp
  800d07:	83 f5 1f             	xor    $0x1f,%ebp
  800d0a:	75 3c                	jne    800d48 <__udivdi3+0x98>
  800d0c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d10:	39 34 24             	cmp    %esi,(%esp)
  800d13:	0f 86 9f 00 00 00    	jbe    800db8 <__udivdi3+0x108>
  800d19:	39 d0                	cmp    %edx,%eax
  800d1b:	0f 82 97 00 00 00    	jb     800db8 <__udivdi3+0x108>
  800d21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d28:	31 d2                	xor    %edx,%edx
  800d2a:	31 c0                	xor    %eax,%eax
  800d2c:	83 c4 0c             	add    $0xc,%esp
  800d2f:	5e                   	pop    %esi
  800d30:	5f                   	pop    %edi
  800d31:	5d                   	pop    %ebp
  800d32:	c3                   	ret    
  800d33:	90                   	nop
  800d34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d38:	89 f8                	mov    %edi,%eax
  800d3a:	f7 f1                	div    %ecx
  800d3c:	31 d2                	xor    %edx,%edx
  800d3e:	83 c4 0c             	add    $0xc,%esp
  800d41:	5e                   	pop    %esi
  800d42:	5f                   	pop    %edi
  800d43:	5d                   	pop    %ebp
  800d44:	c3                   	ret    
  800d45:	8d 76 00             	lea    0x0(%esi),%esi
  800d48:	89 e9                	mov    %ebp,%ecx
  800d4a:	8b 3c 24             	mov    (%esp),%edi
  800d4d:	d3 e0                	shl    %cl,%eax
  800d4f:	89 c6                	mov    %eax,%esi
  800d51:	b8 20 00 00 00       	mov    $0x20,%eax
  800d56:	29 e8                	sub    %ebp,%eax
  800d58:	89 c1                	mov    %eax,%ecx
  800d5a:	d3 ef                	shr    %cl,%edi
  800d5c:	89 e9                	mov    %ebp,%ecx
  800d5e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d62:	8b 3c 24             	mov    (%esp),%edi
  800d65:	09 74 24 08          	or     %esi,0x8(%esp)
  800d69:	89 d6                	mov    %edx,%esi
  800d6b:	d3 e7                	shl    %cl,%edi
  800d6d:	89 c1                	mov    %eax,%ecx
  800d6f:	89 3c 24             	mov    %edi,(%esp)
  800d72:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d76:	d3 ee                	shr    %cl,%esi
  800d78:	89 e9                	mov    %ebp,%ecx
  800d7a:	d3 e2                	shl    %cl,%edx
  800d7c:	89 c1                	mov    %eax,%ecx
  800d7e:	d3 ef                	shr    %cl,%edi
  800d80:	09 d7                	or     %edx,%edi
  800d82:	89 f2                	mov    %esi,%edx
  800d84:	89 f8                	mov    %edi,%eax
  800d86:	f7 74 24 08          	divl   0x8(%esp)
  800d8a:	89 d6                	mov    %edx,%esi
  800d8c:	89 c7                	mov    %eax,%edi
  800d8e:	f7 24 24             	mull   (%esp)
  800d91:	39 d6                	cmp    %edx,%esi
  800d93:	89 14 24             	mov    %edx,(%esp)
  800d96:	72 30                	jb     800dc8 <__udivdi3+0x118>
  800d98:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d9c:	89 e9                	mov    %ebp,%ecx
  800d9e:	d3 e2                	shl    %cl,%edx
  800da0:	39 c2                	cmp    %eax,%edx
  800da2:	73 05                	jae    800da9 <__udivdi3+0xf9>
  800da4:	3b 34 24             	cmp    (%esp),%esi
  800da7:	74 1f                	je     800dc8 <__udivdi3+0x118>
  800da9:	89 f8                	mov    %edi,%eax
  800dab:	31 d2                	xor    %edx,%edx
  800dad:	e9 7a ff ff ff       	jmp    800d2c <__udivdi3+0x7c>
  800db2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800db8:	31 d2                	xor    %edx,%edx
  800dba:	b8 01 00 00 00       	mov    $0x1,%eax
  800dbf:	e9 68 ff ff ff       	jmp    800d2c <__udivdi3+0x7c>
  800dc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dc8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800dcb:	31 d2                	xor    %edx,%edx
  800dcd:	83 c4 0c             	add    $0xc,%esp
  800dd0:	5e                   	pop    %esi
  800dd1:	5f                   	pop    %edi
  800dd2:	5d                   	pop    %ebp
  800dd3:	c3                   	ret    
  800dd4:	66 90                	xchg   %ax,%ax
  800dd6:	66 90                	xchg   %ax,%ax
  800dd8:	66 90                	xchg   %ax,%ax
  800dda:	66 90                	xchg   %ax,%ax
  800ddc:	66 90                	xchg   %ax,%ax
  800dde:	66 90                	xchg   %ax,%ax

00800de0 <__umoddi3>:
  800de0:	55                   	push   %ebp
  800de1:	57                   	push   %edi
  800de2:	56                   	push   %esi
  800de3:	83 ec 14             	sub    $0x14,%esp
  800de6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800dea:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800dee:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800df2:	89 c7                	mov    %eax,%edi
  800df4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800df8:	8b 44 24 30          	mov    0x30(%esp),%eax
  800dfc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800e00:	89 34 24             	mov    %esi,(%esp)
  800e03:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e07:	85 c0                	test   %eax,%eax
  800e09:	89 c2                	mov    %eax,%edx
  800e0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e0f:	75 17                	jne    800e28 <__umoddi3+0x48>
  800e11:	39 fe                	cmp    %edi,%esi
  800e13:	76 4b                	jbe    800e60 <__umoddi3+0x80>
  800e15:	89 c8                	mov    %ecx,%eax
  800e17:	89 fa                	mov    %edi,%edx
  800e19:	f7 f6                	div    %esi
  800e1b:	89 d0                	mov    %edx,%eax
  800e1d:	31 d2                	xor    %edx,%edx
  800e1f:	83 c4 14             	add    $0x14,%esp
  800e22:	5e                   	pop    %esi
  800e23:	5f                   	pop    %edi
  800e24:	5d                   	pop    %ebp
  800e25:	c3                   	ret    
  800e26:	66 90                	xchg   %ax,%ax
  800e28:	39 f8                	cmp    %edi,%eax
  800e2a:	77 54                	ja     800e80 <__umoddi3+0xa0>
  800e2c:	0f bd e8             	bsr    %eax,%ebp
  800e2f:	83 f5 1f             	xor    $0x1f,%ebp
  800e32:	75 5c                	jne    800e90 <__umoddi3+0xb0>
  800e34:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e38:	39 3c 24             	cmp    %edi,(%esp)
  800e3b:	0f 87 e7 00 00 00    	ja     800f28 <__umoddi3+0x148>
  800e41:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800e45:	29 f1                	sub    %esi,%ecx
  800e47:	19 c7                	sbb    %eax,%edi
  800e49:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e4d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e51:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e55:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e59:	83 c4 14             	add    $0x14,%esp
  800e5c:	5e                   	pop    %esi
  800e5d:	5f                   	pop    %edi
  800e5e:	5d                   	pop    %ebp
  800e5f:	c3                   	ret    
  800e60:	85 f6                	test   %esi,%esi
  800e62:	89 f5                	mov    %esi,%ebp
  800e64:	75 0b                	jne    800e71 <__umoddi3+0x91>
  800e66:	b8 01 00 00 00       	mov    $0x1,%eax
  800e6b:	31 d2                	xor    %edx,%edx
  800e6d:	f7 f6                	div    %esi
  800e6f:	89 c5                	mov    %eax,%ebp
  800e71:	8b 44 24 04          	mov    0x4(%esp),%eax
  800e75:	31 d2                	xor    %edx,%edx
  800e77:	f7 f5                	div    %ebp
  800e79:	89 c8                	mov    %ecx,%eax
  800e7b:	f7 f5                	div    %ebp
  800e7d:	eb 9c                	jmp    800e1b <__umoddi3+0x3b>
  800e7f:	90                   	nop
  800e80:	89 c8                	mov    %ecx,%eax
  800e82:	89 fa                	mov    %edi,%edx
  800e84:	83 c4 14             	add    $0x14,%esp
  800e87:	5e                   	pop    %esi
  800e88:	5f                   	pop    %edi
  800e89:	5d                   	pop    %ebp
  800e8a:	c3                   	ret    
  800e8b:	90                   	nop
  800e8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e90:	8b 04 24             	mov    (%esp),%eax
  800e93:	be 20 00 00 00       	mov    $0x20,%esi
  800e98:	89 e9                	mov    %ebp,%ecx
  800e9a:	29 ee                	sub    %ebp,%esi
  800e9c:	d3 e2                	shl    %cl,%edx
  800e9e:	89 f1                	mov    %esi,%ecx
  800ea0:	d3 e8                	shr    %cl,%eax
  800ea2:	89 e9                	mov    %ebp,%ecx
  800ea4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ea8:	8b 04 24             	mov    (%esp),%eax
  800eab:	09 54 24 04          	or     %edx,0x4(%esp)
  800eaf:	89 fa                	mov    %edi,%edx
  800eb1:	d3 e0                	shl    %cl,%eax
  800eb3:	89 f1                	mov    %esi,%ecx
  800eb5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800eb9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ebd:	d3 ea                	shr    %cl,%edx
  800ebf:	89 e9                	mov    %ebp,%ecx
  800ec1:	d3 e7                	shl    %cl,%edi
  800ec3:	89 f1                	mov    %esi,%ecx
  800ec5:	d3 e8                	shr    %cl,%eax
  800ec7:	89 e9                	mov    %ebp,%ecx
  800ec9:	09 f8                	or     %edi,%eax
  800ecb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800ecf:	f7 74 24 04          	divl   0x4(%esp)
  800ed3:	d3 e7                	shl    %cl,%edi
  800ed5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ed9:	89 d7                	mov    %edx,%edi
  800edb:	f7 64 24 08          	mull   0x8(%esp)
  800edf:	39 d7                	cmp    %edx,%edi
  800ee1:	89 c1                	mov    %eax,%ecx
  800ee3:	89 14 24             	mov    %edx,(%esp)
  800ee6:	72 2c                	jb     800f14 <__umoddi3+0x134>
  800ee8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800eec:	72 22                	jb     800f10 <__umoddi3+0x130>
  800eee:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800ef2:	29 c8                	sub    %ecx,%eax
  800ef4:	19 d7                	sbb    %edx,%edi
  800ef6:	89 e9                	mov    %ebp,%ecx
  800ef8:	89 fa                	mov    %edi,%edx
  800efa:	d3 e8                	shr    %cl,%eax
  800efc:	89 f1                	mov    %esi,%ecx
  800efe:	d3 e2                	shl    %cl,%edx
  800f00:	89 e9                	mov    %ebp,%ecx
  800f02:	d3 ef                	shr    %cl,%edi
  800f04:	09 d0                	or     %edx,%eax
  800f06:	89 fa                	mov    %edi,%edx
  800f08:	83 c4 14             	add    $0x14,%esp
  800f0b:	5e                   	pop    %esi
  800f0c:	5f                   	pop    %edi
  800f0d:	5d                   	pop    %ebp
  800f0e:	c3                   	ret    
  800f0f:	90                   	nop
  800f10:	39 d7                	cmp    %edx,%edi
  800f12:	75 da                	jne    800eee <__umoddi3+0x10e>
  800f14:	8b 14 24             	mov    (%esp),%edx
  800f17:	89 c1                	mov    %eax,%ecx
  800f19:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800f1d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800f21:	eb cb                	jmp    800eee <__umoddi3+0x10e>
  800f23:	90                   	nop
  800f24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f28:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800f2c:	0f 82 0f ff ff ff    	jb     800e41 <__umoddi3+0x61>
  800f32:	e9 1a ff ff ff       	jmp    800e51 <__umoddi3+0x71>
