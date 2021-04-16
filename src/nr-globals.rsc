################################################################################
# Name: nr-globals                                                             #
# Policy: Read, Write, Policy, Test                                            #
# Comment: Exports global functions and ENV vars used by nr-agent.rsc          #
################################################################################

# Sets new relic global api key as a global variable
:global NR_API_KEY "Abc123"  # Get from ... TODO


# Usage, import the global function and call it where timestamp is needed:
#   :global getTimestmap;
#   :local timestamp [$getTimestamp];
# Returns:
#   timestamp value
:global getTimestamp do={
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

# searialize metrics object to NR metrics format
# Params
#   metrics
#   timestamp
# Returns
#   String json representing a NR metric
:global nrMetricsToJson do={
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