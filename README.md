# mikrotik-newrelic

1. Create a New Relic account if not having one already.
1. Follow the steps under _Register an Insert API key_ in this documentatation:
  - https://docs.newrelic.com/docs/telemetry-data-platform/ingest-manage-data/ingest-apis/introduction-event-api/#register
1. Login to your Mikrotik router:
  - Go to `System > Scripts`, click `Add New`.
    - Copy the content of [newrelic-metrics.rsc](src/newrelic-metrics.rsc) in the `Source` field.
    - Set the `Name` and `Policy` fields as described in that file.
  - Go to `System > Scripts`, click `Add New`.
    - Set `Start time = startup`
    - Set interval to 00:00:15


## Docs

Report metrics via the Metric API: https://docs.newrelic.com/docs/telemetry-data-platform/ingest-manage-data/ingest-apis/report-metrics-metric-api/
