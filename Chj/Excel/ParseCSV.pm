# Wed Aug 31 14:30:04 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Excel::ParseCSV

=head1 SYNOPSIS

 use Chj::Excel::ParseCSV;
 use Chj::xopen 'xopen_read';
 use Chj::schemestring;
 my $s= new Chj::Excel::ParseCSV xopen_read("WdWPosts7korrigiertcj.csv");
 print "(\n";
 while(my $row= $s->getrow) {
     print "(", join(" ",map{schemestring $_} @$row),")\n";
 }
 print ")\n";

=head1 DESCRIPTION

Parse CSV files as written by MS Excel.

By default uses ; as column separator since the MS Excel program I'm using
is actually using those, not the comma, when being told to write CSV files.

getrow returns an array ref, or undef on eof.

(Why doesn't the emptylist trick work? because of empty lines, and it would be waste to copy the output list to a new array in the while loop just to be able to check against the number of items first.)

=cut


package Chj::Excel::ParseCSV;

use strict;

use Class::Array -fields=>
  -publica=>
  'port',
  'eof' #bool
  ;

use Carp;

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Port])=@_;
    $s
}

sub getchar {
    my $s=shift;
    if ($$s[Eof]) {
	die "getchar: eof reached";#shouldn't happen since getchar shouldn't be called then.
    } else {
	my $ch;
	if ($$s[Port]->xread($ch,1)) {
	    $ch
	} else {
	    undef
	}
    }
}

sub _dequote {
    my ($str)=@_;
    $str=~ s/\"\"/\"/sg;
    $str
}

sub getrow {
    my $s=shift;
    if ($$s[Eof]) {
	return;
    } else {
	my @row;
      FIELD: while(defined(my $ch=$s->getchar)) {
	    if ($ch eq "\n") {
		return \@row;
	    }
	    elsif ($ch eq ";") {
		push @row, "";
	    }
	    elsif ($ch eq "\"") {
		# quoted mode
		my $str="";
		while(defined(my $ch=$s->getchar)) {
		    if ($ch eq "\"") {
			if (defined(my $nextch=$s->getchar)) {
			    if ($nextch eq "\"") {
				$str.=$ch;
			    }
			    elsif ($nextch eq "\n") {
				# auch gleich abschluss der row
				push @row, _dequote $str;#
				return \@row;
			    }
			    elsif ($nextch eq ";") {
				push @row, _dequote $str;#
				next FIELD;
			    }
			    else {
				die "fehlerhafterinput";
			    }
			} else {
			    # #goto ENDEFIELD;
			    # #last;#last CHAR_OF_FIELD;
			    # #goto ENDEROW nein sogar ende file hum. alles klar hier loopts fangswieder von vorne an.
			    push @row, _dequote $str;#
			    $$s[Eof]=1;
			    carp __PACKAGE__."::getrow: warning: last line doesn't end in newline";
			    return \@row;
			    # # hei teufel warum immer noch loop?
			}
		    }
		    else  {
			$str.=$ch;
		    }
		}
	      ENDEFIELD:
		push @row, _dequote $str;#
		return \@row;
	    }
	    else {
		# non-quoted mode.
		my $str=$ch; #heps scho kool diese impliziten resp einfach trivialen konversionen  , char gibtsnich ist string..
		while(defined(my$ch=$s->getchar)){
		    if ($ch eq ";") {
			push @row, _dequote $str;#
			next FIELD;
		    }
		    elsif ($ch eq "\n") {
			push @row, _dequote $str;#
			return \@row;
		    }
		    else {
			$str.=$ch;
		    }
		}
		push @row, _dequote $str;#
		$$s[Eof]=1;
		carp __PACKAGE__."::getrow: warning: last line doesn't end in newline";
		return \@row;
	    }
	}
	$$s[Eof]=1;
	# only output a row in this missing-nl-on-last-line case if a field has actually been read
	if (@row) {
	    carp __PACKAGE__."::getrow: warning: last line doesn't end in newline";
	    #HMMM we only get here if it ends in the midst of a field. After a ; it leaves somewhere above.  of course.
	    return \@row;
	} else {
	    return
	}
    }
}


end Class::Array;