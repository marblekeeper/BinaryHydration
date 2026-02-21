// main3.c (Updated Execution Block)
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define MSG_COUNT 5
#define MSG_LEN 32

typedef struct {
    uint32_t magic;                        // 4 bytes  (0x5A45524F)
    uint32_t version;                      // 4 bytes  (3)
    uint32_t active_offset;                // 4 bytes
    char     messages[MSG_COUNT][MSG_LEN]; // 160 bytes
    uint32_t sentinel;                     // 4 bytes  (0xDEADBEEF)
} ExecutionState;

int main() {
    uint8_t arena[1024]; 
    
    FILE *f = fopen("world3.bin", "rb");
    if (!f) return 1;
    fread(arena, 1, sizeof(ExecutionState), f);
    fclose(f);

    ExecutionState *state = (ExecutionState*)arena;

    if (state->magic != 0x5A45524F || state->version != 3 || state->sentinel != 0xDEADBEEF) {
        printf("[FATAL] Geometry or Header Mismatch!\n");
        return 1;
    }

    char* active_task_ptr = (char*)state + state->active_offset;
    printf("--- HYDRATION SUCCESS (v%u) ---\n", state->version);
    printf(">>> CURRENT TASK: %s\n", active_task_ptr);

    // ---------------------------------------------------------
    // 4. MUTATION & BOUNDS CHECKING
    // ---------------------------------------------------------
    printf("\n[C Runtime] Processing task...\n");
    strncpy(active_task_ptr, "[DONE] Task completed.", MSG_LEN - 1);
    
    // Calculate the physical boundary of the array
    // 12 bytes of header + 160 bytes of array = 172 bytes
    uint32_t boundary = 12 + (MSG_COUNT * MSG_LEN);

    // Check if advancing pushes us into the Sentinel
    if (state->active_offset + MSG_LEN >= boundary) {
        printf("[C Runtime] SEQUENCE COMPLETE. Reached end of memory slab.\n");
    } else {
        state->active_offset += MSG_LEN; 
        char* next_task_ptr = (char*)state + state->active_offset;
        printf("[C Runtime] Advanced offset by %d bytes.\n", MSG_LEN);
        printf(">>> NEXT TASK PREPPED: %s\n", next_task_ptr);
    }

    FILE *out = fopen("world3.bin", "wb");
    fwrite(state, 1, sizeof(ExecutionState), out);
    fclose(out);
    
    printf("\n[SUCCESS] Memory image 'world3.bin' overwritten. State persisted.\n");

    return 0;
}