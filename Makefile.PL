use ExtUtils::MakeMaker;

BEGIN {
  my $fatal = 0;
  print "Checking for required modules ...\n";

  eval { require XML::Parser };
  if($@) {
    print "XML::Parser.pm is not installed ... please install before proceeding\n";
    $fatal = 1;
  }
  else {
    print "XML::Parser.pm is installed ... good\n";
  }

  eval { require Storable };
  if($@) {
    print "Storable.pm is not installed ... caching functions will not be available\n";
  }
  else {
    print "Storable.pm is installed ... good\n";
  }


  die "Unable to proceed" if($fatal);
}

WriteMakefile(
    'NAME'          => 'XML::Simple',
    'VERSION_FROM'  => 'Simple.pm',
    'DISTNAME'      => 'XML-Simple',
    'PREREQ_PM'     => { 'XML::Parser' => 2, 'File::Spec' => 0 },
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    # Don't worry if these aren't supported by your Perl
    'AUTHOR'        => 'Grant McLean <grantm@web.co.nz>',
    'ABSTRACT_FROM' => 'Simple.pm',
);
