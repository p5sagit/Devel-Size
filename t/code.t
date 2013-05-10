#!/usr/bin/perl -w

use strict;
use Test::More tests => 14;
use Devel::Size ':all';

sub zwapp;
sub swoosh($$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$);
sub crunch {
}

my $whack_size = total_size(\&whack);
my $zwapp_size = total_size(\&zwapp);
my $swoosh_size = total_size(\&swoosh);
my $crunch_size = total_size(\&crunch);

cmp_ok($whack_size, '>', 0, 'CV generated at runtime has a size');
if("$]" >= 5.017) {
    cmp_ok($zwapp_size, '==', $whack_size,
	   'CV stubbed at compiletime is the same size');
} else {
    cmp_ok($zwapp_size, '>', $whack_size,
	   'CV stubbed at compiletime is larger (CvOUTSIDE is set and followed)');
}
cmp_ok(length prototype \&swoosh, '>', 0, 'prototype has a length');
cmp_ok($swoosh_size, '>', $zwapp_size + length prototype \&swoosh,
       'prototypes add to the size');
cmp_ok($crunch_size, '>', $zwapp_size, 'sub bodies add to the size');

my $anon_proto = sub ($$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$) {};
my $anon_size = total_size(sub {});
my $anon_proto_size = total_size($anon_proto);
cmp_ok($anon_size, '>', 0, 'anonymous subroutines have a size');
cmp_ok(length prototype $anon_proto, '>', 0, 'prototype has a length');
cmp_ok($anon_proto_size, '>', $anon_size + length prototype $anon_proto,
       'prototypes add to the size');

SKIP: {
    use vars '@b';
    my $aelemfast_lex = total_size(sub {my @a; $a[0]});
    my $aelemfast = total_size(sub {my @a; $b[0]});

    # This one is sane even before Dave's lexical aelemfast changes:
    cmp_ok($aelemfast_lex, '>', $anon_size,
	   'aelemfast for a lexical is handled correctly');
    skip('alemfast was extended to lexicals after this perl was released', 1)
      if $] < 5.008004;
    cmp_ok($aelemfast, '>', $aelemfast_lex,
	   'aelemfast for a package variable is larger');
}

my $short_pvop = total_size(sub {goto GLIT});
my $long_pvop = total_size(sub {goto KREEK_KREEK_CLANK_CLANK});
cmp_ok($short_pvop, '>', $anon_size, 'OPc_PVOP can be measured');
is($long_pvop, $short_pvop + 19, 'the only size difference is the label length');

sub bloop {
    my $clunk = shift;
    if (--$clunk > 0) {
	bloop($clunk);
    }
}

my $before_size = total_size(\&bloop);
bloop(42);
my $after_size = total_size(\&bloop);

cmp_ok($after_size, '>', $before_size, 'Recursion increases the PADLIST');

sub closure_with_eval {
    my $a;
    return sub { eval ""; $a };
}

sub closure_without_eval {
    my $a;
    return sub { require ""; $a };
}

if ($] > 5.017001) {
    # Again relying too much on the core's implementation, but while that holds,
    # this does test that CvOUTSIDE() is being followed.
    cmp_ok(total_size(closure_with_eval()), '>',
	   total_size(closure_without_eval()) + 256,
	   'CvOUTSIDE is now NULL on cloned closures, unless they have eval');
} else {
    # Seems that they differ by a few bytes on 5.8.x
    cmp_ok(total_size(closure_with_eval()), '<=',
	   total_size(closure_without_eval()) + 256,
	   "CvOUTSIDE is set on all cloned closures, so these won't differ by much");
}
