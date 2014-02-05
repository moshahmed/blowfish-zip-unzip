/*
Knuth's random number generator.
From http://www-cs-faculty.stanford.edu/~uno/programs/rng.c 
Additions GPL(C) moshahmed/at/gmail
$Header: c:/cvs/repo/github/bfz/zips/zip30/krani.h,v 1.1 2014-02-04 11:24:58 a Exp $
*/

#ifndef HAVE_KRAND
#define HAVE_KRAND

void knuth_rand_seed(long seed);
long knuth_rand(void);
long knuth_rand_max(void);

#endif
