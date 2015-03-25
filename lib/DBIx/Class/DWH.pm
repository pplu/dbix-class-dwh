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
#################### main pod documentation begin ###################

=head1 NAME

DBIx::Class::DWH - Helps you build Datawarehouses on star schemas

=head1 SYNOPSIS

  In your schema class (DB.pm)

  __PACKAGE__->load_namespaces(default_resultset_class => '+DBIx::Class::ResultSet::DWH');

  In the classes that represent facts (Table.pm)

  __PACKAGE__->load_components("DWH");

=head1 DESCRIPTION

This DBIx::Class plugin helps you 

=head1 USAGE

Set up your schema class to have a default_result_class of DBIx::Class::ResultSet::DWH (see the synopsis for

how to do that. Then load the "DWH" component in the result classes of your schema.

=head1 METHODS

The module provides you with two methods that satisfy to common patterns: locating the surrogate key of a 

dimension,

=head2 fact({ dim1 => { dim1 criteria }, dimN => { dim2 search }, fact1 => $scalar, fact2 => $scalar })

The fact method helps you insert facts into a fact table in an easy way. It will locate the first row

in a dimension that match the dimensions criteria, and save the surrogate key (PK of the dimension table

in the fact table), for each of the dimensions specified. If a row for the dimension isn't found, then 

the values for the search will be inserted as a new row, and the surrogate key for that new row used as the 

foreign key. Fact column values will be inserted directly.

=head2 dwh_query({ dimensions => [ 'dim1.column', 'dimN.column' ], measurements => [ { SUM => 'factcol1' }, { COUNT => '*' }, { AVG => 'factcol2' } ])

the dwh_query method returns a DBIx::Class resultset that is joined with the dimensions specified, 

and grouped by the dimension columns. The measurements field specifies what aggregation operation to 

do on the fact columns. The dimension columns are returned in the resultset as "dimension1", ..., "dimensionN"

and "measurement1" to "measurementN".

=head1 CONTRIBUTE

The source code is located here: 

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

Copyright (c) 2014 by Jose Luis Martinez Torres

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
