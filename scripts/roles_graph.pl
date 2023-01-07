#!/usr/bin/perl

use strict;
use warnings;

use Cwd 'abs_path';
use File::Basename;
use Graph::Easy;
use YAML::Tiny;

my $roles_path = abs_path(dirname(dirname($0)) . "/roles");
my @roles_paths = glob("$roles_path/*");
my $role_graph = Graph::Easy->new();

foreach my $role_path (@roles_paths) {
  my $role_name = basename($role_path);
  $role_graph->add_node($role_name);
  my $role_meta_path = "$role_path/meta/main.yaml";
  if (! -r $role_meta_path) {
    next;
  }
  my $role_meta = YAML::Tiny->read($role_meta_path)->[0];
  my $role_deps = $role_meta->{dependencies};
  foreach my $role_dep (@$role_deps) {
    my $role_dep_name = $role_dep->{role};
    $role_graph->add_edge($role_dep_name, $role_name);
  }
}

print $role_graph->as_ascii();
