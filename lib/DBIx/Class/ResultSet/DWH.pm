package DBIx::Class::ResultSet::DWH;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';



sub get_column_from_fieldspec {
    my ($self, $spec) = @_;

    my @dim_spec = split /\./, $spec;  #/

    die "Unknown fieldspec $spec" if (@dim_spec < 2);
    return $dim_spec[@dim_spec - 2] . '.' . $dim_spec[@dim_spec - 1];
}



sub dwh_query {
    my ($self, $query) = @_;

    # Convert dimensions into the appropiate JOINs
    my $joins   = {};
    my $columns = [ ];
    
    foreach my $dimension (@{ $query->{ dimensions } }){
        my @dim_spec = split /\./, $dimension; #/
    
        if (@dim_spec == 2){
            #push @$joins, $dim_spec[0];
            $joins->{ $dim_spec[0] } = undef;
            push @$columns, $self->get_column_from_fieldspec($dimension);
        } elsif (@dim_spec == 3){
            #push @$joins, { $dim_spec[0] => $dim_spec[1] };
            $joins->{ $dim_spec[0] } = $dim_spec[1];
            push @$columns, $self->get_column_from_fieldspec($dimension);
        } else {
            # 0, 1, 4 ... elements
            die "Unknown dimension format $dimension";
        }
    }
  
    my $measure_columns = [ ];
    foreach my $measurement (@{ $query->{ measurements } }){
        die "Unrecognized measurement $measurement" if (ref($measurement) ne 'HASH');
        my ($oper, $column) = each %$measurement;
        push @$measure_columns, { lc("$oper\_$column") => $measurement };
    }
    my ($dims, $meas) = (1, 1);
  
    my $attrs = { 'join' => $joins,
                #'columns' => [ @$columns, @$measure_columns ],
                'select' => [ @{ $columns },
                              @{ $query->{ measurements } }  # 'select' => [{ 'AVG => 'worked_time', -as => 'measurement1' }],
                ],
                'as' => [ ( map { 'dimension' . $dims++ } @$columns ),
                          ( map { 'measurement' . $meas++ } @$measure_columns )
                          ],
                'group_by' => [ @$columns ],
    };

    my $rs = $self->search_rs({}, $attrs);

    return $rs
}

sub dimension {
  my ($self, $search, $update) = @_;

  my $obj = $self->search($search)->first;

  if (not defined $obj) {
     $obj = $self->new({});
     foreach my $prop (keys %$search) {
       $obj->$prop($search->{ $prop });
     }
     $obj->insert;
  }
 
  if (defined $update){
    foreach my $prop (keys %$update) {
      $obj->$prop($update->{ $prop });
    }
    $obj->update();
    #$obj->in_storage ? $obj->update() : $obj->insert();
  }
  return $obj;
}

sub get_dimension {
   my ($self, $key, $search) = @_;

   my $dim = $self->result_source->related_class($key);
   return $self->result_source->schema->resultset($dim)->dimension($search);
}

sub fact {
   my ($self, %info) = @_;
    
   my $fact = $self->new({});
   foreach my $key (keys %info) {
      if (ref($info{$key}) eq 'HASH') {
        my $dim_id = $self->get_dimension($key, $info{$key}, {});
        $fact->$key($dim_id);
      } else {
        $fact->$key($info{$key});
      }
   }
   
   $fact->insert;
   return $fact;
}

1;
