package MusicBrainz::Server::Data::LogStatistic;

use Moose;
use Readonly;
use namespace::autoclean;
use MusicBrainz::Server::Entity::LogStatistic;
use MusicBrainz::Server::Data::Utils qw( placeholders query_to_list );
use JSON;

use DateTime::Format::Pg;

extends 'MusicBrainz::Server::Data::Entity';

Readonly my $CACHE_PREFIX => 'logstatistic';
Readonly my $CATEGORY_KEY => 'logstatistic-category';

sub _table 
{ 
    return 'log_statistic';
}

sub _columns 
{ 
    return 'name, category, timestamp, data';
}

sub _column_mapping 
{
    return {
        name => 'name',
        category => 'category',
        timestamp => 'timestamp'
    };
}

sub _entity_class 
{ 
    return 'MusicBrainz::Server::Entity::LogStatistic';
}

sub get_datetimes
{
    my $self = shift;

    # Select timestamps from the database
    my $data_query = "SELECT DISTINCT timestamp"
                   . " FROM " . $self->_table 
                   . " ORDER BY timestamp DESC";
    my $datetimes = $self->sql->select_single_column_array($data_query) or return;

    # Parse DateTime objects
    foreach my $datetime (@$datetimes) {
        $datetime = DateTime::Format::Pg->parse_timestamp($datetime);
    }
    
    return $datetimes;
}

sub get_categories
{
    my $self = shift;

    # Caching
    my $cache = $self->c->cache($CACHE_PREFIX);
    my $categories = $cache->get($CATEGORY_KEY);
    
    if (!$categories) {
        # Select reports from the database
        my $data_query = "SELECT DISTINCT category"
                       . " FROM " . $self->_table;
        $categories = $self->sql->select_single_column_array($data_query) or return;

        $cache->set($CATEGORY_KEY, $categories);
    }
    
    return $categories;
}

sub get_category
{
    my ($self, $category, $datetime) = @_;
    
    # Select reports from the database with this category
    my $data_query = "SELECT " . $self->_columns 
                   . " FROM " . $self->_table
                   . " WHERE lower(category) = ?"
                   . " AND date_trunc('second', timestamp) = ?"
                   . " ORDER BY name";
    
    my @log_stats = query_to_list(
        $self->c->sql, 
        sub { $self->_new_from_row(shift) },
        $data_query,
        $category,
        DateTime::Format::Pg->format_datetime($datetime)
    );
    
    return \@log_stats;
}

sub get_json
{
    my ($self, $category, $name, $dt) = @_;
    my $data_query = "SELECT data"
                   . " FROM " . $self->_table
                   . " WHERE category = ?"
                   . " AND name = ?"
                   . " AND date_trunc('second', timestamp) = ?";
    
    my $timestamp = DateTime::Format::Pg->format_datetime($dt);
    
    return $self->sql->select_single_value($data_query, $category, $name, $timestamp);
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
