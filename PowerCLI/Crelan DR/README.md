Manual DR - Dedicated VDI (Xendesktop)
======================================

Fail-over and Fail-back procedure:

- Start script '01_Create_CSV.ps1' to create a CSV file with all VMs that will failover. Change the VIRP CI in the script.
- Start script '02_Unregister_VMs.ps1' to unregister all VMs from the CSV file created on the previous step.
- Ask Storage team to unmap LUNs at protected site.
- Ask Storage team to do a final sync of the LUNs.
- Ask Storage team to map DR LUNs at recovery site.
- Rescan hosts and add the LUNs at the recovery site. Use assign "New signature" when adding the existing LUNs at the recovery site!
- Rename datastores to correct name (remove 'snap-256a1546-')
- Start script '03_Register_VMs.ps1' (Make sure that VM folder 'DRPXendesktop' is already created.)
- Power ON VMs (Some VMs will wait for an answer if they were Moved or Copied)
- Ask Storage team to reverse the sync