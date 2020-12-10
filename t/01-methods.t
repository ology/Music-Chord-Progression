#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Chord::Progression';

my $obj = new_ok 'Music::Chord::Progression';

my $got = $obj->generate;
use Data::Dumper::Compact 'ddc';
warn(__PACKAGE__,' ',__LINE__," MARK: ",ddc($got));

#my $obj = new_ok 'Music::Chord::Progression' => [
#    foo => 123,
#];
#is $obj->foo, 123, 'foo';

done_testing();
