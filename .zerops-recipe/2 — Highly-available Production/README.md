<!-- #ZEROPS_EXTRACT_START:intro# -->
Run Operant against a 3-node Postgres HA cluster for data durability, with the Operant
service on dedicated CPU. Note: the Operant service itself stays single-node by design —
its gateway process owns one Slack connection and OpenClaw's session/cron state, so it
can't be replicated. This tier hardens your data layer and gives the app more headroom;
it doesn't make the app itself redundant. Requires the Serious project plan.
<!-- #ZEROPS_EXTRACT_END:intro# -->
