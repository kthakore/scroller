use strict;
use warnings;
use SDL;
use SDL::Rect;
use SDL::Events;
use Math::Trig;
use Collision::2D ':all';
use Data::Dumper;
use SDLx::App;
use SDLx::Controller::Interface;
use SDLx::Sprite::Animated;

my $app = SDLx::App->new( w => 400, h => 400, dt => 0.02, title => 'Pario' );

$app->update();

my @update_rects = ();

my $sprite = SDLx::Sprite::Animated->new(
    image           => 'data/m.png',
    rect            => SDL::Rect->new( 0, 0, 16, 28 ),
    ticks_per_frame => 2,
);

$sprite->set_sequences(
    left  => [ [ 0, 1 ], [ 1, 1 ], [ 2, 1 ], [ 3, 1 ], [ 4, 1 ] ],
    right => [ [ 0, 0 ], [ 1, 0 ], [ 2, 0 ], [ 3, 0 ], [ 4, 0 ] ],
    stopl => [ [ 0, 1 ] ],
    stopr => [ [ 0, 0 ] ],
    jumpr => [ [ 5, 0 ] ],
    jumpl => [ [ 5, 1 ] ],

);

$sprite->sequence('stopr');
$sprite->start();

my $obj =
  SDLx::Controller::Interface->new( x => 10, y => 380, v_x => 0, v_y => 0 );

my @collide_blocks = (
    [ 19,  330 ],
    [ 40,  330 ],
    [ 30,  309 ],
    [ 120, 400 ],
    [ 141, 400 ],
    [ 141, 379 ]
);

foreach ( ( 0 .. 2, 10 ... 15, 17 ... 25 ) ) {
    push @collide_blocks, [ $_ * 20 + $_ * 1, 400 ];
}

foreach (@collide_blocks) {
    $_->[1] -= 20;
    $_->[2] = 20;
    $_->[3] = 20;
}

my $pressed   = {};
my $lockjump  = 0;
my $vel_x     = 100;
my $vel_y     = -102;
my $quit      = 0;
my $gravity   = 180;
my $dashboard = '';
my $w         = 16;
my $h         = 28;
my $scroller  = 0;

$obj->set_acceleration(
    sub {
        my $time  = shift;
        my $state = shift;
        $state->v_x(0);    #Don't move by default
        my $ay = 0;

        #Basic movements
        if ( $pressed->{right} ) {
            $state->v_x($vel_x);
            if   ( $pressed->{up} ) { $sprite->sequence('jumpr') }
            else                    { $sprite->sequence('right'); }

        }
        elsif ( $sprite->sequence() eq 'right' && !$pressed->{left} ) {
            $sprite->sequence('stopr');
        }

        if ( $pressed->{left} ) {
            $state->v_x( -$vel_x );
            if   ( $pressed->{up} ) { $sprite->sequence('jumpl') }
            else                    { $sprite->sequence('left'); }
        }
        elsif ( $sprite->sequence() eq 'left' && !$pressed->{right} ) {
            $sprite->sequence('stopl');
        }
        if ( $pressed->{up} && !$lockjump ) {

	  $sprite->sequence('jumpr')   if ( $sprite->sequence() =~ 'r');
	  $sprite->sequence('jumpl')   if ( $sprite->sequence() =~ 'l');

            $state->v_y($vel_y);
            $lockjump = 1;

        }

        my $collision = check_collision( $state, \@collide_blocks );
        $dashboard = 'Collision = ' . Dumper $collision;

        if ( $collision != -1 && $collision->[0] eq 'x' ) {
            my $block = $collision->[1];

            #X-axis collision_check
            if ( $state->v_x() > 0 ) {    #moving right

                $state->x( $block->[0] - $w - 3 );    #set to edge of block

            }
            if ( $state->v_x() < 0 ) {                #moving left

                $state->x( $block->[0] + 3 + $block->[2] )
                  ;                                   #set to edge of block
            }
        }

        #y-axis collision_check

        if ( $state->v_y() < 0 ) {                    #moving up
            if ( $collision != -1 && $collision->[0] eq 'y' ) {
                my $block = $collision->[1];
                $state->y( $block->[1] + $block->[3] + 3 );
                $state->v_y(0);


            }
            else {

                #continue falling
                $ay = $gravity;
            }
        }

        else    #moving down on ground
        {
            if ( $collision != -1 && $collision->[0] eq 'y' ) {
                my $block = $collision->[1];
                $state->y( $block->[1] - $h - 1 );
                $state->v_y(0);    # Causes test again in next frame
                $ay = 0;
                $lockjump = 0 if ( !$pressed->{up} );
		$sprite->sequence( 'stopr' ) if $sprite->sequence =~ 'r';
		$sprite->sequence( 'stopl' ) if $sprite->sequence =~ 'l';

            }
            else              
            { #falling in air 

                $ay = $gravity;

		# $lockjump = 1;

            }
        }

        if ( $state->y + 10 > $app->h ) {

            $quit = 1;
        }



        if ($scroller) {
            my $dir = 0;
            $scroller-- and $dir = +1 if $scroller > 0;
            $scroller++ and $dir = -1 if $scroller < 0;

            $state->x( $state->x() + $dir );

            $_->[0] += $dir foreach (@collide_blocks);

        }
        else {
            if ( $state->x() > $app->w - 100 ) {
                $scroller = -5;
            }
            if ( $state->x() < 100 ) {
                $scroller = 5;
            }

        }

        return ( 0, $ay, 0 );
    }
);

my $render_obj = sub {

    my $state = shift;

    my $c_rect = SDL::Rect->new( $state->x, $state->y, 16, 28 );

#    $app->draw_rect( $c_rect, 0xFF00CCFF );

    #	$app->draw_rect( [50,50, 16, 28], 0xFF00CCFF );
    $sprite->x( $state->x );
    $sprite->y( $state->y );
    $sprite->next();
    $sprite->draw($app);

};

$app->add_event_handler(
    sub {
        return 0 if $_[0]->type == SDL_QUIT;

        my $key = $_[0]->key_sym;
        my $name = SDL::Events::get_key_name($key) if $key;

        if ( $_[0]->type == SDL_KEYDOWN ) {
            $pressed->{$name} = 1;
        }
        elsif ( $_[0]->type == SDL_KEYUP ) {
            $pressed->{$name} = 0;
        }

        return 1 if !$quit;
    }
);

$app->add_show_handler(
    sub {
        $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x0 );
        $app->draw_rect( $_, 0xFFFF0000 ) foreach @collide_blocks;

#::GFX::Primitives::string_color( $app, $app->w/2-100, 0, $dashboard, 0xFF0000FF);
        SDL::GFX::Primitives::string_color(
            $app,
            $app->w / 2 - 100,
            $app->h / 2,
            "Mario is DEAD", 0xFF0000FF
        ) if $quit;

    }
);

$app->add_object( $obj, $render_obj );

$app->add_show_handler( sub { $app->update(); } );

$app->run_test;

sub check_collision {
    my ( $mario, $blocks ) = @_;

    my @collisions = ();

    foreach (@$blocks) {
        my $hash = {
            x  => $mario->x,
            y  => $mario->y,
            w  => $w,
            h  => $h,
            xv => $mario->v_x * 0.02,
            yv => $mario->v_y * 0.02
        };
        my $rect  = hash2rect($hash);
        my $bhash = { x => $_->[0], y => $_->[1], w => $_->[2], h => $_->[3] };
        my $block = hash2rect($bhash);
        my $c =
          dynamic_collision( $rect, $block, interval => 1, keep_order => 1 );
        if ($c) {

            my $axis = $c->axis() || 'y';

            return [ $axis, $_ ];

        }

    }

    return -1;

}
