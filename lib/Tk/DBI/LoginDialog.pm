package Tk::DBI::LoginDialog;

=head1 NAME

Tk::DBI::LoginDialog - DBI login dialog class for Perl/Tk.

=head1 SYNOPSIS

  use Tk::DBI::LoginDialog;

  my $top = new MainWindow;

  my $d = $top->LoginDialog(-instance => 'XE');
 
  my $dbh = $d->login;

  print $d->error . "\n"
	unless defined($dbh);

  # ... or ...

  $d->Show;

  print $d->error . "\n"
	unless defined($d->dbh);

=head1 DESCRIPTION

"Tk::DBI::LoginDialog" is a dialog widget which interacts with the DBI
interface specifically to attempt a connection to a database, and thus
returning a database handle.

This widget allows the user to enter username and password details
into the dialog, and also to select driver, and other driver-specific
details where necessary.

The dialog presents three buttons as follows:

  Cancel: hides the dialog without further processing or interaction.

  Exit: calls the defined exit routine.  See L<CALLBACKS>.

  Login: attempt to login via DBI with the credentials supplied.

=cut

use 5.014002;

use strict;
use warnings;

use Carp qw(cluck confess);     # only use stack backtrace within class
use Data::Dumper;
use DBI;
use Log::Log4perl qw/ get_logger /;

# based on Tk widget writers advice at:
#    http://docstore.mik.ua/orelly/perl3/tk/ch14_01.htm

use Tk::widgets qw/ DialogBox Label Entry BrowseEntry ROText /;
use base qw/ Tk::Toplevel /;

Construct Tk::Widget 'LoginDialog';


# package constants

use constant CHAR_MASK => '*';	# masking character
use constant N_RETRY => 3;	# number of loops to attempt login
use constant S_NULL => "(null)";
use constant S_WHATAMI => "Tk::DBI::LoginDialog";
use constant RE_DRIVER_INSTANCE => "(Oracle|DB2)";


# --- package globals ---
our $VERSION = '1.001';


# --- package locals ---


# --- Tk standard routines ---
sub ClassInit {
	my ($class,$mw)=@_;

	$class->SUPER::ClassInit($mw);
}


sub Populate {
	my ($self,$args)=@_;
	my %specs;

	$self->SUPER::Populate($args);

	my $attribute = $self->privateData;
	%$attribute = (
	    logger => get_logger(S_WHATAMI),
	    driver => "",
	    dbh => undef,
	    dbname => "",
	    instance => "",
	    username => "",
	    password => "",
	    re_driver => RE_DRIVER_INSTANCE,
	);

	my $o = $self->_paint;

	$self->Advertise('LoginDialog' => $o);

	$specs{-dbh} = [ qw/ METHOD dbh Dbh /, undef ];
	$specs{-dbname} = [ qw/ METHOD dbname Dbname /, undef ];
	$specs{-driver} = [ qw/ METHOD driver Driver /, undef ];
	$specs{-instance} = [ qw/ METHOD instance Instance /, undef ];
	$specs{-login} = [ qw/ METHOD login Login /, undef ];
	$specs{-password} = [ qw/ METHOD password Password /, undef ];
	$specs{-show} = [ qw/ METHOD show Show /, undef ];
	$specs{-username} = [ qw/ METHOD username Username /, undef ];

=head1 WIDGET-SPECIFIC OPTIONS

C<LoginDialog> provides the following specific options:

=over 4

=item B<-mask>

The character or string used to hide (mask) the password.

=cut

	$specs{-mask} = [ qw/ PASSIVE mask Mask /, CHAR_MASK ];

=item B<-retry>

The number of times that attempts will be made to login to the database
before giving up.  A default applies.

=back

=cut
	$specs{-retry} = [ qw/ PASSIVE retry Retry /, N_RETRY ];

=head1 CALLBACKS

C<LoginDialog> provides the following callbacks:

=over 4

=item B<-exit>

The sub-routine to call when the B<Exit> button is pressed.
Defaults to B<Tk::exit>.

=back

=cut

	$specs{-exit} = [ qw/ CALLBACK exit Exit /, sub { Tk::exit; } ];

	$self->ConfigSpecs(%specs);

	$self->ConfigSpecs('DEFAULT' => [$o]);

	$self->Delegates('DEFAULT' => $o);
}


# --- private methods ---
sub _default_value {
	my $self = shift;
	my $attribute = shift;
	my $value = shift;
	my $data = $self->privateData;

	if (defined $value) {
		$data->{$attribute} = $value;
		return $value;
	}
	return $data->{$attribute};
}


sub _dump {
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

		$self->_dump($child, $l);
	}

	$self->_log->debug(sprintf 'ConfigSpecs [%s]', Dumper($w->Subwidget))
		if ($l == 1);
}


sub _error {
	my $self = shift;
	my $rotext = $self->Subwidget('error');

	if (@_) {
		$rotext->Contents(join(' ', @_));
	}

	my $s_text = $rotext->Contents;

	chomp($s_text);

	return $s_text;
}


sub _log {
	return shift->privateData->{'logger'};
}


sub _paint {
#	+-----------------------+
#	| label | BrowseEntry   |
#	+-----------------------+
#	| label | Entry x 3     |
#	+-----------------------+
#	| ROText (error)        |
#	+-----------------------+
	my $self = shift;
	my $w;
	my $data = $self->privateData;
	my @buttons = qw/ Cancel Exit Login /;

	my $d = $self->DialogBox(-title => S_WHATAMI,
		-buttons => [ @buttons ],
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
		-variable => \$data->{'driver'},
		)->grid(-row => 1, -column => 2, -sticky => 'w');


	$self->Advertise('dialog', $d);
	$self->Advertise('driver', $w);

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
Valid subwidget names are listed below.

=over 4

=item Name:  dialog, Class: DialogBox

Widget reference of the dialog in which credentials are entered.

=item Name:  driver, Class: BrowseEntry

Widget reference of B<driver> drop-down widget.

=item Name:  instance, Class: Entry

=item Name:  username, Class: Entry

=item Name:  password, Class: Entry

Widget references for the basic credential entry widgets.

=cut

	# add some entry fields on the right side 

	my @entry = qw/ instance username password /;
	for (my $e = 0; $e < @entry; $e++) {

		$w = (); $w = $f->Entry(-textvariable => \$data->{$entry[$e]},
			)->grid(-row => $e + 2, -column => 2, -sticky => 'w');

		$self->Advertise($entry[$e], $w);
	}

=item Name:  error, Class: ROText

Widget reference of the status/error message widget.

=cut
	# add the error/status field at the bottom

	$w = (); $w = $f->ROText( -height => 3, -width => 40,
		-wrap => 'word',
		)->grid(-row => 5, -column => 1, -columnspan => 2);

	$self->Advertise('error', $w);

=item Name:  B_Cancel, Class: Button

=item Name:  B_Exit, Class: Button

=item Name:  B_Login, Class: Button

Widget references of the three dialog buttons.

=back

=cut

	for (@buttons) {
		my $button = "B_" . $_;

		$self->Advertise($button, $d->Subwidget($button));
	}

	return $d;
}


# --- callbacks ---
sub cb_login {
	my $self = shift;
	my $button = shift;
	my $data = $self->privateData;

	if ($button eq 'Exit') {

		$self->Callback('-exit');

	} elsif ($button eq 'Cancel') {

	} elsif ($button eq 'Login') {
		$self->_log->debug("attempting to login to database");

		my $data_source = join(':', "DBI", $data->{'driver'}, 
			defined($data->{'instance'}) ? $data->{'instance'} : ""
			);

		$self->_log->debug("data_source [$data_source]");

		my $dbh = DBI->connect($data_source, $data->{'username'}, $data->{'password'});

		if (defined $dbh) {
			$data->{'dbh'} = $dbh;
			$self->_error("Connected okay.");
		} else {
			$self->_log->logwarn($DBI::errstr);
			$self->_error($DBI::errstr);
		}
	} else {
		$self->_log->logcroak("ERROR invalid action [$button]");
	}
}


sub cb_populate {
	my $self = shift;
	my $button = shift;
	my @drivers = DBI->available_drivers;
	my $data = $self->privateData;

	my $dropdown = $self->Subwidget('driver');

	$dropdown->configure('-choices', [ @drivers ]);

	for (@drivers) {
		$data->{'driver'} = $_
			if ($_ =~ /$data->{'re_driver'}/);
	}

	my $w; for (qw/ instance username password /) {

		$w = $self->Subwidget($_);

		last if ($self->$_ eq "");
	}
	#$self->_log->debug(sprintf "setting focus to [%s]", $w->PathName);
	$w->focus;

	my $pw = $self->Subwidget('password');
	my $mask = $self->cget('-mask');
	$pw->configure(-show => $mask);
}


# --- public methods ---
=head1 METHODS

=over 4

=item B<dbh>

Returns the database handle associated with the current object.

=cut

sub dbh {
	return shift->_default_value('dbh');
}


=item B<driver>

Set or return the B<driver> variable.

=cut

sub driver {
	return shift->_default_value('driver', shift);
}


=item B<dbname>

Set or return the B<database name> variable.
May not be applicable for all driver types.

=cut

sub dbname {
	return shift->_default_value('dbname', shift);
}


=item B<error>

Return the latest error message from the DBI framework following an
attempt to connect via the specified driver.  If last connection
attempt was successful, this will return "Connected okay."

=cut

sub error {
	return shift->_error;
}


=item B<password>

Set or return the B<password> variable.
May not be applicable for all driver types.

=cut

sub password {
	return shift->_default_value('password', shift);
}


=item B<instance>

Set or return the B<instance> variable.
May not be applicable for all driver types.

=cut

sub instance {
	return shift->_default_value('instance', shift);
}


=item B<username>

Set or return the B<username> variable.
May not be applicable for all driver types.

=cut

sub username {
	return shift->_default_value('username', shift);
}


=item B<login>([RETRY])

A convenience function to show the login dialog and attempt connection.
The number of attempts is prescribed by the B<RETRY> parameter, which is
optional.
Returns a DBI database handle, subject to the DBI B<connect> method.

=item B<Show>

The Show method behaves as per the DialogBox widget.

=cut

sub login {
	my $self = shift;
	my $retry = (@_) ? shift : $self->cget('-retry');

	# override silly values for retry which might have been 
	# configured by the calling application

	if ($retry <= 0) {
		$retry = N_RETRY;

		$self->configure('-retry' => $retry);

		$self->_log->debug("-retry reset to [$retry]");
	}

	while ($retry-- > 0) {

		my $button = $self->Show;

		last if (defined $self->dbh || $button =~ "Cancel");
	} 

	return $self->dbh;
}


1;
__END__

=back

=head1 VERSION

___EUMM_VERSION___

=head1 AUTHOR

Copyright (C) 2014  B<Tom McMeekin> E<lt>tmcmeeki@cpan.orgE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 2 of the License,
or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 SEE ALSO

L<perl>, L<DBI>, L<Tk>.

=cut

