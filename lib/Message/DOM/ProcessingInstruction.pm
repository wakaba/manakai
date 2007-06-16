package Message::DOM::ProcessingInstruction;
use strict;
our $VERSION=do{my @r=(q$Revision: 1.4 $=~/\d+/g);sprintf "%d."."%02d" x $#r,@r};
push our @ISA, 'Message::DOM::Node', 'Message::IF::ProcessingInstruction';
require Message::DOM::Node;

sub ____new ($$$$) {
  my $self = shift->SUPER::____new (shift);
  ($$self->{target}, $$self->{data}) = @_;
  return $self;
} # ____new
             
sub AUTOLOAD {
  my $method_name = our $AUTOLOAD;
  $method_name =~ s/.*:://;
  return if $method_name eq 'DESTROY';

  if ({
    ## Read-only attributes (trivial accessors)
    target => 1,
    data => 1,
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        if (\@_ > 1) {
          require Carp;
          Carp::croak (qq<Can't modify read-only attribute>);
        }
        return \${\$_[0]}->{$method_name}; 
      }
    };
    goto &{ $AUTOLOAD };
  } elsif ({
    ## Read-write attributes (DOMString, trivial accessors)
  }->{$method_name}) {
    no strict 'refs';
    eval qq{
      sub $method_name (\$) {
        if (\@_ > 1) {
          \${\$_[0]}->{$method_name} = ''.$_[1];
        }
        return \${\$_[0]}->{$method_name}; 
      }
    };
    goto &{ $AUTOLOAD };
  } else {
    require Carp;
    Carp::croak (qq<Can't locate method "$AUTOLOAD">);
  }
} # AUTOLOAD
sub target ($);
sub data ($);

## The |Node| interface - attribute

sub child_nodes ($) {
  require Message::DOM::NodeList;
  return bless \\($_[0]), 'Message::DOM::NodeList::EmptyNodeList';
} # child_nodes

## The target of the processing instruction [DOM1, DOM2].
## Same as |ProcessingInstruction.target| [DOM3].

*node_name = \&target;

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-111237558>

sub node_type ($) { 7 } # PROCESSING_INSTRUCTION_NODE

## The entire content exclude the target [DOM1, DOM2].
## Same as |ProcessingInstruction.data| [DOM3].

*node_value = \&data;

*text_content = \&node_value;

package Message::IF::ProcessingInstruction;

package Message::DOM::Document;

## Spec:
## <http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-135944439>
## Compatibility note:
## <http://suika.fam.cx/gate/2005/sw/createProcessingInstruction>

sub create_processing_instruction ($$$) {
  return Message::DOM::ProcessingInstruction->____new (@_[0, 1, 2]);
} # create_processing_instruction

1;
## License: <http://suika.fam.cx/~wakaba/archive/2004/8/18/license#Perl+MPL>
## $Date: 2007/06/16 15:27:45 $
