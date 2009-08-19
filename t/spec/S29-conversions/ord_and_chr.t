use v6;

use Test;

=begin pod

Basic tests for the ord() and chr() built-in.

=end pod

# L<S29/Conversions/ord>
# L<S29/Conversions/chr>

# What is the best way to test 0 through 31??
my @maps = (
  " ",    32,
  "!",    33,
  '"',    34,
  "#",    35,
  '$',    36,
  "%",    37,
  "&",    38,
  "'",    39,
  "(",    40,
  ")",    41,
  "*",    42,
  "+",    43,
  ",",    44,
  "-",    45,
  ".",    46,
  "/",    47,
  "0",    48,
  "1",    49,
  "2",    50,
  "3",    51,
  "4",    52,
  "5",    53,
  "6",    54,
  "7",    55,
  "8",    56,
  "9",    57,
  ":",    58,
  ";",    59,
  "<",    60,
  "=",    61,
  ">",    62,
  "?",    63,
  "@",    64,
  "A",    65,
  "B",    66,
  "C",    67,
  "D",    68,
  "E",    69,
  "F",    70,
  "G",    71,
  "H",    72,
  "I",    73,
  "J",    74,
  "K",    75,
  "L",    76,
  "M",    77,
  "N",    78,
  "O",    79,
  "P",    80,
  "Q",    81,
  "R",    82,
  "S",    83,
  "T",    84,
  "U",    85,
  "V",    86,
  "W",    87,
  "X",    88,
  "Y",    89,
  "Z",    90,
  "[",    91,
  "\\",   92,
  "]",    93,
  "^",    94,
  "_",    95,
  "`",    96,
  "a",    97,
  "b",    98,
  "c",    99,
  "d",    100,
  "e",    101,
  "f",    102,
  "g",    103,
  "h",    104,
  "i",    105,
  "j",    106,
  "k",    107,
  "l",    108,
  "m",    109,
  "n",    110,
  "o",    111,
  "p",    112,
  "q",    113,
  "r",    114,
  "s",    115,
  "t",    116,
  "u",    117,
  "v",    118,
  "w",    119,
  "x",    120,
  "y",    121,
  "z",    122,
  '{',    123,
  "|",    124,
  '}',    125,
  "~",    126,

  # Unicode tests
  "ä",    228,
  "€",    8364,
  "»",    187,
  "«",    171,

  # Special chars
  "\o00", 0,
  "\o01", 1,
  "\o03", 3,
);

plan 38+@maps*2;

for @maps -> $char, $code {
  my $descr = "\\{$code}{$code >= 32 ?? " == '{$char}'" !! ""}";
  is ord($char), $code, "ord() works for $descr";
  is chr($code), $char, "chr() works for $descr";
}

for @maps -> $char, $code {
   my $descr = "\\{$code}{$code >= 32 ?? " == '{$char}'" !! ""}";
#?rakudo skip 'named args'
   is ord(:string($char)), $code, "ord() works for $descr with named args";
#?rakudo skip 'named args'
   is chr(:graph($code)), $char, "chr() works for $descr with named args";
}

for 0..31 -> $code {
  my $char = chr($code);
  is ord($char), $code, "ord(chr($code)) is $code";
}

is 'A'.ord, 65, "there's a .ord method";
is 65.chr, 'A', "there's a .chr method";

#?rakudo 2 skip 'multi-arg variants of ord and chr not in place yet'
is ord('hello'), [104, 101, 108, 108, 111], 'ord works with longer strings';
is chr(104, 101, 108, 108, 111), 'hello', 'chr works with a list of ints';

ok ord("") ~~ Failure, 'ord("") returns a Failure';

# RT #65172
{
    my $rt65172a = "\c[LATIN CAPITAL LETTER A, COMBINING DOT ABOVE]";
    my $rt65172b = "\c[LATIN CAPITAL LETTER A WITH DOT ABOVE]";
    #?rakudo todo 'RT #65172'
    is $rt65172a.ord, $rt65172b.ord, '.ord defaults to grapheme mode';
}

#vim: ft=perl6
