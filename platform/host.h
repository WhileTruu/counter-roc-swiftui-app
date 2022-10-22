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

struct RocPotatoTextElem {
    const struct RocStr schMext;
    float poop;
};

struct RocTextElem {
    const struct RocStr text;
};

struct RocXTextElem {
    const struct RocStr ext;
};

struct RocXXTextElem {
    const struct RocStr sext;
};

struct RocVStackElem {
    const struct RocList children;
};

enum RocElemTag {
    PotatoTextElem = 0,
    TextElem = 1,
    VStackElem = 2,
    XTextElem = 3,
    XXTextElem = 4
};

union RocElemEntry {
    struct RocPotatoTextElem potatoTextElem;
    struct RocTextElem textElem;
    struct RocVStackElem vStackElem;
    struct RocXTextElem xTextElem;
    struct RocXXTextElem xxTextElem;
};

struct RocElem {
    union RocElemEntry *entry;
    enum RocElemTag *tag;
};

extern void roc__mainForHost_1_exposed_generic(
    const struct RocElem *ret,
    const struct RocStr *arg
);
