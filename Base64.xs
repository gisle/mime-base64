/* $Id$

Copyright (c) 1997 Gisle Aas

The tables and some of the code is borrowed from metamail, which comes
with this message:

  Copyright (c) 1991 Bell Communications Research, Inc. (Bellcore)

  Permission to use, copy, modify, and distribute this material 
  for any purpose and without fee is hereby granted, provided 
  that the above copyright notice and this permission notice 
  appear in all copies, and that the name of Bellcore not be 
  used in advertising or publicity pertaining to this 
  material without the specific, prior written permission 
  of an authorized representative of Bellcore.  BELLCORE 
  MAKES NO REPRESENTATIONS ABOUT THE ACCURACY OR SUITABILITY 
  OF THIS MATERIAL FOR ANY PURPOSE.  IT IS PROVIDED "AS IS", 
  WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.

*/


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static char basis_64[] =
   "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

#define XX 255  /* illegal base64 char */
#define EQ 254  /* padding */
static unsigned char index_64[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,62, XX,XX,XX,63,
    52,53,54,55, 56,57,58,59, 60,61,XX,XX, XX,EQ,XX,XX,
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
    XX,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,XX, XX,XX,XX,XX,

    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};

#define MAX_LINE       76
#define GETC(str,len)  (len > 0 ? len--,*str++ : EOF)
#define INVALID_B64(c) (index_64[(unsigned char)c] == XX)


MODULE = MIME::Base64		PACKAGE = MIME::Base64

SV*
encode_base64(sv,...)
	SV* sv
	PROTOTYPE: $;$

	PREINIT:
	char *str;   /* string to encode */
	int len;     /* length of the string */
        char *eol;   /* the end-of-line sequence to use */
        int eollen;  /* length of the EOL sequence */
	char *r;     /* result string */
	int rlen;    /* length of result string */
	unsigned char c1, c2, c3;
	int chunk;

	CODE:
	str = SvPV(sv, len);

	/* set up EOL from the second argument if present, default to "\n" */
	if (items > 1 && SvOK(ST(1))) {
	   eol = SvPV(ST(1), eollen);
        } else {
           eol = "\n";
	   eollen = 1;
        }

	/* calculate the length of the result */
	rlen = (len+2) / 3 * 4;  /* encoded bytes */
	if (rlen) {
	    /* add space for EOL */
	    rlen += ((rlen-1) / MAX_LINE + 1) * eollen;
	}

	/* allocate a result buffer */
	RETVAL = newSV(rlen+1);
	SvPOK_on(RETVAL);	
	SvCUR_set(RETVAL, rlen);
	r = SvPVX(RETVAL);

	/* encode */
	for (chunk=0; len > 0; len -= 3, chunk++) {
	    if (chunk == (MAX_LINE/4)) {
	        char *c = eol;
	        char *e = eol + eollen;
	        while (c < e)
		   *r++ = *c++;
	        chunk = 0;
            }
	    c1 = *str++;
	    c2 = *str++;
	    *r++ = basis_64[c1>>2];
	    *r++ = basis_64[((c1 & 0x3)<< 4) | ((c2 & 0xF0) >> 4)];
	    if (len > 2) {
	        c3 = *str++;
		*r++ = basis_64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6)];
	        *r++ = basis_64[c3 & 0x3F];
	    } else if (len == 2) {
	        *r++ = basis_64[(c2 & 0xF) << 2];
	        *r++ = '=';
            } else { /* len == 1 */
                *r++ = '=';
		*r++ = '=';
            }
	}
	if (rlen) {
	    /* append eol to the result string */
	    char *c = eol;
	    char *e = eol + eollen;
	    while (c < e)
	        *r++ = *c++;
        }
	*r = '\0';  /* every SV in perl should be NUL-terminated */

	OUTPUT:
	RETVAL

SV*
decode_base64(sv)
	SV* sv
	PROTOTYPE: $

	PREINIT:
	unsigned char *str;
	int len;
	char *r;
	int c1, c2, c3, c4;

	CODE:
	str = (unsigned char*)SvPV(sv, len);

	RETVAL = newSV(len/4*3 + 1);  /* enough, but might waste some space */
	SvPOK_on(RETVAL);
	r = SvPVX(RETVAL);

	while ((c1 = GETC(str, len)) != EOF) {
	   if (INVALID_B64(c1))
	       continue;
           do {
               c2 = GETC(str, len);
           } while (c2 != EOF && INVALID_B64(c2));
           do {
               c3 = GETC(str, len);
           } while (c3 != EOF && INVALID_B64(c3));
           do {
               c4 = GETC(str, len);
           } while (c4 != EOF && INVALID_B64(c4));

	   if (c2 == EOF || c3 == EOF || c4 == EOF)
	       croak("Premature end of base64 data");

	   if (c1 == '=' || c2 == '=')
	      break;

	   /* printf("C1=%d,C2=%d,C3=%d,C4=%d\n", c1, c2, c3, c4); */
	   c1 = index_64[c1];
	   c2 = index_64[c2];
	   *r++ = (c1<<2) | ((c2&0x30)>>4);

	   if (c3 == '=') {
               break;
           } else {
               c3 = index_64[c3];
               *r++ = ((c2&0XF) << 4) | ((c3&0x3C) >> 2);
           }
           if (c4 == '=') {
	       break;
            } else {
                c4 = index_64[c4];
                *r++ = ((c3&0x03) <<6) | c4;
            }
        }
	SvCUR_set(RETVAL, r - SvPVX(RETVAL));
	*r = '\0';

	OUTPUT:
	RETVAL
