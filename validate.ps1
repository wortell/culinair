$postsFolder = Join-Path -Path $PSScriptRoot -ChildPath '_posts'
$posts = Get-ChildItem -Path $postsFolder -Filter '*.md'
$validationIssues = $false

function Get-FileEncoding {
  param (
    [Parameter(Mandatory)]
    [string] $File
  )
  $streamReader = [System.IO.StreamReader]::new($File)
  [void] $streamReader.Peek()
  $streamReader.CurrentEncoding.WebName
  $streamReader.Close()
  $streamReader.Dispose()
}

function Test-Bom {
  param (
    [Parameter(Mandatory)]
    [string] $File
  )
  $bom = [System.Byte[]]::CreateInstance([System.Byte], 3)
  $reader = [System.IO.File]::OpenRead($File)
  [void] $reader.Read($bom, 0, 3)
  $reader.Close()
  $bom[0] -eq 0xEF -and $bom[1] -eq 0xBB -and $bom[2] -eq 0xBF
}

foreach ($p in $posts) {
  $postContent = Get-Content -Path $p.FullName -Raw
  if ($postContent -match '\t') {
    Write-Warning -Message "$($p.Name) contains tabs. Use spaces instead"
    $validationIssues = $true
  }

  if ($postContent -match '\r\n') {
    Write-Warning -Message "$($p.Name) uses crlf for end of line. Use lf instead"
    $validationIssues = $true
  }

  $postEncoding = Get-FileEncoding -File $p.FullName
  if ($postEncoding -ne 'utf-8') {
    Write-Warning -Message "$($p.Name) uses $postEncoding encoding. Use utf8 instead"
    $validationIssues = $true
  }

  if (Test-Bom -File $p.FullName) {
    Write-Warning -Message "$($p.Name) uses $postEncoding with a BOM. Use no BOM instead"
    $validationIssues = $true
  }
}

if ($validationIssues) {
  throw 'Validation issues where found'
}