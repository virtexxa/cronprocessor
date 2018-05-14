package DB;

use strict;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(_connect _disconnect);


sub _connect {

	my $conf = shift;

        my $dsn = "DBI:$conf->{DB}->{db_type}:$conf->{DB}->{db_name};host=$conf->{DB}->{db_host};mysql_socket=$conf->{DB}->{db_sock}";
	my $dbh = DBI->connect("$dsn", "$conf->{DB}->{db_user}", "$conf->{DB}->{db_pass}", {'RaiseError' => 1});

	return ($dbh);

}


sub _disconnect {
	my $dbh = shift;
	$dbh->disconnect() if $dbh;
}



