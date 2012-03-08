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

package PDNS::Query;

use base 'Exporter';

use POSIX qw(strftime);
use Redis;
use Date::Manip;
use Time::Format;

my %RRTypevalue = (
    "A"     => 1,
    "NS"    => 2,
    "AAAA"  => 28,
    "CNAME" => 5
);

my $r = Redis->new( server => '127.0.0.1:6379', encoding => undef );

my $burl = "/l/";

sub Query {

    my $query = shift;
    my $ret   = "";
    $ret .= "<a id=\"v_toggle\" href=\"\#\">[+-]</a>";
    $ret .= "<div id=\"vertical_slide\">";

    while ( my ( $typename, $typevalue ) = each(%RRTypevalue) ) {

        my @x = Lookup( $query, $typevalue );
        if ( defined(@x) ) {
            foreach $p (@x) {
                if ( $typename =~ m/CNAME/ ) {
                    $ret .= MakeLink($p) . "(" . $typename . ")";
                }
                else {
                    $ret .= $p . "(" . $typename . ")";
                }
                $ret .=
                    " first seen: "
                  . NiceDate( FirstSeen( $query, $p ) )
                  . " last seen: "
                  . NiceDate( LastSeen( $query, $p ) )
                  . " Hits: "
                  . OccTuple( $query, $p ) . "\n";

                #$ret .= " behind: " . join( ""  , LookupIP($p) ) . "\n";
                $ret .= "<br />";
                foreach $n ( LookupIP($p) ) {
                    $ret .= MakeLink($n);
                }
                $ret .= "<br /> <br />";
            }
        }

    }
    $ret .= "</div>";
    return $ret;
}

sub QueryJSON {
    my $query = shift;
    my $ret   = <<JSHEAD;
            var event_data = 
              {
              "dateTimeFormat": "iso8601",
              "events":[
JSHEAD
    while ( my ( $typename, $typevalue ) = each(%RRTypevalue) ) {
        my @x = Lookup( $query, $typevalue );

        if ( defined(@x) ) {
            foreach $p (@x) {
                $ret .= "\{\"start\": \""
                  . NiceDateISO( FirstSeen( $query, $p ) ) . "\",\n";
                $ret .= "\"end\": \""
                  . NiceDateISO( LastSeen( $query, $p ) ) . "\",\n";
                chomp($p);
                $ret .= "\"title\": \"" . $p . "(" . $typename . ")\",\n";
                $ret .= "\"description\": \"" . $p . "(" . $typename . ")\",\n";
                $ret .= "\"instant\": \"false\",\n";
                $ret .= "\},\n";
            }
        }

    }
    chop($ret);
    chop($ret);
    return $ret . "] };\n";
}

sub MakeLink {
    my $value = shift;
    my $ret   = "<a href=\"" . $burl . "" . $value . "\">$value</a> ";
    return $ret;
}

sub NiceDate {
    my $epochvalue = shift;

    return strftime( "%Y%m%d-%H:%M:%S", localtime($epochvalue) );

}

sub NiceDateISO {
    my $epochvalue = shift;
    my $format     = "yyyy-mm{on}-ddThh:mm:ss+00:00";
    return time_format( $format, $epochvalue );
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
    return -1;

    #return $r->get($key);
}

1;
