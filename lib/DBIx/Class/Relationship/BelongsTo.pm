package # hide from PAUSE
    DBIx::Class::Relationship::BelongsTo;

# Documentation for these methods can be found in
# DBIx::Class::Relationship

use strict;
use warnings;
use Try::Tiny;
use namespace::clean;

our %_pod_inherit_config =
  (
   class_map => { 'DBIx::Class::Relationship::BelongsTo' => 'DBIx::Class::Relationship' }
  );

sub belongs_to {
  my ($class, $rel, $f_class, $cond, $attrs) = @_;

  # assume a foreign key constraint unless defined otherwise
  $attrs->{is_foreign_key_constraint} = 1
    if not exists $attrs->{is_foreign_key_constraint};
  $attrs->{undef_on_null_fk} = 1
    if not exists $attrs->{undef_on_null_fk};

  # no join condition or just a column name
  if (!ref $cond) {
    $class->ensure_class_loaded($f_class);

    my $pri = $f_class->result_source_instance->_single_pri_col_or_die;

    my ($f_key, $guess);
    if (defined $cond and length $cond) {
      $f_key = $cond;
      $guess = "caller specified foreign key '$f_key'";
    }
    else {
      $f_key = $rel;
      $guess = "using given relationship name '$rel' as foreign key column name";
    }

    $class->throw_exception(
      "No such column '$f_key' declared yet on ${class} ($guess)"
    )  unless $class->has_column($f_key);

    $cond = { "foreign.${pri}" => "self.${f_key}" };

  }
  # explicit join condition
  else {
    if (ref $cond eq 'HASH') { # ARRAY is also valid
      my $cond_rel;
      for (keys %$cond) {
        if (m/\./) { # Explicit join condition
          $cond_rel = $cond;
          last;
        }
        $cond_rel->{"foreign.$_"} = "self.".$cond->{$_};
      }
      $cond = $cond_rel;
    }
  }

  my $acc_type = (
    ref $cond eq 'HASH'
      and
    keys %$cond == 1
      and
    (keys %$cond)[0] =~ /^foreign\./
      and
    $class->has_column($rel)
  ) ? 'filter' : 'single';

  my $fk_columns = ($acc_type eq 'single' and ref $cond eq 'HASH')
    ? { map { $_ =~ /^self\.(.+)/ ? ( $1 => 1 ) : () } (values %$cond ) }
    : undef
  ;

  $class->add_relationship($rel, $f_class,
    $cond,
    {
      accessor => $acc_type,
      $fk_columns ? ( fk_columns => $fk_columns ) : (),
      %{$attrs || {}}
    }
  );

  return 1;
}

# Attempt to remove the POD so it (maybe) falls off the indexer

#=head1 AUTHORS
#
#Alexander Hartmaier <Alexander.Hartmaier@t-systems.at>
#
#Matt S. Trout <mst@shadowcatsystems.co.uk>
#
#=cut

1;
