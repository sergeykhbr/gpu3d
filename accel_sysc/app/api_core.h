#pragma once

// compatibility with riscv_vhdl repository

#if defined(_WIN32) || defined(__CYGWIN__)
    #define RV_PRI64 "I64"
#else /* Linux */
    # if defined(__WORDSIZE) && (__WORDSIZE == 64)
    #  define RV_PRI64 "l"
    # else
    #  define RV_PRI64 "ll"
    # endif
#endif

#define RISCV_sprintf snprintf
