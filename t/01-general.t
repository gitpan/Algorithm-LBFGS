use Test::More tests => 6;

# 1
BEGIN { use_ok('Algorithm::LBFGS'); }

my $xt;

sub f() {
    my $x = shift;
    return $x->[0] * $x->[0];
}

sub g() {
    my $x = shift;
    return [ 2 * $x->[0] ];
}

# 2
$xt = fmin(\&f, \&g, 0);
is $xt, undef;

# 3
$xt = fmin(\&f, 0, [5]);
is $xt, undef;

# 4
$xt = fmin(0, \&f, [5]);
is $xt, undef;

# 5
$xt = fmin(0, 0, 0);
is $xt, undef;

# 6
$xt = fmin(\&f, \&g, [5]);
is join(',', @$xt), join(',', (0.0));
