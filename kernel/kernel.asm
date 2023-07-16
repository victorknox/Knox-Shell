
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b6013103          	ld	sp,-1184(sp) # 80008b60 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	b7070713          	addi	a4,a4,-1168 # 80008bc0 <timer_scratch>
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
    80000066:	2de78793          	addi	a5,a5,734 # 80006340 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbbcf>
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
    8000012e:	646080e7          	jalr	1606(ra) # 80002770 <either_copyin>
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
    8000018e:	b7650513          	addi	a0,a0,-1162 # 80010d00 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b6648493          	addi	s1,s1,-1178 # 80010d00 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	bf690913          	addi	s2,s2,-1034 # 80010d98 <cons+0x98>
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
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	3f2080e7          	jalr	1010(ra) # 800025ba <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	130080e7          	jalr	304(ra) # 80002306 <sleep>
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
    80000216:	508080e7          	jalr	1288(ra) # 8000271a <either_copyout>
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
    8000022a:	ada50513          	addi	a0,a0,-1318 # 80010d00 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	ac450513          	addi	a0,a0,-1340 # 80010d00 <cons>
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
    80000276:	b2f72323          	sw	a5,-1242(a4) # 80010d98 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	a3450513          	addi	a0,a0,-1484 # 80010d00 <cons>
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
    800002f6:	4d4080e7          	jalr	1236(ra) # 800027c6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	a0650513          	addi	a0,a0,-1530 # 80010d00 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	9e270713          	addi	a4,a4,-1566 # 80010d00 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	9b878793          	addi	a5,a5,-1608 # 80010d00 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	a227a783          	lw	a5,-1502(a5) # 80010d98 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	97670713          	addi	a4,a4,-1674 # 80010d00 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	96648493          	addi	s1,s1,-1690 # 80010d00 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	92a70713          	addi	a4,a4,-1750 # 80010d00 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	9af72a23          	sw	a5,-1612(a4) # 80010da0 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	8ee78793          	addi	a5,a5,-1810 # 80010d00 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	96c7a323          	sw	a2,-1690(a5) # 80010d9c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	95a50513          	addi	a0,a0,-1702 # 80010d98 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f24080e7          	jalr	-220(ra) # 8000236a <wakeup>
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
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	8a050513          	addi	a0,a0,-1888 # 80010d00 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	62078793          	addi	a5,a5,1568 # 80021a98 <devsw>
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
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
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
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8607aa23          	sw	zero,-1932(a5) # 80010dc0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	49a50513          	addi	a0,a0,1178 # 80008a08 <syscalls+0x5b8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	60f72023          	sw	a5,1536(a4) # 80008b80 <panicked>
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
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	804dad83          	lw	s11,-2044(s11) # 80010dc0 <pr+0x18>
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
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	7ae50513          	addi	a0,a0,1966 # 80010da8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
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
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
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
    8000075c:	65050513          	addi	a0,a0,1616 # 80010da8 <pr>
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
    80000778:	63448493          	addi	s1,s1,1588 # 80010da8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
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
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	5f450513          	addi	a0,a0,1524 # 80010dc8 <uart_tx_lock>
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
    80000804:	3807a783          	lw	a5,896(a5) # 80008b80 <panicked>
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
    8000083c:	3507b783          	ld	a5,848(a5) # 80008b88 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	35073703          	ld	a4,848(a4) # 80008b90 <uart_tx_w>
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
    80000866:	566a0a13          	addi	s4,s4,1382 # 80010dc8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	31e48493          	addi	s1,s1,798 # 80008b88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	31e98993          	addi	s3,s3,798 # 80008b90 <uart_tx_w>
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
    80000898:	ad6080e7          	jalr	-1322(ra) # 8000236a <wakeup>
    
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
    800008d4:	4f850513          	addi	a0,a0,1272 # 80010dc8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2a07a783          	lw	a5,672(a5) # 80008b80 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	2a673703          	ld	a4,678(a4) # 80008b90 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2967b783          	ld	a5,662(a5) # 80008b88 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	4ca98993          	addi	s3,s3,1226 # 80010dc8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	28248493          	addi	s1,s1,642 # 80008b88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	28290913          	addi	s2,s2,642 # 80008b90 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	9e8080e7          	jalr	-1560(ra) # 80002306 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	49448493          	addi	s1,s1,1172 # 80010dc8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	24e7b423          	sd	a4,584(a5) # 80008b90 <uart_tx_w>
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
    800009be:	40e48493          	addi	s1,s1,1038 # 80010dc8 <uart_tx_lock>
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
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	23478793          	addi	a5,a5,564 # 80022c30 <end>
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
    80000a20:	3e490913          	addi	s2,s2,996 # 80010e00 <kmem>
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
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
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
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	34650513          	addi	a0,a0,838 # 80010e00 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	16250513          	addi	a0,a0,354 # 80022c30 <end>
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
    80000af4:	31048493          	addi	s1,s1,784 # 80010e00 <kmem>
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
    80000b0c:	2f850513          	addi	a0,a0,760 # 80010e00 <kmem>
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
    80000b38:	2cc50513          	addi	a0,a0,716 # 80010e00 <kmem>
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
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
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
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
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
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
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
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
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
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
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
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
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
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc3d1>
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
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	d1070713          	addi	a4,a4,-752 # 80008b98 <started>
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
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	a4a080e7          	jalr	-1462(ra) # 80002908 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	4ba080e7          	jalr	1210(ra) # 80006380 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	14c080e7          	jalr	332(ra) # 8000201a <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00008517          	auipc	a0,0x8
    80000eea:	b2250513          	addi	a0,a0,-1246 # 80008a08 <syscalls+0x5b8>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00008517          	auipc	a0,0x8
    80000f0a:	b0250513          	addi	a0,a0,-1278 # 80008a08 <syscalls+0x5b8>
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
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	9aa080e7          	jalr	-1622(ra) # 800028e0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	9ca080e7          	jalr	-1590(ra) # 80002908 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	424080e7          	jalr	1060(ra) # 8000636a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	432080e7          	jalr	1074(ra) # 80006380 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	390080e7          	jalr	912(ra) # 800032e6 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	a30080e7          	jalr	-1488(ra) # 8000398e <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	9d6080e7          	jalr	-1578(ra) # 8000493c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	51a080e7          	jalr	1306(ra) # 80006488 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d4c080e7          	jalr	-692(ra) # 80001cc2 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	c0f72a23          	sw	a5,-1004(a4) # 80008b98 <started>
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
    80000f9c:	c087b783          	ld	a5,-1016(a5) # 80008ba0 <kernel_pagetable>
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
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc3c7>
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
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
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
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
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
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
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
    80001254:	00008797          	auipc	a5,0x8
    80001258:	94a7b623          	sd	a0,-1716(a5) # 80008ba0 <kernel_pagetable>
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
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
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
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
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
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
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
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
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
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc3d0>
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

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	a0448493          	addi	s1,s1,-1532 # 80011250 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	feaa0a13          	addi	s4,s4,-22 # 80017850 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	19848493          	addi	s1,s1,408
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	53850513          	addi	a0,a0,1336 # 80010e20 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	53850513          	addi	a0,a0,1336 # 80010e38 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010497          	auipc	s1,0x10
    80001914:	94048493          	addi	s1,s1,-1728 # 80011250 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00016997          	auipc	s3,0x16
    80001936:	f1e98993          	addi	s3,s3,-226 # 80017850 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	19848493          	addi	s1,s1,408
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	4b450513          	addi	a0,a0,1204 # 80010e50 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	45c70713          	addi	a4,a4,1116 # 80010e20 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	1147a783          	lw	a5,276(a5) # 80008b10 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	f1a080e7          	jalr	-230(ra) # 80002920 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	0e07ad23          	sw	zero,250(a5) # 80008b10 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	eee080e7          	jalr	-274(ra) # 8000390e <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	3ea90913          	addi	s2,s2,1002 # 80010e20 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	0d078793          	addi	a5,a5,208 # 80008b18 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->saved_tf)
    80001b7a:	1804b503          	ld	a0,384(s1)
    80001b7e:	c509                	beqz	a0,80001b88 <freeproc+0x2a>
    kfree((void*)p->saved_tf);
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	e68080e7          	jalr	-408(ra) # 800009e8 <kfree>
  p->saved_tf = 0;
    80001b88:	1804b023          	sd	zero,384(s1)
  if(p->pagetable)
    80001b8c:	68a8                	ld	a0,80(s1)
    80001b8e:	c511                	beqz	a0,80001b9a <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    80001b90:	64ac                	ld	a1,72(s1)
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	f7a080e7          	jalr	-134(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b9a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b9e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ba2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001baa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bae:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bba:	0004ac23          	sw	zero,24(s1)
  p->strace_m = 0;
    80001bbe:	1604bc23          	sd	zero,376(s1)
}
    80001bc2:	60e2                	ld	ra,24(sp)
    80001bc4:	6442                	ld	s0,16(sp)
    80001bc6:	64a2                	ld	s1,8(sp)
    80001bc8:	6105                	addi	sp,sp,32
    80001bca:	8082                	ret

0000000080001bcc <allocproc>:
{
    80001bcc:	1101                	addi	sp,sp,-32
    80001bce:	ec06                	sd	ra,24(sp)
    80001bd0:	e822                	sd	s0,16(sp)
    80001bd2:	e426                	sd	s1,8(sp)
    80001bd4:	e04a                	sd	s2,0(sp)
    80001bd6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd8:	0000f497          	auipc	s1,0xf
    80001bdc:	67848493          	addi	s1,s1,1656 # 80011250 <proc>
    80001be0:	00016917          	auipc	s2,0x16
    80001be4:	c7090913          	addi	s2,s2,-912 # 80017850 <tickslock>
    acquire(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	fec080e7          	jalr	-20(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bf2:	4c9c                	lw	a5,24(s1)
    80001bf4:	cf81                	beqz	a5,80001c0c <allocproc+0x40>
      release(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	092080e7          	jalr	146(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c00:	19848493          	addi	s1,s1,408
    80001c04:	ff2492e3          	bne	s1,s2,80001be8 <allocproc+0x1c>
  return 0;
    80001c08:	4481                	li	s1,0
    80001c0a:	a8ad                	j	80001c84 <allocproc+0xb8>
  p->pid = allocpid();
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	e1e080e7          	jalr	-482(ra) # 80001a2a <allocpid>
    80001c14:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c16:	4785                	li	a5,1
    80001c18:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	ecc080e7          	jalr	-308(ra) # 80000ae6 <kalloc>
    80001c22:	892a                	mv	s2,a0
    80001c24:	eca8                	sd	a0,88(s1)
    80001c26:	c535                	beqz	a0,80001c92 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	e46080e7          	jalr	-442(ra) # 80001a70 <proc_pagetable>
    80001c32:	892a                	mv	s2,a0
    80001c34:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c36:	c935                	beqz	a0,80001caa <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001c38:	07000613          	li	a2,112
    80001c3c:	4581                	li	a1,0
    80001c3e:	06048513          	addi	a0,s1,96
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	090080e7          	jalr	144(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c4a:	00000797          	auipc	a5,0x0
    80001c4e:	d9a78793          	addi	a5,a5,-614 # 800019e4 <forkret>
    80001c52:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c54:	60bc                	ld	a5,64(s1)
    80001c56:	6705                	lui	a4,0x1
    80001c58:	97ba                	add	a5,a5,a4
    80001c5a:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c5c:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c60:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c64:	00007797          	auipc	a5,0x7
    80001c68:	f547a783          	lw	a5,-172(a5) # 80008bb8 <ticks>
    80001c6c:	16f4a623          	sw	a5,364(s1)
p->priority = 60;
    80001c70:	03c00793          	li	a5,60
    80001c74:	18f4a423          	sw	a5,392(s1)
p->nrun = 0;
    80001c78:	1804a623          	sw	zero,396(s1)
p->waittime = 0;
    80001c7c:	1804aa23          	sw	zero,404(s1)
p->runtime = 0;
    80001c80:	1804a823          	sw	zero,400(s1)
}
    80001c84:	8526                	mv	a0,s1
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6902                	ld	s2,0(sp)
    80001c8e:	6105                	addi	sp,sp,32
    80001c90:	8082                	ret
    freeproc(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	eca080e7          	jalr	-310(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	fec080e7          	jalr	-20(ra) # 80000c8a <release>
    return 0;
    80001ca6:	84ca                	mv	s1,s2
    80001ca8:	bff1                	j	80001c84 <allocproc+0xb8>
    freeproc(p);
    80001caa:	8526                	mv	a0,s1
    80001cac:	00000097          	auipc	ra,0x0
    80001cb0:	eb2080e7          	jalr	-334(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	fd4080e7          	jalr	-44(ra) # 80000c8a <release>
    return 0;
    80001cbe:	84ca                	mv	s1,s2
    80001cc0:	b7d1                	j	80001c84 <allocproc+0xb8>

0000000080001cc2 <userinit>:
{
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	f00080e7          	jalr	-256(ra) # 80001bcc <allocproc>
    80001cd4:	84aa                	mv	s1,a0
  initproc = p;
    80001cd6:	00007797          	auipc	a5,0x7
    80001cda:	eca7bd23          	sd	a0,-294(a5) # 80008bb0 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cde:	03400613          	li	a2,52
    80001ce2:	00007597          	auipc	a1,0x7
    80001ce6:	e3e58593          	addi	a1,a1,-450 # 80008b20 <initcode>
    80001cea:	6928                	ld	a0,80(a0)
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	66a080e7          	jalr	1642(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cf4:	6785                	lui	a5,0x1
    80001cf6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf8:	6cb8                	ld	a4,88(s1)
    80001cfa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cfe:	6cb8                	ld	a4,88(s1)
    80001d00:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d02:	4641                	li	a2,16
    80001d04:	00006597          	auipc	a1,0x6
    80001d08:	4fc58593          	addi	a1,a1,1276 # 80008200 <digits+0x1c0>
    80001d0c:	15848513          	addi	a0,s1,344
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	10c080e7          	jalr	268(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d18:	00006517          	auipc	a0,0x6
    80001d1c:	4f850513          	addi	a0,a0,1272 # 80008210 <digits+0x1d0>
    80001d20:	00002097          	auipc	ra,0x2
    80001d24:	618080e7          	jalr	1560(ra) # 80004338 <namei>
    80001d28:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d2c:	478d                	li	a5,3
    80001d2e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d30:	8526                	mv	a0,s1
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	f58080e7          	jalr	-168(ra) # 80000c8a <release>
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6105                	addi	sp,sp,32
    80001d42:	8082                	ret

0000000080001d44 <growproc>:
{
    80001d44:	1101                	addi	sp,sp,-32
    80001d46:	ec06                	sd	ra,24(sp)
    80001d48:	e822                	sd	s0,16(sp)
    80001d4a:	e426                	sd	s1,8(sp)
    80001d4c:	e04a                	sd	s2,0(sp)
    80001d4e:	1000                	addi	s0,sp,32
    80001d50:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	c5a080e7          	jalr	-934(ra) # 800019ac <myproc>
    80001d5a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d5c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d5e:	01204c63          	bgtz	s2,80001d76 <growproc+0x32>
  } else if(n < 0){
    80001d62:	02094663          	bltz	s2,80001d8e <growproc+0x4a>
  p->sz = sz;
    80001d66:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d68:	4501                	li	a0,0
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6902                	ld	s2,0(sp)
    80001d72:	6105                	addi	sp,sp,32
    80001d74:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d76:	4691                	li	a3,4
    80001d78:	00b90633          	add	a2,s2,a1
    80001d7c:	6928                	ld	a0,80(a0)
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	692080e7          	jalr	1682(ra) # 80001410 <uvmalloc>
    80001d86:	85aa                	mv	a1,a0
    80001d88:	fd79                	bnez	a0,80001d66 <growproc+0x22>
      return -1;
    80001d8a:	557d                	li	a0,-1
    80001d8c:	bff9                	j	80001d6a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8e:	00b90633          	add	a2,s2,a1
    80001d92:	6928                	ld	a0,80(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	634080e7          	jalr	1588(ra) # 800013c8 <uvmdealloc>
    80001d9c:	85aa                	mv	a1,a0
    80001d9e:	b7e1                	j	80001d66 <growproc+0x22>

0000000080001da0 <fork>:
{
    80001da0:	7139                	addi	sp,sp,-64
    80001da2:	fc06                	sd	ra,56(sp)
    80001da4:	f822                	sd	s0,48(sp)
    80001da6:	f426                	sd	s1,40(sp)
    80001da8:	f04a                	sd	s2,32(sp)
    80001daa:	ec4e                	sd	s3,24(sp)
    80001dac:	e852                	sd	s4,16(sp)
    80001dae:	e456                	sd	s5,8(sp)
    80001db0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	bfa080e7          	jalr	-1030(ra) # 800019ac <myproc>
    80001dba:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	e10080e7          	jalr	-496(ra) # 80001bcc <allocproc>
    80001dc4:	10050c63          	beqz	a0,80001edc <fork+0x13c>
    80001dc8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dca:	048ab603          	ld	a2,72(s5)
    80001dce:	692c                	ld	a1,80(a0)
    80001dd0:	050ab503          	ld	a0,80(s5)
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	794080e7          	jalr	1940(ra) # 80001568 <uvmcopy>
    80001ddc:	04054863          	bltz	a0,80001e2c <fork+0x8c>
  np->sz = p->sz;
    80001de0:	048ab783          	ld	a5,72(s5)
    80001de4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001de8:	058ab683          	ld	a3,88(s5)
    80001dec:	87b6                	mv	a5,a3
    80001dee:	058a3703          	ld	a4,88(s4)
    80001df2:	12068693          	addi	a3,a3,288
    80001df6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfa:	6788                	ld	a0,8(a5)
    80001dfc:	6b8c                	ld	a1,16(a5)
    80001dfe:	6f90                	ld	a2,24(a5)
    80001e00:	01073023          	sd	a6,0(a4)
    80001e04:	e708                	sd	a0,8(a4)
    80001e06:	eb0c                	sd	a1,16(a4)
    80001e08:	ef10                	sd	a2,24(a4)
    80001e0a:	02078793          	addi	a5,a5,32
    80001e0e:	02070713          	addi	a4,a4,32
    80001e12:	fed792e3          	bne	a5,a3,80001df6 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e16:	058a3783          	ld	a5,88(s4)
    80001e1a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e1e:	0d0a8493          	addi	s1,s5,208
    80001e22:	0d0a0913          	addi	s2,s4,208
    80001e26:	150a8993          	addi	s3,s5,336
    80001e2a:	a00d                	j	80001e4c <fork+0xac>
    freeproc(np);
    80001e2c:	8552                	mv	a0,s4
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	d30080e7          	jalr	-720(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e36:	8552                	mv	a0,s4
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e52080e7          	jalr	-430(ra) # 80000c8a <release>
    return -1;
    80001e40:	597d                	li	s2,-1
    80001e42:	a059                	j	80001ec8 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e44:	04a1                	addi	s1,s1,8
    80001e46:	0921                	addi	s2,s2,8
    80001e48:	01348b63          	beq	s1,s3,80001e5e <fork+0xbe>
    if(p->ofile[i])
    80001e4c:	6088                	ld	a0,0(s1)
    80001e4e:	d97d                	beqz	a0,80001e44 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e50:	00003097          	auipc	ra,0x3
    80001e54:	b7e080e7          	jalr	-1154(ra) # 800049ce <filedup>
    80001e58:	00a93023          	sd	a0,0(s2)
    80001e5c:	b7e5                	j	80001e44 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e5e:	150ab503          	ld	a0,336(s5)
    80001e62:	00002097          	auipc	ra,0x2
    80001e66:	cec080e7          	jalr	-788(ra) # 80003b4e <idup>
    80001e6a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e6e:	4641                	li	a2,16
    80001e70:	158a8593          	addi	a1,s5,344
    80001e74:	158a0513          	addi	a0,s4,344
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	fa4080e7          	jalr	-92(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e80:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	e04080e7          	jalr	-508(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e8e:	0000f497          	auipc	s1,0xf
    80001e92:	faa48493          	addi	s1,s1,-86 # 80010e38 <wait_lock>
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	d3e080e7          	jalr	-706(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ea0:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eae:	8552                	mv	a0,s4
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	d26080e7          	jalr	-730(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eb8:	478d                	li	a5,3
    80001eba:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ebe:	8552                	mv	a0,s4
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dca080e7          	jalr	-566(ra) # 80000c8a <release>
}
    80001ec8:	854a                	mv	a0,s2
    80001eca:	70e2                	ld	ra,56(sp)
    80001ecc:	7442                	ld	s0,48(sp)
    80001ece:	74a2                	ld	s1,40(sp)
    80001ed0:	7902                	ld	s2,32(sp)
    80001ed2:	69e2                	ld	s3,24(sp)
    80001ed4:	6a42                	ld	s4,16(sp)
    80001ed6:	6aa2                	ld	s5,8(sp)
    80001ed8:	6121                	addi	sp,sp,64
    80001eda:	8082                	ret
    return -1;
    80001edc:	597d                	li	s2,-1
    80001ede:	b7ed                	j	80001ec8 <fork+0x128>

0000000080001ee0 <get_priority>:
int get_priority(struct proc *p){
    80001ee0:	1141                	addi	sp,sp,-16
    80001ee2:	e422                	sd	s0,8(sp)
    80001ee4:	0800                	addi	s0,sp,16
  int niceness = 5, dp, sp = p->priority;
    80001ee6:	18852783          	lw	a5,392(a0)
  int st = p->waittime; 
    80001eea:	19452603          	lw	a2,404(a0)
  int den = p->runtime + st;
    80001eee:	19052683          	lw	a3,400(a0)
    80001ef2:	9eb1                	addw	a3,a3,a2
    80001ef4:	0006859b          	sext.w	a1,a3
  int niceness = 5, dp, sp = p->priority;
    80001ef8:	4715                	li	a4,5
  if(den != 0){
    80001efa:	c981                	beqz	a1,80001f0a <get_priority+0x2a>
    niceness = (st / den)*10;
    80001efc:	02d6463b          	divw	a2,a2,a3
    80001f00:	0026171b          	slliw	a4,a2,0x2
    80001f04:	9f31                	addw	a4,a4,a2
    80001f06:	0017171b          	slliw	a4,a4,0x1
  dp = sp - niceness + 5;
    80001f0a:	40e7853b          	subw	a0,a5,a4
    80001f0e:	2515                	addiw	a0,a0,5
  return dp;
    80001f10:	0005079b          	sext.w	a5,a0
    80001f14:	fff7c793          	not	a5,a5
    80001f18:	97fd                	srai	a5,a5,0x3f
    80001f1a:	8d7d                	and	a0,a0,a5
    80001f1c:	0005071b          	sext.w	a4,a0
    80001f20:	06400793          	li	a5,100
    80001f24:	00e7d463          	bge	a5,a4,80001f2c <get_priority+0x4c>
    80001f28:	06400513          	li	a0,100
}
    80001f2c:	2501                	sext.w	a0,a0
    80001f2e:	6422                	ld	s0,8(sp)
    80001f30:	0141                	addi	sp,sp,16
    80001f32:	8082                	ret

0000000080001f34 <update_time>:
 {
    80001f34:	7179                	addi	sp,sp,-48
    80001f36:	f406                	sd	ra,40(sp)
    80001f38:	f022                	sd	s0,32(sp)
    80001f3a:	ec26                	sd	s1,24(sp)
    80001f3c:	e84a                	sd	s2,16(sp)
    80001f3e:	e44e                	sd	s3,8(sp)
    80001f40:	e052                	sd	s4,0(sp)
    80001f42:	1800                	addi	s0,sp,48
   for (p = proc; p < &proc[NPROC]; p++) {
    80001f44:	0000f497          	auipc	s1,0xf
    80001f48:	30c48493          	addi	s1,s1,780 # 80011250 <proc>
     if (p->state == RUNNING) {
    80001f4c:	4991                	li	s3,4
    else if (p->state == SLEEPING)
    80001f4e:	4a09                	li	s4,2
   for (p = proc; p < &proc[NPROC]; p++) {
    80001f50:	00016917          	auipc	s2,0x16
    80001f54:	90090913          	addi	s2,s2,-1792 # 80017850 <tickslock>
    80001f58:	a025                	j	80001f80 <update_time+0x4c>
       p->rtime++;
    80001f5a:	1684a783          	lw	a5,360(s1)
    80001f5e:	2785                	addiw	a5,a5,1
    80001f60:	16f4a423          	sw	a5,360(s1)
      p->runtime++;
    80001f64:	1904a783          	lw	a5,400(s1)
    80001f68:	2785                	addiw	a5,a5,1
    80001f6a:	18f4a823          	sw	a5,400(s1)
     release(&p->lock); 
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d1a080e7          	jalr	-742(ra) # 80000c8a <release>
   for (p = proc; p < &proc[NPROC]; p++) {
    80001f78:	19848493          	addi	s1,s1,408
    80001f7c:	03248263          	beq	s1,s2,80001fa0 <update_time+0x6c>
     acquire(&p->lock);
    80001f80:	8526                	mv	a0,s1
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	c54080e7          	jalr	-940(ra) # 80000bd6 <acquire>
     if (p->state == RUNNING) {
    80001f8a:	4c9c                	lw	a5,24(s1)
    80001f8c:	fd3787e3          	beq	a5,s3,80001f5a <update_time+0x26>
    else if (p->state == SLEEPING)
    80001f90:	fd479fe3          	bne	a5,s4,80001f6e <update_time+0x3a>
      p->waittime++;
    80001f94:	1944a783          	lw	a5,404(s1)
    80001f98:	2785                	addiw	a5,a5,1
    80001f9a:	18f4aa23          	sw	a5,404(s1)
    80001f9e:	bfc1                	j	80001f6e <update_time+0x3a>
 }
    80001fa0:	70a2                	ld	ra,40(sp)
    80001fa2:	7402                	ld	s0,32(sp)
    80001fa4:	64e2                	ld	s1,24(sp)
    80001fa6:	6942                	ld	s2,16(sp)
    80001fa8:	69a2                	ld	s3,8(sp)
    80001faa:	6a02                	ld	s4,0(sp)
    80001fac:	6145                	addi	sp,sp,48
    80001fae:	8082                	ret

0000000080001fb0 <trace>:
{
    80001fb0:	1101                	addi	sp,sp,-32
    80001fb2:	ec06                	sd	ra,24(sp)
    80001fb4:	e822                	sd	s0,16(sp)
    80001fb6:	e426                	sd	s1,8(sp)
    80001fb8:	1000                	addi	s0,sp,32
    80001fba:	84aa                	mv	s1,a0
  myproc()->strace_m = mask;
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	9f0080e7          	jalr	-1552(ra) # 800019ac <myproc>
    80001fc4:	16953c23          	sd	s1,376(a0)
}
    80001fc8:	4501                	li	a0,0
    80001fca:	60e2                	ld	ra,24(sp)
    80001fcc:	6442                	ld	s0,16(sp)
    80001fce:	64a2                	ld	s1,8(sp)
    80001fd0:	6105                	addi	sp,sp,32
    80001fd2:	8082                	ret

0000000080001fd4 <rand>:
{
    80001fd4:	1141                	addi	sp,sp,-16
    80001fd6:	e422                	sd	s0,8(sp)
    80001fd8:	0800                	addi	s0,sp,16
  bit  = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5) ) & 1;
    80001fda:	00007717          	auipc	a4,0x7
    80001fde:	b3a70713          	addi	a4,a4,-1222 # 80008b14 <lfsr>
    80001fe2:	00075503          	lhu	a0,0(a4)
    80001fe6:	0025579b          	srliw	a5,a0,0x2
    80001fea:	0035569b          	srliw	a3,a0,0x3
    80001fee:	8fb5                	xor	a5,a5,a3
    80001ff0:	8fa9                	xor	a5,a5,a0
    80001ff2:	0055569b          	srliw	a3,a0,0x5
    80001ff6:	8fb5                	xor	a5,a5,a3
    80001ff8:	8b85                	andi	a5,a5,1
    80001ffa:	00007697          	auipc	a3,0x7
    80001ffe:	baf6a723          	sw	a5,-1106(a3) # 80008ba8 <bit>
  return lfsr = (lfsr >> 1) | (bit << 15);
    80002002:	0015551b          	srliw	a0,a0,0x1
    80002006:	00f7979b          	slliw	a5,a5,0xf
    8000200a:	8d5d                	or	a0,a0,a5
    8000200c:	1542                	slli	a0,a0,0x30
    8000200e:	9141                	srli	a0,a0,0x30
    80002010:	00a71023          	sh	a0,0(a4)
}
    80002014:	6422                	ld	s0,8(sp)
    80002016:	0141                	addi	sp,sp,16
    80002018:	8082                	ret

000000008000201a <scheduler>:
{
    8000201a:	7159                	addi	sp,sp,-112
    8000201c:	f486                	sd	ra,104(sp)
    8000201e:	f0a2                	sd	s0,96(sp)
    80002020:	eca6                	sd	s1,88(sp)
    80002022:	e8ca                	sd	s2,80(sp)
    80002024:	e4ce                	sd	s3,72(sp)
    80002026:	e0d2                	sd	s4,64(sp)
    80002028:	fc56                	sd	s5,56(sp)
    8000202a:	f85a                	sd	s6,48(sp)
    8000202c:	f45e                	sd	s7,40(sp)
    8000202e:	f062                	sd	s8,32(sp)
    80002030:	ec66                	sd	s9,24(sp)
    80002032:	e86a                	sd	s10,16(sp)
    80002034:	e46e                	sd	s11,8(sp)
    80002036:	1880                	addi	s0,sp,112
    80002038:	8792                	mv	a5,tp
  int id = r_tp();
    8000203a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000203c:	00779d13          	slli	s10,a5,0x7
    80002040:	0000f717          	auipc	a4,0xf
    80002044:	de070713          	addi	a4,a4,-544 # 80010e20 <pid_lock>
    80002048:	976a                	add	a4,a4,s10
    8000204a:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &to_be_run->context);
    8000204e:	0000f717          	auipc	a4,0xf
    80002052:	e0a70713          	addi	a4,a4,-502 # 80010e58 <cpus+0x8>
    80002056:	9d3a                	add	s10,s10,a4
      if (p->state == RUNNABLE)
    80002058:	4c0d                	li	s8,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000205a:	00015b97          	auipc	s7,0x15
    8000205e:	7f6b8b93          	addi	s7,s7,2038 # 80017850 <tickslock>
    to_be_run->state = RUNNING;
    80002062:	4d91                	li	s11,4
    c->proc = to_be_run;
    80002064:	079e                	slli	a5,a5,0x7
    80002066:	0000fc97          	auipc	s9,0xf
    8000206a:	dbac8c93          	addi	s9,s9,-582 # 80010e20 <pid_lock>
    8000206e:	9cbe                	add	s9,s9,a5
    80002070:	a8e9                	j	8000214a <scheduler+0x130>
          release(&to_be_run->lock);
    80002072:	855a                	mv	a0,s6
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c16080e7          	jalr	-1002(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000207c:	0f79fa63          	bgeu	s3,s7,80002170 <scheduler+0x156>
    80002080:	8b56                	mv	s6,s5
    80002082:	a091                	j	800020c6 <scheduler+0xac>
          if (to_be_run->nrun == p->nrun && to_be_run->ctime < p->ctime)
    80002084:	18cb2703          	lw	a4,396(s6)
    80002088:	ff492783          	lw	a5,-12(s2)
    8000208c:	00f70a63          	beq	a4,a5,800020a0 <scheduler+0x86>
          else if (to_be_run->nrun > p->nrun)
    80002090:	06e7db63          	bge	a5,a4,80002106 <scheduler+0xec>
            release(&to_be_run->lock);
    80002094:	855a                	mv	a0,s6
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	bf4080e7          	jalr	-1036(ra) # 80000c8a <release>
            continue;
    8000209e:	bff9                	j	8000207c <scheduler+0x62>
          if (to_be_run->nrun == p->nrun && to_be_run->ctime < p->ctime)
    800020a0:	16cb2703          	lw	a4,364(s6)
    800020a4:	fd492783          	lw	a5,-44(s2)
    800020a8:	04f77f63          	bgeu	a4,a5,80002106 <scheduler+0xec>
              release(&to_be_run->lock);
    800020ac:	855a                	mv	a0,s6
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bdc080e7          	jalr	-1060(ra) # 80000c8a <release>
              continue;
    800020b6:	b7d9                	j	8000207c <scheduler+0x62>
      release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bd0080e7          	jalr	-1072(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800020c2:	0b797463          	bgeu	s2,s7,8000216a <scheduler+0x150>
    800020c6:	19848493          	addi	s1,s1,408
    800020ca:	19890913          	addi	s2,s2,408
    800020ce:	8aa6                	mv	s5,s1
      acquire(&p->lock);
    800020d0:	8526                	mv	a0,s1
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b04080e7          	jalr	-1276(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    800020da:	89ca                	mv	s3,s2
    800020dc:	e8092783          	lw	a5,-384(s2)
    800020e0:	fd879ce3          	bne	a5,s8,800020b8 <scheduler+0x9e>
        if (to_be_run == 0)
    800020e4:	f80b0ce3          	beqz	s6,8000207c <scheduler+0x62>
        else if (get_priority(to_be_run) > get_priority(p))
    800020e8:	855a                	mv	a0,s6
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	df6080e7          	jalr	-522(ra) # 80001ee0 <get_priority>
    800020f2:	8a2a                	mv	s4,a0
    800020f4:	8526                	mv	a0,s1
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	dea080e7          	jalr	-534(ra) # 80001ee0 <get_priority>
    800020fe:	f7454ae3          	blt	a0,s4,80002072 <scheduler+0x58>
        else if (get_priority(to_be_run) == get_priority(p))
    80002102:	f8aa01e3          	beq	s4,a0,80002084 <scheduler+0x6a>
      release(&p->lock);
    80002106:	8556                	mv	a0,s5
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b82080e7          	jalr	-1150(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002110:	fb79ebe3          	bltu	s3,s7,800020c6 <scheduler+0xac>
    to_be_run->state = RUNNING;
    80002114:	01bb2c23          	sw	s11,24(s6)
    to_be_run->runtime = 0;
    80002118:	180b2823          	sw	zero,400(s6)
    to_be_run->waittime = 0;
    8000211c:	180b2a23          	sw	zero,404(s6)
    to_be_run->nrun++;
    80002120:	18cb2783          	lw	a5,396(s6)
    80002124:	2785                	addiw	a5,a5,1
    80002126:	18fb2623          	sw	a5,396(s6)
    c->proc = to_be_run;
    8000212a:	036cb823          	sd	s6,48(s9)
    swtch(&c->context, &to_be_run->context);
    8000212e:	060b0593          	addi	a1,s6,96
    80002132:	856a                	mv	a0,s10
    80002134:	00000097          	auipc	ra,0x0
    80002138:	742080e7          	jalr	1858(ra) # 80002876 <swtch>
    c->proc = 0;
    8000213c:	020cb823          	sd	zero,48(s9)
    release(&to_be_run->lock);
    80002140:	855a                	mv	a0,s6
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b48080e7          	jalr	-1208(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000214a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000214e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002152:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	0fa48493          	addi	s1,s1,250 # 80011250 <proc>
    8000215e:	0000f917          	auipc	s2,0xf
    80002162:	28a90913          	addi	s2,s2,650 # 800113e8 <proc+0x198>
    struct proc *to_be_run = 0;
    80002166:	4b01                	li	s6,0
    80002168:	b79d                	j	800020ce <scheduler+0xb4>
    if (!to_be_run){
    8000216a:	fe0b00e3          	beqz	s6,8000214a <scheduler+0x130>
    8000216e:	b75d                	j	80002114 <scheduler+0xfa>
    for (p = proc; p < &proc[NPROC]; p++)
    80002170:	8b56                	mv	s6,s5
    80002172:	b74d                	j	80002114 <scheduler+0xfa>

0000000080002174 <sched>:
{
    80002174:	7179                	addi	sp,sp,-48
    80002176:	f406                	sd	ra,40(sp)
    80002178:	f022                	sd	s0,32(sp)
    8000217a:	ec26                	sd	s1,24(sp)
    8000217c:	e84a                	sd	s2,16(sp)
    8000217e:	e44e                	sd	s3,8(sp)
    80002180:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002182:	00000097          	auipc	ra,0x0
    80002186:	82a080e7          	jalr	-2006(ra) # 800019ac <myproc>
    8000218a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	9d0080e7          	jalr	-1584(ra) # 80000b5c <holding>
    80002194:	c93d                	beqz	a0,8000220a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002196:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002198:	2781                	sext.w	a5,a5
    8000219a:	079e                	slli	a5,a5,0x7
    8000219c:	0000f717          	auipc	a4,0xf
    800021a0:	c8470713          	addi	a4,a4,-892 # 80010e20 <pid_lock>
    800021a4:	97ba                	add	a5,a5,a4
    800021a6:	0a87a703          	lw	a4,168(a5)
    800021aa:	4785                	li	a5,1
    800021ac:	06f71763          	bne	a4,a5,8000221a <sched+0xa6>
  if(p->state == RUNNING)
    800021b0:	4c98                	lw	a4,24(s1)
    800021b2:	4791                	li	a5,4
    800021b4:	06f70b63          	beq	a4,a5,8000222a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021bc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021be:	efb5                	bnez	a5,8000223a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021c0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021c2:	0000f917          	auipc	s2,0xf
    800021c6:	c5e90913          	addi	s2,s2,-930 # 80010e20 <pid_lock>
    800021ca:	2781                	sext.w	a5,a5
    800021cc:	079e                	slli	a5,a5,0x7
    800021ce:	97ca                	add	a5,a5,s2
    800021d0:	0ac7a983          	lw	s3,172(a5)
    800021d4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021d6:	2781                	sext.w	a5,a5
    800021d8:	079e                	slli	a5,a5,0x7
    800021da:	0000f597          	auipc	a1,0xf
    800021de:	c7e58593          	addi	a1,a1,-898 # 80010e58 <cpus+0x8>
    800021e2:	95be                	add	a1,a1,a5
    800021e4:	06048513          	addi	a0,s1,96
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	68e080e7          	jalr	1678(ra) # 80002876 <swtch>
    800021f0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021f2:	2781                	sext.w	a5,a5
    800021f4:	079e                	slli	a5,a5,0x7
    800021f6:	993e                	add	s2,s2,a5
    800021f8:	0b392623          	sw	s3,172(s2)
}
    800021fc:	70a2                	ld	ra,40(sp)
    800021fe:	7402                	ld	s0,32(sp)
    80002200:	64e2                	ld	s1,24(sp)
    80002202:	6942                	ld	s2,16(sp)
    80002204:	69a2                	ld	s3,8(sp)
    80002206:	6145                	addi	sp,sp,48
    80002208:	8082                	ret
    panic("sched p->lock");
    8000220a:	00006517          	auipc	a0,0x6
    8000220e:	00e50513          	addi	a0,a0,14 # 80008218 <digits+0x1d8>
    80002212:	ffffe097          	auipc	ra,0xffffe
    80002216:	32e080e7          	jalr	814(ra) # 80000540 <panic>
    panic("sched locks");
    8000221a:	00006517          	auipc	a0,0x6
    8000221e:	00e50513          	addi	a0,a0,14 # 80008228 <digits+0x1e8>
    80002222:	ffffe097          	auipc	ra,0xffffe
    80002226:	31e080e7          	jalr	798(ra) # 80000540 <panic>
    panic("sched running");
    8000222a:	00006517          	auipc	a0,0x6
    8000222e:	00e50513          	addi	a0,a0,14 # 80008238 <digits+0x1f8>
    80002232:	ffffe097          	auipc	ra,0xffffe
    80002236:	30e080e7          	jalr	782(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000223a:	00006517          	auipc	a0,0x6
    8000223e:	00e50513          	addi	a0,a0,14 # 80008248 <digits+0x208>
    80002242:	ffffe097          	auipc	ra,0xffffe
    80002246:	2fe080e7          	jalr	766(ra) # 80000540 <panic>

000000008000224a <yield>:
{
    8000224a:	1101                	addi	sp,sp,-32
    8000224c:	ec06                	sd	ra,24(sp)
    8000224e:	e822                	sd	s0,16(sp)
    80002250:	e426                	sd	s1,8(sp)
    80002252:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	758080e7          	jalr	1880(ra) # 800019ac <myproc>
    8000225c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	978080e7          	jalr	-1672(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002266:	478d                	li	a5,3
    80002268:	cc9c                	sw	a5,24(s1)
  sched();
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	f0a080e7          	jalr	-246(ra) # 80002174 <sched>
  release(&p->lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a16080e7          	jalr	-1514(ra) # 80000c8a <release>
}
    8000227c:	60e2                	ld	ra,24(sp)
    8000227e:	6442                	ld	s0,16(sp)
    80002280:	64a2                	ld	s1,8(sp)
    80002282:	6105                	addi	sp,sp,32
    80002284:	8082                	ret

0000000080002286 <set_priority>:
void set_priority(int priority, int pid, int *old){
    80002286:	7139                	addi	sp,sp,-64
    80002288:	fc06                	sd	ra,56(sp)
    8000228a:	f822                	sd	s0,48(sp)
    8000228c:	f426                	sd	s1,40(sp)
    8000228e:	f04a                	sd	s2,32(sp)
    80002290:	ec4e                	sd	s3,24(sp)
    80002292:	e852                	sd	s4,16(sp)
    80002294:	e456                	sd	s5,8(sp)
    80002296:	0080                	addi	s0,sp,64
    80002298:	8aaa                	mv	s5,a0
    8000229a:	892e                	mv	s2,a1
    8000229c:	8a32                	mv	s4,a2
  for (p = proc; p < &proc[NPROC]; p++){
    8000229e:	0000f497          	auipc	s1,0xf
    800022a2:	fb248493          	addi	s1,s1,-78 # 80011250 <proc>
    800022a6:	00015997          	auipc	s3,0x15
    800022aa:	5aa98993          	addi	s3,s3,1450 # 80017850 <tickslock>
    800022ae:	a029                	j	800022b8 <set_priority+0x32>
    800022b0:	19848493          	addi	s1,s1,408
    800022b4:	05348063          	beq	s1,s3,800022f4 <set_priority+0x6e>
    if(p->pid == pid){
    800022b8:	589c                	lw	a5,48(s1)
    800022ba:	ff279be3          	bne	a5,s2,800022b0 <set_priority+0x2a>
      acquire(&p->lock);
    800022be:	8526                	mv	a0,s1
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	916080e7          	jalr	-1770(ra) # 80000bd6 <acquire>
      *old = p->priority;
    800022c8:	1884a783          	lw	a5,392(s1)
    800022cc:	00fa2023          	sw	a5,0(s4)
      p->priority = priority;
    800022d0:	1954a423          	sw	s5,392(s1)
      p->runtime = 0;
    800022d4:	1804a823          	sw	zero,400(s1)
      release(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9b0080e7          	jalr	-1616(ra) # 80000c8a <release>
      if (*old_proc > priority){
    800022e2:	000a2783          	lw	a5,0(s4)
    800022e6:	fcfad5e3          	bge	s5,a5,800022b0 <set_priority+0x2a>
        yield();
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	f60080e7          	jalr	-160(ra) # 8000224a <yield>
    800022f2:	bf7d                	j	800022b0 <set_priority+0x2a>
}
    800022f4:	70e2                	ld	ra,56(sp)
    800022f6:	7442                	ld	s0,48(sp)
    800022f8:	74a2                	ld	s1,40(sp)
    800022fa:	7902                	ld	s2,32(sp)
    800022fc:	69e2                	ld	s3,24(sp)
    800022fe:	6a42                	ld	s4,16(sp)
    80002300:	6aa2                	ld	s5,8(sp)
    80002302:	6121                	addi	sp,sp,64
    80002304:	8082                	ret

0000000080002306 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002306:	7179                	addi	sp,sp,-48
    80002308:	f406                	sd	ra,40(sp)
    8000230a:	f022                	sd	s0,32(sp)
    8000230c:	ec26                	sd	s1,24(sp)
    8000230e:	e84a                	sd	s2,16(sp)
    80002310:	e44e                	sd	s3,8(sp)
    80002312:	1800                	addi	s0,sp,48
    80002314:	89aa                	mv	s3,a0
    80002316:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	694080e7          	jalr	1684(ra) # 800019ac <myproc>
    80002320:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	8b4080e7          	jalr	-1868(ra) # 80000bd6 <acquire>
  release(lk);
    8000232a:	854a                	mv	a0,s2
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	95e080e7          	jalr	-1698(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002334:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002338:	4789                	li	a5,2
    8000233a:	cc9c                	sw	a5,24(s1)

  sched();
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	e38080e7          	jalr	-456(ra) # 80002174 <sched>

  // Tidy up.
  p->chan = 0;
    80002344:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	940080e7          	jalr	-1728(ra) # 80000c8a <release>
  acquire(lk);
    80002352:	854a                	mv	a0,s2
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	882080e7          	jalr	-1918(ra) # 80000bd6 <acquire>
}
    8000235c:	70a2                	ld	ra,40(sp)
    8000235e:	7402                	ld	s0,32(sp)
    80002360:	64e2                	ld	s1,24(sp)
    80002362:	6942                	ld	s2,16(sp)
    80002364:	69a2                	ld	s3,8(sp)
    80002366:	6145                	addi	sp,sp,48
    80002368:	8082                	ret

000000008000236a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000236a:	7139                	addi	sp,sp,-64
    8000236c:	fc06                	sd	ra,56(sp)
    8000236e:	f822                	sd	s0,48(sp)
    80002370:	f426                	sd	s1,40(sp)
    80002372:	f04a                	sd	s2,32(sp)
    80002374:	ec4e                	sd	s3,24(sp)
    80002376:	e852                	sd	s4,16(sp)
    80002378:	e456                	sd	s5,8(sp)
    8000237a:	0080                	addi	s0,sp,64
    8000237c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000237e:	0000f497          	auipc	s1,0xf
    80002382:	ed248493          	addi	s1,s1,-302 # 80011250 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002386:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002388:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000238a:	00015917          	auipc	s2,0x15
    8000238e:	4c690913          	addi	s2,s2,1222 # 80017850 <tickslock>
    80002392:	a811                	j	800023a6 <wakeup+0x3c>
      }
      release(&p->lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	8f4080e7          	jalr	-1804(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000239e:	19848493          	addi	s1,s1,408
    800023a2:	03248663          	beq	s1,s2,800023ce <wakeup+0x64>
    if(p != myproc()){
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	606080e7          	jalr	1542(ra) # 800019ac <myproc>
    800023ae:	fea488e3          	beq	s1,a0,8000239e <wakeup+0x34>
      acquire(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	822080e7          	jalr	-2014(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023bc:	4c9c                	lw	a5,24(s1)
    800023be:	fd379be3          	bne	a5,s3,80002394 <wakeup+0x2a>
    800023c2:	709c                	ld	a5,32(s1)
    800023c4:	fd4798e3          	bne	a5,s4,80002394 <wakeup+0x2a>
        p->state = RUNNABLE;
    800023c8:	0154ac23          	sw	s5,24(s1)
    800023cc:	b7e1                	j	80002394 <wakeup+0x2a>
    }
  }
}
    800023ce:	70e2                	ld	ra,56(sp)
    800023d0:	7442                	ld	s0,48(sp)
    800023d2:	74a2                	ld	s1,40(sp)
    800023d4:	7902                	ld	s2,32(sp)
    800023d6:	69e2                	ld	s3,24(sp)
    800023d8:	6a42                	ld	s4,16(sp)
    800023da:	6aa2                	ld	s5,8(sp)
    800023dc:	6121                	addi	sp,sp,64
    800023de:	8082                	ret

00000000800023e0 <reparent>:
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	e052                	sd	s4,0(sp)
    800023ee:	1800                	addi	s0,sp,48
    800023f0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f2:	0000f497          	auipc	s1,0xf
    800023f6:	e5e48493          	addi	s1,s1,-418 # 80011250 <proc>
      pp->parent = initproc;
    800023fa:	00006a17          	auipc	s4,0x6
    800023fe:	7b6a0a13          	addi	s4,s4,1974 # 80008bb0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002402:	00015997          	auipc	s3,0x15
    80002406:	44e98993          	addi	s3,s3,1102 # 80017850 <tickslock>
    8000240a:	a029                	j	80002414 <reparent+0x34>
    8000240c:	19848493          	addi	s1,s1,408
    80002410:	01348d63          	beq	s1,s3,8000242a <reparent+0x4a>
    if(pp->parent == p){
    80002414:	7c9c                	ld	a5,56(s1)
    80002416:	ff279be3          	bne	a5,s2,8000240c <reparent+0x2c>
      pp->parent = initproc;
    8000241a:	000a3503          	ld	a0,0(s4)
    8000241e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002420:	00000097          	auipc	ra,0x0
    80002424:	f4a080e7          	jalr	-182(ra) # 8000236a <wakeup>
    80002428:	b7d5                	j	8000240c <reparent+0x2c>
}
    8000242a:	70a2                	ld	ra,40(sp)
    8000242c:	7402                	ld	s0,32(sp)
    8000242e:	64e2                	ld	s1,24(sp)
    80002430:	6942                	ld	s2,16(sp)
    80002432:	69a2                	ld	s3,8(sp)
    80002434:	6a02                	ld	s4,0(sp)
    80002436:	6145                	addi	sp,sp,48
    80002438:	8082                	ret

000000008000243a <exit>:
{
    8000243a:	7179                	addi	sp,sp,-48
    8000243c:	f406                	sd	ra,40(sp)
    8000243e:	f022                	sd	s0,32(sp)
    80002440:	ec26                	sd	s1,24(sp)
    80002442:	e84a                	sd	s2,16(sp)
    80002444:	e44e                	sd	s3,8(sp)
    80002446:	e052                	sd	s4,0(sp)
    80002448:	1800                	addi	s0,sp,48
    8000244a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	560080e7          	jalr	1376(ra) # 800019ac <myproc>
    80002454:	89aa                	mv	s3,a0
  if(p == initproc)
    80002456:	00006797          	auipc	a5,0x6
    8000245a:	75a7b783          	ld	a5,1882(a5) # 80008bb0 <initproc>
    8000245e:	0d050493          	addi	s1,a0,208
    80002462:	15050913          	addi	s2,a0,336
    80002466:	02a79363          	bne	a5,a0,8000248c <exit+0x52>
    panic("init exiting");
    8000246a:	00006517          	auipc	a0,0x6
    8000246e:	df650513          	addi	a0,a0,-522 # 80008260 <digits+0x220>
    80002472:	ffffe097          	auipc	ra,0xffffe
    80002476:	0ce080e7          	jalr	206(ra) # 80000540 <panic>
      fileclose(f);
    8000247a:	00002097          	auipc	ra,0x2
    8000247e:	5a6080e7          	jalr	1446(ra) # 80004a20 <fileclose>
      p->ofile[fd] = 0;
    80002482:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002486:	04a1                	addi	s1,s1,8
    80002488:	01248563          	beq	s1,s2,80002492 <exit+0x58>
    if(p->ofile[fd]){
    8000248c:	6088                	ld	a0,0(s1)
    8000248e:	f575                	bnez	a0,8000247a <exit+0x40>
    80002490:	bfdd                	j	80002486 <exit+0x4c>
  begin_op();
    80002492:	00002097          	auipc	ra,0x2
    80002496:	0c6080e7          	jalr	198(ra) # 80004558 <begin_op>
  iput(p->cwd);
    8000249a:	1509b503          	ld	a0,336(s3)
    8000249e:	00002097          	auipc	ra,0x2
    800024a2:	8a8080e7          	jalr	-1880(ra) # 80003d46 <iput>
  end_op();
    800024a6:	00002097          	auipc	ra,0x2
    800024aa:	130080e7          	jalr	304(ra) # 800045d6 <end_op>
  p->cwd = 0;
    800024ae:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024b2:	0000f497          	auipc	s1,0xf
    800024b6:	98648493          	addi	s1,s1,-1658 # 80010e38 <wait_lock>
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	71a080e7          	jalr	1818(ra) # 80000bd6 <acquire>
  reparent(p);
    800024c4:	854e                	mv	a0,s3
    800024c6:	00000097          	auipc	ra,0x0
    800024ca:	f1a080e7          	jalr	-230(ra) # 800023e0 <reparent>
  wakeup(p->parent);
    800024ce:	0389b503          	ld	a0,56(s3)
    800024d2:	00000097          	auipc	ra,0x0
    800024d6:	e98080e7          	jalr	-360(ra) # 8000236a <wakeup>
  acquire(&p->lock);
    800024da:	854e                	mv	a0,s3
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	6fa080e7          	jalr	1786(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800024e4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024e8:	4795                	li	a5,5
    800024ea:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800024ee:	00006797          	auipc	a5,0x6
    800024f2:	6ca7a783          	lw	a5,1738(a5) # 80008bb8 <ticks>
    800024f6:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	78e080e7          	jalr	1934(ra) # 80000c8a <release>
  sched();
    80002504:	00000097          	auipc	ra,0x0
    80002508:	c70080e7          	jalr	-912(ra) # 80002174 <sched>
  panic("zombie exit");
    8000250c:	00006517          	auipc	a0,0x6
    80002510:	d6450513          	addi	a0,a0,-668 # 80008270 <digits+0x230>
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	02c080e7          	jalr	44(ra) # 80000540 <panic>

000000008000251c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000251c:	7179                	addi	sp,sp,-48
    8000251e:	f406                	sd	ra,40(sp)
    80002520:	f022                	sd	s0,32(sp)
    80002522:	ec26                	sd	s1,24(sp)
    80002524:	e84a                	sd	s2,16(sp)
    80002526:	e44e                	sd	s3,8(sp)
    80002528:	1800                	addi	s0,sp,48
    8000252a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000252c:	0000f497          	auipc	s1,0xf
    80002530:	d2448493          	addi	s1,s1,-732 # 80011250 <proc>
    80002534:	00015997          	auipc	s3,0x15
    80002538:	31c98993          	addi	s3,s3,796 # 80017850 <tickslock>
    acquire(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	698080e7          	jalr	1688(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002546:	589c                	lw	a5,48(s1)
    80002548:	01278d63          	beq	a5,s2,80002562 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	73c080e7          	jalr	1852(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002556:	19848493          	addi	s1,s1,408
    8000255a:	ff3491e3          	bne	s1,s3,8000253c <kill+0x20>
  }
  return -1;
    8000255e:	557d                	li	a0,-1
    80002560:	a829                	j	8000257a <kill+0x5e>
      p->killed = 1;
    80002562:	4785                	li	a5,1
    80002564:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002566:	4c98                	lw	a4,24(s1)
    80002568:	4789                	li	a5,2
    8000256a:	00f70f63          	beq	a4,a5,80002588 <kill+0x6c>
      release(&p->lock);
    8000256e:	8526                	mv	a0,s1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	71a080e7          	jalr	1818(ra) # 80000c8a <release>
      return 0;
    80002578:	4501                	li	a0,0
}
    8000257a:	70a2                	ld	ra,40(sp)
    8000257c:	7402                	ld	s0,32(sp)
    8000257e:	64e2                	ld	s1,24(sp)
    80002580:	6942                	ld	s2,16(sp)
    80002582:	69a2                	ld	s3,8(sp)
    80002584:	6145                	addi	sp,sp,48
    80002586:	8082                	ret
        p->state = RUNNABLE;
    80002588:	478d                	li	a5,3
    8000258a:	cc9c                	sw	a5,24(s1)
    8000258c:	b7cd                	j	8000256e <kill+0x52>

000000008000258e <setkilled>:

void
setkilled(struct proc *p)
{
    8000258e:	1101                	addi	sp,sp,-32
    80002590:	ec06                	sd	ra,24(sp)
    80002592:	e822                	sd	s0,16(sp)
    80002594:	e426                	sd	s1,8(sp)
    80002596:	1000                	addi	s0,sp,32
    80002598:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	63c080e7          	jalr	1596(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800025a2:	4785                	li	a5,1
    800025a4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025a6:	8526                	mv	a0,s1
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	6e2080e7          	jalr	1762(ra) # 80000c8a <release>
}
    800025b0:	60e2                	ld	ra,24(sp)
    800025b2:	6442                	ld	s0,16(sp)
    800025b4:	64a2                	ld	s1,8(sp)
    800025b6:	6105                	addi	sp,sp,32
    800025b8:	8082                	ret

00000000800025ba <killed>:

int
killed(struct proc *p)
{
    800025ba:	1101                	addi	sp,sp,-32
    800025bc:	ec06                	sd	ra,24(sp)
    800025be:	e822                	sd	s0,16(sp)
    800025c0:	e426                	sd	s1,8(sp)
    800025c2:	e04a                	sd	s2,0(sp)
    800025c4:	1000                	addi	s0,sp,32
    800025c6:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	60e080e7          	jalr	1550(ra) # 80000bd6 <acquire>
  k = p->killed;
    800025d0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6b4080e7          	jalr	1716(ra) # 80000c8a <release>
  return k;
}
    800025de:	854a                	mv	a0,s2
    800025e0:	60e2                	ld	ra,24(sp)
    800025e2:	6442                	ld	s0,16(sp)
    800025e4:	64a2                	ld	s1,8(sp)
    800025e6:	6902                	ld	s2,0(sp)
    800025e8:	6105                	addi	sp,sp,32
    800025ea:	8082                	ret

00000000800025ec <wait>:
{
    800025ec:	715d                	addi	sp,sp,-80
    800025ee:	e486                	sd	ra,72(sp)
    800025f0:	e0a2                	sd	s0,64(sp)
    800025f2:	fc26                	sd	s1,56(sp)
    800025f4:	f84a                	sd	s2,48(sp)
    800025f6:	f44e                	sd	s3,40(sp)
    800025f8:	f052                	sd	s4,32(sp)
    800025fa:	ec56                	sd	s5,24(sp)
    800025fc:	e85a                	sd	s6,16(sp)
    800025fe:	e45e                	sd	s7,8(sp)
    80002600:	e062                	sd	s8,0(sp)
    80002602:	0880                	addi	s0,sp,80
    80002604:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	3a6080e7          	jalr	934(ra) # 800019ac <myproc>
    8000260e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002610:	0000f517          	auipc	a0,0xf
    80002614:	82850513          	addi	a0,a0,-2008 # 80010e38 <wait_lock>
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	5be080e7          	jalr	1470(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002620:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002622:	4a15                	li	s4,5
        havekids = 1;
    80002624:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002626:	00015997          	auipc	s3,0x15
    8000262a:	22a98993          	addi	s3,s3,554 # 80017850 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000262e:	0000fc17          	auipc	s8,0xf
    80002632:	80ac0c13          	addi	s8,s8,-2038 # 80010e38 <wait_lock>
    havekids = 0;
    80002636:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002638:	0000f497          	auipc	s1,0xf
    8000263c:	c1848493          	addi	s1,s1,-1000 # 80011250 <proc>
    80002640:	a0bd                	j	800026ae <wait+0xc2>
          pid = pp->pid;
    80002642:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002646:	000b0e63          	beqz	s6,80002662 <wait+0x76>
    8000264a:	4691                	li	a3,4
    8000264c:	02c48613          	addi	a2,s1,44
    80002650:	85da                	mv	a1,s6
    80002652:	05093503          	ld	a0,80(s2)
    80002656:	fffff097          	auipc	ra,0xfffff
    8000265a:	016080e7          	jalr	22(ra) # 8000166c <copyout>
    8000265e:	02054563          	bltz	a0,80002688 <wait+0x9c>
          freeproc(pp);
    80002662:	8526                	mv	a0,s1
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	4fa080e7          	jalr	1274(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	61c080e7          	jalr	1564(ra) # 80000c8a <release>
          release(&wait_lock);
    80002676:	0000e517          	auipc	a0,0xe
    8000267a:	7c250513          	addi	a0,a0,1986 # 80010e38 <wait_lock>
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	60c080e7          	jalr	1548(ra) # 80000c8a <release>
          return pid;
    80002686:	a0b5                	j	800026f2 <wait+0x106>
            release(&pp->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	600080e7          	jalr	1536(ra) # 80000c8a <release>
            release(&wait_lock);
    80002692:	0000e517          	auipc	a0,0xe
    80002696:	7a650513          	addi	a0,a0,1958 # 80010e38 <wait_lock>
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	5f0080e7          	jalr	1520(ra) # 80000c8a <release>
            return -1;
    800026a2:	59fd                	li	s3,-1
    800026a4:	a0b9                	j	800026f2 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026a6:	19848493          	addi	s1,s1,408
    800026aa:	03348463          	beq	s1,s3,800026d2 <wait+0xe6>
      if(pp->parent == p){
    800026ae:	7c9c                	ld	a5,56(s1)
    800026b0:	ff279be3          	bne	a5,s2,800026a6 <wait+0xba>
        acquire(&pp->lock);
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	520080e7          	jalr	1312(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800026be:	4c9c                	lw	a5,24(s1)
    800026c0:	f94781e3          	beq	a5,s4,80002642 <wait+0x56>
        release(&pp->lock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	5c4080e7          	jalr	1476(ra) # 80000c8a <release>
        havekids = 1;
    800026ce:	8756                	mv	a4,s5
    800026d0:	bfd9                	j	800026a6 <wait+0xba>
    if(!havekids || killed(p)){
    800026d2:	c719                	beqz	a4,800026e0 <wait+0xf4>
    800026d4:	854a                	mv	a0,s2
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	ee4080e7          	jalr	-284(ra) # 800025ba <killed>
    800026de:	c51d                	beqz	a0,8000270c <wait+0x120>
      release(&wait_lock);
    800026e0:	0000e517          	auipc	a0,0xe
    800026e4:	75850513          	addi	a0,a0,1880 # 80010e38 <wait_lock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5a2080e7          	jalr	1442(ra) # 80000c8a <release>
      return -1;
    800026f0:	59fd                	li	s3,-1
}
    800026f2:	854e                	mv	a0,s3
    800026f4:	60a6                	ld	ra,72(sp)
    800026f6:	6406                	ld	s0,64(sp)
    800026f8:	74e2                	ld	s1,56(sp)
    800026fa:	7942                	ld	s2,48(sp)
    800026fc:	79a2                	ld	s3,40(sp)
    800026fe:	7a02                	ld	s4,32(sp)
    80002700:	6ae2                	ld	s5,24(sp)
    80002702:	6b42                	ld	s6,16(sp)
    80002704:	6ba2                	ld	s7,8(sp)
    80002706:	6c02                	ld	s8,0(sp)
    80002708:	6161                	addi	sp,sp,80
    8000270a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000270c:	85e2                	mv	a1,s8
    8000270e:	854a                	mv	a0,s2
    80002710:	00000097          	auipc	ra,0x0
    80002714:	bf6080e7          	jalr	-1034(ra) # 80002306 <sleep>
    havekids = 0;
    80002718:	bf39                	j	80002636 <wait+0x4a>

000000008000271a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000271a:	7179                	addi	sp,sp,-48
    8000271c:	f406                	sd	ra,40(sp)
    8000271e:	f022                	sd	s0,32(sp)
    80002720:	ec26                	sd	s1,24(sp)
    80002722:	e84a                	sd	s2,16(sp)
    80002724:	e44e                	sd	s3,8(sp)
    80002726:	e052                	sd	s4,0(sp)
    80002728:	1800                	addi	s0,sp,48
    8000272a:	84aa                	mv	s1,a0
    8000272c:	892e                	mv	s2,a1
    8000272e:	89b2                	mv	s3,a2
    80002730:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	27a080e7          	jalr	634(ra) # 800019ac <myproc>
  if(user_dst){
    8000273a:	c08d                	beqz	s1,8000275c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000273c:	86d2                	mv	a3,s4
    8000273e:	864e                	mv	a2,s3
    80002740:	85ca                	mv	a1,s2
    80002742:	6928                	ld	a0,80(a0)
    80002744:	fffff097          	auipc	ra,0xfffff
    80002748:	f28080e7          	jalr	-216(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000274c:	70a2                	ld	ra,40(sp)
    8000274e:	7402                	ld	s0,32(sp)
    80002750:	64e2                	ld	s1,24(sp)
    80002752:	6942                	ld	s2,16(sp)
    80002754:	69a2                	ld	s3,8(sp)
    80002756:	6a02                	ld	s4,0(sp)
    80002758:	6145                	addi	sp,sp,48
    8000275a:	8082                	ret
    memmove((char *)dst, src, len);
    8000275c:	000a061b          	sext.w	a2,s4
    80002760:	85ce                	mv	a1,s3
    80002762:	854a                	mv	a0,s2
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	5ca080e7          	jalr	1482(ra) # 80000d2e <memmove>
    return 0;
    8000276c:	8526                	mv	a0,s1
    8000276e:	bff9                	j	8000274c <either_copyout+0x32>

0000000080002770 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002770:	7179                	addi	sp,sp,-48
    80002772:	f406                	sd	ra,40(sp)
    80002774:	f022                	sd	s0,32(sp)
    80002776:	ec26                	sd	s1,24(sp)
    80002778:	e84a                	sd	s2,16(sp)
    8000277a:	e44e                	sd	s3,8(sp)
    8000277c:	e052                	sd	s4,0(sp)
    8000277e:	1800                	addi	s0,sp,48
    80002780:	892a                	mv	s2,a0
    80002782:	84ae                	mv	s1,a1
    80002784:	89b2                	mv	s3,a2
    80002786:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002788:	fffff097          	auipc	ra,0xfffff
    8000278c:	224080e7          	jalr	548(ra) # 800019ac <myproc>
  if(user_src){
    80002790:	c08d                	beqz	s1,800027b2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002792:	86d2                	mv	a3,s4
    80002794:	864e                	mv	a2,s3
    80002796:	85ca                	mv	a1,s2
    80002798:	6928                	ld	a0,80(a0)
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	f5e080e7          	jalr	-162(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027a2:	70a2                	ld	ra,40(sp)
    800027a4:	7402                	ld	s0,32(sp)
    800027a6:	64e2                	ld	s1,24(sp)
    800027a8:	6942                	ld	s2,16(sp)
    800027aa:	69a2                	ld	s3,8(sp)
    800027ac:	6a02                	ld	s4,0(sp)
    800027ae:	6145                	addi	sp,sp,48
    800027b0:	8082                	ret
    memmove(dst, (char*)src, len);
    800027b2:	000a061b          	sext.w	a2,s4
    800027b6:	85ce                	mv	a1,s3
    800027b8:	854a                	mv	a0,s2
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	574080e7          	jalr	1396(ra) # 80000d2e <memmove>
    return 0;
    800027c2:	8526                	mv	a0,s1
    800027c4:	bff9                	j	800027a2 <either_copyin+0x32>

00000000800027c6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027c6:	715d                	addi	sp,sp,-80
    800027c8:	e486                	sd	ra,72(sp)
    800027ca:	e0a2                	sd	s0,64(sp)
    800027cc:	fc26                	sd	s1,56(sp)
    800027ce:	f84a                	sd	s2,48(sp)
    800027d0:	f44e                	sd	s3,40(sp)
    800027d2:	f052                	sd	s4,32(sp)
    800027d4:	ec56                	sd	s5,24(sp)
    800027d6:	e85a                	sd	s6,16(sp)
    800027d8:	e45e                	sd	s7,8(sp)
    800027da:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027dc:	00006517          	auipc	a0,0x6
    800027e0:	22c50513          	addi	a0,a0,556 # 80008a08 <syscalls+0x5b8>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	da6080e7          	jalr	-602(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027ec:	0000f497          	auipc	s1,0xf
    800027f0:	bbc48493          	addi	s1,s1,-1092 # 800113a8 <proc+0x158>
    800027f4:	00015917          	auipc	s2,0x15
    800027f8:	1b490913          	addi	s2,s2,436 # 800179a8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027fc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027fe:	00006997          	auipc	s3,0x6
    80002802:	a8298993          	addi	s3,s3,-1406 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002806:	00006a97          	auipc	s5,0x6
    8000280a:	a82a8a93          	addi	s5,s5,-1406 # 80008288 <digits+0x248>
    printf("\n");
    8000280e:	00006a17          	auipc	s4,0x6
    80002812:	1faa0a13          	addi	s4,s4,506 # 80008a08 <syscalls+0x5b8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002816:	00006b97          	auipc	s7,0x6
    8000281a:	ab2b8b93          	addi	s7,s7,-1358 # 800082c8 <states.0>
    8000281e:	a00d                	j	80002840 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002820:	ed86a583          	lw	a1,-296(a3)
    80002824:	8556                	mv	a0,s5
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	d64080e7          	jalr	-668(ra) # 8000058a <printf>
    printf("\n");
    8000282e:	8552                	mv	a0,s4
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	d5a080e7          	jalr	-678(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002838:	19848493          	addi	s1,s1,408
    8000283c:	03248263          	beq	s1,s2,80002860 <procdump+0x9a>
    if(p->state == UNUSED)
    80002840:	86a6                	mv	a3,s1
    80002842:	ec04a783          	lw	a5,-320(s1)
    80002846:	dbed                	beqz	a5,80002838 <procdump+0x72>
      state = "???";
    80002848:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000284a:	fcfb6be3          	bltu	s6,a5,80002820 <procdump+0x5a>
    8000284e:	02079713          	slli	a4,a5,0x20
    80002852:	01d75793          	srli	a5,a4,0x1d
    80002856:	97de                	add	a5,a5,s7
    80002858:	6390                	ld	a2,0(a5)
    8000285a:	f279                	bnez	a2,80002820 <procdump+0x5a>
      state = "???";
    8000285c:	864e                	mv	a2,s3
    8000285e:	b7c9                	j	80002820 <procdump+0x5a>
  }
}
    80002860:	60a6                	ld	ra,72(sp)
    80002862:	6406                	ld	s0,64(sp)
    80002864:	74e2                	ld	s1,56(sp)
    80002866:	7942                	ld	s2,48(sp)
    80002868:	79a2                	ld	s3,40(sp)
    8000286a:	7a02                	ld	s4,32(sp)
    8000286c:	6ae2                	ld	s5,24(sp)
    8000286e:	6b42                	ld	s6,16(sp)
    80002870:	6ba2                	ld	s7,8(sp)
    80002872:	6161                	addi	sp,sp,80
    80002874:	8082                	ret

0000000080002876 <swtch>:
    80002876:	00153023          	sd	ra,0(a0)
    8000287a:	00253423          	sd	sp,8(a0)
    8000287e:	e900                	sd	s0,16(a0)
    80002880:	ed04                	sd	s1,24(a0)
    80002882:	03253023          	sd	s2,32(a0)
    80002886:	03353423          	sd	s3,40(a0)
    8000288a:	03453823          	sd	s4,48(a0)
    8000288e:	03553c23          	sd	s5,56(a0)
    80002892:	05653023          	sd	s6,64(a0)
    80002896:	05753423          	sd	s7,72(a0)
    8000289a:	05853823          	sd	s8,80(a0)
    8000289e:	05953c23          	sd	s9,88(a0)
    800028a2:	07a53023          	sd	s10,96(a0)
    800028a6:	07b53423          	sd	s11,104(a0)
    800028aa:	0005b083          	ld	ra,0(a1)
    800028ae:	0085b103          	ld	sp,8(a1)
    800028b2:	6980                	ld	s0,16(a1)
    800028b4:	6d84                	ld	s1,24(a1)
    800028b6:	0205b903          	ld	s2,32(a1)
    800028ba:	0285b983          	ld	s3,40(a1)
    800028be:	0305ba03          	ld	s4,48(a1)
    800028c2:	0385ba83          	ld	s5,56(a1)
    800028c6:	0405bb03          	ld	s6,64(a1)
    800028ca:	0485bb83          	ld	s7,72(a1)
    800028ce:	0505bc03          	ld	s8,80(a1)
    800028d2:	0585bc83          	ld	s9,88(a1)
    800028d6:	0605bd03          	ld	s10,96(a1)
    800028da:	0685bd83          	ld	s11,104(a1)
    800028de:	8082                	ret

00000000800028e0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028e0:	1141                	addi	sp,sp,-16
    800028e2:	e406                	sd	ra,8(sp)
    800028e4:	e022                	sd	s0,0(sp)
    800028e6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028e8:	00006597          	auipc	a1,0x6
    800028ec:	a1058593          	addi	a1,a1,-1520 # 800082f8 <states.0+0x30>
    800028f0:	00015517          	auipc	a0,0x15
    800028f4:	f6050513          	addi	a0,a0,-160 # 80017850 <tickslock>
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	24e080e7          	jalr	590(ra) # 80000b46 <initlock>
}
    80002900:	60a2                	ld	ra,8(sp)
    80002902:	6402                	ld	s0,0(sp)
    80002904:	0141                	addi	sp,sp,16
    80002906:	8082                	ret

0000000080002908 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002908:	1141                	addi	sp,sp,-16
    8000290a:	e422                	sd	s0,8(sp)
    8000290c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000290e:	00004797          	auipc	a5,0x4
    80002912:	9a278793          	addi	a5,a5,-1630 # 800062b0 <kernelvec>
    80002916:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000291a:	6422                	ld	s0,8(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret

0000000080002920 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002920:	1141                	addi	sp,sp,-16
    80002922:	e406                	sd	ra,8(sp)
    80002924:	e022                	sd	s0,0(sp)
    80002926:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	084080e7          	jalr	132(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002930:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002934:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002936:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000293a:	00004697          	auipc	a3,0x4
    8000293e:	6c668693          	addi	a3,a3,1734 # 80007000 <_trampoline>
    80002942:	00004717          	auipc	a4,0x4
    80002946:	6be70713          	addi	a4,a4,1726 # 80007000 <_trampoline>
    8000294a:	8f15                	sub	a4,a4,a3
    8000294c:	040007b7          	lui	a5,0x4000
    80002950:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002952:	07b2                	slli	a5,a5,0xc
    80002954:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002956:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000295a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000295c:	18002673          	csrr	a2,satp
    80002960:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002962:	6d30                	ld	a2,88(a0)
    80002964:	6138                	ld	a4,64(a0)
    80002966:	6585                	lui	a1,0x1
    80002968:	972e                	add	a4,a4,a1
    8000296a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000296c:	6d38                	ld	a4,88(a0)
    8000296e:	00000617          	auipc	a2,0x0
    80002972:	13e60613          	addi	a2,a2,318 # 80002aac <usertrap>
    80002976:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002978:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000297a:	8612                	mv	a2,tp
    8000297c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002982:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002986:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000298a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000298e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002990:	6f18                	ld	a4,24(a4)
    80002992:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002996:	6928                	ld	a0,80(a0)
    80002998:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000299a:	00004717          	auipc	a4,0x4
    8000299e:	70270713          	addi	a4,a4,1794 # 8000709c <userret>
    800029a2:	8f15                	sub	a4,a4,a3
    800029a4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029a6:	577d                	li	a4,-1
    800029a8:	177e                	slli	a4,a4,0x3f
    800029aa:	8d59                	or	a0,a0,a4
    800029ac:	9782                	jalr	a5
}
    800029ae:	60a2                	ld	ra,8(sp)
    800029b0:	6402                	ld	s0,0(sp)
    800029b2:	0141                	addi	sp,sp,16
    800029b4:	8082                	ret

00000000800029b6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029b6:	1101                	addi	sp,sp,-32
    800029b8:	ec06                	sd	ra,24(sp)
    800029ba:	e822                	sd	s0,16(sp)
    800029bc:	e426                	sd	s1,8(sp)
    800029be:	e04a                	sd	s2,0(sp)
    800029c0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029c2:	00015917          	auipc	s2,0x15
    800029c6:	e8e90913          	addi	s2,s2,-370 # 80017850 <tickslock>
    800029ca:	854a                	mv	a0,s2
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	20a080e7          	jalr	522(ra) # 80000bd6 <acquire>
  ticks++;
    800029d4:	00006497          	auipc	s1,0x6
    800029d8:	1e448493          	addi	s1,s1,484 # 80008bb8 <ticks>
    800029dc:	409c                	lw	a5,0(s1)
    800029de:	2785                	addiw	a5,a5,1
    800029e0:	c09c                	sw	a5,0(s1)
  update_time();
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	552080e7          	jalr	1362(ra) # 80001f34 <update_time>
  wakeup(&ticks);
    800029ea:	8526                	mv	a0,s1
    800029ec:	00000097          	auipc	ra,0x0
    800029f0:	97e080e7          	jalr	-1666(ra) # 8000236a <wakeup>
  release(&tickslock);
    800029f4:	854a                	mv	a0,s2
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	294080e7          	jalr	660(ra) # 80000c8a <release>
}
    800029fe:	60e2                	ld	ra,24(sp)
    80002a00:	6442                	ld	s0,16(sp)
    80002a02:	64a2                	ld	s1,8(sp)
    80002a04:	6902                	ld	s2,0(sp)
    80002a06:	6105                	addi	sp,sp,32
    80002a08:	8082                	ret

0000000080002a0a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a0a:	1101                	addi	sp,sp,-32
    80002a0c:	ec06                	sd	ra,24(sp)
    80002a0e:	e822                	sd	s0,16(sp)
    80002a10:	e426                	sd	s1,8(sp)
    80002a12:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a14:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a18:	00074d63          	bltz	a4,80002a32 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a1c:	57fd                	li	a5,-1
    80002a1e:	17fe                	slli	a5,a5,0x3f
    80002a20:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a22:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a24:	06f70363          	beq	a4,a5,80002a8a <devintr+0x80>
  }
}
    80002a28:	60e2                	ld	ra,24(sp)
    80002a2a:	6442                	ld	s0,16(sp)
    80002a2c:	64a2                	ld	s1,8(sp)
    80002a2e:	6105                	addi	sp,sp,32
    80002a30:	8082                	ret
     (scause & 0xff) == 9){
    80002a32:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002a36:	46a5                	li	a3,9
    80002a38:	fed792e3          	bne	a5,a3,80002a1c <devintr+0x12>
    int irq = plic_claim();
    80002a3c:	00004097          	auipc	ra,0x4
    80002a40:	97c080e7          	jalr	-1668(ra) # 800063b8 <plic_claim>
    80002a44:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a46:	47a9                	li	a5,10
    80002a48:	02f50763          	beq	a0,a5,80002a76 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a4c:	4785                	li	a5,1
    80002a4e:	02f50963          	beq	a0,a5,80002a80 <devintr+0x76>
    return 1;
    80002a52:	4505                	li	a0,1
    } else if(irq){
    80002a54:	d8f1                	beqz	s1,80002a28 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a56:	85a6                	mv	a1,s1
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	8a850513          	addi	a0,a0,-1880 # 80008300 <states.0+0x38>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	b2a080e7          	jalr	-1238(ra) # 8000058a <printf>
      plic_complete(irq);
    80002a68:	8526                	mv	a0,s1
    80002a6a:	00004097          	auipc	ra,0x4
    80002a6e:	972080e7          	jalr	-1678(ra) # 800063dc <plic_complete>
    return 1;
    80002a72:	4505                	li	a0,1
    80002a74:	bf55                	j	80002a28 <devintr+0x1e>
      uartintr();
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	f22080e7          	jalr	-222(ra) # 80000998 <uartintr>
    80002a7e:	b7ed                	j	80002a68 <devintr+0x5e>
      virtio_disk_intr();
    80002a80:	00004097          	auipc	ra,0x4
    80002a84:	e24080e7          	jalr	-476(ra) # 800068a4 <virtio_disk_intr>
    80002a88:	b7c5                	j	80002a68 <devintr+0x5e>
    if(cpuid() == 0){
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	ef6080e7          	jalr	-266(ra) # 80001980 <cpuid>
    80002a92:	c901                	beqz	a0,80002aa2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a94:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a9a:	14479073          	csrw	sip,a5
    return 2;
    80002a9e:	4509                	li	a0,2
    80002aa0:	b761                	j	80002a28 <devintr+0x1e>
      clockintr();
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	f14080e7          	jalr	-236(ra) # 800029b6 <clockintr>
    80002aaa:	b7ed                	j	80002a94 <devintr+0x8a>

0000000080002aac <usertrap>:
{
    80002aac:	1101                	addi	sp,sp,-32
    80002aae:	ec06                	sd	ra,24(sp)
    80002ab0:	e822                	sd	s0,16(sp)
    80002ab2:	e426                	sd	s1,8(sp)
    80002ab4:	e04a                	sd	s2,0(sp)
    80002ab6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002abc:	1007f793          	andi	a5,a5,256
    80002ac0:	e3b1                	bnez	a5,80002b04 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ac2:	00003797          	auipc	a5,0x3
    80002ac6:	7ee78793          	addi	a5,a5,2030 # 800062b0 <kernelvec>
    80002aca:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	ede080e7          	jalr	-290(ra) # 800019ac <myproc>
    80002ad6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ad8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ada:	14102773          	csrr	a4,sepc
    80002ade:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ae4:	47a1                	li	a5,8
    80002ae6:	02f70763          	beq	a4,a5,80002b14 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	f20080e7          	jalr	-224(ra) # 80002a0a <devintr>
    80002af2:	892a                	mv	s2,a0
    80002af4:	c151                	beqz	a0,80002b78 <usertrap+0xcc>
  if(killed(p))
    80002af6:	8526                	mv	a0,s1
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	ac2080e7          	jalr	-1342(ra) # 800025ba <killed>
    80002b00:	c929                	beqz	a0,80002b52 <usertrap+0xa6>
    80002b02:	a099                	j	80002b48 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	81c50513          	addi	a0,a0,-2020 # 80008320 <states.0+0x58>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a34080e7          	jalr	-1484(ra) # 80000540 <panic>
    if(killed(p))
    80002b14:	00000097          	auipc	ra,0x0
    80002b18:	aa6080e7          	jalr	-1370(ra) # 800025ba <killed>
    80002b1c:	e921                	bnez	a0,80002b6c <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002b1e:	6cb8                	ld	a4,88(s1)
    80002b20:	6f1c                	ld	a5,24(a4)
    80002b22:	0791                	addi	a5,a5,4
    80002b24:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b2a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b2e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	2d4080e7          	jalr	724(ra) # 80002e06 <syscall>
  if(killed(p))
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	a7e080e7          	jalr	-1410(ra) # 800025ba <killed>
    80002b44:	c911                	beqz	a0,80002b58 <usertrap+0xac>
    80002b46:	4901                	li	s2,0
    exit(-1);
    80002b48:	557d                	li	a0,-1
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	8f0080e7          	jalr	-1808(ra) # 8000243a <exit>
  if(which_dev == 2)
    80002b52:	4789                	li	a5,2
    80002b54:	04f90f63          	beq	s2,a5,80002bb2 <usertrap+0x106>
  usertrapret();
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	dc8080e7          	jalr	-568(ra) # 80002920 <usertrapret>
}
    80002b60:	60e2                	ld	ra,24(sp)
    80002b62:	6442                	ld	s0,16(sp)
    80002b64:	64a2                	ld	s1,8(sp)
    80002b66:	6902                	ld	s2,0(sp)
    80002b68:	6105                	addi	sp,sp,32
    80002b6a:	8082                	ret
      exit(-1);
    80002b6c:	557d                	li	a0,-1
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	8cc080e7          	jalr	-1844(ra) # 8000243a <exit>
    80002b76:	b765                	j	80002b1e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b78:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b7c:	5890                	lw	a2,48(s1)
    80002b7e:	00005517          	auipc	a0,0x5
    80002b82:	7c250513          	addi	a0,a0,1986 # 80008340 <states.0+0x78>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	a04080e7          	jalr	-1532(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b92:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b96:	00005517          	auipc	a0,0x5
    80002b9a:	7da50513          	addi	a0,a0,2010 # 80008370 <states.0+0xa8>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9ec080e7          	jalr	-1556(ra) # 8000058a <printf>
    setkilled(p);
    80002ba6:	8526                	mv	a0,s1
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	9e6080e7          	jalr	-1562(ra) # 8000258e <setkilled>
    80002bb0:	b769                	j	80002b3a <usertrap+0x8e>
    yield();
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	698080e7          	jalr	1688(ra) # 8000224a <yield>
    80002bba:	bf79                	j	80002b58 <usertrap+0xac>

0000000080002bbc <kerneltrap>:
{
    80002bbc:	7179                	addi	sp,sp,-48
    80002bbe:	f406                	sd	ra,40(sp)
    80002bc0:	f022                	sd	s0,32(sp)
    80002bc2:	ec26                	sd	s1,24(sp)
    80002bc4:	e84a                	sd	s2,16(sp)
    80002bc6:	e44e                	sd	s3,8(sp)
    80002bc8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bca:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bd6:	1004f793          	andi	a5,s1,256
    80002bda:	cb85                	beqz	a5,80002c0a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002be0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002be2:	ef85                	bnez	a5,80002c1a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	e26080e7          	jalr	-474(ra) # 80002a0a <devintr>
    80002bec:	cd1d                	beqz	a0,80002c2a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bee:	4789                	li	a5,2
    80002bf0:	06f50a63          	beq	a0,a5,80002c64 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bf4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf8:	10049073          	csrw	sstatus,s1
}
    80002bfc:	70a2                	ld	ra,40(sp)
    80002bfe:	7402                	ld	s0,32(sp)
    80002c00:	64e2                	ld	s1,24(sp)
    80002c02:	6942                	ld	s2,16(sp)
    80002c04:	69a2                	ld	s3,8(sp)
    80002c06:	6145                	addi	sp,sp,48
    80002c08:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c0a:	00005517          	auipc	a0,0x5
    80002c0e:	78650513          	addi	a0,a0,1926 # 80008390 <states.0+0xc8>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	92e080e7          	jalr	-1746(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	79e50513          	addi	a0,a0,1950 # 800083b8 <states.0+0xf0>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002c2a:	85ce                	mv	a1,s3
    80002c2c:	00005517          	auipc	a0,0x5
    80002c30:	7ac50513          	addi	a0,a0,1964 # 800083d8 <states.0+0x110>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	956080e7          	jalr	-1706(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c40:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c44:	00005517          	auipc	a0,0x5
    80002c48:	7a450513          	addi	a0,a0,1956 # 800083e8 <states.0+0x120>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	93e080e7          	jalr	-1730(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c54:	00005517          	auipc	a0,0x5
    80002c58:	7ac50513          	addi	a0,a0,1964 # 80008400 <states.0+0x138>
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	8e4080e7          	jalr	-1820(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	d48080e7          	jalr	-696(ra) # 800019ac <myproc>
    80002c6c:	d541                	beqz	a0,80002bf4 <kerneltrap+0x38>
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	d3e080e7          	jalr	-706(ra) # 800019ac <myproc>
    80002c76:	4d18                	lw	a4,24(a0)
    80002c78:	4791                	li	a5,4
    80002c7a:	f6f71de3          	bne	a4,a5,80002bf4 <kerneltrap+0x38>
    yield();
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	5cc080e7          	jalr	1484(ra) # 8000224a <yield>
    80002c86:	b7bd                	j	80002bf4 <kerneltrap+0x38>

0000000080002c88 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	1000                	addi	s0,sp,32
    80002c92:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	d18080e7          	jalr	-744(ra) # 800019ac <myproc>
  switch (n) {
    80002c9c:	4795                	li	a5,5
    80002c9e:	0497e163          	bltu	a5,s1,80002ce0 <argraw+0x58>
    80002ca2:	048a                	slli	s1,s1,0x2
    80002ca4:	00005717          	auipc	a4,0x5
    80002ca8:	79470713          	addi	a4,a4,1940 # 80008438 <states.0+0x170>
    80002cac:	94ba                	add	s1,s1,a4
    80002cae:	409c                	lw	a5,0(s1)
    80002cb0:	97ba                	add	a5,a5,a4
    80002cb2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cb4:	6d3c                	ld	a5,88(a0)
    80002cb6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6105                	addi	sp,sp,32
    80002cc0:	8082                	ret
    return p->trapframe->a1;
    80002cc2:	6d3c                	ld	a5,88(a0)
    80002cc4:	7fa8                	ld	a0,120(a5)
    80002cc6:	bfcd                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a2;
    80002cc8:	6d3c                	ld	a5,88(a0)
    80002cca:	63c8                	ld	a0,128(a5)
    80002ccc:	b7f5                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a3;
    80002cce:	6d3c                	ld	a5,88(a0)
    80002cd0:	67c8                	ld	a0,136(a5)
    80002cd2:	b7dd                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a4;
    80002cd4:	6d3c                	ld	a5,88(a0)
    80002cd6:	6bc8                	ld	a0,144(a5)
    80002cd8:	b7c5                	j	80002cb8 <argraw+0x30>
    return p->trapframe->a5;
    80002cda:	6d3c                	ld	a5,88(a0)
    80002cdc:	6fc8                	ld	a0,152(a5)
    80002cde:	bfe9                	j	80002cb8 <argraw+0x30>
  panic("argraw");
    80002ce0:	00005517          	auipc	a0,0x5
    80002ce4:	73050513          	addi	a0,a0,1840 # 80008410 <states.0+0x148>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	858080e7          	jalr	-1960(ra) # 80000540 <panic>

0000000080002cf0 <fetchaddr>:
{
    80002cf0:	1101                	addi	sp,sp,-32
    80002cf2:	ec06                	sd	ra,24(sp)
    80002cf4:	e822                	sd	s0,16(sp)
    80002cf6:	e426                	sd	s1,8(sp)
    80002cf8:	e04a                	sd	s2,0(sp)
    80002cfa:	1000                	addi	s0,sp,32
    80002cfc:	84aa                	mv	s1,a0
    80002cfe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	cac080e7          	jalr	-852(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d08:	653c                	ld	a5,72(a0)
    80002d0a:	02f4f863          	bgeu	s1,a5,80002d3a <fetchaddr+0x4a>
    80002d0e:	00848713          	addi	a4,s1,8
    80002d12:	02e7e663          	bltu	a5,a4,80002d3e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d16:	46a1                	li	a3,8
    80002d18:	8626                	mv	a2,s1
    80002d1a:	85ca                	mv	a1,s2
    80002d1c:	6928                	ld	a0,80(a0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	9da080e7          	jalr	-1574(ra) # 800016f8 <copyin>
    80002d26:	00a03533          	snez	a0,a0
    80002d2a:	40a00533          	neg	a0,a0
}
    80002d2e:	60e2                	ld	ra,24(sp)
    80002d30:	6442                	ld	s0,16(sp)
    80002d32:	64a2                	ld	s1,8(sp)
    80002d34:	6902                	ld	s2,0(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret
    return -1;
    80002d3a:	557d                	li	a0,-1
    80002d3c:	bfcd                	j	80002d2e <fetchaddr+0x3e>
    80002d3e:	557d                	li	a0,-1
    80002d40:	b7fd                	j	80002d2e <fetchaddr+0x3e>

0000000080002d42 <fetchstr>:
{
    80002d42:	7179                	addi	sp,sp,-48
    80002d44:	f406                	sd	ra,40(sp)
    80002d46:	f022                	sd	s0,32(sp)
    80002d48:	ec26                	sd	s1,24(sp)
    80002d4a:	e84a                	sd	s2,16(sp)
    80002d4c:	e44e                	sd	s3,8(sp)
    80002d4e:	1800                	addi	s0,sp,48
    80002d50:	892a                	mv	s2,a0
    80002d52:	84ae                	mv	s1,a1
    80002d54:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	c56080e7          	jalr	-938(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d5e:	86ce                	mv	a3,s3
    80002d60:	864a                	mv	a2,s2
    80002d62:	85a6                	mv	a1,s1
    80002d64:	6928                	ld	a0,80(a0)
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	a20080e7          	jalr	-1504(ra) # 80001786 <copyinstr>
    80002d6e:	00054e63          	bltz	a0,80002d8a <fetchstr+0x48>
  return strlen(buf);
    80002d72:	8526                	mv	a0,s1
    80002d74:	ffffe097          	auipc	ra,0xffffe
    80002d78:	0da080e7          	jalr	218(ra) # 80000e4e <strlen>
}
    80002d7c:	70a2                	ld	ra,40(sp)
    80002d7e:	7402                	ld	s0,32(sp)
    80002d80:	64e2                	ld	s1,24(sp)
    80002d82:	6942                	ld	s2,16(sp)
    80002d84:	69a2                	ld	s3,8(sp)
    80002d86:	6145                	addi	sp,sp,48
    80002d88:	8082                	ret
    return -1;
    80002d8a:	557d                	li	a0,-1
    80002d8c:	bfc5                	j	80002d7c <fetchstr+0x3a>

0000000080002d8e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d8e:	1101                	addi	sp,sp,-32
    80002d90:	ec06                	sd	ra,24(sp)
    80002d92:	e822                	sd	s0,16(sp)
    80002d94:	e426                	sd	s1,8(sp)
    80002d96:	1000                	addi	s0,sp,32
    80002d98:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d9a:	00000097          	auipc	ra,0x0
    80002d9e:	eee080e7          	jalr	-274(ra) # 80002c88 <argraw>
    80002da2:	c088                	sw	a0,0(s1)
}
    80002da4:	60e2                	ld	ra,24(sp)
    80002da6:	6442                	ld	s0,16(sp)
    80002da8:	64a2                	ld	s1,8(sp)
    80002daa:	6105                	addi	sp,sp,32
    80002dac:	8082                	ret

0000000080002dae <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	e426                	sd	s1,8(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	ece080e7          	jalr	-306(ra) # 80002c88 <argraw>
    80002dc2:	e088                	sd	a0,0(s1)
}
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	64a2                	ld	s1,8(sp)
    80002dca:	6105                	addi	sp,sp,32
    80002dcc:	8082                	ret

0000000080002dce <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dce:	7179                	addi	sp,sp,-48
    80002dd0:	f406                	sd	ra,40(sp)
    80002dd2:	f022                	sd	s0,32(sp)
    80002dd4:	ec26                	sd	s1,24(sp)
    80002dd6:	e84a                	sd	s2,16(sp)
    80002dd8:	1800                	addi	s0,sp,48
    80002dda:	84ae                	mv	s1,a1
    80002ddc:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002dde:	fd840593          	addi	a1,s0,-40
    80002de2:	00000097          	auipc	ra,0x0
    80002de6:	fcc080e7          	jalr	-52(ra) # 80002dae <argaddr>
  return fetchstr(addr, buf, max);
    80002dea:	864a                	mv	a2,s2
    80002dec:	85a6                	mv	a1,s1
    80002dee:	fd843503          	ld	a0,-40(s0)
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	f50080e7          	jalr	-176(ra) # 80002d42 <fetchstr>
}
    80002dfa:	70a2                	ld	ra,40(sp)
    80002dfc:	7402                	ld	s0,32(sp)
    80002dfe:	64e2                	ld	s1,24(sp)
    80002e00:	6942                	ld	s2,16(sp)
    80002e02:	6145                	addi	sp,sp,48
    80002e04:	8082                	ret

0000000080002e06 <syscall>:
#endif
};

void
syscall(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	e04a                	sd	s2,0(sp)
    80002e10:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	b9a080e7          	jalr	-1126(ra) # 800019ac <myproc>
    80002e1a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e1c:	05853903          	ld	s2,88(a0)
    80002e20:	0a893783          	ld	a5,168(s2)
    80002e24:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e28:	37fd                	addiw	a5,a5,-1
    80002e2a:	4769                	li	a4,26
    80002e2c:	00f76f63          	bltu	a4,a5,80002e4a <syscall+0x44>
    80002e30:	00369713          	slli	a4,a3,0x3
    80002e34:	00005797          	auipc	a5,0x5
    80002e38:	61c78793          	addi	a5,a5,1564 # 80008450 <syscalls>
    80002e3c:	97ba                	add	a5,a5,a4
    80002e3e:	639c                	ld	a5,0(a5)
    80002e40:	c789                	beqz	a5,80002e4a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e42:	9782                	jalr	a5
    80002e44:	06a93823          	sd	a0,112(s2)
    80002e48:	a839                	j	80002e66 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e4a:	15848613          	addi	a2,s1,344
    80002e4e:	588c                	lw	a1,48(s1)
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	5c850513          	addi	a0,a0,1480 # 80008418 <states.0+0x150>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	732080e7          	jalr	1842(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e60:	6cbc                	ld	a5,88(s1)
    80002e62:	577d                	li	a4,-1
    80002e64:	fbb8                	sd	a4,112(a5)
  }
}
    80002e66:	60e2                	ld	ra,24(sp)
    80002e68:	6442                	ld	s0,16(sp)
    80002e6a:	64a2                	ld	s1,8(sp)
    80002e6c:	6902                	ld	s2,0(sp)
    80002e6e:	6105                	addi	sp,sp,32
    80002e70:	8082                	ret

0000000080002e72 <sys_exit>:
#include "proc.h"
#include "syscall.h"

uint64
sys_exit(void)
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e7a:	fec40593          	addi	a1,s0,-20
    80002e7e:	4501                	li	a0,0
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	f0e080e7          	jalr	-242(ra) # 80002d8e <argint>
  exit(n);
    80002e88:	fec42503          	lw	a0,-20(s0)
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	5ae080e7          	jalr	1454(ra) # 8000243a <exit>
  return 0;  // not reached
}
    80002e94:	4501                	li	a0,0
    80002e96:	60e2                	ld	ra,24(sp)
    80002e98:	6442                	ld	s0,16(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret

0000000080002e9e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e9e:	1101                	addi	sp,sp,-32
    80002ea0:	ec06                	sd	ra,24(sp)
    80002ea2:	e822                	sd	s0,16(sp)
    80002ea4:	e426                	sd	s1,8(sp)
    80002ea6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	b04080e7          	jalr	-1276(ra) # 800019ac <myproc>
  int ret = p->pid;
    80002eb0:	5904                	lw	s1,48(a0)
  if (p->strace_m & (1 << SYS_getpid))
    80002eb2:	17853783          	ld	a5,376(a0)
    80002eb6:	83ad                	srli	a5,a5,0xb
    80002eb8:	8b85                	andi	a5,a5,1
    80002eba:	e799                	bnez	a5,80002ec8 <sys_getpid+0x2a>
    printf("%d: syscall getpid () -> %d\n", ret, ret);
  return ret;
}
    80002ebc:	8526                	mv	a0,s1
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret
    printf("%d: syscall getpid () -> %d\n", ret, ret);
    80002ec8:	8626                	mv	a2,s1
    80002eca:	85a6                	mv	a1,s1
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	66450513          	addi	a0,a0,1636 # 80008530 <syscalls+0xe0>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	6b6080e7          	jalr	1718(ra) # 8000058a <printf>
    80002edc:	b7c5                	j	80002ebc <sys_getpid+0x1e>

0000000080002ede <sys_fork>:

uint64
sys_fork(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	e426                	sd	s1,8(sp)
    80002ee6:	1000                	addi	s0,sp,32
  int ret = fork();
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	eb8080e7          	jalr	-328(ra) # 80001da0 <fork>
    80002ef0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	aba080e7          	jalr	-1350(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_fork))
    80002efa:	17853783          	ld	a5,376(a0)
    80002efe:	8b89                	andi	a5,a5,2
    80002f00:	e799                	bnez	a5,80002f0e <sys_fork+0x30>
    printf("%d: syscall fork () -> %d\n", p->pid, ret);
  return ret;
}
    80002f02:	8526                	mv	a0,s1
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	64a2                	ld	s1,8(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret
    printf("%d: syscall fork () -> %d\n", p->pid, ret);
    80002f0e:	8626                	mv	a2,s1
    80002f10:	590c                	lw	a1,48(a0)
    80002f12:	00005517          	auipc	a0,0x5
    80002f16:	63e50513          	addi	a0,a0,1598 # 80008550 <syscalls+0x100>
    80002f1a:	ffffd097          	auipc	ra,0xffffd
    80002f1e:	670080e7          	jalr	1648(ra) # 8000058a <printf>
    80002f22:	b7c5                	j	80002f02 <sys_fork+0x24>

0000000080002f24 <sys_wait>:

uint64
sys_wait(void)
{
    80002f24:	7179                	addi	sp,sp,-48
    80002f26:	f406                	sd	ra,40(sp)
    80002f28:	f022                	sd	s0,32(sp)
    80002f2a:	ec26                	sd	s1,24(sp)
    80002f2c:	1800                	addi	s0,sp,48
  uint64 p;
  argaddr(0, &p);
    80002f2e:	fd840593          	addi	a1,s0,-40
    80002f32:	4501                	li	a0,0
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	e7a080e7          	jalr	-390(ra) # 80002dae <argaddr>
  int ret = wait(p);
    80002f3c:	fd843503          	ld	a0,-40(s0)
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	6ac080e7          	jalr	1708(ra) # 800025ec <wait>
    80002f48:	84aa                	mv	s1,a0
  struct proc *myp = myproc();
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	a62080e7          	jalr	-1438(ra) # 800019ac <myproc>
  if (myp->strace_m & (1 << SYS_wait))
    80002f52:	17853783          	ld	a5,376(a0)
    80002f56:	8ba1                	andi	a5,a5,8
    80002f58:	e799                	bnez	a5,80002f66 <sys_wait+0x42>
    printf("%d: syscall wait (%d) -> %d\n", myp->pid, p, ret);
  return ret;
}
    80002f5a:	8526                	mv	a0,s1
    80002f5c:	70a2                	ld	ra,40(sp)
    80002f5e:	7402                	ld	s0,32(sp)
    80002f60:	64e2                	ld	s1,24(sp)
    80002f62:	6145                	addi	sp,sp,48
    80002f64:	8082                	ret
    printf("%d: syscall wait (%d) -> %d\n", myp->pid, p, ret);
    80002f66:	86a6                	mv	a3,s1
    80002f68:	fd843603          	ld	a2,-40(s0)
    80002f6c:	590c                	lw	a1,48(a0)
    80002f6e:	00005517          	auipc	a0,0x5
    80002f72:	60250513          	addi	a0,a0,1538 # 80008570 <syscalls+0x120>
    80002f76:	ffffd097          	auipc	ra,0xffffd
    80002f7a:	614080e7          	jalr	1556(ra) # 8000058a <printf>
    80002f7e:	bff1                	j	80002f5a <sys_wait+0x36>

0000000080002f80 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80002f80:	7179                	addi	sp,sp,-48
    80002f82:	f406                	sd	ra,40(sp)
    80002f84:	f022                	sd	s0,32(sp)
    80002f86:	ec26                	sd	s1,24(sp)
    80002f88:	1800                	addi	s0,sp,48
  int n;
  argint(0, &n);
    80002f8a:	fdc40593          	addi	a1,s0,-36
    80002f8e:	4501                	li	a0,0
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	dfe080e7          	jalr	-514(ra) # 80002d8e <argint>
  uint64 periodic_fn_ptr;
  argaddr(1, &periodic_fn_ptr);
    80002f98:	fd040593          	addi	a1,s0,-48
    80002f9c:	4505                	li	a0,1
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	e10080e7          	jalr	-496(ra) # 80002dae <argaddr>

  struct proc *p = myproc();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	a06080e7          	jalr	-1530(ra) # 800019ac <myproc>
    80002fae:	84aa                	mv	s1,a0
  *p->saved_tf = *p->trapframe;
    80002fb0:	6d34                	ld	a3,88(a0)
    80002fb2:	87b6                	mv	a5,a3
    80002fb4:	18053703          	ld	a4,384(a0)
    80002fb8:	12068693          	addi	a3,a3,288
    80002fbc:	0007b803          	ld	a6,0(a5)
    80002fc0:	6788                	ld	a0,8(a5)
    80002fc2:	6b8c                	ld	a1,16(a5)
    80002fc4:	6f90                	ld	a2,24(a5)
    80002fc6:	01073023          	sd	a6,0(a4)
    80002fca:	e708                	sd	a0,8(a4)
    80002fcc:	eb0c                	sd	a1,16(a4)
    80002fce:	ef10                	sd	a2,24(a4)
    80002fd0:	02078793          	addi	a5,a5,32
    80002fd4:	02070713          	addi	a4,a4,32
    80002fd8:	fed792e3          	bne	a5,a3,80002fbc <sys_sigalarm+0x3c>

  acquire(&p->lock);
    80002fdc:	8526                	mv	a0,s1
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	bf8080e7          	jalr	-1032(ra) # 80000bd6 <acquire>
  if (p->rtime % n == 0)
    80002fe6:	1684a783          	lw	a5,360(s1)
    80002fea:	fdc42703          	lw	a4,-36(s0)
    80002fee:	02e7f7bb          	remuw	a5,a5,a4
    80002ff2:	e789                	bnez	a5,80002ffc <sys_sigalarm+0x7c>
    p->trapframe->epc = periodic_fn_ptr;
    80002ff4:	6cbc                	ld	a5,88(s1)
    80002ff6:	fd043703          	ld	a4,-48(s0)
    80002ffa:	ef98                	sd	a4,24(a5)
  release(&p->lock);
    80002ffc:	8526                	mv	a0,s1
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	c8c080e7          	jalr	-884(ra) # 80000c8a <release>

  return 0;
}
    80003006:	4501                	li	a0,0
    80003008:	70a2                	ld	ra,40(sp)
    8000300a:	7402                	ld	s0,32(sp)
    8000300c:	64e2                	ld	s1,24(sp)
    8000300e:	6145                	addi	sp,sp,48
    80003010:	8082                	ret

0000000080003012 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80003012:	1141                	addi	sp,sp,-16
    80003014:	e406                	sd	ra,8(sp)
    80003016:	e022                	sd	s0,0(sp)
    80003018:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	992080e7          	jalr	-1646(ra) # 800019ac <myproc>

  *p->trapframe = *p->saved_tf;
    80003022:	18053683          	ld	a3,384(a0)
    80003026:	87b6                	mv	a5,a3
    80003028:	6d38                	ld	a4,88(a0)
    8000302a:	12068693          	addi	a3,a3,288
    8000302e:	0007b883          	ld	a7,0(a5)
    80003032:	0087b803          	ld	a6,8(a5)
    80003036:	6b8c                	ld	a1,16(a5)
    80003038:	6f90                	ld	a2,24(a5)
    8000303a:	01173023          	sd	a7,0(a4)
    8000303e:	01073423          	sd	a6,8(a4)
    80003042:	eb0c                	sd	a1,16(a4)
    80003044:	ef10                	sd	a2,24(a4)
    80003046:	02078793          	addi	a5,a5,32
    8000304a:	02070713          	addi	a4,a4,32
    8000304e:	fed790e3          	bne	a5,a3,8000302e <sys_sigreturn+0x1c>
  p->trapframe->epc += 4;
    80003052:	6d38                	ld	a4,88(a0)
    80003054:	6f1c                	ld	a5,24(a4)
    80003056:	0791                	addi	a5,a5,4
    80003058:	ef1c                	sd	a5,24(a4)

  return 0;
}
    8000305a:	4501                	li	a0,0
    8000305c:	60a2                	ld	ra,8(sp)
    8000305e:	6402                	ld	s0,0(sp)
    80003060:	0141                	addi	sp,sp,16
    80003062:	8082                	ret

0000000080003064 <sys_trace>:

uint64
sys_trace(void)
{
    80003064:	1101                	addi	sp,sp,-32
    80003066:	ec06                	sd	ra,24(sp)
    80003068:	e822                	sd	s0,16(sp)
    8000306a:	1000                	addi	s0,sp,32
  uint64 addr;
  argaddr(0, &addr);
    8000306c:	fe840593          	addi	a1,s0,-24
    80003070:	4501                	li	a0,0
    80003072:	00000097          	auipc	ra,0x0
    80003076:	d3c080e7          	jalr	-708(ra) # 80002dae <argaddr>
  int ret = trace(addr);
    8000307a:	fe843503          	ld	a0,-24(s0)
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	f32080e7          	jalr	-206(ra) # 80001fb0 <trace>
  return ret;
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret

000000008000308e <sys_set_priority>:

uint64 
sys_set_priority(void){
    8000308e:	1101                	addi	sp,sp,-32
    80003090:	ec06                	sd	ra,24(sp)
    80003092:	e822                	sd	s0,16(sp)
    80003094:	1000                	addi	s0,sp,32
  #ifndef PBS
  return -1;
  #endif
  int priority, pid, old;
  old = -1;
    80003096:	57fd                	li	a5,-1
    80003098:	fef42223          	sw	a5,-28(s0)
  argint(0, &priority);
    8000309c:	fec40593          	addi	a1,s0,-20
    800030a0:	4501                	li	a0,0
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	cec080e7          	jalr	-788(ra) # 80002d8e <argint>
  argint(1, &pid);
    800030aa:	fe840593          	addi	a1,s0,-24
    800030ae:	4505                	li	a0,1
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	cde080e7          	jalr	-802(ra) # 80002d8e <argint>
  set_priority(priority, pid, &old);
    800030b8:	fe440613          	addi	a2,s0,-28
    800030bc:	fe842583          	lw	a1,-24(s0)
    800030c0:	fec42503          	lw	a0,-20(s0)
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	1c2080e7          	jalr	450(ra) # 80002286 <set_priority>
  return old;
}
    800030cc:	fe442503          	lw	a0,-28(s0)
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	6105                	addi	sp,sp,32
    800030d6:	8082                	ret

00000000800030d8 <sys_sbrk>:
 
uint64
sys_sbrk(void)
{
    800030d8:	7179                	addi	sp,sp,-48
    800030da:	f406                	sd	ra,40(sp)
    800030dc:	f022                	sd	s0,32(sp)
    800030de:	ec26                	sd	s1,24(sp)
    800030e0:	e84a                	sd	s2,16(sp)
    800030e2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;
  struct proc *p = myproc();
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	8c8080e7          	jalr	-1848(ra) # 800019ac <myproc>
    800030ec:	84aa                	mv	s1,a0

  argint(0, &n);
    800030ee:	fdc40593          	addi	a1,s0,-36
    800030f2:	4501                	li	a0,0
    800030f4:	00000097          	auipc	ra,0x0
    800030f8:	c9a080e7          	jalr	-870(ra) # 80002d8e <argint>
  addr = p->sz;
    800030fc:	0484b903          	ld	s2,72(s1)
  if(growproc(n) < 0)
    80003100:	fdc42503          	lw	a0,-36(s0)
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	c40080e7          	jalr	-960(ra) # 80001d44 <growproc>
    8000310c:	02054b63          	bltz	a0,80003142 <sys_sbrk+0x6a>
    return -1;

  if (p->strace_m & (1 << SYS_sbrk))
    80003110:	1784b703          	ld	a4,376(s1)
    80003114:	6785                	lui	a5,0x1
    80003116:	8ff9                	and	a5,a5,a4
    80003118:	eb81                	bnez	a5,80003128 <sys_sbrk+0x50>
    printf("%d: syscall sbrk (%d) -> %d\n", p->pid, n, addr);
  return addr;
}
    8000311a:	854a                	mv	a0,s2
    8000311c:	70a2                	ld	ra,40(sp)
    8000311e:	7402                	ld	s0,32(sp)
    80003120:	64e2                	ld	s1,24(sp)
    80003122:	6942                	ld	s2,16(sp)
    80003124:	6145                	addi	sp,sp,48
    80003126:	8082                	ret
    printf("%d: syscall sbrk (%d) -> %d\n", p->pid, n, addr);
    80003128:	86ca                	mv	a3,s2
    8000312a:	fdc42603          	lw	a2,-36(s0)
    8000312e:	588c                	lw	a1,48(s1)
    80003130:	00005517          	auipc	a0,0x5
    80003134:	46050513          	addi	a0,a0,1120 # 80008590 <syscalls+0x140>
    80003138:	ffffd097          	auipc	ra,0xffffd
    8000313c:	452080e7          	jalr	1106(ra) # 8000058a <printf>
    80003140:	bfe9                	j	8000311a <sys_sbrk+0x42>
    return -1;
    80003142:	597d                	li	s2,-1
    80003144:	bfd9                	j	8000311a <sys_sbrk+0x42>

0000000080003146 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003146:	7139                	addi	sp,sp,-64
    80003148:	fc06                	sd	ra,56(sp)
    8000314a:	f822                	sd	s0,48(sp)
    8000314c:	f426                	sd	s1,40(sp)
    8000314e:	f04a                	sd	s2,32(sp)
    80003150:	ec4e                	sd	s3,24(sp)
    80003152:	e852                	sd	s4,16(sp)
    80003154:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;
  struct proc *p = myproc();
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	856080e7          	jalr	-1962(ra) # 800019ac <myproc>
    8000315e:	892a                	mv	s2,a0

  argint(0, &n);
    80003160:	fcc40593          	addi	a1,s0,-52
    80003164:	4501                	li	a0,0
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	c28080e7          	jalr	-984(ra) # 80002d8e <argint>
  acquire(&tickslock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	6e250513          	addi	a0,a0,1762 # 80017850 <tickslock>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	a60080e7          	jalr	-1440(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000317e:	00006997          	auipc	s3,0x6
    80003182:	a3a9a983          	lw	s3,-1478(s3) # 80008bb8 <ticks>
  while(ticks - ticks0 < n){
    80003186:	fcc42783          	lw	a5,-52(s0)
    8000318a:	cf85                	beqz	a5,800031c2 <sys_sleep+0x7c>
    if(killed(p)){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000318c:	00014a17          	auipc	s4,0x14
    80003190:	6c4a0a13          	addi	s4,s4,1732 # 80017850 <tickslock>
    80003194:	00006497          	auipc	s1,0x6
    80003198:	a2448493          	addi	s1,s1,-1500 # 80008bb8 <ticks>
    if(killed(p)){
    8000319c:	854a                	mv	a0,s2
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	41c080e7          	jalr	1052(ra) # 800025ba <killed>
    800031a6:	e939                	bnez	a0,800031fc <sys_sleep+0xb6>
    sleep(&ticks, &tickslock);
    800031a8:	85d2                	mv	a1,s4
    800031aa:	8526                	mv	a0,s1
    800031ac:	fffff097          	auipc	ra,0xfffff
    800031b0:	15a080e7          	jalr	346(ra) # 80002306 <sleep>
  while(ticks - ticks0 < n){
    800031b4:	409c                	lw	a5,0(s1)
    800031b6:	413787bb          	subw	a5,a5,s3
    800031ba:	fcc42703          	lw	a4,-52(s0)
    800031be:	fce7efe3          	bltu	a5,a4,8000319c <sys_sleep+0x56>
  }
  release(&tickslock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	68e50513          	addi	a0,a0,1678 # 80017850 <tickslock>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	ac0080e7          	jalr	-1344(ra) # 80000c8a <release>
  if (p->strace_m & (1 << SYS_sleep))
    800031d2:	17893783          	ld	a5,376(s2)
    800031d6:	6509                	lui	a0,0x2
    800031d8:	8d7d                	and	a0,a0,a5
    800031da:	c915                	beqz	a0,8000320e <sys_sleep+0xc8>
    printf("%d: syscall sleep (%u) -> 0\n", p->pid, ticks);
    800031dc:	00006617          	auipc	a2,0x6
    800031e0:	9dc62603          	lw	a2,-1572(a2) # 80008bb8 <ticks>
    800031e4:	03092583          	lw	a1,48(s2)
    800031e8:	00005517          	auipc	a0,0x5
    800031ec:	3c850513          	addi	a0,a0,968 # 800085b0 <syscalls+0x160>
    800031f0:	ffffd097          	auipc	ra,0xffffd
    800031f4:	39a080e7          	jalr	922(ra) # 8000058a <printf>
  return 0;
    800031f8:	4501                	li	a0,0
    800031fa:	a811                	j	8000320e <sys_sleep+0xc8>
      release(&tickslock);
    800031fc:	00014517          	auipc	a0,0x14
    80003200:	65450513          	addi	a0,a0,1620 # 80017850 <tickslock>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	a86080e7          	jalr	-1402(ra) # 80000c8a <release>
      return -1;
    8000320c:	557d                	li	a0,-1
}
    8000320e:	70e2                	ld	ra,56(sp)
    80003210:	7442                	ld	s0,48(sp)
    80003212:	74a2                	ld	s1,40(sp)
    80003214:	7902                	ld	s2,32(sp)
    80003216:	69e2                	ld	s3,24(sp)
    80003218:	6a42                	ld	s4,16(sp)
    8000321a:	6121                	addi	sp,sp,64
    8000321c:	8082                	ret

000000008000321e <sys_kill>:

uint64
sys_kill(void)
{
    8000321e:	7179                	addi	sp,sp,-48
    80003220:	f406                	sd	ra,40(sp)
    80003222:	f022                	sd	s0,32(sp)
    80003224:	ec26                	sd	s1,24(sp)
    80003226:	1800                	addi	s0,sp,48
  int pid;

  argint(0, &pid);
    80003228:	fdc40593          	addi	a1,s0,-36
    8000322c:	4501                	li	a0,0
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	b60080e7          	jalr	-1184(ra) # 80002d8e <argint>
  int ret = kill(pid);
    80003236:	fdc42503          	lw	a0,-36(s0)
    8000323a:	fffff097          	auipc	ra,0xfffff
    8000323e:	2e2080e7          	jalr	738(ra) # 8000251c <kill>
    80003242:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	768080e7          	jalr	1896(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_kill))
    8000324c:	17853783          	ld	a5,376(a0)
    80003250:	0407f793          	andi	a5,a5,64
    80003254:	e799                	bnez	a5,80003262 <sys_kill+0x44>
    printf("%d: syscall kill (%d) -> %d\n", p->pid, pid, ret);
  return ret;
}
    80003256:	8526                	mv	a0,s1
    80003258:	70a2                	ld	ra,40(sp)
    8000325a:	7402                	ld	s0,32(sp)
    8000325c:	64e2                	ld	s1,24(sp)
    8000325e:	6145                	addi	sp,sp,48
    80003260:	8082                	ret
    printf("%d: syscall kill (%d) -> %d\n", p->pid, pid, ret);
    80003262:	86a6                	mv	a3,s1
    80003264:	fdc42603          	lw	a2,-36(s0)
    80003268:	590c                	lw	a1,48(a0)
    8000326a:	00005517          	auipc	a0,0x5
    8000326e:	36650513          	addi	a0,a0,870 # 800085d0 <syscalls+0x180>
    80003272:	ffffd097          	auipc	ra,0xffffd
    80003276:	318080e7          	jalr	792(ra) # 8000058a <printf>
    8000327a:	bff1                	j	80003256 <sys_kill+0x38>

000000008000327c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000327c:	1101                	addi	sp,sp,-32
    8000327e:	ec06                	sd	ra,24(sp)
    80003280:	e822                	sd	s0,16(sp)
    80003282:	e426                	sd	s1,8(sp)
    80003284:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003286:	00014517          	auipc	a0,0x14
    8000328a:	5ca50513          	addi	a0,a0,1482 # 80017850 <tickslock>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	948080e7          	jalr	-1720(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003296:	00006497          	auipc	s1,0x6
    8000329a:	9224a483          	lw	s1,-1758(s1) # 80008bb8 <ticks>
  release(&tickslock);
    8000329e:	00014517          	auipc	a0,0x14
    800032a2:	5b250513          	addi	a0,a0,1458 # 80017850 <tickslock>
    800032a6:	ffffe097          	auipc	ra,0xffffe
    800032aa:	9e4080e7          	jalr	-1564(ra) # 80000c8a <release>
  struct proc *p = myproc();
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	6fe080e7          	jalr	1790(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_uptime))
    800032b6:	17853703          	ld	a4,376(a0)
    800032ba:	6791                	lui	a5,0x4
    800032bc:	8ff9                	and	a5,a5,a4
    800032be:	eb89                	bnez	a5,800032d0 <sys_uptime+0x54>
    printf("%d: syscall uptime () -> %u\n", p->pid, xticks);
  return xticks;
}
    800032c0:	02049513          	slli	a0,s1,0x20
    800032c4:	9101                	srli	a0,a0,0x20
    800032c6:	60e2                	ld	ra,24(sp)
    800032c8:	6442                	ld	s0,16(sp)
    800032ca:	64a2                	ld	s1,8(sp)
    800032cc:	6105                	addi	sp,sp,32
    800032ce:	8082                	ret
    printf("%d: syscall uptime () -> %u\n", p->pid, xticks);
    800032d0:	8626                	mv	a2,s1
    800032d2:	590c                	lw	a1,48(a0)
    800032d4:	00005517          	auipc	a0,0x5
    800032d8:	31c50513          	addi	a0,a0,796 # 800085f0 <syscalls+0x1a0>
    800032dc:	ffffd097          	auipc	ra,0xffffd
    800032e0:	2ae080e7          	jalr	686(ra) # 8000058a <printf>
    800032e4:	bff1                	j	800032c0 <sys_uptime+0x44>

00000000800032e6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032e6:	7179                	addi	sp,sp,-48
    800032e8:	f406                	sd	ra,40(sp)
    800032ea:	f022                	sd	s0,32(sp)
    800032ec:	ec26                	sd	s1,24(sp)
    800032ee:	e84a                	sd	s2,16(sp)
    800032f0:	e44e                	sd	s3,8(sp)
    800032f2:	e052                	sd	s4,0(sp)
    800032f4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032f6:	00005597          	auipc	a1,0x5
    800032fa:	31a58593          	addi	a1,a1,794 # 80008610 <syscalls+0x1c0>
    800032fe:	00014517          	auipc	a0,0x14
    80003302:	56a50513          	addi	a0,a0,1386 # 80017868 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	840080e7          	jalr	-1984(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000330e:	0001c797          	auipc	a5,0x1c
    80003312:	55a78793          	addi	a5,a5,1370 # 8001f868 <bcache+0x8000>
    80003316:	0001c717          	auipc	a4,0x1c
    8000331a:	7ba70713          	addi	a4,a4,1978 # 8001fad0 <bcache+0x8268>
    8000331e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003322:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003326:	00014497          	auipc	s1,0x14
    8000332a:	55a48493          	addi	s1,s1,1370 # 80017880 <bcache+0x18>
    b->next = bcache.head.next;
    8000332e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003330:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003332:	00005a17          	auipc	s4,0x5
    80003336:	2e6a0a13          	addi	s4,s4,742 # 80008618 <syscalls+0x1c8>
    b->next = bcache.head.next;
    8000333a:	2b893783          	ld	a5,696(s2)
    8000333e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003340:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003344:	85d2                	mv	a1,s4
    80003346:	01048513          	addi	a0,s1,16
    8000334a:	00001097          	auipc	ra,0x1
    8000334e:	4c8080e7          	jalr	1224(ra) # 80004812 <initsleeplock>
    bcache.head.next->prev = b;
    80003352:	2b893783          	ld	a5,696(s2)
    80003356:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003358:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000335c:	45848493          	addi	s1,s1,1112
    80003360:	fd349de3          	bne	s1,s3,8000333a <binit+0x54>
  }
}
    80003364:	70a2                	ld	ra,40(sp)
    80003366:	7402                	ld	s0,32(sp)
    80003368:	64e2                	ld	s1,24(sp)
    8000336a:	6942                	ld	s2,16(sp)
    8000336c:	69a2                	ld	s3,8(sp)
    8000336e:	6a02                	ld	s4,0(sp)
    80003370:	6145                	addi	sp,sp,48
    80003372:	8082                	ret

0000000080003374 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003374:	7179                	addi	sp,sp,-48
    80003376:	f406                	sd	ra,40(sp)
    80003378:	f022                	sd	s0,32(sp)
    8000337a:	ec26                	sd	s1,24(sp)
    8000337c:	e84a                	sd	s2,16(sp)
    8000337e:	e44e                	sd	s3,8(sp)
    80003380:	1800                	addi	s0,sp,48
    80003382:	892a                	mv	s2,a0
    80003384:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003386:	00014517          	auipc	a0,0x14
    8000338a:	4e250513          	addi	a0,a0,1250 # 80017868 <bcache>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	848080e7          	jalr	-1976(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003396:	0001c497          	auipc	s1,0x1c
    8000339a:	78a4b483          	ld	s1,1930(s1) # 8001fb20 <bcache+0x82b8>
    8000339e:	0001c797          	auipc	a5,0x1c
    800033a2:	73278793          	addi	a5,a5,1842 # 8001fad0 <bcache+0x8268>
    800033a6:	02f48f63          	beq	s1,a5,800033e4 <bread+0x70>
    800033aa:	873e                	mv	a4,a5
    800033ac:	a021                	j	800033b4 <bread+0x40>
    800033ae:	68a4                	ld	s1,80(s1)
    800033b0:	02e48a63          	beq	s1,a4,800033e4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033b4:	449c                	lw	a5,8(s1)
    800033b6:	ff279ce3          	bne	a5,s2,800033ae <bread+0x3a>
    800033ba:	44dc                	lw	a5,12(s1)
    800033bc:	ff3799e3          	bne	a5,s3,800033ae <bread+0x3a>
      b->refcnt++;
    800033c0:	40bc                	lw	a5,64(s1)
    800033c2:	2785                	addiw	a5,a5,1
    800033c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033c6:	00014517          	auipc	a0,0x14
    800033ca:	4a250513          	addi	a0,a0,1186 # 80017868 <bcache>
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	8bc080e7          	jalr	-1860(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800033d6:	01048513          	addi	a0,s1,16
    800033da:	00001097          	auipc	ra,0x1
    800033de:	472080e7          	jalr	1138(ra) # 8000484c <acquiresleep>
      return b;
    800033e2:	a8b9                	j	80003440 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033e4:	0001c497          	auipc	s1,0x1c
    800033e8:	7344b483          	ld	s1,1844(s1) # 8001fb18 <bcache+0x82b0>
    800033ec:	0001c797          	auipc	a5,0x1c
    800033f0:	6e478793          	addi	a5,a5,1764 # 8001fad0 <bcache+0x8268>
    800033f4:	00f48863          	beq	s1,a5,80003404 <bread+0x90>
    800033f8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033fa:	40bc                	lw	a5,64(s1)
    800033fc:	cf81                	beqz	a5,80003414 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033fe:	64a4                	ld	s1,72(s1)
    80003400:	fee49de3          	bne	s1,a4,800033fa <bread+0x86>
  panic("bget: no buffers");
    80003404:	00005517          	auipc	a0,0x5
    80003408:	21c50513          	addi	a0,a0,540 # 80008620 <syscalls+0x1d0>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	134080e7          	jalr	308(ra) # 80000540 <panic>
      b->dev = dev;
    80003414:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003418:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000341c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003420:	4785                	li	a5,1
    80003422:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003424:	00014517          	auipc	a0,0x14
    80003428:	44450513          	addi	a0,a0,1092 # 80017868 <bcache>
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	85e080e7          	jalr	-1954(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003434:	01048513          	addi	a0,s1,16
    80003438:	00001097          	auipc	ra,0x1
    8000343c:	414080e7          	jalr	1044(ra) # 8000484c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003440:	409c                	lw	a5,0(s1)
    80003442:	cb89                	beqz	a5,80003454 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003444:	8526                	mv	a0,s1
    80003446:	70a2                	ld	ra,40(sp)
    80003448:	7402                	ld	s0,32(sp)
    8000344a:	64e2                	ld	s1,24(sp)
    8000344c:	6942                	ld	s2,16(sp)
    8000344e:	69a2                	ld	s3,8(sp)
    80003450:	6145                	addi	sp,sp,48
    80003452:	8082                	ret
    virtio_disk_rw(b, 0);
    80003454:	4581                	li	a1,0
    80003456:	8526                	mv	a0,s1
    80003458:	00003097          	auipc	ra,0x3
    8000345c:	21a080e7          	jalr	538(ra) # 80006672 <virtio_disk_rw>
    b->valid = 1;
    80003460:	4785                	li	a5,1
    80003462:	c09c                	sw	a5,0(s1)
  return b;
    80003464:	b7c5                	j	80003444 <bread+0xd0>

0000000080003466 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003466:	1101                	addi	sp,sp,-32
    80003468:	ec06                	sd	ra,24(sp)
    8000346a:	e822                	sd	s0,16(sp)
    8000346c:	e426                	sd	s1,8(sp)
    8000346e:	1000                	addi	s0,sp,32
    80003470:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003472:	0541                	addi	a0,a0,16
    80003474:	00001097          	auipc	ra,0x1
    80003478:	472080e7          	jalr	1138(ra) # 800048e6 <holdingsleep>
    8000347c:	cd01                	beqz	a0,80003494 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000347e:	4585                	li	a1,1
    80003480:	8526                	mv	a0,s1
    80003482:	00003097          	auipc	ra,0x3
    80003486:	1f0080e7          	jalr	496(ra) # 80006672 <virtio_disk_rw>
}
    8000348a:	60e2                	ld	ra,24(sp)
    8000348c:	6442                	ld	s0,16(sp)
    8000348e:	64a2                	ld	s1,8(sp)
    80003490:	6105                	addi	sp,sp,32
    80003492:	8082                	ret
    panic("bwrite");
    80003494:	00005517          	auipc	a0,0x5
    80003498:	1a450513          	addi	a0,a0,420 # 80008638 <syscalls+0x1e8>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	0a4080e7          	jalr	164(ra) # 80000540 <panic>

00000000800034a4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034a4:	1101                	addi	sp,sp,-32
    800034a6:	ec06                	sd	ra,24(sp)
    800034a8:	e822                	sd	s0,16(sp)
    800034aa:	e426                	sd	s1,8(sp)
    800034ac:	e04a                	sd	s2,0(sp)
    800034ae:	1000                	addi	s0,sp,32
    800034b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034b2:	01050913          	addi	s2,a0,16
    800034b6:	854a                	mv	a0,s2
    800034b8:	00001097          	auipc	ra,0x1
    800034bc:	42e080e7          	jalr	1070(ra) # 800048e6 <holdingsleep>
    800034c0:	c92d                	beqz	a0,80003532 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034c2:	854a                	mv	a0,s2
    800034c4:	00001097          	auipc	ra,0x1
    800034c8:	3de080e7          	jalr	990(ra) # 800048a2 <releasesleep>

  acquire(&bcache.lock);
    800034cc:	00014517          	auipc	a0,0x14
    800034d0:	39c50513          	addi	a0,a0,924 # 80017868 <bcache>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	702080e7          	jalr	1794(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800034dc:	40bc                	lw	a5,64(s1)
    800034de:	37fd                	addiw	a5,a5,-1
    800034e0:	0007871b          	sext.w	a4,a5
    800034e4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034e6:	eb05                	bnez	a4,80003516 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034e8:	68bc                	ld	a5,80(s1)
    800034ea:	64b8                	ld	a4,72(s1)
    800034ec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034ee:	64bc                	ld	a5,72(s1)
    800034f0:	68b8                	ld	a4,80(s1)
    800034f2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034f4:	0001c797          	auipc	a5,0x1c
    800034f8:	37478793          	addi	a5,a5,884 # 8001f868 <bcache+0x8000>
    800034fc:	2b87b703          	ld	a4,696(a5)
    80003500:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003502:	0001c717          	auipc	a4,0x1c
    80003506:	5ce70713          	addi	a4,a4,1486 # 8001fad0 <bcache+0x8268>
    8000350a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000350c:	2b87b703          	ld	a4,696(a5)
    80003510:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003512:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003516:	00014517          	auipc	a0,0x14
    8000351a:	35250513          	addi	a0,a0,850 # 80017868 <bcache>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	76c080e7          	jalr	1900(ra) # 80000c8a <release>
}
    80003526:	60e2                	ld	ra,24(sp)
    80003528:	6442                	ld	s0,16(sp)
    8000352a:	64a2                	ld	s1,8(sp)
    8000352c:	6902                	ld	s2,0(sp)
    8000352e:	6105                	addi	sp,sp,32
    80003530:	8082                	ret
    panic("brelse");
    80003532:	00005517          	auipc	a0,0x5
    80003536:	10e50513          	addi	a0,a0,270 # 80008640 <syscalls+0x1f0>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	006080e7          	jalr	6(ra) # 80000540 <panic>

0000000080003542 <bpin>:

void
bpin(struct buf *b) {
    80003542:	1101                	addi	sp,sp,-32
    80003544:	ec06                	sd	ra,24(sp)
    80003546:	e822                	sd	s0,16(sp)
    80003548:	e426                	sd	s1,8(sp)
    8000354a:	1000                	addi	s0,sp,32
    8000354c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000354e:	00014517          	auipc	a0,0x14
    80003552:	31a50513          	addi	a0,a0,794 # 80017868 <bcache>
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	680080e7          	jalr	1664(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000355e:	40bc                	lw	a5,64(s1)
    80003560:	2785                	addiw	a5,a5,1
    80003562:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003564:	00014517          	auipc	a0,0x14
    80003568:	30450513          	addi	a0,a0,772 # 80017868 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	71e080e7          	jalr	1822(ra) # 80000c8a <release>
}
    80003574:	60e2                	ld	ra,24(sp)
    80003576:	6442                	ld	s0,16(sp)
    80003578:	64a2                	ld	s1,8(sp)
    8000357a:	6105                	addi	sp,sp,32
    8000357c:	8082                	ret

000000008000357e <bunpin>:

void
bunpin(struct buf *b) {
    8000357e:	1101                	addi	sp,sp,-32
    80003580:	ec06                	sd	ra,24(sp)
    80003582:	e822                	sd	s0,16(sp)
    80003584:	e426                	sd	s1,8(sp)
    80003586:	1000                	addi	s0,sp,32
    80003588:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000358a:	00014517          	auipc	a0,0x14
    8000358e:	2de50513          	addi	a0,a0,734 # 80017868 <bcache>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	644080e7          	jalr	1604(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000359a:	40bc                	lw	a5,64(s1)
    8000359c:	37fd                	addiw	a5,a5,-1
    8000359e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035a0:	00014517          	auipc	a0,0x14
    800035a4:	2c850513          	addi	a0,a0,712 # 80017868 <bcache>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	6e2080e7          	jalr	1762(ra) # 80000c8a <release>
}
    800035b0:	60e2                	ld	ra,24(sp)
    800035b2:	6442                	ld	s0,16(sp)
    800035b4:	64a2                	ld	s1,8(sp)
    800035b6:	6105                	addi	sp,sp,32
    800035b8:	8082                	ret

00000000800035ba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035ba:	1101                	addi	sp,sp,-32
    800035bc:	ec06                	sd	ra,24(sp)
    800035be:	e822                	sd	s0,16(sp)
    800035c0:	e426                	sd	s1,8(sp)
    800035c2:	e04a                	sd	s2,0(sp)
    800035c4:	1000                	addi	s0,sp,32
    800035c6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035c8:	00d5d59b          	srliw	a1,a1,0xd
    800035cc:	0001d797          	auipc	a5,0x1d
    800035d0:	9787a783          	lw	a5,-1672(a5) # 8001ff44 <sb+0x1c>
    800035d4:	9dbd                	addw	a1,a1,a5
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	d9e080e7          	jalr	-610(ra) # 80003374 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035de:	0074f713          	andi	a4,s1,7
    800035e2:	4785                	li	a5,1
    800035e4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035e8:	14ce                	slli	s1,s1,0x33
    800035ea:	90d9                	srli	s1,s1,0x36
    800035ec:	00950733          	add	a4,a0,s1
    800035f0:	05874703          	lbu	a4,88(a4)
    800035f4:	00e7f6b3          	and	a3,a5,a4
    800035f8:	c69d                	beqz	a3,80003626 <bfree+0x6c>
    800035fa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035fc:	94aa                	add	s1,s1,a0
    800035fe:	fff7c793          	not	a5,a5
    80003602:	8f7d                	and	a4,a4,a5
    80003604:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003608:	00001097          	auipc	ra,0x1
    8000360c:	126080e7          	jalr	294(ra) # 8000472e <log_write>
  brelse(bp);
    80003610:	854a                	mv	a0,s2
    80003612:	00000097          	auipc	ra,0x0
    80003616:	e92080e7          	jalr	-366(ra) # 800034a4 <brelse>
}
    8000361a:	60e2                	ld	ra,24(sp)
    8000361c:	6442                	ld	s0,16(sp)
    8000361e:	64a2                	ld	s1,8(sp)
    80003620:	6902                	ld	s2,0(sp)
    80003622:	6105                	addi	sp,sp,32
    80003624:	8082                	ret
    panic("freeing free block");
    80003626:	00005517          	auipc	a0,0x5
    8000362a:	02250513          	addi	a0,a0,34 # 80008648 <syscalls+0x1f8>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	f12080e7          	jalr	-238(ra) # 80000540 <panic>

0000000080003636 <balloc>:
{
    80003636:	711d                	addi	sp,sp,-96
    80003638:	ec86                	sd	ra,88(sp)
    8000363a:	e8a2                	sd	s0,80(sp)
    8000363c:	e4a6                	sd	s1,72(sp)
    8000363e:	e0ca                	sd	s2,64(sp)
    80003640:	fc4e                	sd	s3,56(sp)
    80003642:	f852                	sd	s4,48(sp)
    80003644:	f456                	sd	s5,40(sp)
    80003646:	f05a                	sd	s6,32(sp)
    80003648:	ec5e                	sd	s7,24(sp)
    8000364a:	e862                	sd	s8,16(sp)
    8000364c:	e466                	sd	s9,8(sp)
    8000364e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003650:	0001d797          	auipc	a5,0x1d
    80003654:	8dc7a783          	lw	a5,-1828(a5) # 8001ff2c <sb+0x4>
    80003658:	cff5                	beqz	a5,80003754 <balloc+0x11e>
    8000365a:	8baa                	mv	s7,a0
    8000365c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000365e:	0001db17          	auipc	s6,0x1d
    80003662:	8cab0b13          	addi	s6,s6,-1846 # 8001ff28 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003666:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003668:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000366c:	6c89                	lui	s9,0x2
    8000366e:	a061                	j	800036f6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003670:	97ca                	add	a5,a5,s2
    80003672:	8e55                	or	a2,a2,a3
    80003674:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003678:	854a                	mv	a0,s2
    8000367a:	00001097          	auipc	ra,0x1
    8000367e:	0b4080e7          	jalr	180(ra) # 8000472e <log_write>
        brelse(bp);
    80003682:	854a                	mv	a0,s2
    80003684:	00000097          	auipc	ra,0x0
    80003688:	e20080e7          	jalr	-480(ra) # 800034a4 <brelse>
  bp = bread(dev, bno);
    8000368c:	85a6                	mv	a1,s1
    8000368e:	855e                	mv	a0,s7
    80003690:	00000097          	auipc	ra,0x0
    80003694:	ce4080e7          	jalr	-796(ra) # 80003374 <bread>
    80003698:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000369a:	40000613          	li	a2,1024
    8000369e:	4581                	li	a1,0
    800036a0:	05850513          	addi	a0,a0,88
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	62e080e7          	jalr	1582(ra) # 80000cd2 <memset>
  log_write(bp);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	080080e7          	jalr	128(ra) # 8000472e <log_write>
  brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	dec080e7          	jalr	-532(ra) # 800034a4 <brelse>
}
    800036c0:	8526                	mv	a0,s1
    800036c2:	60e6                	ld	ra,88(sp)
    800036c4:	6446                	ld	s0,80(sp)
    800036c6:	64a6                	ld	s1,72(sp)
    800036c8:	6906                	ld	s2,64(sp)
    800036ca:	79e2                	ld	s3,56(sp)
    800036cc:	7a42                	ld	s4,48(sp)
    800036ce:	7aa2                	ld	s5,40(sp)
    800036d0:	7b02                	ld	s6,32(sp)
    800036d2:	6be2                	ld	s7,24(sp)
    800036d4:	6c42                	ld	s8,16(sp)
    800036d6:	6ca2                	ld	s9,8(sp)
    800036d8:	6125                	addi	sp,sp,96
    800036da:	8082                	ret
    brelse(bp);
    800036dc:	854a                	mv	a0,s2
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	dc6080e7          	jalr	-570(ra) # 800034a4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036e6:	015c87bb          	addw	a5,s9,s5
    800036ea:	00078a9b          	sext.w	s5,a5
    800036ee:	004b2703          	lw	a4,4(s6)
    800036f2:	06eaf163          	bgeu	s5,a4,80003754 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800036f6:	41fad79b          	sraiw	a5,s5,0x1f
    800036fa:	0137d79b          	srliw	a5,a5,0x13
    800036fe:	015787bb          	addw	a5,a5,s5
    80003702:	40d7d79b          	sraiw	a5,a5,0xd
    80003706:	01cb2583          	lw	a1,28(s6)
    8000370a:	9dbd                	addw	a1,a1,a5
    8000370c:	855e                	mv	a0,s7
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	c66080e7          	jalr	-922(ra) # 80003374 <bread>
    80003716:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003718:	004b2503          	lw	a0,4(s6)
    8000371c:	000a849b          	sext.w	s1,s5
    80003720:	8762                	mv	a4,s8
    80003722:	faa4fde3          	bgeu	s1,a0,800036dc <balloc+0xa6>
      m = 1 << (bi % 8);
    80003726:	00777693          	andi	a3,a4,7
    8000372a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000372e:	41f7579b          	sraiw	a5,a4,0x1f
    80003732:	01d7d79b          	srliw	a5,a5,0x1d
    80003736:	9fb9                	addw	a5,a5,a4
    80003738:	4037d79b          	sraiw	a5,a5,0x3
    8000373c:	00f90633          	add	a2,s2,a5
    80003740:	05864603          	lbu	a2,88(a2)
    80003744:	00c6f5b3          	and	a1,a3,a2
    80003748:	d585                	beqz	a1,80003670 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000374a:	2705                	addiw	a4,a4,1
    8000374c:	2485                	addiw	s1,s1,1
    8000374e:	fd471ae3          	bne	a4,s4,80003722 <balloc+0xec>
    80003752:	b769                	j	800036dc <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	f0c50513          	addi	a0,a0,-244 # 80008660 <syscalls+0x210>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	e2e080e7          	jalr	-466(ra) # 8000058a <printf>
  return 0;
    80003764:	4481                	li	s1,0
    80003766:	bfa9                	j	800036c0 <balloc+0x8a>

0000000080003768 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003768:	7179                	addi	sp,sp,-48
    8000376a:	f406                	sd	ra,40(sp)
    8000376c:	f022                	sd	s0,32(sp)
    8000376e:	ec26                	sd	s1,24(sp)
    80003770:	e84a                	sd	s2,16(sp)
    80003772:	e44e                	sd	s3,8(sp)
    80003774:	e052                	sd	s4,0(sp)
    80003776:	1800                	addi	s0,sp,48
    80003778:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000377a:	47ad                	li	a5,11
    8000377c:	02b7e863          	bltu	a5,a1,800037ac <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003780:	02059793          	slli	a5,a1,0x20
    80003784:	01e7d593          	srli	a1,a5,0x1e
    80003788:	00b504b3          	add	s1,a0,a1
    8000378c:	0504a903          	lw	s2,80(s1)
    80003790:	06091e63          	bnez	s2,8000380c <bmap+0xa4>
      addr = balloc(ip->dev);
    80003794:	4108                	lw	a0,0(a0)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	ea0080e7          	jalr	-352(ra) # 80003636 <balloc>
    8000379e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037a2:	06090563          	beqz	s2,8000380c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800037a6:	0524a823          	sw	s2,80(s1)
    800037aa:	a08d                	j	8000380c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800037ac:	ff45849b          	addiw	s1,a1,-12
    800037b0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037b4:	0ff00793          	li	a5,255
    800037b8:	08e7e563          	bltu	a5,a4,80003842 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800037bc:	08052903          	lw	s2,128(a0)
    800037c0:	00091d63          	bnez	s2,800037da <bmap+0x72>
      addr = balloc(ip->dev);
    800037c4:	4108                	lw	a0,0(a0)
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	e70080e7          	jalr	-400(ra) # 80003636 <balloc>
    800037ce:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037d2:	02090d63          	beqz	s2,8000380c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800037d6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800037da:	85ca                	mv	a1,s2
    800037dc:	0009a503          	lw	a0,0(s3)
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	b94080e7          	jalr	-1132(ra) # 80003374 <bread>
    800037e8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037ea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037ee:	02049713          	slli	a4,s1,0x20
    800037f2:	01e75593          	srli	a1,a4,0x1e
    800037f6:	00b784b3          	add	s1,a5,a1
    800037fa:	0004a903          	lw	s2,0(s1)
    800037fe:	02090063          	beqz	s2,8000381e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003802:	8552                	mv	a0,s4
    80003804:	00000097          	auipc	ra,0x0
    80003808:	ca0080e7          	jalr	-864(ra) # 800034a4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000380c:	854a                	mv	a0,s2
    8000380e:	70a2                	ld	ra,40(sp)
    80003810:	7402                	ld	s0,32(sp)
    80003812:	64e2                	ld	s1,24(sp)
    80003814:	6942                	ld	s2,16(sp)
    80003816:	69a2                	ld	s3,8(sp)
    80003818:	6a02                	ld	s4,0(sp)
    8000381a:	6145                	addi	sp,sp,48
    8000381c:	8082                	ret
      addr = balloc(ip->dev);
    8000381e:	0009a503          	lw	a0,0(s3)
    80003822:	00000097          	auipc	ra,0x0
    80003826:	e14080e7          	jalr	-492(ra) # 80003636 <balloc>
    8000382a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000382e:	fc090ae3          	beqz	s2,80003802 <bmap+0x9a>
        a[bn] = addr;
    80003832:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003836:	8552                	mv	a0,s4
    80003838:	00001097          	auipc	ra,0x1
    8000383c:	ef6080e7          	jalr	-266(ra) # 8000472e <log_write>
    80003840:	b7c9                	j	80003802 <bmap+0x9a>
  panic("bmap: out of range");
    80003842:	00005517          	auipc	a0,0x5
    80003846:	e3650513          	addi	a0,a0,-458 # 80008678 <syscalls+0x228>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	cf6080e7          	jalr	-778(ra) # 80000540 <panic>

0000000080003852 <iget>:
{
    80003852:	7179                	addi	sp,sp,-48
    80003854:	f406                	sd	ra,40(sp)
    80003856:	f022                	sd	s0,32(sp)
    80003858:	ec26                	sd	s1,24(sp)
    8000385a:	e84a                	sd	s2,16(sp)
    8000385c:	e44e                	sd	s3,8(sp)
    8000385e:	e052                	sd	s4,0(sp)
    80003860:	1800                	addi	s0,sp,48
    80003862:	89aa                	mv	s3,a0
    80003864:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003866:	0001c517          	auipc	a0,0x1c
    8000386a:	6e250513          	addi	a0,a0,1762 # 8001ff48 <itable>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	368080e7          	jalr	872(ra) # 80000bd6 <acquire>
  empty = 0;
    80003876:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003878:	0001c497          	auipc	s1,0x1c
    8000387c:	6e848493          	addi	s1,s1,1768 # 8001ff60 <itable+0x18>
    80003880:	0001e697          	auipc	a3,0x1e
    80003884:	17068693          	addi	a3,a3,368 # 800219f0 <log>
    80003888:	a039                	j	80003896 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000388a:	02090b63          	beqz	s2,800038c0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000388e:	08848493          	addi	s1,s1,136
    80003892:	02d48a63          	beq	s1,a3,800038c6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003896:	449c                	lw	a5,8(s1)
    80003898:	fef059e3          	blez	a5,8000388a <iget+0x38>
    8000389c:	4098                	lw	a4,0(s1)
    8000389e:	ff3716e3          	bne	a4,s3,8000388a <iget+0x38>
    800038a2:	40d8                	lw	a4,4(s1)
    800038a4:	ff4713e3          	bne	a4,s4,8000388a <iget+0x38>
      ip->ref++;
    800038a8:	2785                	addiw	a5,a5,1
    800038aa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038ac:	0001c517          	auipc	a0,0x1c
    800038b0:	69c50513          	addi	a0,a0,1692 # 8001ff48 <itable>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	3d6080e7          	jalr	982(ra) # 80000c8a <release>
      return ip;
    800038bc:	8926                	mv	s2,s1
    800038be:	a03d                	j	800038ec <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038c0:	f7f9                	bnez	a5,8000388e <iget+0x3c>
    800038c2:	8926                	mv	s2,s1
    800038c4:	b7e9                	j	8000388e <iget+0x3c>
  if(empty == 0)
    800038c6:	02090c63          	beqz	s2,800038fe <iget+0xac>
  ip->dev = dev;
    800038ca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038ce:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038d2:	4785                	li	a5,1
    800038d4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038d8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038dc:	0001c517          	auipc	a0,0x1c
    800038e0:	66c50513          	addi	a0,a0,1644 # 8001ff48 <itable>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	3a6080e7          	jalr	934(ra) # 80000c8a <release>
}
    800038ec:	854a                	mv	a0,s2
    800038ee:	70a2                	ld	ra,40(sp)
    800038f0:	7402                	ld	s0,32(sp)
    800038f2:	64e2                	ld	s1,24(sp)
    800038f4:	6942                	ld	s2,16(sp)
    800038f6:	69a2                	ld	s3,8(sp)
    800038f8:	6a02                	ld	s4,0(sp)
    800038fa:	6145                	addi	sp,sp,48
    800038fc:	8082                	ret
    panic("iget: no inodes");
    800038fe:	00005517          	auipc	a0,0x5
    80003902:	d9250513          	addi	a0,a0,-622 # 80008690 <syscalls+0x240>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	c3a080e7          	jalr	-966(ra) # 80000540 <panic>

000000008000390e <fsinit>:
fsinit(int dev) {
    8000390e:	7179                	addi	sp,sp,-48
    80003910:	f406                	sd	ra,40(sp)
    80003912:	f022                	sd	s0,32(sp)
    80003914:	ec26                	sd	s1,24(sp)
    80003916:	e84a                	sd	s2,16(sp)
    80003918:	e44e                	sd	s3,8(sp)
    8000391a:	1800                	addi	s0,sp,48
    8000391c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000391e:	4585                	li	a1,1
    80003920:	00000097          	auipc	ra,0x0
    80003924:	a54080e7          	jalr	-1452(ra) # 80003374 <bread>
    80003928:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000392a:	0001c997          	auipc	s3,0x1c
    8000392e:	5fe98993          	addi	s3,s3,1534 # 8001ff28 <sb>
    80003932:	02000613          	li	a2,32
    80003936:	05850593          	addi	a1,a0,88
    8000393a:	854e                	mv	a0,s3
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	3f2080e7          	jalr	1010(ra) # 80000d2e <memmove>
  brelse(bp);
    80003944:	8526                	mv	a0,s1
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	b5e080e7          	jalr	-1186(ra) # 800034a4 <brelse>
  if(sb.magic != FSMAGIC)
    8000394e:	0009a703          	lw	a4,0(s3)
    80003952:	102037b7          	lui	a5,0x10203
    80003956:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000395a:	02f71263          	bne	a4,a5,8000397e <fsinit+0x70>
  initlog(dev, &sb);
    8000395e:	0001c597          	auipc	a1,0x1c
    80003962:	5ca58593          	addi	a1,a1,1482 # 8001ff28 <sb>
    80003966:	854a                	mv	a0,s2
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	b4a080e7          	jalr	-1206(ra) # 800044b2 <initlog>
}
    80003970:	70a2                	ld	ra,40(sp)
    80003972:	7402                	ld	s0,32(sp)
    80003974:	64e2                	ld	s1,24(sp)
    80003976:	6942                	ld	s2,16(sp)
    80003978:	69a2                	ld	s3,8(sp)
    8000397a:	6145                	addi	sp,sp,48
    8000397c:	8082                	ret
    panic("invalid file system");
    8000397e:	00005517          	auipc	a0,0x5
    80003982:	d2250513          	addi	a0,a0,-734 # 800086a0 <syscalls+0x250>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	bba080e7          	jalr	-1094(ra) # 80000540 <panic>

000000008000398e <iinit>:
{
    8000398e:	7179                	addi	sp,sp,-48
    80003990:	f406                	sd	ra,40(sp)
    80003992:	f022                	sd	s0,32(sp)
    80003994:	ec26                	sd	s1,24(sp)
    80003996:	e84a                	sd	s2,16(sp)
    80003998:	e44e                	sd	s3,8(sp)
    8000399a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000399c:	00005597          	auipc	a1,0x5
    800039a0:	d1c58593          	addi	a1,a1,-740 # 800086b8 <syscalls+0x268>
    800039a4:	0001c517          	auipc	a0,0x1c
    800039a8:	5a450513          	addi	a0,a0,1444 # 8001ff48 <itable>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	19a080e7          	jalr	410(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039b4:	0001c497          	auipc	s1,0x1c
    800039b8:	5bc48493          	addi	s1,s1,1468 # 8001ff70 <itable+0x28>
    800039bc:	0001e997          	auipc	s3,0x1e
    800039c0:	04498993          	addi	s3,s3,68 # 80021a00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039c4:	00005917          	auipc	s2,0x5
    800039c8:	cfc90913          	addi	s2,s2,-772 # 800086c0 <syscalls+0x270>
    800039cc:	85ca                	mv	a1,s2
    800039ce:	8526                	mv	a0,s1
    800039d0:	00001097          	auipc	ra,0x1
    800039d4:	e42080e7          	jalr	-446(ra) # 80004812 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039d8:	08848493          	addi	s1,s1,136
    800039dc:	ff3498e3          	bne	s1,s3,800039cc <iinit+0x3e>
}
    800039e0:	70a2                	ld	ra,40(sp)
    800039e2:	7402                	ld	s0,32(sp)
    800039e4:	64e2                	ld	s1,24(sp)
    800039e6:	6942                	ld	s2,16(sp)
    800039e8:	69a2                	ld	s3,8(sp)
    800039ea:	6145                	addi	sp,sp,48
    800039ec:	8082                	ret

00000000800039ee <ialloc>:
{
    800039ee:	715d                	addi	sp,sp,-80
    800039f0:	e486                	sd	ra,72(sp)
    800039f2:	e0a2                	sd	s0,64(sp)
    800039f4:	fc26                	sd	s1,56(sp)
    800039f6:	f84a                	sd	s2,48(sp)
    800039f8:	f44e                	sd	s3,40(sp)
    800039fa:	f052                	sd	s4,32(sp)
    800039fc:	ec56                	sd	s5,24(sp)
    800039fe:	e85a                	sd	s6,16(sp)
    80003a00:	e45e                	sd	s7,8(sp)
    80003a02:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a04:	0001c717          	auipc	a4,0x1c
    80003a08:	53072703          	lw	a4,1328(a4) # 8001ff34 <sb+0xc>
    80003a0c:	4785                	li	a5,1
    80003a0e:	04e7fa63          	bgeu	a5,a4,80003a62 <ialloc+0x74>
    80003a12:	8aaa                	mv	s5,a0
    80003a14:	8bae                	mv	s7,a1
    80003a16:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a18:	0001ca17          	auipc	s4,0x1c
    80003a1c:	510a0a13          	addi	s4,s4,1296 # 8001ff28 <sb>
    80003a20:	00048b1b          	sext.w	s6,s1
    80003a24:	0044d593          	srli	a1,s1,0x4
    80003a28:	018a2783          	lw	a5,24(s4)
    80003a2c:	9dbd                	addw	a1,a1,a5
    80003a2e:	8556                	mv	a0,s5
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	944080e7          	jalr	-1724(ra) # 80003374 <bread>
    80003a38:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a3a:	05850993          	addi	s3,a0,88
    80003a3e:	00f4f793          	andi	a5,s1,15
    80003a42:	079a                	slli	a5,a5,0x6
    80003a44:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a46:	00099783          	lh	a5,0(s3)
    80003a4a:	c3a1                	beqz	a5,80003a8a <ialloc+0x9c>
    brelse(bp);
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	a58080e7          	jalr	-1448(ra) # 800034a4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a54:	0485                	addi	s1,s1,1
    80003a56:	00ca2703          	lw	a4,12(s4)
    80003a5a:	0004879b          	sext.w	a5,s1
    80003a5e:	fce7e1e3          	bltu	a5,a4,80003a20 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003a62:	00005517          	auipc	a0,0x5
    80003a66:	c6650513          	addi	a0,a0,-922 # 800086c8 <syscalls+0x278>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	b20080e7          	jalr	-1248(ra) # 8000058a <printf>
  return 0;
    80003a72:	4501                	li	a0,0
}
    80003a74:	60a6                	ld	ra,72(sp)
    80003a76:	6406                	ld	s0,64(sp)
    80003a78:	74e2                	ld	s1,56(sp)
    80003a7a:	7942                	ld	s2,48(sp)
    80003a7c:	79a2                	ld	s3,40(sp)
    80003a7e:	7a02                	ld	s4,32(sp)
    80003a80:	6ae2                	ld	s5,24(sp)
    80003a82:	6b42                	ld	s6,16(sp)
    80003a84:	6ba2                	ld	s7,8(sp)
    80003a86:	6161                	addi	sp,sp,80
    80003a88:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a8a:	04000613          	li	a2,64
    80003a8e:	4581                	li	a1,0
    80003a90:	854e                	mv	a0,s3
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	240080e7          	jalr	576(ra) # 80000cd2 <memset>
      dip->type = type;
    80003a9a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a9e:	854a                	mv	a0,s2
    80003aa0:	00001097          	auipc	ra,0x1
    80003aa4:	c8e080e7          	jalr	-882(ra) # 8000472e <log_write>
      brelse(bp);
    80003aa8:	854a                	mv	a0,s2
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	9fa080e7          	jalr	-1542(ra) # 800034a4 <brelse>
      return iget(dev, inum);
    80003ab2:	85da                	mv	a1,s6
    80003ab4:	8556                	mv	a0,s5
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	d9c080e7          	jalr	-612(ra) # 80003852 <iget>
    80003abe:	bf5d                	j	80003a74 <ialloc+0x86>

0000000080003ac0 <iupdate>:
{
    80003ac0:	1101                	addi	sp,sp,-32
    80003ac2:	ec06                	sd	ra,24(sp)
    80003ac4:	e822                	sd	s0,16(sp)
    80003ac6:	e426                	sd	s1,8(sp)
    80003ac8:	e04a                	sd	s2,0(sp)
    80003aca:	1000                	addi	s0,sp,32
    80003acc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ace:	415c                	lw	a5,4(a0)
    80003ad0:	0047d79b          	srliw	a5,a5,0x4
    80003ad4:	0001c597          	auipc	a1,0x1c
    80003ad8:	46c5a583          	lw	a1,1132(a1) # 8001ff40 <sb+0x18>
    80003adc:	9dbd                	addw	a1,a1,a5
    80003ade:	4108                	lw	a0,0(a0)
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	894080e7          	jalr	-1900(ra) # 80003374 <bread>
    80003ae8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aea:	05850793          	addi	a5,a0,88
    80003aee:	40d8                	lw	a4,4(s1)
    80003af0:	8b3d                	andi	a4,a4,15
    80003af2:	071a                	slli	a4,a4,0x6
    80003af4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003af6:	04449703          	lh	a4,68(s1)
    80003afa:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003afe:	04649703          	lh	a4,70(s1)
    80003b02:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b06:	04849703          	lh	a4,72(s1)
    80003b0a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b0e:	04a49703          	lh	a4,74(s1)
    80003b12:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b16:	44f8                	lw	a4,76(s1)
    80003b18:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b1a:	03400613          	li	a2,52
    80003b1e:	05048593          	addi	a1,s1,80
    80003b22:	00c78513          	addi	a0,a5,12
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	208080e7          	jalr	520(ra) # 80000d2e <memmove>
  log_write(bp);
    80003b2e:	854a                	mv	a0,s2
    80003b30:	00001097          	auipc	ra,0x1
    80003b34:	bfe080e7          	jalr	-1026(ra) # 8000472e <log_write>
  brelse(bp);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	96a080e7          	jalr	-1686(ra) # 800034a4 <brelse>
}
    80003b42:	60e2                	ld	ra,24(sp)
    80003b44:	6442                	ld	s0,16(sp)
    80003b46:	64a2                	ld	s1,8(sp)
    80003b48:	6902                	ld	s2,0(sp)
    80003b4a:	6105                	addi	sp,sp,32
    80003b4c:	8082                	ret

0000000080003b4e <idup>:
{
    80003b4e:	1101                	addi	sp,sp,-32
    80003b50:	ec06                	sd	ra,24(sp)
    80003b52:	e822                	sd	s0,16(sp)
    80003b54:	e426                	sd	s1,8(sp)
    80003b56:	1000                	addi	s0,sp,32
    80003b58:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b5a:	0001c517          	auipc	a0,0x1c
    80003b5e:	3ee50513          	addi	a0,a0,1006 # 8001ff48 <itable>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	074080e7          	jalr	116(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003b6a:	449c                	lw	a5,8(s1)
    80003b6c:	2785                	addiw	a5,a5,1
    80003b6e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b70:	0001c517          	auipc	a0,0x1c
    80003b74:	3d850513          	addi	a0,a0,984 # 8001ff48 <itable>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	112080e7          	jalr	274(ra) # 80000c8a <release>
}
    80003b80:	8526                	mv	a0,s1
    80003b82:	60e2                	ld	ra,24(sp)
    80003b84:	6442                	ld	s0,16(sp)
    80003b86:	64a2                	ld	s1,8(sp)
    80003b88:	6105                	addi	sp,sp,32
    80003b8a:	8082                	ret

0000000080003b8c <ilock>:
{
    80003b8c:	1101                	addi	sp,sp,-32
    80003b8e:	ec06                	sd	ra,24(sp)
    80003b90:	e822                	sd	s0,16(sp)
    80003b92:	e426                	sd	s1,8(sp)
    80003b94:	e04a                	sd	s2,0(sp)
    80003b96:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b98:	c115                	beqz	a0,80003bbc <ilock+0x30>
    80003b9a:	84aa                	mv	s1,a0
    80003b9c:	451c                	lw	a5,8(a0)
    80003b9e:	00f05f63          	blez	a5,80003bbc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ba2:	0541                	addi	a0,a0,16
    80003ba4:	00001097          	auipc	ra,0x1
    80003ba8:	ca8080e7          	jalr	-856(ra) # 8000484c <acquiresleep>
  if(ip->valid == 0){
    80003bac:	40bc                	lw	a5,64(s1)
    80003bae:	cf99                	beqz	a5,80003bcc <ilock+0x40>
}
    80003bb0:	60e2                	ld	ra,24(sp)
    80003bb2:	6442                	ld	s0,16(sp)
    80003bb4:	64a2                	ld	s1,8(sp)
    80003bb6:	6902                	ld	s2,0(sp)
    80003bb8:	6105                	addi	sp,sp,32
    80003bba:	8082                	ret
    panic("ilock");
    80003bbc:	00005517          	auipc	a0,0x5
    80003bc0:	b2450513          	addi	a0,a0,-1244 # 800086e0 <syscalls+0x290>
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	97c080e7          	jalr	-1668(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bcc:	40dc                	lw	a5,4(s1)
    80003bce:	0047d79b          	srliw	a5,a5,0x4
    80003bd2:	0001c597          	auipc	a1,0x1c
    80003bd6:	36e5a583          	lw	a1,878(a1) # 8001ff40 <sb+0x18>
    80003bda:	9dbd                	addw	a1,a1,a5
    80003bdc:	4088                	lw	a0,0(s1)
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	796080e7          	jalr	1942(ra) # 80003374 <bread>
    80003be6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003be8:	05850593          	addi	a1,a0,88
    80003bec:	40dc                	lw	a5,4(s1)
    80003bee:	8bbd                	andi	a5,a5,15
    80003bf0:	079a                	slli	a5,a5,0x6
    80003bf2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bf4:	00059783          	lh	a5,0(a1)
    80003bf8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bfc:	00259783          	lh	a5,2(a1)
    80003c00:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c04:	00459783          	lh	a5,4(a1)
    80003c08:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c0c:	00659783          	lh	a5,6(a1)
    80003c10:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c14:	459c                	lw	a5,8(a1)
    80003c16:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c18:	03400613          	li	a2,52
    80003c1c:	05b1                	addi	a1,a1,12
    80003c1e:	05048513          	addi	a0,s1,80
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	10c080e7          	jalr	268(ra) # 80000d2e <memmove>
    brelse(bp);
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	878080e7          	jalr	-1928(ra) # 800034a4 <brelse>
    ip->valid = 1;
    80003c34:	4785                	li	a5,1
    80003c36:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c38:	04449783          	lh	a5,68(s1)
    80003c3c:	fbb5                	bnez	a5,80003bb0 <ilock+0x24>
      panic("ilock: no type");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	aaa50513          	addi	a0,a0,-1366 # 800086e8 <syscalls+0x298>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8fa080e7          	jalr	-1798(ra) # 80000540 <panic>

0000000080003c4e <iunlock>:
{
    80003c4e:	1101                	addi	sp,sp,-32
    80003c50:	ec06                	sd	ra,24(sp)
    80003c52:	e822                	sd	s0,16(sp)
    80003c54:	e426                	sd	s1,8(sp)
    80003c56:	e04a                	sd	s2,0(sp)
    80003c58:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c5a:	c905                	beqz	a0,80003c8a <iunlock+0x3c>
    80003c5c:	84aa                	mv	s1,a0
    80003c5e:	01050913          	addi	s2,a0,16
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	c82080e7          	jalr	-894(ra) # 800048e6 <holdingsleep>
    80003c6c:	cd19                	beqz	a0,80003c8a <iunlock+0x3c>
    80003c6e:	449c                	lw	a5,8(s1)
    80003c70:	00f05d63          	blez	a5,80003c8a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c74:	854a                	mv	a0,s2
    80003c76:	00001097          	auipc	ra,0x1
    80003c7a:	c2c080e7          	jalr	-980(ra) # 800048a2 <releasesleep>
}
    80003c7e:	60e2                	ld	ra,24(sp)
    80003c80:	6442                	ld	s0,16(sp)
    80003c82:	64a2                	ld	s1,8(sp)
    80003c84:	6902                	ld	s2,0(sp)
    80003c86:	6105                	addi	sp,sp,32
    80003c88:	8082                	ret
    panic("iunlock");
    80003c8a:	00005517          	auipc	a0,0x5
    80003c8e:	a6e50513          	addi	a0,a0,-1426 # 800086f8 <syscalls+0x2a8>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	8ae080e7          	jalr	-1874(ra) # 80000540 <panic>

0000000080003c9a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c9a:	7179                	addi	sp,sp,-48
    80003c9c:	f406                	sd	ra,40(sp)
    80003c9e:	f022                	sd	s0,32(sp)
    80003ca0:	ec26                	sd	s1,24(sp)
    80003ca2:	e84a                	sd	s2,16(sp)
    80003ca4:	e44e                	sd	s3,8(sp)
    80003ca6:	e052                	sd	s4,0(sp)
    80003ca8:	1800                	addi	s0,sp,48
    80003caa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cac:	05050493          	addi	s1,a0,80
    80003cb0:	08050913          	addi	s2,a0,128
    80003cb4:	a021                	j	80003cbc <itrunc+0x22>
    80003cb6:	0491                	addi	s1,s1,4
    80003cb8:	01248d63          	beq	s1,s2,80003cd2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cbc:	408c                	lw	a1,0(s1)
    80003cbe:	dde5                	beqz	a1,80003cb6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cc0:	0009a503          	lw	a0,0(s3)
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	8f6080e7          	jalr	-1802(ra) # 800035ba <bfree>
      ip->addrs[i] = 0;
    80003ccc:	0004a023          	sw	zero,0(s1)
    80003cd0:	b7dd                	j	80003cb6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cd2:	0809a583          	lw	a1,128(s3)
    80003cd6:	e185                	bnez	a1,80003cf6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cd8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cdc:	854e                	mv	a0,s3
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	de2080e7          	jalr	-542(ra) # 80003ac0 <iupdate>
}
    80003ce6:	70a2                	ld	ra,40(sp)
    80003ce8:	7402                	ld	s0,32(sp)
    80003cea:	64e2                	ld	s1,24(sp)
    80003cec:	6942                	ld	s2,16(sp)
    80003cee:	69a2                	ld	s3,8(sp)
    80003cf0:	6a02                	ld	s4,0(sp)
    80003cf2:	6145                	addi	sp,sp,48
    80003cf4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cf6:	0009a503          	lw	a0,0(s3)
    80003cfa:	fffff097          	auipc	ra,0xfffff
    80003cfe:	67a080e7          	jalr	1658(ra) # 80003374 <bread>
    80003d02:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d04:	05850493          	addi	s1,a0,88
    80003d08:	45850913          	addi	s2,a0,1112
    80003d0c:	a021                	j	80003d14 <itrunc+0x7a>
    80003d0e:	0491                	addi	s1,s1,4
    80003d10:	01248b63          	beq	s1,s2,80003d26 <itrunc+0x8c>
      if(a[j])
    80003d14:	408c                	lw	a1,0(s1)
    80003d16:	dde5                	beqz	a1,80003d0e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d18:	0009a503          	lw	a0,0(s3)
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	89e080e7          	jalr	-1890(ra) # 800035ba <bfree>
    80003d24:	b7ed                	j	80003d0e <itrunc+0x74>
    brelse(bp);
    80003d26:	8552                	mv	a0,s4
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	77c080e7          	jalr	1916(ra) # 800034a4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d30:	0809a583          	lw	a1,128(s3)
    80003d34:	0009a503          	lw	a0,0(s3)
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	882080e7          	jalr	-1918(ra) # 800035ba <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d40:	0809a023          	sw	zero,128(s3)
    80003d44:	bf51                	j	80003cd8 <itrunc+0x3e>

0000000080003d46 <iput>:
{
    80003d46:	1101                	addi	sp,sp,-32
    80003d48:	ec06                	sd	ra,24(sp)
    80003d4a:	e822                	sd	s0,16(sp)
    80003d4c:	e426                	sd	s1,8(sp)
    80003d4e:	e04a                	sd	s2,0(sp)
    80003d50:	1000                	addi	s0,sp,32
    80003d52:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d54:	0001c517          	auipc	a0,0x1c
    80003d58:	1f450513          	addi	a0,a0,500 # 8001ff48 <itable>
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	e7a080e7          	jalr	-390(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d64:	4498                	lw	a4,8(s1)
    80003d66:	4785                	li	a5,1
    80003d68:	02f70363          	beq	a4,a5,80003d8e <iput+0x48>
  ip->ref--;
    80003d6c:	449c                	lw	a5,8(s1)
    80003d6e:	37fd                	addiw	a5,a5,-1
    80003d70:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d72:	0001c517          	auipc	a0,0x1c
    80003d76:	1d650513          	addi	a0,a0,470 # 8001ff48 <itable>
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	f10080e7          	jalr	-240(ra) # 80000c8a <release>
}
    80003d82:	60e2                	ld	ra,24(sp)
    80003d84:	6442                	ld	s0,16(sp)
    80003d86:	64a2                	ld	s1,8(sp)
    80003d88:	6902                	ld	s2,0(sp)
    80003d8a:	6105                	addi	sp,sp,32
    80003d8c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d8e:	40bc                	lw	a5,64(s1)
    80003d90:	dff1                	beqz	a5,80003d6c <iput+0x26>
    80003d92:	04a49783          	lh	a5,74(s1)
    80003d96:	fbf9                	bnez	a5,80003d6c <iput+0x26>
    acquiresleep(&ip->lock);
    80003d98:	01048913          	addi	s2,s1,16
    80003d9c:	854a                	mv	a0,s2
    80003d9e:	00001097          	auipc	ra,0x1
    80003da2:	aae080e7          	jalr	-1362(ra) # 8000484c <acquiresleep>
    release(&itable.lock);
    80003da6:	0001c517          	auipc	a0,0x1c
    80003daa:	1a250513          	addi	a0,a0,418 # 8001ff48 <itable>
    80003dae:	ffffd097          	auipc	ra,0xffffd
    80003db2:	edc080e7          	jalr	-292(ra) # 80000c8a <release>
    itrunc(ip);
    80003db6:	8526                	mv	a0,s1
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	ee2080e7          	jalr	-286(ra) # 80003c9a <itrunc>
    ip->type = 0;
    80003dc0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dc4:	8526                	mv	a0,s1
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	cfa080e7          	jalr	-774(ra) # 80003ac0 <iupdate>
    ip->valid = 0;
    80003dce:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	00001097          	auipc	ra,0x1
    80003dd8:	ace080e7          	jalr	-1330(ra) # 800048a2 <releasesleep>
    acquire(&itable.lock);
    80003ddc:	0001c517          	auipc	a0,0x1c
    80003de0:	16c50513          	addi	a0,a0,364 # 8001ff48 <itable>
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	df2080e7          	jalr	-526(ra) # 80000bd6 <acquire>
    80003dec:	b741                	j	80003d6c <iput+0x26>

0000000080003dee <iunlockput>:
{
    80003dee:	1101                	addi	sp,sp,-32
    80003df0:	ec06                	sd	ra,24(sp)
    80003df2:	e822                	sd	s0,16(sp)
    80003df4:	e426                	sd	s1,8(sp)
    80003df6:	1000                	addi	s0,sp,32
    80003df8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	e54080e7          	jalr	-428(ra) # 80003c4e <iunlock>
  iput(ip);
    80003e02:	8526                	mv	a0,s1
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	f42080e7          	jalr	-190(ra) # 80003d46 <iput>
}
    80003e0c:	60e2                	ld	ra,24(sp)
    80003e0e:	6442                	ld	s0,16(sp)
    80003e10:	64a2                	ld	s1,8(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret

0000000080003e16 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e16:	1141                	addi	sp,sp,-16
    80003e18:	e422                	sd	s0,8(sp)
    80003e1a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e1c:	411c                	lw	a5,0(a0)
    80003e1e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e20:	415c                	lw	a5,4(a0)
    80003e22:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e24:	04451783          	lh	a5,68(a0)
    80003e28:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e2c:	04a51783          	lh	a5,74(a0)
    80003e30:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e34:	04c56783          	lwu	a5,76(a0)
    80003e38:	e99c                	sd	a5,16(a1)
}
    80003e3a:	6422                	ld	s0,8(sp)
    80003e3c:	0141                	addi	sp,sp,16
    80003e3e:	8082                	ret

0000000080003e40 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e40:	457c                	lw	a5,76(a0)
    80003e42:	0ed7e963          	bltu	a5,a3,80003f34 <readi+0xf4>
{
    80003e46:	7159                	addi	sp,sp,-112
    80003e48:	f486                	sd	ra,104(sp)
    80003e4a:	f0a2                	sd	s0,96(sp)
    80003e4c:	eca6                	sd	s1,88(sp)
    80003e4e:	e8ca                	sd	s2,80(sp)
    80003e50:	e4ce                	sd	s3,72(sp)
    80003e52:	e0d2                	sd	s4,64(sp)
    80003e54:	fc56                	sd	s5,56(sp)
    80003e56:	f85a                	sd	s6,48(sp)
    80003e58:	f45e                	sd	s7,40(sp)
    80003e5a:	f062                	sd	s8,32(sp)
    80003e5c:	ec66                	sd	s9,24(sp)
    80003e5e:	e86a                	sd	s10,16(sp)
    80003e60:	e46e                	sd	s11,8(sp)
    80003e62:	1880                	addi	s0,sp,112
    80003e64:	8b2a                	mv	s6,a0
    80003e66:	8bae                	mv	s7,a1
    80003e68:	8a32                	mv	s4,a2
    80003e6a:	84b6                	mv	s1,a3
    80003e6c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e6e:	9f35                	addw	a4,a4,a3
    return 0;
    80003e70:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e72:	0ad76063          	bltu	a4,a3,80003f12 <readi+0xd2>
  if(off + n > ip->size)
    80003e76:	00e7f463          	bgeu	a5,a4,80003e7e <readi+0x3e>
    n = ip->size - off;
    80003e7a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e7e:	0a0a8963          	beqz	s5,80003f30 <readi+0xf0>
    80003e82:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e84:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e88:	5c7d                	li	s8,-1
    80003e8a:	a82d                	j	80003ec4 <readi+0x84>
    80003e8c:	020d1d93          	slli	s11,s10,0x20
    80003e90:	020ddd93          	srli	s11,s11,0x20
    80003e94:	05890613          	addi	a2,s2,88
    80003e98:	86ee                	mv	a3,s11
    80003e9a:	963a                	add	a2,a2,a4
    80003e9c:	85d2                	mv	a1,s4
    80003e9e:	855e                	mv	a0,s7
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	87a080e7          	jalr	-1926(ra) # 8000271a <either_copyout>
    80003ea8:	05850d63          	beq	a0,s8,80003f02 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eac:	854a                	mv	a0,s2
    80003eae:	fffff097          	auipc	ra,0xfffff
    80003eb2:	5f6080e7          	jalr	1526(ra) # 800034a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eb6:	013d09bb          	addw	s3,s10,s3
    80003eba:	009d04bb          	addw	s1,s10,s1
    80003ebe:	9a6e                	add	s4,s4,s11
    80003ec0:	0559f763          	bgeu	s3,s5,80003f0e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ec4:	00a4d59b          	srliw	a1,s1,0xa
    80003ec8:	855a                	mv	a0,s6
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	89e080e7          	jalr	-1890(ra) # 80003768 <bmap>
    80003ed2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ed6:	cd85                	beqz	a1,80003f0e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ed8:	000b2503          	lw	a0,0(s6)
    80003edc:	fffff097          	auipc	ra,0xfffff
    80003ee0:	498080e7          	jalr	1176(ra) # 80003374 <bread>
    80003ee4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ee6:	3ff4f713          	andi	a4,s1,1023
    80003eea:	40ec87bb          	subw	a5,s9,a4
    80003eee:	413a86bb          	subw	a3,s5,s3
    80003ef2:	8d3e                	mv	s10,a5
    80003ef4:	2781                	sext.w	a5,a5
    80003ef6:	0006861b          	sext.w	a2,a3
    80003efa:	f8f679e3          	bgeu	a2,a5,80003e8c <readi+0x4c>
    80003efe:	8d36                	mv	s10,a3
    80003f00:	b771                	j	80003e8c <readi+0x4c>
      brelse(bp);
    80003f02:	854a                	mv	a0,s2
    80003f04:	fffff097          	auipc	ra,0xfffff
    80003f08:	5a0080e7          	jalr	1440(ra) # 800034a4 <brelse>
      tot = -1;
    80003f0c:	59fd                	li	s3,-1
  }
  return tot;
    80003f0e:	0009851b          	sext.w	a0,s3
}
    80003f12:	70a6                	ld	ra,104(sp)
    80003f14:	7406                	ld	s0,96(sp)
    80003f16:	64e6                	ld	s1,88(sp)
    80003f18:	6946                	ld	s2,80(sp)
    80003f1a:	69a6                	ld	s3,72(sp)
    80003f1c:	6a06                	ld	s4,64(sp)
    80003f1e:	7ae2                	ld	s5,56(sp)
    80003f20:	7b42                	ld	s6,48(sp)
    80003f22:	7ba2                	ld	s7,40(sp)
    80003f24:	7c02                	ld	s8,32(sp)
    80003f26:	6ce2                	ld	s9,24(sp)
    80003f28:	6d42                	ld	s10,16(sp)
    80003f2a:	6da2                	ld	s11,8(sp)
    80003f2c:	6165                	addi	sp,sp,112
    80003f2e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f30:	89d6                	mv	s3,s5
    80003f32:	bff1                	j	80003f0e <readi+0xce>
    return 0;
    80003f34:	4501                	li	a0,0
}
    80003f36:	8082                	ret

0000000080003f38 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f38:	457c                	lw	a5,76(a0)
    80003f3a:	10d7e863          	bltu	a5,a3,8000404a <writei+0x112>
{
    80003f3e:	7159                	addi	sp,sp,-112
    80003f40:	f486                	sd	ra,104(sp)
    80003f42:	f0a2                	sd	s0,96(sp)
    80003f44:	eca6                	sd	s1,88(sp)
    80003f46:	e8ca                	sd	s2,80(sp)
    80003f48:	e4ce                	sd	s3,72(sp)
    80003f4a:	e0d2                	sd	s4,64(sp)
    80003f4c:	fc56                	sd	s5,56(sp)
    80003f4e:	f85a                	sd	s6,48(sp)
    80003f50:	f45e                	sd	s7,40(sp)
    80003f52:	f062                	sd	s8,32(sp)
    80003f54:	ec66                	sd	s9,24(sp)
    80003f56:	e86a                	sd	s10,16(sp)
    80003f58:	e46e                	sd	s11,8(sp)
    80003f5a:	1880                	addi	s0,sp,112
    80003f5c:	8aaa                	mv	s5,a0
    80003f5e:	8bae                	mv	s7,a1
    80003f60:	8a32                	mv	s4,a2
    80003f62:	8936                	mv	s2,a3
    80003f64:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f66:	00e687bb          	addw	a5,a3,a4
    80003f6a:	0ed7e263          	bltu	a5,a3,8000404e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f6e:	00043737          	lui	a4,0x43
    80003f72:	0ef76063          	bltu	a4,a5,80004052 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f76:	0c0b0863          	beqz	s6,80004046 <writei+0x10e>
    80003f7a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f7c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f80:	5c7d                	li	s8,-1
    80003f82:	a091                	j	80003fc6 <writei+0x8e>
    80003f84:	020d1d93          	slli	s11,s10,0x20
    80003f88:	020ddd93          	srli	s11,s11,0x20
    80003f8c:	05848513          	addi	a0,s1,88
    80003f90:	86ee                	mv	a3,s11
    80003f92:	8652                	mv	a2,s4
    80003f94:	85de                	mv	a1,s7
    80003f96:	953a                	add	a0,a0,a4
    80003f98:	ffffe097          	auipc	ra,0xffffe
    80003f9c:	7d8080e7          	jalr	2008(ra) # 80002770 <either_copyin>
    80003fa0:	07850263          	beq	a0,s8,80004004 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	788080e7          	jalr	1928(ra) # 8000472e <log_write>
    brelse(bp);
    80003fae:	8526                	mv	a0,s1
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	4f4080e7          	jalr	1268(ra) # 800034a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fb8:	013d09bb          	addw	s3,s10,s3
    80003fbc:	012d093b          	addw	s2,s10,s2
    80003fc0:	9a6e                	add	s4,s4,s11
    80003fc2:	0569f663          	bgeu	s3,s6,8000400e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003fc6:	00a9559b          	srliw	a1,s2,0xa
    80003fca:	8556                	mv	a0,s5
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	79c080e7          	jalr	1948(ra) # 80003768 <bmap>
    80003fd4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fd8:	c99d                	beqz	a1,8000400e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003fda:	000aa503          	lw	a0,0(s5)
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	396080e7          	jalr	918(ra) # 80003374 <bread>
    80003fe6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe8:	3ff97713          	andi	a4,s2,1023
    80003fec:	40ec87bb          	subw	a5,s9,a4
    80003ff0:	413b06bb          	subw	a3,s6,s3
    80003ff4:	8d3e                	mv	s10,a5
    80003ff6:	2781                	sext.w	a5,a5
    80003ff8:	0006861b          	sext.w	a2,a3
    80003ffc:	f8f674e3          	bgeu	a2,a5,80003f84 <writei+0x4c>
    80004000:	8d36                	mv	s10,a3
    80004002:	b749                	j	80003f84 <writei+0x4c>
      brelse(bp);
    80004004:	8526                	mv	a0,s1
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	49e080e7          	jalr	1182(ra) # 800034a4 <brelse>
  }

  if(off > ip->size)
    8000400e:	04caa783          	lw	a5,76(s5)
    80004012:	0127f463          	bgeu	a5,s2,8000401a <writei+0xe2>
    ip->size = off;
    80004016:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000401a:	8556                	mv	a0,s5
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	aa4080e7          	jalr	-1372(ra) # 80003ac0 <iupdate>

  return tot;
    80004024:	0009851b          	sext.w	a0,s3
}
    80004028:	70a6                	ld	ra,104(sp)
    8000402a:	7406                	ld	s0,96(sp)
    8000402c:	64e6                	ld	s1,88(sp)
    8000402e:	6946                	ld	s2,80(sp)
    80004030:	69a6                	ld	s3,72(sp)
    80004032:	6a06                	ld	s4,64(sp)
    80004034:	7ae2                	ld	s5,56(sp)
    80004036:	7b42                	ld	s6,48(sp)
    80004038:	7ba2                	ld	s7,40(sp)
    8000403a:	7c02                	ld	s8,32(sp)
    8000403c:	6ce2                	ld	s9,24(sp)
    8000403e:	6d42                	ld	s10,16(sp)
    80004040:	6da2                	ld	s11,8(sp)
    80004042:	6165                	addi	sp,sp,112
    80004044:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004046:	89da                	mv	s3,s6
    80004048:	bfc9                	j	8000401a <writei+0xe2>
    return -1;
    8000404a:	557d                	li	a0,-1
}
    8000404c:	8082                	ret
    return -1;
    8000404e:	557d                	li	a0,-1
    80004050:	bfe1                	j	80004028 <writei+0xf0>
    return -1;
    80004052:	557d                	li	a0,-1
    80004054:	bfd1                	j	80004028 <writei+0xf0>

0000000080004056 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004056:	1141                	addi	sp,sp,-16
    80004058:	e406                	sd	ra,8(sp)
    8000405a:	e022                	sd	s0,0(sp)
    8000405c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000405e:	4639                	li	a2,14
    80004060:	ffffd097          	auipc	ra,0xffffd
    80004064:	d42080e7          	jalr	-702(ra) # 80000da2 <strncmp>
}
    80004068:	60a2                	ld	ra,8(sp)
    8000406a:	6402                	ld	s0,0(sp)
    8000406c:	0141                	addi	sp,sp,16
    8000406e:	8082                	ret

0000000080004070 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004070:	7139                	addi	sp,sp,-64
    80004072:	fc06                	sd	ra,56(sp)
    80004074:	f822                	sd	s0,48(sp)
    80004076:	f426                	sd	s1,40(sp)
    80004078:	f04a                	sd	s2,32(sp)
    8000407a:	ec4e                	sd	s3,24(sp)
    8000407c:	e852                	sd	s4,16(sp)
    8000407e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004080:	04451703          	lh	a4,68(a0)
    80004084:	4785                	li	a5,1
    80004086:	00f71a63          	bne	a4,a5,8000409a <dirlookup+0x2a>
    8000408a:	892a                	mv	s2,a0
    8000408c:	89ae                	mv	s3,a1
    8000408e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004090:	457c                	lw	a5,76(a0)
    80004092:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004094:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004096:	e79d                	bnez	a5,800040c4 <dirlookup+0x54>
    80004098:	a8a5                	j	80004110 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000409a:	00004517          	auipc	a0,0x4
    8000409e:	66650513          	addi	a0,a0,1638 # 80008700 <syscalls+0x2b0>
    800040a2:	ffffc097          	auipc	ra,0xffffc
    800040a6:	49e080e7          	jalr	1182(ra) # 80000540 <panic>
      panic("dirlookup read");
    800040aa:	00004517          	auipc	a0,0x4
    800040ae:	66e50513          	addi	a0,a0,1646 # 80008718 <syscalls+0x2c8>
    800040b2:	ffffc097          	auipc	ra,0xffffc
    800040b6:	48e080e7          	jalr	1166(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ba:	24c1                	addiw	s1,s1,16
    800040bc:	04c92783          	lw	a5,76(s2)
    800040c0:	04f4f763          	bgeu	s1,a5,8000410e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c4:	4741                	li	a4,16
    800040c6:	86a6                	mv	a3,s1
    800040c8:	fc040613          	addi	a2,s0,-64
    800040cc:	4581                	li	a1,0
    800040ce:	854a                	mv	a0,s2
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	d70080e7          	jalr	-656(ra) # 80003e40 <readi>
    800040d8:	47c1                	li	a5,16
    800040da:	fcf518e3          	bne	a0,a5,800040aa <dirlookup+0x3a>
    if(de.inum == 0)
    800040de:	fc045783          	lhu	a5,-64(s0)
    800040e2:	dfe1                	beqz	a5,800040ba <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040e4:	fc240593          	addi	a1,s0,-62
    800040e8:	854e                	mv	a0,s3
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	f6c080e7          	jalr	-148(ra) # 80004056 <namecmp>
    800040f2:	f561                	bnez	a0,800040ba <dirlookup+0x4a>
      if(poff)
    800040f4:	000a0463          	beqz	s4,800040fc <dirlookup+0x8c>
        *poff = off;
    800040f8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040fc:	fc045583          	lhu	a1,-64(s0)
    80004100:	00092503          	lw	a0,0(s2)
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	74e080e7          	jalr	1870(ra) # 80003852 <iget>
    8000410c:	a011                	j	80004110 <dirlookup+0xa0>
  return 0;
    8000410e:	4501                	li	a0,0
}
    80004110:	70e2                	ld	ra,56(sp)
    80004112:	7442                	ld	s0,48(sp)
    80004114:	74a2                	ld	s1,40(sp)
    80004116:	7902                	ld	s2,32(sp)
    80004118:	69e2                	ld	s3,24(sp)
    8000411a:	6a42                	ld	s4,16(sp)
    8000411c:	6121                	addi	sp,sp,64
    8000411e:	8082                	ret

0000000080004120 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004120:	711d                	addi	sp,sp,-96
    80004122:	ec86                	sd	ra,88(sp)
    80004124:	e8a2                	sd	s0,80(sp)
    80004126:	e4a6                	sd	s1,72(sp)
    80004128:	e0ca                	sd	s2,64(sp)
    8000412a:	fc4e                	sd	s3,56(sp)
    8000412c:	f852                	sd	s4,48(sp)
    8000412e:	f456                	sd	s5,40(sp)
    80004130:	f05a                	sd	s6,32(sp)
    80004132:	ec5e                	sd	s7,24(sp)
    80004134:	e862                	sd	s8,16(sp)
    80004136:	e466                	sd	s9,8(sp)
    80004138:	e06a                	sd	s10,0(sp)
    8000413a:	1080                	addi	s0,sp,96
    8000413c:	84aa                	mv	s1,a0
    8000413e:	8b2e                	mv	s6,a1
    80004140:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004142:	00054703          	lbu	a4,0(a0)
    80004146:	02f00793          	li	a5,47
    8000414a:	02f70363          	beq	a4,a5,80004170 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000414e:	ffffe097          	auipc	ra,0xffffe
    80004152:	85e080e7          	jalr	-1954(ra) # 800019ac <myproc>
    80004156:	15053503          	ld	a0,336(a0)
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	9f4080e7          	jalr	-1548(ra) # 80003b4e <idup>
    80004162:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004164:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004168:	4cb5                	li	s9,13
  len = path - s;
    8000416a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000416c:	4c05                	li	s8,1
    8000416e:	a87d                	j	8000422c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004170:	4585                	li	a1,1
    80004172:	4505                	li	a0,1
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	6de080e7          	jalr	1758(ra) # 80003852 <iget>
    8000417c:	8a2a                	mv	s4,a0
    8000417e:	b7dd                	j	80004164 <namex+0x44>
      iunlockput(ip);
    80004180:	8552                	mv	a0,s4
    80004182:	00000097          	auipc	ra,0x0
    80004186:	c6c080e7          	jalr	-916(ra) # 80003dee <iunlockput>
      return 0;
    8000418a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000418c:	8552                	mv	a0,s4
    8000418e:	60e6                	ld	ra,88(sp)
    80004190:	6446                	ld	s0,80(sp)
    80004192:	64a6                	ld	s1,72(sp)
    80004194:	6906                	ld	s2,64(sp)
    80004196:	79e2                	ld	s3,56(sp)
    80004198:	7a42                	ld	s4,48(sp)
    8000419a:	7aa2                	ld	s5,40(sp)
    8000419c:	7b02                	ld	s6,32(sp)
    8000419e:	6be2                	ld	s7,24(sp)
    800041a0:	6c42                	ld	s8,16(sp)
    800041a2:	6ca2                	ld	s9,8(sp)
    800041a4:	6d02                	ld	s10,0(sp)
    800041a6:	6125                	addi	sp,sp,96
    800041a8:	8082                	ret
      iunlock(ip);
    800041aa:	8552                	mv	a0,s4
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	aa2080e7          	jalr	-1374(ra) # 80003c4e <iunlock>
      return ip;
    800041b4:	bfe1                	j	8000418c <namex+0x6c>
      iunlockput(ip);
    800041b6:	8552                	mv	a0,s4
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	c36080e7          	jalr	-970(ra) # 80003dee <iunlockput>
      return 0;
    800041c0:	8a4e                	mv	s4,s3
    800041c2:	b7e9                	j	8000418c <namex+0x6c>
  len = path - s;
    800041c4:	40998633          	sub	a2,s3,s1
    800041c8:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800041cc:	09acd863          	bge	s9,s10,8000425c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800041d0:	4639                	li	a2,14
    800041d2:	85a6                	mv	a1,s1
    800041d4:	8556                	mv	a0,s5
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	b58080e7          	jalr	-1192(ra) # 80000d2e <memmove>
    800041de:	84ce                	mv	s1,s3
  while(*path == '/')
    800041e0:	0004c783          	lbu	a5,0(s1)
    800041e4:	01279763          	bne	a5,s2,800041f2 <namex+0xd2>
    path++;
    800041e8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ea:	0004c783          	lbu	a5,0(s1)
    800041ee:	ff278de3          	beq	a5,s2,800041e8 <namex+0xc8>
    ilock(ip);
    800041f2:	8552                	mv	a0,s4
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	998080e7          	jalr	-1640(ra) # 80003b8c <ilock>
    if(ip->type != T_DIR){
    800041fc:	044a1783          	lh	a5,68(s4)
    80004200:	f98790e3          	bne	a5,s8,80004180 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004204:	000b0563          	beqz	s6,8000420e <namex+0xee>
    80004208:	0004c783          	lbu	a5,0(s1)
    8000420c:	dfd9                	beqz	a5,800041aa <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000420e:	865e                	mv	a2,s7
    80004210:	85d6                	mv	a1,s5
    80004212:	8552                	mv	a0,s4
    80004214:	00000097          	auipc	ra,0x0
    80004218:	e5c080e7          	jalr	-420(ra) # 80004070 <dirlookup>
    8000421c:	89aa                	mv	s3,a0
    8000421e:	dd41                	beqz	a0,800041b6 <namex+0x96>
    iunlockput(ip);
    80004220:	8552                	mv	a0,s4
    80004222:	00000097          	auipc	ra,0x0
    80004226:	bcc080e7          	jalr	-1076(ra) # 80003dee <iunlockput>
    ip = next;
    8000422a:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000422c:	0004c783          	lbu	a5,0(s1)
    80004230:	01279763          	bne	a5,s2,8000423e <namex+0x11e>
    path++;
    80004234:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004236:	0004c783          	lbu	a5,0(s1)
    8000423a:	ff278de3          	beq	a5,s2,80004234 <namex+0x114>
  if(*path == 0)
    8000423e:	cb9d                	beqz	a5,80004274 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004240:	0004c783          	lbu	a5,0(s1)
    80004244:	89a6                	mv	s3,s1
  len = path - s;
    80004246:	8d5e                	mv	s10,s7
    80004248:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000424a:	01278963          	beq	a5,s2,8000425c <namex+0x13c>
    8000424e:	dbbd                	beqz	a5,800041c4 <namex+0xa4>
    path++;
    80004250:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004252:	0009c783          	lbu	a5,0(s3)
    80004256:	ff279ce3          	bne	a5,s2,8000424e <namex+0x12e>
    8000425a:	b7ad                	j	800041c4 <namex+0xa4>
    memmove(name, s, len);
    8000425c:	2601                	sext.w	a2,a2
    8000425e:	85a6                	mv	a1,s1
    80004260:	8556                	mv	a0,s5
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	acc080e7          	jalr	-1332(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000426a:	9d56                	add	s10,s10,s5
    8000426c:	000d0023          	sb	zero,0(s10)
    80004270:	84ce                	mv	s1,s3
    80004272:	b7bd                	j	800041e0 <namex+0xc0>
  if(nameiparent){
    80004274:	f00b0ce3          	beqz	s6,8000418c <namex+0x6c>
    iput(ip);
    80004278:	8552                	mv	a0,s4
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	acc080e7          	jalr	-1332(ra) # 80003d46 <iput>
    return 0;
    80004282:	4a01                	li	s4,0
    80004284:	b721                	j	8000418c <namex+0x6c>

0000000080004286 <dirlink>:
{
    80004286:	7139                	addi	sp,sp,-64
    80004288:	fc06                	sd	ra,56(sp)
    8000428a:	f822                	sd	s0,48(sp)
    8000428c:	f426                	sd	s1,40(sp)
    8000428e:	f04a                	sd	s2,32(sp)
    80004290:	ec4e                	sd	s3,24(sp)
    80004292:	e852                	sd	s4,16(sp)
    80004294:	0080                	addi	s0,sp,64
    80004296:	892a                	mv	s2,a0
    80004298:	8a2e                	mv	s4,a1
    8000429a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000429c:	4601                	li	a2,0
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	dd2080e7          	jalr	-558(ra) # 80004070 <dirlookup>
    800042a6:	e93d                	bnez	a0,8000431c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a8:	04c92483          	lw	s1,76(s2)
    800042ac:	c49d                	beqz	s1,800042da <dirlink+0x54>
    800042ae:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b0:	4741                	li	a4,16
    800042b2:	86a6                	mv	a3,s1
    800042b4:	fc040613          	addi	a2,s0,-64
    800042b8:	4581                	li	a1,0
    800042ba:	854a                	mv	a0,s2
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	b84080e7          	jalr	-1148(ra) # 80003e40 <readi>
    800042c4:	47c1                	li	a5,16
    800042c6:	06f51163          	bne	a0,a5,80004328 <dirlink+0xa2>
    if(de.inum == 0)
    800042ca:	fc045783          	lhu	a5,-64(s0)
    800042ce:	c791                	beqz	a5,800042da <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d0:	24c1                	addiw	s1,s1,16
    800042d2:	04c92783          	lw	a5,76(s2)
    800042d6:	fcf4ede3          	bltu	s1,a5,800042b0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042da:	4639                	li	a2,14
    800042dc:	85d2                	mv	a1,s4
    800042de:	fc240513          	addi	a0,s0,-62
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	afc080e7          	jalr	-1284(ra) # 80000dde <strncpy>
  de.inum = inum;
    800042ea:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ee:	4741                	li	a4,16
    800042f0:	86a6                	mv	a3,s1
    800042f2:	fc040613          	addi	a2,s0,-64
    800042f6:	4581                	li	a1,0
    800042f8:	854a                	mv	a0,s2
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	c3e080e7          	jalr	-962(ra) # 80003f38 <writei>
    80004302:	1541                	addi	a0,a0,-16
    80004304:	00a03533          	snez	a0,a0
    80004308:	40a00533          	neg	a0,a0
}
    8000430c:	70e2                	ld	ra,56(sp)
    8000430e:	7442                	ld	s0,48(sp)
    80004310:	74a2                	ld	s1,40(sp)
    80004312:	7902                	ld	s2,32(sp)
    80004314:	69e2                	ld	s3,24(sp)
    80004316:	6a42                	ld	s4,16(sp)
    80004318:	6121                	addi	sp,sp,64
    8000431a:	8082                	ret
    iput(ip);
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	a2a080e7          	jalr	-1494(ra) # 80003d46 <iput>
    return -1;
    80004324:	557d                	li	a0,-1
    80004326:	b7dd                	j	8000430c <dirlink+0x86>
      panic("dirlink read");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	40050513          	addi	a0,a0,1024 # 80008728 <syscalls+0x2d8>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	210080e7          	jalr	528(ra) # 80000540 <panic>

0000000080004338 <namei>:

struct inode*
namei(char *path)
{
    80004338:	1101                	addi	sp,sp,-32
    8000433a:	ec06                	sd	ra,24(sp)
    8000433c:	e822                	sd	s0,16(sp)
    8000433e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004340:	fe040613          	addi	a2,s0,-32
    80004344:	4581                	li	a1,0
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	dda080e7          	jalr	-550(ra) # 80004120 <namex>
}
    8000434e:	60e2                	ld	ra,24(sp)
    80004350:	6442                	ld	s0,16(sp)
    80004352:	6105                	addi	sp,sp,32
    80004354:	8082                	ret

0000000080004356 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004356:	1141                	addi	sp,sp,-16
    80004358:	e406                	sd	ra,8(sp)
    8000435a:	e022                	sd	s0,0(sp)
    8000435c:	0800                	addi	s0,sp,16
    8000435e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004360:	4585                	li	a1,1
    80004362:	00000097          	auipc	ra,0x0
    80004366:	dbe080e7          	jalr	-578(ra) # 80004120 <namex>
}
    8000436a:	60a2                	ld	ra,8(sp)
    8000436c:	6402                	ld	s0,0(sp)
    8000436e:	0141                	addi	sp,sp,16
    80004370:	8082                	ret

0000000080004372 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	e04a                	sd	s2,0(sp)
    8000437c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000437e:	0001d917          	auipc	s2,0x1d
    80004382:	67290913          	addi	s2,s2,1650 # 800219f0 <log>
    80004386:	01892583          	lw	a1,24(s2)
    8000438a:	02892503          	lw	a0,40(s2)
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	fe6080e7          	jalr	-26(ra) # 80003374 <bread>
    80004396:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004398:	02c92683          	lw	a3,44(s2)
    8000439c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000439e:	02d05863          	blez	a3,800043ce <write_head+0x5c>
    800043a2:	0001d797          	auipc	a5,0x1d
    800043a6:	67e78793          	addi	a5,a5,1662 # 80021a20 <log+0x30>
    800043aa:	05c50713          	addi	a4,a0,92
    800043ae:	36fd                	addiw	a3,a3,-1
    800043b0:	02069613          	slli	a2,a3,0x20
    800043b4:	01e65693          	srli	a3,a2,0x1e
    800043b8:	0001d617          	auipc	a2,0x1d
    800043bc:	66c60613          	addi	a2,a2,1644 # 80021a24 <log+0x34>
    800043c0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043c2:	4390                	lw	a2,0(a5)
    800043c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043c6:	0791                	addi	a5,a5,4
    800043c8:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800043ca:	fed79ce3          	bne	a5,a3,800043c2 <write_head+0x50>
  }
  bwrite(buf);
    800043ce:	8526                	mv	a0,s1
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	096080e7          	jalr	150(ra) # 80003466 <bwrite>
  brelse(buf);
    800043d8:	8526                	mv	a0,s1
    800043da:	fffff097          	auipc	ra,0xfffff
    800043de:	0ca080e7          	jalr	202(ra) # 800034a4 <brelse>
}
    800043e2:	60e2                	ld	ra,24(sp)
    800043e4:	6442                	ld	s0,16(sp)
    800043e6:	64a2                	ld	s1,8(sp)
    800043e8:	6902                	ld	s2,0(sp)
    800043ea:	6105                	addi	sp,sp,32
    800043ec:	8082                	ret

00000000800043ee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ee:	0001d797          	auipc	a5,0x1d
    800043f2:	62e7a783          	lw	a5,1582(a5) # 80021a1c <log+0x2c>
    800043f6:	0af05d63          	blez	a5,800044b0 <install_trans+0xc2>
{
    800043fa:	7139                	addi	sp,sp,-64
    800043fc:	fc06                	sd	ra,56(sp)
    800043fe:	f822                	sd	s0,48(sp)
    80004400:	f426                	sd	s1,40(sp)
    80004402:	f04a                	sd	s2,32(sp)
    80004404:	ec4e                	sd	s3,24(sp)
    80004406:	e852                	sd	s4,16(sp)
    80004408:	e456                	sd	s5,8(sp)
    8000440a:	e05a                	sd	s6,0(sp)
    8000440c:	0080                	addi	s0,sp,64
    8000440e:	8b2a                	mv	s6,a0
    80004410:	0001da97          	auipc	s5,0x1d
    80004414:	610a8a93          	addi	s5,s5,1552 # 80021a20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004418:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000441a:	0001d997          	auipc	s3,0x1d
    8000441e:	5d698993          	addi	s3,s3,1494 # 800219f0 <log>
    80004422:	a00d                	j	80004444 <install_trans+0x56>
    brelse(lbuf);
    80004424:	854a                	mv	a0,s2
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	07e080e7          	jalr	126(ra) # 800034a4 <brelse>
    brelse(dbuf);
    8000442e:	8526                	mv	a0,s1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	074080e7          	jalr	116(ra) # 800034a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004438:	2a05                	addiw	s4,s4,1
    8000443a:	0a91                	addi	s5,s5,4
    8000443c:	02c9a783          	lw	a5,44(s3)
    80004440:	04fa5e63          	bge	s4,a5,8000449c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004444:	0189a583          	lw	a1,24(s3)
    80004448:	014585bb          	addw	a1,a1,s4
    8000444c:	2585                	addiw	a1,a1,1
    8000444e:	0289a503          	lw	a0,40(s3)
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	f22080e7          	jalr	-222(ra) # 80003374 <bread>
    8000445a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000445c:	000aa583          	lw	a1,0(s5)
    80004460:	0289a503          	lw	a0,40(s3)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	f10080e7          	jalr	-240(ra) # 80003374 <bread>
    8000446c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000446e:	40000613          	li	a2,1024
    80004472:	05890593          	addi	a1,s2,88
    80004476:	05850513          	addi	a0,a0,88
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	8b4080e7          	jalr	-1868(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004482:	8526                	mv	a0,s1
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	fe2080e7          	jalr	-30(ra) # 80003466 <bwrite>
    if(recovering == 0)
    8000448c:	f80b1ce3          	bnez	s6,80004424 <install_trans+0x36>
      bunpin(dbuf);
    80004490:	8526                	mv	a0,s1
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	0ec080e7          	jalr	236(ra) # 8000357e <bunpin>
    8000449a:	b769                	j	80004424 <install_trans+0x36>
}
    8000449c:	70e2                	ld	ra,56(sp)
    8000449e:	7442                	ld	s0,48(sp)
    800044a0:	74a2                	ld	s1,40(sp)
    800044a2:	7902                	ld	s2,32(sp)
    800044a4:	69e2                	ld	s3,24(sp)
    800044a6:	6a42                	ld	s4,16(sp)
    800044a8:	6aa2                	ld	s5,8(sp)
    800044aa:	6b02                	ld	s6,0(sp)
    800044ac:	6121                	addi	sp,sp,64
    800044ae:	8082                	ret
    800044b0:	8082                	ret

00000000800044b2 <initlog>:
{
    800044b2:	7179                	addi	sp,sp,-48
    800044b4:	f406                	sd	ra,40(sp)
    800044b6:	f022                	sd	s0,32(sp)
    800044b8:	ec26                	sd	s1,24(sp)
    800044ba:	e84a                	sd	s2,16(sp)
    800044bc:	e44e                	sd	s3,8(sp)
    800044be:	1800                	addi	s0,sp,48
    800044c0:	892a                	mv	s2,a0
    800044c2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044c4:	0001d497          	auipc	s1,0x1d
    800044c8:	52c48493          	addi	s1,s1,1324 # 800219f0 <log>
    800044cc:	00004597          	auipc	a1,0x4
    800044d0:	26c58593          	addi	a1,a1,620 # 80008738 <syscalls+0x2e8>
    800044d4:	8526                	mv	a0,s1
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	670080e7          	jalr	1648(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800044de:	0149a583          	lw	a1,20(s3)
    800044e2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044e4:	0109a783          	lw	a5,16(s3)
    800044e8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044ea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044ee:	854a                	mv	a0,s2
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	e84080e7          	jalr	-380(ra) # 80003374 <bread>
  log.lh.n = lh->n;
    800044f8:	4d34                	lw	a3,88(a0)
    800044fa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044fc:	02d05663          	blez	a3,80004528 <initlog+0x76>
    80004500:	05c50793          	addi	a5,a0,92
    80004504:	0001d717          	auipc	a4,0x1d
    80004508:	51c70713          	addi	a4,a4,1308 # 80021a20 <log+0x30>
    8000450c:	36fd                	addiw	a3,a3,-1
    8000450e:	02069613          	slli	a2,a3,0x20
    80004512:	01e65693          	srli	a3,a2,0x1e
    80004516:	06050613          	addi	a2,a0,96
    8000451a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000451c:	4390                	lw	a2,0(a5)
    8000451e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004520:	0791                	addi	a5,a5,4
    80004522:	0711                	addi	a4,a4,4
    80004524:	fed79ce3          	bne	a5,a3,8000451c <initlog+0x6a>
  brelse(buf);
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	f7c080e7          	jalr	-132(ra) # 800034a4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004530:	4505                	li	a0,1
    80004532:	00000097          	auipc	ra,0x0
    80004536:	ebc080e7          	jalr	-324(ra) # 800043ee <install_trans>
  log.lh.n = 0;
    8000453a:	0001d797          	auipc	a5,0x1d
    8000453e:	4e07a123          	sw	zero,1250(a5) # 80021a1c <log+0x2c>
  write_head(); // clear the log
    80004542:	00000097          	auipc	ra,0x0
    80004546:	e30080e7          	jalr	-464(ra) # 80004372 <write_head>
}
    8000454a:	70a2                	ld	ra,40(sp)
    8000454c:	7402                	ld	s0,32(sp)
    8000454e:	64e2                	ld	s1,24(sp)
    80004550:	6942                	ld	s2,16(sp)
    80004552:	69a2                	ld	s3,8(sp)
    80004554:	6145                	addi	sp,sp,48
    80004556:	8082                	ret

0000000080004558 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004558:	1101                	addi	sp,sp,-32
    8000455a:	ec06                	sd	ra,24(sp)
    8000455c:	e822                	sd	s0,16(sp)
    8000455e:	e426                	sd	s1,8(sp)
    80004560:	e04a                	sd	s2,0(sp)
    80004562:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004564:	0001d517          	auipc	a0,0x1d
    80004568:	48c50513          	addi	a0,a0,1164 # 800219f0 <log>
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	66a080e7          	jalr	1642(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004574:	0001d497          	auipc	s1,0x1d
    80004578:	47c48493          	addi	s1,s1,1148 # 800219f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000457c:	4979                	li	s2,30
    8000457e:	a039                	j	8000458c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004580:	85a6                	mv	a1,s1
    80004582:	8526                	mv	a0,s1
    80004584:	ffffe097          	auipc	ra,0xffffe
    80004588:	d82080e7          	jalr	-638(ra) # 80002306 <sleep>
    if(log.committing){
    8000458c:	50dc                	lw	a5,36(s1)
    8000458e:	fbed                	bnez	a5,80004580 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004590:	5098                	lw	a4,32(s1)
    80004592:	2705                	addiw	a4,a4,1
    80004594:	0007069b          	sext.w	a3,a4
    80004598:	0027179b          	slliw	a5,a4,0x2
    8000459c:	9fb9                	addw	a5,a5,a4
    8000459e:	0017979b          	slliw	a5,a5,0x1
    800045a2:	54d8                	lw	a4,44(s1)
    800045a4:	9fb9                	addw	a5,a5,a4
    800045a6:	00f95963          	bge	s2,a5,800045b8 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045aa:	85a6                	mv	a1,s1
    800045ac:	8526                	mv	a0,s1
    800045ae:	ffffe097          	auipc	ra,0xffffe
    800045b2:	d58080e7          	jalr	-680(ra) # 80002306 <sleep>
    800045b6:	bfd9                	j	8000458c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045b8:	0001d517          	auipc	a0,0x1d
    800045bc:	43850513          	addi	a0,a0,1080 # 800219f0 <log>
    800045c0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	6c8080e7          	jalr	1736(ra) # 80000c8a <release>
      break;
    }
  }
}
    800045ca:	60e2                	ld	ra,24(sp)
    800045cc:	6442                	ld	s0,16(sp)
    800045ce:	64a2                	ld	s1,8(sp)
    800045d0:	6902                	ld	s2,0(sp)
    800045d2:	6105                	addi	sp,sp,32
    800045d4:	8082                	ret

00000000800045d6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045d6:	7139                	addi	sp,sp,-64
    800045d8:	fc06                	sd	ra,56(sp)
    800045da:	f822                	sd	s0,48(sp)
    800045dc:	f426                	sd	s1,40(sp)
    800045de:	f04a                	sd	s2,32(sp)
    800045e0:	ec4e                	sd	s3,24(sp)
    800045e2:	e852                	sd	s4,16(sp)
    800045e4:	e456                	sd	s5,8(sp)
    800045e6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045e8:	0001d497          	auipc	s1,0x1d
    800045ec:	40848493          	addi	s1,s1,1032 # 800219f0 <log>
    800045f0:	8526                	mv	a0,s1
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800045fa:	509c                	lw	a5,32(s1)
    800045fc:	37fd                	addiw	a5,a5,-1
    800045fe:	0007891b          	sext.w	s2,a5
    80004602:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004604:	50dc                	lw	a5,36(s1)
    80004606:	e7b9                	bnez	a5,80004654 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004608:	04091e63          	bnez	s2,80004664 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000460c:	0001d497          	auipc	s1,0x1d
    80004610:	3e448493          	addi	s1,s1,996 # 800219f0 <log>
    80004614:	4785                	li	a5,1
    80004616:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004618:	8526                	mv	a0,s1
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	670080e7          	jalr	1648(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004622:	54dc                	lw	a5,44(s1)
    80004624:	06f04763          	bgtz	a5,80004692 <end_op+0xbc>
    acquire(&log.lock);
    80004628:	0001d497          	auipc	s1,0x1d
    8000462c:	3c848493          	addi	s1,s1,968 # 800219f0 <log>
    80004630:	8526                	mv	a0,s1
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	5a4080e7          	jalr	1444(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000463a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000463e:	8526                	mv	a0,s1
    80004640:	ffffe097          	auipc	ra,0xffffe
    80004644:	d2a080e7          	jalr	-726(ra) # 8000236a <wakeup>
    release(&log.lock);
    80004648:	8526                	mv	a0,s1
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	640080e7          	jalr	1600(ra) # 80000c8a <release>
}
    80004652:	a03d                	j	80004680 <end_op+0xaa>
    panic("log.committing");
    80004654:	00004517          	auipc	a0,0x4
    80004658:	0ec50513          	addi	a0,a0,236 # 80008740 <syscalls+0x2f0>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	ee4080e7          	jalr	-284(ra) # 80000540 <panic>
    wakeup(&log);
    80004664:	0001d497          	auipc	s1,0x1d
    80004668:	38c48493          	addi	s1,s1,908 # 800219f0 <log>
    8000466c:	8526                	mv	a0,s1
    8000466e:	ffffe097          	auipc	ra,0xffffe
    80004672:	cfc080e7          	jalr	-772(ra) # 8000236a <wakeup>
  release(&log.lock);
    80004676:	8526                	mv	a0,s1
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	612080e7          	jalr	1554(ra) # 80000c8a <release>
}
    80004680:	70e2                	ld	ra,56(sp)
    80004682:	7442                	ld	s0,48(sp)
    80004684:	74a2                	ld	s1,40(sp)
    80004686:	7902                	ld	s2,32(sp)
    80004688:	69e2                	ld	s3,24(sp)
    8000468a:	6a42                	ld	s4,16(sp)
    8000468c:	6aa2                	ld	s5,8(sp)
    8000468e:	6121                	addi	sp,sp,64
    80004690:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004692:	0001da97          	auipc	s5,0x1d
    80004696:	38ea8a93          	addi	s5,s5,910 # 80021a20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000469a:	0001da17          	auipc	s4,0x1d
    8000469e:	356a0a13          	addi	s4,s4,854 # 800219f0 <log>
    800046a2:	018a2583          	lw	a1,24(s4)
    800046a6:	012585bb          	addw	a1,a1,s2
    800046aa:	2585                	addiw	a1,a1,1
    800046ac:	028a2503          	lw	a0,40(s4)
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	cc4080e7          	jalr	-828(ra) # 80003374 <bread>
    800046b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046ba:	000aa583          	lw	a1,0(s5)
    800046be:	028a2503          	lw	a0,40(s4)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	cb2080e7          	jalr	-846(ra) # 80003374 <bread>
    800046ca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046cc:	40000613          	li	a2,1024
    800046d0:	05850593          	addi	a1,a0,88
    800046d4:	05848513          	addi	a0,s1,88
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	656080e7          	jalr	1622(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800046e0:	8526                	mv	a0,s1
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	d84080e7          	jalr	-636(ra) # 80003466 <bwrite>
    brelse(from);
    800046ea:	854e                	mv	a0,s3
    800046ec:	fffff097          	auipc	ra,0xfffff
    800046f0:	db8080e7          	jalr	-584(ra) # 800034a4 <brelse>
    brelse(to);
    800046f4:	8526                	mv	a0,s1
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	dae080e7          	jalr	-594(ra) # 800034a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046fe:	2905                	addiw	s2,s2,1
    80004700:	0a91                	addi	s5,s5,4
    80004702:	02ca2783          	lw	a5,44(s4)
    80004706:	f8f94ee3          	blt	s2,a5,800046a2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	c68080e7          	jalr	-920(ra) # 80004372 <write_head>
    install_trans(0); // Now install writes to home locations
    80004712:	4501                	li	a0,0
    80004714:	00000097          	auipc	ra,0x0
    80004718:	cda080e7          	jalr	-806(ra) # 800043ee <install_trans>
    log.lh.n = 0;
    8000471c:	0001d797          	auipc	a5,0x1d
    80004720:	3007a023          	sw	zero,768(a5) # 80021a1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004724:	00000097          	auipc	ra,0x0
    80004728:	c4e080e7          	jalr	-946(ra) # 80004372 <write_head>
    8000472c:	bdf5                	j	80004628 <end_op+0x52>

000000008000472e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000472e:	1101                	addi	sp,sp,-32
    80004730:	ec06                	sd	ra,24(sp)
    80004732:	e822                	sd	s0,16(sp)
    80004734:	e426                	sd	s1,8(sp)
    80004736:	e04a                	sd	s2,0(sp)
    80004738:	1000                	addi	s0,sp,32
    8000473a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000473c:	0001d917          	auipc	s2,0x1d
    80004740:	2b490913          	addi	s2,s2,692 # 800219f0 <log>
    80004744:	854a                	mv	a0,s2
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	490080e7          	jalr	1168(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000474e:	02c92603          	lw	a2,44(s2)
    80004752:	47f5                	li	a5,29
    80004754:	06c7c563          	blt	a5,a2,800047be <log_write+0x90>
    80004758:	0001d797          	auipc	a5,0x1d
    8000475c:	2b47a783          	lw	a5,692(a5) # 80021a0c <log+0x1c>
    80004760:	37fd                	addiw	a5,a5,-1
    80004762:	04f65e63          	bge	a2,a5,800047be <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004766:	0001d797          	auipc	a5,0x1d
    8000476a:	2aa7a783          	lw	a5,682(a5) # 80021a10 <log+0x20>
    8000476e:	06f05063          	blez	a5,800047ce <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004772:	4781                	li	a5,0
    80004774:	06c05563          	blez	a2,800047de <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004778:	44cc                	lw	a1,12(s1)
    8000477a:	0001d717          	auipc	a4,0x1d
    8000477e:	2a670713          	addi	a4,a4,678 # 80021a20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004782:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004784:	4314                	lw	a3,0(a4)
    80004786:	04b68c63          	beq	a3,a1,800047de <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000478a:	2785                	addiw	a5,a5,1
    8000478c:	0711                	addi	a4,a4,4
    8000478e:	fef61be3          	bne	a2,a5,80004784 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004792:	0621                	addi	a2,a2,8
    80004794:	060a                	slli	a2,a2,0x2
    80004796:	0001d797          	auipc	a5,0x1d
    8000479a:	25a78793          	addi	a5,a5,602 # 800219f0 <log>
    8000479e:	97b2                	add	a5,a5,a2
    800047a0:	44d8                	lw	a4,12(s1)
    800047a2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047a4:	8526                	mv	a0,s1
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	d9c080e7          	jalr	-612(ra) # 80003542 <bpin>
    log.lh.n++;
    800047ae:	0001d717          	auipc	a4,0x1d
    800047b2:	24270713          	addi	a4,a4,578 # 800219f0 <log>
    800047b6:	575c                	lw	a5,44(a4)
    800047b8:	2785                	addiw	a5,a5,1
    800047ba:	d75c                	sw	a5,44(a4)
    800047bc:	a82d                	j	800047f6 <log_write+0xc8>
    panic("too big a transaction");
    800047be:	00004517          	auipc	a0,0x4
    800047c2:	f9250513          	addi	a0,a0,-110 # 80008750 <syscalls+0x300>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	d7a080e7          	jalr	-646(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800047ce:	00004517          	auipc	a0,0x4
    800047d2:	f9a50513          	addi	a0,a0,-102 # 80008768 <syscalls+0x318>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	d6a080e7          	jalr	-662(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800047de:	00878693          	addi	a3,a5,8
    800047e2:	068a                	slli	a3,a3,0x2
    800047e4:	0001d717          	auipc	a4,0x1d
    800047e8:	20c70713          	addi	a4,a4,524 # 800219f0 <log>
    800047ec:	9736                	add	a4,a4,a3
    800047ee:	44d4                	lw	a3,12(s1)
    800047f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047f2:	faf609e3          	beq	a2,a5,800047a4 <log_write+0x76>
  }
  release(&log.lock);
    800047f6:	0001d517          	auipc	a0,0x1d
    800047fa:	1fa50513          	addi	a0,a0,506 # 800219f0 <log>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	48c080e7          	jalr	1164(ra) # 80000c8a <release>
}
    80004806:	60e2                	ld	ra,24(sp)
    80004808:	6442                	ld	s0,16(sp)
    8000480a:	64a2                	ld	s1,8(sp)
    8000480c:	6902                	ld	s2,0(sp)
    8000480e:	6105                	addi	sp,sp,32
    80004810:	8082                	ret

0000000080004812 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004812:	1101                	addi	sp,sp,-32
    80004814:	ec06                	sd	ra,24(sp)
    80004816:	e822                	sd	s0,16(sp)
    80004818:	e426                	sd	s1,8(sp)
    8000481a:	e04a                	sd	s2,0(sp)
    8000481c:	1000                	addi	s0,sp,32
    8000481e:	84aa                	mv	s1,a0
    80004820:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004822:	00004597          	auipc	a1,0x4
    80004826:	f6658593          	addi	a1,a1,-154 # 80008788 <syscalls+0x338>
    8000482a:	0521                	addi	a0,a0,8
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	31a080e7          	jalr	794(ra) # 80000b46 <initlock>
  lk->name = name;
    80004834:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004838:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000483c:	0204a423          	sw	zero,40(s1)
}
    80004840:	60e2                	ld	ra,24(sp)
    80004842:	6442                	ld	s0,16(sp)
    80004844:	64a2                	ld	s1,8(sp)
    80004846:	6902                	ld	s2,0(sp)
    80004848:	6105                	addi	sp,sp,32
    8000484a:	8082                	ret

000000008000484c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000484c:	1101                	addi	sp,sp,-32
    8000484e:	ec06                	sd	ra,24(sp)
    80004850:	e822                	sd	s0,16(sp)
    80004852:	e426                	sd	s1,8(sp)
    80004854:	e04a                	sd	s2,0(sp)
    80004856:	1000                	addi	s0,sp,32
    80004858:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000485a:	00850913          	addi	s2,a0,8
    8000485e:	854a                	mv	a0,s2
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	376080e7          	jalr	886(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004868:	409c                	lw	a5,0(s1)
    8000486a:	cb89                	beqz	a5,8000487c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000486c:	85ca                	mv	a1,s2
    8000486e:	8526                	mv	a0,s1
    80004870:	ffffe097          	auipc	ra,0xffffe
    80004874:	a96080e7          	jalr	-1386(ra) # 80002306 <sleep>
  while (lk->locked) {
    80004878:	409c                	lw	a5,0(s1)
    8000487a:	fbed                	bnez	a5,8000486c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000487c:	4785                	li	a5,1
    8000487e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004880:	ffffd097          	auipc	ra,0xffffd
    80004884:	12c080e7          	jalr	300(ra) # 800019ac <myproc>
    80004888:	591c                	lw	a5,48(a0)
    8000488a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000488c:	854a                	mv	a0,s2
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	3fc080e7          	jalr	1020(ra) # 80000c8a <release>
}
    80004896:	60e2                	ld	ra,24(sp)
    80004898:	6442                	ld	s0,16(sp)
    8000489a:	64a2                	ld	s1,8(sp)
    8000489c:	6902                	ld	s2,0(sp)
    8000489e:	6105                	addi	sp,sp,32
    800048a0:	8082                	ret

00000000800048a2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048a2:	1101                	addi	sp,sp,-32
    800048a4:	ec06                	sd	ra,24(sp)
    800048a6:	e822                	sd	s0,16(sp)
    800048a8:	e426                	sd	s1,8(sp)
    800048aa:	e04a                	sd	s2,0(sp)
    800048ac:	1000                	addi	s0,sp,32
    800048ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048b0:	00850913          	addi	s2,a0,8
    800048b4:	854a                	mv	a0,s2
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	320080e7          	jalr	800(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800048be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048c2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048c6:	8526                	mv	a0,s1
    800048c8:	ffffe097          	auipc	ra,0xffffe
    800048cc:	aa2080e7          	jalr	-1374(ra) # 8000236a <wakeup>
  release(&lk->lk);
    800048d0:	854a                	mv	a0,s2
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	3b8080e7          	jalr	952(ra) # 80000c8a <release>
}
    800048da:	60e2                	ld	ra,24(sp)
    800048dc:	6442                	ld	s0,16(sp)
    800048de:	64a2                	ld	s1,8(sp)
    800048e0:	6902                	ld	s2,0(sp)
    800048e2:	6105                	addi	sp,sp,32
    800048e4:	8082                	ret

00000000800048e6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048e6:	7179                	addi	sp,sp,-48
    800048e8:	f406                	sd	ra,40(sp)
    800048ea:	f022                	sd	s0,32(sp)
    800048ec:	ec26                	sd	s1,24(sp)
    800048ee:	e84a                	sd	s2,16(sp)
    800048f0:	e44e                	sd	s3,8(sp)
    800048f2:	1800                	addi	s0,sp,48
    800048f4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048f6:	00850913          	addi	s2,a0,8
    800048fa:	854a                	mv	a0,s2
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	2da080e7          	jalr	730(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004904:	409c                	lw	a5,0(s1)
    80004906:	ef99                	bnez	a5,80004924 <holdingsleep+0x3e>
    80004908:	4481                	li	s1,0
  release(&lk->lk);
    8000490a:	854a                	mv	a0,s2
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	37e080e7          	jalr	894(ra) # 80000c8a <release>
  return r;
}
    80004914:	8526                	mv	a0,s1
    80004916:	70a2                	ld	ra,40(sp)
    80004918:	7402                	ld	s0,32(sp)
    8000491a:	64e2                	ld	s1,24(sp)
    8000491c:	6942                	ld	s2,16(sp)
    8000491e:	69a2                	ld	s3,8(sp)
    80004920:	6145                	addi	sp,sp,48
    80004922:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004924:	0284a983          	lw	s3,40(s1)
    80004928:	ffffd097          	auipc	ra,0xffffd
    8000492c:	084080e7          	jalr	132(ra) # 800019ac <myproc>
    80004930:	5904                	lw	s1,48(a0)
    80004932:	413484b3          	sub	s1,s1,s3
    80004936:	0014b493          	seqz	s1,s1
    8000493a:	bfc1                	j	8000490a <holdingsleep+0x24>

000000008000493c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000493c:	1141                	addi	sp,sp,-16
    8000493e:	e406                	sd	ra,8(sp)
    80004940:	e022                	sd	s0,0(sp)
    80004942:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004944:	00004597          	auipc	a1,0x4
    80004948:	e5458593          	addi	a1,a1,-428 # 80008798 <syscalls+0x348>
    8000494c:	0001d517          	auipc	a0,0x1d
    80004950:	1ec50513          	addi	a0,a0,492 # 80021b38 <ftable>
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	1f2080e7          	jalr	498(ra) # 80000b46 <initlock>
}
    8000495c:	60a2                	ld	ra,8(sp)
    8000495e:	6402                	ld	s0,0(sp)
    80004960:	0141                	addi	sp,sp,16
    80004962:	8082                	ret

0000000080004964 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004964:	1101                	addi	sp,sp,-32
    80004966:	ec06                	sd	ra,24(sp)
    80004968:	e822                	sd	s0,16(sp)
    8000496a:	e426                	sd	s1,8(sp)
    8000496c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000496e:	0001d517          	auipc	a0,0x1d
    80004972:	1ca50513          	addi	a0,a0,458 # 80021b38 <ftable>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	260080e7          	jalr	608(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000497e:	0001d497          	auipc	s1,0x1d
    80004982:	1d248493          	addi	s1,s1,466 # 80021b50 <ftable+0x18>
    80004986:	0001e717          	auipc	a4,0x1e
    8000498a:	16a70713          	addi	a4,a4,362 # 80022af0 <disk>
    if(f->ref == 0){
    8000498e:	40dc                	lw	a5,4(s1)
    80004990:	cf99                	beqz	a5,800049ae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004992:	02848493          	addi	s1,s1,40
    80004996:	fee49ce3          	bne	s1,a4,8000498e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000499a:	0001d517          	auipc	a0,0x1d
    8000499e:	19e50513          	addi	a0,a0,414 # 80021b38 <ftable>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	2e8080e7          	jalr	744(ra) # 80000c8a <release>
  return 0;
    800049aa:	4481                	li	s1,0
    800049ac:	a819                	j	800049c2 <filealloc+0x5e>
      f->ref = 1;
    800049ae:	4785                	li	a5,1
    800049b0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049b2:	0001d517          	auipc	a0,0x1d
    800049b6:	18650513          	addi	a0,a0,390 # 80021b38 <ftable>
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	2d0080e7          	jalr	720(ra) # 80000c8a <release>
}
    800049c2:	8526                	mv	a0,s1
    800049c4:	60e2                	ld	ra,24(sp)
    800049c6:	6442                	ld	s0,16(sp)
    800049c8:	64a2                	ld	s1,8(sp)
    800049ca:	6105                	addi	sp,sp,32
    800049cc:	8082                	ret

00000000800049ce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049ce:	1101                	addi	sp,sp,-32
    800049d0:	ec06                	sd	ra,24(sp)
    800049d2:	e822                	sd	s0,16(sp)
    800049d4:	e426                	sd	s1,8(sp)
    800049d6:	1000                	addi	s0,sp,32
    800049d8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049da:	0001d517          	auipc	a0,0x1d
    800049de:	15e50513          	addi	a0,a0,350 # 80021b38 <ftable>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	1f4080e7          	jalr	500(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800049ea:	40dc                	lw	a5,4(s1)
    800049ec:	02f05263          	blez	a5,80004a10 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049f0:	2785                	addiw	a5,a5,1
    800049f2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049f4:	0001d517          	auipc	a0,0x1d
    800049f8:	14450513          	addi	a0,a0,324 # 80021b38 <ftable>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	28e080e7          	jalr	654(ra) # 80000c8a <release>
  return f;
}
    80004a04:	8526                	mv	a0,s1
    80004a06:	60e2                	ld	ra,24(sp)
    80004a08:	6442                	ld	s0,16(sp)
    80004a0a:	64a2                	ld	s1,8(sp)
    80004a0c:	6105                	addi	sp,sp,32
    80004a0e:	8082                	ret
    panic("filedup");
    80004a10:	00004517          	auipc	a0,0x4
    80004a14:	d9050513          	addi	a0,a0,-624 # 800087a0 <syscalls+0x350>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	b28080e7          	jalr	-1240(ra) # 80000540 <panic>

0000000080004a20 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a20:	7139                	addi	sp,sp,-64
    80004a22:	fc06                	sd	ra,56(sp)
    80004a24:	f822                	sd	s0,48(sp)
    80004a26:	f426                	sd	s1,40(sp)
    80004a28:	f04a                	sd	s2,32(sp)
    80004a2a:	ec4e                	sd	s3,24(sp)
    80004a2c:	e852                	sd	s4,16(sp)
    80004a2e:	e456                	sd	s5,8(sp)
    80004a30:	0080                	addi	s0,sp,64
    80004a32:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a34:	0001d517          	auipc	a0,0x1d
    80004a38:	10450513          	addi	a0,a0,260 # 80021b38 <ftable>
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	19a080e7          	jalr	410(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004a44:	40dc                	lw	a5,4(s1)
    80004a46:	06f05163          	blez	a5,80004aa8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a4a:	37fd                	addiw	a5,a5,-1
    80004a4c:	0007871b          	sext.w	a4,a5
    80004a50:	c0dc                	sw	a5,4(s1)
    80004a52:	06e04363          	bgtz	a4,80004ab8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a56:	0004a903          	lw	s2,0(s1)
    80004a5a:	0094ca83          	lbu	s5,9(s1)
    80004a5e:	0104ba03          	ld	s4,16(s1)
    80004a62:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a66:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a6a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a6e:	0001d517          	auipc	a0,0x1d
    80004a72:	0ca50513          	addi	a0,a0,202 # 80021b38 <ftable>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	214080e7          	jalr	532(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004a7e:	4785                	li	a5,1
    80004a80:	04f90d63          	beq	s2,a5,80004ada <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a84:	3979                	addiw	s2,s2,-2
    80004a86:	4785                	li	a5,1
    80004a88:	0527e063          	bltu	a5,s2,80004ac8 <fileclose+0xa8>
    begin_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	acc080e7          	jalr	-1332(ra) # 80004558 <begin_op>
    iput(ff.ip);
    80004a94:	854e                	mv	a0,s3
    80004a96:	fffff097          	auipc	ra,0xfffff
    80004a9a:	2b0080e7          	jalr	688(ra) # 80003d46 <iput>
    end_op();
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	b38080e7          	jalr	-1224(ra) # 800045d6 <end_op>
    80004aa6:	a00d                	j	80004ac8 <fileclose+0xa8>
    panic("fileclose");
    80004aa8:	00004517          	auipc	a0,0x4
    80004aac:	d0050513          	addi	a0,a0,-768 # 800087a8 <syscalls+0x358>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	a90080e7          	jalr	-1392(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004ab8:	0001d517          	auipc	a0,0x1d
    80004abc:	08050513          	addi	a0,a0,128 # 80021b38 <ftable>
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	1ca080e7          	jalr	458(ra) # 80000c8a <release>
  }
}
    80004ac8:	70e2                	ld	ra,56(sp)
    80004aca:	7442                	ld	s0,48(sp)
    80004acc:	74a2                	ld	s1,40(sp)
    80004ace:	7902                	ld	s2,32(sp)
    80004ad0:	69e2                	ld	s3,24(sp)
    80004ad2:	6a42                	ld	s4,16(sp)
    80004ad4:	6aa2                	ld	s5,8(sp)
    80004ad6:	6121                	addi	sp,sp,64
    80004ad8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ada:	85d6                	mv	a1,s5
    80004adc:	8552                	mv	a0,s4
    80004ade:	00000097          	auipc	ra,0x0
    80004ae2:	34c080e7          	jalr	844(ra) # 80004e2a <pipeclose>
    80004ae6:	b7cd                	j	80004ac8 <fileclose+0xa8>

0000000080004ae8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ae8:	715d                	addi	sp,sp,-80
    80004aea:	e486                	sd	ra,72(sp)
    80004aec:	e0a2                	sd	s0,64(sp)
    80004aee:	fc26                	sd	s1,56(sp)
    80004af0:	f84a                	sd	s2,48(sp)
    80004af2:	f44e                	sd	s3,40(sp)
    80004af4:	0880                	addi	s0,sp,80
    80004af6:	84aa                	mv	s1,a0
    80004af8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004afa:	ffffd097          	auipc	ra,0xffffd
    80004afe:	eb2080e7          	jalr	-334(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b02:	409c                	lw	a5,0(s1)
    80004b04:	37f9                	addiw	a5,a5,-2
    80004b06:	4705                	li	a4,1
    80004b08:	04f76763          	bltu	a4,a5,80004b56 <filestat+0x6e>
    80004b0c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b0e:	6c88                	ld	a0,24(s1)
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	07c080e7          	jalr	124(ra) # 80003b8c <ilock>
    stati(f->ip, &st);
    80004b18:	fb840593          	addi	a1,s0,-72
    80004b1c:	6c88                	ld	a0,24(s1)
    80004b1e:	fffff097          	auipc	ra,0xfffff
    80004b22:	2f8080e7          	jalr	760(ra) # 80003e16 <stati>
    iunlock(f->ip);
    80004b26:	6c88                	ld	a0,24(s1)
    80004b28:	fffff097          	auipc	ra,0xfffff
    80004b2c:	126080e7          	jalr	294(ra) # 80003c4e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b30:	46e1                	li	a3,24
    80004b32:	fb840613          	addi	a2,s0,-72
    80004b36:	85ce                	mv	a1,s3
    80004b38:	05093503          	ld	a0,80(s2)
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	b30080e7          	jalr	-1232(ra) # 8000166c <copyout>
    80004b44:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b48:	60a6                	ld	ra,72(sp)
    80004b4a:	6406                	ld	s0,64(sp)
    80004b4c:	74e2                	ld	s1,56(sp)
    80004b4e:	7942                	ld	s2,48(sp)
    80004b50:	79a2                	ld	s3,40(sp)
    80004b52:	6161                	addi	sp,sp,80
    80004b54:	8082                	ret
  return -1;
    80004b56:	557d                	li	a0,-1
    80004b58:	bfc5                	j	80004b48 <filestat+0x60>

0000000080004b5a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b5a:	7179                	addi	sp,sp,-48
    80004b5c:	f406                	sd	ra,40(sp)
    80004b5e:	f022                	sd	s0,32(sp)
    80004b60:	ec26                	sd	s1,24(sp)
    80004b62:	e84a                	sd	s2,16(sp)
    80004b64:	e44e                	sd	s3,8(sp)
    80004b66:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b68:	00854783          	lbu	a5,8(a0)
    80004b6c:	c3d5                	beqz	a5,80004c10 <fileread+0xb6>
    80004b6e:	84aa                	mv	s1,a0
    80004b70:	89ae                	mv	s3,a1
    80004b72:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b74:	411c                	lw	a5,0(a0)
    80004b76:	4705                	li	a4,1
    80004b78:	04e78963          	beq	a5,a4,80004bca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b7c:	470d                	li	a4,3
    80004b7e:	04e78d63          	beq	a5,a4,80004bd8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b82:	4709                	li	a4,2
    80004b84:	06e79e63          	bne	a5,a4,80004c00 <fileread+0xa6>
    ilock(f->ip);
    80004b88:	6d08                	ld	a0,24(a0)
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	002080e7          	jalr	2(ra) # 80003b8c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b92:	874a                	mv	a4,s2
    80004b94:	5094                	lw	a3,32(s1)
    80004b96:	864e                	mv	a2,s3
    80004b98:	4585                	li	a1,1
    80004b9a:	6c88                	ld	a0,24(s1)
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	2a4080e7          	jalr	676(ra) # 80003e40 <readi>
    80004ba4:	892a                	mv	s2,a0
    80004ba6:	00a05563          	blez	a0,80004bb0 <fileread+0x56>
      f->off += r;
    80004baa:	509c                	lw	a5,32(s1)
    80004bac:	9fa9                	addw	a5,a5,a0
    80004bae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bb0:	6c88                	ld	a0,24(s1)
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	09c080e7          	jalr	156(ra) # 80003c4e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bba:	854a                	mv	a0,s2
    80004bbc:	70a2                	ld	ra,40(sp)
    80004bbe:	7402                	ld	s0,32(sp)
    80004bc0:	64e2                	ld	s1,24(sp)
    80004bc2:	6942                	ld	s2,16(sp)
    80004bc4:	69a2                	ld	s3,8(sp)
    80004bc6:	6145                	addi	sp,sp,48
    80004bc8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bca:	6908                	ld	a0,16(a0)
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	3c6080e7          	jalr	966(ra) # 80004f92 <piperead>
    80004bd4:	892a                	mv	s2,a0
    80004bd6:	b7d5                	j	80004bba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bd8:	02451783          	lh	a5,36(a0)
    80004bdc:	03079693          	slli	a3,a5,0x30
    80004be0:	92c1                	srli	a3,a3,0x30
    80004be2:	4725                	li	a4,9
    80004be4:	02d76863          	bltu	a4,a3,80004c14 <fileread+0xba>
    80004be8:	0792                	slli	a5,a5,0x4
    80004bea:	0001d717          	auipc	a4,0x1d
    80004bee:	eae70713          	addi	a4,a4,-338 # 80021a98 <devsw>
    80004bf2:	97ba                	add	a5,a5,a4
    80004bf4:	639c                	ld	a5,0(a5)
    80004bf6:	c38d                	beqz	a5,80004c18 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bf8:	4505                	li	a0,1
    80004bfa:	9782                	jalr	a5
    80004bfc:	892a                	mv	s2,a0
    80004bfe:	bf75                	j	80004bba <fileread+0x60>
    panic("fileread");
    80004c00:	00004517          	auipc	a0,0x4
    80004c04:	bb850513          	addi	a0,a0,-1096 # 800087b8 <syscalls+0x368>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	938080e7          	jalr	-1736(ra) # 80000540 <panic>
    return -1;
    80004c10:	597d                	li	s2,-1
    80004c12:	b765                	j	80004bba <fileread+0x60>
      return -1;
    80004c14:	597d                	li	s2,-1
    80004c16:	b755                	j	80004bba <fileread+0x60>
    80004c18:	597d                	li	s2,-1
    80004c1a:	b745                	j	80004bba <fileread+0x60>

0000000080004c1c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c1c:	715d                	addi	sp,sp,-80
    80004c1e:	e486                	sd	ra,72(sp)
    80004c20:	e0a2                	sd	s0,64(sp)
    80004c22:	fc26                	sd	s1,56(sp)
    80004c24:	f84a                	sd	s2,48(sp)
    80004c26:	f44e                	sd	s3,40(sp)
    80004c28:	f052                	sd	s4,32(sp)
    80004c2a:	ec56                	sd	s5,24(sp)
    80004c2c:	e85a                	sd	s6,16(sp)
    80004c2e:	e45e                	sd	s7,8(sp)
    80004c30:	e062                	sd	s8,0(sp)
    80004c32:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c34:	00954783          	lbu	a5,9(a0)
    80004c38:	10078663          	beqz	a5,80004d44 <filewrite+0x128>
    80004c3c:	892a                	mv	s2,a0
    80004c3e:	8b2e                	mv	s6,a1
    80004c40:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c42:	411c                	lw	a5,0(a0)
    80004c44:	4705                	li	a4,1
    80004c46:	02e78263          	beq	a5,a4,80004c6a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c4a:	470d                	li	a4,3
    80004c4c:	02e78663          	beq	a5,a4,80004c78 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c50:	4709                	li	a4,2
    80004c52:	0ee79163          	bne	a5,a4,80004d34 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c56:	0ac05d63          	blez	a2,80004d10 <filewrite+0xf4>
    int i = 0;
    80004c5a:	4981                	li	s3,0
    80004c5c:	6b85                	lui	s7,0x1
    80004c5e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c62:	6c05                	lui	s8,0x1
    80004c64:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c68:	a861                	j	80004d00 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c6a:	6908                	ld	a0,16(a0)
    80004c6c:	00000097          	auipc	ra,0x0
    80004c70:	22e080e7          	jalr	558(ra) # 80004e9a <pipewrite>
    80004c74:	8a2a                	mv	s4,a0
    80004c76:	a045                	j	80004d16 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c78:	02451783          	lh	a5,36(a0)
    80004c7c:	03079693          	slli	a3,a5,0x30
    80004c80:	92c1                	srli	a3,a3,0x30
    80004c82:	4725                	li	a4,9
    80004c84:	0cd76263          	bltu	a4,a3,80004d48 <filewrite+0x12c>
    80004c88:	0792                	slli	a5,a5,0x4
    80004c8a:	0001d717          	auipc	a4,0x1d
    80004c8e:	e0e70713          	addi	a4,a4,-498 # 80021a98 <devsw>
    80004c92:	97ba                	add	a5,a5,a4
    80004c94:	679c                	ld	a5,8(a5)
    80004c96:	cbdd                	beqz	a5,80004d4c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c98:	4505                	li	a0,1
    80004c9a:	9782                	jalr	a5
    80004c9c:	8a2a                	mv	s4,a0
    80004c9e:	a8a5                	j	80004d16 <filewrite+0xfa>
    80004ca0:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ca4:	00000097          	auipc	ra,0x0
    80004ca8:	8b4080e7          	jalr	-1868(ra) # 80004558 <begin_op>
      ilock(f->ip);
    80004cac:	01893503          	ld	a0,24(s2)
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	edc080e7          	jalr	-292(ra) # 80003b8c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cb8:	8756                	mv	a4,s5
    80004cba:	02092683          	lw	a3,32(s2)
    80004cbe:	01698633          	add	a2,s3,s6
    80004cc2:	4585                	li	a1,1
    80004cc4:	01893503          	ld	a0,24(s2)
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	270080e7          	jalr	624(ra) # 80003f38 <writei>
    80004cd0:	84aa                	mv	s1,a0
    80004cd2:	00a05763          	blez	a0,80004ce0 <filewrite+0xc4>
        f->off += r;
    80004cd6:	02092783          	lw	a5,32(s2)
    80004cda:	9fa9                	addw	a5,a5,a0
    80004cdc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ce0:	01893503          	ld	a0,24(s2)
    80004ce4:	fffff097          	auipc	ra,0xfffff
    80004ce8:	f6a080e7          	jalr	-150(ra) # 80003c4e <iunlock>
      end_op();
    80004cec:	00000097          	auipc	ra,0x0
    80004cf0:	8ea080e7          	jalr	-1814(ra) # 800045d6 <end_op>

      if(r != n1){
    80004cf4:	009a9f63          	bne	s5,s1,80004d12 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cf8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cfc:	0149db63          	bge	s3,s4,80004d12 <filewrite+0xf6>
      int n1 = n - i;
    80004d00:	413a04bb          	subw	s1,s4,s3
    80004d04:	0004879b          	sext.w	a5,s1
    80004d08:	f8fbdce3          	bge	s7,a5,80004ca0 <filewrite+0x84>
    80004d0c:	84e2                	mv	s1,s8
    80004d0e:	bf49                	j	80004ca0 <filewrite+0x84>
    int i = 0;
    80004d10:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d12:	013a1f63          	bne	s4,s3,80004d30 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d16:	8552                	mv	a0,s4
    80004d18:	60a6                	ld	ra,72(sp)
    80004d1a:	6406                	ld	s0,64(sp)
    80004d1c:	74e2                	ld	s1,56(sp)
    80004d1e:	7942                	ld	s2,48(sp)
    80004d20:	79a2                	ld	s3,40(sp)
    80004d22:	7a02                	ld	s4,32(sp)
    80004d24:	6ae2                	ld	s5,24(sp)
    80004d26:	6b42                	ld	s6,16(sp)
    80004d28:	6ba2                	ld	s7,8(sp)
    80004d2a:	6c02                	ld	s8,0(sp)
    80004d2c:	6161                	addi	sp,sp,80
    80004d2e:	8082                	ret
    ret = (i == n ? n : -1);
    80004d30:	5a7d                	li	s4,-1
    80004d32:	b7d5                	j	80004d16 <filewrite+0xfa>
    panic("filewrite");
    80004d34:	00004517          	auipc	a0,0x4
    80004d38:	a9450513          	addi	a0,a0,-1388 # 800087c8 <syscalls+0x378>
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>
    return -1;
    80004d44:	5a7d                	li	s4,-1
    80004d46:	bfc1                	j	80004d16 <filewrite+0xfa>
      return -1;
    80004d48:	5a7d                	li	s4,-1
    80004d4a:	b7f1                	j	80004d16 <filewrite+0xfa>
    80004d4c:	5a7d                	li	s4,-1
    80004d4e:	b7e1                	j	80004d16 <filewrite+0xfa>

0000000080004d50 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d50:	7179                	addi	sp,sp,-48
    80004d52:	f406                	sd	ra,40(sp)
    80004d54:	f022                	sd	s0,32(sp)
    80004d56:	ec26                	sd	s1,24(sp)
    80004d58:	e84a                	sd	s2,16(sp)
    80004d5a:	e44e                	sd	s3,8(sp)
    80004d5c:	e052                	sd	s4,0(sp)
    80004d5e:	1800                	addi	s0,sp,48
    80004d60:	84aa                	mv	s1,a0
    80004d62:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d64:	0005b023          	sd	zero,0(a1)
    80004d68:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	bf8080e7          	jalr	-1032(ra) # 80004964 <filealloc>
    80004d74:	e088                	sd	a0,0(s1)
    80004d76:	c551                	beqz	a0,80004e02 <pipealloc+0xb2>
    80004d78:	00000097          	auipc	ra,0x0
    80004d7c:	bec080e7          	jalr	-1044(ra) # 80004964 <filealloc>
    80004d80:	00aa3023          	sd	a0,0(s4)
    80004d84:	c92d                	beqz	a0,80004df6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	d60080e7          	jalr	-672(ra) # 80000ae6 <kalloc>
    80004d8e:	892a                	mv	s2,a0
    80004d90:	c125                	beqz	a0,80004df0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d92:	4985                	li	s3,1
    80004d94:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d98:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d9c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004da0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004da4:	00004597          	auipc	a1,0x4
    80004da8:	a3458593          	addi	a1,a1,-1484 # 800087d8 <syscalls+0x388>
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	d9a080e7          	jalr	-614(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004db4:	609c                	ld	a5,0(s1)
    80004db6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dba:	609c                	ld	a5,0(s1)
    80004dbc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dc0:	609c                	ld	a5,0(s1)
    80004dc2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dc6:	609c                	ld	a5,0(s1)
    80004dc8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dcc:	000a3783          	ld	a5,0(s4)
    80004dd0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dd4:	000a3783          	ld	a5,0(s4)
    80004dd8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ddc:	000a3783          	ld	a5,0(s4)
    80004de0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004de4:	000a3783          	ld	a5,0(s4)
    80004de8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dec:	4501                	li	a0,0
    80004dee:	a025                	j	80004e16 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004df0:	6088                	ld	a0,0(s1)
    80004df2:	e501                	bnez	a0,80004dfa <pipealloc+0xaa>
    80004df4:	a039                	j	80004e02 <pipealloc+0xb2>
    80004df6:	6088                	ld	a0,0(s1)
    80004df8:	c51d                	beqz	a0,80004e26 <pipealloc+0xd6>
    fileclose(*f0);
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	c26080e7          	jalr	-986(ra) # 80004a20 <fileclose>
  if(*f1)
    80004e02:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e06:	557d                	li	a0,-1
  if(*f1)
    80004e08:	c799                	beqz	a5,80004e16 <pipealloc+0xc6>
    fileclose(*f1);
    80004e0a:	853e                	mv	a0,a5
    80004e0c:	00000097          	auipc	ra,0x0
    80004e10:	c14080e7          	jalr	-1004(ra) # 80004a20 <fileclose>
  return -1;
    80004e14:	557d                	li	a0,-1
}
    80004e16:	70a2                	ld	ra,40(sp)
    80004e18:	7402                	ld	s0,32(sp)
    80004e1a:	64e2                	ld	s1,24(sp)
    80004e1c:	6942                	ld	s2,16(sp)
    80004e1e:	69a2                	ld	s3,8(sp)
    80004e20:	6a02                	ld	s4,0(sp)
    80004e22:	6145                	addi	sp,sp,48
    80004e24:	8082                	ret
  return -1;
    80004e26:	557d                	li	a0,-1
    80004e28:	b7fd                	j	80004e16 <pipealloc+0xc6>

0000000080004e2a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e2a:	1101                	addi	sp,sp,-32
    80004e2c:	ec06                	sd	ra,24(sp)
    80004e2e:	e822                	sd	s0,16(sp)
    80004e30:	e426                	sd	s1,8(sp)
    80004e32:	e04a                	sd	s2,0(sp)
    80004e34:	1000                	addi	s0,sp,32
    80004e36:	84aa                	mv	s1,a0
    80004e38:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	d9c080e7          	jalr	-612(ra) # 80000bd6 <acquire>
  if(writable){
    80004e42:	02090d63          	beqz	s2,80004e7c <pipeclose+0x52>
    pi->writeopen = 0;
    80004e46:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e4a:	21848513          	addi	a0,s1,536
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	51c080e7          	jalr	1308(ra) # 8000236a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e56:	2204b783          	ld	a5,544(s1)
    80004e5a:	eb95                	bnez	a5,80004e8e <pipeclose+0x64>
    release(&pi->lock);
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	e2c080e7          	jalr	-468(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004e66:	8526                	mv	a0,s1
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	b80080e7          	jalr	-1152(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004e70:	60e2                	ld	ra,24(sp)
    80004e72:	6442                	ld	s0,16(sp)
    80004e74:	64a2                	ld	s1,8(sp)
    80004e76:	6902                	ld	s2,0(sp)
    80004e78:	6105                	addi	sp,sp,32
    80004e7a:	8082                	ret
    pi->readopen = 0;
    80004e7c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e80:	21c48513          	addi	a0,s1,540
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	4e6080e7          	jalr	1254(ra) # 8000236a <wakeup>
    80004e8c:	b7e9                	j	80004e56 <pipeclose+0x2c>
    release(&pi->lock);
    80004e8e:	8526                	mv	a0,s1
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	dfa080e7          	jalr	-518(ra) # 80000c8a <release>
}
    80004e98:	bfe1                	j	80004e70 <pipeclose+0x46>

0000000080004e9a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e9a:	711d                	addi	sp,sp,-96
    80004e9c:	ec86                	sd	ra,88(sp)
    80004e9e:	e8a2                	sd	s0,80(sp)
    80004ea0:	e4a6                	sd	s1,72(sp)
    80004ea2:	e0ca                	sd	s2,64(sp)
    80004ea4:	fc4e                	sd	s3,56(sp)
    80004ea6:	f852                	sd	s4,48(sp)
    80004ea8:	f456                	sd	s5,40(sp)
    80004eaa:	f05a                	sd	s6,32(sp)
    80004eac:	ec5e                	sd	s7,24(sp)
    80004eae:	e862                	sd	s8,16(sp)
    80004eb0:	1080                	addi	s0,sp,96
    80004eb2:	84aa                	mv	s1,a0
    80004eb4:	8aae                	mv	s5,a1
    80004eb6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	af4080e7          	jalr	-1292(ra) # 800019ac <myproc>
    80004ec0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ec2:	8526                	mv	a0,s1
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	d12080e7          	jalr	-750(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ecc:	0b405663          	blez	s4,80004f78 <pipewrite+0xde>
  int i = 0;
    80004ed0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ed2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ed4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ed8:	21c48b93          	addi	s7,s1,540
    80004edc:	a089                	j	80004f1e <pipewrite+0x84>
      release(&pi->lock);
    80004ede:	8526                	mv	a0,s1
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	daa080e7          	jalr	-598(ra) # 80000c8a <release>
      return -1;
    80004ee8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004eea:	854a                	mv	a0,s2
    80004eec:	60e6                	ld	ra,88(sp)
    80004eee:	6446                	ld	s0,80(sp)
    80004ef0:	64a6                	ld	s1,72(sp)
    80004ef2:	6906                	ld	s2,64(sp)
    80004ef4:	79e2                	ld	s3,56(sp)
    80004ef6:	7a42                	ld	s4,48(sp)
    80004ef8:	7aa2                	ld	s5,40(sp)
    80004efa:	7b02                	ld	s6,32(sp)
    80004efc:	6be2                	ld	s7,24(sp)
    80004efe:	6c42                	ld	s8,16(sp)
    80004f00:	6125                	addi	sp,sp,96
    80004f02:	8082                	ret
      wakeup(&pi->nread);
    80004f04:	8562                	mv	a0,s8
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	464080e7          	jalr	1124(ra) # 8000236a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f0e:	85a6                	mv	a1,s1
    80004f10:	855e                	mv	a0,s7
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	3f4080e7          	jalr	1012(ra) # 80002306 <sleep>
  while(i < n){
    80004f1a:	07495063          	bge	s2,s4,80004f7a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f1e:	2204a783          	lw	a5,544(s1)
    80004f22:	dfd5                	beqz	a5,80004ede <pipewrite+0x44>
    80004f24:	854e                	mv	a0,s3
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	694080e7          	jalr	1684(ra) # 800025ba <killed>
    80004f2e:	f945                	bnez	a0,80004ede <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f30:	2184a783          	lw	a5,536(s1)
    80004f34:	21c4a703          	lw	a4,540(s1)
    80004f38:	2007879b          	addiw	a5,a5,512
    80004f3c:	fcf704e3          	beq	a4,a5,80004f04 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f40:	4685                	li	a3,1
    80004f42:	01590633          	add	a2,s2,s5
    80004f46:	faf40593          	addi	a1,s0,-81
    80004f4a:	0509b503          	ld	a0,80(s3)
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	7aa080e7          	jalr	1962(ra) # 800016f8 <copyin>
    80004f56:	03650263          	beq	a0,s6,80004f7a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f5a:	21c4a783          	lw	a5,540(s1)
    80004f5e:	0017871b          	addiw	a4,a5,1
    80004f62:	20e4ae23          	sw	a4,540(s1)
    80004f66:	1ff7f793          	andi	a5,a5,511
    80004f6a:	97a6                	add	a5,a5,s1
    80004f6c:	faf44703          	lbu	a4,-81(s0)
    80004f70:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f74:	2905                	addiw	s2,s2,1
    80004f76:	b755                	j	80004f1a <pipewrite+0x80>
  int i = 0;
    80004f78:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f7a:	21848513          	addi	a0,s1,536
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	3ec080e7          	jalr	1004(ra) # 8000236a <wakeup>
  release(&pi->lock);
    80004f86:	8526                	mv	a0,s1
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	d02080e7          	jalr	-766(ra) # 80000c8a <release>
  return i;
    80004f90:	bfa9                	j	80004eea <pipewrite+0x50>

0000000080004f92 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f92:	715d                	addi	sp,sp,-80
    80004f94:	e486                	sd	ra,72(sp)
    80004f96:	e0a2                	sd	s0,64(sp)
    80004f98:	fc26                	sd	s1,56(sp)
    80004f9a:	f84a                	sd	s2,48(sp)
    80004f9c:	f44e                	sd	s3,40(sp)
    80004f9e:	f052                	sd	s4,32(sp)
    80004fa0:	ec56                	sd	s5,24(sp)
    80004fa2:	e85a                	sd	s6,16(sp)
    80004fa4:	0880                	addi	s0,sp,80
    80004fa6:	84aa                	mv	s1,a0
    80004fa8:	892e                	mv	s2,a1
    80004faa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	a00080e7          	jalr	-1536(ra) # 800019ac <myproc>
    80004fb4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fb6:	8526                	mv	a0,s1
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	c1e080e7          	jalr	-994(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fc0:	2184a703          	lw	a4,536(s1)
    80004fc4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fc8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fcc:	02f71763          	bne	a4,a5,80004ffa <piperead+0x68>
    80004fd0:	2244a783          	lw	a5,548(s1)
    80004fd4:	c39d                	beqz	a5,80004ffa <piperead+0x68>
    if(killed(pr)){
    80004fd6:	8552                	mv	a0,s4
    80004fd8:	ffffd097          	auipc	ra,0xffffd
    80004fdc:	5e2080e7          	jalr	1506(ra) # 800025ba <killed>
    80004fe0:	e949                	bnez	a0,80005072 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fe2:	85a6                	mv	a1,s1
    80004fe4:	854e                	mv	a0,s3
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	320080e7          	jalr	800(ra) # 80002306 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fee:	2184a703          	lw	a4,536(s1)
    80004ff2:	21c4a783          	lw	a5,540(s1)
    80004ff6:	fcf70de3          	beq	a4,a5,80004fd0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ffa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ffc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ffe:	05505463          	blez	s5,80005046 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005002:	2184a783          	lw	a5,536(s1)
    80005006:	21c4a703          	lw	a4,540(s1)
    8000500a:	02f70e63          	beq	a4,a5,80005046 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000500e:	0017871b          	addiw	a4,a5,1
    80005012:	20e4ac23          	sw	a4,536(s1)
    80005016:	1ff7f793          	andi	a5,a5,511
    8000501a:	97a6                	add	a5,a5,s1
    8000501c:	0187c783          	lbu	a5,24(a5)
    80005020:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005024:	4685                	li	a3,1
    80005026:	fbf40613          	addi	a2,s0,-65
    8000502a:	85ca                	mv	a1,s2
    8000502c:	050a3503          	ld	a0,80(s4)
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	63c080e7          	jalr	1596(ra) # 8000166c <copyout>
    80005038:	01650763          	beq	a0,s6,80005046 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000503c:	2985                	addiw	s3,s3,1
    8000503e:	0905                	addi	s2,s2,1
    80005040:	fd3a91e3          	bne	s5,s3,80005002 <piperead+0x70>
    80005044:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005046:	21c48513          	addi	a0,s1,540
    8000504a:	ffffd097          	auipc	ra,0xffffd
    8000504e:	320080e7          	jalr	800(ra) # 8000236a <wakeup>
  release(&pi->lock);
    80005052:	8526                	mv	a0,s1
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	c36080e7          	jalr	-970(ra) # 80000c8a <release>
  return i;
}
    8000505c:	854e                	mv	a0,s3
    8000505e:	60a6                	ld	ra,72(sp)
    80005060:	6406                	ld	s0,64(sp)
    80005062:	74e2                	ld	s1,56(sp)
    80005064:	7942                	ld	s2,48(sp)
    80005066:	79a2                	ld	s3,40(sp)
    80005068:	7a02                	ld	s4,32(sp)
    8000506a:	6ae2                	ld	s5,24(sp)
    8000506c:	6b42                	ld	s6,16(sp)
    8000506e:	6161                	addi	sp,sp,80
    80005070:	8082                	ret
      release(&pi->lock);
    80005072:	8526                	mv	a0,s1
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	c16080e7          	jalr	-1002(ra) # 80000c8a <release>
      return -1;
    8000507c:	59fd                	li	s3,-1
    8000507e:	bff9                	j	8000505c <piperead+0xca>

0000000080005080 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005080:	1141                	addi	sp,sp,-16
    80005082:	e422                	sd	s0,8(sp)
    80005084:	0800                	addi	s0,sp,16
    80005086:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005088:	8905                	andi	a0,a0,1
    8000508a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000508c:	8b89                	andi	a5,a5,2
    8000508e:	c399                	beqz	a5,80005094 <flags2perm+0x14>
      perm |= PTE_W;
    80005090:	00456513          	ori	a0,a0,4
    return perm;
}
    80005094:	6422                	ld	s0,8(sp)
    80005096:	0141                	addi	sp,sp,16
    80005098:	8082                	ret

000000008000509a <exec>:

int
exec(char *path, char **argv)
{
    8000509a:	de010113          	addi	sp,sp,-544
    8000509e:	20113c23          	sd	ra,536(sp)
    800050a2:	20813823          	sd	s0,528(sp)
    800050a6:	20913423          	sd	s1,520(sp)
    800050aa:	21213023          	sd	s2,512(sp)
    800050ae:	ffce                	sd	s3,504(sp)
    800050b0:	fbd2                	sd	s4,496(sp)
    800050b2:	f7d6                	sd	s5,488(sp)
    800050b4:	f3da                	sd	s6,480(sp)
    800050b6:	efde                	sd	s7,472(sp)
    800050b8:	ebe2                	sd	s8,464(sp)
    800050ba:	e7e6                	sd	s9,456(sp)
    800050bc:	e3ea                	sd	s10,448(sp)
    800050be:	ff6e                	sd	s11,440(sp)
    800050c0:	1400                	addi	s0,sp,544
    800050c2:	892a                	mv	s2,a0
    800050c4:	dea43423          	sd	a0,-536(s0)
    800050c8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	8e0080e7          	jalr	-1824(ra) # 800019ac <myproc>
    800050d4:	84aa                	mv	s1,a0

  begin_op();
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	482080e7          	jalr	1154(ra) # 80004558 <begin_op>

  if((ip = namei(path)) == 0){
    800050de:	854a                	mv	a0,s2
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	258080e7          	jalr	600(ra) # 80004338 <namei>
    800050e8:	c93d                	beqz	a0,8000515e <exec+0xc4>
    800050ea:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	aa0080e7          	jalr	-1376(ra) # 80003b8c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050f4:	04000713          	li	a4,64
    800050f8:	4681                	li	a3,0
    800050fa:	e5040613          	addi	a2,s0,-432
    800050fe:	4581                	li	a1,0
    80005100:	8556                	mv	a0,s5
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	d3e080e7          	jalr	-706(ra) # 80003e40 <readi>
    8000510a:	04000793          	li	a5,64
    8000510e:	00f51a63          	bne	a0,a5,80005122 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005112:	e5042703          	lw	a4,-432(s0)
    80005116:	464c47b7          	lui	a5,0x464c4
    8000511a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000511e:	04f70663          	beq	a4,a5,8000516a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005122:	8556                	mv	a0,s5
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	cca080e7          	jalr	-822(ra) # 80003dee <iunlockput>
    end_op();
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	4aa080e7          	jalr	1194(ra) # 800045d6 <end_op>
  }
  return -1;
    80005134:	557d                	li	a0,-1
}
    80005136:	21813083          	ld	ra,536(sp)
    8000513a:	21013403          	ld	s0,528(sp)
    8000513e:	20813483          	ld	s1,520(sp)
    80005142:	20013903          	ld	s2,512(sp)
    80005146:	79fe                	ld	s3,504(sp)
    80005148:	7a5e                	ld	s4,496(sp)
    8000514a:	7abe                	ld	s5,488(sp)
    8000514c:	7b1e                	ld	s6,480(sp)
    8000514e:	6bfe                	ld	s7,472(sp)
    80005150:	6c5e                	ld	s8,464(sp)
    80005152:	6cbe                	ld	s9,456(sp)
    80005154:	6d1e                	ld	s10,448(sp)
    80005156:	7dfa                	ld	s11,440(sp)
    80005158:	22010113          	addi	sp,sp,544
    8000515c:	8082                	ret
    end_op();
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	478080e7          	jalr	1144(ra) # 800045d6 <end_op>
    return -1;
    80005166:	557d                	li	a0,-1
    80005168:	b7f9                	j	80005136 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000516a:	8526                	mv	a0,s1
    8000516c:	ffffd097          	auipc	ra,0xffffd
    80005170:	904080e7          	jalr	-1788(ra) # 80001a70 <proc_pagetable>
    80005174:	8b2a                	mv	s6,a0
    80005176:	d555                	beqz	a0,80005122 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005178:	e7042783          	lw	a5,-400(s0)
    8000517c:	e8845703          	lhu	a4,-376(s0)
    80005180:	c735                	beqz	a4,800051ec <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005182:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005184:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005188:	6a05                	lui	s4,0x1
    8000518a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000518e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005192:	6d85                	lui	s11,0x1
    80005194:	7d7d                	lui	s10,0xfffff
    80005196:	ac3d                	j	800053d4 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005198:	00003517          	auipc	a0,0x3
    8000519c:	64850513          	addi	a0,a0,1608 # 800087e0 <syscalls+0x390>
    800051a0:	ffffb097          	auipc	ra,0xffffb
    800051a4:	3a0080e7          	jalr	928(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051a8:	874a                	mv	a4,s2
    800051aa:	009c86bb          	addw	a3,s9,s1
    800051ae:	4581                	li	a1,0
    800051b0:	8556                	mv	a0,s5
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	c8e080e7          	jalr	-882(ra) # 80003e40 <readi>
    800051ba:	2501                	sext.w	a0,a0
    800051bc:	1aa91963          	bne	s2,a0,8000536e <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800051c0:	009d84bb          	addw	s1,s11,s1
    800051c4:	013d09bb          	addw	s3,s10,s3
    800051c8:	1f74f663          	bgeu	s1,s7,800053b4 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800051cc:	02049593          	slli	a1,s1,0x20
    800051d0:	9181                	srli	a1,a1,0x20
    800051d2:	95e2                	add	a1,a1,s8
    800051d4:	855a                	mv	a0,s6
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	e86080e7          	jalr	-378(ra) # 8000105c <walkaddr>
    800051de:	862a                	mv	a2,a0
    if(pa == 0)
    800051e0:	dd45                	beqz	a0,80005198 <exec+0xfe>
      n = PGSIZE;
    800051e2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800051e4:	fd49f2e3          	bgeu	s3,s4,800051a8 <exec+0x10e>
      n = sz - i;
    800051e8:	894e                	mv	s2,s3
    800051ea:	bf7d                	j	800051a8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051ec:	4901                	li	s2,0
  iunlockput(ip);
    800051ee:	8556                	mv	a0,s5
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	bfe080e7          	jalr	-1026(ra) # 80003dee <iunlockput>
  end_op();
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	3de080e7          	jalr	990(ra) # 800045d6 <end_op>
  p = myproc();
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	7ac080e7          	jalr	1964(ra) # 800019ac <myproc>
    80005208:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000520a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000520e:	6785                	lui	a5,0x1
    80005210:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005212:	97ca                	add	a5,a5,s2
    80005214:	777d                	lui	a4,0xfffff
    80005216:	8ff9                	and	a5,a5,a4
    80005218:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000521c:	4691                	li	a3,4
    8000521e:	6609                	lui	a2,0x2
    80005220:	963e                	add	a2,a2,a5
    80005222:	85be                	mv	a1,a5
    80005224:	855a                	mv	a0,s6
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	1ea080e7          	jalr	490(ra) # 80001410 <uvmalloc>
    8000522e:	8c2a                	mv	s8,a0
  ip = 0;
    80005230:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005232:	12050e63          	beqz	a0,8000536e <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005236:	75f9                	lui	a1,0xffffe
    80005238:	95aa                	add	a1,a1,a0
    8000523a:	855a                	mv	a0,s6
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	3fe080e7          	jalr	1022(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80005244:	7afd                	lui	s5,0xfffff
    80005246:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005248:	df043783          	ld	a5,-528(s0)
    8000524c:	6388                	ld	a0,0(a5)
    8000524e:	c925                	beqz	a0,800052be <exec+0x224>
    80005250:	e9040993          	addi	s3,s0,-368
    80005254:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005258:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000525a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	bf2080e7          	jalr	-1038(ra) # 80000e4e <strlen>
    80005264:	0015079b          	addiw	a5,a0,1
    80005268:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000526c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005270:	13596663          	bltu	s2,s5,8000539c <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005274:	df043d83          	ld	s11,-528(s0)
    80005278:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000527c:	8552                	mv	a0,s4
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	bd0080e7          	jalr	-1072(ra) # 80000e4e <strlen>
    80005286:	0015069b          	addiw	a3,a0,1
    8000528a:	8652                	mv	a2,s4
    8000528c:	85ca                	mv	a1,s2
    8000528e:	855a                	mv	a0,s6
    80005290:	ffffc097          	auipc	ra,0xffffc
    80005294:	3dc080e7          	jalr	988(ra) # 8000166c <copyout>
    80005298:	10054663          	bltz	a0,800053a4 <exec+0x30a>
    ustack[argc] = sp;
    8000529c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052a0:	0485                	addi	s1,s1,1
    800052a2:	008d8793          	addi	a5,s11,8
    800052a6:	def43823          	sd	a5,-528(s0)
    800052aa:	008db503          	ld	a0,8(s11)
    800052ae:	c911                	beqz	a0,800052c2 <exec+0x228>
    if(argc >= MAXARG)
    800052b0:	09a1                	addi	s3,s3,8
    800052b2:	fb3c95e3          	bne	s9,s3,8000525c <exec+0x1c2>
  sz = sz1;
    800052b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ba:	4a81                	li	s5,0
    800052bc:	a84d                	j	8000536e <exec+0x2d4>
  sp = sz;
    800052be:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052c0:	4481                	li	s1,0
  ustack[argc] = 0;
    800052c2:	00349793          	slli	a5,s1,0x3
    800052c6:	f9078793          	addi	a5,a5,-112
    800052ca:	97a2                	add	a5,a5,s0
    800052cc:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800052d0:	00148693          	addi	a3,s1,1
    800052d4:	068e                	slli	a3,a3,0x3
    800052d6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052da:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052de:	01597663          	bgeu	s2,s5,800052ea <exec+0x250>
  sz = sz1;
    800052e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052e6:	4a81                	li	s5,0
    800052e8:	a059                	j	8000536e <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052ea:	e9040613          	addi	a2,s0,-368
    800052ee:	85ca                	mv	a1,s2
    800052f0:	855a                	mv	a0,s6
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	37a080e7          	jalr	890(ra) # 8000166c <copyout>
    800052fa:	0a054963          	bltz	a0,800053ac <exec+0x312>
  p->trapframe->a1 = sp;
    800052fe:	058bb783          	ld	a5,88(s7)
    80005302:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005306:	de843783          	ld	a5,-536(s0)
    8000530a:	0007c703          	lbu	a4,0(a5)
    8000530e:	cf11                	beqz	a4,8000532a <exec+0x290>
    80005310:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005312:	02f00693          	li	a3,47
    80005316:	a039                	j	80005324 <exec+0x28a>
      last = s+1;
    80005318:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000531c:	0785                	addi	a5,a5,1
    8000531e:	fff7c703          	lbu	a4,-1(a5)
    80005322:	c701                	beqz	a4,8000532a <exec+0x290>
    if(*s == '/')
    80005324:	fed71ce3          	bne	a4,a3,8000531c <exec+0x282>
    80005328:	bfc5                	j	80005318 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000532a:	4641                	li	a2,16
    8000532c:	de843583          	ld	a1,-536(s0)
    80005330:	158b8513          	addi	a0,s7,344
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	ae8080e7          	jalr	-1304(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000533c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005340:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005344:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005348:	058bb783          	ld	a5,88(s7)
    8000534c:	e6843703          	ld	a4,-408(s0)
    80005350:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005352:	058bb783          	ld	a5,88(s7)
    80005356:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000535a:	85ea                	mv	a1,s10
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	7b0080e7          	jalr	1968(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005364:	0004851b          	sext.w	a0,s1
    80005368:	b3f9                	j	80005136 <exec+0x9c>
    8000536a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000536e:	df843583          	ld	a1,-520(s0)
    80005372:	855a                	mv	a0,s6
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	798080e7          	jalr	1944(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000537c:	da0a93e3          	bnez	s5,80005122 <exec+0x88>
  return -1;
    80005380:	557d                	li	a0,-1
    80005382:	bb55                	j	80005136 <exec+0x9c>
    80005384:	df243c23          	sd	s2,-520(s0)
    80005388:	b7dd                	j	8000536e <exec+0x2d4>
    8000538a:	df243c23          	sd	s2,-520(s0)
    8000538e:	b7c5                	j	8000536e <exec+0x2d4>
    80005390:	df243c23          	sd	s2,-520(s0)
    80005394:	bfe9                	j	8000536e <exec+0x2d4>
    80005396:	df243c23          	sd	s2,-520(s0)
    8000539a:	bfd1                	j	8000536e <exec+0x2d4>
  sz = sz1;
    8000539c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053a0:	4a81                	li	s5,0
    800053a2:	b7f1                	j	8000536e <exec+0x2d4>
  sz = sz1;
    800053a4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053a8:	4a81                	li	s5,0
    800053aa:	b7d1                	j	8000536e <exec+0x2d4>
  sz = sz1;
    800053ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053b0:	4a81                	li	s5,0
    800053b2:	bf75                	j	8000536e <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053b4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053b8:	e0843783          	ld	a5,-504(s0)
    800053bc:	0017869b          	addiw	a3,a5,1
    800053c0:	e0d43423          	sd	a3,-504(s0)
    800053c4:	e0043783          	ld	a5,-512(s0)
    800053c8:	0387879b          	addiw	a5,a5,56
    800053cc:	e8845703          	lhu	a4,-376(s0)
    800053d0:	e0e6dfe3          	bge	a3,a4,800051ee <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053d4:	2781                	sext.w	a5,a5
    800053d6:	e0f43023          	sd	a5,-512(s0)
    800053da:	03800713          	li	a4,56
    800053de:	86be                	mv	a3,a5
    800053e0:	e1840613          	addi	a2,s0,-488
    800053e4:	4581                	li	a1,0
    800053e6:	8556                	mv	a0,s5
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	a58080e7          	jalr	-1448(ra) # 80003e40 <readi>
    800053f0:	03800793          	li	a5,56
    800053f4:	f6f51be3          	bne	a0,a5,8000536a <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800053f8:	e1842783          	lw	a5,-488(s0)
    800053fc:	4705                	li	a4,1
    800053fe:	fae79de3          	bne	a5,a4,800053b8 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005402:	e4043483          	ld	s1,-448(s0)
    80005406:	e3843783          	ld	a5,-456(s0)
    8000540a:	f6f4ede3          	bltu	s1,a5,80005384 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000540e:	e2843783          	ld	a5,-472(s0)
    80005412:	94be                	add	s1,s1,a5
    80005414:	f6f4ebe3          	bltu	s1,a5,8000538a <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005418:	de043703          	ld	a4,-544(s0)
    8000541c:	8ff9                	and	a5,a5,a4
    8000541e:	fbad                	bnez	a5,80005390 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005420:	e1c42503          	lw	a0,-484(s0)
    80005424:	00000097          	auipc	ra,0x0
    80005428:	c5c080e7          	jalr	-932(ra) # 80005080 <flags2perm>
    8000542c:	86aa                	mv	a3,a0
    8000542e:	8626                	mv	a2,s1
    80005430:	85ca                	mv	a1,s2
    80005432:	855a                	mv	a0,s6
    80005434:	ffffc097          	auipc	ra,0xffffc
    80005438:	fdc080e7          	jalr	-36(ra) # 80001410 <uvmalloc>
    8000543c:	dea43c23          	sd	a0,-520(s0)
    80005440:	d939                	beqz	a0,80005396 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005442:	e2843c03          	ld	s8,-472(s0)
    80005446:	e2042c83          	lw	s9,-480(s0)
    8000544a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000544e:	f60b83e3          	beqz	s7,800053b4 <exec+0x31a>
    80005452:	89de                	mv	s3,s7
    80005454:	4481                	li	s1,0
    80005456:	bb9d                	j	800051cc <exec+0x132>

0000000080005458 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005458:	1101                	addi	sp,sp,-32
    8000545a:	ec06                	sd	ra,24(sp)
    8000545c:	e822                	sd	s0,16(sp)
    8000545e:	e426                	sd	s1,8(sp)
    80005460:	1000                	addi	s0,sp,32
    80005462:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	548080e7          	jalr	1352(ra) # 800019ac <myproc>
    8000546c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000546e:	0d050793          	addi	a5,a0,208
    80005472:	4501                	li	a0,0
    80005474:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005476:	6398                	ld	a4,0(a5)
    80005478:	cb19                	beqz	a4,8000548e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000547a:	2505                	addiw	a0,a0,1
    8000547c:	07a1                	addi	a5,a5,8
    8000547e:	fed51ce3          	bne	a0,a3,80005476 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005482:	557d                	li	a0,-1
}
    80005484:	60e2                	ld	ra,24(sp)
    80005486:	6442                	ld	s0,16(sp)
    80005488:	64a2                	ld	s1,8(sp)
    8000548a:	6105                	addi	sp,sp,32
    8000548c:	8082                	ret
      p->ofile[fd] = f;
    8000548e:	01a50793          	addi	a5,a0,26
    80005492:	078e                	slli	a5,a5,0x3
    80005494:	963e                	add	a2,a2,a5
    80005496:	e204                	sd	s1,0(a2)
      return fd;
    80005498:	b7f5                	j	80005484 <fdalloc+0x2c>

000000008000549a <argfd>:
{
    8000549a:	7179                	addi	sp,sp,-48
    8000549c:	f406                	sd	ra,40(sp)
    8000549e:	f022                	sd	s0,32(sp)
    800054a0:	ec26                	sd	s1,24(sp)
    800054a2:	e84a                	sd	s2,16(sp)
    800054a4:	1800                	addi	s0,sp,48
    800054a6:	892e                	mv	s2,a1
    800054a8:	84b2                	mv	s1,a2
  argint(n, &fd);
    800054aa:	fdc40593          	addi	a1,s0,-36
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	8e0080e7          	jalr	-1824(ra) # 80002d8e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054b6:	fdc42703          	lw	a4,-36(s0)
    800054ba:	47bd                	li	a5,15
    800054bc:	02e7eb63          	bltu	a5,a4,800054f2 <argfd+0x58>
    800054c0:	ffffc097          	auipc	ra,0xffffc
    800054c4:	4ec080e7          	jalr	1260(ra) # 800019ac <myproc>
    800054c8:	fdc42703          	lw	a4,-36(s0)
    800054cc:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc3ea>
    800054d0:	078e                	slli	a5,a5,0x3
    800054d2:	953e                	add	a0,a0,a5
    800054d4:	611c                	ld	a5,0(a0)
    800054d6:	c385                	beqz	a5,800054f6 <argfd+0x5c>
  if(pfd)
    800054d8:	00090463          	beqz	s2,800054e0 <argfd+0x46>
    *pfd = fd;
    800054dc:	00e92023          	sw	a4,0(s2)
  return 0;
    800054e0:	4501                	li	a0,0
  if(pf)
    800054e2:	c091                	beqz	s1,800054e6 <argfd+0x4c>
    *pf = f;
    800054e4:	e09c                	sd	a5,0(s1)
}
    800054e6:	70a2                	ld	ra,40(sp)
    800054e8:	7402                	ld	s0,32(sp)
    800054ea:	64e2                	ld	s1,24(sp)
    800054ec:	6942                	ld	s2,16(sp)
    800054ee:	6145                	addi	sp,sp,48
    800054f0:	8082                	ret
    return -1;
    800054f2:	557d                	li	a0,-1
    800054f4:	bfcd                	j	800054e6 <argfd+0x4c>
    800054f6:	557d                	li	a0,-1
    800054f8:	b7fd                	j	800054e6 <argfd+0x4c>

00000000800054fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054fa:	715d                	addi	sp,sp,-80
    800054fc:	e486                	sd	ra,72(sp)
    800054fe:	e0a2                	sd	s0,64(sp)
    80005500:	fc26                	sd	s1,56(sp)
    80005502:	f84a                	sd	s2,48(sp)
    80005504:	f44e                	sd	s3,40(sp)
    80005506:	f052                	sd	s4,32(sp)
    80005508:	ec56                	sd	s5,24(sp)
    8000550a:	e85a                	sd	s6,16(sp)
    8000550c:	0880                	addi	s0,sp,80
    8000550e:	8b2e                	mv	s6,a1
    80005510:	89b2                	mv	s3,a2
    80005512:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005514:	fb040593          	addi	a1,s0,-80
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	e3e080e7          	jalr	-450(ra) # 80004356 <nameiparent>
    80005520:	84aa                	mv	s1,a0
    80005522:	14050f63          	beqz	a0,80005680 <create+0x186>
    return 0;

  ilock(dp);
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	666080e7          	jalr	1638(ra) # 80003b8c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000552e:	4601                	li	a2,0
    80005530:	fb040593          	addi	a1,s0,-80
    80005534:	8526                	mv	a0,s1
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	b3a080e7          	jalr	-1222(ra) # 80004070 <dirlookup>
    8000553e:	8aaa                	mv	s5,a0
    80005540:	c931                	beqz	a0,80005594 <create+0x9a>
    iunlockput(dp);
    80005542:	8526                	mv	a0,s1
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	8aa080e7          	jalr	-1878(ra) # 80003dee <iunlockput>
    ilock(ip);
    8000554c:	8556                	mv	a0,s5
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	63e080e7          	jalr	1598(ra) # 80003b8c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005556:	000b059b          	sext.w	a1,s6
    8000555a:	4789                	li	a5,2
    8000555c:	02f59563          	bne	a1,a5,80005586 <create+0x8c>
    80005560:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc414>
    80005564:	37f9                	addiw	a5,a5,-2
    80005566:	17c2                	slli	a5,a5,0x30
    80005568:	93c1                	srli	a5,a5,0x30
    8000556a:	4705                	li	a4,1
    8000556c:	00f76d63          	bltu	a4,a5,80005586 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005570:	8556                	mv	a0,s5
    80005572:	60a6                	ld	ra,72(sp)
    80005574:	6406                	ld	s0,64(sp)
    80005576:	74e2                	ld	s1,56(sp)
    80005578:	7942                	ld	s2,48(sp)
    8000557a:	79a2                	ld	s3,40(sp)
    8000557c:	7a02                	ld	s4,32(sp)
    8000557e:	6ae2                	ld	s5,24(sp)
    80005580:	6b42                	ld	s6,16(sp)
    80005582:	6161                	addi	sp,sp,80
    80005584:	8082                	ret
    iunlockput(ip);
    80005586:	8556                	mv	a0,s5
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	866080e7          	jalr	-1946(ra) # 80003dee <iunlockput>
    return 0;
    80005590:	4a81                	li	s5,0
    80005592:	bff9                	j	80005570 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005594:	85da                	mv	a1,s6
    80005596:	4088                	lw	a0,0(s1)
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	456080e7          	jalr	1110(ra) # 800039ee <ialloc>
    800055a0:	8a2a                	mv	s4,a0
    800055a2:	c539                	beqz	a0,800055f0 <create+0xf6>
  ilock(ip);
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	5e8080e7          	jalr	1512(ra) # 80003b8c <ilock>
  ip->major = major;
    800055ac:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800055b0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800055b4:	4905                	li	s2,1
    800055b6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800055ba:	8552                	mv	a0,s4
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	504080e7          	jalr	1284(ra) # 80003ac0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055c4:	000b059b          	sext.w	a1,s6
    800055c8:	03258b63          	beq	a1,s2,800055fe <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800055cc:	004a2603          	lw	a2,4(s4)
    800055d0:	fb040593          	addi	a1,s0,-80
    800055d4:	8526                	mv	a0,s1
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	cb0080e7          	jalr	-848(ra) # 80004286 <dirlink>
    800055de:	06054f63          	bltz	a0,8000565c <create+0x162>
  iunlockput(dp);
    800055e2:	8526                	mv	a0,s1
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	80a080e7          	jalr	-2038(ra) # 80003dee <iunlockput>
  return ip;
    800055ec:	8ad2                	mv	s5,s4
    800055ee:	b749                	j	80005570 <create+0x76>
    iunlockput(dp);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	7fc080e7          	jalr	2044(ra) # 80003dee <iunlockput>
    return 0;
    800055fa:	8ad2                	mv	s5,s4
    800055fc:	bf95                	j	80005570 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055fe:	004a2603          	lw	a2,4(s4)
    80005602:	00003597          	auipc	a1,0x3
    80005606:	1fe58593          	addi	a1,a1,510 # 80008800 <syscalls+0x3b0>
    8000560a:	8552                	mv	a0,s4
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	c7a080e7          	jalr	-902(ra) # 80004286 <dirlink>
    80005614:	04054463          	bltz	a0,8000565c <create+0x162>
    80005618:	40d0                	lw	a2,4(s1)
    8000561a:	00003597          	auipc	a1,0x3
    8000561e:	1ee58593          	addi	a1,a1,494 # 80008808 <syscalls+0x3b8>
    80005622:	8552                	mv	a0,s4
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	c62080e7          	jalr	-926(ra) # 80004286 <dirlink>
    8000562c:	02054863          	bltz	a0,8000565c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005630:	004a2603          	lw	a2,4(s4)
    80005634:	fb040593          	addi	a1,s0,-80
    80005638:	8526                	mv	a0,s1
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	c4c080e7          	jalr	-948(ra) # 80004286 <dirlink>
    80005642:	00054d63          	bltz	a0,8000565c <create+0x162>
    dp->nlink++;  // for ".."
    80005646:	04a4d783          	lhu	a5,74(s1)
    8000564a:	2785                	addiw	a5,a5,1
    8000564c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	46e080e7          	jalr	1134(ra) # 80003ac0 <iupdate>
    8000565a:	b761                	j	800055e2 <create+0xe8>
  ip->nlink = 0;
    8000565c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005660:	8552                	mv	a0,s4
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	45e080e7          	jalr	1118(ra) # 80003ac0 <iupdate>
  iunlockput(ip);
    8000566a:	8552                	mv	a0,s4
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	782080e7          	jalr	1922(ra) # 80003dee <iunlockput>
  iunlockput(dp);
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	778080e7          	jalr	1912(ra) # 80003dee <iunlockput>
  return 0;
    8000567e:	bdcd                	j	80005570 <create+0x76>
    return 0;
    80005680:	8aaa                	mv	s5,a0
    80005682:	b5fd                	j	80005570 <create+0x76>

0000000080005684 <sys_dup>:
{
    80005684:	7179                	addi	sp,sp,-48
    80005686:	f406                	sd	ra,40(sp)
    80005688:	f022                	sd	s0,32(sp)
    8000568a:	ec26                	sd	s1,24(sp)
    8000568c:	e84a                	sd	s2,16(sp)
    8000568e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005690:	fd840613          	addi	a2,s0,-40
    80005694:	4581                	li	a1,0
    80005696:	4501                	li	a0,0
    80005698:	00000097          	auipc	ra,0x0
    8000569c:	e02080e7          	jalr	-510(ra) # 8000549a <argfd>
    return -1;
    800056a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056a2:	02054c63          	bltz	a0,800056da <sys_dup+0x56>
  if((fd=fdalloc(f)) < 0)
    800056a6:	fd843903          	ld	s2,-40(s0)
    800056aa:	854a                	mv	a0,s2
    800056ac:	00000097          	auipc	ra,0x0
    800056b0:	dac080e7          	jalr	-596(ra) # 80005458 <fdalloc>
    800056b4:	84aa                	mv	s1,a0
    return -1;
    800056b6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056b8:	02054163          	bltz	a0,800056da <sys_dup+0x56>
  filedup(f);
    800056bc:	854a                	mv	a0,s2
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	310080e7          	jalr	784(ra) # 800049ce <filedup>
  struct proc *p = myproc();
    800056c6:	ffffc097          	auipc	ra,0xffffc
    800056ca:	2e6080e7          	jalr	742(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_dup))
    800056ce:	17853783          	ld	a5,376(a0)
    800056d2:	4007f793          	andi	a5,a5,1024
    800056d6:	eb89                	bnez	a5,800056e8 <sys_dup+0x64>
  return fd;
    800056d8:	87a6                	mv	a5,s1
}
    800056da:	853e                	mv	a0,a5
    800056dc:	70a2                	ld	ra,40(sp)
    800056de:	7402                	ld	s0,32(sp)
    800056e0:	64e2                	ld	s1,24(sp)
    800056e2:	6942                	ld	s2,16(sp)
    800056e4:	6145                	addi	sp,sp,48
    800056e6:	8082                	ret
    printf("%d: syscall dup (file_ptr) -> %d\n", p->pid, fd);
    800056e8:	8626                	mv	a2,s1
    800056ea:	590c                	lw	a1,48(a0)
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	12450513          	addi	a0,a0,292 # 80008810 <syscalls+0x3c0>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e96080e7          	jalr	-362(ra) # 8000058a <printf>
    800056fc:	bff1                	j	800056d8 <sys_dup+0x54>

00000000800056fe <sys_read>:
{
    800056fe:	7139                	addi	sp,sp,-64
    80005700:	fc06                	sd	ra,56(sp)
    80005702:	f822                	sd	s0,48(sp)
    80005704:	f426                	sd	s1,40(sp)
    80005706:	0080                	addi	s0,sp,64
  argaddr(1, &p);
    80005708:	fc840593          	addi	a1,s0,-56
    8000570c:	4505                	li	a0,1
    8000570e:	ffffd097          	auipc	ra,0xffffd
    80005712:	6a0080e7          	jalr	1696(ra) # 80002dae <argaddr>
  argint(2, &n);
    80005716:	fd440593          	addi	a1,s0,-44
    8000571a:	4509                	li	a0,2
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	672080e7          	jalr	1650(ra) # 80002d8e <argint>
  if(argfd(0, 0, &f) < 0)
    80005724:	fd840613          	addi	a2,s0,-40
    80005728:	4581                	li	a1,0
    8000572a:	4501                	li	a0,0
    8000572c:	00000097          	auipc	ra,0x0
    80005730:	d6e080e7          	jalr	-658(ra) # 8000549a <argfd>
    80005734:	87aa                	mv	a5,a0
    return -1;
    80005736:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005738:	0207c763          	bltz	a5,80005766 <sys_read+0x68>
  int ret = fileread(f, p, n);
    8000573c:	fd442603          	lw	a2,-44(s0)
    80005740:	fc843583          	ld	a1,-56(s0)
    80005744:	fd843503          	ld	a0,-40(s0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	412080e7          	jalr	1042(ra) # 80004b5a <fileread>
    80005750:	84aa                	mv	s1,a0
  struct proc *myp = myproc();
    80005752:	ffffc097          	auipc	ra,0xffffc
    80005756:	25a080e7          	jalr	602(ra) # 800019ac <myproc>
  if (myp->strace_m & (1 << SYS_read))
    8000575a:	17853783          	ld	a5,376(a0)
    8000575e:	0207f793          	andi	a5,a5,32
    80005762:	e799                	bnez	a5,80005770 <sys_read+0x72>
  return ret;
    80005764:	8526                	mv	a0,s1
}
    80005766:	70e2                	ld	ra,56(sp)
    80005768:	7442                	ld	s0,48(sp)
    8000576a:	74a2                	ld	s1,40(sp)
    8000576c:	6121                	addi	sp,sp,64
    8000576e:	8082                	ret
    printf("%d: syscall read (file_ptr %d %d) -> %d\n", myp->pid, p, n, ret);
    80005770:	8726                	mv	a4,s1
    80005772:	fd442683          	lw	a3,-44(s0)
    80005776:	fc843603          	ld	a2,-56(s0)
    8000577a:	590c                	lw	a1,48(a0)
    8000577c:	00003517          	auipc	a0,0x3
    80005780:	0bc50513          	addi	a0,a0,188 # 80008838 <syscalls+0x3e8>
    80005784:	ffffb097          	auipc	ra,0xffffb
    80005788:	e06080e7          	jalr	-506(ra) # 8000058a <printf>
    8000578c:	bfe1                	j	80005764 <sys_read+0x66>

000000008000578e <sys_write>:
{
    8000578e:	7139                	addi	sp,sp,-64
    80005790:	fc06                	sd	ra,56(sp)
    80005792:	f822                	sd	s0,48(sp)
    80005794:	f426                	sd	s1,40(sp)
    80005796:	0080                	addi	s0,sp,64
  argaddr(1, &p);
    80005798:	fc840593          	addi	a1,s0,-56
    8000579c:	4505                	li	a0,1
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	610080e7          	jalr	1552(ra) # 80002dae <argaddr>
  argint(2, &n);
    800057a6:	fd440593          	addi	a1,s0,-44
    800057aa:	4509                	li	a0,2
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	5e2080e7          	jalr	1506(ra) # 80002d8e <argint>
  if(argfd(0, 0, &f) < 0)
    800057b4:	fd840613          	addi	a2,s0,-40
    800057b8:	4581                	li	a1,0
    800057ba:	4501                	li	a0,0
    800057bc:	00000097          	auipc	ra,0x0
    800057c0:	cde080e7          	jalr	-802(ra) # 8000549a <argfd>
    800057c4:	87aa                	mv	a5,a0
    return -1;
    800057c6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057c8:	0207c663          	bltz	a5,800057f4 <sys_write+0x66>
  int ret = filewrite(f, p, n);
    800057cc:	fd442603          	lw	a2,-44(s0)
    800057d0:	fc843583          	ld	a1,-56(s0)
    800057d4:	fd843503          	ld	a0,-40(s0)
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	444080e7          	jalr	1092(ra) # 80004c1c <filewrite>
    800057e0:	84aa                	mv	s1,a0
  struct proc *myp = myproc();
    800057e2:	ffffc097          	auipc	ra,0xffffc
    800057e6:	1ca080e7          	jalr	458(ra) # 800019ac <myproc>
  if (myp->strace_m & (1 << SYS_wait))
    800057ea:	17853783          	ld	a5,376(a0)
    800057ee:	8ba1                	andi	a5,a5,8
    800057f0:	e799                	bnez	a5,800057fe <sys_write+0x70>
  return ret;
    800057f2:	8526                	mv	a0,s1
}
    800057f4:	70e2                	ld	ra,56(sp)
    800057f6:	7442                	ld	s0,48(sp)
    800057f8:	74a2                	ld	s1,40(sp)
    800057fa:	6121                	addi	sp,sp,64
    800057fc:	8082                	ret
    printf("%d: syscall write (%d %d) -> %d\n", myp->pid, p, n, ret);
    800057fe:	8726                	mv	a4,s1
    80005800:	fd442683          	lw	a3,-44(s0)
    80005804:	fc843603          	ld	a2,-56(s0)
    80005808:	590c                	lw	a1,48(a0)
    8000580a:	00003517          	auipc	a0,0x3
    8000580e:	05e50513          	addi	a0,a0,94 # 80008868 <syscalls+0x418>
    80005812:	ffffb097          	auipc	ra,0xffffb
    80005816:	d78080e7          	jalr	-648(ra) # 8000058a <printf>
    8000581a:	bfe1                	j	800057f2 <sys_write+0x64>

000000008000581c <sys_close>:
{
    8000581c:	7179                	addi	sp,sp,-48
    8000581e:	f406                	sd	ra,40(sp)
    80005820:	f022                	sd	s0,32(sp)
    80005822:	ec26                	sd	s1,24(sp)
    80005824:	e84a                	sd	s2,16(sp)
    80005826:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80005828:	ffffc097          	auipc	ra,0xffffc
    8000582c:	184080e7          	jalr	388(ra) # 800019ac <myproc>
    80005830:	84aa                	mv	s1,a0
  if(argfd(0, &fd, &f) < 0)
    80005832:	fd040613          	addi	a2,s0,-48
    80005836:	fdc40593          	addi	a1,s0,-36
    8000583a:	4501                	li	a0,0
    8000583c:	00000097          	auipc	ra,0x0
    80005840:	c5e080e7          	jalr	-930(ra) # 8000549a <argfd>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005846:	02054663          	bltz	a0,80005872 <sys_close+0x56>
  p->ofile[fd] = 0;
    8000584a:	fdc42903          	lw	s2,-36(s0)
    8000584e:	01a90793          	addi	a5,s2,26
    80005852:	078e                	slli	a5,a5,0x3
    80005854:	97a6                	add	a5,a5,s1
    80005856:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000585a:	fd043503          	ld	a0,-48(s0)
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	1c2080e7          	jalr	450(ra) # 80004a20 <fileclose>
  if (p->strace_m & (1 << SYS_close))
    80005866:	1784b703          	ld	a4,376(s1)
    8000586a:	002007b7          	lui	a5,0x200
    8000586e:	8ff9                	and	a5,a5,a4
    80005870:	eb81                	bnez	a5,80005880 <sys_close+0x64>
}
    80005872:	853e                	mv	a0,a5
    80005874:	70a2                	ld	ra,40(sp)
    80005876:	7402                	ld	s0,32(sp)
    80005878:	64e2                	ld	s1,24(sp)
    8000587a:	6942                	ld	s2,16(sp)
    8000587c:	6145                	addi	sp,sp,48
    8000587e:	8082                	ret
    printf("%d: syscall close (%d) -> 0\n", p->pid, fd);
    80005880:	864a                	mv	a2,s2
    80005882:	588c                	lw	a1,48(s1)
    80005884:	00003517          	auipc	a0,0x3
    80005888:	00c50513          	addi	a0,a0,12 # 80008890 <syscalls+0x440>
    8000588c:	ffffb097          	auipc	ra,0xffffb
    80005890:	cfe080e7          	jalr	-770(ra) # 8000058a <printf>
  return 0;
    80005894:	4781                	li	a5,0
    80005896:	bff1                	j	80005872 <sys_close+0x56>

0000000080005898 <sys_fstat>:
{
    80005898:	7179                	addi	sp,sp,-48
    8000589a:	f406                	sd	ra,40(sp)
    8000589c:	f022                	sd	s0,32(sp)
    8000589e:	ec26                	sd	s1,24(sp)
    800058a0:	1800                	addi	s0,sp,48
  argaddr(1, &st);
    800058a2:	fd040593          	addi	a1,s0,-48
    800058a6:	4505                	li	a0,1
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	506080e7          	jalr	1286(ra) # 80002dae <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058b0:	fd840613          	addi	a2,s0,-40
    800058b4:	4581                	li	a1,0
    800058b6:	4501                	li	a0,0
    800058b8:	00000097          	auipc	ra,0x0
    800058bc:	be2080e7          	jalr	-1054(ra) # 8000549a <argfd>
    800058c0:	87aa                	mv	a5,a0
    return -1;
    800058c2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058c4:	0207c463          	bltz	a5,800058ec <sys_fstat+0x54>
  int ret = filestat(f, st);
    800058c8:	fd043583          	ld	a1,-48(s0)
    800058cc:	fd843503          	ld	a0,-40(s0)
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	218080e7          	jalr	536(ra) # 80004ae8 <filestat>
    800058d8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800058da:	ffffc097          	auipc	ra,0xffffc
    800058de:	0d2080e7          	jalr	210(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_wait))
    800058e2:	17853783          	ld	a5,376(a0)
    800058e6:	8ba1                	andi	a5,a5,8
    800058e8:	e799                	bnez	a5,800058f6 <sys_fstat+0x5e>
  return ret;
    800058ea:	8526                	mv	a0,s1
}
    800058ec:	70a2                	ld	ra,40(sp)
    800058ee:	7402                	ld	s0,32(sp)
    800058f0:	64e2                	ld	s1,24(sp)
    800058f2:	6145                	addi	sp,sp,48
    800058f4:	8082                	ret
    printf("%d: syscall fstat (%d) -> %d\n", p->pid, st, ret);
    800058f6:	86a6                	mv	a3,s1
    800058f8:	fd043603          	ld	a2,-48(s0)
    800058fc:	590c                	lw	a1,48(a0)
    800058fe:	00003517          	auipc	a0,0x3
    80005902:	fb250513          	addi	a0,a0,-78 # 800088b0 <syscalls+0x460>
    80005906:	ffffb097          	auipc	ra,0xffffb
    8000590a:	c84080e7          	jalr	-892(ra) # 8000058a <printf>
    8000590e:	bff1                	j	800058ea <sys_fstat+0x52>

0000000080005910 <sys_link>:
{
    80005910:	7169                	addi	sp,sp,-304
    80005912:	f606                	sd	ra,296(sp)
    80005914:	f222                	sd	s0,288(sp)
    80005916:	ee26                	sd	s1,280(sp)
    80005918:	ea4a                	sd	s2,272(sp)
    8000591a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000591c:	08000613          	li	a2,128
    80005920:	ed040593          	addi	a1,s0,-304
    80005924:	4501                	li	a0,0
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	4a8080e7          	jalr	1192(ra) # 80002dce <argstr>
    return -1;
    8000592e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005930:	14054163          	bltz	a0,80005a72 <sys_link+0x162>
    80005934:	08000613          	li	a2,128
    80005938:	f5040593          	addi	a1,s0,-176
    8000593c:	4505                	li	a0,1
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	490080e7          	jalr	1168(ra) # 80002dce <argstr>
    return -1;
    80005946:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005948:	12054563          	bltz	a0,80005a72 <sys_link+0x162>
  begin_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	c0c080e7          	jalr	-1012(ra) # 80004558 <begin_op>
  if((ip = namei(old)) == 0){
    80005954:	ed040513          	addi	a0,s0,-304
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	9e0080e7          	jalr	-1568(ra) # 80004338 <namei>
    80005960:	84aa                	mv	s1,a0
    80005962:	c94d                	beqz	a0,80005a14 <sys_link+0x104>
  ilock(ip);
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	228080e7          	jalr	552(ra) # 80003b8c <ilock>
  if(ip->type == T_DIR){
    8000596c:	04449703          	lh	a4,68(s1)
    80005970:	4785                	li	a5,1
    80005972:	0af70763          	beq	a4,a5,80005a20 <sys_link+0x110>
  ip->nlink++;
    80005976:	04a4d783          	lhu	a5,74(s1)
    8000597a:	2785                	addiw	a5,a5,1 # 200001 <_entry-0x7fdfffff>
    8000597c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	13e080e7          	jalr	318(ra) # 80003ac0 <iupdate>
  iunlock(ip);
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	2c2080e7          	jalr	706(ra) # 80003c4e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005994:	fd040593          	addi	a1,s0,-48
    80005998:	f5040513          	addi	a0,s0,-176
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	9ba080e7          	jalr	-1606(ra) # 80004356 <nameiparent>
    800059a4:	892a                	mv	s2,a0
    800059a6:	cd49                	beqz	a0,80005a40 <sys_link+0x130>
  ilock(dp);
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	1e4080e7          	jalr	484(ra) # 80003b8c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059b0:	00092703          	lw	a4,0(s2)
    800059b4:	409c                	lw	a5,0(s1)
    800059b6:	08f71063          	bne	a4,a5,80005a36 <sys_link+0x126>
    800059ba:	40d0                	lw	a2,4(s1)
    800059bc:	fd040593          	addi	a1,s0,-48
    800059c0:	854a                	mv	a0,s2
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	8c4080e7          	jalr	-1852(ra) # 80004286 <dirlink>
    800059ca:	06054663          	bltz	a0,80005a36 <sys_link+0x126>
  iunlockput(dp);
    800059ce:	854a                	mv	a0,s2
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	41e080e7          	jalr	1054(ra) # 80003dee <iunlockput>
  iput(ip);
    800059d8:	8526                	mv	a0,s1
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	36c080e7          	jalr	876(ra) # 80003d46 <iput>
  end_op();
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	bf4080e7          	jalr	-1036(ra) # 800045d6 <end_op>
  struct proc *p = myproc();
    800059ea:	ffffc097          	auipc	ra,0xffffc
    800059ee:	fc2080e7          	jalr	-62(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_link))
    800059f2:	17853703          	ld	a4,376(a0)
    800059f6:	000807b7          	lui	a5,0x80
    800059fa:	8ff9                	and	a5,a5,a4
    800059fc:	cbbd                	beqz	a5,80005a72 <sys_link+0x162>
    printf("%d: syscall link (str) -> 0\n", p->pid);
    800059fe:	590c                	lw	a1,48(a0)
    80005a00:	00003517          	auipc	a0,0x3
    80005a04:	ed050513          	addi	a0,a0,-304 # 800088d0 <syscalls+0x480>
    80005a08:	ffffb097          	auipc	ra,0xffffb
    80005a0c:	b82080e7          	jalr	-1150(ra) # 8000058a <printf>
  return 0;
    80005a10:	4781                	li	a5,0
    80005a12:	a085                	j	80005a72 <sys_link+0x162>
    end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	bc2080e7          	jalr	-1086(ra) # 800045d6 <end_op>
    return -1;
    80005a1c:	57fd                	li	a5,-1
    80005a1e:	a891                	j	80005a72 <sys_link+0x162>
    iunlockput(ip);
    80005a20:	8526                	mv	a0,s1
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	3cc080e7          	jalr	972(ra) # 80003dee <iunlockput>
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	bac080e7          	jalr	-1108(ra) # 800045d6 <end_op>
    return -1;
    80005a32:	57fd                	li	a5,-1
    80005a34:	a83d                	j	80005a72 <sys_link+0x162>
    iunlockput(dp);
    80005a36:	854a                	mv	a0,s2
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	3b6080e7          	jalr	950(ra) # 80003dee <iunlockput>
  ilock(ip);
    80005a40:	8526                	mv	a0,s1
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	14a080e7          	jalr	330(ra) # 80003b8c <ilock>
  ip->nlink--;
    80005a4a:	04a4d783          	lhu	a5,74(s1)
    80005a4e:	37fd                	addiw	a5,a5,-1 # 7ffff <_entry-0x7ff80001>
    80005a50:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a54:	8526                	mv	a0,s1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	06a080e7          	jalr	106(ra) # 80003ac0 <iupdate>
  iunlockput(ip);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	38e080e7          	jalr	910(ra) # 80003dee <iunlockput>
  end_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	b6e080e7          	jalr	-1170(ra) # 800045d6 <end_op>
  return -1;
    80005a70:	57fd                	li	a5,-1
}
    80005a72:	853e                	mv	a0,a5
    80005a74:	70b2                	ld	ra,296(sp)
    80005a76:	7412                	ld	s0,288(sp)
    80005a78:	64f2                	ld	s1,280(sp)
    80005a7a:	6952                	ld	s2,272(sp)
    80005a7c:	6155                	addi	sp,sp,304
    80005a7e:	8082                	ret

0000000080005a80 <sys_unlink>:
{
    80005a80:	7151                	addi	sp,sp,-240
    80005a82:	f586                	sd	ra,232(sp)
    80005a84:	f1a2                	sd	s0,224(sp)
    80005a86:	eda6                	sd	s1,216(sp)
    80005a88:	e9ca                	sd	s2,208(sp)
    80005a8a:	e5ce                	sd	s3,200(sp)
    80005a8c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a8e:	08000613          	li	a2,128
    80005a92:	f3040593          	addi	a1,s0,-208
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	336080e7          	jalr	822(ra) # 80002dce <argstr>
    80005aa0:	1a054763          	bltz	a0,80005c4e <sys_unlink+0x1ce>
  begin_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	ab4080e7          	jalr	-1356(ra) # 80004558 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005aac:	fb040593          	addi	a1,s0,-80
    80005ab0:	f3040513          	addi	a0,s0,-208
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	8a2080e7          	jalr	-1886(ra) # 80004356 <nameiparent>
    80005abc:	84aa                	mv	s1,a0
    80005abe:	10050163          	beqz	a0,80005bc0 <sys_unlink+0x140>
  ilock(dp);
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	0ca080e7          	jalr	202(ra) # 80003b8c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005aca:	00003597          	auipc	a1,0x3
    80005ace:	d3658593          	addi	a1,a1,-714 # 80008800 <syscalls+0x3b0>
    80005ad2:	fb040513          	addi	a0,s0,-80
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	580080e7          	jalr	1408(ra) # 80004056 <namecmp>
    80005ade:	16050f63          	beqz	a0,80005c5c <sys_unlink+0x1dc>
    80005ae2:	00003597          	auipc	a1,0x3
    80005ae6:	d2658593          	addi	a1,a1,-730 # 80008808 <syscalls+0x3b8>
    80005aea:	fb040513          	addi	a0,s0,-80
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	568080e7          	jalr	1384(ra) # 80004056 <namecmp>
    80005af6:	16050363          	beqz	a0,80005c5c <sys_unlink+0x1dc>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005afa:	f2c40613          	addi	a2,s0,-212
    80005afe:	fb040593          	addi	a1,s0,-80
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	56c080e7          	jalr	1388(ra) # 80004070 <dirlookup>
    80005b0c:	892a                	mv	s2,a0
    80005b0e:	14050763          	beqz	a0,80005c5c <sys_unlink+0x1dc>
  ilock(ip);
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	07a080e7          	jalr	122(ra) # 80003b8c <ilock>
  if(ip->nlink < 1)
    80005b1a:	04a91783          	lh	a5,74(s2)
    80005b1e:	0af05763          	blez	a5,80005bcc <sys_unlink+0x14c>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b22:	04491703          	lh	a4,68(s2)
    80005b26:	4785                	li	a5,1
    80005b28:	0af70a63          	beq	a4,a5,80005bdc <sys_unlink+0x15c>
  memset(&de, 0, sizeof(de));
    80005b2c:	4641                	li	a2,16
    80005b2e:	4581                	li	a1,0
    80005b30:	fc040513          	addi	a0,s0,-64
    80005b34:	ffffb097          	auipc	ra,0xffffb
    80005b38:	19e080e7          	jalr	414(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b3c:	4741                	li	a4,16
    80005b3e:	f2c42683          	lw	a3,-212(s0)
    80005b42:	fc040613          	addi	a2,s0,-64
    80005b46:	4581                	li	a1,0
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	3ee080e7          	jalr	1006(ra) # 80003f38 <writei>
    80005b52:	47c1                	li	a5,16
    80005b54:	0cf51a63          	bne	a0,a5,80005c28 <sys_unlink+0x1a8>
  if(ip->type == T_DIR){
    80005b58:	04491703          	lh	a4,68(s2)
    80005b5c:	4785                	li	a5,1
    80005b5e:	0cf70d63          	beq	a4,a5,80005c38 <sys_unlink+0x1b8>
  iunlockput(dp);
    80005b62:	8526                	mv	a0,s1
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	28a080e7          	jalr	650(ra) # 80003dee <iunlockput>
  ip->nlink--;
    80005b6c:	04a95783          	lhu	a5,74(s2)
    80005b70:	37fd                	addiw	a5,a5,-1
    80005b72:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b76:	854a                	mv	a0,s2
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	f48080e7          	jalr	-184(ra) # 80003ac0 <iupdate>
  iunlockput(ip);
    80005b80:	854a                	mv	a0,s2
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	26c080e7          	jalr	620(ra) # 80003dee <iunlockput>
  end_op();
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	a4c080e7          	jalr	-1460(ra) # 800045d6 <end_op>
  struct proc *p = myproc();
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	e1a080e7          	jalr	-486(ra) # 800019ac <myproc>
    80005b9a:	872a                	mv	a4,a0
  if (p->strace_m & (1 << SYS_unlink))
    80005b9c:	17853683          	ld	a3,376(a0)
    80005ba0:	000407b7          	lui	a5,0x40
    80005ba4:	00d7f533          	and	a0,a5,a3
    80005ba8:	c561                	beqz	a0,80005c70 <sys_unlink+0x1f0>
    printf("%d: syscall unlink (str) -> 0\n", p->pid);
    80005baa:	5b0c                	lw	a1,48(a4)
    80005bac:	00003517          	auipc	a0,0x3
    80005bb0:	d8450513          	addi	a0,a0,-636 # 80008930 <syscalls+0x4e0>
    80005bb4:	ffffb097          	auipc	ra,0xffffb
    80005bb8:	9d6080e7          	jalr	-1578(ra) # 8000058a <printf>
  return 0;
    80005bbc:	4501                	li	a0,0
    80005bbe:	a84d                	j	80005c70 <sys_unlink+0x1f0>
    end_op();
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	a16080e7          	jalr	-1514(ra) # 800045d6 <end_op>
    return -1;
    80005bc8:	557d                	li	a0,-1
    80005bca:	a05d                	j	80005c70 <sys_unlink+0x1f0>
    panic("unlink: nlink < 1");
    80005bcc:	00003517          	auipc	a0,0x3
    80005bd0:	d2450513          	addi	a0,a0,-732 # 800088f0 <syscalls+0x4a0>
    80005bd4:	ffffb097          	auipc	ra,0xffffb
    80005bd8:	96c080e7          	jalr	-1684(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bdc:	04c92703          	lw	a4,76(s2)
    80005be0:	02000793          	li	a5,32
    80005be4:	f4e7f4e3          	bgeu	a5,a4,80005b2c <sys_unlink+0xac>
    80005be8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bec:	4741                	li	a4,16
    80005bee:	86ce                	mv	a3,s3
    80005bf0:	f1840613          	addi	a2,s0,-232
    80005bf4:	4581                	li	a1,0
    80005bf6:	854a                	mv	a0,s2
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	248080e7          	jalr	584(ra) # 80003e40 <readi>
    80005c00:	47c1                	li	a5,16
    80005c02:	00f51b63          	bne	a0,a5,80005c18 <sys_unlink+0x198>
    if(de.inum != 0)
    80005c06:	f1845783          	lhu	a5,-232(s0)
    80005c0a:	e7a1                	bnez	a5,80005c52 <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c0c:	29c1                	addiw	s3,s3,16
    80005c0e:	04c92783          	lw	a5,76(s2)
    80005c12:	fcf9ede3          	bltu	s3,a5,80005bec <sys_unlink+0x16c>
    80005c16:	bf19                	j	80005b2c <sys_unlink+0xac>
      panic("isdirempty: readi");
    80005c18:	00003517          	auipc	a0,0x3
    80005c1c:	cf050513          	addi	a0,a0,-784 # 80008908 <syscalls+0x4b8>
    80005c20:	ffffb097          	auipc	ra,0xffffb
    80005c24:	920080e7          	jalr	-1760(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005c28:	00003517          	auipc	a0,0x3
    80005c2c:	cf850513          	addi	a0,a0,-776 # 80008920 <syscalls+0x4d0>
    80005c30:	ffffb097          	auipc	ra,0xffffb
    80005c34:	910080e7          	jalr	-1776(ra) # 80000540 <panic>
    dp->nlink--;
    80005c38:	04a4d783          	lhu	a5,74(s1)
    80005c3c:	37fd                	addiw	a5,a5,-1 # 3ffff <_entry-0x7ffc0001>
    80005c3e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c42:	8526                	mv	a0,s1
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	e7c080e7          	jalr	-388(ra) # 80003ac0 <iupdate>
    80005c4c:	bf19                	j	80005b62 <sys_unlink+0xe2>
    return -1;
    80005c4e:	557d                	li	a0,-1
    80005c50:	a005                	j	80005c70 <sys_unlink+0x1f0>
    iunlockput(ip);
    80005c52:	854a                	mv	a0,s2
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	19a080e7          	jalr	410(ra) # 80003dee <iunlockput>
  iunlockput(dp);
    80005c5c:	8526                	mv	a0,s1
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	190080e7          	jalr	400(ra) # 80003dee <iunlockput>
  end_op();
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	970080e7          	jalr	-1680(ra) # 800045d6 <end_op>
  return -1;
    80005c6e:	557d                	li	a0,-1
}
    80005c70:	70ae                	ld	ra,232(sp)
    80005c72:	740e                	ld	s0,224(sp)
    80005c74:	64ee                	ld	s1,216(sp)
    80005c76:	694e                	ld	s2,208(sp)
    80005c78:	69ae                	ld	s3,200(sp)
    80005c7a:	616d                	addi	sp,sp,240
    80005c7c:	8082                	ret

0000000080005c7e <sys_open>:

uint64
sys_open(void)
{
    80005c7e:	7131                	addi	sp,sp,-192
    80005c80:	fd06                	sd	ra,184(sp)
    80005c82:	f922                	sd	s0,176(sp)
    80005c84:	f526                	sd	s1,168(sp)
    80005c86:	f14a                	sd	s2,160(sp)
    80005c88:	ed4e                	sd	s3,152(sp)
    80005c8a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c8c:	f4c40593          	addi	a1,s0,-180
    80005c90:	4505                	li	a0,1
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	0fc080e7          	jalr	252(ra) # 80002d8e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c9a:	08000613          	li	a2,128
    80005c9e:	f5040593          	addi	a1,s0,-176
    80005ca2:	4501                	li	a0,0
    80005ca4:	ffffd097          	auipc	ra,0xffffd
    80005ca8:	12a080e7          	jalr	298(ra) # 80002dce <argstr>
    80005cac:	87aa                	mv	a5,a0
    return -1;
    80005cae:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cb0:	0c07c263          	bltz	a5,80005d74 <sys_open+0xf6>

  begin_op();
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	8a4080e7          	jalr	-1884(ra) # 80004558 <begin_op>

  if(omode & O_CREATE){
    80005cbc:	f4c42783          	lw	a5,-180(s0)
    80005cc0:	2007f793          	andi	a5,a5,512
    80005cc4:	c7e9                	beqz	a5,80005d8e <sys_open+0x110>
    ip = create(path, T_FILE, 0, 0);
    80005cc6:	4681                	li	a3,0
    80005cc8:	4601                	li	a2,0
    80005cca:	4589                	li	a1,2
    80005ccc:	f5040513          	addi	a0,s0,-176
    80005cd0:	00000097          	auipc	ra,0x0
    80005cd4:	82a080e7          	jalr	-2006(ra) # 800054fa <create>
    80005cd8:	84aa                	mv	s1,a0
    if(ip == 0){
    80005cda:	c545                	beqz	a0,80005d82 <sys_open+0x104>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cdc:	04449703          	lh	a4,68(s1)
    80005ce0:	478d                	li	a5,3
    80005ce2:	00f71763          	bne	a4,a5,80005cf0 <sys_open+0x72>
    80005ce6:	0464d703          	lhu	a4,70(s1)
    80005cea:	47a5                	li	a5,9
    80005cec:	0ee7e663          	bltu	a5,a4,80005dd8 <sys_open+0x15a>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	c74080e7          	jalr	-908(ra) # 80004964 <filealloc>
    80005cf8:	892a                	mv	s2,a0
    80005cfa:	12050963          	beqz	a0,80005e2c <sys_open+0x1ae>
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	75a080e7          	jalr	1882(ra) # 80005458 <fdalloc>
    80005d06:	89aa                	mv	s3,a0
    80005d08:	10054d63          	bltz	a0,80005e22 <sys_open+0x1a4>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d0c:	04449703          	lh	a4,68(s1)
    80005d10:	478d                	li	a5,3
    80005d12:	0cf70e63          	beq	a4,a5,80005dee <sys_open+0x170>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d16:	4789                	li	a5,2
    80005d18:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005d1c:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005d20:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005d24:	f4c42783          	lw	a5,-180(s0)
    80005d28:	0017c713          	xori	a4,a5,1
    80005d2c:	8b05                	andi	a4,a4,1
    80005d2e:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d32:	0037f713          	andi	a4,a5,3
    80005d36:	00e03733          	snez	a4,a4
    80005d3a:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d3e:	4007f793          	andi	a5,a5,1024
    80005d42:	c791                	beqz	a5,80005d4e <sys_open+0xd0>
    80005d44:	04449703          	lh	a4,68(s1)
    80005d48:	4789                	li	a5,2
    80005d4a:	0af70963          	beq	a4,a5,80005dfc <sys_open+0x17e>
    itrunc(ip);
  }

  iunlock(ip);
    80005d4e:	8526                	mv	a0,s1
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	efe080e7          	jalr	-258(ra) # 80003c4e <iunlock>
  end_op();
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	87e080e7          	jalr	-1922(ra) # 800045d6 <end_op>

  struct proc *p = myproc();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	c4c080e7          	jalr	-948(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_open))
    80005d68:	17853703          	ld	a4,376(a0)
    80005d6c:	67a1                	lui	a5,0x8
    80005d6e:	8ff9                	and	a5,a5,a4
    80005d70:	efc1                	bnez	a5,80005e08 <sys_open+0x18a>
    printf("%d: syscall open (%d) -> %d\n", p->pid, omode, fd);
  return fd;
    80005d72:	854e                	mv	a0,s3
}
    80005d74:	70ea                	ld	ra,184(sp)
    80005d76:	744a                	ld	s0,176(sp)
    80005d78:	74aa                	ld	s1,168(sp)
    80005d7a:	790a                	ld	s2,160(sp)
    80005d7c:	69ea                	ld	s3,152(sp)
    80005d7e:	6129                	addi	sp,sp,192
    80005d80:	8082                	ret
      end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	854080e7          	jalr	-1964(ra) # 800045d6 <end_op>
      return -1;
    80005d8a:	557d                	li	a0,-1
    80005d8c:	b7e5                	j	80005d74 <sys_open+0xf6>
    if((ip = namei(path)) == 0){
    80005d8e:	f5040513          	addi	a0,s0,-176
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	5a6080e7          	jalr	1446(ra) # 80004338 <namei>
    80005d9a:	84aa                	mv	s1,a0
    80005d9c:	c905                	beqz	a0,80005dcc <sys_open+0x14e>
    ilock(ip);
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	dee080e7          	jalr	-530(ra) # 80003b8c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005da6:	04449703          	lh	a4,68(s1)
    80005daa:	4785                	li	a5,1
    80005dac:	f2f718e3          	bne	a4,a5,80005cdc <sys_open+0x5e>
    80005db0:	f4c42783          	lw	a5,-180(s0)
    80005db4:	df95                	beqz	a5,80005cf0 <sys_open+0x72>
      iunlockput(ip);
    80005db6:	8526                	mv	a0,s1
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	036080e7          	jalr	54(ra) # 80003dee <iunlockput>
      end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	816080e7          	jalr	-2026(ra) # 800045d6 <end_op>
      return -1;
    80005dc8:	557d                	li	a0,-1
    80005dca:	b76d                	j	80005d74 <sys_open+0xf6>
      end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	80a080e7          	jalr	-2038(ra) # 800045d6 <end_op>
      return -1;
    80005dd4:	557d                	li	a0,-1
    80005dd6:	bf79                	j	80005d74 <sys_open+0xf6>
    iunlockput(ip);
    80005dd8:	8526                	mv	a0,s1
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	014080e7          	jalr	20(ra) # 80003dee <iunlockput>
    end_op();
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	7f4080e7          	jalr	2036(ra) # 800045d6 <end_op>
    return -1;
    80005dea:	557d                	li	a0,-1
    80005dec:	b761                	j	80005d74 <sys_open+0xf6>
    f->type = FD_DEVICE;
    80005dee:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005df2:	04649783          	lh	a5,70(s1)
    80005df6:	02f91223          	sh	a5,36(s2)
    80005dfa:	b71d                	j	80005d20 <sys_open+0xa2>
    itrunc(ip);
    80005dfc:	8526                	mv	a0,s1
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	e9c080e7          	jalr	-356(ra) # 80003c9a <itrunc>
    80005e06:	b7a1                	j	80005d4e <sys_open+0xd0>
    printf("%d: syscall open (%d) -> %d\n", p->pid, omode, fd);
    80005e08:	86ce                	mv	a3,s3
    80005e0a:	f4c42603          	lw	a2,-180(s0)
    80005e0e:	590c                	lw	a1,48(a0)
    80005e10:	00003517          	auipc	a0,0x3
    80005e14:	b4050513          	addi	a0,a0,-1216 # 80008950 <syscalls+0x500>
    80005e18:	ffffa097          	auipc	ra,0xffffa
    80005e1c:	772080e7          	jalr	1906(ra) # 8000058a <printf>
    80005e20:	bf89                	j	80005d72 <sys_open+0xf4>
      fileclose(f);
    80005e22:	854a                	mv	a0,s2
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	bfc080e7          	jalr	-1028(ra) # 80004a20 <fileclose>
    iunlockput(ip);
    80005e2c:	8526                	mv	a0,s1
    80005e2e:	ffffe097          	auipc	ra,0xffffe
    80005e32:	fc0080e7          	jalr	-64(ra) # 80003dee <iunlockput>
    end_op();
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	7a0080e7          	jalr	1952(ra) # 800045d6 <end_op>
    return -1;
    80005e3e:	557d                	li	a0,-1
    80005e40:	bf15                	j	80005d74 <sys_open+0xf6>

0000000080005e42 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e42:	7175                	addi	sp,sp,-144
    80005e44:	e506                	sd	ra,136(sp)
    80005e46:	e122                	sd	s0,128(sp)
    80005e48:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	70e080e7          	jalr	1806(ra) # 80004558 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e52:	08000613          	li	a2,128
    80005e56:	f7040593          	addi	a1,s0,-144
    80005e5a:	4501                	li	a0,0
    80005e5c:	ffffd097          	auipc	ra,0xffffd
    80005e60:	f72080e7          	jalr	-142(ra) # 80002dce <argstr>
    80005e64:	04054463          	bltz	a0,80005eac <sys_mkdir+0x6a>
    80005e68:	4681                	li	a3,0
    80005e6a:	4601                	li	a2,0
    80005e6c:	4585                	li	a1,1
    80005e6e:	f7040513          	addi	a0,s0,-144
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	688080e7          	jalr	1672(ra) # 800054fa <create>
    80005e7a:	c90d                	beqz	a0,80005eac <sys_mkdir+0x6a>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	f72080e7          	jalr	-142(ra) # 80003dee <iunlockput>
  end_op();
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	752080e7          	jalr	1874(ra) # 800045d6 <end_op>

  struct proc *p = myproc();
    80005e8c:	ffffc097          	auipc	ra,0xffffc
    80005e90:	b20080e7          	jalr	-1248(ra) # 800019ac <myproc>
    80005e94:	872a                	mv	a4,a0
  if (p->strace_m & (1 << SYS_mkdir))
    80005e96:	17853683          	ld	a3,376(a0)
    80005e9a:	001007b7          	lui	a5,0x100
    80005e9e:	00d7f533          	and	a0,a5,a3
    80005ea2:	e919                	bnez	a0,80005eb8 <sys_mkdir+0x76>
  {
    int pid = p->pid;
    printf("%d: syscall mkdir (str) -> 0\n", pid);
  }
  return 0;
}
    80005ea4:	60aa                	ld	ra,136(sp)
    80005ea6:	640a                	ld	s0,128(sp)
    80005ea8:	6149                	addi	sp,sp,144
    80005eaa:	8082                	ret
    end_op();
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	72a080e7          	jalr	1834(ra) # 800045d6 <end_op>
    return -1;
    80005eb4:	557d                	li	a0,-1
    80005eb6:	b7fd                	j	80005ea4 <sys_mkdir+0x62>
    printf("%d: syscall mkdir (str) -> 0\n", pid);
    80005eb8:	5b0c                	lw	a1,48(a4)
    80005eba:	00003517          	auipc	a0,0x3
    80005ebe:	ab650513          	addi	a0,a0,-1354 # 80008970 <syscalls+0x520>
    80005ec2:	ffffa097          	auipc	ra,0xffffa
    80005ec6:	6c8080e7          	jalr	1736(ra) # 8000058a <printf>
  return 0;
    80005eca:	4501                	li	a0,0
    80005ecc:	bfe1                	j	80005ea4 <sys_mkdir+0x62>

0000000080005ece <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ece:	7135                	addi	sp,sp,-160
    80005ed0:	ed06                	sd	ra,152(sp)
    80005ed2:	e922                	sd	s0,144(sp)
    80005ed4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	682080e7          	jalr	1666(ra) # 80004558 <begin_op>
  argint(1, &major);
    80005ede:	f6c40593          	addi	a1,s0,-148
    80005ee2:	4505                	li	a0,1
    80005ee4:	ffffd097          	auipc	ra,0xffffd
    80005ee8:	eaa080e7          	jalr	-342(ra) # 80002d8e <argint>
  argint(2, &minor);
    80005eec:	f6840593          	addi	a1,s0,-152
    80005ef0:	4509                	li	a0,2
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	e9c080e7          	jalr	-356(ra) # 80002d8e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005efa:	08000613          	li	a2,128
    80005efe:	f7040593          	addi	a1,s0,-144
    80005f02:	4501                	li	a0,0
    80005f04:	ffffd097          	auipc	ra,0xffffd
    80005f08:	eca080e7          	jalr	-310(ra) # 80002dce <argstr>
    80005f0c:	04054663          	bltz	a0,80005f58 <sys_mknod+0x8a>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f10:	f6841683          	lh	a3,-152(s0)
    80005f14:	f6c41603          	lh	a2,-148(s0)
    80005f18:	458d                	li	a1,3
    80005f1a:	f7040513          	addi	a0,s0,-144
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	5dc080e7          	jalr	1500(ra) # 800054fa <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f26:	c90d                	beqz	a0,80005f58 <sys_mknod+0x8a>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	ec6080e7          	jalr	-314(ra) # 80003dee <iunlockput>
  end_op();
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	6a6080e7          	jalr	1702(ra) # 800045d6 <end_op>
  
  struct proc *p = myproc();
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	a74080e7          	jalr	-1420(ra) # 800019ac <myproc>
    80005f40:	872a                	mv	a4,a0
  if (p->strace_m & (1 << SYS_mknod))
    80005f42:	17853683          	ld	a3,376(a0)
    80005f46:	000207b7          	lui	a5,0x20
    80005f4a:	00d7f533          	and	a0,a5,a3
    80005f4e:	e919                	bnez	a0,80005f64 <sys_mknod+0x96>
    printf("%d: syscall mknod (%d %d) -> 0\n", p->pid, major, minor);
  return 0;
}
    80005f50:	60ea                	ld	ra,152(sp)
    80005f52:	644a                	ld	s0,144(sp)
    80005f54:	610d                	addi	sp,sp,160
    80005f56:	8082                	ret
    end_op();
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	67e080e7          	jalr	1662(ra) # 800045d6 <end_op>
    return -1;
    80005f60:	557d                	li	a0,-1
    80005f62:	b7fd                	j	80005f50 <sys_mknod+0x82>
    printf("%d: syscall mknod (%d %d) -> 0\n", p->pid, major, minor);
    80005f64:	f6842683          	lw	a3,-152(s0)
    80005f68:	f6c42603          	lw	a2,-148(s0)
    80005f6c:	5b0c                	lw	a1,48(a4)
    80005f6e:	00003517          	auipc	a0,0x3
    80005f72:	a2250513          	addi	a0,a0,-1502 # 80008990 <syscalls+0x540>
    80005f76:	ffffa097          	auipc	ra,0xffffa
    80005f7a:	614080e7          	jalr	1556(ra) # 8000058a <printf>
  return 0;
    80005f7e:	4501                	li	a0,0
    80005f80:	bfc1                	j	80005f50 <sys_mknod+0x82>

0000000080005f82 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f82:	7135                	addi	sp,sp,-160
    80005f84:	ed06                	sd	ra,152(sp)
    80005f86:	e922                	sd	s0,144(sp)
    80005f88:	e526                	sd	s1,136(sp)
    80005f8a:	e14a                	sd	s2,128(sp)
    80005f8c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f8e:	ffffc097          	auipc	ra,0xffffc
    80005f92:	a1e080e7          	jalr	-1506(ra) # 800019ac <myproc>
    80005f96:	892a                	mv	s2,a0
  
  begin_op();
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	5c0080e7          	jalr	1472(ra) # 80004558 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fa0:	08000613          	li	a2,128
    80005fa4:	f6040593          	addi	a1,s0,-160
    80005fa8:	4501                	li	a0,0
    80005faa:	ffffd097          	auipc	ra,0xffffd
    80005fae:	e24080e7          	jalr	-476(ra) # 80002dce <argstr>
    80005fb2:	06054563          	bltz	a0,8000601c <sys_chdir+0x9a>
    80005fb6:	f6040513          	addi	a0,s0,-160
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	37e080e7          	jalr	894(ra) # 80004338 <namei>
    80005fc2:	84aa                	mv	s1,a0
    80005fc4:	cd21                	beqz	a0,8000601c <sys_chdir+0x9a>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	bc6080e7          	jalr	-1082(ra) # 80003b8c <ilock>
  if(ip->type != T_DIR){
    80005fce:	04449703          	lh	a4,68(s1)
    80005fd2:	4785                	li	a5,1
    80005fd4:	04f71f63          	bne	a4,a5,80006032 <sys_chdir+0xb0>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fd8:	8526                	mv	a0,s1
    80005fda:	ffffe097          	auipc	ra,0xffffe
    80005fde:	c74080e7          	jalr	-908(ra) # 80003c4e <iunlock>
  iput(p->cwd);
    80005fe2:	15093503          	ld	a0,336(s2)
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	d60080e7          	jalr	-672(ra) # 80003d46 <iput>
  end_op();
    80005fee:	ffffe097          	auipc	ra,0xffffe
    80005ff2:	5e8080e7          	jalr	1512(ra) # 800045d6 <end_op>
  p->cwd = ip;
    80005ff6:	14993823          	sd	s1,336(s2)

  if (p->strace_m & (1 << SYS_chdir))
    80005ffa:	17893503          	ld	a0,376(s2)
    80005ffe:	20057513          	andi	a0,a0,512
    80006002:	c115                	beqz	a0,80006026 <sys_chdir+0xa4>
    printf("%d: syscall chdir () -> 0\n", p->pid);
    80006004:	03092583          	lw	a1,48(s2)
    80006008:	00003517          	auipc	a0,0x3
    8000600c:	9a850513          	addi	a0,a0,-1624 # 800089b0 <syscalls+0x560>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	57a080e7          	jalr	1402(ra) # 8000058a <printf>
  return 0;
    80006018:	4501                	li	a0,0
    8000601a:	a031                	j	80006026 <sys_chdir+0xa4>
    end_op();
    8000601c:	ffffe097          	auipc	ra,0xffffe
    80006020:	5ba080e7          	jalr	1466(ra) # 800045d6 <end_op>
    return -1;
    80006024:	557d                	li	a0,-1
}
    80006026:	60ea                	ld	ra,152(sp)
    80006028:	644a                	ld	s0,144(sp)
    8000602a:	64aa                	ld	s1,136(sp)
    8000602c:	690a                	ld	s2,128(sp)
    8000602e:	610d                	addi	sp,sp,160
    80006030:	8082                	ret
    iunlockput(ip);
    80006032:	8526                	mv	a0,s1
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	dba080e7          	jalr	-582(ra) # 80003dee <iunlockput>
    end_op();
    8000603c:	ffffe097          	auipc	ra,0xffffe
    80006040:	59a080e7          	jalr	1434(ra) # 800045d6 <end_op>
    return -1;
    80006044:	557d                	li	a0,-1
    80006046:	b7c5                	j	80006026 <sys_chdir+0xa4>

0000000080006048 <sys_exec>:

uint64
sys_exec(void)
{
    80006048:	7145                	addi	sp,sp,-464
    8000604a:	e786                	sd	ra,456(sp)
    8000604c:	e3a2                	sd	s0,448(sp)
    8000604e:	ff26                	sd	s1,440(sp)
    80006050:	fb4a                	sd	s2,432(sp)
    80006052:	f74e                	sd	s3,424(sp)
    80006054:	f352                	sd	s4,416(sp)
    80006056:	ef56                	sd	s5,408(sp)
    80006058:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000605a:	e3840593          	addi	a1,s0,-456
    8000605e:	4505                	li	a0,1
    80006060:	ffffd097          	auipc	ra,0xffffd
    80006064:	d4e080e7          	jalr	-690(ra) # 80002dae <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006068:	08000613          	li	a2,128
    8000606c:	f4040593          	addi	a1,s0,-192
    80006070:	4501                	li	a0,0
    80006072:	ffffd097          	auipc	ra,0xffffd
    80006076:	d5c080e7          	jalr	-676(ra) # 80002dce <argstr>
    8000607a:	87aa                	mv	a5,a0
    return -1;
    8000607c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000607e:	0e07c863          	bltz	a5,8000616e <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
    80006082:	10000613          	li	a2,256
    80006086:	4581                	li	a1,0
    80006088:	e4040513          	addi	a0,s0,-448
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	c46080e7          	jalr	-954(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006094:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006098:	89a6                	mv	s3,s1
    8000609a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000609c:	02000a13          	li	s4,32
    800060a0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060a4:	00391513          	slli	a0,s2,0x3
    800060a8:	e3040593          	addi	a1,s0,-464
    800060ac:	e3843783          	ld	a5,-456(s0)
    800060b0:	953e                	add	a0,a0,a5
    800060b2:	ffffd097          	auipc	ra,0xffffd
    800060b6:	c3e080e7          	jalr	-962(ra) # 80002cf0 <fetchaddr>
    800060ba:	02054a63          	bltz	a0,800060ee <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800060be:	e3043783          	ld	a5,-464(s0)
    800060c2:	c3b9                	beqz	a5,80006108 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	a22080e7          	jalr	-1502(ra) # 80000ae6 <kalloc>
    800060cc:	85aa                	mv	a1,a0
    800060ce:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060d2:	cd11                	beqz	a0,800060ee <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060d4:	6605                	lui	a2,0x1
    800060d6:	e3043503          	ld	a0,-464(s0)
    800060da:	ffffd097          	auipc	ra,0xffffd
    800060de:	c68080e7          	jalr	-920(ra) # 80002d42 <fetchstr>
    800060e2:	00054663          	bltz	a0,800060ee <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800060e6:	0905                	addi	s2,s2,1
    800060e8:	09a1                	addi	s3,s3,8
    800060ea:	fb491be3          	bne	s2,s4,800060a0 <sys_exec+0x58>
  if (p->strace_m & (1 << SYS_wait))
    printf("%d: syscall exec (%d) -> %d\n", p->pid, uargv, ret);
  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ee:	f4040913          	addi	s2,s0,-192
    800060f2:	6088                	ld	a0,0(s1)
    800060f4:	cd25                	beqz	a0,8000616c <sys_exec+0x124>
    kfree(argv[i]);
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	8f2080e7          	jalr	-1806(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060fe:	04a1                	addi	s1,s1,8
    80006100:	ff2499e3          	bne	s1,s2,800060f2 <sys_exec+0xaa>
  return -1;
    80006104:	557d                	li	a0,-1
    80006106:	a0a5                	j	8000616e <sys_exec+0x126>
      argv[i] = 0;
    80006108:	0a8e                	slli	s5,s5,0x3
    8000610a:	fc0a8793          	addi	a5,s5,-64
    8000610e:	00878ab3          	add	s5,a5,s0
    80006112:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006116:	e4040593          	addi	a1,s0,-448
    8000611a:	f4040513          	addi	a0,s0,-192
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	f7c080e7          	jalr	-132(ra) # 8000509a <exec>
    80006126:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006128:	f4040993          	addi	s3,s0,-192
    8000612c:	6088                	ld	a0,0(s1)
    8000612e:	c901                	beqz	a0,8000613e <sys_exec+0xf6>
    kfree(argv[i]);
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	8b8080e7          	jalr	-1864(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006138:	04a1                	addi	s1,s1,8
    8000613a:	ff3499e3          	bne	s1,s3,8000612c <sys_exec+0xe4>
  struct proc *p = myproc();
    8000613e:	ffffc097          	auipc	ra,0xffffc
    80006142:	86e080e7          	jalr	-1938(ra) # 800019ac <myproc>
  if (p->strace_m & (1 << SYS_wait))
    80006146:	17853783          	ld	a5,376(a0)
    8000614a:	8ba1                	andi	a5,a5,8
    8000614c:	e399                	bnez	a5,80006152 <sys_exec+0x10a>
  return ret;
    8000614e:	854a                	mv	a0,s2
    80006150:	a839                	j	8000616e <sys_exec+0x126>
    printf("%d: syscall exec (%d) -> %d\n", p->pid, uargv, ret);
    80006152:	86ca                	mv	a3,s2
    80006154:	e3843603          	ld	a2,-456(s0)
    80006158:	590c                	lw	a1,48(a0)
    8000615a:	00003517          	auipc	a0,0x3
    8000615e:	87650513          	addi	a0,a0,-1930 # 800089d0 <syscalls+0x580>
    80006162:	ffffa097          	auipc	ra,0xffffa
    80006166:	428080e7          	jalr	1064(ra) # 8000058a <printf>
    8000616a:	b7d5                	j	8000614e <sys_exec+0x106>
  return -1;
    8000616c:	557d                	li	a0,-1
}
    8000616e:	60be                	ld	ra,456(sp)
    80006170:	641e                	ld	s0,448(sp)
    80006172:	74fa                	ld	s1,440(sp)
    80006174:	795a                	ld	s2,432(sp)
    80006176:	79ba                	ld	s3,424(sp)
    80006178:	7a1a                	ld	s4,416(sp)
    8000617a:	6afa                	ld	s5,408(sp)
    8000617c:	6179                	addi	sp,sp,464
    8000617e:	8082                	ret

0000000080006180 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006180:	7139                	addi	sp,sp,-64
    80006182:	fc06                	sd	ra,56(sp)
    80006184:	f822                	sd	s0,48(sp)
    80006186:	f426                	sd	s1,40(sp)
    80006188:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000618a:	ffffc097          	auipc	ra,0xffffc
    8000618e:	822080e7          	jalr	-2014(ra) # 800019ac <myproc>
    80006192:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006194:	fd840593          	addi	a1,s0,-40
    80006198:	4501                	li	a0,0
    8000619a:	ffffd097          	auipc	ra,0xffffd
    8000619e:	c14080e7          	jalr	-1004(ra) # 80002dae <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800061a2:	fc840593          	addi	a1,s0,-56
    800061a6:	fd040513          	addi	a0,s0,-48
    800061aa:	fffff097          	auipc	ra,0xfffff
    800061ae:	ba6080e7          	jalr	-1114(ra) # 80004d50 <pipealloc>
    return -1;
    800061b2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061b4:	0a054663          	bltz	a0,80006260 <sys_pipe+0xe0>
  fd0 = -1;
    800061b8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061bc:	fd043503          	ld	a0,-48(s0)
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	298080e7          	jalr	664(ra) # 80005458 <fdalloc>
    800061c8:	fca42223          	sw	a0,-60(s0)
    800061cc:	06054d63          	bltz	a0,80006246 <sys_pipe+0xc6>
    800061d0:	fc843503          	ld	a0,-56(s0)
    800061d4:	fffff097          	auipc	ra,0xfffff
    800061d8:	284080e7          	jalr	644(ra) # 80005458 <fdalloc>
    800061dc:	fca42023          	sw	a0,-64(s0)
    800061e0:	04054a63          	bltz	a0,80006234 <sys_pipe+0xb4>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061e4:	4691                	li	a3,4
    800061e6:	fc440613          	addi	a2,s0,-60
    800061ea:	fd843583          	ld	a1,-40(s0)
    800061ee:	68a8                	ld	a0,80(s1)
    800061f0:	ffffb097          	auipc	ra,0xffffb
    800061f4:	47c080e7          	jalr	1148(ra) # 8000166c <copyout>
    800061f8:	06054a63          	bltz	a0,8000626c <sys_pipe+0xec>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061fc:	4691                	li	a3,4
    800061fe:	fc040613          	addi	a2,s0,-64
    80006202:	fd843583          	ld	a1,-40(s0)
    80006206:	0591                	addi	a1,a1,4
    80006208:	68a8                	ld	a0,80(s1)
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	462080e7          	jalr	1122(ra) # 8000166c <copyout>
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006212:	04054d63          	bltz	a0,8000626c <sys_pipe+0xec>
    fileclose(rf);
    fileclose(wf);
    return -1;
  }

  if (p->strace_m & (1 << SYS_pipe))
    80006216:	1784b783          	ld	a5,376(s1)
    8000621a:	8bc1                	andi	a5,a5,16
    8000621c:	c3b1                	beqz	a5,80006260 <sys_pipe+0xe0>
    printf("%d: syscall pipe () -> 0\n", p->pid);
    8000621e:	588c                	lw	a1,48(s1)
    80006220:	00002517          	auipc	a0,0x2
    80006224:	7d050513          	addi	a0,a0,2000 # 800089f0 <syscalls+0x5a0>
    80006228:	ffffa097          	auipc	ra,0xffffa
    8000622c:	362080e7          	jalr	866(ra) # 8000058a <printf>
  return 0;
    80006230:	4781                	li	a5,0
    80006232:	a03d                	j	80006260 <sys_pipe+0xe0>
    if(fd0 >= 0)
    80006234:	fc442783          	lw	a5,-60(s0)
    80006238:	0007c763          	bltz	a5,80006246 <sys_pipe+0xc6>
      p->ofile[fd0] = 0;
    8000623c:	07e9                	addi	a5,a5,26 # 2001a <_entry-0x7ffdffe6>
    8000623e:	078e                	slli	a5,a5,0x3
    80006240:	97a6                	add	a5,a5,s1
    80006242:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006246:	fd043503          	ld	a0,-48(s0)
    8000624a:	ffffe097          	auipc	ra,0xffffe
    8000624e:	7d6080e7          	jalr	2006(ra) # 80004a20 <fileclose>
    fileclose(wf);
    80006252:	fc843503          	ld	a0,-56(s0)
    80006256:	ffffe097          	auipc	ra,0xffffe
    8000625a:	7ca080e7          	jalr	1994(ra) # 80004a20 <fileclose>
    return -1;
    8000625e:	57fd                	li	a5,-1
}
    80006260:	853e                	mv	a0,a5
    80006262:	70e2                	ld	ra,56(sp)
    80006264:	7442                	ld	s0,48(sp)
    80006266:	74a2                	ld	s1,40(sp)
    80006268:	6121                	addi	sp,sp,64
    8000626a:	8082                	ret
    p->ofile[fd0] = 0;
    8000626c:	fc442783          	lw	a5,-60(s0)
    80006270:	07e9                	addi	a5,a5,26
    80006272:	078e                	slli	a5,a5,0x3
    80006274:	97a6                	add	a5,a5,s1
    80006276:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000627a:	fc042783          	lw	a5,-64(s0)
    8000627e:	07e9                	addi	a5,a5,26
    80006280:	078e                	slli	a5,a5,0x3
    80006282:	97a6                	add	a5,a5,s1
    80006284:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006288:	fd043503          	ld	a0,-48(s0)
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	794080e7          	jalr	1940(ra) # 80004a20 <fileclose>
    fileclose(wf);
    80006294:	fc843503          	ld	a0,-56(s0)
    80006298:	ffffe097          	auipc	ra,0xffffe
    8000629c:	788080e7          	jalr	1928(ra) # 80004a20 <fileclose>
    return -1;
    800062a0:	57fd                	li	a5,-1
    800062a2:	bf7d                	j	80006260 <sys_pipe+0xe0>
	...

00000000800062b0 <kernelvec>:
    800062b0:	7111                	addi	sp,sp,-256
    800062b2:	e006                	sd	ra,0(sp)
    800062b4:	e40a                	sd	sp,8(sp)
    800062b6:	e80e                	sd	gp,16(sp)
    800062b8:	ec12                	sd	tp,24(sp)
    800062ba:	f016                	sd	t0,32(sp)
    800062bc:	f41a                	sd	t1,40(sp)
    800062be:	f81e                	sd	t2,48(sp)
    800062c0:	fc22                	sd	s0,56(sp)
    800062c2:	e0a6                	sd	s1,64(sp)
    800062c4:	e4aa                	sd	a0,72(sp)
    800062c6:	e8ae                	sd	a1,80(sp)
    800062c8:	ecb2                	sd	a2,88(sp)
    800062ca:	f0b6                	sd	a3,96(sp)
    800062cc:	f4ba                	sd	a4,104(sp)
    800062ce:	f8be                	sd	a5,112(sp)
    800062d0:	fcc2                	sd	a6,120(sp)
    800062d2:	e146                	sd	a7,128(sp)
    800062d4:	e54a                	sd	s2,136(sp)
    800062d6:	e94e                	sd	s3,144(sp)
    800062d8:	ed52                	sd	s4,152(sp)
    800062da:	f156                	sd	s5,160(sp)
    800062dc:	f55a                	sd	s6,168(sp)
    800062de:	f95e                	sd	s7,176(sp)
    800062e0:	fd62                	sd	s8,184(sp)
    800062e2:	e1e6                	sd	s9,192(sp)
    800062e4:	e5ea                	sd	s10,200(sp)
    800062e6:	e9ee                	sd	s11,208(sp)
    800062e8:	edf2                	sd	t3,216(sp)
    800062ea:	f1f6                	sd	t4,224(sp)
    800062ec:	f5fa                	sd	t5,232(sp)
    800062ee:	f9fe                	sd	t6,240(sp)
    800062f0:	8cdfc0ef          	jal	ra,80002bbc <kerneltrap>
    800062f4:	6082                	ld	ra,0(sp)
    800062f6:	6122                	ld	sp,8(sp)
    800062f8:	61c2                	ld	gp,16(sp)
    800062fa:	7282                	ld	t0,32(sp)
    800062fc:	7322                	ld	t1,40(sp)
    800062fe:	73c2                	ld	t2,48(sp)
    80006300:	7462                	ld	s0,56(sp)
    80006302:	6486                	ld	s1,64(sp)
    80006304:	6526                	ld	a0,72(sp)
    80006306:	65c6                	ld	a1,80(sp)
    80006308:	6666                	ld	a2,88(sp)
    8000630a:	7686                	ld	a3,96(sp)
    8000630c:	7726                	ld	a4,104(sp)
    8000630e:	77c6                	ld	a5,112(sp)
    80006310:	7866                	ld	a6,120(sp)
    80006312:	688a                	ld	a7,128(sp)
    80006314:	692a                	ld	s2,136(sp)
    80006316:	69ca                	ld	s3,144(sp)
    80006318:	6a6a                	ld	s4,152(sp)
    8000631a:	7a8a                	ld	s5,160(sp)
    8000631c:	7b2a                	ld	s6,168(sp)
    8000631e:	7bca                	ld	s7,176(sp)
    80006320:	7c6a                	ld	s8,184(sp)
    80006322:	6c8e                	ld	s9,192(sp)
    80006324:	6d2e                	ld	s10,200(sp)
    80006326:	6dce                	ld	s11,208(sp)
    80006328:	6e6e                	ld	t3,216(sp)
    8000632a:	7e8e                	ld	t4,224(sp)
    8000632c:	7f2e                	ld	t5,232(sp)
    8000632e:	7fce                	ld	t6,240(sp)
    80006330:	6111                	addi	sp,sp,256
    80006332:	10200073          	sret
    80006336:	00000013          	nop
    8000633a:	00000013          	nop
    8000633e:	0001                	nop

0000000080006340 <timervec>:
    80006340:	34051573          	csrrw	a0,mscratch,a0
    80006344:	e10c                	sd	a1,0(a0)
    80006346:	e510                	sd	a2,8(a0)
    80006348:	e914                	sd	a3,16(a0)
    8000634a:	6d0c                	ld	a1,24(a0)
    8000634c:	7110                	ld	a2,32(a0)
    8000634e:	6194                	ld	a3,0(a1)
    80006350:	96b2                	add	a3,a3,a2
    80006352:	e194                	sd	a3,0(a1)
    80006354:	4589                	li	a1,2
    80006356:	14459073          	csrw	sip,a1
    8000635a:	6914                	ld	a3,16(a0)
    8000635c:	6510                	ld	a2,8(a0)
    8000635e:	610c                	ld	a1,0(a0)
    80006360:	34051573          	csrrw	a0,mscratch,a0
    80006364:	30200073          	mret
	...

000000008000636a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000636a:	1141                	addi	sp,sp,-16
    8000636c:	e422                	sd	s0,8(sp)
    8000636e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006370:	0c0007b7          	lui	a5,0xc000
    80006374:	4705                	li	a4,1
    80006376:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006378:	c3d8                	sw	a4,4(a5)
}
    8000637a:	6422                	ld	s0,8(sp)
    8000637c:	0141                	addi	sp,sp,16
    8000637e:	8082                	ret

0000000080006380 <plicinithart>:

void
plicinithart(void)
{
    80006380:	1141                	addi	sp,sp,-16
    80006382:	e406                	sd	ra,8(sp)
    80006384:	e022                	sd	s0,0(sp)
    80006386:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006388:	ffffb097          	auipc	ra,0xffffb
    8000638c:	5f8080e7          	jalr	1528(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006390:	0085171b          	slliw	a4,a0,0x8
    80006394:	0c0027b7          	lui	a5,0xc002
    80006398:	97ba                	add	a5,a5,a4
    8000639a:	40200713          	li	a4,1026
    8000639e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063a2:	00d5151b          	slliw	a0,a0,0xd
    800063a6:	0c2017b7          	lui	a5,0xc201
    800063aa:	97aa                	add	a5,a5,a0
    800063ac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800063b0:	60a2                	ld	ra,8(sp)
    800063b2:	6402                	ld	s0,0(sp)
    800063b4:	0141                	addi	sp,sp,16
    800063b6:	8082                	ret

00000000800063b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063b8:	1141                	addi	sp,sp,-16
    800063ba:	e406                	sd	ra,8(sp)
    800063bc:	e022                	sd	s0,0(sp)
    800063be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063c0:	ffffb097          	auipc	ra,0xffffb
    800063c4:	5c0080e7          	jalr	1472(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063c8:	00d5151b          	slliw	a0,a0,0xd
    800063cc:	0c2017b7          	lui	a5,0xc201
    800063d0:	97aa                	add	a5,a5,a0
  return irq;
}
    800063d2:	43c8                	lw	a0,4(a5)
    800063d4:	60a2                	ld	ra,8(sp)
    800063d6:	6402                	ld	s0,0(sp)
    800063d8:	0141                	addi	sp,sp,16
    800063da:	8082                	ret

00000000800063dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063dc:	1101                	addi	sp,sp,-32
    800063de:	ec06                	sd	ra,24(sp)
    800063e0:	e822                	sd	s0,16(sp)
    800063e2:	e426                	sd	s1,8(sp)
    800063e4:	1000                	addi	s0,sp,32
    800063e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063e8:	ffffb097          	auipc	ra,0xffffb
    800063ec:	598080e7          	jalr	1432(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063f0:	00d5151b          	slliw	a0,a0,0xd
    800063f4:	0c2017b7          	lui	a5,0xc201
    800063f8:	97aa                	add	a5,a5,a0
    800063fa:	c3c4                	sw	s1,4(a5)
}
    800063fc:	60e2                	ld	ra,24(sp)
    800063fe:	6442                	ld	s0,16(sp)
    80006400:	64a2                	ld	s1,8(sp)
    80006402:	6105                	addi	sp,sp,32
    80006404:	8082                	ret

0000000080006406 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006406:	1141                	addi	sp,sp,-16
    80006408:	e406                	sd	ra,8(sp)
    8000640a:	e022                	sd	s0,0(sp)
    8000640c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000640e:	479d                	li	a5,7
    80006410:	04a7cc63          	blt	a5,a0,80006468 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006414:	0001c797          	auipc	a5,0x1c
    80006418:	6dc78793          	addi	a5,a5,1756 # 80022af0 <disk>
    8000641c:	97aa                	add	a5,a5,a0
    8000641e:	0187c783          	lbu	a5,24(a5)
    80006422:	ebb9                	bnez	a5,80006478 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006424:	00451693          	slli	a3,a0,0x4
    80006428:	0001c797          	auipc	a5,0x1c
    8000642c:	6c878793          	addi	a5,a5,1736 # 80022af0 <disk>
    80006430:	6398                	ld	a4,0(a5)
    80006432:	9736                	add	a4,a4,a3
    80006434:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006438:	6398                	ld	a4,0(a5)
    8000643a:	9736                	add	a4,a4,a3
    8000643c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006440:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006444:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006448:	97aa                	add	a5,a5,a0
    8000644a:	4705                	li	a4,1
    8000644c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006450:	0001c517          	auipc	a0,0x1c
    80006454:	6b850513          	addi	a0,a0,1720 # 80022b08 <disk+0x18>
    80006458:	ffffc097          	auipc	ra,0xffffc
    8000645c:	f12080e7          	jalr	-238(ra) # 8000236a <wakeup>
}
    80006460:	60a2                	ld	ra,8(sp)
    80006462:	6402                	ld	s0,0(sp)
    80006464:	0141                	addi	sp,sp,16
    80006466:	8082                	ret
    panic("free_desc 1");
    80006468:	00002517          	auipc	a0,0x2
    8000646c:	5a850513          	addi	a0,a0,1448 # 80008a10 <syscalls+0x5c0>
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	0d0080e7          	jalr	208(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006478:	00002517          	auipc	a0,0x2
    8000647c:	5a850513          	addi	a0,a0,1448 # 80008a20 <syscalls+0x5d0>
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	0c0080e7          	jalr	192(ra) # 80000540 <panic>

0000000080006488 <virtio_disk_init>:
{
    80006488:	1101                	addi	sp,sp,-32
    8000648a:	ec06                	sd	ra,24(sp)
    8000648c:	e822                	sd	s0,16(sp)
    8000648e:	e426                	sd	s1,8(sp)
    80006490:	e04a                	sd	s2,0(sp)
    80006492:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006494:	00002597          	auipc	a1,0x2
    80006498:	59c58593          	addi	a1,a1,1436 # 80008a30 <syscalls+0x5e0>
    8000649c:	0001c517          	auipc	a0,0x1c
    800064a0:	77c50513          	addi	a0,a0,1916 # 80022c18 <disk+0x128>
    800064a4:	ffffa097          	auipc	ra,0xffffa
    800064a8:	6a2080e7          	jalr	1698(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064ac:	100017b7          	lui	a5,0x10001
    800064b0:	4398                	lw	a4,0(a5)
    800064b2:	2701                	sext.w	a4,a4
    800064b4:	747277b7          	lui	a5,0x74727
    800064b8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064bc:	14f71b63          	bne	a4,a5,80006612 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064c0:	100017b7          	lui	a5,0x10001
    800064c4:	43dc                	lw	a5,4(a5)
    800064c6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064c8:	4709                	li	a4,2
    800064ca:	14e79463          	bne	a5,a4,80006612 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ce:	100017b7          	lui	a5,0x10001
    800064d2:	479c                	lw	a5,8(a5)
    800064d4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064d6:	12e79e63          	bne	a5,a4,80006612 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064da:	100017b7          	lui	a5,0x10001
    800064de:	47d8                	lw	a4,12(a5)
    800064e0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064e2:	554d47b7          	lui	a5,0x554d4
    800064e6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064ea:	12f71463          	bne	a4,a5,80006612 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ee:	100017b7          	lui	a5,0x10001
    800064f2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f6:	4705                	li	a4,1
    800064f8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064fa:	470d                	li	a4,3
    800064fc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064fe:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006500:	c7ffe6b7          	lui	a3,0xc7ffe
    80006504:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbb2f>
    80006508:	8f75                	and	a4,a4,a3
    8000650a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000650c:	472d                	li	a4,11
    8000650e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006510:	5bbc                	lw	a5,112(a5)
    80006512:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006516:	8ba1                	andi	a5,a5,8
    80006518:	10078563          	beqz	a5,80006622 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000651c:	100017b7          	lui	a5,0x10001
    80006520:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006524:	43fc                	lw	a5,68(a5)
    80006526:	2781                	sext.w	a5,a5
    80006528:	10079563          	bnez	a5,80006632 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000652c:	100017b7          	lui	a5,0x10001
    80006530:	5bdc                	lw	a5,52(a5)
    80006532:	2781                	sext.w	a5,a5
  if(max == 0)
    80006534:	10078763          	beqz	a5,80006642 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006538:	471d                	li	a4,7
    8000653a:	10f77c63          	bgeu	a4,a5,80006652 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000653e:	ffffa097          	auipc	ra,0xffffa
    80006542:	5a8080e7          	jalr	1448(ra) # 80000ae6 <kalloc>
    80006546:	0001c497          	auipc	s1,0x1c
    8000654a:	5aa48493          	addi	s1,s1,1450 # 80022af0 <disk>
    8000654e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	596080e7          	jalr	1430(ra) # 80000ae6 <kalloc>
    80006558:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	58c080e7          	jalr	1420(ra) # 80000ae6 <kalloc>
    80006562:	87aa                	mv	a5,a0
    80006564:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006566:	6088                	ld	a0,0(s1)
    80006568:	cd6d                	beqz	a0,80006662 <virtio_disk_init+0x1da>
    8000656a:	0001c717          	auipc	a4,0x1c
    8000656e:	58e73703          	ld	a4,1422(a4) # 80022af8 <disk+0x8>
    80006572:	cb65                	beqz	a4,80006662 <virtio_disk_init+0x1da>
    80006574:	c7fd                	beqz	a5,80006662 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006576:	6605                	lui	a2,0x1
    80006578:	4581                	li	a1,0
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	758080e7          	jalr	1880(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006582:	0001c497          	auipc	s1,0x1c
    80006586:	56e48493          	addi	s1,s1,1390 # 80022af0 <disk>
    8000658a:	6605                	lui	a2,0x1
    8000658c:	4581                	li	a1,0
    8000658e:	6488                	ld	a0,8(s1)
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	742080e7          	jalr	1858(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006598:	6605                	lui	a2,0x1
    8000659a:	4581                	li	a1,0
    8000659c:	6888                	ld	a0,16(s1)
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	734080e7          	jalr	1844(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065a6:	100017b7          	lui	a5,0x10001
    800065aa:	4721                	li	a4,8
    800065ac:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800065ae:	4098                	lw	a4,0(s1)
    800065b0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800065b4:	40d8                	lw	a4,4(s1)
    800065b6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800065ba:	6498                	ld	a4,8(s1)
    800065bc:	0007069b          	sext.w	a3,a4
    800065c0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800065c4:	9701                	srai	a4,a4,0x20
    800065c6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800065ca:	6898                	ld	a4,16(s1)
    800065cc:	0007069b          	sext.w	a3,a4
    800065d0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800065d4:	9701                	srai	a4,a4,0x20
    800065d6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800065da:	4705                	li	a4,1
    800065dc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800065de:	00e48c23          	sb	a4,24(s1)
    800065e2:	00e48ca3          	sb	a4,25(s1)
    800065e6:	00e48d23          	sb	a4,26(s1)
    800065ea:	00e48da3          	sb	a4,27(s1)
    800065ee:	00e48e23          	sb	a4,28(s1)
    800065f2:	00e48ea3          	sb	a4,29(s1)
    800065f6:	00e48f23          	sb	a4,30(s1)
    800065fa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800065fe:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006602:	0727a823          	sw	s2,112(a5)
}
    80006606:	60e2                	ld	ra,24(sp)
    80006608:	6442                	ld	s0,16(sp)
    8000660a:	64a2                	ld	s1,8(sp)
    8000660c:	6902                	ld	s2,0(sp)
    8000660e:	6105                	addi	sp,sp,32
    80006610:	8082                	ret
    panic("could not find virtio disk");
    80006612:	00002517          	auipc	a0,0x2
    80006616:	42e50513          	addi	a0,a0,1070 # 80008a40 <syscalls+0x5f0>
    8000661a:	ffffa097          	auipc	ra,0xffffa
    8000661e:	f26080e7          	jalr	-218(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006622:	00002517          	auipc	a0,0x2
    80006626:	43e50513          	addi	a0,a0,1086 # 80008a60 <syscalls+0x610>
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	f16080e7          	jalr	-234(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006632:	00002517          	auipc	a0,0x2
    80006636:	44e50513          	addi	a0,a0,1102 # 80008a80 <syscalls+0x630>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	f06080e7          	jalr	-250(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006642:	00002517          	auipc	a0,0x2
    80006646:	45e50513          	addi	a0,a0,1118 # 80008aa0 <syscalls+0x650>
    8000664a:	ffffa097          	auipc	ra,0xffffa
    8000664e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006652:	00002517          	auipc	a0,0x2
    80006656:	46e50513          	addi	a0,a0,1134 # 80008ac0 <syscalls+0x670>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	ee6080e7          	jalr	-282(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	47e50513          	addi	a0,a0,1150 # 80008ae0 <syscalls+0x690>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ed6080e7          	jalr	-298(ra) # 80000540 <panic>

0000000080006672 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006672:	7119                	addi	sp,sp,-128
    80006674:	fc86                	sd	ra,120(sp)
    80006676:	f8a2                	sd	s0,112(sp)
    80006678:	f4a6                	sd	s1,104(sp)
    8000667a:	f0ca                	sd	s2,96(sp)
    8000667c:	ecce                	sd	s3,88(sp)
    8000667e:	e8d2                	sd	s4,80(sp)
    80006680:	e4d6                	sd	s5,72(sp)
    80006682:	e0da                	sd	s6,64(sp)
    80006684:	fc5e                	sd	s7,56(sp)
    80006686:	f862                	sd	s8,48(sp)
    80006688:	f466                	sd	s9,40(sp)
    8000668a:	f06a                	sd	s10,32(sp)
    8000668c:	ec6e                	sd	s11,24(sp)
    8000668e:	0100                	addi	s0,sp,128
    80006690:	8aaa                	mv	s5,a0
    80006692:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006694:	00c52d03          	lw	s10,12(a0)
    80006698:	001d1d1b          	slliw	s10,s10,0x1
    8000669c:	1d02                	slli	s10,s10,0x20
    8000669e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800066a2:	0001c517          	auipc	a0,0x1c
    800066a6:	57650513          	addi	a0,a0,1398 # 80022c18 <disk+0x128>
    800066aa:	ffffa097          	auipc	ra,0xffffa
    800066ae:	52c080e7          	jalr	1324(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800066b2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066b4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800066b6:	0001cb97          	auipc	s7,0x1c
    800066ba:	43ab8b93          	addi	s7,s7,1082 # 80022af0 <disk>
  for(int i = 0; i < 3; i++){
    800066be:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066c0:	0001cc97          	auipc	s9,0x1c
    800066c4:	558c8c93          	addi	s9,s9,1368 # 80022c18 <disk+0x128>
    800066c8:	a08d                	j	8000672a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800066ca:	00fb8733          	add	a4,s7,a5
    800066ce:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800066d2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800066d4:	0207c563          	bltz	a5,800066fe <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800066d8:	2905                	addiw	s2,s2,1
    800066da:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800066dc:	05690c63          	beq	s2,s6,80006734 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800066e0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800066e2:	0001c717          	auipc	a4,0x1c
    800066e6:	40e70713          	addi	a4,a4,1038 # 80022af0 <disk>
    800066ea:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800066ec:	01874683          	lbu	a3,24(a4)
    800066f0:	fee9                	bnez	a3,800066ca <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800066f2:	2785                	addiw	a5,a5,1
    800066f4:	0705                	addi	a4,a4,1
    800066f6:	fe979be3          	bne	a5,s1,800066ec <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800066fa:	57fd                	li	a5,-1
    800066fc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800066fe:	01205d63          	blez	s2,80006718 <virtio_disk_rw+0xa6>
    80006702:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006704:	000a2503          	lw	a0,0(s4)
    80006708:	00000097          	auipc	ra,0x0
    8000670c:	cfe080e7          	jalr	-770(ra) # 80006406 <free_desc>
      for(int j = 0; j < i; j++)
    80006710:	2d85                	addiw	s11,s11,1
    80006712:	0a11                	addi	s4,s4,4
    80006714:	ff2d98e3          	bne	s11,s2,80006704 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006718:	85e6                	mv	a1,s9
    8000671a:	0001c517          	auipc	a0,0x1c
    8000671e:	3ee50513          	addi	a0,a0,1006 # 80022b08 <disk+0x18>
    80006722:	ffffc097          	auipc	ra,0xffffc
    80006726:	be4080e7          	jalr	-1052(ra) # 80002306 <sleep>
  for(int i = 0; i < 3; i++){
    8000672a:	f8040a13          	addi	s4,s0,-128
{
    8000672e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006730:	894e                	mv	s2,s3
    80006732:	b77d                	j	800066e0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006734:	f8042503          	lw	a0,-128(s0)
    80006738:	00a50713          	addi	a4,a0,10
    8000673c:	0712                	slli	a4,a4,0x4

  if(write)
    8000673e:	0001c797          	auipc	a5,0x1c
    80006742:	3b278793          	addi	a5,a5,946 # 80022af0 <disk>
    80006746:	00e786b3          	add	a3,a5,a4
    8000674a:	01803633          	snez	a2,s8
    8000674e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006750:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006754:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006758:	f6070613          	addi	a2,a4,-160
    8000675c:	6394                	ld	a3,0(a5)
    8000675e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006760:	00870593          	addi	a1,a4,8
    80006764:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006766:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006768:	0007b803          	ld	a6,0(a5)
    8000676c:	9642                	add	a2,a2,a6
    8000676e:	46c1                	li	a3,16
    80006770:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006772:	4585                	li	a1,1
    80006774:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006778:	f8442683          	lw	a3,-124(s0)
    8000677c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006780:	0692                	slli	a3,a3,0x4
    80006782:	9836                	add	a6,a6,a3
    80006784:	058a8613          	addi	a2,s5,88
    80006788:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000678c:	0007b803          	ld	a6,0(a5)
    80006790:	96c2                	add	a3,a3,a6
    80006792:	40000613          	li	a2,1024
    80006796:	c690                	sw	a2,8(a3)
  if(write)
    80006798:	001c3613          	seqz	a2,s8
    8000679c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067a0:	00166613          	ori	a2,a2,1
    800067a4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067a8:	f8842603          	lw	a2,-120(s0)
    800067ac:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067b0:	00250693          	addi	a3,a0,2
    800067b4:	0692                	slli	a3,a3,0x4
    800067b6:	96be                	add	a3,a3,a5
    800067b8:	58fd                	li	a7,-1
    800067ba:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067be:	0612                	slli	a2,a2,0x4
    800067c0:	9832                	add	a6,a6,a2
    800067c2:	f9070713          	addi	a4,a4,-112
    800067c6:	973e                	add	a4,a4,a5
    800067c8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800067cc:	6398                	ld	a4,0(a5)
    800067ce:	9732                	add	a4,a4,a2
    800067d0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067d2:	4609                	li	a2,2
    800067d4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800067d8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067dc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800067e0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067e4:	6794                	ld	a3,8(a5)
    800067e6:	0026d703          	lhu	a4,2(a3)
    800067ea:	8b1d                	andi	a4,a4,7
    800067ec:	0706                	slli	a4,a4,0x1
    800067ee:	96ba                	add	a3,a3,a4
    800067f0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800067f4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067f8:	6798                	ld	a4,8(a5)
    800067fa:	00275783          	lhu	a5,2(a4)
    800067fe:	2785                	addiw	a5,a5,1
    80006800:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006804:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006808:	100017b7          	lui	a5,0x10001
    8000680c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006810:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006814:	0001c917          	auipc	s2,0x1c
    80006818:	40490913          	addi	s2,s2,1028 # 80022c18 <disk+0x128>
  while(b->disk == 1) {
    8000681c:	4485                	li	s1,1
    8000681e:	00b79c63          	bne	a5,a1,80006836 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006822:	85ca                	mv	a1,s2
    80006824:	8556                	mv	a0,s5
    80006826:	ffffc097          	auipc	ra,0xffffc
    8000682a:	ae0080e7          	jalr	-1312(ra) # 80002306 <sleep>
  while(b->disk == 1) {
    8000682e:	004aa783          	lw	a5,4(s5)
    80006832:	fe9788e3          	beq	a5,s1,80006822 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006836:	f8042903          	lw	s2,-128(s0)
    8000683a:	00290713          	addi	a4,s2,2
    8000683e:	0712                	slli	a4,a4,0x4
    80006840:	0001c797          	auipc	a5,0x1c
    80006844:	2b078793          	addi	a5,a5,688 # 80022af0 <disk>
    80006848:	97ba                	add	a5,a5,a4
    8000684a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000684e:	0001c997          	auipc	s3,0x1c
    80006852:	2a298993          	addi	s3,s3,674 # 80022af0 <disk>
    80006856:	00491713          	slli	a4,s2,0x4
    8000685a:	0009b783          	ld	a5,0(s3)
    8000685e:	97ba                	add	a5,a5,a4
    80006860:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006864:	854a                	mv	a0,s2
    80006866:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000686a:	00000097          	auipc	ra,0x0
    8000686e:	b9c080e7          	jalr	-1124(ra) # 80006406 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006872:	8885                	andi	s1,s1,1
    80006874:	f0ed                	bnez	s1,80006856 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006876:	0001c517          	auipc	a0,0x1c
    8000687a:	3a250513          	addi	a0,a0,930 # 80022c18 <disk+0x128>
    8000687e:	ffffa097          	auipc	ra,0xffffa
    80006882:	40c080e7          	jalr	1036(ra) # 80000c8a <release>
}
    80006886:	70e6                	ld	ra,120(sp)
    80006888:	7446                	ld	s0,112(sp)
    8000688a:	74a6                	ld	s1,104(sp)
    8000688c:	7906                	ld	s2,96(sp)
    8000688e:	69e6                	ld	s3,88(sp)
    80006890:	6a46                	ld	s4,80(sp)
    80006892:	6aa6                	ld	s5,72(sp)
    80006894:	6b06                	ld	s6,64(sp)
    80006896:	7be2                	ld	s7,56(sp)
    80006898:	7c42                	ld	s8,48(sp)
    8000689a:	7ca2                	ld	s9,40(sp)
    8000689c:	7d02                	ld	s10,32(sp)
    8000689e:	6de2                	ld	s11,24(sp)
    800068a0:	6109                	addi	sp,sp,128
    800068a2:	8082                	ret

00000000800068a4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068a4:	1101                	addi	sp,sp,-32
    800068a6:	ec06                	sd	ra,24(sp)
    800068a8:	e822                	sd	s0,16(sp)
    800068aa:	e426                	sd	s1,8(sp)
    800068ac:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068ae:	0001c497          	auipc	s1,0x1c
    800068b2:	24248493          	addi	s1,s1,578 # 80022af0 <disk>
    800068b6:	0001c517          	auipc	a0,0x1c
    800068ba:	36250513          	addi	a0,a0,866 # 80022c18 <disk+0x128>
    800068be:	ffffa097          	auipc	ra,0xffffa
    800068c2:	318080e7          	jalr	792(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068c6:	10001737          	lui	a4,0x10001
    800068ca:	533c                	lw	a5,96(a4)
    800068cc:	8b8d                	andi	a5,a5,3
    800068ce:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068d0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068d4:	689c                	ld	a5,16(s1)
    800068d6:	0204d703          	lhu	a4,32(s1)
    800068da:	0027d783          	lhu	a5,2(a5)
    800068de:	04f70863          	beq	a4,a5,8000692e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068e2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068e6:	6898                	ld	a4,16(s1)
    800068e8:	0204d783          	lhu	a5,32(s1)
    800068ec:	8b9d                	andi	a5,a5,7
    800068ee:	078e                	slli	a5,a5,0x3
    800068f0:	97ba                	add	a5,a5,a4
    800068f2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068f4:	00278713          	addi	a4,a5,2
    800068f8:	0712                	slli	a4,a4,0x4
    800068fa:	9726                	add	a4,a4,s1
    800068fc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006900:	e721                	bnez	a4,80006948 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006902:	0789                	addi	a5,a5,2
    80006904:	0792                	slli	a5,a5,0x4
    80006906:	97a6                	add	a5,a5,s1
    80006908:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000690a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000690e:	ffffc097          	auipc	ra,0xffffc
    80006912:	a5c080e7          	jalr	-1444(ra) # 8000236a <wakeup>

    disk.used_idx += 1;
    80006916:	0204d783          	lhu	a5,32(s1)
    8000691a:	2785                	addiw	a5,a5,1
    8000691c:	17c2                	slli	a5,a5,0x30
    8000691e:	93c1                	srli	a5,a5,0x30
    80006920:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006924:	6898                	ld	a4,16(s1)
    80006926:	00275703          	lhu	a4,2(a4)
    8000692a:	faf71ce3          	bne	a4,a5,800068e2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000692e:	0001c517          	auipc	a0,0x1c
    80006932:	2ea50513          	addi	a0,a0,746 # 80022c18 <disk+0x128>
    80006936:	ffffa097          	auipc	ra,0xffffa
    8000693a:	354080e7          	jalr	852(ra) # 80000c8a <release>
}
    8000693e:	60e2                	ld	ra,24(sp)
    80006940:	6442                	ld	s0,16(sp)
    80006942:	64a2                	ld	s1,8(sp)
    80006944:	6105                	addi	sp,sp,32
    80006946:	8082                	ret
      panic("virtio_disk_intr status");
    80006948:	00002517          	auipc	a0,0x2
    8000694c:	1b050513          	addi	a0,a0,432 # 80008af8 <syscalls+0x6a8>
    80006950:	ffffa097          	auipc	ra,0xffffa
    80006954:	bf0080e7          	jalr	-1040(ra) # 80000540 <panic>
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
