package Object;
use strict;
use warnings;    ###Move to XS after

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    $self->{current} = { x => 100, y => 100, v => 0 };
    $self->{previous} = $self->{current};
}

sub interpolate {
    my ( $self, $alpha ) = @_;
    my ( $current, $previous ) = ( $self->{current}, $self->{previous} );
    my $state = {
        x => $current->{x} * $alpha + $previous->{x} * ( 1 - $alpha ),
        v => $current->{v} * $alpha + $previous->{v} * ( 1 - $alpha ),
    };
    return $state;
}

sub acceleration {
    return -9.8;
    my ( $self, $state ) = @_;
    my $k = 10;
    my $b = 1;
    return ( ( -1 * $k ) * $state->{x} - $b * $state->{v} );
}

sub evaluate {
    my ( $self, $initial, $t, $dt, $d ) = @_;
    my $state;
    my $output;
    if ($dt) {
        $state->{x} = $initial->{x} + $d->{dx} * $dt;
        $state->{v} = $initial->{v} + $d->{dv} * $dt;
        $output =
          { dx => $state->{v}, dv => $self->acceleration( $state, $t + $dt ), };
    }
    else {
        $output =
          { dx => $initial->{v}, dv => $self->acceleration( $initial, $t ), };
    }
    return $output;
}

sub integrate {
    my ( $self, $t, $dt ) = @_;
    my $state = $self->{current};
    my $a     = $self->evaluate( $state, $t );
    my $b     = $self->evaluate( $state, $t, $dt * 0.5, $a );
    my $c     = $self->evaluate( $state, $t, $dt * 0.5, $b );
    my $d     = $self->evaluate( $state, $t, $dt, $c );
    my $dxdt =
      1.0 / 6.0 * ( $a->{dx} + 2.0 * ( $b->{dx} + $c->{dx} ) + $d->{dx} );
    my $dvdt =
      1.0 / 6.0 * ( $a->{dv} + 2.0 * ( $b->{dv} + $c->{dv} ) + $d->{dv} );
    $state->{x} += $dxdt * $dt;
    $state->{v} += $dvdt * $dt;
}

sub update {
    my ( $self, $t, $dt ) = @_;
    $self->{previous} = $self->{current};
    $self->integrate( $t, $dt );
}

1;
