use strict;
use warnings;

use inc::Module::Install;

name            'Algorithm-LBFGS';
all_from        'lib/Algorithm/LBFGS.pm';
license         'MIT';

include         'Test::Builder';
include         'Test::Builder::Module';
include         'Test::More';
include         'Test::Number::Delta';

include         'Inline';
include         'Inline::C';
include         'Inline::C::ParseRecDescent';
include         'Inline::MakeMaker';
include         'Inline::denter';

auto_install;

WriteMakefile(
    LIBS              => [],
    INC               => '-I.',
    OBJECT            => '$(O_FILES)'
);


