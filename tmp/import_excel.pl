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
for my $row (9...$sheet->maxrow) {
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
