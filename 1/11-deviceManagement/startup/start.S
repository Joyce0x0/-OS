#include "platform.h"

	# size of each hart's stack is 1024 bytes
	.equ	STACK_SIZE, 1024

	.global	_start

	.text
_start:
	# park harts with id != 0
	csrr	t0, mhartid		# read current hart id
	mv	tp, t0			# keep CPU's hartid in its tp for later usage.
	bnez	t0, park		# if we're not on the hart 0
					# we park the hart

	# Set all bytes in the BSS section to zero.
	la	a0, _bss_start
	la	a1, _bss_end
	bgeu	a0, a1, 2f
1:
	sw	zero, (a0)
	addi	a0, a0, 4
	bltu	a0, a1, 1b
2:
	# Setup stacks, the stack grows from bottom to top, so we put the
	# stack pointer to the very end of the stack range.
	slli	t0, t0, 10		# shift left the hart id by 1024
	la	sp, stacks + STACK_SIZE	# set the initial stack pointer
					# to the end of the first stack space
	add	sp, sp, t0		# move the current hart stack pointer
					# to its place in the stack space

	# At the end of start_kernel, schedule() will call RET to switch
	# to the first task, so we do first system task idle in machine mode
	# in idle the last one instruction call task_yield will call MRET  
	# so we parepare the mstatus here.
	# Notice: default mstatus is 0	
	# set mstatus.MPIE to 1, so MRET will enable the interrupt.
	# set mstatus.MPP to 3, so we will run in Machine mode after MRET
	# set mstatus.MPP as 0, we will run in User Mode after MRET
#ifdef MACHINE_MODE
	li	t0, 3 << 11 | 1 << 7
#else
	li t0, 1 << 7
#endif
	csrr	a1, mstatus
	or	t0, t0, a1
	csrw	mstatus, t0

	j	start_kernel		# hart 0 jump to c

park:
	wfi
	j	park

stacks:
	.skip	STACK_SIZE * MAXNUM_CPU # allocate space for all the harts stacks

	.end				# End of file
