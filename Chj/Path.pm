#
# Copyright 2011 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Path

=head1 SYNOPSIS

=head1 DESCRIPTION

Not sure why I'm creating something from scratch here.

Well, I just realize that Chj/Path/Calc.pm has broken handling of "//"
I think.

And where did I do it previously? Maildir?

This doesn't access the file system, and it doesn't resolve
"..". These are things that have to be implemented by the user.

=cut


package Chj::Path;

use strict;

use Class::Array -fields=>
  -publica=>
  'segments', # array of str not containing slashes
  'has_endslash', # bool, whether the path is forcibly specifying a
                  # dir by using a slash at the end (forcing a dir by
                  # ending in "." isn't setting this flag)
  'is_absolute', # bool
  ;


sub new {
    my $cl=shift;
    bless [@_], $cl
}

sub new_from_string {
    my $cl=shift;
    my ($str)=@_;
    my @p= split m{/+}, $str;
    $cl->new(\@p,
	     scalar $str=~ m{/$}s,
	     scalar $str=~ m{^/}s)
}

sub string_without_endslash {
    my $s=shift;
    join("/",@{$$s[Segments]})
}

sub string {
    my $s=shift;
    my $str= $s->string_without_endslash;
    if ($s->has_endslash) {
	if (length $str) {
	    $str."/"
	} else {
	    if ($s->is_absolute) {
		"/"
	    } else {
		# force using ".", XX hmm but yes no other way
		"./"
	    }
	}
    } else {
	if (length $str) {
	    $str
	} else {
	    # PS. if I would split ..,1, then I could do away with
	    # this test (and also some others), right?
	    if ($s->is_absolute) {
		"/"
	    } else {
		"."
	    }
	}
    }
}

# remove "." entries: (leave ".." in, because these cannot be resolved
# without knowing the file system, right?)
sub clean {
    my $s=shift;
    my $cl= ref $s;
    bless [
	   [
	    grep {
		not ($_ eq ".")
	    } @{$$s[Segments]}
	   ],
	   # set forced dir flag if the last segment was a ".", even
	   # if previously it didn't end in "/"
	   ($$s[Has_endslash]
	    or
	    do {
		if (defined (my $last= ${$$s[Segments]}[-1])) {
		    $last eq "."
		} else {
		    0
		}
	    }),
	   @$s[2..$#$s]
	  ], $cl;
}

sub add_segment { # functionally. hm.
    my $s=shift;
    my ($segment)=@_;
    die "segment contains slash: '$segment'" if $segment=~ m{/};
    my $cl= ref $s;
    bless [
	   [
	    @{$$s[Segments]},
	    $segment
	   ],
	   0, # no forced endslash anymore
	   @$s[2..$#$s]
	  ], $cl;
}

sub dirname { # functional
    my $s=shift;
    my $seg= $$s[Segments];
    @$seg or die "can't take dirname of empty path";
    my $cl= ref $s;
    bless [
	   [
	    @{$seg}[0..($#$seg-1)]
	   ],
	   0, # no forced endslash anymore
	   @$s[2..$#$s]
	  ], $cl;
}

sub to_relative {
    my $s=shift;
    die "is already relative" unless $s->is_absolute;
    my $seg= $$s[Segments];
    my $cl= ref $s;
    bless [
	   [
	    # drop first entry
	    @{$seg}[1..($#$seg)]
	   ],
	   scalar $s->has_endslash, # XX hm always? what about the dropping of first entry?
	   0, # not absolute
	   @$s[3..$#$s]
	  ], $cl;
}

sub contains_dotdot {
    my $s=shift;
    for my $segment (@{$$s[Segments]}) {
	return 1 if $segment eq ".."
    }
    0
}

end Class::Array;

__END__

  tests:
calc> :l (new_from_string Chj::Path "hello//world/you")->string
hello/world/you
calc> :l (new_from_string Chj::Path "/hello//world/you")->string
/hello/world/you
calc> :l (new_from_string Chj::Path "/hello//world/you/")->string
/hello/world/you/
calc> :l (new_from_string Chj::Path "/")->string
/
calc> :l (new_from_string Chj::Path ".")->string
.
calc> :l (new_from_string Chj::Path "./")->string
./
calc> :l (new_from_string Chj::Path "./")->clean->string
./
calc> :l (new_from_string Chj::Path "./..")->string
./..
calc> :l (new_from_string Chj::Path "./..")->clean->string
..

calc> :l (new_from_string Chj::Path "./foo/../bar/.//baz/.")->clean->string
foo/../bar/baz/
calc> :d (new_from_string Chj::Path "")->clean->string
$VAR1 = '';
# XX should this be an error?

calc> :l (new_from_string Chj::Path ".")->string
.
calc> :d (new_from_string Chj::Path ".")->clean->string
$VAR1 = './';

calc> :l (new_from_string Chj::Path "/")->string
/
calc> :l (new_from_string Chj::Path "/")->clean->string
/
calc> :l (new_from_string Chj::Path "/.")->clean->string
/
calc> :l (new_from_string Chj::Path "/./")->clean->string
/
calc> :l (new_from_string Chj::Path "/./")->string
/./
calc> :l (new_from_string Chj::Path "/.")->string
/.

calc> :l (new_from_string Chj::Path "/.")->contains_dotdot
0
calc> :l (new_from_string Chj::Path "foo/bar/../baz")->contains_dotdot
1
calc> :l (new_from_string Chj::Path "../baz")->contains_dotdot
1
calc> :l (new_from_string Chj::Path "baz/..")->contains_dotdot
1
calc> :l (new_from_string Chj::Path "baz/..")->clean->contains_dotdot
1

calc> :d Chj::Path->new_from_string(".")->clean->dirname
can't take dirname of empty path at /usr/local/lib/site_perl/Chj/Path.pm line 124.
calc> :d Chj::Path->new_from_string("foo")->clean->dirname->string
$VAR1 = '.';
calc> :d Chj::Path->new_from_string("foo/bar")->clean->dirname->string
$VAR1 = 'foo';
calc> :d Chj::Path->new_from_string("")->dirname
can't take dirname of empty path at /usr/local/lib/site_perl/Chj/Path.pm line 134.

calc> :d Chj::Path->new_from_string(".")->clean->has_endslash
$VAR1 = 1;
calc> :d Chj::Path->new_from_string(".")->clean->string
$VAR1 = './';
#ok
calc> :d Chj::Path->new_from_string("")->clean->has_endslash
$VAR1 = 0;
calc> :d Chj::Path->new_from_string("")->clean->string
$VAR1 = '.';
#h

calc> :d Chj::Path->new_from_string("/foo")->to_relative->string
$VAR1 = 'foo';
calc> :d Chj::Path->new_from_string("/")->to_relative->string
$VAR1 = './';
calc> :d Chj::Path->new_from_string("")->to_relative->string
is already relative at /usr/local/lib/site_perl/Chj/Path.pm line 147.
calc> :d Chj::Path->new_from_string("/foo/")->to_relative->string
$VAR1 = 'foo/';