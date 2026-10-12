# Fetch page HTML
# $response = Invoke-WebRequest -Uri "https://www.939waby.com/onair/played/?date=2024-12-16&hour=3"
# $reponse.RawContent # | out-gridview

$baseUrl = "https://www.939waby.com/onair/played/?date=2024-12-"

for($itDay=16; $itDay -le 22; $itDay++) {
	$urlWithMonth = $baseUrl + $itDay
	Write-Output "2024-12-" + $itDay
	
	$output = ""
	for($itHour=0; $itHour -le 24; $itHour++) {

		$url = $urlWithMonth + '&hour=' + $itHour
		Write-Output $itHour
		
		$response = Invoke-WebRequest -Uri $url

		# Extract data from $response
		$songs = $response.Images | Select-Object alt -Skip 2
		# $output = $output + $songs

		# Output results 
		$outputFile = "WABY-2024-12-" + $itDay + ".csv"
		$songs | Export-Csv -Append -Path $outputFile -NoTypeInformation  
	}
}

# Set-Clipboard -Value $output

# Extract product info
# $name = $response.Content -match ‘<h2 class="name">(.*?)</h2>‘ | Out-Null
# $description = $response.Content -match ‘<p class="description">(.*?)</p>‘ | Out-Null 
# $price = $response.Content -match ‘<span class="price">(.*?)</span>‘ | Out-Null
