#!/usr/bin/env perl
use warnings;
use strict;
use Mojolicious::Lite;
use DBI;

#plugin 'ClientIP';

require "settings.pl";
our $dbhost;
our $dbname;
our $username;
our $password;

my $dbport = "5432";
my $dboptions = "-e";
my $dbtty = "ansi";

sub save_log {
	my $account = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "INSERT INTO change_log (email, ip)
	                  VALUES ('$account','$ENV{'REMOTE_ADDR'}')";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Content-Type: text/plain\n\n";
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
}

sub select_json {
	my $fields = shift;
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
	  	$value =~ s/"/\\"/g;
	    push @row, '"'.$field.'":"'.$value.'"';
	  }
	  push @result, '{'.(join ',', @row).'}';
	}

	$sth->finish();
	$dbh->disconnect();

	'['.(join ',', @result).']'
}

sub get_account {
	my $name = shift;
	my $pass = shift;
	my $query = "SELECT account FROM logins WHERE LOWER(email)='$name' AND LOWER(password)='$pass' AND active=true";

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $account = 0;
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$account = $array[0];
	}

	$sth->finish();
	$dbh->disconnect();

	return $account;
}

sub get_location_id {
	my $id = shift;
	my $account = shift;
	my $query = "SELECT id FROM locations WHERE id='$id' AND account='$account'";

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $location_id = '0';
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$location_id = $array[0];
	}

	$sth->finish();
	$dbh->disconnect();

	return $location_id;
}

sub standing_order_create_or_update {
	my $account = shift;
	my $day_of_week = shift;
	my $location_id = shift;
	my $item_id = shift;
	my $qte = shift;
	my $active = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "SELECT id 
	               FROM standing_orders
	              WHERE account='$account' AND
	                    day_of_week='$day_of_week' AND
	                    location='$location_id' AND
	                    item_no='$item_id'";

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

	if ($order_id == 0) {
		if ($qte > 0) {
			$query = "INSERT INTO standing_orders (account, day_of_week, location, item_no, quantity, active, item_active)
			               VALUES ('$account','$day_of_week', '$location_id', '$item_id', '$qte', '$active', 'true')";
		} else {
			return 0;
		}
	} else {
		if ($qte > 0) {
			$query = "UPDATE standing_orders
			             SET quantity='$qte', active='$active'
			           WHERE id='$order_id'";
		} elsif ($qte == 0) {
			$query = "DELETE FROM standing_orders
			           WHERE id='$order_id'";
		} else {
			return 0;
		}
	}

	$rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();


	save_log($account);
	return 1;
}

sub standing_order_copy {
	my $account = shift;
	my $day_of_week_from = shift;
	my $location_from = shift;
	my $day_of_week_to = shift;
	my $location_to = shift;

	my $query = "SELECT item_no,quantity,active
	               FROM standing_orders
	              WHERE account='$account' AND
	                    day_of_week='$day_of_week_from' AND
	                    location='$location_from'";

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	while (my @array = $sth->fetchrow_array()) {
		my $item_no = $array[0];
		my $quantity = $array[1];
		my $active = $array[2];
		standing_order_create_or_update($account, $day_of_week_to, $location_to, $item_no, $quantity, $active);
	}

	$sth->finish();
	$dbh->disconnect();

	return 1;
}

sub standing_order_delete_item {
	my $account = shift;
	my $item_id = shift;
	my $day_of_week = shift;
	my $location_id = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "DELETE FROM standing_orders
	                WHERE account='$account' AND
	                      item_no='$item_id' AND
	                      day_of_week='$day_of_week' AND
	                      location='$location_id'";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;
}

sub standing_order_activate {
	my $account = shift;
	my $day_of_week = shift;
	my $location_id = shift;
	my $active = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "UPDATE standing_orders
	                SET active='$active'
	              WHERE account='$account' AND
	                    day_of_week='$day_of_week' AND
	                    location='$location_id'";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;
}

sub standing_order_delete {
	my $account = shift;
	my $day_of_week = shift;
	my $location_id = shift;
	my $active = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "DELETE FROM standing_orders
	              WHERE account='$account' AND
	                    day_of_week='$day_of_week' AND
	                    location='$location_id'";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;
}

sub create_location {
	my $account = shift;
	my $location = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "SELECT id 
	               FROM locations
	              WHERE account='$account' AND
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
		$query = "INSERT INTO locations (location, account)
		               VALUES ('$location','$account')";
		$rv = $dbh->do($query);
		if (!defined $rv) {
		  print "Error in request: " . $dbh->errstr . "\n";
		  exit(0);
		}
	}

	$dbh->disconnect();
	return 1;
}

sub edit_location {
	my $account = shift;
	my $location_id = shift;
	my $location = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "UPDATE locations
	                SET location='$location'
	              WHERE account='$account' AND
	                    id='$location_id'";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;
}

sub delete_location {
	my $account = shift;
	my $location_id = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "SELECT id 
	               FROM standing_orders
	              WHERE account='$account' AND
	                    location='$location_id'";

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	while (my @array = $sth->fetchrow_array()) {
		return 0;
	}
	$sth->finish();

	$query = "DELETE FROM locations
	           WHERE account='$account' AND
                     id='$location_id'";

	$rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;
}

sub replace_items {
	my $account = shift;
	my $item_from = shift;
	my $item_to = shift;
	my $location_id = shift;

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query;
	if ($location_id != '0') {
		$query = "UPDATE standing_orders
		             SET item_no='$item_to'
		           WHERE account='$account' AND
		                 item_no='$item_from' AND
		                 location='$location_id'";
	} else {
		$query = "UPDATE standing_orders
		             SET item_no='$item_to'
		           WHERE account='$account' AND
		                 item_no='$item_from'";
	}

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();
	return 1;	
}

sub process_request {
    my $self = shift;
    my $action = $self->param('action');
	my $name = $self->param('name');
	my $password = $self->param('password');

	my $account = get_account($name, $password);

	if ($action eq '/api/login') {
		my $name = select_json( ['name'], "SELECT name FROM customers WHERE account='$account'");

		$self->render(text => '{"account":"'.$account.'","name":'.$name.',"client_ip":"'.$ENV{'REMOTE_ADDR'}.'"}', format => 'json');
	} elsif ($action eq '/api/get_data') {
		my $items = select_json( ['id','description'], "SELECT items.item_no, description
		                                                  FROM items
		                                                  JOIN prices ON items.item_no=prices.item_no
		                                                           WHERE prices.account='$account'");
		my $locations = select_json( ['id','location'], "SELECT id, location
		                                                   FROM locations
		                                                  WHERE account='$account'");
		my $orders = select_json( ['day','location','item','qte','active'],
								  "SELECT day_of_week,location,item_no,quantity,active
								     FROM standing_orders
								    WHERE account='$account' AND
								          item_active=true");

		my $result = '{"account":"'.$account.'","items":'.$items.',"locations":'.$locations.',"orders":'.$orders.'}';
	    $self->render(text => $result, format => 'json');
	} elsif ($action eq '/api/order_save') {
		my $day = $self->param('day');
		my $location = $self->param('location');
		my $item = $self->param('item');
		my $qte = $self->param('qte');
		my $active = $self->param('active');

		if (get_location_id($location, $account)  == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		if (standing_order_create_or_update($account, $day, $location, $item, $qte, $active) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/order_delete_item') {
		my $item = $self->param('item');
		my $day = $self->param('day');
		my $location = $self->param('location');

		if (standing_order_delete_item($account, $item, $day, $location) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/create_location') {
		my $location = $self->param('location');

		if (create_location($account, $location) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/edit_location') {
		my $location_id = $self->param('location_id');
		my $location = $self->param('location');

		if (edit_location($account, $location_id, $location) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/activate_order') {
		my $day = $self->param('day');
		my $location = $self->param('location');
		my $active = $self->param('active');

		if (standing_order_activate($account, $day, $location, $active) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/delete_order') {
		my $day = $self->param('day');
		my $location = $self->param('location');
		my $active = $self->param('active');

		if (standing_order_delete($account, $day, $location, $active) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/copy_order') {
		my $day_from = $self->param('day_from');
		my $location_from = $self->param('location_from');
		my $day_to = $self->param('day_to');
		my $location_to = $self->param('location_to');

		if (standing_order_copy($account, $day_from, $location_from, $day_to, $location_to) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/delete_location') {
		my $location_id = $self->param('location_id');

		if (delete_location($account, $location_id) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');
	} elsif ($action eq '/api/replace_items') {
        my $item_from = $self->param('item_from');
        my $item_to = $self->param('item_to');
		my $location_id = $self->param('location_id');

		if (replace_items($account, $item_from, $item_to, $location_id) == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		$self->render(text => '{"account":"'.$account.'"}', format => 'json');		
	} else {
	    $self->render('index');	
	}
}

any '/' => sub {
	my $self = shift;
	process_request($self);
};

any 'app.pl' => sub {
	my $self = shift;
	process_request($self);
};

app->start;
