package Group::Git::Cmd::Stats;

# Created on: 2013-05-10 07:05:17
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use version;
use Moose::Role;
use Carp;
use List::Util qw/max/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use File::chdir;
use Path::Tiny;
use Getopt::Alt;
use YAML::Syck;

our $VERSION = version->new('0.0.2');

my $opt = Getopt::Alt->new(
    {
        helper  => 1,
        help    => __PACKAGE__,
        default => {
            min => 1,
        },
    },
    [
        'by_email|by-email|e',
        'by_name|by-name|n',
        'by_date|by-date|d',
        'verbose|v+',
        'quiet|q!',
    ]
);

sub start_start {
    $opt->process;

    return;
}

my $collected = {};
sub stats {
    my ($self, $name) = @_;

    return unless -d $name;

    $opt->process if !%{ $opt->opt || {} };

    my $dir = path($CWD);

    local $CWD = $name;

    my $newest = qx{git log -n1 --format=format:"%H"};
    chomp $newest;
    my $cache = $dir->path('.stats', $newest . '.yml');
    $cache->parent->mkpath;
    if ( -f $cache ) {
        $collected->{$name} = LoadFile($cache);
        return;
    }

    my %stats;
    open my $pipe, '-|', q{git log --format=format:"%H';'%ai';'%an';'%ae"};

    while (my $log = <$pipe>) {
        chomp $log;
        my ($id, $date, $name, $email) = split q{';'}, $log, 4;
        $newest ||= $id;

        # dodgy date handling but hay
        $date =~ s/\s.+$//;

        $stats{count}++;
        $stats{date}{$date}++;
        $stats{name}{$name}++;
        $stats{email}{$email}++;
    }

    $cache = $dir->path('.stats', $newest . '.yml');
    DumpFile($cache, \%stats);

    $collected->{$name} = \%stats;

    return;
}

sub stats_end {
    DumpFile('stats.yml', $collected);

    my $type = $opt->opt->by_email ? 'email'
        : $opt->opt->by_name       ? 'name'
        : $opt->opt->by_date       ? 'date'
        :                            '';

    my %stats;
    for my $repo (keys %{ $collected }) {
        for my $item (keys %{ $collected->{$repo}{$type} }) {
            $stats{$item} += $collected->{$repo}{$type}{$item};
        }
    }

    my @items = sort { $stats{$a} <=> $stats{$b} } keys %stats;
    my $max   = max map {length $_} @items;
    for my $item (@items) {
        printf "%-${max}s %d\n", $item, $stats{$item};
    }

    return;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::Stats - Group-Git tools to show statistics accross many repositories

=head1 VERSION

This documentation refers to Group::Git::Cmd::Stats version 0.0.2

=head1 SYNOPSIS

   use Group::Git::Cmd::Stats;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Adds the stats command to L<Group::Git> which allows you to collect statistics
accross many repositories.

=head1 SUBROUTINES/METHODS

=head2 C<stats ($name)>

Collects the stats for each repository.

=head2 C<stats_end ()>

Outputs the stats results.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
