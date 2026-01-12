$VCFVMS = Get-VM -Tag "vcf-main"

# Create snapshots for all NSX/AVI related VMs and Config
ForEach ($vm in $VCFVMS) { Get-VM -Name $vm.Name | New-Snapshot -Name "Before AVI Setup Snap" -Memory -Quiesce -Description "Snapshot before AVI config." }

<# ----- Official List based on tags: --------------
Name                 PowerState Num CPUs MemoryGB
----                 ---------- -------- --------
sddcm01              PoweredOn  4        16.000
vc01                 PoweredOn  2        14.000
nsx01a               PoweredOn  6        24.000
opsfm01              PoweredOn  4        12.000
vcf01                PoweredOn  4        16.000
avilb-node0          PoweredOn  6        32.000
#>

# List Snapshots
ForEach ($vm in $VCFVMS) { Get-VM -Name $vm.Name | Get-Snapshot }

# Revert snapshots:
# Don't forget todo vCenter last, or do it through the host it's on:
$VCFVMS = Get-VM -Tag "vcf-main" | Where-Object {$_.Name -notLike 'vc01*'}
ForEach ($vm in $VCFVMS) { $snapshot = Get-Snapshot -VM $vm.Name ; Set-VM -VM $vm.Name -Snapshot $snapshot -Confirm:$false }
$vcsnap = Get-Snapshot -VM "vc01"
Set-VM -VM 'vc01' -Snapshot $vcsnap

ForEach ($vm in $VCFVMS) { $snapshot = Get-Snapshot -VM $vm.Name -Name $snapshotName ; Set-VM -VM $vm.Name -Snapshot $snapshot -Confirm:$false }

# Delete snapshots
ForEach ($vm in $VCFVMS) { Get-VM -Name $vm.Name | Get-Snapshot | Remove-Snapshot -Confirm:$false }