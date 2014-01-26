/*
Blowfish encryption for zip and vim; in Blowfish output feedback mode.
GPL(C) moshahmed/at/gmail
Based on http://www.schneier.com/blowfish.html by Bruce Schneier
*/

#ifndef BLOWFISH_VERSION
#define BLOWFISH_VERSION   "3"

int           bf_self_test(void);
void          bf_ofb_update(unsigned char c);
unsigned char bf_ranbyte(void);
void          bf_clear_key(unsigned char *key);

#define BF_BLOCK       8
#define BF_OFB_LEN    (8*(BF_BLOCK))

/* encode byte c, using temp t.  Warning: c must not have side effects. */
#define BF_ZENCODE(c, t)  (t = bf_ranbyte(), bf_ofb_update(c), t^(c))

/* decode byte c in place */
#define BF_ZDECODE(c)   bf_ofb_update(c ^= bf_ranbyte())

#ifdef __GNUC__
#define _FILE_OFFSET_BITS 64
#define __int64 long long
#include <stdint.h>
#else
typedef unsigned long uint32_t;
typedef unsigned char uint8_t;
#endif

typedef union {
    uint32_t ul[2];
    uint8_t  uc[8];
    __int64  uul;
} block8;

typedef union {
    unsigned long ul;
    unsigned char uc[4];
} block4;

#pragma pack(push,4)
typedef struct {
  block4 salt;
  block8 iv;
} file_header;
#pragma pack(pop)

void krand_setup(int userseed);
void hash_salt_pass(char *cryptkey, file_header *fh);
void bf_e_cblock(uint8_t *block );
void bf_d_cblock(uint8_t *block );

#endif
