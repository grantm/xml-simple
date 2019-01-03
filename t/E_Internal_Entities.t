use strict;
use warnings;
use Test::More;

eval { require XML::Parser; };
if($@) {
  plan skip_all => 'no XML::Parser';
}

plan tests => 2;

use XML::Simple;

$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

my $xml = qq(<?xml version="1.0"?>
<!DOCTYPE foo [
<!ENTITY b "XML bomb" >]>
<foo>&b;</foo>
);

my $opt = XMLin($xml);
isnt($opt, 'XML bomb', 'Internal subset entity not expanded');
is_deeply($opt, {}, 'Internal subset entity left as empty');

exit(0);
