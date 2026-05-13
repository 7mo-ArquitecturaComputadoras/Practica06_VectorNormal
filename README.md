# Práctica 06 — Norma (Módulo) de un Vector en Ensamblador x86

## Descripción

Programa mixto **ensamblador x86 + C++** que calcula la **norma euclídea** (módulo o longitud) de un vector de números reales de dimensión arbitraria N. La función ensamblador recorre el vector con un registro puntero, acumula la suma de cuadrados elemento a elemento en la pila de la FPU, y devuelve la raíz cuadrada del acumulador en `ST(0)`.

La operación implementada es:

```
‖v‖ = √(v[0]² + v[1]² + ... + v[N-1]²)
```

---

## Estructura del Proyecto

```
Practica06_VectorNormal/
├── vectorNormal.asm                 # Función en ensamblador x86: acumula cuadrados y aplica FSQRT
├── main.cpp                         # Programa principal en C++: solicita datos y muestra el resultado
└── Practica06_VectorNormal.vcxproj  # Proyecto de Visual Studio con soporte MASM habilitado
```

---

## Interfaz y Convención de Llamada

La función ensamblador es invocada desde C++ usando la convención **cdecl** (convención C plana):

| Elemento               | Descripción                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| `.model flat, c`       | Modelo de memoria plana con compatibilidad de nombres C                     |
| `extern "C"` en C++    | Desactiva el *name mangling* para que el enlazador ubique el símbolo `vectorNormal` |
| `[EBP+8]`              | Puntero a `vec` (`double*`, 4 bytes en x86)                                |
| `[EBP+12]`             | Dimensión `N` (`int`, 4 bytes)                                             |
| `ST(0)` al hacer `RET` | Registro donde se deposita el resultado `double` para el llamador           |
| `ESI`                  | Preservado con `PUSH`/`POP` según exige la convención *cdecl*               |

Cada elemento `double` del vector ocupa **8 bytes**; por eso el puntero avanza con `ADD ESI, 8` en cada iteración.

---

## Funcionamiento del Algoritmo

La función implementa un **bucle de acumulación de cuadrados** sobre la pila de la FPU. Antes de entrar al bucle, verifica que `N > 0`; si no, retorna `0.0` inmediatamente. Al terminar el bucle, aplica `FSQRT` al acumulador para obtener la norma.

### Registros utilizados

| Registro | Rol                                                                         |
|----------|-----------------------------------------------------------------------------|
| `ESI`    | Puntero al elemento actual de `vec`; avanza 8 bytes por iteración           |
| `ECX`    | Contador decreciente: inicia en `N` y llega a 0 al terminar                 |
| `ST(0)`  | Valor al cuadrado `vec[i]²` durante la iteración; acumulador entre iteraciones; norma al final |
| `ST(1)`  | Acumulador desplazado temporalmente mientras `ST(0)` contiene el cuadrado   |

### Flujo de ejecución

```
Inicio
 └─ ESI = &vec[0], ECX = N
 └─ FLDZ → ST(0) = 0.0  (acumulador)
 └─ TEST ECX, ECX → N <= 0 ? → fin (retorna 0.0)

bucle:
 ├─ FLD  [ESI]           → ST(0)=vec[i],  ST(1)=acum
 ├─ FMUL ST(0), ST(0)    → ST(0)=vec[i]²,  ST(1)=acum
 ├─ FADDP ST(1), ST(0)   → ST(0)=acum + vec[i]²  (pop)
 ├─ ADD ESI, 8           → avanzar al siguiente double
 ├─ DEC ECX
 └─ JNZ bucle            → repetir si ECX != 0

 └─ FSQRT → ST(0) = √acum

fin:
 └─ RET → ST(0) = norma final
```

### Estado de la pila FPU por instrucción

| Instrucción           | ST(0)              | ST(1) |
|-----------------------|--------------------|-------|
| `FLDZ`                | `0.0` (acum)       | —     |
| `FLD [ESI]`           | `vec[i]`           | acum  |
| `FMUL ST(0), ST(0)`   | `vec[i]²`          | acum  |
| `FADDP ST(1), ST(0)`  | `acum + vec[i]²`   | —     |
| `FSQRT`               | `√acum`            | —     |

### Ejemplo con v=(3, 4, 0)

| Iteración | vec[i] | vec[i]² | Acumulador |
|-----------|--------|---------|------------|
| inicial   | —      | —       | 0.0        |
| 1         | 3.0    | 9.0     | 9.0        |
| 2         | 4.0    | 16.0    | 25.0       |
| 3         | 0.0    | 0.0     | 25.0       |
| FSQRT     | —      | —       | **5.0**    |

Resultado final: **5.000000**

---

## Instrucciones x86 Utilizadas

### FPU

| Instrucción  | Operación                                                                      |
|--------------|--------------------------------------------------------------------------------|
| `FLDZ`       | Carga la constante `0.0` al tope de la pila FPU; inicializa el acumulador      |
| `FLD`        | Carga un `double` (8 bytes) desde memoria al tope de la pila FPU               |
| `FMUL`       | Multiplica `ST(0)` por sí mismo (`ST(0),ST(0)`); eleva al cuadrado sin *pop*   |
| `FADDP`      | Suma `ST(0)` a `ST(1)` y hace *pop*; acumulador actualizado en `ST(0)`         |
| `FSQRT`      | Calcula la raíz cuadrada de `ST(0)` en hardware; resultado en el mismo registro |

### Propósito general

| Instrucción    | Operación                                                            |
|----------------|----------------------------------------------------------------------|
| `PUSH` / `POP` | Prólogo/epílogo del marco de pila y preservación de `ESI`            |
| `MOV`          | Carga puntero y contador desde el marco de pila a los registros      |
| `ADD`          | Avanza el puntero `ESI` en 8 bytes por iteración                     |
| `DEC`          | Decrementa `ECX` y actualiza banderas para el salto `JNZ`            |
| `TEST`         | Verifica si `ECX == 0` antes de entrar al bucle (AND lógica)         |
| `JLE`          | Salta al final si `N <= 0`; protección contra dimensión inválida     |
| `JNZ`          | Repite el bucle si `ECX != 0`                                        |
| `RET`          | Retorna al llamador; el resultado `double` permanece en `ST(0)`      |

---

## Ejemplo de Ejecución

```
Ingresa la dimension del vector (N): 3

--- DATOS DEL VECTOR ---
Ingresa el valor para vec[0]: 3
Ingresa el valor para vec[1]: 4
Ingresa el valor para vec[2]: 0

----------------------------------------
Resultado de la Norma del Vector: 5.000000
```

---

## Requisitos

- **Ensamblador:** MASM (Microsoft Macro Assembler), incluido en Visual Studio
- **Compilador C++:** MSVC (Visual Studio 2022, conjunto de herramientas v145)
- **Arquitectura:** x86 (32 bits), modo protegido plano (`flat`)
- **Sistema operativo:** Windows
- **Convención de llamadas:** `cdecl` / convención C (`flat, c`)
