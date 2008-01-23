use strict;
use warnings;

use t::LBFGS;

plan tests => 1 * blocks;

run_is 'snippet' => 'expected';

__END__

=== Preparation of the following tests
--- snippet
$o = Algorithm::LBFGS->new;
$eps = $o->get_param('epsilon');
1;
--- expected
1;

=== A simple optimization (one dimension)
f(x) = x^2
--- snippet
my $lbfgs_eval = sub {
    my $x = shift;
    my $f = $x->[0] * $x->[0];
    my $g = [ 2 * $x->[0] ];
    return ($f, $g);
};
my $x = $o->fmin($lbfgs_eval, [6]);
[approx_eq($x, [0], $eps), $o->{status}]
--- expected
[1, 'LBFGS_OK']

=== Another simple optimization (two dimension)
f(x1, x2) = x1^2 / 2 + x2^2 / 3
--- snippet
my $lbfgs_eval = sub {
    my $x = shift;
    my $f = $x->[0] * $x->[0] / 2 + $x->[1] * $x->[1] / 3;
    my $g = [$x->[0], 2 * $x->[1] / 3];
    return ($f, $g);
};
my $x = $o->fmin($lbfgs_eval, [5, 5]);
[approx_eq($x, [0.0, 0.0], $eps), $o->{status}]
--- expected
[1, 'LBFGS_OK']

=== A larger scale optimization (100000 dimension)
f(x1, x2, ..., x100000) = (x1 - 2)^2 + (x2 + 3)^2 + x3^2 + ... + x100000^2
--- snippet
my $dim = 100000;
my $lbfgs_eval = sub {
    my $i;
    my $x = shift;
    my $f = ($x->[0] - 2) * ($x->[0] - 2) + ($x->[1] + 3) * ($x->[1] + 3);
    for ($i = 2; $i < $dim; $i++) { $f += $x->[$i] * $x->[$i] }
    my $g = [ 2 * $x->[0] - 4, 2 * $x->[1] + 6 ];
    for ($i = 2; $i < $dim; $i++) { $g->[$i] = 2 * $x->[$i] }
    return ($f, $g);
};
my $x0;
for (my $i = 0; $i < $dim; $i++) { $x0->[$i] = 0.5 }
my $x1;
$x1->[0] = 2;
$x1->[1] = -3;
for (my $i = 2; $i < $dim; $i++) { $x1->[$i] = 0 }
my $x = $o->fmin($lbfgs_eval, $x0);
[approx_eq($x, $x1, $eps), $o->{status}]
--- expected
[1, 'LBFGS_OK']
