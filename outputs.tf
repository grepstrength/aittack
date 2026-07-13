output "resource_group_name" {
  description = "Resource group holding the lab. Target this to be sure you've deleted everything."
  value       = azurerm_resource_group.lab.name
}
output "bastion_name" {
  description = "Bastion host to connect through (Portal > this Bastion > Connect)."
  value       = azurerm_bastion_host.lab.name
}
output "admin_username" {
  description = "Local admin username for RDP into both VMs."
  value       = azurerm_windows_virtual_machine.attack.admin_username
}
output "attack_vm_private_ip" {
  description = "Attack VM private IP on snet-vms."
  value       = azurerm_network_interface.attack.private_ip_address
}
output "victim_vm_private_ip" {
  description = "Victim VM private IP on snet-vms."
  value       = azurerm_network_interface.victim.private_ip_address
}
output "network_isolated_state" {
  description = "Current isolation state... false = internet reachable, true = isolated."
  value       = var.network_isolated
}