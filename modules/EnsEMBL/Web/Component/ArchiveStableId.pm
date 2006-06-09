package EnsEMBL::Web::Component::ArchiveStableId;

=head1 LICENCE

This code is distributed under an Apache style licence:
Please see http://www.ensembl.org/code_licence.html for details

=head1 CONTACT

Fiona Cunningham <webmaster@sanger.ac.uk>

=cut

use EnsEMBL::Web::Component;
our @ISA = qw( EnsEMBL::Web::Component);
use strict;
use warnings;
no warnings "uninitialized";
use POSIX qw(floor ceil);
use CGI qw(escapeHTML);

# General info table #########################################################

=head2 name

 Arg1        : panel
 Arg2        : data object
 Example     : $panel1->add_rows(qw(name   EnsEMBL::Web::Component::SNP::name) );
 Description : adds a label and the variation name, source to the panel
 Return type : 1

=cut

sub name {
  my($panel, $object) = @_;
  my $label  = 'Stable ID';
  my $id = $object->stable_id;
  my $param = $object->type eq 'Translation' ? 'peptide' : lc($object->type);
  my $name = _archive_link($object, $id, $param, $id) || $id;
  $panel->add_row( $label, $object->type.": ".$name );
  return 1;
}


sub db_name {
  my($panel, $object) = @_;
  my $label  = 'Status';
  my $current_release = $object->species_defs->ENSEMBL_VERSION;
  my $release  = $object->release;

  my $status;
  if ($release == $current_release) {
    $status = "Current v$release";
  }
  elsif ($current_release > $release) {
    $status = "<b>This ID has been removed from the current version of Ensembl</b>.<br />Archived in release $release";
  }
  else {
    $status = "Data error: release $release";
  }

  my $assembly = $object->assembly;
  $status .= " ($assembly)<br />Database: ".$object->db_name;
  $panel->add_row( $label, $status );
  return 1;
}

sub transcript {
  my($panel, $object) = @_;
  my $label  = 'Related transcripts';
  my @ids   = @{ $object->transcript || []};
  return  $panel->add_row( $label, "Unknown") unless scalar @ids;
  my $html;
  foreach (@ids) {
    $html .= "<p>".$_->stable_id;
    $html .= "</p>";
  }
  $panel->add_row( $label, $html);
  return 1;
}

sub peptide {
  my($panel, $object) = @_;
  my $label  = 'Related peptides';
  my @ids   = @{ $object->peptide || []};
  return  $panel->add_row( $label, "Unknown") unless scalar @ids;

  my $html;
  foreach (@ids) {
    $html .= "<p>".$_->stable_id;
    $html .= " <kbd>".$_->get_peptide."</kbd></p>";
  }
  $panel->add_row( $label, $html);
  return 1;
}


sub history {
  my($panel, $object) = @_;
  my $history;
  foreach my $arch_id ( @{ $object->history} ) {
    push @{ $history->{$arch_id->release} }, $arch_id;
  }
  my $dbnames = $object->dbnames;
  return unless keys %$history;

  $panel->add_columns(
    { 'key' => 'Release',  },
    { 'key' => 'Assembly',  },
    { 'key' => 'Database', },
		     );

  my %columns;
  my $type = $object->type;
  my $param = $type eq 'Translation' ? "peptide" : lc($type);

  my @releases = (sort { $b <=> $a } keys %$history);
  # loop over releases and print results
  for (my $i =0; $i < $#releases; $i++) {
    my $row;

    if ( $releases[$i]-$releases[$i+1] == 1) {
      $row->{Release} = "v$releases[$i]";
    }
    else {
      my $start = $releases[$i+1] +1;
      $row->{Release} = "v$releases[$i]-$start";
    }

    $row->{Database} = $history->{$releases[$i]}->[0]->db_name;
    $row->{Assembly} = $history->{$releases[$i]}->[0]->assembly;

    # loop over archive ids
    foreach my $a (sort {$a->stable_id cmp $b->stable_id} @{ $history->{$releases[$i]} }) {
      my $id = $a->stable_id.".".$a->version;
      $panel->add_columns(  { 'key' => $a->stable_id, 
			      'title' => $type.": ".$a->stable_id} ) unless $columns{$a->stable_id};
      $columns{$a->stable_id}++;
      my $archive = _archive_link($object, $id, $param, "<img src='/img/ensemblicon.gif'/>",  $releases[$i]);

      $row->{$a->stable_id} = qq(<a href="idhistoryview?$param).qq(=$id">$id</a> $archive);

      next if $type eq 'Translation';
      # get peptide length
      foreach my $pep (@{ $a->get_all_translation_archive_ids }) {
	my $pep_length = length($pep->get_peptide)."bp";
	my $archive = _archive_link($object, $pep->stable_id, "peptide", "<img src='/img/ensemblicon.gif' />", $releases[$i]);

	$row->{$a->stable_id}.= "<br /><a href='idhistoryview?peptide=".
	  $pep->stable_id."'>".$pep->stable_id."</a> ($pep_length) $archive";
      }
    }
    $panel->add_row( $row );
  }
  return 1;
}

sub _archive_link {
  my ($object, $name, $type, $id, $release) = @_;
  $release ||= $object->release;
  return unless $release > 24;

  my $current_release = $object->species_defs->ENSEMBL_VERSION;
  my $url;
  if ($release == $current_release) {
    $url = "/";
  }
  else {
    my %archive_sites;
    map { $archive_sites{ $_->{release_id} } = $_->{short_date} }@{ $object->species_defs->RELEASE_INFO };
    $url = "http://$archive_sites{$release}.archive.ensembl.org/";
    $url =~ s/ //;
  }

  $url .=  $ENV{'ENSEMBL_SPECIES'}."/";
  my $view = $type."view";
  if ($type eq 'peptide') {
    $view = 'protview';
  }

  $id = qq(<a title="Archive site" href="$url$view?$type=$name">$id</a>);

  return $id;
}



1;

      # get successors (for tagging)
      #my $predecessor = join("<br />", map { $_->stable_id.".".$_->version }  @{ $a->get_all_predecessors });
      #$html .= "<td>$predecessor</td>";

