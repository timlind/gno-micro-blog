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