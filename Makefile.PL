use strict;
use warnings;

use inc::Module::Install;

name            'Algorithm-LBFGS';
all_from        'lib/Algorithm/LBFGS.pm';
license         'MIT';

use_test_base;

auto_install;

WriteMakefile(
    LIBS              => ['-lm'],
    INC               => '-I.',
    OBJECT            => '$(O_FILES)'
);


