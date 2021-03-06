package MusicBrainz::Server::Controller::LogStatistic;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MusicBrainz::Server::Controller'; }

__PACKAGE__->config(
    namespace   => 'log-statistics',
);

sub view_category : Path('') Args(1)
{
    my ($self, $c, $category) = @_;
    my $dates = $c->model('LogStatistic')->get_dates;
    $self->view_category_with_timestamp($c, $category, $dates->[0]);
}

sub view_category_with_timestamp : Path('') Args(2)
{
    my ($self, $c, $category, $date) = @_;
    
    my $categories = $c->model('LogStatistic')->get_categories;
    my @categories_lc = map { lc($_) } @$categories;
    
    my $dates = $c->model('LogStatistic')->get_dates;
    
    if ($category ~~ \@categories_lc) {
        $c->stash(
            template    => 'logstatistics/category.tt',
            stats       => $c->model('LogStatistic')->get_category($category, $date),
            categories  => $categories,
            category    => $category,
            dates       => $dates
        );
    } else {
        $self->redirect_to_top_entities($c);
    }
}

sub redirect_to_top_entities : Path('')
{
    my ($self, $c) = @_;
    $c->response->redirect($c->uri_for("/log-statistics/top%20entities"), 303);
}

sub json : Local Args(3)
{
    my ($self, $c, $category, $name, $date) = @_;
    
    $c->res->content_type('application/json');
    $c->res->body($c->model('LogStatistic')->get_json($category, $name, $date));
}

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
