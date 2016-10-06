#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 06buttons.t'
#
# 06buttons.t - test harness for module Tk::DBI::LoginDialog
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

# ---- test harness ----
use lib 't';
use tester;

my $ot = tester->new;
$ot->tests(12);


# ---- module ----
my $c_this = 'Tk::DBI::LoginDialog';
require_ok($c_this);


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $log = get_logger(__FILE__);
my $top = $ot->top;


# ---- test buttons ----
my $tld0 = $top->LoginDialog;
isa_ok($tld0, $c_this,	"new object 1");
$ot->queue_button($tld0, "Cancel");


my @buttons = qw/ help me rhonda /;
my $tld1 = $top->LoginDialog(-buttons => [ @buttons ]);
isa_ok($tld1, $c_this,	"new object 2");
$ot->queue_button($tld1, $buttons[0]);
$ot->queue_button($tld1, $buttons[-1]);


my $b_dodgy ="extra";
unshift @buttons, $b_dodgy;
my $tld2 = $top->LoginDialog(-buttons => [ @buttons ]);
isa_ok($tld2, $c_this,	"new object 3");
$ot->queue_button($tld2, $b_dodgy);
#$ot->queue_button($tld2, $buttons[-1]);	# will fail; invalid action

