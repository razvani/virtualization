Manual DR - Dedicated VDI (Xendesktop)

Fail-over:

- Start script '01_Create_CSV.ps1' to create a CSV file with all VMs that will failover. Change the VIRP CI in the script.
- Start script '02_Unregister_VMs.ps1' to unregister all VMs from the CSV file created on the previous step.
- Ask Storage team to unmap LUNs at protected site.
- Ask Storage team to do a final sync of the LUNs.
- Ask Storage team to map DR LUNs at recovery site.
- Rescan hosts and add the LUNs at the recovery site. Use assign "New signature" when adding the existing luns at the recovery site!
- Rename datastores to correct name (remove 'snap-256a1546-')
- Start script '03_Register_VMs.ps1' (Make sure that VM folder 'DRPXendesktop' is already created.)
- Power ON VMs (Some VMs will wait for an answer if they were Moved or Copied)
- Ask Storage team to reverse the sync

=======================================================

Fail-back:

- Start script '01_Create_CSV.ps1' to create a CSV file with all VMs that will failover. Change the VIRP CI in the script.
- Start script '02_Unregister_VMs.ps1' to unregister all VMs from the CSV file created on the previous step
- As the check on the folder isn't working at the moment, update the CSV file and change the DRP folder to whatever the VMs need to be put in at the recovery site.
- Ask Storage team to unmap LUNs at protected site.
- Ask Storage team to do a final sync of the LUNs.
- Ask Storage team to map DR LUNs at recovery site.
- Rescan hosts and add the LUNs at the recovery site. Use assign "New signature" when adding the existing luns at the recovery site!
- Rename datastores to correct name (remove 'snap-256a1546-')
- Start script '03_Register_vms.ps1'
- Power ON VMs (Some VMs will wait for an answer if they were Moved or Copied)
- Ask storage to reverse the sync

Side notes:
DO NOT EDIT with EXCEL as it will break the formatting.
Add Datastores one by one. No need to fill the datastore name.
Fail-over execution time: 1 hour and 42 minutes