#include <stdlib.h>

struct RocStr {
    char* bytes;
    size_t len;
    size_t capacity;
};

struct RocList {
    void** elements;
    size_t length;
    size_t capacity;
};

struct RocTextElem {
    const struct RocStr text;
};

struct RocStackElem {
    const struct RocList children;
};

union RocElemEntry {
    struct RocTextElem textElem;
    struct RocStackElem stackElem;
};

struct RocElem {
    union RocElemEntry *entry;
};

extern void roc__programForHost_1_exposed_generic(
    const struct RocElem *ret,
    const struct RocStr *arg
);
