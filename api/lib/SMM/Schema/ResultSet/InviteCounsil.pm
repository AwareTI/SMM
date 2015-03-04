package SMM::Schema::ResultSet::InviteCounsil;
use namespace::autoclean;

use utf8;
use Moose;
extends 'DBIx::Class::ResultSet';
with 'SMM::Role::Verification';
with 'SMM::Role::Verification::TransactionalActions::DBIC';
with 'SMM::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use MooseX::Types::Email qw/EmailAddress/;

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                organization_id => {
                    required => 1,
                    type     => 'Int',
                },
                hash => {
                    required => 0,
                    type     => 'Str',
                },
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $r = shift;
                        return 0
                          if (
                            $self->find(
                                { email => lc $r->get_value('email') }
                            )
                          );
                        return 1;
                    }
                },
            },
        ),
        login => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required => 1,
                    type     => EmailAddress
                },
                password => {
                    required => 1,
                    type     => 'Str',
                },
            }
        ),
        check_email => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required => 1,
                    type     => EmailAddress
                }
            }
        ),
    };
}

use String::Random qw(random_regex);
use Template;
use Data::Section::Simple qw(get_data_section);
use SMM::Mailer::Template;
use DateTime::Format::Strptime;

my $strp = DateTime::Format::Strptime->new(
    pattern   => '%d/%m/%y %T',
    locale    => 'pt_BR',
    time_zone => 'local',
);
my $tt = Template->new( EVAL_PERL => 0 );

# cache of escaped characters
our $URI_ESCAPES;

sub uri_filter {
    my $text = shift;

    $URI_ESCAPES ||= { map { ( chr($_), sprintf( "%%%02X", $_ ) ) } ( 0 .. 255 ), };

    if ( $] >= 5.008 && utf8::is_utf8($text) ) {
        utf8::encode($text);
    }

    $text =~ s/([^A-Za-z0-9\-_.!~*'()])/$URI_ESCAPES->{$1}/eg;
    $text;
}

sub action_specs {
    my $self = shift;
    return {
        create => sub {
            my %values = shift->valid_values;

#            my $user = $self->schema->resultset('InviteCounsil')->search( { email => $values{email} } )->first;

            my $key = random_regex(q([a-zA-Z0-9]{20}));

            $key = random_regex(q([a-zA-Z0-9]{20}))
              while ( $self->search( { hash => $key },{ rows => 1 } )->next );

			$values{hash} = $key;
            my $invite_counsil = $self->create(
                {
                    organization_id  => $values{organization_id},
                    hash             => $values{hash},
                    email            => $values{email}
                }
            );

            my $body = '';

            my $wrapper = get_data_section('invite_counsil.tt');
            $tt->process(
                \$wrapper,
                {
                    date             => DateTime->now( formatter => $strp, time_zone => 'local' ),
                    web_url          => '[% web_url %]',
					secret_key       => $key,
					email            => $values{email},
					organization_id  => $values{organization_id},
                    email_uri        => &uri_filter( $values{email} )
                },
                \$body
            );
            my $title = 'b-metria: Solicitação de nova senha';
            my $email = SMM::Mailer::Template->new(
                to      => $invite_counsil,
                from    => q{"b-metria" <no-reply@b-metria.com.br>},
                subject => $title,
                content => $body,
                title   => 'Convite - De Olho Nas Metas',

            )->build_email;
			return 1;
            $self->result_source->schema->resultset('EmailQueue')
              ->create( {  body => $email->as_string, title => $title } );

            return 1;
        },
    };
}

1;

__DATA__

@@ invite_counsil.tt

<div style="font-family: arial, verdana; color: #333333;">

<p>Caro(a) usuário(a),</p>

<p>Email: [% email %]</p>

<p>Data: [% date %]</p>
<p> Código: [% secret_key %]</p>

<p>Para efetuar a alteração, basta acessar o link abaixo e digitar a
nova senha de acesso, este acesso é válido apenas pelas 2 horas
seguintes a solicitação realizada através do sistema da b-datum.</p>


<p><a href="[% web_url %]/cadastro?key=[% secret_key  %]&email=[%email_uri%]">
  [% web_url %]/cadastro?key=[% secret_key %]&email=[%email_uri%]&organization_id=[%organization_id%]</a></p>

<p>Caso você não tenha solicitado esta alteração de senha, acima
encontram-se informações sobre o horário e o endereço IP da máquina de
onde partiu a solicitação.</p>

</div>



