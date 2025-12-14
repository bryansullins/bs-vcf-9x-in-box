1. Move dns02 to esxauto.
2. Power down all VMs.
--> Thought: Keep a copy of the VCF Installer on esxauto!
3. ESX Boot settings - ks.cfg
4. kickstart installation - esx01 and esx02
--> Will need to remove vSAN partitions.
5. ensure ntpd is running on both hosts.
6. Run the VCF Install sript to deploy (deploy_vcf_installer.sh)
7. Modify the installer to not use https:

Open the application-prod.properties file located at /opt/vmware/vcf/lcm/lcm-app/conf/ using a text editor
lcm.depot.adapter.httpsEnabled=false
systemctl restart lcm

8. Download binaries into local store on SDDCM01
9. Run setup_vcf_installer.ps1 (forces VCF to be two-host possible)
9. Deploy VCF using JSON Spec.