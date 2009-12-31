#!/usr/bin/perl -w

use strict;
use English;
use FileHandle;
use Fcntl;
use File::Basename;
use Getopt::Long;
use POSIX qw(tmpnam);
use Term::ReadKey;
use Palm::Zetetic::Strip;
use Tkx;

## The next 3 lines are a hack to support PerlApp
## It it needs to know all direct dependencies
use Palm::Zetetic::Strip::CryptV10;
use Palm::Zetetic::Strip::PDB::PasswordV10;
use Palm::Zetetic::Strip::PDB::SystemsV10;
use Palm::Zetetic::Strip::PDB::AccountsV10;

use vars qw($opt_directory $opt_file $opt_password $strip $version $file);

my $IS_AQUA = Tkx::tk_windowingsystem() eq "aqua";

my $mw = Tkx::widget->new(".");
$mw->g_wm_title("Palm Strip Export");

my $frame = $mw->new_frame();
$frame->g_pack(-anchor=>'center', -padx => 20, -pady => 20);

my $password_label = $frame->new_ttk__label(-text => "Password");
$password_label->g_grid(-row => 0, -column => 0, -sticky => 'nw', -padx => 10, -pady => 5);

my $password_entry = $frame->new_ttk__entry(-width => 20, -textvariable => \$opt_password);
$password_entry->g_grid(-row => 0, -column => 1, -sticky => 'nw', -padx => 10, -pady => 5);

my $directory_button = $frame->new_ttk__button(-text => 'Choose Directory',  -command => \&getDirectory);
$directory_button->g_grid(-row => 1, -column => 0, -sticky => 'nw', -padx => 10, -pady => 5);

my $directory_entry = $frame->new_ttk__entry(-width => 60, -textvariable => \$opt_directory);
$directory_entry->g_grid(-row => 1, -column => 1, -sticky => 'nw', -padx => 10, -pady => 5);

my $file_button = $frame->new_ttk__button(-text => 'Save As',  -command => \&getTarget);
$file_button->g_grid(-row => 2, -column => 0, -sticky => 'nw', -padx => 10, -pady => 5);

my $file_entry = $frame->new_ttk__entry(-width => 60, -textvariable => \$opt_file);
$file_entry->g_grid(-row => 2, -column => 1, -sticky => 'nw', -padx => 10, -pady => 5);

my $export_button = $frame->new_ttk__button(-text => 'Export To File',  -command => \&export);
$export_button->g_grid(-row => 3, -column => 1, -sticky => 'nw', -padx => 10, -pady => 5);
 
Tkx::MainLoop();

sub getDirectory {
  $opt_directory = Tkx::tk___chooseDirectory()
}

sub getTarget {
  $opt_file = Tkx::tk___getSaveFile(-initialfile => 'strip.csv', -defaultextension => '.csv');
}

sub validate {
  my $message = "";
  unless($opt_password) {
    $message .= "Enter your password\n";
  }
  unless($opt_directory) {
    $message .= "Choose the directory to load Strip databases from\n"; 
  }
  unless($opt_file) {
    $message .= "Choose the file to save entries to\n"; 
  }
  if($message) {
    Tkx::tk___messageBox(-message => "$message\n", -type => "ok");
    return 0;
  }
  return 1;
}

sub export {
  if(validate()) {
    
    
    $strip = new Palm::Zetetic::Strip();
    eval {
      $strip->set_directory($opt_directory);
      $version = $strip->get_strip_version();
    }; if ($@) {
        Tkx::tk___messageBox(-message => "Unable to find a Strip database in that location\n", -type => "ok");
	return;
    }
    if (! $version->is_1_0())
    {
        Tkx::tk___messageBox(-message => "Unable to open database. Please upgrade your database to strip 2.0 before running\n", -type => "ok");
	return;
    }
    
    if (! $strip->set_password($opt_password))
    {
        Tkx::tk___messageBox(-message => "You entered a bad password\n", -type => "ok");
	return;
    }
    $strip->load();

    unless(open($file, "> $opt_file")) {
      Tkx::tk___messageBox(-message => "Unable to open output file\n", -type => "ok");
      return;
    }     

    my @systems = $strip->get_systems();
    foreach my $system (@systems)
    {
        my $category = $system->get_name();
        my @accounts = $strip->get_accounts($system);
        next if (@accounts == 0);
    
        print $file "\"Category\",\"Entry\",\"Username\",\"Service\",\"Password\",\"Note\"\n";
        foreach my $account (@accounts)
        {
            my $system_name = $account->get_system();
            my $username = $account->get_username();
            my $service = $account->get_service();
            my $password = $account->get_password();
            my $note = $account->get_comment();
     	$password =~ s/\n/ /g;
     	$note =~ s/\n/ /g;
        	print $file "\"$category\",\"$system_name\",\"$username\",\"$service\",\"$password\",\"$note\"\n";
        }
    }
    
    $file->close();
    Tkx::tk___messageBox(-message => "Conversion complete!\n", -type => "ok");
  }
}
