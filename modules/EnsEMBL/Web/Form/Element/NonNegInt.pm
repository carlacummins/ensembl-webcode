package EnsEMBL::Web::Form::Element::NonNegInt;

use EnsEMBL::Web::Form::Element::String;
our @ISA = qw( EnsEMBL::Web::Form::Element::String );

sub new { my $class = shift; return $class->SUPER::new( @_, 'style' => 'short' ); }

sub _is_valid { return $_[0]->value =~ /^[+-]?\d+$/ &&  $_[0]->value>0; }

sub _class { return '_nonnegint'; }
1;
