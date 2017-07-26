#****************************************************************************
#*
#*   Copyright (C) 2016 Shilo_XyZ_. All rights reserved.
#*   Author:  Shilo_XyZ_ <Shilo_XyZ_<at>mail.ru>
#*
#* Redistribution and use in source and binary forms, with or without
#* modification, are permitted provided that the following conditions
#* are met:
#*
#* 1. Redistributions of source code must retain the above copyright
#*    notice, this list of conditions and the following disclaimer.
#* 2. Redistributions in binary form must reproduce the above copyright
#*    notice, this list of conditions and the following disclaimer in
#*    the documentation and/or other materials provided with the
#*    distribution.
#*
#* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
#* OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#* AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#* ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#* POSSIBILITY OF SUCH DAMAGE.
#*
#****************************************************************************/

cmake_minimum_required(VERSION 2.8.5)

function(floterise RESULT VALUE DEVIDER)
    math(EXPR RESULT_N
        "${VALUE} / ${DEVIDER}")
    math(EXPR RESULT_F
        "${VALUE} - ${RESULT_N} * ${DEVIDER}")

    set(${RESULT} "${RESULT_N}.${RESULT_F}" PARENT_SCOPE)
endfunction()

macro(calc_test_input_period_ms CALCULED_TEST_PERIOD_MS DEVIDER)
    math(EXPR CALCULED_TEST_FREQ   "${REFERENCE_CLOCK_HZ} / ${DEVIDER}")
    math(EXPR ${CALCULED_TEST_PERIOD_MS} "1000 / ${CALCULED_TEST_FREQ}")
endmacro()

