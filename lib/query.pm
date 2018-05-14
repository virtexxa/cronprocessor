package query;

use strict;
use warnings;
use Time::Local;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(select select_function insert update use_db db_delete _convert_time_to_unixtime _convert_unixtime_to_date);

sub select {
	
	my $dbh = shift;
	my $fields = shift;
	my $table  = shift;
	my $clause = shift;

	my $sth = $dbh->prepare("SELECT $fields  FROM $table $clause");
	if(!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }

	my (@db_fname, @db_fvalue);

	my $db_fname  = $sth->{'NAME'};
	my $cntfields = $sth->{'NUM_OF_FIELDS'};

	my @data;

	while (my $db_fvalue = $sth->fetchrow_arrayref) {

		my @record;

		for (my $i = 0; $i < $cntfields; $i++) {
            		push @record, $$db_fvalue[$i];
		}
		push @data, \@record;
    	}


	$sth->finish;

	return (@data);

}

sub select_function {

	my $dbh      = shift;
	my $function = shift;
	my $values   = shift;
	
	# usage: select_function($dbh, 'function', "$values");

	my $sth = $dbh->prepare("SELECT $function($values)");
	if(!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }

	my (@db_fname, @db_fvalue);

	my $db_fname  = $sth->{'NAME'};
	my $cntfields = $sth->{'NUM_OF_FIELDS'};

	my @data;

	while (my $db_fvalue = $sth->fetchrow_arrayref) {

		my @record;

		for (my $i = 0; $i < $cntfields; $i++) {
            		push @record, $$db_fvalue[$i];
		}
		push @data, \@record;
    	}


	$sth->finish;

	return (@data);

}

sub insert {

	no warnings 'uninitialized';

	my $dbh = shift;
	my $table  = shift;
	my $fields = shift;
	my $values = shift;
	my $return_id = shift;
	
	$return_id = 'RETURNING id' if($return_id);
	$return_id = undef if(!$return_id);
	
	# usage: insert($dbh, $table, 'field1, field2',"'$val1', '$val2'", 1*);  * optional use if field id is present and if you want to return the insert id

	# $dbh->do("INSERT INTO $table ($fields) VALUES ($values) $return_id");
	
	my $result;
	
	my $sth = $dbh->prepare("INSERT INTO $table ($fields) VALUES ($values) $return_id");
	if(!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }
	
	if($return_id) {
		while (my $row = $sth->fetchrow_hashref) {
			$result = $row->{id};
		}
	}
	
	return($result);

}

sub insert_select {
	
	my $dbh          = shift;
	my $table_insert = shift;
	my $table_select = shift;
	my $where_select = shift;
	
	my $sth = $dbh->prepare("INSERT INTO $table_insert (select * from $table_select WHERE $where_select)");
	if(!$sth->execute) { die "Error:" . $sth->errstr . "\n"; }
	

}

sub update {

	my $dbh = shift;
	my $table  = shift;
	my $fields = shift;
	my $where = shift;
	
	# usage: update($dbh, 'table', "field='new_value'", "id=id");

	$dbh->do("UPDATE $table SET $fields WHERE $where");

}

sub use_db {

	# usage = use_db($dbh, 'dbname');

	my $dbh = shift;
	my $dbname = shift;

	$dbh->do("USE $dbname");

}

sub db_delete {

	my $dbh = shift;
	my $table  = shift;
	my $where = shift;
	
	# usage: db_delete($dbh, 'table', 'id=$id');
	
	$dbh->do("DELETE FROM $table WHERE $where");

}


sub _convert_time_to_unixtime {

	my $giventime = shift; # sql date: YYYY-MM-DD HH:MM:SSSSS - returns 0 if date is not valid

	my $yy = substr($giventime,0,4) - 1900; 
	my $mm = substr($giventime,5,2);
	my $dd = substr($giventime,8,2);
	my $hh = substr($giventime,11,2);
	my $mn = substr($giventime,14,2);
	my $ss = substr($giventime,17,2);
		
	my @mdays = (0,31,28,31,30,31,30,31,31,30,31,30,31);
	return(0) if($mm < 1 || $mm > 12);
		
	# Leap year conditions
	if ($mm == 2) {
		if ($yy % 4 != 0) { $mdays[2] = 28; }
			elsif ($yy % 400 == 0) { $mdays[2] = 29; }
			elsif ($yy % 100 == 0) { $mdays[2] = 28; }
			else { $mdays[2] = 29; }
	}
	return(0) if($dd < 1 || $dd > $mdays[$mm]);
	
	$mm = $mm - 1;

	return(timelocal($ss, $mn, $hh, $dd, $mm, $yy));
	
}

sub _convert_unixtime_to_date {

	my $timestamp = shift;
	
	# usage: _convert_unixtime_to_date($var, time); # time can be any unix-timestamp or empty (if empty it takes the current time).
	# returns: sql date
	
	$timestamp = time if(!$timestamp);
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($timestamp);
	my $date = $year + 1900 . '-' . sprintf("%02d", $mon + 1) . '-' . sprintf("%02d", $mday) . ' ' . sprintf("%02d", $hour) . ':' . sprintf("%02d", $min) . ':' . sprintf("%02d", $sec);
	
	return($date);
}


1;

