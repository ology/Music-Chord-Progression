package Music::Chord::Progression;

# ABSTRACT: Create network transition chord progressions

our $VERSION = '0.0306';

use Carp qw(croak);
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

  my $chords = $prog->generate;

  my $chord = $prog->substitution('m'); # m7 or mM7

=head1 DESCRIPTION

C<Music::Chord::Progression> creates network transition chord
progressions.

Also this module can perform limited jazz chord substitutions, if
requested in the constructor.

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

The keys must start with C<1> and be contiguous to the end.

Ending on C<12> represents all the notes of the chromatic scale, for
instance.  Ending on C<7> can represent the diatonic notes, given the
B<scale_name>.

If you do not wish a scale note to be chosen, include it among the
keys, but do not refer to it and do not give it any neighbors.

For example, the chord for the 5th degree of the scale will not be
chosen here:

  { 1 => [qw( 1 2 3 4 6 7)],
    2 => [qw( 3 )],
    3 => [qw( 2 4 6 )],
    4 => [qw( 1 2 3 )],
    5 => [],
    6 => [qw( 2 4 )],
    7 => [qw( 1 4 )] }

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

The chord names of each scale position.

The number of items in this list must be equal and correspond to the
number of keys in the B<net>.

Default: C<[ '', 'm', 'm', '', '', 'm' ]>

Here C<''> refers to the major chord and C<'m'> means minor.

Alternative example:

  [ 'M7', 'm7', 'm7', 'M7', '7', 'm7' ]

The different chord names are listed in the source of L<Music::Chord::Note>.

=cut

has chords => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a arrayref" unless ref $_[0] eq 'ARRAY' },
    default => sub { ['', 'm', 'm', '', '', 'm'] },
);

=head2 scale_name

The name of the scale.

Default: C<major>

Please see L<Music::Scales/SCALES> for the allowed scale names.

=cut

has scale_name => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid string" if ref $_[0] },
    default => sub { 'major' },
);

=head2 scale_note

The (uppercase) name of the scale starting note.

Default: C<C>

=cut

has scale_note => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);

=head2 scale

The scale notes.  This is a computed attribute.

Default: C<[C D E F G A B]>

=cut

has scale => (
    is        => 'lazy',
    init_args => undef,
);

sub _build_scale {
    my ($self) = @_;
    my @scale = get_scale_notes($self->scale_note, $self->scale_name);
    return \@scale;
}

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
random B<net> key is chosen.

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
given as C<0> a neighbor of the last chord is chosen.  If given as
C<-1> a random B<net> key is chosen.

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

Rules:

=over 4

=item Any chord can be changed to a dominant

=item Any dominant chord can be changed to a 9, 11, or 13

=item Any chord can be changed to a chord a tritone away

=back

=cut

has substitute => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head2 sub_cond

The subroutine to execute to determine if a chord substitution should
happen.

Default: C<sub { int rand 4 == 0 }> (25% of the time)

=cut

has sub_cond => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid coderef" unless ref($_[0]) eq 'CODE' },
    default => sub { return sub { int rand 4 == 0 } },
);

=head2 flat

Whether to use flats instead of sharps in the generated chords or not.

Default: C<0>

=cut

has flat => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head2 graph

The network transition L<Graph> object.  This is a computed attribute.

Default: C<Graph::Directed>

=cut

has graph => (
    is        => 'lazy',
    init_args => undef,
);

sub _build_graph {
  my ($self) = @_;
    my $g = Graph::Directed->new;
    for my $posn (keys %{ $self->net }) {
        for my $p (@{ $self->net->{$posn} }) {
            $g->add_edge($posn, $p);
        }
    }
    return $g;
}

=head2 verbose

Show the B<generate> and B<substitute> progress.

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
    net        => { 1 => [...], ... 6 => [...] },
    chords     => ['m','','m','m','',''],
    scale_name => 'minor',
    scale_note => 'A',
    octave     => 5,
    tonic      => 0,
    resolve    => -1,
    substitute => 1,
    verbose    => 1,
  );

Create a new C<Music::Chord::Progression> object.

=head2 generate

  $chords = $prog->generate;

Generate a fresh chord progression.

=cut

sub generate {
    my ($self) = @_;

    croak 'chords length must equal number of net keys'
        unless @{ $self->chords } == keys %{ $self->net };

    print 'Graph: ' . $self->graph, "\n" if $self->verbose;

    # Create a random progression
    my @progression;
    my $v; # Vertex
    for my $n (1 .. $self->max) {
        $v = $self->_next_successor($n, $v);
        push @progression, $v;
    }
    print "Progression: @progression\n" if $self->verbose;

    my @chords = @{ $self->chords };

    if ($self->substitute) {
        my $i = 0;
        for my $chord (@chords) {
            my $substitute = $self->sub_cond->() ? $self->substitution($chord) : $chord;
            if ($substitute eq $chord && $i < @progression && $self->sub_cond->()) {
                $progression[$i] .= 't'; # Indicate that we should tritone substitute
            }
            $chord = $substitute;
            $i++;
        }
    }

    my @phrase = map { $self->_tt_sub(\@chords, $_) } @progression;
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

sub _next_successor {
    my ($self, $n, $v) = @_;

    my $s;

    if ($n == 1) {
        if ($self->tonic == 0) {
            $s = $self->graph->random_successor(1);
        }
        elsif ($self->tonic == 1) {
            $s = 1;
        }
        else {
            $s = $self->_full_keys;
        }
    }
    elsif ($n == $self->max) {
        if ($self->resolve == 0) {
            $s = $self->graph->random_successor(scalar keys %{ $self->net });
        }
        elsif ($self->resolve == 1) {
            $s = 1;
        }
        else {
            $s = $self->_full_keys;
        }
    }
    else {
        $s = $self->graph->random_successor($v);
    }

    return $s;
}

sub _full_keys {
    my ($self) = @_;
    my @keys = grep { keys @{ $self->net->{$_} } > 0 } keys %{ $self->net };
    return $keys[int rand @keys];
}

sub _tt_sub {
    my ($self, $chords, $n) = @_;

    my $note;

    if ($n =~ /t/) {
        my @fnotes = get_scale_notes('C', 'chromatic', 0, 'b');
        my @snotes = get_scale_notes('C', 'chromatic');
        my %ftritone = map { $fnotes[$_] => $fnotes[($_ + 6) % @fnotes] } 0 .. $#fnotes;
        my %stritone = map { $snotes[$_] => $snotes[($_ + 6) % @snotes] } 0 .. $#snotes;

        $n =~ s/t//;
        $note = $ftritone{ $self->scale->[$n - 1] } || $stritone{ $self->scale->[$n - 1] };
        print "Tritone: $self->scale->[$n - 1] => $note\n" if $self->verbose;
    }
    else {
        $note = $self->scale->[$n - 1];
    }

    return $note . $chords->[$n - 1];
}

=head2 substitution

  $substitute = $prog->substitution($chord_name);

Perform a jazz substitution on the given the B<chord_name>.

=cut

# These gymnastics are performed to appease Music::Chord::Note
sub substitution {
    my ($self, $chord) = @_;

    my $substitute = $chord;

    if ($chord eq '' || $chord eq 'm') {
        my $roll = int rand 2;
        $substitute = $roll == 0 ? $chord . 'M7' : $chord . 7;
    }
    elsif ($chord eq 'dim' || $chord eq 'aug') {
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

    print qq|Substitute: "$chord" => "$substitute"\n| if $self->verbose && $substitute ne $chord;

    return $substitute;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> test and F<eg/*> example files

L<Carp>

L<Data::Dumper::Compact>

L<Graph>

L<Moo>

L<Music::Chord::Note>

L<Music::Scales>

=cut
