# Before `make install' is performed this script should be runnable with
#!/usr/bin/perl
#
# tld1-tk.t - test harness for module Tk::DBI::LoginDialog
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
my $tld1 = $top->LoginDialog;
#$log->debug(sprintf "tld1 [%s]", Dumper($tld1));
isa_ok( $tld1, $c_this, "new no parm");
is( Tk::Exists($tld1), 1,	"exists");

eval { my @dummy = $tld1->configure; };
is($@, "", "configure $c_this");

eval { $tld1->update; };
is($@, "", "update $c_this");

eval { $tld1->destroy; };
is($@, "", "destroy $c_this");

isnt(Tk::Exists($tld1), 1, "destroyed $c_this");

my $tld2 = $top->LoginDialog(-instance => 'XE');
$tld2->_log->info("hello");
$tld2->_dump;
#eval { $tld2->Show; };
#is($@, "", "Show $c_this");
#
#$tld2->Exit('Cancel');

my $dbh = $tld2->loop;
isa_ok( $dbh, "DBI::db", "got handle");
$log->debug(sprintf "error [%s]", $tld2->error);
$log->info("exiting test.");

