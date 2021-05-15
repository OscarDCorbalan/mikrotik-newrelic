# mikrotik-newrelic

1. Create a New Relic account if not having one already.
1. Follow the steps under _Register an Insert API key_ in this documentatation:
   - https://docs.newrelic.com/docs/telemetry-data-platform/ingest-manage-data/ingest-apis/introduction-event-api/#register 
1. Login to your Mikrotik router:
   - Go to `System > Scripts`, click `Add New`.
     - Copy the content of [newrelic-metrics.rsc](src/newrelic-metrics.rsc) in the `Source` field.
     - Set the `Name` and `Policy` fields as described in that file.
     - Paste your API Key as the `nrApiKey` value.
     - There are two `metricsUrl` variables, one of them commented out. One is for the US region
       and the other one is for the Europe region. Use the one that matches the region of your
       NR account.
     - Click OK to save it.
   - Go to `System > Scheduler`, click `Add New`.
     - Set `Start Time` to `startup`.
     - Set the `Interval` to `00:00:15`, so that it runs and sends metrics every 15 seconds. You can always adjust it later to
       any value you prefer.
     - Click OK to save it.
   - Reboot your router -so that the `startup` hook is fired and the scheduler starts calling the script.
1. After the script has run and sent data at least once, you can check if New Relic is getting the data:
   - Open the Data Explorer ("Query your data" button at top navigation).
   - Make sure you are in the Metrics tab.
   - Use the input to filter by `mikrotik` (as all data is dumped with that string at the start)

## Debugging (not seeing data in New Relic)

If you can't see the data in the Data Explorer, try to:

1. In New Relic, go to Data Explorer => Events tab
   - Look for the NrIntegrationError table -if the API is receiving the POSTs and rejecting the data, you can see the reason there.
1. Run the script manually in your router console  
   - Login to the router's web GUI
   - Click Terminal at top right
   - Type `system script run newrelic-metrics` and press Enter.
   - It will run the script once -if there's a script error, or an HTTP error when sending the data, you can see it there.

## Contributions are welcome :)

Either posting in the Issues tab or Opening PRs are very welcome.

## Docs

- [New Relic's Metric API](https://docs.newrelic.com/docs/telemetry-data-platform/ingest-manage-data/ingest-apis/report-metrics-metric-api/)
- [New Relic's Entity Synthesis](https://github.com/newrelic-experimental/entity-synthesis-definitions)
- [Mikrotik scripting](https://wiki.mikrotik.com/wiki/Scripts)

