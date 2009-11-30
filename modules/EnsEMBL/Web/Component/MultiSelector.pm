package EnsEMBL::Web::Component::MultiSelector;

use strict;
use warnings;
no warnings 'uninitialized';

use CGI qw(escapeHTML);

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  
  $self->cacheable(0);
  $self->ajaxable(0);
  
  $self->{'panel_type'} = 'MultiSelector'; # Default value - can be overridden in child _init function. Determines javascript Ensembl.panel type
  $self->{'url_param'}  = ''; # This MUST be implemented in the child _init function - it is the name of the parameter you want for the URL, eg if you want to add parameters s1, s2, s3..., $self->{'url_param'} = 's'
}

sub content {
  my $self = shift;
  
  my $object = $self->object;
  my $url    = $self->ajax_url('ajax') . ';no_wrap=1';
  
  return sprintf('
    <div class="autocenter navbar" style="width:%spx; text-align: left; clear: both">
      <a class="modal_link" href="%s">%s</a>
    </div>',
    $self->image_width,
    $url,
    $self->{'link_text'}
  );
}

sub content_ajax {
  my $self     = shift;
  my $object   = $self->object;
  my %all      = %{$self->{'all_options'}};       # Set in child content_ajax function - complete list of options in the form { URL param value => display label }
  my %included = %{$self->{'included_options'}};  # Set in child content_ajax function - List of options currently set in URL in the form { url param value => 1 }
  my $url      = $object->_url({ function => undef, align => $object->param('align') }, 1);
  my ($include_list, $exclude_list, $extra_inputs);
  
  $extra_inputs .= sprintf '<input type="hidden" name="%s" value="%s" />', escapeHTML($_), escapeHTML($url->[1]{$_}) for sort keys %{$url->[1]};
  $include_list .= sprintf '<li class="%s"><span>%s</span><span class="switch"></span></li>', $_, $all{$_} for sort { $included{$a} <=> $included{$b} } keys %included;
  $exclude_list .= sprintf '<li class="%s"><span>%s</span><span class="switch"></span></li>', $_, $all{$_} for sort { $all{$a} cmp $all{$b} } grep !$included{$_}, keys %all;
  
  my $content = sprintf('
    <div class="content">
      <form action="%s" method="get">%s</form>
      <div class="multi_selector_list">
        <h2>%s</h2>
        <ul class="included">
          %s
        </ul>
      </div>
      <div class="multi_selector_list">
        <h2>%s</h2>
        <ul class="excluded">
          %s
        </ul>
      </div>
      <p class="invisible">.</p>
    </div>',
    $url->[0],
    $extra_inputs,
    $self->{'included_header'}, # Set in child _init function
    $include_list,
    $self->{'excluded_header'}, # Set in child _init function
    $exclude_list,
  );
  
  $content =~ s/\n//g;
  
  return qq{{'content':'$content','panelType':'$self->{'panel_type'}','wrapper':'<div class="panel modal_wrapper"></div>','nav':'','urlParam':'$self->{'url_param'}'}};
}

1;
