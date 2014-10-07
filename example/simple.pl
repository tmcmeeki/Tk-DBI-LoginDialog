#!/usr/bin/perl
#########################
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl simple.pl'
#
# simple.pl - sample code for module Tk::DBI::LoginDialog
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
require Tk::DBI::LoginDialog;


# ---- globals ----
Log::Log4perl->easy_init($DEBUG);
my $top = new MainWindow;
my $log = get_logger(__FILE__);

# ---- create ----
my $ld = $top->LoginDialog(-instance => 'XE', -driver => 'Oracle');

$ld->login(3);
