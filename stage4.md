## Stage 4: Multi-Arena Segmentation & The DNA Header

In Stage 4, we introduce **Structural Segmentation**. Instead of a single array of strings, we now manage multiple types of data—textual and numeric—in separate memory "sub-arenas." To coordinate this, we expand the configuration header into a **DNA Header** that explicitly dictates the system's logical limits to the C runtime.

### Architectural Concept

* **The DNA Header:** The `BinaryConfig` struct now acts as the system's instruction manual. It tells C exactly how many messages exist and the size of the numeric data pool.
* **Multi-Arena Hydration:** With a single `fread`, we populate two distinct data structures: the `messages` array (text) and the `statuses` array (numeric).
* **Static Safety (NASA Rule of Ten):** While the logic is dynamic, the memory is static. We use `MAX_MSGS` to ensure the C compiler reserves enough space, but we use `state->config.msg_count` to ensure the logic never touches a byte it shouldn't.

---

### The Architect (emit4.lisp)

```lisp
;; Bakes a Config Header, Text Arena, Numeric Arena, and Sentinel.
(defconstant +msg-count+ 5)
(defconstant +data-count+ 16) ; DNA: Logical limits for numeric slots

(defun bake-universe (filename messages active-index)
  (with-open-file (out filename :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
    
    ;; 1. The DNA Header (24 bytes)
    ;; We export the system's physics to the binary slab.
    (write-uint32 +magic-number+ out)
    (write-uint32 +version+ out)
    (write-uint32 +msg-count+ out)   
    (write-uint32 +msg-len+ out)     
    (write-uint32 +data-count+ out)  
    (write-uint32 active-index out)  
    
    ;; 2. Sub-Arena A: Text
    ;; ... (Loop through messages)
                
    ;; 3. Sub-Arena B: Numeric Data (The "Status" Pool)
    (loop for i from 0 below +data-count+ do
          (write-byte (if (< i +msg-count+) 0 255) out)) ; 0=Pending, 255=Unused
                
    ;; 4. The Sentinel
    (write-uint32 +sentinel+ out)))

```

### The Runtime (main4.c)

```c
typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t msg_count;   // DNA: Logical Limit
    uint32_t data_count;  // DNA: Logical Limit
    uint32_t active_index;
} BinaryConfig;

typedef struct {
    BinaryConfig config;                                
    char         messages[MAX_MSGS][MAX_MSG_LEN]; 
    uint8_t      statuses[MAX_DATA];            // Numeric Sub-Arena
    uint32_t     sentinel;                      
} ExecutionState;

int main() {
    // ... Hydration ...

    // DNA VERIFICATION: Ensure the binary's physics fit in C's reality
    if (state->config.msg_count > MAX_MSGS) return 1;

    // SIMULTANEOUS DATA ACCESS
    char* active_task = state->messages[idx];
    uint8_t active_status = state->statuses[idx]; // Accessing the numeric sub-arena

    // UPDATE STATE
    state->statuses[idx] = 1; // Mark as complete
    state->config.active_index += 1;
    
    // ... Dehydration ...
}

```

### Iteration Log

Observe how the runtime now reports the **Limits Loaded** from the DNA header. It knows the size of its world before it takes a single step.

```text
PS C:\BinaryHydration> ./hydration_test.exe
--- HYDRATION SUCCESS (v4) ---
Limits Loaded: 5 Messages, 16 Numeric Slots
>>> CURRENT TASK [1]: Phase 2: Establish uplink (Status Code: 0)
[C Runtime] Processing task...
[SUCCESS] Task marked complete (Status=1). File 'world4.bin' overwritten.

PS C:\BinaryHydration> ./hydration_test.exe
--- HYDRATION SUCCESS (v4) ---
Limits Loaded: 5 Messages, 16 Numeric Slots
>>> CURRENT TASK [2]: Phase 3: Synchronize data (Status Code: 0)
...

```

---
