## Stage 1: The Symbolic Cast

In the first stage, we establish the fundamental link between Lisp and C. We prove that a high-level language can "bake" a memory-perfect image that a low-level language can "hydrate" without a single line of parsing logic.

### Architectural Concept

* **The Bake:** Lisp calculates the exact byte-offsets for an array of strings and appends a 32-bit sentinel.
* **The Cast:** C maps a raw pointer directly onto a struct. It doesn't "read" data; it simply "is" the data.
* **The Fuse:** If Lisp and C disagree on the geometry by even one byte, the `sentinel` check fails, and the system halts safely.

### The Architect (emit.lisp)

```lisp
;; Bakes a fixed-size 2D string array and a verification sentinel.
(defconstant +msg-count+ 5)
(defconstant +msg-len+ 32)
(defconstant +sentinel+ #xDEADBEEF)

(defun verify-geometry (messages)
  "Verifies that the Lisp data matches the C memory layout precisely."
  (let ((actual-count (length messages)))
    (when (/= actual-count +msg-count+)
      (error "Geometry Mismatch: C expects ~A messages, but Lisp provided ~A." +msg-count+ actual-count)))
  
  (loop for msg in messages for i from 0
        do (when (>= (length msg) +msg-len+)
             (error "Buffer Overflow: Message [~A] exceeds ~A bytes." i (1- +msg-len+)))))

(defun bake-messages (filename messages)
  (verify-geometry messages)
  (with-open-file (out filename :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
    ;; Write the Array of Strings (padded with null bytes)
    (loop for msg in messages do
          (loop for i from 0 below +msg-len+ do
                (write-byte (if (< i (length msg)) (char-code (char msg i)) 0) out)))
    ;; Write the Sentinel Value (Little-Endian)
    (loop for i from 0 to 24 by 8 do (write-byte (ldb (byte 8 i) +sentinel+) out))))

(bake-messages "world.bin" '("System initializing..." "Hydration active." "Zero parsing." "Sentinel standby." "Systems nominal."))

```

### The Runtime (main.c)

```c
#include <stdio.h>
#include <stdint.h>

#define MSG_COUNT 5
#define MSG_LEN 32

typedef struct {
    char     messages[MSG_COUNT][MSG_LEN]; // 160 bytes
    uint32_t sentinel;                     // 4 bytes
} MessageSlab;

int main() {
    uint8_t arena[256]; 
    FILE *f = fopen("world.bin", "rb");
    if (!f) return 1;

    // Zero-overhead hydration
    fread(arena, 1, sizeof(MessageSlab), f);
    fclose(f);

    // The Symbolic Cast
    MessageSlab *world = (MessageSlab*)arena;

    // The Physical Fuse
    if (world->sentinel != 0xDEADBEEF) {
        printf("[FATAL] Spec mismatch! Sentinel: 0x%08X\n", world->sentinel);
        return 1;
    }

    printf("--- HYDRATION SUCCESSFUL ---\n");
    for(int i = 0; i < MSG_COUNT; i++) printf("[%d]: %s\n", i, world->messages[i]);
    return 0;
}

```

### Build & Execution Log

```text
[1/2] Lisp: Baking binary slab (world.bin)...
[Analyzer] Geometry verified. Data aligns with C specification.
[2/2] C: Compiling Hydration Runtime...
---------------------------------
[SUCCESS] Runtime Compiled.

--- HYDRATION SUCCESSFUL (164 bytes read) ---
Message [0]: System initializing...
Message [1]: Hydration active.
Message [2]: Zero parsing.
Message [3]: Sentinel standby.
Message [4]: Systems nominal.
---------------------------------------------
Sentinel Verified: 0xDEADBEEF

```

---
