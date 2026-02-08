package postgres

import (
	"testing"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

func Test_aiChatMessageModelToDomain(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := aiChatMessageModelToDomain(nil); got != nil {
			t.Errorf("aiChatMessageModelToDomain(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("с attachment и DeletedAt", func(t *testing.T) {
		att := "file-id"
		m := &aiChatMessageModel{
			Id:               "mid",
			SessionId:        "sid",
			Content:          "c",
			Role:             "user",
			AttachmentFileId: &att,
			CreatedAt:        now,
			UpdatedAt:        now,
			DeletedAt:        gorm.DeletedAt{Time: now, Valid: true},
		}
		got := aiChatMessageModelToDomain(m)
		if got == nil || got.AttachmentName != "file-id" || got.DeletedAt == nil || !got.DeletedAt.Equal(now) {
			t.Errorf("aiChatMessageModelToDomain: %+v", got)
		}
	})
}

func Test_aiChatMessageDomainToModel(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := aiChatMessageDomainToModel(nil); got != nil {
			t.Errorf("aiChatMessageDomainToModel(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("с AttachmentName и DeletedAt", func(t *testing.T) {
		msg := &domain.AIChatMessage{
			Id:             "mid",
			SessionId:      "sid",
			Content:        "c",
			Role:           domain.AIChatMessageRoleUser,
			AttachmentName: "file-id",
			CreatedAt:      now,
			UpdatedAt:      now,
			DeletedAt:      &now,
		}
		got := aiChatMessageDomainToModel(msg)
		if got == nil || got.AttachmentFileId == nil || *got.AttachmentFileId != "file-id" || !got.DeletedAt.Valid {
			t.Errorf("aiChatMessageDomainToModel: %+v", got)
		}
	})
}
