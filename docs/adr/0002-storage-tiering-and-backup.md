# 2. Storage tiering and backup: local NVMe for state, NFS for bulk, Kopia for backup

- Status: accepted
- Date: 2026-10-02

## Context

Until now every application PVC lived on the Synology NAS over NFS
(`nfs-csi-sc`, the default StorageClass), and "backup" meant the NAS's own
snapshots plus a nightly `pg_dump` CronJob for CloudNativePG. This was simple
and it worked, but it has structural weaknesses that became clear once the
cluster hosted real household data (documents, finances, home automation):

- **SQLite over NFS.** Paperless, Home Assistant, Actual, Mealie, Jellyseerr,
  the \*arr suite and Forgejo all keep state in SQLite. NFS file locking is
  notoriously unreliable for SQLite; a NAS hiccup can corrupt a database that
  otherwise looks healthy.
- **Live data and backup on the same device.** The PVC *and* its backup were
  both on the Synology. A RAID failure, a bad firmware update or ransomware on
  the NAS takes both. That is one copy on one medium, not a backup.
- **Workarounds already in production.** `csi-driver-nfs` runs with
  `fsGroupPolicy` disabled because kubelet's recursive chown breaks over NFS.
  That is a symptom of putting application state on a network filesystem.
- **No restore path in Git.** Restoring an app meant clicking through Synology
  snapshot UIs. Nothing was declarative, nothing was tested.
- **Latency.** The node has fast NVMe and a GPU; making PostgreSQL and the
  Prometheus TSDB wait on NFS wastes that.

The reference repos this lab aligns with (bjw-s-labs/home-ops,
onedr0p/home-ops) both run the same two-tier model: block storage for
application state, NFS only for bulk/shared data, and a Kopia-based operator
(**kopiur**, from home-operations) for backups with an on-site repository and
an off-site replica.

Alternatives considered:

- **Keep everything on NFS, add kopiur on top.** Fixes the backup story but
  not SQLite-over-NFS or the fsGroup workaround, and the primary data would
  still sit on the same box as its backup.
- **Replicated block storage (Rook-Ceph, miroir).** What the multi-node
  reference clusters use. Pointless on a single node; adds operational weight
  for no durability gain.
- **VolSync + restic.** The previous community standard. kopiur is its
  successor from the same maintainers, is Kopia-native (dedup, maintenance,
  replication built in) and is what both reference repos moved to.
- **Backblaze B2 as the off-site target.** Cheapest per GB (~€1/month at our
  size). Rejected in favour of Hetzner Object Storage because the edge VPS
  (ADR-0003) is at Hetzner too and the maintainer wants one bill; the ~€4/month
  premium buys 1 TB of headroom and a single vendor relationship.

## Decision

1. **Default StorageClass becomes OpenEBS hostpath (local NVMe).** A PVC goes
   on `nfs-csi-sc` only if the data is (a) shared outside the pod (e.g. a drop
   folder also written from a laptop), (b) too large to reasonably back up
   (media libraries, download buffers), or (c) needs RWX. **Application state
   is never on NFS.**
2. **Backups are kopiur.** One `ClusterRepository` on the Synology over NFS
   (Kopia `filesystem` backend) is the primary, fast-restore repository. A
   `RepositoryReplication` mirrors it on a schedule to an S3 bucket on
   **Hetzner Object Storage** (off-site). Apps opt in via a shared
   `kubernetes/components/kopiur` component so a `SnapshotPolicy` +
   `SnapshotSchedule` is one line per app.
3. **Migration is app-by-app**, starting with Paperless as the pilot
   (small, SQLite, already exported), each migration ending in a tested
   restore. Only when the last stateful PVC has moved does `nfs-csi-sc` lose
   its default annotation. The NFS CSI driver itself stays.
4. The CNPG nightly dump CronJob is retained until it is replaced by a kopiur
   `SnapshotPolicy` with a `pg_dump` pre-hook, so PostgreSQL ends up under the
   same retention policy as everything else.

## Consequences

**Positive**

- Two real copies on two media (NVMe → NAS), plus a third off-site; a proper
  3-2-1 without any manual steps.
- SQLite databases are on a local filesystem; the fsGroup workaround becomes
  irrelevant for state volumes.
- Restore is a Kubernetes object (`Restore` CR), reviewable in Git and
  testable; a full app rebuild is "apply the ks, wait for the restore".
- Matches the reference repos one-to-one, so their components and docs apply
  directly.

**Negative / trade-offs**

- Local NVMe is a single disk. The durability argument rests entirely on the
  backup cadence: a disk failure loses everything since the last snapshot.
  Daily snapshots (hourly for the few apps where it matters) are the
  mitigation; this is the same trade every single-node lab makes.
- Node storage is finite (1 TB shared with the OS). Media and anything bulky
  must stay on NFS; the StorageClass rule above has to be applied honestly.
- Migration work: ~25 PVCs, each with a short downtime.
- Hetzner Object Storage has a €4.99/month floor; B2 would be cheaper at
  current volume. Accepted for the single-vendor benefit.

**Neutral**

- The Synology's own backups continue to protect what legitimately stays on
  NFS (media, drop folders) and the kopiur repository itself.

## Notes

Reversing the StorageClass default is trivial; moving data back is not. The
decision is treated as hard-to-reverse because of the data migration, not the
configuration. Revisit if the node ever grows to 3+ nodes (replicated block
storage becomes worth it) or if Hetzner Object Storage pricing/reliability
disappoints (swap the replication target; the primary repository is
unaffected).
