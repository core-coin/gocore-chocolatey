$ErrorActionPreference = 'Stop'

if (-not (Get-ProcessorBits 64)) {
  throw 'go-core only ships a 64-bit Windows build; 32-bit Windows is not supported.'
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$packageArgs = @{
  PackageName    = 'go-core'
  FileFullPath   = Join-Path $toolsDir 'gocore.exe'
  Url64bit       = 'https://github.com/core-coin/go-core/releases/download/v2.2.2/gocore-windows-x86_64.exe'
  Checksum64     = 'a0e1f0bea509bc4b6df3c6468b698ad0e74a4113344efb0b238ca3a394a9c831'
  ChecksumType64 = 'sha256'
}

Get-ChocolateyWebFile @packageArgs
