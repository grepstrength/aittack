![alt text](aittack-social-preview.png)

# AIttack!

**Build your own rapidly deployable lab for practicing AI pentesting and red teaming!**

This uses two Windows Server 2022 VMs: an attack VM (with an uncensored Ollama LLM) and a victim VM (OpenClaw + its own local Ollama model). The two VMs talk to each other but the lab can be isolated from the internet with a single config flip. You can access via Bastion host. Neither VM has a public IP. 

I specifically chose the uncensored FableForge-AI/mythos-v2-8b as the attack VM's model, but it's entirely up to you. 

## Configurations

- **Cloud & IaC**: Azure provisioned with Terraform 
- **Network**: Single VNet (`10.0.0.0/16`); VMs on snet-vms (`10.0.1.0/24`); Bastion on AzureBastionSubnet (`10.0.2.0/26`)
- **Isolation toggle**: `network_isolated` varable. `false` = reaches the internet with `true` = egress denied via NSG rule
- **VMs**: 2x Windows Server 2022 Datacenter with the Azure image `Standard_D4s_v5`, no public IPs
- **Attack VM**: Ollama + `FableForge-AI/mythos-v2-8b` (swap to your preference)
- **Victim VM**: OpenClaw + Ollama + `llama3.2:3b` (swap to your preference)
- **Access**: Accessible via Bastion host with a basic SKU, with browser-based RDP
- **Auth**: Azure identity via `az login`. Both the subscription and admin password are stored via environment variables... no credentials in code 

## Post-Deployment Setup Instructions

> ⚠️ **Everything in steps 2–5 needs internet.** Both model pulls, OpenClaw, and Open WebUI all download from the web — so run them all *before* you isolate the lab in step 7. Isolate last, only after step 6 confirms everything works.

### 1. Connect to each VM 

Neither VM has a public IP, so you need to connect via Bastion host:

Azure Portal > VM > Connect > Bastion, then authenticate with your admin username (`labmin` by default) and the password you supplied at deployment.

The Terraform `CustomScriptExtension` already installed Ollama on both VMs during provisioning. The last thing you need to do is pull models and install OpenClaw by hand. 

### 2. Attack VM - pull the model
On your attack VM, in PowerShell:
```powershell
ollama pull FableForge-AI/mythos-v2-8b
```

### 3. Victim VM - pull the model
On the victim VM, in PowerShell:
```powershell
ollama pull llama3.2:3b
```

### 4. Victim VM - install OpenClaw
✅ *RECOMMENDED*

This lets you review before you run the installer. 
Invoke WebRequest > Read the install script > execute your local copy if it looks in order

On the victim VM, in PowerShell:
```powershell
mkdir C:\Temp -Force
irm https://openclaw.ai/install.ps1 -OutFile C:\Temp\openclaw-install.ps1
notepad C:\Temp\openclaw-install.ps1
powershell -ExecutionPolicy Bypass -File C:\Temp\openclaw-install.ps1
```

❌ *NOT RECOMMENDED*

This is the living dangerously method... running random scripts from the internet blind!

On the victim VM, in PowerShell:

```powershell
irm https://openclaw.ai/install.ps1 | iex
```

### 5. Victim VM - serve the model over a web UI

This stands up [Open WebUI](https://github.com/open-webui/open-webui), a ChatGPT-style frontend for the victim's local model — bound so the attack VM can reach it across the subnet. This is the attack surface for later exploitation.

Open WebUI needs Python 3.11.x specifically (not 3.12+). On the victim VM, in PowerShell:
```powershell
winget install --exact --id Python.Python.3.11
```

Close and reopen PowerShell, confirm the version, then install and launch bound to all interfaces:
```powershell
python --version                              # should report 3.11.x
pip install open-webui
open-webui serve --host 0.0.0.0 --port 8080
```

⚠️ Leave that window running — the server holds it open. On first launch, Open WebUI downloads frontend assets and an embedding model, so wait until it prints that it's listening on `0.0.0.0:8080` before isolating. Isolate too early and first-run setup fails.

Then open port 8080 on the victim's **Windows Firewall** (separate from the Azure NSG, which already allows VM-to-VM traffic). In a *second* PowerShell window on the victim:
```powershell
New-NetFirewallRule -DisplayName "Open WebUI 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

### 6. Verify before you isolate the VMs
On both, confirm Ollama and the model:
```powershell
ollama --version    # confirms Ollama is installed
ollama list         # confirms the pulled model is present on the system
```

Then confirm the attack VM can reach the victim's web UI. Grab the victim's private IP from your host's Terraform directory:
```powershell
terraform output victim_vm_private_ip
```
From the **attack VM**, browse to `http://<victim-private-ip>:8080`. If the Open WebUI setup screen loads, the attack surface is live across the air-gapped subnet. Create the local admin account (first account created becomes admin); your pulled `llama3.2:3b` appears in the model dropdown automatically.

### 7. Isolate the lab
From the Terraform directory within your host machine:
```powershell
terraform apply -var="network_isolated=true"
```
This will add the deny-internet-outbound NSG rule. VM-to-VM traffic and Bastion access will remain, but internet ingress and egress will no longer be possible.

## License 
MIT, because you're doing all the work. 