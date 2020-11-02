Fairly simple TF scripts to deploy VMs on Azure:


 - one is a Python Flask web app making SQL requests to the 2nd VM

 - the 2nd VM is a SQL server that pulls 10 random dog images from the web


Various objects are assumed to exist (Azure resource-group for example) so before you run in your environment, read the code.


Terraform logs in using the service-principal plus secret method.


VM tags are meant to be used by a Cloud APIC listening for events in the
 subscription. 
VMs are then placed in the appropriate EPGs.


Builds are performed by Jenkins using a pipeline triggered by a generic webhook.


This is work in progress and mostly just plain experiments. 
Enjoy!
