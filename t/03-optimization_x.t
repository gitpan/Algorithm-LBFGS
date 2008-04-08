use strict;
use warnings;

use Test::More;
use Test::Number::Delta within => 1e-5;

eval "use Inline 'C' => 'void a() {}'";
$@
    ? plan skip_all => 'Inline::C is required for running this test'
    : plan tests => 5;

use Inline 'C' => 'DATA';

my $__;
sub NAME { $__ = shift };

###
NAME 'Preparation for the following tests';
use Algorithm::LBFGS;
my $o = Algorithm::LBFGS->new;
ok 1,
$__;

###
NAME 'A simple optimization (one dimension) - external';
# f(x) = x^2
{
    my $x1 = $o->fmin(f1_eval_ptr(), [6]);
    delta_ok $x1, [0],
    $__;
}

###
NAME 'Test status';
is $o->get_status, 'LBFGS_OK',
$__;

###
NAME 'Another simple optimization (two dimensions) - external';
# f(x1, x2) = x1^2 / 2 + x2^2 / 3
{
    my $x1 = $o->fmin(f2_eval_ptr(), [5, 5]);
    delta_ok $x1, [0, 0],
    $__;
}

###
NAME 'A high dimension optimization (100,000 dimensions) - external';
# f(x1, x2, ..., x100000) = (x1 - 2)^2 + (x2 + 3)^2 + x3^2 + ... + x100000^2
{
    my $dim = 100000;
    my $x0 = [];
    for (my $i = 0; $i < $dim; $i++) { $x0->[$i] = 0.5 }
    my $x1 = $o->fmin(f3_eval_ptr(), $x0);
    my $x1_expected = [];
    $x1_expected->[0] = 2;
    $x1_expected->[1] = -3;
    for (my $i = 2; $i < $dim; $i++) { $x1_expected->[$i] = 0 }
    delta_ok $x1, $x1_expected,
    $__;
}

__END__
__C__

#define EVAL_FUNC(name) \
    double name ( \
        void*          userdata, \
        const double*  x, \
        double*        g, \
        const int      n, \
        const double   step \
    )

EVAL_FUNC(f1_eval) {
    g[0] = 2 * x[0];
    return x[0] * x[0];
}

EVAL_FUNC(f2_eval) {
    g[0] = x[0];
    g[1] = 2 * x[1] / 3.0;
    return x[0] * x[0] / 2.0 + x[1] * x[1] / 3.0;
}

EVAL_FUNC(f3_eval) {
   int dim = 100000, i;
   double f = 0;
   g[0] = 2 * x[0] - 4;
   g[1] = 2 * x[1] + 6;
   for (i = 2; i < dim; i++) g[i] = 2 * x[i];
   f = (x[0] - 2) * (x[0] - 2) + (x[1] + 3) * (x[1] + 3);
   for (i = 2; i < dim; i++) f += x[i] * x[i];
   return f;
}

void* f1_eval_ptr() { return &f1_eval; }
void* f2_eval_ptr() { return &f2_eval; }
void* f3_eval_ptr() { return &f3_eval; }


