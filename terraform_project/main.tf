resource "random_pet" "rg_name" {
 
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg2" {
  location = var.resource_group_location
  name     = var.resource_group_name_prefix
}

 resource "azurerm_virtual_network" "vnet1" {
   name                = "vnet1"
   address_space       = ["10.0.0.0/16"]
   location            = azurerm_resource_group.rg2.location
   resource_group_name = azurerm_resource_group.rg2.name
 }

 resource "azurerm_subnet" "public" {
   name                 = "public"
   resource_group_name  = azurerm_resource_group.rg2.name
   virtual_network_name = azurerm_virtual_network.vnet1.name
   address_prefixes     = ["10.0.0.0/24"]
 }

  resource "azurerm_subnet" "private" {
   name                 = "private"
   resource_group_name  = azurerm_resource_group.rg2.name
   virtual_network_name = azurerm_virtual_network.vnet1.name
    address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
 }
  }
  }





resource "azurerm_lb" "main" {
  name                = "main"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  sku                 = "Standard"

  frontend_ip_configuration  {
    name                 = "publicIp"
    subnet_id            = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"

  }
}


resource "azurerm_lb_rule" "lb_rule1" {
  frontend_ip_configuration_name = "publicIp"
  name                = "lb-rule1"
  loadbalancer_id     = azurerm_lb.main.id
  resource_group_name = azurerm_resource_group.rg2.name

  protocol    = "tcp"
  frontend_port = 80
  backend_port  = 80

  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool_rule1.id
}



resource "azurerm_lb_backend_address_pool" "backend_pool_rule1" {
  name                = "backend-pool_rule1"
  loadbalancer_id     = azurerm_lb.main.id
  resource_group_name = azurerm_resource_group.rg2.name  

  backend_address {
    virtual_network_id = azurerm_virtual_network.vnet1.id
    name = "vm1B"
    ip_address = azurerm_network_interface.nic1.private_ip_address
  }
    backend_address {
    virtual_network_id = azurerm_virtual_network.vnet1.id
    name = "vm2B"
    ip_address = azurerm_network_interface.nic2.private_ip_address
  }
      backend_address {
    virtual_network_id = azurerm_virtual_network.vnet1.id
    name = "vm3B"
    ip_address = azurerm_network_interface.nic3.private_ip_address
  }
  }


resource "azurerm_network_security_group" "publicnsg" {
   resource_group_name   = azurerm_resource_group.rg2.name
    location              = azurerm_resource_group.rg2.location
    name   = "publicnsg"
 # source_address_prefix = "0.0.0.0/24"
  
}

resource "azurerm_subnet_network_security_group_association" "publicToPublicnsg" {
  subnet_id = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.publicnsg.id
  
}
resource "azurerm_network_security_rule" "allowRdp" {
  name                        = "allowRdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.publicnsg.name
}



resource "azurerm_network_security_rule" "allowSqlIn" {
  name                        = "allowConnection"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "5432"
  destination_port_range      = "8080"
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "10.0.0.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.publicnsg.name
}


resource "azurerm_network_security_rule" "allowSqlOutt" {
  name                        = "allowConnection"
  priority                    = 150
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.publicnsg.name
}
/*
resource "azurerm_network_security_rule" "allowConnection" {
  name                        = "allowConnection"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.publicnsg.name
}

resource "azurerm_network_security_rule" "allowrdp" {
  name                        = "allowrdp"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.0.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.publicnsg.name
}


resource "azurerm_network_security_rule" "allowsshTcp" {
  name                        = "allowsshTcp"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.publicnsg.name
}


resource "azurerm_network_security_rule" "allowPostgreSql" {
  name                        = "allowPostgreSql"
  priority                    = 300
  direction                   = "outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "5432"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.0.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.publicnsg.name
}

*/
resource "azurerm_network_security_group" "privatensg" {
  resource_group_name   = azurerm_resource_group.rg2.name
  location              = azurerm_resource_group.rg2.location
  name                  = "privatensg"
  
}


resource "azurerm_subnet_network_security_group_association" "privateToPrivatensg" {
  subnet_id = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.privatensg.id
  
}




resource "azurerm_network_security_rule" "connectionVmToSql" {
  name                        = "allowConnection"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "8080"
  destination_port_range      = "5432"
  source_address_prefix       = "10.0.0.0/24"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.privatensg.name
}

resource "azurerm_network_security_rule" "connectionSqlToVm" {
  name                        = "allowConnection"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "5432"
  destination_port_range      = "8080"
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "10.0.0.0/24"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.privatensg.name
}


/*
resource "azurerm_network_security_rule" "allowConnectionToSql" {
  name                        = "allowConnectionToSql"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "8080"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/24"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.privatensg.name
}

#resource "azurerm_network_security_rule" "allowConnection2" {
  #name                        = "allowConnection"
  #priority                    = 100
  #direction                   = "Outbound"
  #access                      = "Allow"
  #protocol                    = "*"
  #source_port_range           = "*"
  #destination_port_range      = "8080"
  #source_address_prefix       = "*"
  #destination_address_prefix  = "10.0.2.0/24"
  #resource_group_name         = azurerm_resource_group.rg2.name
 # network_security_group_name = azurerm_network_security_group.privatensg.name
#}


resource "azurerm_network_security_rule" "allowsshSql" {
  name                        = "allowsshSql"
  priority                    = 120
  source_address_prefix = "10.0.0.0/24"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "8080"
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.privatensg.name
}

/*
#resource "azurerm_public_ip" "test" {
  #name = "test"
  #location = azurerm_resource_group.rg2.location
  #resource_group_name = azurerm_resource_group.rg2.name
 # allocation_method = "Static"
  
#}
*/

 resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
   location            = azurerm_resource_group.rg2.location
   resource_group_name = azurerm_resource_group.rg2.name

   ip_configuration {
     name                          = "ipconfig1"
     subnet_id                     = azurerm_subnet.public.id
     private_ip_address_allocation = "Dynamic"
 
   }
 } 



  resource "azurerm_virtual_machine" "vm1" {
   name                  = "vm1"
   location              = azurerm_resource_group.rg2.location
   resource_group_name   = azurerm_resource_group.rg2.name
   network_interface_ids = [azurerm_network_interface.nic1.id]
   vm_size                  = "Standard_DS1_v2"
  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  }

  
 resource "azurerm_network_interface" "nic2" {
   name                = "nic2"
   location            = azurerm_resource_group.rg2.location
   resource_group_name = azurerm_resource_group.rg2.name

   ip_configuration {
     name                          = "ipconfig2"
     subnet_id                     = azurerm_subnet.public.id
     private_ip_address_allocation = "Dynamic"
   }
 }


  resource "azurerm_virtual_machine" "vm2" {
   name                  = "vm2"
   location              = azurerm_resource_group.rg2.location
   resource_group_name   = azurerm_resource_group.rg2.name
   network_interface_ids = [azurerm_network_interface.nic2.id]
   vm_size                  = "Standard_DS1_v2"
  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  }


  resource "azurerm_network_interface" "nic3" {
   name                = "nic3"
   location            = azurerm_resource_group.rg2.location
   resource_group_name = azurerm_resource_group.rg2.name

   ip_configuration {
     name                          = "ipconfig3"
     subnet_id                     = azurerm_subnet.public.id
     private_ip_address_allocation = "Dynamic"
   }
 }


  resource "azurerm_virtual_machine" "vm3" {
   name                  = "vm3"
   location              = azurerm_resource_group.rg2.location
   resource_group_name   = azurerm_resource_group.rg2.name
   network_interface_ids = [azurerm_network_interface.nic3.id]
   vm_size                  = "Standard_DS1_v2"
  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk3"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  }
  


  resource "azurerm_private_dns_zone" "sqlDns" {
  name                = "example.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg2.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "sqlDnsLink" {
  name                  = "exampleVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.sqlDns.name
  virtual_network_id    = azurerm_virtual_network.vnet1.id
  resource_group_name   = azurerm_resource_group.rg2.name
}

resource "azurerm_postgresql_flexible_server" "tairserver" {
  name                   = "tairserver"
  resource_group_name    = azurerm_resource_group.rg2.name
  location               = azurerm_resource_group.rg2.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.private.id
  private_dns_zone_id    = azurerm_private_dns_zone.sqlDns.id
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  zone                   = "1"

  storage_mb = 32768

  sku_name   = "GP_Standard_D4s_v3"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.sqlDnsLink]

}


  


 resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_pool_association" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = azurerm_network_interface.nic1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool_rule1.id
}

 resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_pool_association2" {
  network_interface_id    = azurerm_network_interface.nic2.id
  ip_configuration_name   = azurerm_network_interface.nic2.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool_rule1.id
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_pool_association3" {
  network_interface_id    = azurerm_network_interface.nic3.id
  ip_configuration_name   = azurerm_network_interface.nic3.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool_rule1.id
}




 resource "azurerm_virtual_network" "vnet2" {
   name                = "vnet2"
   address_space       = ["10.1.0.0/16"]
   location            = azurerm_resource_group.rg2.location
   resource_group_name = azurerm_resource_group.rg2.name
 }

 
 resource "azurerm_subnet" "subvnet2" {
   name                 = "subvnet2"
   resource_group_name  = azurerm_resource_group.rg2.name
   virtual_network_name = azurerm_virtual_network.vnet2.name
   address_prefixes     = ["10.1.0.0/24"]
 }


 

  resource "azurerm_network_interface" "nic4" {
   name                = "nic4"
   location            = azurerm_resource_group.rg2.location
   resource_group_name = azurerm_resource_group.rg2.name

   ip_configuration {
     name                          = "ipconfig4"
     subnet_id                     = azurerm_subnet.subvnet2.id
     private_ip_address_allocation = "Dynamic"
   }
 }


  resource "azurerm_virtual_machine" "vm4" {
   name                  = "vm4"
   location              = azurerm_resource_group.rg2.location
   resource_group_name   = azurerm_resource_group.rg2.name
   network_interface_ids = [azurerm_network_interface.nic4.id]
   vm_size                  = "Standard_DS1_v2"
  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk4"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  }


  
resource "azurerm_virtual_network_peering" "peer1to2" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.rg2.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
}

resource "azurerm_virtual_network_peering" "peer2to1" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.rg2.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
}
  



