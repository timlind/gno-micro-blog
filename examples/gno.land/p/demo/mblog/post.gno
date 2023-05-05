package mblog

import (
	"time"

	"std"
)

type Post struct {
	author std.Address
	date time.Time
	body string
}

func NewPost(author std.Address, body string) *Post {
	return &Post{
		author: author,
		body: body,
		date: time.Now(),
	}
}