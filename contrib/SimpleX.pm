package Net::IMAP::SimpleX;

use strict;
use warnings;
use Parse::RecDescent;
use base 'Net::IMAP::Simple';

# directly from http://tools.ietf.org/html/rfc3501#section-9
# try and flatten, format as best we can
our $body_grammar = q {
body:                 body_type_mpart | body_type_1part
                      { $return = $item[1]; }
body_type_mpart:    '('body(s) subtype')'
                    { $return = {
                        parts => $item[2],
                        type  => $item{subtype}
                      };
                    }
body_type_1part:    body_type_basic | body_type_text
body_type_basic:    '('media_type body_fields')'
                    { $return = {
                        content_type => $item{media_type},
                        %{$item{body_fields}}
                      };
                    }
body_type_text:     '('media_type body_fields number')'
                    { $return = {
                      content_type  => $item{media_type},
                      %{$item{body_fields}},
                    }}
body_fields:        body_field_param body_field_id body_field_desc body_field_enc body_field_octets
                    { $return = {
                        id                  => $item{body_field_id},
                        content_description => $item{body_field_desc},
                        encoding            => $item{body_field_enc},
                        encoded_size        => $item{body_field_octets},
                        $item{body_field_param} ? %{$item{body_field_param}} : ()
                      };
                    }
body_field_id:      nil | word
body_field_desc:    nil | word
body_field_enc:     word
body_field_octets:  number
body_field_param:   body_field_param_simple | body_field_param_ext | nil
body_field_param_ext:   '('word word word word')'
                    { $return = { $item[2] => $item[3], $item[4] => $item[5] }; }
body_field_param_simple:   '('word word')'
                    { $return = { $item[2] => $item[3] }; }
body_field_param:   nil
media_type:         type subtype
                    { $return = "$item{type}/$item{subtype}"; }
type:               word
subtype:            word
nil:                'NIL'
                    {$return = '';}
number:             /\d+/
key:                word
value:              word
word:               /[^\s\)\(]+/
                    { $item[1] =~ s/\"//g; $return = $item[1];}
};


sub new {
    my $class = shift;
    if (my $self = $class->SUPER::new(@_)) {
        $self->{__body_parser} = Parse::RecDescent->new($body_grammar);
        return $self;
    }
}

sub __id_parts {
    my $data  = shift;
    my $pre   = shift;
    $pre = $pre ? "$pre." : '';

    my $id = 1;
    if (my $parts = $data->{parts}) {
        for my $sub (@$parts){
          __id_parts($sub,"$pre$id") if $sub->{parts};
          $sub->{part_number} = "$pre$id";
          $id++;
        }
    } else {
        $data->{part_number} = $id;
    }
}

sub body_summary {
    my ($self, $number) = @_;

    my $body_parts;

    return $self->_process_cmd(
        cmd => [ 'FETCH' => qq[$number BODY] ],
        final => sub { $body_parts; },
        process => sub { if ($_[0] =~ m/\(BODY\s+(.*?)\)\s*$/i) {
          $body_parts = $self->{__body_parser}->body($1);
          __id_parts($body_parts);
        }},
    );
}

1;
