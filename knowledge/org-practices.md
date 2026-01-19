# Organization Cloud Practices

This document defines our company's mandatory security, cost, and operational practices for Azure resources. All resources must comply with these standards.

---

## Security Practices

### Network Security Groups (NSGs)

**Critical Requirements:**
- **Never allow SSH (port 22) from 0.0.0.0/0 or *** - All SSH access must be restricted to specific IP ranges or use Azure Bastion
- **Never allow RDP (port 3389) from 0.0.0.0/0 or *** - All RDP access must be restricted to corporate VPN IP ranges or use Azure Bastion
- **No unrestricted inbound rules** - Every inbound rule must have a specific source IP or CIDR range
- **Deny rules take priority** - Explicit deny rules should be in place for sensitive ports

**Remediation:**
- Replace `*` or `0.0.0.0/0` source with specific IP ranges
- Use Azure Bastion for administrative access
- Implement Just-In-Time (JIT) VM access

### Key Vault Secrets

**Critical Requirements:**
- **Secrets must not expire within 30 days** - All secrets should be rotated before they reach 30-day expiration window
- **Secrets expiring in 30-60 days** - Warning level, schedule rotation
- **No secrets without expiration dates** - All secrets must have an expiration date set
- **Enable soft delete and purge protection** - Required for all production Key Vaults

**Remediation:**
- Rotate secrets before expiration
- Implement automated secret rotation using Azure Automation or Key Vault auto-rotation
- Set expiration dates on all secrets (maximum 1 year)

### Private DNS Zones

**Critical Requirements:**
- **All Private DNS Zones must be linked to their associated VNet** - Unlinked zones break private endpoint resolution
- **Use auto-registration only when appropriate** - Avoid conflicts with multiple VNets

**Remediation:**
- Create VNet links for all Private DNS Zones
- Verify private endpoint connectivity after linking

### Storage Accounts

**Critical Requirements:**
- **Disable public blob access** - `allowBlobPublicAccess: false`
- **Disable shared key access** - Use Azure AD authentication only (`allowSharedKeyAccess: false`)
- **Require HTTPS** - `supportsHttpsTrafficOnly: true`
- **Minimum TLS 1.2** - `minimumTlsVersion: TLS1_2`
- **Enable soft delete for blobs** - Minimum 7 days retention

**Remediation:**
- Update storage account properties to meet requirements
- Migrate applications to use managed identity authentication

### App Service / Web Apps

**Critical Requirements:**
- **HTTPS only** - HTTP must redirect to HTTPS
- **Use managed identity** - No hardcoded credentials
- **Enable VNet integration for internal resources** - Apps accessing internal resources must use VNet integration
- **Minimum TLS 1.2** - For all HTTPS connections

---

## Cost Practices

### Tagging Requirements

**Mandatory Tags for ALL Resources:**
| Tag Name | Required | Description |
|----------|----------|-------------|
| `cost-center` | Yes | Finance cost center code (e.g., "engineering", "marketing") |
| `owner` | Yes | Team or individual responsible (e.g., "platform-team") |
| `environment` | Yes | dev, staging, prod |
| `project` | Recommended | Project or application name |

**Enforcement:**
- Resources missing `cost-center` or `owner` tags are flagged for remediation
- Untagged resources older than 7 days should be investigated for deletion

### Virtual Machines

**Right-sizing Requirements:**
- **CPU utilization < 5% for 14+ days** - VM is considered idle, evaluate for deletion or downsizing
- **CPU utilization < 20% average** - VM is underutilized, consider downsizing
- **Use appropriate VM series** - Don't use premium series (D-series) for dev/test workloads
- **Use Spot VMs for batch workloads** - When interruption is acceptable
- **Reserved Instances** - Commit to 1-year or 3-year reservations for stable production workloads

**Recommended Actions:**
- Idle VMs (< 5% CPU): Delete or stop
- Underutilized VMs (< 20% CPU): Downsize by one tier
- Batch workloads: Convert to Spot VMs

### Orphaned Resources

**Resources to Monitor:**
- **Unattached Managed Disks** - Disks not attached to any VM for 7+ days should be deleted or snapshotted
- **Unused Public IPs** - Public IPs not associated with any resource
- **Empty Resource Groups** - Resource groups with no resources
- **Stopped VMs** - VMs in deallocated state for 30+ days (still incur storage costs)
- **Unattached NICs** - Network interfaces not attached to VMs

**Remediation:**
- Review orphaned resources weekly
- Delete or archive unused resources
- Create snapshots before deleting disks if data may be needed

### Storage Optimization

**Requirements:**
- **Use appropriate access tiers** - Archive for rarely accessed, Cool for infrequent, Hot for frequent
- **Enable lifecycle management** - Auto-tier blobs based on access patterns
- **Delete old snapshots** - Snapshots older than 90 days should be reviewed

---

## Operational Practices

### Monitoring

**Required for All Production Resources:**
- Enable Azure Monitor diagnostics
- Configure alerts for critical metrics
- Send logs to Log Analytics workspace

### Backup

**Requirements:**
- All production VMs must have Azure Backup enabled
- Databases must have point-in-time restore configured
- Test restore procedures quarterly

---

## Compliance Summary

| Category | Requirement | Severity |
|----------|-------------|----------|
| NSG - Open SSH/RDP | No 0.0.0.0/0 source | 🔴 Critical |
| Key Vault - Expiring Secrets | > 30 days until expiration | 🔴 Critical |
| Private DNS - VNet Links | All zones linked | 🟡 Warning |
| Tagging - cost-center | Required on all resources | 🟡 Warning |
| Tagging - owner | Required on all resources | 🟡 Warning |
| VMs - Idle | < 5% CPU for 14 days | 🟡 Warning |
| Disks - Orphaned | Unattached > 7 days | 🟡 Warning |
| Storage - Public Access | Must be disabled | 🔴 Critical |

---

## Contact

For questions about these practices, contact the Platform Engineering team.
