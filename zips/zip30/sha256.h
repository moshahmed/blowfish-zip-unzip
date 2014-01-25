/*
//  $Header: c:/cvs/repo/src/zips/zip30/sha256.h,v 1.5 2014-01-25 02:51:25 a Exp $
//  FIPS-180-2 compliant SHA-256 implementation
//  GPL by Christophe Devine.
//  Modified for md5deep, in public domain.
//  Modified for zip and vim, GPL(C) moshahmed
*/

void  sha256_begin(void);
void  sha256_continue(char *buf, int buflen);
void  sha256_end(char *hexit, int len);

void  sha256_key(char *buf, char *salt, int salt_len, char* hexit, int hexit_len);
int   sha256_self_test(void);
