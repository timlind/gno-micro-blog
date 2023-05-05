package mblog

import (
	"std"
	"strings"
	"testing"

	"gno.land/p/demo/testutils"
)

func TestBlog_CreateProfile(t *testing.T) {
	author := testutils.TestAddress("author")

	blog := NewBlog()
	blog.CreateProfile(NewProfile(author.String(), "Test User", "Testing everything.", "https://testr.xyz"))

	value, exists := blog.profiles.Get(author.String())
	if !exists {
		t.Fatalf("profile not found")
	}
	profile, ok := value.(*Profile)
	if !ok {
		t.Fatalf("not a *Profile")
	}
	if profile.Owner != author.String() {
		t.Fatalf("incorrect owner")
	}
	if profile.Name != "Test User" {
		t.Fatalf("incorrect name")
	}
	if profile.Bio != "Testing everything." {
		t.Fatalf("incorrect bio")
	}
}

func TestBlog_Post(t *testing.T) {
	author := testutils.TestAddress("author")
	std.TestSetOrigCaller(author)

	blog := NewBlog()
	blog.CreateProfile(NewProfile(author.String(), "", "", ""))
	blog.Post(author, "Hello world!")
	value, exists := blog.posts.Get(author.String() + "_0")
	if !exists {
		t.Fatalf("no post found")
	}
	post, ok := value.(*Post)
	if !ok {
		t.Fatalf("not a *Post")
	}
	if author != post.author {
		t.Fatalf("incorrect author")
	}
	if post.body != "Hello world!" {
		t.Fatalf("incorrect post body")
	}
}

func TestBlog_RenderHome(t *testing.T) {
	author := testutils.TestAddress("author")

	blog := NewBlog()
	blog.CreateProfile(NewProfile(author.String(), "Test User", "", ""))

	homeStr := blog.RenderHome()
	if !strings.Contains(homeStr, "* Test User") {
		t.Fatalf("missing user")
	}
}

func TestBlog_RenderProfile(t *testing.T) {
	author := testutils.TestAddress("author")

	blog := NewBlog()
	blog.CreateProfile(NewProfile(author.String(), "Test User", "Testing everything.", "https://testr.xyz"))

	blog.Post(author, "Hello world!")

	profileStr := blog.RenderProfile(author.String())
	if !strings.Contains(profileStr, "Test User") {
		t.Fatalf("missing name")
	}
	if !strings.Contains(profileStr, "Testing everything.") {
		t.Fatalf("missing bio")
	}
	if !strings.Contains(profileStr, "https://testr.xyz") {
		t.Fatalf("missing href")
	}
	if !strings.Contains(profileStr, "Hello world!") {
		t.Fatalf("missing post")
	}
}