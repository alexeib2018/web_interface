use Spreadsheet::ParseXLSX;
use Spreadsheet::Read;

my $book = Spreadsheet::Read->new ("orders.xlsx");
my $sheet = $book->sheet(1);
my $cell  = $sheet->cell("D1");
#print $sheet->label;
#print $sheet->maxrow;

#my @dates;

#print $sheet->cell(7,6);

my $item;
my $qte;
for my $row (9...9) { 	# $sheet->maxrow) {
	$item = $sheet->cell(3, $row);
	if ($item =~ m/^\d\d\d\d\d$/) {
		print "$item\n";

		$qte = $sheet->cell(6, $row);
		if ($qte =~ m/\s?\d+\s?/) {
			print "Sun $qte\n";
		}

		$qte = $sheet->cell(7, $row);
		if ($qte =~ m/\s?\d+\s?/) {
			print "Mon $qte\n";
		}

		$qte = $sheet->cell(8, $row);
		if ($qte =~ m/\s?\d+\s?/) {
			print "Tue $qte\n";
		}

		$qte = $sheet->cell(9, $row);
		if ($qte =~ m/\s?\d+\s?/) {
			print "Wed $qte\n";
		}

		$qte = $sheet->cell(10, $row);
		if ($qte =~ m/\s?\d+\s?/) {
			print "Thu $qte\n";
		}

		$qte = $sheet->cell(11, $row);
		if ($qte =~ m/\s?\d+\s?/) {
			print "Fri $qte\n";
		}

		$qte = $sheet->cell(12, $row);
		if ($qte =~ m/\s?\d+\s?/) {
			print "Sat $qte\n";
		}		
	}
}

$date1970 = $sheet->cell(7,6) - 25569;
print $sheet->cell(7,6)."\n";
#print $sheet->cell(7,6)."\n";
print $date1970."\n";

my $datestring = localtime();
print "Current date and time $datestring\n";

my $gmt = gmtime();
print "GMT date and time $gmt\n";

my $timezone = -7*60*60;

my $epoc = time() + $timezone;
print "Epoc from 01 Jan 1970 $epoc\n";

my $yesterday = localtime($epoc - 24*60*60);
print "Yesterday date and time $yesterday\n";

my $days = int($epoc / (24*60*60));
print "Days: $days\n";

my $hours = int( ($epoc - $days * 24*60*60) / (60*60) );
print "Hours: $hours\n";

my $offset = $datestring - $gmt;
print "Time offset: $offset\n";

print $sheet->cell(6,6)."\n";
print $sheet->cell(7,6)."\n";
print $sheet->cell(8,6)."\n";
print $sheet->cell(9,6)."\n";
print $sheet->cell(10,6)."\n";
print $sheet->cell(11,6)."\n";
print $sheet->cell(12,6)."\n";
