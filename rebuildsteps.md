# BS Home Lab Running Notes for Rebuild/Automation

## VCF 9.0.1 Deployment

1. Move dns02 to esxauto.
2. Power down all VMs.
--> Thought: Keep a copy of the VCF Installer on esxauto!
3. ESX Boot settings - ks.cfg
4. kickstart installation - esx01 and esx02
--> Will need to remove vSAN partitions.
5. ensure ntpd is running on both hosts.
6. Run the VCF Install sript to deploy (deploy_vcf_installer.sh)
7. Run setup_vcf_installer.ps1 (forces VCF to be two-host possible)
8. Download binaries into local store on SDDCM01
9. Deploy VCF using JSON Spec.


## NSX Edge Deployment
1. System->Fabric->Hosts->(select vSphere Cluster)->Action->Activate NSX on DVPG
2. Walk through the Cluster creation in https://williamlam.com/2025/07/ms-a2-vcf-9-0-lab-configuring-nsx-virtual-private-cloud-vpc.html
3. Implement Workaround: [William Lam's NSX Edge Workaround Script for Ryzen](./scripts/nsxedge-avi/configure_nsx_edge_on_amd_ryzen.ps1)

## AVI Single Node Deployment

1. Downlad desired AVI Version.
2. Use AVI upload script here: [VCF TOOLS](https://github.com/avinetworks/devops/tree/master/tools/vcf/)
3. Fill in all items, otherwise it will fail (parens don't mean default).
4. Edit feature.properties on SDDCM01 - feature.vcf.vgl-41078.alb.single.node.cluster=true
5. Restart services with echo 'y' | /opt/vmware/vcf/operationsmanager/scripts/cli/sddcmanager_restart_services.sh.
6. Run the deploy_one_node_nsx_alb.ps1 script

## Supervisor steps

Use deploy_one_node_nsx_alb.ps1
Next: Setup the Cert for IP SANS: https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/avi-load-balancer/avi-kubernetes-operator/2-1/avi-kubernetes-operator-guide-2-1/avi-kubernetes-operator-deployment-guide/ako-and-tanzu/deploying-ako-on-vsphere-with-tanzu-on-nsx-t-via-supervisor.html

AVI Setup:

https://labs.hol.vmware.com/HOL/catalog/lab/26881

https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/avi-load-balancer/avi-load-balancer-vmware-cloud-foundation/9-0/deploying-supervisor-with-nsx-and-avi-load-balancer.html

https://vworld.com.pl/from-zero-to-a-scalable-application-in-vcf-9-0-the-complete-hyper-detailed-configuration-guide/

IMPORTANT:

https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/avi-load-balancer/avi-kubernetes-operator/2-1/avi-kubernetes-operator-guide-2-1/avi-kubernetes-operator-deployment-guide/ako-and-tanzu/deploying-ako-on-vsphere-with-tanzu-on-nsx-t-via-supervisor.html


