# dump_amass.sh - author: alhazred 2024

Dumps actually useful information from amass enum sqlite file

# Requirements

sqlite3 >= 3.45.0

# Usage

```
dump_amass.sh [-a] [-d SUFFIX] [-i] | [-e] [-4] | [-6] <amass.sqlite>

  -d SUFFIX    only show domains ending with SUFFIX
  -a           only show matches with an A record
  -i           internal, only show domains that resolve to a private IP range (implies -a)
  -e           external, only show domains that are internet routable (implies -a)
  -4           only show IPv4 addresses (implies -a)
  -6           only show IPv6 addresses (implies -a)
  -h           show this help
<amass.sqlite> amass sqlite file
```



