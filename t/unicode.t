BEGIN {
	unless ($] >= 5.006) {
		print "1..0\n";
		exit(0);
	}
        if ($ENV{PERL_CORE}) {
                chdir 't' if -d 't';
                @INC = '../lib';
        }
}

print "1..2\n";

require MIME::Base64;

eval {
    MIME::Base64::encode(v300);
};

print "not " unless $@;
print "ok 1\n";

require MIME::QuotedPrint;

eval {
    MIME::QuotedPrint::encode(v300);
};

print "not " unless $@;
print "ok 2\n";

