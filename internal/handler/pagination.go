package handler

func normalizePagination(page, pageSize, defaultPageSize int32) (int32, int32) {
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = defaultPageSize
	}
	return page, pageSize
}
