package Music::Chord::Progression;

# ABSTRACT: Create network transition chord progressions

our $VERSION = '0.0005';

use Data::Dumper::Compact qw(ddc);
use Graph::Directed;
use Music::Scales qw(get_scale_notes);
use Music::Chord::Note;

use Moo;
use strictures 2;
use namespace::clean;

=head1 SYNOPSIS

  use Music::Chord::Progression;

  my $prog = Music::Chord::Progression->new;

  my $notes = $prog->generate;

  my $chord = $prog->substitution('m'); # m7

=head1 DESCRIPTION

C<Music::Chord::Progression> creates network transition chord
progressions.

=head1 ATTRIBUTES

=head2 max

The maximum number of chords to generate.

Default: C<8>

=cut

has max => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 8 },
);

=head2 net

The network transitions between chords of the progression.

Default:

  { 1 => [qw( 1 2 3 4 5 6 )],
    2 => [qw( 3 4 5 )],
    3 => [qw( 1 2 4 6 )],
    4 => [qw( 1 3 5 6 )],
    5 => [qw( 1 4 6 )],
    6 => [qw( 1 2 4 5 )] }

Alternative example:

  { 1 => [qw( 1 2 3 4 5 6 )],
    2 => [qw( 3 5 )],
    3 => [qw( 2 4 6 )],
    4 => [qw( 1 2 3 5 )],
    5 => [qw( 1 )],
    6 => [qw( 2 4 )] }

The keys must start with C<1> and end on a number less than or equal
to C<7>.  If you do not wish a scale note, that is located in the
middle of the range, to be chosen, include it among the keys, but do
not refer to it and do not give it any neighbors.

For example, the chord for the 5th degree of the scale will not be
chosen here, because no key refers to it and it has no neighbors:

  { 1 => [qw( 1 2 3 4 6 7)],
    2 => [qw( 3 )],
    3 => [qw( 2 4 6 )],
    4 => [qw( 1 2 3 )],
    5 => [],
    6 => [qw( 2 4 )] }

=cut

has net => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a hashref" unless ref $_[0] eq 'HASH' },
    default => sub {
      { 1 => [qw( 1 2 3 4 5 6 )],
        2 => [qw( 3 4 5 )],
        3 => [qw( 1 2 4 6 )],
        4 => [qw( 1 3 5 6 )],
        5 => [qw( 1 4 6 )],
        6 => [qw( 1 2 4 5 )] }
    },
);

=head2 chords

The chord name parts of each scale position.

The number of items in this list must be equal and correspond to the
number of keys in the B<net>.

Default: C<[ '', 'm', 'm', '', '', 'm' ]>

Alternative example:

  [ 'M7', 'm7', 'm7', 'M7', '7', 'm7' ]

=cut

has chords => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a arrayref" unless ref $_[0] eq 'ARRAY' },
    default => sub { ['', 'm', 'm', '', '', 'm'] },
);

=head2 scale_name

The name of the scale.

Default: C<major>

=cut

has scale_name => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid string" if ref $_[0] },
    default => sub { 'major' },
);

=head2 scale_note

The name of the scale starting note.

Default: C<C>

=cut

has scale_note => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid string" if ref $_[0] },
    default => sub { 'C' },
);

=head2 octave

The octave number of the scale.

Default: C<4>

=cut

has octave => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid octave" unless $_[0] =~ /^-?\d+$/ },
    default => sub { 4 },
);

=head2 tonic

Whether to start the progression with the tonic chord or not.

If this is given as C<1> the tonic chord starts the progression.  If
given as C<0> a neighbor of the tonic is chosen.  If given as C<-1> a
random vertex is chosen.

Default: C<1>

=cut

has tonic => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid setting" unless $_[0] =~ /^-?[01]$/ },
    default => sub { 1 },
);

=head2 resolve

Whether to end the progression with the tonic chord or not.

If this is given as C<1> the tonic chord ends the progression.  If
given as C<0> a neighbor of the tonic is chosen.  If given as C<-1> a
random vertex is chosen.

Default: C<1>

=cut

has resolve => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid setting" unless $_[0] =~ /^-?[01]$/ },
    default => sub { 1 },
);

=head2 substitute

Whether to perform jazz chord substitution.

Default: C<0>

=cut

has substitute => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head2 flat

Whether to use flats instead of sharps in the chords or not.

Default: C<0>

=cut

has flat => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head2 graph

The network transition graph.

Default: C<Graph::Directed>

=cut

has graph => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid graph" unless ref($_[0]) =~ /^Graph/ },
    default => sub { Graph::Directed->new },
);

=head2 verbose

Show the progress of the B<generate> method.

=cut

has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head1 METHODS

=head2 new

  $prog = Music::Chord::Progression->new; # Use the defaults

  $prog = Music::Chord::Progression->new( # Override the defaults
    max        => 4,
    net        => { 1 => [...], ... },
    chords     => ['m','','m','m','',''],
    scale_name => 'minor',
    scale_note => 'A',
    octave     => 5,
    tonic      => 0,
    resolve    => 0,
    substitute => 1,
    verbose    => 1,
  );

Create a new C<Music::Chord::Progression> object.

=head2 generate

  $notes = $prog->generate;

Generate a new chord progression.

=cut

sub generate {
    my ($self) = @_;

    # Build the graph
    for my $posn (keys %{ $self->net }) {
        for my $p (@{ $self->net->{$posn} }) {
            $self->graph->add_edge($posn, $p);
        }
    }
    print 'Graph: ' . $self->graph, "\n" if $self->verbose;

    # Create a random progression
    my @progression;
    my $v;
    for my $n (1 .. $self->max) {
        if ($n == 1) {
            if ($self->tonic == 0) {
                $v = (@{ $self->net->{1} })[int rand @{ $self->net->{1} }];
            }
            elsif ($self->tonic == 1) {
                $v = 1;
            }
            else {
                my @keys = grep { keys @{ $self->net->{$_} } > 0 } keys %{ $self->net };
                $v = $keys[int rand @keys];
            }
        }
        elsif ($n == $self->max) {
            if ($self->resolve == 0) {
                my @keys = keys %{ $self->net };
                $v = (@{ $self->net->{ scalar @keys } })[int rand @{ $self->net->{ scalar @keys } }];
            }
            elsif ($self->resolve == 1) {
                $v = 1;
            }
            else {
                my @keys = grep { keys @{ $self->net->{$_} } > 0 } keys %{ $self->net };
                $v = $keys[int rand @keys];
            }
        }
        else {
            $v = $self->graph->random_successor($v);
        }
        push @progression, $v;
    }
    print "Progression: @progression\n" if $self->verbose;

    my @scale = get_scale_notes($self->scale_note, $self->scale_name);

    my $chords = $self->chords;

    if ($self->substitute) {
        for my $chord (@$chords) {
            $chord = int rand 2 ? $self->substitution($chord) : $chord;
        }
    }

    my @phrase = map { $scale[$_ - 1] . $chords->[$_ - 1] } @progression;
    print "Phrase: @phrase\n" if $self->verbose;

    # Add octaves to the chord notes
    my $mcn = Music::Chord::Note->new;
    my @notes;
    for my $chord (@phrase) {
        my @chord = $mcn->chord_with_octave($chord, $self->octave);
        push @notes, \@chord;
    }
    if ($self->flat) {
        my %equiv = (
            'C#' => 'Db',
            'D#' => 'Eb',
            'E#' => 'F',
            'F#' => 'Gb',
            'G#' => 'Ab',
            'A#' => 'Bb',
            'B#' => 'C',
        );
        for my $chord (@notes) {
            for my $note (@$chord) {
                $note =~ s/^([A-G]#)(\d+)$/$equiv{$1}$2/ if $note =~ /#/;
            }
        }
    }
    print 'Notes: ', ddc(\@notes) if $self->verbose;

    return \@notes;
}

=head2 substitution

  $substitute = $prog->substitution($chord_name);

Perform a jazz substitution on the given the B<chord_name>.

Rules:

  * Any chord can be changed to a dominant

  * Any dominant chord can be changed to a 9, 11, or 13

  * Any chord can be changed to a chord a tritone away (not implemented)

=cut

# These gymnastics are performed to appease Music::Chord::Note
sub substitution {
    my ($self, $chord) = @_;

    my $substitute = $chord;

    if (
        $chord eq ''
        || $chord eq 'm'
        || $chord eq 'dim'
        || $chord eq 'aug'
    ) {
        $substitute = $chord . 7;
    }
    elsif ($chord eq '-5' || $chord eq '-9') {
        $substitute = "7($chord)";
    }
    elsif ($chord eq 'M7') {
        my $roll = int rand 3;
        $substitute = $roll == 0 ? 'M9' : $roll == 1 ? 'M11' : 'M13';
    }
    elsif ($chord eq '7') {
        my $roll = int rand 3;
        $substitute = $roll == 0 ? '9' : $roll == 1 ? '11' : '13';
    }
    elsif ($chord eq 'm7') {
        my $roll = int rand 3;
        $substitute = $roll == 0 ? 'm9' : $roll == 1 ? 'm11' : 'm13';
    }

    return $substitute;
}

1;
__END__

=head1 SEE ALSO

L<Data::Dumper::Compact>

L<Graph::Directed>

L<Moo>

L<Music::Chord::Note>

L<Music::Scales>

=cut
