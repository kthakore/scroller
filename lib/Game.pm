package Game;
use strict;
use warnings;

use base 'SDLx::App';

use SDL;
use SDL::Event;
use SDL::Events;
use Scalar::Util 'refaddr';
use lib 'lib';
use Object;

my %update;
my %hero;

sub new {
    my $class = shift;
    my $obj =
      SDLx::App->new( w => 200, h => 200, dt => 10, title => 'Scroller' );
    my $self = bless $obj, $class;
    $obj->add_event_handler( sub { $self->_dispatcher( $_[0] ) } );
    $obj->add_show_handler( sub  { $self->_render } );
    $self->on_init();
    return $self;

}

sub on_init {
    $hero{ refaddr $_[0] } = Object->new( width => 10, height => 10 );
    $hero{ refaddr $_[0] }->x(10);
    $hero{ refaddr $_[0] }->y( $_[0]->w - 50 );

}

sub _dispatcher {
    my ( $self, $event ) = @_;

    return if $event->type == SDL_QUIT;

    return $self->hero->event($event);

    return 1;
}

sub _render {
    $_[0]->hero->draw_xy( $_[0] );
    $_[0]->update();

}

sub hero {

    return $hero{ refaddr $_[0] };

}

1;
