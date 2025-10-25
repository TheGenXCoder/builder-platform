package importtypes

import (
	"time"

	"github.com/TheGenXCoder/knowledge-graph/pkg/types"
	"github.com/google/uuid"
)

// ImportSource represents a discovered file to import
type ImportSource struct {
	FilePath     string
	FileType     string // "conversation-log", "spec", "doc", "working-file"
	LastModified time.Time
	FileHash     string
	FileSize     int64

	// Visibility and organization (Week 1.5+)
	Visibility         string // "public", "org-private", "individual", "auto"
	SourceClass        string // "public-web", "private-repo", "client-data", "personal"
	OrganizationID     *uuid.UUID
	ContainsPII        bool
	RequiresCompliance []string // ["hipaa", "soc2", "gdpr"]

	// Metadata for classification
	Metadata map[string]interface{}
}

// ParsedDocument represents a parsed source file
type ParsedDocument struct {
	Source   ImportSource
	Metadata map[string]interface{}
	Sections []Section
}

// Section represents a hierarchical section in a document
type Section struct {
	Level    int // H1=1, H2=2, etc.
	Title    string
	Content  string
	Children []Section
	Line     int // Source line number
}

// PreBlock represents a block before embedding generation
type PreBlock struct {
	Topic       string
	Exchanges   []PreExchange
	Metadata    map[string]interface{}
	Tags        []string
	ProjectPath string
	SourceFile  string
	SourceType  string
	SourceHash  string
	StartedAt   time.Time
	CompletedAt *time.Time

	// Visibility and attribution (Week 1.5+)
	Visibility        string // "public", "org-private", "individual"
	OrganizationID    *uuid.UUID
	SourceURL         string // For attribution (web sources)
	SourceAttribution string // Citation text
}

// Getter methods for PreBlock (for interface compatibility with ImportBlock)
func (p *PreBlock) GetTopic() string                    { return p.Topic }
func (p *PreBlock) GetMetadata() map[string]interface{} { return p.Metadata }
func (p *PreBlock) GetTags() []string                   { return p.Tags }
func (p *PreBlock) GetProjectPath() string              { return p.ProjectPath }
func (p *PreBlock) GetSourceFile() string               { return p.SourceFile }
func (p *PreBlock) GetSourceType() string               { return p.SourceType }
func (p *PreBlock) GetSourceHash() string               { return p.SourceHash }
func (p *PreBlock) GetStartedAt() time.Time             { return p.StartedAt }
func (p *PreBlock) GetCompletedAt() *time.Time          { return p.CompletedAt }
func (p *PreBlock) GetVisibility() string               { return p.Visibility }
func (p *PreBlock) GetOrganizationID() *uuid.UUID       { return p.OrganizationID }
func (p *PreBlock) GetSourceURL() string                { return p.SourceURL }
func (p *PreBlock) GetSourceAttribution() string        { return p.SourceAttribution }
func (p *PreBlock) GetExchanges() []interface{} {
	exchanges := make([]interface{}, len(p.Exchanges))
	for i := range p.Exchanges {
		exchanges[i] = &p.Exchanges[i]
	}
	return exchanges
}

// PreExchange represents an exchange before database insertion
type PreExchange struct {
	Question  string
	Answer    string
	Timestamp time.Time
	ModelUsed string
}

// Getter methods for PreExchange (for interface compatibility)
func (p *PreExchange) GetQuestion() string     { return p.Question }
func (p *PreExchange) GetAnswer() string       { return p.Answer }
func (p *PreExchange) GetTimestamp() time.Time { return p.Timestamp }
func (p *PreExchange) GetModelUsed() string    { return p.ModelUsed }

// ImportDecision represents what to do with a PreBlock
type ImportDecision struct {
	Action      string // "insert", "update", "skip"
	PreBlock    *PreBlock
	ExistingID  *uuid.UUID
	Reason      string
	SourceBlock *types.Block // For updates
}

// ImportReport summarizes the import results
type ImportReport struct {
	StartedAt     time.Time
	CompletedAt   time.Time
	SourcesFound  int
	SourcesParsed int
	BlocksCreated int
	Decisions     []ImportDecision
	Inserted      int
	Updated       int
	Skipped       int
	Failed        int
	Errors        []ImportError
}

// ImportError represents an error during import
type ImportError struct {
	Source  ImportSource
	Stage   string // "discovery", "parse", "chunk", "deduplicate", "import"
	Message string
	Error   error
}

// ImportOptions configures the import process
type ImportOptions struct {
	// File discovery
	RootDir        string
	FileTypes      []string // "logs", "specs", "docs", "working", "all"
	ExcludePattern []string
	Recursive      bool

	// Processing
	DryRun         bool
	SkipDuplicates bool
	UpdateOnly     bool
	BatchSize      int

	// Output
	ShowProgress bool
	Verbose      bool
	PreviewCount int // Number of sample blocks in dry-run (default: 5)
}

// DefaultImportOptions returns sensible defaults
func DefaultImportOptions() ImportOptions {
	return ImportOptions{
		FileTypes:      []string{"all"},
		ExcludePattern: []string{".git/*", "node_modules/*", "*.test.md"},
		Recursive:      true,
		DryRun:         false,
		SkipDuplicates: false,
		UpdateOnly:     false,
		BatchSize:      10,
		ShowProgress:   true,
		Verbose:        false,
		PreviewCount:   5,
	}
}

// AddMetadata adds metadata to ImportSource
func (s *ImportSource) AddMetadata(key string, value interface{}) {
	if s.Metadata == nil {
		s.Metadata = make(map[string]interface{})
	}
	s.Metadata[key] = value
}
