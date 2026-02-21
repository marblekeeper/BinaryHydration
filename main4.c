// main4.c
#include <stdio.h>
#include <stdint.h>
#include <string.h>

// We define maximum absolute capacities for static allocation (NASA Rule of Ten)
// But the *logical* limits are dictated entirely by the Lisp config header.
#define MAX_MSGS 5
#define MAX_MSG_LEN 32
#define MAX_DATA 16

// =========================================================================
// THE PHYSICAL SPEC v4
// Total size = 24 (Config) + 160 (Text) + 16 (Numeric) + 4 (Sentinel) = 204 bytes
// =========================================================================
typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t msg_count;         // Lisp-defined boundary
    uint32_t msg_len;           // Lisp-defined boundary
    uint32_t data_count;        // Lisp-defined boundary
    uint32_t active_index;      // Current state
} BinaryConfig;

typedef struct {
    BinaryConfig config;                        // 24 bytes
    char         messages[MAX_MSGS][MAX_MSG_LEN]; // 160 bytes
    uint8_t      statuses[MAX_DATA];            // 16 bytes
    uint32_t     sentinel;                      // 4 bytes
} ExecutionState;

int main() {
    uint8_t arena[1024]; 
    
    // 1. HYDRATION
    FILE *f = fopen("world4.bin", "rb");
    if (!f) return 1;
    fread(arena, 1, sizeof(ExecutionState), f);
    fclose(f);

    ExecutionState *state = (ExecutionState*)arena;

    // 2. GEOMETRIC VERIFICATION & HARDWARE SANITY CHECK
    if (state->config.magic != 0x5A45524F || state->config.version != 4 || state->sentinel != 0xDEADBEEF) {
        printf("[FATAL] Geometry or DNA Header Mismatch!\n");
        return 1;
    }
    
    // Check that Lisp's requested limits fit inside C's maximum physical limits
    if (state->config.msg_count > MAX_MSGS || state->config.data_count > MAX_DATA) {
        printf("[FATAL] Binary config requests bounds outside of static arena capacity!\n");
        return 1;
    }

    // 3. EXECUTION STATE CHECK
    uint32_t idx = state->config.active_index;
    
    // C reads its limits directly from the binary header
    if (idx >= state->config.msg_count) {
        printf("\n--- HYDRATION SUCCESS (v%u) ---\n", state->config.version);
        printf("[C Runtime] ALL TASKS COMPLETE. Halting sequence.\n");
        return 0;
    }

    printf("\n--- HYDRATION SUCCESS (v%u) ---\n", state->config.version);
    printf("Limits Loaded: %u Messages, %u Numeric Slots\n", state->config.msg_count, state->config.data_count);
    
    // Hydrate both Text and Numeric data simultaneously
    char* active_task = state->messages[idx];
    uint8_t active_status = state->statuses[idx];
    
    printf(">>> CURRENT TASK [%u]: %s (Status Code: %u)\n", idx, active_task, active_status);

    // 4. MUTATION
    printf("[C Runtime] Processing task...\n");
    strncpy(active_task, "[DONE] Task completed.", state->config.msg_len - 1);
    
    // Update the numeric sub-arena (Change Status from 0 to 1)
    state->statuses[idx] = 1; 
    
    // Advance the state machine
    state->config.active_index += 1;

    // Save state
    FILE *out = fopen("world4.bin", "wb");
    fwrite(state, 1, sizeof(ExecutionState), out);
    fclose(out);
    
    printf("[SUCCESS] Task marked complete (Status=1). File 'world4.bin' overwritten.\n");

    return 0;
}