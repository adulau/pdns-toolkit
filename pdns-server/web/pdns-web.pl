#!/bin/env perl
#
# Minimal and Scalable Passive DNS - Web interface 
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


use Mojolicious::Lite;
use Mojolicious::Static;
use PDNSq;

# Documentation browser under "/perldoc" (this plugin requires Perl 5.10)
plugin 'pod_renderer';

get '/l/(.query)' => sub {
  my $self = shift;
  my $q = $self->param('query');
  my $ret = PDNS::Query::Query($q);
  my $json = PDNS::Query::QueryJSON($q);
  $self->render(template => 'index', q => $ret, query => $q, jq => $json);
};

post '/l' => sub {
  my $self = shift;
  my $q = $self->param('q');
  my $ret = PDNS::Query::Query($q);
  my $json = PDNS::Query::QueryJSON($q);
  $self->render(template => 'index', q => $ret, query => $q, jq => $json);
};

get '/js/(.query)' => sub {
  my $self = shift;
  my $q = $self->param('query');
  $self->render_static('static/'.$q);
};

get '/__history__.html' => sub {
  my $self = shift;
  $self->render_static('static/__history__.html');
};

get '/' => sub {
  my $self = shift;
  $self->render(template => 'main');
};


app->secret('You have to change it');
app->start;
__DATA__

@@ main.html.ep
% layout 'default';
% title 'Passive DNS';
<h1>Passive DNS interface</h1>
<form name="lookup" action="/l/"i method=POST>
<input type="text" name="q" />
<input type="submit" value="lookup"/>
</form>

@@ index.html.ep
% layout 'default';
% title 'PDNS Lookup';
<h1>Passive DNS lookup result for <a href="/l/<%= $query %>"><%= $query %></a></h1>
<a href="#visual">(go to visual timeline)</a><br /><br />
<%== $q %>
<a name="visual">Visual timeline</a>
<div id="tl" class="timeline-default" style="height: 400px; border: 1px solid #aaa;"></div>


<noscript>
This page uses Javascript to show you a Timeline. Please enable Javascript in your browser to see the full page. Thank you.
</noscript>
<script>

            var tl;
            //in php you can get this 1so8601 date using date("c",$you_date_variable);
            var startProj = SimileAjax.DateTime.parseIso8601DateTime("2011-03-01T00:00:00");
            var endProj = SimileAjax.DateTime.parseIso8601DateTime("2011-12-30T00:00:00");

<%== $jq %>            

            function onLoad() {
                var tl_el = document.getElementById("tl");
                var eventSource = new Timeline.DefaultEventSource();
                var theme = Timeline.ClassicTheme.create();
                theme.autoWidth = true; // Set the Timeline's "width" automatically.
                theme.autoWidthMargin=10;
                theme.event.bubble.width = 220;
                theme.event.bubble.height = 120;

                theme.ether.backgroundColors = ["#E6E6E6","#F7F7F7"];

                theme.timeline_start = startProj;
                theme.timeline_stop  = endProj;

                theme.event.track.height = "20";
                theme.event.tape.height = 10; // px
                theme.event.track.height = theme.event.tape.height + 6;

                var d = SimileAjax.DateTime.parseIso8601DateTime("2011-03-01T00:00:00");
                var bandInfos = [

                    Timeline.createBandInfo({
                        layout:         'original',// original, overview, detailed
                        eventSource:    eventSource,
                        date:           d,
                        width:          350,
                        intervalUnit:   Timeline.DateTime.DAY,
                        intervalPixels: 100,
                        //trackHeight: 10,
                        theme :theme

                    }),
                    Timeline.createBandInfo({
                        layout:         'overview',
                        date:           d,
                        trackHeight:    0.5,
                        trackGap:       0.2,
                        eventSource:    eventSource,
                        width:          50,
                        intervalUnit:   Timeline.DateTime.MONTH,
                        //    showEventText:  false,
                        intervalPixels: 200,
                        theme :theme
                    })

                ];

                bandInfos[1].highlight = true;
                bandInfos[1].syncWith = 0;



                bandInfos[1].decorators = [
                    new Timeline.SpanHighlightDecorator({
                       // startDate:  startProj,
                       // endDate:    endProj,
                        inFront:    false,
                        color:      "#FFC080",
                        opacity:    30,
                        startLabel: "Begin",
                        endLabel:   "End",
                        theme:      theme
                    })
                ];


                tl = Timeline.create(tl_el, bandInfos, Timeline.HORIZONTAL);
                // show loading message
                tl.showLoadingMessage();

                eventSource.loadJSON(event_data, document.location.href);

                // dismiss loading message
                tl.hideLoadingMessage();

                // setup highlight filters
                //setupFilterHighlightControls(document.getElementById("controls"), tl, [0,1], theme);

            }
            //function centerProjStart() {
            //    tl.getBand(1).setCenterVisibleDate(startProj);
            //}
            
            //function centerProjEnd() {
            //    tl.getBand(1).setCenterVisibleDate(endProj);
           // }

            var resizeTimerID = null;
            function onResize() {
                if(resizeTimerID == null) {
                    resizeTimerID = window.setTimeout(function() {
                        resizeTimerID = null;
                        tl.layout();
                    }, 500);
                }
            }

</script>

@@ layouts/default.html.ep
<!doctype html><html>
  <head><title><%= title %></title>
  <link rel="stylesheet" type="text/css" href="http://www.circl.lu/css/styles.css">
  <link rel="stylesheet" type="text/css" href="/js/pdns.css">

  <link rel="shortcut icon" href="/favicon.ico" />
  <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />
  <script src="http://static.simile.mit.edu/timeline/api-2.3.0/timeline-api.js?bundle=true" type="text/javascript"></script>
  <script src="/js/mootools-core-1.3.1.js" type="text/javascript"></script> 
  <script src="/js/mootools-more-1.3.1.1.js" type="text/javascript"></script>
  <script src="/js/moo-pdns.js" type="text/javascript"></script>  
  </head>
  <body onload="onLoad();" onresize="onResize();">
  <div class="header" id="header">Passive DNS toolkit
  </div>
  <div class="body" id="body">
  <%= content =%></body>
  </div>
</html>
