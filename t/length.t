#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 15;

use MIME::Base64 ();
*len = *MIME::Base64::decoded_base64_length;

ok(len(""), 0);
ok(len("a"), 0);
ok(len("aa"), 1);
ok(len("aaa"), 2);
ok(len("aaaa"), 3);
ok(len("aaaaa"), 3);
ok(len("aaaaaa"), 4);
ok(len("aaaaaaa"), 5);
ok(len("aaaaaaaa"), 6);

ok(len("=aaaa"), 0);
ok(len("a=aaa"), 0);
ok(len("aa=aa"), 1);
ok(len("aaa=a"), 2);
ok(len("aaaa="), 3);

ok(len("a\na\na a"), 3);
