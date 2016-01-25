#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 05labels.t'
#
# 05labels.t - test harness for module Tk::DBI::LoginDialog
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

if (Tk::Exists($top)) { plan tests => 18;
} else { plan skip_all => 'No X server available'; }

my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);

use constant TIMEOUT => (exists $ENV{TIMEOUT}) ? $ENV{TIMEOUT} : 250; # unit: ms

use constant ATTR_LABEL => '-text';

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
my $tld = $top->LoginDialog;

isa_ok($tld, $c_this,	"new object");

isnt("", $tld->driver,	"default dsn_label");


# ---- get sub-widgets ----
my $cycle = 1;
my ($w, @w);
for my $lt (qw/ driver username password /) {

	my $ln = "L_" . $lt;

	$w = $tld->Subwidget($ln);

	isa_ok($w, "Tk::Label",	"sub class $cycle");

	my $lv = $w->cget(ATTR_LABEL);

	is(lc($lv), lc($lt),	"widget text $cycle");

	push @w, $w;

	$cycle++;
}


# ---- modify label text ----
my $s_override = "mylabel_";
for $w (@w) {

	my $dfl = $w->cget(ATTR_LABEL);

	isnt($dfl, $s_override,		"default $cycle");

	$w->configure('-text' => $s_override . $cycle);

	queue_button($tld, "Cancel");

	my $new = $w->cget(ATTR_LABEL);

	like($new, qr/$s_override/,	"override $cycle");

	$cycle++;
}

