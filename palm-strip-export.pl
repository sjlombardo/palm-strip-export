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

## The next 3 lines are a hack to support PerlApp
## It it needs to know all direct dependencies
use Palm::Zetetic::Strip::CryptV10;
use Palm::Zetetic::Strip::PDB::PasswordV10;
use Palm::Zetetic::Strip::PDB::SystemsV10;
use Palm::Zetetic::Strip::PDB::AccountsV10;

use vars qw($VERSION $file
            $PROGRAM $opt_help $opt_directory $opt_file $opt_password);

$VERSION = "1.0.4";
$PROGRAM = basename($0);

sub usage
{
    print <<USAGE;
$PROGRAM [OPTION ...]
    -d, -directory=DIRECTORY
                                Sets directory containing databse files.
    -h, --help                  Print usage and exit.
    -w, --width=WIDTH           Forces column width to WIDTH characters.
    -f, --file=FILE          Write to output file
    -p, --password=PASSWORD     System password

USAGE
}

my $strip;
my $version;
my $rc;

$opt_directory = ".";
$opt_file = "-"; # STDOUT

$rc = GetOptions("directory|d=s",
                 "file|f=s",
                 "password|p=s",
                 "width|w=i",
                 "help|h");

if (! $rc)
{
    usage_error(1);
}

if ($opt_help)
{
    usage();
    exit 0;
}

if (@ARGV > 0)
{
    usage_error(1);
}

open($file, "> $opt_file") or die "unable to open file $!";

$strip = new Palm::Zetetic::Strip();
$strip->set_directory($opt_directory);
$version = $strip->get_strip_version();

if (! $version->is_1_0())
{
    print "Unable to open database. Please upgrade your database to strip 2.0 before running\n";
    exit(1);
}

if (! $strip->set_password($opt_password))
{
	print "bad password\n";
	exit(1);
}
$strip->load();

my @systems = $strip->get_systems();
foreach my $system (@systems)
{
    my $category = $system->get_name();
    my @accounts = $strip->get_accounts($system);
    next if (@accounts == 0);

    print $file "\"Category\",\"Entry\",\"Username(field)\",\"Service(field)\",\"Password(password)\",\"Note(note)\"\n";
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

