# Wed Aug  4 15:36:49 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Maildir::SubfolderAndSubfolders

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Maildir::SubfolderAndSubfolders;

use strict;
use Chj::xopendir;
use Carp;
use POSIX qw(EEXIST ENOTEMPTY);
use Chj::xopen 'xopen_read';
use Chj::xtmpfile;

use Class::Array -fields=> ('Me',
			    'Subfolders' #arrayrf, eh nein hashrf weil f�r record schnell zugriff auf alte objekte m�glich sein muss, key= (unquoted) name des childs.
			   );


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Me])=@_; # a Chj::Maildir::Subfolder
    $s
}


#($basedirectorypath,$basename)= .

# basename  .

#sub new_from_basename { <-- Subfolder.pm
#}
#sub new_from_basedirectorypath_basename { <-- Basefolder.pm
#}

# sub new_from_subbasename { # kette aller childs bilden und am schluss uns zur�ckgeben.  ALMOST copy from same method in Subfolder.pm
#     my $class=shift;
#     my ($parent,$subbasename)=@_;
#     if ($subbasename=~ s/^\.([^.]+)//s) {
# 	my $quotedname=$1;
# 	my $s=$class->new_quoted($parent,$quotedname);
# 	if (length $subbasename) {
# 	    $class->new_from_subbasename($s,$subbasename);
# 	}
# 	$s
#     } else {
# 	croak "new_from_subbasename: subbasename '$subbasename' does not match criteria";
#     }
# }

# sub record_subfolders { # record_scanning_for_subfolders
#     my $s=shift;
#     #my $basepath= $$s[Me]->basepath; # fla/Maildir/.blah.bluh.blam
#     my $basename= $$s[Me]->basename; # .blah.bluh.blam
#     my $basedirectorypath= $$s[Me]->basedirectorypath;
#     my $d=xopendir $basedirectorypath;
#     while(defined(my$item=$d->xnread)){
# 	#next unless /^\./;
# 	#next unless /^\Q$basename\E(.+)/s;
# 	# going to scan multiple times h�m?
# 	# try to be more efficient here: only scan the dir once.
# 	next unless /^\Q$basename\E\.(.+)/s;
# # 	my $rest=$1;
# # 	my $curpar=$s;
# # 	my $firstchild;
# # 	my $child;
# # 	for (split /\./,$rest) {
# # 	    my $child= Chj::Maildir::Subfolder->new_quoted($curpar,);
	
# }


# sub rename {
#     my $s=shift;
#     my ($newname)=@_;
#     my $basedirectorypath= $$s[Me]->basedirectorypath;
#     my $oldbasename= $$s[Me]->basename; # .blah.bluh.blam
#     $$s[Me]->set_name($newname);
#     my $newbasename= $$s[Me]->basename;
#     my $d=xopendir $basedirectorypath;
#     while(defined(my$item=$d->xnread)){
# 	next unless /^\Q$basename\E\.(.+)/s;
# 	#my $rest=$1;

# 	my $newname=$item;
# 	$newname=~ 
# 	xrename "$basedirectorypath/$item",
# 	  "$basedirectorypath/
#     }
# }

#^- shit isch nicht besser, weil weiss doch n�d wie regex aussehen muss f�r den rename, muss ja doch teile machen

sub add_from_subbasename { # f�ge kette aller childs bei
    my $s=shift;
    my ($subbasename)=@_;
    return unless length $subbasename;
    if ($subbasename=~ s/^\.([^.]+)//s) {
	my $quotedname=$1;
	my $smallchild=Chj::Maildir::Subfolder->new_quoted($$s[Me],$quotedname);
	my $childname=$smallchild->name;
	my $bigchild;
	if (my $old= $$s[Subfolders]{$childname}) {
	    # already done. take old object instead.
	    $bigchild=$old;
	} else {
	    $bigchild= ref($s)->new($smallchild);
	    $$s[Subfolders]{$childname}=$bigchild;
	}
	$bigchild->add_from_subbasename($subbasename);
    } else {
	croak "new_from_subbasename: subbasename '$subbasename' does not match criteria";
    }
}


sub record_subfolders { # record_scanning_for_subfolders
    my $s=shift;
    #my $basepath= $$s[Me]->basepath; # fla/Maildir/.blah.bluh.blam
    my $basename= $$s[Me]->basename; # .blah.bluh.blam
    my $basedirectorypath= $$s[Me]->basedirectorypath;
    my $d=xopendir $basedirectorypath;
    while(defined(my$item=$d->xnread)){
	# try to be efficient here: only scan the dir once.
	next unless $item=~/^\Q$basename\E(\..+)/s;#oh oh, n�d $_
	my $rest=$1;
	$s->add_from_subbasename($rest);
    }
    $d->xclose;
}

sub rename { # returns true if succeeded, false if the target already folder exists. exceptions on real errors (ist es etwa so dass man eigentlich nie exceptions trappen muss?)
    my $s=shift;
    my ($newname)=@_;
    # shit: vorhernachher. ein parent benennt sich um. childs nachziehen.
    # muss ich listen machen? kann ich nicht rekursiv.
    # luschtig, ob haskell (lazy eval?) hier helfen w�rde?
    # oder switcherei?  iterator, der next child, aber immer den parent der renamed werden soll mit f�hrt?.
    my $oldname= $$s[Me]->name;
#     {
# 	my $oldbasepath= $$s[Me]->basepath;
# 	$$s[Me]->set_name($newname);
# 	my $newbasepath= $$s[Me]->basepath;
# 	rename $oldbasepath,$newbasepath or do {
# 	    if ($!==EEXIST  or $!==ENOTEMPTY) {# latter only for obscure systems?
# 		return 0
# 	    } else {
# 		croak "rename: rename $oldbasepath,$newbasepath: $!";
# 	    }
# 	};
#     }
#     # iterator stuff:
#     my $do;
#     $do=sub {
# 	my ($self)=@_;
# 	#for my $child (values %{$$s[Subfolders]}) { NOPE
# 	for my $child (values %{$$self[Subfolders]}) {
# 	    $$s[Me]->set_name($oldname);
# 	    my $oldbasepath= $child->[Me]->basepath;
# 	    $$s[Me]->set_name($newname);
# 	    my $newbasepath= $child->[Me]->basepath;
# $DB::single=1;
# 	    rename $oldbasepath,$newbasepath or do {
# 		if ($!==EEXIST  or $!==ENOTEMPTY) {# latter only for obscure systems?
# 		    return 0
# 		} else {
# 		    croak "rename: rename $oldbasepath,$newbasepath: $!";
# 		}
# 	    };
# 	    $do->($child);
# 	}
#     };
    # read subsciptions (see also comment below):
    my $basedirectorypath= $$s[Me]->basedirectorypath;
    my $subscriptionfilepath= "$basedirectorypath/courierimapsubscribed";
    my $subscrs= xopen_read($subscriptionfilepath)->xcontent;
    my $original_subscrs=$subscrs;# for tracking changes

    # iterator stuff:
    eval {
	my $do;
	$do=sub {
	    my ($self)=@_;
	    $$s[Me]->set_name($oldname);
	    my $oldbasepath= $$self[Me]->basepath;
	    my $oldimapboxstring= $$self[Me]->imapboxstring;
	    $$s[Me]->set_name($newname);
	    my $newbasepath= $$self[Me]->basepath;
	    my $newimapboxstring= $$self[Me]->imapboxstring;
	    # hm I *could* put a rename method into Subfolder.pm, rename($newname,$optionalwhichelementtorename). which does $optionalwhichelementtorename->set_name($newname). And changes the subscription. But then there were inkoherent folders there: parent of that self is different from original/other parent. and how to make it not need to reopen the subscriptions file again for each step? thus do it here for time being.
	    rename $oldbasepath,$newbasepath or do {
		if ($!==EEXIST  or $!==ENOTEMPTY) {# latter only for obscure systems?
		    return 0
		} else {
		    croak "rename: rename $oldbasepath,$newbasepath: $!";
		}
	    };
	    $subscrs=~ s/^\Q$oldimapboxstring\E$/$newimapboxstring/m;
	    for my $child (values %{$$self[Subfolders]}) {
		$do->($child);
	    }
	};
	$do->($s);
    };
    my $E=$@;
    eval {
	my $tmp= xtmpfile $subscriptionfilepath,0666;
	$tmp->xprint ($subscrs);
	$tmp->xclose;
	#$tmp->xreplace_or_withmode($subscriptionfilepath,  ach, just use mode above on xtmpfile call
	$tmp->xrename($subscriptionfilepath);
    };
    if ($@) {
	if ($E) {
	    die "Two exceptions:\n1. ${E}2. $@";
	} else {
	    die $@;
	}
    }
    if ($E){
	die $E;
    }
}

#sub moveinto {  oder  sub { mergeinto  todo, und "saubere" exceptionoben oder returnwert



#sub DESTROY {   ##ps circular?
#    my $self=shift;
#    # �� dito rausschmeissen wenn nicht benutzt
#    $self->SUPER::DESTROY;
#}

1;