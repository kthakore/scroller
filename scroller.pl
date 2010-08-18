use strict;
use warnings;
use SDL;
use SDL::Rect;
use SDL::Events;
use Math::Trig;
use SDLx::App;
use SDLx::Controller::Object;

my $app = SDLx::App->new( w => 400, h => 400, dt => 0.02 );

$app->update();

my @update_rects = ();

my $obj =
  SDLx::Controller::Object->new( x => 10, y => 380, v_x => 0, v_y => 0 );

my $move       = '';
my $moving    = -1;
my $jumping    = -1;
my $jump_count = 20;
my $print      = '';

$obj->set_acceleration(
    sub {
        my $time  = shift;
        my $state = shift;
        my $ay    = 180;

        if ( $state->y > 390 && $move !~ 'up' ) {
            $state->v_y(0);
            $ay = 0;
            $state->y(390);
            if ( $jumping == 0 ) { $jumping = -1; }

        }

        if ( $move =~ 'up' && $jumping < 0 ) {
            $state->y(389); #Get his jump started.
            $state->v_y(-82);
            $jumping++;
        }

        if ( $jumping == -1 ) {
            
             #We can only stop moving when we are not jumping. But let us know that we should't continue 
            if ( $moving == -1 && $move =~ 'none' )  {  $state->v_x(0);  }
            
            if ( $move =~ 'left' )  { $state->v_x(-80); $moving = 1 }
            if ( $move =~ 'right' ) { $state->v_x(80); $moving = 1 }
        }      
           
            if ( $move =~ 'stopl' ) {  $moving = -1 } 
            if ( $move =~ 'stopr' ) {  $moving = -1 }
        

       # $print = " $move | $moving ";

        $move = 'none';
        return ( 0, $ay, 0 );
    }
);

my $render_obj = sub {

    my $state = shift;

    #SDL::GFX::Primitives::string_color( $app, 0, 0, "$jumping|$print",
    #    0xFFFFFFF );

    my $s_rect = SDL::Rect->new( 0, 0, $app->w, $app->h );
    my $p_rect =
      SDL::Rect->new( $obj->previous->x - 5, $obj->previous->y - 5, 20, 20 );
    my $c_rect = SDL::Rect->new( $state->x, $state->y, 10, 10 );

    push @update_rects, $s_rect;
    $app->draw_rect( $p_rect, 0x0 );
    $app->draw_rect( $c_rect, 0xFF00CCFF );

};

$app->add_event_handler(
    sub {
        return 0 if $_[0]->type == SDL_QUIT;

        if ( $_[0]->type == SDL_KEYDOWN ) {
            my $key = $_[0]->key_sym;
            $move .= SDL::Events::get_key_name($key);
            return 1;
        }
        elsif ( $_[0]->type == SDL_KEYUP ) {
            if ( $_[0]->key_sym == SDLK_LEFT ) {
                $move = 'stopl'; return 1;
            }
            elsif ( $_[0]->key_sym == SDLK_RIGHT ) {
                $move = 'stopr'; return 1;
            }
        }
        return 1;
    }
);

$app->add_show_handler(
    sub { $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x0 ); } );

$app->add_object( $obj, $render_obj );

$app->add_show_handler(
    sub { $app->update( \@update_rects ); @update_rects = (); } );

$app->run_test;

