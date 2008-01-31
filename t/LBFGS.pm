use strict;
use warnings;

package t::LBFGS;

use Test::Base -Base;
use Data::Dumper;
use Algorithm::LBFGS;

sub norm2(@) {
    my $x = shift;
    my $r = 0;
    for (@$x) { $r += $_ * $_ }
    return sqrt($r);
}

sub run_tests() {
    my $eps = defined($_[0]) ? $_[0] : 1e-5;
    our %tmp = ();
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Sortkeys = 1;
    for (blocks) {
        next if not exists $_->{'snippet'};
	my $x = eval($_->snippet);
        # tests approximate equality
        if (exists $_->{'approx_expected'}) {
	    my $y = eval($_->approx_expected);	    
	    my $name = $_->name;
            my $max_d = 0;
	    my $cond;
	    if (defined($x) && defined($y)) {
 	        # compare 2 array refs approximately
                if (ref($x) eq 'ARRAY' && ref($y) eq 'ARRAY') {
		    if (scalar(@$x) == scalar(@$y)) {
                        for (my $i = 0; $i < scalar(@$x); $i++) {
                            my $d = abs($x->[$i] - $y->[$i]);
	                    $max_d = $d if $d > $max_d;
                        }
		    }
		    else { $max_d = $eps * 10 }
                }
	        # compare 2 scalar
                else { $max_d = abs($x - $y) }
                $cond = $max_d < $eps * 1.1;
	    }
	    else { $cond = 0 }
	    # if okay condition do not holds, print diagnose information
	    if (!ok($cond, $name)) {
	        my $x_str = Dumper $x;
	        my $y_str = Dumper $y;	
  	        diag "\ngot: $x_str\nexpected: $y_str\neps: $eps\n";
            }
        }
        # test equality
	elsif (exists $_->{'expected'}) {
   	    my $y = eval($_->expected);
	    my $name = $_->name;
	    my $cond;
	    my $x_str = Dumper $x;
	    my $y_str = Dumper $y;
	    if (defined($x) && defined($y)) {
	        is $x_str, $y_str, $name;
	    }
	    else {
	        ok(0, $name);
		diag "\ngot: $x_str\nexpected: $y_str\n";
	    }
	}
    }
}

1;
