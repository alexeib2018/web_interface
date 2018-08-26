fin = open('items.csv.orig','rt')
fout = open('items.csv','wt')
lineout = fin.readline()
while True:
	line = fin.readline()
	if not line:
		break
	fout.write(lineout)
	line_arr = line.split(',')
	line_begin = ','.join(line_arr[0:5])
	line_uom = ','.join(line_arr[5:-2]).replace('"','""')
	line_end = ','.join(line_arr[-2:])
	lineout = '%s,"%s",%s' % (line_begin, line_uom, line_end)
fout.close()
fin.close()
