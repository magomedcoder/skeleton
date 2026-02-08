package postgres

import "testing"

func Test_normalizePagination(t *testing.T) {
	tests := []struct {
		page, pageSize int32
		wantPage       int32
		wantPageSize   int32
		wantOffset     int32
	}{
		{0, 0, 1, 20, 0},
		{1, 10, 1, 10, 0},
		{2, 20, 2, 20, 20},
		{-1, 5, 1, 5, 0},
		{3, 250, 3, 200, 400},
	}
	for _, tt := range tests {
		gotPage, gotSize, gotOffset := normalizePagination(tt.page, tt.pageSize)
		if gotPage != tt.wantPage || gotSize != tt.wantPageSize || gotOffset != tt.wantOffset {
			t.Errorf("normalizePagination(%d, %d) = %d, %d, %d; ожидалось %d, %d, %d", tt.page, tt.pageSize, gotPage, gotSize, gotOffset, tt.wantPage, tt.wantPageSize, tt.wantOffset)
		}
	}
}
