=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ImageConfig::gene_summary;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ImageConfig);

sub init_cacheable {
  ## @override
  my $self  = shift;
  my $sd    = $self->hub->species_defs;

  $self->SUPER::init_cacheable(@_);

  $self->set_parameters({
    'image_resizeable'  => 1,
    'sortable_tracks'   => 'drag', # allow the user to reorder tracks
    'opt_lines'         => 1, # draw registry lines
  });

  $self->create_menus(qw(
    sequence
    transcript
    rnaseq
    prediction
    variation
    somatic
    functional
    external_data
    user_data
    other
    information
  ));

  if (my $gencode_version = $sd->GENCODE_VERSION || "") {
    $self->add_track('transcript', 'gencode', "Basic Gene Annotations from $gencode_version", '_gencode', {
      labelcaption  => "Genes (Basic set from $gencode_version)",
      display       => 'off',
      description   => 'The GENCODE set is the gene set for human and mouse. GENCODE Basic is a subset of representative transcripts (splice variants).',
      sortable      => 1,
      colours       => $self->species_defs->colour('gene'),
      label_key     => '[biotype]',
      logic_names   => ['proj_ensembl',  'proj_ncrna', 'proj_havana_ig_gene', 'havana_ig_gene', 'ensembl_havana_ig_gene', 'proj_ensembl_havana_lincrna', 'proj_havana', 'ensembl', 'mt_genbank_import', 'ensembl_havana_lincrna', 'proj_ensembl_havana_ig_gene', 'ncrna', 'assembly_patch_ensembl', 'ensembl_havana_gene', 'ensembl_lincrna', 'proj_ensembl_havana_gene', 'havana'],
      renderers     =>  [
        'off',                     'Off',
        'gene_nolabel',            'No exon structure without labels',
        'gene_label',              'No exon structure with labels',
        'transcript_nolabel',      'Expanded without labels',
        'transcript_label',        'Expanded with labels',
        'collapsed_nolabel',       'Collapsed without labels',
        'collapsed_label',         'Collapsed with labels',
        'transcript_label_coding', 'Coding transcripts only (in coding genes)',
      ],
    });
  }

  $self->add_tracks('other',
    [ 'scalebar',  '', 'scalebar',  { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',     { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable', { display => 'normal', strand => 'b', menu => 'no' }],
  );

  $self->add_tracks('information',
    [ 'missing', '', 'text', { display => 'normal', strand => 'r', name => 'Disabled track summary', description => 'Show counts of number of tracks turned off by the user' }],
    [ 'info',    '', 'text', { display => 'normal', strand => 'r', name => 'Information',            description => 'Details of the region shown in the image' }]
  );

  $self->add_tracks('sequence',
    [ 'contig', 'Contigs',  'contig', { display => 'normal', strand => 'r' }]
  );

  $self->load_tracks;

  $self->modify_configs(
    [ 'fg_regulatory_features_funcgen', 'transcript', 'prediction', 'variation' ],
    { display => 'off' }
  );

  $self->modify_configs(	
    [ 'transcript_core_ensembl', 'transcript_core_sg' ],
    { display => 'transcript_label' }
  );
}

1;
