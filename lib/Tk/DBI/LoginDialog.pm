package Tk::DBI::LoginDialog;
#
# Tk::DBI::LoginDialog - DBI login dialog class for Perl/Tk.
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
use 5.014002;

use strict;
use warnings;

use Carp qw(cluck confess);     # only use stack backtrace within class
use Data::Dumper;
use DBI;
use File::Basename;
use Log::Log4perl qw/ get_logger /;

# based on Tk widget writers advice at:
#    http://docstore.mik.ua/orelly/perl3/tk/ch14_01.htm

#use Tk;
use Tk::widgets qw/ DialogBox Label Entry BrowseEntry ROText messageBox /;
use base qw/ Tk::Toplevel /;

# package constants

use constant S_NULL => "(null)";
use constant S_WHATAMI => "Tk::DBI::LoginDialog";

Construct Tk::Widget 'LoginDialog';

# --- package globals ---
#our $AUTOLOAD;
our $VERSION = '0.01';

# --- package locals ---
my %attribute = (
        _log => get_logger("___package___"),
);


# sub-routines

sub ClassInit {
	my ($class,$mw)=@_;

	$class->SUPER::ClassInit($mw);
}


sub Populate {
	my ($self,$args)=@_;
	my %specs;

	$self->SUPER::Populate($args);

	# the following specs are referenced during paint!

	$self->ConfigSpecs(
	    -logger => [ qw/ PASSIVE logger Logger /, get_logger(S_WHATAMI) ],
	    -log => [ qw/ METHOD _log Log /, undef ],
	);

	my $o = $self->paint;

	$self->Advertise('LoginDialog' => $o);

	$specs{-username} = [ qw/ PASSIVE username Username /, undef ];
	$specs{-password} = [ qw/ PASSIVE password Password /, undef ];
	$specs{-dbname} = [ qw/ PASSIVE dbname Dbname /, undef ];
	$specs{-instance} = [ qw/ PASSIVE instance Instance /, undef ];
	$specs{-dbh} = [ qw/ PASSIVE dbh Dbh /, undef ];
	$specs{-dump} = [ qw/ METHOD dump Dump /, undef ];
	$specs{-error} = [ qw/ METHOD error Error /, undef ];
	$specs{-drivers} = [ qw/ METHOD drivers Drivers /, undef ];
	$specs{-driver} = [ qw/ PASSIVE driver Driver /, undef ];

	$self->ConfigSpecs(%specs);
	$self->ConfigSpecs('DEFAULT' => [$o]);

	$self->Delegates('DEFAULT' => $o);
}


sub _log {
	my $self = shift;

	my $log = $self->cget('-logger');
#	my $log = $self->{'_log'};
#	printf "log [%s]\n", Dumper($log);
	return $log;
}


#sub AUTOLOAD {
#	my $self = shift;
#	my $type = ref($self) or croak("self is not an object");
#
#	my $name = $AUTOLOAD;
#	$name =~ s/.*://;   # strip fully−qualified portion
#
#	unless (exists $self->{_permitted}->{$name} ) {
#		warn "no attribute [$name] in class [$type]";
#		return undef;
#	}
#
#	if (@_) {
#		return $self->{$name} = shift;
#	} else {
#		return $self->{$name};
#	}
#}


#sub new {
#	my ($class) = shift;
#	#my $self = $class->SUPER::new(@_);
#	my $self = { _permitted => \%attribute, %attribute };
#
#	++ ${ $self->{_n_objects} };
#
#	bless ($self, $class);
#
#	my %args = @_;  # start processing any parameters passed
#	my ($method,$value);    # start processing any parameters passed
#	while (($method, $value) = each %args) {
#
#		confess "SYNTAX new(method => value, ...) value not specified"
#		unless (defined $value);
#
#		$self->_log->debug("method [self->$method($value)]");
#
#		$self->$method($value);
#	}
#
#	return $self;
#}


sub drivers {
	my $self = shift;

	my @driver_names = DBI->available_drivers;

	for (@driver_names) {
		$self->_log->info("driver [$_]\n");
	}

	return @driver_names;
}


sub sources {
	my $self = shift;
	my $driver = shift;

	$self->_log->logcroak("SYNTAX: sources(driver)") unless defined($driver);
#	my @data_sources = DBI->data_sources($driver);
#
#	for (@data_sources) {
#		$self->_log->info("source [$_]\n");
#	}
}


sub cb_login {
	my $self = shift;
	my $button = shift;

	$self->_log->debug("button [$button]");

	if ($button eq 'Exit') {
		$self->_log->info("exiting");
		Tk::exit;
	} elsif ($button eq 'Cancel') {
		$self->_log->info("login sequence cancelled");
	} elsif ($button eq 'Login') {
		$self->_log->debug("attempting to login to database");

		my $data_source = join(':', "DBI", $self->{'driver'}, 
			defined($self->{'instance'}) ? $self->{'instance'} : ""
			);

		$self->_log->debug("data_source [$data_source]");

		my $dbh = DBI->connect($data_source, $self->{'username'}, $self->{'password'});

		if (defined $dbh) {
			$self->_log->debug(sprintf "connected okay [%s]", Dumper($dbh));
			$self->error("Connected okay.");
			$self->configure("-dbh" => $dbh);
		} else {
			$self->_log->logwarn($DBI::errstr);
			$self->error($DBI::errstr);

			$self->toplevel->messageBox(
				-message => $DBI::errstr,
				-title => S_WHATAMI,
			);
		}
	} else {
		$self->_log->logcroak("ERROR invalid action [$button]");
	}
}


sub cb_populate {
	my $self = shift;
	my $button = shift;
	my @drivers = $self->drivers;

	$self->_log->debug("button [$button]");

	my $dropdown = $self->Subwidget('driver');

	$dropdown->configure('-choices', [ @drivers ]);

	for (@drivers) {
		$self->{'driver'} = $_
			if ($_ =~ /(Oracle|DB2)/);
	}

	my $focus = $self->Subwidget('instance');

	$self->_log->debug($self->PathName);
	$self->_log->debug($focus->PathName);

	$self->configure(-focus => $focus);
}


# +-----------------------+
# | label | BrowseEntry   |
# +-----------------------+
# | label | Entry x 3     |
# +-----------------------+
# | ROText (error)        |
# +-----------------------+

sub paint {
	my $self = shift;
	my $w;

	my $d = $self->DialogBox(-title => S_WHATAMI,
		-buttons => [ qw/ Cancel Exit Login / ],
		-default_button => 'Login',
		-command => [ \&cb_login, $self ],
		-showcommand => [ \&cb_populate, $self ],
	);

	my $f = $d->add('Frame', -borderwidth => 3, -relief => 'ridge')->pack;

	# add some labels on the left side

	$f->Label(-text => 'Driver', 
		)->grid(-row => 1, -column => 1, -sticky => 'e');
	$f->Label(-text => 'Instance', 
		)->grid(-row => 2, -column => 1, -sticky => 'e');
	$f->Label(-text => 'Username', 
		)->grid(-row => 3, -column => 1, -sticky => 'e');
	$f->Label(-text => 'Password', 
		)->grid(-row => 4, -column => 1, -sticky => 'e');


	# add the driver drop-down

	$w = (); $w = $f->BrowseEntry(-state => 'readonly',
		-variable => \$self->{'driver'},
		)->grid(-row => 1, -column => 2, -sticky => 'w');

	$self->Advertise('driver', $w);


	# add some entry fields on the right side 

	my @entry = qw/ instance username password /;
	for (my $e = 0; $e < @entry; $e++) {

		$w = (); $w = $f->Entry(-textvariable => \$self->{$entry[$e]},
			)->grid(-row => $e + 2, -column => 2, -sticky => 'w');

		$self->Advertise($entry[$e], $w);

		$d->configure(-focus => $w)
			if ($e == 0);
	}


	# add the error/status field at the bottom

	$w = (); $w = $f->ROText( -height => 3, -width => 40,
		-wrap => 'word',
		)->grid(-row => 5, -column => 1, -columnspan => 2);

	$self->Advertise('error', $w);

	return $d;
}


sub dump {
	my $self = shift;
	my $w = shift;	# widget
	my $l = shift;	# level

	$w = $self unless (defined $w);
	$l = 0 unless (defined $l);

	$self->_log->debug(sprintf "path [%s] level [%d] widget [%s]",
		$w->PathName,
		$l++, $w->name,
	);

	for my $child ($w->children) {

		$self->dump($child, $l);
	}

	$self->_log->debug(sprintf 'ConfigSpecs [%s]', Dumper($w->Subwidget))
		if ($l == 1);
}


sub error {
	my $self = shift;
	my $rotext = $self->Subwidget('error');

	unless (@_) {
		return $rotext->Contents;
	} else {
		my $text = join(' ', @_);

		$self->_log->debug("setting status to [$text]");
		$rotext->Contents($text);
	}
}


1;
__END__

=head1 NAME

Tk::DBI::LoginDialog - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Tk::DBI::LoginDialog;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Tk::DBI::LoginDialog, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

=over 4

=item B<-label>

Label text to appear next to the Optionmenu.  If I<-labelVariable> is
also specified, I<-label> takes precedence.

=item B<-labelPack>


=back

=head1 METHODS

None.

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
Valid subwidget names are listed below.

=over 4

=item Name:  label, Class: Label

Widget reference of Label widget.

=item Name:  optionmenu, Class: Optionmenu

  Widget reference of Optionmenu widget.

=back

=head1 EXAMPLE

I<$lo> = I<$mw>-E<gt>B<LabOptionmenu>(-label =E<gt> 'Ranking:',
-options =E<gt> [1 .. 5], -labelPack =E<gt> [-side => 'left']);

I<$lo>-E<gt>configure(-labelFont =E<gt> [qw/Times 18 italic/]);

=head1 VERSION

___EUMM_VERSION___

=head1 AUTHOR

Copyright (C) 2014  B<Tom McMeekin> tmcmeeki@cpan.org

=head1 SEE ALSO

L<perl>, DBI, Tk.

=cut

