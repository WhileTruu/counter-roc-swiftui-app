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

struct RocButtonElem {
    const struct RocStr label;
    void* onClick;
};

union RocElemEntry {
    struct RocTextElem textElem;
    struct RocStackElem stackElem;
    struct RocButtonElem buttonElem;
};

struct RocElem {
    union RocElemEntry *entry;
};

extern void roc__programForHost_1_exposed_generic();

extern void roc__programForHost_1__Init_caller(
    const struct RocStr *arg,
    void *closure,
    void *ret
);

extern void roc__programForHost_1__Update_caller(
    const void *model,
    const void *msg,
    void *closure,
    void *ret
);

extern void roc__programForHost_1__Render_caller(
    const void *arg,
    void *closure,
    struct RocElem *ret
);
