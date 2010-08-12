package Object;
use strict;
use warnings;
use SDL::Event;
use SDL::Events;
use base 'SDLx::Sprite';

sub new {
    my $class = shift;
    my $obj   = SDLx::Sprite->new( width => 10, height => 10 );
    my $self  = bless $obj, $class;
    $self->_render();

    $self->{state} = 'stand';
    return $self;

}

sub _render {
    my $self = shift;
    $self->surface->draw_rect( [ 0, 0, 10, 10 ], 0xFF00FFF );
    return $self;

}

sub event {
    my ( $self, $event ) = @_;

    $self->x( $self->x + 2 ) if $event->key_sym == SDLK_LEFT;

    return 1;
}

sub evaluate { }

sub accelerate { }
1;
