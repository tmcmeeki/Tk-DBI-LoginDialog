# Before `make install' is performed this script should be runnable with
#!/usr/bin/perl
#
# tld-tk.t - test harness for module Tk::DBI::LoginDialog
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
# `make test'. After `make install' it should work as `perl Tk-DBI-LoginDialog.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Log::Log4perl qw/ :easy /;
use Test::More tests => 2;
use Tk;
use Data::Dumper;


BEGIN { use_ok('Tk::DBI::LoginDialog') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# ---- globals ----

# ---- main ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);

#my $ld = Tk::DBI::LoginDialog->new();
my $c_this = 'Tk::DBI::LoginDialog';

my $top = new MainWindow;
my $tld = $top->LoginDialog;
#$log->debug(sprintf "tld [%s]", Dumper($tld));
isa_ok( $tld, $c_this, "new no parm");
$tld->_log->info("hello");
$tld->dump;
do {
	$tld->Show;

} until (defined $tld->cget('-dbh'));

$log->info("exiting test.");

