package Music::Chord::Progression;

# ABSTRACT: Create network transition chord progressions

our $VERSION = '0.0001';

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
    2 => [qw( 3 5 )],
    3 => [qw( 2 4 6 )],
    4 => [qw( 1 2 3 5 )],
    5 => [qw( 1 )],
    6 => [qw( 2 4 )] }

=cut

has net => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a hashref" unless ref $_[0] eq 'HASH' },
    default => sub {
        {
            1 => [qw(1 2 3 4 5 6)],
            2 => [qw(3 5)],
            3 => [qw(2 4 6)],
            4 => [qw(1 2 3 5)],
            5 => [qw(1)],
            6 => [qw(2 4)],
        };
    },
);

=head2 valence

The chord name parts of each scale position.

The number of items in this list must be equal and correspond to the
number of keys in the B<net>.

Default: C<[ '', 'm', 'm', '', '', 'm' ]>

=cut

has valence => (
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

Default: C<1>

=cut

has tonic => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 1 },
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

  $prog = Music::Chord::Progression->new;
  $prog = Music::Chord::Progression->new(
    net        => { 1 => [...], ... },
    valence    => ['m','','m','m','',''],
    scale_name => 'minor',
    scale_note => 'A',
    octave     => 5,
  );

Create a new C<Music::Chord::Progression> object.

=head2 generate

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
    print 'Graph: ' . $self->graph if $self->verbose;

    # Create a random progression
    my @progression;
    my $v;
    for my $n (1 .. $self->max) {
        if ($n == 1) {
            $v = $self->tonic ? 1 : (keys %{ $self->net })[int rand keys %{ $self->net }];
            push @progression, $v;
            next;
        }
        $v = $self->graph->random_successor($v);
        push @progression, $v;
    }
    print "Progression: @progression\n" if $self->verbose;

    my @scale = get_scale_notes($self->scale_note, $self->scale_name);

    my @phrase = map { $scale[$_ - 1] . $self->valence->[$_ - 1] } @progression;
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

1;
__END__

=head1 SEE ALSO

L<Data::Dumper::Compact>

L<Graph::Directed>

L<Moo>

L<Music::Chord::Note>

L<Music::Scales>

=cut
