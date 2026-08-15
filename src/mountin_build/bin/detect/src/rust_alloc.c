/*
 * Rust allocator shim - forwards Rust allocator calls to C stdlib.
 * Required when linking Rust static libraries from C.
 *
 * Note: malloc() on most platforms returns memory aligned to at least
 * sizeof(max_align_t), typically 16 bytes. This is sufficient for Rust's
 * standard library which uses alignments <= 16 for typical allocations.
 */

#include <stdlib.h>
#include <string.h>

void *__rust_alloc(size_t size, size_t align) {
    (void)align;  /* malloc provides sufficient alignment for typical use */
    return malloc(size);
}

void __rust_dealloc(void *ptr, size_t size, size_t align) {
    (void)size;
    (void)align;
    free(ptr);
}

void *__rust_realloc(void *ptr, size_t old_size, size_t align, size_t new_size) {
    (void)old_size;
    (void)align;
    return realloc(ptr, new_size);
}

void *__rust_alloc_zeroed(size_t size, size_t align) {
    (void)align;
    return calloc(1, size);
}
