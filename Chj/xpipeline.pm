# Sun Aug  1 15:15:38 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xpipeline

=head1 SYNOPSIS

=head1 DESCRIPTION


 rather unfinished! see Chj::IO::Pipeline docs. cj

 xxpipeline is subject to change.

=head1 TODO

 additionally to the todo list in Chj::IO::Pipeline:

 - xxpipeline should behave same for first (in fact last) child.

=cut


package Chj::xpipeline;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(xxpipeline
	      xreceiverpipeline
	      xreceiverpipeline_with_out_to
	     );
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;
use Chj::IO::Pipeline;
use Carp;
use Chj::xpipe;
use Chj::xperlfunc;

#sub xpipeline {

sub xreceiverpipeline {
    #Chj::IO::Pipeline->xreceiverpipeline_with_out_to(undef,@_);
    unshift @_,undef;
    unshift @_,'Chj::IO::Pipeline';
    goto &Chj::IO::Pipeline::xreceiverpipeline_with_out_to
}

sub xreceiverpipeline_with_out_to{
    unshift @_, 'Chj::IO::Pipeline';
    goto &Chj::IO::Pipeline::xreceiverpipeline_with_out_to
}

sub xxpipeline {
    if (@_>=2) {
	my $firstframe=shift;
	my $out= Chj::IO::Pipeline->xreceiverpipeline_with_out_to(undef,@_);
	my ($readerr,$writeerr)=xpipe;
	if (my $pid=xfork) {#  spinn ich??Found = in conditional, should be == at /usr/local/lib/perl/5.6.1/Chj/xpipeline.pm line 53.   heh kommt nur wenn sonst fehler kommen.
	#my $pid=xfork;
	#if ($pid){
	    $writeerr->xclose;
	    my $err= $readerr->xcontent;
	    if ($err) {
		croak __PACKAGE__."::xxpipeline: could not execute @$firstframe: $err";
	    }
	    waitpid $pid,0;
	    croak "xxpipeline: first child gave exit status (\$?) $?" unless $?==0;##endlich rausfinden wie ich das will genau, sollte doch stets splitted sein das h ding
	    $out->xxfinish;
	} else {
	    $out->xdup2(1);
	    # ps zum gl�ck kein close von $out n�tig, sonst w�rde mir destructor mit seinem wait reinfunken? isch das ein mess.  todo mal �berlegen ob wait dort raus oder was immer
	    # to_do2: ev hier auch noch das err ding machen f�r rausfinden was failed  done tja

	    no warnings;
	    exec @$firstframe;
	    $writeerr->xprint($!);
	    exit;
	}
    } elsif (@_==1) {
	xxsystem @{$_[0]}
    } else {
	croak "xxpipeline: missing arguments";
    }
}

1;