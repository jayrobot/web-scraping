# Fetch page HTML
# $response = Invoke-WebRequest -Uri "https://www.939waby.com/onair/played/?date=2024-12-16&hour=3"
# $reponse.RawContent # | out-gridview

# convert to parameters
# $startDay 23
# $endDay 29
# $yearMonth 2024-12-

$today = Get-Date
if ($today.DayOfWeek -ne "Monday") { return "This script must be run on a Monday" }

$startDate = $today.AddDays(-7)	
$endDate = $today.AddDays(-1)

$baseUrl = "https://www.939waby.com/onair/played/?date="
			
for ($currentDate = $startDate; $currentDate -le $endDate; $currentDate = $currentDate.AddDays(1)) {
	
	# $dayNumber = ($itDay -lt 10 ? "0" : "") + $itDay
	# $urlWithDay = $baseUrl + $dayNumber

	# $output = ""
	for ($itHour = 0; $itHour -le 23; $itHour++) {

		$urlParams = $currentDate.ToString("yyyy-MM-dd") + "&hour=" + $itHour.ToString()
		
		$url = $baseUrl + $urlParams
		Write-Output $url
		
		$response = Invoke-WebRequest -Uri $url

		# Extract data from $response
		$songs = $response.Images | Select-Object alt -Skip 2
		# replace &#039; with ' in song titles
		$songs = $songs | ForEach-Object { $_.alt = $_.alt -replace "&#039;", "'"; $_ }

		# Output results 
		$outputFile = ".\WABY-Playlists\WABY-" + $currentDate.ToString("yyyy-MM-dd") + ".csv"
		$songs | Export-Csv -Append -Path $outputFile -NoTypeInformation  
	}
}

#$baseUrl = "https://www.939waby.com/onair/played/?date=2024-12-"

#for($itDay=30; $itDay -le 31; $itDay++) {
#	$urlWithMonth = $baseUrl + $itDay
#	Write-Output "2024-12-"$itDay
	
#	$output = ""
#	for($itHour=0; $itHour -le 23; $itHour++) {

#		$url = $urlWithMonth + '&hour=' + $itHour
#		Write-Output $itHour
		
#		$response = Invoke-WebRequest -Uri $url

#		# Extract data from $response
#		$songs = $response.Images | Select-Object alt -Skip 2

#		# Output results 
#		# $output = $output + $songs
#		$outputFile = "WABY-2024-12-" + $itDay + ".csv"
#		$songs | Export-Csv -Append -Path $outputFile -NoTypeInformation  
#	}
#}


# Set-Clipboard -Value $output

# Extract product info
# $name = $response.Content -match ‘<h2 class="name">(.*?)</h2>‘ | Out-Null
# $description = $response.Content -match ‘<p class="description">(.*?)</p>‘ | Out-Null 
# $price = $response.Content -match ‘<span class="price">(.*?)</span>‘ | Out-Null
