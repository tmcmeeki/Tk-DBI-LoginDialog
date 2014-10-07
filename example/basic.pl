use Tk;
require Tk::DBI::LoginDialog;

my $mw = new MainWindow;

my $tld = $mw->LoginDialog;

$tld->login;

