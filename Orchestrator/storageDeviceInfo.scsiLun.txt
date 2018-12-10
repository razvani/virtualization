var scsiLuns = host.configManager.storageSystem.storageDeviceInfo.scsiLun;  
for each (var lun in scsiLuns) {  
  System.log("lun.canonicalName: " + lun.canonicalName);  
  System.log("lun.RuntimeName: " + lun.RuntimeName);  
  System.log("lun.capabilities: " + lun.capabilities);  
  System.log("lun.descriptor: " + lun.descriptor);  
  System.log("lun.deviceName: " + lun.deviceName);  
  System.log("lun.deviceType: " + lun.deviceType);  
  System.log("lun.displayName: " + lun.displayName);  
  System.log("lun.durableName: " + lun.durableName);  
  System.log("lun.dynamicProperty: " + lun.dynamicProperty);  
  System.log("lun.dynamicType: " + lun.dynamicType);  
  System.log("lun.key: " + lun.key);  
  System.log("lun.lunType: " + lun.lunType);  
  System.log("lun.model: " + lun.model);  
  System.log("lun.operationalState: " + lun.operationalState);  
  System.log("lun.queueDepth: " + lun.queueDepth);  
  System.log("lun.revision: " + lun.revision);  
  System.log("lun.scsiLevel: " + lun.scsiLevel);  
  System.log("lun.serialNumber: " + lun.serialNumber);  
  System.log("lun.standardInquiry: " + lun.standardInquiry);  
  System.log("lun.uuid: " + lun.uuid);  
  System.log("lun.vendor: " + lun.vendor);  
  System.log("lun.vStorageSupport: " + lun.vStorageSupport);  
  
  
  System.log ("########################################################################################");  
}  