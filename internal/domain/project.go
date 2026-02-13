package domain

type Project struct {
	Id        string
	Name      string
	CreatedBy int
}

type ProjectMember struct {
	ProjectId string
	UserId    int
	CreatedBy int
}

type Task struct {
	Id          string
	ProjectId   string
	Name        string
	Description string
	CreatedBy   int
	CreatedAt   int64
	Assigner    int
	Executor    int
}
