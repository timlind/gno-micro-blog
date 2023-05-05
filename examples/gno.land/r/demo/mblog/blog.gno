package mblog

import (
	"strings"

	"std"
	"gno.land/p/demo/mblog"
)

var (
	blog *mblog.Blog
)

func init() {
	blog = mblog.NewBlog()
}

func CreateProfile(name, bio, href string) {
	profile := mblog.NewProfile(
		std.GetOrigCaller().String(),
		name,
		bio,
		href,
	)
	blog.CreateProfile(profile)
}

func Post(message string) {
	blog.Post(std.GetOrigCaller(), message)
}

func Render(path string) string {
	paths := strings.Split(path, "/")

	if path == "" {
		return blog.RenderHome()
	} else if paths[0] == "profile" {
		return blog.RenderProfile(paths[1])
	}

	return "not found"
}