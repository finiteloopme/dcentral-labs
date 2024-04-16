package filter

import (
	yaml "gopkg.in/yaml.v3"
)

type FilterType struct {
	Name        string `yaml:"name"`
	PubsubTopic string `yaml:"pubsub-topic,omitempty"`
	Address     string `yaml:"address,omitempty"`
	Event       string `yaml:"event,omitempty"`
	Abi         string `yaml:"abi,omitempty"`
}

type Filter struct {
	Filter FilterType `yaml:"filter"`
}

// Encodes raw bytes into a Filter record
func Unmarshal(rawBytes []byte) ([]*Filter, error) {
	var filter []*Filter

	return filter, yaml.Unmarshal(rawBytes, &filter)
}
