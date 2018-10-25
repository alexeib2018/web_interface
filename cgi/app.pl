#!/usr/bin/env perl
use warnings;
use strict;
use Mojolicious::Lite;
use DBI;
use Spreadsheet::ParseXLSX;
use Spreadsheet::Read;
use MIME::Base64;
use File::Temp qw/ tempfile /;

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
	my %log = @_;
	my $account = $log{'account'};
	my $table_changed = $log{'table_changed'};
	my $action = $log{'action'};
	my $new_value = $log{'new_value'};
	my $old_value = $log{'old_value'};

	if (!defined $old_value) {
		$old_value = '';
	}

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "INSERT INTO change_log (account, table_changed, action, new_value, old_value, ip)
	                  VALUES ('$account', '$table_changed', '$action', '$new_value', '$old_value', '$ENV{'REMOTE_ADDR'}')";

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

	my %log = ('account'=>$account,
	           'table_changed'=>'standing_orders');

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "SELECT id, day_of_week, location, item_no, quantity
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
	my $old_value = '';
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$order_id = $array[0];
		$old_value = "day_of_week=$array[1], location=$array[2], item_no=$array[3], quantity=$array[4]";
	}
	$sth->finish();

	if ($order_id == 0) {
		if ($qte > 0) {
			$query = "INSERT INTO standing_orders (account, day_of_week, location, item_no, quantity, active, item_active)
			               VALUES ('$account','$day_of_week', '$location_id', '$item_id', '$qte', '$active', 'true')";
			$log{'action'} = 'insert';
			$log{'new_value'} = "day_of_week=$day_of_week, location=$location_id, item_no=$item_id, quantity=$qte";
		} else {
			return 0;
		}
	} else {
		if ($qte > 0) {
			$query = "UPDATE standing_orders
			             SET quantity='$qte', active='$active'
			           WHERE id='$order_id'";
			$log{'action'} = 'update';
			$log{'new_value'} = "day_of_week=$day_of_week, location=$location_id, item_no=$item_id, quantity=$qte";
			$log{'old_value'} = $old_value;
		} elsif ($qte == 0) {
			$query = "DELETE FROM standing_orders
			           WHERE id='$order_id'";
			$log{'action'} = 'delete';
			$log{'old_value'} = $old_value;
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

	save_log(%log);
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

	my %log = ('account'=>$account,
	           'table_changed'=>'standing_orders');

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "DELETE FROM standing_orders
	                WHERE account='$account' AND
	                      item_no='$item_id' AND
	                      day_of_week='$day_of_week' AND
	                      location='$location_id'";

	$log{'action'} = 'delete';
	$log{'old_value'} = "WHERE item_no=$item_id AND day_of_week=$day_of_week AND location=$location_id";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();

	save_log(%log);
	return 1;
}

sub standing_order_activate {
	my $account = shift;
	my $day_of_week = shift;
	my $location_id = shift;
	my $active = shift;

	my %log = ('account'=>$account,
	           'table_changed'=>'standing_orders');

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "UPDATE standing_orders
	                SET active='$active'
	              WHERE account='$account' AND
	                    day_of_week='$day_of_week' AND
	                    location='$location_id'";

	$log{'action'} = 'update';
	$log{'new_value'} = "active=$active";
	if ($active) {
		$log{'old_value'} = "active=0";
	} else {
		$log{'old_value'} = "active=1";
	}

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();

	save_log(%log);
	return 1;
}

sub standing_order_delete {
	my $account = shift;
	my $day_of_week = shift;
	my $location_id = shift;
	my $active = shift;

	my %log = ('account'=>$account,
	           'table_changed'=>'standing_orders');

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "DELETE FROM standing_orders
	              WHERE account='$account' AND
	                    day_of_week='$day_of_week' AND
	                    location='$location_id'";

	$log{'action'} = 'delete';
	$log{'old_value'} = "WHERE day_of_week=$day_of_week AND location=$location_id";

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();

	save_log(%log);
	return 1;
}

sub create_location {
	my $account = shift;
	my $location = shift;

	my %log = ('account'=>$account,
	           'table_changed'=>'locations');	

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

		$log{'action'} = 'insert';
		$log{'new_value'} = "$location";

		$rv = $dbh->do($query);
		if (!defined $rv) {
		  print "Error in request: " . $dbh->errstr . "\n";
		  exit(0);
		}
	}

	$dbh->disconnect();

	save_log(%log);
	return 1;
}

sub edit_location {
	my $account = shift;
	my $location_id = shift;
	my $location = shift;

	my %log = ('account'=>$account,
	           'table_changed'=>'locations');	

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query = "SELECT location
	               FROM locations
	              WHERE account='$account' AND
	                    id='$location_id'";

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $old_location = '';
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$old_location = $array[0];
	}
	$sth->finish();

	$query = "UPDATE locations
	             SET location='$location'
	           WHERE account='$account' AND
	                      id='$location_id'";

	$log{'action'} = 'update';
	$log{'new_value'} = "$location";
	$log{'old_value'} = "$old_location";

	$rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();

	save_log(%log);
	return 1;
}

sub delete_location {
	my $account = shift;
	my $location_id = shift;

	my %log = ('account'=>$account,
	           'table_changed'=>'locations');	

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

	$query = "SELECT location
	            FROM locations
	           WHERE account='$account' AND
	                      id='$location_id'";

	$sth = $dbh->prepare($query);
	$rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $old_location = '';
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$old_location = $array[0];
	}
	$sth->finish();

	$query = "DELETE FROM locations
	           WHERE account='$account' AND
                     id='$location_id'";

	$log{'action'} = 'delete';
	$log{'old_value'} = "$old_location";

	$rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();

	save_log(%log);
	return 1;
}

sub replace_items {
	my $account = shift;
	my $item_from = shift;
	my $item_to = shift;
	my $location_id = shift;

	my %log = ('account'=>$account,
	           'table_changed'=>'standing_orders');

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $query;
	if ($location_id != '0') {
		$query = "UPDATE standing_orders
		             SET item_no='$item_to'
		           WHERE account='$account' AND
		                 item_no='$item_from' AND
		                 location='$location_id'";
		$log{'action'} = 'update';
		$log{'new_value'} = "item_no=$item_to";
		$log{'old_value'} = "WHERE item_no=$item_from AND location=$location_id";
	} else {
		$query = "UPDATE standing_orders
		             SET item_no='$item_to'
		           WHERE account='$account' AND
		                 item_no='$item_from'";
		$log{'action'} = 'update';
		$log{'new_value'} = "item_no=$item_to";
		$log{'old_value'} = "WHERE item_no=$item_from";
	}

	my $rv = $dbh->do($query);
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	$dbh->disconnect();

	save_log(%log);
	return 1;	
}

sub import_excel_create_or_update {
	my $dbh = shift;
	my $account = shift;
	my $day_of_week = shift;
	my $date = shift;
	my $location_id = shift;
	my $item_id = shift;
	my $qte = shift;
	my $active = shift;

	my $timezone = -7*60*60;
	my $epoc = time() + $timezone;
	my $days = int($epoc / (24*60*60));
	my $hours = int( ($epoc - $days * 24*60*60) / (60*60) );

	my @log = ($day_of_week, $item_id, $qte);

	if ($hours < 8) {
		if ($date - 25569 < $days) {
			push @log, "REJECT";
			return @log;
		}
	} else {
		if ($date - 25569 < $days+1) {
			push @log, "REJECT";
			return @log;
		}		
	}

	my $log_status = '';

	my $query_select = "SELECT id, day_of_week, location, item_no, quantity
	                      FROM standing_orders
	                     WHERE account='$account' AND
	                           day_of_week='$day_of_week' AND
	                           location='$location_id' AND
	                           item_no='$item_id'";

	my $sth = $dbh->prepare($query_select);
	my $rv = $sth->execute();
	if (!defined $rv) {
	  print "Error in request: " . $dbh->errstr . "\n";
	  exit(0);
	}

	my $order_id = 0;
	my $old_qte = '';
	my @result=();
	while (my @array = $sth->fetchrow_array()) {
		$order_id = $array[0];
		#$old_value = "day_of_week=$array[1], location=$array[2], item_no=$array[3], quantity=$array[4]";
		$old_qte = $array[4];
	}
	$sth->finish();

	my $query;
	if ($order_id == 0) {
		if ($qte > 0) {
			$query = "INSERT INTO standing_orders (account, day_of_week, location, item_no, quantity, active, item_active)
			               VALUES ('$account','$day_of_week', '$location_id', '$item_id', '$qte', '$active', 'true')";
			$log_status = "new";
		} else {
			$log_status = "REJECT";
		}
	} else {
		if ($qte == $old_qte) {
			$log_status = "same";
		} elsif ($qte > 0) {
			$query = "UPDATE standing_orders
			             SET quantity='$qte', active='$active'
			           WHERE id='$order_id'";
			$log_status = "update($old_qte)";
		} elsif ($qte == 0) {
			$query = "DELETE FROM standing_orders
			           WHERE id='$order_id'";
			$log_status = "delete($old_qte)";
		} else {
			$log_status = "REJECT";
		}
	}

	if ($query) {
		$rv = $dbh->do($query);
		if (!defined $rv) {
			$log_status = "db_error";
		}
	}

	push @log, $log_status;
	return @log;
}

sub import_excel_get_or_create_location_id {
	my $account = shift;
	my $dbh = shift;
	my $location = shift;

	my $query_select = "SELECT id
	                      FROM locations
	                     WHERE account='$account' AND
	                          location='$location'";

	my $sth = $dbh->prepare($query_select);
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

	if ($location_id == 0) {
		my $query_insert = "INSERT INTO locations (location, account)
   		                         VALUES ('$location','$account')";
		$rv = $dbh->do($query_insert);
		if (!defined $rv) {
		  	print "Error in request: " . $dbh->errstr . "\n";
		  	exit(0);
		}

		$sth = $dbh->prepare($query_select);
		$rv = $sth->execute();
		if (!defined $rv) {
		  	print "Error in request: " . $dbh->errstr . "\n";
		  	exit(0);
		}

		@result=();
		while (my @array = $sth->fetchrow_array()) {
			$location_id = $array[0];
		}
		$sth->finish();
	}

	return $location_id;
}

sub import_excel {
	my $account = shift;
	my $file_base64 = shift;

	my($fh, $filename) = tempfile(DIR=>'../tmp/', SUFFIX=>'.xlsx');

	#open (my $fh, '>', '../tmp/orders_new.xlsx');
	binmode ($fh);
	print {$fh} decode_base64($file_base64);
	#print {$fh} $filename;
	close $fh;

	#my $filename = '../tmp/orders.xlsx';
	my $book = Spreadsheet::Read->new($filename);
	my $sheet = $book->sheet(1);
	#my $cell  = $sheet->cell("D1");
	#print $sheet->label;
	#print $sheet->maxrow;

	#my @dates;

	#print $sheet->cell(7,6);

	my @log = ();

	my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport;options=$dboptions;tty=$dbtty","$username","$password",
	        {PrintError => 0});

	my $location = $sheet->label;
	my $location_id = import_excel_get_or_create_location_id($account, $dbh, $location);
	push @log, [$location];

	my $sunday_date    = $sheet->cell(6, 6);
	my $monday_date    = $sheet->cell(7, 6);
	my $tuesday_date   = $sheet->cell(8, 6);
	my $wednesday_date = $sheet->cell(9, 6);
	my $thursday_date  = $sheet->cell(10, 6);
	my $friday_date    = $sheet->cell(11, 6);
	my $saturday_date  = $sheet->cell(12, 6);

	my $item;
	my $qte;
	for my $row (10...$sheet->maxrow) {
		$item = $sheet->cell(3, $row);
		if ($item =~ m/^\d\d\d\d\d$/) {
			# print "$item\n";

			$qte = $sheet->cell(6, $row);
			if ($qte =~ m/\s?\d+\s?/) {
				push @log, [import_excel_create_or_update($dbh, $account, 'sunday',    $sunday_date,    $location_id, $item, $qte, 'true')];
			}

			$qte = $sheet->cell(7, $row);
			if ($qte =~ m/\s?\d+\s?/) {
				push @log, [import_excel_create_or_update($dbh, $account, 'monday',    $monday_date,    $location_id, $item, $qte, 'true')];
			}

			$qte = $sheet->cell(8, $row);
			if ($qte =~ m/\s?\d+\s?/) {
				push @log, [import_excel_create_or_update($dbh, $account, 'tuesday',   $tuesday_date,   $location_id, $item, $qte, 'true')];
			}

			$qte = $sheet->cell(9, $row);
			if ($qte =~ m/\s?\d+\s?/) {
				push @log, [import_excel_create_or_update($dbh, $account, 'wednesday', $wednesday_date, $location_id, $item, $qte, 'true')];
			}

			$qte = $sheet->cell(10, $row);
			if ($qte =~ m/\s?\d+\s?/) {
				push @log, [import_excel_create_or_update($dbh, $account, 'thursday',  $thursday_date,  $location_id, $item, $qte, 'true')];
			}

			$qte = $sheet->cell(11, $row);
			if ($qte =~ m/\s?\d+\s?/) {
				push @log, [import_excel_create_or_update($dbh, $account, 'friday',    $friday_date,    $location_id, $item, $qte, 'true')];
			}

			$qte = $sheet->cell(12, $row);
			if ($qte =~ m/\s?\d+\s?/) {
				push @log, [import_excel_create_or_update($dbh, $account, 'saturday',  $saturday_date,  $location_id, $item, $qte, 'true')];
			}		
		}
	}

	$dbh->disconnect();

	return @log;
}

sub process_request {
    my $self = shift;
    my $action = $self->param('action');
	my $name = $self->param('name');
	my $password = $self->param('password');

	if (!defined $action) {
		$action = 'help';
	}

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
	} elsif ($action eq '/api/import_excel') {
        my $file_base64 = $self->param('file_base64');

        my @ret = import_excel($account, $file_base64);
		if ($#ret == 0) {
			return $self->render(text => '{"account":"0"}', format => 'json');
		}

		my $records = '[';
		for(my $i=0; $i<=$#ret; $i++) {
			my $item_arr = $ret[$i];
			my $day_of_week = $item_arr->[0];
			my $item_id     = $item_arr->[1];
			my $qte         = $item_arr->[2];
			my $status      = $item_arr->[3];
			my $item = '{"day_of_week":"'.$day_of_week.'","item_id":"'.$item_id.'","qte":"'.$qte.'","status":"'.$status.'"}';
			if ($i == 0) {
				$records .= $item
			} else {
				$records .= ','.$item;
			}
		}
		$records .= ']';

		$self->render(text => '{"account":"'.$account.'","log":'.$records.'}', format => 'json');		
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
