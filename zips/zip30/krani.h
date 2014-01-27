/*
Knuth's random number generator.
From http://www-cs-faculty.stanford.edu/~uno/programs/rng.c 
Additions GPL(C) moshahmed/at/gmail
$Header: c:/cvs/repo/src/zips/zip30/krani.h,v 1.5 2014-01-27 14:50:24 a Exp $
*/

#ifndef HAVE_KRAND
#define HAVE_KRAND

void knuth_rand_seed(long seed);
long knuth_rand(void);
long knuth_rand_max(void);

#endif
