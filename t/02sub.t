#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02sub.t'
#
# 02sub.t - test harness for module Tk::DBI::LoginDialog
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

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Log::Log4perl qw/ :easy /;
use Test::More tests => 9;
use Tk;

use constant TIMEOUT => 250; # unit: ms

sub queue_button {
	my ($o,$action)=@_;

	my $button = $o->Subwidget("B_$action");

	$button->after(TIMEOUT, sub{ $button->invoke; });

	is($o->Show, $action,		"show $action");
}


BEGIN { use_ok('Tk::DBI::LoginDialog') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);
my $c_this = 'Tk::DBI::LoginDialog';

# ---- create ----
my $top = new MainWindow;
my %field = (instance => "val_0", username => "val_1", password => "val_2");

my $ld0 = $top->LoginDialog(%field);
isa_ok($ld0, $c_this, "new with parms");

# ---- destroy some subwidgets ----
queue_button($ld0, "Cancel");

for (keys %field, "error") {

	my $w = $ld0->Subwidget($_);

	$w->destroy;

	ok(Tk::Exists($w) == 0,	"destroy subwidget $_");

	$ld0->update;
}

my $ld1 = $top->LoginDialog;
isa_ok($ld1, $c_this, "new no parms");


$ld1->configure(-title => "HELLO WORLD");

$ld1->update;
queue_button($ld1, "Cancel");

