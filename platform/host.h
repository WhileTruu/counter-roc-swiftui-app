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

typedef void* Model;

extern void roc__programForHost_1_exposed_generic();

extern void roc__programForHost_1__Init_caller(
    const struct RocStr *arg,
    void *closure,
    void *ret
);

extern void roc__programForHost_1__Render_caller(
    void *arg,
    void *closure,
    const struct RocElem *ret
);