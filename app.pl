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


sub get_location_id {
	my $id = shift;
	my $customer_id = shift;
	my $query = "SELECT id FROM locations WHERE id='$id' AND customer_id='$customer_id'";

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $location_id = 0;
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$location_id = $array[0];
	}

	$sth->finish();
	$dbh->disconnect();

	return $location_id;
}

sub standing_order_create_or_update {
	my $customer_id = shift;
	my $day_of_week = shift;
	my $location_id = shift;
	my $item_id = shift;
	my $qte = shift;
	my $active = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "SELECT id 
	               FROM standing_orders
	              WHERE customer_id='$customer_id' AND
	                    day_of_week='$day_of_week' AND
	                    location_id='$location_id' AND
	                    item_id='$item_id'";

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $order_id = 0;
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$order_id = $array[0];
	}
	$sth->finish();

	if ($order_id==0) {
		$query = "INSERT INTO standing_orders (customer_id, day_of_week, location_id, item_id, qte, active)
		               VALUES ('$customer_id','$day_of_week', '$location_id', '$item_id', '$qte', '$active')";
	} else {
		$query = "UPDATE standing_orders
		             SET qte='$qte', active='$active'
		           WHERE id='$order_id'";
	}

	$rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;
}

sub standing_order_delete_item {
	my $customer_id = shift;
	my $item_id = shift;
	my $day_of_week = shift;
	my $location_id = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "DELETE FROM standing_orders
	                WHERE customer_id='$customer_id' AND
	                      item_id='$item_id' AND
	                      day_of_week='$day_of_week' AND
	                      location_id='$location_id'";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;
}

sub create_location {
	my $customer_id = shift;
	my $location = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "SELECT id 
	               FROM locations
	              WHERE customer_id='$customer_id' AND
	                    location='$location'";

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $location_id = 0;
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$location_id = $array[0];
	}
	$sth->finish();

	if ($location_id==0) {
		$query = "INSERT INTO locations (location, customer_id)
		               VALUES ('$location','$customer_id')";
		$rv = $dbh->do($query);
		if (!defined $rv) {
		  print "Error in request: " . $dbh->errstr . "\n";
		  exit(0);
		}
	}

	$dbh->disconnect();
	return 1;
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
	my $orders = select_json( ['day','location','item','qte','active'],
							  "SELECT day_of_week,location_id,item_id,qte,active
							     FROM standing_orders
							    WHERE customer_id='$customer_id'");

	my $result = '{"customer_id":"'.$customer_id.'","items":'.$items.',"locations":'.$locations.',"orders":'.$orders.'}';
    $self->render(text => $result, format => 'json');
};

post '/api/order_save' => sub {
	my $self = shift;
	my $name = $self->param('name');
	my $password = $self->param('password');
	my $day = $self->param('day');
	my $location = $self->param('location');
	my $item = $self->param('item');
	my $qte = $self->param('qte');
	my $active = $self->param('active');

	my $customer_id = get_customer_id($name, $password);
	if ($customer_id==0) {
		$self->render(text => '{"customer_id":"0"}', format => 'json');
		return;
	}

	if (get_location_id($location, $customer_id)==0) {
		return $self->render(text => '{"customer_id":"0"}', format => 'json');
	}

	if (standing_order_create_or_update($customer_id, $day, $location, $item, $qte, $active)==0) {
		return $self->render(text => '{"customer_id":"0"}', format => 'json');
	}

	$self->render(text => '{"customer_id":"'.$customer_id.'"}', format => 'json');
};

post '/api/order_delete_item' => sub {
	my $self = shift;
	my $name = $self->param('name');
	my $password = $self->param('password');
	my $item = $self->param('item');
	my $day = $self->param('day');
	my $location = $self->param('location');

	my $customer_id = get_customer_id($name, $password);
	if ($customer_id==0) {
		$self->render(text => '{"customer_id":"0"}', format => 'json');
		return;
	}

	if (standing_order_delete_item($customer_id, $item, $day, $location)==0) {
		return $self->render(text => '{"customer_id":"0"}', format => 'json');
	}

	$self->render(text => '{"customer_id":"'.$customer_id.'"}', format => 'json');
};


post '/api/create_location' => sub {
	my $self = shift;
	my $name = $self->param('name');
	my $password = $self->param('password');
	my $location = $self->param('location');

	my $customer_id = get_customer_id($name, $password);
	if ($customer_id==0) {
		$self->render(text => '{"customer_id":"0"}', format => 'json');
		return;
	}

	if (create_location($customer_id, $location)==0) {
		return $self->render(text => '{"customer_id":"0"}', format => 'json');
	}

	$self->render(text => '{"customer_id":"'.$customer_id.'"}', format => 'json');
};

app->start;
