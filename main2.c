// main2.c
#include <stdio.h>
#include <stdint.h>

#define MSG_COUNT 5
#define MSG_LEN 32

// =========================================================================
// THE PHYSICAL SPEC
// Total size = 4 (offset) + 160 (messages) + 4 (sentinel) = 168 bytes
// =========================================================================
typedef struct {
    uint32_t active_offset;                // 4 bytes
    char     messages[MSG_COUNT][MSG_LEN]; // 160 bytes
    uint32_t sentinel;                     // 4 bytes
} ExecutionState;

int main() {
    uint8_t arena[1024]; 
    
    // 1. Binary Hydration
    // Ensure this matches exactly what Lisp outputs!
    FILE *f = fopen("world.bin", "rb");
    if (!f) {
        printf("[FATAL ERROR] Could not find 'world.bin'. Check your Lisp output!\n");
        return 1; // Halt loudly
    }
    
    size_t bytes_read = fread(arena, 1, sizeof(ExecutionState), f);
    fclose(f);

    // 2. The Symbolic Cast
    ExecutionState *state = (ExecutionState*)arena;

    // 3. Security Verification
    if (state->sentinel != 0xDEADBEEF) {
        printf("[FATAL ERROR] Geometry mismatch detected!\n");
        printf("Expected Sentinel: 0xDEADBEEF\n");
        printf("Got Sentinel     : 0x%08X\n", state->sentinel);
        return 1;
    }

    // =========================================================================
    // 4. RESUME EXECUTION VIA RELATIVE POINTER MATH
    // Data is Code. Code is Geometry.
    // We calculate the raw memory pointer by adding the baked byte offset 
    // to the base address of our struct.
    // =========================================================================
    char* active_task_ptr = (char*)state + state->active_offset;

    printf("--- STATE HYDRATED (%zu bytes read) ---\n", bytes_read);
    printf("Base Arena Address : %p\n", (void*)state);
    printf("Calculated Pointer : %p (Base + %u bytes)\n", (void*)active_task_ptr, state->active_offset);
    printf("\n>>> RESUMING TASK: %s\n", active_task_ptr);
    printf("---------------------------------------------\n");
    printf("Sentinel Verified  : 0x%08X\n", state->sentinel);

    return 0;
}