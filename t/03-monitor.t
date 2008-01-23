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
my $lbfgs_eval = sub {
    my $x = shift;
    my $f = $x->[0] * $x->[0] / 2 + $x->[1] * $x->[1] / 3;
    my $g = [$x->[0], 2 * $x->[1] / 3];
    return ($f, $g);
};
$log = [];
my $x = $o->fmin($lbfgs_eval, [5, 5], 'logging', $log);
1;
--- expected
1;

=== Iteration number k should be growing natural numbers
--- snippet
my $ok = 1;
for (my $i = 0; $i < scalar(@$log); $i++) {
    if ($log->[$i]->{k} != $i + 1) {
        $ok = 0;
	last;
    }
}
$ok;
--- expected
1;

=== Check the consistency of x, grad f(x) and their 2-norms
--- snippet
my $ok = 1;
for (my $i = 0; $i < scalar(@$log); $i++) {
    if (!approx_eq([norm2($log->[$i]->{x})], [$log->[$i]->{xnorm}], $eps)) {
        $ok = 0;
	last;
    }
    if (!approx_eq([norm2($log->[$i]->{g})], [$log->[$i]->{gnorm}], $eps)) {
        $ok = 0;
	last;
    }
}
$ok;
--- expected
1;

=== f(x) should be decreasing
--- snippet
my $ok = 1;
if (scalar(@$log) > 1) {
    for (my $i = 1; $i < scalar(@$log); $i++) {
        if ($log->[$i]->{fx} > $log->[$i - 1]->{fx}) {
	    $ok = 0;
	    last;
	}
    }
}
$ok;
--- expected
1;
