# $Id$

use strict;

use File::Spec;
use IO::File;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');

  eval { require XML::SAX; };
  if($@) {
    print STDERR "no XML::SAX...";
    print "1..0\n";
    exit 0;
  }
}

use TagsToUpper;

# Initialise filenames and check they're there

my $SrcFile   = File::Spec->catfile('t', 'desertnet.src');
my $XMLFile   = File::Spec->catfile('t', 'desertnet.xml');
my $CacheFile = File::Spec->catfile('t', 'desertnet.stor');

unless(-e $SrcFile) {
  print STDERR "test data missing...";
  print "1..0\n";
  exit 0;
}

print "1..13\n";

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

# Initialise test data

my $Expected  = {
  'server' => {
		'sahara' => {
			      'osversion' => '2.6',
			      'osname' => 'solaris',
			      'address' => [
					     '10.0.0.101',
					     '10.0.1.101'
					   ]
			    },
		'gobi' => {
			    'osversion' => '6.5',
			    'osname' => 'irix',
			    'address' => '10.0.0.102'
			  },
		'kalahari' => {
				'osversion' => '2.0.34',
				'osname' => 'linux',
				'address' => [
					       '10.0.0.103',
					       '10.0.1.103'
					     ]
			      }
	      }
};

my $xml = '';


# Force default behaviour of using SAX parser if it is available (which it
# is or we wouldn't be here).

$XML::Simple::PREFERRED_PARSER = '';

ok(1, CopyFile($SrcFile, $XMLFile));  # Start with known source file
unlink($CacheFile);                   # Ensure there are ...
ok(2, ! -e $CacheFile);               # ... no cache files lying around

# Pass in a filename to check parse_uri()

my $opt = XMLin($XMLFile);
ok(3, DataCompare($opt, $Expected));  # Got what we expected


# Pass in an IO::File object to test parse_file()

my $fh = IO::File->new("<$XMLFile");
ok(4, ref($fh));
$opt = XMLin($fh);
ok(5, DataCompare($opt, $Expected));  # Got what we expected
$fh->close();


# Pass in a string to test parse_string()

if(open(XMLFILE, "<$XMLFile")) {
  local($/) = undef;
  $xml = <XMLFILE>;
  close(XMLFILE);
}
$opt = XMLin($xml);
ok(6, DataCompare($opt, $Expected));  # Got what we expected
  

# Pass in '-' for STDIN

open(OLDSTDIN, "<&STDIN");
close(STDIN);
open(STDIN, "<$XMLFile");
$opt = XMLin('-');
ok(7, DataCompare($opt, $Expected));  # Got what we expected

open(STDIN, "<&OLDSTDIN");
close(OLDSTDIN);


# Try using XML:Simple object as a SAX handler

my $simple = XML::Simple->new();
my $parser = XML::SAX::ParserFactory->parser(Handler => $simple);

$opt = $parser->parse_uri($XMLFile);
ok(8, DataCompare($opt, $Expected));  # Got what we expected


# Try again but make sure options from the constructor are being used

$simple = XML::Simple->new(
  keyattr    => { server => 'osname' },
  forcearray => ['address'],
);
$parser = XML::SAX::ParserFactory->parser(Handler => $simple);

$opt = $parser->parse_uri($XMLFile);
my $Expected2 = {
  'server' => {
		'irix' => {
			    'address' => [ '10.0.0.102' ],
			    'osversion' => '6.5',
			    'name' => 'gobi'
			  },
		'solaris' => {
			       'address' => [ '10.0.0.101', '10.0.1.101' ],
			       'osversion' => '2.6',
			       'name' => 'sahara'
			     },
		'linux' => {
			     'address' => [ '10.0.0.103', '10.0.1.103' ],
			     'osversion' => '2.0.34',
			     'name' => 'kalahari'
			   }
	      }
};

ok(9, DataCompare($opt, $Expected2));  # Got what we expected


# Try using XML::Simple to drive a SAX pipeline

my $Expected3  = {
  'SERVER' => {
		'sahara' => {
			      'OSVERSION' => '2.6',
			      'OSNAME' => 'solaris',
			      'ADDRESS' => [
					     '10.0.0.101',
					     '10.0.1.101'
					   ]
			    },
		'gobi' => {
			    'OSVERSION' => '6.5',
			    'OSNAME' => 'irix',
			    'ADDRESS' => '10.0.0.102'
			  },
		'kalahari' => {
				'OSVERSION' => '2.0.34',
				'OSNAME' => 'linux',
				'ADDRESS' => [
					       '10.0.0.103',
					       '10.0.1.103'
					     ]
			      }
	      }
};
my $simple2 = XML::Simple->new(keyattr => [qw(NAME)]);
my $filter = TagsToUpper->new(Handler => $simple2);

my $opt2 = XMLout($opt,
  keyattr    => { server => 'osname' },
  Handler    => $filter,
);
ok(10, DataCompare($opt2, $Expected3));  # Got what we expected


# Confirm that 'handler' is a synonym for 'Handler'

$simple2 = XML::Simple->new(keyattr => [qw(NAME)]);
$filter = TagsToUpper->new(Handler => $simple2);
$opt2 = XMLout($opt,
  keyattr    => { server => 'osname' },
  handler    => $filter,
);
ok(11, DataCompare($opt2, $Expected3));  # Got what we expected


# Confirm that DataHandler routine gets called

$xml = q(<opt><anon>one</anon><anon>two</anon><anon>three</anon></opt>);
$simple = XML::Simple->new(
  DataHandler => sub {
		   my $xs = shift;
		   my $data = shift;
		   return(join(',', @$data));
		 }
);
$parser = XML::SAX::ParserFactory->parser(Handler => $simple);
my $result = $parser->parse_string($xml);

ok(12, $result, 'one,two,three');


# Confirm that 'datahandler' is a synonym for 'DataHandler'

$simple = XML::Simple->new(
  datahandler => sub {
		   my $xs = shift;
		   my $data = shift;
		   return(join(',', reverse(@$data)));
		 }
);
$parser = XML::SAX::ParserFactory->parser(Handler => $simple);
$result = $parser->parse_string($xml);

ok(13, $result, 'three,two,one');


# Clean up and go

unlink($CacheFile);
unlink($XMLFile);
exit(0);

