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

package EnsEMBL::Draw::GlyphSet_wiggle;

# Draws "wiggles". Not actually a GlyphSet, but used by them.

use strict;

use List::Util qw(min max);

sub _min_defined(@) { min(grep { defined $_ } @_); }

use base qw(EnsEMBL::Draw::GlyphSet);

sub supports_subtitles { 1; }
sub wiggle_subtitle { undef; }
sub subtitle_colour { $_[0]->{'subtitle_colour'} || 'slategray' }
sub subtitle_text {
  my ($self) = @_;

  my $name = $self->my_config('short_name') || $self->my_config('name');
  my $label = $self->wiggle_subtitle;
  $label =~ s/\[\[name\]\]/$name/;
  $label =~ s/<.*?>//g;
  return $label;
}

## Draw the special box found on reg. multi-wiggle tracks
sub _add_sublegend_box {
  my ($self,$offset,$content,$click_text) = @_;

  my %font_details = $self->get_font_details('innertext', 1);
  my @text = $self->get_text_width(0,$click_text, '', %font_details);
  my ($width,$height) = @text[2,3];
  $self->push($self->Rect({
    width         => $width + 15,
    absolutewidth => $width + 15,
    height        => $height + 2,
    y             => $offset+13,
    x             => -117,
    absolutey     => 1,
    absolutex     => 1,
    title         => join('; ',@$content),
    class         => 'coloured',
    bordercolour  => '#336699',
    colour        => 'white',
  }), $self->Text({
    text      => $click_text,
    height    => $height,
    halign    => 'left',
    valign    => 'bottom',
    colour    => '#336699',
    y         => $offset+13,
    x         => -116,
    absolutey => 1,
    absolutex => 1,
    %font_details,
  }), $self->Triangle({
    width     => 6,
    height    => 5,
    direction => 'down',
    mid_point => [ -123 + $width + 10, $offset+23 ],
    colour    => '#336699',
    absolutex => 1,
    absolutey => 1,
  }));
  return $height;
}

## Contents of the ZMenu of the special box found on reg. multi-wiggles
sub _sublegend_box_content {
  my ($self,$parameters,$header_label,$labels,$colours) = @_;

  my $legend_alt_text = $self->_build_reg_legend_text($labels,$colours);
  my $title = join(', ',$header_label,
                          @{$parameters->{'zmenu_extra_title'}||[]});
  $title =~ s/&/and/g; # amps problematic; not just a matter of encoding
  return [$title,"[ $legend_alt_text ]",
                 @{$parameters->{'zmenu_extra_content'}||[]}];
}

## Draw the mini label founf on reg. multi-wiggle tracks
sub _draw_mini_label {
  my ($self,$label,$offset) = @_;

  my %font_details = $self->get_font_details('innertext', 1);
  my @res_analysis = $self->get_text_width(0,'Legend & More', '',
                                           %font_details);
  $self->push($self->Text({
    text      => $label,
    height    => $res_analysis[3],
    width     => $res_analysis[2],
    halign    => 'left',
    valign    => 'bottom',
    colour    => 'black',
    y         => $offset,
    x         => -118,
    absolutey => 1,
    absolutex => 1,
    %font_details,
  }));
}

## Should we draw the mini-label. Yes except CTCF.
# This code should be deleted when the ctcf glyphset goes in e82.
sub _should_draw_mini_label {
  my ($self,$text) = @_;

  return $text ne 'CTCF';
}

## Draw the mini label and special box found on reg. multi-wiggle tracks
sub _add_sublegend {
  my ($self,$parameters,$offset,$labels,$colours) = @_;

  # The label
  my $header_label = shift @$labels;
  if($self->_should_draw_mini_label($header_label)) {
    $self->_draw_mini_label($header_label,$offset);
  }
  # The box
  my $content = $self->_sublegend_box_content($parameters,$header_label,                                                  $labels,$colours);
  my $click_text = $parameters->{'zmenu_click_text'} || 'Legend';
  my $height = $self->_add_sublegend_box($offset,$content,$click_text);
  return $height+4;
}

sub _build_reg_legend_text {
  my ($self,$labels,$colours) = @_;

  my ($legend_alt_text, %seen);
  my $max = scalar @$labels - 1;
  for (my $i = 0; $i <= $max; $i++) {
    my $name = $labels->[$i];
    my $colour = $colours->[$i];

    if (!exists $seen{$name}) {
      $legend_alt_text .= "$name:$colour,";
      $seen{$name} = 1;
    }
  }
  $legend_alt_text =~ s/,$//;
  return $legend_alt_text;
}
    
sub _draw_axes {
  my ($self,$top,$zero,$bottom,$slice_length,$parameters) = @_;

  my $axis_style = $parameters->{'graph_type'} eq 'line' ? 0 : 1;
  my $axis_colour =
    $parameters->{'axis_colour'} || $self->my_colour('axis') || 'red';
  $self->push($self->Line({ # horizontal line
    x         => 0,
    y         => $zero,
    width     => $slice_length,
    height    => 0,
    absolutey => 1,
    colour    => $axis_colour,
    dotted    => $axis_style,
  }), $self->Line({ # vertical line
    x         => 0,
    y         => $top,
    width     => 0,
    height    => $bottom,
    absolutey => 1,
    absolutex => 1,
    colour    => $axis_colour,
    dotted    => $axis_style,
  }));
}

sub _draw_score {
  my ($self,$y,$value,$colour) = @_;

  my $text = sprintf('%.2f',$value);
  my %font = $self->get_font_details('innertext', 1);
  my $width = [ $self->get_text_width(0, $text, '', %font) ]->[2];
  my $height = [ $self->get_text_width(0, 1, '', %font) ]->[3];
  $self->push($self->Text({
    text          => $text,
    height        => $height,
    width         => $width,
    textwidth     => $width,
    halign        => 'right',
    colour        => $colour,
    y             => $y - $height/2,
    x             => -10 - $width,
    absolutey     => 1,
    absolutex     => 1,
    absolutewidth => 1,
    %font,
  }), $self->Rect({
    height        => 0,
    width         => 5,
    colour        => $colour,
    y             => $y,
    x             => -8,
    absolutey     => 1,
    absolutex     => 1,
    absolutewidth => 1,
  }));
}

# top: top of graph in pixel units, offset from track top (usu. 0)
# line_score: value to draw "to" up/down, in score units (usu. 0)
# line_px: value to draw "to" up/down, in pixel units (usu. 0)
# bottom: bottom of graph in pixel units (usu. approx. pixel height)

sub do_draw_wiggle {
  ### Wiggle plot
  ### Args: array_ref of features in score order, colour, min score for features, max_score for features, display label
  ### Description: draws wiggle plot using the score of the features
  ### Returns 1

  my ($self, $features, $parameters, $colours, $labels) = @_;
  my $slice         = $self->{'container'};
  my $row_height    = $self->my_config('height') || 60;
  my $max_score     = $parameters->{'max_score'};
  my $min_score     = $parameters->{'min_score'};
  my $axis_style    = $parameters->{'graph_type'} eq 'line' ? 0 : 1;
  my $axis_colour   = $parameters->{'axis_colour'}   || $self->my_colour('axis')  || 'red';

  my $range = $max_score-$min_score;
  $max_score = $min_score + $range;

  my $pix_per_score = $row_height/$range;
  my $top = ($parameters->{'initial_offset'}||0);
  my $line_score = max(0,$min_score);
  my $bottom = $top + $pix_per_score * $range;
  my $line_px = $bottom - ($line_score-$min_score) * $pix_per_score;

  $self->{'subtitle_colour'} ||=
    $parameters->{'score_colour'} || $self->my_colour('score') || 'blue';

  $self->_add_sublegend($parameters,$top,$labels,$colours) if $labels;

  if (!$parameters->{'no_axis'}) {
    $self->_draw_axes($top,$line_px,$bottom,$slice->length,
                      $parameters);
  }

  if ($parameters->{'axis_label'} ne 'off') {
    $self->_draw_score($top,$max_score,$axis_colour);
    $self->_draw_score($bottom,$min_score,$axis_colour);
  }

  # Draw wiggly plot
  ## Check to see if we have multiple data sets to draw on one axis
  if (ref $features->[0] eq 'ARRAY') {
    foreach my $feature_set (@$features) {
      my $colour = shift @$colours;
      if ($parameters->{'graph_type'} eq 'line') {
        $self->draw_wiggle_points_as_line($feature_set, $parameters, $line_score, $line_px, $pix_per_score, $colour);
      } else {
        $self->draw_wiggle_points($feature_set, $slice, $parameters, $line_score,$line_px, $pix_per_score, $colour);
      }
    }
  } else {
    my $colour = $parameters->{'score_colour'}  || $self->my_colour('score') || 'blue';
    $self->draw_wiggle_points($features, $slice, $parameters, $line_score, $line_px, $pix_per_score, $colour);
  }

  return $row_height;
}

# eg. Sarcophilus harrisii as of e80
sub _is_old_style_rnaseq {
  my ($self,$f) = @_;

  return (ref $f ne 'HASH' and $f->can('display_id') and
    $f->can('analysis') and $f->analysis and
    $f->analysis->logic_name =~ /_intron/);
}

sub _old_rnaseq_is_non_canonical {
  my ($self,$f) = @_;

  my $can_type = [ split /:/, $f->display_id ]->[-1];
  return ($can_type and length $can_type > 3 and
    substr('non canonical', 0, length $can_type) eq $can_type);
}

sub _use_this_feature_colour {
  my ($self,$f,$parameters) = @_;

  if ($parameters->{'use_feature_colours'} and $f->can('external_data')) {
    my $data        = $f->external_data;
    if($data and $data->{'item_colour'} and
       ref($data->{'item_colour'}) eq 'ARRAY') {
      return $data->{'item_colour'}[0];
    }
  }
  return undef;
}

## Does feature need special colour handling?
sub _special_colour {
  my ($self,$f,$parameters) = @_;

  if($self->_is_old_style_rnaseq($f) and
     $self->_old_rnaseq_is_non_canonical($f)) {
    return $parameters->{'non_can_score_colour'};
  }

  my $feature_colour = $self->_use_this_feature_colour($f,$parameters);
  return $feature_colour if defined $feature_colour;

  # No special colour
  return undef;
}

## Given a feature, extract coords, value, and colour for this point
sub _feature_values {
  my ($self,$f,$slice_length) = @_;

  my @out;
  my ($start,$end,$score);
  if (ref $f eq 'HASH') {
    # A simple HASH value
    ($start,$end,$score) = ($f->{'start'},$f->{'end'},$f->{'score'});
  } else {
    # A proper feature
    ($start,$end,$score) = ($f->start,$f->end,0);
    if($f->can('score')) {
      $score = $f->score || 0;
    } elsif($f->can('scores')) {
      $score = $f->scores->[0] || 0;
    }
  }
  $start = max($start,1);
  $end = min($end,$slice_length);
  return ($start,$end,$score);
}

sub _feature_href {
  my ($self,$f,$hrefs) = @_;

  if(ref $f ne 'HASH' && $f->can('display_id')) {
    return $hrefs->{$f->display_id};
  }
  return '';
}

sub draw_wiggle_points {
  my ($self,$features,$slice,$parameters,$line_score,$line_px,$pix_per_score,$colour) = @_;

  my $hrefs     = $parameters->{'hrefs'};
  my $use_points    = $parameters->{'graph_type'} eq 'points';
  my $max_score = $parameters->{'max_score'};
  my $slice_length = $slice->length;

  foreach my $f (@$features) {
    my $href = $self->_feature_href($f,$hrefs||{});
    my $colour = $self->_special_colour($f,$parameters) || $colour;
    my ($start,$end,$score) = $self->_feature_values($f,$slice_length);
    my $height = ($score-$line_score) * $pix_per_score;
    my $title = sprintf('%.2f',$score);

    $self->push($self->Rect({
      y         => $line_px - max($height, 0),
      height    => $use_points ? 0 : abs $height,
      x         => $start - 1,
      width     => $end - $start + 1,
      absolutey => 1,
      colour    => $colour,
      alpha     => $parameters->{'use_alpha'} ? 0.5 : 0,
      title     => $parameters->{'no_titles'} ? undef : $title,
      href      => $href,
    }));
  }
}

sub _discrete_features {
  my ($self,$ff) = @_;

  if(ref($ff->[0]) eq 'HASH' or $ff->[0]->window_size) {
    return 0;
  } else {
    return 1;
  }
}

sub draw_wiggle_points_as_line {
  my ($self, $features, $parameters, $line_score,$line_px, $pix_per_score, $colour) = @_;
  my $slice_length = $self->{'container'}->length;
  my $discrete_features = $self->_discrete_features($features);
  if($discrete_features) {
    $features = [ sort { $a->start <=> $b->start } @$features ];
  }

  my ($previous_x,$previous_y);
  for (my $i = 0; $i <= @$features; $i++) {
    my $f = $features->[$i];
    next if ref $f eq 'HASH' and $discrete_features;

    my ($current_x,$current_score);
    if ($discrete_features) {
      $current_score = $f->scores->[0];
      $current_x     = ($f->end + $f->start) / 2;
    } else {
      $current_x     = ($f->{'end'} + $f->{'start'}) / 2;
      $current_score = $f->{'score'};
    }
    my $current_y = $line_px-($current_score-$line_score) * $pix_per_score;
    next unless $current_x <= $slice_length;

    if($i) {
      $self->push($self->Line({
        x         => $current_x,
        y         => $current_y,
        width     => $previous_x - $current_x,
        height    => $previous_y - $current_y,
        colour    => $colour,
        absolutey => 1,
      }));
    }

    $previous_x     = $current_x;
    $previous_y     = $current_y;
  }
}

1;