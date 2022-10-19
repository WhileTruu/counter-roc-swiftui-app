#include <stdlib.h>

struct RocStr {
    char* bytes;
    size_t len;
    size_t capacity;
};


struct RocElem {
    const struct RocStr text;
};


extern void roc__mainForHost_1_exposed_generic(
    const struct RocElem *ret,
    const struct RocStr *arg
);
