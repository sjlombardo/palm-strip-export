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
use Tk;
use Tk::LabFrame;

## The next 3 lines are a hack to support PerlApp
## It it needs to know all direct dependencies
use Palm::Zetetic::Strip::CryptV10;
use Palm::Zetetic::Strip::PDB::PasswordV10;
use Palm::Zetetic::Strip::PDB::SystemsV10;
use Palm::Zetetic::Strip::PDB::AccountsV10;

use vars qw($VERSION $file
            $PROGRAM $opt_help $opt_directory $opt_file $opt_password
	    $mainwindow $source_dialog $target_dialog
    	);

$VERSION = "1.0.4";
$PROGRAM = basename($0);

my $strip;
my $version;
my $rc;

$mainwindow = MainWindow->new(-title => "Palm Strip Export");
my $frame = $mainwindow->LabFrame(-label => "Configuration",
                                   -labelside => "acrosstop")->pack(-anchor=>'center', -padx => 20, -pady => 20);

my $r0c0 = $frame->Frame->grid(-row => 0, -column => 0, -sticky => 'nw', -padx => 10, -pady => 5);
my $r0c1 = $frame->Frame->grid(-row => 0, -column => 1, -sticky => 'nw', -padx => 10, -pady => 5);
my $r1c0 = $frame->Frame->grid(-row => 1, -column => 0, -sticky => 'nw', -padx => 10, -pady => 5);
my $r1c1 = $frame->Frame->grid(-row => 1, -column => 1, -sticky => 'nw', -padx => 10, -pady => 5);
my $r2c0 = $frame->Frame->grid(-row => 2, -column => 0, -sticky => 'nw', -padx => 10, -pady => 5);
my $r2c1 = $frame->Frame->grid(-row => 2, -column => 1, -sticky => 'nw', -padx => 10, -pady => 5);
my $r3 = $frame->Frame->grid(-row => 3, -column => 0, -columnspan => 2, -padx => 10, -pady => 5);

  

$r0c0->Label(-text => "Password")->pack(-side=>"top", -anchor => "ne");
$r0c1->Entry(-width => 20, -textvariable => \$opt_password)->pack(-side => "top", -anchor => "ne"); 

$r1c0->Button(
  -text => 'Choose Directory',
  -command => \&getDirectory
)->pack(-side => "top", -anchor => "ne"); 
$r1c1->Entry(-width => 60, -textvariable => \$opt_directory)->pack(-side => "top", -anchor => "ne"); 

$r2c0->Button(
  -text => 'Save As',
  -command => \&getTarget
)->pack(-side => "top", -anchor => "ne"); 
$r2c1->Entry(-width => 60, -textvariable => \$opt_file)->pack(-side => "top", -anchor => "ne"); 

$r3->Button(
  -text => 'Export To File',
  -command => \&export
)->pack(-side => "top", -anchor => "center"); 

MainLoop();

sub getDirectory {
  $opt_directory = $mainwindow ->chooseDirectory();
}

sub getTarget {
  $opt_file = $mainwindow->getSaveFile(
    -initialfile => 'strip.csv',
    -defaultextension => '.csv');
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
    $mainwindow->messageBox(-message => "$message\n", -type => "ok");
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
        $mainwindow->messageBox(-message => "Unable to find a Strip database in that location\n", -type => "ok");
	return;
    }
    if (! $version->is_1_0())
    {
        $mainwindow->messageBox(-message => "Unable to open database. Please upgrade your database to strip 2.0 before running\n", -type => "ok");
	return;
    }
    
    if (! $strip->set_password($opt_password))
    {
        $mainwindow->messageBox(-message => "You entered a bad password\n", -type => "ok");
	return;
    }
    $strip->load();

    unless(open($file, "> $opt_file")) {
      $mainwindow->messageBox(-message => "Unable to open output file\n", -type => "ok");
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
    $mainwindow->messageBox(-message => "Conversion complete!\n", -type => "ok");
  }
}
