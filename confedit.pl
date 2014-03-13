#!/usr/bin/perl
#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
use strict;
use warnings;
use CGI qw(:cgi-lib :standard); 
use YAML qw( LoadFile );
my $conffile = "/opt/ifmi/poolmanager.conf";
my $mconf = LoadFile( $conffile );
my $hostname = `hostname`;
my $theme = $mconf->{display}->{status_css};

print header;
print start_html( -title=>'PM - ' . $hostname . ' - Config',
          -style=>{-src=>'/IFMI/themes/' . $theme } );

my $savepath = $mconf->{settings}->{savepath}; 
our %in;
&ReadParse(%in);
my $confdata = $in{'configtext'};
my $tempfile = "/tmp/confedit.tmp";
if ($confdata ne "") {
  open my $fin, '>', $tempfile;
  print $fin $confdata;
  close $fin; 
  $confdata = ""; 
}
my $status = "";
my $ln = $in{'lname'}; if ($ln ne "") {
$status = "Save of $savepath failed!" if (system("echo $in{'ptext'} | sudo -S -u $ln /bin/cp $tempfile $savepath")!=0);
}
$ln = ""; unlink $tempfile; 

print "<div id='content'><table class=configeditor><tr><td class=bigger>Miner Configuration Editor</td></tr>";
print "<tr><td class=big>Hostname: $hostname </td></tr><tr><td>Config file: $savepath ";
my $owner = getpwuid((stat($savepath))[4]);
print " - Owned by: $owner";
print "<br><small><i>Change this filepath in the <a href='config.pl'>settings</a></small></i></td></tr>";
my $filedata = "";
open my $fin, '<', $savepath;
while (<$fin>) {
  $filedata .= "$_";
}
print "<tr><td><form name='configedit' action='confedit.pl' method='POST'>";
print "<textarea name='configtext' style='width:800px;height:600px'>$filedata</textarea>";
print "</td></tr><tr><td>";
print " User: <input type='text' placeholder='username' name='lname' required>";
print " Password: ";
print "<input type='password' placeholder='password' name='ptext' required> ";
print " <input type='submit' value='Save'>";
if ($status ne "") {
  print "</td></tr><tr><td>";
  print "$status";
}
print "</form></td></tr>";
print "<tr><td>WARNING! This will NOT preserve your edits if your save fails.</td></tr>";
print "<tr><td><a href='status.pl'>Back to node page</a></td></tr>";
print "</table></div></body></html>";
