variable "location" {
  type        = string
  description = "The Azure region for all lab resources."
  default     = "eastus"
}
variable "prefix" {
  type        = string
  description = "Short name stitched into every resource name so the lab is easy to spot and destroy."
  default     = "agentlab"
}
variable "admin_username" {
  type        = string
  description = "Local admin account created on both Windows VMs."
  default     = "labmin"
}
variable "admin_password" {
  type        = string
  description = "Password for the local admin account. 12-123 char, which meets Azure complexity rules."
  default     = true
}
variable "network_isolated" {
  type        = string
  description = "false = VMs have outbound internet (provisioning), true = outbound internet is denied"
  default     = false
}
variable "attack_vm_size" {
  type        = string
  description = "VM SKU for the attack host running Ollama."
  default     = "Standard_D4s_v5"
}
variable "victim_vm_size" {
  type        = string
  description = "VM SKU for the victim machine running OpenClaw plus its own local Ollama model."
  default     = "Standard_D4s_v5"
}
variable "attack_ollama_model" {
  type        = string
  description = "The model slug the attack VM pulls via 'ollama pull'."
  default     = "FableForge-AI/mythos-v2-8b"
}
variable "victim_ollama_model" {
  type        = string
  description = "Model slug the victim VM pulls. Any model works; smaller = faster on CPU."
  default     = "llama3.2:3b"
}