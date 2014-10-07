#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00basic.t'
#
# 00basic.t - test harness for module Tk::DBI::LoginDialog
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
#########################
use strict;
use warnings;

use Data::Dumper;
use Tk;
use Log::Log4perl qw/ :easy /;
use Test::More;

my $top; eval { $top = new MainWindow; };

if (Tk::Exists($top)) { plan tests => 10;
} else { plan skip_all => 'No X server available'; }

my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);

use constant TIMEOUT => (exists $ENV{TIMEOUT}) ? $ENV{TIMEOUT} : 250; # unit: ms

# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);

sub queue_button {
	my ($o,$action,$method)=@_;
	my $label = "B_$action";

	my $button = $o->Subwidget($label);

#	$log->debug("about to queue action for [$label]");

	$button->after(TIMEOUT, sub{ $button->invoke; });

	if ($method eq "s") {
		is($o->Show, $action,		"show $action");
	} else {
		isa_ok($o->login(1), "DBI::db",	"$action");
	}
}


# ---- create ----
my $ld = $top->LoginDialog;
isa_ok($ld, $c_this,		"new");

# ---- cancel ----
queue_button($ld, "Cancel", "s");
ok(defined($ld->dbh) == 0,	"null dbh");

# ---- exit ----
$ld->configure(-exit => sub { warn "IGNORE dummy exit routine\n"; });
queue_button($ld, "Exit", "s");

# ---- login ----
$ld->driver("ExampleP");
queue_button($ld, "Login", "s");
isa_ok($ld->dbh, "DBI::db",	"non-null dbh");

# ---- loop ----
queue_button($ld, "Login", "l");
like($ld->error, qr/onnected/,        "error");

# ---- clean-up ----
$ld->destroy;
ok(Tk::Exists($ld) == 0,	"destroy");

