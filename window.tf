

resource "azurerm_windows_virtual_machine" "window" {
  name                = "window-vm"
  resource_group_name = azurerm_resource_group.demo.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "Bismillah95%"
  network_interface_ids = [
    azurerm_network_interface.demo-instance2.id,
  ]

  os_disk {
    name                 = "myosdisk2"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_network" "demo2" {
  name                = "${var.prefix}-windows-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name
}



resource "azurerm_subnet" "demo-internal-2" {
  name                 = "${var.prefix}-windows-internal-1"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo2.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_network_interface" "demo-instance2" {
  name                = "${var.prefix}-windows-instance1"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo-internal-2.id
    private_ip_address_allocation = "Dynamic"
  }
}

