#!/usr/bin/env perl
use Mojolicious::Lite;
use DBI;

my $dbhost = "ec2-54-235-160-57.compute-1.amazonaws.com";
my $dbport = "5432";
my $dbname = "d1kbiva5h13qal";
my $username = "ucxzubqrwjbhiy";
my $password = "08e5f16ea2cc3bbb976949d48c513bcdc39dd37726a17eadf363a81baf5b79fb";
my $dboptions = "-e";
my $dbtty = "ansi";


sub select_json {
	my $fields = shift;
	# my $table = shift;
	# my $addon = shift;

	# my $join_fields = join ',', @$fields;
	# my $query = "SELECT $join_fields FROM $table $addon;";
	my $query = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my @result=();
	while (my @array = $sth->fetchrow_array()) {
	  my @row=();
	  for(my $i=0; $i<scalar @$fields; $i++) {
	  	my $field = @$fields[$i];
	  	my $value = $array[$i];
	    push @row, '"'.$field.'":"'.$value.'"';
	  }
	  push @result, '{'.(join ',', @row).'}';
	}

	$sth->finish();
	$dbh->disconnect();

	'['.(join ',', @result).']'
}

sub get_customer_id {
	my $name = shift;
	my $pass = shift;
	my $query = "SELECT id FROM customer WHERE name='$name' AND password='$pass' AND active=1";

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $customer_id = 0;
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$customer_id = $array[0];
	}

	$sth->finish();
	$dbh->disconnect();

	return $customer_id;
}

sub get_customer_items {
	my $customer_id = shift;

}


get '/' => sub {
    my $self = shift;
    $self->render('index');
};

get '/api' => sub {
    my $self = shift;

    my @fields = ('name', 'password');
    my $result = select_json( ['name'], 'customer', "WHERE name='alexei' AND password='alexeib123'" );

    $self->render(text => $result, format => 'json');
};

post '/api/login' => sub {
	my $self = shift;
	my $name = $self->param('name');
	my $password = $self->param('password');

    # my $result = select_json( ['name'], 'customer', "WHERE name='$name' AND password='$password'" );
    # $self->render(text => $result, format => 'json');
	my $customer_id = get_customer_id($name, $password);
	$self->render(text => '{"customer_id":"'.$customer_id.'"}', format => 'json');
};

post '/api/get_data' => sub {
	my $self = shift;
	my $name = $self->param('name');
	my $password = $self->param('password');

	my $customer_id = get_customer_id($name, $password);
	if ($customer_id==0) {
		$self->render(text => '{"customer_id":"0"}', format => 'json');
		return;
	}
	my $items = select_json( ['id','description'], "SELECT items.id, description FROM items JOIN customer_items ON items.id=customer_items.item_id WHERE customer_items.customer_id=$customer_id");
	my $locations = select_json( ['id','location'], "SELECT id, location FROM locations WHERE customer_id=$customer_id");

	my $result = '{"customer_id":"'.$customer_id.'","items":'.$items.',"locations":'.$locations.'}';
    $self->render(text => $result, format => 'json');
};

app->start;
