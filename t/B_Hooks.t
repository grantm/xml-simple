# $Id$
# vim: syntax=perl

use strict;
use Test::More;

plan tests => 4;

use_ok('XML::Simple');

SKIP: {
  eval { require Tie::IxHash };

  skip "Tie::IxHash not installed", 3 if $@;

  $@ = '';
  eval <<'EOF';

    package SimpleOrder;

    use base qw(XML::Simple);
    use Tie::IxHash;

    sub new_hashref {
      my $self = shift;
      my %hash;
      tie %hash, 'Tie::IxHash', @_;
      return \%hash;
    }
EOF
  ok(!$@, 'no errors processing SimpleOrder');

  my $xs = SimpleOrder->new;
  my $xml = q{
    <nums>
      <num id="one">I</num>
      <num id="two">II</num>
      <num id="three">III</num>
      <num id="four">IV</num>
      <num id="five">V</num>
      <num id="six">VI</num>
      <num id="seven">VII</num>
    </nums>
  };
  my $expected = {
    'one'   => { 'content' => 'I'   },
    'two'   => { 'content' => 'II'  },
    'three' => { 'content' => 'III' },
    'four'  => { 'content' => 'IV'  },
    'five'  => { 'content' => 'V'   },
    'six'   => { 'content' => 'VI'  },
    'seven' => { 'content' => 'VII' },
  };

  my $data = $xs->xml_in($xml);

  is_deeply($data->{num}, $expected, 'hash content looks good');

  is_deeply(
    [ keys %{$data->{num}} ],
    [ qw(one two three four five six seven) ],
    'order of the hash keys looks good too'
  );

}

exit 0;
