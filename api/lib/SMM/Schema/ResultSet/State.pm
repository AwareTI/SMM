package SMM::Schema::ResultSet::State;
use namespace::autoclean;

use utf8;
use Moose;
extends 'DBIx::Class::ResultSet';
with 'SMM::Schema::Role::InflateAsHashRef';

1;

