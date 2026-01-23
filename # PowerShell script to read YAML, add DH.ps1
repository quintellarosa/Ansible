# PowerShell script to read YAML, add DHCP reservations, and DNS records

param(
  [string]$YamlFile = "quintellarosa.home.yaml",
  [string]$DHCPScope = "192.168.1.0",
  [string]$DNSZone = "quintellarosa.home"
)

# Install YamlDotNet if not available
$YamlModule = Get-Module -ListAvailable -Name "powershell-yaml"
if (-not $YamlModule) {
  Install-Module -Name "powershell-yaml" -Force -Scope CurrentUser
}

Import-Module powershell-yaml

# Read YAML file
$YamlContent = Get-Content $YamlFile -Raw
$Hosts = ConvertFrom-Yaml $YamlContent

# Process each host
foreach ($Host in $Hosts.hosts) {
  $Hostname = $Host.name
  $IPAddress = $Host.ip
  $MACAddress = $Host.mac
  
  Write-Host "Processing: $Hostname - $IPAddress - $MACAddress"
  
  # Add DHCP Reservation
  try {
    Add-DhcpServerv4Reservation -ScopeId $DHCPScope `
      -IPAddress $IPAddress `
      -ClientId $MACAddress `
      -Description $Hostname `
      -ErrorAction Stop
    Write-Host "✓ DHCP reservation added for $Hostname"
  }
  catch {
    Write-Host "✗ DHCP reservation failed for $Hostname : $_"
  }
  
  # Add DNS A Record
  try {
    Add-DnsServerResourceRecordA -ZoneName $DNSZone `
      -Name $Hostname `
      -IPv4Address $IPAddress `
      -ErrorAction Stop
    Write-Host "✓ DNS record added for $Hostname"
  }
  catch {
    Write-Host "✗ DNS record failed for $Hostname : $_"
  }
}

Write-Host "Completed"