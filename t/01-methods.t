#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Chord::Progression';

my $obj = new_ok 'Music::Chord::Progression';

my $got = $obj->generate;
is scalar @$got, 8, 'generate';
is_deeply $got->[0], ['C4','E4','G4'], 'generate';

$obj = new_ok 'Music::Chord::Progression' => [
    scale_note => 'B',
];
$got = $obj->generate;
is_deeply $got->[0], ['B4','D#5','F#5'], 'generate';

done_testing();
