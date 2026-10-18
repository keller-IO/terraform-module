locals {
  nodes_map = { for n in var.nodes : n.name => n }

  # Effective datastore per node (per-node storage_id overrides vm_storage_id).
  node_storage_id = {
    for n in var.nodes : n.name => coalesce(n.storage_id, var.vm_storage_id)
  }

  # Datastore of the cloud-init drive (per-node cloudinit_storage_id, else the
  # node's effective storage_id). Changing it on an existing VM makes the
  # provider power the VM off to move the drive, so it can be pinned separately.
  node_cloudinit_storage_id = {
    for n in var.nodes : n.name => coalesce(n.cloudinit_storage_id, local.node_storage_id[n.name])
  }

  # Effective Longhorn disk size per node (0 / null => no Longhorn disk).
  node_longhorn_gb = {
    for n in var.nodes : n.name => (
      n.longhorn_disk_gb != null ? n.longhorn_disk_gb : var.default_longhorn_disk_gb
    )
  }

  # ISO is downloaded once to shared storage; pick a stable host (lowest node name).
  names_sorted      = sort(keys(local.nodes_map))
  iso_download_node = local.nodes_map[local.names_sorted[0]].target_pve
}
