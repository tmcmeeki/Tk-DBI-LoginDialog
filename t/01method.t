#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01method.t'
#
# 01method.t - test harness for module Tk::DBI::LoginDialog
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
use Test::More tests => 23;
use Tk;
use Data::Dumper;


BEGIN { use_ok('Tk::DBI::LoginDialog') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);


# ---- main ----
my $c_this = 'Tk::DBI::LoginDialog';

my $top = new MainWindow;
my $ld0 = $top->LoginDialog;

isa_ok( $ld0, $c_this, "new no parm");
is( Tk::Exists($ld0), 1,	"exists");

eval { $ld0->update; };
is($@, "", "update $c_this");

eval { $ld0->destroy; };
is($@, "", "destroy $c_this");

isnt(Tk::Exists($ld0), 1, "destroyed $c_this");

my $ld1 = $top->LoginDialog;
isa_ok( $ld1, $c_this, "new no parm");

for my $method (qw/ driver dbname password instance username /) {

	my $condition = "method get $method";
	my $value = $ld1->$method;
	is($value, "",			$condition);

	$condition = "method set $method";
	$value = $ld1->$method("DUMMY");
	ok($value eq "DUMMY",			$condition);
}

for my $option (qw/ -mask -retry /) {
	my $value = $ld1->cget($option);
	isnt($value, "",	"option get $option");

	isa_ok($ld1->configure($option => "X"), "ARRAY", "option configure $option");
	$value = $ld1->cget($option);
	is($value, "X",	"option verify $option");
}

