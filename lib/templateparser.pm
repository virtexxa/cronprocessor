package templateparser;

# This software is part of the cronprossecor
# (c) Bernd Hilmar 2018-05-07 - VIRTEXXA Cloud Services SRL
# https://virtexxa.com 
# https://ihost24.com 
# https://everymail.net
# Released under GNU GPLv3

use strict;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(parse);

sub parse {

	my $config = shift;
	my $var    = shift;

	# fetch css

	open(C, "<$config->{'cron'}->{'cron_html_template'}.css") or die "Template $config->{'cron'}->{'cron_html_template'}.css not found.\n";
	my @CSS = (<C>);
	close(C);

	foreach my $line (@CSS) {
		$line =~ s/[\t\n]//g;
		$line =~ s/^\ +//;
		$var->{'css'} .= $line if($line !~ /^\/\*/);
	}

	# add custom styles

	open(C, "<$config->{'cron'}->{'cron_html_template'}-custom.css");
        my @CCSS = (<C>);
        close(C);

        foreach my $line (@CCSS) {
                $line =~ s/[\t\n]//g;
                $line =~ s/^\ +//;
                $var->{'css'} .= $line if($line !~ /^\/\*/);
        }

	# calcuate copyright year
	$var->{'current_date'} =~ /^([0-9]{4})/;
	my $c_year = $1;
	$c_year = '2018 - ' . $c_year if($c_year > 2018);
	$var->{'c_years'} = $c_year;

	open(T, "<$config->{'cron'}->{'cron_html_template'}") or die "Template $config->{'cron'}->{'cron_html_template'} not found.\n";
	my @TEMPLATE = (<T>);
	close(T);

	my $content;

	foreach my $line (@TEMPLATE) {
		$line =~ /\[([a-z0-9\_\-]+)\]/;
		my $tag = $1;
		$line =~ s/\[$tag\]/$var->{$tag}/;
		$content .= $line;

	}


	return($content);
	


}


1;

