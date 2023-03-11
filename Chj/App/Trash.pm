# Wed Jun 25 00:40:40 2008  Christian Jaeger, christian at jaeger mine nu
#
# Copyright 2008-2023 by Christian Jaeger
# Published under the same terms as perl itself
#

=head1 NAME

Chj::App::Trash

=head1 SYNOPSIS

 use Chj::App::Trash;
 my $trash= new Chj::App::Trash;
 $trash->trash(@paths);
 #print Dumper $trash->ls; not yet impl.
 # ..

=head1 DESCRIPTION


=cut


package Chj::App::Trash;

use strict;
use utf8;

use Carp; #always. well. we pay the (electricity bill)
use POSIX 'EEXIST'; #dito.joyofprl.5.
use experimental 'signatures';
use Chj::FP::Memoize "memoize_thunk";
use Chj::xperlfunc 'dirname', 'basename';
use Digest;
use Chj::xrealpath;
use Sys::Hostname; # or Chj::Hostname ?

my $hostname = hostname;

sub sha256($str) {
    my $d = Digest->new("SHA-256");
    $d->add($str);
    $d->hexdigest
}

sub Mv { #rename would give 'Invalid cross-device link'
    if (fork) {
	wait;
    } else {
	exec '/bin/mv', '--', @_
    }
}


use FP::Struct [
    'trashdir',
    ] => qw(FP::Struct::Show);


sub trashdir($self) {
    $self->{trashdir}
        // $ENV{HOME}."/.trash"
        # lowercase now so that hopefully gnome won't move it.
}


sub maybe_create_trashdir($self) {
    my $path= $self->trashdir;
    if (mkdir $path, 0700) {
	1
    } else {
	my $errno= 0+$!;
	if ($errno == EEXIST) { ### silly if it did check for -e already above.
	    0
	} else {
	    croak "maybe_create_trashdir: could not create '$path': $!"
	}
    }
}


# For every dirname, use a separate trashdir; make the trashdir
# deterministically unique. Prepare it (meh).
sub trashbase_from_path($self, $path) {
    my $t = time;
    my $pid = $$;
    my $xpath = xrealpath(dirname $path);
    my $hash = sha256($xpath);
    my $trashdir = $self->trashdir;
    my $tbase1 = "$trashdir/$t.$pid.$hostname";
    mkdir $tbase1;
    my $tbase2 = "$tbase1/$hash";
    my $made_dir = mkdir $tbase2;
    # Record original path if not already
    symlink $xpath, "$tbase2.orig" or do {
        if ($made_dir) {
            die "can't create symlink at '$tbase2.orig': $!";
        }
        # Otherwise attempted to do it anyway for prev interrupt, but
        # no error if exists.
    };
    $tbase2
}


sub trash($self, @paths) {
    $self->maybe_create_trashdir;

    for my $path (@paths) {
	my $bn= basename $path;
	if ($bn eq '.') {
	    warn "Ignoring '$path' since the filename is just '.'\n";
	    next;
	}
	if ($bn eq '..') {
	    warn "Ignoring '$path' since the filename is just '..'\n";
	    next;
	}
        
        my $tbase = $self->trashbase_from_path($path);
	my $trashedpath= "$tbase/$bn";
	if (stat $trashedpath) {
	    die "BUG: path exists: '$trashedpath'";
	} else {
	    Mv($path, $trashedpath);
	}
    }
}


_END_
