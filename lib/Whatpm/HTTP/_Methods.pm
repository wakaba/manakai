$Whatpm::HTTP::_Methods::VERSION = 20131103;
$Whatpm::HTTP::Methods = {
          'ACL' => {},
          'BASELINE-CONTROL' => {},
          'BCOPY' => {},
          'BDELETE' => {},
          'BIND' => {},
          'BMOVE' => {},
          'BPROPFIND' => {},
          'BPROPPATCH' => {},
          'BROWSE' => {},
          'CHECKIN' => {},
          'CHECKOUT' => {},
          'CONNECT' => {
                         'case_insensitive' => 1,
                         'xhr_unsafe' => 1
                       },
          'COPY' => {},
          'DELETE' => {
                        'case_insensitive' => 1,
                        'idempotent' => 1
                      },
          'GET' => {
                     'case_insensitive' => 1,
                     'idempotent' => 1,
                     'safe' => 1,
                     'simple' => 1
                   },
          'HEAD' => {
                      'case_insensitive' => 1,
                      'idempotent' => 1,
                      'safe' => 1,
                      'simple' => 1
                    },
          'LABEL' => {},
          'LINK' => {},
          'LOCK' => {},
          'M-GET' => {},
          'M-POST' => {},
          'M-PUT' => {},
          'MDELETE' => {},
          'MERGE' => {},
          'MGET' => {},
          'MKACTIVITY' => {},
          'MKCALENDAR' => {},
          'MKCOL' => {},
          'MKREDIRECTREF' => {},
          'MKWORKSPACE' => {},
          'MOVE' => {},
          'MPUT' => {},
          'NOTIFY' => {},
          'OPTIONS' => {
                         'case_insensitive' => 1,
                         'idempotent' => 1
                       },
          'ORDERPATCH' => {},
          'PATCH' => {},
          'PEP' => {},
          'PEP-PUT' => {},
          'POLL' => {},
          'POST' => {
                      'case_insensitive' => 1,
                      'simple' => 1
                    },
          'PROPFIND' => {},
          'PROPPATCH' => {},
          'PUT' => {
                     'case_insensitive' => 1,
                     'idempotent' => 1
                   },
          'REBIND' => {},
          'REPORT' => {},
          'RPC_IN_DATA' => {},
          'RPC_OUT_DATA' => {},
          'SEARCH' => {},
          'SHOWMETHOD' => {},
          'SPACEJUMP' => {},
          'SUBSCRIBE' => {},
          'Secure' => {},
          'TEXTSEARCH' => {},
          'TRACE' => {
                       'case_insensitive' => 1,
                       'idempotent' => 1,
                       'xhr_unsafe' => 1
                     },
          'TRACK' => {
                       'case_insensitive' => 1,
                       'xhr_unsafe' => 1
                     },
          'UNBIND' => {},
          'UNCHECKOUT' => {},
          'UNLINK' => {},
          'UNLOCK' => {},
          'UNSUBSCRIBE' => {},
          'UPDATE' => {},
          'UPDATEREDIRECTREF' => {},
          'VERSION-CONTROL' => {},
          'X-MS-ENUMATTS' => {}
        };
