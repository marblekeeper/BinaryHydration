## Stage 3: The Persistent State Machine

In Stage 3, we bridge the gap between "loading data" and "executing a process." The binary slab is no longer a static snapshot; it is a living, mutable environment. We introduce **Mutation and Persistence**, allowing the C runtime to process a task, update its own internal state, and dehydrate back to disk.

### Architectural Concept

* **The Magic Header:** We add a `magic` number (`0x5A45524F`) and a `version` field. This ensures the runtime doesn't just check the end of the file (the sentinel) but also verifies the identity and "DNA" of the slab before execution begins.
* **Mutation-in-Place:** The C runtime doesn't use temporary variables to track progress. It modifies the hydrated memory slab directly—updating the message text and advancing the `active_offset` geometrically.
* **Seamless Persistence:** Because the in-memory `struct` is identical to the on-disk file, "saving" the entire system state is reduced to a single, atomic `fwrite`.

---

### The Architect (emit3.lisp)

```lisp
;; Bakes a Magic Header, Version, active offset, array, and Sentinel.
(defconstant +magic-number+ #x5A45524F) ; "ZERO"
(defconstant +version+ 3)

(defun bake-state (filename messages active-index)
  (with-open-file (out filename :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
    ;; 1. The Header (Identity & Versioning)
    (write-uint32 +magic-number+ out)
    (write-uint32 +version+ out)
    
    ;; 2. The Active Offset (Relative Navigation)
    ;; Offset = 4(magic) + 4(version) + 4(offset itself) + (index * 32)
    (let ((active-offset (+ 12 (* active-index +msg-len+))))
      (write-uint32 active-offset out))
    
    ;; 3. The Data & 4. The Sentinel
    ;; ... (Payload emission)
    ))

```

### The Runtime (main3.c)

```c
typedef struct {
    uint32_t magic;                // "ZERO" Identity
    uint32_t version;              // Version 3
    uint32_t active_offset;        // Navigation DNA
    char     messages[5][32];      // Payload
    uint32_t sentinel;             // Physical Fuse
} ExecutionState;

int main() {
    // ... Hydration ...

    // 1. ADVANCE STATE
    // We update the data within the hydrated memory directly
    strncpy(active_task_ptr, "[DONE] Task completed.", MSG_LEN - 1);
    state->active_offset += MSG_LEN; 

    // 2. DEHYDRATION
    // Save the entire world state back to disk in one transaction
    FILE *out = fopen("world3.bin", "wb");
    fwrite(state, 1, sizeof(ExecutionState), out);
    fclose(out);
}

```

### Build & Iteration Log

Observe the **Lifecycle**: Lisp suspends the process, C hydrates it, completes a phase, and "freezes" the state back into the file. Subsequent runs pick up exactly where the previous run left off.

```text
PS C:\BinaryHydration> ./hydration_test.exe
--- HYDRATION SUCCESS (v3) ---
>>> CURRENT TASK: Phase 3: Synchronize data

[C Runtime] Processing task...
[C Runtime] Advanced offset by 32 bytes.
>>> NEXT TASK PREPPED: Phase 4: Deploy payload
[SUCCESS] Memory image 'world3.bin' overwritten. State persisted.

PS C:\BinaryHydration> ./hydration_test.exe
--- HYDRATION SUCCESS (v3) ---
>>> CURRENT TASK: Phase 4: Deploy payload
...

```

---