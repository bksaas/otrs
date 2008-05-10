#!/usr/bin/perl -w
# --
# DBUpdate-to-2.3.pl - update script to migrate OTRS 2.2.x to 2.3.x
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: DBUpdate-to-2.3.pl,v 1.2 2008-05-10 10:31:22 mh Exp $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . "/Kernel/cpan-lib";

use vars qw($VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

use Getopt::Std;
use Kernel::Config;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::Encode;
use Kernel::System::DB;
use Kernel::System::Main;

# get options
my %Opts;
getopt( 'h', \%Opts );
if ( $Opts{'h'} ) {
    print STDOUT "DBUpdate-to-2.3.pl <Revision $VERSION> - Database migrate script\n";
    print STDOUT "Copyright (c) 2001-2008 OTRS AG, http://otrs.org/\n";
    exit 1;
}

# create needed objects
my %CommonObject;
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-Test',
    %CommonObject,
);
$CommonObject{MainObject}   = Kernel::System::Main->new(%CommonObject);
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{TimeObject}   = Kernel::System::Time->new(%CommonObject);
$CommonObject{DBObject}     = Kernel::System::DB->new(%CommonObject);

print STDOUT "Start migration of the system...\n\n";

# ------------------------------------------------------------ #
# migrate the service sla relations
# ------------------------------------------------------------ #

{

    print STDOUT "Migrate the service sla relations... ";

    # get all existing relations
    my $Success = $CommonObject{DBObject}->Prepare(
        SQL => "SELECT id, service_id FROM sla ORDER BY id ASC",
    );

    if ( !$Success ) {
        print STDOUT "impossible or not required!\n";
    }
    else {

        # fetch the result
        my @ServiceSLARelation;
        while ( my @Row = $CommonObject{DBObject}->FetchrowArray() ) {

            my %Relation;
            $Relation{SLAID}     = $Row[0];
            $Relation{ServiceID} = $Row[1];

            push @ServiceSLARelation, \%Relation;
        }

        # add the new relations
        RELATION:
        for my $Relation (@ServiceSLARelation) {

            next RELATION if !$Relation->{SLAID};
            next RELATION if !$Relation->{ServiceID};

            # add one relation
            $CommonObject{DBObject}->Do(
                SQL => "INSERT INTO service_sla "
                    . "(service_id, sla_id) VALUES ($Relation->{ServiceID}, $Relation->{SLAID})",
            );
        }

        print STDOUT " done\n";
    }
}

print STDOUT "\nMigration of the system completed!\n";

exit 0;
