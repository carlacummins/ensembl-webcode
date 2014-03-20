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

package EnsEMBL::eDoc::Generator;

## Module to automatically generate documentation in e!doc format

use strict;
use warnings;
use EnsEMBL::eDoc::Module;
use EnsEMBL::eDoc::Writer;
use File::Find;

sub new {
  my ($class, %params) = @_;
  my $writer = new EnsEMBL::eDoc::Writer;
  my $self = {
    'directories' => $params{'directories'} || [],
    'module_info' => $params{'module_info'} || {},
    'identifier'  => $params{'identifier'}  || '##',
    'keywords'    => $params{'keywords'}    || '',
    'serverroot'  => $params{'serverroot'}  || '',
    'version'     => $params{'version'}     || 'master',
    'writer'      => $writer,
  };
  bless $self, $class;
  if ($self->{'serverroot'}) {
    $writer->set_serverroot($self->{'server_root'});
  }
  return $self;
}

sub get_directories {
  my $self = shift;
  return $self->{'directories'};
}

sub get_module_info {
  my $self = shift;
  return $self->{'module_info'};
}

sub get_module_names {
  my $self = shift;
  return keys %{$self->{'modules'}};
}

sub get_modules {
  my $self = shift;
  return values %{$self->{'modules'}};
}

sub get_all_modules {
  my $self = shift;
  my $modules = [];
  my @values = values %{$self->{'modules'}};
  foreach (@values) {
    push @$modules, @$_;
  }
  return $modules;
}

sub get_modules_by_name {
  my ($self, $name) = @_;
  return $self->{'modules'}{$name};
}

sub get_identifier {
  my $self = shift;
  return $self->{'identifier'};
}

sub get_keywords {
  my $self = shift;
  return $self->{'keywords'};
}

sub get_serverroot {
  my $self = shift;
  return $self->{'serverroot'};
}

sub get_version {
  my $self = shift;
  return $self->{'version'};
}

sub writer {
  my $self = shift;
  return $self->{'writer'};
}

sub find_modules {
  ### Recursively finds modules located in the directory parameter.
  my $self = shift;
  my $code_ref = sub { $self->wanted(@_) };
  find($code_ref, @{$self->get_directories});

  # map inheritance (super and sub classes), and replace module
  # names with module objects.
  my %subclasses = ();
  while (my ($class, $modules) = each(%{$self->get_module_info})) {
  }
  return;

  foreach my $arrayref ($self->get_modules) {
    foreach my $module (@$arrayref) {
  
      if ($module->inheritance) {
        my @class_cache = ();
        foreach my $classname (@{ $module->get_inheritance }) {
          push @class_cache, $classname;
        }

        $module->set_inheritance([]);

        foreach my $classname (@class_cache) {
          my $superclass = $self->get_module_by_name($classname);
          if ($superclass) {
            $module->add_superclass($superclass);
            if (!$subclasses{$superclass->name}) {
              $subclasses{$module->get_inheritance} = [];
            }
            push @{ $subclasses{$superclass->get_name} }, $module;
          }
        }
      }
    }
  }

  foreach my $module_name (keys %subclasses) {
    my $module = $self->get_module_by_name($module_name);
    if ($module) {
      my @subclasses = @{ $subclasses{$module_name} };
      if (@subclasses) {
        foreach my $subclass (@subclasses) {
          $module->add_subclass($subclass);
        }
      }
    }
  }

  return $self->get_modules;
}

sub wanted {
  ### Callback method used to find packages in the directory of
  ### interest.
  my $self = shift;
  if ($File::Find::name =~ /pm$/) {
    #print "Indexing " . $_ . "\n";
    #warn "CHECKING: " . $File::Find::name;
    my $class = $self->_package_name($File::Find::name);
    $self->_add_module($class, $File::Find::name);
  }
}

sub generate_html {
  my ($self, $location, $base, $support) = @_;

  my $writer = $self->writer;
  $writer->set_location($location);
  $writer->set_support($support);
  $writer->set_base($base);

  $writer->write_info_page($self->get_all_modules);
  $writer->write_package_frame($self->get_all_modules);
  $writer->write_method_frame($self->get_all_methods);
  $writer->write_base_frame($self->get_all_modules);
  $writer->write_module_pages($self->get_all_modules, $self->get_version);
  $writer->write_frameset;

  #$writer->copy_support_files;
}

sub get_all_methods {
  ### Returns all method objects for all found modules
  my $self = shift;
  my @methods = ();
  foreach my $module (@{$self->get_all_modules}) {
    foreach my $method (@{ $module->get_methods }) {
      #warn $method;
      push @methods, $method;
    }
  }
  return \@methods;
}

sub _package_name {
  ### (filename) Reads package name from .pm file
  ### Returns $package
  my ($self, $filename) = @_;
  open (my $fh, $filename) or die "$!: $filename";
  my $package = '';
  while (<$fh>) {
    if (/^package/) {
      $package = $_;
      chomp $package;
      $package =~ s/package |;//g;
      last;
    }
  }
  close $fh;
  return $package;
}


sub _add_module {
  ### Adds a new module object to the array of found modules.
  ### The new module will find methods within that package on
  ### instantiation.
  my ($self, $class, $location) = @_;
  #print "ADDING: $class\n";
  my $module = EnsEMBL::eDoc::Module->new(
                     name         => $class,
                     location     => $location,
                     identifier   => $self->get_identifier,
                     keywords     => $self->get_keywords,
                     find_methods => 1,
                   );
  my $arrayref = $self->get_modules_by_name($class);
  if ($arrayref) {
    push @$arrayref, $module;
  }
  else {
    $self->{'modules'}{$class} = [$module];
  }
}

1;
