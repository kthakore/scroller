package Runner;

use base 'SDLx::Controller::Object';

sub new {
    my $class   = shift;
    my %options = @_;
    my $self    = SDLx::Controller::Object->new(%options);

    my $accel = sub {

        my ( $t, $state ) = @_;
        my $k  = 10;
        my $b  = 1;
        my $ax = ( ( -1 * $k ) * ( $state->x ) - $b * $state->v_x );

        return ( 10, 0, 0 );
    };

    $self->set_acceleration($accel);
    $self->acceleration(1);
    $options{app}->add_object( $self, \&render, $options{app} );
    $self = bless $self, $class;
    return $self;
}

sub render {
    my $state = shift;
    my $app   = shift;
    $app->draw_rect( [ 0,         0,         $app->w, $app->h ], 0x0 );
    $app->draw_rect( [ $state->x, $state->y, 2,       2 ],       0xFF0FFF );
    $app->update();

}

package main;
use strict;
use warnings;
use Time::HiRes qw( time sleep );
use SDL;
use SDLx::App;
use SDL::Event;
use SDL::Events;

use SDLx::Controller::Object;
my $app = SDLx::App->new( w => 200, h => 200, title => "timestep" );

my $spring = Runner->new( x => 0, y => 150, app => $app );

my $event = sub {
    return 0 if $_[0]->type == SDL_QUIT;
    return 1;
};

$app->add_event_handler($event);
$app->run_test();

