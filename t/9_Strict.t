# $Id$
# vim: syntax=perl

use strict;
use Test::More;

plan tests => 15;


##############################################################################
#                      T E S T   R O U T I N E S
##############################################################################

eval "use XML::Simple qw(:strict);";
ok(!$@, 'XML::Simple loads ok with qw(:strict)');

# Check that the basic functionality still works

my $xml = q(<opt name1="value1" name2="value2"></opt>);

$@ = '';
my $opt = eval {
  XMLin($xml, forcearray => 1, keyattr => {});
};
is($@, '', 'XMLin() did not fail');

my $keys = join(' ', sort keys %$opt);

is($keys, 'name1 name2', 'and managed to produce the expected results');


# Confirm that forcearray cannot be omitted

eval {
  $opt = XMLin($xml, keyattr => {});
};

isnt($@, '', 'omitting forcearray was a fatal error');
like($@, qr/No value specified for 'forcearray'/, 
  'with the correct error message');


# Confirm that keyattr cannot be omitted

eval {
  $opt = XMLin($xml, forcearray => []);
};

isnt($@, '', 'omitting keyattr was a fatal error');
like($@, qr/No value specified for 'keyattr'/,
  'with the correct error message');


# Confirm that element names from keyattr cannot be omitted from forcearray

eval {
  $opt = XMLin($xml, keyattr => { part => 'partnum' }, forcearray => 0);
};

isnt($@, '', 'omitting forcearray for elements in keyattr was a fatal error');
like($@, qr/<part> set in keyattr but not in forcearray/,
  'with the correct error message');


eval {
  $opt = XMLin($xml, keyattr => { part => 'partnum' }, forcearray => ['x','y']);
};

isnt($@, '', 'omitting keyattr elements from forcearray was a fatal error');
like($@, qr/<part> set in keyattr but not in forcearray/,
  'with the correct error message');


# Confirm that missing key attributes are detected

$xml = q(
<opt>
  <part partnum="12345" desc="Thingy" />
  <part partnum="67890" desc="Wotsit" />
  <part desc="Fnurgle" />
</opt>
);

eval {
  $opt = XMLin($xml, keyattr => { part => 'partnum' }, forcearray => 1);
};

isnt($@, '', 'key attribute missing from names element was a fatal error');
like($@, qr/<part> element has no 'partnum' key attribute/,
  'with the correct error message');


# Confirm that stringification of references is trapped

$xml = q(
<opt>
  <item>
    <name><firstname>Bob</firstname></name>
    <age>21</age>
  </item>
</opt>
);

eval {
  $opt = XMLin($xml, keyattr => { item => 'name' }, forcearray => ['item']);
};

isnt($@, '', 'key attribute not a scalar was a fatal error');
like($@, qr/<item> element has non-scalar 'name' key attribute/,
  'with the correct error message');

exit(0);

