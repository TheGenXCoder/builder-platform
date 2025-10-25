package importer

import (
	"bufio"
	"os"
	"regexp"
	"strings"

	"github.com/google/uuid"
)

// Public URL patterns for source classification
var publicURLPatterns = []string{
	// Documentation sites
	`https?://.*\.readthedocs\.io`,
	`https?://docs\..*`,
	`https?://.*\.github\.io`,

	// Q&A and community
	`https?://stackoverflow\.com`,
	`https?://stackexchange\.com`,
	`https?://serverfault\.com`,
	`https?://superuser\.com`,

	// Public repositories
	`https?://github\.com/[^/]+/[^/]+(?:/|$)`, // Public GitHub repos (not enterprise)
	`https?://gitlab\.com/[^/]+/[^/]+(?:/|$)`,

	// Technical blogs and resources
	`https?://medium\.com`,
	`https?://dev\.to`,
	`https?://hashnode\.com`,

	// Official documentation
	`https?://developer\.mozilla\.org`,
	`https?://golang\.org`,
	`https?://python\.org`,
	`https?://rust-lang\.org`,
}

// Paywall patterns (should NOT be classified as public)
var paywallPatterns = []string{
	`patreon\.com`,
	`medium\.com/.*membership`,
	`substack\.com/subscribe`,
}

// Client directory patterns (org-private classification)
var clientDirectoryPatterns = []string{
	`/work/`,
	`/client-`,
	`/clients/`,
	`/uta/`, // User's specific client
}

// Personal directory patterns (individual classification)
var personalDirectoryPatterns = []string{
	`/personal/`,
	`/home/`,
	`/Users/[^/]+/Documents`,
}

// ClassifySource determines visibility and source classification for an import source
func ClassifySource(source *ImportSource, defaultVisibility string, orgID *uuid.UUID) error {
	// Read file content for URL detection
	content, err := readFileContent(source.FilePath)
	if err != nil {
		return err
	}

	// Check for manual classification tags in content
	if hasTag(content, "#public") {
		source.Visibility = "public"
		source.SourceClass = "user-contributed"
		return nil
	}

	if hasTag(content, "#private") || hasTag(content, "#confidential") {
		source.Visibility = "org-private"
		source.SourceClass = "confidential"
		source.ContainsPII = true
		return nil
	}

	// Detect public URLs in content
	publicURLs := extractPublicURLs(content)
	if len(publicURLs) > 0 {
		// Check for paywall URLs
		if containsPaywallURLs(publicURLs) {
			source.Visibility = "org-private"
			source.SourceClass = "paywall-content"
		} else {
			source.Visibility = "public"
			source.SourceClass = "public-web"
			// Store first URL for attribution
			source.Metadata = map[string]interface{}{
				"source_urls": publicURLs,
			}
		}
		return nil
	}

	// Check directory path patterns
	path := source.FilePath

	// Client directories → org-private
	for _, pattern := range clientDirectoryPatterns {
		if strings.Contains(path, pattern) {
			source.Visibility = "org-private"
			source.SourceClass = "client-data"
			source.OrganizationID = orgID
			return nil
		}
	}

	// Personal directories → individual
	for _, pattern := range personalDirectoryPatterns {
		if strings.Contains(path, pattern) {
			source.Visibility = "individual"
			source.SourceClass = "personal"
			return nil
		}
	}

	// Check git remote for public repos
	if isPublicGitRepo(path) {
		source.Visibility = "public"
		source.SourceClass = "public-repo"
		return nil
	}

	// Default behavior based on configuration
	if defaultVisibility == "auto" {
		// Auto mode: default to org-private for safety
		source.Visibility = "org-private"
		source.SourceClass = "private-repo"
		source.OrganizationID = orgID
	} else {
		source.Visibility = defaultVisibility
		source.SourceClass = "user-specified"
		if defaultVisibility == "org-private" {
			source.OrganizationID = orgID
		}
	}

	return nil
}

// extractPublicURLs finds all public URLs in content
func extractPublicURLs(content string) []string {
	var urls []string
	seen := make(map[string]bool)

	for _, pattern := range publicURLPatterns {
		re := regexp.MustCompile(pattern)
		matches := re.FindAllString(content, -1)
		for _, url := range matches {
			if !seen[url] {
				urls = append(urls, url)
				seen[url] = true
			}
		}
	}

	return urls
}

// containsPaywallURLs checks if any URLs are behind paywalls
func containsPaywallURLs(urls []string) bool {
	for _, url := range urls {
		for _, pattern := range paywallPatterns {
			if matched, _ := regexp.MatchString(pattern, url); matched {
				return true
			}
		}
	}
	return false
}

// hasTag checks if content contains a specific tag
func hasTag(content, tag string) bool {
	// Check markdown frontmatter
	if strings.Contains(content, tag) {
		return true
	}
	// Check tag index section
	tagIndexRe := regexp.MustCompile(`(?i)##\s*tag\s*index\s*\n([^#]+)`)
	if matches := tagIndexRe.FindStringSubmatch(content); len(matches) > 1 {
		return strings.Contains(matches[1], tag)
	}
	return false
}

// isPublicGitRepo checks if the file is in a public git repository
func isPublicGitRepo(filePath string) bool {
	// TODO: Implement git remote check
	// For now, return false (Week 2 feature)
	return false
}

// readFileContent reads file content for classification
func readFileContent(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	// Read first 10KB for classification (don't load entire large files)
	var content strings.Builder
	scanner := bufio.NewScanner(file)
	lineCount := 0
	maxLines := 200 // ~10KB of text

	for scanner.Scan() && lineCount < maxLines {
		content.WriteString(scanner.Text())
		content.WriteString("\n")
		lineCount++
	}

	return content.String(), scanner.Err()
}
