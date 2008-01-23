use strict;
use warnings;

use t::LBFGS;

plan tests => 1 * blocks;

run_is 'snippet' => 'expected';

__END__

=== Create a L-BFGS optimizer
--- snippet
my $o = Algorithm::LBFGS->new;
defined($o)
--- expected
1

=== Default parameters
--- snippet
my $o = Algorithm::LBFGS->new;
[
    $o->get_param('m'),
    $o->get_param('epsilon'),
    $o->get_param('max_iterations'),
    $o->get_param('max_linesearch'),
    $o->get_param('min_step'),
    $o->get_param('max_step'),
    $o->get_param('ftol'),
    $o->get_param('gtol'),
    $o->get_param('orthantwise_c')
]
--- expected
[6, 1e-5, 0, 20, 1e-20, 1e+20, 1e-4, 0.9, 0.0]

=== Create a L-BFGS optimizer by customized parameters
--- snippet
my $o = Algorithm::LBFGS->new(m => 4, gtol => 1.0);
[
    $o->get_param('m'),
    $o->get_param('gtol')
]
--- expected
[4, 1.0]

=== Modify the parameters
--- snippet
my $o = Algorithm::LBFGS->new;
$o->set_param(m => 4, gtol => 1.0);
[
    $o->get_param('m'),
    $o->get_param('gtol')
]
--- expected
[4, 1.0]

