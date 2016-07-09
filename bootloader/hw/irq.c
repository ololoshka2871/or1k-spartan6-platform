#include <stddef.h>
#include <string.h>

#include "mem_map.h"
#include "syscall.h"

#include "irq.h"

struct src_handler {
    enum InterruptSources src;
    isr_handler ISR;
};

static struct src_handler ISRs[IS_Count] = {
{ IS_TIMER_HIRES, NULL },
{ IS_TIMER_SYSTICK, NULL },
{ IS_UART0, NULL }
};

static unsigned int irq_disable_counter = 1;

//-----------------------------------------------------------------
// irq_enable 
//-----------------------------------------------------------------
void irq_enable(int interrupt)
{
    IRQ_MASK_SET = (1 << interrupt);
}
//-----------------------------------------------------------------
// irq_disable 
//-----------------------------------------------------------------
void irq_disable(int interrupt)
{
    IRQ_MASK_CLR = (1 << interrupt);
}
//-----------------------------------------------------------------
// irq_acknowledge 
//-----------------------------------------------------------------
void irq_acknowledge(int interrupt)
{
    IRQ_STATUS = (1 << interrupt);
}
//-----------------------------------------------------------------
// irq_check
//-----------------------------------------------------------------
int irq_check(int interrupt)
{
    return IRQ_STATUS & (1 << interrupt);
}


//-----------------------------------------------------------------

static unsigned int* default_ISR(unsigned int * registers) {
    // check irq source
    for (int i = 0; i < IS_Count; ++i) {
        struct src_handler* d = &ISRs[i];
        if (irq_check(d->src)) {
            if (d->ISR)
                d->ISR(registers);
            irq_acknowledge(d->src);
        }
    }

    return registers;
}

void setInterruptPriority(enum InterruptSources src, uint8_t prio) {
    int i;
    int current_prio = -1;
    if (prio >= IS_Count)
        return;
    // find current prio
    for (int i = 0; i < IS_Count; ++i)
        if (ISRs[i].src == src)
            current_prio = i;
    if(current_prio == -1)
        return;

    if (current_prio == prio)
        return;

    struct src_handler _ISRs[IS_Count];
    memcpy(_ISRs, ISRs, sizeof(ISRs));
    isr_handler isr_fun = ISRs[current_prio].ISR;
    if (current_prio > prio) {
        // shift fragment up

        // 1 ----                           1 ----
        // 2 current_prio                   3 ----
        // 3 ----                           4 ----
        // 4 ----                           5 ----
        // 5 ---- <- prio                   2 prio
        // 6 ----                           6 ----
        memmove(&_ISRs[current_prio],
                &_ISRs[current_prio + 1],
                sizeof(struct src_handler) * (prio - current_prio));
    } else {
        // shift fragment down

        // 1 ----                           1 ----
        // 2 ---- <- prio                   5 prio
        // 3 ----                           2 ----
        // 4 ----                           3 ----
        // 5 current_prio                   4 ----
        // 6 ----                           6 ----
        memmove(&_ISRs[prio + 1],
                &_ISRs[prio],
                sizeof(struct src_handler) * (current_prio - prio));
    }
    _ISRs[prio].src = src;
    _ISRs[prio].ISR = isr_fun;
    ENTER_CRITICAL();
    memcpy(ISRs, _ISRs, sizeof(ISRs));
    EXIT_CRITICAL();
}


isr_handler set_irq_handler(enum InterruptSources src, isr_handler handler) {
    for (int i = 0; i < IS_Count; ++i) {
        struct src_handler* d = &ISRs[i];
        if (d->src == src) {
            isr_handler result = d->ISR;
            ENTER_CRITICAL();
            d->ISR = handler;
            EXIT_CRITICAL();
            return result;
        }
    }
    return NULL;
}

irq_handler install_irq_global_handler(irq_handler handler) {
    asm volatile("l.sys 5");
    return handler; // old handler value from syscall
}

void interrupts_init(void) {
    install_irq_global_handler(default_ISR);
}


void __or1k_disable_interrupts(void) {
    ++irq_disable_counter;
#if 1
    unsigned long sr = mfspr(SPR_SR);
    mtspr(SPR_SR, sr & ~SPR_SR_GIE);
#else
    unsigned long value;
    asm volatile ("l.mfspr\t\t%0,r0,%1" : "=r" (value) : "i" (SPR_SR));
    asm volatile ("l.mtspr\t\tr0,%0,%1" :
                  : "r" (value & ~SPR_SR_GIE), "i" (SPR_SR));
#endif
}

void __or1k_enable_interrupts(void) {
    if (irq_disable_counter) {
        --irq_disable_counter;
        if (irq_disable_counter)
            return;
    }
#if 1
    unsigned long sr = mfspr(SPR_SR);
    mtspr(SPR_SR, sr | SPR_SR_GIE);
#else
    unsigned long value;
    asm volatile ("l.mfspr\t\t%0,r0,%1" : "=r" (value) : "i" (SPR_SR));
    asm volatile ("l.mtspr\t\tr0,%0,%1" :
                  : "r" (value | SPR_SR_GIE), "i" (SPR_SR));
#endif
}