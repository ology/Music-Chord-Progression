#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::Chord::Progression';

# Test the defaults
my $obj = new_ok 'Music::Chord::Progression';
my $expect = ['C4','E4','G4'];
my $got = $obj->generate;
is scalar @$got, 8, 'generate';
is_deeply $got->[0], $expect, 'generate';
is_deeply $got->[-1], $expect, 'generate';

# Test setting a scale note
$obj = new_ok 'Music::Chord::Progression' => [
    scale_note => 'Bb',
];
$expect = ['A#4','D5','F5'];
$got = $obj->generate;
is_deeply $got->[0], $expect, 'generate';
is_deeply $got->[-1], $expect, 'generate';

# Test flattening the generated phrase
$obj = new_ok 'Music::Chord::Progression' => [
    scale_note => 'Bb',
    flat => 1,
#    verbose => 1,
];
$expect = ['Bb4','D5','F5'];
$got = $obj->generate;
is_deeply $got->[0], $expect, 'flat';
is_deeply $got->[-1], $expect, 'flat';

# Test substitution
$got = $obj->substitution('');
ok $got eq 7 || $got eq 'M7', 'substitution';
$got = $obj->substitution('m');
ok $got eq 'm7' || $got eq 'mM7', 'substitution';
$got = $obj->substitution('7');
ok $got eq 9 || $got eq 11 || $got eq 13, 'substitution';

# Test basic net
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

# Always substitute
$obj = new_ok 'Music::Chord::Progression' => [
    max => 3,
    substitute => 1,
    sub_cond => sub { 1 },
];
$got = $obj->generate;
ok @$_ > 3, 'sub_cond' for @$got;

# Test invalid chords
$obj = new_ok 'Music::Chord::Progression' => [
    chords => [''],
];
throws_ok { $obj->generate }
    qr/chords length must equal number of net keys/, 'invalid chords';


done_testing();
