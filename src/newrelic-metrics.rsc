################################################################################
# Name: newrelic-metrics                                                       #
# Policy: Ftp, Read, Write, Policy, Test                                       #
# Comment: Send metric data to New Relic                                       #
################################################################################

##### START CONFIG ##############################################

# Retrieve your New Relic API key -see README.
:local NRAPIKEY "NRII-Abc123"

# Use the commented-out URL if your NR region is set to US instead of Europe
# :local METRICSURL "https://metric-api.newrelic.com/metric/v1"
:local METRICSURL "https://metric-api.eu.newrelic.com/metric/v1"

# These are attached as tags to the entity created in NR for the router
:local attributes {
    "instrumentation.provider"="mikrotik-router";
    "instrumentation.version"="1.1.0";
    "mikrotik.name"=[/system identity get name];
    "mikrotik.boardname"=[/system resource get board-name];
    "mikrotik.serialnumber"=[/system routerboard get serial-number]
    "mikrotik.model"=[/system routerboard get model];
    "mikrotik.currentfirmware"=[/system routerboard get current-firmware];
    "mikrotik.upgradefirmware"=[/system routerboard get upgrade-firmware];
}

# These are metrics of the entity created in NR -can be charted, used for alerting, etc
:local observedMetrics {
    "mikrotik.system.cpu.load"=[/system resource get cpu-load];
    "mikrotik.system.memory.total"=[/system resource get total-memory];
    "mikrotik.system.memory.free"=[/system resource get free-memory];
    "mikrotik.system.memory.load"=100 - (100 * [/system resource get free-memory] / [/system resource get total-memory])
    "mikrotik.ip.pool.used"=[/ip pool used print count-only];
    "mikrotik.ip.dns.cache.size"=[/ip dns get cache-size];
    "mikrotik.ip.dns.cache.used"=[/ip dns get cache-used];
    "mikrotik.ip.dhcpserver.leases"=[/ip dhcp-server lease print active count-only];
    "mikrotik.firewall.connection.tcp"=[/ip firewall connection print count-only where protocol=tcp];
    "mikrotik.firewall.connection.udp"=[/ip firewall connection print count-only where protocol=udp];
    "mikrotik.firewall.connection.established"=[/ip firewall connection print count-only where tcp-state=established];
};

# Loop all interfaces to add their throughputs to "observedMetrics"
{
    :foreach i in=[/interface find] do={
        /interface monitor [/interface find where .id="$i"] once do={
            :set ($observedMetrics->("mikrotik.interface." . $"name" . ".txbps")) $"tx-bits-per-second";
            :set ($observedMetrics->("mikrotik.interface." . $"name" . ".rxbps")) $"rx-bits-per-second";
            :set ($observedMetrics->("mikrotik.interface." . $"name" . ".fptxbps")) $"fp-tx-bits-per-second";
            :set ($observedMetrics->("mikrotik.interface." . $"name" . ".fprxbps")) $"fp-rx-bits-per-second";
            :set ($observedMetrics->("mikrotik.interface." . $"name" . ".txerrorsps")) $"tx-errors-per-second";
            :set ($observedMetrics->("mikrotik.interface." . $"name" . ".rxerrorsps")) $"rx-errors-per-second";
        };
    }
}

##### END CONFIG ################################################


##### START HELPER METHODS ######################################

# Calculates a millisecond-based timestamp value
# @returns Timestamp value
:local getTimestamp do={
   :local ds [/system clock get date];
   :local months;
   :if ((([:pick $ds 9 11]-1)/4) != (([:pick $ds 9 11])/4)) do={
      :set months {"an"=0;"eb"=31;"ar"=60;"pr"=91;"ay"=121;"un"=152;"ul"=182;"ug"=213;"ep"=244;"ct"=274;"ov"=305;"ec"=335};
   } else={
      :set months {"an"=0;"eb"=31;"ar"=59;"pr"=90;"ay"=120;"un"=151;"ul"=181;"ug"=212;"ep"=243;"ct"=273;"ov"=304;"ec"=334};
   }
   :set ds (([:pick $ds 9 11]*365)+(([:pick $ds 9 11]-1)/4)+($months->[:pick $ds 1 3])+[:pick $ds 4 6]);
   :local ts [/system clock get time];
   :set ts (([:pick $ts 0 2]*60*60)+([:pick $ts 3 5]*60)+[:pick $ts 6 8]);
   :return ($ds*24*60*60 + $ts + 946684800 - [/system clock get gmt-offset]);
};

# Searializes a metrics object to NR metrics json format
# @param {object} metrics
# @param {number} timestamp
# @returns {string} Json string representing a New Relic-formatted metric
:local nrMetricsToJson do={

  :local ret ("[{\"common\":{$common},\"metrics\":[")
  :local firstIteration true

  :foreach k,metric in $metrics do={
    if (!$firstIteration) do={
      :set $ret ($ret . ",")
    };
    :set $firstIteration false

    # parse each metric array
    :set ret ($ret . "{")
    :local isFirstMetricInArray true

    :foreach k,v in $metric do={
      if ($isFirstMetricInArray) do={
        :set $ret ($ret . "\"".$k . "\":")
      } else={
        :set $ret ($ret . "," . "\"". $k . "\":")
      };
      :set $isFirstMetricInArray false

      :if ([:typeof $v] = "str") do={
          :set $ret ($ret . "\"" . $v . "\"")
      } else {
          :set $ret ($ret . $v )
      };
    };

    :set $ret ($ret . "}")
  };

  :set $ret ($ret . "]}]")
  :return $ret;
};

:local toAttributesJson do= {
    :local ret ""
    :foreach k,v in=$attributes do={
        :set $ret ($ret . "\"" . $k . "\":\"" . $v . "\"" . ",");
    }
    :set $ret [:pick $ret 0 ([:len $ret] - 1)]
    :return "\"attributes\":{$ret}";
}

:local toMetric do={
    :ret {"name"=$name; "value"=$value; "type"="gauge"};
}

##### END HELPER METHODS ########################################


##### START ACTUAL PROCESSING ###################################

:set $attributes [$toAttributesJson attributes=$attributes]
:set $common ("$attributes,\"timestamp\":$[$getTimestamp]")

:local metricsArray [:toarray ""];
:foreach k,v in=$observedMetrics do={
    :local metric [$toMetric name=$k value=$v];
    :set $metricsArray ($metricsArray , {$metric});
}

:local httpData [$nrMetricsToJson metrics=$metricsArray common=$common];

/tool fetch http-method=post output=none http-header-field="Content-Type:application/json,Api-Key:$NRAPIKEY" http-data=$httpData url=$METRICSURL

##### END ACTUAL PROCESSING #####################################
