package importer

import (
	"github.com/TheGenXCoder/knowledge-graph/internal/importtypes"
)

// Re-export types from importtypes for backward compatibility
type ImportSource = importtypes.ImportSource
type ParsedDocument = importtypes.ParsedDocument
type Section = importtypes.Section
type PreBlock = importtypes.PreBlock
type PreExchange = importtypes.PreExchange
type ImportDecision = importtypes.ImportDecision
type ImportReport = importtypes.ImportReport
type ImportError = importtypes.ImportError
type ImportOptions = importtypes.ImportOptions

// Re-export default options function
var DefaultImportOptions = importtypes.DefaultImportOptions
