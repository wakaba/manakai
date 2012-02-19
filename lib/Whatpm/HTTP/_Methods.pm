$Whatpm::HTTP::_Methods::VERSION = 20120219;
$Whatpm::HTTP::Methods = {
          'ACL' => {},
          'BASELINE-CONTROL' => {},
          'BCOPY' => {},
          'BDELETE' => {},
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
                     'safe' => 1
                   },
          'HEAD' => {
                      'case_insensitive' => 1,
                      'idempotent' => 1,
                      'safe' => 1
                    },
          'LABEL' => {},
          'LOCK' => {},
          'MERGE' => {},
          'MKACTIVITY' => {},
          'MKCALENDAR' => {},
          'MKCOL' => {},
          'MKWORKSPACE' => {},
          'MOVE' => {},
          'NOTIFY' => {},
          'OPTIONS' => {
                         'case_insensitive' => 1,
                         'idempotent' => 1
                       },
          'ORDERPATCH' => {},
          'PEP' => {},
          'PEP-PUT' => {},
          'POLL' => {},
          'POST' => {
                      'case_insensitive' => 1
                    },
          'PROPFIND' => {},
          'PROPPATCH' => {},
          'PUT' => {
                     'case_insensitive' => 1,
                     'idempotent' => 1
                   },
          'REPORT' => {},
          'RPC_IN_DATA' => {},
          'RPC_OUT_DATA' => {},
          'SEARCH' => {},
          'SUBSCRIBE' => {},
          'TRACE' => {
                       'case_insensitive' => 1,
                       'idempotent' => 1,
                       'xhr_unsafe' => 1
                     },
          'TRACK' => {
                       'case_insensitive' => 1,
                       'xhr_unsafe' => 1
                     },
          'UNCHECKOUT' => {},
          'UNLOCK' => {},
          'UNSUBSCRIBE' => {},
          'UPDATE' => {},
          'VERSION-CONTROL' => {},
          'X-MS-ENUMATTS' => {}
        };
