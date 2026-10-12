# Define the URL to scrape
$url = "https://dutchie.com/dispensary/robinsons-flower/products/edibles"

# Send a web request and get the response
$response = Invoke-WebRequest -Uri $url

# Parse the HTML content
$html = $response.ParsedHtml

# Specify the class you're looking for
$timePlayedClass = "gm-sec-title"
$songTitleClass = "gm-sec-title"

# Use the `IHTMLDocument` COM object to find all `<p>` tags
$pTags = $html.getElementsByTagName("p")

# Loop through all `<p>` tags to find `<span>` tags with the target class
foreach ($p in $pTags) {
	$spanTags = $p.getElementsByTagName("span")
	foreach ($span in $spanTags) {
		if ($span.className -eq $timePlayedClass) {
			# Output or process the span's inner text or HTML
			Write-Output $span.innerText
		}
		elseif ($span.className -eq $songTitleClass) {
			# Output or process the span's inner text or HTML
			Write-Output $span.innerText
		}
	}
