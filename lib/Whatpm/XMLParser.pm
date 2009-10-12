package Whatpm::XMLParser;

## Just a wrapper for XMLParserTemp for now.

sub parse_string ($$$;$) {
  require Encode;
  my $s = Encode::encode ('utf8', $_[1]);
  open my $fh, '<', \$s;
  return $_[0]->parse_byte_stream ($fh => $_[2], $_[3], charset => 'utf8');
} # parse_string

sub parse_byte_stream ($$$;$%) {
  my $onerror = $_[3] || sub { };
  my %opt = @_[4..$#$_];
  require Message::DOM::XMLParserTemp;
  return Message::DOM::XMLParserTemp->parse_byte_stream
      ($_[1] => $_[2]->implementation, $onerror,
       charset => $opt{charset});
} # parse_byte_stream

1;
## $Date: 2007/08/11 07:19:18 $
