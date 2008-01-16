package Algorithm::LBFGS;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(&fmin);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Algorithm::LBFGS', $VERSION);

# parameters of L-BFGS
our $m = 5;
our $xtol = eps();
our $eps = eps();
our $iprt1 = 1;
our $iprt2 = 0;
our $gtol = .9;
our $stpmin = 1e-20;
our $stpmax = 1e20;

# subroutine: fmin
sub fmin(@) {
    my ($f, $g, $x0, $diag) = @_;
    # check the input
    return undef if
        ref $f ne 'CODE' or
        ref $g ne 'CODE' or
        ref $x0 ne 'ARRAY' or
        scalar(@$x0) == 0 or
        defined($diag) and ref $diag ne 'CODE';
    # initialize
    my $n = scalar(@$x0);
    my $diagco = defined($diag) ? 1 : 0;
    my $w = alloc_workspace($n, $m);
    return undef if not $w; # fail to allocate workspace
    my $x = $x0;
    set_gtol($gtol);
    set_stpmin($stpmin);
    set_stpmax($stpmax);
    # iterations
    my $iflag = 0;
    do {
        lbfgs_step($n, $m, $x, $f->($x), $g->($x), $diagco, 
	           defined $diag ? $diag->($x) : [],
	           $iprt1, $iprt2, $eps, $xtol, $w, \$iflag);
    } while ($iflag == 1);
    # finish
    free_workspace($w);
    return $iflag != 0 ? undef : $x;
}

1;
__END__

=head1 NAME

Algorithm::LBFGS - Perl extension for L-BFGS 

=head1 SYNOPSIS

  use Algorithm::LBFGS;
  
  # f(x) = x^2
  sub f() {
      my $x = shift;
      return $x->[0] * $x->[0];
  }

  # grad f(x) = 2x
  sub g() {
      my $x = shift;
      return [ 2 * $x->[0] ];
  }

  # minimize
  my $xt = fmin(\&f, \&g, [5]); # $xt = [0]

=head1 DESCRIPTION

L-BFGS is a limited-memory quasi-Newton method for unconstrained
optimization. This method is especially efficient on problems involving a
large number of variables.

It solves a problem described as following:

  min f(x), x = (x1, x2, ..., xn)

This module is a Perl port of its Fortran 77 version by Jorge Nocedal.

L<http://www.ece.northwestern.edu/~nocedal/lbfgs.html>

=head2 fmin

C<fmin(f, g, x0)> finds a vector C<x> which minimize the function C<f(x)>. 

=over

=item *
C<f> - The reference to the C<f(x)> function. This function is supposed to
accept an array reference (the vector of C<x>) and return a scalar (the
value C<f(x)>).

=item *
C<g> - The reference to the C<grad f(x)> function (C<grad> for gradient).
This function is supposed to accept an array reference (the vector C<x>) and
return an array reference (the gradient vector of C<f> at C<x>).

=item *
C<x0> - The initial value of C<x>. It is supposed to be an array reference.
The final result may depend on your choice of the initial C<x>.

=back

C<fmin> returns the optimized C<x> on success, otherwise returns C<undef>.

=head2 $Algorithm::LBFGS::m

C<m> is an positive integer value that can be set by the user to the number
of corrections used in the BFGS update. Values of C<m> less than 3 are not 
recommended; large values of C<m> will result in excessive computing time.
C<3 E<lt>= m E<lt>= 7> is recommended. The default value of C<m> is 5.

=head2 $Algorithm::LBFGS::xtol

C<xtol> is a positive value that can be set by the user to an estimate of 
the machine precision. The line search routine will terminate if the
relative width of the interval of uncertainty is less than C<xtol>.
The default value of C<xtol> is equal to the C<DBL_EPSILON> in F<float.h>.

=head2 $Algorithm::LBFGS::eps

C<eps> is a positive DOUBLE value that can be set by the user to determine
the accuracy with which the solution is to be found. The subroutine terminates when

  ||G|| < eps max(1,||X||)

where C<||.||> denotes the Euclidean norm.

The default value of C<eps> is equal to the C<DBL_EPSILON> in F<float.h>.

=head2 $Algorithm::LBFGS::gtol

C<gtol> is a value with default value 0.9, which controls the accuracy of
the line search. If the C<f(x)> and C<grad f(x)> evaluations are
inexpensive with respect to the cost of the iteration (which is sometimes
the case when solving very large problems) it may be advantageous to set
C<gtol> to a small value. A typical small value is 0.1. C<gtol> should be
greater than 1E-04.

=head2 $Algorithm::LBFGS::stpmin and $Algorithm::LBFGS::stpmax

C<stpmin> and C<stpmax> are non-negative value which specify lower and upper
bounds for the step in the line search. Their default values are 1.D-20 and
1.D+20, respectively. These values need not be modified unless the exponents
are too large for the machine being used, or unless the problem is extremely
badly scaled (in which case the exponents should be increased).

=head2 $Algorithm::LBFGS::iprt1 and $Algorithm::LBFGS::iprt2

C<iprt1> and C<iprt2> can be specified to control the output.

C<iprt1> specifies the frequency of the output:

=over

=item *
C<iprt1 E<lt> 0> : no output is generated, 

=item *
C<iprt1 = 0> : output only at first and last iteration,

=item *
C<iprt1 E<gt> 0> : output every iterations.

=back

C<iprt2> specifies the type of output generated:

=over

=item *
C<iprt2 = 0> : iteration count, number of function evaluations, function
value, norm of the gradient, and steplength,

=item *
C<iprt2 = 1> : same as C<iprt2 = 0>, plus vector of variables and gradient
vector at the initial point,

=item *
C<iprt2 = 2> : same as C<iprt2 = 1>, plus vector of variables,

=item *
C<iprt2 = 3> : same as C<iprt2 = 2>, plus gradient vector.

=back

The default value of C<iprt1> and C<iprt2> is 1, 0 respectively.

=head1 DEPENDENCY

To build the module, you need to install C<libf2c> beforehand.

=head1 SEE ALSO

L<PDL>, L<PDL::Opt::NonLinear>

=head1 AUTHOR

Laye Suen, E<lt>laye@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Laye Suen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 REFERENCE

=over

=item
J. Nocedal. Updating Quasi-Newton Matrices with Limited Storage (1980)
, Mathematics of Computation 35, pp. 773-782.

=item
D.C. Liu and J. Nocedal. On the Limited Memory Method for Large Scale
Optimization (1989), Mathematical Programming B, 45, 3, pp. 503-528.

=back

=cut
