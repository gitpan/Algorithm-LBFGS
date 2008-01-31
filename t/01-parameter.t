use strict;
use warnings;

use t::LBFGS;

plan tests => 1 * blocks;

t::LBFGS::run_tests;

__END__

=== Create a L-BFGS optimizer
--- snippet
$tmp{o} = Algorithm::LBFGS->new;
defined($tmp{o})
--- expected
1

=== Default parameters (float)
--- snippet
$tmp{o} = Algorithm::LBFGS->new;
[
    $tmp{o}->get_param('epsilon'),
    $tmp{o}->get_param('min_step'),
    $tmp{o}->get_param('max_step'),
    $tmp{o}->get_param('ftol'),
    $tmp{o}->get_param('gtol'),
    $tmp{o}->get_param('orthantwise_c')
]
--- approx_expected
[1e-5, 1e-20, 1e+20, 1e-4, 0.9, 0.0]

=== Default parameters (int)
--- snippet
[
    $tmp{o}->get_param('m'),
    $tmp{o}->get_param('max_iterations'),
    $tmp{o}->get_param('max_linesearch')
]
--- expected
[6, 0, 20]

=== Create a L-BFGS optimizer by customized parameters
--- snippet
$tmp{o} = Algorithm::LBFGS->new(gtol => 1.0, epsilon => 1e-6);
[
    $tmp{o}->get_param('gtol'),
    $tmp{o}->get_param('epsilon')
]
--- approx_expected
[1.0, 1e-6]

=== Modify a parameters
--- snippet
$tmp{o}->set_param(m => 4);
$tmp{o}->get_param('m')
--- expected
4

