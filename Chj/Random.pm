# Fri Mar  3 18:03:31 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Random

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Random;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(seed);

use strict;
use Carp ;

our $randev= "/dev/urandom";
sub seed {
    @_==1 or croak "expecting 1 argument";
    my ($length)=@_;
    open IN, "<$randev" or croak "could not open '$randev' for reading: $!";
    my $seed;
    my $len = read (IN,$seed,$length);
    if (! defined $len) {
	croak "could not read from '$randev': $!"; ##  eagain und so  ?
    }
    if (! $len) {
	croak "got eof from '$randev', how can this happen?";## signal interrupts?
    }
    if ($len == $length) {
	$seed
    } else {
	croak "couldn't read $length bytes from '$randev', got only $len";
    }
}


1