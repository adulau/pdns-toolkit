#
# Minimal and Scalable Passive DNS - ranking records
#
# Copyright (C) 2012 Alexandre Dulaunoy
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
#
# Sample input (pdns-ranking.py) read line with the Passive DNS format:
# s:truecsi.org:ns3.afraid.org. = 1327737190
#
# and output the following:
# truecsi.org
# [(1.0003765060241001, 'truecsi.org')]
# truecsi.org,1.00037650602
#
# and update the DB 6 database
# redis> select 6
# OK
# redis> KEYS "*"
# 1) "truecsi.org"
# redis> GET "truecsi.org"
# "1.00037650602"
# redis>


import sys
import re
import redis

path = "../lib/DomainClassifier/DomainClassifier/"
sys.path.append(path)

import domainclassifier


def domexist(ldomain = None):
   print ldomain
   r = redis.StrictRedis(host='localhost', port=6379, db=6)

   if ldomain is not None:
	if r.exists(ldomain):
            return True
        else:
            return False
   else:
       return False

def domstore(ldomain = None, rank = 1.0):
   r =  redis.StrictRedis(host='localhost', port=6379, db=6)
   return r.set(ldomain,rank)

for line in sys.stdin:
	domain = line.split(':')[1].lower()
        if not (re.search("(spamhaus.org|arpa)$", domain)):
            if not domexist(ldomain=domain):
                c = domainclassifier.Extract(domain)
                c.domain()
                c.validdomain()
                r = c.rankdomain()
                if r:
                    r.sort(reverse=True)
                    ranking = r[0][0]
                    print r
                    if ranking is not None:
                        print domain+","+str(ranking)
                        domstore(ldomain=domain, rank=ranking)
                    else:
                        print domain+","+str(1)
                        domstore(ldomain=domain)
                else:
                    print domain+","+str(1)
                    domstore(ldomain=domain)
            else:
                print domain+" already cached"
