package importer

import (
	"crypto/sha256"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// Discover finds all importable files in the given directory
func Discover(opts ImportOptions) ([]ImportSource, error) {
	var sources []ImportSource

	// Determine file patterns based on requested types
	patterns := getFilePatterns(opts.FileTypes)

	err := filepath.Walk(opts.RootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories
		if info.IsDir() {
			// Check if directory should be excluded
			relPath, _ := filepath.Rel(opts.RootDir, path)
			if shouldExclude(relPath, opts.ExcludePattern) {
				return filepath.SkipDir
			}
			return nil
		}

		// Check if file matches any pattern
		relPath, _ := filepath.Rel(opts.RootDir, path)
		if shouldExclude(relPath, opts.ExcludePattern) {
			return nil
		}

		for _, pattern := range patterns {
			matched, _ := filepath.Match(pattern.Pattern, info.Name())
			if matched {
				// Calculate file hash
				hash, err := calculateFileHash(path)
				if err != nil {
					return fmt.Errorf("failed to hash file %s: %w", path, err)
				}

				source := ImportSource{
					FilePath:     path,
					FileType:     pattern.Type,
					LastModified: info.ModTime(),
					FileHash:     hash,
					FileSize:     info.Size(),
				}
				sources = append(sources, source)
				break
			}
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to discover files: %w", err)
	}

	// Log file type breakdown
	typeCounts := make(map[string]int)
	for _, s := range sources {
		typeCounts[s.FileType]++
	}
	log.Printf("[DISCOVERY] File type breakdown:")
	for fileType, count := range typeCounts {
		log.Printf("[DISCOVERY]   %s: %d files", fileType, count)
	}

	return sources, nil
}

// FilePattern maps file patterns to import types
type FilePattern struct {
	Pattern string
	Type    string
}

// getFilePatterns returns file patterns for requested types
func getFilePatterns(types []string) []FilePattern {
	patterns := []FilePattern{}

	for _, t := range types {
		switch t {
		case "logs", "conversation-logs":
			patterns = append(patterns, FilePattern{
				Pattern: "session-*.md",
				Type:    "conversation-log",
			})
		case "specs", "specifications":
			patterns = append(patterns, FilePattern{
				Pattern: "*-spec.md",
				Type:    "spec",
			})
			patterns = append(patterns, FilePattern{
				Pattern: "*-specification.md",
				Type:    "spec",
			})
		case "docs", "documentation":
			patterns = append(patterns, FilePattern{
				Pattern: "README.md",
				Type:    "readme",
			})
			patterns = append(patterns, FilePattern{
				Pattern: "MISSION.md",
				Type:    "mission",
			})
			patterns = append(patterns, FilePattern{
				Pattern: "*.md",
				Type:    "doc",
			})
		case "working":
			patterns = append(patterns, FilePattern{
				Pattern: ".working.md",
				Type:    "working-file",
			})
		case "all":
			return getFilePatterns([]string{"logs", "specs", "docs", "working"})
		}
	}

	return patterns
}

// shouldExclude checks if a path matches any exclude pattern
func shouldExclude(path string, patterns []string) bool {
	for _, pattern := range patterns {
		matched, _ := filepath.Match(pattern, path)
		if matched {
			return true
		}
		// Also check if path starts with pattern (for directory exclusion)
		if strings.HasPrefix(path, strings.TrimSuffix(pattern, "/*")) {
			return true
		}
	}
	return false
}

// calculateFileHash computes SHA256 hash of file contents
func calculateFileHash(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", h.Sum(nil)), nil
}
