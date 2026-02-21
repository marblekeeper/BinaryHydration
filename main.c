// main.c
#include <stdio.h>
#include <stdint.h>

#define MSG_COUNT 5
#define MSG_LEN 32

// =========================================================================
// THE PHYSICAL SPEC
// Total size = (5 * 32) + 4 = 164 bytes
// This is the single source of truth for the C runtime.
// =========================================================================
typedef struct {
    char     messages[MSG_COUNT][MSG_LEN]; // 160 bytes
    uint32_t sentinel;                     // 4 bytes
} MessageSlab;

int main() {
    uint8_t arena[1024]; 
    
    // 1. Binary Hydration
    FILE *f = fopen("world.bin", "rb");
    if (!f) {
        printf("Error: Could not find world.bin. Did Lisp run?\n");
        return 1;
    }
    // We only read exactly the size of our spec
    size_t bytes_read = fread(arena, 1, sizeof(MessageSlab), f);
    fclose(f);

    // 2. The Symbolic Cast
    MessageSlab *world = (MessageSlab*)arena;

    // 3. The Security / Spec Verification
    // If the Lisp layout and C layout differ by even 1 byte, this fails.
    if (world->sentinel != 0xDEADBEEF) {
        printf("[FATAL ERROR] Slab corruption or spec mismatch detected!\n");
        printf("Expected Sentinel: 0xDEADBEEF\n");
        printf("Got Sentinel     : 0x%08X\n", world->sentinel);
        return 1; // Halt execution immediately
    }

    // 4. Execution
    printf("--- HYDRATION SUCCESSFUL (%zu bytes read) ---\n", bytes_read);
    for(int i = 0; i < MSG_COUNT; i++) {
        printf("Message [%d]: %s\n", i, world->messages[i]);
    }
    printf("---------------------------------------------\n");
    printf("Sentinel Verified: 0x%08X\n", world->sentinel);

    return 0;
}