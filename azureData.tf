provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "~> 1.34"
}

data "azurerm_resource_group" "myRg" {
  # naming convention is CAPIC_tenant_vrf_region 
  name     = "CAPIC_domenico_VRF1_francecentral"
}

data "azurerm_virtual_network" "myNet" {
  name                = "VRF1"
  resource_group_name = "${data.azurerm_resource_group.myRg.name}"
}

data "azurerm_subnet" "mySubnet" {
  name                 = "subnet-11.0.1.0_24"
  resource_group_name  = "${data.azurerm_resource_group.myRg.name}"
  virtual_network_name = "${data.azurerm_virtual_network.myNet.name}"
}

# Create public IPs
resource "azurerm_public_ip" "dom-publicip" {
    name                         = "dom-PublicIP"
    location                     = "francecentral"
    resource_group_name          = data.azurerm_resource_group.myRg.name
    allocation_method            = "Dynamic"
    domain_name_label            = "dom-tf-db"

    tags = {
        application = "database"
    }
}

resource "azurerm_public_ip" "dom-publicip2" {
    name                         = "dom-PublicIP2"
    location                     = "francecentral"
    resource_group_name          = data.azurerm_resource_group.myRg.name
    allocation_method            = "Dynamic"
    domain_name_label            = "dom-tf-web"

    tags = {
        application = "web"
    }
}

# Create temporary security group to allow file provisioner SSH access
resource "azurerm_network_security_group" "dom-tf-provisioner" {
    name                = "dom-tf-provisioner"
    location            = "francecentral"
    resource_group_name = data.azurerm_resource_group.myRg.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "egress_all"
        priority                   = 105
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    tags = {
        environment = "temporary"
    }
}
/* data "azurerm_network_security_group" "temporaryGroup" {
    name                = "manual-cpaggen"
    resource_group_name = "${data.azurerm_resource_group.myRg.name}"
} 
 */ 
 resource "azurerm_network_interface" "dom-tf-db-nic" {
  name                = "dom-tf-db-nic"
  location            = data.azurerm_resource_group.myRg.location
  resource_group_name = data.azurerm_resource_group.myRg.name
  network_security_group_id = azurerm_network_security_group.dom-tf-provisioner.id

  ip_configuration {
    name                          = "dom-tf-db-ip"
    subnet_id                     = data.azurerm_subnet.mySubnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "11.0.1.200"
    public_ip_address_id          = azurerm_public_ip.dom-publicip.id
  }
} 

resource "azurerm_network_interface" "dom-tf-client-nic" {
  name                = "dom-tf-client-nic"
  location            = data.azurerm_resource_group.myRg.location
  resource_group_name = data.azurerm_resource_group.myRg.name
  network_security_group_id = azurerm_network_security_group.dom-tf-provisioner.id

  ip_configuration {
    name                          = "dom-tf-client-ip"
    subnet_id                     = data.azurerm_subnet.mySubnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "11.0.1.100"
    public_ip_address_id          = azurerm_public_ip.dom-publicip2.id
  }
} 

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${data.azurerm_resource_group.myRg.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "dom-mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = data.azurerm_resource_group.myRg.name
    location                    = "francecentral"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    enable_advanced_threat_protection = "false"

    tags = {
        environment = "dom-terraform-demo"
    }
}

/* data "azurerm_storage_account" "dom-mystorageaccount" {
  name = "capichybridtenantazurevr"
  resource_group_name = "${data.azurerm_resource_group.myRg.name}"
} */
resource "azurerm_virtual_machine" "dom-tf-db-vm" {
  name                  = "dom-tf-db-vm"
  location              = "${data.azurerm_resource_group.myRg.location}"
  resource_group_name   = "${data.azurerm_resource_group.myRg.name}"
  network_interface_ids = ["${azurerm_network_interface.dom-tf-db-nic.id}"]
  vm_size               = "Standard_B1S"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "dom-tf-db-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.vmName}-db"
    admin_username = "${var.adminUsername}"
    admin_password = "${var.adminPassword}"
    custom_data    = "${file("cloudinit.conf")}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  boot_diagnostics {
    enabled = "true"
    storage_uri = "${azurerm_storage_account.dom-mystorageaccount.primary_blob_endpoint}"
  }
  tags = {
    application = "db"
  }
}


resource "azurerm_virtual_machine" "dom-tf-client-vm" {
  name                  = "dom-tf-client-vm"
  location              = "${data.azurerm_resource_group.myRg.location}"
  resource_group_name   = "${data.azurerm_resource_group.myRg.name}"
  network_interface_ids = ["${azurerm_network_interface.dom-tf-client-nic.id}"]
  vm_size               = "Standard_B1S"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "dom-tf-client-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.vmName}-web"
    admin_username = "${var.adminUsername}"
    admin_password = "${var.adminPassword}"
    custom_data    = "${file("cloudinit-client.conf")}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  boot_diagnostics {
    enabled = "true"
    storage_uri = "${azurerm_storage_account.dom-mystorageaccount.primary_blob_endpoint}"
  }
  tags = {
    application = "web"
  }

  connection {
      type     = "ssh"
      user     = "${var.adminUsername}"
      password = "${var.adminPassword}"
      host     = "${azurerm_public_ip.dom-publicip2.fqdn}"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/cisco/templates",
      "sudo chown cisco /home/cisco/templates",
      "sudo chgrp cisco /home/cisco/templates"
    ]
  }
  provisioner "file" {
    source      = "app.py"
    destination = "/home/cisco/app.py"
  }
  provisioner "file" {
    source      = "templates/index.html"
    destination = "/home/cisco/templates/index.html"
  }
  provisioner "file" {
    source      = "templates/showdog.html"
    destination = "/home/cisco/templates/showdog.html"
  }
}
