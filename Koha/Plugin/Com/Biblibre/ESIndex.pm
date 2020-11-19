package Koha::Plugin::Com::Biblibre::ESIndex;

use Modern::Perl;

use C4::Biblio;
use Business::ISBN;

use base qw(Koha::Plugins::Base);

our $VERSION = '1.0';

our $metadata = {
    name => 'ES Index Language',
    author => 'Alex Arnaud <alex.arnaud@biblibre.com>',
    description => 'Elasticsearch Indexing plugin for languages',
    date_authored => '2020-11-13',
    date_updated => '2020-11-13',
    minimum_version => '18.05.00.000',
    maximum_version => undef,
    version => $VERSION,
};

our $plugins = {
    index_lang => {
        name => 'Language',
        method => 'lang'
    },
    delete_dash => {
        name => 'Remove dash',
        method => 'remove_dash'
    },
    isbn => {
        name => 'ISBN',
        method => 'isbn'
    },
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub elasticsearch_index_plugins {
    my ($self) = @_;

    return $plugins;
}

sub lang {
    my ($self, $values) = @_;

    my $new_values = [];
    foreach my $value ( @$values ) {
        my $lang = GetAuthorisedValueDesc('','',$value,'','','LANG');
        push @{ $new_values }, $lang ? $lang : $value;
    }

    return $new_values;
}

sub remove_dash {
    my ($self, $values) = @_;

    my $new_values = [];
    foreach my $value ( @$values ) {
        $value =~ s/-//g;
        push @{ $new_values }, $value;
    }

    return $new_values;
}

sub isbn {
    my ($self, $values) = @_;

    my $new_values = [];
    foreach my $i ( @$values ) {
        my $isbn = Business::ISBN->new( $i );
        if($isbn) {
            if ( my $isbn10 = $isbn->as_isbn10 ) {
                my $isbn_string = $isbn10->as_string;
                push @{ $new_values }, $isbn_string;
                $isbn_string =~ s/-//g;
                push @{ $new_values }, $isbn_string;
            }
            if ( my $isbn13 = $isbn->as_isbn13 ) {
                my $isbn_string = $isbn13->as_string;
                push @{ $new_values }, $isbn_string;
                $isbn_string =~ s/-//g;
                push @{ $new_values }, $isbn_string;
            }
        } else {
            # It's not a valid ISBN but we want to index it anyway
            my $value = $i;
            push @{ $new_values }, $value;
            if($value =~ /-/) {
                $value =~ s/-//g;
                push @{ $new_values }, $value;
            }
        }
    }

    return $new_values;
}
