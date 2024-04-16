package filter

import (
	_ "embed"
	"testing"

	"github.com/stretchr/testify/assert"
)

//go:embed testdata/filters.yaml
var rawBytes []byte

func TestUnmarshall(t *testing.T) {

	filters, err := Unmarshal(rawBytes)

	assert.NoError(t, err, "Unexpected error while unmarshalling filters")
	assert.Greater(t, len(filters), 0, "Expecting three filters")

}
