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

package EnsEMBL::eDoc::Writer;

### Output component of the e! doc documentation system. This class
### controls the display of the documentation information collected.

use strict;
use warnings;

sub new {
  my ($class, %params) = @_;
  my $self = {
    'location'    => $params{'location'}    || '',
    'base'        => $params{'base'}        || '',
    'serverroot'  => $params{'serverroot'}  || '',
    'support'     => $params{'support'}     || '',
  };
  bless $self, $class;
  return $self;
}

sub get_location {
  my $self = shift;
  return $self->{'location'};
}

sub set_location {
  my $self = shift;
  $self->{'location'} = shift;
}

sub get_base {
  my $self = shift;
  return $self->{'base'};
}

sub set_base {
  my $self = shift;
  $self->{'base'} = shift;
}

sub get_serverroot {
  my $self = shift;
  return $self->{'serverroot'};
}

sub set_serverroot {
  my $self = shift;
  $self->{'serverroot'} = shift;
}

sub get_support {
  my $self = shift;
  return $self->{'support'};
}

sub set_support {
  my $self = shift;
  $self->{'support'} = shift;
}

sub write_info_page {
  ### Writes information page for the documentation.
  my ($self, $packages) = @_;
  open (my $fh, ">", $self->get_location . "/info.html") or die "$!: " . $self->get_location;
  print $fh $self->html_header();
  print $fh '
<div class="front">
  <h1><i><span style="color:#3366bb">e</span><span style="color:#880000">!</span></i> documentation info</h1>
  <div class="coverage">
  <table>
    <tr>
      <th style="width:20%">Family</th>
      <th style="width:40%;text-align:center">Size</th>
      <th style="width:40%;text-align:center">Average coverage</th>
    </tr>';
  my %count;
  my %total;
  my %average;
  foreach my $module (@{ $packages }) {
    my @elements = split /::/, $module->get_name;
    my $final = pop @elements;
    my $family = "";
    foreach my $element (@elements) {
      $family .= $element . "::";
      if (!$count{$family}) {
        $count{$family} = 0;
      }
      $count{$family}++;
    }
  }
  foreach my $module (@{ $packages }) {
    foreach my $family (keys %count) {
      if (!$total{$family}) {
        $total{$family} = 0;
      }
      if ($module->get_name =~ /^$family/) {
        $total{$family} += $module->coverage;
      }
    }
  }

  foreach my $family (keys %count) {
    $average{$family} = ($total{$family} / $count{$family});
  }

  foreach my $family (reverse sort { $average{$a} <=> $average{$b} } keys %average) {
    my $text = $family;
    $text =~ s/::$//;

    print $fh '
    <tr>
      <td>', $text, '</td>
      <td style="text-align:center">', $count{$family},'</td>
      <td style="text-align:center">', sprintf("%.0f", $average{$family}), '%</td>
    </tr>';
  }

  print $fh '
  </table>
  <br />
  <br />
  <a href="base.html">&larr; Home</a>
  <br /><br />
  </div>',
  $self->html_footer;
}

sub write_package_frame {
  ### Writes the HTML package listing.
  my ($self, $packages) = @_;
  open (my $fh, ">", $self->get_location . "/package.html") or die "$!: " . $self->get_location;
  print $fh $self->html_header( (class => "list" ));
  print $fh qq(<div class="heading">Packages</div>);
  print $fh qq(<ul>);
  foreach my $package (sort {$a->get_name cmp $b->get_name} @{ $packages }) {
    print $fh '<li><a href="', $self->link_for_package($package->get_name), '" target="base">', $package->get_name, "</a></li>\n";
  }
  print $fh qq(</ul>);
  print $fh $self->html_footer;
}

sub write_method_frame {
  ### Writes a complete list of methods from all modules to an HTML file.
  my ($self, $methods) = @_;
  open (my $fh, ">", $self->get_location . "/methods.html") or die "$!: " . $self->get_location;
  print $fh $self->html_header( (class => "list" ));
  print $fh qq(<div class="heading">Methods</div>);
  print $fh qq(<ul>);
  my %exists = ();
  foreach my $method (@{ $methods }) {
    $exists{$method->get_name}++;
  }
  foreach my $method (sort { $a->get_name cmp $b->get_name } @{ $methods }) {
    my $module_suffix = "";
    if ($exists{$method->get_name} > 1) {
      $module_suffix = " (" . $method->get_module->get_name . ")";
    }
    if ($method->get_name ne "") {
      print $fh "<li>" . $self->link_for_method($method) . $module_suffix . "</li>\n";
    }
  }
  print $fh qq(</ul>);
  print $fh $self->html_footer;
}

sub write_hierarchy {
  ### Returns a formatted list of inheritance and subclass information for a given module.
  my ($self, $module) = @_;
  my $html = "";
  if (@{ $module->get_inheritance }) {
    $html .= '<div class="hier">';
    $html .= "<h3>Inherits from:</h3>\n";
    $html .= "<ul>\n";
    #foreach my $class (@{ $module->get_inheritance }) {
    #  $html .= '<li><a href="' . $self->link_for_package($class->get_name) . '">' . $class->get_name . "</a></li>\n";
    #}
    $html .= "</ul>\n";
    $html .= "</div>";
  } else {
    $html .= '<div class="hier">No superclasses</div>';
  }

  if (@{ $module->get_subclasses } > 0) {
    $html .= '<div class="hier">';
    $html .= "<h3>Subclasses:</h3>\n";
    $html .= "<ul>\n";
   # foreach my $subclass (sort { $a->get_name cmp $b->get_name } @{ $module->get_subclasses }) {
   #   $html .= '<li><a href="' . $self->link_for_package($subclass->get_name) . '">' . $subclass->get_name. "</a></li>\n";
   # }
    $html .= "</ul>\n";
    $html .= "</div>";
  } else {
    $html .= '<div class="hier">No subclasses</div>';
  }

  if ($html ne "") {
    $html .= '<br style="clear:all" />';
  }

  return $html;
}

sub write_module_page {
  ### Writes the complete HTML documentation page for a module. 
  my ($self, $module, $version) = @_;
  open (my $fh, ">", $self->_html_path_from_package($module->get_name));
  my $location = $module->get_location;
  my $root = $self->get_serverroot;
  $location =~ s/$root//g if $root;
  my $repo = 'ensembl-webcode';

  print $fh $self->html_header( (package => $module->get_name) ),'
  <div class="title">
    <h1>' . $module->get_name . '</h1>
    Location: ', $location, '<br />
    <a href="', $self->source_code_link($version, $repo, $module->get_name) , '" rel="external">View source code on github</a> &middot;
    <a href="', $self->link_for_package($module->get_name), '">Permalink</a>
  </div>
  <div class="content">
    <div class="classy">',
    $self->write_hierarchy($module),'
      <div class="methods">',
    $self->toc_html($module),'
        <br /><br />
        <div class="definitions">',
    $self->methods_html($module, $version),'
        </div>
        <br clear="all">
      </div>
    </div>
  </div>
  <div class="footer">&larr; 
    <a href="', "../" x element_count_from_package($module->get_name),'base.html">Home</a> &middot;
    <a href="', $self->source_code_link($version, $repo, $module->get_name),'" rel="external">View source code on github</a>
  </div>',
    $self->html_footer;
}

sub source_code_link {
  my ($self, $version, $repo, $package) = @_;
  $package =~ s/::/\//g;
  my $branch = $version eq 'master' ? 'master' : "release/$version";
  return sprintf 'https://github.com/Ensembl/%s/blob/%s/modules/%s.pm', $repo, $branch, $package;
}

sub write_module_pages {
  ### Writes module documentation page for every found module.
  my ($self, $modules, $version) = @_;
  foreach my $module (@{ $modules }) {
    $self->write_module_page($module, $version);
  }
}

sub toc_html {
  ### Returns the table of contents for the module methods.
  my ($self, $module) = @_;
  my $html = "";
  $html .= qq(<h3>Overview</h3>\n);
  $html .= $self->markup_documentation($module->get_overview);
  foreach my $type (@{ $module->get_types }) {
    $html .= "<h4>" . ucfirst($type) . "</h4>\n";
    $html .= "<ul>";
    foreach my $method (sort {$a->get_name cmp $b->get_name} @{ $module->methods_of_type($type) }) {
      if ($method->get_type !~ /unknown/) {
        $html .= '<li><a href="#' . $method->get_name . '">' . $method->get_name . '</a>';
        if ($method->get_module->get_name ne $module->get_name) {
          $html .= " (" . $method->get_module->get_name . ")";
        }
        $html .= "</li>\n";
      } else {
        $html .= "<li>" . $method->get_name;

        if ($method->get_module->get_name ne $module->get_name) {
          $html .= " (" . $method->get_module->get_name . ")";
        }

        $html .= "</li>\n";
      }
    }
    $html .= "</ul>";
  }
  $html .= "Documentation coverage: " . sprintf("%.0f", $module->coverage) . " %";
  return $html;
}

sub markup_documentation {
  ### Marks up documentation text for links and embedded tables. See also {{markup_links}} and {{markup_embedded_table}}.
  my ($self, $overview) = @_;
  my $html = "";
  my @contents = split(/___/, $overview);
  my $count = 0;
  foreach my $content (@contents) {
    $count++;
    if ($count == 1) {
      $html .= $content;
    }
    if ($count == 2) {
      $html .= $self->markup_embedded_table($content);
    }
    if ($count == 3) {
      $html .= $content;
      $count = 0;
    }
  }
  return $self->markup_links($html);
}

sub markup_embedded_table {
  ### Marks up key value pairs when embedded in documentation. An embedded table should be delineated with a starting and ending triple underscore. 
  my ($self, $table) = @_;
  my $html = "";
  my @rows = split(/\n/, $table);
  my $count = 0;
  my %content = ();
  foreach my $row (@rows) {
    $count++;
    my ($key, $value) = split(/:/, $row);
    if ($key && $value) {
      $content{$key} = $value;
    }
  }
  return $self->markup_method_table(\%content);
}

sub methods_html {
  ### Returns a formatted list of method names and documentation.
  my ($self, $module, $version) = @_;
  my $html = "";
  $html .= qq(<h3>Methods</h3>);
  $html .= qq(<ul>);
  my $count = 0;
  foreach my $method (sort { $a->get_name cmp $b->get_name } @{ $module->get_methods }) {
    if ($method->get_type !~ /unknown/) {
      my $complete = $module->get_name . "::" . $method->get_name;
      $count++;
      $html .= qq(<b><a name=") . $method->get_name . qq("></a>) . $method->get_name . qq(</b><br />\n);
      $html .= $self->markup_documentation($method->get_documentation);
      $html .= $self->markup_method_table($method->get_table);
      if ($method->get_result) {
        $html .= qq(<i>) . $self->markup_links($method->get_result) . qq(</i>\n);
      }
      $html .= qq(<br />\n);
      if ($method->get_module->get_name ne $module->get_name) {
        $complete = $method->get_module->get_name . "::" . $method->get_name;
        $html .= qq(Inherited from <a href=") . $self->link_for_package($method->get_module->get_name) . qq(">) . $method->get_module->get_name . "</a><br />";
      }
      #$html .= sprintf '<a href="%s" rel="external">View source on github</a>', $self->source_code_link($version, 'ensembl-webcode', $complete);
      $html .= "<div id='" . $complete . "' style='display: none;'>" . $complete . "</div>";
      $html .= qq(<br /><br />\n);
    }
  }
  if (!$count) {
    $html .= qq(No documented methods.);
  }
  $html .= qq(</ul>);
  return $html;
}

sub markup_method_table {
  ### Returns tabulated documentation.
  my ($self, $table) = @_;
  my $html = "";
  if (keys %{ $table }) {
    $html = "<div class='indent'>\n";
    $html .= "<table width='65%' cellpadding='4' cellspacing='0'>\n";
    my %table = %{ $table };
    my $row_count = 0;
    my $classname = "";
    foreach my $key (sort keys %table) {
      $row_count++;
      $classname = "";
      if ($row_count % 2) {
        $classname = "class='filled'";
      }
      $html .= "<tr><td $classname valign='top'>$key</td><td $classname>" . $self->markup_links($table{$key}) . "</td></tr>\n";
    }
    $html .= "</table></div>\n";
  }
  return $html;
}

sub markup_links {
  ### Parses documentation for special e! doc markup. Links to other modules and methods can be included between double braces. For example: { { EnsEMBL::Web::Tools::Document::Module::new } } is parsed to {{EnsEMBL::Web::Tools::Document::Module::new}}. Simple method and module names can also be used. {{markup_links}} does not perform any error checking on the names of modules and methods. 
  my ($self, $documentation) = @_;
  my $markup = $documentation;
  $_ = $documentation;
  while (/{{(.*?)}}/g) {
    my $name = $1;
    if ($name =~ /\:\:/) {
      my @elements = split /\:\:/, $name;
      if ($elements[$#elements] =~ /^[a-z]/) {
        my $package = "";
        my $path = "";
        my $method = $elements[$#elements];
        for (my $n = 0; $n < $#elements; $n++) {
          $package .= $elements[$n] . "::";
        }
        $package =~ s/\:\:$//;
        my $link = "<a href='" . $self->link_for_package($package) . "#$method'>" . $package . "::" . $method . "</a>";
        $markup =~ s/{{$name}}/$link/;
      } else {
        my $link = "<a href='" . $self->link_for_package($name) . "'>" . $name . "</a>";
        $markup =~ s/{{$name}}/$link/;
      }
    } else {
      my $link = "<a href='#$name'>$name</a>";
      $markup =~ s/{{$name}}/$link/;
    }
  }
  return $markup;
}

sub write_base_frame {
  ### Writes the home page for the e! doc.
  my ($self, $modules) = @_;
  open (my $fh, ">", $self->get_location . "/base.html");
  my $total = 0;
  my $count = 0;
  my $methods = 0;
  my $lines = 0;
  foreach my $module (@{ $modules }) {
    $count++;
    $total += $module->coverage;
    $methods += @{ $module->get_methods };
    $lines += $module->get_lines;
  }
  my $coverage = 0;
  if ($count == 0) {
    warn "No modules indexed!";
  } else {
    $coverage = $total / $count;
  }
  print $fh $self->html_header;
  print $fh "<div class='front'>";
  print $fh "<h1><i><span style='color: #3366bb'>e</span><span style='color: #880000'>!</span></i> web code documentation</h1>";
  print $fh qq(<div class='coverage'>);
  print $fh qq(Documentation coverage: ) . sprintf("%.0f", $coverage) . qq( %);
  print $fh qq(</div>);
  print $fh "<div class='date'>" . $count . " modules<br />\n";
  print $fh "" . $methods . " methods<br />\n";
  print $fh "" . $lines . " lines of source code<br /><br />\n";
  print $fh "<a href='info.html'>More info &rarr;</a><br />\n";
  print $fh "</div>";
  print $fh "<div class='date'>Last built: " . localtime() . "</div>";
  print $fh "</div>";
  print $fh $self->html_footer;
}

sub write_frameset {
  ### Writes the frameset for the e! doc collection.
  my $self = shift;

  open FH, '>', $self->get_location . '/iframe.html';
  print FH '
    <!--#set var="decor" value="none"-->
    <html>
    <head>
      <title>e! doc</title>
    </head>
    <frameset rows="25%, 75%">
    <frameset cols="50%,50%">
        <frame src="package.html" title="e! doc" name="packages">
        <frame src="methods.html"  name="methods">
    </frameset>
    <frame src="base.html" name="base">
    <noframes>
          <body bgcolor="white">
            You need frames to view the e! documentation.
          </body>
    </noframes>
    </frameset>
    </html>
  ';

  close FH;

  open FH, '>', $self->get_location . '/index.html';
  print FH '
    <html>
    <head>
      <title>e! doc</title>
    </head>
    <body>
    <div id="static">
      <iframe src="iframe.html" id="pdoc_iframe" width="100%" height="1000px"></iframe>
    </div>
    </body>
    </html>
  ';

  close FH;
}

sub link_for_method {
  ### Returns the HTML formatted link to a method page in a module page.
  my ($self, $method) = @_;
  return sprintf '<a href="%s#%s" target="base">%s</a>', 
                  $self->link_for_package($method->get_module->get_name), 
                  $method->get_name, $method->get_name;
}

sub copy_support_files {
  ### Copies support files (stylesheets etc) to the export location (set by {{support}}.
  my $self = shift;
  return;
  my $source = $self->get_support;
  my $destination = $self->get_location;
  if ($source) {
    my $cp = `cp $source/* $destination/`;
  }
}

sub html_header {
  ### ($package, $class) Returns an HTML header. When supplied, $package
  ### is used to determine relative links and $class determins the class
  ### of the HTML body.
  my ($self, %params) = @_;
  my $package = $params{package};
  my $class = $params{class};
  my $title = $params{title} ? $params{title} : "e! doc";
  if ($class) {
    $class = " class='" . $class . "'";
  } else {
    $class = "";
  }
  my $html = "";
  $html = qq(<!--#set var="decor" value="none"-->
<html>
  <head>
    <title>e! doc</title>
    <script type="text/javascript" src="/components/00_jquery.js"></script>
    <script type="text/javascript" src="/edoc.js"></script>
    <link href="/edoc.css" rel="stylesheet" type="text/css" media="all" />
  </head>
  <body $class>);
  return $html;
}

sub include_stylesheet {
  ### Returns the HTML to include a CSS stylesheet.
  return;
}

sub include_javascript {
  ### Returns HTML to include a javascript file.
  return;
}

sub package_prefix {
  ### Returns the relative path prefix for a particular 
  ### package name.
  my ($self, $package) = @_;
  my $html = "";
  if (element_count_from_package($package)) {
     $html .= ("../" x element_count_from_package($package));
  }
  return $html;
}

sub html_footer {
  ### Returns a simple HTML footer
  return qq(
    </body>
    </html>
  );
}

sub _html_path_from_package {
  ### Returns an export location from a package name
  my ($self, $package) = @_;
  my $path = $self->get_location . "/" . $self->path_from_package($package) . ".html";
  return $path;
}

sub link_for_package {
  ### Returns the HTML location of a package, excluding &lt;A HREF&gt; markup.
  my ($self, $package) = @_;
  my $path = $self->get_base . "/" . $self->path_from_package($package) . ".html";
  return $path;
}

sub path_from_package {
  ### Returns file system path to package
  my ($self, $package) = @_;
  my @elements = split(/::/, $package);
  my $file = pop @elements;
  my $path = $self->get_location;

  foreach my $element (@elements) {
    $path = $path . "/" . $element;
    if (!-e $path) {
      print "Creating $path\n";
      my $mk = `mkdir $path`;
    }
  }

  $package =~ s/::/\//g;
  return $package;
}

sub element_count_from_package {
  ### Returns the number of elements in a package name.
  my $package = shift;
  if ($package) {
    my @elements = split(/::/, $package);
    return $#elements;
  }
  return 0;
}


1;
