package # hide from PAUSE
    DBIx::Class::Relationship::HasMany;

use strict;
use warnings;
use Try::Tiny;
use namespace::clean;

our %_pod_inherit_config =
  (
   class_map => { 'DBIx::Class::Relationship::HasMany' => 'DBIx::Class::Relationship' }
  );

sub has_many {
  my ($class, $rel, $f_class, $cond, $attrs) = @_;

  unless (ref $cond) {
    $class->ensure_class_loaded($f_class);

    my $pri = $class->result_source_instance->_single_pri_col_or_die;

    my ($f_key,$guess);
    if (defined $cond && length $cond) {
      $f_key = $cond;
      $guess = "caller specified foreign key '$f_key'";
    } else {
      $class =~ /([^\:]+)$/;  # match is safe - $class can't be ''
      $f_key = lc $1; # go ahead and guess; best we can do
      $guess = "using our class name '$class' as foreign key source";
    }

    my $f_class_loaded = try { $f_class->columns };
    $class->throw_exception(
      "No such column '$f_key' on foreign class ${f_class} ($guess)"
    ) if $f_class_loaded && !$f_class->has_column($f_key);

    $cond = { "foreign.${f_key}" => "self.${pri}" };
  }

  my $default_cascade = ref $cond eq 'CODE' ? 0 : 1;

  $class->add_relationship($rel, $f_class, $cond, {
    accessor => 'multi',
    join_type => 'LEFT',
    cascade_delete => $default_cascade,
    cascade_copy => $default_cascade,
    %{$attrs||{}}
  });
}

1;
