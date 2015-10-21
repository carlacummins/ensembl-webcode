=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Draw::GlyphSet::bigwig;

### Module for drawing data in BigWIG format (either user-attached, or
### internally configured via an ini file or database record

use strict;

use EnsEMBL::Web::IOWrapper::Indexed;

use parent qw(EnsEMBL::Draw::GlyphSet::UserData);

sub can_json { return 1; }

sub features {
  my $self      = shift;
  my $hub       = $self->{'config'}->hub;
  my $url       = $self->my_config('url');
  my $container = $self->{'container'};
  my $args      = {'options' => {'hub' => $hub}};

  my $iow = EnsEMBL::Web::IOWrapper::Indexed::open($url, 'BigWig', $args);
  my $data;

  if ($iow) {
    ## Parse the file, filtering on the current slice
    $data = $iow->create_tracks($container);

    ## Override colourset based on format here, because we only want to have to do this in one place
    my $colourset   = $iow->colourset || 'userdata';
    $self->{'my_config'}->set('colours', $hub->species_defs->colour($colourset));
    $self->{'my_config'}->set('default_colour', $self->my_colour('default'));
  } else {
    #return $self->errorTrack(sprintf 'Could not read file %s', $self->my_config('caption'));
    warn "!!! ERROR CREATING PARSER FOR BIGBED FORMAT";
  }
  #$self->{'config'}->add_to_legend($legend);

  return $data;
}

sub render_text {
  my ($self, $wiggle) = @_;
  warn 'No text render implemented for bigwig';
  return '';
}

1;
