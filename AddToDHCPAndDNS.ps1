# PowerShell script to read YAML, add DHCP reservations, and DNS records

param(
  [string]$YamlFile = "quintellarosa.home.yaml",
  [string]$DHCPScope = "192.168.1.0",
  [string]$DNSZone = "quintellarosa.home"
)

Write-Host "YAML File: $YamlFile"
Write-Host "DHCP Scope: $DHCPScope"
Write-Host "DNS Zone: $DNSZone"

# Install YamlDotNet if not available
$YamlModule = Get-Module -ListAvailable -Name "powershell-yaml"
if (-not $YamlModule) {
  Install-Module -Name "powershell-yaml" -Force -Scope CurrentUser
}

Import-Module powershell-yaml

# Read YAML file
$YamlContent = Get-Content $YamlFile -Raw
$Hs = ConvertFrom-Yaml $YamlContent

# Process each host
foreach ($H in $Hs.hosts) {
  $Name = $H.name
  $IPAddress = $H.ip
  $MACAddress = $H.mac
  
  Write-Host "Processing: $Name - $IPAddress - $MACAddress"
  
  # Add DHCP Reservation
  try {
    Add-DhcpServerv4Reservation -ScopeId $DHCPScope `
      -IPAddress $IPAddress `
      -ClientId $MACAddress `
      -Description $Name `
      -ErrorAction Stop
    Write-Host "✓ DHCP reservation added for $Name"
  }
  catch {
    Write-Host "✗ DHCP reservation failed for $Name : $_"
  }
  
  # Add DNS A Record
  try {
    Add-DnsServerResourceRecordA -ZoneName $DNSZone `
      -Name $Name `
      -IPv4Address $IPAddress `
      -ErrorAction Stop
    Write-Host "✓ DNS record added for $Name"
  }
  catch {
    Write-Host "✗ DNS record failed for $Name : $_"
  }
}

Write-Host "Completed"