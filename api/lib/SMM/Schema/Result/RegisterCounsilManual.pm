use utf8;

package SMM::Schema::Result::RegisterCounsilManual;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SMM::Schema::Result::RegisterCounsilManual

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp",
    "PassphraseColumn" );

=head1 TABLE: C<register_counsil_manual>

=cut

__PACKAGE__->table("register_counsil_manual");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'register_counsil_manual_id_seq'

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 phone_number

  data_type: 'text'
  is_nullable: 0

=head2 council

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "register_counsil_manual_id_seq",
    },
    "email",
    { data_type => "text", is_nullable => 0 },
    "phone_number",
    { data_type => "text", is_nullable => 0 },
    "council",
    { data_type => "text", is_nullable => 0 },
    "name",
    { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-24 06:23:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PZE/80sVOJV+h00OxhDwRg
with 'SMM::Role::Verification';
with 'SMM::Role::Verification::TransactionalActions::DBIC';
with 'SMM::Schema::Role::ResultsetFind';

use Data::Verifier;
use MooseX::Types::Email qw/EmailAddress/;
use SMM::Types qw /DataStr TimeStr/;

sub verifiers_specs {
    my $self = shift;
    return {
        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                email => {
                    required => 1,
                    type     => 'Str',
                },
                name => {
                    required => 0,
                    type     => 'Str',
                },
                phone_number => {
                    required => 1,
                    type     => 'Str',
                },
                council => {
                    required => 1,
                    type     => 'Str',
                },
            }
        ),
    };
}

sub action_specs {
    my $self = shift;
    return {
        update => sub {
            my %values = shift->valid_values;

            not defined $values{$_} and delete $values{$_} for keys %values;

            my $register_counsil_manual = $self->update( \%values );

            return $register_counsil_manual;
        },
    };
}
use Data::Section::Simple qw(get_data_section);
use Template;

use SMM::Mailer::Template;
use DateTime::Format::Strptime;

my $strp = DateTime::Format::Strptime->new(
    pattern   => '%d/%m/%y %T',
    locale    => 'pt_BR',
    time_zone => 'local',
);

my $tt = Template->new();

use DateTime;
use MIME::Base64 qw(decode_base64);

sub _build_email {
    my ( $self, $email, $title, $content ) = @_;

    my $data = '';

    my $wrapper = get_data_section('body.tt');

    my $env = {
        year => DateTime->now( time_zone => 'local' )->year,

        partner_name => 'b-metria',
        url          => 'http://192.168.1.161:5040',
        web_url      => 'http://192.168.1.161:5040',
        title        => $title

    };

    my $processed_content = '';
    $tt->process( \$content, $env, \$processed_content );
    $tt->process( \$wrapper, { content => $processed_content, %$env }, \$data );

    $email->attach(
        Type => 'text/html; charset=UTF-8',
        Data => $data,
    );

    $email->attach(
        Type     => 'image/png',
        Id       => 'logo.png',
        Encoding => 'base64',
        Data     => decode_base64( get_data_section('logo.png') ),
    );
    return $email;

}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;