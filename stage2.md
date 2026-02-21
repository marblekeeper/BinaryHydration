## Stage 2: Geometric DNA & Config Headers

In the second stage, we evolve the architecture from a static data dump to a **Relocatable State Machine**. We introduce the concept of "Geometric DNA"—metadata that tells the C runtime exactly where to point its focus without the runtime having to perform any logic or searching.

### Architectural Concept

* **The "Aha" Moment:** Instead of the C program searching for the current task, Lisp calculates the **Relative Offset** (the exact number of bytes from the start of the struct) and bakes it into the header.
* **Immortal State:** By using an offset instead of a hardcoded pointer address, the binary slab becomes "relocatable." As seen in the logs, even when the `Base Arena Address` changes across different executions, the `Calculated Pointer` remains mathematically perfect.
* **Resuming Execution:** C simply adds the baked offset to its base pointer. This is hydration with a memory-perfect resume point.

---

### The Architect (emit2.lisp)

```lisp
;; Bakes a state machine array, the active execution offset, and a sentinel.
(defconstant +msg-count+ 5)
(defconstant +msg-len+ 32)
(defconstant +sentinel+ #xDEADBEEF)

(defun bake-state (filename messages active-index)
  (with-open-file (out filename :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
    ;; 1. Calculate and Write the Active Offset (Relative Pointer)
    ;; (4 bytes for offset) + (active-index * 32 bytes)
    (let ((active-offset (+ 4 (* active-index +msg-len+))))
      (format t "[Lisp] Saving active state offset at ~A bytes from base.~%" active-offset)
      (write-uint32 active-offset out))
    
    ;; 2. Write the Message Array
    (loop for msg in messages do
          (loop for i from 0 below +msg-len+ do
                (write-byte (if (< i (length msg)) (char-code (char msg i)) 0) out)))
                
    ;; 3. Write the Sentinel
    (write-uint32 +sentinel+ out)))

;; We simulate a process suspended at Phase 3 (Index 2)
(bake-state "world.bin" '("Phase 1: Boot" "Phase 2: Uplink" "Phase 3: Sync" "Phase 4: Deploy" "Phase 5: Terminate") 2)

```

### The Runtime (main2.c)

```c
typedef struct {
    uint32_t active_offset;                // 4 bytes
    char     messages[MSG_COUNT][MSG_LEN]; // 160 bytes
    uint32_t sentinel;                     // 4 bytes
} ExecutionState;

int main() {
    // ... Hydration (fread) and Sentinel Check ...

    ExecutionState *state = (ExecutionState*)arena;

    // RESUME EXECUTION VIA RELATIVE POINTER MATH
    // Base Pointer + Baked Offset = Instant Resume
    char* active_task_ptr = (char*)state + state->active_offset;

    printf("Base Arena Address : %p\n", (void*)state);
    printf("Calculated Pointer : %p (Base + %u bytes)\n", (void*)active_task_ptr, state->active_offset);
    printf("\n>>> RESUMING TASK: %s\n", active_task_ptr);
    
    return 0;
}

```

### Execution Log

Notice how the **Base Arena Address** changes every time the OS runs the program, but the **Relative Offset** (+68 bytes) remains the immutable geometric truth.

```text
PS C:\BinaryHydration> ./hydration_test.exe
--- STATE HYDRATED (168 bytes read) ---
Base Arena Address : 0000002B4F3FF3B0
Calculated Pointer : 0000002B4F3FF3F4 (Base + 68 bytes)

>>> RESUMING TASK: Phase 3: Synchronize data
---------------------------------------------
Sentinel Verified  : 0xDEADBEEF

PS C:\BinaryHydration> ./hydration_test.exe
--- STATE HYDRATED (168 bytes read) ---
Base Arena Address : 00000080F4FFF3A0
Calculated Pointer : 00000080F4FFF3E4 (Base + 68 bytes)
...

```

---
