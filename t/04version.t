#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 04version.t'
#
# 04version.t - test harness for module Tk::DBI::LoginDialog
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

if (Tk::Exists($top)) { plan tests => 14;
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

isa_ok($ld, $c_this, "new object");


# ---- show version ----
my $default = $ld->version;
isnt($default, "",		"retrieve version string");
queue_button($ld, "Cancel");

is($ld->version(1), $default,	"render version");
queue_button($ld, "Cancel");

is($ld->version, $default,	"hide version");
queue_button($ld, "Cancel");

is($ld->version, $default,	"hide-again version");
queue_button($ld, "Cancel");

is($ld->version(1), $default,	"re-render version");
queue_button($ld, "Cancel");

is($ld->version(0), $default,	"re-hide version");
queue_button($ld, "Cancel");

