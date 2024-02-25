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
    "instrumentation.version"="1.2.0";
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
    "mikrotik.ip"=[/ip address get [find interface="ether1"] address];
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
  :return (1000 * [:tonum [:timestamp]])
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
    :return {"name"=$name; "value"=$value; "type"="gauge"};
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
