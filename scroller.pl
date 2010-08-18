use strict;
use warnings;
use SDL;
use SDL::Rect;
use SDL::Events;
use Math::Trig;
use Collision::2D ':all';
use Data::Dumper;
use SDLx::App;
use SDLx::Controller::Object;

my $app = SDLx::App->new( w => 400, h => 400, dt => 0.02 );

$app->update();

my @update_rects = ();

my $obj =
  SDLx::Controller::Object->new( x => 10, y => 380, v_x => 0, v_y => 0 );

my @collide_blocks = ([19,350], [40,350], [30,329], [ 120, 400 ] );

foreach( 0..2 )
{
	push @collide_blocks, [rand($app->w), rand($app->h-375) + 375];
}

foreach(  @collide_blocks )
{
	$_->[1] -= 20;
	$_->[2]=20; $_->[3]=20;
}

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

				my $c = check_collision( $state, \@collide_blocks );
		if($c != -1 )
		{
			 
			#$state->x( $state->x + $c->[0] );
			if( $c->[0] eq 'x')
			{
			$state->v_x(-0.01 * $state->v_x() );

			}
			else
			{
			$state->y( $state->y );
			$state->v_y( 0 );
			$ay = 0;
			}
			$moving = 0 if $move !~ 'none';
			$jumping = -1;
		
		}

        if ( $move =~ 'up' && $jumping < 0 ) {
            $state->y($state->y - 1); #Get his jump started.
            $state->v_y(-102);
            $jumping++;
        }

        if ( $jumping == -1 ) {
            
			#We can only stop moving when we are not jumping. But let us know that we should't continue 
            if ( $moving == -1 && $move =~ 'none' )  {  $state->v_x(0);  }
            
            if ( $move =~ 'left' )  { $state->x($state->x-1); $state->v_x(-80); $moving = 1 }
            if ( $move =~ 'right' ) { $state->x($state->x+1); $state->v_x(80); $moving = 1 }
        }      
           
            if ( $move =~ 'stopl' ) {  $moving = -1; $state->v_x(0.7* $state->v_x )}
            if ( $move =~ 'stopr' ) {  $moving = -1; $state->v_x(0.7* $state->v_x ) }
       

       # $print = " $move | $moving ";

        $move = 'none';
        return ( 0, $ay, 0 );
    }
);

my $render_obj = sub {

    my $state = shift;

    my $c_rect = SDL::Rect->new( $state->x, $state->y, 10, 10 );

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
    sub { 
		$app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x0 );		
		$app->draw_rect( $_, 0xFFFF0000 ) foreach @collide_blocks;
	    } 
	  );

$app->add_object( $obj, $render_obj );

$app->add_show_handler(
    sub { $app->update( );  } );

$app->run_test;


sub check_collision {
 my ($mario, $blocks ) = @_;

 my @collisions = ();

 foreach ( @$blocks )
 {
   my $hash = { x => $mario->x, y=> $mario->y, w=> 10, h => 10, xv => $mario->v_x*0.03, yv => $mario->v_y*0.03 };
   my $rect = hash2rect ($hash);
   my $bhash =  {x=> $_->[0], y=> $_->[1], w => $_->[2], h => $_->[3] };
   my $block = hash2rect ( $bhash );
    my $c = dynamic_collision ($rect, $block, interval=>1, keep_order=>1); 
    if ( $c )
	{

		my $axis =  $c->axis() || 'y';

		my $xdiff = $mario->x - $_->[0];
		$xdiff = int( abs($xdiff + 0.01)/($xdiff + 0.01) );

		my $ydiff = $mario->y - $_->[0];
		$ydiff =  int( abs($ydiff + 0.01)/($ydiff + 0.01) );
		return [$axis, $xdiff, $ydiff];
	 
	}

 }

return -1;

}
