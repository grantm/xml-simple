# $Id$

use ExtUtils::MakeMaker;

my $parser_count = 0;
my $fatal        = 0;

print "Checking for required modules ...\n";

eval { require XML::SAX };
if($@) {
  print "XML::SAX is not installed\n";
}
else {
  print "XML::SAX is installed ... good\n";
  $parser_count++;

  eval { require XML::NamespaceSupport };
  if($@) {
    print "XML::NamespaceSupport is not installed ... this is required only for generating XML with namespace declarations\n";
  }
  else {
    if($XML::NamespaceSupport::VERSION < 1.04) {
      print "You must upgrade XML::NamespaceSupport to version 1.04 or better\n";
      $fatal++;
    }
    else {
      print "XML::NamespaceSupport is installed ... good\n";
    }
  }

}

eval { require XML::Parser };
if($@) {
  print "XML::Parser is not installed\n";
}
else {
  print "XML::Parser is installed ... good\n";
  $parser_count++;
}

eval { require Storable };
if($@) {
  print "Storable is not installed ... caching functions will not be available\n";
}
else {
  print "Storable is installed ... good\n";
}


unless($parser_count) {
  print "You must install either XML::SAX or XML::Parser before XML::Simple\n";
  $fatal++;
}

if($fatal) {
  print "You must correct the above problems before XML::Simple can be installed\n";
  exit(1);
}

WriteMakefile(
    'NAME'          => 'XML::Simple',
    'VERSION_FROM'  => 'Simple.pm',
    'DISTNAME'      => 'XML-Simple',
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    ($] >= 5.005 ? (
      'AUTHOR'        => 'Grant McLean <grantm@web.co.nz>',
      'ABSTRACT_FROM' => 'Simple.pm',
    ) : () )
);
