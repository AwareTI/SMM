
use strict;
use warnings;

use Test::More;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Temp qw/ tempfile /;
use Text::CSV_XS;
use Catalyst::Test q(WebSMM);

use HTTP::Request::Common;
use Package::Stash;
use Path::Class qw(dir);
use JSON;

my $stash = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user  = Iota::TestOnly::Mock::AuthUser->new;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {

    for my $invalido_nome (qw/invalido2.kml invalido3.kml invalido.kml /) {
        ( $res, $c ) = ctx_request(
            POST '/kml',
            'Content-Type' => 'form-data',
            Content        => [
                api_key   => 'test',
                'arquivo' => [ $Bin . '/' . $invalido_nome ],
            ]
        );
        ok( $res->is_success, 'OK' );
        is( $res->code, 200, 'upload done!' );

        is(
            $res->content,
            '{"error":"Unssuported KML\n"}',
            'nao suportado formato/invalido ' . $invalido_nome
        );
    }

    ( $res, $c ) = ctx_request(
        POST '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/municipio_ac.kml' ],
        ]
    );
    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );

    my $ret1 = eval { from_json( $res->content ) };
    is( @{ $ret1->{vec} }, 22, 'tem 22 vetores' );
    undef $ret1;

    ( $res, $c ) = ctx_request(
        POST $user1_uri. '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/ilhabela_municipios.kml' ],
        ]
    );
    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );
    $ret1 = eval { from_json( $res->content ) };

    is( @{ $ret1->{vec} }, 2, 'tem 2 vetores' );
    undef $ret1;

    ( $res, $c ) = ctx_request(
        POST $user1_uri. '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/municipio_teste.kml' ],
        ]
    );
    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );
    my $ret2 = eval { from_json( $res->content ) };
    is( @{ $ret2->{vec} }, 2, 'tem 2 vetores' );

    is_deeply(
        $ret2,
        {
            'vec' => [
                {
                    'latlng' => [
                        [ '-69.6214070', '-8.2150924' ],
                        [ '-69.5869513', '-8.2445153' ]
                    ],
                    'name' => undef
                },
                {
                    'latlng' => [ [ '-68.2793555', '-9.8218697' ] ],
                    'name' => undef
                }
            ]
        },
        'parse ok!'
    );

    ( $res, $c ) = ctx_request(
        POST $user1_uri. '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/sp_segundo_layout_sem_dados.kml' ],
        ]
    );
    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );
    $ret2 = eval { from_json( $res->content ) };
    is( @{ $ret2->{vec} }, 2, 'tem 2 vetores' );

    is_deeply(
        $ret2,
        {
            'vec' => [
                {
                    'latlng' => [
                        [ '-46.58166',  '-23.552155' ],
                        [ '-46.581659', '-23.552154' ]
                    ],
                    'name' => 'ÁGUA RASA'
                },
                {
                    'latlng' => [
                        [ '-46.714476', '-23.535314' ],
                        [ '-46.714221', '-23.535285' ]
                    ],
                    'name' => 'ALTO DE PINHEIROS'
                }
            ]
        },
        'parse ok!'
    );

    ( $res, $c ) = ctx_request(
        POST $user1_uri. '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/sp_segundo_layout.kml' ],
        ]
    );
    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );
    $ret2 = eval { from_json( $res->content ) };
    is( @{ $ret2->{vec} }, 96, 'tem 96 vetores' );

    ( $res, $c ) = ctx_request(
        POST $user1_uri. '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/sp_outro_layout.kml' ],
        ]
    );
    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );
    $ret2 = eval { from_json( $res->content ) };
    is( @{ $ret2->{vec} }, 289, 'tem 96 vetores' );

    ( $res, $c ) = ctx_request(
        POST $user1_uri. '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/sp_mais_um_outro.kml' ],
        ]
    );

    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );
    $ret2 = eval { from_json( $res->content ) };
    is( @{ $ret2->{vec} }, 96, 'tem 96 vetores' );

    ( $res, $c ) = ctx_request(
        POST $user1_uri. '/kml',
        'Content-Type' => 'form-data',
        Content        => [
            api_key   => 'test',
            'arquivo' => [ $Bin . '/mais-um.kml' ],
        ]
    );

    ok( $res->is_success, 'OK' );
    is( $res->code, 200, 'upload done!' );
    $ret2 = eval { from_json( $res->content ) };
    is( @{ $ret2->{vec} }, 5, 'tem 5 vetores' );

    die 'rollback';

};

die $@ unless $@ =~ /rollback/;

done_testing;
