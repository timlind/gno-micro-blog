package mblog

import (
	"std"
	"strings"
	"testing"

	"gno.land/p/demo/testutils"

	"gno.land/p/demo/mblog"
)

func TestCreateProfile(t *testing.T) {
	author := testutils.TestAddress("author")
	std.TestSetOrigCaller(author)
	CreateProfile("Test User", "Testing everything.", "https://testr.xyz")
	profileStr := blog.RenderProfile(author.String())
	if strings.Contains(profileStr, "not found") {
		t.Fatalf("not found")
	}
}

func TestPost(t *testing.T) {
	author := testutils.TestAddress("author")
	std.TestSetOrigCaller(author)
	CreateProfile("Test User", "Testing everything.", "https://testr.xyz")
	Post("Hello world!")
	profileStr := blog.RenderProfile(author.String())
	if !strings.Contains(profileStr, "Hello world!") {
		t.Fatalf("missing message")
	}
}

func TestRender(t *testing.T) {
	author := testutils.TestAddress("author")
	std.TestSetOrigCaller(author)
	CreateProfile("Test User", "Testing everything.", "https://testr.xyz")

	t.Run("homepage", func(t *testing.T) {
		homeStr := Render("")
		if !strings.Contains(homeStr, "* Test User") {
			t.Fatalf("missing user")
		}
	})

	t.Run("profile", func(t *testing.T) {
		profileStr := Render("profile/" + author.String())
		if strings.Contains(profileStr, "not found") {
			t.Fatalf("not found")
		}
		if !strings.Contains(profileStr, "Test User") {
			t.Fatalf("missing name")
		}
		if !strings.Contains(profileStr, "Testing everything.") {
			t.Fatalf("missing bio")
		}
		if !strings.Contains(profileStr, "https://testr.xyz") {
			t.Fatalf("missing href")
		}
	})
}