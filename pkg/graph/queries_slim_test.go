package graph

import (
	"testing"
)

func TestComputeSlim_DeadObjects(t *testing.T) {
	objects := []SlimObjectInfo{
		{Name: "ZCL_LIVE", Type: "CLAS", Package: "$ZDEV"},
		{Name: "ZCL_DEAD", Type: "CLAS", Package: "$ZDEV"},
		{Name: "ZPROG_DEAD", Type: "PROG", Package: "$ZDEV"},
	}
	refs := []SlimRefRow{
		// ZCL_LIVE has an external caller
		{CallerInclude: "ZCL_CONSUMER========CP", TargetName: "ZCL_LIVE", Source: "WBCROSSGT"},
		// ZCL_DEAD: only self-reference
		{CallerInclude: "ZCL_DEAD========CP", TargetName: "ZCL_DEAD", Source: "WBCROSSGT"},
		// ZPROG_DEAD: no references at all
	}

	result := ComputeSlim(objects, refs, nil)

	if result.TotalObjects != 3 {
		t.Errorf("TotalObjects: got %d, want 3", result.TotalObjects)
	}
	if result.DeadObjectCount != 2 {
		t.Errorf("DeadObjectCount: got %d, want 2 (ZCL_DEAD + ZPROG_DEAD)", result.DeadObjectCount)
	}
	if result.LiveObjectCount != 1 {
		t.Errorf("LiveObjectCount: got %d, want 1", result.LiveObjectCount)
	}

	// Check dead entries
	deadNames := make(map[string]bool)
	for _, d := range result.DeadObjects {
		deadNames[d.Name] = true
		if d.Kind != "dead_object" {
			t.Errorf("Kind should be dead_object, got %q", d.Kind)
		}
		if d.Confidence != "HIGH" {
			t.Errorf("Dead object confidence should be HIGH, got %q", d.Confidence)
		}
	}
	if !deadNames["ZCL_DEAD"] {
		t.Error("ZCL_DEAD should be dead")
	}
	if !deadNames["ZPROG_DEAD"] {
		t.Error("ZPROG_DEAD should be dead")
	}
	if deadNames["ZCL_LIVE"] {
		t.Error("ZCL_LIVE should NOT be dead")
	}
}

func TestComputeSlim_SelfRefNotCounted(t *testing.T) {
	objects := []SlimObjectInfo{
		{Name: "ZCL_SELF", Type: "CLAS", Package: "$ZDEV"},
	}
	refs := []SlimRefRow{
		// Self-references from different includes of the same class
		{CallerInclude: "ZCL_SELF========CP", TargetName: "ZCL_SELF", Source: "WBCROSSGT"},
		{CallerInclude: "ZCL_SELF========CU", TargetName: "ZCL_SELF", Source: "WBCROSSGT"},
		{CallerInclude: "ZCL_SELF========CM001", TargetName: "ZCL_SELF", Source: "WBCROSSGT"},
	}

	result := ComputeSlim(objects, refs, nil)

	if result.DeadObjectCount != 1 {
		t.Errorf("Self-refs only: should be dead, got %d dead", result.DeadObjectCount)
	}
}

func TestComputeSlim_AllLive(t *testing.T) {
	objects := []SlimObjectInfo{
		{Name: "ZCL_A", Type: "CLAS"},
		{Name: "ZCL_B", Type: "CLAS"},
	}
	refs := []SlimRefRow{
		{CallerInclude: "ZCL_B========CP", TargetName: "ZCL_A", Source: "WBCROSSGT"},
		{CallerInclude: "ZCL_A========CP", TargetName: "ZCL_B", Source: "WBCROSSGT"},
	}

	result := ComputeSlim(objects, refs, nil)

	if result.DeadObjectCount != 0 {
		t.Errorf("All live: got %d dead", result.DeadObjectCount)
	}
}

func TestComputeSlim_Empty(t *testing.T) {
	result := ComputeSlim(nil, nil, nil)

	if result.TotalObjects != 0 || result.DeadObjectCount != 0 {
		t.Error("Empty input should produce empty result")
	}
}

func TestComputeSlim_DeadMethods(t *testing.T) {
	objects := []SlimObjectInfo{
		{
			Name: "ZCL_FOO", Type: "CLAS", Package: "$ZDEV",
			Methods: []string{"LIVE_METHOD", "DEAD_METHOD", "INTF_METHOD"},
		},
	}
	refs := []SlimRefRow{
		// Object is alive (has external caller)
		{CallerInclude: "ZCL_CONSUMER========CP", TargetName: "ZCL_FOO", Source: "WBCROSSGT"},
	}
	// INTF_METHOD comes from interface — should not be flagged
	interfaceMethods := map[string]bool{
		"ZCL_FOO=>INTF_METHOD": true,
	}

	result := ComputeSlim(objects, refs, interfaceMethods)

	// Object is live, so methods are checked
	if result.DeadObjectCount != 0 {
		t.Error("ZCL_FOO should be live")
	}
	// DEAD_METHOD and LIVE_METHOD should both appear as dead_method
	// (we don't have method-level ref tracking in v1, so both are flagged)
	// But INTF_METHOD should be skipped (interface method)
	for _, m := range result.DeadMethods {
		if m.Method == "INTF_METHOD" {
			t.Error("Interface method should not be flagged as dead")
		}
		if m.Confidence != "MEDIUM" {
			t.Errorf("Dead method confidence should be MEDIUM, got %q", m.Confidence)
		}
	}
}

func TestComputeSlim_DeadObjectSkipsMethodAnalysis(t *testing.T) {
	objects := []SlimObjectInfo{
		{
			Name: "ZCL_DEAD", Type: "CLAS",
			Methods: []string{"METHOD_A", "METHOD_B"},
		},
	}
	// No refs at all — object is dead
	result := ComputeSlim(objects, nil, nil)

	if result.DeadObjectCount != 1 {
		t.Error("Should be dead")
	}
	// Dead object's methods should NOT be listed separately
	if result.DeadMethodCount != 0 {
		t.Errorf("Dead object's methods should not be listed: got %d", result.DeadMethodCount)
	}
}

func TestComputeSlim_Sorting(t *testing.T) {
	objects := []SlimObjectInfo{
		{Name: "ZPROG_C", Type: "PROG"},
		{Name: "ZCL_A", Type: "CLAS"},
		{Name: "ZCL_B", Type: "CLAS"},
	}

	result := ComputeSlim(objects, nil, nil)

	if len(result.DeadObjects) != 3 {
		t.Fatalf("Expected 3 dead, got %d", len(result.DeadObjects))
	}
	// Sorted by NodeID: CLAS:ZCL_A < CLAS:ZCL_B < PROG:ZPROG_C
	if result.DeadObjects[0].Name != "ZCL_A" {
		t.Errorf("First: got %q, want ZCL_A", result.DeadObjects[0].Name)
	}
	if result.DeadObjects[1].Name != "ZCL_B" {
		t.Errorf("Second: got %q, want ZCL_B", result.DeadObjects[1].Name)
	}
	if result.DeadObjects[2].Name != "ZPROG_C" {
		t.Errorf("Third: got %q, want ZPROG_C", result.DeadObjects[2].Name)
	}
}

func TestComputeSlim_CrossSource(t *testing.T) {
	// Refs from CROSS (not just WBCROSSGT) should count
	objects := []SlimObjectInfo{
		{Name: "Z_MY_FM", Type: "FUGR"},
	}
	refs := []SlimRefRow{
		{CallerInclude: "ZREPORT", TargetName: "Z_MY_FM", Source: "CROSS"},
	}

	result := ComputeSlim(objects, refs, nil)

	if result.DeadObjectCount != 0 {
		t.Error("Z_MY_FM has CROSS caller, should be live")
	}
}
