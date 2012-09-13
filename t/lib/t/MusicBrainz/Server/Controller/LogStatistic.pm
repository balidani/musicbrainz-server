package t::MusicBrainz::Server::Controller::LogStatistic;

use Test::Routine;
use Test::More;
use MusicBrainz::Server::Test qw( html_ok );
use DateTime::Format::Pg;

with 't::Context', 't::Mechanize';

test 'Can load log statistics' => sub {
    my $test = shift;
    
    MusicBrainz::Server::Test->prepare_test_database($test->c);

    $test->mech->get_ok('/log-statistics');
    html_ok($test->mech->content);
    $test->mech->content_like(qr{Log Statistics});
    
};

test 'Can load categories' => sub {
    my $test = shift;
    my $c = $test->c;
    my $categories = $c->model('LogStatistic')->get_categories;
    
    MusicBrainz::Server::Test->prepare_test_database($test->c);
    
    foreach my $category ( @$categories ) {
        $test->mech->get_ok('/log-statistics/' . lc($category));
        html_ok($test->mech->content);
        
        $category =~ s/[^a-zA-Z0-9]/./g;
        $test->mech->content_like(qr{$category});
    }
};

test 'Can load json data' => sub {
    my $test = shift;
    my $c = $test->c;
    
    MusicBrainz::Server::Test->prepare_test_database($test->c);
    
    my $query = "SELECT category, name, timestamp FROM " 
        . $c->model('LogStatistic')->_table 
        . " LIMIT 1";
    
    my $row = $c->sql->select_single_row_hash($query);
    my $dt = DateTime::Format::Pg->parse_datetime($row->{timestamp});
    my $epoch = $dt->epoch;
    
    $test->mech->get_ok('/log-statistics/json/' . $row->{category} . '/' . $row->{name} . '/' . $epoch);
    html_ok($test->mech->content);
    $test->mech->content_like(qr{data});
};

1;
