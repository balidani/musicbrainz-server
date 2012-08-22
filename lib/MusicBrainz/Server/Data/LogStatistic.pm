package MusicBrainz::Server::Data::LogStatistic;

use Moose;
use Readonly;
use namespace::autoclean;
use MusicBrainz::Server::Entity::LogStatistic;
use MusicBrainz::Server::Data::Utils qw( placeholders query_to_list );
use JSON::Any;

extends 'MusicBrainz::Server::Data::Entity';

Readonly my $CACHE_PREFIX => 'logstatistic';
Readonly my $CACHE_KEY => 'logstatistic-category';

sub _table 
{ 
    return 'log_statistic';
}

sub _columns 
{ 
    return 'id, category, timestamp, data';
}

sub _column_mapping 
{
    return {
        id => 'id',
        name => sub { 
            my ($row, $prefix) = @_;
            my $decoded_href = JSON::Any->new( utf8 => 1 )->jsonToObj($row->{"${prefix}data"}); 
            return $decoded_href->{'name'}; 
        },
        category => 'category',
        timestamp => 'timestamp'
    };
}

sub _entity_class 
{ 
    return 'MusicBrainz::Server::Entity::LogStatistic';
}

sub get_categories
{
    my $self = shift;

    # Caching
    my $cache = $self->c->cache($CACHE_PREFIX);
    my $categories = $cache->get($CACHE_KEY);
    
    if (!$categories) {
        # Select reports from the database
        my $data_query = "SELECT DISTINCT category"
                       . " FROM " . $self->_table;
        $categories = $self->sql->select_single_column_array($data_query) or return;

        $cache->set($CACHE_KEY, $categories);
    }
    
    return $categories;
}

sub get_category
{
    my ($self, $category) = @_;
    
    # Select reports from the database with this category
    my $data_query = "SELECT " . $self->_columns 
                   . " FROM " . $self->_table
                   . " WHERE lower(category) = ?"
                   . " ORDER BY id";
    
    my @log_stats = query_to_list(
        $self->c->sql, 
        sub { $self->_new_from_row(shift) },
        $data_query,
        $category
    );
    
    return \@log_stats;
}

sub get_json
{
    my ($self, $stat) = @_;
    my $data_query = "SELECT data"
                   . " FROM " . $self->_table
                   . " WHERE id = ?";
    $self->sql->select($data_query, $stat) or return;
    
    my $row = $self->sql->next_row_hash_ref;
    return $row->{'data'};
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2012 Daniel Bali

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
