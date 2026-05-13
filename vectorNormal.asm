; ============================================================
; Autor: Edson Joel Carrera Avila
; vectorNormal.asm
; ============================================================

.586
.model flat, c

; ============================================================
; SECCIÓN DE CÓDIGO (.code)
; ============================================================
.code
; --- Inicio del programa ---

; Parámetros: [EBP+8]  = puntero a vec (double*)
;             [EBP+12] = N (int)
vectorNormal PROC
    PUSH    EBP                     ; Guardamos el marco de pila actual
    MOV     EBP, ESP                ; Establecemos el nuevo marco de pila
    PUSH    ESI                     ; Preservamos ESI según la convención cdecl    
    MOV     ESI, [EBP+8]            ; ESI apunta al inicio de vec
    MOV     ECX, [EBP+12]           ; ECX almacena la dimensión N (contador del ciclo)
    FLDZ                            ; Cargamos 0.0 en la pila de la FPU. ST(0) = acumulador
    TEST    ECX, ECX                ; Comparamos N con 0
    JLE     fin                     ; Si N <= 0, saltamos al final (retorna 0.0)

; --- Bucle de suma de cuadrados ---
bucle:
    FLD     QWORD PTR [ESI]         ; Cargamos vec[i] en ST(0). El acumulador baja a ST(1)
    FMUL    ST(0), ST(0)            ; Multiplicamos ST(0) por sí mismo. ST(0) = vec[i]^2
    FADDP   ST(1), ST(0)            ; Sumamos ST(0) al acumulador en ST(1) y desapilamos. ST(0) = acumulador
    ADD     ESI, 8                  ; Avanzamos 8 bytes en vec (tamaño de un double)
    DEC     ECX                     ; Disminuimos el contador N
    JNZ     bucle                   ; Si ECX no es 0, repetimos el ciclo

; --- Raíz cuadrada ---
    FSQRT                           ; Calculamos la raíz cuadrada del acumulador. ST(0) = sqrt(suma_cuadrados)

; --- Fin del programa ---
fin:
    POP     ESI                 
    MOV     ESP, EBP            
    POP     EBP                 
    RET                         
vectorNormal ENDP

END
