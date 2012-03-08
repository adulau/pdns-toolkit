#
# Minimal and Scalable Passive DNS - Query tool
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


use POSIX qw(strftime);
use Redis;
use Date::Manip;

# will lookup the following RR types
my %RRTypevalue = (
    "A"     => 1,
    "AAAA"  => 28,
    "CNAME" => 5,
    "NS"    => 2

);

my $r = Redis->new( server => '127.0.0.1:6379', encoding => undef );


while ( my ( $typename, $typevalue ) = each(%RRTypevalue) ) {

    my @x = Lookup( $ARGV[0], $typevalue );

    if ( defined(@x) ) {
        foreach $p (@x) {
            print $p. "("
              . $typename . ")"
              . " first seen: "
              . NiceDate( FirstSeen( $ARGV[0], $p ) )
              . " last seen: "
              . NiceDate( LastSeen( $ARGV[0], $p ) )
              . " Hits: "
              . OccTuple( $ARGV[0], $p ) . "\n";
            print " behind: " . join( ",", LookupIP($p) ) . "\n";
        }
    }

}

sub NiceDate {
    my $epochvalue = shift;

    return strftime( "%Y%m%d-%H:%M:%S", localtime($epochvalue) );

}

sub Lookup {
    my $name = shift;
    my $type = shift;

    # default A record
    if ( !( defined($type) ) ) { $type = 1; }
    my $key = "r:$name:$type";
    return $r->smembers($key);
}

sub LookupIP {
    my $name = shift;
    my $key  = "v:$name";
    return $r->smembers($key);
}

sub FirstSeen {
    my $name  = shift;
    my $rdata = shift;

    my $key = "s:$name:$rdata";
    return $r->get($key);
}

sub LastSeen {
    my $name  = shift;
    my $rdata = shift;

    my $key = "l:$name:$rdata";
    return $r->get($key);
}

sub OccTuple {
    my $name  = shift;
    my $rdata = shift;

    my $key = "o:$name:$rdata";
    return $r->get($key);
}
