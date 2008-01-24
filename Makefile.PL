use inc::Module::Install;

name            'Algorithm-LBFGS';
all_from        'lib/Algorithm/LBFGS.pm';
license         'MIT';

use_test_base;

auto_install;

my $float_precision = '64';
my $sse_support = '';

#$| = 1;
#print "\nPrecision of float (64): ";
#while (<STDIN>) {
#    $float_precision = '32' if m/^\s*32\s*$/;
#    last if m/^\s*$/ or m/^\s*32\s*$/ or m/^\s*64\s*$/;
#    print "only 32 and 64 is allowed\nPrecision of float (64): ";
#}
#print "Enable SSE support (y/N): ";
#$_ = <STDIN>;
#$sse_support = '-DUSE_SSE -D__SSE2__ -D__SSE__' if m/^\s*[yY]\s*$/;

WriteMakefile(
    LIBS              => ['-lm'],
    INC               => '-I.',
    OBJECT            => '$(O_FILES)',
    DEFINE            => "-DLBFGS_FLOAT=$float_precision $sse_support",
);

