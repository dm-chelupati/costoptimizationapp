# Cost Optimization Demo for SRE Agent

This demo deploys Azure resources with **intentional cost optimization opportunities** for SRE Agent to detect.

## What Gets Deployed

| Resource | Intentional Issue | SRE Agent Should Detect |
|----------|-------------------|------------------------|
| VM (D2s_v3) | Idle, no workload running | ⚠️ Underutilized - right-size or shutdown |
| VM (D4s_v3) | Idle, oversized | ⚠️ Underutilized - consider B-series |
| 2x Managed Disks | Not attached to any VM | ⚠️ Orphaned resources - wasted spend |
| 2x Storage Accounts | Missing cost-center/owner tags | ⚠️ Governance risk - unattributed costs |
| 1x Storage Account | No tags at all | ⚠️ Governance risk |

## Estimated Monthly Cost

| Resource | Size | Est. Cost/Month |
|----------|------|-----------------|
| VM 1 | D2s_v3 | ~$70 |
| VM 2 | D4s_v3 | ~$140 |
| Orphaned Disk 1 | 128GB Premium | ~$19 |
| Orphaned Disk 2 | 256GB Standard | ~$10 |
| Storage (3x) | Standard LRS | ~$3 |
| **Total waste potential** | | **~$240/month** |

## Deploy

```bash
cd cost-optimization-demo
azd auth login
azd init
azd up
```

**Note:** VMs will incur costs immediately. The idle CPU pattern will be visible in metrics after ~1 hour.

## Test with SRE Agent

After deployment (wait at least 1 hour for metrics), use this prompt:

```
Analyze my subscription for cost optimization opportunities. Find:
1. VMs with average CPU under 15% over the past 7 days
2. Unattached managed disks
3. Resources missing 'cost-center' or 'owner' tags

Calculate potential monthly savings for each finding.
```

**For immediate testing** (before CPU metrics accumulate):

```
Analyze my subscription for cost optimization opportunities. Find:
1. Unattached managed disks that aren't connected to any VM
2. Resources missing 'cost-center' or 'owner' tags
3. VMs that could be candidates for Reserved Instances

List each finding with estimated monthly cost impact.
```

## Expected Findings

SRE Agent should identify:
- 2 VMs with low/no utilization (after metrics accumulate)
- 2 orphaned managed disks (~$29/month waste)
- 3 resources missing required tags
- Potential RI savings for VMs running 24/7

## Clean Up

```bash
azd down --purge
```

**Important:** Clean up promptly to avoid unnecessary VM costs!
