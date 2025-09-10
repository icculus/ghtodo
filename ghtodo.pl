#!/usr/bin/perl -w

# sudo apt-get install libnet-github-perl

use warnings;
use strict;
use Net::GitHub;
use Net::GitHub::V3;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# Globals...
my $github = undef;  # Access handle for talking to GitHub (v3 API).
my $home = $ENV{'HOME'};
my $use_desc_file = 0;
my $desc_file_path = "$home/.ghtodo_desc.md";
my @labels = ();
my $milestone = undef;

# Config/commandline stuff...
my $title = undef;
my $description = undef;
my $github_token = undef;
my $github_username = undef;
my $github_reponame = undef;
my $editor = undef;

sub usage {
    print STDERR "USAGE: $0 <new_bug_title> [description]\n";
    exit(1);
}

sub parse_config_file {
    my $path = (defined $ENV{'GHTODO_CFGPATH'}) ? $ENV{'GHTODO_CFGPATH'} : $ENV{'HOME'} . '/.ghtodo';
    open(CFGIN, '<', $path) or die("Couldn't open '$path': $!\n");
    while (<CFGIN>) {
        chomp;
        s/\A\s+//;
        s/\s+\Z//;
        next if /\A\#/;
        if (/\A(.*?)\s*\=\s*(.*?)\Z/) {
            my $k = $1;
            my $v = $2;
            if ($k eq 'username') {
                $github_username = $v;
            } elsif ($k eq 'repo') {
                $github_reponame = $v;
            } elsif ($k eq 'token') {
                $github_token = $v;
            } elsif ($k eq 'editor') {
                $editor = $v;
            } else {
                die("Unknown config key '$k' in '$path'\n");
            }
        } else {
            die("Malformed config line in '$path'");
        }
    }
    close(CFGIN);

    $editor = $ENV{'EDITOR'} if not defined $editor;
}

sub parse_commandline {
    foreach (@ARGV) {
        $github_username = $1, next if (/\A\-\-username\=(.*)\Z/);
        $github_reponame = $1, next if (/\A\-\-repo\=(.*)\Z/);
        $github_token = $1, next if (/\A\-\-token\=(.*)\Z/);
        $editor = $1, next if (/\A\-\-editor\=(.*)\Z/);
        $title = $_, next if not defined $title;
        $description = $_, next if not defined $description;
        usage();
    }
    usage() if not defined $title;
}

sub auth_to_github {
    $github = Net::GitHub::V3->new(version => 3, access_token => $github_token, RaiseError => 1) or die("Failed to connect to GitHub v3: $!\n");
    #$github4 = Net::GitHub::V4->new(version => 4, access_token => $github_token, RaiseError => 1) or die("Failed to connect to GitHub v4: $!\n");
    my $u = $github->user->show();   # just so we have to talk to them at all.
    $github->set_default_user_repo($github_username, $github_reponame);
}

sub prepare_description {
    if ((defined $description) and ($description eq '--')) {
        $description = '';
        return;
    }

    my $do_stdin = ((defined $description) and ($description eq '-'));

    return if defined $description and not $do_stdin;

    my $fh = undef;
    if ($do_stdin) {
        $fh = *STDIN;
    } else {
        $use_desc_file = 1;
        my $path = $desc_file_path;
        if (! -f $path) {
            open(FH, '>', $path) or die("Can't open '$path': $!\n");
            print FH qq{


; labels=
; milestone=
; Lines that start with ';', like this one, are stripped before posting.
; Write any description for the new issue above, in Markdown.
; Leave this file blank to not provide a description.

};

            close(FH);
        }

        (system("$editor '$path'") == 0) or die("Launching '$editor' seems to have failed: $!\n");
        open($fh, '<', $path) or die("Couldn't open '$path': $!\n");
    }

    $description = '';
    while (<$fh>) {
        if (/\A\; labels\=(.*)/) {
            $1 =~ s/\A\s+//;
            $1 =~ s/\s+\Z//;
            @labels = split(/\s*,\s*/, $1);
            next;
        } elsif (/\A; milestone\=(.*)/) {
            $1 =~ s/\A\s+//;
            $1 =~ s/\s+\Z//;
            $milestone = $1;
            next;
        }
        next if /\A\;/;
        $description .= $_;
    }
    close($fh);

    #print("LABELS:"); my $sep = ' '; foreach (@labels) { print("$sep$_"); $sep = ', '; } print("\n");
    #print("MILESTONE: $milestone\n") if defined $milestone;
    #exit(0);
}

sub verify_config {
    die("Missing 'username' in config or commandline\n") if (not defined $github_username);
    die("Missing 'repo=' line in config or commandline\n") if (not defined $github_reponame);
    die("Missing 'token=' line in config or commandline\n") if (not defined $github_token);
    die("Missing 'editor=' line in config or commandline (or EDITOR env var)\n") if (not defined $editor);
}

sub post_new_issue {
    my %args = (
        'title' => $title,
        'body' => $description,
    );

    if (scalar(@labels) > 0) {
        $args{'labels'} = \@labels;
    }

    if (defined $milestone) {
        my $milestones = $github->issue->milestones();
        foreach (@$milestones) {
            $args{'milestone'} = $$_{'number'}, last if ($$_{'title'} eq $milestone);
        }
        die("Unknown milestone '$milestone'\n") if not defined($args{'milestone'});
    }

    my $issue = $github->issue->create_issue(\%args);
    unlink($desc_file_path) if ($use_desc_file);
    my $issue_number = int($$issue{'number'});
    print("https://github.com/$github_username/$github_reponame/issues/$issue_number\n");
}


# Mainline!

parse_config_file();
parse_commandline();
verify_config();
prepare_description();
auth_to_github();
post_new_issue();

# end of ghtodo.pl ...


