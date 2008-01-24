use strict;
use warnings;

package t::LBFGS;

use Test::Base -Base;

filters {
    snippet => 'my_eval',
    expected => 'my_eval'
};

package t::LBFGS::Filter;

use Test::Base::Filter -base;
use Algorithm::LBFGS;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

sub approx_eq(@) {
    my ($x, $y, $eps) = @_;
    my $max_d = 0;
    return undef if scalar(@$x) != scalar(@$y);
    for (my $i = 0; $i < scalar(@$x); $i++) {
        my $d = abs($x->[$i] - $y->[$i]);
	$max_d = $d if $d > $max_d;
    }
    return $max_d < $eps * 1.2 ? 1 : 0;
}

sub norm2(@) {
    my $x = shift;
    my $r = 0;
    for (@$x) { $r += $_ * $_ }
    return sqrt($r);
}

our ($o, $log, $eps);

sub my_eval { return Dumper(eval(shift)) }

1;
