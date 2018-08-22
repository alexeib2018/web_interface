#!/usr/bin/env perl
use Mojolicious::Lite;
use DBI;

get '/' => sub {
    my $self = shift;
    $self->render('index');
};

get '/api' => sub {
    my $self = shift;

	my $dbname = "d1kbiva5h13qal";
	my $username = "ucxzubqrwjbhiy";
	my $password = "08e5f16ea2cc3bbb976949d48c513bcdc39dd37726a17eadf363a81baf5b79fb";
	my $dbhost = "ec2-54-235-160-57.compute-1.amazonaws.com";
	my $dbport = "5432";
	my $dboptions = "-e";
	my $dbtty = "ansi";

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	if ($DBI::err != 0) {
	  print $DBI::errstr . "\n";
	  exit($DBI::err);
	}

	my $query = "SELECT * FROM pg_tables";

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $result = '';
	while (my @array = $sth->fetchrow_array()) {
	  foreach my $i (@array) {
	    $result .= "$i\t";
	  }
	  $result .= "<br>\n";
	}

	$sth->finish();
	$dbh->disconnect();

    $self->render(text => $result);
};

app->start;
