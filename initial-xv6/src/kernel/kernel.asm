
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	92070713          	addi	a4,a4,-1760 # 80008970 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	3fe78793          	addi	a5,a5,1022 # 80006460 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9c1f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6f2080e7          	jalr	1778(ra) # 8000281c <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	92650513          	addi	a0,a0,-1754 # 80010ab0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	91648493          	addi	s1,s1,-1770 # 80010ab0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9a690913          	addi	s2,s2,-1626 # 80010b48 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	996080e7          	jalr	-1642(ra) # 80001b56 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	49e080e7          	jalr	1182(ra) # 80002666 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1b4080e7          	jalr	436(ra) # 8000238a <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	5b4080e7          	jalr	1460(ra) # 800027c6 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	88a50513          	addi	a0,a0,-1910 # 80010ab0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	87450513          	addi	a0,a0,-1932 # 80010ab0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8cf72b23          	sw	a5,-1834(a4) # 80010b48 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7e450513          	addi	a0,a0,2020 # 80010ab0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	580080e7          	jalr	1408(ra) # 80002872 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7b650513          	addi	a0,a0,1974 # 80010ab0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	79270713          	addi	a4,a4,1938 # 80010ab0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	76878793          	addi	a5,a5,1896 # 80010ab0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7d27a783          	lw	a5,2002(a5) # 80010b48 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	72670713          	addi	a4,a4,1830 # 80010ab0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	71648493          	addi	s1,s1,1814 # 80010ab0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6da70713          	addi	a4,a4,1754 # 80010ab0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	76f72223          	sw	a5,1892(a4) # 80010b50 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	69e78793          	addi	a5,a5,1694 # 80010ab0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	70c7ab23          	sw	a2,1814(a5) # 80010b4c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	70a50513          	addi	a0,a0,1802 # 80010b48 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fa8080e7          	jalr	-88(ra) # 800023ee <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	ba858593          	addi	a1,a1,-1112 # 80008000 <etext>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	65050513          	addi	a0,a0,1616 # 80010ab0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	5d078793          	addi	a5,a5,1488 # 80023a48 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b7660613          	addi	a2,a2,-1162 # 80008030 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6207a223          	sw	zero,1572(a5) # 80010b70 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ab450513          	addi	a0,a0,-1356 # 80008008 <etext+0x8>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b4a50513          	addi	a0,a0,-1206 # 800080b8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	3af72823          	sw	a5,944(a4) # 80008930 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	5b4dad83          	lw	s11,1460(s11) # 80010b70 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a48b0b13          	addi	s6,s6,-1464 # 80008030 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	55e50513          	addi	a0,a0,1374 # 80010b58 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a0c50513          	addi	a0,a0,-1524 # 80008018 <etext+0x18>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	90a48493          	addi	s1,s1,-1782 # 80008010 <etext+0x10>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	40050513          	addi	a0,a0,1024 # 80010b58 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3e448493          	addi	s1,s1,996 # 80010b58 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8ac58593          	addi	a1,a1,-1876 # 80008028 <etext+0x28>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	87c58593          	addi	a1,a1,-1924 # 80008048 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	3a450513          	addi	a0,a0,932 # 80010b78 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1307a783          	lw	a5,304(a5) # 80008930 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1007b783          	ld	a5,256(a5) # 80008938 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	10073703          	ld	a4,256(a4) # 80008940 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	316a0a13          	addi	s4,s4,790 # 80010b78 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0ce48493          	addi	s1,s1,206 # 80008938 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0ce98993          	addi	s3,s3,206 # 80008940 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b5a080e7          	jalr	-1190(ra) # 800023ee <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	2a850513          	addi	a0,a0,680 # 80010b78 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0507a783          	lw	a5,80(a5) # 80008930 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	05673703          	ld	a4,86(a4) # 80008940 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0467b783          	ld	a5,70(a5) # 80008938 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	27a98993          	addi	s3,s3,634 # 80010b78 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	03248493          	addi	s1,s1,50 # 80008938 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	03290913          	addi	s2,s2,50 # 80008940 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a6c080e7          	jalr	-1428(ra) # 8000238a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	24448493          	addi	s1,s1,580 # 80010b78 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fee7bc23          	sd	a4,-8(a5) # 80008940 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	1be48493          	addi	s1,s1,446 # 80010b78 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00024797          	auipc	a5,0x24
    80000a00:	1e478793          	addi	a5,a5,484 # 80024be0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	19490913          	addi	s2,s2,404 # 80010bb0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	60250513          	addi	a0,a0,1538 # 80008050 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5a658593          	addi	a1,a1,1446 # 80008058 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0f650513          	addi	a0,a0,246 # 80010bb0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00024517          	auipc	a0,0x24
    80000ad2:	11250513          	addi	a0,a0,274 # 80024be0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0c048493          	addi	s1,s1,192 # 80010bb0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0a850513          	addi	a0,a0,168 # 80010bb0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	07c50513          	addi	a0,a0,124 # 80010bb0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	fca080e7          	jalr	-54(ra) # 80001b3a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	f98080e7          	jalr	-104(ra) # 80001b3a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	f8c080e7          	jalr	-116(ra) # 80001b3a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	f74080e7          	jalr	-140(ra) # 80001b3a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	f34080e7          	jalr	-204(ra) # 80001b3a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	44650513          	addi	a0,a0,1094 # 80008060 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	f08080e7          	jalr	-248(ra) # 80001b3a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	3fe50513          	addi	a0,a0,1022 # 80008068 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	40650513          	addi	a0,a0,1030 # 80008080 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3c650513          	addi	a0,a0,966 # 80008088 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda421>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	caa080e7          	jalr	-854(ra) # 80001b2a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ac070713          	addi	a4,a4,-1344 # 80008948 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	c8e080e7          	jalr	-882(ra) # 80001b2a <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	20250513          	addi	a0,a0,514 # 800080a8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	cba080e7          	jalr	-838(ra) # 80002b78 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	5da080e7          	jalr	1498(ra) # 800064a0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	1ba080e7          	jalr	442(ra) # 80002088 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1d250513          	addi	a0,a0,466 # 800080b8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	19a50513          	addi	a0,a0,410 # 80008090 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1b250513          	addi	a0,a0,434 # 800080b8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	b5c080e7          	jalr	-1188(ra) # 80001a8a <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	c1a080e7          	jalr	-998(ra) # 80002b50 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	c3a080e7          	jalr	-966(ra) # 80002b78 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	544080e7          	jalr	1348(ra) # 8000648a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	552080e7          	jalr	1362(ra) # 800064a0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	6f0080e7          	jalr	1776(ra) # 80003646 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	d90080e7          	jalr	-624(ra) # 80003cee <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	d36080e7          	jalr	-714(ra) # 80004c9c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	63a080e7          	jalr	1594(ra) # 800065a8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	ef4080e7          	jalr	-268(ra) # 80001e6a <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9cf72223          	sw	a5,-1596(a4) # 80008948 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9b87b783          	ld	a5,-1608(a5) # 80008950 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0e450513          	addi	a0,a0,228 # 800080c0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda417>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fc650513          	addi	a0,a0,-58 # 800080c8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fc650513          	addi	a0,a0,-58 # 800080d8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f8a50513          	addi	a0,a0,-118 # 800080e8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	7da080e7          	jalr	2010(ra) # 80001a08 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ea7be23          	sd	a0,1788(a5) # 80008950 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e4650513          	addi	a0,a0,-442 # 800080f0 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e4e50513          	addi	a0,a0,-434 # 80008108 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e4e50513          	addi	a0,a0,-434 # 80008118 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e5650513          	addi	a0,a0,-426 # 80008130 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d9050513          	addi	a0,a0,-624 # 80008148 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c6450513          	addi	a0,a0,-924 # 80008168 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	b9650513          	addi	a0,a0,-1130 # 80008178 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	ba650513          	addi	a0,a0,-1114 # 80008198 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b5c50513          	addi	a0,a0,-1188 # 800081b8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffda420>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <helpticks>:
// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;
void helpticks(){
    80001836:	7179                	addi	sp,sp,-48
    80001838:	f406                	sd	ra,40(sp)
    8000183a:	f022                	sd	s0,32(sp)
    8000183c:	ec26                	sd	s1,24(sp)
    8000183e:	e84a                	sd	s2,16(sp)
    80001840:	e44e                	sd	s3,8(sp)
    80001842:	e052                	sd	s4,0(sp)
    80001844:	1800                	addi	s0,sp,48
for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80001846:	00010497          	auipc	s1,0x10
    8000184a:	fba48493          	addi	s1,s1,-70 # 80011800 <proc>
    acquire(&p->lock);
    if (p->state==RUNNING){
    8000184e:	4991                	li	s3,4
      p->rtime++;
    }
    if (p->state==SLEEPING){
    80001850:	4a09                	li	s4,2
for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80001852:	00018917          	auipc	s2,0x18
    80001856:	fae90913          	addi	s2,s2,-82 # 80019800 <tickslock>
    8000185a:	a839                	j	80001878 <helpticks+0x42>
      p->rtime++;
    8000185c:	1784b783          	ld	a5,376(s1)
    80001860:	0785                	addi	a5,a5,1
    80001862:	16f4bc23          	sd	a5,376(s1)
      p->wtime++;
    }
    release(&p->lock);
    80001866:	8526                	mv	a0,s1
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	422080e7          	jalr	1058(ra) # 80000c8a <release>
for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80001870:	20048493          	addi	s1,s1,512
    80001874:	03248263          	beq	s1,s2,80001898 <helpticks+0x62>
    acquire(&p->lock);
    80001878:	8526                	mv	a0,s1
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	35c080e7          	jalr	860(ra) # 80000bd6 <acquire>
    if (p->state==RUNNING){
    80001882:	4c9c                	lw	a5,24(s1)
    80001884:	fd378ce3          	beq	a5,s3,8000185c <helpticks+0x26>
    if (p->state==SLEEPING){
    80001888:	fd479fe3          	bne	a5,s4,80001866 <helpticks+0x30>
      p->wtime++;
    8000188c:	1704b783          	ld	a5,368(s1)
    80001890:	0785                	addi	a5,a5,1
    80001892:	16f4b823          	sd	a5,368(s1)
    80001896:	bfc1                	j	80001866 <helpticks+0x30>
}
}
    80001898:	70a2                	ld	ra,40(sp)
    8000189a:	7402                	ld	s0,32(sp)
    8000189c:	64e2                	ld	s1,24(sp)
    8000189e:	6942                	ld	s2,16(sp)
    800018a0:	69a2                	ld	s3,8(sp)
    800018a2:	6a02                	ld	s4,0(sp)
    800018a4:	6145                	addi	sp,sp,48
    800018a6:	8082                	ret

00000000800018a8 <addQueue>:
int addQueue(int qno,struct proc *p){
    800018a8:	862a                	mv	a2,a0
    for(int i=0; i<q_t[qno];i++){
    800018aa:	00251713          	slli	a4,a0,0x2
    800018ae:	00007797          	auipc	a5,0x7
    800018b2:	01278793          	addi	a5,a5,18 # 800088c0 <q_t>
    800018b6:	97ba                	add	a5,a5,a4
    800018b8:	4388                	lw	a0,0(a5)
    800018ba:	02a05f63          	blez	a0,800018f8 <addQueue+0x50>
      if(p->pid==que[qno][i]->pid){
    800018be:	0305a803          	lw	a6,48(a1)
    800018c2:	00961793          	slli	a5,a2,0x9
    800018c6:	0000f717          	auipc	a4,0xf
    800018ca:	73a70713          	addi	a4,a4,1850 # 80011000 <que>
    800018ce:	97ba                	add	a5,a5,a4
    800018d0:	00661693          	slli	a3,a2,0x6
    800018d4:	fff5071b          	addiw	a4,a0,-1
    800018d8:	1702                	slli	a4,a4,0x20
    800018da:	9301                	srli	a4,a4,0x20
    800018dc:	96ba                	add	a3,a3,a4
    800018de:	068e                	slli	a3,a3,0x3
    800018e0:	0000f717          	auipc	a4,0xf
    800018e4:	72870713          	addi	a4,a4,1832 # 80011008 <que+0x8>
    800018e8:	96ba                	add	a3,a3,a4
    800018ea:	6398                	ld	a4,0(a5)
    800018ec:	5b18                	lw	a4,48(a4)
    800018ee:	07070f63          	beq	a4,a6,8000196c <addQueue+0xc4>
    for(int i=0; i<q_t[qno];i++){
    800018f2:	07a1                	addi	a5,a5,8
    800018f4:	fed79be3          	bne	a5,a3,800018ea <addQueue+0x42>
          return 1;
      }
    }
    p->que=qno;
    800018f8:	1ac5b823          	sd	a2,432(a1)
    p->entry=ticks;
    800018fc:	00007697          	auipc	a3,0x7
    80001900:	0646a683          	lw	a3,100(a3) # 80008960 <ticks>
    80001904:	02069793          	slli	a5,a3,0x20
    80001908:	9381                	srli	a5,a5,0x20
    8000190a:	1cf5b823          	sd	a5,464(a1)
    q_t[qno]++;
    8000190e:	2505                	addiw	a0,a0,1
    80001910:	0005071b          	sext.w	a4,a0
    80001914:	00261813          	slli	a6,a2,0x2
    80001918:	00007797          	auipc	a5,0x7
    8000191c:	fa878793          	addi	a5,a5,-88 # 800088c0 <q_t>
    80001920:	97c2                	add	a5,a5,a6
    80001922:	c388                	sw	a0,0(a5)
    que[qno][q_t[qno]]=p;
    80001924:	00661793          	slli	a5,a2,0x6
    80001928:	97ba                	add	a5,a5,a4
    8000192a:	078e                	slli	a5,a5,0x3
    8000192c:	0000f717          	auipc	a4,0xf
    80001930:	6d470713          	addi	a4,a4,1748 # 80011000 <que>
    80001934:	97ba                	add	a5,a5,a4
    80001936:	e38c                	sd	a1,0(a5)
     if(p->pid>2 && p->pid<13)
    80001938:	598c                	lw	a1,48(a1)
    8000193a:	ffd5871b          	addiw	a4,a1,-3
    8000193e:	47a5                	li	a5,9
    printf("Process with PID %d added to Queue %d at %d\n", p->pid-2, qno,ticks);
    return 0;
    80001940:	4501                	li	a0,0
     if(p->pid>2 && p->pid<13)
    80001942:	00e7f363          	bgeu	a5,a4,80001948 <addQueue+0xa0>
}
    80001946:	8082                	ret
int addQueue(int qno,struct proc *p){
    80001948:	1141                	addi	sp,sp,-16
    8000194a:	e406                	sd	ra,8(sp)
    8000194c:	e022                	sd	s0,0(sp)
    8000194e:	0800                	addi	s0,sp,16
    printf("Process with PID %d added to Queue %d at %d\n", p->pid-2, qno,ticks);
    80001950:	35f9                	addiw	a1,a1,-2
    80001952:	00007517          	auipc	a0,0x7
    80001956:	87650513          	addi	a0,a0,-1930 # 800081c8 <digits+0x198>
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	c30080e7          	jalr	-976(ra) # 8000058a <printf>
    return 0;
    80001962:	4501                	li	a0,0
}
    80001964:	60a2                	ld	ra,8(sp)
    80001966:	6402                	ld	s0,0(sp)
    80001968:	0141                	addi	sp,sp,16
    8000196a:	8082                	ret
          return 1;
    8000196c:	4505                	li	a0,1
    8000196e:	8082                	ret

0000000080001970 <deleteQueue>:
int deleteQueue(int qno,struct proc *p){
    80001970:	1141                	addi	sp,sp,-16
    80001972:	e422                	sd	s0,8(sp)
    80001974:	0800                	addi	s0,sp,16
  int r=0;
  int foundProcess=-1;
  for(int i=0;i<=q_t[qno];i++){
    80001976:	00251713          	slli	a4,a0,0x2
    8000197a:	00007797          	auipc	a5,0x7
    8000197e:	f4678793          	addi	a5,a5,-186 # 800088c0 <q_t>
    80001982:	97ba                	add	a5,a5,a4
    80001984:	4390                	lw	a2,0(a5)
    80001986:	06064f63          	bltz	a2,80001a04 <deleteQueue+0x94>
    if(que[qno][i]->pid==p->pid){
    8000198a:	598c                	lw	a1,48(a1)
    8000198c:	00951793          	slli	a5,a0,0x9
    80001990:	0000f717          	auipc	a4,0xf
    80001994:	67070713          	addi	a4,a4,1648 # 80011000 <que>
    80001998:	97ba                	add	a5,a5,a4
  for(int i=0;i<=q_t[qno];i++){
    8000199a:	4701                	li	a4,0
    if(que[qno][i]->pid==p->pid){
    8000199c:	6394                	ld	a3,0(a5)
    8000199e:	5a94                	lw	a3,48(a3)
    800019a0:	00b68863          	beq	a3,a1,800019b0 <deleteQueue+0x40>
  for(int i=0;i<=q_t[qno];i++){
    800019a4:	2705                	addiw	a4,a4,1
    800019a6:	07a1                	addi	a5,a5,8
    800019a8:	fee65ae3          	bge	a2,a4,8000199c <deleteQueue+0x2c>
      r=i;
      break;
    }
  }
  if(foundProcess==-1){
    return -1;
    800019ac:	557d                	li	a0,-1
    800019ae:	a881                	j	800019fe <deleteQueue+0x8e>
  }
  for(int i=r;i<q_t[qno];++i){
    800019b0:	02c75e63          	bge	a4,a2,800019ec <deleteQueue+0x7c>
    800019b4:	00651593          	slli	a1,a0,0x6
    800019b8:	95ba                	add	a1,a1,a4
    800019ba:	00359793          	slli	a5,a1,0x3
    800019be:	0000f697          	auipc	a3,0xf
    800019c2:	64268693          	addi	a3,a3,1602 # 80011000 <que>
    800019c6:	97b6                	add	a5,a5,a3
    800019c8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    800019cc:	40e6873b          	subw	a4,a3,a4
    800019d0:	1702                	slli	a4,a4,0x20
    800019d2:	9301                	srli	a4,a4,0x20
    800019d4:	972e                	add	a4,a4,a1
    800019d6:	070e                	slli	a4,a4,0x3
    800019d8:	0000f697          	auipc	a3,0xf
    800019dc:	63068693          	addi	a3,a3,1584 # 80011008 <que+0x8>
    800019e0:	9736                	add	a4,a4,a3
    que[qno][i]=que[qno][i+1];
    800019e2:	6794                	ld	a3,8(a5)
    800019e4:	e394                	sd	a3,0(a5)
  for(int i=r;i<q_t[qno];++i){
    800019e6:	07a1                	addi	a5,a5,8
    800019e8:	fee79de3          	bne	a5,a4,800019e2 <deleteQueue+0x72>
  }
  q_t[qno]--;
    800019ec:	050a                	slli	a0,a0,0x2
    800019ee:	00007797          	auipc	a5,0x7
    800019f2:	ed278793          	addi	a5,a5,-302 # 800088c0 <q_t>
    800019f6:	97aa                	add	a5,a5,a0
    800019f8:	367d                	addiw	a2,a2,-1
    800019fa:	c390                	sw	a2,0(a5)
  //printf("Process with PID %d is removed from Queue %d at %d\n", p->pid, qno,ticks);
  return 1;
    800019fc:	4505                	li	a0,1
}
    800019fe:	6422                	ld	s0,8(sp)
    80001a00:	0141                	addi	sp,sp,16
    80001a02:	8082                	ret
    return -1;
    80001a04:	557d                	li	a0,-1
    80001a06:	bfe5                	j	800019fe <deleteQueue+0x8e>

0000000080001a08 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a08:	7139                	addi	sp,sp,-64
    80001a0a:	fc06                	sd	ra,56(sp)
    80001a0c:	f822                	sd	s0,48(sp)
    80001a0e:	f426                	sd	s1,40(sp)
    80001a10:	f04a                	sd	s2,32(sp)
    80001a12:	ec4e                	sd	s3,24(sp)
    80001a14:	e852                	sd	s4,16(sp)
    80001a16:	e456                	sd	s5,8(sp)
    80001a18:	0080                	addi	s0,sp,64
    80001a1a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a1c:	00010497          	auipc	s1,0x10
    80001a20:	de448493          	addi	s1,s1,-540 # 80011800 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a24:	8a26                	mv	s4,s1
    80001a26:	04000937          	lui	s2,0x4000
    80001a2a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a2c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a2e:	00018a97          	auipc	s5,0x18
    80001a32:	dd2a8a93          	addi	s5,s5,-558 # 80019800 <tickslock>
    char *pa = kalloc();
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	0b0080e7          	jalr	176(ra) # 80000ae6 <kalloc>
    80001a3e:	862a                	mv	a2,a0
    if (pa == 0)
    80001a40:	cd0d                	beqz	a0,80001a7a <proc_mapstacks+0x72>
    uint64 va = KSTACK((int)(p - proc));
    80001a42:	414485b3          	sub	a1,s1,s4
    80001a46:	85a5                	srai	a1,a1,0x9
    80001a48:	2585                	addiw	a1,a1,1
    80001a4a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a4e:	4719                	li	a4,6
    80001a50:	6685                	lui	a3,0x1
    80001a52:	40b905b3          	sub	a1,s2,a1
    80001a56:	854e                	mv	a0,s3
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	6e6080e7          	jalr	1766(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a60:	20048493          	addi	s1,s1,512
    80001a64:	fd5499e3          	bne	s1,s5,80001a36 <proc_mapstacks+0x2e>
  }
}
    80001a68:	70e2                	ld	ra,56(sp)
    80001a6a:	7442                	ld	s0,48(sp)
    80001a6c:	74a2                	ld	s1,40(sp)
    80001a6e:	7902                	ld	s2,32(sp)
    80001a70:	69e2                	ld	s3,24(sp)
    80001a72:	6a42                	ld	s4,16(sp)
    80001a74:	6aa2                	ld	s5,8(sp)
    80001a76:	6121                	addi	sp,sp,64
    80001a78:	8082                	ret
      panic("kalloc");
    80001a7a:	00006517          	auipc	a0,0x6
    80001a7e:	77e50513          	addi	a0,a0,1918 # 800081f8 <digits+0x1c8>
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	abe080e7          	jalr	-1346(ra) # 80000540 <panic>

0000000080001a8a <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001a8a:	7139                	addi	sp,sp,-64
    80001a8c:	fc06                	sd	ra,56(sp)
    80001a8e:	f822                	sd	s0,48(sp)
    80001a90:	f426                	sd	s1,40(sp)
    80001a92:	f04a                	sd	s2,32(sp)
    80001a94:	ec4e                	sd	s3,24(sp)
    80001a96:	e852                	sd	s4,16(sp)
    80001a98:	e456                	sd	s5,8(sp)
    80001a9a:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a9c:	00006597          	auipc	a1,0x6
    80001aa0:	76458593          	addi	a1,a1,1892 # 80008200 <digits+0x1d0>
    80001aa4:	0000f517          	auipc	a0,0xf
    80001aa8:	12c50513          	addi	a0,a0,300 # 80010bd0 <pid_lock>
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	09a080e7          	jalr	154(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ab4:	00006597          	auipc	a1,0x6
    80001ab8:	75458593          	addi	a1,a1,1876 # 80008208 <digits+0x1d8>
    80001abc:	0000f517          	auipc	a0,0xf
    80001ac0:	12c50513          	addi	a0,a0,300 # 80010be8 <wait_lock>
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	082080e7          	jalr	130(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001acc:	00010497          	auipc	s1,0x10
    80001ad0:	d3448493          	addi	s1,s1,-716 # 80011800 <proc>
  {
    initlock(&p->lock, "proc");
    80001ad4:	00006a17          	auipc	s4,0x6
    80001ad8:	744a0a13          	addi	s4,s4,1860 # 80008218 <digits+0x1e8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001adc:	89a6                	mv	s3,s1
    80001ade:	04000937          	lui	s2,0x4000
    80001ae2:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ae4:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ae6:	00018a97          	auipc	s5,0x18
    80001aea:	d1aa8a93          	addi	s5,s5,-742 # 80019800 <tickslock>
    initlock(&p->lock, "proc");
    80001aee:	85d2                	mv	a1,s4
    80001af0:	8526                	mv	a0,s1
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	054080e7          	jalr	84(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001afa:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001afe:	413487b3          	sub	a5,s1,s3
    80001b02:	87a5                	srai	a5,a5,0x9
    80001b04:	2785                	addiw	a5,a5,1
    80001b06:	00d7979b          	slliw	a5,a5,0xd
    80001b0a:	40f907b3          	sub	a5,s2,a5
    80001b0e:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b10:	20048493          	addi	s1,s1,512
    80001b14:	fd549de3          	bne	s1,s5,80001aee <procinit+0x64>
  }
}
    80001b18:	70e2                	ld	ra,56(sp)
    80001b1a:	7442                	ld	s0,48(sp)
    80001b1c:	74a2                	ld	s1,40(sp)
    80001b1e:	7902                	ld	s2,32(sp)
    80001b20:	69e2                	ld	s3,24(sp)
    80001b22:	6a42                	ld	s4,16(sp)
    80001b24:	6aa2                	ld	s5,8(sp)
    80001b26:	6121                	addi	sp,sp,64
    80001b28:	8082                	ret

0000000080001b2a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b2a:	1141                	addi	sp,sp,-16
    80001b2c:	e422                	sd	s0,8(sp)
    80001b2e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b30:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b32:	2501                	sext.w	a0,a0
    80001b34:	6422                	ld	s0,8(sp)
    80001b36:	0141                	addi	sp,sp,16
    80001b38:	8082                	ret

0000000080001b3a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b3a:	1141                	addi	sp,sp,-16
    80001b3c:	e422                	sd	s0,8(sp)
    80001b3e:	0800                	addi	s0,sp,16
    80001b40:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b42:	2781                	sext.w	a5,a5
    80001b44:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b46:	0000f517          	auipc	a0,0xf
    80001b4a:	0ba50513          	addi	a0,a0,186 # 80010c00 <cpus>
    80001b4e:	953e                	add	a0,a0,a5
    80001b50:	6422                	ld	s0,8(sp)
    80001b52:	0141                	addi	sp,sp,16
    80001b54:	8082                	ret

0000000080001b56 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	1000                	addi	s0,sp,32
  push_off();
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	02a080e7          	jalr	42(ra) # 80000b8a <push_off>
    80001b68:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b6a:	2781                	sext.w	a5,a5
    80001b6c:	079e                	slli	a5,a5,0x7
    80001b6e:	0000f717          	auipc	a4,0xf
    80001b72:	06270713          	addi	a4,a4,98 # 80010bd0 <pid_lock>
    80001b76:	97ba                	add	a5,a5,a4
    80001b78:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	0b0080e7          	jalr	176(ra) # 80000c2a <pop_off>
  return p;
}
    80001b82:	8526                	mv	a0,s1
    80001b84:	60e2                	ld	ra,24(sp)
    80001b86:	6442                	ld	s0,16(sp)
    80001b88:	64a2                	ld	s1,8(sp)
    80001b8a:	6105                	addi	sp,sp,32
    80001b8c:	8082                	ret

0000000080001b8e <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b8e:	1141                	addi	sp,sp,-16
    80001b90:	e406                	sd	ra,8(sp)
    80001b92:	e022                	sd	s0,0(sp)
    80001b94:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	fc0080e7          	jalr	-64(ra) # 80001b56 <myproc>
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	0ec080e7          	jalr	236(ra) # 80000c8a <release>

  if (first)
    80001ba6:	00007797          	auipc	a5,0x7
    80001baa:	d0a7a783          	lw	a5,-758(a5) # 800088b0 <first.1>
    80001bae:	eb89                	bnez	a5,80001bc0 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bb0:	00001097          	auipc	ra,0x1
    80001bb4:	fe0080e7          	jalr	-32(ra) # 80002b90 <usertrapret>
}
    80001bb8:	60a2                	ld	ra,8(sp)
    80001bba:	6402                	ld	s0,0(sp)
    80001bbc:	0141                	addi	sp,sp,16
    80001bbe:	8082                	ret
    first = 0;
    80001bc0:	00007797          	auipc	a5,0x7
    80001bc4:	ce07a823          	sw	zero,-784(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001bc8:	4505                	li	a0,1
    80001bca:	00002097          	auipc	ra,0x2
    80001bce:	0a4080e7          	jalr	164(ra) # 80003c6e <fsinit>
    80001bd2:	bff9                	j	80001bb0 <forkret+0x22>

0000000080001bd4 <allocpid>:
{
    80001bd4:	1101                	addi	sp,sp,-32
    80001bd6:	ec06                	sd	ra,24(sp)
    80001bd8:	e822                	sd	s0,16(sp)
    80001bda:	e426                	sd	s1,8(sp)
    80001bdc:	e04a                	sd	s2,0(sp)
    80001bde:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001be0:	0000f917          	auipc	s2,0xf
    80001be4:	ff090913          	addi	s2,s2,-16 # 80010bd0 <pid_lock>
    80001be8:	854a                	mv	a0,s2
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	fec080e7          	jalr	-20(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001bf2:	00007797          	auipc	a5,0x7
    80001bf6:	cc278793          	addi	a5,a5,-830 # 800088b4 <nextpid>
    80001bfa:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bfc:	0014871b          	addiw	a4,s1,1
    80001c00:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c02:	854a                	mv	a0,s2
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	086080e7          	jalr	134(ra) # 80000c8a <release>
}
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6902                	ld	s2,0(sp)
    80001c16:	6105                	addi	sp,sp,32
    80001c18:	8082                	ret

0000000080001c1a <proc_pagetable>:
{
    80001c1a:	1101                	addi	sp,sp,-32
    80001c1c:	ec06                	sd	ra,24(sp)
    80001c1e:	e822                	sd	s0,16(sp)
    80001c20:	e426                	sd	s1,8(sp)
    80001c22:	e04a                	sd	s2,0(sp)
    80001c24:	1000                	addi	s0,sp,32
    80001c26:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	700080e7          	jalr	1792(ra) # 80001328 <uvmcreate>
    80001c30:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c32:	c121                	beqz	a0,80001c72 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c34:	4729                	li	a4,10
    80001c36:	00005697          	auipc	a3,0x5
    80001c3a:	3ca68693          	addi	a3,a3,970 # 80007000 <_trampoline>
    80001c3e:	6605                	lui	a2,0x1
    80001c40:	040005b7          	lui	a1,0x4000
    80001c44:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c46:	05b2                	slli	a1,a1,0xc
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	456080e7          	jalr	1110(ra) # 8000109e <mappages>
    80001c50:	02054863          	bltz	a0,80001c80 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c54:	4719                	li	a4,6
    80001c56:	05893683          	ld	a3,88(s2)
    80001c5a:	6605                	lui	a2,0x1
    80001c5c:	020005b7          	lui	a1,0x2000
    80001c60:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c62:	05b6                	slli	a1,a1,0xd
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	438080e7          	jalr	1080(ra) # 8000109e <mappages>
    80001c6e:	02054163          	bltz	a0,80001c90 <proc_pagetable+0x76>
}
    80001c72:	8526                	mv	a0,s1
    80001c74:	60e2                	ld	ra,24(sp)
    80001c76:	6442                	ld	s0,16(sp)
    80001c78:	64a2                	ld	s1,8(sp)
    80001c7a:	6902                	ld	s2,0(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret
    uvmfree(pagetable, 0);
    80001c80:	4581                	li	a1,0
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	8aa080e7          	jalr	-1878(ra) # 8000152e <uvmfree>
    return 0;
    80001c8c:	4481                	li	s1,0
    80001c8e:	b7d5                	j	80001c72 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c90:	4681                	li	a3,0
    80001c92:	4605                	li	a2,1
    80001c94:	040005b7          	lui	a1,0x4000
    80001c98:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c9a:	05b2                	slli	a1,a1,0xc
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	5c6080e7          	jalr	1478(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ca6:	4581                	li	a1,0
    80001ca8:	8526                	mv	a0,s1
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	884080e7          	jalr	-1916(ra) # 8000152e <uvmfree>
    return 0;
    80001cb2:	4481                	li	s1,0
    80001cb4:	bf7d                	j	80001c72 <proc_pagetable+0x58>

0000000080001cb6 <proc_freepagetable>:
{
    80001cb6:	1101                	addi	sp,sp,-32
    80001cb8:	ec06                	sd	ra,24(sp)
    80001cba:	e822                	sd	s0,16(sp)
    80001cbc:	e426                	sd	s1,8(sp)
    80001cbe:	e04a                	sd	s2,0(sp)
    80001cc0:	1000                	addi	s0,sp,32
    80001cc2:	84aa                	mv	s1,a0
    80001cc4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc6:	4681                	li	a3,0
    80001cc8:	4605                	li	a2,1
    80001cca:	040005b7          	lui	a1,0x4000
    80001cce:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cd0:	05b2                	slli	a1,a1,0xc
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	592080e7          	jalr	1426(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cda:	4681                	li	a3,0
    80001cdc:	4605                	li	a2,1
    80001cde:	020005b7          	lui	a1,0x2000
    80001ce2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ce4:	05b6                	slli	a1,a1,0xd
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	57c080e7          	jalr	1404(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cf0:	85ca                	mv	a1,s2
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	83a080e7          	jalr	-1990(ra) # 8000152e <uvmfree>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6902                	ld	s2,0(sp)
    80001d04:	6105                	addi	sp,sp,32
    80001d06:	8082                	ret

0000000080001d08 <freeproc>:
{
    80001d08:	1101                	addi	sp,sp,-32
    80001d0a:	ec06                	sd	ra,24(sp)
    80001d0c:	e822                	sd	s0,16(sp)
    80001d0e:	e426                	sd	s1,8(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d14:	6d28                	ld	a0,88(a0)
    80001d16:	c509                	beqz	a0,80001d20 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	cd0080e7          	jalr	-816(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001d20:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d24:	68a8                	ld	a0,80(s1)
    80001d26:	c511                	beqz	a0,80001d32 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d28:	64ac                	ld	a1,72(s1)
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	f8c080e7          	jalr	-116(ra) # 80001cb6 <proc_freepagetable>
  p->pagetable = 0;
    80001d32:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d36:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d3a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d3e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d42:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d46:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d4a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d4e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d52:	0004ac23          	sw	zero,24(s1)
}
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6105                	addi	sp,sp,32
    80001d5e:	8082                	ret

0000000080001d60 <allocproc>:
{
    80001d60:	1101                	addi	sp,sp,-32
    80001d62:	ec06                	sd	ra,24(sp)
    80001d64:	e822                	sd	s0,16(sp)
    80001d66:	e426                	sd	s1,8(sp)
    80001d68:	e04a                	sd	s2,0(sp)
    80001d6a:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d6c:	00010497          	auipc	s1,0x10
    80001d70:	a9448493          	addi	s1,s1,-1388 # 80011800 <proc>
    80001d74:	00018917          	auipc	s2,0x18
    80001d78:	a8c90913          	addi	s2,s2,-1396 # 80019800 <tickslock>
    acquire(&p->lock);
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	e58080e7          	jalr	-424(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001d86:	4c9c                	lw	a5,24(s1)
    80001d88:	cf81                	beqz	a5,80001da0 <allocproc+0x40>
      release(&p->lock);
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	efe080e7          	jalr	-258(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d94:	20048493          	addi	s1,s1,512
    80001d98:	ff2492e3          	bne	s1,s2,80001d7c <allocproc+0x1c>
  return 0;
    80001d9c:	4481                	li	s1,0
    80001d9e:	a079                	j	80001e2c <allocproc+0xcc>
  p->pid = allocpid();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	e34080e7          	jalr	-460(ra) # 80001bd4 <allocpid>
    80001da8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001daa:	4785                	li	a5,1
    80001dac:	cc9c                	sw	a5,24(s1)
  p->clktik=ticks;
    80001dae:	00007797          	auipc	a5,0x7
    80001db2:	bb27e783          	lwu	a5,-1102(a5) # 80008960 <ticks>
    80001db6:	16f4b423          	sd	a5,360(s1)
  p->rtime=0;
    80001dba:	1604bc23          	sd	zero,376(s1)
  p->wtime=0;
    80001dbe:	1604b823          	sd	zero,368(s1)
  p->etime=0;
    80001dc2:	1804b023          	sd	zero,384(s1)
    p->qticks[i]=0;
    80001dc6:	1804b823          	sd	zero,400(s1)
    80001dca:	1804bc23          	sd	zero,408(s1)
    80001dce:	1a04b023          	sd	zero,416(s1)
    80001dd2:	1a04b423          	sd	zero,424(s1)
  p->currticks=0;
    80001dd6:	1c04b023          	sd	zero,448(s1)
  p->que=0;
    80001dda:	1a04b823          	sd	zero,432(s1)
  p->wmlfq=0;
    80001dde:	1a04bc23          	sd	zero,440(s1)
  p->runnum=0;
    80001de2:	1804b423          	sd	zero,392(s1)
  p->entry=0;
    80001de6:	1c04b823          	sd	zero,464(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	cfc080e7          	jalr	-772(ra) # 80000ae6 <kalloc>
    80001df2:	892a                	mv	s2,a0
    80001df4:	eca8                	sd	a0,88(s1)
    80001df6:	c131                	beqz	a0,80001e3a <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    80001df8:	8526                	mv	a0,s1
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	e20080e7          	jalr	-480(ra) # 80001c1a <proc_pagetable>
    80001e02:	892a                	mv	s2,a0
    80001e04:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e06:	c531                	beqz	a0,80001e52 <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    80001e08:	07000613          	li	a2,112
    80001e0c:	4581                	li	a1,0
    80001e0e:	06048513          	addi	a0,s1,96
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	ec0080e7          	jalr	-320(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001e1a:	00000797          	auipc	a5,0x0
    80001e1e:	d7478793          	addi	a5,a5,-652 # 80001b8e <forkret>
    80001e22:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e24:	60bc                	ld	a5,64(s1)
    80001e26:	6705                	lui	a4,0x1
    80001e28:	97ba                	add	a5,a5,a4
    80001e2a:	f4bc                	sd	a5,104(s1)
}
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	60e2                	ld	ra,24(sp)
    80001e30:	6442                	ld	s0,16(sp)
    80001e32:	64a2                	ld	s1,8(sp)
    80001e34:	6902                	ld	s2,0(sp)
    80001e36:	6105                	addi	sp,sp,32
    80001e38:	8082                	ret
    freeproc(p);
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	ecc080e7          	jalr	-308(ra) # 80001d08 <freeproc>
    release(&p->lock);
    80001e44:	8526                	mv	a0,s1
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e44080e7          	jalr	-444(ra) # 80000c8a <release>
    return 0;
    80001e4e:	84ca                	mv	s1,s2
    80001e50:	bff1                	j	80001e2c <allocproc+0xcc>
    freeproc(p);
    80001e52:	8526                	mv	a0,s1
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	eb4080e7          	jalr	-332(ra) # 80001d08 <freeproc>
    release(&p->lock);
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	e2c080e7          	jalr	-468(ra) # 80000c8a <release>
    return 0;
    80001e66:	84ca                	mv	s1,s2
    80001e68:	b7d1                	j	80001e2c <allocproc+0xcc>

0000000080001e6a <userinit>:
{
    80001e6a:	1101                	addi	sp,sp,-32
    80001e6c:	ec06                	sd	ra,24(sp)
    80001e6e:	e822                	sd	s0,16(sp)
    80001e70:	e426                	sd	s1,8(sp)
    80001e72:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	eec080e7          	jalr	-276(ra) # 80001d60 <allocproc>
    80001e7c:	84aa                	mv	s1,a0
  initproc = p;
    80001e7e:	00007797          	auipc	a5,0x7
    80001e82:	aca7bd23          	sd	a0,-1318(a5) # 80008958 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e86:	03400613          	li	a2,52
    80001e8a:	00007597          	auipc	a1,0x7
    80001e8e:	a4658593          	addi	a1,a1,-1466 # 800088d0 <initcode>
    80001e92:	6928                	ld	a0,80(a0)
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	4c2080e7          	jalr	1218(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001e9c:	6785                	lui	a5,0x1
    80001e9e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ea0:	6cb8                	ld	a4,88(s1)
    80001ea2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ea6:	6cb8                	ld	a4,88(s1)
    80001ea8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eaa:	4641                	li	a2,16
    80001eac:	00006597          	auipc	a1,0x6
    80001eb0:	37458593          	addi	a1,a1,884 # 80008220 <digits+0x1f0>
    80001eb4:	15848513          	addi	a0,s1,344
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	f64080e7          	jalr	-156(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001ec0:	00006517          	auipc	a0,0x6
    80001ec4:	37050513          	addi	a0,a0,880 # 80008230 <digits+0x200>
    80001ec8:	00002097          	auipc	ra,0x2
    80001ecc:	7d0080e7          	jalr	2000(ra) # 80004698 <namei>
    80001ed0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ed4:	478d                	li	a5,3
    80001ed6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ed8:	8526                	mv	a0,s1
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	db0080e7          	jalr	-592(ra) # 80000c8a <release>
}
    80001ee2:	60e2                	ld	ra,24(sp)
    80001ee4:	6442                	ld	s0,16(sp)
    80001ee6:	64a2                	ld	s1,8(sp)
    80001ee8:	6105                	addi	sp,sp,32
    80001eea:	8082                	ret

0000000080001eec <growproc>:
{
    80001eec:	1101                	addi	sp,sp,-32
    80001eee:	ec06                	sd	ra,24(sp)
    80001ef0:	e822                	sd	s0,16(sp)
    80001ef2:	e426                	sd	s1,8(sp)
    80001ef4:	e04a                	sd	s2,0(sp)
    80001ef6:	1000                	addi	s0,sp,32
    80001ef8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001efa:	00000097          	auipc	ra,0x0
    80001efe:	c5c080e7          	jalr	-932(ra) # 80001b56 <myproc>
    80001f02:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f04:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f06:	01204c63          	bgtz	s2,80001f1e <growproc+0x32>
  else if (n < 0)
    80001f0a:	02094663          	bltz	s2,80001f36 <growproc+0x4a>
  p->sz = sz;
    80001f0e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f10:	4501                	li	a0,0
}
    80001f12:	60e2                	ld	ra,24(sp)
    80001f14:	6442                	ld	s0,16(sp)
    80001f16:	64a2                	ld	s1,8(sp)
    80001f18:	6902                	ld	s2,0(sp)
    80001f1a:	6105                	addi	sp,sp,32
    80001f1c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f1e:	4691                	li	a3,4
    80001f20:	00b90633          	add	a2,s2,a1
    80001f24:	6928                	ld	a0,80(a0)
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	4ea080e7          	jalr	1258(ra) # 80001410 <uvmalloc>
    80001f2e:	85aa                	mv	a1,a0
    80001f30:	fd79                	bnez	a0,80001f0e <growproc+0x22>
      return -1;
    80001f32:	557d                	li	a0,-1
    80001f34:	bff9                	j	80001f12 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f36:	00b90633          	add	a2,s2,a1
    80001f3a:	6928                	ld	a0,80(a0)
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	48c080e7          	jalr	1164(ra) # 800013c8 <uvmdealloc>
    80001f44:	85aa                	mv	a1,a0
    80001f46:	b7e1                	j	80001f0e <growproc+0x22>

0000000080001f48 <fork>:
{
    80001f48:	7139                	addi	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f5a:	00000097          	auipc	ra,0x0
    80001f5e:	bfc080e7          	jalr	-1028(ra) # 80001b56 <myproc>
    80001f62:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	dfc080e7          	jalr	-516(ra) # 80001d60 <allocproc>
    80001f6c:	10050c63          	beqz	a0,80002084 <fork+0x13c>
    80001f70:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f72:	048ab603          	ld	a2,72(s5)
    80001f76:	692c                	ld	a1,80(a0)
    80001f78:	050ab503          	ld	a0,80(s5)
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	5ec080e7          	jalr	1516(ra) # 80001568 <uvmcopy>
    80001f84:	04054863          	bltz	a0,80001fd4 <fork+0x8c>
  np->sz = p->sz;
    80001f88:	048ab783          	ld	a5,72(s5)
    80001f8c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f90:	058ab683          	ld	a3,88(s5)
    80001f94:	87b6                	mv	a5,a3
    80001f96:	058a3703          	ld	a4,88(s4)
    80001f9a:	12068693          	addi	a3,a3,288
    80001f9e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fa2:	6788                	ld	a0,8(a5)
    80001fa4:	6b8c                	ld	a1,16(a5)
    80001fa6:	6f90                	ld	a2,24(a5)
    80001fa8:	01073023          	sd	a6,0(a4)
    80001fac:	e708                	sd	a0,8(a4)
    80001fae:	eb0c                	sd	a1,16(a4)
    80001fb0:	ef10                	sd	a2,24(a4)
    80001fb2:	02078793          	addi	a5,a5,32
    80001fb6:	02070713          	addi	a4,a4,32
    80001fba:	fed792e3          	bne	a5,a3,80001f9e <fork+0x56>
  np->trapframe->a0 = 0;
    80001fbe:	058a3783          	ld	a5,88(s4)
    80001fc2:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fc6:	0d0a8493          	addi	s1,s5,208
    80001fca:	0d0a0913          	addi	s2,s4,208
    80001fce:	150a8993          	addi	s3,s5,336
    80001fd2:	a00d                	j	80001ff4 <fork+0xac>
    freeproc(np);
    80001fd4:	8552                	mv	a0,s4
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	d32080e7          	jalr	-718(ra) # 80001d08 <freeproc>
    release(&np->lock);
    80001fde:	8552                	mv	a0,s4
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	caa080e7          	jalr	-854(ra) # 80000c8a <release>
    return -1;
    80001fe8:	597d                	li	s2,-1
    80001fea:	a059                	j	80002070 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001fec:	04a1                	addi	s1,s1,8
    80001fee:	0921                	addi	s2,s2,8
    80001ff0:	01348b63          	beq	s1,s3,80002006 <fork+0xbe>
    if (p->ofile[i])
    80001ff4:	6088                	ld	a0,0(s1)
    80001ff6:	d97d                	beqz	a0,80001fec <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ff8:	00003097          	auipc	ra,0x3
    80001ffc:	d36080e7          	jalr	-714(ra) # 80004d2e <filedup>
    80002000:	00a93023          	sd	a0,0(s2)
    80002004:	b7e5                	j	80001fec <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002006:	150ab503          	ld	a0,336(s5)
    8000200a:	00002097          	auipc	ra,0x2
    8000200e:	ea4080e7          	jalr	-348(ra) # 80003eae <idup>
    80002012:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002016:	4641                	li	a2,16
    80002018:	158a8593          	addi	a1,s5,344
    8000201c:	158a0513          	addi	a0,s4,344
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	dfc080e7          	jalr	-516(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80002028:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    8000202c:	8552                	mv	a0,s4
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	c5c080e7          	jalr	-932(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80002036:	0000f497          	auipc	s1,0xf
    8000203a:	bb248493          	addi	s1,s1,-1102 # 80010be8 <wait_lock>
    8000203e:	8526                	mv	a0,s1
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	b96080e7          	jalr	-1130(ra) # 80000bd6 <acquire>
  np->parent = p;
    80002048:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	c3c080e7          	jalr	-964(ra) # 80000c8a <release>
  acquire(&np->lock);
    80002056:	8552                	mv	a0,s4
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	b7e080e7          	jalr	-1154(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80002060:	478d                	li	a5,3
    80002062:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002066:	8552                	mv	a0,s4
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c22080e7          	jalr	-990(ra) # 80000c8a <release>
}
    80002070:	854a                	mv	a0,s2
    80002072:	70e2                	ld	ra,56(sp)
    80002074:	7442                	ld	s0,48(sp)
    80002076:	74a2                	ld	s1,40(sp)
    80002078:	7902                	ld	s2,32(sp)
    8000207a:	69e2                	ld	s3,24(sp)
    8000207c:	6a42                	ld	s4,16(sp)
    8000207e:	6aa2                	ld	s5,8(sp)
    80002080:	6121                	addi	sp,sp,64
    80002082:	8082                	ret
    return -1;
    80002084:	597d                	li	s2,-1
    80002086:	b7ed                	j	80002070 <fork+0x128>

0000000080002088 <scheduler>:
{
    80002088:	7119                	addi	sp,sp,-128
    8000208a:	fc86                	sd	ra,120(sp)
    8000208c:	f8a2                	sd	s0,112(sp)
    8000208e:	f4a6                	sd	s1,104(sp)
    80002090:	f0ca                	sd	s2,96(sp)
    80002092:	ecce                	sd	s3,88(sp)
    80002094:	e8d2                	sd	s4,80(sp)
    80002096:	e4d6                	sd	s5,72(sp)
    80002098:	e0da                	sd	s6,64(sp)
    8000209a:	fc5e                	sd	s7,56(sp)
    8000209c:	f862                	sd	s8,48(sp)
    8000209e:	f466                	sd	s9,40(sp)
    800020a0:	f06a                	sd	s10,32(sp)
    800020a2:	ec6e                	sd	s11,24(sp)
    800020a4:	0100                	addi	s0,sp,128
    800020a6:	8792                	mv	a5,tp
  int id = r_tp();
    800020a8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020aa:	00779693          	slli	a3,a5,0x7
    800020ae:	0000f717          	auipc	a4,0xf
    800020b2:	b2270713          	addi	a4,a4,-1246 # 80010bd0 <pid_lock>
    800020b6:	9736                	add	a4,a4,a3
    800020b8:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &p->context);
    800020bc:	0000f717          	auipc	a4,0xf
    800020c0:	b4c70713          	addi	a4,a4,-1204 # 80010c08 <cpus+0x8>
    800020c4:	9736                	add	a4,a4,a3
    800020c6:	f8e43423          	sd	a4,-120(s0)
              for(p = proc; p < &proc[NPROC]; p++) {
    800020ca:	00017497          	auipc	s1,0x17
    800020ce:	73648493          	addi	s1,s1,1846 # 80019800 <tickslock>
            int aging=ticks-p->entry;
    800020d2:	00007917          	auipc	s2,0x7
    800020d6:	88e90913          	addi	s2,s2,-1906 # 80008960 <ticks>
            if (aging>28){
    800020da:	49f1                	li	s3,28
    800020dc:	00006c97          	auipc	s9,0x6
    800020e0:	7f4c8c93          	addi	s9,s9,2036 # 800088d0 <initcode>
            c->proc=p;
    800020e4:	0000fd97          	auipc	s11,0xf
    800020e8:	aecd8d93          	addi	s11,s11,-1300 # 80010bd0 <pid_lock>
    800020ec:	9db6                	add	s11,s11,a3
    800020ee:	a8f9                	j	800021cc <scheduler+0x144>
                  addQueue(0,p);
    800020f0:	85d2                	mv	a1,s4
    800020f2:	4501                	li	a0,0
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	7b4080e7          	jalr	1972(ra) # 800018a8 <addQueue>
              for(p = proc; p < &proc[NPROC]; p++) {
    800020fc:	200a0a13          	addi	s4,s4,512
    80002100:	009a0663          	beq	s4,s1,8000210c <scheduler+0x84>
                if(p->que==0){
    80002104:	1b0a3783          	ld	a5,432(s4)
    80002108:	fbf5                	bnez	a5,800020fc <scheduler+0x74>
    8000210a:	b7dd                	j	800020f0 <scheduler+0x68>
            for(p = proc; p < &proc[NPROC]; p++) {
    8000210c:	0000fa17          	auipc	s4,0xf
    80002110:	6f4a0a13          	addi	s4,s4,1780 # 80011800 <proc>
    80002114:	a819                	j	8000212a <scheduler+0xa2>
                addQueue(0,p);
    80002116:	85d2                	mv	a1,s4
    80002118:	4501                	li	a0,0
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	78e080e7          	jalr	1934(ra) # 800018a8 <addQueue>
            for(p = proc; p < &proc[NPROC]; p++) {
    80002122:	200a0a13          	addi	s4,s4,512
    80002126:	049a0263          	beq	s4,s1,8000216a <scheduler+0xe2>
            int aging=ticks-p->entry;
    8000212a:	1d0a3703          	ld	a4,464(s4)
    8000212e:	00092783          	lw	a5,0(s2)
            if (aging>28){
    80002132:	9f99                	subw	a5,a5,a4
    80002134:	fef9d7e3          	bge	s3,a5,80002122 <scheduler+0x9a>
               deleteQueue(p->que,p);
    80002138:	85d2                	mv	a1,s4
    8000213a:	1b0a2503          	lw	a0,432(s4)
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	832080e7          	jalr	-1998(ra) # 80001970 <deleteQueue>
               p->entry=ticks;
    80002146:	00096783          	lwu	a5,0(s2)
    8000214a:	1cfa3823          	sd	a5,464(s4)
               p->currticks=0;
    8000214e:	1c0a3023          	sd	zero,448(s4)
               p->wmlfq=0;
    80002152:	1a0a3c23          	sd	zero,440(s4)
               if(p->que>0){
    80002156:	1b0a3503          	ld	a0,432(s4)
    8000215a:	dd55                	beqz	a0,80002116 <scheduler+0x8e>
               addQueue(p->que-1,p); 
    8000215c:	85d2                	mv	a1,s4
    8000215e:	357d                	addiw	a0,a0,-1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	748080e7          	jalr	1864(ra) # 800018a8 <addQueue>
    80002168:	bf6d                	j	80002122 <scheduler+0x9a>
    8000216a:	00006b17          	auipc	s6,0x6
    8000216e:	756b0b13          	addi	s6,s6,1878 # 800088c0 <q_t>
    80002172:	0000fb97          	auipc	s7,0xf
    80002176:	e8eb8b93          	addi	s7,s7,-370 # 80011000 <que>
             p=0;
    8000217a:	4c01                	li	s8,0
              for(int j=0;j<=q_t[i];j++){
    8000217c:	4d01                	li	s10,0
                if(que[i][j]->state==RUNNABLE){
    8000217e:	4a8d                	li	s5,3
    80002180:	a831                	j	8000219c <scheduler+0x114>
                  deleteQueue(p->que,p);
    80002182:	85d2                	mv	a1,s4
    80002184:	1b0a2503          	lw	a0,432(s4)
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	7e8080e7          	jalr	2024(ra) # 80001970 <deleteQueue>
                if(que[i][j]->state==RUNNABLE){
    80002190:	8c52                	mv	s8,s4
             for(int i=0;i<4;i++){
    80002192:	0b11                	addi	s6,s6,4
    80002194:	200b8b93          	addi	s7,s7,512
    80002198:	039b0363          	beq	s6,s9,800021be <scheduler+0x136>
              if (q_t[i]==-1)
    8000219c:	000b2603          	lw	a2,0(s6)
    800021a0:	fe0649e3          	bltz	a2,80002192 <scheduler+0x10a>
    800021a4:	87de                	mv	a5,s7
              for(int j=0;j<=q_t[i];j++){
    800021a6:	876a                	mv	a4,s10
                if(que[i][j]->state==RUNNABLE){
    800021a8:	0007ba03          	ld	s4,0(a5)
    800021ac:	018a2683          	lw	a3,24(s4)
    800021b0:	fd5689e3          	beq	a3,s5,80002182 <scheduler+0xfa>
              for(int j=0;j<=q_t[i];j++){
    800021b4:	2705                	addiw	a4,a4,1
    800021b6:	07a1                	addi	a5,a5,8
    800021b8:	fee658e3          	bge	a2,a4,800021a8 <scheduler+0x120>
    800021bc:	bfd9                	j	80002192 <scheduler+0x10a>
        if(p!=0 && p->state==RUNNABLE){
    800021be:	000c0763          	beqz	s8,800021cc <scheduler+0x144>
    800021c2:	018c2703          	lw	a4,24(s8)
    800021c6:	478d                	li	a5,3
    800021c8:	00f70d63          	beq	a4,a5,800021e2 <scheduler+0x15a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021d4:	10079073          	csrw	sstatus,a5
              for(p = proc; p < &proc[NPROC]; p++) {
    800021d8:	0000fa17          	auipc	s4,0xf
    800021dc:	628a0a13          	addi	s4,s4,1576 # 80011800 <proc>
    800021e0:	b715                	j	80002104 <scheduler+0x7c>
            p->runnum++;
    800021e2:	188c3783          	ld	a5,392(s8)
    800021e6:	0785                	addi	a5,a5,1
    800021e8:	18fc3423          	sd	a5,392(s8)
            p->qticks[p->que]++;
    800021ec:	1b0c3783          	ld	a5,432(s8)
    800021f0:	078e                	slli	a5,a5,0x3
    800021f2:	97e2                	add	a5,a5,s8
    800021f4:	1907b703          	ld	a4,400(a5)
    800021f8:	0705                	addi	a4,a4,1
    800021fa:	18e7b823          	sd	a4,400(a5)
            p->state=RUNNING;
    800021fe:	4791                	li	a5,4
    80002200:	00fc2c23          	sw	a5,24(s8)
            acquire(&p->lock);
    80002204:	8562                	mv	a0,s8
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	9d0080e7          	jalr	-1584(ra) # 80000bd6 <acquire>
            c->proc=p;
    8000220e:	038db823          	sd	s8,48(s11)
            swtch(&c->context, &p->context);
    80002212:	060c0593          	addi	a1,s8,96
    80002216:	f8843503          	ld	a0,-120(s0)
    8000221a:	00001097          	auipc	ra,0x1
    8000221e:	8cc080e7          	jalr	-1844(ra) # 80002ae6 <swtch>
            c->proc=0;
    80002222:	020db823          	sd	zero,48(s11)
            release(&p->lock);
    80002226:	8562                	mv	a0,s8
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a62080e7          	jalr	-1438(ra) # 80000c8a <release>
            if(p!=0 && p->state==RUNNABLE){
    80002230:	018c2703          	lw	a4,24(s8)
    80002234:	478d                	li	a5,3
    80002236:	f8f71be3          	bne	a4,a5,800021cc <scheduler+0x144>
              if(p->changequeue==1){
    8000223a:	1c8c3703          	ld	a4,456(s8)
    8000223e:	4785                	li	a5,1
    80002240:	f8f716e3          	bne	a4,a5,800021cc <scheduler+0x144>
                p->changequeue=0;
    80002244:	1c0c3423          	sd	zero,456(s8)
                p->currticks=0;
    80002248:	1c0c3023          	sd	zero,448(s8)
                p->wmlfq=0;
    8000224c:	1a0c3c23          	sd	zero,440(s8)
                p->entry=ticks;
    80002250:	00096783          	lwu	a5,0(s2)
    80002254:	1cfc3823          	sd	a5,464(s8)
                if(p->que<3){
    80002258:	1b0c3783          	ld	a5,432(s8)
    8000225c:	4709                	li	a4,2
    8000225e:	00f76563          	bltu	a4,a5,80002268 <scheduler+0x1e0>
                  p->que++; 
    80002262:	0785                	addi	a5,a5,1
    80002264:	1afc3823          	sd	a5,432(s8)
                addQueue(p->que,p);
    80002268:	85e2                	mv	a1,s8
    8000226a:	1b0c2503          	lw	a0,432(s8)
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	63a080e7          	jalr	1594(ra) # 800018a8 <addQueue>
    80002276:	bf99                	j	800021cc <scheduler+0x144>

0000000080002278 <sched>:
{
    80002278:	7179                	addi	sp,sp,-48
    8000227a:	f406                	sd	ra,40(sp)
    8000227c:	f022                	sd	s0,32(sp)
    8000227e:	ec26                	sd	s1,24(sp)
    80002280:	e84a                	sd	s2,16(sp)
    80002282:	e44e                	sd	s3,8(sp)
    80002284:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002286:	00000097          	auipc	ra,0x0
    8000228a:	8d0080e7          	jalr	-1840(ra) # 80001b56 <myproc>
    8000228e:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	8cc080e7          	jalr	-1844(ra) # 80000b5c <holding>
    80002298:	c93d                	beqz	a0,8000230e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000229a:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000229c:	2781                	sext.w	a5,a5
    8000229e:	079e                	slli	a5,a5,0x7
    800022a0:	0000f717          	auipc	a4,0xf
    800022a4:	93070713          	addi	a4,a4,-1744 # 80010bd0 <pid_lock>
    800022a8:	97ba                	add	a5,a5,a4
    800022aa:	0a87a703          	lw	a4,168(a5)
    800022ae:	4785                	li	a5,1
    800022b0:	06f71763          	bne	a4,a5,8000231e <sched+0xa6>
  if (p->state == RUNNING)
    800022b4:	4c98                	lw	a4,24(s1)
    800022b6:	4791                	li	a5,4
    800022b8:	06f70b63          	beq	a4,a5,8000232e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022bc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022c0:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022c2:	efb5                	bnez	a5,8000233e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022c6:	0000f917          	auipc	s2,0xf
    800022ca:	90a90913          	addi	s2,s2,-1782 # 80010bd0 <pid_lock>
    800022ce:	2781                	sext.w	a5,a5
    800022d0:	079e                	slli	a5,a5,0x7
    800022d2:	97ca                	add	a5,a5,s2
    800022d4:	0ac7a983          	lw	s3,172(a5)
    800022d8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022da:	2781                	sext.w	a5,a5
    800022dc:	079e                	slli	a5,a5,0x7
    800022de:	0000f597          	auipc	a1,0xf
    800022e2:	92a58593          	addi	a1,a1,-1750 # 80010c08 <cpus+0x8>
    800022e6:	95be                	add	a1,a1,a5
    800022e8:	06048513          	addi	a0,s1,96
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	7fa080e7          	jalr	2042(ra) # 80002ae6 <swtch>
    800022f4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022f6:	2781                	sext.w	a5,a5
    800022f8:	079e                	slli	a5,a5,0x7
    800022fa:	993e                	add	s2,s2,a5
    800022fc:	0b392623          	sw	s3,172(s2)
}
    80002300:	70a2                	ld	ra,40(sp)
    80002302:	7402                	ld	s0,32(sp)
    80002304:	64e2                	ld	s1,24(sp)
    80002306:	6942                	ld	s2,16(sp)
    80002308:	69a2                	ld	s3,8(sp)
    8000230a:	6145                	addi	sp,sp,48
    8000230c:	8082                	ret
    panic("sched p->lock");
    8000230e:	00006517          	auipc	a0,0x6
    80002312:	f2a50513          	addi	a0,a0,-214 # 80008238 <digits+0x208>
    80002316:	ffffe097          	auipc	ra,0xffffe
    8000231a:	22a080e7          	jalr	554(ra) # 80000540 <panic>
    panic("sched locks");
    8000231e:	00006517          	auipc	a0,0x6
    80002322:	f2a50513          	addi	a0,a0,-214 # 80008248 <digits+0x218>
    80002326:	ffffe097          	auipc	ra,0xffffe
    8000232a:	21a080e7          	jalr	538(ra) # 80000540 <panic>
    panic("sched running");
    8000232e:	00006517          	auipc	a0,0x6
    80002332:	f2a50513          	addi	a0,a0,-214 # 80008258 <digits+0x228>
    80002336:	ffffe097          	auipc	ra,0xffffe
    8000233a:	20a080e7          	jalr	522(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000233e:	00006517          	auipc	a0,0x6
    80002342:	f2a50513          	addi	a0,a0,-214 # 80008268 <digits+0x238>
    80002346:	ffffe097          	auipc	ra,0xffffe
    8000234a:	1fa080e7          	jalr	506(ra) # 80000540 <panic>

000000008000234e <yield>:
{
    8000234e:	1101                	addi	sp,sp,-32
    80002350:	ec06                	sd	ra,24(sp)
    80002352:	e822                	sd	s0,16(sp)
    80002354:	e426                	sd	s1,8(sp)
    80002356:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	7fe080e7          	jalr	2046(ra) # 80001b56 <myproc>
    80002360:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000236a:	478d                	li	a5,3
    8000236c:	cc9c                	sw	a5,24(s1)
  sched();
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	f0a080e7          	jalr	-246(ra) # 80002278 <sched>
  release(&p->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	912080e7          	jalr	-1774(ra) # 80000c8a <release>
}
    80002380:	60e2                	ld	ra,24(sp)
    80002382:	6442                	ld	s0,16(sp)
    80002384:	64a2                	ld	s1,8(sp)
    80002386:	6105                	addi	sp,sp,32
    80002388:	8082                	ret

000000008000238a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000238a:	7179                	addi	sp,sp,-48
    8000238c:	f406                	sd	ra,40(sp)
    8000238e:	f022                	sd	s0,32(sp)
    80002390:	ec26                	sd	s1,24(sp)
    80002392:	e84a                	sd	s2,16(sp)
    80002394:	e44e                	sd	s3,8(sp)
    80002396:	1800                	addi	s0,sp,48
    80002398:	89aa                	mv	s3,a0
    8000239a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	7ba080e7          	jalr	1978(ra) # 80001b56 <myproc>
    800023a4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	830080e7          	jalr	-2000(ra) # 80000bd6 <acquire>
  release(lk);
    800023ae:	854a                	mv	a0,s2
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800023b8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023bc:	4789                	li	a5,2
    800023be:	cc9c                	sw	a5,24(s1)

  sched();
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	eb8080e7          	jalr	-328(ra) # 80002278 <sched>

  // Tidy up.
  p->chan = 0;
    800023c8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8bc080e7          	jalr	-1860(ra) # 80000c8a <release>
  acquire(lk);
    800023d6:	854a                	mv	a0,s2
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	7fe080e7          	jalr	2046(ra) # 80000bd6 <acquire>
}
    800023e0:	70a2                	ld	ra,40(sp)
    800023e2:	7402                	ld	s0,32(sp)
    800023e4:	64e2                	ld	s1,24(sp)
    800023e6:	6942                	ld	s2,16(sp)
    800023e8:	69a2                	ld	s3,8(sp)
    800023ea:	6145                	addi	sp,sp,48
    800023ec:	8082                	ret

00000000800023ee <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023ee:	7139                	addi	sp,sp,-64
    800023f0:	fc06                	sd	ra,56(sp)
    800023f2:	f822                	sd	s0,48(sp)
    800023f4:	f426                	sd	s1,40(sp)
    800023f6:	f04a                	sd	s2,32(sp)
    800023f8:	ec4e                	sd	s3,24(sp)
    800023fa:	e852                	sd	s4,16(sp)
    800023fc:	e456                	sd	s5,8(sp)
    800023fe:	0080                	addi	s0,sp,64
    80002400:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002402:	0000f497          	auipc	s1,0xf
    80002406:	3fe48493          	addi	s1,s1,1022 # 80011800 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000240a:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000240c:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000240e:	00017917          	auipc	s2,0x17
    80002412:	3f290913          	addi	s2,s2,1010 # 80019800 <tickslock>
    80002416:	a811                	j	8000242a <wakeup+0x3c>
#ifdef MLFQ
    p->wmlfq=0;
    p->currticks=0;
#endif
      }
      release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	870080e7          	jalr	-1936(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002422:	20048493          	addi	s1,s1,512
    80002426:	03248a63          	beq	s1,s2,8000245a <wakeup+0x6c>
    if (p != myproc())
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	72c080e7          	jalr	1836(ra) # 80001b56 <myproc>
    80002432:	fea488e3          	beq	s1,a0,80002422 <wakeup+0x34>
      acquire(&p->lock);
    80002436:	8526                	mv	a0,s1
    80002438:	ffffe097          	auipc	ra,0xffffe
    8000243c:	79e080e7          	jalr	1950(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002440:	4c9c                	lw	a5,24(s1)
    80002442:	fd379be3          	bne	a5,s3,80002418 <wakeup+0x2a>
    80002446:	709c                	ld	a5,32(s1)
    80002448:	fd4798e3          	bne	a5,s4,80002418 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000244c:	0154ac23          	sw	s5,24(s1)
    p->wmlfq=0;
    80002450:	1a04bc23          	sd	zero,440(s1)
    p->currticks=0;
    80002454:	1c04b023          	sd	zero,448(s1)
    80002458:	b7c1                	j	80002418 <wakeup+0x2a>
    }
  }
}
    8000245a:	70e2                	ld	ra,56(sp)
    8000245c:	7442                	ld	s0,48(sp)
    8000245e:	74a2                	ld	s1,40(sp)
    80002460:	7902                	ld	s2,32(sp)
    80002462:	69e2                	ld	s3,24(sp)
    80002464:	6a42                	ld	s4,16(sp)
    80002466:	6aa2                	ld	s5,8(sp)
    80002468:	6121                	addi	sp,sp,64
    8000246a:	8082                	ret

000000008000246c <reparent>:
{
    8000246c:	7179                	addi	sp,sp,-48
    8000246e:	f406                	sd	ra,40(sp)
    80002470:	f022                	sd	s0,32(sp)
    80002472:	ec26                	sd	s1,24(sp)
    80002474:	e84a                	sd	s2,16(sp)
    80002476:	e44e                	sd	s3,8(sp)
    80002478:	e052                	sd	s4,0(sp)
    8000247a:	1800                	addi	s0,sp,48
    8000247c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000247e:	0000f497          	auipc	s1,0xf
    80002482:	38248493          	addi	s1,s1,898 # 80011800 <proc>
      pp->parent = initproc;
    80002486:	00006a17          	auipc	s4,0x6
    8000248a:	4d2a0a13          	addi	s4,s4,1234 # 80008958 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000248e:	00017997          	auipc	s3,0x17
    80002492:	37298993          	addi	s3,s3,882 # 80019800 <tickslock>
    80002496:	a029                	j	800024a0 <reparent+0x34>
    80002498:	20048493          	addi	s1,s1,512
    8000249c:	01348d63          	beq	s1,s3,800024b6 <reparent+0x4a>
    if (pp->parent == p)
    800024a0:	7c9c                	ld	a5,56(s1)
    800024a2:	ff279be3          	bne	a5,s2,80002498 <reparent+0x2c>
      pp->parent = initproc;
    800024a6:	000a3503          	ld	a0,0(s4)
    800024aa:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024ac:	00000097          	auipc	ra,0x0
    800024b0:	f42080e7          	jalr	-190(ra) # 800023ee <wakeup>
    800024b4:	b7d5                	j	80002498 <reparent+0x2c>
}
    800024b6:	70a2                	ld	ra,40(sp)
    800024b8:	7402                	ld	s0,32(sp)
    800024ba:	64e2                	ld	s1,24(sp)
    800024bc:	6942                	ld	s2,16(sp)
    800024be:	69a2                	ld	s3,8(sp)
    800024c0:	6a02                	ld	s4,0(sp)
    800024c2:	6145                	addi	sp,sp,48
    800024c4:	8082                	ret

00000000800024c6 <exit>:
{
    800024c6:	7179                	addi	sp,sp,-48
    800024c8:	f406                	sd	ra,40(sp)
    800024ca:	f022                	sd	s0,32(sp)
    800024cc:	ec26                	sd	s1,24(sp)
    800024ce:	e84a                	sd	s2,16(sp)
    800024d0:	e44e                	sd	s3,8(sp)
    800024d2:	e052                	sd	s4,0(sp)
    800024d4:	1800                	addi	s0,sp,48
    800024d6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	67e080e7          	jalr	1662(ra) # 80001b56 <myproc>
    800024e0:	89aa                	mv	s3,a0
  if (p == initproc)
    800024e2:	00006797          	auipc	a5,0x6
    800024e6:	4767b783          	ld	a5,1142(a5) # 80008958 <initproc>
    800024ea:	0d050493          	addi	s1,a0,208
    800024ee:	15050913          	addi	s2,a0,336
    800024f2:	02a79363          	bne	a5,a0,80002518 <exit+0x52>
    panic("init exiting");
    800024f6:	00006517          	auipc	a0,0x6
    800024fa:	d8a50513          	addi	a0,a0,-630 # 80008280 <digits+0x250>
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	042080e7          	jalr	66(ra) # 80000540 <panic>
      fileclose(f);
    80002506:	00003097          	auipc	ra,0x3
    8000250a:	87a080e7          	jalr	-1926(ra) # 80004d80 <fileclose>
      p->ofile[fd] = 0;
    8000250e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002512:	04a1                	addi	s1,s1,8
    80002514:	01248563          	beq	s1,s2,8000251e <exit+0x58>
    if (p->ofile[fd])
    80002518:	6088                	ld	a0,0(s1)
    8000251a:	f575                	bnez	a0,80002506 <exit+0x40>
    8000251c:	bfdd                	j	80002512 <exit+0x4c>
  begin_op();
    8000251e:	00002097          	auipc	ra,0x2
    80002522:	39a080e7          	jalr	922(ra) # 800048b8 <begin_op>
  iput(p->cwd);
    80002526:	1509b503          	ld	a0,336(s3)
    8000252a:	00002097          	auipc	ra,0x2
    8000252e:	b7c080e7          	jalr	-1156(ra) # 800040a6 <iput>
  end_op();
    80002532:	00002097          	auipc	ra,0x2
    80002536:	404080e7          	jalr	1028(ra) # 80004936 <end_op>
  p->cwd = 0;
    8000253a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000253e:	0000e497          	auipc	s1,0xe
    80002542:	6aa48493          	addi	s1,s1,1706 # 80010be8 <wait_lock>
    80002546:	8526                	mv	a0,s1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	68e080e7          	jalr	1678(ra) # 80000bd6 <acquire>
  reparent(p);
    80002550:	854e                	mv	a0,s3
    80002552:	00000097          	auipc	ra,0x0
    80002556:	f1a080e7          	jalr	-230(ra) # 8000246c <reparent>
  wakeup(p->parent);
    8000255a:	0389b503          	ld	a0,56(s3)
    8000255e:	00000097          	auipc	ra,0x0
    80002562:	e90080e7          	jalr	-368(ra) # 800023ee <wakeup>
  acquire(&p->lock);
    80002566:	854e                	mv	a0,s3
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	66e080e7          	jalr	1646(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002570:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002574:	4795                	li	a5,5
    80002576:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000257a:	00006797          	auipc	a5,0x6
    8000257e:	3e67e783          	lwu	a5,998(a5) # 80008960 <ticks>
    80002582:	18f9b023          	sd	a5,384(s3)
  deleteQueue(p->que,p);
    80002586:	85ce                	mv	a1,s3
    80002588:	1b09a503          	lw	a0,432(s3)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	3e4080e7          	jalr	996(ra) # 80001970 <deleteQueue>
  release(&wait_lock);
    80002594:	8526                	mv	a0,s1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	6f4080e7          	jalr	1780(ra) # 80000c8a <release>
  sched();
    8000259e:	00000097          	auipc	ra,0x0
    800025a2:	cda080e7          	jalr	-806(ra) # 80002278 <sched>
  panic("zombie exit");
    800025a6:	00006517          	auipc	a0,0x6
    800025aa:	cea50513          	addi	a0,a0,-790 # 80008290 <digits+0x260>
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	f92080e7          	jalr	-110(ra) # 80000540 <panic>

00000000800025b6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025b6:	7179                	addi	sp,sp,-48
    800025b8:	f406                	sd	ra,40(sp)
    800025ba:	f022                	sd	s0,32(sp)
    800025bc:	ec26                	sd	s1,24(sp)
    800025be:	e84a                	sd	s2,16(sp)
    800025c0:	e44e                	sd	s3,8(sp)
    800025c2:	1800                	addi	s0,sp,48
    800025c4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	23a48493          	addi	s1,s1,570 # 80011800 <proc>
    800025ce:	00017997          	auipc	s3,0x17
    800025d2:	23298993          	addi	s3,s3,562 # 80019800 <tickslock>
  {
    acquire(&p->lock);
    800025d6:	8526                	mv	a0,s1
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	5fe080e7          	jalr	1534(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800025e0:	589c                	lw	a5,48(s1)
    800025e2:	01278d63          	beq	a5,s2,800025fc <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	6a2080e7          	jalr	1698(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025f0:	20048493          	addi	s1,s1,512
    800025f4:	ff3491e3          	bne	s1,s3,800025d6 <kill+0x20>
  }
  return -1;
    800025f8:	557d                	li	a0,-1
    800025fa:	a829                	j	80002614 <kill+0x5e>
      p->killed = 1;
    800025fc:	4785                	li	a5,1
    800025fe:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002600:	4c98                	lw	a4,24(s1)
    80002602:	4789                	li	a5,2
    80002604:	00f70f63          	beq	a4,a5,80002622 <kill+0x6c>
      release(&p->lock);
    80002608:	8526                	mv	a0,s1
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	680080e7          	jalr	1664(ra) # 80000c8a <release>
      return 0;
    80002612:	4501                	li	a0,0
}
    80002614:	70a2                	ld	ra,40(sp)
    80002616:	7402                	ld	s0,32(sp)
    80002618:	64e2                	ld	s1,24(sp)
    8000261a:	6942                	ld	s2,16(sp)
    8000261c:	69a2                	ld	s3,8(sp)
    8000261e:	6145                	addi	sp,sp,48
    80002620:	8082                	ret
        p->state = RUNNABLE;
    80002622:	478d                	li	a5,3
    80002624:	cc9c                	sw	a5,24(s1)
        p->wmlfq=0;
    80002626:	1a04bc23          	sd	zero,440(s1)
        addQueue(p->que,p);
    8000262a:	85a6                	mv	a1,s1
    8000262c:	1b04a503          	lw	a0,432(s1)
    80002630:	fffff097          	auipc	ra,0xfffff
    80002634:	278080e7          	jalr	632(ra) # 800018a8 <addQueue>
    80002638:	bfc1                	j	80002608 <kill+0x52>

000000008000263a <setkilled>:

void setkilled(struct proc *p)
{
    8000263a:	1101                	addi	sp,sp,-32
    8000263c:	ec06                	sd	ra,24(sp)
    8000263e:	e822                	sd	s0,16(sp)
    80002640:	e426                	sd	s1,8(sp)
    80002642:	1000                	addi	s0,sp,32
    80002644:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	590080e7          	jalr	1424(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000264e:	4785                	li	a5,1
    80002650:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	636080e7          	jalr	1590(ra) # 80000c8a <release>
}
    8000265c:	60e2                	ld	ra,24(sp)
    8000265e:	6442                	ld	s0,16(sp)
    80002660:	64a2                	ld	s1,8(sp)
    80002662:	6105                	addi	sp,sp,32
    80002664:	8082                	ret

0000000080002666 <killed>:

int killed(struct proc *p)
{
    80002666:	1101                	addi	sp,sp,-32
    80002668:	ec06                	sd	ra,24(sp)
    8000266a:	e822                	sd	s0,16(sp)
    8000266c:	e426                	sd	s1,8(sp)
    8000266e:	e04a                	sd	s2,0(sp)
    80002670:	1000                	addi	s0,sp,32
    80002672:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	562080e7          	jalr	1378(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000267c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002680:	8526                	mv	a0,s1
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	608080e7          	jalr	1544(ra) # 80000c8a <release>
  return k;
}
    8000268a:	854a                	mv	a0,s2
    8000268c:	60e2                	ld	ra,24(sp)
    8000268e:	6442                	ld	s0,16(sp)
    80002690:	64a2                	ld	s1,8(sp)
    80002692:	6902                	ld	s2,0(sp)
    80002694:	6105                	addi	sp,sp,32
    80002696:	8082                	ret

0000000080002698 <wait>:
{
    80002698:	715d                	addi	sp,sp,-80
    8000269a:	e486                	sd	ra,72(sp)
    8000269c:	e0a2                	sd	s0,64(sp)
    8000269e:	fc26                	sd	s1,56(sp)
    800026a0:	f84a                	sd	s2,48(sp)
    800026a2:	f44e                	sd	s3,40(sp)
    800026a4:	f052                	sd	s4,32(sp)
    800026a6:	ec56                	sd	s5,24(sp)
    800026a8:	e85a                	sd	s6,16(sp)
    800026aa:	e45e                	sd	s7,8(sp)
    800026ac:	e062                	sd	s8,0(sp)
    800026ae:	0880                	addi	s0,sp,80
    800026b0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026b2:	fffff097          	auipc	ra,0xfffff
    800026b6:	4a4080e7          	jalr	1188(ra) # 80001b56 <myproc>
    800026ba:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026bc:	0000e517          	auipc	a0,0xe
    800026c0:	52c50513          	addi	a0,a0,1324 # 80010be8 <wait_lock>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	512080e7          	jalr	1298(ra) # 80000bd6 <acquire>
    havekids = 0;
    800026cc:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026ce:	4a15                	li	s4,5
        havekids = 1;
    800026d0:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026d2:	00017997          	auipc	s3,0x17
    800026d6:	12e98993          	addi	s3,s3,302 # 80019800 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026da:	0000ec17          	auipc	s8,0xe
    800026de:	50ec0c13          	addi	s8,s8,1294 # 80010be8 <wait_lock>
    havekids = 0;
    800026e2:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026e4:	0000f497          	auipc	s1,0xf
    800026e8:	11c48493          	addi	s1,s1,284 # 80011800 <proc>
    800026ec:	a0bd                	j	8000275a <wait+0xc2>
          pid = pp->pid;
    800026ee:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026f2:	000b0e63          	beqz	s6,8000270e <wait+0x76>
    800026f6:	4691                	li	a3,4
    800026f8:	02c48613          	addi	a2,s1,44
    800026fc:	85da                	mv	a1,s6
    800026fe:	05093503          	ld	a0,80(s2)
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	f6a080e7          	jalr	-150(ra) # 8000166c <copyout>
    8000270a:	02054563          	bltz	a0,80002734 <wait+0x9c>
          freeproc(pp);
    8000270e:	8526                	mv	a0,s1
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	5f8080e7          	jalr	1528(ra) # 80001d08 <freeproc>
          release(&pp->lock);
    80002718:	8526                	mv	a0,s1
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	570080e7          	jalr	1392(ra) # 80000c8a <release>
          release(&wait_lock);
    80002722:	0000e517          	auipc	a0,0xe
    80002726:	4c650513          	addi	a0,a0,1222 # 80010be8 <wait_lock>
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	560080e7          	jalr	1376(ra) # 80000c8a <release>
          return pid;
    80002732:	a0b5                	j	8000279e <wait+0x106>
            release(&pp->lock);
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	554080e7          	jalr	1364(ra) # 80000c8a <release>
            release(&wait_lock);
    8000273e:	0000e517          	auipc	a0,0xe
    80002742:	4aa50513          	addi	a0,a0,1194 # 80010be8 <wait_lock>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
            return -1;
    8000274e:	59fd                	li	s3,-1
    80002750:	a0b9                	j	8000279e <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002752:	20048493          	addi	s1,s1,512
    80002756:	03348463          	beq	s1,s3,8000277e <wait+0xe6>
      if (pp->parent == p)
    8000275a:	7c9c                	ld	a5,56(s1)
    8000275c:	ff279be3          	bne	a5,s2,80002752 <wait+0xba>
        acquire(&pp->lock);
    80002760:	8526                	mv	a0,s1
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	474080e7          	jalr	1140(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000276a:	4c9c                	lw	a5,24(s1)
    8000276c:	f94781e3          	beq	a5,s4,800026ee <wait+0x56>
        release(&pp->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	518080e7          	jalr	1304(ra) # 80000c8a <release>
        havekids = 1;
    8000277a:	8756                	mv	a4,s5
    8000277c:	bfd9                	j	80002752 <wait+0xba>
    if (!havekids || killed(p))
    8000277e:	c719                	beqz	a4,8000278c <wait+0xf4>
    80002780:	854a                	mv	a0,s2
    80002782:	00000097          	auipc	ra,0x0
    80002786:	ee4080e7          	jalr	-284(ra) # 80002666 <killed>
    8000278a:	c51d                	beqz	a0,800027b8 <wait+0x120>
      release(&wait_lock);
    8000278c:	0000e517          	auipc	a0,0xe
    80002790:	45c50513          	addi	a0,a0,1116 # 80010be8 <wait_lock>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	4f6080e7          	jalr	1270(ra) # 80000c8a <release>
      return -1;
    8000279c:	59fd                	li	s3,-1
}
    8000279e:	854e                	mv	a0,s3
    800027a0:	60a6                	ld	ra,72(sp)
    800027a2:	6406                	ld	s0,64(sp)
    800027a4:	74e2                	ld	s1,56(sp)
    800027a6:	7942                	ld	s2,48(sp)
    800027a8:	79a2                	ld	s3,40(sp)
    800027aa:	7a02                	ld	s4,32(sp)
    800027ac:	6ae2                	ld	s5,24(sp)
    800027ae:	6b42                	ld	s6,16(sp)
    800027b0:	6ba2                	ld	s7,8(sp)
    800027b2:	6c02                	ld	s8,0(sp)
    800027b4:	6161                	addi	sp,sp,80
    800027b6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027b8:	85e2                	mv	a1,s8
    800027ba:	854a                	mv	a0,s2
    800027bc:	00000097          	auipc	ra,0x0
    800027c0:	bce080e7          	jalr	-1074(ra) # 8000238a <sleep>
    havekids = 0;
    800027c4:	bf39                	j	800026e2 <wait+0x4a>

00000000800027c6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027c6:	7179                	addi	sp,sp,-48
    800027c8:	f406                	sd	ra,40(sp)
    800027ca:	f022                	sd	s0,32(sp)
    800027cc:	ec26                	sd	s1,24(sp)
    800027ce:	e84a                	sd	s2,16(sp)
    800027d0:	e44e                	sd	s3,8(sp)
    800027d2:	e052                	sd	s4,0(sp)
    800027d4:	1800                	addi	s0,sp,48
    800027d6:	84aa                	mv	s1,a0
    800027d8:	892e                	mv	s2,a1
    800027da:	89b2                	mv	s3,a2
    800027dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	378080e7          	jalr	888(ra) # 80001b56 <myproc>
  if (user_dst)
    800027e6:	c08d                	beqz	s1,80002808 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027e8:	86d2                	mv	a3,s4
    800027ea:	864e                	mv	a2,s3
    800027ec:	85ca                	mv	a1,s2
    800027ee:	6928                	ld	a0,80(a0)
    800027f0:	fffff097          	auipc	ra,0xfffff
    800027f4:	e7c080e7          	jalr	-388(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027f8:	70a2                	ld	ra,40(sp)
    800027fa:	7402                	ld	s0,32(sp)
    800027fc:	64e2                	ld	s1,24(sp)
    800027fe:	6942                	ld	s2,16(sp)
    80002800:	69a2                	ld	s3,8(sp)
    80002802:	6a02                	ld	s4,0(sp)
    80002804:	6145                	addi	sp,sp,48
    80002806:	8082                	ret
    memmove((char *)dst, src, len);
    80002808:	000a061b          	sext.w	a2,s4
    8000280c:	85ce                	mv	a1,s3
    8000280e:	854a                	mv	a0,s2
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	51e080e7          	jalr	1310(ra) # 80000d2e <memmove>
    return 0;
    80002818:	8526                	mv	a0,s1
    8000281a:	bff9                	j	800027f8 <either_copyout+0x32>

000000008000281c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000281c:	7179                	addi	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	e052                	sd	s4,0(sp)
    8000282a:	1800                	addi	s0,sp,48
    8000282c:	892a                	mv	s2,a0
    8000282e:	84ae                	mv	s1,a1
    80002830:	89b2                	mv	s3,a2
    80002832:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	322080e7          	jalr	802(ra) # 80001b56 <myproc>
  if (user_src)
    8000283c:	c08d                	beqz	s1,8000285e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000283e:	86d2                	mv	a3,s4
    80002840:	864e                	mv	a2,s3
    80002842:	85ca                	mv	a1,s2
    80002844:	6928                	ld	a0,80(a0)
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	eb2080e7          	jalr	-334(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000284e:	70a2                	ld	ra,40(sp)
    80002850:	7402                	ld	s0,32(sp)
    80002852:	64e2                	ld	s1,24(sp)
    80002854:	6942                	ld	s2,16(sp)
    80002856:	69a2                	ld	s3,8(sp)
    80002858:	6a02                	ld	s4,0(sp)
    8000285a:	6145                	addi	sp,sp,48
    8000285c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000285e:	000a061b          	sext.w	a2,s4
    80002862:	85ce                	mv	a1,s3
    80002864:	854a                	mv	a0,s2
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	4c8080e7          	jalr	1224(ra) # 80000d2e <memmove>
    return 0;
    8000286e:	8526                	mv	a0,s1
    80002870:	bff9                	j	8000284e <either_copyin+0x32>

0000000080002872 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002872:	715d                	addi	sp,sp,-80
    80002874:	e486                	sd	ra,72(sp)
    80002876:	e0a2                	sd	s0,64(sp)
    80002878:	fc26                	sd	s1,56(sp)
    8000287a:	f84a                	sd	s2,48(sp)
    8000287c:	f44e                	sd	s3,40(sp)
    8000287e:	f052                	sd	s4,32(sp)
    80002880:	ec56                	sd	s5,24(sp)
    80002882:	e85a                	sd	s6,16(sp)
    80002884:	e45e                	sd	s7,8(sp)
    80002886:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	83050513          	addi	a0,a0,-2000 # 800080b8 <digits+0x88>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cfa080e7          	jalr	-774(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002898:	0000f497          	auipc	s1,0xf
    8000289c:	0c048493          	addi	s1,s1,192 # 80011958 <proc+0x158>
    800028a0:	00017917          	auipc	s2,0x17
    800028a4:	0b890913          	addi	s2,s2,184 # 80019958 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028aa:	00006997          	auipc	s3,0x6
    800028ae:	9f698993          	addi	s3,s3,-1546 # 800082a0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800028b2:	00006a97          	auipc	s5,0x6
    800028b6:	9f6a8a93          	addi	s5,s5,-1546 # 800082a8 <digits+0x278>
    printf("\n");
    800028ba:	00005a17          	auipc	s4,0x5
    800028be:	7fea0a13          	addi	s4,s4,2046 # 800080b8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c2:	00006b97          	auipc	s7,0x6
    800028c6:	a46b8b93          	addi	s7,s7,-1466 # 80008308 <states.0>
    800028ca:	a00d                	j	800028ec <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028cc:	ed86a583          	lw	a1,-296(a3)
    800028d0:	8556                	mv	a0,s5
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	cb8080e7          	jalr	-840(ra) # 8000058a <printf>
    printf("\n");
    800028da:	8552                	mv	a0,s4
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	cae080e7          	jalr	-850(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028e4:	20048493          	addi	s1,s1,512
    800028e8:	03248263          	beq	s1,s2,8000290c <procdump+0x9a>
    if (p->state == UNUSED)
    800028ec:	86a6                	mv	a3,s1
    800028ee:	ec04a783          	lw	a5,-320(s1)
    800028f2:	dbed                	beqz	a5,800028e4 <procdump+0x72>
      state = "???";
    800028f4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f6:	fcfb6be3          	bltu	s6,a5,800028cc <procdump+0x5a>
    800028fa:	02079713          	slli	a4,a5,0x20
    800028fe:	01d75793          	srli	a5,a4,0x1d
    80002902:	97de                	add	a5,a5,s7
    80002904:	6390                	ld	a2,0(a5)
    80002906:	f279                	bnez	a2,800028cc <procdump+0x5a>
      state = "???";
    80002908:	864e                	mv	a2,s3
    8000290a:	b7c9                	j	800028cc <procdump+0x5a>
  }
}
    8000290c:	60a6                	ld	ra,72(sp)
    8000290e:	6406                	ld	s0,64(sp)
    80002910:	74e2                	ld	s1,56(sp)
    80002912:	7942                	ld	s2,48(sp)
    80002914:	79a2                	ld	s3,40(sp)
    80002916:	7a02                	ld	s4,32(sp)
    80002918:	6ae2                	ld	s5,24(sp)
    8000291a:	6b42                	ld	s6,16(sp)
    8000291c:	6ba2                	ld	s7,8(sp)
    8000291e:	6161                	addi	sp,sp,80
    80002920:	8082                	ret

0000000080002922 <waitx>:
// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002922:	711d                	addi	sp,sp,-96
    80002924:	ec86                	sd	ra,88(sp)
    80002926:	e8a2                	sd	s0,80(sp)
    80002928:	e4a6                	sd	s1,72(sp)
    8000292a:	e0ca                	sd	s2,64(sp)
    8000292c:	fc4e                	sd	s3,56(sp)
    8000292e:	f852                	sd	s4,48(sp)
    80002930:	f456                	sd	s5,40(sp)
    80002932:	f05a                	sd	s6,32(sp)
    80002934:	ec5e                	sd	s7,24(sp)
    80002936:	e862                	sd	s8,16(sp)
    80002938:	e466                	sd	s9,8(sp)
    8000293a:	e06a                	sd	s10,0(sp)
    8000293c:	1080                	addi	s0,sp,96
    8000293e:	8b2a                	mv	s6,a0
    80002940:	8bae                	mv	s7,a1
    80002942:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002944:	fffff097          	auipc	ra,0xfffff
    80002948:	212080e7          	jalr	530(ra) # 80001b56 <myproc>
    8000294c:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000294e:	0000e517          	auipc	a0,0xe
    80002952:	29a50513          	addi	a0,a0,666 # 80010be8 <wait_lock>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	280080e7          	jalr	640(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000295e:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002960:	4a15                	li	s4,5
        havekids = 1;
    80002962:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002964:	00017997          	auipc	s3,0x17
    80002968:	e9c98993          	addi	s3,s3,-356 # 80019800 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000296c:	0000ed17          	auipc	s10,0xe
    80002970:	27cd0d13          	addi	s10,s10,636 # 80010be8 <wait_lock>
    havekids = 0;
    80002974:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002976:	0000f497          	auipc	s1,0xf
    8000297a:	e8a48493          	addi	s1,s1,-374 # 80011800 <proc>
    8000297e:	a069                	j	80002a08 <waitx+0xe6>
          pid = np->pid;
    80002980:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002984:	1784b783          	ld	a5,376(s1)
    80002988:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->clktik - np->rtime;
    8000298c:	1804b783          	ld	a5,384(s1)
    80002990:	1684b703          	ld	a4,360(s1)
    80002994:	1784b683          	ld	a3,376(s1)
    80002998:	9f35                	addw	a4,a4,a3
    8000299a:	9f99                	subw	a5,a5,a4
    8000299c:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800029a0:	000b0e63          	beqz	s6,800029bc <waitx+0x9a>
    800029a4:	4691                	li	a3,4
    800029a6:	02c48613          	addi	a2,s1,44
    800029aa:	85da                	mv	a1,s6
    800029ac:	05093503          	ld	a0,80(s2)
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	cbc080e7          	jalr	-836(ra) # 8000166c <copyout>
    800029b8:	02054563          	bltz	a0,800029e2 <waitx+0xc0>
          freeproc(np);
    800029bc:	8526                	mv	a0,s1
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	34a080e7          	jalr	842(ra) # 80001d08 <freeproc>
          release(&np->lock);
    800029c6:	8526                	mv	a0,s1
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	2c2080e7          	jalr	706(ra) # 80000c8a <release>
          release(&wait_lock);
    800029d0:	0000e517          	auipc	a0,0xe
    800029d4:	21850513          	addi	a0,a0,536 # 80010be8 <wait_lock>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
          return pid;
    800029e0:	a09d                	j	80002a46 <waitx+0x124>
            release(&np->lock);
    800029e2:	8526                	mv	a0,s1
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	2a6080e7          	jalr	678(ra) # 80000c8a <release>
            release(&wait_lock);
    800029ec:	0000e517          	auipc	a0,0xe
    800029f0:	1fc50513          	addi	a0,a0,508 # 80010be8 <wait_lock>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	296080e7          	jalr	662(ra) # 80000c8a <release>
            return -1;
    800029fc:	59fd                	li	s3,-1
    800029fe:	a0a1                	j	80002a46 <waitx+0x124>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a00:	20048493          	addi	s1,s1,512
    80002a04:	03348463          	beq	s1,s3,80002a2c <waitx+0x10a>
      if (np->parent == p)
    80002a08:	7c9c                	ld	a5,56(s1)
    80002a0a:	ff279be3          	bne	a5,s2,80002a00 <waitx+0xde>
        acquire(&np->lock);
    80002a0e:	8526                	mv	a0,s1
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	1c6080e7          	jalr	454(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002a18:	4c9c                	lw	a5,24(s1)
    80002a1a:	f74783e3          	beq	a5,s4,80002980 <waitx+0x5e>
        release(&np->lock);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	26a080e7          	jalr	618(ra) # 80000c8a <release>
        havekids = 1;
    80002a28:	8756                	mv	a4,s5
    80002a2a:	bfd9                	j	80002a00 <waitx+0xde>
    if (!havekids || p->killed)
    80002a2c:	c701                	beqz	a4,80002a34 <waitx+0x112>
    80002a2e:	02892783          	lw	a5,40(s2)
    80002a32:	cb8d                	beqz	a5,80002a64 <waitx+0x142>
      release(&wait_lock);
    80002a34:	0000e517          	auipc	a0,0xe
    80002a38:	1b450513          	addi	a0,a0,436 # 80010be8 <wait_lock>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
      return -1;
    80002a44:	59fd                	li	s3,-1
  }
}
    80002a46:	854e                	mv	a0,s3
    80002a48:	60e6                	ld	ra,88(sp)
    80002a4a:	6446                	ld	s0,80(sp)
    80002a4c:	64a6                	ld	s1,72(sp)
    80002a4e:	6906                	ld	s2,64(sp)
    80002a50:	79e2                	ld	s3,56(sp)
    80002a52:	7a42                	ld	s4,48(sp)
    80002a54:	7aa2                	ld	s5,40(sp)
    80002a56:	7b02                	ld	s6,32(sp)
    80002a58:	6be2                	ld	s7,24(sp)
    80002a5a:	6c42                	ld	s8,16(sp)
    80002a5c:	6ca2                	ld	s9,8(sp)
    80002a5e:	6d02                	ld	s10,0(sp)
    80002a60:	6125                	addi	sp,sp,96
    80002a62:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a64:	85ea                	mv	a1,s10
    80002a66:	854a                	mv	a0,s2
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	922080e7          	jalr	-1758(ra) # 8000238a <sleep>
    havekids = 0;
    80002a70:	b711                	j	80002974 <waitx+0x52>

0000000080002a72 <getps>:
int
getps(void) 
{
    80002a72:	7179                	addi	sp,sp,-48
    80002a74:	f406                	sd	ra,40(sp)
    80002a76:	f022                	sd	s0,32(sp)
    80002a78:	ec26                	sd	s1,24(sp)
    80002a7a:	e84a                	sd	s2,16(sp)
    80002a7c:	e44e                	sd	s3,8(sp)
    80002a7e:	1800                	addi	s0,sp,48
    struct proc *p;
    int ret = -1;
    printf("Name\ts_time\n");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	83850513          	addi	a0,a0,-1992 # 800082b8 <digits+0x288>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	b02080e7          	jalr	-1278(ra) # 8000058a <printf>
    for (p = proc; p < &proc[3]; p++)
    80002a90:	0000f497          	auipc	s1,0xf
    80002a94:	d7048493          	addi	s1,s1,-656 # 80011800 <proc>
    {
      acquire(&p->lock);
      printf("%s \t %d\n", p->name,p->wtime);
    80002a98:	00006997          	auipc	s3,0x6
    80002a9c:	83098993          	addi	s3,s3,-2000 # 800082c8 <digits+0x298>
    for (p = proc; p < &proc[3]; p++)
    80002aa0:	0000f917          	auipc	s2,0xf
    80002aa4:	36090913          	addi	s2,s2,864 # 80011e00 <proc+0x600>
      acquire(&p->lock);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	12c080e7          	jalr	300(ra) # 80000bd6 <acquire>
      printf("%s \t %d\n", p->name,p->wtime);
    80002ab2:	1704b603          	ld	a2,368(s1)
    80002ab6:	15848593          	addi	a1,s1,344
    80002aba:	854e                	mv	a0,s3
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	ace080e7          	jalr	-1330(ra) # 8000058a <printf>
      release(&p->lock);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	1c4080e7          	jalr	452(ra) # 80000c8a <release>
    for (p = proc; p < &proc[3]; p++)
    80002ace:	20048493          	addi	s1,s1,512
    80002ad2:	fd249be3          	bne	s1,s2,80002aa8 <getps+0x36>
   }
    return ret;
}
    80002ad6:	557d                	li	a0,-1
    80002ad8:	70a2                	ld	ra,40(sp)
    80002ada:	7402                	ld	s0,32(sp)
    80002adc:	64e2                	ld	s1,24(sp)
    80002ade:	6942                	ld	s2,16(sp)
    80002ae0:	69a2                	ld	s3,8(sp)
    80002ae2:	6145                	addi	sp,sp,48
    80002ae4:	8082                	ret

0000000080002ae6 <swtch>:
    80002ae6:	00153023          	sd	ra,0(a0)
    80002aea:	00253423          	sd	sp,8(a0)
    80002aee:	e900                	sd	s0,16(a0)
    80002af0:	ed04                	sd	s1,24(a0)
    80002af2:	03253023          	sd	s2,32(a0)
    80002af6:	03353423          	sd	s3,40(a0)
    80002afa:	03453823          	sd	s4,48(a0)
    80002afe:	03553c23          	sd	s5,56(a0)
    80002b02:	05653023          	sd	s6,64(a0)
    80002b06:	05753423          	sd	s7,72(a0)
    80002b0a:	05853823          	sd	s8,80(a0)
    80002b0e:	05953c23          	sd	s9,88(a0)
    80002b12:	07a53023          	sd	s10,96(a0)
    80002b16:	07b53423          	sd	s11,104(a0)
    80002b1a:	0005b083          	ld	ra,0(a1)
    80002b1e:	0085b103          	ld	sp,8(a1)
    80002b22:	6980                	ld	s0,16(a1)
    80002b24:	6d84                	ld	s1,24(a1)
    80002b26:	0205b903          	ld	s2,32(a1)
    80002b2a:	0285b983          	ld	s3,40(a1)
    80002b2e:	0305ba03          	ld	s4,48(a1)
    80002b32:	0385ba83          	ld	s5,56(a1)
    80002b36:	0405bb03          	ld	s6,64(a1)
    80002b3a:	0485bb83          	ld	s7,72(a1)
    80002b3e:	0505bc03          	ld	s8,80(a1)
    80002b42:	0585bc83          	ld	s9,88(a1)
    80002b46:	0605bd03          	ld	s10,96(a1)
    80002b4a:	0685bd83          	ld	s11,104(a1)
    80002b4e:	8082                	ret

0000000080002b50 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b50:	1141                	addi	sp,sp,-16
    80002b52:	e406                	sd	ra,8(sp)
    80002b54:	e022                	sd	s0,0(sp)
    80002b56:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b58:	00005597          	auipc	a1,0x5
    80002b5c:	7e058593          	addi	a1,a1,2016 # 80008338 <states.0+0x30>
    80002b60:	00017517          	auipc	a0,0x17
    80002b64:	ca050513          	addi	a0,a0,-864 # 80019800 <tickslock>
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	fde080e7          	jalr	-34(ra) # 80000b46 <initlock>
}
    80002b70:	60a2                	ld	ra,8(sp)
    80002b72:	6402                	ld	s0,0(sp)
    80002b74:	0141                	addi	sp,sp,16
    80002b76:	8082                	ret

0000000080002b78 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b78:	1141                	addi	sp,sp,-16
    80002b7a:	e422                	sd	s0,8(sp)
    80002b7c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b7e:	00004797          	auipc	a5,0x4
    80002b82:	85278793          	addi	a5,a5,-1966 # 800063d0 <kernelvec>
    80002b86:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b8a:	6422                	ld	s0,8(sp)
    80002b8c:	0141                	addi	sp,sp,16
    80002b8e:	8082                	ret

0000000080002b90 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002b90:	1141                	addi	sp,sp,-16
    80002b92:	e406                	sd	ra,8(sp)
    80002b94:	e022                	sd	s0,0(sp)
    80002b96:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	fbe080e7          	jalr	-66(ra) # 80001b56 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ba4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ba6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002baa:	00004697          	auipc	a3,0x4
    80002bae:	45668693          	addi	a3,a3,1110 # 80007000 <_trampoline>
    80002bb2:	00004717          	auipc	a4,0x4
    80002bb6:	44e70713          	addi	a4,a4,1102 # 80007000 <_trampoline>
    80002bba:	8f15                	sub	a4,a4,a3
    80002bbc:	040007b7          	lui	a5,0x4000
    80002bc0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002bc2:	07b2                	slli	a5,a5,0xc
    80002bc4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc6:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bca:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bcc:	18002673          	csrr	a2,satp
    80002bd0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bd2:	6d30                	ld	a2,88(a0)
    80002bd4:	6138                	ld	a4,64(a0)
    80002bd6:	6585                	lui	a1,0x1
    80002bd8:	972e                	add	a4,a4,a1
    80002bda:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bdc:	6d38                	ld	a4,88(a0)
    80002bde:	00000617          	auipc	a2,0x0
    80002be2:	13e60613          	addi	a2,a2,318 # 80002d1c <usertrap>
    80002be6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002be8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bea:	8612                	mv	a2,tp
    80002bec:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bee:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bf2:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bf6:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bfa:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bfe:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c00:	6f18                	ld	a4,24(a4)
    80002c02:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c06:	6928                	ld	a0,80(a0)
    80002c08:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c0a:	00004717          	auipc	a4,0x4
    80002c0e:	49270713          	addi	a4,a4,1170 # 8000709c <userret>
    80002c12:	8f15                	sub	a4,a4,a3
    80002c14:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c16:	577d                	li	a4,-1
    80002c18:	177e                	slli	a4,a4,0x3f
    80002c1a:	8d59                	or	a0,a0,a4
    80002c1c:	9782                	jalr	a5
}
    80002c1e:	60a2                	ld	ra,8(sp)
    80002c20:	6402                	ld	s0,0(sp)
    80002c22:	0141                	addi	sp,sp,16
    80002c24:	8082                	ret

0000000080002c26 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	e426                	sd	s1,8(sp)
    80002c2e:	e04a                	sd	s2,0(sp)
    80002c30:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c32:	00017917          	auipc	s2,0x17
    80002c36:	bce90913          	addi	s2,s2,-1074 # 80019800 <tickslock>
    80002c3a:	854a                	mv	a0,s2
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	f9a080e7          	jalr	-102(ra) # 80000bd6 <acquire>
  ticks++;
    80002c44:	00006497          	auipc	s1,0x6
    80002c48:	d1c48493          	addi	s1,s1,-740 # 80008960 <ticks>
    80002c4c:	409c                	lw	a5,0(s1)
    80002c4e:	2785                	addiw	a5,a5,1
    80002c50:	c09c                	sw	a5,0(s1)
  helpticks();
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	be4080e7          	jalr	-1052(ra) # 80001836 <helpticks>
  //   {
  //     p->wtime++;
  //   }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002c5a:	8526                	mv	a0,s1
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	792080e7          	jalr	1938(ra) # 800023ee <wakeup>
  release(&tickslock);
    80002c64:	854a                	mv	a0,s2
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	024080e7          	jalr	36(ra) # 80000c8a <release>
}
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6902                	ld	s2,0(sp)
    80002c76:	6105                	addi	sp,sp,32
    80002c78:	8082                	ret

0000000080002c7a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002c7a:	1101                	addi	sp,sp,-32
    80002c7c:	ec06                	sd	ra,24(sp)
    80002c7e:	e822                	sd	s0,16(sp)
    80002c80:	e426                	sd	s1,8(sp)
    80002c82:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c84:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002c88:	00074d63          	bltz	a4,80002ca2 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002c8c:	57fd                	li	a5,-1
    80002c8e:	17fe                	slli	a5,a5,0x3f
    80002c90:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002c92:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002c94:	06f70363          	beq	a4,a5,80002cfa <devintr+0x80>
  }
}
    80002c98:	60e2                	ld	ra,24(sp)
    80002c9a:	6442                	ld	s0,16(sp)
    80002c9c:	64a2                	ld	s1,8(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret
      (scause & 0xff) == 9)
    80002ca2:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002ca6:	46a5                	li	a3,9
    80002ca8:	fed792e3          	bne	a5,a3,80002c8c <devintr+0x12>
    int irq = plic_claim();
    80002cac:	00004097          	auipc	ra,0x4
    80002cb0:	82c080e7          	jalr	-2004(ra) # 800064d8 <plic_claim>
    80002cb4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002cb6:	47a9                	li	a5,10
    80002cb8:	02f50763          	beq	a0,a5,80002ce6 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002cbc:	4785                	li	a5,1
    80002cbe:	02f50963          	beq	a0,a5,80002cf0 <devintr+0x76>
    return 1;
    80002cc2:	4505                	li	a0,1
    else if (irq)
    80002cc4:	d8f1                	beqz	s1,80002c98 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cc6:	85a6                	mv	a1,s1
    80002cc8:	00005517          	auipc	a0,0x5
    80002ccc:	67850513          	addi	a0,a0,1656 # 80008340 <states.0+0x38>
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	8ba080e7          	jalr	-1862(ra) # 8000058a <printf>
      plic_complete(irq);
    80002cd8:	8526                	mv	a0,s1
    80002cda:	00004097          	auipc	ra,0x4
    80002cde:	822080e7          	jalr	-2014(ra) # 800064fc <plic_complete>
    return 1;
    80002ce2:	4505                	li	a0,1
    80002ce4:	bf55                	j	80002c98 <devintr+0x1e>
      uartintr();
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	cb2080e7          	jalr	-846(ra) # 80000998 <uartintr>
    80002cee:	b7ed                	j	80002cd8 <devintr+0x5e>
      virtio_disk_intr();
    80002cf0:	00004097          	auipc	ra,0x4
    80002cf4:	cd4080e7          	jalr	-812(ra) # 800069c4 <virtio_disk_intr>
    80002cf8:	b7c5                	j	80002cd8 <devintr+0x5e>
    if (cpuid() == 0)
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	e30080e7          	jalr	-464(ra) # 80001b2a <cpuid>
    80002d02:	c901                	beqz	a0,80002d12 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d04:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d08:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d0a:	14479073          	csrw	sip,a5
    return 2;
    80002d0e:	4509                	li	a0,2
    80002d10:	b761                	j	80002c98 <devintr+0x1e>
      clockintr();
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	f14080e7          	jalr	-236(ra) # 80002c26 <clockintr>
    80002d1a:	b7ed                	j	80002d04 <devintr+0x8a>

0000000080002d1c <usertrap>:
{
    80002d1c:	7179                	addi	sp,sp,-48
    80002d1e:	f406                	sd	ra,40(sp)
    80002d20:	f022                	sd	s0,32(sp)
    80002d22:	ec26                	sd	s1,24(sp)
    80002d24:	e84a                	sd	s2,16(sp)
    80002d26:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d28:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d2c:	1007f793          	andi	a5,a5,256
    80002d30:	e7e5                	bnez	a5,80002e18 <usertrap+0xfc>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d32:	00003797          	auipc	a5,0x3
    80002d36:	69e78793          	addi	a5,a5,1694 # 800063d0 <kernelvec>
    80002d3a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	e18080e7          	jalr	-488(ra) # 80001b56 <myproc>
    80002d46:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d48:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d4a:	14102773          	csrr	a4,sepc
    80002d4e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d50:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d54:	47a1                	li	a5,8
    80002d56:	0cf70963          	beq	a4,a5,80002e28 <usertrap+0x10c>
  else if ((which_dev = devintr()) != 0)
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	f20080e7          	jalr	-224(ra) # 80002c7a <devintr>
    80002d62:	892a                	mv	s2,a0
    80002d64:	14050d63          	beqz	a0,80002ebe <usertrap+0x1a2>
    if(which_dev==2 && p->set==0 && p->called == 1){
    80002d68:	4789                	li	a5,2
    80002d6a:	0ef51363          	bne	a0,a5,80002e50 <usertrap+0x134>
    80002d6e:	1f04b703          	ld	a4,496(s1)
    80002d72:	4785                	li	a5,1
    80002d74:	1782                	slli	a5,a5,0x20
    80002d76:	10f70363          	beq	a4,a5,80002e7c <usertrap+0x160>
  if (killed(p))
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	8ea080e7          	jalr	-1814(ra) # 80002666 <killed>
    80002d84:	18051f63          	bnez	a0,80002f22 <usertrap+0x206>
if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	dce080e7          	jalr	-562(ra) # 80001b56 <myproc>
    80002d90:	c571                	beqz	a0,80002e5c <usertrap+0x140>
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	dc4080e7          	jalr	-572(ra) # 80001b56 <myproc>
    80002d9a:	4d18                	lw	a4,24(a0)
    80002d9c:	4791                	li	a5,4
    80002d9e:	0af71f63          	bne	a4,a5,80002e5c <usertrap+0x140>
      int q_maxticks[4]={1,3,9,15};
    80002da2:	4785                	li	a5,1
    80002da4:	fcf42823          	sw	a5,-48(s0)
    80002da8:	478d                	li	a5,3
    80002daa:	fcf42a23          	sw	a5,-44(s0)
    80002dae:	47a5                	li	a5,9
    80002db0:	fcf42c23          	sw	a5,-40(s0)
    80002db4:	47bd                	li	a5,15
    80002db6:	fcf42e23          	sw	a5,-36(s0)
      if(myproc()->currticks>=q_maxticks[myproc()->que])
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	d9c080e7          	jalr	-612(ra) # 80001b56 <myproc>
    80002dc2:	1c053483          	ld	s1,448(a0)
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	d90080e7          	jalr	-624(ra) # 80001b56 <myproc>
    80002dce:	1b053783          	ld	a5,432(a0)
    80002dd2:	078a                	slli	a5,a5,0x2
    80002dd4:	1781                	addi	a5,a5,-32
    80002dd6:	97a2                	add	a5,a5,s0
    80002dd8:	ff07a783          	lw	a5,-16(a5)
    80002ddc:	12f4f763          	bgeu	s1,a5,80002f0a <usertrap+0x1ee>
        myproc()->currticks++;
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	d76080e7          	jalr	-650(ra) # 80001b56 <myproc>
    80002de8:	1c053783          	ld	a5,448(a0)
    80002dec:	0785                	addi	a5,a5,1
    80002dee:	1cf53023          	sd	a5,448(a0)
        myproc()->qticks[myproc()->que]++;
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	d64080e7          	jalr	-668(ra) # 80001b56 <myproc>
    80002dfa:	84aa                	mv	s1,a0
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	d5a080e7          	jalr	-678(ra) # 80001b56 <myproc>
    80002e04:	1b053783          	ld	a5,432(a0)
    80002e08:	078e                	slli	a5,a5,0x3
    80002e0a:	97a6                	add	a5,a5,s1
    80002e0c:	1907b703          	ld	a4,400(a5)
    80002e10:	0705                	addi	a4,a4,1
    80002e12:	18e7b823          	sd	a4,400(a5)
    80002e16:	a099                	j	80002e5c <usertrap+0x140>
    panic("usertrap: not from user mode");
    80002e18:	00005517          	auipc	a0,0x5
    80002e1c:	54850513          	addi	a0,a0,1352 # 80008360 <states.0+0x58>
    80002e20:	ffffd097          	auipc	ra,0xffffd
    80002e24:	720080e7          	jalr	1824(ra) # 80000540 <panic>
    if (killed(p))
    80002e28:	00000097          	auipc	ra,0x0
    80002e2c:	83e080e7          	jalr	-1986(ra) # 80002666 <killed>
    80002e30:	e121                	bnez	a0,80002e70 <usertrap+0x154>
    p->trapframe->epc += 4;
    80002e32:	6cb8                	ld	a4,88(s1)
    80002e34:	6f1c                	ld	a5,24(a4)
    80002e36:	0791                	addi	a5,a5,4
    80002e38:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e42:	10079073          	csrw	sstatus,a5
    syscall();
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	3d8080e7          	jalr	984(ra) # 8000321e <syscall>
  int which_dev = 0;
    80002e4e:	4901                	li	s2,0
  if (killed(p))
    80002e50:	8526                	mv	a0,s1
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	814080e7          	jalr	-2028(ra) # 80002666 <killed>
    80002e5a:	ed59                	bnez	a0,80002ef8 <usertrap+0x1dc>
  usertrapret();
    80002e5c:	00000097          	auipc	ra,0x0
    80002e60:	d34080e7          	jalr	-716(ra) # 80002b90 <usertrapret>
}
    80002e64:	70a2                	ld	ra,40(sp)
    80002e66:	7402                	ld	s0,32(sp)
    80002e68:	64e2                	ld	s1,24(sp)
    80002e6a:	6942                	ld	s2,16(sp)
    80002e6c:	6145                	addi	sp,sp,48
    80002e6e:	8082                	ret
      exit(-1);
    80002e70:	557d                	li	a0,-1
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	654080e7          	jalr	1620(ra) # 800024c6 <exit>
    80002e7a:	bf65                	j	80002e32 <usertrap+0x116>
    p->cur_ticks++;
    80002e7c:	1f84a783          	lw	a5,504(s1)
    80002e80:	2785                	addiw	a5,a5,1
    80002e82:	1ef4ac23          	sw	a5,504(s1)
    struct trapframe *tf=kalloc();
    80002e86:	ffffe097          	auipc	ra,0xffffe
    80002e8a:	c60080e7          	jalr	-928(ra) # 80000ae6 <kalloc>
    80002e8e:	892a                	mv	s2,a0
    memmove(tf,p->trapframe,sizeof(struct trapframe));
    80002e90:	12000613          	li	a2,288
    80002e94:	6cac                	ld	a1,88(s1)
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	e98080e7          	jalr	-360(ra) # 80000d2e <memmove>
    p->tfp=tf;
    80002e9e:	1f24b423          	sd	s2,488(s1)
    if(p->cur_ticks>=p->ticks)
    80002ea2:	1f84a703          	lw	a4,504(s1)
    80002ea6:	1e04a783          	lw	a5,480(s1)
    80002eaa:	ecf748e3          	blt	a4,a5,80002d7a <usertrap+0x5e>
      p->set=1;
    80002eae:	4785                	li	a5,1
    80002eb0:	1ef4a823          	sw	a5,496(s1)
      p->trapframe->epc=p->handler;
    80002eb4:	6cbc                	ld	a5,88(s1)
    80002eb6:	1d84b703          	ld	a4,472(s1)
    80002eba:	ef98                	sd	a4,24(a5)
    80002ebc:	bd7d                	j	80002d7a <usertrap+0x5e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ebe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ec2:	5890                	lw	a2,48(s1)
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	4bc50513          	addi	a0,a0,1212 # 80008380 <states.0+0x78>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	6be080e7          	jalr	1726(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ed4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	4d450513          	addi	a0,a0,1236 # 800083b0 <states.0+0xa8>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	6a6080e7          	jalr	1702(ra) # 8000058a <printf>
    setkilled(p);
    80002eec:	8526                	mv	a0,s1
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	74c080e7          	jalr	1868(ra) # 8000263a <setkilled>
    80002ef6:	bfa9                	j	80002e50 <usertrap+0x134>
    exit(-1);
    80002ef8:	557d                	li	a0,-1
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	5cc080e7          	jalr	1484(ra) # 800024c6 <exit>
if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f02:	4789                	li	a5,2
    80002f04:	f4f91ce3          	bne	s2,a5,80002e5c <usertrap+0x140>
    80002f08:	b541                	j	80002d88 <usertrap+0x6c>
          myproc()->changequeue=1;
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	c4c080e7          	jalr	-948(ra) # 80001b56 <myproc>
    80002f12:	4785                	li	a5,1
    80002f14:	1cf53423          	sd	a5,456(a0)
          yield();      
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	436080e7          	jalr	1078(ra) # 8000234e <yield>
    80002f20:	b5c1                	j	80002de0 <usertrap+0xc4>
    exit(-1);
    80002f22:	557d                	li	a0,-1
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	5a2080e7          	jalr	1442(ra) # 800024c6 <exit>
if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f2c:	bdb1                	j	80002d88 <usertrap+0x6c>

0000000080002f2e <kerneltrap>:
{
    80002f2e:	7139                	addi	sp,sp,-64
    80002f30:	fc06                	sd	ra,56(sp)
    80002f32:	f822                	sd	s0,48(sp)
    80002f34:	f426                	sd	s1,40(sp)
    80002f36:	f04a                	sd	s2,32(sp)
    80002f38:	ec4e                	sd	s3,24(sp)
    80002f3a:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f3c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f40:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f44:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002f48:	1004f793          	andi	a5,s1,256
    80002f4c:	cb85                	beqz	a5,80002f7c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f52:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002f54:	ef85                	bnez	a5,80002f8c <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	d24080e7          	jalr	-732(ra) # 80002c7a <devintr>
    80002f5e:	cd1d                	beqz	a0,80002f9c <kerneltrap+0x6e>
if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f60:	4789                	li	a5,2
    80002f62:	06f50a63          	beq	a0,a5,80002fd6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f66:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f6a:	10049073          	csrw	sstatus,s1
}
    80002f6e:	70e2                	ld	ra,56(sp)
    80002f70:	7442                	ld	s0,48(sp)
    80002f72:	74a2                	ld	s1,40(sp)
    80002f74:	7902                	ld	s2,32(sp)
    80002f76:	69e2                	ld	s3,24(sp)
    80002f78:	6121                	addi	sp,sp,64
    80002f7a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	45450513          	addi	a0,a0,1108 # 800083d0 <states.0+0xc8>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	5bc080e7          	jalr	1468(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002f8c:	00005517          	auipc	a0,0x5
    80002f90:	46c50513          	addi	a0,a0,1132 # 800083f8 <states.0+0xf0>
    80002f94:	ffffd097          	auipc	ra,0xffffd
    80002f98:	5ac080e7          	jalr	1452(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002f9c:	85ce                	mv	a1,s3
    80002f9e:	00005517          	auipc	a0,0x5
    80002fa2:	47a50513          	addi	a0,a0,1146 # 80008418 <states.0+0x110>
    80002fa6:	ffffd097          	auipc	ra,0xffffd
    80002faa:	5e4080e7          	jalr	1508(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fb2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fb6:	00005517          	auipc	a0,0x5
    80002fba:	47250513          	addi	a0,a0,1138 # 80008428 <states.0+0x120>
    80002fbe:	ffffd097          	auipc	ra,0xffffd
    80002fc2:	5cc080e7          	jalr	1484(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	47a50513          	addi	a0,a0,1146 # 80008440 <states.0+0x138>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	572080e7          	jalr	1394(ra) # 80000540 <panic>
if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	b80080e7          	jalr	-1152(ra) # 80001b56 <myproc>
    80002fde:	d541                	beqz	a0,80002f66 <kerneltrap+0x38>
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	b76080e7          	jalr	-1162(ra) # 80001b56 <myproc>
    80002fe8:	4d18                	lw	a4,24(a0)
    80002fea:	4791                	li	a5,4
    80002fec:	f6f71de3          	bne	a4,a5,80002f66 <kerneltrap+0x38>
      int q_maxticks[4]={1,3,9,15};
    80002ff0:	4785                	li	a5,1
    80002ff2:	fcf42023          	sw	a5,-64(s0)
    80002ff6:	478d                	li	a5,3
    80002ff8:	fcf42223          	sw	a5,-60(s0)
    80002ffc:	47a5                	li	a5,9
    80002ffe:	fcf42423          	sw	a5,-56(s0)
    80003002:	47bd                	li	a5,15
    80003004:	fcf42623          	sw	a5,-52(s0)
      if(myproc()->currticks>=q_maxticks[myproc()->que])
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	b4e080e7          	jalr	-1202(ra) # 80001b56 <myproc>
    80003010:	1c053983          	ld	s3,448(a0)
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	b42080e7          	jalr	-1214(ra) # 80001b56 <myproc>
    8000301c:	1b053783          	ld	a5,432(a0)
    80003020:	078a                	slli	a5,a5,0x2
    80003022:	fd078793          	addi	a5,a5,-48
    80003026:	97a2                	add	a5,a5,s0
    80003028:	ff07a783          	lw	a5,-16(a5)
    8000302c:	02f9fe63          	bgeu	s3,a5,80003068 <kerneltrap+0x13a>
        myproc()->currticks++;
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	b26080e7          	jalr	-1242(ra) # 80001b56 <myproc>
    80003038:	1c053783          	ld	a5,448(a0)
    8000303c:	0785                	addi	a5,a5,1
    8000303e:	1cf53023          	sd	a5,448(a0)
        myproc()->qticks[myproc()->que]++;
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	b14080e7          	jalr	-1260(ra) # 80001b56 <myproc>
    8000304a:	89aa                	mv	s3,a0
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	b0a080e7          	jalr	-1270(ra) # 80001b56 <myproc>
    80003054:	1b053783          	ld	a5,432(a0)
    80003058:	078e                	slli	a5,a5,0x3
    8000305a:	97ce                	add	a5,a5,s3
    8000305c:	1907b703          	ld	a4,400(a5)
    80003060:	0705                	addi	a4,a4,1
    80003062:	18e7b823          	sd	a4,400(a5)
    80003066:	b701                	j	80002f66 <kerneltrap+0x38>
          myproc()->changequeue=1;
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	aee080e7          	jalr	-1298(ra) # 80001b56 <myproc>
    80003070:	4785                	li	a5,1
    80003072:	1cf53423          	sd	a5,456(a0)
          if(myproc()->pid>2 && myproc()->pid<13)
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	ae0080e7          	jalr	-1312(ra) # 80001b56 <myproc>
    8000307e:	5918                	lw	a4,48(a0)
    80003080:	4789                	li	a5,2
    80003082:	fae7d7e3          	bge	a5,a4,80003030 <kerneltrap+0x102>
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	ad0080e7          	jalr	-1328(ra) # 80001b56 <myproc>
    8000308e:	5918                	lw	a4,48(a0)
    80003090:	47b1                	li	a5,12
    80003092:	f8e7cfe3          	blt	a5,a4,80003030 <kerneltrap+0x102>
          yield();
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	2b8080e7          	jalr	696(ra) # 8000234e <yield>
    8000309e:	bf49                	j	80003030 <kerneltrap+0x102>

00000000800030a0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	aaa080e7          	jalr	-1366(ra) # 80001b56 <myproc>
  switch (n) {
    800030b4:	4795                	li	a5,5
    800030b6:	0497e163          	bltu	a5,s1,800030f8 <argraw+0x58>
    800030ba:	048a                	slli	s1,s1,0x2
    800030bc:	00005717          	auipc	a4,0x5
    800030c0:	3bc70713          	addi	a4,a4,956 # 80008478 <states.0+0x170>
    800030c4:	94ba                	add	s1,s1,a4
    800030c6:	409c                	lw	a5,0(s1)
    800030c8:	97ba                	add	a5,a5,a4
    800030ca:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030cc:	6d3c                	ld	a5,88(a0)
    800030ce:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret
    return p->trapframe->a1;
    800030da:	6d3c                	ld	a5,88(a0)
    800030dc:	7fa8                	ld	a0,120(a5)
    800030de:	bfcd                	j	800030d0 <argraw+0x30>
    return p->trapframe->a2;
    800030e0:	6d3c                	ld	a5,88(a0)
    800030e2:	63c8                	ld	a0,128(a5)
    800030e4:	b7f5                	j	800030d0 <argraw+0x30>
    return p->trapframe->a3;
    800030e6:	6d3c                	ld	a5,88(a0)
    800030e8:	67c8                	ld	a0,136(a5)
    800030ea:	b7dd                	j	800030d0 <argraw+0x30>
    return p->trapframe->a4;
    800030ec:	6d3c                	ld	a5,88(a0)
    800030ee:	6bc8                	ld	a0,144(a5)
    800030f0:	b7c5                	j	800030d0 <argraw+0x30>
    return p->trapframe->a5;
    800030f2:	6d3c                	ld	a5,88(a0)
    800030f4:	6fc8                	ld	a0,152(a5)
    800030f6:	bfe9                	j	800030d0 <argraw+0x30>
  panic("argraw");
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	35850513          	addi	a0,a0,856 # 80008450 <states.0+0x148>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	440080e7          	jalr	1088(ra) # 80000540 <panic>

0000000080003108 <fetchaddr>:
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	e04a                	sd	s2,0(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
    80003116:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	a3e080e7          	jalr	-1474(ra) # 80001b56 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003120:	653c                	ld	a5,72(a0)
    80003122:	02f4f863          	bgeu	s1,a5,80003152 <fetchaddr+0x4a>
    80003126:	00848713          	addi	a4,s1,8
    8000312a:	02e7e663          	bltu	a5,a4,80003156 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000312e:	46a1                	li	a3,8
    80003130:	8626                	mv	a2,s1
    80003132:	85ca                	mv	a1,s2
    80003134:	6928                	ld	a0,80(a0)
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	5c2080e7          	jalr	1474(ra) # 800016f8 <copyin>
    8000313e:	00a03533          	snez	a0,a0
    80003142:	40a00533          	neg	a0,a0
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	64a2                	ld	s1,8(sp)
    8000314c:	6902                	ld	s2,0(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret
    return -1;
    80003152:	557d                	li	a0,-1
    80003154:	bfcd                	j	80003146 <fetchaddr+0x3e>
    80003156:	557d                	li	a0,-1
    80003158:	b7fd                	j	80003146 <fetchaddr+0x3e>

000000008000315a <fetchstr>:
{
    8000315a:	7179                	addi	sp,sp,-48
    8000315c:	f406                	sd	ra,40(sp)
    8000315e:	f022                	sd	s0,32(sp)
    80003160:	ec26                	sd	s1,24(sp)
    80003162:	e84a                	sd	s2,16(sp)
    80003164:	e44e                	sd	s3,8(sp)
    80003166:	1800                	addi	s0,sp,48
    80003168:	892a                	mv	s2,a0
    8000316a:	84ae                	mv	s1,a1
    8000316c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	9e8080e7          	jalr	-1560(ra) # 80001b56 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003176:	86ce                	mv	a3,s3
    80003178:	864a                	mv	a2,s2
    8000317a:	85a6                	mv	a1,s1
    8000317c:	6928                	ld	a0,80(a0)
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	608080e7          	jalr	1544(ra) # 80001786 <copyinstr>
    80003186:	00054e63          	bltz	a0,800031a2 <fetchstr+0x48>
  return strlen(buf);
    8000318a:	8526                	mv	a0,s1
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	cc2080e7          	jalr	-830(ra) # 80000e4e <strlen>
}
    80003194:	70a2                	ld	ra,40(sp)
    80003196:	7402                	ld	s0,32(sp)
    80003198:	64e2                	ld	s1,24(sp)
    8000319a:	6942                	ld	s2,16(sp)
    8000319c:	69a2                	ld	s3,8(sp)
    8000319e:	6145                	addi	sp,sp,48
    800031a0:	8082                	ret
    return -1;
    800031a2:	557d                	li	a0,-1
    800031a4:	bfc5                	j	80003194 <fetchstr+0x3a>

00000000800031a6 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800031a6:	1101                	addi	sp,sp,-32
    800031a8:	ec06                	sd	ra,24(sp)
    800031aa:	e822                	sd	s0,16(sp)
    800031ac:	e426                	sd	s1,8(sp)
    800031ae:	1000                	addi	s0,sp,32
    800031b0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	eee080e7          	jalr	-274(ra) # 800030a0 <argraw>
    800031ba:	c088                	sw	a0,0(s1)
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	1000                	addi	s0,sp,32
    800031d0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	ece080e7          	jalr	-306(ra) # 800030a0 <argraw>
    800031da:	e088                	sd	a0,0(s1)
}
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031e6:	7179                	addi	sp,sp,-48
    800031e8:	f406                	sd	ra,40(sp)
    800031ea:	f022                	sd	s0,32(sp)
    800031ec:	ec26                	sd	s1,24(sp)
    800031ee:	e84a                	sd	s2,16(sp)
    800031f0:	1800                	addi	s0,sp,48
    800031f2:	84ae                	mv	s1,a1
    800031f4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031f6:	fd840593          	addi	a1,s0,-40
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	fcc080e7          	jalr	-52(ra) # 800031c6 <argaddr>
  return fetchstr(addr, buf, max);
    80003202:	864a                	mv	a2,s2
    80003204:	85a6                	mv	a1,s1
    80003206:	fd843503          	ld	a0,-40(s0)
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	f50080e7          	jalr	-176(ra) # 8000315a <fetchstr>
}
    80003212:	70a2                	ld	ra,40(sp)
    80003214:	7402                	ld	s0,32(sp)
    80003216:	64e2                	ld	s1,24(sp)
    80003218:	6942                	ld	s2,16(sp)
    8000321a:	6145                	addi	sp,sp,48
    8000321c:	8082                	ret

000000008000321e <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    8000321e:	1101                	addi	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	e426                	sd	s1,8(sp)
    80003226:	e04a                	sd	s2,0(sp)
    80003228:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	92c080e7          	jalr	-1748(ra) # 80001b56 <myproc>
    80003232:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003234:	05853903          	ld	s2,88(a0)
    80003238:	0a893783          	ld	a5,168(s2)
    8000323c:	0007869b          	sext.w	a3,a5
  if(num==SYS_read){
    80003240:	4715                	li	a4,5
    80003242:	02e68763          	beq	a3,a4,80003270 <syscall+0x52>
    g_read++;
  }
  if(num==SYS_getreadcount){
    80003246:	475d                	li	a4,23
    80003248:	04e69763          	bne	a3,a4,80003296 <syscall+0x78>
    p->rc=g_read;
    8000324c:	00005717          	auipc	a4,0x5
    80003250:	71872703          	lw	a4,1816(a4) # 80008964 <g_read>
    80003254:	1ee52223          	sw	a4,484(a0)
  }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003258:	37fd                	addiw	a5,a5,-1
    8000325a:	4665                	li	a2,25
    8000325c:	00000717          	auipc	a4,0x0
    80003260:	38270713          	addi	a4,a4,898 # 800035de <sys_getreadcount>
    80003264:	04f66663          	bltu	a2,a5,800032b0 <syscall+0x92>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003268:	9702                	jalr	a4
    8000326a:	06a93823          	sd	a0,112(s2)
    8000326e:	a8b9                	j	800032cc <syscall+0xae>
    g_read++;
    80003270:	00005617          	auipc	a2,0x5
    80003274:	6f460613          	addi	a2,a2,1780 # 80008964 <g_read>
    80003278:	4218                	lw	a4,0(a2)
    8000327a:	2705                	addiw	a4,a4,1
    8000327c:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000327e:	37fd                	addiw	a5,a5,-1
    80003280:	4765                	li	a4,25
    80003282:	02f76763          	bltu	a4,a5,800032b0 <syscall+0x92>
    80003286:	068e                	slli	a3,a3,0x3
    80003288:	00005797          	auipc	a5,0x5
    8000328c:	20878793          	addi	a5,a5,520 # 80008490 <syscalls>
    80003290:	97b6                	add	a5,a5,a3
    80003292:	6398                	ld	a4,0(a5)
    80003294:	bfd1                	j	80003268 <syscall+0x4a>
    80003296:	37fd                	addiw	a5,a5,-1
    80003298:	4765                	li	a4,25
    8000329a:	00f76b63          	bltu	a4,a5,800032b0 <syscall+0x92>
    8000329e:	00369713          	slli	a4,a3,0x3
    800032a2:	00005797          	auipc	a5,0x5
    800032a6:	1ee78793          	addi	a5,a5,494 # 80008490 <syscalls>
    800032aa:	97ba                	add	a5,a5,a4
    800032ac:	6398                	ld	a4,0(a5)
    800032ae:	ff4d                	bnez	a4,80003268 <syscall+0x4a>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032b0:	15848613          	addi	a2,s1,344
    800032b4:	588c                	lw	a1,48(s1)
    800032b6:	00005517          	auipc	a0,0x5
    800032ba:	1a250513          	addi	a0,a0,418 # 80008458 <states.0+0x150>
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	2cc080e7          	jalr	716(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032c6:	6cbc                	ld	a5,88(s1)
    800032c8:	577d                	li	a4,-1
    800032ca:	fbb8                	sd	a4,112(a5)
  }
}
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	64a2                	ld	s1,8(sp)
    800032d2:	6902                	ld	s2,0(sp)
    800032d4:	6105                	addi	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800032e0:	fec40593          	addi	a1,s0,-20
    800032e4:	4501                	li	a0,0
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	ec0080e7          	jalr	-320(ra) # 800031a6 <argint>
  exit(n);
    800032ee:	fec42503          	lw	a0,-20(s0)
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	1d4080e7          	jalr	468(ra) # 800024c6 <exit>
  return 0; // not reached
}
    800032fa:	4501                	li	a0,0
    800032fc:	60e2                	ld	ra,24(sp)
    800032fe:	6442                	ld	s0,16(sp)
    80003300:	6105                	addi	sp,sp,32
    80003302:	8082                	ret

0000000080003304 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003304:	1141                	addi	sp,sp,-16
    80003306:	e406                	sd	ra,8(sp)
    80003308:	e022                	sd	s0,0(sp)
    8000330a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000330c:	fffff097          	auipc	ra,0xfffff
    80003310:	84a080e7          	jalr	-1974(ra) # 80001b56 <myproc>
}
    80003314:	5908                	lw	a0,48(a0)
    80003316:	60a2                	ld	ra,8(sp)
    80003318:	6402                	ld	s0,0(sp)
    8000331a:	0141                	addi	sp,sp,16
    8000331c:	8082                	ret

000000008000331e <sys_fork>:

uint64
sys_fork(void)
{
    8000331e:	1141                	addi	sp,sp,-16
    80003320:	e406                	sd	ra,8(sp)
    80003322:	e022                	sd	s0,0(sp)
    80003324:	0800                	addi	s0,sp,16
  return fork();
    80003326:	fffff097          	auipc	ra,0xfffff
    8000332a:	c22080e7          	jalr	-990(ra) # 80001f48 <fork>
}
    8000332e:	60a2                	ld	ra,8(sp)
    80003330:	6402                	ld	s0,0(sp)
    80003332:	0141                	addi	sp,sp,16
    80003334:	8082                	ret

0000000080003336 <sys_wait>:

uint64
sys_wait(void)
{
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000333e:	fe840593          	addi	a1,s0,-24
    80003342:	4501                	li	a0,0
    80003344:	00000097          	auipc	ra,0x0
    80003348:	e82080e7          	jalr	-382(ra) # 800031c6 <argaddr>
  return wait(p);
    8000334c:	fe843503          	ld	a0,-24(s0)
    80003350:	fffff097          	auipc	ra,0xfffff
    80003354:	348080e7          	jalr	840(ra) # 80002698 <wait>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret

0000000080003360 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003360:	7179                	addi	sp,sp,-48
    80003362:	f406                	sd	ra,40(sp)
    80003364:	f022                	sd	s0,32(sp)
    80003366:	ec26                	sd	s1,24(sp)
    80003368:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000336a:	fdc40593          	addi	a1,s0,-36
    8000336e:	4501                	li	a0,0
    80003370:	00000097          	auipc	ra,0x0
    80003374:	e36080e7          	jalr	-458(ra) # 800031a6 <argint>
  addr = myproc()->sz;
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	7de080e7          	jalr	2014(ra) # 80001b56 <myproc>
    80003380:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003382:	fdc42503          	lw	a0,-36(s0)
    80003386:	fffff097          	auipc	ra,0xfffff
    8000338a:	b66080e7          	jalr	-1178(ra) # 80001eec <growproc>
    8000338e:	00054863          	bltz	a0,8000339e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003392:	8526                	mv	a0,s1
    80003394:	70a2                	ld	ra,40(sp)
    80003396:	7402                	ld	s0,32(sp)
    80003398:	64e2                	ld	s1,24(sp)
    8000339a:	6145                	addi	sp,sp,48
    8000339c:	8082                	ret
    return -1;
    8000339e:	54fd                	li	s1,-1
    800033a0:	bfcd                	j	80003392 <sys_sbrk+0x32>

00000000800033a2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033a2:	7139                	addi	sp,sp,-64
    800033a4:	fc06                	sd	ra,56(sp)
    800033a6:	f822                	sd	s0,48(sp)
    800033a8:	f426                	sd	s1,40(sp)
    800033aa:	f04a                	sd	s2,32(sp)
    800033ac:	ec4e                	sd	s3,24(sp)
    800033ae:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800033b0:	fcc40593          	addi	a1,s0,-52
    800033b4:	4501                	li	a0,0
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	df0080e7          	jalr	-528(ra) # 800031a6 <argint>
  acquire(&tickslock);
    800033be:	00016517          	auipc	a0,0x16
    800033c2:	44250513          	addi	a0,a0,1090 # 80019800 <tickslock>
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	810080e7          	jalr	-2032(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800033ce:	00005917          	auipc	s2,0x5
    800033d2:	59292903          	lw	s2,1426(s2) # 80008960 <ticks>
  while (ticks - ticks0 < n)
    800033d6:	fcc42783          	lw	a5,-52(s0)
    800033da:	cf9d                	beqz	a5,80003418 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033dc:	00016997          	auipc	s3,0x16
    800033e0:	42498993          	addi	s3,s3,1060 # 80019800 <tickslock>
    800033e4:	00005497          	auipc	s1,0x5
    800033e8:	57c48493          	addi	s1,s1,1404 # 80008960 <ticks>
    if (killed(myproc()))
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	76a080e7          	jalr	1898(ra) # 80001b56 <myproc>
    800033f4:	fffff097          	auipc	ra,0xfffff
    800033f8:	272080e7          	jalr	626(ra) # 80002666 <killed>
    800033fc:	ed15                	bnez	a0,80003438 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800033fe:	85ce                	mv	a1,s3
    80003400:	8526                	mv	a0,s1
    80003402:	fffff097          	auipc	ra,0xfffff
    80003406:	f88080e7          	jalr	-120(ra) # 8000238a <sleep>
  while (ticks - ticks0 < n)
    8000340a:	409c                	lw	a5,0(s1)
    8000340c:	412787bb          	subw	a5,a5,s2
    80003410:	fcc42703          	lw	a4,-52(s0)
    80003414:	fce7ece3          	bltu	a5,a4,800033ec <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003418:	00016517          	auipc	a0,0x16
    8000341c:	3e850513          	addi	a0,a0,1000 # 80019800 <tickslock>
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	86a080e7          	jalr	-1942(ra) # 80000c8a <release>
  return 0;
    80003428:	4501                	li	a0,0
}
    8000342a:	70e2                	ld	ra,56(sp)
    8000342c:	7442                	ld	s0,48(sp)
    8000342e:	74a2                	ld	s1,40(sp)
    80003430:	7902                	ld	s2,32(sp)
    80003432:	69e2                	ld	s3,24(sp)
    80003434:	6121                	addi	sp,sp,64
    80003436:	8082                	ret
      release(&tickslock);
    80003438:	00016517          	auipc	a0,0x16
    8000343c:	3c850513          	addi	a0,a0,968 # 80019800 <tickslock>
    80003440:	ffffe097          	auipc	ra,0xffffe
    80003444:	84a080e7          	jalr	-1974(ra) # 80000c8a <release>
      return -1;
    80003448:	557d                	li	a0,-1
    8000344a:	b7c5                	j	8000342a <sys_sleep+0x88>

000000008000344c <sys_kill>:

uint64
sys_kill(void)
{
    8000344c:	1101                	addi	sp,sp,-32
    8000344e:	ec06                	sd	ra,24(sp)
    80003450:	e822                	sd	s0,16(sp)
    80003452:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003454:	fec40593          	addi	a1,s0,-20
    80003458:	4501                	li	a0,0
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	d4c080e7          	jalr	-692(ra) # 800031a6 <argint>
  return kill(pid);
    80003462:	fec42503          	lw	a0,-20(s0)
    80003466:	fffff097          	auipc	ra,0xfffff
    8000346a:	150080e7          	jalr	336(ra) # 800025b6 <kill>
}
    8000346e:	60e2                	ld	ra,24(sp)
    80003470:	6442                	ld	s0,16(sp)
    80003472:	6105                	addi	sp,sp,32
    80003474:	8082                	ret

0000000080003476 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003476:	1101                	addi	sp,sp,-32
    80003478:	ec06                	sd	ra,24(sp)
    8000347a:	e822                	sd	s0,16(sp)
    8000347c:	e426                	sd	s1,8(sp)
    8000347e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003480:	00016517          	auipc	a0,0x16
    80003484:	38050513          	addi	a0,a0,896 # 80019800 <tickslock>
    80003488:	ffffd097          	auipc	ra,0xffffd
    8000348c:	74e080e7          	jalr	1870(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003490:	00005497          	auipc	s1,0x5
    80003494:	4d04a483          	lw	s1,1232(s1) # 80008960 <ticks>
  release(&tickslock);
    80003498:	00016517          	auipc	a0,0x16
    8000349c:	36850513          	addi	a0,a0,872 # 80019800 <tickslock>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	7ea080e7          	jalr	2026(ra) # 80000c8a <release>
  return xticks;
}
    800034a8:	02049513          	slli	a0,s1,0x20
    800034ac:	9101                	srli	a0,a0,0x20
    800034ae:	60e2                	ld	ra,24(sp)
    800034b0:	6442                	ld	s0,16(sp)
    800034b2:	64a2                	ld	s1,8(sp)
    800034b4:	6105                	addi	sp,sp,32
    800034b6:	8082                	ret

00000000800034b8 <sys_waitx>:

uint64
sys_waitx(void)
{
    800034b8:	7139                	addi	sp,sp,-64
    800034ba:	fc06                	sd	ra,56(sp)
    800034bc:	f822                	sd	s0,48(sp)
    800034be:	f426                	sd	s1,40(sp)
    800034c0:	f04a                	sd	s2,32(sp)
    800034c2:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800034c4:	fd840593          	addi	a1,s0,-40
    800034c8:	4501                	li	a0,0
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	cfc080e7          	jalr	-772(ra) # 800031c6 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800034d2:	fd040593          	addi	a1,s0,-48
    800034d6:	4505                	li	a0,1
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	cee080e7          	jalr	-786(ra) # 800031c6 <argaddr>
  argaddr(2, &addr2);
    800034e0:	fc840593          	addi	a1,s0,-56
    800034e4:	4509                	li	a0,2
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	ce0080e7          	jalr	-800(ra) # 800031c6 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800034ee:	fc040613          	addi	a2,s0,-64
    800034f2:	fc440593          	addi	a1,s0,-60
    800034f6:	fd843503          	ld	a0,-40(s0)
    800034fa:	fffff097          	auipc	ra,0xfffff
    800034fe:	428080e7          	jalr	1064(ra) # 80002922 <waitx>
    80003502:	892a                	mv	s2,a0
  //getps();
  struct proc *p = myproc();
    80003504:	ffffe097          	auipc	ra,0xffffe
    80003508:	652080e7          	jalr	1618(ra) # 80001b56 <myproc>
    8000350c:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000350e:	4691                	li	a3,4
    80003510:	fc440613          	addi	a2,s0,-60
    80003514:	fd043583          	ld	a1,-48(s0)
    80003518:	6928                	ld	a0,80(a0)
    8000351a:	ffffe097          	auipc	ra,0xffffe
    8000351e:	152080e7          	jalr	338(ra) # 8000166c <copyout>
    return -1;
    80003522:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003524:	00054f63          	bltz	a0,80003542 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003528:	4691                	li	a3,4
    8000352a:	fc040613          	addi	a2,s0,-64
    8000352e:	fc843583          	ld	a1,-56(s0)
    80003532:	68a8                	ld	a0,80(s1)
    80003534:	ffffe097          	auipc	ra,0xffffe
    80003538:	138080e7          	jalr	312(ra) # 8000166c <copyout>
    8000353c:	00054a63          	bltz	a0,80003550 <sys_waitx+0x98>
    return -1;
  return ret;
    80003540:	87ca                	mv	a5,s2
}
    80003542:	853e                	mv	a0,a5
    80003544:	70e2                	ld	ra,56(sp)
    80003546:	7442                	ld	s0,48(sp)
    80003548:	74a2                	ld	s1,40(sp)
    8000354a:	7902                	ld	s2,32(sp)
    8000354c:	6121                	addi	sp,sp,64
    8000354e:	8082                	ret
    return -1;
    80003550:	57fd                	li	a5,-1
    80003552:	bfc5                	j	80003542 <sys_waitx+0x8a>

0000000080003554 <sys_getps>:
uint64
sys_getps(void)
{
    80003554:	1141                	addi	sp,sp,-16
    80003556:	e406                	sd	ra,8(sp)
    80003558:	e022                	sd	s0,0(sp)
    8000355a:	0800                	addi	s0,sp,16
    return getps();
    8000355c:	fffff097          	auipc	ra,0xfffff
    80003560:	516080e7          	jalr	1302(ra) # 80002a72 <getps>
}
    80003564:	60a2                	ld	ra,8(sp)
    80003566:	6402                	ld	s0,0(sp)
    80003568:	0141                	addi	sp,sp,16
    8000356a:	8082                	ret

000000008000356c <sys_sigalarm>:
uint64 
sys_sigalarm(void)
{
    8000356c:	1101                	addi	sp,sp,-32
    8000356e:	ec06                	sd	ra,24(sp)
    80003570:	e822                	sd	s0,16(sp)
    80003572:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handleradd;
  argint(0,&ticks);
    80003574:	fec40593          	addi	a1,s0,-20
    80003578:	4501                	li	a0,0
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	c2c080e7          	jalr	-980(ra) # 800031a6 <argint>
  argaddr(1,&handleradd);
    80003582:	fe040593          	addi	a1,s0,-32
    80003586:	4505                	li	a0,1
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	c3e080e7          	jalr	-962(ra) # 800031c6 <argaddr>
   if (ticks <= 0)
    80003590:	fec42783          	lw	a5,-20(s0)
    80003594:	02f05e63          	blez	a5,800035d0 <sys_sigalarm+0x64>
  {
    myproc()->called = 0;
    return 0;
  }
  myproc()->ticks=ticks;
    80003598:	ffffe097          	auipc	ra,0xffffe
    8000359c:	5be080e7          	jalr	1470(ra) # 80001b56 <myproc>
    800035a0:	fec42783          	lw	a5,-20(s0)
    800035a4:	1ef52023          	sw	a5,480(a0)
  myproc()->called = 1;
    800035a8:	ffffe097          	auipc	ra,0xffffe
    800035ac:	5ae080e7          	jalr	1454(ra) # 80001b56 <myproc>
    800035b0:	4785                	li	a5,1
    800035b2:	1ef52a23          	sw	a5,500(a0)
  myproc()->handler=handleradd;
    800035b6:	ffffe097          	auipc	ra,0xffffe
    800035ba:	5a0080e7          	jalr	1440(ra) # 80001b56 <myproc>
    800035be:	fe043783          	ld	a5,-32(s0)
    800035c2:	1cf53c23          	sd	a5,472(a0)
  return 0;
}
    800035c6:	4501                	li	a0,0
    800035c8:	60e2                	ld	ra,24(sp)
    800035ca:	6442                	ld	s0,16(sp)
    800035cc:	6105                	addi	sp,sp,32
    800035ce:	8082                	ret
    myproc()->called = 0;
    800035d0:	ffffe097          	auipc	ra,0xffffe
    800035d4:	586080e7          	jalr	1414(ra) # 80001b56 <myproc>
    800035d8:	1e052a23          	sw	zero,500(a0)
    return 0;
    800035dc:	b7ed                	j	800035c6 <sys_sigalarm+0x5a>

00000000800035de <sys_getreadcount>:
uint64 
sys_getreadcount(void){
    800035de:	1141                	addi	sp,sp,-16
    800035e0:	e406                	sd	ra,8(sp)
    800035e2:	e022                	sd	s0,0(sp)
    800035e4:	0800                	addi	s0,sp,16
  return myproc()->rc;
    800035e6:	ffffe097          	auipc	ra,0xffffe
    800035ea:	570080e7          	jalr	1392(ra) # 80001b56 <myproc>
}
    800035ee:	1e452503          	lw	a0,484(a0)
    800035f2:	60a2                	ld	ra,8(sp)
    800035f4:	6402                	ld	s0,0(sp)
    800035f6:	0141                	addi	sp,sp,16
    800035f8:	8082                	ret

00000000800035fa <sys_sigreturn>:
uint64
sys_sigreturn(void)
{
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	e426                	sd	s1,8(sp)
    80003602:	1000                	addi	s0,sp,32
  struct proc *p=0;
  p=myproc();
    80003604:	ffffe097          	auipc	ra,0xffffe
    80003608:	552080e7          	jalr	1362(ra) # 80001b56 <myproc>
    8000360c:	84aa                	mv	s1,a0
  memmove(p->trapframe,p->tfp,sizeof(struct trapframe));
    8000360e:	12000613          	li	a2,288
    80003612:	1e853583          	ld	a1,488(a0)
    80003616:	6d28                	ld	a0,88(a0)
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	716080e7          	jalr	1814(ra) # 80000d2e <memmove>
  kfree(p->tfp);
    80003620:	1e84b503          	ld	a0,488(s1)
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	3c4080e7          	jalr	964(ra) # 800009e8 <kfree>
  p->cur_ticks = 0;
    8000362c:	1e04ac23          	sw	zero,504(s1)
  p->tfp=0;
    80003630:	1e04b423          	sd	zero,488(s1)
  p->set = 0;
    80003634:	1e04a823          	sw	zero,496(s1)
  return p->trapframe->a0;
    80003638:	6cbc                	ld	a5,88(s1)
    8000363a:	7ba8                	ld	a0,112(a5)
    8000363c:	60e2                	ld	ra,24(sp)
    8000363e:	6442                	ld	s0,16(sp)
    80003640:	64a2                	ld	s1,8(sp)
    80003642:	6105                	addi	sp,sp,32
    80003644:	8082                	ret

0000000080003646 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003646:	7179                	addi	sp,sp,-48
    80003648:	f406                	sd	ra,40(sp)
    8000364a:	f022                	sd	s0,32(sp)
    8000364c:	ec26                	sd	s1,24(sp)
    8000364e:	e84a                	sd	s2,16(sp)
    80003650:	e44e                	sd	s3,8(sp)
    80003652:	e052                	sd	s4,0(sp)
    80003654:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003656:	00005597          	auipc	a1,0x5
    8000365a:	f1258593          	addi	a1,a1,-238 # 80008568 <syscalls+0xd8>
    8000365e:	00016517          	auipc	a0,0x16
    80003662:	1ba50513          	addi	a0,a0,442 # 80019818 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	4e0080e7          	jalr	1248(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000366e:	0001e797          	auipc	a5,0x1e
    80003672:	1aa78793          	addi	a5,a5,426 # 80021818 <bcache+0x8000>
    80003676:	0001e717          	auipc	a4,0x1e
    8000367a:	40a70713          	addi	a4,a4,1034 # 80021a80 <bcache+0x8268>
    8000367e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003682:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003686:	00016497          	auipc	s1,0x16
    8000368a:	1aa48493          	addi	s1,s1,426 # 80019830 <bcache+0x18>
    b->next = bcache.head.next;
    8000368e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003690:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003692:	00005a17          	auipc	s4,0x5
    80003696:	edea0a13          	addi	s4,s4,-290 # 80008570 <syscalls+0xe0>
    b->next = bcache.head.next;
    8000369a:	2b893783          	ld	a5,696(s2)
    8000369e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036a0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036a4:	85d2                	mv	a1,s4
    800036a6:	01048513          	addi	a0,s1,16
    800036aa:	00001097          	auipc	ra,0x1
    800036ae:	4c8080e7          	jalr	1224(ra) # 80004b72 <initsleeplock>
    bcache.head.next->prev = b;
    800036b2:	2b893783          	ld	a5,696(s2)
    800036b6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036b8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036bc:	45848493          	addi	s1,s1,1112
    800036c0:	fd349de3          	bne	s1,s3,8000369a <binit+0x54>
  }
}
    800036c4:	70a2                	ld	ra,40(sp)
    800036c6:	7402                	ld	s0,32(sp)
    800036c8:	64e2                	ld	s1,24(sp)
    800036ca:	6942                	ld	s2,16(sp)
    800036cc:	69a2                	ld	s3,8(sp)
    800036ce:	6a02                	ld	s4,0(sp)
    800036d0:	6145                	addi	sp,sp,48
    800036d2:	8082                	ret

00000000800036d4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036d4:	7179                	addi	sp,sp,-48
    800036d6:	f406                	sd	ra,40(sp)
    800036d8:	f022                	sd	s0,32(sp)
    800036da:	ec26                	sd	s1,24(sp)
    800036dc:	e84a                	sd	s2,16(sp)
    800036de:	e44e                	sd	s3,8(sp)
    800036e0:	1800                	addi	s0,sp,48
    800036e2:	892a                	mv	s2,a0
    800036e4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036e6:	00016517          	auipc	a0,0x16
    800036ea:	13250513          	addi	a0,a0,306 # 80019818 <bcache>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	4e8080e7          	jalr	1256(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036f6:	0001e497          	auipc	s1,0x1e
    800036fa:	3da4b483          	ld	s1,986(s1) # 80021ad0 <bcache+0x82b8>
    800036fe:	0001e797          	auipc	a5,0x1e
    80003702:	38278793          	addi	a5,a5,898 # 80021a80 <bcache+0x8268>
    80003706:	02f48f63          	beq	s1,a5,80003744 <bread+0x70>
    8000370a:	873e                	mv	a4,a5
    8000370c:	a021                	j	80003714 <bread+0x40>
    8000370e:	68a4                	ld	s1,80(s1)
    80003710:	02e48a63          	beq	s1,a4,80003744 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003714:	449c                	lw	a5,8(s1)
    80003716:	ff279ce3          	bne	a5,s2,8000370e <bread+0x3a>
    8000371a:	44dc                	lw	a5,12(s1)
    8000371c:	ff3799e3          	bne	a5,s3,8000370e <bread+0x3a>
      b->refcnt++;
    80003720:	40bc                	lw	a5,64(s1)
    80003722:	2785                	addiw	a5,a5,1
    80003724:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003726:	00016517          	auipc	a0,0x16
    8000372a:	0f250513          	addi	a0,a0,242 # 80019818 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	55c080e7          	jalr	1372(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003736:	01048513          	addi	a0,s1,16
    8000373a:	00001097          	auipc	ra,0x1
    8000373e:	472080e7          	jalr	1138(ra) # 80004bac <acquiresleep>
      return b;
    80003742:	a8b9                	j	800037a0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003744:	0001e497          	auipc	s1,0x1e
    80003748:	3844b483          	ld	s1,900(s1) # 80021ac8 <bcache+0x82b0>
    8000374c:	0001e797          	auipc	a5,0x1e
    80003750:	33478793          	addi	a5,a5,820 # 80021a80 <bcache+0x8268>
    80003754:	00f48863          	beq	s1,a5,80003764 <bread+0x90>
    80003758:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000375a:	40bc                	lw	a5,64(s1)
    8000375c:	cf81                	beqz	a5,80003774 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000375e:	64a4                	ld	s1,72(s1)
    80003760:	fee49de3          	bne	s1,a4,8000375a <bread+0x86>
  panic("bget: no buffers");
    80003764:	00005517          	auipc	a0,0x5
    80003768:	e1450513          	addi	a0,a0,-492 # 80008578 <syscalls+0xe8>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	dd4080e7          	jalr	-556(ra) # 80000540 <panic>
      b->dev = dev;
    80003774:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003778:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000377c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003780:	4785                	li	a5,1
    80003782:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003784:	00016517          	auipc	a0,0x16
    80003788:	09450513          	addi	a0,a0,148 # 80019818 <bcache>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	4fe080e7          	jalr	1278(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003794:	01048513          	addi	a0,s1,16
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	414080e7          	jalr	1044(ra) # 80004bac <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037a0:	409c                	lw	a5,0(s1)
    800037a2:	cb89                	beqz	a5,800037b4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037a4:	8526                	mv	a0,s1
    800037a6:	70a2                	ld	ra,40(sp)
    800037a8:	7402                	ld	s0,32(sp)
    800037aa:	64e2                	ld	s1,24(sp)
    800037ac:	6942                	ld	s2,16(sp)
    800037ae:	69a2                	ld	s3,8(sp)
    800037b0:	6145                	addi	sp,sp,48
    800037b2:	8082                	ret
    virtio_disk_rw(b, 0);
    800037b4:	4581                	li	a1,0
    800037b6:	8526                	mv	a0,s1
    800037b8:	00003097          	auipc	ra,0x3
    800037bc:	fda080e7          	jalr	-38(ra) # 80006792 <virtio_disk_rw>
    b->valid = 1;
    800037c0:	4785                	li	a5,1
    800037c2:	c09c                	sw	a5,0(s1)
  return b;
    800037c4:	b7c5                	j	800037a4 <bread+0xd0>

00000000800037c6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037c6:	1101                	addi	sp,sp,-32
    800037c8:	ec06                	sd	ra,24(sp)
    800037ca:	e822                	sd	s0,16(sp)
    800037cc:	e426                	sd	s1,8(sp)
    800037ce:	1000                	addi	s0,sp,32
    800037d0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037d2:	0541                	addi	a0,a0,16
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	472080e7          	jalr	1138(ra) # 80004c46 <holdingsleep>
    800037dc:	cd01                	beqz	a0,800037f4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037de:	4585                	li	a1,1
    800037e0:	8526                	mv	a0,s1
    800037e2:	00003097          	auipc	ra,0x3
    800037e6:	fb0080e7          	jalr	-80(ra) # 80006792 <virtio_disk_rw>
}
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	64a2                	ld	s1,8(sp)
    800037f0:	6105                	addi	sp,sp,32
    800037f2:	8082                	ret
    panic("bwrite");
    800037f4:	00005517          	auipc	a0,0x5
    800037f8:	d9c50513          	addi	a0,a0,-612 # 80008590 <syscalls+0x100>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	d44080e7          	jalr	-700(ra) # 80000540 <panic>

0000000080003804 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	e04a                	sd	s2,0(sp)
    8000380e:	1000                	addi	s0,sp,32
    80003810:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003812:	01050913          	addi	s2,a0,16
    80003816:	854a                	mv	a0,s2
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	42e080e7          	jalr	1070(ra) # 80004c46 <holdingsleep>
    80003820:	c92d                	beqz	a0,80003892 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	3de080e7          	jalr	990(ra) # 80004c02 <releasesleep>

  acquire(&bcache.lock);
    8000382c:	00016517          	auipc	a0,0x16
    80003830:	fec50513          	addi	a0,a0,-20 # 80019818 <bcache>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	3a2080e7          	jalr	930(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000383c:	40bc                	lw	a5,64(s1)
    8000383e:	37fd                	addiw	a5,a5,-1
    80003840:	0007871b          	sext.w	a4,a5
    80003844:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003846:	eb05                	bnez	a4,80003876 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003848:	68bc                	ld	a5,80(s1)
    8000384a:	64b8                	ld	a4,72(s1)
    8000384c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000384e:	64bc                	ld	a5,72(s1)
    80003850:	68b8                	ld	a4,80(s1)
    80003852:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003854:	0001e797          	auipc	a5,0x1e
    80003858:	fc478793          	addi	a5,a5,-60 # 80021818 <bcache+0x8000>
    8000385c:	2b87b703          	ld	a4,696(a5)
    80003860:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003862:	0001e717          	auipc	a4,0x1e
    80003866:	21e70713          	addi	a4,a4,542 # 80021a80 <bcache+0x8268>
    8000386a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000386c:	2b87b703          	ld	a4,696(a5)
    80003870:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003872:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003876:	00016517          	auipc	a0,0x16
    8000387a:	fa250513          	addi	a0,a0,-94 # 80019818 <bcache>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	40c080e7          	jalr	1036(ra) # 80000c8a <release>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	64a2                	ld	s1,8(sp)
    8000388c:	6902                	ld	s2,0(sp)
    8000388e:	6105                	addi	sp,sp,32
    80003890:	8082                	ret
    panic("brelse");
    80003892:	00005517          	auipc	a0,0x5
    80003896:	d0650513          	addi	a0,a0,-762 # 80008598 <syscalls+0x108>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	ca6080e7          	jalr	-858(ra) # 80000540 <panic>

00000000800038a2 <bpin>:

void
bpin(struct buf *b) {
    800038a2:	1101                	addi	sp,sp,-32
    800038a4:	ec06                	sd	ra,24(sp)
    800038a6:	e822                	sd	s0,16(sp)
    800038a8:	e426                	sd	s1,8(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038ae:	00016517          	auipc	a0,0x16
    800038b2:	f6a50513          	addi	a0,a0,-150 # 80019818 <bcache>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	320080e7          	jalr	800(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800038be:	40bc                	lw	a5,64(s1)
    800038c0:	2785                	addiw	a5,a5,1
    800038c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038c4:	00016517          	auipc	a0,0x16
    800038c8:	f5450513          	addi	a0,a0,-172 # 80019818 <bcache>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	3be080e7          	jalr	958(ra) # 80000c8a <release>
}
    800038d4:	60e2                	ld	ra,24(sp)
    800038d6:	6442                	ld	s0,16(sp)
    800038d8:	64a2                	ld	s1,8(sp)
    800038da:	6105                	addi	sp,sp,32
    800038dc:	8082                	ret

00000000800038de <bunpin>:

void
bunpin(struct buf *b) {
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	1000                	addi	s0,sp,32
    800038e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038ea:	00016517          	auipc	a0,0x16
    800038ee:	f2e50513          	addi	a0,a0,-210 # 80019818 <bcache>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	2e4080e7          	jalr	740(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800038fa:	40bc                	lw	a5,64(s1)
    800038fc:	37fd                	addiw	a5,a5,-1
    800038fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003900:	00016517          	auipc	a0,0x16
    80003904:	f1850513          	addi	a0,a0,-232 # 80019818 <bcache>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	382080e7          	jalr	898(ra) # 80000c8a <release>
}
    80003910:	60e2                	ld	ra,24(sp)
    80003912:	6442                	ld	s0,16(sp)
    80003914:	64a2                	ld	s1,8(sp)
    80003916:	6105                	addi	sp,sp,32
    80003918:	8082                	ret

000000008000391a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000391a:	1101                	addi	sp,sp,-32
    8000391c:	ec06                	sd	ra,24(sp)
    8000391e:	e822                	sd	s0,16(sp)
    80003920:	e426                	sd	s1,8(sp)
    80003922:	e04a                	sd	s2,0(sp)
    80003924:	1000                	addi	s0,sp,32
    80003926:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003928:	00d5d59b          	srliw	a1,a1,0xd
    8000392c:	0001e797          	auipc	a5,0x1e
    80003930:	5c87a783          	lw	a5,1480(a5) # 80021ef4 <sb+0x1c>
    80003934:	9dbd                	addw	a1,a1,a5
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	d9e080e7          	jalr	-610(ra) # 800036d4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000393e:	0074f713          	andi	a4,s1,7
    80003942:	4785                	li	a5,1
    80003944:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003948:	14ce                	slli	s1,s1,0x33
    8000394a:	90d9                	srli	s1,s1,0x36
    8000394c:	00950733          	add	a4,a0,s1
    80003950:	05874703          	lbu	a4,88(a4)
    80003954:	00e7f6b3          	and	a3,a5,a4
    80003958:	c69d                	beqz	a3,80003986 <bfree+0x6c>
    8000395a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000395c:	94aa                	add	s1,s1,a0
    8000395e:	fff7c793          	not	a5,a5
    80003962:	8f7d                	and	a4,a4,a5
    80003964:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	126080e7          	jalr	294(ra) # 80004a8e <log_write>
  brelse(bp);
    80003970:	854a                	mv	a0,s2
    80003972:	00000097          	auipc	ra,0x0
    80003976:	e92080e7          	jalr	-366(ra) # 80003804 <brelse>
}
    8000397a:	60e2                	ld	ra,24(sp)
    8000397c:	6442                	ld	s0,16(sp)
    8000397e:	64a2                	ld	s1,8(sp)
    80003980:	6902                	ld	s2,0(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret
    panic("freeing free block");
    80003986:	00005517          	auipc	a0,0x5
    8000398a:	c1a50513          	addi	a0,a0,-998 # 800085a0 <syscalls+0x110>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	bb2080e7          	jalr	-1102(ra) # 80000540 <panic>

0000000080003996 <balloc>:
{
    80003996:	711d                	addi	sp,sp,-96
    80003998:	ec86                	sd	ra,88(sp)
    8000399a:	e8a2                	sd	s0,80(sp)
    8000399c:	e4a6                	sd	s1,72(sp)
    8000399e:	e0ca                	sd	s2,64(sp)
    800039a0:	fc4e                	sd	s3,56(sp)
    800039a2:	f852                	sd	s4,48(sp)
    800039a4:	f456                	sd	s5,40(sp)
    800039a6:	f05a                	sd	s6,32(sp)
    800039a8:	ec5e                	sd	s7,24(sp)
    800039aa:	e862                	sd	s8,16(sp)
    800039ac:	e466                	sd	s9,8(sp)
    800039ae:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039b0:	0001e797          	auipc	a5,0x1e
    800039b4:	52c7a783          	lw	a5,1324(a5) # 80021edc <sb+0x4>
    800039b8:	cff5                	beqz	a5,80003ab4 <balloc+0x11e>
    800039ba:	8baa                	mv	s7,a0
    800039bc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039be:	0001eb17          	auipc	s6,0x1e
    800039c2:	51ab0b13          	addi	s6,s6,1306 # 80021ed8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039c8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ca:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039cc:	6c89                	lui	s9,0x2
    800039ce:	a061                	j	80003a56 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039d0:	97ca                	add	a5,a5,s2
    800039d2:	8e55                	or	a2,a2,a3
    800039d4:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	0b4080e7          	jalr	180(ra) # 80004a8e <log_write>
        brelse(bp);
    800039e2:	854a                	mv	a0,s2
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	e20080e7          	jalr	-480(ra) # 80003804 <brelse>
  bp = bread(dev, bno);
    800039ec:	85a6                	mv	a1,s1
    800039ee:	855e                	mv	a0,s7
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	ce4080e7          	jalr	-796(ra) # 800036d4 <bread>
    800039f8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039fa:	40000613          	li	a2,1024
    800039fe:	4581                	li	a1,0
    80003a00:	05850513          	addi	a0,a0,88
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	2ce080e7          	jalr	718(ra) # 80000cd2 <memset>
  log_write(bp);
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	00001097          	auipc	ra,0x1
    80003a12:	080080e7          	jalr	128(ra) # 80004a8e <log_write>
  brelse(bp);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	dec080e7          	jalr	-532(ra) # 80003804 <brelse>
}
    80003a20:	8526                	mv	a0,s1
    80003a22:	60e6                	ld	ra,88(sp)
    80003a24:	6446                	ld	s0,80(sp)
    80003a26:	64a6                	ld	s1,72(sp)
    80003a28:	6906                	ld	s2,64(sp)
    80003a2a:	79e2                	ld	s3,56(sp)
    80003a2c:	7a42                	ld	s4,48(sp)
    80003a2e:	7aa2                	ld	s5,40(sp)
    80003a30:	7b02                	ld	s6,32(sp)
    80003a32:	6be2                	ld	s7,24(sp)
    80003a34:	6c42                	ld	s8,16(sp)
    80003a36:	6ca2                	ld	s9,8(sp)
    80003a38:	6125                	addi	sp,sp,96
    80003a3a:	8082                	ret
    brelse(bp);
    80003a3c:	854a                	mv	a0,s2
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	dc6080e7          	jalr	-570(ra) # 80003804 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a46:	015c87bb          	addw	a5,s9,s5
    80003a4a:	00078a9b          	sext.w	s5,a5
    80003a4e:	004b2703          	lw	a4,4(s6)
    80003a52:	06eaf163          	bgeu	s5,a4,80003ab4 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003a56:	41fad79b          	sraiw	a5,s5,0x1f
    80003a5a:	0137d79b          	srliw	a5,a5,0x13
    80003a5e:	015787bb          	addw	a5,a5,s5
    80003a62:	40d7d79b          	sraiw	a5,a5,0xd
    80003a66:	01cb2583          	lw	a1,28(s6)
    80003a6a:	9dbd                	addw	a1,a1,a5
    80003a6c:	855e                	mv	a0,s7
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	c66080e7          	jalr	-922(ra) # 800036d4 <bread>
    80003a76:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a78:	004b2503          	lw	a0,4(s6)
    80003a7c:	000a849b          	sext.w	s1,s5
    80003a80:	8762                	mv	a4,s8
    80003a82:	faa4fde3          	bgeu	s1,a0,80003a3c <balloc+0xa6>
      m = 1 << (bi % 8);
    80003a86:	00777693          	andi	a3,a4,7
    80003a8a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a8e:	41f7579b          	sraiw	a5,a4,0x1f
    80003a92:	01d7d79b          	srliw	a5,a5,0x1d
    80003a96:	9fb9                	addw	a5,a5,a4
    80003a98:	4037d79b          	sraiw	a5,a5,0x3
    80003a9c:	00f90633          	add	a2,s2,a5
    80003aa0:	05864603          	lbu	a2,88(a2)
    80003aa4:	00c6f5b3          	and	a1,a3,a2
    80003aa8:	d585                	beqz	a1,800039d0 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aaa:	2705                	addiw	a4,a4,1
    80003aac:	2485                	addiw	s1,s1,1
    80003aae:	fd471ae3          	bne	a4,s4,80003a82 <balloc+0xec>
    80003ab2:	b769                	j	80003a3c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003ab4:	00005517          	auipc	a0,0x5
    80003ab8:	b0450513          	addi	a0,a0,-1276 # 800085b8 <syscalls+0x128>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	ace080e7          	jalr	-1330(ra) # 8000058a <printf>
  return 0;
    80003ac4:	4481                	li	s1,0
    80003ac6:	bfa9                	j	80003a20 <balloc+0x8a>

0000000080003ac8 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ac8:	7179                	addi	sp,sp,-48
    80003aca:	f406                	sd	ra,40(sp)
    80003acc:	f022                	sd	s0,32(sp)
    80003ace:	ec26                	sd	s1,24(sp)
    80003ad0:	e84a                	sd	s2,16(sp)
    80003ad2:	e44e                	sd	s3,8(sp)
    80003ad4:	e052                	sd	s4,0(sp)
    80003ad6:	1800                	addi	s0,sp,48
    80003ad8:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ada:	47ad                	li	a5,11
    80003adc:	02b7e863          	bltu	a5,a1,80003b0c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003ae0:	02059793          	slli	a5,a1,0x20
    80003ae4:	01e7d593          	srli	a1,a5,0x1e
    80003ae8:	00b504b3          	add	s1,a0,a1
    80003aec:	0504a903          	lw	s2,80(s1)
    80003af0:	06091e63          	bnez	s2,80003b6c <bmap+0xa4>
      addr = balloc(ip->dev);
    80003af4:	4108                	lw	a0,0(a0)
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	ea0080e7          	jalr	-352(ra) # 80003996 <balloc>
    80003afe:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b02:	06090563          	beqz	s2,80003b6c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003b06:	0524a823          	sw	s2,80(s1)
    80003b0a:	a08d                	j	80003b6c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003b0c:	ff45849b          	addiw	s1,a1,-12
    80003b10:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b14:	0ff00793          	li	a5,255
    80003b18:	08e7e563          	bltu	a5,a4,80003ba2 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b1c:	08052903          	lw	s2,128(a0)
    80003b20:	00091d63          	bnez	s2,80003b3a <bmap+0x72>
      addr = balloc(ip->dev);
    80003b24:	4108                	lw	a0,0(a0)
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	e70080e7          	jalr	-400(ra) # 80003996 <balloc>
    80003b2e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b32:	02090d63          	beqz	s2,80003b6c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b36:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003b3a:	85ca                	mv	a1,s2
    80003b3c:	0009a503          	lw	a0,0(s3)
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	b94080e7          	jalr	-1132(ra) # 800036d4 <bread>
    80003b48:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b4a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b4e:	02049713          	slli	a4,s1,0x20
    80003b52:	01e75593          	srli	a1,a4,0x1e
    80003b56:	00b784b3          	add	s1,a5,a1
    80003b5a:	0004a903          	lw	s2,0(s1)
    80003b5e:	02090063          	beqz	s2,80003b7e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b62:	8552                	mv	a0,s4
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	ca0080e7          	jalr	-864(ra) # 80003804 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b6c:	854a                	mv	a0,s2
    80003b6e:	70a2                	ld	ra,40(sp)
    80003b70:	7402                	ld	s0,32(sp)
    80003b72:	64e2                	ld	s1,24(sp)
    80003b74:	6942                	ld	s2,16(sp)
    80003b76:	69a2                	ld	s3,8(sp)
    80003b78:	6a02                	ld	s4,0(sp)
    80003b7a:	6145                	addi	sp,sp,48
    80003b7c:	8082                	ret
      addr = balloc(ip->dev);
    80003b7e:	0009a503          	lw	a0,0(s3)
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	e14080e7          	jalr	-492(ra) # 80003996 <balloc>
    80003b8a:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b8e:	fc090ae3          	beqz	s2,80003b62 <bmap+0x9a>
        a[bn] = addr;
    80003b92:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b96:	8552                	mv	a0,s4
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	ef6080e7          	jalr	-266(ra) # 80004a8e <log_write>
    80003ba0:	b7c9                	j	80003b62 <bmap+0x9a>
  panic("bmap: out of range");
    80003ba2:	00005517          	auipc	a0,0x5
    80003ba6:	a2e50513          	addi	a0,a0,-1490 # 800085d0 <syscalls+0x140>
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	996080e7          	jalr	-1642(ra) # 80000540 <panic>

0000000080003bb2 <iget>:
{
    80003bb2:	7179                	addi	sp,sp,-48
    80003bb4:	f406                	sd	ra,40(sp)
    80003bb6:	f022                	sd	s0,32(sp)
    80003bb8:	ec26                	sd	s1,24(sp)
    80003bba:	e84a                	sd	s2,16(sp)
    80003bbc:	e44e                	sd	s3,8(sp)
    80003bbe:	e052                	sd	s4,0(sp)
    80003bc0:	1800                	addi	s0,sp,48
    80003bc2:	89aa                	mv	s3,a0
    80003bc4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bc6:	0001e517          	auipc	a0,0x1e
    80003bca:	33250513          	addi	a0,a0,818 # 80021ef8 <itable>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	008080e7          	jalr	8(ra) # 80000bd6 <acquire>
  empty = 0;
    80003bd6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bd8:	0001e497          	auipc	s1,0x1e
    80003bdc:	33848493          	addi	s1,s1,824 # 80021f10 <itable+0x18>
    80003be0:	00020697          	auipc	a3,0x20
    80003be4:	dc068693          	addi	a3,a3,-576 # 800239a0 <log>
    80003be8:	a039                	j	80003bf6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bea:	02090b63          	beqz	s2,80003c20 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bee:	08848493          	addi	s1,s1,136
    80003bf2:	02d48a63          	beq	s1,a3,80003c26 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bf6:	449c                	lw	a5,8(s1)
    80003bf8:	fef059e3          	blez	a5,80003bea <iget+0x38>
    80003bfc:	4098                	lw	a4,0(s1)
    80003bfe:	ff3716e3          	bne	a4,s3,80003bea <iget+0x38>
    80003c02:	40d8                	lw	a4,4(s1)
    80003c04:	ff4713e3          	bne	a4,s4,80003bea <iget+0x38>
      ip->ref++;
    80003c08:	2785                	addiw	a5,a5,1
    80003c0a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c0c:	0001e517          	auipc	a0,0x1e
    80003c10:	2ec50513          	addi	a0,a0,748 # 80021ef8 <itable>
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	076080e7          	jalr	118(ra) # 80000c8a <release>
      return ip;
    80003c1c:	8926                	mv	s2,s1
    80003c1e:	a03d                	j	80003c4c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c20:	f7f9                	bnez	a5,80003bee <iget+0x3c>
    80003c22:	8926                	mv	s2,s1
    80003c24:	b7e9                	j	80003bee <iget+0x3c>
  if(empty == 0)
    80003c26:	02090c63          	beqz	s2,80003c5e <iget+0xac>
  ip->dev = dev;
    80003c2a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c2e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c32:	4785                	li	a5,1
    80003c34:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c38:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c3c:	0001e517          	auipc	a0,0x1e
    80003c40:	2bc50513          	addi	a0,a0,700 # 80021ef8 <itable>
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	046080e7          	jalr	70(ra) # 80000c8a <release>
}
    80003c4c:	854a                	mv	a0,s2
    80003c4e:	70a2                	ld	ra,40(sp)
    80003c50:	7402                	ld	s0,32(sp)
    80003c52:	64e2                	ld	s1,24(sp)
    80003c54:	6942                	ld	s2,16(sp)
    80003c56:	69a2                	ld	s3,8(sp)
    80003c58:	6a02                	ld	s4,0(sp)
    80003c5a:	6145                	addi	sp,sp,48
    80003c5c:	8082                	ret
    panic("iget: no inodes");
    80003c5e:	00005517          	auipc	a0,0x5
    80003c62:	98a50513          	addi	a0,a0,-1654 # 800085e8 <syscalls+0x158>
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	8da080e7          	jalr	-1830(ra) # 80000540 <panic>

0000000080003c6e <fsinit>:
fsinit(int dev) {
    80003c6e:	7179                	addi	sp,sp,-48
    80003c70:	f406                	sd	ra,40(sp)
    80003c72:	f022                	sd	s0,32(sp)
    80003c74:	ec26                	sd	s1,24(sp)
    80003c76:	e84a                	sd	s2,16(sp)
    80003c78:	e44e                	sd	s3,8(sp)
    80003c7a:	1800                	addi	s0,sp,48
    80003c7c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c7e:	4585                	li	a1,1
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	a54080e7          	jalr	-1452(ra) # 800036d4 <bread>
    80003c88:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c8a:	0001e997          	auipc	s3,0x1e
    80003c8e:	24e98993          	addi	s3,s3,590 # 80021ed8 <sb>
    80003c92:	02000613          	li	a2,32
    80003c96:	05850593          	addi	a1,a0,88
    80003c9a:	854e                	mv	a0,s3
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	092080e7          	jalr	146(ra) # 80000d2e <memmove>
  brelse(bp);
    80003ca4:	8526                	mv	a0,s1
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	b5e080e7          	jalr	-1186(ra) # 80003804 <brelse>
  if(sb.magic != FSMAGIC)
    80003cae:	0009a703          	lw	a4,0(s3)
    80003cb2:	102037b7          	lui	a5,0x10203
    80003cb6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cba:	02f71263          	bne	a4,a5,80003cde <fsinit+0x70>
  initlog(dev, &sb);
    80003cbe:	0001e597          	auipc	a1,0x1e
    80003cc2:	21a58593          	addi	a1,a1,538 # 80021ed8 <sb>
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	b4a080e7          	jalr	-1206(ra) # 80004812 <initlog>
}
    80003cd0:	70a2                	ld	ra,40(sp)
    80003cd2:	7402                	ld	s0,32(sp)
    80003cd4:	64e2                	ld	s1,24(sp)
    80003cd6:	6942                	ld	s2,16(sp)
    80003cd8:	69a2                	ld	s3,8(sp)
    80003cda:	6145                	addi	sp,sp,48
    80003cdc:	8082                	ret
    panic("invalid file system");
    80003cde:	00005517          	auipc	a0,0x5
    80003ce2:	91a50513          	addi	a0,a0,-1766 # 800085f8 <syscalls+0x168>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	85a080e7          	jalr	-1958(ra) # 80000540 <panic>

0000000080003cee <iinit>:
{
    80003cee:	7179                	addi	sp,sp,-48
    80003cf0:	f406                	sd	ra,40(sp)
    80003cf2:	f022                	sd	s0,32(sp)
    80003cf4:	ec26                	sd	s1,24(sp)
    80003cf6:	e84a                	sd	s2,16(sp)
    80003cf8:	e44e                	sd	s3,8(sp)
    80003cfa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cfc:	00005597          	auipc	a1,0x5
    80003d00:	91458593          	addi	a1,a1,-1772 # 80008610 <syscalls+0x180>
    80003d04:	0001e517          	auipc	a0,0x1e
    80003d08:	1f450513          	addi	a0,a0,500 # 80021ef8 <itable>
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	e3a080e7          	jalr	-454(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d14:	0001e497          	auipc	s1,0x1e
    80003d18:	20c48493          	addi	s1,s1,524 # 80021f20 <itable+0x28>
    80003d1c:	00020997          	auipc	s3,0x20
    80003d20:	c9498993          	addi	s3,s3,-876 # 800239b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d24:	00005917          	auipc	s2,0x5
    80003d28:	8f490913          	addi	s2,s2,-1804 # 80008618 <syscalls+0x188>
    80003d2c:	85ca                	mv	a1,s2
    80003d2e:	8526                	mv	a0,s1
    80003d30:	00001097          	auipc	ra,0x1
    80003d34:	e42080e7          	jalr	-446(ra) # 80004b72 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d38:	08848493          	addi	s1,s1,136
    80003d3c:	ff3498e3          	bne	s1,s3,80003d2c <iinit+0x3e>
}
    80003d40:	70a2                	ld	ra,40(sp)
    80003d42:	7402                	ld	s0,32(sp)
    80003d44:	64e2                	ld	s1,24(sp)
    80003d46:	6942                	ld	s2,16(sp)
    80003d48:	69a2                	ld	s3,8(sp)
    80003d4a:	6145                	addi	sp,sp,48
    80003d4c:	8082                	ret

0000000080003d4e <ialloc>:
{
    80003d4e:	715d                	addi	sp,sp,-80
    80003d50:	e486                	sd	ra,72(sp)
    80003d52:	e0a2                	sd	s0,64(sp)
    80003d54:	fc26                	sd	s1,56(sp)
    80003d56:	f84a                	sd	s2,48(sp)
    80003d58:	f44e                	sd	s3,40(sp)
    80003d5a:	f052                	sd	s4,32(sp)
    80003d5c:	ec56                	sd	s5,24(sp)
    80003d5e:	e85a                	sd	s6,16(sp)
    80003d60:	e45e                	sd	s7,8(sp)
    80003d62:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d64:	0001e717          	auipc	a4,0x1e
    80003d68:	18072703          	lw	a4,384(a4) # 80021ee4 <sb+0xc>
    80003d6c:	4785                	li	a5,1
    80003d6e:	04e7fa63          	bgeu	a5,a4,80003dc2 <ialloc+0x74>
    80003d72:	8aaa                	mv	s5,a0
    80003d74:	8bae                	mv	s7,a1
    80003d76:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d78:	0001ea17          	auipc	s4,0x1e
    80003d7c:	160a0a13          	addi	s4,s4,352 # 80021ed8 <sb>
    80003d80:	00048b1b          	sext.w	s6,s1
    80003d84:	0044d593          	srli	a1,s1,0x4
    80003d88:	018a2783          	lw	a5,24(s4)
    80003d8c:	9dbd                	addw	a1,a1,a5
    80003d8e:	8556                	mv	a0,s5
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	944080e7          	jalr	-1724(ra) # 800036d4 <bread>
    80003d98:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d9a:	05850993          	addi	s3,a0,88
    80003d9e:	00f4f793          	andi	a5,s1,15
    80003da2:	079a                	slli	a5,a5,0x6
    80003da4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003da6:	00099783          	lh	a5,0(s3)
    80003daa:	c3a1                	beqz	a5,80003dea <ialloc+0x9c>
    brelse(bp);
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	a58080e7          	jalr	-1448(ra) # 80003804 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003db4:	0485                	addi	s1,s1,1
    80003db6:	00ca2703          	lw	a4,12(s4)
    80003dba:	0004879b          	sext.w	a5,s1
    80003dbe:	fce7e1e3          	bltu	a5,a4,80003d80 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003dc2:	00005517          	auipc	a0,0x5
    80003dc6:	85e50513          	addi	a0,a0,-1954 # 80008620 <syscalls+0x190>
    80003dca:	ffffc097          	auipc	ra,0xffffc
    80003dce:	7c0080e7          	jalr	1984(ra) # 8000058a <printf>
  return 0;
    80003dd2:	4501                	li	a0,0
}
    80003dd4:	60a6                	ld	ra,72(sp)
    80003dd6:	6406                	ld	s0,64(sp)
    80003dd8:	74e2                	ld	s1,56(sp)
    80003dda:	7942                	ld	s2,48(sp)
    80003ddc:	79a2                	ld	s3,40(sp)
    80003dde:	7a02                	ld	s4,32(sp)
    80003de0:	6ae2                	ld	s5,24(sp)
    80003de2:	6b42                	ld	s6,16(sp)
    80003de4:	6ba2                	ld	s7,8(sp)
    80003de6:	6161                	addi	sp,sp,80
    80003de8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003dea:	04000613          	li	a2,64
    80003dee:	4581                	li	a1,0
    80003df0:	854e                	mv	a0,s3
    80003df2:	ffffd097          	auipc	ra,0xffffd
    80003df6:	ee0080e7          	jalr	-288(ra) # 80000cd2 <memset>
      dip->type = type;
    80003dfa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dfe:	854a                	mv	a0,s2
    80003e00:	00001097          	auipc	ra,0x1
    80003e04:	c8e080e7          	jalr	-882(ra) # 80004a8e <log_write>
      brelse(bp);
    80003e08:	854a                	mv	a0,s2
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	9fa080e7          	jalr	-1542(ra) # 80003804 <brelse>
      return iget(dev, inum);
    80003e12:	85da                	mv	a1,s6
    80003e14:	8556                	mv	a0,s5
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	d9c080e7          	jalr	-612(ra) # 80003bb2 <iget>
    80003e1e:	bf5d                	j	80003dd4 <ialloc+0x86>

0000000080003e20 <iupdate>:
{
    80003e20:	1101                	addi	sp,sp,-32
    80003e22:	ec06                	sd	ra,24(sp)
    80003e24:	e822                	sd	s0,16(sp)
    80003e26:	e426                	sd	s1,8(sp)
    80003e28:	e04a                	sd	s2,0(sp)
    80003e2a:	1000                	addi	s0,sp,32
    80003e2c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e2e:	415c                	lw	a5,4(a0)
    80003e30:	0047d79b          	srliw	a5,a5,0x4
    80003e34:	0001e597          	auipc	a1,0x1e
    80003e38:	0bc5a583          	lw	a1,188(a1) # 80021ef0 <sb+0x18>
    80003e3c:	9dbd                	addw	a1,a1,a5
    80003e3e:	4108                	lw	a0,0(a0)
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	894080e7          	jalr	-1900(ra) # 800036d4 <bread>
    80003e48:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e4a:	05850793          	addi	a5,a0,88
    80003e4e:	40d8                	lw	a4,4(s1)
    80003e50:	8b3d                	andi	a4,a4,15
    80003e52:	071a                	slli	a4,a4,0x6
    80003e54:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003e56:	04449703          	lh	a4,68(s1)
    80003e5a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003e5e:	04649703          	lh	a4,70(s1)
    80003e62:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003e66:	04849703          	lh	a4,72(s1)
    80003e6a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003e6e:	04a49703          	lh	a4,74(s1)
    80003e72:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003e76:	44f8                	lw	a4,76(s1)
    80003e78:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e7a:	03400613          	li	a2,52
    80003e7e:	05048593          	addi	a1,s1,80
    80003e82:	00c78513          	addi	a0,a5,12
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	ea8080e7          	jalr	-344(ra) # 80000d2e <memmove>
  log_write(bp);
    80003e8e:	854a                	mv	a0,s2
    80003e90:	00001097          	auipc	ra,0x1
    80003e94:	bfe080e7          	jalr	-1026(ra) # 80004a8e <log_write>
  brelse(bp);
    80003e98:	854a                	mv	a0,s2
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	96a080e7          	jalr	-1686(ra) # 80003804 <brelse>
}
    80003ea2:	60e2                	ld	ra,24(sp)
    80003ea4:	6442                	ld	s0,16(sp)
    80003ea6:	64a2                	ld	s1,8(sp)
    80003ea8:	6902                	ld	s2,0(sp)
    80003eaa:	6105                	addi	sp,sp,32
    80003eac:	8082                	ret

0000000080003eae <idup>:
{
    80003eae:	1101                	addi	sp,sp,-32
    80003eb0:	ec06                	sd	ra,24(sp)
    80003eb2:	e822                	sd	s0,16(sp)
    80003eb4:	e426                	sd	s1,8(sp)
    80003eb6:	1000                	addi	s0,sp,32
    80003eb8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eba:	0001e517          	auipc	a0,0x1e
    80003ebe:	03e50513          	addi	a0,a0,62 # 80021ef8 <itable>
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	d14080e7          	jalr	-748(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003eca:	449c                	lw	a5,8(s1)
    80003ecc:	2785                	addiw	a5,a5,1
    80003ece:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ed0:	0001e517          	auipc	a0,0x1e
    80003ed4:	02850513          	addi	a0,a0,40 # 80021ef8 <itable>
    80003ed8:	ffffd097          	auipc	ra,0xffffd
    80003edc:	db2080e7          	jalr	-590(ra) # 80000c8a <release>
}
    80003ee0:	8526                	mv	a0,s1
    80003ee2:	60e2                	ld	ra,24(sp)
    80003ee4:	6442                	ld	s0,16(sp)
    80003ee6:	64a2                	ld	s1,8(sp)
    80003ee8:	6105                	addi	sp,sp,32
    80003eea:	8082                	ret

0000000080003eec <ilock>:
{
    80003eec:	1101                	addi	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	e426                	sd	s1,8(sp)
    80003ef4:	e04a                	sd	s2,0(sp)
    80003ef6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ef8:	c115                	beqz	a0,80003f1c <ilock+0x30>
    80003efa:	84aa                	mv	s1,a0
    80003efc:	451c                	lw	a5,8(a0)
    80003efe:	00f05f63          	blez	a5,80003f1c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f02:	0541                	addi	a0,a0,16
    80003f04:	00001097          	auipc	ra,0x1
    80003f08:	ca8080e7          	jalr	-856(ra) # 80004bac <acquiresleep>
  if(ip->valid == 0){
    80003f0c:	40bc                	lw	a5,64(s1)
    80003f0e:	cf99                	beqz	a5,80003f2c <ilock+0x40>
}
    80003f10:	60e2                	ld	ra,24(sp)
    80003f12:	6442                	ld	s0,16(sp)
    80003f14:	64a2                	ld	s1,8(sp)
    80003f16:	6902                	ld	s2,0(sp)
    80003f18:	6105                	addi	sp,sp,32
    80003f1a:	8082                	ret
    panic("ilock");
    80003f1c:	00004517          	auipc	a0,0x4
    80003f20:	71c50513          	addi	a0,a0,1820 # 80008638 <syscalls+0x1a8>
    80003f24:	ffffc097          	auipc	ra,0xffffc
    80003f28:	61c080e7          	jalr	1564(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f2c:	40dc                	lw	a5,4(s1)
    80003f2e:	0047d79b          	srliw	a5,a5,0x4
    80003f32:	0001e597          	auipc	a1,0x1e
    80003f36:	fbe5a583          	lw	a1,-66(a1) # 80021ef0 <sb+0x18>
    80003f3a:	9dbd                	addw	a1,a1,a5
    80003f3c:	4088                	lw	a0,0(s1)
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	796080e7          	jalr	1942(ra) # 800036d4 <bread>
    80003f46:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f48:	05850593          	addi	a1,a0,88
    80003f4c:	40dc                	lw	a5,4(s1)
    80003f4e:	8bbd                	andi	a5,a5,15
    80003f50:	079a                	slli	a5,a5,0x6
    80003f52:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f54:	00059783          	lh	a5,0(a1)
    80003f58:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f5c:	00259783          	lh	a5,2(a1)
    80003f60:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f64:	00459783          	lh	a5,4(a1)
    80003f68:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f6c:	00659783          	lh	a5,6(a1)
    80003f70:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f74:	459c                	lw	a5,8(a1)
    80003f76:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f78:	03400613          	li	a2,52
    80003f7c:	05b1                	addi	a1,a1,12
    80003f7e:	05048513          	addi	a0,s1,80
    80003f82:	ffffd097          	auipc	ra,0xffffd
    80003f86:	dac080e7          	jalr	-596(ra) # 80000d2e <memmove>
    brelse(bp);
    80003f8a:	854a                	mv	a0,s2
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	878080e7          	jalr	-1928(ra) # 80003804 <brelse>
    ip->valid = 1;
    80003f94:	4785                	li	a5,1
    80003f96:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f98:	04449783          	lh	a5,68(s1)
    80003f9c:	fbb5                	bnez	a5,80003f10 <ilock+0x24>
      panic("ilock: no type");
    80003f9e:	00004517          	auipc	a0,0x4
    80003fa2:	6a250513          	addi	a0,a0,1698 # 80008640 <syscalls+0x1b0>
    80003fa6:	ffffc097          	auipc	ra,0xffffc
    80003faa:	59a080e7          	jalr	1434(ra) # 80000540 <panic>

0000000080003fae <iunlock>:
{
    80003fae:	1101                	addi	sp,sp,-32
    80003fb0:	ec06                	sd	ra,24(sp)
    80003fb2:	e822                	sd	s0,16(sp)
    80003fb4:	e426                	sd	s1,8(sp)
    80003fb6:	e04a                	sd	s2,0(sp)
    80003fb8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fba:	c905                	beqz	a0,80003fea <iunlock+0x3c>
    80003fbc:	84aa                	mv	s1,a0
    80003fbe:	01050913          	addi	s2,a0,16
    80003fc2:	854a                	mv	a0,s2
    80003fc4:	00001097          	auipc	ra,0x1
    80003fc8:	c82080e7          	jalr	-894(ra) # 80004c46 <holdingsleep>
    80003fcc:	cd19                	beqz	a0,80003fea <iunlock+0x3c>
    80003fce:	449c                	lw	a5,8(s1)
    80003fd0:	00f05d63          	blez	a5,80003fea <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fd4:	854a                	mv	a0,s2
    80003fd6:	00001097          	auipc	ra,0x1
    80003fda:	c2c080e7          	jalr	-980(ra) # 80004c02 <releasesleep>
}
    80003fde:	60e2                	ld	ra,24(sp)
    80003fe0:	6442                	ld	s0,16(sp)
    80003fe2:	64a2                	ld	s1,8(sp)
    80003fe4:	6902                	ld	s2,0(sp)
    80003fe6:	6105                	addi	sp,sp,32
    80003fe8:	8082                	ret
    panic("iunlock");
    80003fea:	00004517          	auipc	a0,0x4
    80003fee:	66650513          	addi	a0,a0,1638 # 80008650 <syscalls+0x1c0>
    80003ff2:	ffffc097          	auipc	ra,0xffffc
    80003ff6:	54e080e7          	jalr	1358(ra) # 80000540 <panic>

0000000080003ffa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ffa:	7179                	addi	sp,sp,-48
    80003ffc:	f406                	sd	ra,40(sp)
    80003ffe:	f022                	sd	s0,32(sp)
    80004000:	ec26                	sd	s1,24(sp)
    80004002:	e84a                	sd	s2,16(sp)
    80004004:	e44e                	sd	s3,8(sp)
    80004006:	e052                	sd	s4,0(sp)
    80004008:	1800                	addi	s0,sp,48
    8000400a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000400c:	05050493          	addi	s1,a0,80
    80004010:	08050913          	addi	s2,a0,128
    80004014:	a021                	j	8000401c <itrunc+0x22>
    80004016:	0491                	addi	s1,s1,4
    80004018:	01248d63          	beq	s1,s2,80004032 <itrunc+0x38>
    if(ip->addrs[i]){
    8000401c:	408c                	lw	a1,0(s1)
    8000401e:	dde5                	beqz	a1,80004016 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004020:	0009a503          	lw	a0,0(s3)
    80004024:	00000097          	auipc	ra,0x0
    80004028:	8f6080e7          	jalr	-1802(ra) # 8000391a <bfree>
      ip->addrs[i] = 0;
    8000402c:	0004a023          	sw	zero,0(s1)
    80004030:	b7dd                	j	80004016 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004032:	0809a583          	lw	a1,128(s3)
    80004036:	e185                	bnez	a1,80004056 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004038:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000403c:	854e                	mv	a0,s3
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	de2080e7          	jalr	-542(ra) # 80003e20 <iupdate>
}
    80004046:	70a2                	ld	ra,40(sp)
    80004048:	7402                	ld	s0,32(sp)
    8000404a:	64e2                	ld	s1,24(sp)
    8000404c:	6942                	ld	s2,16(sp)
    8000404e:	69a2                	ld	s3,8(sp)
    80004050:	6a02                	ld	s4,0(sp)
    80004052:	6145                	addi	sp,sp,48
    80004054:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004056:	0009a503          	lw	a0,0(s3)
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	67a080e7          	jalr	1658(ra) # 800036d4 <bread>
    80004062:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004064:	05850493          	addi	s1,a0,88
    80004068:	45850913          	addi	s2,a0,1112
    8000406c:	a021                	j	80004074 <itrunc+0x7a>
    8000406e:	0491                	addi	s1,s1,4
    80004070:	01248b63          	beq	s1,s2,80004086 <itrunc+0x8c>
      if(a[j])
    80004074:	408c                	lw	a1,0(s1)
    80004076:	dde5                	beqz	a1,8000406e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004078:	0009a503          	lw	a0,0(s3)
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	89e080e7          	jalr	-1890(ra) # 8000391a <bfree>
    80004084:	b7ed                	j	8000406e <itrunc+0x74>
    brelse(bp);
    80004086:	8552                	mv	a0,s4
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	77c080e7          	jalr	1916(ra) # 80003804 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004090:	0809a583          	lw	a1,128(s3)
    80004094:	0009a503          	lw	a0,0(s3)
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	882080e7          	jalr	-1918(ra) # 8000391a <bfree>
    ip->addrs[NDIRECT] = 0;
    800040a0:	0809a023          	sw	zero,128(s3)
    800040a4:	bf51                	j	80004038 <itrunc+0x3e>

00000000800040a6 <iput>:
{
    800040a6:	1101                	addi	sp,sp,-32
    800040a8:	ec06                	sd	ra,24(sp)
    800040aa:	e822                	sd	s0,16(sp)
    800040ac:	e426                	sd	s1,8(sp)
    800040ae:	e04a                	sd	s2,0(sp)
    800040b0:	1000                	addi	s0,sp,32
    800040b2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040b4:	0001e517          	auipc	a0,0x1e
    800040b8:	e4450513          	addi	a0,a0,-444 # 80021ef8 <itable>
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	b1a080e7          	jalr	-1254(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040c4:	4498                	lw	a4,8(s1)
    800040c6:	4785                	li	a5,1
    800040c8:	02f70363          	beq	a4,a5,800040ee <iput+0x48>
  ip->ref--;
    800040cc:	449c                	lw	a5,8(s1)
    800040ce:	37fd                	addiw	a5,a5,-1
    800040d0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040d2:	0001e517          	auipc	a0,0x1e
    800040d6:	e2650513          	addi	a0,a0,-474 # 80021ef8 <itable>
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	bb0080e7          	jalr	-1104(ra) # 80000c8a <release>
}
    800040e2:	60e2                	ld	ra,24(sp)
    800040e4:	6442                	ld	s0,16(sp)
    800040e6:	64a2                	ld	s1,8(sp)
    800040e8:	6902                	ld	s2,0(sp)
    800040ea:	6105                	addi	sp,sp,32
    800040ec:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040ee:	40bc                	lw	a5,64(s1)
    800040f0:	dff1                	beqz	a5,800040cc <iput+0x26>
    800040f2:	04a49783          	lh	a5,74(s1)
    800040f6:	fbf9                	bnez	a5,800040cc <iput+0x26>
    acquiresleep(&ip->lock);
    800040f8:	01048913          	addi	s2,s1,16
    800040fc:	854a                	mv	a0,s2
    800040fe:	00001097          	auipc	ra,0x1
    80004102:	aae080e7          	jalr	-1362(ra) # 80004bac <acquiresleep>
    release(&itable.lock);
    80004106:	0001e517          	auipc	a0,0x1e
    8000410a:	df250513          	addi	a0,a0,-526 # 80021ef8 <itable>
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	b7c080e7          	jalr	-1156(ra) # 80000c8a <release>
    itrunc(ip);
    80004116:	8526                	mv	a0,s1
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	ee2080e7          	jalr	-286(ra) # 80003ffa <itrunc>
    ip->type = 0;
    80004120:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004124:	8526                	mv	a0,s1
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	cfa080e7          	jalr	-774(ra) # 80003e20 <iupdate>
    ip->valid = 0;
    8000412e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004132:	854a                	mv	a0,s2
    80004134:	00001097          	auipc	ra,0x1
    80004138:	ace080e7          	jalr	-1330(ra) # 80004c02 <releasesleep>
    acquire(&itable.lock);
    8000413c:	0001e517          	auipc	a0,0x1e
    80004140:	dbc50513          	addi	a0,a0,-580 # 80021ef8 <itable>
    80004144:	ffffd097          	auipc	ra,0xffffd
    80004148:	a92080e7          	jalr	-1390(ra) # 80000bd6 <acquire>
    8000414c:	b741                	j	800040cc <iput+0x26>

000000008000414e <iunlockput>:
{
    8000414e:	1101                	addi	sp,sp,-32
    80004150:	ec06                	sd	ra,24(sp)
    80004152:	e822                	sd	s0,16(sp)
    80004154:	e426                	sd	s1,8(sp)
    80004156:	1000                	addi	s0,sp,32
    80004158:	84aa                	mv	s1,a0
  iunlock(ip);
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	e54080e7          	jalr	-428(ra) # 80003fae <iunlock>
  iput(ip);
    80004162:	8526                	mv	a0,s1
    80004164:	00000097          	auipc	ra,0x0
    80004168:	f42080e7          	jalr	-190(ra) # 800040a6 <iput>
}
    8000416c:	60e2                	ld	ra,24(sp)
    8000416e:	6442                	ld	s0,16(sp)
    80004170:	64a2                	ld	s1,8(sp)
    80004172:	6105                	addi	sp,sp,32
    80004174:	8082                	ret

0000000080004176 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004176:	1141                	addi	sp,sp,-16
    80004178:	e422                	sd	s0,8(sp)
    8000417a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000417c:	411c                	lw	a5,0(a0)
    8000417e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004180:	415c                	lw	a5,4(a0)
    80004182:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004184:	04451783          	lh	a5,68(a0)
    80004188:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000418c:	04a51783          	lh	a5,74(a0)
    80004190:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004194:	04c56783          	lwu	a5,76(a0)
    80004198:	e99c                	sd	a5,16(a1)
}
    8000419a:	6422                	ld	s0,8(sp)
    8000419c:	0141                	addi	sp,sp,16
    8000419e:	8082                	ret

00000000800041a0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041a0:	457c                	lw	a5,76(a0)
    800041a2:	0ed7e963          	bltu	a5,a3,80004294 <readi+0xf4>
{
    800041a6:	7159                	addi	sp,sp,-112
    800041a8:	f486                	sd	ra,104(sp)
    800041aa:	f0a2                	sd	s0,96(sp)
    800041ac:	eca6                	sd	s1,88(sp)
    800041ae:	e8ca                	sd	s2,80(sp)
    800041b0:	e4ce                	sd	s3,72(sp)
    800041b2:	e0d2                	sd	s4,64(sp)
    800041b4:	fc56                	sd	s5,56(sp)
    800041b6:	f85a                	sd	s6,48(sp)
    800041b8:	f45e                	sd	s7,40(sp)
    800041ba:	f062                	sd	s8,32(sp)
    800041bc:	ec66                	sd	s9,24(sp)
    800041be:	e86a                	sd	s10,16(sp)
    800041c0:	e46e                	sd	s11,8(sp)
    800041c2:	1880                	addi	s0,sp,112
    800041c4:	8b2a                	mv	s6,a0
    800041c6:	8bae                	mv	s7,a1
    800041c8:	8a32                	mv	s4,a2
    800041ca:	84b6                	mv	s1,a3
    800041cc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800041ce:	9f35                	addw	a4,a4,a3
    return 0;
    800041d0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041d2:	0ad76063          	bltu	a4,a3,80004272 <readi+0xd2>
  if(off + n > ip->size)
    800041d6:	00e7f463          	bgeu	a5,a4,800041de <readi+0x3e>
    n = ip->size - off;
    800041da:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041de:	0a0a8963          	beqz	s5,80004290 <readi+0xf0>
    800041e2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041e4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041e8:	5c7d                	li	s8,-1
    800041ea:	a82d                	j	80004224 <readi+0x84>
    800041ec:	020d1d93          	slli	s11,s10,0x20
    800041f0:	020ddd93          	srli	s11,s11,0x20
    800041f4:	05890613          	addi	a2,s2,88
    800041f8:	86ee                	mv	a3,s11
    800041fa:	963a                	add	a2,a2,a4
    800041fc:	85d2                	mv	a1,s4
    800041fe:	855e                	mv	a0,s7
    80004200:	ffffe097          	auipc	ra,0xffffe
    80004204:	5c6080e7          	jalr	1478(ra) # 800027c6 <either_copyout>
    80004208:	05850d63          	beq	a0,s8,80004262 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000420c:	854a                	mv	a0,s2
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	5f6080e7          	jalr	1526(ra) # 80003804 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004216:	013d09bb          	addw	s3,s10,s3
    8000421a:	009d04bb          	addw	s1,s10,s1
    8000421e:	9a6e                	add	s4,s4,s11
    80004220:	0559f763          	bgeu	s3,s5,8000426e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004224:	00a4d59b          	srliw	a1,s1,0xa
    80004228:	855a                	mv	a0,s6
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	89e080e7          	jalr	-1890(ra) # 80003ac8 <bmap>
    80004232:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004236:	cd85                	beqz	a1,8000426e <readi+0xce>
    bp = bread(ip->dev, addr);
    80004238:	000b2503          	lw	a0,0(s6)
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	498080e7          	jalr	1176(ra) # 800036d4 <bread>
    80004244:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004246:	3ff4f713          	andi	a4,s1,1023
    8000424a:	40ec87bb          	subw	a5,s9,a4
    8000424e:	413a86bb          	subw	a3,s5,s3
    80004252:	8d3e                	mv	s10,a5
    80004254:	2781                	sext.w	a5,a5
    80004256:	0006861b          	sext.w	a2,a3
    8000425a:	f8f679e3          	bgeu	a2,a5,800041ec <readi+0x4c>
    8000425e:	8d36                	mv	s10,a3
    80004260:	b771                	j	800041ec <readi+0x4c>
      brelse(bp);
    80004262:	854a                	mv	a0,s2
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	5a0080e7          	jalr	1440(ra) # 80003804 <brelse>
      tot = -1;
    8000426c:	59fd                	li	s3,-1
  }
  return tot;
    8000426e:	0009851b          	sext.w	a0,s3
}
    80004272:	70a6                	ld	ra,104(sp)
    80004274:	7406                	ld	s0,96(sp)
    80004276:	64e6                	ld	s1,88(sp)
    80004278:	6946                	ld	s2,80(sp)
    8000427a:	69a6                	ld	s3,72(sp)
    8000427c:	6a06                	ld	s4,64(sp)
    8000427e:	7ae2                	ld	s5,56(sp)
    80004280:	7b42                	ld	s6,48(sp)
    80004282:	7ba2                	ld	s7,40(sp)
    80004284:	7c02                	ld	s8,32(sp)
    80004286:	6ce2                	ld	s9,24(sp)
    80004288:	6d42                	ld	s10,16(sp)
    8000428a:	6da2                	ld	s11,8(sp)
    8000428c:	6165                	addi	sp,sp,112
    8000428e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004290:	89d6                	mv	s3,s5
    80004292:	bff1                	j	8000426e <readi+0xce>
    return 0;
    80004294:	4501                	li	a0,0
}
    80004296:	8082                	ret

0000000080004298 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004298:	457c                	lw	a5,76(a0)
    8000429a:	10d7e863          	bltu	a5,a3,800043aa <writei+0x112>
{
    8000429e:	7159                	addi	sp,sp,-112
    800042a0:	f486                	sd	ra,104(sp)
    800042a2:	f0a2                	sd	s0,96(sp)
    800042a4:	eca6                	sd	s1,88(sp)
    800042a6:	e8ca                	sd	s2,80(sp)
    800042a8:	e4ce                	sd	s3,72(sp)
    800042aa:	e0d2                	sd	s4,64(sp)
    800042ac:	fc56                	sd	s5,56(sp)
    800042ae:	f85a                	sd	s6,48(sp)
    800042b0:	f45e                	sd	s7,40(sp)
    800042b2:	f062                	sd	s8,32(sp)
    800042b4:	ec66                	sd	s9,24(sp)
    800042b6:	e86a                	sd	s10,16(sp)
    800042b8:	e46e                	sd	s11,8(sp)
    800042ba:	1880                	addi	s0,sp,112
    800042bc:	8aaa                	mv	s5,a0
    800042be:	8bae                	mv	s7,a1
    800042c0:	8a32                	mv	s4,a2
    800042c2:	8936                	mv	s2,a3
    800042c4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042c6:	00e687bb          	addw	a5,a3,a4
    800042ca:	0ed7e263          	bltu	a5,a3,800043ae <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042ce:	00043737          	lui	a4,0x43
    800042d2:	0ef76063          	bltu	a4,a5,800043b2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042d6:	0c0b0863          	beqz	s6,800043a6 <writei+0x10e>
    800042da:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800042dc:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042e0:	5c7d                	li	s8,-1
    800042e2:	a091                	j	80004326 <writei+0x8e>
    800042e4:	020d1d93          	slli	s11,s10,0x20
    800042e8:	020ddd93          	srli	s11,s11,0x20
    800042ec:	05848513          	addi	a0,s1,88
    800042f0:	86ee                	mv	a3,s11
    800042f2:	8652                	mv	a2,s4
    800042f4:	85de                	mv	a1,s7
    800042f6:	953a                	add	a0,a0,a4
    800042f8:	ffffe097          	auipc	ra,0xffffe
    800042fc:	524080e7          	jalr	1316(ra) # 8000281c <either_copyin>
    80004300:	07850263          	beq	a0,s8,80004364 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004304:	8526                	mv	a0,s1
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	788080e7          	jalr	1928(ra) # 80004a8e <log_write>
    brelse(bp);
    8000430e:	8526                	mv	a0,s1
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	4f4080e7          	jalr	1268(ra) # 80003804 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004318:	013d09bb          	addw	s3,s10,s3
    8000431c:	012d093b          	addw	s2,s10,s2
    80004320:	9a6e                	add	s4,s4,s11
    80004322:	0569f663          	bgeu	s3,s6,8000436e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004326:	00a9559b          	srliw	a1,s2,0xa
    8000432a:	8556                	mv	a0,s5
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	79c080e7          	jalr	1948(ra) # 80003ac8 <bmap>
    80004334:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004338:	c99d                	beqz	a1,8000436e <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000433a:	000aa503          	lw	a0,0(s5)
    8000433e:	fffff097          	auipc	ra,0xfffff
    80004342:	396080e7          	jalr	918(ra) # 800036d4 <bread>
    80004346:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004348:	3ff97713          	andi	a4,s2,1023
    8000434c:	40ec87bb          	subw	a5,s9,a4
    80004350:	413b06bb          	subw	a3,s6,s3
    80004354:	8d3e                	mv	s10,a5
    80004356:	2781                	sext.w	a5,a5
    80004358:	0006861b          	sext.w	a2,a3
    8000435c:	f8f674e3          	bgeu	a2,a5,800042e4 <writei+0x4c>
    80004360:	8d36                	mv	s10,a3
    80004362:	b749                	j	800042e4 <writei+0x4c>
      brelse(bp);
    80004364:	8526                	mv	a0,s1
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	49e080e7          	jalr	1182(ra) # 80003804 <brelse>
  }

  if(off > ip->size)
    8000436e:	04caa783          	lw	a5,76(s5)
    80004372:	0127f463          	bgeu	a5,s2,8000437a <writei+0xe2>
    ip->size = off;
    80004376:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000437a:	8556                	mv	a0,s5
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	aa4080e7          	jalr	-1372(ra) # 80003e20 <iupdate>

  return tot;
    80004384:	0009851b          	sext.w	a0,s3
}
    80004388:	70a6                	ld	ra,104(sp)
    8000438a:	7406                	ld	s0,96(sp)
    8000438c:	64e6                	ld	s1,88(sp)
    8000438e:	6946                	ld	s2,80(sp)
    80004390:	69a6                	ld	s3,72(sp)
    80004392:	6a06                	ld	s4,64(sp)
    80004394:	7ae2                	ld	s5,56(sp)
    80004396:	7b42                	ld	s6,48(sp)
    80004398:	7ba2                	ld	s7,40(sp)
    8000439a:	7c02                	ld	s8,32(sp)
    8000439c:	6ce2                	ld	s9,24(sp)
    8000439e:	6d42                	ld	s10,16(sp)
    800043a0:	6da2                	ld	s11,8(sp)
    800043a2:	6165                	addi	sp,sp,112
    800043a4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043a6:	89da                	mv	s3,s6
    800043a8:	bfc9                	j	8000437a <writei+0xe2>
    return -1;
    800043aa:	557d                	li	a0,-1
}
    800043ac:	8082                	ret
    return -1;
    800043ae:	557d                	li	a0,-1
    800043b0:	bfe1                	j	80004388 <writei+0xf0>
    return -1;
    800043b2:	557d                	li	a0,-1
    800043b4:	bfd1                	j	80004388 <writei+0xf0>

00000000800043b6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043b6:	1141                	addi	sp,sp,-16
    800043b8:	e406                	sd	ra,8(sp)
    800043ba:	e022                	sd	s0,0(sp)
    800043bc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043be:	4639                	li	a2,14
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	9e2080e7          	jalr	-1566(ra) # 80000da2 <strncmp>
}
    800043c8:	60a2                	ld	ra,8(sp)
    800043ca:	6402                	ld	s0,0(sp)
    800043cc:	0141                	addi	sp,sp,16
    800043ce:	8082                	ret

00000000800043d0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043d0:	7139                	addi	sp,sp,-64
    800043d2:	fc06                	sd	ra,56(sp)
    800043d4:	f822                	sd	s0,48(sp)
    800043d6:	f426                	sd	s1,40(sp)
    800043d8:	f04a                	sd	s2,32(sp)
    800043da:	ec4e                	sd	s3,24(sp)
    800043dc:	e852                	sd	s4,16(sp)
    800043de:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043e0:	04451703          	lh	a4,68(a0)
    800043e4:	4785                	li	a5,1
    800043e6:	00f71a63          	bne	a4,a5,800043fa <dirlookup+0x2a>
    800043ea:	892a                	mv	s2,a0
    800043ec:	89ae                	mv	s3,a1
    800043ee:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043f0:	457c                	lw	a5,76(a0)
    800043f2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043f4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043f6:	e79d                	bnez	a5,80004424 <dirlookup+0x54>
    800043f8:	a8a5                	j	80004470 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043fa:	00004517          	auipc	a0,0x4
    800043fe:	25e50513          	addi	a0,a0,606 # 80008658 <syscalls+0x1c8>
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	13e080e7          	jalr	318(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000440a:	00004517          	auipc	a0,0x4
    8000440e:	26650513          	addi	a0,a0,614 # 80008670 <syscalls+0x1e0>
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	12e080e7          	jalr	302(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000441a:	24c1                	addiw	s1,s1,16
    8000441c:	04c92783          	lw	a5,76(s2)
    80004420:	04f4f763          	bgeu	s1,a5,8000446e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004424:	4741                	li	a4,16
    80004426:	86a6                	mv	a3,s1
    80004428:	fc040613          	addi	a2,s0,-64
    8000442c:	4581                	li	a1,0
    8000442e:	854a                	mv	a0,s2
    80004430:	00000097          	auipc	ra,0x0
    80004434:	d70080e7          	jalr	-656(ra) # 800041a0 <readi>
    80004438:	47c1                	li	a5,16
    8000443a:	fcf518e3          	bne	a0,a5,8000440a <dirlookup+0x3a>
    if(de.inum == 0)
    8000443e:	fc045783          	lhu	a5,-64(s0)
    80004442:	dfe1                	beqz	a5,8000441a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004444:	fc240593          	addi	a1,s0,-62
    80004448:	854e                	mv	a0,s3
    8000444a:	00000097          	auipc	ra,0x0
    8000444e:	f6c080e7          	jalr	-148(ra) # 800043b6 <namecmp>
    80004452:	f561                	bnez	a0,8000441a <dirlookup+0x4a>
      if(poff)
    80004454:	000a0463          	beqz	s4,8000445c <dirlookup+0x8c>
        *poff = off;
    80004458:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000445c:	fc045583          	lhu	a1,-64(s0)
    80004460:	00092503          	lw	a0,0(s2)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	74e080e7          	jalr	1870(ra) # 80003bb2 <iget>
    8000446c:	a011                	j	80004470 <dirlookup+0xa0>
  return 0;
    8000446e:	4501                	li	a0,0
}
    80004470:	70e2                	ld	ra,56(sp)
    80004472:	7442                	ld	s0,48(sp)
    80004474:	74a2                	ld	s1,40(sp)
    80004476:	7902                	ld	s2,32(sp)
    80004478:	69e2                	ld	s3,24(sp)
    8000447a:	6a42                	ld	s4,16(sp)
    8000447c:	6121                	addi	sp,sp,64
    8000447e:	8082                	ret

0000000080004480 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004480:	711d                	addi	sp,sp,-96
    80004482:	ec86                	sd	ra,88(sp)
    80004484:	e8a2                	sd	s0,80(sp)
    80004486:	e4a6                	sd	s1,72(sp)
    80004488:	e0ca                	sd	s2,64(sp)
    8000448a:	fc4e                	sd	s3,56(sp)
    8000448c:	f852                	sd	s4,48(sp)
    8000448e:	f456                	sd	s5,40(sp)
    80004490:	f05a                	sd	s6,32(sp)
    80004492:	ec5e                	sd	s7,24(sp)
    80004494:	e862                	sd	s8,16(sp)
    80004496:	e466                	sd	s9,8(sp)
    80004498:	e06a                	sd	s10,0(sp)
    8000449a:	1080                	addi	s0,sp,96
    8000449c:	84aa                	mv	s1,a0
    8000449e:	8b2e                	mv	s6,a1
    800044a0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044a2:	00054703          	lbu	a4,0(a0)
    800044a6:	02f00793          	li	a5,47
    800044aa:	02f70363          	beq	a4,a5,800044d0 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044ae:	ffffd097          	auipc	ra,0xffffd
    800044b2:	6a8080e7          	jalr	1704(ra) # 80001b56 <myproc>
    800044b6:	15053503          	ld	a0,336(a0)
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	9f4080e7          	jalr	-1548(ra) # 80003eae <idup>
    800044c2:	8a2a                	mv	s4,a0
  while(*path == '/')
    800044c4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800044c8:	4cb5                	li	s9,13
  len = path - s;
    800044ca:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044cc:	4c05                	li	s8,1
    800044ce:	a87d                	j	8000458c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800044d0:	4585                	li	a1,1
    800044d2:	4505                	li	a0,1
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	6de080e7          	jalr	1758(ra) # 80003bb2 <iget>
    800044dc:	8a2a                	mv	s4,a0
    800044de:	b7dd                	j	800044c4 <namex+0x44>
      iunlockput(ip);
    800044e0:	8552                	mv	a0,s4
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	c6c080e7          	jalr	-916(ra) # 8000414e <iunlockput>
      return 0;
    800044ea:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044ec:	8552                	mv	a0,s4
    800044ee:	60e6                	ld	ra,88(sp)
    800044f0:	6446                	ld	s0,80(sp)
    800044f2:	64a6                	ld	s1,72(sp)
    800044f4:	6906                	ld	s2,64(sp)
    800044f6:	79e2                	ld	s3,56(sp)
    800044f8:	7a42                	ld	s4,48(sp)
    800044fa:	7aa2                	ld	s5,40(sp)
    800044fc:	7b02                	ld	s6,32(sp)
    800044fe:	6be2                	ld	s7,24(sp)
    80004500:	6c42                	ld	s8,16(sp)
    80004502:	6ca2                	ld	s9,8(sp)
    80004504:	6d02                	ld	s10,0(sp)
    80004506:	6125                	addi	sp,sp,96
    80004508:	8082                	ret
      iunlock(ip);
    8000450a:	8552                	mv	a0,s4
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	aa2080e7          	jalr	-1374(ra) # 80003fae <iunlock>
      return ip;
    80004514:	bfe1                	j	800044ec <namex+0x6c>
      iunlockput(ip);
    80004516:	8552                	mv	a0,s4
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	c36080e7          	jalr	-970(ra) # 8000414e <iunlockput>
      return 0;
    80004520:	8a4e                	mv	s4,s3
    80004522:	b7e9                	j	800044ec <namex+0x6c>
  len = path - s;
    80004524:	40998633          	sub	a2,s3,s1
    80004528:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000452c:	09acd863          	bge	s9,s10,800045bc <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004530:	4639                	li	a2,14
    80004532:	85a6                	mv	a1,s1
    80004534:	8556                	mv	a0,s5
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	7f8080e7          	jalr	2040(ra) # 80000d2e <memmove>
    8000453e:	84ce                	mv	s1,s3
  while(*path == '/')
    80004540:	0004c783          	lbu	a5,0(s1)
    80004544:	01279763          	bne	a5,s2,80004552 <namex+0xd2>
    path++;
    80004548:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000454a:	0004c783          	lbu	a5,0(s1)
    8000454e:	ff278de3          	beq	a5,s2,80004548 <namex+0xc8>
    ilock(ip);
    80004552:	8552                	mv	a0,s4
    80004554:	00000097          	auipc	ra,0x0
    80004558:	998080e7          	jalr	-1640(ra) # 80003eec <ilock>
    if(ip->type != T_DIR){
    8000455c:	044a1783          	lh	a5,68(s4)
    80004560:	f98790e3          	bne	a5,s8,800044e0 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004564:	000b0563          	beqz	s6,8000456e <namex+0xee>
    80004568:	0004c783          	lbu	a5,0(s1)
    8000456c:	dfd9                	beqz	a5,8000450a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000456e:	865e                	mv	a2,s7
    80004570:	85d6                	mv	a1,s5
    80004572:	8552                	mv	a0,s4
    80004574:	00000097          	auipc	ra,0x0
    80004578:	e5c080e7          	jalr	-420(ra) # 800043d0 <dirlookup>
    8000457c:	89aa                	mv	s3,a0
    8000457e:	dd41                	beqz	a0,80004516 <namex+0x96>
    iunlockput(ip);
    80004580:	8552                	mv	a0,s4
    80004582:	00000097          	auipc	ra,0x0
    80004586:	bcc080e7          	jalr	-1076(ra) # 8000414e <iunlockput>
    ip = next;
    8000458a:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000458c:	0004c783          	lbu	a5,0(s1)
    80004590:	01279763          	bne	a5,s2,8000459e <namex+0x11e>
    path++;
    80004594:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004596:	0004c783          	lbu	a5,0(s1)
    8000459a:	ff278de3          	beq	a5,s2,80004594 <namex+0x114>
  if(*path == 0)
    8000459e:	cb9d                	beqz	a5,800045d4 <namex+0x154>
  while(*path != '/' && *path != 0)
    800045a0:	0004c783          	lbu	a5,0(s1)
    800045a4:	89a6                	mv	s3,s1
  len = path - s;
    800045a6:	8d5e                	mv	s10,s7
    800045a8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800045aa:	01278963          	beq	a5,s2,800045bc <namex+0x13c>
    800045ae:	dbbd                	beqz	a5,80004524 <namex+0xa4>
    path++;
    800045b0:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800045b2:	0009c783          	lbu	a5,0(s3)
    800045b6:	ff279ce3          	bne	a5,s2,800045ae <namex+0x12e>
    800045ba:	b7ad                	j	80004524 <namex+0xa4>
    memmove(name, s, len);
    800045bc:	2601                	sext.w	a2,a2
    800045be:	85a6                	mv	a1,s1
    800045c0:	8556                	mv	a0,s5
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	76c080e7          	jalr	1900(ra) # 80000d2e <memmove>
    name[len] = 0;
    800045ca:	9d56                	add	s10,s10,s5
    800045cc:	000d0023          	sb	zero,0(s10)
    800045d0:	84ce                	mv	s1,s3
    800045d2:	b7bd                	j	80004540 <namex+0xc0>
  if(nameiparent){
    800045d4:	f00b0ce3          	beqz	s6,800044ec <namex+0x6c>
    iput(ip);
    800045d8:	8552                	mv	a0,s4
    800045da:	00000097          	auipc	ra,0x0
    800045de:	acc080e7          	jalr	-1332(ra) # 800040a6 <iput>
    return 0;
    800045e2:	4a01                	li	s4,0
    800045e4:	b721                	j	800044ec <namex+0x6c>

00000000800045e6 <dirlink>:
{
    800045e6:	7139                	addi	sp,sp,-64
    800045e8:	fc06                	sd	ra,56(sp)
    800045ea:	f822                	sd	s0,48(sp)
    800045ec:	f426                	sd	s1,40(sp)
    800045ee:	f04a                	sd	s2,32(sp)
    800045f0:	ec4e                	sd	s3,24(sp)
    800045f2:	e852                	sd	s4,16(sp)
    800045f4:	0080                	addi	s0,sp,64
    800045f6:	892a                	mv	s2,a0
    800045f8:	8a2e                	mv	s4,a1
    800045fa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045fc:	4601                	li	a2,0
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	dd2080e7          	jalr	-558(ra) # 800043d0 <dirlookup>
    80004606:	e93d                	bnez	a0,8000467c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004608:	04c92483          	lw	s1,76(s2)
    8000460c:	c49d                	beqz	s1,8000463a <dirlink+0x54>
    8000460e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004610:	4741                	li	a4,16
    80004612:	86a6                	mv	a3,s1
    80004614:	fc040613          	addi	a2,s0,-64
    80004618:	4581                	li	a1,0
    8000461a:	854a                	mv	a0,s2
    8000461c:	00000097          	auipc	ra,0x0
    80004620:	b84080e7          	jalr	-1148(ra) # 800041a0 <readi>
    80004624:	47c1                	li	a5,16
    80004626:	06f51163          	bne	a0,a5,80004688 <dirlink+0xa2>
    if(de.inum == 0)
    8000462a:	fc045783          	lhu	a5,-64(s0)
    8000462e:	c791                	beqz	a5,8000463a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004630:	24c1                	addiw	s1,s1,16
    80004632:	04c92783          	lw	a5,76(s2)
    80004636:	fcf4ede3          	bltu	s1,a5,80004610 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000463a:	4639                	li	a2,14
    8000463c:	85d2                	mv	a1,s4
    8000463e:	fc240513          	addi	a0,s0,-62
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	79c080e7          	jalr	1948(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000464a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000464e:	4741                	li	a4,16
    80004650:	86a6                	mv	a3,s1
    80004652:	fc040613          	addi	a2,s0,-64
    80004656:	4581                	li	a1,0
    80004658:	854a                	mv	a0,s2
    8000465a:	00000097          	auipc	ra,0x0
    8000465e:	c3e080e7          	jalr	-962(ra) # 80004298 <writei>
    80004662:	1541                	addi	a0,a0,-16
    80004664:	00a03533          	snez	a0,a0
    80004668:	40a00533          	neg	a0,a0
}
    8000466c:	70e2                	ld	ra,56(sp)
    8000466e:	7442                	ld	s0,48(sp)
    80004670:	74a2                	ld	s1,40(sp)
    80004672:	7902                	ld	s2,32(sp)
    80004674:	69e2                	ld	s3,24(sp)
    80004676:	6a42                	ld	s4,16(sp)
    80004678:	6121                	addi	sp,sp,64
    8000467a:	8082                	ret
    iput(ip);
    8000467c:	00000097          	auipc	ra,0x0
    80004680:	a2a080e7          	jalr	-1494(ra) # 800040a6 <iput>
    return -1;
    80004684:	557d                	li	a0,-1
    80004686:	b7dd                	j	8000466c <dirlink+0x86>
      panic("dirlink read");
    80004688:	00004517          	auipc	a0,0x4
    8000468c:	ff850513          	addi	a0,a0,-8 # 80008680 <syscalls+0x1f0>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	eb0080e7          	jalr	-336(ra) # 80000540 <panic>

0000000080004698 <namei>:

struct inode*
namei(char *path)
{
    80004698:	1101                	addi	sp,sp,-32
    8000469a:	ec06                	sd	ra,24(sp)
    8000469c:	e822                	sd	s0,16(sp)
    8000469e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046a0:	fe040613          	addi	a2,s0,-32
    800046a4:	4581                	li	a1,0
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	dda080e7          	jalr	-550(ra) # 80004480 <namex>
}
    800046ae:	60e2                	ld	ra,24(sp)
    800046b0:	6442                	ld	s0,16(sp)
    800046b2:	6105                	addi	sp,sp,32
    800046b4:	8082                	ret

00000000800046b6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046b6:	1141                	addi	sp,sp,-16
    800046b8:	e406                	sd	ra,8(sp)
    800046ba:	e022                	sd	s0,0(sp)
    800046bc:	0800                	addi	s0,sp,16
    800046be:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046c0:	4585                	li	a1,1
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	dbe080e7          	jalr	-578(ra) # 80004480 <namex>
}
    800046ca:	60a2                	ld	ra,8(sp)
    800046cc:	6402                	ld	s0,0(sp)
    800046ce:	0141                	addi	sp,sp,16
    800046d0:	8082                	ret

00000000800046d2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046d2:	1101                	addi	sp,sp,-32
    800046d4:	ec06                	sd	ra,24(sp)
    800046d6:	e822                	sd	s0,16(sp)
    800046d8:	e426                	sd	s1,8(sp)
    800046da:	e04a                	sd	s2,0(sp)
    800046dc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046de:	0001f917          	auipc	s2,0x1f
    800046e2:	2c290913          	addi	s2,s2,706 # 800239a0 <log>
    800046e6:	01892583          	lw	a1,24(s2)
    800046ea:	02892503          	lw	a0,40(s2)
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	fe6080e7          	jalr	-26(ra) # 800036d4 <bread>
    800046f6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046f8:	02c92683          	lw	a3,44(s2)
    800046fc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046fe:	02d05863          	blez	a3,8000472e <write_head+0x5c>
    80004702:	0001f797          	auipc	a5,0x1f
    80004706:	2ce78793          	addi	a5,a5,718 # 800239d0 <log+0x30>
    8000470a:	05c50713          	addi	a4,a0,92
    8000470e:	36fd                	addiw	a3,a3,-1
    80004710:	02069613          	slli	a2,a3,0x20
    80004714:	01e65693          	srli	a3,a2,0x1e
    80004718:	0001f617          	auipc	a2,0x1f
    8000471c:	2bc60613          	addi	a2,a2,700 # 800239d4 <log+0x34>
    80004720:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004722:	4390                	lw	a2,0(a5)
    80004724:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004726:	0791                	addi	a5,a5,4
    80004728:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000472a:	fed79ce3          	bne	a5,a3,80004722 <write_head+0x50>
  }
  bwrite(buf);
    8000472e:	8526                	mv	a0,s1
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	096080e7          	jalr	150(ra) # 800037c6 <bwrite>
  brelse(buf);
    80004738:	8526                	mv	a0,s1
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	0ca080e7          	jalr	202(ra) # 80003804 <brelse>
}
    80004742:	60e2                	ld	ra,24(sp)
    80004744:	6442                	ld	s0,16(sp)
    80004746:	64a2                	ld	s1,8(sp)
    80004748:	6902                	ld	s2,0(sp)
    8000474a:	6105                	addi	sp,sp,32
    8000474c:	8082                	ret

000000008000474e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000474e:	0001f797          	auipc	a5,0x1f
    80004752:	27e7a783          	lw	a5,638(a5) # 800239cc <log+0x2c>
    80004756:	0af05d63          	blez	a5,80004810 <install_trans+0xc2>
{
    8000475a:	7139                	addi	sp,sp,-64
    8000475c:	fc06                	sd	ra,56(sp)
    8000475e:	f822                	sd	s0,48(sp)
    80004760:	f426                	sd	s1,40(sp)
    80004762:	f04a                	sd	s2,32(sp)
    80004764:	ec4e                	sd	s3,24(sp)
    80004766:	e852                	sd	s4,16(sp)
    80004768:	e456                	sd	s5,8(sp)
    8000476a:	e05a                	sd	s6,0(sp)
    8000476c:	0080                	addi	s0,sp,64
    8000476e:	8b2a                	mv	s6,a0
    80004770:	0001fa97          	auipc	s5,0x1f
    80004774:	260a8a93          	addi	s5,s5,608 # 800239d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004778:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000477a:	0001f997          	auipc	s3,0x1f
    8000477e:	22698993          	addi	s3,s3,550 # 800239a0 <log>
    80004782:	a00d                	j	800047a4 <install_trans+0x56>
    brelse(lbuf);
    80004784:	854a                	mv	a0,s2
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	07e080e7          	jalr	126(ra) # 80003804 <brelse>
    brelse(dbuf);
    8000478e:	8526                	mv	a0,s1
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	074080e7          	jalr	116(ra) # 80003804 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004798:	2a05                	addiw	s4,s4,1
    8000479a:	0a91                	addi	s5,s5,4
    8000479c:	02c9a783          	lw	a5,44(s3)
    800047a0:	04fa5e63          	bge	s4,a5,800047fc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047a4:	0189a583          	lw	a1,24(s3)
    800047a8:	014585bb          	addw	a1,a1,s4
    800047ac:	2585                	addiw	a1,a1,1
    800047ae:	0289a503          	lw	a0,40(s3)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	f22080e7          	jalr	-222(ra) # 800036d4 <bread>
    800047ba:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047bc:	000aa583          	lw	a1,0(s5)
    800047c0:	0289a503          	lw	a0,40(s3)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	f10080e7          	jalr	-240(ra) # 800036d4 <bread>
    800047cc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047ce:	40000613          	li	a2,1024
    800047d2:	05890593          	addi	a1,s2,88
    800047d6:	05850513          	addi	a0,a0,88
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	554080e7          	jalr	1364(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800047e2:	8526                	mv	a0,s1
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	fe2080e7          	jalr	-30(ra) # 800037c6 <bwrite>
    if(recovering == 0)
    800047ec:	f80b1ce3          	bnez	s6,80004784 <install_trans+0x36>
      bunpin(dbuf);
    800047f0:	8526                	mv	a0,s1
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	0ec080e7          	jalr	236(ra) # 800038de <bunpin>
    800047fa:	b769                	j	80004784 <install_trans+0x36>
}
    800047fc:	70e2                	ld	ra,56(sp)
    800047fe:	7442                	ld	s0,48(sp)
    80004800:	74a2                	ld	s1,40(sp)
    80004802:	7902                	ld	s2,32(sp)
    80004804:	69e2                	ld	s3,24(sp)
    80004806:	6a42                	ld	s4,16(sp)
    80004808:	6aa2                	ld	s5,8(sp)
    8000480a:	6b02                	ld	s6,0(sp)
    8000480c:	6121                	addi	sp,sp,64
    8000480e:	8082                	ret
    80004810:	8082                	ret

0000000080004812 <initlog>:
{
    80004812:	7179                	addi	sp,sp,-48
    80004814:	f406                	sd	ra,40(sp)
    80004816:	f022                	sd	s0,32(sp)
    80004818:	ec26                	sd	s1,24(sp)
    8000481a:	e84a                	sd	s2,16(sp)
    8000481c:	e44e                	sd	s3,8(sp)
    8000481e:	1800                	addi	s0,sp,48
    80004820:	892a                	mv	s2,a0
    80004822:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004824:	0001f497          	auipc	s1,0x1f
    80004828:	17c48493          	addi	s1,s1,380 # 800239a0 <log>
    8000482c:	00004597          	auipc	a1,0x4
    80004830:	e6458593          	addi	a1,a1,-412 # 80008690 <syscalls+0x200>
    80004834:	8526                	mv	a0,s1
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	310080e7          	jalr	784(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000483e:	0149a583          	lw	a1,20(s3)
    80004842:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004844:	0109a783          	lw	a5,16(s3)
    80004848:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000484a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000484e:	854a                	mv	a0,s2
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	e84080e7          	jalr	-380(ra) # 800036d4 <bread>
  log.lh.n = lh->n;
    80004858:	4d34                	lw	a3,88(a0)
    8000485a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000485c:	02d05663          	blez	a3,80004888 <initlog+0x76>
    80004860:	05c50793          	addi	a5,a0,92
    80004864:	0001f717          	auipc	a4,0x1f
    80004868:	16c70713          	addi	a4,a4,364 # 800239d0 <log+0x30>
    8000486c:	36fd                	addiw	a3,a3,-1
    8000486e:	02069613          	slli	a2,a3,0x20
    80004872:	01e65693          	srli	a3,a2,0x1e
    80004876:	06050613          	addi	a2,a0,96
    8000487a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000487c:	4390                	lw	a2,0(a5)
    8000487e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004880:	0791                	addi	a5,a5,4
    80004882:	0711                	addi	a4,a4,4
    80004884:	fed79ce3          	bne	a5,a3,8000487c <initlog+0x6a>
  brelse(buf);
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	f7c080e7          	jalr	-132(ra) # 80003804 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004890:	4505                	li	a0,1
    80004892:	00000097          	auipc	ra,0x0
    80004896:	ebc080e7          	jalr	-324(ra) # 8000474e <install_trans>
  log.lh.n = 0;
    8000489a:	0001f797          	auipc	a5,0x1f
    8000489e:	1207a923          	sw	zero,306(a5) # 800239cc <log+0x2c>
  write_head(); // clear the log
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	e30080e7          	jalr	-464(ra) # 800046d2 <write_head>
}
    800048aa:	70a2                	ld	ra,40(sp)
    800048ac:	7402                	ld	s0,32(sp)
    800048ae:	64e2                	ld	s1,24(sp)
    800048b0:	6942                	ld	s2,16(sp)
    800048b2:	69a2                	ld	s3,8(sp)
    800048b4:	6145                	addi	sp,sp,48
    800048b6:	8082                	ret

00000000800048b8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048b8:	1101                	addi	sp,sp,-32
    800048ba:	ec06                	sd	ra,24(sp)
    800048bc:	e822                	sd	s0,16(sp)
    800048be:	e426                	sd	s1,8(sp)
    800048c0:	e04a                	sd	s2,0(sp)
    800048c2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048c4:	0001f517          	auipc	a0,0x1f
    800048c8:	0dc50513          	addi	a0,a0,220 # 800239a0 <log>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	30a080e7          	jalr	778(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800048d4:	0001f497          	auipc	s1,0x1f
    800048d8:	0cc48493          	addi	s1,s1,204 # 800239a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048dc:	4979                	li	s2,30
    800048de:	a039                	j	800048ec <begin_op+0x34>
      sleep(&log, &log.lock);
    800048e0:	85a6                	mv	a1,s1
    800048e2:	8526                	mv	a0,s1
    800048e4:	ffffe097          	auipc	ra,0xffffe
    800048e8:	aa6080e7          	jalr	-1370(ra) # 8000238a <sleep>
    if(log.committing){
    800048ec:	50dc                	lw	a5,36(s1)
    800048ee:	fbed                	bnez	a5,800048e0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048f0:	5098                	lw	a4,32(s1)
    800048f2:	2705                	addiw	a4,a4,1
    800048f4:	0007069b          	sext.w	a3,a4
    800048f8:	0027179b          	slliw	a5,a4,0x2
    800048fc:	9fb9                	addw	a5,a5,a4
    800048fe:	0017979b          	slliw	a5,a5,0x1
    80004902:	54d8                	lw	a4,44(s1)
    80004904:	9fb9                	addw	a5,a5,a4
    80004906:	00f95963          	bge	s2,a5,80004918 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000490a:	85a6                	mv	a1,s1
    8000490c:	8526                	mv	a0,s1
    8000490e:	ffffe097          	auipc	ra,0xffffe
    80004912:	a7c080e7          	jalr	-1412(ra) # 8000238a <sleep>
    80004916:	bfd9                	j	800048ec <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004918:	0001f517          	auipc	a0,0x1f
    8000491c:	08850513          	addi	a0,a0,136 # 800239a0 <log>
    80004920:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	368080e7          	jalr	872(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000492a:	60e2                	ld	ra,24(sp)
    8000492c:	6442                	ld	s0,16(sp)
    8000492e:	64a2                	ld	s1,8(sp)
    80004930:	6902                	ld	s2,0(sp)
    80004932:	6105                	addi	sp,sp,32
    80004934:	8082                	ret

0000000080004936 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004936:	7139                	addi	sp,sp,-64
    80004938:	fc06                	sd	ra,56(sp)
    8000493a:	f822                	sd	s0,48(sp)
    8000493c:	f426                	sd	s1,40(sp)
    8000493e:	f04a                	sd	s2,32(sp)
    80004940:	ec4e                	sd	s3,24(sp)
    80004942:	e852                	sd	s4,16(sp)
    80004944:	e456                	sd	s5,8(sp)
    80004946:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004948:	0001f497          	auipc	s1,0x1f
    8000494c:	05848493          	addi	s1,s1,88 # 800239a0 <log>
    80004950:	8526                	mv	a0,s1
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	284080e7          	jalr	644(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000495a:	509c                	lw	a5,32(s1)
    8000495c:	37fd                	addiw	a5,a5,-1
    8000495e:	0007891b          	sext.w	s2,a5
    80004962:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004964:	50dc                	lw	a5,36(s1)
    80004966:	e7b9                	bnez	a5,800049b4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004968:	04091e63          	bnez	s2,800049c4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000496c:	0001f497          	auipc	s1,0x1f
    80004970:	03448493          	addi	s1,s1,52 # 800239a0 <log>
    80004974:	4785                	li	a5,1
    80004976:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004978:	8526                	mv	a0,s1
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	310080e7          	jalr	784(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004982:	54dc                	lw	a5,44(s1)
    80004984:	06f04763          	bgtz	a5,800049f2 <end_op+0xbc>
    acquire(&log.lock);
    80004988:	0001f497          	auipc	s1,0x1f
    8000498c:	01848493          	addi	s1,s1,24 # 800239a0 <log>
    80004990:	8526                	mv	a0,s1
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	244080e7          	jalr	580(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000499a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000499e:	8526                	mv	a0,s1
    800049a0:	ffffe097          	auipc	ra,0xffffe
    800049a4:	a4e080e7          	jalr	-1458(ra) # 800023ee <wakeup>
    release(&log.lock);
    800049a8:	8526                	mv	a0,s1
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	2e0080e7          	jalr	736(ra) # 80000c8a <release>
}
    800049b2:	a03d                	j	800049e0 <end_op+0xaa>
    panic("log.committing");
    800049b4:	00004517          	auipc	a0,0x4
    800049b8:	ce450513          	addi	a0,a0,-796 # 80008698 <syscalls+0x208>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	b84080e7          	jalr	-1148(ra) # 80000540 <panic>
    wakeup(&log);
    800049c4:	0001f497          	auipc	s1,0x1f
    800049c8:	fdc48493          	addi	s1,s1,-36 # 800239a0 <log>
    800049cc:	8526                	mv	a0,s1
    800049ce:	ffffe097          	auipc	ra,0xffffe
    800049d2:	a20080e7          	jalr	-1504(ra) # 800023ee <wakeup>
  release(&log.lock);
    800049d6:	8526                	mv	a0,s1
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800049e0:	70e2                	ld	ra,56(sp)
    800049e2:	7442                	ld	s0,48(sp)
    800049e4:	74a2                	ld	s1,40(sp)
    800049e6:	7902                	ld	s2,32(sp)
    800049e8:	69e2                	ld	s3,24(sp)
    800049ea:	6a42                	ld	s4,16(sp)
    800049ec:	6aa2                	ld	s5,8(sp)
    800049ee:	6121                	addi	sp,sp,64
    800049f0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800049f2:	0001fa97          	auipc	s5,0x1f
    800049f6:	fdea8a93          	addi	s5,s5,-34 # 800239d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049fa:	0001fa17          	auipc	s4,0x1f
    800049fe:	fa6a0a13          	addi	s4,s4,-90 # 800239a0 <log>
    80004a02:	018a2583          	lw	a1,24(s4)
    80004a06:	012585bb          	addw	a1,a1,s2
    80004a0a:	2585                	addiw	a1,a1,1
    80004a0c:	028a2503          	lw	a0,40(s4)
    80004a10:	fffff097          	auipc	ra,0xfffff
    80004a14:	cc4080e7          	jalr	-828(ra) # 800036d4 <bread>
    80004a18:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a1a:	000aa583          	lw	a1,0(s5)
    80004a1e:	028a2503          	lw	a0,40(s4)
    80004a22:	fffff097          	auipc	ra,0xfffff
    80004a26:	cb2080e7          	jalr	-846(ra) # 800036d4 <bread>
    80004a2a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a2c:	40000613          	li	a2,1024
    80004a30:	05850593          	addi	a1,a0,88
    80004a34:	05848513          	addi	a0,s1,88
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	2f6080e7          	jalr	758(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004a40:	8526                	mv	a0,s1
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	d84080e7          	jalr	-636(ra) # 800037c6 <bwrite>
    brelse(from);
    80004a4a:	854e                	mv	a0,s3
    80004a4c:	fffff097          	auipc	ra,0xfffff
    80004a50:	db8080e7          	jalr	-584(ra) # 80003804 <brelse>
    brelse(to);
    80004a54:	8526                	mv	a0,s1
    80004a56:	fffff097          	auipc	ra,0xfffff
    80004a5a:	dae080e7          	jalr	-594(ra) # 80003804 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a5e:	2905                	addiw	s2,s2,1
    80004a60:	0a91                	addi	s5,s5,4
    80004a62:	02ca2783          	lw	a5,44(s4)
    80004a66:	f8f94ee3          	blt	s2,a5,80004a02 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a6a:	00000097          	auipc	ra,0x0
    80004a6e:	c68080e7          	jalr	-920(ra) # 800046d2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a72:	4501                	li	a0,0
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	cda080e7          	jalr	-806(ra) # 8000474e <install_trans>
    log.lh.n = 0;
    80004a7c:	0001f797          	auipc	a5,0x1f
    80004a80:	f407a823          	sw	zero,-176(a5) # 800239cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	c4e080e7          	jalr	-946(ra) # 800046d2 <write_head>
    80004a8c:	bdf5                	j	80004988 <end_op+0x52>

0000000080004a8e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a8e:	1101                	addi	sp,sp,-32
    80004a90:	ec06                	sd	ra,24(sp)
    80004a92:	e822                	sd	s0,16(sp)
    80004a94:	e426                	sd	s1,8(sp)
    80004a96:	e04a                	sd	s2,0(sp)
    80004a98:	1000                	addi	s0,sp,32
    80004a9a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a9c:	0001f917          	auipc	s2,0x1f
    80004aa0:	f0490913          	addi	s2,s2,-252 # 800239a0 <log>
    80004aa4:	854a                	mv	a0,s2
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	130080e7          	jalr	304(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004aae:	02c92603          	lw	a2,44(s2)
    80004ab2:	47f5                	li	a5,29
    80004ab4:	06c7c563          	blt	a5,a2,80004b1e <log_write+0x90>
    80004ab8:	0001f797          	auipc	a5,0x1f
    80004abc:	f047a783          	lw	a5,-252(a5) # 800239bc <log+0x1c>
    80004ac0:	37fd                	addiw	a5,a5,-1
    80004ac2:	04f65e63          	bge	a2,a5,80004b1e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ac6:	0001f797          	auipc	a5,0x1f
    80004aca:	efa7a783          	lw	a5,-262(a5) # 800239c0 <log+0x20>
    80004ace:	06f05063          	blez	a5,80004b2e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ad2:	4781                	li	a5,0
    80004ad4:	06c05563          	blez	a2,80004b3e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ad8:	44cc                	lw	a1,12(s1)
    80004ada:	0001f717          	auipc	a4,0x1f
    80004ade:	ef670713          	addi	a4,a4,-266 # 800239d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ae2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ae4:	4314                	lw	a3,0(a4)
    80004ae6:	04b68c63          	beq	a3,a1,80004b3e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004aea:	2785                	addiw	a5,a5,1
    80004aec:	0711                	addi	a4,a4,4
    80004aee:	fef61be3          	bne	a2,a5,80004ae4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004af2:	0621                	addi	a2,a2,8
    80004af4:	060a                	slli	a2,a2,0x2
    80004af6:	0001f797          	auipc	a5,0x1f
    80004afa:	eaa78793          	addi	a5,a5,-342 # 800239a0 <log>
    80004afe:	97b2                	add	a5,a5,a2
    80004b00:	44d8                	lw	a4,12(s1)
    80004b02:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b04:	8526                	mv	a0,s1
    80004b06:	fffff097          	auipc	ra,0xfffff
    80004b0a:	d9c080e7          	jalr	-612(ra) # 800038a2 <bpin>
    log.lh.n++;
    80004b0e:	0001f717          	auipc	a4,0x1f
    80004b12:	e9270713          	addi	a4,a4,-366 # 800239a0 <log>
    80004b16:	575c                	lw	a5,44(a4)
    80004b18:	2785                	addiw	a5,a5,1
    80004b1a:	d75c                	sw	a5,44(a4)
    80004b1c:	a82d                	j	80004b56 <log_write+0xc8>
    panic("too big a transaction");
    80004b1e:	00004517          	auipc	a0,0x4
    80004b22:	b8a50513          	addi	a0,a0,-1142 # 800086a8 <syscalls+0x218>
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	a1a080e7          	jalr	-1510(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004b2e:	00004517          	auipc	a0,0x4
    80004b32:	b9250513          	addi	a0,a0,-1134 # 800086c0 <syscalls+0x230>
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	a0a080e7          	jalr	-1526(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004b3e:	00878693          	addi	a3,a5,8
    80004b42:	068a                	slli	a3,a3,0x2
    80004b44:	0001f717          	auipc	a4,0x1f
    80004b48:	e5c70713          	addi	a4,a4,-420 # 800239a0 <log>
    80004b4c:	9736                	add	a4,a4,a3
    80004b4e:	44d4                	lw	a3,12(s1)
    80004b50:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b52:	faf609e3          	beq	a2,a5,80004b04 <log_write+0x76>
  }
  release(&log.lock);
    80004b56:	0001f517          	auipc	a0,0x1f
    80004b5a:	e4a50513          	addi	a0,a0,-438 # 800239a0 <log>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	12c080e7          	jalr	300(ra) # 80000c8a <release>
}
    80004b66:	60e2                	ld	ra,24(sp)
    80004b68:	6442                	ld	s0,16(sp)
    80004b6a:	64a2                	ld	s1,8(sp)
    80004b6c:	6902                	ld	s2,0(sp)
    80004b6e:	6105                	addi	sp,sp,32
    80004b70:	8082                	ret

0000000080004b72 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b72:	1101                	addi	sp,sp,-32
    80004b74:	ec06                	sd	ra,24(sp)
    80004b76:	e822                	sd	s0,16(sp)
    80004b78:	e426                	sd	s1,8(sp)
    80004b7a:	e04a                	sd	s2,0(sp)
    80004b7c:	1000                	addi	s0,sp,32
    80004b7e:	84aa                	mv	s1,a0
    80004b80:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b82:	00004597          	auipc	a1,0x4
    80004b86:	b5e58593          	addi	a1,a1,-1186 # 800086e0 <syscalls+0x250>
    80004b8a:	0521                	addi	a0,a0,8
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	fba080e7          	jalr	-70(ra) # 80000b46 <initlock>
  lk->name = name;
    80004b94:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b98:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b9c:	0204a423          	sw	zero,40(s1)
}
    80004ba0:	60e2                	ld	ra,24(sp)
    80004ba2:	6442                	ld	s0,16(sp)
    80004ba4:	64a2                	ld	s1,8(sp)
    80004ba6:	6902                	ld	s2,0(sp)
    80004ba8:	6105                	addi	sp,sp,32
    80004baa:	8082                	ret

0000000080004bac <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004bac:	1101                	addi	sp,sp,-32
    80004bae:	ec06                	sd	ra,24(sp)
    80004bb0:	e822                	sd	s0,16(sp)
    80004bb2:	e426                	sd	s1,8(sp)
    80004bb4:	e04a                	sd	s2,0(sp)
    80004bb6:	1000                	addi	s0,sp,32
    80004bb8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bba:	00850913          	addi	s2,a0,8
    80004bbe:	854a                	mv	a0,s2
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	016080e7          	jalr	22(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004bc8:	409c                	lw	a5,0(s1)
    80004bca:	cb89                	beqz	a5,80004bdc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bcc:	85ca                	mv	a1,s2
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffd097          	auipc	ra,0xffffd
    80004bd4:	7ba080e7          	jalr	1978(ra) # 8000238a <sleep>
  while (lk->locked) {
    80004bd8:	409c                	lw	a5,0(s1)
    80004bda:	fbed                	bnez	a5,80004bcc <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bdc:	4785                	li	a5,1
    80004bde:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	f76080e7          	jalr	-138(ra) # 80001b56 <myproc>
    80004be8:	591c                	lw	a5,48(a0)
    80004bea:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bec:	854a                	mv	a0,s2
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
}
    80004bf6:	60e2                	ld	ra,24(sp)
    80004bf8:	6442                	ld	s0,16(sp)
    80004bfa:	64a2                	ld	s1,8(sp)
    80004bfc:	6902                	ld	s2,0(sp)
    80004bfe:	6105                	addi	sp,sp,32
    80004c00:	8082                	ret

0000000080004c02 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c02:	1101                	addi	sp,sp,-32
    80004c04:	ec06                	sd	ra,24(sp)
    80004c06:	e822                	sd	s0,16(sp)
    80004c08:	e426                	sd	s1,8(sp)
    80004c0a:	e04a                	sd	s2,0(sp)
    80004c0c:	1000                	addi	s0,sp,32
    80004c0e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c10:	00850913          	addi	s2,a0,8
    80004c14:	854a                	mv	a0,s2
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	fc0080e7          	jalr	-64(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004c1e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c22:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c26:	8526                	mv	a0,s1
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	7c6080e7          	jalr	1990(ra) # 800023ee <wakeup>
  release(&lk->lk);
    80004c30:	854a                	mv	a0,s2
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	058080e7          	jalr	88(ra) # 80000c8a <release>
}
    80004c3a:	60e2                	ld	ra,24(sp)
    80004c3c:	6442                	ld	s0,16(sp)
    80004c3e:	64a2                	ld	s1,8(sp)
    80004c40:	6902                	ld	s2,0(sp)
    80004c42:	6105                	addi	sp,sp,32
    80004c44:	8082                	ret

0000000080004c46 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c46:	7179                	addi	sp,sp,-48
    80004c48:	f406                	sd	ra,40(sp)
    80004c4a:	f022                	sd	s0,32(sp)
    80004c4c:	ec26                	sd	s1,24(sp)
    80004c4e:	e84a                	sd	s2,16(sp)
    80004c50:	e44e                	sd	s3,8(sp)
    80004c52:	1800                	addi	s0,sp,48
    80004c54:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c56:	00850913          	addi	s2,a0,8
    80004c5a:	854a                	mv	a0,s2
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	f7a080e7          	jalr	-134(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c64:	409c                	lw	a5,0(s1)
    80004c66:	ef99                	bnez	a5,80004c84 <holdingsleep+0x3e>
    80004c68:	4481                	li	s1,0
  release(&lk->lk);
    80004c6a:	854a                	mv	a0,s2
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	01e080e7          	jalr	30(ra) # 80000c8a <release>
  return r;
}
    80004c74:	8526                	mv	a0,s1
    80004c76:	70a2                	ld	ra,40(sp)
    80004c78:	7402                	ld	s0,32(sp)
    80004c7a:	64e2                	ld	s1,24(sp)
    80004c7c:	6942                	ld	s2,16(sp)
    80004c7e:	69a2                	ld	s3,8(sp)
    80004c80:	6145                	addi	sp,sp,48
    80004c82:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c84:	0284a983          	lw	s3,40(s1)
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	ece080e7          	jalr	-306(ra) # 80001b56 <myproc>
    80004c90:	5904                	lw	s1,48(a0)
    80004c92:	413484b3          	sub	s1,s1,s3
    80004c96:	0014b493          	seqz	s1,s1
    80004c9a:	bfc1                	j	80004c6a <holdingsleep+0x24>

0000000080004c9c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c9c:	1141                	addi	sp,sp,-16
    80004c9e:	e406                	sd	ra,8(sp)
    80004ca0:	e022                	sd	s0,0(sp)
    80004ca2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ca4:	00004597          	auipc	a1,0x4
    80004ca8:	a4c58593          	addi	a1,a1,-1460 # 800086f0 <syscalls+0x260>
    80004cac:	0001f517          	auipc	a0,0x1f
    80004cb0:	e3c50513          	addi	a0,a0,-452 # 80023ae8 <ftable>
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	e92080e7          	jalr	-366(ra) # 80000b46 <initlock>
}
    80004cbc:	60a2                	ld	ra,8(sp)
    80004cbe:	6402                	ld	s0,0(sp)
    80004cc0:	0141                	addi	sp,sp,16
    80004cc2:	8082                	ret

0000000080004cc4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cc4:	1101                	addi	sp,sp,-32
    80004cc6:	ec06                	sd	ra,24(sp)
    80004cc8:	e822                	sd	s0,16(sp)
    80004cca:	e426                	sd	s1,8(sp)
    80004ccc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cce:	0001f517          	auipc	a0,0x1f
    80004cd2:	e1a50513          	addi	a0,a0,-486 # 80023ae8 <ftable>
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	f00080e7          	jalr	-256(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cde:	0001f497          	auipc	s1,0x1f
    80004ce2:	e2248493          	addi	s1,s1,-478 # 80023b00 <ftable+0x18>
    80004ce6:	00020717          	auipc	a4,0x20
    80004cea:	dba70713          	addi	a4,a4,-582 # 80024aa0 <disk>
    if(f->ref == 0){
    80004cee:	40dc                	lw	a5,4(s1)
    80004cf0:	cf99                	beqz	a5,80004d0e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cf2:	02848493          	addi	s1,s1,40
    80004cf6:	fee49ce3          	bne	s1,a4,80004cee <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cfa:	0001f517          	auipc	a0,0x1f
    80004cfe:	dee50513          	addi	a0,a0,-530 # 80023ae8 <ftable>
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	f88080e7          	jalr	-120(ra) # 80000c8a <release>
  return 0;
    80004d0a:	4481                	li	s1,0
    80004d0c:	a819                	j	80004d22 <filealloc+0x5e>
      f->ref = 1;
    80004d0e:	4785                	li	a5,1
    80004d10:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d12:	0001f517          	auipc	a0,0x1f
    80004d16:	dd650513          	addi	a0,a0,-554 # 80023ae8 <ftable>
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	f70080e7          	jalr	-144(ra) # 80000c8a <release>
}
    80004d22:	8526                	mv	a0,s1
    80004d24:	60e2                	ld	ra,24(sp)
    80004d26:	6442                	ld	s0,16(sp)
    80004d28:	64a2                	ld	s1,8(sp)
    80004d2a:	6105                	addi	sp,sp,32
    80004d2c:	8082                	ret

0000000080004d2e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d2e:	1101                	addi	sp,sp,-32
    80004d30:	ec06                	sd	ra,24(sp)
    80004d32:	e822                	sd	s0,16(sp)
    80004d34:	e426                	sd	s1,8(sp)
    80004d36:	1000                	addi	s0,sp,32
    80004d38:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d3a:	0001f517          	auipc	a0,0x1f
    80004d3e:	dae50513          	addi	a0,a0,-594 # 80023ae8 <ftable>
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	e94080e7          	jalr	-364(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004d4a:	40dc                	lw	a5,4(s1)
    80004d4c:	02f05263          	blez	a5,80004d70 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d50:	2785                	addiw	a5,a5,1
    80004d52:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d54:	0001f517          	auipc	a0,0x1f
    80004d58:	d9450513          	addi	a0,a0,-620 # 80023ae8 <ftable>
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	f2e080e7          	jalr	-210(ra) # 80000c8a <release>
  return f;
}
    80004d64:	8526                	mv	a0,s1
    80004d66:	60e2                	ld	ra,24(sp)
    80004d68:	6442                	ld	s0,16(sp)
    80004d6a:	64a2                	ld	s1,8(sp)
    80004d6c:	6105                	addi	sp,sp,32
    80004d6e:	8082                	ret
    panic("filedup");
    80004d70:	00004517          	auipc	a0,0x4
    80004d74:	98850513          	addi	a0,a0,-1656 # 800086f8 <syscalls+0x268>
    80004d78:	ffffb097          	auipc	ra,0xffffb
    80004d7c:	7c8080e7          	jalr	1992(ra) # 80000540 <panic>

0000000080004d80 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d80:	7139                	addi	sp,sp,-64
    80004d82:	fc06                	sd	ra,56(sp)
    80004d84:	f822                	sd	s0,48(sp)
    80004d86:	f426                	sd	s1,40(sp)
    80004d88:	f04a                	sd	s2,32(sp)
    80004d8a:	ec4e                	sd	s3,24(sp)
    80004d8c:	e852                	sd	s4,16(sp)
    80004d8e:	e456                	sd	s5,8(sp)
    80004d90:	0080                	addi	s0,sp,64
    80004d92:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d94:	0001f517          	auipc	a0,0x1f
    80004d98:	d5450513          	addi	a0,a0,-684 # 80023ae8 <ftable>
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	e3a080e7          	jalr	-454(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004da4:	40dc                	lw	a5,4(s1)
    80004da6:	06f05163          	blez	a5,80004e08 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004daa:	37fd                	addiw	a5,a5,-1
    80004dac:	0007871b          	sext.w	a4,a5
    80004db0:	c0dc                	sw	a5,4(s1)
    80004db2:	06e04363          	bgtz	a4,80004e18 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004db6:	0004a903          	lw	s2,0(s1)
    80004dba:	0094ca83          	lbu	s5,9(s1)
    80004dbe:	0104ba03          	ld	s4,16(s1)
    80004dc2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dc6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dca:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004dce:	0001f517          	auipc	a0,0x1f
    80004dd2:	d1a50513          	addi	a0,a0,-742 # 80023ae8 <ftable>
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	eb4080e7          	jalr	-332(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004dde:	4785                	li	a5,1
    80004de0:	04f90d63          	beq	s2,a5,80004e3a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004de4:	3979                	addiw	s2,s2,-2
    80004de6:	4785                	li	a5,1
    80004de8:	0527e063          	bltu	a5,s2,80004e28 <fileclose+0xa8>
    begin_op();
    80004dec:	00000097          	auipc	ra,0x0
    80004df0:	acc080e7          	jalr	-1332(ra) # 800048b8 <begin_op>
    iput(ff.ip);
    80004df4:	854e                	mv	a0,s3
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	2b0080e7          	jalr	688(ra) # 800040a6 <iput>
    end_op();
    80004dfe:	00000097          	auipc	ra,0x0
    80004e02:	b38080e7          	jalr	-1224(ra) # 80004936 <end_op>
    80004e06:	a00d                	j	80004e28 <fileclose+0xa8>
    panic("fileclose");
    80004e08:	00004517          	auipc	a0,0x4
    80004e0c:	8f850513          	addi	a0,a0,-1800 # 80008700 <syscalls+0x270>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	730080e7          	jalr	1840(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004e18:	0001f517          	auipc	a0,0x1f
    80004e1c:	cd050513          	addi	a0,a0,-816 # 80023ae8 <ftable>
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	e6a080e7          	jalr	-406(ra) # 80000c8a <release>
  }
}
    80004e28:	70e2                	ld	ra,56(sp)
    80004e2a:	7442                	ld	s0,48(sp)
    80004e2c:	74a2                	ld	s1,40(sp)
    80004e2e:	7902                	ld	s2,32(sp)
    80004e30:	69e2                	ld	s3,24(sp)
    80004e32:	6a42                	ld	s4,16(sp)
    80004e34:	6aa2                	ld	s5,8(sp)
    80004e36:	6121                	addi	sp,sp,64
    80004e38:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e3a:	85d6                	mv	a1,s5
    80004e3c:	8552                	mv	a0,s4
    80004e3e:	00000097          	auipc	ra,0x0
    80004e42:	34c080e7          	jalr	844(ra) # 8000518a <pipeclose>
    80004e46:	b7cd                	j	80004e28 <fileclose+0xa8>

0000000080004e48 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e48:	715d                	addi	sp,sp,-80
    80004e4a:	e486                	sd	ra,72(sp)
    80004e4c:	e0a2                	sd	s0,64(sp)
    80004e4e:	fc26                	sd	s1,56(sp)
    80004e50:	f84a                	sd	s2,48(sp)
    80004e52:	f44e                	sd	s3,40(sp)
    80004e54:	0880                	addi	s0,sp,80
    80004e56:	84aa                	mv	s1,a0
    80004e58:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	cfc080e7          	jalr	-772(ra) # 80001b56 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e62:	409c                	lw	a5,0(s1)
    80004e64:	37f9                	addiw	a5,a5,-2
    80004e66:	4705                	li	a4,1
    80004e68:	04f76763          	bltu	a4,a5,80004eb6 <filestat+0x6e>
    80004e6c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e6e:	6c88                	ld	a0,24(s1)
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	07c080e7          	jalr	124(ra) # 80003eec <ilock>
    stati(f->ip, &st);
    80004e78:	fb840593          	addi	a1,s0,-72
    80004e7c:	6c88                	ld	a0,24(s1)
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	2f8080e7          	jalr	760(ra) # 80004176 <stati>
    iunlock(f->ip);
    80004e86:	6c88                	ld	a0,24(s1)
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	126080e7          	jalr	294(ra) # 80003fae <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e90:	46e1                	li	a3,24
    80004e92:	fb840613          	addi	a2,s0,-72
    80004e96:	85ce                	mv	a1,s3
    80004e98:	05093503          	ld	a0,80(s2)
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	7d0080e7          	jalr	2000(ra) # 8000166c <copyout>
    80004ea4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ea8:	60a6                	ld	ra,72(sp)
    80004eaa:	6406                	ld	s0,64(sp)
    80004eac:	74e2                	ld	s1,56(sp)
    80004eae:	7942                	ld	s2,48(sp)
    80004eb0:	79a2                	ld	s3,40(sp)
    80004eb2:	6161                	addi	sp,sp,80
    80004eb4:	8082                	ret
  return -1;
    80004eb6:	557d                	li	a0,-1
    80004eb8:	bfc5                	j	80004ea8 <filestat+0x60>

0000000080004eba <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004eba:	7179                	addi	sp,sp,-48
    80004ebc:	f406                	sd	ra,40(sp)
    80004ebe:	f022                	sd	s0,32(sp)
    80004ec0:	ec26                	sd	s1,24(sp)
    80004ec2:	e84a                	sd	s2,16(sp)
    80004ec4:	e44e                	sd	s3,8(sp)
    80004ec6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ec8:	00854783          	lbu	a5,8(a0)
    80004ecc:	c3d5                	beqz	a5,80004f70 <fileread+0xb6>
    80004ece:	84aa                	mv	s1,a0
    80004ed0:	89ae                	mv	s3,a1
    80004ed2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ed4:	411c                	lw	a5,0(a0)
    80004ed6:	4705                	li	a4,1
    80004ed8:	04e78963          	beq	a5,a4,80004f2a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004edc:	470d                	li	a4,3
    80004ede:	04e78d63          	beq	a5,a4,80004f38 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ee2:	4709                	li	a4,2
    80004ee4:	06e79e63          	bne	a5,a4,80004f60 <fileread+0xa6>
    ilock(f->ip);
    80004ee8:	6d08                	ld	a0,24(a0)
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	002080e7          	jalr	2(ra) # 80003eec <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ef2:	874a                	mv	a4,s2
    80004ef4:	5094                	lw	a3,32(s1)
    80004ef6:	864e                	mv	a2,s3
    80004ef8:	4585                	li	a1,1
    80004efa:	6c88                	ld	a0,24(s1)
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	2a4080e7          	jalr	676(ra) # 800041a0 <readi>
    80004f04:	892a                	mv	s2,a0
    80004f06:	00a05563          	blez	a0,80004f10 <fileread+0x56>
      f->off += r;
    80004f0a:	509c                	lw	a5,32(s1)
    80004f0c:	9fa9                	addw	a5,a5,a0
    80004f0e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f10:	6c88                	ld	a0,24(s1)
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	09c080e7          	jalr	156(ra) # 80003fae <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f1a:	854a                	mv	a0,s2
    80004f1c:	70a2                	ld	ra,40(sp)
    80004f1e:	7402                	ld	s0,32(sp)
    80004f20:	64e2                	ld	s1,24(sp)
    80004f22:	6942                	ld	s2,16(sp)
    80004f24:	69a2                	ld	s3,8(sp)
    80004f26:	6145                	addi	sp,sp,48
    80004f28:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f2a:	6908                	ld	a0,16(a0)
    80004f2c:	00000097          	auipc	ra,0x0
    80004f30:	3c6080e7          	jalr	966(ra) # 800052f2 <piperead>
    80004f34:	892a                	mv	s2,a0
    80004f36:	b7d5                	j	80004f1a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f38:	02451783          	lh	a5,36(a0)
    80004f3c:	03079693          	slli	a3,a5,0x30
    80004f40:	92c1                	srli	a3,a3,0x30
    80004f42:	4725                	li	a4,9
    80004f44:	02d76863          	bltu	a4,a3,80004f74 <fileread+0xba>
    80004f48:	0792                	slli	a5,a5,0x4
    80004f4a:	0001f717          	auipc	a4,0x1f
    80004f4e:	afe70713          	addi	a4,a4,-1282 # 80023a48 <devsw>
    80004f52:	97ba                	add	a5,a5,a4
    80004f54:	639c                	ld	a5,0(a5)
    80004f56:	c38d                	beqz	a5,80004f78 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f58:	4505                	li	a0,1
    80004f5a:	9782                	jalr	a5
    80004f5c:	892a                	mv	s2,a0
    80004f5e:	bf75                	j	80004f1a <fileread+0x60>
    panic("fileread");
    80004f60:	00003517          	auipc	a0,0x3
    80004f64:	7b050513          	addi	a0,a0,1968 # 80008710 <syscalls+0x280>
    80004f68:	ffffb097          	auipc	ra,0xffffb
    80004f6c:	5d8080e7          	jalr	1496(ra) # 80000540 <panic>
    return -1;
    80004f70:	597d                	li	s2,-1
    80004f72:	b765                	j	80004f1a <fileread+0x60>
      return -1;
    80004f74:	597d                	li	s2,-1
    80004f76:	b755                	j	80004f1a <fileread+0x60>
    80004f78:	597d                	li	s2,-1
    80004f7a:	b745                	j	80004f1a <fileread+0x60>

0000000080004f7c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f7c:	715d                	addi	sp,sp,-80
    80004f7e:	e486                	sd	ra,72(sp)
    80004f80:	e0a2                	sd	s0,64(sp)
    80004f82:	fc26                	sd	s1,56(sp)
    80004f84:	f84a                	sd	s2,48(sp)
    80004f86:	f44e                	sd	s3,40(sp)
    80004f88:	f052                	sd	s4,32(sp)
    80004f8a:	ec56                	sd	s5,24(sp)
    80004f8c:	e85a                	sd	s6,16(sp)
    80004f8e:	e45e                	sd	s7,8(sp)
    80004f90:	e062                	sd	s8,0(sp)
    80004f92:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f94:	00954783          	lbu	a5,9(a0)
    80004f98:	10078663          	beqz	a5,800050a4 <filewrite+0x128>
    80004f9c:	892a                	mv	s2,a0
    80004f9e:	8b2e                	mv	s6,a1
    80004fa0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fa2:	411c                	lw	a5,0(a0)
    80004fa4:	4705                	li	a4,1
    80004fa6:	02e78263          	beq	a5,a4,80004fca <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004faa:	470d                	li	a4,3
    80004fac:	02e78663          	beq	a5,a4,80004fd8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fb0:	4709                	li	a4,2
    80004fb2:	0ee79163          	bne	a5,a4,80005094 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fb6:	0ac05d63          	blez	a2,80005070 <filewrite+0xf4>
    int i = 0;
    80004fba:	4981                	li	s3,0
    80004fbc:	6b85                	lui	s7,0x1
    80004fbe:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004fc2:	6c05                	lui	s8,0x1
    80004fc4:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004fc8:	a861                	j	80005060 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fca:	6908                	ld	a0,16(a0)
    80004fcc:	00000097          	auipc	ra,0x0
    80004fd0:	22e080e7          	jalr	558(ra) # 800051fa <pipewrite>
    80004fd4:	8a2a                	mv	s4,a0
    80004fd6:	a045                	j	80005076 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fd8:	02451783          	lh	a5,36(a0)
    80004fdc:	03079693          	slli	a3,a5,0x30
    80004fe0:	92c1                	srli	a3,a3,0x30
    80004fe2:	4725                	li	a4,9
    80004fe4:	0cd76263          	bltu	a4,a3,800050a8 <filewrite+0x12c>
    80004fe8:	0792                	slli	a5,a5,0x4
    80004fea:	0001f717          	auipc	a4,0x1f
    80004fee:	a5e70713          	addi	a4,a4,-1442 # 80023a48 <devsw>
    80004ff2:	97ba                	add	a5,a5,a4
    80004ff4:	679c                	ld	a5,8(a5)
    80004ff6:	cbdd                	beqz	a5,800050ac <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ff8:	4505                	li	a0,1
    80004ffa:	9782                	jalr	a5
    80004ffc:	8a2a                	mv	s4,a0
    80004ffe:	a8a5                	j	80005076 <filewrite+0xfa>
    80005000:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005004:	00000097          	auipc	ra,0x0
    80005008:	8b4080e7          	jalr	-1868(ra) # 800048b8 <begin_op>
      ilock(f->ip);
    8000500c:	01893503          	ld	a0,24(s2)
    80005010:	fffff097          	auipc	ra,0xfffff
    80005014:	edc080e7          	jalr	-292(ra) # 80003eec <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005018:	8756                	mv	a4,s5
    8000501a:	02092683          	lw	a3,32(s2)
    8000501e:	01698633          	add	a2,s3,s6
    80005022:	4585                	li	a1,1
    80005024:	01893503          	ld	a0,24(s2)
    80005028:	fffff097          	auipc	ra,0xfffff
    8000502c:	270080e7          	jalr	624(ra) # 80004298 <writei>
    80005030:	84aa                	mv	s1,a0
    80005032:	00a05763          	blez	a0,80005040 <filewrite+0xc4>
        f->off += r;
    80005036:	02092783          	lw	a5,32(s2)
    8000503a:	9fa9                	addw	a5,a5,a0
    8000503c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005040:	01893503          	ld	a0,24(s2)
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	f6a080e7          	jalr	-150(ra) # 80003fae <iunlock>
      end_op();
    8000504c:	00000097          	auipc	ra,0x0
    80005050:	8ea080e7          	jalr	-1814(ra) # 80004936 <end_op>

      if(r != n1){
    80005054:	009a9f63          	bne	s5,s1,80005072 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005058:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000505c:	0149db63          	bge	s3,s4,80005072 <filewrite+0xf6>
      int n1 = n - i;
    80005060:	413a04bb          	subw	s1,s4,s3
    80005064:	0004879b          	sext.w	a5,s1
    80005068:	f8fbdce3          	bge	s7,a5,80005000 <filewrite+0x84>
    8000506c:	84e2                	mv	s1,s8
    8000506e:	bf49                	j	80005000 <filewrite+0x84>
    int i = 0;
    80005070:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005072:	013a1f63          	bne	s4,s3,80005090 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005076:	8552                	mv	a0,s4
    80005078:	60a6                	ld	ra,72(sp)
    8000507a:	6406                	ld	s0,64(sp)
    8000507c:	74e2                	ld	s1,56(sp)
    8000507e:	7942                	ld	s2,48(sp)
    80005080:	79a2                	ld	s3,40(sp)
    80005082:	7a02                	ld	s4,32(sp)
    80005084:	6ae2                	ld	s5,24(sp)
    80005086:	6b42                	ld	s6,16(sp)
    80005088:	6ba2                	ld	s7,8(sp)
    8000508a:	6c02                	ld	s8,0(sp)
    8000508c:	6161                	addi	sp,sp,80
    8000508e:	8082                	ret
    ret = (i == n ? n : -1);
    80005090:	5a7d                	li	s4,-1
    80005092:	b7d5                	j	80005076 <filewrite+0xfa>
    panic("filewrite");
    80005094:	00003517          	auipc	a0,0x3
    80005098:	68c50513          	addi	a0,a0,1676 # 80008720 <syscalls+0x290>
    8000509c:	ffffb097          	auipc	ra,0xffffb
    800050a0:	4a4080e7          	jalr	1188(ra) # 80000540 <panic>
    return -1;
    800050a4:	5a7d                	li	s4,-1
    800050a6:	bfc1                	j	80005076 <filewrite+0xfa>
      return -1;
    800050a8:	5a7d                	li	s4,-1
    800050aa:	b7f1                	j	80005076 <filewrite+0xfa>
    800050ac:	5a7d                	li	s4,-1
    800050ae:	b7e1                	j	80005076 <filewrite+0xfa>

00000000800050b0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050b0:	7179                	addi	sp,sp,-48
    800050b2:	f406                	sd	ra,40(sp)
    800050b4:	f022                	sd	s0,32(sp)
    800050b6:	ec26                	sd	s1,24(sp)
    800050b8:	e84a                	sd	s2,16(sp)
    800050ba:	e44e                	sd	s3,8(sp)
    800050bc:	e052                	sd	s4,0(sp)
    800050be:	1800                	addi	s0,sp,48
    800050c0:	84aa                	mv	s1,a0
    800050c2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050c4:	0005b023          	sd	zero,0(a1)
    800050c8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050cc:	00000097          	auipc	ra,0x0
    800050d0:	bf8080e7          	jalr	-1032(ra) # 80004cc4 <filealloc>
    800050d4:	e088                	sd	a0,0(s1)
    800050d6:	c551                	beqz	a0,80005162 <pipealloc+0xb2>
    800050d8:	00000097          	auipc	ra,0x0
    800050dc:	bec080e7          	jalr	-1044(ra) # 80004cc4 <filealloc>
    800050e0:	00aa3023          	sd	a0,0(s4)
    800050e4:	c92d                	beqz	a0,80005156 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	a00080e7          	jalr	-1536(ra) # 80000ae6 <kalloc>
    800050ee:	892a                	mv	s2,a0
    800050f0:	c125                	beqz	a0,80005150 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050f2:	4985                	li	s3,1
    800050f4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050f8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050fc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005100:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005104:	00003597          	auipc	a1,0x3
    80005108:	62c58593          	addi	a1,a1,1580 # 80008730 <syscalls+0x2a0>
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	a3a080e7          	jalr	-1478(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80005114:	609c                	ld	a5,0(s1)
    80005116:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000511a:	609c                	ld	a5,0(s1)
    8000511c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005120:	609c                	ld	a5,0(s1)
    80005122:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005126:	609c                	ld	a5,0(s1)
    80005128:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000512c:	000a3783          	ld	a5,0(s4)
    80005130:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005134:	000a3783          	ld	a5,0(s4)
    80005138:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000513c:	000a3783          	ld	a5,0(s4)
    80005140:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005144:	000a3783          	ld	a5,0(s4)
    80005148:	0127b823          	sd	s2,16(a5)
  return 0;
    8000514c:	4501                	li	a0,0
    8000514e:	a025                	j	80005176 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005150:	6088                	ld	a0,0(s1)
    80005152:	e501                	bnez	a0,8000515a <pipealloc+0xaa>
    80005154:	a039                	j	80005162 <pipealloc+0xb2>
    80005156:	6088                	ld	a0,0(s1)
    80005158:	c51d                	beqz	a0,80005186 <pipealloc+0xd6>
    fileclose(*f0);
    8000515a:	00000097          	auipc	ra,0x0
    8000515e:	c26080e7          	jalr	-986(ra) # 80004d80 <fileclose>
  if(*f1)
    80005162:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005166:	557d                	li	a0,-1
  if(*f1)
    80005168:	c799                	beqz	a5,80005176 <pipealloc+0xc6>
    fileclose(*f1);
    8000516a:	853e                	mv	a0,a5
    8000516c:	00000097          	auipc	ra,0x0
    80005170:	c14080e7          	jalr	-1004(ra) # 80004d80 <fileclose>
  return -1;
    80005174:	557d                	li	a0,-1
}
    80005176:	70a2                	ld	ra,40(sp)
    80005178:	7402                	ld	s0,32(sp)
    8000517a:	64e2                	ld	s1,24(sp)
    8000517c:	6942                	ld	s2,16(sp)
    8000517e:	69a2                	ld	s3,8(sp)
    80005180:	6a02                	ld	s4,0(sp)
    80005182:	6145                	addi	sp,sp,48
    80005184:	8082                	ret
  return -1;
    80005186:	557d                	li	a0,-1
    80005188:	b7fd                	j	80005176 <pipealloc+0xc6>

000000008000518a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000518a:	1101                	addi	sp,sp,-32
    8000518c:	ec06                	sd	ra,24(sp)
    8000518e:	e822                	sd	s0,16(sp)
    80005190:	e426                	sd	s1,8(sp)
    80005192:	e04a                	sd	s2,0(sp)
    80005194:	1000                	addi	s0,sp,32
    80005196:	84aa                	mv	s1,a0
    80005198:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	a3c080e7          	jalr	-1476(ra) # 80000bd6 <acquire>
  if(writable){
    800051a2:	02090d63          	beqz	s2,800051dc <pipeclose+0x52>
    pi->writeopen = 0;
    800051a6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051aa:	21848513          	addi	a0,s1,536
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	240080e7          	jalr	576(ra) # 800023ee <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051b6:	2204b783          	ld	a5,544(s1)
    800051ba:	eb95                	bnez	a5,800051ee <pipeclose+0x64>
    release(&pi->lock);
    800051bc:	8526                	mv	a0,s1
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	acc080e7          	jalr	-1332(ra) # 80000c8a <release>
    kfree((char*)pi);
    800051c6:	8526                	mv	a0,s1
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	820080e7          	jalr	-2016(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    800051d0:	60e2                	ld	ra,24(sp)
    800051d2:	6442                	ld	s0,16(sp)
    800051d4:	64a2                	ld	s1,8(sp)
    800051d6:	6902                	ld	s2,0(sp)
    800051d8:	6105                	addi	sp,sp,32
    800051da:	8082                	ret
    pi->readopen = 0;
    800051dc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051e0:	21c48513          	addi	a0,s1,540
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	20a080e7          	jalr	522(ra) # 800023ee <wakeup>
    800051ec:	b7e9                	j	800051b6 <pipeclose+0x2c>
    release(&pi->lock);
    800051ee:	8526                	mv	a0,s1
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	a9a080e7          	jalr	-1382(ra) # 80000c8a <release>
}
    800051f8:	bfe1                	j	800051d0 <pipeclose+0x46>

00000000800051fa <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051fa:	711d                	addi	sp,sp,-96
    800051fc:	ec86                	sd	ra,88(sp)
    800051fe:	e8a2                	sd	s0,80(sp)
    80005200:	e4a6                	sd	s1,72(sp)
    80005202:	e0ca                	sd	s2,64(sp)
    80005204:	fc4e                	sd	s3,56(sp)
    80005206:	f852                	sd	s4,48(sp)
    80005208:	f456                	sd	s5,40(sp)
    8000520a:	f05a                	sd	s6,32(sp)
    8000520c:	ec5e                	sd	s7,24(sp)
    8000520e:	e862                	sd	s8,16(sp)
    80005210:	1080                	addi	s0,sp,96
    80005212:	84aa                	mv	s1,a0
    80005214:	8aae                	mv	s5,a1
    80005216:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005218:	ffffd097          	auipc	ra,0xffffd
    8000521c:	93e080e7          	jalr	-1730(ra) # 80001b56 <myproc>
    80005220:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005222:	8526                	mv	a0,s1
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	9b2080e7          	jalr	-1614(ra) # 80000bd6 <acquire>
  while(i < n){
    8000522c:	0b405663          	blez	s4,800052d8 <pipewrite+0xde>
  int i = 0;
    80005230:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005232:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005234:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005238:	21c48b93          	addi	s7,s1,540
    8000523c:	a089                	j	8000527e <pipewrite+0x84>
      release(&pi->lock);
    8000523e:	8526                	mv	a0,s1
    80005240:	ffffc097          	auipc	ra,0xffffc
    80005244:	a4a080e7          	jalr	-1462(ra) # 80000c8a <release>
      return -1;
    80005248:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000524a:	854a                	mv	a0,s2
    8000524c:	60e6                	ld	ra,88(sp)
    8000524e:	6446                	ld	s0,80(sp)
    80005250:	64a6                	ld	s1,72(sp)
    80005252:	6906                	ld	s2,64(sp)
    80005254:	79e2                	ld	s3,56(sp)
    80005256:	7a42                	ld	s4,48(sp)
    80005258:	7aa2                	ld	s5,40(sp)
    8000525a:	7b02                	ld	s6,32(sp)
    8000525c:	6be2                	ld	s7,24(sp)
    8000525e:	6c42                	ld	s8,16(sp)
    80005260:	6125                	addi	sp,sp,96
    80005262:	8082                	ret
      wakeup(&pi->nread);
    80005264:	8562                	mv	a0,s8
    80005266:	ffffd097          	auipc	ra,0xffffd
    8000526a:	188080e7          	jalr	392(ra) # 800023ee <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000526e:	85a6                	mv	a1,s1
    80005270:	855e                	mv	a0,s7
    80005272:	ffffd097          	auipc	ra,0xffffd
    80005276:	118080e7          	jalr	280(ra) # 8000238a <sleep>
  while(i < n){
    8000527a:	07495063          	bge	s2,s4,800052da <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000527e:	2204a783          	lw	a5,544(s1)
    80005282:	dfd5                	beqz	a5,8000523e <pipewrite+0x44>
    80005284:	854e                	mv	a0,s3
    80005286:	ffffd097          	auipc	ra,0xffffd
    8000528a:	3e0080e7          	jalr	992(ra) # 80002666 <killed>
    8000528e:	f945                	bnez	a0,8000523e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005290:	2184a783          	lw	a5,536(s1)
    80005294:	21c4a703          	lw	a4,540(s1)
    80005298:	2007879b          	addiw	a5,a5,512
    8000529c:	fcf704e3          	beq	a4,a5,80005264 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052a0:	4685                	li	a3,1
    800052a2:	01590633          	add	a2,s2,s5
    800052a6:	faf40593          	addi	a1,s0,-81
    800052aa:	0509b503          	ld	a0,80(s3)
    800052ae:	ffffc097          	auipc	ra,0xffffc
    800052b2:	44a080e7          	jalr	1098(ra) # 800016f8 <copyin>
    800052b6:	03650263          	beq	a0,s6,800052da <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052ba:	21c4a783          	lw	a5,540(s1)
    800052be:	0017871b          	addiw	a4,a5,1
    800052c2:	20e4ae23          	sw	a4,540(s1)
    800052c6:	1ff7f793          	andi	a5,a5,511
    800052ca:	97a6                	add	a5,a5,s1
    800052cc:	faf44703          	lbu	a4,-81(s0)
    800052d0:	00e78c23          	sb	a4,24(a5)
      i++;
    800052d4:	2905                	addiw	s2,s2,1
    800052d6:	b755                	j	8000527a <pipewrite+0x80>
  int i = 0;
    800052d8:	4901                	li	s2,0
  wakeup(&pi->nread);
    800052da:	21848513          	addi	a0,s1,536
    800052de:	ffffd097          	auipc	ra,0xffffd
    800052e2:	110080e7          	jalr	272(ra) # 800023ee <wakeup>
  release(&pi->lock);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffc097          	auipc	ra,0xffffc
    800052ec:	9a2080e7          	jalr	-1630(ra) # 80000c8a <release>
  return i;
    800052f0:	bfa9                	j	8000524a <pipewrite+0x50>

00000000800052f2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052f2:	715d                	addi	sp,sp,-80
    800052f4:	e486                	sd	ra,72(sp)
    800052f6:	e0a2                	sd	s0,64(sp)
    800052f8:	fc26                	sd	s1,56(sp)
    800052fa:	f84a                	sd	s2,48(sp)
    800052fc:	f44e                	sd	s3,40(sp)
    800052fe:	f052                	sd	s4,32(sp)
    80005300:	ec56                	sd	s5,24(sp)
    80005302:	e85a                	sd	s6,16(sp)
    80005304:	0880                	addi	s0,sp,80
    80005306:	84aa                	mv	s1,a0
    80005308:	892e                	mv	s2,a1
    8000530a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000530c:	ffffd097          	auipc	ra,0xffffd
    80005310:	84a080e7          	jalr	-1974(ra) # 80001b56 <myproc>
    80005314:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005316:	8526                	mv	a0,s1
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	8be080e7          	jalr	-1858(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005320:	2184a703          	lw	a4,536(s1)
    80005324:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005328:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000532c:	02f71763          	bne	a4,a5,8000535a <piperead+0x68>
    80005330:	2244a783          	lw	a5,548(s1)
    80005334:	c39d                	beqz	a5,8000535a <piperead+0x68>
    if(killed(pr)){
    80005336:	8552                	mv	a0,s4
    80005338:	ffffd097          	auipc	ra,0xffffd
    8000533c:	32e080e7          	jalr	814(ra) # 80002666 <killed>
    80005340:	e949                	bnez	a0,800053d2 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005342:	85a6                	mv	a1,s1
    80005344:	854e                	mv	a0,s3
    80005346:	ffffd097          	auipc	ra,0xffffd
    8000534a:	044080e7          	jalr	68(ra) # 8000238a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000534e:	2184a703          	lw	a4,536(s1)
    80005352:	21c4a783          	lw	a5,540(s1)
    80005356:	fcf70de3          	beq	a4,a5,80005330 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000535a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000535c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000535e:	05505463          	blez	s5,800053a6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005362:	2184a783          	lw	a5,536(s1)
    80005366:	21c4a703          	lw	a4,540(s1)
    8000536a:	02f70e63          	beq	a4,a5,800053a6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000536e:	0017871b          	addiw	a4,a5,1
    80005372:	20e4ac23          	sw	a4,536(s1)
    80005376:	1ff7f793          	andi	a5,a5,511
    8000537a:	97a6                	add	a5,a5,s1
    8000537c:	0187c783          	lbu	a5,24(a5)
    80005380:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005384:	4685                	li	a3,1
    80005386:	fbf40613          	addi	a2,s0,-65
    8000538a:	85ca                	mv	a1,s2
    8000538c:	050a3503          	ld	a0,80(s4)
    80005390:	ffffc097          	auipc	ra,0xffffc
    80005394:	2dc080e7          	jalr	732(ra) # 8000166c <copyout>
    80005398:	01650763          	beq	a0,s6,800053a6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000539c:	2985                	addiw	s3,s3,1
    8000539e:	0905                	addi	s2,s2,1
    800053a0:	fd3a91e3          	bne	s5,s3,80005362 <piperead+0x70>
    800053a4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800053a6:	21c48513          	addi	a0,s1,540
    800053aa:	ffffd097          	auipc	ra,0xffffd
    800053ae:	044080e7          	jalr	68(ra) # 800023ee <wakeup>
  release(&pi->lock);
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffc097          	auipc	ra,0xffffc
    800053b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
  return i;
}
    800053bc:	854e                	mv	a0,s3
    800053be:	60a6                	ld	ra,72(sp)
    800053c0:	6406                	ld	s0,64(sp)
    800053c2:	74e2                	ld	s1,56(sp)
    800053c4:	7942                	ld	s2,48(sp)
    800053c6:	79a2                	ld	s3,40(sp)
    800053c8:	7a02                	ld	s4,32(sp)
    800053ca:	6ae2                	ld	s5,24(sp)
    800053cc:	6b42                	ld	s6,16(sp)
    800053ce:	6161                	addi	sp,sp,80
    800053d0:	8082                	ret
      release(&pi->lock);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffc097          	auipc	ra,0xffffc
    800053d8:	8b6080e7          	jalr	-1866(ra) # 80000c8a <release>
      return -1;
    800053dc:	59fd                	li	s3,-1
    800053de:	bff9                	j	800053bc <piperead+0xca>

00000000800053e0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800053e0:	1141                	addi	sp,sp,-16
    800053e2:	e422                	sd	s0,8(sp)
    800053e4:	0800                	addi	s0,sp,16
    800053e6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800053e8:	8905                	andi	a0,a0,1
    800053ea:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800053ec:	8b89                	andi	a5,a5,2
    800053ee:	c399                	beqz	a5,800053f4 <flags2perm+0x14>
      perm |= PTE_W;
    800053f0:	00456513          	ori	a0,a0,4
    return perm;
}
    800053f4:	6422                	ld	s0,8(sp)
    800053f6:	0141                	addi	sp,sp,16
    800053f8:	8082                	ret

00000000800053fa <exec>:

int
exec(char *path, char **argv)
{
    800053fa:	de010113          	addi	sp,sp,-544
    800053fe:	20113c23          	sd	ra,536(sp)
    80005402:	20813823          	sd	s0,528(sp)
    80005406:	20913423          	sd	s1,520(sp)
    8000540a:	21213023          	sd	s2,512(sp)
    8000540e:	ffce                	sd	s3,504(sp)
    80005410:	fbd2                	sd	s4,496(sp)
    80005412:	f7d6                	sd	s5,488(sp)
    80005414:	f3da                	sd	s6,480(sp)
    80005416:	efde                	sd	s7,472(sp)
    80005418:	ebe2                	sd	s8,464(sp)
    8000541a:	e7e6                	sd	s9,456(sp)
    8000541c:	e3ea                	sd	s10,448(sp)
    8000541e:	ff6e                	sd	s11,440(sp)
    80005420:	1400                	addi	s0,sp,544
    80005422:	892a                	mv	s2,a0
    80005424:	dea43423          	sd	a0,-536(s0)
    80005428:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000542c:	ffffc097          	auipc	ra,0xffffc
    80005430:	72a080e7          	jalr	1834(ra) # 80001b56 <myproc>
    80005434:	84aa                	mv	s1,a0

  begin_op();
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	482080e7          	jalr	1154(ra) # 800048b8 <begin_op>

  if((ip = namei(path)) == 0){
    8000543e:	854a                	mv	a0,s2
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	258080e7          	jalr	600(ra) # 80004698 <namei>
    80005448:	c93d                	beqz	a0,800054be <exec+0xc4>
    8000544a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	aa0080e7          	jalr	-1376(ra) # 80003eec <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005454:	04000713          	li	a4,64
    80005458:	4681                	li	a3,0
    8000545a:	e5040613          	addi	a2,s0,-432
    8000545e:	4581                	li	a1,0
    80005460:	8556                	mv	a0,s5
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	d3e080e7          	jalr	-706(ra) # 800041a0 <readi>
    8000546a:	04000793          	li	a5,64
    8000546e:	00f51a63          	bne	a0,a5,80005482 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005472:	e5042703          	lw	a4,-432(s0)
    80005476:	464c47b7          	lui	a5,0x464c4
    8000547a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000547e:	04f70663          	beq	a4,a5,800054ca <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005482:	8556                	mv	a0,s5
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	cca080e7          	jalr	-822(ra) # 8000414e <iunlockput>
    end_op();
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	4aa080e7          	jalr	1194(ra) # 80004936 <end_op>
  }
  return -1;
    80005494:	557d                	li	a0,-1
}
    80005496:	21813083          	ld	ra,536(sp)
    8000549a:	21013403          	ld	s0,528(sp)
    8000549e:	20813483          	ld	s1,520(sp)
    800054a2:	20013903          	ld	s2,512(sp)
    800054a6:	79fe                	ld	s3,504(sp)
    800054a8:	7a5e                	ld	s4,496(sp)
    800054aa:	7abe                	ld	s5,488(sp)
    800054ac:	7b1e                	ld	s6,480(sp)
    800054ae:	6bfe                	ld	s7,472(sp)
    800054b0:	6c5e                	ld	s8,464(sp)
    800054b2:	6cbe                	ld	s9,456(sp)
    800054b4:	6d1e                	ld	s10,448(sp)
    800054b6:	7dfa                	ld	s11,440(sp)
    800054b8:	22010113          	addi	sp,sp,544
    800054bc:	8082                	ret
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	478080e7          	jalr	1144(ra) # 80004936 <end_op>
    return -1;
    800054c6:	557d                	li	a0,-1
    800054c8:	b7f9                	j	80005496 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	74e080e7          	jalr	1870(ra) # 80001c1a <proc_pagetable>
    800054d4:	8b2a                	mv	s6,a0
    800054d6:	d555                	beqz	a0,80005482 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054d8:	e7042783          	lw	a5,-400(s0)
    800054dc:	e8845703          	lhu	a4,-376(s0)
    800054e0:	c735                	beqz	a4,8000554c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054e2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054e4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800054e8:	6a05                	lui	s4,0x1
    800054ea:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800054ee:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800054f2:	6d85                	lui	s11,0x1
    800054f4:	7d7d                	lui	s10,0xfffff
    800054f6:	ac3d                	j	80005734 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054f8:	00003517          	auipc	a0,0x3
    800054fc:	24050513          	addi	a0,a0,576 # 80008738 <syscalls+0x2a8>
    80005500:	ffffb097          	auipc	ra,0xffffb
    80005504:	040080e7          	jalr	64(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005508:	874a                	mv	a4,s2
    8000550a:	009c86bb          	addw	a3,s9,s1
    8000550e:	4581                	li	a1,0
    80005510:	8556                	mv	a0,s5
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	c8e080e7          	jalr	-882(ra) # 800041a0 <readi>
    8000551a:	2501                	sext.w	a0,a0
    8000551c:	1aa91963          	bne	s2,a0,800056ce <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005520:	009d84bb          	addw	s1,s11,s1
    80005524:	013d09bb          	addw	s3,s10,s3
    80005528:	1f74f663          	bgeu	s1,s7,80005714 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000552c:	02049593          	slli	a1,s1,0x20
    80005530:	9181                	srli	a1,a1,0x20
    80005532:	95e2                	add	a1,a1,s8
    80005534:	855a                	mv	a0,s6
    80005536:	ffffc097          	auipc	ra,0xffffc
    8000553a:	b26080e7          	jalr	-1242(ra) # 8000105c <walkaddr>
    8000553e:	862a                	mv	a2,a0
    if(pa == 0)
    80005540:	dd45                	beqz	a0,800054f8 <exec+0xfe>
      n = PGSIZE;
    80005542:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005544:	fd49f2e3          	bgeu	s3,s4,80005508 <exec+0x10e>
      n = sz - i;
    80005548:	894e                	mv	s2,s3
    8000554a:	bf7d                	j	80005508 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000554c:	4901                	li	s2,0
  iunlockput(ip);
    8000554e:	8556                	mv	a0,s5
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	bfe080e7          	jalr	-1026(ra) # 8000414e <iunlockput>
  end_op();
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	3de080e7          	jalr	990(ra) # 80004936 <end_op>
  p = myproc();
    80005560:	ffffc097          	auipc	ra,0xffffc
    80005564:	5f6080e7          	jalr	1526(ra) # 80001b56 <myproc>
    80005568:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000556a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000556e:	6785                	lui	a5,0x1
    80005570:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005572:	97ca                	add	a5,a5,s2
    80005574:	777d                	lui	a4,0xfffff
    80005576:	8ff9                	and	a5,a5,a4
    80005578:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000557c:	4691                	li	a3,4
    8000557e:	6609                	lui	a2,0x2
    80005580:	963e                	add	a2,a2,a5
    80005582:	85be                	mv	a1,a5
    80005584:	855a                	mv	a0,s6
    80005586:	ffffc097          	auipc	ra,0xffffc
    8000558a:	e8a080e7          	jalr	-374(ra) # 80001410 <uvmalloc>
    8000558e:	8c2a                	mv	s8,a0
  ip = 0;
    80005590:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005592:	12050e63          	beqz	a0,800056ce <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005596:	75f9                	lui	a1,0xffffe
    80005598:	95aa                	add	a1,a1,a0
    8000559a:	855a                	mv	a0,s6
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	09e080e7          	jalr	158(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800055a4:	7afd                	lui	s5,0xfffff
    800055a6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800055a8:	df043783          	ld	a5,-528(s0)
    800055ac:	6388                	ld	a0,0(a5)
    800055ae:	c925                	beqz	a0,8000561e <exec+0x224>
    800055b0:	e9040993          	addi	s3,s0,-368
    800055b4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800055b8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800055ba:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800055bc:	ffffc097          	auipc	ra,0xffffc
    800055c0:	892080e7          	jalr	-1902(ra) # 80000e4e <strlen>
    800055c4:	0015079b          	addiw	a5,a0,1
    800055c8:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800055cc:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800055d0:	13596663          	bltu	s2,s5,800056fc <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055d4:	df043d83          	ld	s11,-528(s0)
    800055d8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800055dc:	8552                	mv	a0,s4
    800055de:	ffffc097          	auipc	ra,0xffffc
    800055e2:	870080e7          	jalr	-1936(ra) # 80000e4e <strlen>
    800055e6:	0015069b          	addiw	a3,a0,1
    800055ea:	8652                	mv	a2,s4
    800055ec:	85ca                	mv	a1,s2
    800055ee:	855a                	mv	a0,s6
    800055f0:	ffffc097          	auipc	ra,0xffffc
    800055f4:	07c080e7          	jalr	124(ra) # 8000166c <copyout>
    800055f8:	10054663          	bltz	a0,80005704 <exec+0x30a>
    ustack[argc] = sp;
    800055fc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005600:	0485                	addi	s1,s1,1
    80005602:	008d8793          	addi	a5,s11,8
    80005606:	def43823          	sd	a5,-528(s0)
    8000560a:	008db503          	ld	a0,8(s11)
    8000560e:	c911                	beqz	a0,80005622 <exec+0x228>
    if(argc >= MAXARG)
    80005610:	09a1                	addi	s3,s3,8
    80005612:	fb3c95e3          	bne	s9,s3,800055bc <exec+0x1c2>
  sz = sz1;
    80005616:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000561a:	4a81                	li	s5,0
    8000561c:	a84d                	j	800056ce <exec+0x2d4>
  sp = sz;
    8000561e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005620:	4481                	li	s1,0
  ustack[argc] = 0;
    80005622:	00349793          	slli	a5,s1,0x3
    80005626:	f9078793          	addi	a5,a5,-112
    8000562a:	97a2                	add	a5,a5,s0
    8000562c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005630:	00148693          	addi	a3,s1,1
    80005634:	068e                	slli	a3,a3,0x3
    80005636:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000563a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000563e:	01597663          	bgeu	s2,s5,8000564a <exec+0x250>
  sz = sz1;
    80005642:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005646:	4a81                	li	s5,0
    80005648:	a059                	j	800056ce <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000564a:	e9040613          	addi	a2,s0,-368
    8000564e:	85ca                	mv	a1,s2
    80005650:	855a                	mv	a0,s6
    80005652:	ffffc097          	auipc	ra,0xffffc
    80005656:	01a080e7          	jalr	26(ra) # 8000166c <copyout>
    8000565a:	0a054963          	bltz	a0,8000570c <exec+0x312>
  p->trapframe->a1 = sp;
    8000565e:	058bb783          	ld	a5,88(s7)
    80005662:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005666:	de843783          	ld	a5,-536(s0)
    8000566a:	0007c703          	lbu	a4,0(a5)
    8000566e:	cf11                	beqz	a4,8000568a <exec+0x290>
    80005670:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005672:	02f00693          	li	a3,47
    80005676:	a039                	j	80005684 <exec+0x28a>
      last = s+1;
    80005678:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000567c:	0785                	addi	a5,a5,1
    8000567e:	fff7c703          	lbu	a4,-1(a5)
    80005682:	c701                	beqz	a4,8000568a <exec+0x290>
    if(*s == '/')
    80005684:	fed71ce3          	bne	a4,a3,8000567c <exec+0x282>
    80005688:	bfc5                	j	80005678 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000568a:	4641                	li	a2,16
    8000568c:	de843583          	ld	a1,-536(s0)
    80005690:	158b8513          	addi	a0,s7,344
    80005694:	ffffb097          	auipc	ra,0xffffb
    80005698:	788080e7          	jalr	1928(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000569c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800056a0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800056a4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056a8:	058bb783          	ld	a5,88(s7)
    800056ac:	e6843703          	ld	a4,-408(s0)
    800056b0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800056b2:	058bb783          	ld	a5,88(s7)
    800056b6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800056ba:	85ea                	mv	a1,s10
    800056bc:	ffffc097          	auipc	ra,0xffffc
    800056c0:	5fa080e7          	jalr	1530(ra) # 80001cb6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056c4:	0004851b          	sext.w	a0,s1
    800056c8:	b3f9                	j	80005496 <exec+0x9c>
    800056ca:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800056ce:	df843583          	ld	a1,-520(s0)
    800056d2:	855a                	mv	a0,s6
    800056d4:	ffffc097          	auipc	ra,0xffffc
    800056d8:	5e2080e7          	jalr	1506(ra) # 80001cb6 <proc_freepagetable>
  if(ip){
    800056dc:	da0a93e3          	bnez	s5,80005482 <exec+0x88>
  return -1;
    800056e0:	557d                	li	a0,-1
    800056e2:	bb55                	j	80005496 <exec+0x9c>
    800056e4:	df243c23          	sd	s2,-520(s0)
    800056e8:	b7dd                	j	800056ce <exec+0x2d4>
    800056ea:	df243c23          	sd	s2,-520(s0)
    800056ee:	b7c5                	j	800056ce <exec+0x2d4>
    800056f0:	df243c23          	sd	s2,-520(s0)
    800056f4:	bfe9                	j	800056ce <exec+0x2d4>
    800056f6:	df243c23          	sd	s2,-520(s0)
    800056fa:	bfd1                	j	800056ce <exec+0x2d4>
  sz = sz1;
    800056fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005700:	4a81                	li	s5,0
    80005702:	b7f1                	j	800056ce <exec+0x2d4>
  sz = sz1;
    80005704:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005708:	4a81                	li	s5,0
    8000570a:	b7d1                	j	800056ce <exec+0x2d4>
  sz = sz1;
    8000570c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005710:	4a81                	li	s5,0
    80005712:	bf75                	j	800056ce <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005714:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005718:	e0843783          	ld	a5,-504(s0)
    8000571c:	0017869b          	addiw	a3,a5,1
    80005720:	e0d43423          	sd	a3,-504(s0)
    80005724:	e0043783          	ld	a5,-512(s0)
    80005728:	0387879b          	addiw	a5,a5,56
    8000572c:	e8845703          	lhu	a4,-376(s0)
    80005730:	e0e6dfe3          	bge	a3,a4,8000554e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005734:	2781                	sext.w	a5,a5
    80005736:	e0f43023          	sd	a5,-512(s0)
    8000573a:	03800713          	li	a4,56
    8000573e:	86be                	mv	a3,a5
    80005740:	e1840613          	addi	a2,s0,-488
    80005744:	4581                	li	a1,0
    80005746:	8556                	mv	a0,s5
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	a58080e7          	jalr	-1448(ra) # 800041a0 <readi>
    80005750:	03800793          	li	a5,56
    80005754:	f6f51be3          	bne	a0,a5,800056ca <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005758:	e1842783          	lw	a5,-488(s0)
    8000575c:	4705                	li	a4,1
    8000575e:	fae79de3          	bne	a5,a4,80005718 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005762:	e4043483          	ld	s1,-448(s0)
    80005766:	e3843783          	ld	a5,-456(s0)
    8000576a:	f6f4ede3          	bltu	s1,a5,800056e4 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000576e:	e2843783          	ld	a5,-472(s0)
    80005772:	94be                	add	s1,s1,a5
    80005774:	f6f4ebe3          	bltu	s1,a5,800056ea <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005778:	de043703          	ld	a4,-544(s0)
    8000577c:	8ff9                	and	a5,a5,a4
    8000577e:	fbad                	bnez	a5,800056f0 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005780:	e1c42503          	lw	a0,-484(s0)
    80005784:	00000097          	auipc	ra,0x0
    80005788:	c5c080e7          	jalr	-932(ra) # 800053e0 <flags2perm>
    8000578c:	86aa                	mv	a3,a0
    8000578e:	8626                	mv	a2,s1
    80005790:	85ca                	mv	a1,s2
    80005792:	855a                	mv	a0,s6
    80005794:	ffffc097          	auipc	ra,0xffffc
    80005798:	c7c080e7          	jalr	-900(ra) # 80001410 <uvmalloc>
    8000579c:	dea43c23          	sd	a0,-520(s0)
    800057a0:	d939                	beqz	a0,800056f6 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800057a2:	e2843c03          	ld	s8,-472(s0)
    800057a6:	e2042c83          	lw	s9,-480(s0)
    800057aa:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800057ae:	f60b83e3          	beqz	s7,80005714 <exec+0x31a>
    800057b2:	89de                	mv	s3,s7
    800057b4:	4481                	li	s1,0
    800057b6:	bb9d                	j	8000552c <exec+0x132>

00000000800057b8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800057b8:	7179                	addi	sp,sp,-48
    800057ba:	f406                	sd	ra,40(sp)
    800057bc:	f022                	sd	s0,32(sp)
    800057be:	ec26                	sd	s1,24(sp)
    800057c0:	e84a                	sd	s2,16(sp)
    800057c2:	1800                	addi	s0,sp,48
    800057c4:	892e                	mv	s2,a1
    800057c6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800057c8:	fdc40593          	addi	a1,s0,-36
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	9da080e7          	jalr	-1574(ra) # 800031a6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057d4:	fdc42703          	lw	a4,-36(s0)
    800057d8:	47bd                	li	a5,15
    800057da:	02e7eb63          	bltu	a5,a4,80005810 <argfd+0x58>
    800057de:	ffffc097          	auipc	ra,0xffffc
    800057e2:	378080e7          	jalr	888(ra) # 80001b56 <myproc>
    800057e6:	fdc42703          	lw	a4,-36(s0)
    800057ea:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffda43a>
    800057ee:	078e                	slli	a5,a5,0x3
    800057f0:	953e                	add	a0,a0,a5
    800057f2:	611c                	ld	a5,0(a0)
    800057f4:	c385                	beqz	a5,80005814 <argfd+0x5c>
    return -1;
  if(pfd)
    800057f6:	00090463          	beqz	s2,800057fe <argfd+0x46>
    *pfd = fd;
    800057fa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057fe:	4501                	li	a0,0
  if(pf)
    80005800:	c091                	beqz	s1,80005804 <argfd+0x4c>
    *pf = f;
    80005802:	e09c                	sd	a5,0(s1)
}
    80005804:	70a2                	ld	ra,40(sp)
    80005806:	7402                	ld	s0,32(sp)
    80005808:	64e2                	ld	s1,24(sp)
    8000580a:	6942                	ld	s2,16(sp)
    8000580c:	6145                	addi	sp,sp,48
    8000580e:	8082                	ret
    return -1;
    80005810:	557d                	li	a0,-1
    80005812:	bfcd                	j	80005804 <argfd+0x4c>
    80005814:	557d                	li	a0,-1
    80005816:	b7fd                	j	80005804 <argfd+0x4c>

0000000080005818 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005818:	1101                	addi	sp,sp,-32
    8000581a:	ec06                	sd	ra,24(sp)
    8000581c:	e822                	sd	s0,16(sp)
    8000581e:	e426                	sd	s1,8(sp)
    80005820:	1000                	addi	s0,sp,32
    80005822:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005824:	ffffc097          	auipc	ra,0xffffc
    80005828:	332080e7          	jalr	818(ra) # 80001b56 <myproc>
    8000582c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000582e:	0d050793          	addi	a5,a0,208
    80005832:	4501                	li	a0,0
    80005834:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005836:	6398                	ld	a4,0(a5)
    80005838:	cb19                	beqz	a4,8000584e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000583a:	2505                	addiw	a0,a0,1
    8000583c:	07a1                	addi	a5,a5,8
    8000583e:	fed51ce3          	bne	a0,a3,80005836 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005842:	557d                	li	a0,-1
}
    80005844:	60e2                	ld	ra,24(sp)
    80005846:	6442                	ld	s0,16(sp)
    80005848:	64a2                	ld	s1,8(sp)
    8000584a:	6105                	addi	sp,sp,32
    8000584c:	8082                	ret
      p->ofile[fd] = f;
    8000584e:	01a50793          	addi	a5,a0,26
    80005852:	078e                	slli	a5,a5,0x3
    80005854:	963e                	add	a2,a2,a5
    80005856:	e204                	sd	s1,0(a2)
      return fd;
    80005858:	b7f5                	j	80005844 <fdalloc+0x2c>

000000008000585a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000585a:	715d                	addi	sp,sp,-80
    8000585c:	e486                	sd	ra,72(sp)
    8000585e:	e0a2                	sd	s0,64(sp)
    80005860:	fc26                	sd	s1,56(sp)
    80005862:	f84a                	sd	s2,48(sp)
    80005864:	f44e                	sd	s3,40(sp)
    80005866:	f052                	sd	s4,32(sp)
    80005868:	ec56                	sd	s5,24(sp)
    8000586a:	e85a                	sd	s6,16(sp)
    8000586c:	0880                	addi	s0,sp,80
    8000586e:	8b2e                	mv	s6,a1
    80005870:	89b2                	mv	s3,a2
    80005872:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005874:	fb040593          	addi	a1,s0,-80
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	e3e080e7          	jalr	-450(ra) # 800046b6 <nameiparent>
    80005880:	84aa                	mv	s1,a0
    80005882:	14050f63          	beqz	a0,800059e0 <create+0x186>
    return 0;

  ilock(dp);
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	666080e7          	jalr	1638(ra) # 80003eec <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000588e:	4601                	li	a2,0
    80005890:	fb040593          	addi	a1,s0,-80
    80005894:	8526                	mv	a0,s1
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	b3a080e7          	jalr	-1222(ra) # 800043d0 <dirlookup>
    8000589e:	8aaa                	mv	s5,a0
    800058a0:	c931                	beqz	a0,800058f4 <create+0x9a>
    iunlockput(dp);
    800058a2:	8526                	mv	a0,s1
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	8aa080e7          	jalr	-1878(ra) # 8000414e <iunlockput>
    ilock(ip);
    800058ac:	8556                	mv	a0,s5
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	63e080e7          	jalr	1598(ra) # 80003eec <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058b6:	000b059b          	sext.w	a1,s6
    800058ba:	4789                	li	a5,2
    800058bc:	02f59563          	bne	a1,a5,800058e6 <create+0x8c>
    800058c0:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffda464>
    800058c4:	37f9                	addiw	a5,a5,-2
    800058c6:	17c2                	slli	a5,a5,0x30
    800058c8:	93c1                	srli	a5,a5,0x30
    800058ca:	4705                	li	a4,1
    800058cc:	00f76d63          	bltu	a4,a5,800058e6 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800058d0:	8556                	mv	a0,s5
    800058d2:	60a6                	ld	ra,72(sp)
    800058d4:	6406                	ld	s0,64(sp)
    800058d6:	74e2                	ld	s1,56(sp)
    800058d8:	7942                	ld	s2,48(sp)
    800058da:	79a2                	ld	s3,40(sp)
    800058dc:	7a02                	ld	s4,32(sp)
    800058de:	6ae2                	ld	s5,24(sp)
    800058e0:	6b42                	ld	s6,16(sp)
    800058e2:	6161                	addi	sp,sp,80
    800058e4:	8082                	ret
    iunlockput(ip);
    800058e6:	8556                	mv	a0,s5
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	866080e7          	jalr	-1946(ra) # 8000414e <iunlockput>
    return 0;
    800058f0:	4a81                	li	s5,0
    800058f2:	bff9                	j	800058d0 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800058f4:	85da                	mv	a1,s6
    800058f6:	4088                	lw	a0,0(s1)
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	456080e7          	jalr	1110(ra) # 80003d4e <ialloc>
    80005900:	8a2a                	mv	s4,a0
    80005902:	c539                	beqz	a0,80005950 <create+0xf6>
  ilock(ip);
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	5e8080e7          	jalr	1512(ra) # 80003eec <ilock>
  ip->major = major;
    8000590c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005910:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005914:	4905                	li	s2,1
    80005916:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000591a:	8552                	mv	a0,s4
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	504080e7          	jalr	1284(ra) # 80003e20 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005924:	000b059b          	sext.w	a1,s6
    80005928:	03258b63          	beq	a1,s2,8000595e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000592c:	004a2603          	lw	a2,4(s4)
    80005930:	fb040593          	addi	a1,s0,-80
    80005934:	8526                	mv	a0,s1
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	cb0080e7          	jalr	-848(ra) # 800045e6 <dirlink>
    8000593e:	06054f63          	bltz	a0,800059bc <create+0x162>
  iunlockput(dp);
    80005942:	8526                	mv	a0,s1
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	80a080e7          	jalr	-2038(ra) # 8000414e <iunlockput>
  return ip;
    8000594c:	8ad2                	mv	s5,s4
    8000594e:	b749                	j	800058d0 <create+0x76>
    iunlockput(dp);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	7fc080e7          	jalr	2044(ra) # 8000414e <iunlockput>
    return 0;
    8000595a:	8ad2                	mv	s5,s4
    8000595c:	bf95                	j	800058d0 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000595e:	004a2603          	lw	a2,4(s4)
    80005962:	00003597          	auipc	a1,0x3
    80005966:	df658593          	addi	a1,a1,-522 # 80008758 <syscalls+0x2c8>
    8000596a:	8552                	mv	a0,s4
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	c7a080e7          	jalr	-902(ra) # 800045e6 <dirlink>
    80005974:	04054463          	bltz	a0,800059bc <create+0x162>
    80005978:	40d0                	lw	a2,4(s1)
    8000597a:	00003597          	auipc	a1,0x3
    8000597e:	de658593          	addi	a1,a1,-538 # 80008760 <syscalls+0x2d0>
    80005982:	8552                	mv	a0,s4
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	c62080e7          	jalr	-926(ra) # 800045e6 <dirlink>
    8000598c:	02054863          	bltz	a0,800059bc <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005990:	004a2603          	lw	a2,4(s4)
    80005994:	fb040593          	addi	a1,s0,-80
    80005998:	8526                	mv	a0,s1
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	c4c080e7          	jalr	-948(ra) # 800045e6 <dirlink>
    800059a2:	00054d63          	bltz	a0,800059bc <create+0x162>
    dp->nlink++;  // for ".."
    800059a6:	04a4d783          	lhu	a5,74(s1)
    800059aa:	2785                	addiw	a5,a5,1
    800059ac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	46e080e7          	jalr	1134(ra) # 80003e20 <iupdate>
    800059ba:	b761                	j	80005942 <create+0xe8>
  ip->nlink = 0;
    800059bc:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800059c0:	8552                	mv	a0,s4
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	45e080e7          	jalr	1118(ra) # 80003e20 <iupdate>
  iunlockput(ip);
    800059ca:	8552                	mv	a0,s4
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	782080e7          	jalr	1922(ra) # 8000414e <iunlockput>
  iunlockput(dp);
    800059d4:	8526                	mv	a0,s1
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	778080e7          	jalr	1912(ra) # 8000414e <iunlockput>
  return 0;
    800059de:	bdcd                	j	800058d0 <create+0x76>
    return 0;
    800059e0:	8aaa                	mv	s5,a0
    800059e2:	b5fd                	j	800058d0 <create+0x76>

00000000800059e4 <sys_dup>:
{
    800059e4:	7179                	addi	sp,sp,-48
    800059e6:	f406                	sd	ra,40(sp)
    800059e8:	f022                	sd	s0,32(sp)
    800059ea:	ec26                	sd	s1,24(sp)
    800059ec:	e84a                	sd	s2,16(sp)
    800059ee:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059f0:	fd840613          	addi	a2,s0,-40
    800059f4:	4581                	li	a1,0
    800059f6:	4501                	li	a0,0
    800059f8:	00000097          	auipc	ra,0x0
    800059fc:	dc0080e7          	jalr	-576(ra) # 800057b8 <argfd>
    return -1;
    80005a00:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a02:	02054363          	bltz	a0,80005a28 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005a06:	fd843903          	ld	s2,-40(s0)
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	00000097          	auipc	ra,0x0
    80005a10:	e0c080e7          	jalr	-500(ra) # 80005818 <fdalloc>
    80005a14:	84aa                	mv	s1,a0
    return -1;
    80005a16:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a18:	00054863          	bltz	a0,80005a28 <sys_dup+0x44>
  filedup(f);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	310080e7          	jalr	784(ra) # 80004d2e <filedup>
  return fd;
    80005a26:	87a6                	mv	a5,s1
}
    80005a28:	853e                	mv	a0,a5
    80005a2a:	70a2                	ld	ra,40(sp)
    80005a2c:	7402                	ld	s0,32(sp)
    80005a2e:	64e2                	ld	s1,24(sp)
    80005a30:	6942                	ld	s2,16(sp)
    80005a32:	6145                	addi	sp,sp,48
    80005a34:	8082                	ret

0000000080005a36 <sys_read>:
{
    80005a36:	7179                	addi	sp,sp,-48
    80005a38:	f406                	sd	ra,40(sp)
    80005a3a:	f022                	sd	s0,32(sp)
    80005a3c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a3e:	fd840593          	addi	a1,s0,-40
    80005a42:	4505                	li	a0,1
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	782080e7          	jalr	1922(ra) # 800031c6 <argaddr>
  argint(2, &n);
    80005a4c:	fe440593          	addi	a1,s0,-28
    80005a50:	4509                	li	a0,2
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	754080e7          	jalr	1876(ra) # 800031a6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a5a:	fe840613          	addi	a2,s0,-24
    80005a5e:	4581                	li	a1,0
    80005a60:	4501                	li	a0,0
    80005a62:	00000097          	auipc	ra,0x0
    80005a66:	d56080e7          	jalr	-682(ra) # 800057b8 <argfd>
    80005a6a:	87aa                	mv	a5,a0
    return -1;
    80005a6c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a6e:	0007cc63          	bltz	a5,80005a86 <sys_read+0x50>
  return fileread(f, p, n);
    80005a72:	fe442603          	lw	a2,-28(s0)
    80005a76:	fd843583          	ld	a1,-40(s0)
    80005a7a:	fe843503          	ld	a0,-24(s0)
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	43c080e7          	jalr	1084(ra) # 80004eba <fileread>
}
    80005a86:	70a2                	ld	ra,40(sp)
    80005a88:	7402                	ld	s0,32(sp)
    80005a8a:	6145                	addi	sp,sp,48
    80005a8c:	8082                	ret

0000000080005a8e <sys_write>:
{
    80005a8e:	7179                	addi	sp,sp,-48
    80005a90:	f406                	sd	ra,40(sp)
    80005a92:	f022                	sd	s0,32(sp)
    80005a94:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a96:	fd840593          	addi	a1,s0,-40
    80005a9a:	4505                	li	a0,1
    80005a9c:	ffffd097          	auipc	ra,0xffffd
    80005aa0:	72a080e7          	jalr	1834(ra) # 800031c6 <argaddr>
  argint(2, &n);
    80005aa4:	fe440593          	addi	a1,s0,-28
    80005aa8:	4509                	li	a0,2
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	6fc080e7          	jalr	1788(ra) # 800031a6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ab2:	fe840613          	addi	a2,s0,-24
    80005ab6:	4581                	li	a1,0
    80005ab8:	4501                	li	a0,0
    80005aba:	00000097          	auipc	ra,0x0
    80005abe:	cfe080e7          	jalr	-770(ra) # 800057b8 <argfd>
    80005ac2:	87aa                	mv	a5,a0
    return -1;
    80005ac4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ac6:	0007cc63          	bltz	a5,80005ade <sys_write+0x50>
  return filewrite(f, p, n);
    80005aca:	fe442603          	lw	a2,-28(s0)
    80005ace:	fd843583          	ld	a1,-40(s0)
    80005ad2:	fe843503          	ld	a0,-24(s0)
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	4a6080e7          	jalr	1190(ra) # 80004f7c <filewrite>
}
    80005ade:	70a2                	ld	ra,40(sp)
    80005ae0:	7402                	ld	s0,32(sp)
    80005ae2:	6145                	addi	sp,sp,48
    80005ae4:	8082                	ret

0000000080005ae6 <sys_close>:
{
    80005ae6:	1101                	addi	sp,sp,-32
    80005ae8:	ec06                	sd	ra,24(sp)
    80005aea:	e822                	sd	s0,16(sp)
    80005aec:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005aee:	fe040613          	addi	a2,s0,-32
    80005af2:	fec40593          	addi	a1,s0,-20
    80005af6:	4501                	li	a0,0
    80005af8:	00000097          	auipc	ra,0x0
    80005afc:	cc0080e7          	jalr	-832(ra) # 800057b8 <argfd>
    return -1;
    80005b00:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b02:	02054463          	bltz	a0,80005b2a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b06:	ffffc097          	auipc	ra,0xffffc
    80005b0a:	050080e7          	jalr	80(ra) # 80001b56 <myproc>
    80005b0e:	fec42783          	lw	a5,-20(s0)
    80005b12:	07e9                	addi	a5,a5,26
    80005b14:	078e                	slli	a5,a5,0x3
    80005b16:	953e                	add	a0,a0,a5
    80005b18:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005b1c:	fe043503          	ld	a0,-32(s0)
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	260080e7          	jalr	608(ra) # 80004d80 <fileclose>
  return 0;
    80005b28:	4781                	li	a5,0
}
    80005b2a:	853e                	mv	a0,a5
    80005b2c:	60e2                	ld	ra,24(sp)
    80005b2e:	6442                	ld	s0,16(sp)
    80005b30:	6105                	addi	sp,sp,32
    80005b32:	8082                	ret

0000000080005b34 <sys_fstat>:
{
    80005b34:	1101                	addi	sp,sp,-32
    80005b36:	ec06                	sd	ra,24(sp)
    80005b38:	e822                	sd	s0,16(sp)
    80005b3a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005b3c:	fe040593          	addi	a1,s0,-32
    80005b40:	4505                	li	a0,1
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	684080e7          	jalr	1668(ra) # 800031c6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005b4a:	fe840613          	addi	a2,s0,-24
    80005b4e:	4581                	li	a1,0
    80005b50:	4501                	li	a0,0
    80005b52:	00000097          	auipc	ra,0x0
    80005b56:	c66080e7          	jalr	-922(ra) # 800057b8 <argfd>
    80005b5a:	87aa                	mv	a5,a0
    return -1;
    80005b5c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b5e:	0007ca63          	bltz	a5,80005b72 <sys_fstat+0x3e>
  return filestat(f, st);
    80005b62:	fe043583          	ld	a1,-32(s0)
    80005b66:	fe843503          	ld	a0,-24(s0)
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	2de080e7          	jalr	734(ra) # 80004e48 <filestat>
}
    80005b72:	60e2                	ld	ra,24(sp)
    80005b74:	6442                	ld	s0,16(sp)
    80005b76:	6105                	addi	sp,sp,32
    80005b78:	8082                	ret

0000000080005b7a <sys_link>:
{
    80005b7a:	7169                	addi	sp,sp,-304
    80005b7c:	f606                	sd	ra,296(sp)
    80005b7e:	f222                	sd	s0,288(sp)
    80005b80:	ee26                	sd	s1,280(sp)
    80005b82:	ea4a                	sd	s2,272(sp)
    80005b84:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b86:	08000613          	li	a2,128
    80005b8a:	ed040593          	addi	a1,s0,-304
    80005b8e:	4501                	li	a0,0
    80005b90:	ffffd097          	auipc	ra,0xffffd
    80005b94:	656080e7          	jalr	1622(ra) # 800031e6 <argstr>
    return -1;
    80005b98:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b9a:	10054e63          	bltz	a0,80005cb6 <sys_link+0x13c>
    80005b9e:	08000613          	li	a2,128
    80005ba2:	f5040593          	addi	a1,s0,-176
    80005ba6:	4505                	li	a0,1
    80005ba8:	ffffd097          	auipc	ra,0xffffd
    80005bac:	63e080e7          	jalr	1598(ra) # 800031e6 <argstr>
    return -1;
    80005bb0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bb2:	10054263          	bltz	a0,80005cb6 <sys_link+0x13c>
  begin_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	d02080e7          	jalr	-766(ra) # 800048b8 <begin_op>
  if((ip = namei(old)) == 0){
    80005bbe:	ed040513          	addi	a0,s0,-304
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	ad6080e7          	jalr	-1322(ra) # 80004698 <namei>
    80005bca:	84aa                	mv	s1,a0
    80005bcc:	c551                	beqz	a0,80005c58 <sys_link+0xde>
  ilock(ip);
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	31e080e7          	jalr	798(ra) # 80003eec <ilock>
  if(ip->type == T_DIR){
    80005bd6:	04449703          	lh	a4,68(s1)
    80005bda:	4785                	li	a5,1
    80005bdc:	08f70463          	beq	a4,a5,80005c64 <sys_link+0xea>
  ip->nlink++;
    80005be0:	04a4d783          	lhu	a5,74(s1)
    80005be4:	2785                	addiw	a5,a5,1
    80005be6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bea:	8526                	mv	a0,s1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	234080e7          	jalr	564(ra) # 80003e20 <iupdate>
  iunlock(ip);
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	3b8080e7          	jalr	952(ra) # 80003fae <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005bfe:	fd040593          	addi	a1,s0,-48
    80005c02:	f5040513          	addi	a0,s0,-176
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	ab0080e7          	jalr	-1360(ra) # 800046b6 <nameiparent>
    80005c0e:	892a                	mv	s2,a0
    80005c10:	c935                	beqz	a0,80005c84 <sys_link+0x10a>
  ilock(dp);
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	2da080e7          	jalr	730(ra) # 80003eec <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c1a:	00092703          	lw	a4,0(s2)
    80005c1e:	409c                	lw	a5,0(s1)
    80005c20:	04f71d63          	bne	a4,a5,80005c7a <sys_link+0x100>
    80005c24:	40d0                	lw	a2,4(s1)
    80005c26:	fd040593          	addi	a1,s0,-48
    80005c2a:	854a                	mv	a0,s2
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	9ba080e7          	jalr	-1606(ra) # 800045e6 <dirlink>
    80005c34:	04054363          	bltz	a0,80005c7a <sys_link+0x100>
  iunlockput(dp);
    80005c38:	854a                	mv	a0,s2
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	514080e7          	jalr	1300(ra) # 8000414e <iunlockput>
  iput(ip);
    80005c42:	8526                	mv	a0,s1
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	462080e7          	jalr	1122(ra) # 800040a6 <iput>
  end_op();
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	cea080e7          	jalr	-790(ra) # 80004936 <end_op>
  return 0;
    80005c54:	4781                	li	a5,0
    80005c56:	a085                	j	80005cb6 <sys_link+0x13c>
    end_op();
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	cde080e7          	jalr	-802(ra) # 80004936 <end_op>
    return -1;
    80005c60:	57fd                	li	a5,-1
    80005c62:	a891                	j	80005cb6 <sys_link+0x13c>
    iunlockput(ip);
    80005c64:	8526                	mv	a0,s1
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	4e8080e7          	jalr	1256(ra) # 8000414e <iunlockput>
    end_op();
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	cc8080e7          	jalr	-824(ra) # 80004936 <end_op>
    return -1;
    80005c76:	57fd                	li	a5,-1
    80005c78:	a83d                	j	80005cb6 <sys_link+0x13c>
    iunlockput(dp);
    80005c7a:	854a                	mv	a0,s2
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	4d2080e7          	jalr	1234(ra) # 8000414e <iunlockput>
  ilock(ip);
    80005c84:	8526                	mv	a0,s1
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	266080e7          	jalr	614(ra) # 80003eec <ilock>
  ip->nlink--;
    80005c8e:	04a4d783          	lhu	a5,74(s1)
    80005c92:	37fd                	addiw	a5,a5,-1
    80005c94:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c98:	8526                	mv	a0,s1
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	186080e7          	jalr	390(ra) # 80003e20 <iupdate>
  iunlockput(ip);
    80005ca2:	8526                	mv	a0,s1
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	4aa080e7          	jalr	1194(ra) # 8000414e <iunlockput>
  end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	c8a080e7          	jalr	-886(ra) # 80004936 <end_op>
  return -1;
    80005cb4:	57fd                	li	a5,-1
}
    80005cb6:	853e                	mv	a0,a5
    80005cb8:	70b2                	ld	ra,296(sp)
    80005cba:	7412                	ld	s0,288(sp)
    80005cbc:	64f2                	ld	s1,280(sp)
    80005cbe:	6952                	ld	s2,272(sp)
    80005cc0:	6155                	addi	sp,sp,304
    80005cc2:	8082                	ret

0000000080005cc4 <sys_unlink>:
{
    80005cc4:	7151                	addi	sp,sp,-240
    80005cc6:	f586                	sd	ra,232(sp)
    80005cc8:	f1a2                	sd	s0,224(sp)
    80005cca:	eda6                	sd	s1,216(sp)
    80005ccc:	e9ca                	sd	s2,208(sp)
    80005cce:	e5ce                	sd	s3,200(sp)
    80005cd0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cd2:	08000613          	li	a2,128
    80005cd6:	f3040593          	addi	a1,s0,-208
    80005cda:	4501                	li	a0,0
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	50a080e7          	jalr	1290(ra) # 800031e6 <argstr>
    80005ce4:	18054163          	bltz	a0,80005e66 <sys_unlink+0x1a2>
  begin_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	bd0080e7          	jalr	-1072(ra) # 800048b8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005cf0:	fb040593          	addi	a1,s0,-80
    80005cf4:	f3040513          	addi	a0,s0,-208
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	9be080e7          	jalr	-1602(ra) # 800046b6 <nameiparent>
    80005d00:	84aa                	mv	s1,a0
    80005d02:	c979                	beqz	a0,80005dd8 <sys_unlink+0x114>
  ilock(dp);
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	1e8080e7          	jalr	488(ra) # 80003eec <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d0c:	00003597          	auipc	a1,0x3
    80005d10:	a4c58593          	addi	a1,a1,-1460 # 80008758 <syscalls+0x2c8>
    80005d14:	fb040513          	addi	a0,s0,-80
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	69e080e7          	jalr	1694(ra) # 800043b6 <namecmp>
    80005d20:	14050a63          	beqz	a0,80005e74 <sys_unlink+0x1b0>
    80005d24:	00003597          	auipc	a1,0x3
    80005d28:	a3c58593          	addi	a1,a1,-1476 # 80008760 <syscalls+0x2d0>
    80005d2c:	fb040513          	addi	a0,s0,-80
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	686080e7          	jalr	1670(ra) # 800043b6 <namecmp>
    80005d38:	12050e63          	beqz	a0,80005e74 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d3c:	f2c40613          	addi	a2,s0,-212
    80005d40:	fb040593          	addi	a1,s0,-80
    80005d44:	8526                	mv	a0,s1
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	68a080e7          	jalr	1674(ra) # 800043d0 <dirlookup>
    80005d4e:	892a                	mv	s2,a0
    80005d50:	12050263          	beqz	a0,80005e74 <sys_unlink+0x1b0>
  ilock(ip);
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	198080e7          	jalr	408(ra) # 80003eec <ilock>
  if(ip->nlink < 1)
    80005d5c:	04a91783          	lh	a5,74(s2)
    80005d60:	08f05263          	blez	a5,80005de4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d64:	04491703          	lh	a4,68(s2)
    80005d68:	4785                	li	a5,1
    80005d6a:	08f70563          	beq	a4,a5,80005df4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d6e:	4641                	li	a2,16
    80005d70:	4581                	li	a1,0
    80005d72:	fc040513          	addi	a0,s0,-64
    80005d76:	ffffb097          	auipc	ra,0xffffb
    80005d7a:	f5c080e7          	jalr	-164(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d7e:	4741                	li	a4,16
    80005d80:	f2c42683          	lw	a3,-212(s0)
    80005d84:	fc040613          	addi	a2,s0,-64
    80005d88:	4581                	li	a1,0
    80005d8a:	8526                	mv	a0,s1
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	50c080e7          	jalr	1292(ra) # 80004298 <writei>
    80005d94:	47c1                	li	a5,16
    80005d96:	0af51563          	bne	a0,a5,80005e40 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d9a:	04491703          	lh	a4,68(s2)
    80005d9e:	4785                	li	a5,1
    80005da0:	0af70863          	beq	a4,a5,80005e50 <sys_unlink+0x18c>
  iunlockput(dp);
    80005da4:	8526                	mv	a0,s1
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	3a8080e7          	jalr	936(ra) # 8000414e <iunlockput>
  ip->nlink--;
    80005dae:	04a95783          	lhu	a5,74(s2)
    80005db2:	37fd                	addiw	a5,a5,-1
    80005db4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005db8:	854a                	mv	a0,s2
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	066080e7          	jalr	102(ra) # 80003e20 <iupdate>
  iunlockput(ip);
    80005dc2:	854a                	mv	a0,s2
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	38a080e7          	jalr	906(ra) # 8000414e <iunlockput>
  end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	b6a080e7          	jalr	-1174(ra) # 80004936 <end_op>
  return 0;
    80005dd4:	4501                	li	a0,0
    80005dd6:	a84d                	j	80005e88 <sys_unlink+0x1c4>
    end_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	b5e080e7          	jalr	-1186(ra) # 80004936 <end_op>
    return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	a05d                	j	80005e88 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005de4:	00003517          	auipc	a0,0x3
    80005de8:	98450513          	addi	a0,a0,-1660 # 80008768 <syscalls+0x2d8>
    80005dec:	ffffa097          	auipc	ra,0xffffa
    80005df0:	754080e7          	jalr	1876(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005df4:	04c92703          	lw	a4,76(s2)
    80005df8:	02000793          	li	a5,32
    80005dfc:	f6e7f9e3          	bgeu	a5,a4,80005d6e <sys_unlink+0xaa>
    80005e00:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e04:	4741                	li	a4,16
    80005e06:	86ce                	mv	a3,s3
    80005e08:	f1840613          	addi	a2,s0,-232
    80005e0c:	4581                	li	a1,0
    80005e0e:	854a                	mv	a0,s2
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	390080e7          	jalr	912(ra) # 800041a0 <readi>
    80005e18:	47c1                	li	a5,16
    80005e1a:	00f51b63          	bne	a0,a5,80005e30 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e1e:	f1845783          	lhu	a5,-232(s0)
    80005e22:	e7a1                	bnez	a5,80005e6a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e24:	29c1                	addiw	s3,s3,16
    80005e26:	04c92783          	lw	a5,76(s2)
    80005e2a:	fcf9ede3          	bltu	s3,a5,80005e04 <sys_unlink+0x140>
    80005e2e:	b781                	j	80005d6e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e30:	00003517          	auipc	a0,0x3
    80005e34:	95050513          	addi	a0,a0,-1712 # 80008780 <syscalls+0x2f0>
    80005e38:	ffffa097          	auipc	ra,0xffffa
    80005e3c:	708080e7          	jalr	1800(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005e40:	00003517          	auipc	a0,0x3
    80005e44:	95850513          	addi	a0,a0,-1704 # 80008798 <syscalls+0x308>
    80005e48:	ffffa097          	auipc	ra,0xffffa
    80005e4c:	6f8080e7          	jalr	1784(ra) # 80000540 <panic>
    dp->nlink--;
    80005e50:	04a4d783          	lhu	a5,74(s1)
    80005e54:	37fd                	addiw	a5,a5,-1
    80005e56:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e5a:	8526                	mv	a0,s1
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	fc4080e7          	jalr	-60(ra) # 80003e20 <iupdate>
    80005e64:	b781                	j	80005da4 <sys_unlink+0xe0>
    return -1;
    80005e66:	557d                	li	a0,-1
    80005e68:	a005                	j	80005e88 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e6a:	854a                	mv	a0,s2
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	2e2080e7          	jalr	738(ra) # 8000414e <iunlockput>
  iunlockput(dp);
    80005e74:	8526                	mv	a0,s1
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	2d8080e7          	jalr	728(ra) # 8000414e <iunlockput>
  end_op();
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	ab8080e7          	jalr	-1352(ra) # 80004936 <end_op>
  return -1;
    80005e86:	557d                	li	a0,-1
}
    80005e88:	70ae                	ld	ra,232(sp)
    80005e8a:	740e                	ld	s0,224(sp)
    80005e8c:	64ee                	ld	s1,216(sp)
    80005e8e:	694e                	ld	s2,208(sp)
    80005e90:	69ae                	ld	s3,200(sp)
    80005e92:	616d                	addi	sp,sp,240
    80005e94:	8082                	ret

0000000080005e96 <sys_open>:

uint64
sys_open(void)
{
    80005e96:	7131                	addi	sp,sp,-192
    80005e98:	fd06                	sd	ra,184(sp)
    80005e9a:	f922                	sd	s0,176(sp)
    80005e9c:	f526                	sd	s1,168(sp)
    80005e9e:	f14a                	sd	s2,160(sp)
    80005ea0:	ed4e                	sd	s3,152(sp)
    80005ea2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ea4:	f4c40593          	addi	a1,s0,-180
    80005ea8:	4505                	li	a0,1
    80005eaa:	ffffd097          	auipc	ra,0xffffd
    80005eae:	2fc080e7          	jalr	764(ra) # 800031a6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005eb2:	08000613          	li	a2,128
    80005eb6:	f5040593          	addi	a1,s0,-176
    80005eba:	4501                	li	a0,0
    80005ebc:	ffffd097          	auipc	ra,0xffffd
    80005ec0:	32a080e7          	jalr	810(ra) # 800031e6 <argstr>
    80005ec4:	87aa                	mv	a5,a0
    return -1;
    80005ec6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ec8:	0a07c963          	bltz	a5,80005f7a <sys_open+0xe4>

  begin_op();
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	9ec080e7          	jalr	-1556(ra) # 800048b8 <begin_op>

  if(omode & O_CREATE){
    80005ed4:	f4c42783          	lw	a5,-180(s0)
    80005ed8:	2007f793          	andi	a5,a5,512
    80005edc:	cfc5                	beqz	a5,80005f94 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ede:	4681                	li	a3,0
    80005ee0:	4601                	li	a2,0
    80005ee2:	4589                	li	a1,2
    80005ee4:	f5040513          	addi	a0,s0,-176
    80005ee8:	00000097          	auipc	ra,0x0
    80005eec:	972080e7          	jalr	-1678(ra) # 8000585a <create>
    80005ef0:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ef2:	c959                	beqz	a0,80005f88 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ef4:	04449703          	lh	a4,68(s1)
    80005ef8:	478d                	li	a5,3
    80005efa:	00f71763          	bne	a4,a5,80005f08 <sys_open+0x72>
    80005efe:	0464d703          	lhu	a4,70(s1)
    80005f02:	47a5                	li	a5,9
    80005f04:	0ce7ed63          	bltu	a5,a4,80005fde <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	dbc080e7          	jalr	-580(ra) # 80004cc4 <filealloc>
    80005f10:	89aa                	mv	s3,a0
    80005f12:	10050363          	beqz	a0,80006018 <sys_open+0x182>
    80005f16:	00000097          	auipc	ra,0x0
    80005f1a:	902080e7          	jalr	-1790(ra) # 80005818 <fdalloc>
    80005f1e:	892a                	mv	s2,a0
    80005f20:	0e054763          	bltz	a0,8000600e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f24:	04449703          	lh	a4,68(s1)
    80005f28:	478d                	li	a5,3
    80005f2a:	0cf70563          	beq	a4,a5,80005ff4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f2e:	4789                	li	a5,2
    80005f30:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f34:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f38:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f3c:	f4c42783          	lw	a5,-180(s0)
    80005f40:	0017c713          	xori	a4,a5,1
    80005f44:	8b05                	andi	a4,a4,1
    80005f46:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f4a:	0037f713          	andi	a4,a5,3
    80005f4e:	00e03733          	snez	a4,a4
    80005f52:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f56:	4007f793          	andi	a5,a5,1024
    80005f5a:	c791                	beqz	a5,80005f66 <sys_open+0xd0>
    80005f5c:	04449703          	lh	a4,68(s1)
    80005f60:	4789                	li	a5,2
    80005f62:	0af70063          	beq	a4,a5,80006002 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f66:	8526                	mv	a0,s1
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	046080e7          	jalr	70(ra) # 80003fae <iunlock>
  end_op();
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	9c6080e7          	jalr	-1594(ra) # 80004936 <end_op>

  return fd;
    80005f78:	854a                	mv	a0,s2
}
    80005f7a:	70ea                	ld	ra,184(sp)
    80005f7c:	744a                	ld	s0,176(sp)
    80005f7e:	74aa                	ld	s1,168(sp)
    80005f80:	790a                	ld	s2,160(sp)
    80005f82:	69ea                	ld	s3,152(sp)
    80005f84:	6129                	addi	sp,sp,192
    80005f86:	8082                	ret
      end_op();
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	9ae080e7          	jalr	-1618(ra) # 80004936 <end_op>
      return -1;
    80005f90:	557d                	li	a0,-1
    80005f92:	b7e5                	j	80005f7a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f94:	f5040513          	addi	a0,s0,-176
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	700080e7          	jalr	1792(ra) # 80004698 <namei>
    80005fa0:	84aa                	mv	s1,a0
    80005fa2:	c905                	beqz	a0,80005fd2 <sys_open+0x13c>
    ilock(ip);
    80005fa4:	ffffe097          	auipc	ra,0xffffe
    80005fa8:	f48080e7          	jalr	-184(ra) # 80003eec <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fac:	04449703          	lh	a4,68(s1)
    80005fb0:	4785                	li	a5,1
    80005fb2:	f4f711e3          	bne	a4,a5,80005ef4 <sys_open+0x5e>
    80005fb6:	f4c42783          	lw	a5,-180(s0)
    80005fba:	d7b9                	beqz	a5,80005f08 <sys_open+0x72>
      iunlockput(ip);
    80005fbc:	8526                	mv	a0,s1
    80005fbe:	ffffe097          	auipc	ra,0xffffe
    80005fc2:	190080e7          	jalr	400(ra) # 8000414e <iunlockput>
      end_op();
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	970080e7          	jalr	-1680(ra) # 80004936 <end_op>
      return -1;
    80005fce:	557d                	li	a0,-1
    80005fd0:	b76d                	j	80005f7a <sys_open+0xe4>
      end_op();
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	964080e7          	jalr	-1692(ra) # 80004936 <end_op>
      return -1;
    80005fda:	557d                	li	a0,-1
    80005fdc:	bf79                	j	80005f7a <sys_open+0xe4>
    iunlockput(ip);
    80005fde:	8526                	mv	a0,s1
    80005fe0:	ffffe097          	auipc	ra,0xffffe
    80005fe4:	16e080e7          	jalr	366(ra) # 8000414e <iunlockput>
    end_op();
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	94e080e7          	jalr	-1714(ra) # 80004936 <end_op>
    return -1;
    80005ff0:	557d                	li	a0,-1
    80005ff2:	b761                	j	80005f7a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ff4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ff8:	04649783          	lh	a5,70(s1)
    80005ffc:	02f99223          	sh	a5,36(s3)
    80006000:	bf25                	j	80005f38 <sys_open+0xa2>
    itrunc(ip);
    80006002:	8526                	mv	a0,s1
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	ff6080e7          	jalr	-10(ra) # 80003ffa <itrunc>
    8000600c:	bfa9                	j	80005f66 <sys_open+0xd0>
      fileclose(f);
    8000600e:	854e                	mv	a0,s3
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	d70080e7          	jalr	-656(ra) # 80004d80 <fileclose>
    iunlockput(ip);
    80006018:	8526                	mv	a0,s1
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	134080e7          	jalr	308(ra) # 8000414e <iunlockput>
    end_op();
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	914080e7          	jalr	-1772(ra) # 80004936 <end_op>
    return -1;
    8000602a:	557d                	li	a0,-1
    8000602c:	b7b9                	j	80005f7a <sys_open+0xe4>

000000008000602e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000602e:	7175                	addi	sp,sp,-144
    80006030:	e506                	sd	ra,136(sp)
    80006032:	e122                	sd	s0,128(sp)
    80006034:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	882080e7          	jalr	-1918(ra) # 800048b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000603e:	08000613          	li	a2,128
    80006042:	f7040593          	addi	a1,s0,-144
    80006046:	4501                	li	a0,0
    80006048:	ffffd097          	auipc	ra,0xffffd
    8000604c:	19e080e7          	jalr	414(ra) # 800031e6 <argstr>
    80006050:	02054963          	bltz	a0,80006082 <sys_mkdir+0x54>
    80006054:	4681                	li	a3,0
    80006056:	4601                	li	a2,0
    80006058:	4585                	li	a1,1
    8000605a:	f7040513          	addi	a0,s0,-144
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	7fc080e7          	jalr	2044(ra) # 8000585a <create>
    80006066:	cd11                	beqz	a0,80006082 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006068:	ffffe097          	auipc	ra,0xffffe
    8000606c:	0e6080e7          	jalr	230(ra) # 8000414e <iunlockput>
  end_op();
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	8c6080e7          	jalr	-1850(ra) # 80004936 <end_op>
  return 0;
    80006078:	4501                	li	a0,0
}
    8000607a:	60aa                	ld	ra,136(sp)
    8000607c:	640a                	ld	s0,128(sp)
    8000607e:	6149                	addi	sp,sp,144
    80006080:	8082                	ret
    end_op();
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	8b4080e7          	jalr	-1868(ra) # 80004936 <end_op>
    return -1;
    8000608a:	557d                	li	a0,-1
    8000608c:	b7fd                	j	8000607a <sys_mkdir+0x4c>

000000008000608e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000608e:	7135                	addi	sp,sp,-160
    80006090:	ed06                	sd	ra,152(sp)
    80006092:	e922                	sd	s0,144(sp)
    80006094:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006096:	fffff097          	auipc	ra,0xfffff
    8000609a:	822080e7          	jalr	-2014(ra) # 800048b8 <begin_op>
  argint(1, &major);
    8000609e:	f6c40593          	addi	a1,s0,-148
    800060a2:	4505                	li	a0,1
    800060a4:	ffffd097          	auipc	ra,0xffffd
    800060a8:	102080e7          	jalr	258(ra) # 800031a6 <argint>
  argint(2, &minor);
    800060ac:	f6840593          	addi	a1,s0,-152
    800060b0:	4509                	li	a0,2
    800060b2:	ffffd097          	auipc	ra,0xffffd
    800060b6:	0f4080e7          	jalr	244(ra) # 800031a6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060ba:	08000613          	li	a2,128
    800060be:	f7040593          	addi	a1,s0,-144
    800060c2:	4501                	li	a0,0
    800060c4:	ffffd097          	auipc	ra,0xffffd
    800060c8:	122080e7          	jalr	290(ra) # 800031e6 <argstr>
    800060cc:	02054b63          	bltz	a0,80006102 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060d0:	f6841683          	lh	a3,-152(s0)
    800060d4:	f6c41603          	lh	a2,-148(s0)
    800060d8:	458d                	li	a1,3
    800060da:	f7040513          	addi	a0,s0,-144
    800060de:	fffff097          	auipc	ra,0xfffff
    800060e2:	77c080e7          	jalr	1916(ra) # 8000585a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060e6:	cd11                	beqz	a0,80006102 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	066080e7          	jalr	102(ra) # 8000414e <iunlockput>
  end_op();
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	846080e7          	jalr	-1978(ra) # 80004936 <end_op>
  return 0;
    800060f8:	4501                	li	a0,0
}
    800060fa:	60ea                	ld	ra,152(sp)
    800060fc:	644a                	ld	s0,144(sp)
    800060fe:	610d                	addi	sp,sp,160
    80006100:	8082                	ret
    end_op();
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	834080e7          	jalr	-1996(ra) # 80004936 <end_op>
    return -1;
    8000610a:	557d                	li	a0,-1
    8000610c:	b7fd                	j	800060fa <sys_mknod+0x6c>

000000008000610e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000610e:	7135                	addi	sp,sp,-160
    80006110:	ed06                	sd	ra,152(sp)
    80006112:	e922                	sd	s0,144(sp)
    80006114:	e526                	sd	s1,136(sp)
    80006116:	e14a                	sd	s2,128(sp)
    80006118:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000611a:	ffffc097          	auipc	ra,0xffffc
    8000611e:	a3c080e7          	jalr	-1476(ra) # 80001b56 <myproc>
    80006122:	892a                	mv	s2,a0
  
  begin_op();
    80006124:	ffffe097          	auipc	ra,0xffffe
    80006128:	794080e7          	jalr	1940(ra) # 800048b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000612c:	08000613          	li	a2,128
    80006130:	f6040593          	addi	a1,s0,-160
    80006134:	4501                	li	a0,0
    80006136:	ffffd097          	auipc	ra,0xffffd
    8000613a:	0b0080e7          	jalr	176(ra) # 800031e6 <argstr>
    8000613e:	04054b63          	bltz	a0,80006194 <sys_chdir+0x86>
    80006142:	f6040513          	addi	a0,s0,-160
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	552080e7          	jalr	1362(ra) # 80004698 <namei>
    8000614e:	84aa                	mv	s1,a0
    80006150:	c131                	beqz	a0,80006194 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006152:	ffffe097          	auipc	ra,0xffffe
    80006156:	d9a080e7          	jalr	-614(ra) # 80003eec <ilock>
  if(ip->type != T_DIR){
    8000615a:	04449703          	lh	a4,68(s1)
    8000615e:	4785                	li	a5,1
    80006160:	04f71063          	bne	a4,a5,800061a0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006164:	8526                	mv	a0,s1
    80006166:	ffffe097          	auipc	ra,0xffffe
    8000616a:	e48080e7          	jalr	-440(ra) # 80003fae <iunlock>
  iput(p->cwd);
    8000616e:	15093503          	ld	a0,336(s2)
    80006172:	ffffe097          	auipc	ra,0xffffe
    80006176:	f34080e7          	jalr	-204(ra) # 800040a6 <iput>
  end_op();
    8000617a:	ffffe097          	auipc	ra,0xffffe
    8000617e:	7bc080e7          	jalr	1980(ra) # 80004936 <end_op>
  p->cwd = ip;
    80006182:	14993823          	sd	s1,336(s2)
  return 0;
    80006186:	4501                	li	a0,0
}
    80006188:	60ea                	ld	ra,152(sp)
    8000618a:	644a                	ld	s0,144(sp)
    8000618c:	64aa                	ld	s1,136(sp)
    8000618e:	690a                	ld	s2,128(sp)
    80006190:	610d                	addi	sp,sp,160
    80006192:	8082                	ret
    end_op();
    80006194:	ffffe097          	auipc	ra,0xffffe
    80006198:	7a2080e7          	jalr	1954(ra) # 80004936 <end_op>
    return -1;
    8000619c:	557d                	li	a0,-1
    8000619e:	b7ed                	j	80006188 <sys_chdir+0x7a>
    iunlockput(ip);
    800061a0:	8526                	mv	a0,s1
    800061a2:	ffffe097          	auipc	ra,0xffffe
    800061a6:	fac080e7          	jalr	-84(ra) # 8000414e <iunlockput>
    end_op();
    800061aa:	ffffe097          	auipc	ra,0xffffe
    800061ae:	78c080e7          	jalr	1932(ra) # 80004936 <end_op>
    return -1;
    800061b2:	557d                	li	a0,-1
    800061b4:	bfd1                	j	80006188 <sys_chdir+0x7a>

00000000800061b6 <sys_exec>:

uint64
sys_exec(void)
{
    800061b6:	7145                	addi	sp,sp,-464
    800061b8:	e786                	sd	ra,456(sp)
    800061ba:	e3a2                	sd	s0,448(sp)
    800061bc:	ff26                	sd	s1,440(sp)
    800061be:	fb4a                	sd	s2,432(sp)
    800061c0:	f74e                	sd	s3,424(sp)
    800061c2:	f352                	sd	s4,416(sp)
    800061c4:	ef56                	sd	s5,408(sp)
    800061c6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800061c8:	e3840593          	addi	a1,s0,-456
    800061cc:	4505                	li	a0,1
    800061ce:	ffffd097          	auipc	ra,0xffffd
    800061d2:	ff8080e7          	jalr	-8(ra) # 800031c6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800061d6:	08000613          	li	a2,128
    800061da:	f4040593          	addi	a1,s0,-192
    800061de:	4501                	li	a0,0
    800061e0:	ffffd097          	auipc	ra,0xffffd
    800061e4:	006080e7          	jalr	6(ra) # 800031e6 <argstr>
    800061e8:	87aa                	mv	a5,a0
    return -1;
    800061ea:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800061ec:	0c07c363          	bltz	a5,800062b2 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800061f0:	10000613          	li	a2,256
    800061f4:	4581                	li	a1,0
    800061f6:	e4040513          	addi	a0,s0,-448
    800061fa:	ffffb097          	auipc	ra,0xffffb
    800061fe:	ad8080e7          	jalr	-1320(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006202:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006206:	89a6                	mv	s3,s1
    80006208:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000620a:	02000a13          	li	s4,32
    8000620e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006212:	00391513          	slli	a0,s2,0x3
    80006216:	e3040593          	addi	a1,s0,-464
    8000621a:	e3843783          	ld	a5,-456(s0)
    8000621e:	953e                	add	a0,a0,a5
    80006220:	ffffd097          	auipc	ra,0xffffd
    80006224:	ee8080e7          	jalr	-280(ra) # 80003108 <fetchaddr>
    80006228:	02054a63          	bltz	a0,8000625c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000622c:	e3043783          	ld	a5,-464(s0)
    80006230:	c3b9                	beqz	a5,80006276 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006232:	ffffb097          	auipc	ra,0xffffb
    80006236:	8b4080e7          	jalr	-1868(ra) # 80000ae6 <kalloc>
    8000623a:	85aa                	mv	a1,a0
    8000623c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006240:	cd11                	beqz	a0,8000625c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006242:	6605                	lui	a2,0x1
    80006244:	e3043503          	ld	a0,-464(s0)
    80006248:	ffffd097          	auipc	ra,0xffffd
    8000624c:	f12080e7          	jalr	-238(ra) # 8000315a <fetchstr>
    80006250:	00054663          	bltz	a0,8000625c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006254:	0905                	addi	s2,s2,1
    80006256:	09a1                	addi	s3,s3,8
    80006258:	fb491be3          	bne	s2,s4,8000620e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000625c:	f4040913          	addi	s2,s0,-192
    80006260:	6088                	ld	a0,0(s1)
    80006262:	c539                	beqz	a0,800062b0 <sys_exec+0xfa>
    kfree(argv[i]);
    80006264:	ffffa097          	auipc	ra,0xffffa
    80006268:	784080e7          	jalr	1924(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000626c:	04a1                	addi	s1,s1,8
    8000626e:	ff2499e3          	bne	s1,s2,80006260 <sys_exec+0xaa>
  return -1;
    80006272:	557d                	li	a0,-1
    80006274:	a83d                	j	800062b2 <sys_exec+0xfc>
      argv[i] = 0;
    80006276:	0a8e                	slli	s5,s5,0x3
    80006278:	fc0a8793          	addi	a5,s5,-64
    8000627c:	00878ab3          	add	s5,a5,s0
    80006280:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006284:	e4040593          	addi	a1,s0,-448
    80006288:	f4040513          	addi	a0,s0,-192
    8000628c:	fffff097          	auipc	ra,0xfffff
    80006290:	16e080e7          	jalr	366(ra) # 800053fa <exec>
    80006294:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006296:	f4040993          	addi	s3,s0,-192
    8000629a:	6088                	ld	a0,0(s1)
    8000629c:	c901                	beqz	a0,800062ac <sys_exec+0xf6>
    kfree(argv[i]);
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	74a080e7          	jalr	1866(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062a6:	04a1                	addi	s1,s1,8
    800062a8:	ff3499e3          	bne	s1,s3,8000629a <sys_exec+0xe4>
  return ret;
    800062ac:	854a                	mv	a0,s2
    800062ae:	a011                	j	800062b2 <sys_exec+0xfc>
  return -1;
    800062b0:	557d                	li	a0,-1
}
    800062b2:	60be                	ld	ra,456(sp)
    800062b4:	641e                	ld	s0,448(sp)
    800062b6:	74fa                	ld	s1,440(sp)
    800062b8:	795a                	ld	s2,432(sp)
    800062ba:	79ba                	ld	s3,424(sp)
    800062bc:	7a1a                	ld	s4,416(sp)
    800062be:	6afa                	ld	s5,408(sp)
    800062c0:	6179                	addi	sp,sp,464
    800062c2:	8082                	ret

00000000800062c4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062c4:	7139                	addi	sp,sp,-64
    800062c6:	fc06                	sd	ra,56(sp)
    800062c8:	f822                	sd	s0,48(sp)
    800062ca:	f426                	sd	s1,40(sp)
    800062cc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062ce:	ffffc097          	auipc	ra,0xffffc
    800062d2:	888080e7          	jalr	-1912(ra) # 80001b56 <myproc>
    800062d6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800062d8:	fd840593          	addi	a1,s0,-40
    800062dc:	4501                	li	a0,0
    800062de:	ffffd097          	auipc	ra,0xffffd
    800062e2:	ee8080e7          	jalr	-280(ra) # 800031c6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800062e6:	fc840593          	addi	a1,s0,-56
    800062ea:	fd040513          	addi	a0,s0,-48
    800062ee:	fffff097          	auipc	ra,0xfffff
    800062f2:	dc2080e7          	jalr	-574(ra) # 800050b0 <pipealloc>
    return -1;
    800062f6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062f8:	0c054463          	bltz	a0,800063c0 <sys_pipe+0xfc>
  fd0 = -1;
    800062fc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006300:	fd043503          	ld	a0,-48(s0)
    80006304:	fffff097          	auipc	ra,0xfffff
    80006308:	514080e7          	jalr	1300(ra) # 80005818 <fdalloc>
    8000630c:	fca42223          	sw	a0,-60(s0)
    80006310:	08054b63          	bltz	a0,800063a6 <sys_pipe+0xe2>
    80006314:	fc843503          	ld	a0,-56(s0)
    80006318:	fffff097          	auipc	ra,0xfffff
    8000631c:	500080e7          	jalr	1280(ra) # 80005818 <fdalloc>
    80006320:	fca42023          	sw	a0,-64(s0)
    80006324:	06054863          	bltz	a0,80006394 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006328:	4691                	li	a3,4
    8000632a:	fc440613          	addi	a2,s0,-60
    8000632e:	fd843583          	ld	a1,-40(s0)
    80006332:	68a8                	ld	a0,80(s1)
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	338080e7          	jalr	824(ra) # 8000166c <copyout>
    8000633c:	02054063          	bltz	a0,8000635c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006340:	4691                	li	a3,4
    80006342:	fc040613          	addi	a2,s0,-64
    80006346:	fd843583          	ld	a1,-40(s0)
    8000634a:	0591                	addi	a1,a1,4
    8000634c:	68a8                	ld	a0,80(s1)
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	31e080e7          	jalr	798(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006356:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006358:	06055463          	bgez	a0,800063c0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000635c:	fc442783          	lw	a5,-60(s0)
    80006360:	07e9                	addi	a5,a5,26
    80006362:	078e                	slli	a5,a5,0x3
    80006364:	97a6                	add	a5,a5,s1
    80006366:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000636a:	fc042783          	lw	a5,-64(s0)
    8000636e:	07e9                	addi	a5,a5,26
    80006370:	078e                	slli	a5,a5,0x3
    80006372:	94be                	add	s1,s1,a5
    80006374:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006378:	fd043503          	ld	a0,-48(s0)
    8000637c:	fffff097          	auipc	ra,0xfffff
    80006380:	a04080e7          	jalr	-1532(ra) # 80004d80 <fileclose>
    fileclose(wf);
    80006384:	fc843503          	ld	a0,-56(s0)
    80006388:	fffff097          	auipc	ra,0xfffff
    8000638c:	9f8080e7          	jalr	-1544(ra) # 80004d80 <fileclose>
    return -1;
    80006390:	57fd                	li	a5,-1
    80006392:	a03d                	j	800063c0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006394:	fc442783          	lw	a5,-60(s0)
    80006398:	0007c763          	bltz	a5,800063a6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000639c:	07e9                	addi	a5,a5,26
    8000639e:	078e                	slli	a5,a5,0x3
    800063a0:	97a6                	add	a5,a5,s1
    800063a2:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800063a6:	fd043503          	ld	a0,-48(s0)
    800063aa:	fffff097          	auipc	ra,0xfffff
    800063ae:	9d6080e7          	jalr	-1578(ra) # 80004d80 <fileclose>
    fileclose(wf);
    800063b2:	fc843503          	ld	a0,-56(s0)
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	9ca080e7          	jalr	-1590(ra) # 80004d80 <fileclose>
    return -1;
    800063be:	57fd                	li	a5,-1
}
    800063c0:	853e                	mv	a0,a5
    800063c2:	70e2                	ld	ra,56(sp)
    800063c4:	7442                	ld	s0,48(sp)
    800063c6:	74a2                	ld	s1,40(sp)
    800063c8:	6121                	addi	sp,sp,64
    800063ca:	8082                	ret
    800063cc:	0000                	unimp
	...

00000000800063d0 <kernelvec>:
    800063d0:	7111                	addi	sp,sp,-256
    800063d2:	e006                	sd	ra,0(sp)
    800063d4:	e40a                	sd	sp,8(sp)
    800063d6:	e80e                	sd	gp,16(sp)
    800063d8:	ec12                	sd	tp,24(sp)
    800063da:	f016                	sd	t0,32(sp)
    800063dc:	f41a                	sd	t1,40(sp)
    800063de:	f81e                	sd	t2,48(sp)
    800063e0:	fc22                	sd	s0,56(sp)
    800063e2:	e0a6                	sd	s1,64(sp)
    800063e4:	e4aa                	sd	a0,72(sp)
    800063e6:	e8ae                	sd	a1,80(sp)
    800063e8:	ecb2                	sd	a2,88(sp)
    800063ea:	f0b6                	sd	a3,96(sp)
    800063ec:	f4ba                	sd	a4,104(sp)
    800063ee:	f8be                	sd	a5,112(sp)
    800063f0:	fcc2                	sd	a6,120(sp)
    800063f2:	e146                	sd	a7,128(sp)
    800063f4:	e54a                	sd	s2,136(sp)
    800063f6:	e94e                	sd	s3,144(sp)
    800063f8:	ed52                	sd	s4,152(sp)
    800063fa:	f156                	sd	s5,160(sp)
    800063fc:	f55a                	sd	s6,168(sp)
    800063fe:	f95e                	sd	s7,176(sp)
    80006400:	fd62                	sd	s8,184(sp)
    80006402:	e1e6                	sd	s9,192(sp)
    80006404:	e5ea                	sd	s10,200(sp)
    80006406:	e9ee                	sd	s11,208(sp)
    80006408:	edf2                	sd	t3,216(sp)
    8000640a:	f1f6                	sd	t4,224(sp)
    8000640c:	f5fa                	sd	t5,232(sp)
    8000640e:	f9fe                	sd	t6,240(sp)
    80006410:	b1ffc0ef          	jal	ra,80002f2e <kerneltrap>
    80006414:	6082                	ld	ra,0(sp)
    80006416:	6122                	ld	sp,8(sp)
    80006418:	61c2                	ld	gp,16(sp)
    8000641a:	7282                	ld	t0,32(sp)
    8000641c:	7322                	ld	t1,40(sp)
    8000641e:	73c2                	ld	t2,48(sp)
    80006420:	7462                	ld	s0,56(sp)
    80006422:	6486                	ld	s1,64(sp)
    80006424:	6526                	ld	a0,72(sp)
    80006426:	65c6                	ld	a1,80(sp)
    80006428:	6666                	ld	a2,88(sp)
    8000642a:	7686                	ld	a3,96(sp)
    8000642c:	7726                	ld	a4,104(sp)
    8000642e:	77c6                	ld	a5,112(sp)
    80006430:	7866                	ld	a6,120(sp)
    80006432:	688a                	ld	a7,128(sp)
    80006434:	692a                	ld	s2,136(sp)
    80006436:	69ca                	ld	s3,144(sp)
    80006438:	6a6a                	ld	s4,152(sp)
    8000643a:	7a8a                	ld	s5,160(sp)
    8000643c:	7b2a                	ld	s6,168(sp)
    8000643e:	7bca                	ld	s7,176(sp)
    80006440:	7c6a                	ld	s8,184(sp)
    80006442:	6c8e                	ld	s9,192(sp)
    80006444:	6d2e                	ld	s10,200(sp)
    80006446:	6dce                	ld	s11,208(sp)
    80006448:	6e6e                	ld	t3,216(sp)
    8000644a:	7e8e                	ld	t4,224(sp)
    8000644c:	7f2e                	ld	t5,232(sp)
    8000644e:	7fce                	ld	t6,240(sp)
    80006450:	6111                	addi	sp,sp,256
    80006452:	10200073          	sret
    80006456:	00000013          	nop
    8000645a:	00000013          	nop
    8000645e:	0001                	nop

0000000080006460 <timervec>:
    80006460:	34051573          	csrrw	a0,mscratch,a0
    80006464:	e10c                	sd	a1,0(a0)
    80006466:	e510                	sd	a2,8(a0)
    80006468:	e914                	sd	a3,16(a0)
    8000646a:	6d0c                	ld	a1,24(a0)
    8000646c:	7110                	ld	a2,32(a0)
    8000646e:	6194                	ld	a3,0(a1)
    80006470:	96b2                	add	a3,a3,a2
    80006472:	e194                	sd	a3,0(a1)
    80006474:	4589                	li	a1,2
    80006476:	14459073          	csrw	sip,a1
    8000647a:	6914                	ld	a3,16(a0)
    8000647c:	6510                	ld	a2,8(a0)
    8000647e:	610c                	ld	a1,0(a0)
    80006480:	34051573          	csrrw	a0,mscratch,a0
    80006484:	30200073          	mret
	...

000000008000648a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000648a:	1141                	addi	sp,sp,-16
    8000648c:	e422                	sd	s0,8(sp)
    8000648e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006490:	0c0007b7          	lui	a5,0xc000
    80006494:	4705                	li	a4,1
    80006496:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006498:	c3d8                	sw	a4,4(a5)
}
    8000649a:	6422                	ld	s0,8(sp)
    8000649c:	0141                	addi	sp,sp,16
    8000649e:	8082                	ret

00000000800064a0 <plicinithart>:

void
plicinithart(void)
{
    800064a0:	1141                	addi	sp,sp,-16
    800064a2:	e406                	sd	ra,8(sp)
    800064a4:	e022                	sd	s0,0(sp)
    800064a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064a8:	ffffb097          	auipc	ra,0xffffb
    800064ac:	682080e7          	jalr	1666(ra) # 80001b2a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064b0:	0085171b          	slliw	a4,a0,0x8
    800064b4:	0c0027b7          	lui	a5,0xc002
    800064b8:	97ba                	add	a5,a5,a4
    800064ba:	40200713          	li	a4,1026
    800064be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064c2:	00d5151b          	slliw	a0,a0,0xd
    800064c6:	0c2017b7          	lui	a5,0xc201
    800064ca:	97aa                	add	a5,a5,a0
    800064cc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800064d0:	60a2                	ld	ra,8(sp)
    800064d2:	6402                	ld	s0,0(sp)
    800064d4:	0141                	addi	sp,sp,16
    800064d6:	8082                	ret

00000000800064d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064d8:	1141                	addi	sp,sp,-16
    800064da:	e406                	sd	ra,8(sp)
    800064dc:	e022                	sd	s0,0(sp)
    800064de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064e0:	ffffb097          	auipc	ra,0xffffb
    800064e4:	64a080e7          	jalr	1610(ra) # 80001b2a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064e8:	00d5151b          	slliw	a0,a0,0xd
    800064ec:	0c2017b7          	lui	a5,0xc201
    800064f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800064f2:	43c8                	lw	a0,4(a5)
    800064f4:	60a2                	ld	ra,8(sp)
    800064f6:	6402                	ld	s0,0(sp)
    800064f8:	0141                	addi	sp,sp,16
    800064fa:	8082                	ret

00000000800064fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064fc:	1101                	addi	sp,sp,-32
    800064fe:	ec06                	sd	ra,24(sp)
    80006500:	e822                	sd	s0,16(sp)
    80006502:	e426                	sd	s1,8(sp)
    80006504:	1000                	addi	s0,sp,32
    80006506:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006508:	ffffb097          	auipc	ra,0xffffb
    8000650c:	622080e7          	jalr	1570(ra) # 80001b2a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006510:	00d5151b          	slliw	a0,a0,0xd
    80006514:	0c2017b7          	lui	a5,0xc201
    80006518:	97aa                	add	a5,a5,a0
    8000651a:	c3c4                	sw	s1,4(a5)
}
    8000651c:	60e2                	ld	ra,24(sp)
    8000651e:	6442                	ld	s0,16(sp)
    80006520:	64a2                	ld	s1,8(sp)
    80006522:	6105                	addi	sp,sp,32
    80006524:	8082                	ret

0000000080006526 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006526:	1141                	addi	sp,sp,-16
    80006528:	e406                	sd	ra,8(sp)
    8000652a:	e022                	sd	s0,0(sp)
    8000652c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000652e:	479d                	li	a5,7
    80006530:	04a7cc63          	blt	a5,a0,80006588 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006534:	0001e797          	auipc	a5,0x1e
    80006538:	56c78793          	addi	a5,a5,1388 # 80024aa0 <disk>
    8000653c:	97aa                	add	a5,a5,a0
    8000653e:	0187c783          	lbu	a5,24(a5)
    80006542:	ebb9                	bnez	a5,80006598 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006544:	00451693          	slli	a3,a0,0x4
    80006548:	0001e797          	auipc	a5,0x1e
    8000654c:	55878793          	addi	a5,a5,1368 # 80024aa0 <disk>
    80006550:	6398                	ld	a4,0(a5)
    80006552:	9736                	add	a4,a4,a3
    80006554:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006558:	6398                	ld	a4,0(a5)
    8000655a:	9736                	add	a4,a4,a3
    8000655c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006560:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006564:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006568:	97aa                	add	a5,a5,a0
    8000656a:	4705                	li	a4,1
    8000656c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006570:	0001e517          	auipc	a0,0x1e
    80006574:	54850513          	addi	a0,a0,1352 # 80024ab8 <disk+0x18>
    80006578:	ffffc097          	auipc	ra,0xffffc
    8000657c:	e76080e7          	jalr	-394(ra) # 800023ee <wakeup>
}
    80006580:	60a2                	ld	ra,8(sp)
    80006582:	6402                	ld	s0,0(sp)
    80006584:	0141                	addi	sp,sp,16
    80006586:	8082                	ret
    panic("free_desc 1");
    80006588:	00002517          	auipc	a0,0x2
    8000658c:	22050513          	addi	a0,a0,544 # 800087a8 <syscalls+0x318>
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	fb0080e7          	jalr	-80(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006598:	00002517          	auipc	a0,0x2
    8000659c:	22050513          	addi	a0,a0,544 # 800087b8 <syscalls+0x328>
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	fa0080e7          	jalr	-96(ra) # 80000540 <panic>

00000000800065a8 <virtio_disk_init>:
{
    800065a8:	1101                	addi	sp,sp,-32
    800065aa:	ec06                	sd	ra,24(sp)
    800065ac:	e822                	sd	s0,16(sp)
    800065ae:	e426                	sd	s1,8(sp)
    800065b0:	e04a                	sd	s2,0(sp)
    800065b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065b4:	00002597          	auipc	a1,0x2
    800065b8:	21458593          	addi	a1,a1,532 # 800087c8 <syscalls+0x338>
    800065bc:	0001e517          	auipc	a0,0x1e
    800065c0:	60c50513          	addi	a0,a0,1548 # 80024bc8 <disk+0x128>
    800065c4:	ffffa097          	auipc	ra,0xffffa
    800065c8:	582080e7          	jalr	1410(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065cc:	100017b7          	lui	a5,0x10001
    800065d0:	4398                	lw	a4,0(a5)
    800065d2:	2701                	sext.w	a4,a4
    800065d4:	747277b7          	lui	a5,0x74727
    800065d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065dc:	14f71b63          	bne	a4,a5,80006732 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065e0:	100017b7          	lui	a5,0x10001
    800065e4:	43dc                	lw	a5,4(a5)
    800065e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065e8:	4709                	li	a4,2
    800065ea:	14e79463          	bne	a5,a4,80006732 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065ee:	100017b7          	lui	a5,0x10001
    800065f2:	479c                	lw	a5,8(a5)
    800065f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065f6:	12e79e63          	bne	a5,a4,80006732 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065fa:	100017b7          	lui	a5,0x10001
    800065fe:	47d8                	lw	a4,12(a5)
    80006600:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006602:	554d47b7          	lui	a5,0x554d4
    80006606:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000660a:	12f71463          	bne	a4,a5,80006732 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000660e:	100017b7          	lui	a5,0x10001
    80006612:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006616:	4705                	li	a4,1
    80006618:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000661a:	470d                	li	a4,3
    8000661c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000661e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006620:	c7ffe6b7          	lui	a3,0xc7ffe
    80006624:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9b7f>
    80006628:	8f75                	and	a4,a4,a3
    8000662a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000662c:	472d                	li	a4,11
    8000662e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006630:	5bbc                	lw	a5,112(a5)
    80006632:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006636:	8ba1                	andi	a5,a5,8
    80006638:	10078563          	beqz	a5,80006742 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000663c:	100017b7          	lui	a5,0x10001
    80006640:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006644:	43fc                	lw	a5,68(a5)
    80006646:	2781                	sext.w	a5,a5
    80006648:	10079563          	bnez	a5,80006752 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000664c:	100017b7          	lui	a5,0x10001
    80006650:	5bdc                	lw	a5,52(a5)
    80006652:	2781                	sext.w	a5,a5
  if(max == 0)
    80006654:	10078763          	beqz	a5,80006762 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006658:	471d                	li	a4,7
    8000665a:	10f77c63          	bgeu	a4,a5,80006772 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	488080e7          	jalr	1160(ra) # 80000ae6 <kalloc>
    80006666:	0001e497          	auipc	s1,0x1e
    8000666a:	43a48493          	addi	s1,s1,1082 # 80024aa0 <disk>
    8000666e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006670:	ffffa097          	auipc	ra,0xffffa
    80006674:	476080e7          	jalr	1142(ra) # 80000ae6 <kalloc>
    80006678:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000667a:	ffffa097          	auipc	ra,0xffffa
    8000667e:	46c080e7          	jalr	1132(ra) # 80000ae6 <kalloc>
    80006682:	87aa                	mv	a5,a0
    80006684:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006686:	6088                	ld	a0,0(s1)
    80006688:	cd6d                	beqz	a0,80006782 <virtio_disk_init+0x1da>
    8000668a:	0001e717          	auipc	a4,0x1e
    8000668e:	41e73703          	ld	a4,1054(a4) # 80024aa8 <disk+0x8>
    80006692:	cb65                	beqz	a4,80006782 <virtio_disk_init+0x1da>
    80006694:	c7fd                	beqz	a5,80006782 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006696:	6605                	lui	a2,0x1
    80006698:	4581                	li	a1,0
    8000669a:	ffffa097          	auipc	ra,0xffffa
    8000669e:	638080e7          	jalr	1592(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800066a2:	0001e497          	auipc	s1,0x1e
    800066a6:	3fe48493          	addi	s1,s1,1022 # 80024aa0 <disk>
    800066aa:	6605                	lui	a2,0x1
    800066ac:	4581                	li	a1,0
    800066ae:	6488                	ld	a0,8(s1)
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	622080e7          	jalr	1570(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800066b8:	6605                	lui	a2,0x1
    800066ba:	4581                	li	a1,0
    800066bc:	6888                	ld	a0,16(s1)
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	614080e7          	jalr	1556(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800066c6:	100017b7          	lui	a5,0x10001
    800066ca:	4721                	li	a4,8
    800066cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800066ce:	4098                	lw	a4,0(s1)
    800066d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800066d4:	40d8                	lw	a4,4(s1)
    800066d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800066da:	6498                	ld	a4,8(s1)
    800066dc:	0007069b          	sext.w	a3,a4
    800066e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800066e4:	9701                	srai	a4,a4,0x20
    800066e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800066ea:	6898                	ld	a4,16(s1)
    800066ec:	0007069b          	sext.w	a3,a4
    800066f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800066f4:	9701                	srai	a4,a4,0x20
    800066f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800066fa:	4705                	li	a4,1
    800066fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800066fe:	00e48c23          	sb	a4,24(s1)
    80006702:	00e48ca3          	sb	a4,25(s1)
    80006706:	00e48d23          	sb	a4,26(s1)
    8000670a:	00e48da3          	sb	a4,27(s1)
    8000670e:	00e48e23          	sb	a4,28(s1)
    80006712:	00e48ea3          	sb	a4,29(s1)
    80006716:	00e48f23          	sb	a4,30(s1)
    8000671a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000671e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006722:	0727a823          	sw	s2,112(a5)
}
    80006726:	60e2                	ld	ra,24(sp)
    80006728:	6442                	ld	s0,16(sp)
    8000672a:	64a2                	ld	s1,8(sp)
    8000672c:	6902                	ld	s2,0(sp)
    8000672e:	6105                	addi	sp,sp,32
    80006730:	8082                	ret
    panic("could not find virtio disk");
    80006732:	00002517          	auipc	a0,0x2
    80006736:	0a650513          	addi	a0,a0,166 # 800087d8 <syscalls+0x348>
    8000673a:	ffffa097          	auipc	ra,0xffffa
    8000673e:	e06080e7          	jalr	-506(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006742:	00002517          	auipc	a0,0x2
    80006746:	0b650513          	addi	a0,a0,182 # 800087f8 <syscalls+0x368>
    8000674a:	ffffa097          	auipc	ra,0xffffa
    8000674e:	df6080e7          	jalr	-522(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006752:	00002517          	auipc	a0,0x2
    80006756:	0c650513          	addi	a0,a0,198 # 80008818 <syscalls+0x388>
    8000675a:	ffffa097          	auipc	ra,0xffffa
    8000675e:	de6080e7          	jalr	-538(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006762:	00002517          	auipc	a0,0x2
    80006766:	0d650513          	addi	a0,a0,214 # 80008838 <syscalls+0x3a8>
    8000676a:	ffffa097          	auipc	ra,0xffffa
    8000676e:	dd6080e7          	jalr	-554(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006772:	00002517          	auipc	a0,0x2
    80006776:	0e650513          	addi	a0,a0,230 # 80008858 <syscalls+0x3c8>
    8000677a:	ffffa097          	auipc	ra,0xffffa
    8000677e:	dc6080e7          	jalr	-570(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006782:	00002517          	auipc	a0,0x2
    80006786:	0f650513          	addi	a0,a0,246 # 80008878 <syscalls+0x3e8>
    8000678a:	ffffa097          	auipc	ra,0xffffa
    8000678e:	db6080e7          	jalr	-586(ra) # 80000540 <panic>

0000000080006792 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006792:	7119                	addi	sp,sp,-128
    80006794:	fc86                	sd	ra,120(sp)
    80006796:	f8a2                	sd	s0,112(sp)
    80006798:	f4a6                	sd	s1,104(sp)
    8000679a:	f0ca                	sd	s2,96(sp)
    8000679c:	ecce                	sd	s3,88(sp)
    8000679e:	e8d2                	sd	s4,80(sp)
    800067a0:	e4d6                	sd	s5,72(sp)
    800067a2:	e0da                	sd	s6,64(sp)
    800067a4:	fc5e                	sd	s7,56(sp)
    800067a6:	f862                	sd	s8,48(sp)
    800067a8:	f466                	sd	s9,40(sp)
    800067aa:	f06a                	sd	s10,32(sp)
    800067ac:	ec6e                	sd	s11,24(sp)
    800067ae:	0100                	addi	s0,sp,128
    800067b0:	8aaa                	mv	s5,a0
    800067b2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067b4:	00c52d03          	lw	s10,12(a0)
    800067b8:	001d1d1b          	slliw	s10,s10,0x1
    800067bc:	1d02                	slli	s10,s10,0x20
    800067be:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800067c2:	0001e517          	auipc	a0,0x1e
    800067c6:	40650513          	addi	a0,a0,1030 # 80024bc8 <disk+0x128>
    800067ca:	ffffa097          	auipc	ra,0xffffa
    800067ce:	40c080e7          	jalr	1036(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800067d2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800067d6:	0001eb97          	auipc	s7,0x1e
    800067da:	2cab8b93          	addi	s7,s7,714 # 80024aa0 <disk>
  for(int i = 0; i < 3; i++){
    800067de:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067e0:	0001ec97          	auipc	s9,0x1e
    800067e4:	3e8c8c93          	addi	s9,s9,1000 # 80024bc8 <disk+0x128>
    800067e8:	a08d                	j	8000684a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800067ea:	00fb8733          	add	a4,s7,a5
    800067ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800067f2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800067f4:	0207c563          	bltz	a5,8000681e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800067f8:	2905                	addiw	s2,s2,1
    800067fa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800067fc:	05690c63          	beq	s2,s6,80006854 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006800:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006802:	0001e717          	auipc	a4,0x1e
    80006806:	29e70713          	addi	a4,a4,670 # 80024aa0 <disk>
    8000680a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000680c:	01874683          	lbu	a3,24(a4)
    80006810:	fee9                	bnez	a3,800067ea <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006812:	2785                	addiw	a5,a5,1
    80006814:	0705                	addi	a4,a4,1
    80006816:	fe979be3          	bne	a5,s1,8000680c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000681a:	57fd                	li	a5,-1
    8000681c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000681e:	01205d63          	blez	s2,80006838 <virtio_disk_rw+0xa6>
    80006822:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006824:	000a2503          	lw	a0,0(s4)
    80006828:	00000097          	auipc	ra,0x0
    8000682c:	cfe080e7          	jalr	-770(ra) # 80006526 <free_desc>
      for(int j = 0; j < i; j++)
    80006830:	2d85                	addiw	s11,s11,1
    80006832:	0a11                	addi	s4,s4,4
    80006834:	ff2d98e3          	bne	s11,s2,80006824 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006838:	85e6                	mv	a1,s9
    8000683a:	0001e517          	auipc	a0,0x1e
    8000683e:	27e50513          	addi	a0,a0,638 # 80024ab8 <disk+0x18>
    80006842:	ffffc097          	auipc	ra,0xffffc
    80006846:	b48080e7          	jalr	-1208(ra) # 8000238a <sleep>
  for(int i = 0; i < 3; i++){
    8000684a:	f8040a13          	addi	s4,s0,-128
{
    8000684e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006850:	894e                	mv	s2,s3
    80006852:	b77d                	j	80006800 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006854:	f8042503          	lw	a0,-128(s0)
    80006858:	00a50713          	addi	a4,a0,10
    8000685c:	0712                	slli	a4,a4,0x4

  if(write)
    8000685e:	0001e797          	auipc	a5,0x1e
    80006862:	24278793          	addi	a5,a5,578 # 80024aa0 <disk>
    80006866:	00e786b3          	add	a3,a5,a4
    8000686a:	01803633          	snez	a2,s8
    8000686e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006870:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006874:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006878:	f6070613          	addi	a2,a4,-160
    8000687c:	6394                	ld	a3,0(a5)
    8000687e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006880:	00870593          	addi	a1,a4,8
    80006884:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006886:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006888:	0007b803          	ld	a6,0(a5)
    8000688c:	9642                	add	a2,a2,a6
    8000688e:	46c1                	li	a3,16
    80006890:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006892:	4585                	li	a1,1
    80006894:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006898:	f8442683          	lw	a3,-124(s0)
    8000689c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068a0:	0692                	slli	a3,a3,0x4
    800068a2:	9836                	add	a6,a6,a3
    800068a4:	058a8613          	addi	a2,s5,88
    800068a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800068ac:	0007b803          	ld	a6,0(a5)
    800068b0:	96c2                	add	a3,a3,a6
    800068b2:	40000613          	li	a2,1024
    800068b6:	c690                	sw	a2,8(a3)
  if(write)
    800068b8:	001c3613          	seqz	a2,s8
    800068bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800068c0:	00166613          	ori	a2,a2,1
    800068c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800068c8:	f8842603          	lw	a2,-120(s0)
    800068cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068d0:	00250693          	addi	a3,a0,2
    800068d4:	0692                	slli	a3,a3,0x4
    800068d6:	96be                	add	a3,a3,a5
    800068d8:	58fd                	li	a7,-1
    800068da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068de:	0612                	slli	a2,a2,0x4
    800068e0:	9832                	add	a6,a6,a2
    800068e2:	f9070713          	addi	a4,a4,-112
    800068e6:	973e                	add	a4,a4,a5
    800068e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800068ec:	6398                	ld	a4,0(a5)
    800068ee:	9732                	add	a4,a4,a2
    800068f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068f2:	4609                	li	a2,2
    800068f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800068f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068fc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006900:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006904:	6794                	ld	a3,8(a5)
    80006906:	0026d703          	lhu	a4,2(a3)
    8000690a:	8b1d                	andi	a4,a4,7
    8000690c:	0706                	slli	a4,a4,0x1
    8000690e:	96ba                	add	a3,a3,a4
    80006910:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006914:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006918:	6798                	ld	a4,8(a5)
    8000691a:	00275783          	lhu	a5,2(a4)
    8000691e:	2785                	addiw	a5,a5,1
    80006920:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006924:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006928:	100017b7          	lui	a5,0x10001
    8000692c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006930:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006934:	0001e917          	auipc	s2,0x1e
    80006938:	29490913          	addi	s2,s2,660 # 80024bc8 <disk+0x128>
  while(b->disk == 1) {
    8000693c:	4485                	li	s1,1
    8000693e:	00b79c63          	bne	a5,a1,80006956 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006942:	85ca                	mv	a1,s2
    80006944:	8556                	mv	a0,s5
    80006946:	ffffc097          	auipc	ra,0xffffc
    8000694a:	a44080e7          	jalr	-1468(ra) # 8000238a <sleep>
  while(b->disk == 1) {
    8000694e:	004aa783          	lw	a5,4(s5)
    80006952:	fe9788e3          	beq	a5,s1,80006942 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006956:	f8042903          	lw	s2,-128(s0)
    8000695a:	00290713          	addi	a4,s2,2
    8000695e:	0712                	slli	a4,a4,0x4
    80006960:	0001e797          	auipc	a5,0x1e
    80006964:	14078793          	addi	a5,a5,320 # 80024aa0 <disk>
    80006968:	97ba                	add	a5,a5,a4
    8000696a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000696e:	0001e997          	auipc	s3,0x1e
    80006972:	13298993          	addi	s3,s3,306 # 80024aa0 <disk>
    80006976:	00491713          	slli	a4,s2,0x4
    8000697a:	0009b783          	ld	a5,0(s3)
    8000697e:	97ba                	add	a5,a5,a4
    80006980:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006984:	854a                	mv	a0,s2
    80006986:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000698a:	00000097          	auipc	ra,0x0
    8000698e:	b9c080e7          	jalr	-1124(ra) # 80006526 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006992:	8885                	andi	s1,s1,1
    80006994:	f0ed                	bnez	s1,80006976 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006996:	0001e517          	auipc	a0,0x1e
    8000699a:	23250513          	addi	a0,a0,562 # 80024bc8 <disk+0x128>
    8000699e:	ffffa097          	auipc	ra,0xffffa
    800069a2:	2ec080e7          	jalr	748(ra) # 80000c8a <release>
}
    800069a6:	70e6                	ld	ra,120(sp)
    800069a8:	7446                	ld	s0,112(sp)
    800069aa:	74a6                	ld	s1,104(sp)
    800069ac:	7906                	ld	s2,96(sp)
    800069ae:	69e6                	ld	s3,88(sp)
    800069b0:	6a46                	ld	s4,80(sp)
    800069b2:	6aa6                	ld	s5,72(sp)
    800069b4:	6b06                	ld	s6,64(sp)
    800069b6:	7be2                	ld	s7,56(sp)
    800069b8:	7c42                	ld	s8,48(sp)
    800069ba:	7ca2                	ld	s9,40(sp)
    800069bc:	7d02                	ld	s10,32(sp)
    800069be:	6de2                	ld	s11,24(sp)
    800069c0:	6109                	addi	sp,sp,128
    800069c2:	8082                	ret

00000000800069c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800069c4:	1101                	addi	sp,sp,-32
    800069c6:	ec06                	sd	ra,24(sp)
    800069c8:	e822                	sd	s0,16(sp)
    800069ca:	e426                	sd	s1,8(sp)
    800069cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069ce:	0001e497          	auipc	s1,0x1e
    800069d2:	0d248493          	addi	s1,s1,210 # 80024aa0 <disk>
    800069d6:	0001e517          	auipc	a0,0x1e
    800069da:	1f250513          	addi	a0,a0,498 # 80024bc8 <disk+0x128>
    800069de:	ffffa097          	auipc	ra,0xffffa
    800069e2:	1f8080e7          	jalr	504(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069e6:	10001737          	lui	a4,0x10001
    800069ea:	533c                	lw	a5,96(a4)
    800069ec:	8b8d                	andi	a5,a5,3
    800069ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069f4:	689c                	ld	a5,16(s1)
    800069f6:	0204d703          	lhu	a4,32(s1)
    800069fa:	0027d783          	lhu	a5,2(a5)
    800069fe:	04f70863          	beq	a4,a5,80006a4e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006a02:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a06:	6898                	ld	a4,16(s1)
    80006a08:	0204d783          	lhu	a5,32(s1)
    80006a0c:	8b9d                	andi	a5,a5,7
    80006a0e:	078e                	slli	a5,a5,0x3
    80006a10:	97ba                	add	a5,a5,a4
    80006a12:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a14:	00278713          	addi	a4,a5,2
    80006a18:	0712                	slli	a4,a4,0x4
    80006a1a:	9726                	add	a4,a4,s1
    80006a1c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006a20:	e721                	bnez	a4,80006a68 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a22:	0789                	addi	a5,a5,2
    80006a24:	0792                	slli	a5,a5,0x4
    80006a26:	97a6                	add	a5,a5,s1
    80006a28:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a2a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a2e:	ffffc097          	auipc	ra,0xffffc
    80006a32:	9c0080e7          	jalr	-1600(ra) # 800023ee <wakeup>

    disk.used_idx += 1;
    80006a36:	0204d783          	lhu	a5,32(s1)
    80006a3a:	2785                	addiw	a5,a5,1
    80006a3c:	17c2                	slli	a5,a5,0x30
    80006a3e:	93c1                	srli	a5,a5,0x30
    80006a40:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a44:	6898                	ld	a4,16(s1)
    80006a46:	00275703          	lhu	a4,2(a4)
    80006a4a:	faf71ce3          	bne	a4,a5,80006a02 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006a4e:	0001e517          	auipc	a0,0x1e
    80006a52:	17a50513          	addi	a0,a0,378 # 80024bc8 <disk+0x128>
    80006a56:	ffffa097          	auipc	ra,0xffffa
    80006a5a:	234080e7          	jalr	564(ra) # 80000c8a <release>
}
    80006a5e:	60e2                	ld	ra,24(sp)
    80006a60:	6442                	ld	s0,16(sp)
    80006a62:	64a2                	ld	s1,8(sp)
    80006a64:	6105                	addi	sp,sp,32
    80006a66:	8082                	ret
      panic("virtio_disk_intr status");
    80006a68:	00002517          	auipc	a0,0x2
    80006a6c:	e2850513          	addi	a0,a0,-472 # 80008890 <syscalls+0x400>
    80006a70:	ffffa097          	auipc	ra,0xffffa
    80006a74:	ad0080e7          	jalr	-1328(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
