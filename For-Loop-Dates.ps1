$requiredAddDays = 7
$requiredDate = (get-date).AddDays($requiredAddDays)
$startDate = (get-date).AddDays(7)
$endAddDays = -15

Write-Output "requiredAddDays = $requiredAddDays"
Write-Output "requiredDate =  $requiredDate"
Write-Output "startDate = $startDate"
Write-Output "endAddDays = $endAddDays"

for($i = $startDate; $i -lt $requiredDate; $i = $i.AddDays(1))
{

    Write-Output "$($i.ToString("yyyyMMdd"))-$($i.AddDays($endAddDays).ToString("yyyyMMdd"))"

}
