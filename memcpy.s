.include "common.s"

        /*
         * memcpy
         *
         * $r0: dst
         *
         * $r1: src
         *
         * $r2: len
         */
.globl memcpy
memcpy:
        push4   $lr, $r0, $r3, $r4

        add     $r4, $r1, $r2
1:
        cmp     $r1, $r4
        beq     2f
        ldr8    $r3, [$r1, 0]
        str8    $r3, [$r0, 0]
        add     $r1, $r1, 1
        add     $r0, $r0, 1
        b       1b

2:
        pop4    $lr, $r0, $r3, $r4
        ret
