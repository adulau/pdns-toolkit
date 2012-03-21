pdns-server toolkit
===================

A minimal and scalable toolkit for Passive DNS. The toolkit
can be used for research, security analysis or data mining.

The data store of the Passive DNS is relying on Redis.
The data store format is described in ./doc/datastore-format.txt 

Installation
------------

This is the minimal set to run a standalone passive-dns using dnscap
as a source for the DNS packets.

* Install [redis](http://www.redis.io/).
* Start ./src/redis-server
* Download [dnscap](https://www.dns-oarc.net/tools/dnscap)
* Apply the patch against dnscap to output date in epoch format
* copy the dnscap binary in ./pdns-server/bin
* Start the feeder cd pdns-server/bin; pdns-dnscap2feeder.sh;
* Now the feeder is capturing the DNS answers

* You can start the sample web interface cd pdns-server/web; pdns-web.sh
* or try a query on a hosname cd pdns-server/bin; perl query.pl www.google.com

The install process will be automated in the next release.

dnscap
------

Patch dnscap.c (from branches/wessels) to output the date in epoch format.

-               strftime(when, sizeof when, "%Y-%m-%d %T", tm);
+               strftime(when, sizeof when, "%s", tm);

When having multiple flows of DNS queries, it's better to convert the date
as soon as possible.
