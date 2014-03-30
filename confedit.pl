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

my $currentm = $mconf->{settings}->{current_mconf};
my $savepath = $mconf->{miners}->{$currentm}->{savepath}; 
our %in;
&ReadParse(%in);
my $confdata = $in{'configtext'};
my $tempfile = "/tmp/confedit.tmp";
if (defined $confdata) {
  open my $fin, '>', $tempfile;
  print $fin $confdata;
  close $fin; 
  $confdata = ""; 
}
my $status = -1;
if (defined $in{'ptext'}) {
  $status = (system("echo $in{'ptext'} | sudo -S /bin/cp $tempfile $savepath"));
}
my $filedata = ""; my $datafile = "";
if ($status > 0) {
  $datafile = $tempfile;
} else {
  $datafile = $savepath; 
}
open my $fin, '<', $datafile;
while (<$fin>) {
   $filedata .= "$_";
}
unlink $tempfile; 

print "<div id='content'><table class=configeditor><tr><td class=header>Miner Configuration Editor</td></tr>";
print "<tr><td class=bigger>Hostname: $hostname </td></tr><tr><td>Config file: $savepath ";
my $owner = getpwuid((stat($savepath))[4]);
print " - Owned by: $owner";
print "<br><small><i>Change this filepath in the <a href='config.pl'>settings</a></small></i></td></tr>";
print "<tr><td><form name='configedit' action='confedit.pl' method='POST'>";
print "<textarea name='configtext' style='width:800px;height:600px'>$filedata</textarea>";
print "</td></tr><tr><td>";
#print " User: <input type='text' placeholder='username' name='lname' required>";
print "Root Password: ";
print "<input type='password' placeholder='password' name='ptext' required> ";
print " <input type='submit' value='Save'>";
if ($status > 0) {
  print "</td></tr><tr><td class=error>Save of $savepath failed!";
} elsif ($status == 0) { 
  print "</td></tr><tr><td>$savepath saved";
}
print "</form></td></tr>";
print "<tr><td><a href='status.pl'>Back to node page</a></td></tr>";
print "</table></div></body></html>";
