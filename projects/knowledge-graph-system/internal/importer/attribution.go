package importer

import (
	"fmt"
	"net/url"
	"strings"
)

// GenerateAttribution creates attribution text from source URL
func GenerateAttribution(sourceURL string) string {
	if sourceURL == "" {
		return ""
	}

	// Parse URL to get domain name
	parsedURL, err := url.Parse(sourceURL)
	if err != nil {
		return fmt.Sprintf("Source: %s", sourceURL)
	}

	// Create friendly attribution based on known domains
	domain := parsedURL.Hostname()

	switch {
	case strings.Contains(domain, "stackoverflow.com"):
		return fmt.Sprintf("Source: Stack Overflow - %s", sourceURL)
	case strings.Contains(domain, "github.com"):
		return fmt.Sprintf("Source: GitHub - %s", sourceURL)
	case strings.Contains(domain, "readthedocs.io"):
		return fmt.Sprintf("Source: Documentation - %s", sourceURL)
	case strings.Contains(domain, "medium.com"):
		return fmt.Sprintf("Source: Medium - %s", sourceURL)
	case strings.Contains(domain, "dev.to"):
		return fmt.Sprintf("Source: DEV Community - %s", sourceURL)
	default:
		return fmt.Sprintf("Source: %s", sourceURL)
	}
}

// ExtractPrimarySourceURL extracts the first/primary URL from a list
func ExtractPrimarySourceURL(urls []string) string {
	if len(urls) == 0 {
		return ""
	}
	return urls[0]
}

// AddAttributionToPreBlock adds source attribution to a PreBlock based on metadata
func AddAttributionToPreBlock(preBlock *PreBlock, source *ImportSource) {
	// Check if source has public URLs in metadata
	if source.Metadata != nil {
		if urls, ok := source.Metadata["source_urls"].([]string); ok && len(urls) > 0 {
			primaryURL := ExtractPrimarySourceURL(urls)
			preBlock.SourceURL = primaryURL
			preBlock.SourceAttribution = GenerateAttribution(primaryURL)
		}
	}

	// Set visibility from source
	preBlock.Visibility = source.Visibility
	preBlock.OrganizationID = source.OrganizationID
}
