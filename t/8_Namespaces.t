# $Id$

use strict;

use File::Spec;
use IO::File;

eval { require XML::SAX; };
if($@) {
  print STDERR "no XML::SAX...";
  print "1..0\n";
  exit 0;
}

eval { require XML::NamespaceSupport; };
if($@) {
  print STDERR "no XML::NamespaceSupport...";
  print "1..0\n";
  exit 0;
}
if($XML::NamespaceSupport::VERSION < 1.04) {
  print STDERR "XML::NamespaceSupport is too old (upgrade to 1.04 or better)...";
  print "1..0\n";
  exit 0;
}

print "1..7\n";

my $t = 1;

##############################################################################
#                   S U P P O R T   R O U T I N E S
##############################################################################

##############################################################################
# Print out 'n ok' or 'n not ok' as expected by test harness.
# First arg is test number (n).  If only one following arg, it is interpreted
# as true/false value.  If two args, equality = true.
#

sub ok {
  my($n, $x, $y) = @_;
  die "Sequence error got $n expected $t" if($n != $t);
  $x = 0 if(@_ > 2  and  $x ne $y);
  print(($x ? '' : 'not '), 'ok ', $t++, "\n");
}


##############################################################################
# Take two scalar values (may be references) and compare them (recursively
# if necessary) returning 1 if same, 0 if different.
#

sub DataCompare {
  my($x, $y) = @_;

  my($i);

  if(!ref($x)) {
    return(1) if($x eq $y);
    print STDERR "$t:DataCompare: $x != $y\n";
    return(0);
  }

  if(ref($x) eq 'ARRAY') {
    unless(ref($y) eq 'ARRAY') {
      print STDERR "$t:DataCompare: expected arrayref, got: $y\n";
      return(0);
    }
    if(scalar(@$x) != scalar(@$y)) {
      print STDERR "$t:DataCompare: expected ", scalar(@$x),
                   " element(s), got: ", scalar(@$y), "\n";
      return(0);
    }
    for($i = 0; $i < scalar(@$x); $i++) {
      DataCompare($x->[$i], $y->[$i]) || return(0);
    }
    return(1);
  }

  if(ref($x) eq 'HASH') {
    unless(ref($y) eq 'HASH') {
      print STDERR "$t:DataCompare: expected hashref, got: $y\n";
      return(0);
    }
    if(scalar(keys(%$x)) != scalar(keys(%$y))) {
      print STDERR "$t:DataCompare: expected ", scalar(keys(%$x)),
                   " key(s) (", join(', ', keys(%$x)),
		   "), got: ",  scalar(keys(%$y)), " (", join(', ', keys(%$y)),
		   ")\n";
      return(0);
    }
    foreach $i (keys(%$x)) {
      unless(exists($y->{$i})) {
	print STDERR "$t:DataCompare: missing hash key - {$i}\n";
	return(0);
      }
      DataCompare($x->{$i}, $y->{$i}) || return(0);
    }
    return(1);
  }

  print STDERR "Don't know how to compare: " . ref($x) . "\n";
  return(0);
}


##############################################################################
# Copy a file
#

sub CopyFile {
  my($Src, $Dst) = @_;
  
  open(IN, $Src) || return(undef);
  local($/) = undef;
  my $Data = <IN>;
  close(IN);

  open(OUT, ">$Dst") || return(undef);
  print OUT $Data;
  close(OUT);

  return(1);
}


##############################################################################
#                      T E S T   R O U T I N E S
##############################################################################

use XML::Simple;

# Force default behaviour of using SAX parser if it is available (which it
# is or we wouldn't be here).

$XML::Simple::PREFERRED_PARSER = '';

# Confirm that by default qnames are not expanded on input

my $xml = q(<config xmlns:perl="http://www.perl.com/">
  <perl:list count="3" perl:type="array">
    <item>one</item>
    <item>two</item>
    <item>three</item>
    <test xmlns:perl="http://www.microsoft.com" perl:tm="trademark" />
  </perl:list>
</config>);

my $expected = {
  'perl:list' => {
    'count' => '3',
    'item' => [
      'one',
      'two',
      'three'
    ],
    'perl:type' => 'array',
    'test' => {
      'xmlns:perl' => 'http://www.microsoft.com',
      'perl:tm' => 'trademark',
    }
  },
  'xmlns:perl' => 'http://www.perl.com/'
};

my $opt = XMLin($xml);
ok(1, DataCompare($opt, $expected));  # Got what we expected


# Try again with nsexpand option set

$expected = {
  '{http://www.perl.com/}list' => {
    'count' => '3',
    'item' => [
      'one',
      'two',
      'three'
    ],
    '{http://www.perl.com/}type' => 'array',
    'test' => {
      '{http://www.microsoft.com}tm' => 'trademark',
      '{http://www.w3.org/2000/xmlns/}perl' => 'http://www.microsoft.com'
    }
  },
  '{http://www.w3.org/2000/xmlns/}perl' => 'http://www.perl.com/'
};

$opt = XMLin($xml, nsexpand => 1);
ok(2, DataCompare($opt, $expected));  # Got what we expected


# Confirm that output expansion does not occur by default

$opt = {
  '{http://www.w3.org/2000/xmlns/}perl' => 'http://www.perl.com/',
  '{http://www.perl.com/}attr' => 'value',
  '{http://www.perl.com/}element' => [ 'data' ],
};

$xml = XMLout($opt);
ok(3, $xml =~ m{
  ^\s*<opt
  \s+{http://www.w3.org/2000/xmlns/}perl="http://www.perl.com/"
  \s+{http://www.perl.com/}attr="value"
  \s*>
  \s*<{http://www.perl.com/}element\s*>data</{http://www.perl.com/}element\s*>
  \s*</opt>
  \s*$
}sx);


# Confirm nsexpand option works on output

$xml = XMLout($opt, nsexpand => 1);
ok(4, $xml =~ m{
  ^\s*<opt
  \s+xmlns:perl="http://www.perl.com/"
  \s+perl:attr="value"
  \s*>
  \s*<perl:element\s*>data</perl:element\s*>
  \s*</opt>
  \s*$
}sx);


# Check that default namespace is correctly read in ...

$xml = q(<opt xmlns="http://www.orgsoc.org/">
  <list>
    <member>Tom</member>
    <member>Dick</member>
    <member>Larry</member>
  </list>
</opt>
);

$expected = {
  'xmlns' => 'http://www.orgsoc.org/',
  '{http://www.orgsoc.org/}list' => {
    '{http://www.orgsoc.org/}member' => [ 'Tom', 'Dick', 'Larry' ]
  }
};

$opt = XMLin($xml, nsexpand => 1);
ok(5, DataCompare($opt, $expected));


# ... and written out

$xml = XMLout($opt, nsexpand => 1);
ok(6, $xml =~ m{
  ^\s*<opt
  \s+xmlns="http://www.orgsoc.org/"
  \s*>
  \s*<list>
  \s*<member>Tom</member>
  \s*<member>Dick</member>
  \s*<member>Larry</member>
  \s*</list>
  \s*</opt>
  \s*$
}sx);


# Check that the autogeneration of namespaces works as we expect

$opt = {
  'xmlns' => 'http://www.orgsoc.org/',
  '{http://www.orgsoc.org/}list' => {
    '{http://www.orgsoc.org/}member' => [ 'Tom', 'Dick', 'Larry' ],
    '{http://www.phantom.com/}director' => [ 'Bill', 'Ben' ],
  }
};

$xml = XMLout($opt, nsexpand => 1);
ok(7, $xml =~ m{
  ^\s*<opt
  \s+xmlns="http://www.orgsoc.org/"
  \s*>
  \s*<list\s+xmlns:(\w+)="http://www.phantom.com/"\s*>
  \s*<member>Tom</member>
  \s*<member>Dick</member>
  \s*<member>Larry</member>
  \s*<\1:director>Bill</\1:director>
  \s*<\1:director>Ben</\1:director>
  \s*</list>
  \s*</opt>
  \s*$
}sx);


exit(0);

