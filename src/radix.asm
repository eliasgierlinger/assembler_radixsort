;---- SET ASC TO 0 IF YOU WANT TO SORT DESCENDINGLY ----; 
ASC = 0
.data

;prefixArr dw 16 dup (1)
oneArr dd 8 dup (1)

tempArr db 32 dup (?)

.code

RadixSort proc ; void RadixSort(unsigned long int* arr, unsigned long int* helperArr, unsigned long int length)
; rcx : arr
; rdx : helperArr
; r8d : length
push rbx

vmovdqu ymm15, ymmword ptr [OFFSET oneArr] ; we can AND with this ymmword to keep only the last bit of the longs

FOR forvalue, <0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31>

;set buckets to zero
xor r10d, r10d ; zero-bucket
xor r11d, r11d ; one-bucket


;calculate the amount of times, we need to loop through the code (where we process 64 longs at once)
mov eax, r8d ; copy r8d into eax
mov r12d, r8d
and r12d, 63 ; bitwise and with 63 is the same as modulo with 64 - r12d now contains the amount of longs left at the end
shr eax, 6 ; divide by 64 - eax now contains the amount of times we need to loop

jz Residuals&forvalue& ; if eax is zero and we needn't ever go through the loop, jump directly to Residuals


PrefixSumLoopHead&forvalue&:
; we will load 64 longs at once
; a ymmword fits 8 longs, so we need 8 ymmwords
; we fill the 8 ymmwords with longs
; then we AND all of them with 1 (oneArr) in order to get only the bit we need of all longs
; the zeroth ymmword is then shifted to the left by 0 bits, the first ymmword by 1 bit, ... and the 7th ymmword is shifted by 7 bits
; then we can OR all of the ymmwords into a single ymmword
; that single ymmword will look like this: (00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000 XXXXXXXX) (00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000 XXXXXXXX) (00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000 XXXXXXXX) (00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000 XXXXXXXX)
; now we put that into tempArr, where for some reason the bits swap places a bit: (XXXXXXXX 00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000) (XXXXXXXX 00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000) (XXXXXXXX 00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000) (XXXXXXXX 00000000 00000000 00000000 XXXXXXXX 00000000 00000000 00000000)
; then merge all 64 Xs into a register
; on that register we can use popcount to get all amount of 1s
 
vmovdqu ymm0, ymmword ptr [rcx]
vmovdqu ymm1, ymmword ptr [rcx+32]
vmovdqu ymm2, ymmword ptr [rcx+64]
vmovdqu ymm3, ymmword ptr [rcx+96]
vmovdqu ymm4, ymmword ptr [rcx+128]
vmovdqu ymm5, ymmword ptr [rcx+160]
vmovdqu ymm6, ymmword ptr [rcx+192]
vmovdqu ymm7, ymmword ptr [rcx+224]

vpand ymm0, ymm0, ymm15 ; ymm0 = ymm0 & ymm15
vpand ymm1, ymm1, ymm15
vpand ymm2, ymm2, ymm15
vpand ymm3, ymm3, ymm15
vpand ymm4, ymm4, ymm15
vpand ymm5, ymm5, ymm15
vpand ymm6, ymm6, ymm15
vpand ymm7, ymm7, ymm15


; the shifting part will change depending on the iteration
; this is the code for the first iteration:
;vpslld ymm0, ymm0, 0
;vpslld ymm1, ymm1, 1 
;vpslld ymm2, ymm2, 2
;vpslld ymm3, ymm3, 3
;vpslld ymm4, ymm4, 4
;vpslld ymm5, ymm5, 5
;vpslld ymm6, ymm6, 6
;vpslld ymm7, ymm7, 7

; this is the code for the second iteration
;vpsrld ymm0, ymm0, 1
;vpslld ymm1, ymm1, 0
;vpslld ymm2, ymm2, 1
;vpslld ymm3, ymm3, 2
;vpslld ymm4, ymm4, 3
;vpslld ymm5, ymm5, 4
;vpslld ymm6, ymm6, 5
;vpslld ymm7, ymm7, 6

; we can constate, that the formula, by which the amount, that we need to shift left, is calculated, is the following:
;vpslld ymm0, ymm0, (0-forvalue)
;vpslld ymm1, ymm1, (1-forvalue)
;vpslld ymm2, ymm2, (2-forvalue)
;vpslld ymm3, ymm3, (3-forvalue)
;vpslld ymm4, ymm4, (4-forvalue)
;vpslld ymm5, ymm5, (5-forvalue)
;vpslld ymm6, ymm6, (6-forvalue)
;vpslld ymm7, ymm7, (7-forvalue)

; because we cannot shift left by a negative amount, we need to add macro-ifs:
FOR regshiftval, <0,1,2,3,4,5,6,7>

if regshiftval - forvalue gt 0
vpslld ymm&regshiftval&, ymm&regshiftval&, (regshiftval-forvalue)
elseif regshiftval - forvalue lt 0
vpsrld ymm&regshiftval&, ymm&regshiftval&, (forvalue-regshiftval)
else ; do nothing when we need not shift
endif

ENDM




vpor ymm0, ymm0, ymm1 ; ymm0 = ymm0 | ymm1
vpor ymm0, ymm0, ymm2
vpor ymm0, ymm0, ymm3
vpor ymm0, ymm0, ymm4
vpor ymm0, ymm0, ymm5
vpor ymm0, ymm0, ymm6
vpor ymm0, ymm0, ymm7

; copy ymm0 into tempArr
vextracti128 xmmword ptr [OFFSET tempArr], ymm0, 0 ; copy first half of ymm0 into tempArr
vextracti128 xmmword ptr [OFFSET tempArr+16], ymm0, 1 ; copy second half of ymm0 into tempArr

; merge into rbx
xor rbx, rbx ; set rbx to zero
or bl, byte ptr [OFFSET tempArr] ; put first Xs into lowest 8 bits of rbx
shl rbx, 8 ; shift Xs to the left
or bl, byte ptr [OFFSET tempArr+4] ; add new Xs
shl rbx, 8
or bl, byte ptr [OFFSET tempArr+8]
shl rbx, 8
or bl, byte ptr [OFFSET tempArr+12]
shl rbx, 8
or bl, byte ptr [OFFSET tempArr+16]
shl rbx, 8
or bl, byte ptr [OFFSET tempArr+20]
shl rbx, 8
or bl, byte ptr [OFFSET tempArr+24]
shl rbx, 8
or bl, byte ptr [OFFSET tempArr+28]

popcnt rbx, rbx ; get amount of 1s and put it into rbx

add r11d, ebx ; add to one-bucket
add r10d, 64
sub r10d, ebx ; add to zero-bucket

add rcx, 256 ; move to next 64 longs
dec eax ; decrease loop counter
jnz PrefixSumLoopHead&forvalue&

cmp r12d, 0 ; skip residuals if dont have any more longs
je ResidualsEnd&forvalue&

Residuals&forvalue&:

mov ebx, dword ptr [rcx]
and ebx, (1b SHL forvalue) ; get the desired bit

jnz PrefixBitSet&forvalue&

;Bit Not Set:
inc r10d
jmp PrefixBucketsUpdated&forvalue&

PrefixBitSet&forvalue&:
inc r11d
PrefixBucketsUpdated&forvalue&:

add rcx, 4 ; move to next long
dec r12d ; update counter
jnz Residuals&forvalue&

ResidualsEnd&forvalue&:

; add zero bucket to one bucket for the proper prefix sum - or the other way around for descending sort
IF ASC NE 0
add r11d, r10d
ELSE
add r10d, r11d
ENDIF


; END OF PREFIX SUM CALCULATION
; now we can reorder the elements

mov r12d, r8d ; get back length of original array



ReorderLoop&forvalue&: ; rcx -> last element +1 of original array, rdx -> start of destination array
sub rcx, 4 ; at the start rcx is arr[arr.length] -> sub 4 to get to last element; on future iterations we want to move down the array

mov ebx, dword ptr [rcx] ; load source long from memory
mov r13d, ebx ; copy to r13b to check if bit is set
and r13d, (1b SHL forvalue) ; get the desired bit

mov r13, rdx ; this does not change flags! the next line is triggered by the AND operation


jnz ReorderBitSet&forvalue&

;Bit Not Set:
dec r10d ; decrease r10
mov eax, r10d ; note that this also zeroes the first 32 bits (which is wanted here)
jmp BitSetFin&forvalue&


ReorderBitSet&forvalue&:
dec r11d ; decrease r11
mov eax, r11d


BitSetFin&forvalue&:
shl rax, 2; multiply with 4, since we need to move forward 4 bytes
add r13, rax ; get destination adress
mov dword ptr [r13], ebx ; ebx was set to *rcx above; move to destination

dec r12d
jnz ReorderLoop&forvalue& ; we still have elements to reorder -> loop back

; swap input and output array
mov rax, rcx
mov rcx, rdx
mov rdx, rax

; we now have the prefix sums in r10 and r11
vpslld ymm15, ymm15, 1 ; shift the bits left, since we now want to AND with another bit - this probably breaks the shifting up above - update to use rotation

ENDM

pop rbx

ret

RadixSort endp
end