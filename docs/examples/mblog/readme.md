# Tutorial: Building a Microblog with GnoLand

## What We're Building

This tutorial is about builing a micro blogging platform on Gnoland in the Gno programming language.

A user will be able to: 
* Create one profile per address
* Create a new post
* View any profile and all their posts

## About GnoLand

GnoLand is a blockchain that runs smart contracts programmed in an interpreted version of Golang called Gno.

## Realms and Packages

Gno packages are like Golang packages, while realms are the smart contracts that store state.

Any variables associated with a realm package is automatically serialised and deserialised.

Gnoland has an AVL tree implementation that can be used an as efficient means to store and iterate over map like structures, which we'll see below.

## Render Functions

A realm can have a render function that takes a URL path segment and returns markdown
which will be displayed on the GnoLand website, making it easy to create smart contracts that can be viewed and navigated.


## Mblog Realm

We'll start off by creating the realm. 
It will store a pointer to a Blog struct that we'll define in our package, and a Render function.

Here you'll see a function in Gnolang's std package used: `std.GetOrigCaller()`. 
It gets the address of the calling account, similar to message.Signer() in cosmos, or msg.sender in Ethereum.

The Render() function responds to two routes: 
* A listing of profiles
* A profile page

```go
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
	} else if len(paths) > 1 && paths[0] == "profile" {
		return blog.RenderProfile(paths[1])
	}

	return "not found"
}
```

## Mblog Package

The mblog package defines three structs: 
* Blog
* Profile
* Post

### blog.go

The Blog struct uses Gnolangs AVL tree to store posts and profiles, 
which you can view the source code of in gno.land/p/demo/avl.

An AVL tree has an Iterate() function which iterates through a range of the keys, 
so we in a start and end range for iteration, then cast the node value to what we have previously stored. 
```go
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
```

### profile.go

```go
package mblog

import "gno.land/p/demo/avl"

type Profile struct {
	Owner string
	Name string
	Bio string
	Href string
}

func NewProfile(owner, name, bio, href string) *Profile {
	return &Profile{
		Owner: owner,
		Name: name,
		Bio: bio,
		Href: href,
	}
}
```

### post.go

```go
package mblog

import "std"

type Post struct {
	author std.Address
	date string
	body string
}
```

## Test Code

There are a few functions that help with testing.

* `std.TestAddress(string)` will generate a test address from the given string
* `std.TestSetOrigCaller(addr)` will set the address that is returned from `std.GetOrigCaller()`

### Realm Test Code

The realm tests code tests the three functions exported.

The Render() function has two cases that are tested, the homepage, and the profile page.

```go
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
```

### Package Test Code

```go
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
```

## Starting a Local Blockchain

Install the following binaries:
* gnoland
* gnoweb
* gnofaucet
* gnokey

```sh
cd gno.land
make install
```

Generate a new key with `gnokey generate` and `gnokey add --recover AdminKey`.

Install a genesis account by editing genesis_balances.txt

To start GnoLand run `gnoland`

To start the front end run `gnoweb`

## Deploying the Package and Realm

Install the package: 

```shell
gnokey maketx addpkg \                                                                                                                                                                                                                  
--pkgpath "gno.land/p/demo/mblog" \
--pkgdir "examples/gno.land/p/demo/mblog" \
--deposit 100000000ugnot \      
--gas-fee 1000000ugnot \                                                                              
--gas-wanted 2000000 \      
--broadcast \             
--chainid dev \         
--remote localhost:26657 \
AdminKey
```

Install the realm:

```shell
gnokey maketx addpkg \                                                                                                                                                                                                                  
--pkgpath "gno.land/r/demo/mblog" \
--pkgdir "examples/gno.land/r/demo/mblog" \
--deposit 100000000ugnot \      
--gas-fee 1000000ugnot \                                                                              
--gas-wanted 2000000 \      
--broadcast \             
--chainid dev \         
--remote localhost:26657 \
AdminKey
```

## Viewing the Render output

To view a list of profiles: http://127.0.0.1:8888/r/demo/mblog/

To view a profile: http://127.0.0.1:8888/r/demo/mblog:profile/{address}

## Creating a Profile

```shell
gnokey maketx call \                                                                                                                                                                                                                    
--pkgpath "gno.land/r/demo/mblog" \
--func "CreateProfile" \                   
--args "Test User" \            
--args "Testing everything." \                                                                        
--args "https://testr.xyz" \
--gas-fee "1000000ugnot" \
--gas-wanted "2000000" \
--broadcast \             
--chainid dev \           
--remote localhost:26657 \ 
AdminKey
```
## Posting a message

```shell
gnokey maketx call \
--pkgpath "gno.land/r/demo/mblog" \
--func "Post" \
--args "Hello world!" \
--gas-fee "1000000ugnot" \
--gas-wanted "2000000" \
--broadcast \
--chainid dev \
--remote localhost:26657 \
AdminKey
```

## Further Improvements

Some improvements that are left for the reader are: 
* Pagination
* Following
* Feeds
* Moderation
