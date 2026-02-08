package handler

import (
	"testing"
)

func TestNormalizePagination(t *testing.T) {
	tests := []struct {
		page, pageSize, defaultSize int32
		wantPage, wantSize          int32
	}{
		{0, 0, 20, 1, 20},
		{1, 10, 20, 1, 10},
		{-1, 5, 20, 1, 5},
		{2, 0, 50, 2, 50},
		{3, 100, 20, 3, 100},
	}
	for _, tt := range tests {
		gotPage, gotSize := normalizePagination(tt.page, tt.pageSize, tt.defaultSize)
		if gotPage != tt.wantPage || gotSize != tt.wantSize {
			t.Errorf("normalizePagination(%d, %d, %d) = %d, %d; ожидалось %d, %d", tt.page, tt.pageSize, tt.defaultSize, gotPage, gotSize, tt.wantPage, tt.wantSize)
		}
	}
}
