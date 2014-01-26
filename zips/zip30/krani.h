/*
Knuth's random number generator.
From http://www-cs-faculty.stanford.edu/~uno/programs/rng.c 
Additions GPL(C) moshahmed/at/gmail
*/

void knuth_rand_seed(long seed);
long knuth_rand(void);
long knuth_rand_max(void);

