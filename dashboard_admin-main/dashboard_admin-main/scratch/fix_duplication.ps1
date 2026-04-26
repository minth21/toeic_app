$path = "d:\doantn\dashboard_admin-main\dashboard_admin-main\src\pages\PartDetail.tsx"
$lines = Get-Content $path
$newLines = $lines[0..1133] + $lines[1280..($lines.Length - 1)]
$newLines | Set-Content $path
