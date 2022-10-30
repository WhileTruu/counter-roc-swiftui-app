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


// PROGRAM

extern void roc__programForHost_1_exposed_generic();
extern int64_t roc__programForHost_size();

// MODEL

typedef void* Model;

extern void roc__programForHost_1__Init_caller(const struct RocStr *arg, void *closure, Model ret);
extern int64_t roc__programForHost_1__Init_size();
extern int64_t roc__programForHost_1__Init_result_size();

// UPDATE

extern void roc__programForHost_1__Update_caller(
    const Model model,
    const void *msg,
    void *closure,
    Model ret
);
extern int64_t roc__programForHost_1__Update_result_size();
extern int64_t roc__programForHost_1__Update_size();

// VIEW

extern void roc__programForHost_1__Render_caller(
    const Model model,
    void *closure,
    struct RocElem *ret
);
extern int64_t roc__programForHost_1__Render_size();
