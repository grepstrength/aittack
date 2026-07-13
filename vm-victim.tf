resource "azurerm_network_interface" "victim" {
  name                = "nic-${var.prefix}-victim"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vms.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "victim" {
  name                = "vm-${var.prefix}-victim"
  computer_name       = "victim-vm"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  size                = var.victim_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.victim.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "victim_ollama" {
  name                 = "install-ollama"
  virtual_machine_id   = azurerm_windows_virtual_machine.victim.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"Invoke-WebRequest https://ollama.com/download/OllamaSetup.exe -OutFile C:/Windows/Temp/OllamaSetup.exe; Start-Process C:/Windows/Temp/OllamaSetup.exe -ArgumentList '/VERYSILENT' -Wait; [Environment]::SetEnvironmentVariable('OLLAMA_HOST','0.0.0.0','Machine')\""
  })
}