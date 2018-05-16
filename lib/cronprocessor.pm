package cronprocessor;

# This software is part of the cronprossecor
# (c) Bernd Hilmar 2018-05-07 - VIRTEXXA Cloud Services SRL
# https://virtexxa.com 
# https://ihost24.com 
# https://everymail.net
# Released under GNU GPLv3

use strict;
require Exporter;

use query;
use DB;
use CGI;
use CGI::Carp qw(fatalsToBrowser set_message carpout);

our @ISA = qw(Exporter);
our @EXPORT = qw(process unescape_value escape_value);

sub process {

	my $config = shift;

	my $var = getvars();

	$var->{'current_date'} = _convert_unixtime_to_date();
	$var->{'slug'} = ucfirst($config->{'cron'}->{'slug'});
	$var->{'company'} = $config->{'cron'}->{'company'};
	$var->{'cron_viewer_link'} = $config->{'cron'}->{'cron_viewer_link'};
	$var->{'cron_viewer_ajax'} = $config->{'cron'}->{'cron_viewer_ajax'};

	$var->{'period_start'} =~ m/([0-9]{4}\-[0-9]{2}\-[0-9]{2})/;
	my $period_start = $1;

	$var->{'period_end'} =~ m/([0-9]{4}\-[0-9]{2}\-[0-9]{2})/;
	my $period_end = $1;

	my ($date_start, $date_end);

	if(!$period_start) {
		my $ts_current = _convert_time_to_unixtime($var->{'current_date'});
		my $ts_start = $ts_current - 86400;
		$date_start = _convert_unixtime_to_date($ts_start);
		$period_start = $date_start;
		$period_start  =~ s/\ [0-9]{2}\:[0-9]{2}\:[0-9]{2}$//;
	} else {
		$date_start = $period_start . ' 00:00:00';
	}
	if($period_end) {
		$date_end = $period_end . ' 23:59:59';
		my $time_start = _convert_time_to_unixtime($date_start);	
		my $time_end = _convert_time_to_unixtime($date_end);
		if($time_end < $time_start) {
			$date_end = $date_start;
			$date_end =~ s/00\:00\:00/23\:59\:59/;
			$period_end = $period_start;
		}
	} else {
		$date_end = $var->{'current_date'};
		$period_end = $date_end;
		$period_end =~ s/\ [0-9]{2}\:[0-9]{2}\:[0-9]{2}$//;
	}

	$var->{'period_start'} = $period_start;
	$var->{'period_end'} = $period_end;
	$var->{'date_start'} = $date_start;
	$var->{'date_end'} = $date_end;

	my @crons;

	my $dbh = _connect($config);
        use_db($dbh, 'cron');

	my $where;
	if($var->{'keyword'}) {
		# find a keyword match
		my ($req_status, $keyword);
		
		$keyword = $var->{'keyword'};

		($req_status, $keyword) = split("\:", $var->{'keyword'}) if($var->{'keyword'} =~ /\:/);
		
		if($var->{'keyword'} eq "error" || $var->{'keyword'} eq "warning" || $var->{'keyword'} eq "notice") {
			$req_status = $keyword;
			$keyword = undef;
		}
		
		$where = qq~timestamp > '$date_start' AND timestamp < '$date_end' AND (cronjob LIKE '%$keyword%' OR hostname LIKE '%$keyword%')~ if($keyword);
		$where = qq~timestamp > '$date_start' AND timestamp < '$date_end' AND (cronjob LIKE '%$keyword%' OR hostname LIKE '%$keyword%') AND status = '$req_status'~ if($keyword && $req_status);
		$where = qq~timestamp > '$date_start' AND timestamp < '$date_end' AND status = '$req_status'~ if(!$keyword && $req_status);
	} else {
		$where = qq~timestamp > '$date_start' AND timestamp < '$date_end'~;
	}

	my @selectcrons = select($dbh, 'timestamp,hostname,cronjob,status,id', 'cronjobs', "WHERE $where ORDER BY timestamp ASC");

        foreach my $record (@selectcrons) {

                my @fields = @{$record};
                        my $cron;
                        $cron->{'timestamp'}    = $fields[0];
                        $cron->{'hostname'}     = unescape_value($fields[1]);
                        $cron->{'cronjob'}      = unescape_value($fields[2]);
                        $cron->{'status'}       = $fields[3];
			$cron->{'id'}		= $fields[4];
                        #$cron->{'cron_content'} = $fields[4];
                        push @crons, $cron;

        }

	# set counters

	foreach my $cron (@crons) {
		$var->{'crons_in_period'}++;
		$var->{'cron_notices'}++ if($cron->{'status'} eq "notice");
		$var->{'cron_warnings'}++ if($cron->{'status'} eq "warning");
		$var->{'cron_errors'}++ if($cron->{'status'} eq "error");
		
	}
	$var->{'crons_in_period'} = '0' if(!$var->{'crons_in_period'});
	$var->{'cron_notices'} = '0' if(!$var->{'cron_notices'});
	$var->{'cron_warnings'} = '0' if(!$var->{'cron_warnings'});
	$var->{'cron_errors'} = '0' if(!$var->{'cron_errors'});

	my ($keyword,$add_keyword);
	my ($att, $foundkeyword) = split(":", $var->{'keyword'}) if($var->{'keyword'} =~ /:/);
	if($foundkeyword) {
		$keyword = $foundkeyword;
	} else {
		$keyword = $var->{'keyword'};
	}
	$add_keyword = ":$keyword" if($keyword);

	$var->{'cron_notices'} = qq~<a href="$var->{'cron_viewer_link'}?keyword=notice$add_keyword&period_start=$var->{'period_start'}&period_end=$var->{'period_end'}">$var->{'cron_notices'}</a>~ if($var->{'cron_notices'} > 0);
	$var->{'cron_warnings'} = qq~<a href="$var->{'cron_viewer_link'}?keyword=warning$add_keyword&period_start=$var->{'period_start'}&period_end=$var->{'period_end'}">$var->{'cron_warnings'}</a>~ if($var->{'cron_warnings'} > 0);
	$var->{'cron_errors'} = qq~<a href="$var->{'cron_viewer_link'}?keyword=error$add_keyword&period_start=$var->{'period_start'}&period_end=$var->{'period_end'}">$var->{'cron_errors'}</a>~ if($var->{'cron_errors'} > 0);

	$var->{'cronjob_list'} = build_table($config, \@crons, $var);

	
	

	# returns the table list in the selected period and all template variables
	# [period_start]	- date
	# [period_end]		- date
	# [crons_in_period]	- counter
	# [cron_notices]	- counter
	# [cron_warnings]	- counter
	# [cron_errors]		- counter
	# [cronjob_list]	- table



	return($var);

}

sub build_table {

        my $config = $_[0];
        my @crons = @{$_[1]};
	my $var = $_[2];

        my ($table, $startddate, $enddate, $i);

        foreach my $rec (@crons) {

                my($timestamp, $hostname, $cronjob, $status);

                $i++;
		my $color;
		my $id;

                foreach my $key (keys %{$rec}) {

			$id = $rec->{'id'} if($key eq "id");

                        $timestamp = $rec->{'timestamp'} if($key eq "timestamp");
                        $hostname = substr($rec->{'hostname'},0,16) if($key eq "hostname");
			$hostname .= '...' if(length($rec->{'hostname'}) > 16 && $key eq "hostname");

                        if($key eq "cronjob") {
				$rec->{'cronjob'} =~ s/[\(\)]//g;
                                $rec->{'cronjob'} =~ m/\/([a-zA-Z0-9\.\-\_\ \|\*\<\>\:\"\&]+)$/;
                                $cronjob = substr($1,0,20);
				$cronjob .= '...' if(length($1) > 20);
                        }

                        if($key eq "status") {

				$color = 'GoldenRod' if($rec->{'status'} eq "notice");
				$color = 'DarkOrange' if($rec->{'status'} eq "warning");
				$color = 'red' if($rec->{'status'} eq "error");
			

                                $status = "<span class='status ok'></span>" if($rec->{'status'} eq "ok");
                                $status = "<span class='status notice '></span>" if($rec->{'status'} eq "notice");
                                $status = "<span class='status warning'></span>" if($rec->{'status'} eq "warning");
                                $status = "<span class='status error'></span>" if($rec->{'status'} eq "error");
                        }


                }
                $table .= "<tr class='table_row'><td>$timestamp</td><td>$hostname</td><td class=''><a href='#' id='$id'>$cronjob</a></td><td>$status</td></tr>\n" if(!$color);
		$table .= "<tr class='table_row'><td style='color: $color'>$timestamp</td><td style='color: $color'>$hostname</td><td class='' style='color: $color'><a href='#' id='$id'>$cronjob</a></td><td>$status</td></tr>\n" if($color);


        }

	if(!$i) {
		my $message;
		$message = qq~<p class="tablelist-title">Nothing found for "$var->{'keyword'}"<br />in the period from $var->{'date_start'} to $var->{'date_end'}</p>~ if($var->{'keyword'});
		$message = qq~<p class="tablelist-title">Nothing found<br />in the period from $var->{'date_start'} to $var->{'date_end'}</p>~ if(!$var->{'keyword'});
		return($message);
	}

	my $searchinfo;
	$searchinfo = "<br />Search: $var->{'keyword'}" if($var->{'keyword'});
        my $body =qq~<p class="tablelist-title">Cronjobs from $var->{'date_start'} to $var->{'date_end'}$searchinfo</p>~;
        $body .= '<table id="cronjoblist">';
        $body .= "<tr><th>execution time</th><th>host</th><th>cronjob name</th><th>status</th></tr>\n$table";


        $body .= "</table>";

        return($body);
}


sub getvars {

        my $qstring = shift;

        my $var;

        my $cgi = new CGI;

        return($var) unless $cgi->param;

        foreach my $param ($cgi->param) {
                my $name = $cgi->escapeHTML($param);
                foreach my $value ($cgi->param($param)) {
                        $var->{$name} = escape_value($value);
                }
        }

        return($var);

}

sub escape_value {

        my $val = shift;

        $val =~ s/\<(.*)\>//mg; # strip any html tags # html not allowed
        $val =~ s/[\'\`\~\´]//mg;
        $val =~ s/\"\(\)\{\}/\\\"\\\(\\\)\\\{\\\}/mg;

        return($val);

}

sub unescape_value {

        my $val = shift;

        $val =~ s/\\\"\\\(\\\)\\\{\\\}/\"\(\)\{\}/mg;

        return($val);

}


1;


