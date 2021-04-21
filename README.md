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
  - Go to `System > Scripts`, click `Add New`.
    - Set `Start Time` to `startup`.
    - Set the `Interval` to `00:00:15`, so that it runs and sends metrics every 15 seconds. You can always adjust it later to
      any value you prefer.
    - Click OK to save it.

## Contributions are welcome :)

Either posting in the Issues tab or Opening PRs are very welcome.

## Docs

- [New Relic's Metric API](https://docs.newrelic.com/docs/telemetry-data-platform/ingest-manage-data/ingest-apis/report-metrics-metric-api/)
- [Mikrotik scripting](https://wiki.mikrotik.com/wiki/Scripts)
