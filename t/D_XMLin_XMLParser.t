use strict;
use warnings;
use File::Spec;
use FindBin;
use Test::More;

eval { require XML::Parser; };
if($@) {
  plan skip_all => 'no XML::Parser';
}

$ENV{XML_SIMPLE_PREFERRED_PARSER} = 'XML::Parser';

$0 = File::Spec->catfile($FindBin::Bin, '1_XMLin.t');  # t/1_XMLin.t
require $0;
