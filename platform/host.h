#include <stdlib.h>

struct RocStr {
    char* bytes;
    size_t len;
    size_t capacity;
};


struct RocTextElem {
    const struct RocStr text;
};


extern void roc__mainForHost_1_exposed_generic(
    const struct RocTextElem *ret,
    const struct RocStr *arg
);
