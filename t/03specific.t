#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 03specific.t'
#
# 03specific.t - test harness for module Tk::DBI::LoginDialog
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
use Log::Log4perl qw/ :easy /;
use Tk;
use Test::More;

my $top; eval { $top = new MainWindow; };

if (Tk::Exists($top)) { plan tests => 17;
} else { plan skip_all => 'No X server available'; }

my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);

use constant TIMEOUT => (exists $ENV{TIMEOUT}) ? $ENV{TIMEOUT} : 250; # unit: ms

sub queue_button {
	my ($o,$action,$timeout)=@_;
	$timeout = TIMEOUT unless defined($timeout);

	if ($action eq 'show') {
		$o->after($timeout, sub{ $o->Show; });
		$action = "Cancel";
		$timeout *= 2;
	}

	my $button = $o->Subwidget("B_$action");
	$button->after($timeout, sub{ $button->invoke; });

	is($o->Show, $action,		"show $action");
}


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);

# ---- create ----
my $ld = $top->LoginDialog;
isa_ok($ld, $c_this, "new with parms");


my @drivers = qw/ Oracle ODBC CSV DB2 /;
SKIP: {
	skip "error conditions", 1 unless($ENV{'DEBUG'} eq 'FAIL');

	is(ref($ld->drivers(@drivers)), "ARRAY", "should fail");
};

is(ref($ld->drivers(\@drivers)), "ARRAY", "configure drivers");
queue_button($ld, "Cancel");

for my $driver (@drivers) {

	is($ld->driver($driver), $driver,	"driver override $driver");
	queue_button($ld, "Cancel");

	isnt($ld->driver, "",	"driver set after $driver");
}

