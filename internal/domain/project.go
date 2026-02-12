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
