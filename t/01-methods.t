#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Chord::Progression';

my $obj = new_ok 'Music::Chord::Progression';

my $expect = ['C4','E4','G4'];
my $got = $obj->generate;
is scalar @$got, 8, 'generate';
is_deeply $got->[0], $expect, 'generate';
is_deeply $got->[-1], $expect, 'generate';

$obj = new_ok 'Music::Chord::Progression' => [
    scale_note => 'B',
];
$expect = ['B4','D#5','F#5'];
$got = $obj->generate;
is_deeply $got->[0], $expect, 'generate';
is_deeply $got->[-1], $expect, 'generate';

$obj = new_ok 'Music::Chord::Progression' => [
    scale_note => 'Bb',
    flat => 1,
#    verbose => 1,
];
$expect = ['Bb4','D5','F5'];
$got = $obj->generate;
is_deeply $got->[0], $expect, 'flat';
is_deeply $got->[-1], $expect, 'flat';

$got = $obj->substitution('');
ok $got eq 7 || $got eq 'M7', 'substitution';
$got = $obj->substitution('m');
ok $got eq 'm7' || $got eq 'mM7', 'substitution';

$obj = new_ok 'Music::Chord::Progression' => [
    max => 6,
    net => { 1 => [2], 2 => [3], 3 => [4], 4 => [5], 5 => [6], 6 => [1] },
    resolve => 0,
];
$expect = [
    ['C4','E4','G4'], ['D4','F4','A4'], ['E4','G4','B4'],
    ['F4','A4','C5'], ['G4','B4','D5'], ['C4','E4','G4'],
];
$got = $obj->generate;
is_deeply $got, $expect, 'generate';

done_testing();
