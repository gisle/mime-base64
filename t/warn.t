#!perl -w

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use MIME::Base64 qw(decode_base64);

print "1..1\n";

use warnings;

my @warn;
$SIG{__WARN__} = sub { push(@warn, @_) };

warn;
my $a;
$a = decode_base64("aa");
$a = decode_base64("a===");
warn;
$a = do {
    no warnings;
    decode_base64("aa");
};
$a = do {
    no warnings;
    decode_base64("a===");
};
warn;
$a = do {
    local $^W;
    decode_base64("aa");
};
$a = do {
    local $^W;
    decode_base64("a===");
};
warn;

for (@warn) {
    print "# $_";
}

print "not " unless join("", @warn) eq <<'EOT'; print "ok 1\n";
Warning: something's wrong at t/warn.t line 20.
Premature end of base64 data at t/warn.t line 22.
Premature padding of base64 data at t/warn.t line 23.
Warning: something's wrong at t/warn.t line 24.
Premature end of base64 data at t/warn.t line 27.
Premature padding of base64 data at t/warn.t line 31.
Warning: something's wrong at t/warn.t line 33.
Warning: something's wrong at t/warn.t line 42.
EOT
