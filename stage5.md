## Stage 5: The Build-Time Handshake (Compile-Time Invariants)

In Stage 5, we achieve the ultimate goal of the **Metaprogramming Architect**: total synchronization between the high-level design and the low-level machine code. We move from "suggested" limits to **Compile-Time Invariants**.

### Architectural Concept

* **The Architect’s Decree:** Lisp no longer just bakes the data; it bakes the **C Source Code** itself. By generating `arena_spec.h`, Lisp dictates the `EXACT_ARENA_SIZE` before the C compiler even starts.
* **Static Enforcement:** We introduce `_Static_assert`. This is a physical lock on the compilation process. If the C compiler attempts to add hidden padding bytes that violate Lisp's calculated geometry, the build fails instantly.
* **File Weight Verification:** At runtime, we perform a "Weight Check." If the file on disk is even one byte larger or smaller than the `EXACT_ARENA_SIZE` defined at compile-time, the system refuses to hydrate.

---

### The Architect (emit5.lisp)

```lisp
;; Calculate the absolute physical footprint
(defconstant +total-size+ (+ 24 (* +msg-count+ +msg-len+) +data-count+ 4))

(defun bake-c-header (filename size)
  "Decrees the physical truth to the C Compiler."
  (with-open-file (out filename :direction :output :if-exists :supersede)
    (format out "#define EXACT_ARENA_SIZE ~A~%" size)
    (format out "#define MAX_MSGS ~A~%" +msg-count+)
    (format out "#define MAX_DATA ~A~%" +data-count+)))

;; Execute the Decree
(bake-c-header "arena_spec.h" +total-size+)

```

### The Runtime (main5.c)

```c
#include "arena_spec.h" 

typedef struct {
    BinaryConfig config;                                
    char         messages[MAX_MSGS][MAX_MSG_LEN]; 
    uint8_t      statuses[MAX_DATA];            
    uint32_t     sentinel;                      
} ExecutionState;

// THE LOCK: Build fails if C layout != Lisp geometry
_Static_assert(sizeof(ExecutionState) == EXACT_ARENA_SIZE, 
               "Geometry Mismatch Detected!");

int main() {
    // 1. THE WEIGHT CHECK
    // Refuse to load if the file weight doesn't match the compile-time spec
    if (file_size != EXACT_ARENA_SIZE) {
        printf("[FATAL] File weight mismatch!");
        return 1;
    }

    // 2. ZERO-OVERHEAD HYDRATION
    // We allocate the exact number of bytes decreed by Lisp
    uint8_t arena[EXACT_ARENA_SIZE]; 
    fread(arena, 1, EXACT_ARENA_SIZE, f);
}

```

### Build & Execution Log

The "Handshake" is visible in the build log. Lisp generates the spec, and C uses that exact spec to allocate memory and verify the binary.

```text
[1/3] Cleaning old artifacts...
[2/3] Lisp: Baking binary slab (world.bin)...
[Architect] Generating C-Header 'arena_spec.h' with EXACT_ARENA_SIZE 204 bytes.
[Analyzer] Geometry verified. DNA limits mapped.
[3/3] C: Compiling Hydration Runtime...
---------------------------------
[SUCCESS] Runtime Compiled.

--- HYDRATION SUCCESS (v5 | EXACT MEMORY: 204 bytes) ---
Limits Loaded: 5 Messages, 16 Numeric Slots
>>> CURRENT TASK [0]: Phase 1: Boot sequence (Status Code: 0)

```

---
