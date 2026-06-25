<!-- #ZEROPS_EXTRACT_START:intro# -->
Run Operant for higher availability: a 3-node Postgres HA cluster and a control plane
scaled across multiple containers behind the load balancer. The OpenClaw gateway and
the sandbox Docker host stay single-node by design — the gateway owns OpenClaw's
session and cron state, and the Docker host is a fixed-resource VM — so this tier
hardens the data and dashboard layers, not chat ingress itself. Requires the Serious
project plan.
<!-- #ZEROPS_EXTRACT_END:intro# -->
