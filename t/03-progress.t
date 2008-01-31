use strict;
use warnings;

use t::LBFGS;

plan tests => 1 * blocks;

t::LBFGS::run_tests;

__END__

=== Preparation of the following tests
--- snippet
$tmp{o} = Algorithm::LBFGS->new;
my $lbfgs_eval = sub {
    my $x = shift;
    my $f = $x->[0] * $x->[0] / 2 + $x->[1] * $x->[1] / 3;
    my $g = [$x->[0], 2 * $x->[1] / 3];
    return ($f, $g);
};
$tmp{log} = [];
my $x = $tmp{o}->fmin($lbfgs_eval, [5, 5], 'logging', $tmp{log});
1;
--- expected
1;

=== Iteration number k should be growing natural numbers
--- snippet
my @k = map { $_->{k} } @{$tmp{log}};
\@k;
--- expected
[1..scalar(@{$tmp{log}})];

=== Check the consistency of x and xnorm
--- snippet
my @xnorm = map { norm2($_->{x}) } @{$tmp{log}};
\@xnorm;
--- approx_expected
my @expected_xnorm = map { $_->{xnorm} } @{$tmp{log}};
\@expected_xnorm;

=== Check the consistency of g (grad f(x)) and gnorm
--- snippet
my @gnorm = map { norm2($_->{g}) } @{$tmp{log}};
\@gnorm;
--- approx_expected
my @expected_gnorm = map { $_->{gnorm} } @{$tmp{log}};
\@expected_gnorm;

=== f(x) should be decreasing
--- snippet
my $d = [];
my $log = $tmp{log};
if (scalar(@$log) > 1) {
    for (my $i = 1; $i < scalar(@$log); $i++) {
        $d->[$i - 1] = $log->[$i]->{fx} < $log->[$i - 1] ? 1 : 0;
    }
}
$d;
--- expected
my $d = [];
my $log = $tmp{log};
if (scalar(@$log) > 1) {
    push @$d, 1 for (1..scalar(@$log)-1);
}
$d;
