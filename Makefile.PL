
use ExtUtils::MakeMaker;

BEGIN {
  if($] < 5.006) {
    warn
      qq(This version of XML::Simple requires Perl version 5.6 or better.\n) .
      qq(You might prefer to install an older version of XML::Simple\n\n) .
      qq(  perl -MCPAN -e "install 'G/GR/GRANTM/XML-Simple-1.08.tar.gz'"\n\n);
  }
}

require 5.006;

my $make_params = {
    'NAME'          => 'XML::Simple',
    'VERSION_FROM'  => 'lib/XML/Simple.pm',
    'DISTNAME'      => 'XML-Simple',
    'PREREQ_PM'     => {
                         Test::Simple          => 0.41,
                       },
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    'AUTHOR'        => 'Grant McLean <grantm@cpan.org>',
    'ABSTRACT_FROM' => 'lib/XML/Simple.pm',
};

print "Checking installed modules ...\n";

if ( eval { require XML::SAX } && ! $@ ) {
    my $default_parser = ref(XML::SAX::ParserFactory->parser());
    if ($default_parser eq 'XML::SAX::PurePerl') {
      my $version = XML::SAX->VERSION;
      if($version > 0.12  and  $version < 0.15) {
        die <<"EOF";
=============================================================================

  Fatal error: Your default XML parser (XML::SAX::PurePerl) is broken.

  There are known bugs in the PurePerl parser included with version 0.13 
  and 0.14 of XML::SAX.  The XML::Simple tests will fail with this parser.

  One way to avoid the problem is to install XML::SAX::Expat - it will
  install itself as the system default XML parser and then you will be able 
  to install XML::Simple successfully.  XML::SAX::Expat is also much faster
  than XML::SAX::PurePerl so you probably want it anyway.

=============================================================================
EOF
      }
    }
    elsif ($default_parser eq 'XML::SAX::RTF') {
      die <<"EOF";
=============================================================================

  Fatal error: Your default XML parser (XML::SAX::RTF) is broken.

  The XML::SAX:RTF module is installed as the default XML parser on your
  system.  This is a bug - although the module does generate SAX events,
  it does not parse XML and should not register itself as an XML parser.

  One way to avoid the problem is to install XML::SAX::Expat - it will
  register itself as the system default XML parser and then you will be
  able to install XML::Simple successfully.

  Another solution would be to locate the XML/SAX/ParserDetails.ini file
  and edit it to completely remove the section beginning [XML::SAX::RTF].

=============================================================================
EOF
    }
    print "XML::SAX is installed, it will be used by the test suite\n";
    $make_params->{PREREQ_PM}->{'XML::SAX'} = 0;
    $make_params->{PREREQ_PM}->{'XML::NamespaceSupport'} = 1.04;
}
elsif ( eval { require XML::Parser } && ! $@ ) {
    print "XML::Parser is installed, it will be used by the test suite\n";
    $make_params->{PREREQ_PM}->{'XML::Parser'} = 0;
} 
else {
    print "You don't have either XML::SAX or XML::Parser installed!\n";
    $make_params->{PREREQ_PM}->{'XML::SAX'} = 0;
    $make_params->{PREREQ_PM}->{'XML::NamespaceSupport'} = 1.04;
    # Hopefully the following line can be removed after next XML::SAX release
    $make_params->{PREREQ_PM}->{'XML::SAX::Expat'} = 0;
}

eval { require Storable };
if($@) {
  print "Storable is not installed ... caching functions will not be available\n";
}


WriteMakefile(%$make_params);
