################################################################################
# Name: newrelic-metrics                                                       #
# Policy: Ftp, Read, Write, Policy, Test                                       #
# Comment: Send metric data to New Relic                                       #
################################################################################

##### START CONFIG ##############################################

# Retrieve your New Relic API key -see README.
:local nrApiKey "NRII-Abc123"

# Use the commented-out URL if you set your NR region in US instead of Europe
# :local metricsUrl "https://metric-api.newrelic.com/metric/v1"
:local metricsUrl "https://metric-api.eu.newrelic.com/metric/v1"

:local observedMetrics {
# Required by New Relic to Synthesize the metrics as a Mikrotik router
# Do not delete these metrics
    "mikrotik_system_cpu_load"=[/system resource get cpu-load];
    "mikrotik_system_memory_total"=[/system resource get total-memory];
    "mikrotik_system_memory_free"=[/system resource get free-memory];
    "mikrotik_ip_pool_used"=[/ip pool used print count-only];

# Optional metrics, remove them or add more in this sction:
    "mikrotik_ip_dns_cache_size"=[/ip dns get cache-size];
    "mikrotik_ip_dns_cache_used"=[/ip dns get cache-used];
    "mikrotik_ip_dhcpserver_leases"=[/ip dhcp-server lease print active count-only];
    "mikrotik_firewall_connection_tcp"=[/ip firewall connection print count-only where protocol=tcp];
    "mikrotik_firewall_connection_udp"=[/ip firewall connection print count-only where protocol=udp];
    "mikrotik_firewall_connection_established"=[/ip firewall connection print count-only where tcp-state=established];
};

# More optional metrics, to send throughputs of each interface:
{
    :foreach i in=[/interface find] do={
        /interface monitor [/interface find where .id="$i"] once do={
            :set ($observedMetrics->("mikrotik_interface_" . $"name" . "_txbps")) $"tx-bits-per-second";
            :set ($observedMetrics->("mikrotik_interface_" . $"name" . "_rxbps")) $"rx-bits-per-second";
            :set ($observedMetrics->("mikrotik_interface_" . $"name" . "_fptxbps")) $"fp-tx-bits-per-second";
            :set ($observedMetrics->("mikrotik_interface_" . $"name" . "_fprxbps")) $"fp-rx-bits-per-second";
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
      :set months {"an"=0;"eb"=31;"ar"=59;"pr"=90;"ay"=120;"un"=151;"ul"=181;"ug"=212;"ep"=243;"ct"=273;"ov"=304;"dec"=334};
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
  :local ret ("[{\"common\":{\"timestamp\":" . $timestamp . "},\"metrics\":[")
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

:local toMetric do={
    :ret {"name"=$name; "value"=$value; "type"="gauge"};
}

##### END HELPER METHODS ########################################


##### START PROCESSING observedMetrics ##########################

:local timestamp [$getTimestamp];

:local metricsArray [:toarray ""];
:foreach k,v in=$observedMetrics do={
    :local metric [$toMetric name=$k value=$v];
    :set $metricsArray ($metricsArray , {$metric});
}

:local httpData [$nrMetricsToJson metrics=$metricsArray timestamp=$timestamp];

/tool fetch http-method=post output=none http-header-field="Content-Type:application/json,Api-Key:$nrApiKey" http-data=$httpData url="https://metric-api.eu.newrelic.com/metric/v1"

##### END PROCESSING observedMetrics ############################
