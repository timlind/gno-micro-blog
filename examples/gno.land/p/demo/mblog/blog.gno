package mblog

import (
	"std"

	"gno.land/p/demo/ufmt"
	"gno.land/p/demo/avl"
)

type Blog struct {
	profiles avl.Tree // std.Address -> *Profile
	posts avl.Tree // std.Address_postId -> *Post
	postCount uint64
}

func NewBlog() *Blog {
	return &Blog{
	}
}

func (blog *Blog) CreateProfile(profile *Profile) {
	blog.profiles.Set(profile.Owner, profile)
}

func (blog *Blog) Post(owner std.Address, message string) {
	blog.posts.Set(ufmt.Sprintf("%s_%d", owner.String(), blog.postCount), NewPost(owner, message))
	blog.postCount++
}

func (blog *Blog) RenderHome() string {
	output := ""
	blog.profiles.Iterate("","", func(n *avl.Node) bool {
		profile, _ := n.Value().(*Profile)

		output += "* " + profile.Name + "\n"

		return false
	})
	return output
}

func (blog *Blog) RenderProfile(address string) string {
	value, exists := blog.profiles.Get(address)
	if !exists {
		return "not found"
	}
	profile, _ := value.(*Profile)


	output := "# " + profile.Name + "\n"
	output += profile.Bio + "\n"
	output += profile.Href + "["+profile.Href+"]\n\n"

	blog.posts.Iterate(std.GetOrigCaller().String(), "", func(n *avl.Node) bool {
		post, _ := n.Value().(*Post)

		output += post.body + "\n\n"

		return false
	})

	return output
}

