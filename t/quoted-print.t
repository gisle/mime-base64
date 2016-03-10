BEGIN {
        if ($ENV{PERL_CORE}) {
                chdir 't' if -d 't';
                @INC = '../lib';
        }
}

# Use our own is() function to not have any dependencies on other modules;
# this one is simplified from the one in core perl t/test.pl
my $testno = 0;
sub is ($$@) {
    my ($got, $expected, @mess) = @_;

    $testno++;

    my $pass;
    if( !defined $got || !defined $expected ) {
        # undef only matches undef
        $pass = !defined $got && !defined $expected;
    }
    else {
        $pass = $got eq $expected;
    }

    print "not " unless $pass;
    print "ok $testno";
    print " - ", @mess if @mess;
    print "\n";
    if (! $pass) {
        my @caller = caller(0);
	print STDERR "# Failed test $testno";
        print STDERR " - ", @mess if @mess;
        print STDERR " at $caller[1] line $caller[2]\n";
	print STDERR "#      got $got\n# expected $expected\n";
    }

    return $pass;
}

use MIME::QuotedPrint;

$x70 = "x" x 70;

# This abandons testing of EBCDICS prior to v5.8.0, which is when this
# translation function was defined
*to_native = (defined &utf8::unicode_to_native)
             ? \&utf8::unicode_to_native
             : sub { return shift };

my $ae                = chr to_native(0xe6);
my $a_ring            = chr to_native(0xe5);
my $o_stroke          = chr to_native(0xf8);

my $encoded_ae        = sprintf "=%02X", ord $ae;
my $encoded_a_ring    = sprintf "=%02X", ord $a_ring;
my $encoded_cr        = sprintf "=%02X", ord "\r";
my $encoded_equal     = sprintf "=%02X", ord "=";
my $encoded_lf        = sprintf "=%02X", ord "\n";
my $encoded_o_stroke  = sprintf "=%02X", ord $o_stroke;
my $encoded_space     = sprintf "=%02X", ord " ";
my $encoded_tab       = sprintf "=%02X", ord "\t";

@tests =
  (
   # plain ascii should not be encoded
   ["", ""],
   ["quoted print\table"  =>
    "quoted print\table=\n"],

   # 8-bit chars should be encoded
   ["v${a_ring}re kj${ae}re norske tegn b${o_stroke}r ${ae}res" =>
    "v${encoded_a_ring}re kj${encoded_ae}re norske tegn b${encoded_o_stroke}r ${encoded_ae}res=\n"],

   # trailing space should be encoded
   ["  " => "${encoded_space}${encoded_space}=\n"],
   ["\tt\t" => "\tt${encoded_tab}=\n"],
   ["test  \ntest\n\t \t \n" => "test${encoded_space}${encoded_space}\ntest\n${encoded_tab}${encoded_space}${encoded_tab}${encoded_space}\n"],

   # "=" is special an should be decoded
   ["=30\n" => "${encoded_equal}30\n"],
   ["\0\xff0" => "=00=FF0=\n"],

   # Very long lines should be broken (not more than 76 chars)
   ["The Quoted-Printable encoding is intended to represent data that largly consists of octets that correspond to printable characters in the ASCII character set." =>
    "The Quoted-Printable encoding is intended to represent data that largly con=
sists of octets that correspond to printable characters in the ASCII charac=
ter set.=\n"
    ],

   # Long lines after short lines were broken through 2.01.
   ["short line
In America, any boy may become president and I suppose that's just one of the risks he takes. -- Adlai Stevenson" =>
    "short line
In America, any boy may become president and I suppose that's just one of t=
he risks he takes. -- Adlai Stevenson=\n"],

   # My (roderick@argon.org) first crack at fixing that bug failed for
   # multiple long lines.
   ["College football is a game which would be much more interesting if the faculty played instead of the students, and even more interesting if the
trustees played.  There would be a great increase in broken arms, legs, and necks, and simultaneously an appreciable diminution in the loss to humanity. -- H. L. Mencken" =>
    "College football is a game which would be much more interesting if the facu=
lty played instead of the students, and even more interesting if the
trustees played.  There would be a great increase in broken arms, legs, and=
 necks, and simultaneously an appreciable diminution in the loss to humanit=
y. -- H. L. Mencken=\n"],

   # Don't break a line that's near but not over 76 chars.
   ["$x70!23"		=> "$x70!23=\n"],
   ["$x70!234"		=> "$x70!234=\n"],
   ["$x70!2345"		=> "$x70!2345=\n"],
   ["$x70!23456"	=> "$x70!2345=\n6=\n"],
   ["$x70!234567"	=> "$x70!2345=\n67=\n"],
   ["$x70!23456="	=> "$x70!2345=\n6${encoded_equal}=\n"],
   ["$x70!23\n"		=> "$x70!23\n"],
   ["$x70!234\n"	=> "$x70!234\n"],
   ["$x70!2345\n"	=> "$x70!2345\n"],
   ["$x70!23456\n"	=> "$x70!23456\n"],
   ["$x70!234567\n"	=> "$x70!2345=\n67\n"],
   ["$x70!23456=\n"	=> "$x70!2345=\n6${encoded_equal}\n"],

   # Not allowed to break =XX escapes using soft line break
   ["$x70===xxxxx"  => "$x70${encoded_equal}=\n${encoded_equal}${encoded_equal}xxxxx=\n"],
   ["$x70!===xxxx"  => "$x70!${encoded_equal}=\n${encoded_equal}${encoded_equal}xxxx=\n"],
   ["$x70!2===xxx"  => "$x70!2${encoded_equal}=\n${encoded_equal}${encoded_equal}xxx=\n"],
   ["$x70!23===xx"  => "$x70!23=\n${encoded_equal}${encoded_equal}${encoded_equal}xx=\n"],
   ["$x70!234===x"  => "$x70!234=\n${encoded_equal}${encoded_equal}${encoded_equal}x=\n"],
   ["$x70!2="       => "$x70!2${encoded_equal}=\n"],
   ["$x70!23="      => "$x70!23=\n${encoded_equal}=\n"],
   ["$x70!234="     => "$x70!234=\n${encoded_equal}=\n"],
   ["$x70!2345="    => "$x70!2345=\n${encoded_equal}=\n"],
   ["$x70!23456="   => "$x70!2345=\n6${encoded_equal}=\n"],
   ["$x70!2=\n"     => "$x70!2${encoded_equal}\n"],
   ["$x70!23=\n"    => "$x70!23${encoded_equal}\n"],
   ["$x70!234=\n"   => "$x70!234=\n${encoded_equal}\n"],
   ["$x70!2345=\n"  => "$x70!2345=\n${encoded_equal}\n"],
   ["$x70!23456=\n" => "$x70!2345=\n6${encoded_equal}\n"],
   #                              ^
   #                      70123456|
   #                             max
   #                          line width

   # some extra special cases we have had problems with
   ["$x70!2=x=x" => "$x70!2${encoded_equal}=\nx${encoded_equal}x=\n"],
   ["$x70!2345$x70!2345$x70!23456\n", "$x70!2345=\n$x70!2345=\n$x70!23456\n"],

   # trailing whitespace
   ["foo \t ", "foo${encoded_space}${encoded_tab}${encoded_space}=\n"],
   ["foo\t \n \t", "foo${encoded_tab}${encoded_space}\n${encoded_space}${encoded_tab}=\n"],
);

$notests = @tests * 2 + 16;
print "1..$notests\n";

for (@tests) {
    my ($plain, $encoded) = @$_;
    my $x = encode_qp($plain);
    is($x, $encoded, "Encode test");
    $x = decode_qp($encoded);
    is($x, $plain, "Decode test");
}

# Some extra testing for a case that was wrong until libwww-perl-5.09
is (decode_qp("foo  \n\nfoo =\n\nfoo${encoded_space}\n\n"),
    "foo\n\nfoo \nfoo \n\n");

# Same test but with "\r\n" terminated lines
is(decode_qp("foo  \r\n\r\nfoo =\r\n\r\nfoo${encoded_space}\r\n\r\n"),
             "foo\n\nfoo \nfoo \n\n");

# Trailing whitespace
is(decode_qp("foo  "), "foo  ");
is(decode_qp("foo  \n"), "foo\n");
is(decode_qp("foo = \t \nbar\t \n"), "foo bar\n");
is(decode_qp("foo = \t \r\nbar\t \r\n"), "foo bar\n");
is(decode_qp("foo = \t \n"), "foo ");
is(decode_qp("foo = \t \r\n"), "foo ");
is(decode_qp("foo = \t y\r\n"), "foo = \t y\n");
is(decode_qp("foo =xy\n"), "foo =xy\n");

# Test with with alternative line break
is(encode_qp("$x70!2345$x70\n", "***"), "$x70!2345=***$x70***");

# Test with no line breaks
is(encode_qp("$x70!2345$x70\n", ""), "$x70!2345$x70$encoded_lf");

# Test binary encoding
is(encode_qp("foo", undef, 1), "foo=\n");

is(encode_qp("foo\nbar\r\n", undef, 1), "foo${encoded_lf}bar${encoded_cr}${encoded_lf}=\n");


# Generate a string of all possible bytes in order, using the characters
# themselves of ASCII printable ones, and otherwise =XX of the code point in
# hex.
my $col = 0;
for my $cp (0..255) {
    my $char = chr $cp;
    if ($char =~ /[\][\tA-Za-z0-9 !"#\$\%&'()*+,.\/:;<>?\@\\^_`{|}~-]/) {

        # Space and tab must be output encoded if they are at the end of the
        # line
        goto do_encode if    $char =~ /[ \t]/
                          && ($cp == 255 || chr($cp+1) =~ /[\n\r]/);
        $col++;
        if ($col >= 76) {
            $string .= "=\n";
            $col = 1;
        }
        $string .= $char;
    }
    else {
      do_encode:
        $col += 3;
        if ($col >= 76) {
            $string .= "=\n";
            $col = 3;
        }
        $string .= sprintf "=%02X", $cp;
    }
}
$string .= "=\n";

is(encode_qp(join("", map chr, 0..255), undef, 1), $string);

if ($] lt 5.006) {
    $testno++;
    print "ok $testno # Skipped for perls before v5.6\n";
}
else {
    my $result = (eval 'encode_qp("XXX \x{100}")' || !$@)
                 ? 0
                 : 1;
    is($result, 1);
}

