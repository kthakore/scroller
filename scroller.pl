use strict;
use warnings;
use Time::HiRes qw( time sleep );
use SDL;
use SDLx::App;
use SDL::Event;
use SDL::Events;

use lib 'lib';
use Object;

my $quit;
my $spring       = Object->new();
my $t            = 0.0;
my $dt           = 0.1;
my $current_time = 0.0;
my $accumulator  = 0.0;
my $app          = SDLx::App->new( w => 200, h => 200, title => "timestep" );
my $event        = SDL::Event->new();
while ( !$quit ) {
    SDL::Events::pump_events();
    while ( SDL::Events::poll_event($event) ) {
        $quit = 1 if $event->type == SDL_QUIT;
    }
    my $new_time   = time;
    my $delta_time = $new_time - $current_time;
    $current_time = $new_time;
    $delta_time = 0.25 if ( $delta_time > 0.25 );
    $accumulator += $delta_time;
    while ( $accumulator >= $dt ) {
        $accumulator -= $dt;
        $spring->update( $t, $dt );
        $t += $dt;
    }
    my $state = $spring->interpolate( $accumulator / $dt );
    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x0 );
    $app->draw_rect( [ 100 - int( $state->{x} ), 98, 2, 2 ], 0xFF0FFF );
    $app->update();
}

