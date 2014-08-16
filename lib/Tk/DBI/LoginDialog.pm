package Tk::DBI::LoginDialog;
#
# Tk::DBI::LoginDialog - DBI login dialog class for Perl/Tk.
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
use Tk::widgets qw/ DialogBox Label Entry BrowseEntry ROText /;
use base qw/ Tk::Toplevel /;

Construct Tk::Widget 'LoginDialog';


# package constants

use constant N_RETRY => 3;	# number of loops to attempt login
use constant S_NULL => "(null)";
use constant S_WHATAMI => "Tk::DBI::LoginDialog";
use constant RE_DRIVER_INSTANCE => "(Oracle|DB2)";


# --- package globals ---
#our $AUTOLOAD;
our $VERSION = '0.01';


# --- package locals ---


# sub-routines

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
	    instance => "",
	    username => "",
	    password => "",
	    re_driver => RE_DRIVER_INSTANCE,
	);

#	$self->ConfigSpecs(
#	    -logger => [ qw/ PASSIVE logger Logger /, get_logger(S_WHATAMI) ],
#	    -log => [ qw/ METHOD _log Log /, undef ],
#	$specs{-dump} = [ qw/ METHOD dump Dump /, undef ];
#	);

	my $o = $self->paint;

	$self->Advertise('LoginDialog' => $o);

	$specs{-username} = [ qw/ PASSIVE username Username /, undef ];
	$specs{-password} = [ qw/ PASSIVE password Password /, undef ];
	$specs{-dbname} = [ qw/ PASSIVE dbname Dbname /, undef ];
	$specs{-instance} = [ qw/ PASSIVE instance Instance /, undef ];
	$specs{-dbh} = [ qw/ PASSIVE dbh Dbh /, undef ];
	$specs{-error} = [ qw/ METHOD error Error /, undef ];
#	$specs{-exit} = [ qw/ METHOD exit Exit /, sub { Tk::exit; } ];
	$specs{-drivers} = [ qw/ METHOD drivers Drivers /, undef ];
	$specs{-driver} = [ qw/ PASSIVE driver Driver /, undef ];
	$specs{-retry} = [ qw/ PASSIVE retry Retry /, N_RETRY ];
	$self->ConfigSpecs(%specs);

	$self->ConfigSpecs('DEFAULT' => [$o]);

	$self->Delegates('DEFAULT' => $o);
}


# --- private methods ---

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


sub _log {
	my $self = shift;
	my $logger = $self->privateData->{'logger'};

#	my $log = $self->cget('-logger');
#	my $log = $self->{'_log'};
	return $logger;
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


sub loop {
	my $self = shift;
	my $retry =  $self->cget('-retry');

	# override silly values for retry which might have been 
	# configured by a users

	if ($retry <= 0) {
		$retry = N_RETRY;

		$self->configure('-retry' => $retry);

		$self->_log->debug("-retry reset to [$retry]");
	}

	while ($retry-- > 0) {

		my $button = $self->Show;

		last if (defined $self->cget('-dbh')
			|| $button =~ "Cancel");
	} 

	return $self->cget('-dbh');
}


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
	my $data = $self->privateData;

	$self->_log->debug("button [$button]");

	if ($button eq 'Exit') {

		$self->_log->info("exiting");
#		&{$self->cget('-exit')};
		Tk::exit;

	} elsif ($button eq 'Cancel') {

		$self->_log->info("login sequence cancelled");

	} elsif ($button eq 'Login') {
		$self->_log->debug("attempting to login to database");

		my $data_source = join(':', "DBI", $data->{'driver'}, 
			defined($data->{'instance'}) ? $data->{'instance'} : ""
			);

		$self->_log->debug("data_source [$data_source]");

		my $dbh = DBI->connect($data_source, $data->{'username'}, $data->{'password'});

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
	my $data = $self->privateData;

	$self->_log->debug("button [$button]");

	my $dropdown = $self->Subwidget('driver');

	$dropdown->configure('-choices', [ @drivers ]);

	for (@drivers) {
		$data->{'driver'} = $_
			if ($_ =~ /$data->{'re_driver'}/);
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
	my $data = $self->privateData;

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
		-variable => \$data->{'driver'},
		)->grid(-row => 1, -column => 2, -sticky => 'w');

	$self->Advertise('driver', $w);


	# add some entry fields on the right side 

	my @entry = qw/ instance username password /;
	for (my $e = 0; $e < @entry; $e++) {

		$w = (); $w = $f->Entry(-textvariable => \$data->{$entry[$e]},
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

=head1 AUTHOR

Copyright (C) 2014  B<Tom McMeekin> E<lt>tmcmeeki@cpan.orgE<gt>

=head1 SYNOPSIS

  use Tk::DBI::LoginDialog;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Tk::DBI::LoginDialog, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

=over 4

=item B<-label>

Label text to appear next to the LoginDialog.  If I<-labelVariable> is
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

=item Name:  LoginDialog, Class: LoginDialog

  Widget reference of LoginDialog widget.

=back

=head1 EXAMPLE

I<$lo> = I<$mw>-E<gt>B<LoginDialog>(-label =E<gt> 'Ranking:',
-options =E<gt> [1 .. 5], -labelPack =E<gt> [-side => 'left']);

I<$lo>-E<gt>configure(-labelFont =E<gt> [qw/Times 18 italic/]);

=head1 VERSION

___EUMM_VERSION___

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

L<perl>, DBI, Tk.

=cut
