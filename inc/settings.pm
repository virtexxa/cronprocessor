package settings;

use strict;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(_config);

sub _config {

	my $rootpath = shift;

	my %conf = (
		'DB'	=> { 	get_db_config($rootpath), },
		'cron'	=> {	
				# to addresses: for all non cron emails 
				# and recipients of the digest email
				# multiple addresses are comma seperated.
				'sysadmin'	=> 'bernd@virtexxa.com',

				# sender address
				'from'		=> 'system@ihost24.com',

				# Company or Service Name
				'company'	=> 'VIRTEXXA Cloud Services SRL',

				# slug (shortname)
				'slug'		=> 'virtexxa',

				# Enter here path of cronscripts you do not want to be saved to the database.
				# instead of to be added to the database, the cron mail will be delivered normally.
				'ignore'	=> {
							'domain_handlers/at.pl'		=> undef,
							'cron/sendWelcomeMail'		=> undef,
							'check_hosts_for_reboot'	=> undef,
				},

				# Add here strings that should be stripped from the cron name (found in the subject)
				# and used as cron name.
				'strip'		=> {
							'/usr/bin/perl '	=> 1,
							'/usr/bin/php '		=> 1,
							'php -q '		=> 1,
							'test -x '		=> 1,
							'/bin/bash '		=> 1,
				},

				# path to templates and links

				'cron_html_template' 	=> $rootpath . '/templates/HTML/cron_viewer',
				'cron_viewer_link'	=> 'https://manage.ihost24.com/_tools/cronprocessor/cron_viewer',
				'cron_viewer_ajax'	=> 'https://manage.ihost24.com/_tools/cronprocessor/ajax/get_cronjob?id=',

				# DELETE old cronjobs
				# you can define a value in days, when you want to delete old cronjobs.
				# if you leave this value blank, cronjobs will never be deleted from the database.
				# The delete works in the "cron_digest". Ensure that you defined a cronjob once the day
				# for the digest. If no cronjob for "cron_digest" is defined, the deletion of old jobs
				# will not work. Due to performance issues the deletion does not work on every execution,
				# at least there is a timeframe of 5 days, so the deletion is only executed every 5 days.

				'delete_old_after_days'	=> '1095', # value in days: for example 356 = delete jobs after 1 year
								   # 1068 = 3 years
						
		},
	);

	
	return(\%conf);
}

sub get_db_config {

	my $root = shift;

	my %conf;

	if(-e "$root/inc/config") {
		open(C, "<$root/inc/config");
                while (<C>) {
                        next if($_ eq "\n" || $_ =~ /^\#/);
                        if($_ !~ /[\[\]]/) {
                                my ($att, $value) = split("=", $_);
                                chomp($value);
                                $conf{"$att"} = $value;
				error("<h2>Configuration error!</h2><p>There seems to be an error in your configuration.<br />Please check the file $root/inc/config</p>") if(!$value);
                        }
		}
		close(C);
		return(%conf);


	} else {
		error("<h2>Configuration not found!</h2><p>The configuration file could not be found.<br />The file $root/inc/config must exist.</p>");
	}


}


sub error {

	my $text = shift;

	print "Content-type: text/html\n\n";
	print $text;
	exit;

}

1;
