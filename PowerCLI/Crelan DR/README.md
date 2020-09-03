Manual DR - Dedicated VDI (Xendesktop)

Fail-over:

- Start script 01_Create_CSV.ps1 to create a CSV file with all vm's that will failover. Change the VIRP ci in the script.
- Start script 02_Unregister_vm's.ps1 to unregister all vm's from that CSV.
- Ask storage to unmap luns at protected site
- Ask storage to do a final sync of the storage
- Ask storage to map dr luns at recovery site
- rescan hosts and add the luns at the recovery site. Use assign "New signature" when adding the existing luns at the recovery site!
- rename datastores to correct name (remove snap-256a1546-)
- Start 03_Register_vms.ps1 (Make sure that VM folder 'DRPXendesktop' is already created.)
- Power ON VMs (Some VMs will wait for an answer if they were Moved or Copied)
- Ask storage to reverse the sync

=======================================================

Fail-back:

- Start script 01_Create_CSV.ps1 to create a CSV file with all vm's that will failover. Change the VIRP ci in the script.
- Start script 02_Unregister_vms_based_on_a_file.ps1 to unregister all vm's from that CSV.
- As the check on the folder isn't working at the moment, update the CSV file and change the DRP folder to whatever the vm's need to be put in at the recovery site.
- Ask storage to unmap luns at protected site
- Ask storage to do a final sync of the storage
- Ask storage to map dr luns at recovery site
- rescan hosts and add the luns at the recovery site. Use assign "New signature" when adding the existing luns at the recovery site.
- rename datastores to correct name (remove snap-256a1546-)
- Start 03_Register_vms.ps1
- Ask storage to reverse the sync

Side notes:
DO NOT EDIT with EXCEL as it will break the formatting.
Add Datastores one by one. No need to fill the datastore name.
Fail-over execution time: 1 hour and 42 minutes (Razvan)