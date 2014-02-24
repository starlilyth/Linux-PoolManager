#!/usr/bin/perl
#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

use CGI qw(:cgi-lib :standard);
print header;
&ReadParse(%in);
$hostname = `hostname`;
my $filepath = ""; my $filepath = $in{'cfilepath'};
my $savepath = ""; my $savepath = $in{'csavepath'};
my $confdata = ""; my $confdata = $in{'configtext'};
my $tempfile = "/tmp/confedit.tmp";
if ($confdata ne "") {
  open (MYFILE, ">", $tempfile);
  print MYFILE $confdata;
  close (MYFILE); 
}
my $ln = $in{'lname'}; if ($ln ne "") {
  $status = "Save of $savepath failed!" if (system("echo $in{'ptext'} | sudo -S -u $ln /bin/cp $tempfile $savepath")!=0);
}
$ln = ""; unlink $tempfile; 
print "<style type='text/css'> body {font-family: 'Trebuchet MS', Helvetica, sans-serif; background-color:white; text-align:center; }";
print "table { border: 2px solid #cccccc; margin-left: auto; margin-right: auto; } tr {border: 2px solid; } td {padding:3px; text-align:center; }"; 
print "</style><br><h1>Configuration Editor</h1><table><tr><td>Hostname: $hostname</td></tr>";
print "<form name='config' action='confedit.pl' method='POST'>";
print "<tr><td><input type='text' placeholder='/path/to/config.file' size='40' name='cfilepath' required>";
print "<input type='submit' value='Load into textbox'>";
print "</form></td></tr>";
$filepath = $savepath if ($savepath ne ""); 
if (-f $filepath) { 
  print "<tr><td>Loaded file: $filepath";
  $owner = getpwuid((stat($filepath))[4]) if ($filepath ne "");
  print " - Owned by: $owner</td></tr>";
  open (MYFILE, $filepath);
   while (<MYFILE>) {
 	chomp;
 	$filedata .= "$_\n";
   }
  close (MYFILE); 
} else {
  print "<tr><td>$filepath isn't valid" if ($filepath ne "");
}
print "<tr><td>";
print "<form name='configedit' action='confedit.pl' method='POST'>";
print "<textarea name='configtext' style='width:512px;height:256px'>$filedata</textarea>";
print "</td></tr><tr><td><input type='submit' value='Save textbox as'>";
print "<input type='text' placeholder='/path/to/config.file' size='40' name='csavepath' required>";
print "</td></tr><tr><td>User:";
print "<input type='text' placeholder='username' name='lname' required>";
print " Password:";
print "<input type='password' placeholder='password' name='ptext' required>";
if ($status ne "") {
  print "</td></tr><tr><td>";
  print "$status";
}
print "</form></td></tr></table>";
print "<br><p>WARNING! This will NOT preserve your edits if your save fails.";
print "<br>It will let you overwrite files. It performs no validation whatsoever.";
print "<br><big>USE ENTIRELY AT YOUR OWN RISK</big>";
print "<small><p>Pizza and praises to lily\@disorg.net";
print "<br>BTC: 1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6 <br>LTC: LdMJB36zEfTo7QLZyKDB55z9epgN78hhFb";
print "</body></html>";
