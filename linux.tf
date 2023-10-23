provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "demo" {
  name     = "final-lab-demo"
  location = var.location
}

resource "azurerm_linux_virtual_machine" "os_linux_instance" {
  name                = "${var.prefix}-linux-vm"
  resource_group_name = azurerm_resource_group.demo.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.demo-instance.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.linux_key.public_key_openssh
  }

  os_disk {
    name                 = "myosdisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.public-ip.ip_address} >> /Windows/System32/drivers/etc/"
  }

  depends_on = [
    tls_private_key.linux_key
  ]
}

resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem


}

resource "azurerm_virtual_network" "demo" {
  name                = "${var.prefix}-linux-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name
}

resource "azurerm_public_ip" "public-ip" {
  name                = "PublicIp1"
  resource_group_name = azurerm_resource_group.demo.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_subnet" "demo-internal-1" {
  name                 = "${var.prefix}-linux-internal-1"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "demo-instance" {
  name                = "${var.prefix}-linux-instance1"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "instance1"
    subnet_id                     = azurerm_subnet.demo-internal-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip.id
  }
}

resource "azurerm_network_security_group" "allow-ssh" {
  name                = "${var.prefix}-allow-ssh"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh-source-address
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "demo-instance-1" {
  network_interface_id      = azurerm_network_interface.demo-instance.id
  network_security_group_id = azurerm_network_security_group.allow-ssh.id
}










