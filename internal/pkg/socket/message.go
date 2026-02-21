package socket

import "github.com/magomedcoder/legion/api/pb/accountpb"

type SenderContent struct {
	isAck        bool
	broadcast    bool
	excludeIDs   []int64
	recipientIDs []int64
	update       *accountpb.UpdateResponse
}

func NewSenderContent() *SenderContent {
	return &SenderContent{
		excludeIDs:   nil,
		recipientIDs: nil,
		update:       &accountpb.UpdateResponse{},
	}
}

func (s *SenderContent) SetAck(value bool) *SenderContent {
	s.isAck = value
	return s
}

func (s *SenderContent) SetBroadcast(value bool) *SenderContent {
	s.broadcast = value

	return s
}

func (s *SenderContent) SetUpdateUserStatus(update *accountpb.Update_UserStatus) *SenderContent {
	s.update = &accountpb.UpdateResponse{
		Updates: []*accountpb.Update{{UpdateType: update}},
	}
	return s
}

func (s *SenderContent) SetUpdateNewMessage(update *accountpb.Update_NewMessage) *SenderContent {
	s.update = &accountpb.UpdateResponse{
		Updates: []*accountpb.Update{{UpdateType: update}},
	}

	return s
}

func (s *SenderContent) SetUpdateNewTask(update *accountpb.Update_NewTask) *SenderContent {
	s.update = &accountpb.UpdateResponse{
		Updates: []*accountpb.Update{{UpdateType: update}},
	}

	return s
}

func (s *SenderContent) SetUpdateTaskChanged(update *accountpb.Update_TaskChanged) *SenderContent {
	s.update = &accountpb.UpdateResponse{
		Updates: []*accountpb.Update{{UpdateType: update}},
	}
	
	return s
}

func (s *SenderContent) SetUpdateMessageDeleted(update *accountpb.Update_MessageDeleted) *SenderContent {
	s.update = &accountpb.UpdateResponse{
		Updates: []*accountpb.Update{{UpdateType: update}},
	}

	return s
}

func (s *SenderContent) SetUpdateMessageRead(update *accountpb.Update_MessageRead) *SenderContent {
	s.update = &accountpb.UpdateResponse{
		Updates: []*accountpb.Update{{UpdateType: update}},
	}

	return s
}

func (s *SenderContent) SetReceive(cid ...int64) *SenderContent {
	s.recipientIDs = append(s.recipientIDs, cid...)
	return s
}

func (s *SenderContent) SetExclude(cid ...int64) *SenderContent {
	s.excludeIDs = append(s.excludeIDs, cid...)
	return s
}

func (s *SenderContent) IsBroadcast() bool {
	return s.broadcast
}

func (s *SenderContent) Build() *accountpb.UpdateResponse {
	return &accountpb.UpdateResponse{
		Updates: s.update.Updates,
	}
}
