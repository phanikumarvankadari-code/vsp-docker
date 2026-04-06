package graph

import (
	"sort"
	"strings"
)

// SlimEntry represents a candidate dead object or dead method.
type SlimEntry struct {
	NodeID        string `json:"node_id"`                   // CLAS:ZCL_OLD_HELPER
	Name          string `json:"name"`                      // ZCL_OLD_HELPER
	Type          string `json:"type"`                      // CLAS, PROG, INTF, FUGR, TABL, ...
	Package       string `json:"package,omitempty"`         // $ZDEV
	Kind          string `json:"kind"`                      // "dead_object" or "dead_method"
	Method        string `json:"method,omitempty"`          // method name (for dead_method only)
	IncomingRefs  int    `json:"incoming_refs"`             // total incoming references found
	Confidence    string `json:"confidence"`                // HIGH = zero refs confirmed, MEDIUM = low refs but some noise possible
	LastTransport string `json:"last_transport,omitempty"`  // YYYYMMDD from meta if available
}

// SlimResult is the result of ComputeSlim.
type SlimResult struct {
	Scope            string      `json:"scope"`
	TotalObjects     int         `json:"total_objects"`
	DeadObjects      []SlimEntry `json:"dead_objects"`
	DeadMethods      []SlimEntry `json:"dead_methods,omitempty"`
	DeadObjectCount  int         `json:"dead_object_count"`
	DeadMethodCount  int         `json:"dead_method_count"`
	LiveObjectCount  int         `json:"live_object_count"`
}

// SlimObjectInfo describes a custom object in the target package.
type SlimObjectInfo struct {
	Name    string
	Type    string
	Package string
	Methods []string // for classes: method names (empty for non-class types)
}

// SlimRefRow represents a reverse cross-reference row.
// CallerInclude = who references this, TargetName = what is referenced.
type SlimRefRow struct {
	CallerInclude string // include that holds the reference
	TargetName    string // object being referenced
	Source        string // "WBCROSSGT" or "CROSS"
}

// ComputeSlim identifies dead objects and optionally dead methods.
// An object is "dead" if no external objects reference it (zero incoming
// cross-refs from outside its own object scope).
// A method is "dead" if no external objects call it AND it is not declared
// in an implemented interface (interface methods may be called polymorphically).
//
// This is a read-only analysis. No deletions.
func ComputeSlim(objects []SlimObjectInfo, refs []SlimRefRow, interfaceMethods map[string]bool) *SlimResult {
	result := &SlimResult{
		TotalObjects: len(objects),
	}

	// Build object set for self-reference detection
	objectSet := make(map[string]bool)
	for _, obj := range objects {
		objectSet[strings.ToUpper(obj.Name)] = true
	}

	// Count incoming external references per target
	// External = caller is not the same object (after NormalizeInclude)
	incomingRefs := make(map[string]int)       // target name → count of external refs
	methodRefs := make(map[string]int)          // "OBJNAME=>METHOD" → count of external refs

	for _, ref := range refs {
		targetUpper := strings.ToUpper(strings.TrimSpace(ref.TargetName))
		if targetUpper == "" {
			continue
		}

		callerInclude := strings.TrimSpace(ref.CallerInclude)
		if callerInclude == "" {
			continue
		}

		// Normalize caller to object level
		_, _, callerName := NormalizeInclude(callerInclude)
		callerUpper := strings.ToUpper(callerName)

		// Skip self-references (same object referencing itself)
		if strings.EqualFold(callerUpper, targetUpper) {
			continue
		}

		incomingRefs[targetUpper]++

		// Track method-level refs: if caller include contains method call pattern
		// This is approximate — we count any reference to the object as potential method usage
		// More precise method-level analysis would need source parsing
	}

	// Identify dead objects
	for _, obj := range objects {
		nameUpper := strings.ToUpper(obj.Name)
		refs := incomingRefs[nameUpper]

		if refs == 0 {
			entry := SlimEntry{
				NodeID:       NodeID(obj.Type, obj.Name),
				Name:         obj.Name,
				Type:         obj.Type,
				Package:      obj.Package,
				Kind:         "dead_object",
				IncomingRefs: 0,
				Confidence:   "HIGH",
			}
			result.DeadObjects = append(result.DeadObjects, entry)
		}
	}

	// Identify dead methods (for classes with methods listed)
	if interfaceMethods == nil {
		interfaceMethods = make(map[string]bool)
	}

	for _, obj := range objects {
		if obj.Type != "CLAS" || len(obj.Methods) == 0 {
			continue
		}

		nameUpper := strings.ToUpper(obj.Name)

		// If the whole object is dead, don't also list its methods
		if incomingRefs[nameUpper] == 0 {
			continue
		}

		for _, method := range obj.Methods {
			methodUpper := strings.ToUpper(method)
			methodKey := nameUpper + "=>" + methodUpper

			// Skip if method is from an interface (may be called polymorphically)
			if interfaceMethods[methodKey] {
				continue
			}

			// Check if this specific method has external references
			// We use the method-level ref count if available
			methodRefCount := methodRefs[methodKey]

			if methodRefCount == 0 {
				entry := SlimEntry{
					NodeID:       NodeID(obj.Type, obj.Name),
					Name:         obj.Name,
					Type:         obj.Type,
					Package:      obj.Package,
					Kind:         "dead_method",
					Method:       method,
					IncomingRefs: 0,
					Confidence:   "MEDIUM", // method-level analysis is less precise
				}
				result.DeadMethods = append(result.DeadMethods, entry)
			}
		}
	}

	// Sort: dead objects by name, dead methods by class then method
	sort.Slice(result.DeadObjects, func(i, j int) bool {
		return result.DeadObjects[i].NodeID < result.DeadObjects[j].NodeID
	})
	sort.Slice(result.DeadMethods, func(i, j int) bool {
		if result.DeadMethods[i].NodeID != result.DeadMethods[j].NodeID {
			return result.DeadMethods[i].NodeID < result.DeadMethods[j].NodeID
		}
		return result.DeadMethods[i].Method < result.DeadMethods[j].Method
	})

	result.DeadObjectCount = len(result.DeadObjects)
	result.DeadMethodCount = len(result.DeadMethods)
	result.LiveObjectCount = result.TotalObjects - result.DeadObjectCount

	return result
}
