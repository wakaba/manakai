
=head1 NAME

Message::Entity Perl module

=head1 DESCRIPTION

Perl module for RFC 822/2822 C<message>.
MIME multipart will be also supported (but not implemented yet).

=cut

require 5.6.0;	## (require: v5.6.0 data type)
package Message::Entity;
use strict;
use vars qw(%DEFAULT %REG $VERSION);
$VERSION=do{my @r=(q$Revision: 1.39 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};

require Message::Util;
require Message::Header;
require Message::MIME::MediaType;
require Message::MIME::Encoding;
use overload '""' => sub { $_[0]->stringify },
             fallback => 1;
*REG = \%Message::Util::REG;

## Initialize of this class -- called by constructors
  %DEFAULT = (
    -_METHODS	=> [qw|header body content_type id|],
    -_MEMBERS	=> [qw|header body _cte|],
    	## entity_header -- Don't clone.
    -accept_coderange	=> '7bit',	## 7bit / 8bit / binary
    -body_default_charset	=> 'iso-2022-int-1',
    -body_default_charset_input	=> 'iso-2022-int-1',
    -body_default_media_type	=> 'text',
    -body_default_media_subtype	=> 'plain',
    -cte_default	=> '7bit',
    -fill_missing_fields	=> 1,
    	#add_ua	=> 1,
    	#fill_date	=> 1,
    	-fill_date_name	=> 'date',
    	-fill_destination	=> 0,
    	#fill_destination_ns
    	#fill_destination_resent_ns
    	#fill_from_ns
    	-fill_md5	=> 0,
    	-fill_md5_name	=> 'md5',
    	#fill_msgid	=> 1,
    	-fill_msgid_name	=> 'message-id',
    	#fill_sender_ns
    	-fill_source	=> 0,
    	-recalc_md5	=> 1,
    -force_mime_entity	=> 0,
    -format	=> 'mail-rfc2822',
    -guess_media_type	=> 1,
    #internal_charset_name
    -header_default_charset	=> 'iso-2022-int-1',
    -header_default_charset_input	=> 'iso-2022-int-1',
    -linebreak_strict	=> 0,	## BUG: not work perfectly
    -output_magic_line	=> 1,
    -parse_all	=> 0,
    -remove_post_newline	=> 0,
    -remove_pre_newline	=> 0,
    -text_coderange	=> 'binary',
    	## '8bit' (MIME text/*) / 'binary' (HTTP text/*)
    #ua_field_name	=> 'user-agent',
    -ua_use_Config	=> 1,
    -ua_use_Win32	=> 1,
    -uri_mailto_safe_level	=> 4,
    -use_magic_line	=> 1,
  );
sub _init ($;%) {
  my $self = shift;
  my %options = @_;
  $self->{option} = {};
  my $o = Message::Util::make_clone (\%DEFAULT);
  for my $name (keys %$o) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $$o{$name};
    }
  }
  
  my @new_fields = ();
  for my $name (keys %options) {
    if (substr ($name, 0, 1) eq '-') {
      $self->{option}->{substr ($name, 1)} = $options{$name};
    } elsif ($name eq 'entity_header') {
      $self->{entity_header} = $options{entity_header};
    } else {
      push @new_fields, ($name => $options{$name});
    }
  }
  
  my $format = $self->{option}->{format};
  my $ns822 = $Message::Header::NS_phname2uri{'x-rfc822'};
  my $nshttp = $Message::Header::NS_phname2uri{'x-http'};
  if ($format =~ /http/) {
    $self->{option}->{fill_date_ns} = $nshttp unless defined $options{-fill_date_ns};
    $self->{option}->{fill_from_ns} = $nshttp unless defined $options{-fill_from_ns};
    $self->{option}->{fill_ua_ns}   = $nshttp unless defined $options{-fill_ua_ns};
    $self->{option}->{fill_source} = 0 unless defined $options{-fill_source};
    $self->{option}->{accept_coderange} = 'binary';
    $self->{option}->{text_coderange} = 'binary';
    $self->{option}->{cte_default} = 'binary';
  } else {
    if ($format =~ /mail-rfc822|mail-rfc2822/ && $format !~ /mime-entity/) {
      $self->{option}->{fill_destination} = 1;
      $self->{option}->{fill_source} = 1 unless defined $options{-fill_source};
    }
    $self->{option}->{fill_date_ns} = $ns822 unless defined $options{-fill_date_ns};
    $self->{option}->{fill_from_ns} = $ns822 unless defined $options{-fill_from_ns};
    $self->{option}->{fill_ua_ns}   = $ns822 unless defined $options{-fill_ua_ns};
    $self->{option}->{text_coderange} = '8bit';
    if ($format =~ /news-usefor|smtp-8bitmime/) {
      $self->{option}->{accept_coderange} = '8bit';
    } else {
      $self->{option}->{accept_coderange} = '7bit';
    }
  }
  for (qw/fill_msgid_ns fill_msgid_from fill_mimever_ns fill_destination_ns fill_sender_ns/) {
    $self->{option}->{$_} = $ns822;
  }
  $self->{option}->{fill_destination_resent_ns} = $Message::Header::NS_phname2uri{'x-rfc822-resent'};
  unless (defined $self->{option}->{fill_date}) {
    $self->{option}->{fill_date} = $format !~ /mime-entity|cgi|uri-url-mailto/;
  }
  unless (defined $self->{option}->{fill_msgid}) {
    $self->{option}->{fill_msgid} = $format !~ /mime-entity|http|uri-url-mailto/;
  }
  unless (defined $self->{option}->{fill_ct}) {
    $self->{option}->{fill_ct} = $format !~ /http/;
  }
  unless (defined $self->{option}->{fill_mimever}) {
    $self->{option}->{fill_mimever} = $format !~ /http|mime-entity/;
  }
  unless (defined $self->{option}->{add_ua}) {
    $self->{option}->{add_ua} = $format !~ /mime-entity/;
  }
  unless ($self->{option}->{fill_ua_name}) {
    $self->{option}->{fill_ua_name} = $format =~ /response|cgi|uri-url-mailto/?
      'server': 'user-agent';
  }
  unless (defined $options{-output_magic_line}) {
    $self->{option}->{output_magic_line} = 0
      if $format =~ /mail|news|mime/;
  }
  @new_fields;
}

=head1 CONSTRUCTORS

The following methods construct new C<Message::Entity> objects:

=over 4

=item Message::Entity->new ([%initial-fields/options])

Constructs a new C<Message::Entity> object.  You might pass some initial
C<field-name>-C<field-body> pairs and/or options as parameters to the constructor.

Example:

 $msg = new Message::Entity
        Content_Type => 'text/html',
        X_URI => '<http://www.foo.example/>',
        -format => 'mail-rfc2822'	## not to be header field
        ;

=cut

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  my %new_field = $self->_init (@_);
  if (defined $new_field{body}) {
    $self->{body} = $new_field{body};  $new_field{body} = undef;
    $self->{body} = $self->_parse_value ([$self->content_type] => $self->{body})
      if $self->{option}->{parse_all};
  }
  $self->{header} = new Message::Header
    -format => $self->{option}->{format},
    -header_default_charset	=> $self->{option}->{header_default_charset},
    -header_default_charset_input	=> $self->{option}->{header_default_charset_input},
    -parse_all => $self->{option}->{parse_all}, %new_field;
  $self;
}

=item Message::Entity->parse ($message, [%options])

Parses given C<message> (a message entity) and constructs a new C<Message::Entity>
object.  You might pass some additional C<field-name>-C<field-body> pairs 
or/and initial options as parameters to the constructor.

=cut

sub parse ($$;%) {
  my $class = shift;
  my $message = shift;
  my $self = bless {}, $class;
  my %new_field = $self->_init (@_);
  my $nl = "\x0D\x0A";
  unless ($self->{option}->{linebreak_strict}) {
    $nl = Message::Util::decide_newline ($message);
  }
  my ($hdr, $body);
  $message =~ s/^(?:$nl)+//s if $self->{option}->{remove_pre_newline};
  $message =~ s/(?:$nl)+$/$nl/s if $self->{option}->{remove_post_newline};
  if ($self->{option}->{use_magic_line}) {
    ## TODO: Reset format option?
    if ($message =~ s/>?From (.+?)$nl//gs) {	## Mail from line
      $new_field{'x-rfc822-mail-from'} = $1;
    } elsif ($message =~ s#^($REG{http_token})\x20($REG{S_uri})\x20($REG{http_token})/([0-9]+)\.([0-9]+)$nl##gs) {
    ## HTTP Request
      ($self->{http_method}, $self->{http_request_uri},
      $self->{http_protocol_name}, $self->{http_protocol_version})
        = ($1, $2, uc $3, pack ('U2', $4, $5));
    } elsif ($message =~ s#^($REG{http_token})/([0-9]+)\.([0-9]+)\x20([0-9][0-9][0-9]\x20.*?)$nl##gs) {
    ## HTTP Response
      ($self->{http_protocol_name}, $self->{http_protocol_version})
        = (uc $1, pack ('U2', $2, $3));
      $new_field{'x-http-status'} = $4;
    } elsif ($message =~ s#^($REG{http_token})\x20($REG{S_uri})$nl##gs) {
    ## HTTP/0.9 simple-request
      ($self->{http_method}, $self->{http_request_uri},
      $self->{http_protocol_name}, $self->{http_protocol_version})
        = ($1, $2, 'HTTP', v0.9);
      $message = $nl . $message;	## Has no header fields
    }
  }
  if ($message !~ s/^$nl//s) {
    ($hdr, $body) = split /$nl$nl/, $message, 2;
  } else {
    $hdr = ''; $body = $message;
    $body =~ s/^$nl//s;
  }
  $new_field{body} = undef if $new_field{body};
  	## Is this implemention good?
  $self->{header} = parse Message::Header $hdr,
    -header_default_charset	=> $self->{option}->{header_default_charset},
    -header_default_charset_input	=> $self->{option}->{header_default_charset_input},
    -parse_all => $self->{option}->{parse_all},
    -format => $self->{option}->{format},
    %new_field;	## Additional header fields
  
  $self->{body} = $body;
  $self->{body} = $self->_parse_value ([ $self->content_type ] => $self->{body})
    if $self->{option}->{parse_all};
  $self;
}

=back

=head1 METHODS

=head2 $self->header ([$new_header])

Returns Message::Header unless $new_header.
Set $new_header instead of current C<header>.
If !ref $new_header, Message::Header->parse is automatically
called.

=cut

## TODO: to be compatible with HTTP::Message
sub header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{header} = $new_header;
  } elsif ($new_header) {
    $self->{header} = Message::Header->parse ($new_header,
    -header_default_charset	=> $self->{option}->{header_default_charset},
    -header_default_charset_input	=> $self->{option}->{header_default_charset_input},
      -parse_all => $self->{option}->{parse_all},
      -format => $self->{option}->{format});
  }
  unless (ref $self->{header} || length $self->{header}) {
    $self->{header} = new Message::Header (
    -header_default_charset	=> $self->{option}->{header_default_charset},
    -header_default_charset_input	=> $self->{option}->{header_default_charset_input},
      -parse_all => $self->{option}->{parse_all},
      -format => $self->{option}->{format});
  }
  $self->{header};
}

=head2 $self->body ([$new_body])

Returns C<body> as string unless $new_body.
Set $new_body instead of current C<body>.

=cut

sub body ($;$) {
  my $self = shift;
  my $new_body = shift;
  if ($new_body) {
    $self->{body} = $new_body;
  }
  $self->{body} = $self->_parse_value ([$self->content_type] => $self->{body})
    unless ref $self->{body};
  $self->{body};
}

## [SG]et its entity header.  This method is or can be used
## when Message::Entity is used as a body (such as message/rfc822).
sub entity_header ($;$) {
  my $self = shift;
  my $new_header = shift;
  if (ref $new_header) {
    $self->{entity_header} = $new_header;
  }
  $self->{entity_header};
}

## Note: If you once parse body (including parse_all => 1 option),
##       it might make validation failed.
sub md5_check ($) {
  my $self = shift;
  my $md5f = $self->{header}->field ('content-md5', -new_item_unless_exist => 0);
  my $md5; $md5 = $md5f->value if ref $md5f;
  unless ($md5) {
    Carp::carp "md5_check: MD5 checksum not found";
    return undef;
  }
  my $MD5;
  eval q{
    require Digest::MD5;
    $MD5 = ($self->Message::MIME::Encoding::encode_base64 (Digest::MD5::md5 ($self->{body})))[0];
    $MD5 =~ tr/\x09\x0A\x0D\x20//d;
  1} or Carp::croak $@;
  return $MD5 eq $md5? 1 : 0;
}

## $self->_parse_value ($type, $value);
sub _parse_value ($$$) {
  my $self = shift;
  my ($mt,$mst) = @{ shift(@_) };
  my $value = shift;
  return $value if ref $value;
  
  ## decode
  $value = $self->_decode_body ($value);
  
  my $mt_def = $Message::MIME::MediaType::type{$mt}->{$mst};
  $mt_def = $Message::MIME::MediaType::type{$mt}->{'/default'} unless ref $mt_def;
  $mt_def = $Message::MIME::MediaType::type{'/default'}->{'/default'}
    unless ref $mt_def;
  my $handler = $mt_def->{handler}
    || $Message::MIME::MediaType::type{$mt}->{'/default'}->{handler}
    || $Message::MIME::MediaType::type{'/default'}->{'/default'}->{handler};
    ## Ummmmmm....
  if (ref $handler eq 'CODE') {
    $handler = &$handler ($self, $mt, $mst);
  }
  my $vtype = $handler->[0];
  my %vopt = (
    -format	=> $self->{option}->{format},
    -linebreak_strict	=> $self->{option}->{linebreak_strict},
    -media_type	=> $mt,
    -media_subtype	=> $mst,
    -parse_all	=> $self->{option}->{parse_all},
    -body_default_charset	=> $self->{option}->{body_default_charset},
    -body_default_charset_input	=> $self->{option}->{body_default_charset_input},
    -internal_charset_name	=> $self->{option}->{internal_charset_name},
    entity_header	=> $self->{header},
  );
  ## Media type specified option/parameters
  if (ref $handler->[1] eq 'HASH') {
    for (keys %{$handler->[1]}) {
      $vopt{$_} = ${$handler->[1]}{$_};
    }
  }
  ## Inherited options
  if (ref $handler->[2] eq 'ARRAY') {
    for (@{$handler->[2]}) {
      $vopt{'-'.$_} = $self->{option}->{$_};
    }
  }
  
  if ($vtype eq ':none:') {
    return $value;
  } elsif (defined $value) {
    eval "require $vtype" or Carp::croak qq{<parse>: $vtype: Can't load package: $@};
    return $vtype->parse ($value, %vopt);
  } else {
    eval "require $vtype" or Carp::croak qq{<parse>: $vtype: Can't load package: $@};
    return $vtype->new (%vopt);
  }
}

sub _decode_body ($$) {
  my $self = shift;
  my $value = shift;
  ## MIME CTE
  	my $cte = $self->{_cte} || '';
  	my $ctef = $self->header->field ('content-transfer-encoding',
  	                              -new_item_unless_exist => 0);
  	$cte = $ctef->value if ref $ctef;
  	my $f = $Message::MIME::Encoding::DECODER{$cte};
  	if (ref $f) {
  	  ($value, $cte) = &$f ($self, $value);
  	}
  	$self->{_cte} = $cte;
  $value;
}

sub _encode_body ($$\%) {
  my $self = shift;
  my $value = shift;
  my $option = shift;
  ## MIME CTE
  	my $current_cte = $self->{_cte} || 'binary';
  	my $ctef = $self->{header}->field ('content-transfer-encoding',
  	                              -new_item_unless_exist => 0);
  	my $cte = ''; $cte = lc $ctef->value if ref $ctef;
  	my %enoption;
  	## Get media type of entity body and its accept CTE list
  	  my ($mt,$mst) = $self->content_type;
  	  my $mt_def = $Message::MIME::MediaType::type{$mt}->{$mst};
  	  $mt_def = $Message::MIME::MediaType::type{$mt}->{'/default'}
  	    unless ref $mt_def;
  	  $mt_def = $Message::MIME::MediaType::type{'/default'}->{'/default'}
  	    unless ref $mt_def;
  	  $enoption{mt_is_text} = 1
  	    if $mt eq 'text' || $mt eq 'multipart' || $mt eq 'message';
  	  $enoption{mt_is_text} = 1 if $mt_def->{text_content};
  	  my ($charset, $charset_def) = '';
  	  if ($mt_def->{mime_charset}) {
  	  ## If CT is able to have its charset parameter,
  	    my $ct = $self->{header}->field ('content-type', 
  	                                   -new_item_unless_exist => 0);
  	    $charset = $ct->parameter ('charset') if ref $ct;
  	    if ($charset) {
  	      $charset_def = $Message::MIME::Charset::CHARSET{$charset};
  	    } else {
  	      $charset_def = $Message::MIME::Charset::CHARSET{'*default'};
  	      ## Note: 'encoding_after_encode' option's value is hardcoded.
  	    }
  	  } else {	## Don't have mime style "charset" parameter
  	    $charset_def = {mime_text => 1};
  	  }
  	  $charset_def = {} unless ref $charset_def;	## dummy
  	  #if ($charset_def->{mime_text} != 1) {	## See also Note above
  	  if (Message::MIME::Charset::is_mime_text ($charset || '*default') != 1) {
  	    $enoption{mt_is_text} = 0 if $mt eq 'text';
  	    my $ct = $self->{header}->field ('content-type');
  	    $ct->not_mime_text ($option->{text_coderange} eq 'binary'? 0:1);
  	  }
  	## If accept CTE list is defined,
  	for my $def ($charset_def, $mt_def) {
  	  if (ref $def->{accept_cte} eq 'ARRAY') {
  	    my $f = 1; for (@{$def->{accept_cte}}) {
  	      if ($cte eq $_) {$f = 0; last}
  	    }
  	    if ($f) {	## If CTE is not accepted,
  	      $cte = $def->{accept_cte}->[0];
  	    }
  	  }
  	}
  	if ($current_cte eq 'binary' || ($current_cte && $current_cte ne $cte)) {
  	  my $de = $Message::MIME::Encoding::DECODER{$current_cte};
  	  my $en = $Message::MIME::Encoding::ENCODER{$cte || 'binary'};
  	  if (ref $de && ref $en) {
  	    my ($e, $decoded);
  	    ($decoded, $e) = &$de ($self, $value);
  	    ## Check transparent coderange
  	      my $cr = $self->Message::MIME::Encoding::decide_coderange
  	        ($decoded, \%enoption);
  	      if ($option->{accept_coderange} eq '8bit') {
  	        if ($cr eq 'binary') {
  	          $cte = $charset_def->{cte_7bit_preferred}
  	              || $mt_def->{cte_7bit_preferred} || 'base64';
  	          $en = $Message::MIME::Encoding::ENCODER{$cte};
  	        }
  	      } elsif ($option->{accept_coderange} eq '7bit') {
  	        if ($cr eq 'binary' || $cr eq '8bit') {
  	          $cte = $charset_def->{cte_7bit_preferred}
  	              || $mt_def->{cte_7bit_preferred} || 'base64';
  	          $en = $Message::MIME::Encoding::ENCODER{$cte};
  	          if ($mt eq 'message') {
  	            my $ct = $self->{header}->field ('content-type');
  	            $ct->not_mime_text ($option->{text_coderange} eq 'binary'? 0:1);
  	          }
  	        }
  	      }
  	    if ($e eq 'binary') {
  	      ($value, $e) = &$en ($self, $decoded, \%enoption);
  	      $e = '' if ($e eq $option->{cte_default});
  	      $e = '' if    $e eq '7bit'
  	                 && (   $option->{cte_default} eq '8bit'
  	                     || $option->{cte_default} eq 'binary');
  	      $e = '' if $e eq '8bit' && $option->{cte_default} eq 'binary';
  	      if ($e) {
  	        $ctef = $self->{header}->field ('content-transfer-encoding')
  	           unless ref $ctef;
  	        $ctef->value ($e);
  	      } elsif (ref $ctef) {
  	        $ctef->value ('');
  	      }
  	    } else {
  	      $ctef = $self->{header}->field ('content-transfer-encoding')
  	         unless ref $ctef;
  	      $ctef->value ($current_cte);
  	    }
  	  } else {	## Can't encode by given CTE
  	    $ctef = $self->{header}->field ('content-transfer-encoding')
  	       unless ref $ctef;
  	    $ctef->value ($current_cte);
  	  }
  	}
  	if (ref $ctef && $ctef->value eq '') {
  	  $self->{header}->delete ('content-transfer-encoding');
  	}
  $value;
}

=head2 $self->stringify ([%option])

Returns the C<message> as a string.

=cut

sub stringify ($;%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my ($header, $body, $body0);
  if (ref $self->{body}) {
    $self->{body}->entity_header ($self->{header});
    $body0 = $self->{body}->stringify (-parent_format => $option{format},
      -linebreak_strict => $option{linebreak_strict});
  } else {
    $body0 = $self->{body};
  }
  $body = $self->_encode_body ($body0, \%option);
  if (ref $self->{header}) {
    my $ns_content = $Message::Header::NS_phname2uri{content};
    my $filler;
    $filler = sub {
      my ($hdr, $exist, $hdr_option) = @_;
      ## Date: (RFC 822, HTTP)
      if ($option{fill_date}
         && !$exist->{$option{fill_date_name}.':'.$option{fill_date_ns}}) {
        $hdr->field
          ($option{fill_date_name}, -ns => $option{fill_date_ns})->unix_time (time);
      }
      ## Message-ID: (RFC 822)
      if ($option{fill_msgid}
         && !$exist->{$option{fill_msgid_name}.':'.$option{fill_msgid_ns}}) {
        my $from = $hdr->field
          ('from', -ns => $option{fill_msgid_from_ns}, -new_item_unless_exist => 0);
        $from = $from->addr_spec if ref $from;
        $hdr->field ($option{fill_msgid_name}, -ns => $option{fill_msgid_ns})
            ->generate (addr_spec => $from) if $from;
      }	# fill_msgid
      ## To:, CC:, BCC:, Resent-To:, Resent-Cc:, Resent-Bcc: (RFC 822)
      if ($option{fill_destination}) {
        if ( !$exist->{ 'to:'.$option{fill_destination_ns} }
          && !$exist->{ 'cc:'.$option{fill_destination_ns} }
          && !$exist->{ 'bcc:'.$option{fill_destination_ns} }
          && !$exist->{ 'to:'.$option{fill_destination_resent_ns} }
          && !$exist->{ 'cc:'.$option{fill_destination_resent_ns} }
          && !$exist->{ 'bcc:'.$option{fill_destination_resent_ns} } ) {
          $hdr->add (bcc => '');
        }
      }
      ## From:, Sender:
      if ($option{fill_source}) {
        ## From:
        if (!$exist->{ 'from:'.$option{fill_from_ns} }) {
          $hdr->add (from => 'Unknown source <foo@bar.invalid>',
                     -ns => $option{fill_from_ns});
        ## From: exists, Sender: not exist
        } elsif (!$exist->{ 'sender:'.$option{fill_sender_ns} }) {
          my $from = $hdr->field ('from', -ns => $option{fill_from_ns});
          if ($from->count > 1) {
            $hdr->field ('sender', -ns => $option{fill_sender_ns})
                ->add ($from->item (0, -by => 'index'));
          }
        }
      }
      ## Content-MD5:
      if (($option{fill_md5} && !$exist->{ $option{fill_md5_name} .':'. $ns_content})
        || ($option{recalc_md5} && $exist->{ $option{fill_md5_name} .':'. $ns_content})) {
        my $md5;
        eval q{
          require Digest::MD5;
          $md5 = ($self->Message::MIME::Encoding::encode_base64 (Digest::MD5::md5 ($body0)))[0];
          $md5 =~ tr/\x09\x0A\x0D\x20//d;
        1} or Carp::carp $@;
        if ($md5) {
          my $md5f = $hdr->field ($option{fill_md5_name}, -ns => $ns_content);
          $md5f->value ($md5);
        }
      }
      my $ismime = 0;
      for (keys %$exist) {if (/:$ns_content$/) { $ismime = 1; last }}
      unless ($ismime) {
        $ismime = 1 if $option{force_mime_entity}
                    || $option{fill_md5}
                    || $option{body_default_media_type} ne 'text'
                    || $option{body_default_media_subtype} ne 'plain';
      }
      if ($ismime) {
        ## Content-Type: (MIME, HTTP)
        if ($option{fill_ct} && !$exist->{'type:'.$ns_content}) {
            my $ct = $hdr->field ('type', -ns => $ns_content);
            $ct->media_type ($option{body_default_media_type}.'/'
                            .$option{body_default_media_subtype});
            $ct->replace (Message::MIME::Charset::name_minimumize ($option{body_default_charset} => $body0));
        }
        ## MIME-Version: (MIME)
        if ($option{fill_mimever}
            && !$exist->{'mime-version:'.$option{fill_mimever_ns}}) {
          ## BUG: doesn't support rfc1049, HTTP (ie. non-MIME) content-*: fields
          $hdr->add ('mime-version' => '1.0', 
            -parse => 0, -ns => $option{fill_mimever_ns});
        }
      }	# $ismime
      ## User-Agent: (USEFOR, HTTP)
      if ($option{add_ua}) {
        $hdr->field ($option{fill_ua_name})->add_our_name (
          -use_Config	=> $option{ua_use_Config},
          -use_Win32	=> $option{ua_use_Win32},
          -date	=> q$Date: 2002/12/28 09:10:16 $,
        );
      }
    } if $option{fill_missing_fields};
    
    if ($option{format} =~ /uri-url-mailto/
     && $self->{header}->field_exist ('type', -ns => $ns_content)
     && $option{uri_mailto_safe_level} > 1) {
      $self->{header}->field ('type', -ns => $ns_content)->media_type ('text/plain');
    }
    $header = $self->{header}->stringify (
    	-format => $option{format},
    	-linebreak_strict => $option{linebreak_strict},
    	-uri_mailto_safe_level => $option{uri_mailto_safe_level},
    	($filler? (-hook_stringify_fill_fields	=> $filler) :()),
    );
  } else {
    $header = $self->{header};
    unless ($option{linebreak_strict}) {
      ## bare \x0D and bare \x0A are unsafe
      $header =~ s/\x0D(?=[^\x09\x0A\x20])/\x0D\x20/g;
      $header =~ s/\x0A(?=[^\x09\x20])/\x0A\x20/g;
    }
  }
  if ($option{format} =~ /uri-url-mailto/) {
    if ($option{format} =~ /rfc1738/) {
      my $to = $self->{header}->stringify (-format => $option{format},
        -uri_mailto_safe_level => $option{uri_mailto_safe_level});
      $to? 'mailto:'.$to: '';
    } else {
      my $f = $option{format};  $f =~ s/-mailto/-mailto-to/;
      my $to = $self->{header}->stringify (-format => $f,
        -uri_mailto_safe_level => $option{uri_mailto_safe_level});
      $body =~ s/([^:@+\$A-Za-z0-9\-_.!~*])/sprintf('%%%02X', ord $1)/ge;
      if (length $body) {
        $header .= '&' if $header;
        $header .= 'body='.$body;
      }
      $header = '?'.$header if $header;
      $to||$header? 'mailto:'.$to.$header: '';
    }
  } else {
    ## Magic line (<- named by the author of this module:-)
    my $mline;
    if ($option{use_magic_line} && $option{output_magic_line}) {
      if ($option{format} =~ /mail|news/ && ref $self->{header}) {
        my $mfrom = $self->{header}->field ('mail-from', -new_item_unless_exist=>0);
        $mline = sprintf 'From %s', $mfrom->value if ref $mfrom;
      } elsif ($option{format} =~ /http.+?request/) {
        $mline = sprintf '%s %s %s/%vd', $self->{http_method} || 'GET',
          $self->{http_request_uri} || '/', $self->{http_protocol_name} || 'HTTP',
          $self->{http_protocol_version} || v1.0;
      } elsif ($option{format} =~ /http.+?response/ && ref $self->{header}
            && $option{format} !~ /cgi/) {
        my $s = $self->{header}->field ('x-http-status');
        $mline = sprintf '%s/%vd %s', $self->{http_protocol_name} || 'HTTP',
          $self->{http_protocol_version} || v1.0, $s->value || '200 OK';
      }
    }
    $mline .= "\x0D\x0A" if $mline;
    $mline = '' unless $mline;
    
    $header .= "\x0D\x0A" if $header && $header !~ /\x0D\x0A$/;
    $mline.$header."\x0D\x0A".$body;
  }
}
*as_string = \&stringify;


=head1 SHORTCUT METHOD FOR MESSAGE PROPERTIES

=over 4

=item $self->content_type ([%options])

Returns Internet media type of message body
(aka MIME type, content type).  Only media type
(type/subtype pair) is returned, i.e. no parameter
is returned, if any.  To get such value, or to set
new value, use C<field> method.

Default is C<text/plain>.

Example:

  $msg->field ('Content-Type')->media_type ('text/html');
  print $msg->content_type;	## text/html

=cut

sub content_type ($;%) {
  my $self = shift;
  my $ct = $self->{header}->field ('content-type', -new_item_unless_exist => 0);
  my ($mt, $mst);
  unless (ref $ct) {
    $mt = $self->{option}->{body_default_media_type};
    $mst = $self->{option}->{body_default_media_subtype};
    if ($mt ne 'text' || $mst ne 'plain') {
      $ct = $self->{header}->field ('content-type');
      $ct->media_type_major ($mt);
      $ct->media_type_minor ($mst);
    }
    if ($self->{option}->{guess_media_type} && $self->{body} && !ref $self->{body}
     && $self->{option}->{format} =~ /mail|news/) {
      if ($self->{body} =~ /^-----BEGIN PGP SIGNED MESSAGE-----\x0D?$/m
        && $self->{body} =~ /^-----BEGIN PGP SIGNATURE-----\x0D?$/m
        && $self->{body} =~ /^-----END PGP SIGNATURE-----\x0D?$/m) {
        $ct = $self->{header}->field ('content-type') unless ref $ct;
        $mt = $ct->media_type_major ('text');
        $mst = $ct->media_type_minor ('x-pgp-cleartext-signed');
      } elsif ($self->{body} =~ /^-----BEGIN PGP [A-Z\x20]+-----\x0D?$/m
        && $self->{body} =~ /^-----END PGP [A-Z\x20]+-----\x0D?$/m) {
        $ct = $self->{header}->field ('content-type') unless ref $ct;
        $mt = $ct->media_type_major ('application');
        $mst = $ct->media_type_minor ('pgp');
        $ct->parameter (format => 'text');
      } elsif ($self->{body} =~ /^-+ start of forwarded message \(RFC 934 encapsulation\) -+\x0D?$/m) {
        $ct = $self->{header}->field ('content-type') unless ref $ct;
        $mt = $ct->media_type_major ('text');
        $mst = $ct->media_type_minor ('x-message-rfc934');
      } elsif ($self->{body} =~ /^-{70,70}\x0D?$/m
        && $self->{body} =~ /^-{30,30}\x0D?$/m
        && $self->{body} =~ /\x0D?\x0A-{30,30}\x0D?\x0A\x0D?\x0AEnd of.+?Digest.*?\x0D?\x0A\*+(?:\x0D?\x0A)*$/s) {
        $ct = $self->{header}->field ('content-type') unless ref $ct;
        $mt = $ct->media_type_major ('text');
        $mst = $ct->media_type_minor ('x-message-rfc1153');
      } elsif ($self->{body} =~ /^-----PRIVACY-ENHANCED MESSAGE BOUNDARY-----\x0D?$/m) {
        $ct = $self->{header}->field ('content-type') unless ref $ct;
        $mt = $ct->media_type_major ('text');
        $mst = $ct->media_type_minor ('x-message-pem');
      } elsif ($self->{body} =~ /^#(?:HELO|EHLO)/mi
            && $self->{body} =~ /^#MAIL FROM:/mi
            && $self->{body} !~ /^[^#]/m) {
        ## RFC 976 Batch SMTP (BSMTP) message
        $ct = $self->{header}->field ('content-type') unless ref $ct;
        $mt = $ct->media_type_major ('application');
        $mst = $ct->media_type_minor ('x-batch-smtp');
      }
    }
  } else {
    ($mt, $mst) = ($ct->media_type_major, $ct->media_type_minor);
  }
  if ($self->{option}->{guess_media_type}) {
    if ($mt eq 'text' && $mst eq 'plain') {
      my $mls = $self->{header}->field ('x-mlserver', -new_item_unless_exist => 0);
      if (ref $mls && $mls =~ /fml/) {
        my $s = $self->{header}->field ('subject', -new_item_unless_exist => 0);
        if (index ($s, 'RFC934(mh-burst)') >= 0) {
          $ct = $self->{header}->field ('content-type') unless ref $ct;
          $mt = $ct->media_type_major ('text');
          $mst = $ct->media_type_minor ('x-message-rfc934');
          $ct->delete ('charset');
        } elsif (index ($s, 'Digest (RFC1153)') >= 0) {
          $ct = $self->{header}->field ('content-type') unless ref $ct;
          $mt = $ct->media_type_major ('text');
          $mst = $ct->media_type_minor ('x-message-rfc1153');
          $ct->delete ('charset');
        }
      }
    }
  }
  if (wantarray) {
    ($mt, $mst);
  } else {
    ref $ct ? $ct->media_type : sprintf '%s/%s', $mt, $mst;
  }
}
*media_type = \&content_type;

=item $self->id

Returns ID of message entity.  If there are C<Message-ID:>
field, its value is returned.  Unless, but there are
C<Content-ID:> field, it is returned.  Without both of
fields, C<""> is returned.

=cut

sub id ($) {
  my $self = shift;
  return scalar $self->{header}->field ('message-id')->id
    if $self->{header}->field_exist ('message-id');
  return scalar $self->{header}->field ('content-id')->id
    if $self->{header}->field_exist ('content-id');
  '';
}

sub sender ($;%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  $option{use_x_envelope_from} = 1;	## X-Envelope-From:
  $option{use_normal} = 1;	## From:, Sender:
  $option{use_resent} = 1;	## Resent-From:, Resent-Sender:
  my $hdr = $self->{header};
  if ($option{use_x_envelope_from} && $hdr->field_exist ('x-envelope-from')) {
    return $hdr->field ('x-envelope-from')->addr_spec;
  } elsif ($option{use_resent} && $hdr->field_exist ('resent-sender')) {
    ## TODO: Resent block support
    return $hdr->field ('resent-sender')->addr_spec;
  } elsif ($option{use_resent} && $hdr->field_exist ('resent-from')) {
    ## TODO: Resent block support
    return $hdr->field ('resent-from')->addr_spec;
  } elsif ($option{use_normal} && $hdr->field_exist ('sender')) {
    return $hdr->field ('sender')->addr_spec;
  } elsif ($option{use_normal} && $hdr->field_exist ('from')) {
    return $hdr->field ('from')->addr_spec;
  }
  undef;
}

sub destination ($;%) {
  my $self = shift;
  my %params = @_;
  my %option = %{$self->{option}};
  $option{use_x_envelope_to} = 1;	## X-Envelope-To:
  $option{use_normal} = 1;	## To:, Cc:, Bcc:
  $option{use_resent} = 1;	## Resent-To:, Resent-Cc:, Resent-Bcc:
  for (grep {/^-/} keys %params) {$option{substr ($_, 1)} = $params{$_}}
  my $hdr = $self->{header};
  my @to;
  if ($option{use_x_envelope_to} && $hdr->field_exist ('x-rfc822-x-envelope-to')) {
    @to = $hdr->field ('x-rfc822-x-envelope-to')->addr_spec;
  } elsif ($option{use_resent} && $hdr->field_exist ('x-rfc822-resent-from')) {
    ## TODO: Resent block support
    @to = ($hdr->field ('x-rfc822-resent-to')->addr_spec,
           $hdr->field ('x-rfc822-resent-cc')->addr_spec,
           $hdr->field ('x-rfc822-resent-bcc')->addr_spec);
  } elsif ($option{use_normal}) {
    @to = ($hdr->field ('x-rfc822-to')->addr_spec,
           $hdr->field ('x-rfc822-cc')->addr_spec,
           $hdr->field ('x-rfc822-bcc')->addr_spec);
  }
  @to;
}

sub list_name ($) {
  my $self = shift;
  my $hdr = $self->{header};
  if ($hdr->field_exist ('list-id')) {
    my $lname = $hdr->field ('list-id')->display_name;
    return $lname if length $lname;
  }
  my $v = sub {
    my $name = shift;
    my $f = $hdr->field ($name, -new_item_unless_exist => 0);
    return $f->value if ref $f;
    undef;
  };
  ## BUG: list-name "0" is not supported.
  my $lname = &$v ('x-ml-name') || &$v ('x-mailing-list-name')
           || &$v ('x-mailinglist-name') || &$v ('ml-name');
  return $lname if length $lname;
  if ($hdr->field_exist ('x-sequence')) {
    if ($hdr->field ('x-sequence')->value =~ /^(\S+)\s+\d+$/) {
      return $1;
    }
  }
  if ($hdr->field_exist ('subject')) {
    my $s = $hdr->field ('subject');
    return $s->list_name if $s->method_available ('list_name');
  }
  undef;
}

sub list_count ($) {
  my $self = shift;
  my $hdr = $self->{header};
  my $v = sub {
    my $name = shift;
    my $f = $hdr->field ($name, -new_item_unless_exist => 0);
    return $f->value if ref $f;
    undef;
  };
  ## BUG: list-count 0 is not supported.
  my $lc = &$v ('x-mail-count') || &$v ('x-ml-count') || &$v ('x-mailinglist-id')
           || &$v ('mail-count') || &$v ('x-article-no') || &$v ('x-ml-counter')
           || &$v ('x-ml-id') || &$v ('x-ml-sequence') || &$v ('x-serial-no')
           || &$v ('x-seqno');
  return $lc if $lc;
  if ($hdr->field_exist ('x-sequence')) {
    my $s = $hdr->field ('x-sequence')->value;
    if ($s =~ /^\S+\s+(\d+)$/) {
      return $1;
    } elsif ($s =~ /(\d+)/) {
      return $1;
    }
  }
  if ($hdr->field_exist ('subject')) {
    my $s = $hdr->field ('subject');
    return $s->list_count if $s->method_available ('list_count');
  }
  undef;
}

=back

=head1 MISC. METHODS

=over 4

=item $self->option ( $option-name / $option-name, $option-value, ...)

If @_ == 1, returns option value.  Else...

Set option value.  You can pass multiple option name-value pair
as parameter.  Example:

  $msg->option (format => 'mail-rfc822',
                capitalize => 0);
  print $msg->option ('format');	## mail-rfc822

=cut

sub option ($@) {
  my $self = shift;
  if (@_ == 1) {
    return $self->{option}->{ $_[0] };
  }
  my %option = @_;
  while (my ($name, $value) = splice (@_, 0, 2)) {
    $self->{option}->{$name} = $value;
  }
  if ($option{-recursive} && ($self->content_type)[0] ne 'message') {
    $self->{header}->option (%option);
    $self->{body}->option (%option) if ref $self->{body};
  }
}

=item $self->clone ()

Returns a copy of Message::Entity object.

=cut

sub clone ($) {
  my $self = shift;
  my $clone = new Message::Entity;
  $clone->{option} = Message::Util::make_clone ($self->{option});
  for (@{$self->{option}->{_MEMBERS}}) {
    $clone->{$_} = Message::Util::make_clone ($self->{$_});
  }
  $clone;
}

my %_method_default_list = qw(new 1 parse 1 stringify 1 option 1 clone 1 method_available 1);
sub method_available ($$) {
  my $self = shift;
  my $name = shift;
  return 1 if $_method_default_list{$name};
  for (@{$self->{option}->{_METHODS}}) {
    return 1 if $_ eq $name;
  }
  0;
}

sub import ($;%) {
  my $self = shift;
  my %option = @_;
  for (keys %option) {
    $DEFAULT{$_} = $option{$_};
  }
  if ($option{-body_default_charset} && !$option{-body_default_charset_input}) {
    $DEFAULT{-body_default_charset_input} = $option{-body_default_charset};
  }
  if ($option{-header_default_charset} && !$option{-header_default_charset_input}) {
    $DEFAULT{-header_default_charset_input} = $option{-header_default_charset};
  }
}

=back

=head1 C<format>

=over 2

=item mail-rfc650

Internet mail message, defined by IETF RFC 650

=item mail-rfc724

Internet mail message, defined by IETF RFC 724

=item mail-rfc733

Internet mail message, defined by IETF RFC 733

=item mail-rfc822

Internet mail message, defined by IETF RFC 822

=item mail-rfc822+rfc1123

Internet mail message, defined by IETF RFC 822, ammended by RFC 1123

=item mail-rfc2822

Internet mail message, defined by IETF RFC 2822

=item mime-1.0

MIME entity

=item mime-1.0-rfc1341

MIME entity, defined by RFC 1341 (and RFC 1342)

=item mime-1.0-rfc1521

MIME entity, defined by RFC 1521 and 1522

=item mime-1.0-rfc2045

MIME entity, defined by RFC 2045,..., 2049

=item news-bnews

Usenet Bnews format

=item news-rfc850

Usenet news format, defined by IETF RFC 850

=item news-rfc1036

Usenet news format, defined by IETF RFC 1036

=item news-son-of-rfc1036

Usenet news format, defined by son-of-RFC1036

=item news-usefor

Usenet news format, defined by usefor-article (IETF Internet Draft)

=item http-1.0-rfc1945

HTTP/1.0 message, defined by IETF RFC 1945

=item http-1.0-rfc1945-request

HTTP/1.0 request message, defined by IETF RFC 1945

=item http-1.0-rfc1945-response

HTTP/1.0 response message, defined by IETF RFC 1945

=item http-1.1-rfc2068

HTTP/1.1 message, defined by IETF RFC 2068

=item http-1.1-rfc2068-request

HTTP/1.1 request message, defined by IETF RFC 2068

=item http-1.1-rfc2068-response

HTTP/1.1 response message, defined by IETF RFC 2068

=item http-1.1-rfc2616

HTTP/1.1 message, defined by IETF RFC 2616

=item http-1.1-rfc2616-request

HTTP/1.1 request message, defined by IETF RFC 2616

=item http-1.1-rfc2616-response

HTTP/1.1 response message, defined by IETF RFC 2616

=item http-cgi-1.1

CGI/1.1 output (for HTTP), defined by coar-cgi-v11 (IETF Internet Draft)

=item http-cgi-1.2

CGI/1.2 output, defined by coar-cgi-v12 (to be IETF Internet Draft)

=item http-sip-2.0

SIP/2.0 message, defined by IETF RFC 2543

=item http-sip-2.0-request

SIP/2.0 request message, defined by IETF RFC 2543

=item http-sip-2.0-response

SIP/2.0 response message, defined by IETF RFC 2543

=item http-sip-cgi

SIP/2.0 CGI (IETF Internet Draft)

=item cpim-1.0

CPIM/1.0 (IETF Internet Draft)

=item uri-url-mailto

mailto: URL scheme

=item uri-url-mailto-rfc1738

mailto: URL scheme (defined by RFC 1738)

=item uri-url-mailto-rfc2368

mailto: URL scheme (defined by RFC 2368)

=item uri-url-mailto-to

C<to> part of mailto: URL scheme (for internal use only)

=back

=head1 EXAMPLE

  use Message::Entity;
  my $msg = new Message::Entity From	=> 'foo@example.org',
                                Subject	=> 'Example message',
                                To	=> 'bar@example.net',
                                -format	=> 'mail-rfc2822',
                                body	=> $body;
  $msg->header ($header);
  $msg->body ($body);
  print $msg;

=head1 SEE ALSO

Message::* Perl modules
<http://suika.fam.cx/~wakaba/Message-pm/>

=head1 LICENSE

Copyright 2002 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=head1 CHANGE

See F<ChangeLog>.
$Date: 2002/12/28 09:10:16 $

=cut

1;
