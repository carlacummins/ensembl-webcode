=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::VRenderer::png;
use strict;
use base qw(Bio::EnsEMBL::VRenderer::gif);

sub canvas {
  my ($self, $canvas) = @_;
  if(defined $canvas) {
    $self->{'canvas'} = $canvas;
  } else {
    return $self->{'canvas'}->png();
  }
}

sub init_canvas {
  my ($self, $config, $im_width, $im_height) = @_;
  $self->{'im_width'}  = $im_width;
  $self->{'im_height'} = $im_height;

  my $canvas = GD::Image->newTrueColor($self->{sf} * $im_height, $self->{sf} * $im_width);

  my $ST = $self->{'config'}->species_defs->ENSEMBL_STYLE;
  $self->{'ttf_path'} = "/usr/local/share/fonts/ttfonts/";
  $self->{'ttf_path'} = $ST->{'GRAPHIC_TTF_PATH'} if $ST && $ST->{'GRAPHIC_TTF_PATH'};

  $self->canvas($canvas);
  my $bgcolor = $self->colour($config->bgcolor);
  $self->{'canvas'}->filledRectangle(0,0, $self->{sf} * $im_height, $self->{sf} * $im_width, $bgcolor );

  $self->{'config'}->species_defs->timer_push( "CANVAS INIT", 1, 'draw' );
}

1;
