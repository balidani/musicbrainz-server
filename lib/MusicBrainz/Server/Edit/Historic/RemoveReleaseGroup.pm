package MusicBrainz::Server::Edit::Historic::RemoveReleaseGroup;
use strict;
use warnings;

use base 'MusicBrainz::Server::Edit::Historic::NGSMigration';

sub ngs_class { 'MusicBrainz::Server::Edit::ReleaseGroup::Delete' }
sub edit_type { 68 }
sub edit_name { 'Remove release group' }

sub do_upgrade {
    my $self = shift;
    return {
        entity_id => $self->row_id,
        name      => $self->previous_value
    }
}

sub deserialize_previous_value {
    my ($self, $previous) = @_;
    return $previous;
}

sub deserialize_new_value {
    my ($self, $previous) = @_;
    return $previous;
}

1;

