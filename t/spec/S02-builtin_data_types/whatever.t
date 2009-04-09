use v6;
use Test;

plan 6;

{
    my $x = *;
    ok($x.isa(Whatever), 'can assign * to a variable and isa works');
}

my $x = *-1;
lives_ok { $x.WHAT }, '(*-1).WHAT lives';
#?rakudo todo '*-1 should create a closure'
isa_ok $x, Code, '*-1 is of type Code';
#?rakudo skip '*-1 should create a closure'
ok $x.(5), 4, 'and we can execute that Code';

isa_ok *.abs, Code, '*.abs is of type Code';
my @a = map *.abs, 1, -2, 3, -4;
is @a, [1,2,3,4], '*.meth created closure works';


# vim: ft=perl6
