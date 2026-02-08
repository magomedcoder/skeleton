package pkg

import "testing"

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		name     string
		password string
		wantErr  bool
	}{
		{"пустой пароль", "", true},
		{"короткий пароль", "short", true},
		{"7 символов", "1234567", true},
		{"8 символов", "12345678", false},
		{"длинный пароль", "validPassword123", false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidatePassword(tt.password)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidatePassword(%q): err = %v, ожидалась ошибка: %v", tt.password, err, tt.wantErr)
			}
		})
	}
}
