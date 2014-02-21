#!/usr/bin/perl
use CGI qw(:cgi-lib :standard);
require '/opt/bamt/common.pl';
print header;
&ReadParse(%in);

print "<meta http-equiv='REFRESH' content='3;url=./status.pl?'>";
print "<style type='text/css'> body {font-family: 'Trebuchet MS', Helvetica, sans-serif; background-color:white; } </style>";
print "<style type='text/css'> table { border: 2px solid #cccccc; margin-left: auto; margin-right: auto; } td { text-align:center; padding:10px; ) </style>"; 
print "<br><br><br><table><tr>";

my $status = ""; 
my $mstart = $in{'mstart'};
if ($mstart eq "start") { 
  $status = `echo $in{'ptext'} | sudo -S /usr/sbin/mine start`;
  if ($status ne "") {
    print "<td><p><big>$status</big>";
  } else {
    print "<td bgcolor='yellow'><p><big>Failed!</big>";
  }
}

my $mstop = $in{'mstop'};
if ($mstop eq "stop") { 
  $status = `echo $in{'ptext'} | sudo -S /usr/sbin/mine stop`;
  if ($status ne "") {
    print "<td><p><big>$status</big>";
  } else {
    print "<td bgcolor='yellow'><p><big>Failed!</big>";
  }
}

my $reboot = $in{'reboot'};
if ($reboot eq "reboot") { 
  $status = `echo $in{'ptext'} | sudo -S /sbin/coldreboot`;
  if ($status ne "") {
   print "<td bgcolor='red'><p><big>$status...</big><br><small>why... why would you do such a thing... I just dont know...</small></td>";
  } else {
   print "<td bgcolor='yellow'><p><big>Failed!</big>";
  }
}

print "</tr></table></body></html>";

