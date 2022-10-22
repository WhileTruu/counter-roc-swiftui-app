#include <stdlib.h>

struct RocStr {
    char* bytes;
    size_t len;
    size_t capacity;
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
struct RocPotatoTextElem {
    const struct RocStr schMext;
    float poop;
};

enum RocElemTag {
    PotatoTextElem = 0,
    TextElem = 1,
    XTextElem = 2,
    XXTextElem = 3
};

union RocElemEntry {
    struct RocPotatoTextElem potatoTextElem;
    struct RocTextElem textElem;
    struct RocXTextElem xTextElem;
    struct RocXXTextElem xxTextElem;
};

struct RocElem {
    union RocElemEntry entry;
    enum RocElemTag tag;
};

extern void roc__mainForHost_1_exposed_generic(
    const struct RocElem *ret,
    const struct RocStr *arg
);
