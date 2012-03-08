#
# Minimal and Scalable Passive DNS - Redis feeder
#
# Read dnscap output to feed a Redis database
#
#
# Copyright (C) 2010-2012 Alexandre Dulaunoy
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use Date::Manip;
use Redis;
use Scalar::Util;
use IO::Handle;

$| = 1;

my $block = 0;
my $date;
my %counter = (
    "processed" => 0,
    "redisrst"  => 0
);
my @RRType = ( "A", "AAAA", "CNAME", "NS" );
my %RRTypevalue = (
    "A"     => 1,
    "AAAA"  => 28,
    "CNAME" => 5,
    "NS"    => 2,
    "MX"    => 15,
    "SRV"   => 33
);

my $parsedate = new Date::Manip::Date;

my $r = Redis->new( server => '127.0.0.1:6379', encoding => undef );

my $stdin = new IO::Handle;
$stdin->fdopen( fileno(STDIN), "r" );

while ( defined( $_ = $stdin->getline ) ) {

    if ( $counter{'redisrst'} == 1 ) {
        $r->quit;
        undef($r);
        print "Reset\n";
        $r = Redis->new( server => '127.0.0.1:6379', encoding => undef );
        $counter{'redisrst'} = 0;
    }
    if (m/^\[/) {
        $block = 1;
        {
            my @s = split;
            $date = $s[1];
        }
    }

    if ( !(m/^\[/) ) {
        $_ =~ s/\cI//;

        # discarding - [1.2.3.4].53 [149.13.33.69].5234
        if (m/^\[/) { next; }

        # split - 21 ns10.ovh.net,IN,AAAA,172800,2001:41d0:1:1981::1 \
        if (m/^\d* /) {
            $_ =~ s/^\d* //;
        }

        # discarding - dns QUERY,NOERROR,26278,qr|rd|ra \
        if (m/^dns /) { next; }

        # decode line
        ProcessRequest( $date, $_ );
        $counter{'processed'}++;
    }
    if ( ( $counter{'processed'} % 1000 ) == 0 ) {
        $counter{'redisrst'} = 1;
        print "Processed:"
          . $counter{'processed'}
          . " Redist RST:"
          . $counter{'redisrst'} . "\n";
    }

}

sub ProcessRequest {
    my $epoch = shift;
    my $line  = shift;
    chomp($line);

    #my $err   = $parsedate->parse($date);
    #my $epoch = $parsedate->printf('%s');

    my @l = split( /,/, $line );
    if ( $l[2] ~~ @RRType ) {
        my @rdatas = split( / /, $l[4] );

        #$l[4] =~ s/\s\\.*$//g;
        #$l[4] =~ s/(.*)\s/$1/g;
        print $l[0] . " " . $l[2] . " " . "$rdatas[0]\n";
        my @rdatap = split( / /, $l[4] );
        RedisUpdate( $l[0], $l[2], $rdatap[0], $epoch );
        undef(@rdatap);
    }
}

sub RedisUpdate {
    my $name       = lc(shift);
    my $recordtype = shift;
    my $rdata      = lc(shift);
    my $timestamp  = shift;

    my $recordtypevalue = $RRTypevalue{$recordtype};
    my $pdns_r          = "r:" . $name . ":" . $recordtypevalue;
    my $pdns_v          = "v:" . $rdata;
    my $pdns_s          = "s:" . $name . ":" . $rdata;
    my $pdns_l          = "l:" . $name . ":" . $rdata;
    my $pdns_o          = "o:" . $name . ":" . $rdata;

    my $ret = $r->sadd( $pdns_r, $rdata );
    $ret = $r->sadd( $pdns_v, $name );

    # set first seen value
    if ( !( $r->exists($pdns_s) ) ) {
        $ret = $r->set( $pdns_s, $timestamp );
    }

    # set last seen value
    $ret = $r->set( $pdns_l, $timestamp );

    # increment the occurence value
    $ret = $r->incr($pdns_o);
}
