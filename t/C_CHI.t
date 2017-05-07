
use strict;
use warnings;
use Test::More;
use File::Spec;


eval { require Storable; };
eval { require CHI; };
unless($INC{'Storable.pm'}) {
  plan skip_all => 'no Storable.pm';
}
unless($INC{'CHI.pm'}) {
  plan skip_all => 'no CHI.pm';
}

# Initialise filenames and check they're there

my $SrcFile   = File::Spec->catfile('t', 'desertnet.src');
my $XMLFile   = File::Spec->catfile('t', 'desertnet5.xml');

unless(-e $SrcFile) {
  plan skip_all => 'test data missing';
}

# Make sure we can write to the filesystem and check it uses the same
# clock as the machine we're running on.

my $t0 = time();
unless(open(XML, '>', $XMLFile)) {
  plan skip_all => "can't create test file '$XMLFile': $!";
}
close(XML);
my $t1 = (stat($XMLFile))[9];
my $t2 = time();

if($t1 < $t0  or  $t2 < $t1) {
  plan skip_all => 'time moved backwards!'
}

plan tests => 10;

##############################################################################
#                   S U P P O R T   R O U T I N E S
##############################################################################

##############################################################################
# Copy a file
#

sub CopyFile {
  my($src, $dst) = @_;

  open(my $in, $src) or die "open(<$src): $!";
  local($/) = undef;
  my $data = <$in>;
  close($in);

  open(my $out, '>', $dst) or die "open(>$dst): $!";
  print $out $data;
  close($out);

  return(1);
}


##############################################################################
# Wait until the current time is greater than the supplied value
#

sub PassTime {
  my($Target) = @_;

  while(time <= $Target) {
    sleep 1;
  }
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

 
my @options = (
  forcearray => 0,
  keyattr    => ['name', 'key', 'id'],
);

ok(CopyFile($SrcFile, $XMLFile), 'copied source XML file');
$t0 = (stat($XMLFile))[9];         # Remember its timestamp

# Initialize cache
my $chi = CHI->new( driver => 'Memory', global => 0 );

                                   # Parse it with caching enabled
my $opt = XMLin($XMLFile, cache => $chi, @options);
is_deeply($opt, $Expected, 'parsed expected data through the cache');

if ('VMS' eq $^O) {
  1 while (unlink($XMLFile));
} else {
  unlink($XMLFile);
}
ok(! -e $XMLFile, 'deleted the source XML file');
open(FILE, ">$XMLFile");              # Re-create it (empty)
close(FILE);
$t1 = $t0 - 1;
eval { utime($t1, $t1, $XMLFile); };   # but wind back the clock
$t2 = (stat($XMLFile))[9];         # Skip these tests if that didn't work
SKIP: {
  skip 'no utime', 2 if($t2 >= $t0);

  $opt = XMLin($XMLFile, cache => $chi, @options);
  is_deeply($opt, $Expected, 'got what we expected from the cache');
  is(-s $XMLFile, 0, 'even though the source XML file is empty');
}


PassTime(time());                     # Ensure source file will be newer
open(FILE, ">$XMLFile");              # Write some new data to the XML file
print FILE qq(<opt one="1" two="2"></opt>\n);
close(FILE);
PassTime(time());                     # Ensure current time later than file time


                                      # Parse again with caching enabled
$opt = XMLin($XMLFile, cache => $chi, @options);
is_deeply($opt, { one => 1, two => 2}, 'parsed expected data through cache');

$opt->{three} = 3;                    # Alter the returned structure
                                      # Retrieve again from the cache
my $opt2 = XMLin($XMLFile, cache => $chi, @options);

ok(!defined($opt2->{three}), 'cache not modified');

{
  no warnings;
  my $opt3 = XMLin($XMLFile, cache => $chi, @options, normalisespace => 1);
  is_deeply(
    $opt2,
    $opt3,
    "different but unimportant options still parse w/o strictmode"
  );
}


{
  no warnings;
  my $opt3 = XMLin($XMLFile, cache => $chi, @options, keeproot => 1);
  is(
    join(' ', (sort keys %$opt3)),
    'opt',
    "different but important options don't use bad data w/o strictmode"
  );
}

my $val = eval {
  XMLin($XMLFile, cache => $chi, @options, strictmode => 1);
  1;
};

is( $val, undef, 'different options cause death properly in strictmode' );

# Clean up and go

unlink($XMLFile);
exit(0);

# Set up VIM for people using modelines
# vim: et sts=2 sw=2
