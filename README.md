# rpki-rtr-client

## Introduction

A simple client-side implementation of the RPKI-RTR [IETF RFC
8210](https://tools.ietf.org/html/rfc8210) protocol in Python.  See
[Cloudflare's blogs on RPKI](https://blog.cloudflare.com/tag/rpki/) for
more open source RPKI code.

## Installation

Presently the code is easiest to install using pip:

```
$ pip3 install rpki-rtr-client
$ rtr_client
```

Alternatively, build and install from this repo's source:

```
python3 setup.py build
python3 setup.py install
```

The [pytricia](https://pypi.org/project/pytricia/) package is used
for storing maintaining a ROA-based routing table.

## Usage

Cloudflare provides an open RTR server at `rtr.rpki.cloudflare.com` port
`8282` based on Cloudflare's
[GoRTR](https://github.com/cloudflare/gortr) open source RTR server.

Usage is via the `--help` argument.

```
$ rtr_client --help
usage: rtr_client [-H|--help] [-V|--version] [-v|--verbose] [-h HOSTNAME|--host=HOSTNAME] [-p PORTNUMBER|--port=PORTNUMBER] [-s SERIALNUMBER|--serial=SERIALNUMBER] [-S SESSIONID|--session=SESSIONID] [-t SECONDS|--timeout=SECONDS] [-d|--dump]
```

The Cloudflare open RTR server default hostname and port are compiled
into the source code. You can specify your own host and port via the
command line `-h|--host` and `-p|--port` arguments.

```
$ rtr_client --host rtr.rpki.cloudflare.com --port 8282
 ...
^C
$
```

A modicum of debug information is available to show the serial number
and the progress of accepting announce/widthdraw valid ROAs. The code
will always show the progress of serial numbers plus the number of valid
ROAs associated with that serial number.

```
DUMP ROUTES: serial=133 announce=130401/withdraw=0
NEW SERIAL 0->133
```

As the protocol continues to sync, the messages show progress on the
routing list.

```
DUMP ROUTES: serial=381 announce=18/withdraw=2
NEW SERIAL 380->381
```

The `.` debug messages simply mean that PDUs have been transfered
between RTR server and RTR client.

## Data Files

There is a data directory created with JSON files of every serial
number's worth of ROA data. The directory is sorted by `YYYY-MM` and the
files include the full date (in UTC).

```
$ ls -lt data/
total 0
drwxr-xr-x  7 martin martin  224 Feb 11 09:36 2020-02
$

$ ls -lt data/2020-02
total 21592
-rw-r--r--  1 martin martin  5520676 Feb 16 18:22 2020-02-17-022209.routes.00000365.json
-rw-r--r--  1 martin martin  5520676 Feb 16 18:42 2020-02-17-024242.routes.00000838.json
-rw-r--r--  1 martin martin      412 Feb 16 19:56 2020-02-17-035645.routes.00000841.json
-rw-r--r--  1 martin martin      272 Feb 16 20:16 2020-02-17-041647.routes.00000842.json
-rw-r--r--  1 martin martin      643 Feb 16 20:36 2020-02-17-043649.routes.00000843.json
$
```

You can review those files for how many RTR announce/withdraw ROAs were
processed.

```
$ for f in data/2020-02/*.json ; do echo "$f `jq -r '.routes.announce[]|.ip' < $f | wc -l` `jq -r '.routes.withdraw[]|.ip' < $f | wc -l`" ; done
data/2020-02/2020-02-17-022209.routes.00000365.json   128483        0
data/2020-02/2020-02-17-024242.routes.00000838.json   128483        0
data/2020-02/2020-02-17-035645.routes.00000841.json        3        6
data/2020-02/2020-02-17-041647.routes.00000842.json        5        0
data/2020-02/2020-02-17-043649.routes.00000843.json        9        5
$
```

You can list the ROAs. A `null` means that no MaxLen has been specified
in the ROA.

```
$ jq -r '.routes.announce[]|.ip,.asn,.maxlen' data/2020-02/*0838.json | paste - - - | sort -V | head
1.0.0.0/24      13335   null
1.1.1.0/24      13335   null
1.9.0.0/16      4788    24
1.9.12.0/24     65037   null
1.9.21.0/24     24514   null
1.9.23.0/24     65120   null
1.9.31.0/24     65077   null
1.9.65.0/24     24514   null
1.34.0.0/15     3462    24
1.36.0.0/16     4760    null
$
```

Additionally, the full list of valid ROAs is dumped into
`data/routingtable.json` which can be used by the `show` command:

```
$ rtr_client/rtr_show.py 1.37.0.0/16 112.198.0.0/16
ROUTE            ROA              MaxLen ASN
1.37.0.0/16      1.37.0.0/16         /17 AS4775
ROUTE            ROA              MaxLen ASN
112.198.0.0/16   112.198.0.0/16      /24 AS4775
$
```

The `-l` argument will show add more specific ROAs.

The code can also dump the raw binary protocol and then replay that data
to debug the protocol with the `-d|--dump` argument. This generates a
`data/__________-raw-data.bin` file. The `file_process.py` command will
process that file.

## TODO

- (-v) required for syslog, fix that
- tune logging output generally
- find and fix the dupe routing table entry bug
- daemonize
- look at fine tuning TCP session handling (see jtk's favheaders.py)

## Changelog

2021-11-16
- use tempfile for atomic overwrite of data/routingtable.json

2021-11-10
- convert README to markdown with minor doc updates
- remove she-bang from setup.py
- add host and port parameters in calls to rfc8210router()
- rename logger name from RFC8210 to rpki-rtr-client
- add announce/withdraw detail logging to rtr_protocol()
- add basic syslog handling
- add contrib/rp-mon.sh until rtr_client is daemonized

v1.20
- This is the first release and while it works, it is not ready for
  prime time
- Directory format updated to split by YYYY-MM in case it gets big
  (plus the serial number may not be sequential)
- Moved from 3rd party ``netaddr`` package to Python's ``ipaddress``
  data type
- All internal cidr's are stored as ``ipaddress`` types and JSON
  processing now handles that type correctly
- Added valid route table and show command
- Renamed show.py to rtr\_show.py
- moved code to rtr\_client folder
- Added -V/--version flags
- Added support for tracking session\_id's
- Fixed route dump duplication after session restart
- First pass at pypi packaging
- Cleaned up route processing
- Timestamp added to major debug messages
- Connect class does all the socket processing now - just cleaner that
  way

## License

Licensed under the BSD 3 License. See the [LICENSE.txt](LICENSE.txt)
file.
