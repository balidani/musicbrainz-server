package MusicBrainz::Server::Report::NoLanguage;
use Moose;

with 'MusicBrainz::Server::Report::ReleaseReport',
     'MusicBrainz::Server::Report::FilterForEditor::ReleaseID';

sub query {
    "
        SELECT
            r.id AS release_id,
            row_number() OVER (ORDER BY musicbrainz_collate(ac_name.name), musicbrainz_collate(rn.name))
        FROM release r
        JOIN release_name rn ON r.name = rn.id
        JOIN artist_credit ON r.artist_credit = artist_credit.id
        JOIN artist_name ac_name ON ac_name.id = artist_credit.name
        WHERE language IS NULL
    ";
}

sub template
{
    return 'report/releases_without_language.tt';
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky
Copyright (C) 2012 MetaBrainz Foundation

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
