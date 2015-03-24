package DBIx::Class::DWH;

use strict;
use warnings;

use base qw( DBIx::Class );

use DBIx::Class::ResultClass::HashRefInflator;
use Hash::Flatten qw/flatten/;

sub inflate_result {
  my ($self, @rest) = @_;
  my $res = $self->next::method(@rest);

  $res->{_dwh} = flatten(DBIx::Class::ResultClass::HashRefInflator->inflate_result(@rest), 
                         { HashDelimiter => '.' }
  );

  return $res;
}

1;
