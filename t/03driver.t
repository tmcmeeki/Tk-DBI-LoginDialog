#!/usr/bin/perl
#########################
# Before `make install' is performed this script should0 be runnable with
# `make test'. After `make install' it should0 work as `perl 03driver.t'
#
# 03driver.t - test harness for module Tk::DBI::LoginDialog
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
# You should0 have received a copy of the GNU General Public License
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
my $ld0 = $top->LoginDialog;
my $ld1 = $top->LoginDialog;

isa_ok($ld0, $c_this, "new object 0");
isa_ok($ld1, $c_this, "new object 1");


# ---- override driver ----
my $default = $ld0->driver;

isnt($default, "",				"default driver");
isnt($ld0->driver("_invalid_"), "_invalid_",	"prevent invalid override");
is($ld0->driver, $default,			"driver still valid");

$log->debug(sprintf "default drivers [%s]", Dumper($ld0->drivers));

# ---- override drivers ----
my @drivers = qw/ Oracle ODBC CSV DB2 /;

is_deeply($ld0->drivers(@drivers), [@drivers], "configure drivers");

queue_button($ld0, "Cancel");

for my $driver (@drivers) {

	is($ld0->driver($driver), $driver,	"driver override $driver");

	queue_button($ld0, "Cancel");

	isnt($ld0->driver, "",			"driver set after $driver");
}


# ---- constrain drivers ----
my $drivers = $ld1->drivers;
my $count = @$drivers;
my $driver = $ld1->driver;

ok($count > 0,			"drivers are available");
isnt(shift(@$drivers), "",	"remove a driver");
isnt(pop(@$drivers), "",	"remove another driver");
ok(scalar(@{ $ld1->drivers }) == ($count - 2),	"have removed");
isnt($ld1->driver, $driver,	"revised default");

queue_button($ld1, "Login");
queue_button($ld1, "Login");

