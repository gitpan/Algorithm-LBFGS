use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Algorithm::LBFGS',
    VERSION_FROM      => 'lib/Algorithm/LBFGS.pm',
    PREREQ_PM         => {}, 
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Algorithm/LBFGS.pm',
       AUTHOR         => 'Laye Suen <laye@cpan.org>') : ()),
    LIBS              => ['-lm -lf2c'],
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => '$(O_FILES)',
    LICENSE           => 'perl'
);
