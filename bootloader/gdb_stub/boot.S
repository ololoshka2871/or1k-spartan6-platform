.nodelay

#include "exception.inc"

.section    .boot.vectors, "ax"

#-------------------------------------------------------------
# handle_exception: Common exception handling code
#-------------------------------------------------------------
handle_exception:

    # Copy stack pointer to arg1
    l.add r3, r0, r1

    # Jump to debug handler
    l.movhi r10,hi(gdb_exception);
    l.ori r10,r10,lo(gdb_exception);
    l.jalr r10
    l.nop

exception_return:
    # Return value is stack pointer
    l.add r1, r0, r11

    # Restore context
    asm_load_context

.size   handle_exception, .-handle_exception

#-------------------------------------------------------------
# VECTOR 0x100 - Reset
#-------------------------------------------------------------
.org    0x100

.global vector_reset
vector_reset:
__start:
#ifdef _OWN_BOOTLOADER_SECTIONS
    # R4 = _bss_gdb_stub_start
    l.movhi r4,hi(_bss_gdb_stub_start);
    l.ori r4,r4,lo(_bss_gdb_stub_start);

    # R5 = _bss_gdb_stub_end
    l.movhi r5,hi(_bss_gdb_stub_end);
    l.ori r5,r5,lo(_bss_gdb_stub_end);

BSS_GDB_STUB_CLEAR:
    l.sw 0x0(r4),r0          # Write 0x00 to mem[r4]
    l.sfleu r4,r5            # SR[F] = (r4 < r5)
    l.addi r4, r4, 4         # r4 += 4
    l.bf  BSS_GDB_STUB_CLEAR # If SR[F] == 0, jump to BSS_GDB_STUB_CLEAR
    l.nop
#endif

    //
_start:
    # Setup SP (R1)
    l.movhi r4,hi(_sp);
    l.ori r1,r4,lo(_sp);

BSS_CLEAR:
    # R4 = _bss_start
    l.movhi r4,hi(_bss_start);
    l.ori r4,r4,lo(_bss_start);
    
    # R5 = _bss_end
    l.movhi r5,hi(_bss_end);
    l.ori r5,r5,lo(_bss_end);
    
BSS_CLEAR_loop:
    l.sw 0x0(r4),r0         # Write 0x00 to mem[r4]
    l.sfleu r4,r5           # SR[F] = (r4 < r5)
    l.addi r4, r4, 4        # r4 += 4
    l.bf  BSS_CLEAR_loop    # If SR[F] == 0, jump to BSS_CLEAR
    l.nop

    # Jump to debug agent
    l.j gdb_main
    l.nop

.size vector_reset, .-vector_reset

#-------------------------------------------------------------
# VECTOR 0x200 - Fault / Illegal Instruction
#-------------------------------------------------------------
.org    0x200
vector_fault:

    # Save context
    asm_save_context

    # Arg 2 = Fault
    l.addi r4, r0, 1

    l.j handle_exception
    l.nop

.size vector_fault, .-vector_fault

#-------------------------------------------------------------
# VECTOR 0x300 - External Interrupt
#-------------------------------------------------------------
.org    0x300
vector_extint:

    # Save context
    asm_save_context

    # Arg 2 = Ext Int
    #l.addi r4, r0, 2

    # Copy stack pointer to arg1
    l.add r3, r0, r1

    # Jump to interrupt handler
    l.movhi r10,hi(interrupt_handler);
    l.ori r10,r10,lo(interrupt_handler);
    l.jalr r10
    l.nop

    # restore context
    l.j exception_return
    l.nop

.size vector_extint, .-vector_extint

#-------------------------------------------------------------
# VECTOR 0x400 - Syscall
#-------------------------------------------------------------
.org    0x400
vector_syscall:

    # Save context
    asm_save_context

    # Arg 2 = Syscall
    #l.addi r4, r0, 3

    # Copy stack pointer to arg1
    l.add r3, r0, r1

    # Jump to interrupt handler
    l.movhi r10,hi(gdb_syscall);
    l.ori r10,r10,lo(gdb_syscall);
    l.jalr r10
    l.nop

    # restore context
    l.j exception_return
    l.nop

.size vector_syscall, .-vector_syscall

#-------------------------------------------------------------
# VECTOR 0x600 - Trap
#-------------------------------------------------------------
.org    0x600
vector_trap:

    # Save context
    asm_save_context
    
    # Arg 2 = Trap
    l.addi r4, r0, 4

    l.j handle_exception
    l.nop

.size vector_trap, .-vector_trap


