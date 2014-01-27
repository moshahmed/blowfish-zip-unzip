blowfish-zip-unzip
==================

zip and unzip with blowfish encryption

Compiles with visual studio 2008

Tested binaries on win32x86

New option --blowfish to enable stronger encryption method.

Output zip files can contain mix of old and new encrypted files,
the data structure is identical; except that blowfish encrypted files
in an archive require this bf-unzip to unpack.

Sample Usage:

$ bf-zip   --blowfish -Deruo -P password1 file.zip  files1 .. zipup files1

$ bf-unzip --blowfish        -P password1 file.zip         .. to extract files1

$ zip                 -Deruo -P password2 file.zip  files2 .. to add more files2

$ bf-unzip                   -P password2 file.zip         .. to extract files2

- MoshAhmed/at/gmail
